#!/usr/bin/env bash
# apply.sh — Pose ou met à jour, dans une app, tous les fichiers gérés par
# gdm-dev-rules. Fonctionne sur n'importe quelle app, quelle que soit sa stack.
#
# Utilisé par le robot de synchro (sync-all.sh). Peut aussi se lancer à la main :
#   bash sync/apply.sh <dossier gdm-dev-rules> <dossier de l'app>
#
# Variables optionnelles :
#   GDM_NOTES    fichier où écrire les remarques (reprises dans la PR)
#   GDM_TOUCHED  fichier où lister les chemins posés ou supprimés (pour git add)
#   GDM_DEPENDABOT_BRANCH  branche visée par les PR Dependabot quand ce n'est
#                pas la branche par défaut de l'app (en pratique : dev)
#
# Ce que fait le script :
#   - écrase les fichiers gérés en entier (règles, docs-rules, design system,
#     workflows Security OSS et GDM Rules Guard, script de vérification) ;
#   - écrit .github/dependabot.yml selon les gestionnaires de paquets présents
#     (npm, pip, composer), sauf si l'app a déjà le sien ;
#   - met à jour la partie GDM de CLAUDE.md / AGENTS.md en préservant
#     « ## Contexte du projet » et tout ce qui suit ;
#   - retire le bloc gdm-dev-rules que les anciennes versions posaient dans
#     CODEOWNERS (fichier supprimé s'il ne contenait que ce bloc) ;
#   - supprime les fichiers qui ne sont plus gérés (retirés de la source) ;
#   - régénère .ai-rules/MANAGED.sha256, lu par la CI GDM Rules Guard.

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage : $0 <dossier gdm-dev-rules> <dossier de l'app>" >&2
    exit 2
fi

SRC=$(cd "$1" && pwd)
DST=$(cd "$2" && pwd)
TPL="$SRC/templates"
NOTES="${GDM_NOTES:-/dev/null}"
TOUCHED="${GDM_TOUCHED:-/dev/null}"
DEPENDABOT_BRANCH="${GDM_DEPENDABOT_BRANCH:-}"
MANIFEST_REL=".ai-rules/MANAGED.sha256"

entries=()

note()       { echo "- $*" >> "$NOTES"; echo "  ⚠ $*" >&2; }
mark()       { echo "$1" >> "$TOUCHED"; }
managed()    { entries+=("$1 $2"); mark "$2"; }

copy_full() { # copy_full <source> <chemin dans l'app>
    mkdir -p "$DST/$(dirname "$2")"
    cp "$1" "$DST/$2"
    managed full "$2"
}

merge_header() { # merge_header <template> <chemin dans l'app>
    local tpl=$1 rel=$2 dst="$DST/$2"
    if [ ! -f "$dst" ]; then
        cp "$tpl" "$dst"
        note "\`$rel\` créé : pense à remplir la section « Contexte du projet »."
    elif grep -q '^## Contexte du projet' "$dst"; then
        {
            awk '/^## Contexte du projet/{exit} {print}' "$tpl"
            awk '/^## Contexte du projet/{f=1} f' "$dst"
        } > "$dst.gdm-tmp"
        mv "$dst.gdm-tmp" "$dst"
    else
        # On ne sait pas isoler la partie projet : on ne touche à rien plutôt
        # que d'écraser du contenu personnalisé.
        note "\`$rel\` n'a pas de section « ## Contexte du projet » : laissé intact, sa partie GDM n'est pas synchronisée."
        return 0
    fi
    managed header "$rel"
}

# Les premières versions du robot posaient un bloc gdm-dev-rules dans
# CODEOWNERS. Abandonné : la relecture obligatoire (règle gdm-protection) et la
# garde GDM Rules Guard font déjà le travail. On retire le bloc et on supprime
# le fichier s'il ne contenait que lui ; le reste d'un CODEOWNERS est conservé.
remove_codeowners_block() {
    local c dst kept
    for c in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do
        dst="$DST/$c"
        [ -f "$dst" ] || continue
        grep -q '^# >>> gdm-dev-rules' "$dst" || continue
        kept=$(awk '/^# >>> gdm-dev-rules/{f=1} !f{print} /^# <<< gdm-dev-rules/{f=0}' "$dst")
        if [ -z "$(printf '%s' "$kept" | tr -d '[:space:]')" ]; then
            rm -f "$dst"
            note "\`$c\` supprimé : il ne contenait que le bloc gdm-dev-rules, qui n'est plus utilisé."
        else
            printf '%s\n' "$kept" > "$dst"
            note "Bloc gdm-dev-rules retiré de \`$c\` ; le reste du fichier est conservé."
        fi
        mark "$c"
    done
}

# Dossiers de l'app (« / », « /api »…) qui contiennent un des manifestes
# donnés en arguments de find. Hors dépendances installées et fichiers gérés.
manifest_dirs() {
    (cd "$DST" && find . \( -name .git -o -name node_modules -o -name vendor \
        -o -name .venv -o -name venv -o -name docs-rules -o -name system-design \) -prune \
        -o -type f \( "$@" \) -print) \
        | sed -e 's#/[^/]*$##' -e 's#^\.##' -e 's#^$#/#' | LC_ALL=C sort -u
}

# Dependabot : une PR par semaine, qui regroupe les correctifs et versions
# mineures. Les versions majeures se décident et se font à la main. Pas de
# mises à jour des actions GitHub : les workflows de l'app sont gérés ici.
write_dependabot() {
    local rel=".github/dependabot.yml" dst="$DST/.github/dependabot.yml"
    local eco dirs d p body="" was_managed=0
    for p in ${previous[@]+"${previous[@]}"}; do
        [ "$p" = "$rel" ] && was_managed=1
    done
    if [ -f "$dst" ] && [ "$was_managed" = 0 ]; then
        note "\`$rel\` existe déjà et n'a pas été posé par gdm-dev-rules : laissé intact."
        return 0
    fi
    for eco in npm pip composer; do
        case "$eco" in
            npm)      dirs=$(manifest_dirs -name package.json) ;;
            pip)      dirs=$(manifest_dirs -name 'requirements*.txt' -o -name pyproject.toml -o -name Pipfile) ;;
            composer) dirs=$(manifest_dirs -name composer.json) ;;
        esac
        [ -n "$dirs" ] || continue
        body+="  - package-ecosystem: \"$eco\""$'\n'
        body+="    directories:"$'\n'
        while IFS= read -r d; do body+="      - \"$d\""$'\n'; done <<< "$dirs"
        [ -n "$DEPENDABOT_BRANCH" ] && body+="    target-branch: \"$DEPENDABOT_BRANCH\""$'\n'
        body+='    schedule:
      interval: "weekly"
      day: "monday"
      time: "05:00"
      timezone: "Europe/Paris"
    groups:
      mises-a-jour:
        patterns: ["*"]
    ignore:
      - dependency-name: "*"
        update-types: ["version-update:semver-major"]
    commit-message:
      prefix: "chore(deps)"
'
    done
    # Aucun gestionnaire de paquets : pas de fichier (l'étape 7 retire celui
    # d'une synchro précédente).
    [ -n "$body" ] || return 0
    [ "$was_managed" = 1 ] || note "Dependabot activé : chaque lundi, une PR${DEPENDABOT_BRANCH:+ vers \`$DEPENDABOT_BRANCH\`} regroupe les correctifs et versions mineures des dépendances. À merger si elle est verte, après un coup d'œil à l'aperçu de l'app."
    mkdir -p "$DST/.github"
    {
        echo "# Fichier géré par gdm-dev-rules : ne pas le modifier ici."
        echo "#"
        echo "# Chaque lundi, une PR par dossier de dépendances regroupe les correctifs et"
        echo "# versions mineures. Les versions majeures se décident et se font à la main."
        echo "version: 2"
        echo "updates:"
        printf '%s' "$body"
    } > "$dst"
    managed full "$rel"
}

# Fichiers gérés lors de la synchro précédente (pour supprimer ceux retirés).
previous=()
if [ -f "$DST/$MANIFEST_REL" ]; then
    while read -r _hash mode path; do
        case "$_hash" in ''|'#'*) continue ;; esac
        [ "$mode" = full ] && previous+=("$path")
    done < "$DST/$MANIFEST_REL"
fi

# 1. Règles IA et script de vérification
copy_full "$TPL/.ai-rules/RULES.md"             ".ai-rules/RULES.md"
copy_full "$TPL/.ai-rules/verify-managed.sh"    ".ai-rules/verify-managed.sh"
copy_full "$TPL/.cursor/rules/gdm-rules.mdc"    ".cursor/rules/gdm-rules.mdc"

# 2. Workflows : pipeline sécurité (copie complète, voulue) et garde
copy_full "$SRC/.github/workflows/security-oss.yml"      ".github/workflows/security-oss.yml"
copy_full "$TPL/.github/workflows/gdm-rules-guard.yml"   ".github/workflows/gdm-rules-guard.yml"
write_dependabot

# 3. Documentation GDM
for f in "$TPL/docs-rules/"*; do
    [ -f "$f" ] && copy_full "$f" "docs-rules/$(basename "$f")"
done

# 4. Design system (liste dans MANIFEST.txt, qui gère les sous-dossiers)
while IFS= read -r rel; do
    rel=${rel%$'\r'}
    case "$rel" in ''|'#'*) continue ;; esac
    copy_full "$TPL/system-design/$rel" "system-design/$rel"
done < "$TPL/system-design/MANIFEST.txt"

# 5. Instructions IA : partie GDM mise à jour, partie projet préservée
merge_header "$TPL/CLAUDE.md" "CLAUDE.md"
merge_header "$TPL/AGENTS.md" "AGENTS.md"

# 6. Ancien bloc CODEOWNERS : retiré
remove_codeowners_block

# 7. Fichiers qui ne sont plus gérés : on les retire
for old in ${previous[@]+"${previous[@]}"}; do
    still=0
    for e in "${entries[@]}"; do
        [ "$e" = "full $old" ] && { still=1; break; }
    done
    [ "$still" = 1 ] && continue
    case "$old" in
        *..*) continue ;;
        .ai-rules/*|.cursor/rules/*|docs-rules/*|system-design/*|.github/workflows/*|.github/dependabot.yml)
            if [ -f "$DST/$old" ]; then
                rm -f "$DST/$old"
                mark "$old"
                note "\`$old\` supprimé : il n'est plus distribué par gdm-dev-rules."
            fi
            ;;
    esac
done

# 8. Empreintes lues par la CI GDM Rules Guard
(cd "$DST" && printf '%s\n' "${entries[@]}" | bash .ai-rules/verify-managed.sh --generate)
mark "$MANIFEST_REL"
