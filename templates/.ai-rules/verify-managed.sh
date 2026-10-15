#!/usr/bin/env bash
# verify-managed.sh — Vérifie que les fichiers gérés par gdm-dev-rules n'ont pas
# été modifiés dans cette app.
#
# Fichier géré par gdm-dev-rules : ne pas le modifier ici. Il est posé et mis à
# jour automatiquement par le robot de synchro (PR « chore(gdm-rules) »).
#
# Usage :
#   bash .ai-rules/verify-managed.sh              → vérifie (CI « GDM Rules Guard »)
#   bash .ai-rules/verify-managed.sh --generate   → (robot) lit « mode chemin » sur
#                                                   stdin et écrit le manifeste
#
# Modes de hachage :
#   full    fichier entier
#   header  partie GDM de CLAUDE.md / AGENTS.md (tout ce qui précède
#           « ## Contexte du projet », la suite appartient au projet)
#   block   bloc « # >>> gdm-dev-rules … # <<< gdm-dev-rules » de CODEOWNERS
#
# Les retours chariot (\r) sont ignorés : un poste Windows en CRLF ne déclenche
# pas de faux positif.

set -euo pipefail

cd "$(dirname "$0")/.."
MANIFEST=".ai-rules/MANAGED.sha256"

if command -v sha256sum >/dev/null 2>&1; then
    sha() { sha256sum | cut -d' ' -f1; }
else
    sha() { shasum -a 256 | cut -d' ' -f1; }
fi

gdm_hash() {
    local mode=$1 path=$2
    case "$mode" in
        full)   cat -- "$path" ;;
        header) awk '/^## Contexte du projet/{exit} {print}' "$path" ;;
        block)  awk '/^# >>> gdm-dev-rules/{f=1} f{print} /^# <<< gdm-dev-rules/{f=0}' "$path" ;;
        *)      echo "mode inconnu : $mode" >&2; return 2 ;;
    esac | tr -d '\r' | sha
}

if [ "${1:-}" = "--generate" ]; then
    {
        echo "# Empreintes des fichiers gérés par gdm-dev-rules — généré par le robot de synchro."
        echo "# Ne pas modifier : la CI « GDM Rules Guard » compare ces empreintes aux fichiers."
        while read -r mode path; do
            [ -z "$mode" ] && continue
            echo "$(gdm_hash "$mode" "$path")  $mode  $path"
        done
    } > "$MANIFEST"
    exit 0
fi

if [ ! -f "$MANIFEST" ]; then
    echo "::error::$MANIFEST absent : les règles GDM ne sont pas installées dans ce repo (ajoute le topic gdm-managed au repo, le robot les posera)."
    exit 1
fi

errors=0
while read -r expected mode path; do
    case "$expected" in ''|'#'*) continue ;; esac
    if [ ! -f "$path" ]; then
        echo "::error file=$path::Fichier géré par gdm-dev-rules supprimé : $path"
        errors=$((errors + 1))
        continue
    fi
    actual=$(gdm_hash "$mode" "$path")
    if [ "$actual" != "$expected" ]; then
        case "$mode" in
            header) what="la partie GDM (avant « ## Contexte du projet »)" ;;
            block)  what="le bloc gdm-dev-rules" ;;
            *)      what="le fichier" ;;
        esac
        echo "::error file=$path::$path : $what a été modifié localement. Ce contenu est géré par gdm-dev-rules : annule la modification. Pour faire évoluer la règle, ouvre une PR sur GUY-DEMARLE/gdm-dev-rules."
        errors=$((errors + 1))
    fi
done < "$MANIFEST"

if [ "$errors" -gt 0 ]; then
    echo ""
    echo "✗ $errors fichier(s) géré(s) par gdm-dev-rules modifié(s) localement."
    exit 1
fi

echo "✓ Fichiers gérés par gdm-dev-rules intacts."
