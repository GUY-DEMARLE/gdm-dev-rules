#!/usr/bin/env bash
# install.sh — Installation des règles IA GDM dans un repo
#
# Usage depuis n'importe quel repo GDM :
#   cd /chemin/vers/ton/repo
#   curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/install.sh | bash
#
# Ou en local (si tu as cloné gdm-dev-rules) :
#   ./install.sh

set -e

# Configuration
REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/templates}"
DOCS_API_URL="${DOCS_API_URL:-https://api.github.com/repos/GUY-DEMARLE/gdm-dev-rules/contents/templates/docs-rules?ref=main}"
WORKFLOW_URL="${WORKFLOW_URL:-https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/.github/workflows/security-oss.yml}"
FORCE="${FORCE:-false}"

# Couleurs
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   Installation des règles IA GDM${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier qu'on est dans un repo Git
if [ ! -d ".git" ]; then
    echo -e "${RED}✗ Ce dossier n'est pas un repo Git. Lance 'git init' d'abord.${NC}"
    exit 1
fi

# Liste des fichiers à installer (source -> target)
files=(
    ".ai-rules/RULES.md"
    ".cursor/rules/gdm-rules.mdc"
    "CLAUDE.md"
    "AGENTS.md"
)

# Vérifier si des fichiers existent déjà
existing_files=()
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        existing_files+=("$file")
    fi
done

if [ ${#existing_files[@]} -gt 0 ] && [ "$FORCE" != "true" ]; then
    echo -e "${YELLOW}⚠ Les fichiers suivants existent déjà :${NC}"
    for f in "${existing_files[@]}"; do
        echo -e "${YELLOW}    $f${NC}"
    done
    echo ""
    echo -e "${YELLOW}Pour mettre à jour ces fichiers, utilise update.sh à la place :${NC}"
    echo -e "${YELLOW}  curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.sh | bash${NC}"
    echo ""
    echo -e "${YELLOW}Ou relance avec FORCE=true pour écraser :${NC}"
    echo -e "${YELLOW}  FORCE=true ./install.sh${NC}"
    exit 1
fi

# Créer les dossiers nécessaires
echo -e "${CYAN}→ Création des dossiers...${NC}"
mkdir -p .ai-rules .cursor/rules
echo -e "${GREEN}✓ Dossiers OK${NC}"

# Télécharger chaque fichier
echo -e "${CYAN}→ Téléchargement des fichiers depuis $REPO_URL...${NC}"
for file in "${files[@]}"; do
    url="$REPO_URL/$file"
    if curl -sSL -f "$url" -o "$file"; then
        echo -e "${GREEN}✓ $file${NC}"
    else
        echo -e "${RED}✗ Échec du téléchargement de $url${NC}"
        exit 1
    fi
done

# Télécharger la documentation GDM (docs-rules/) — liste dynamique via l'API GitHub
echo -e "${CYAN}→ Téléchargement de la documentation (docs-rules/)...${NC}"
mkdir -p docs-rules
# Extraire les "download_url" du JSON renvoyé par l'API GitHub (sans dépendre de jq)
download_urls=$(curl -sSL -H "User-Agent: gdm-dev-rules-installer" "$DOCS_API_URL" \
    | grep -o '"download_url": *"[^"]*"' \
    | sed 's/.*"download_url": *"\([^"]*\)".*/\1/')
if [ -n "$download_urls" ]; then
    while IFS= read -r doc_url; do
        [ -z "$doc_url" ] && continue
        doc_name=$(basename "$doc_url")
        if curl -sSL -f "$doc_url" -o "docs-rules/$doc_name"; then
            echo -e "${GREEN}✓ docs-rules/$doc_name${NC}"
        else
            echo -e "${YELLOW}⚠ Échec du téléchargement de $doc_url${NC}"
        fi
    done <<< "$download_urls"
else
    echo -e "${YELLOW}⚠ Impossible de lister docs-rules/ via l'API GitHub (règles principales installées).${NC}"
fi

# Design system IA GDM (system-design/) — écrasement complet, c'est une source
# de vérité : le kit ne se modifie pas dans les applications.
# La liste des fichiers vient de MANIFEST.txt (le dossier a des sous-dossiers,
# et raw.githubusercontent n'a pas la limite de 60 req/h de l'API GitHub).
echo -e "${CYAN}→ Téléchargement du design system (system-design/)...${NC}"
SD_BASE="$REPO_URL/system-design"
sd_manifest=$(curl -sSL -f "$SD_BASE/MANIFEST.txt" || true)
if [ -n "$sd_manifest" ]; then
    # On enlève les CR (le manifeste peut arriver en CRLF), les commentaires
    # et les lignes vides.
    sd_files=$(printf '%s\n' "$sd_manifest" | tr -d '\r' \
        | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$')
    while IFS= read -r rel; do
        [ -z "$rel" ] && continue
        mkdir -p "system-design/$(dirname "$rel")"
        if curl -sSL -f "$SD_BASE/$rel" -o "system-design/$rel"; then
            echo -e "${GREEN}✓ system-design/$rel${NC}"
        else
            echo -e "${YELLOW}⚠ Échec du téléchargement de system-design/$rel${NC}"
        fi
    done <<< "$sd_files"
else
    echo -e "${YELLOW}⚠ Impossible de lire system-design/MANIFEST.txt (design system non installé).${NC}"
fi

# Workflow GitHub Actions Security OSS — obligatoire sur toute app GDM
# (RULES.md § 2.6 : Gitleaks/Semgrep/OSV bloquants sur PR, audit complet chaque lundi).
echo -e "${CYAN}→ Téléchargement de .github/workflows/security-oss.yml...${NC}"
mkdir -p .github/workflows
if curl -sSL -f "$WORKFLOW_URL" -o ".github/workflows/security-oss.yml"; then
    echo -e "${GREEN}✓ .github/workflows/security-oss.yml${NC}"
else
    echo -e "${YELLOW}⚠ Impossible de télécharger le workflow security-oss.${NC}"
    echo -e "${YELLOW}⚠ Il est OBLIGATOIRE (RULES.md § 2.6) : relance le script avant de merger.${NC}"
fi

# Vérifier le .gitignore
echo -e "${CYAN}→ Vérification du .gitignore...${NC}"
if [ -f ".gitignore" ]; then
    patterns=(".ai-rules" ".cursor" "CLAUDE.md" "AGENTS.md" "docs-rules" "system-design" ".github/workflows")
    ignored_files=()
    for pattern in "${patterns[@]}"; do
        if grep -qF "$pattern" .gitignore; then
            ignored_files+=("$pattern")
        fi
    done
    if [ ${#ignored_files[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠ Les patterns suivants sont dans .gitignore et empêchent de commit les règles :${NC}"
        for f in "${ignored_files[@]}"; do
            echo -e "${YELLOW}    $f${NC}"
        done
        echo -e "${YELLOW}⚠ Retire-les manuellement si tu veux versionner les règles.${NC}"
    else
        echo -e "${GREEN}✓ .gitignore OK${NC}"
    fi
else
    echo -e "${GREEN}✓ Pas de .gitignore (les règles seront versionnées)${NC}"
fi

# Message final
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Installation terminée ✓${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${WHITE}Prochaines étapes :${NC}"
echo ""
echo -e "${WHITE}  1. Ouvre CLAUDE.md et remplis les sections 'Contexte du projet'${NC}"
echo -e "${WHITE}     et 'Règles spécifiques à ce projet'.${NC}"
echo ""
echo -e "${WHITE}  2. Commit les fichiers :${NC}"
echo -e "${GRAY}       git add .ai-rules/ .cursor/ CLAUDE.md AGENTS.md docs-rules/ system-design/ .github/${NC}"
echo -e "${GRAY}       git commit -m \"chore: add GDM AI rules\"${NC}"
echo ""
echo -e "${WHITE}  3. Vérifie que ça marche :${NC}"
echo -e "${WHITE}     - Avec Claude Code : lance 'claude' et demande${NC}"
echo -e "${WHITE}       'Quelles sont les règles GDM ?'${NC}"
echo -e "${WHITE}     - Avec Cursor : Cmd/Ctrl+L et même question${NC}"
echo -e "${WHITE}     - Avec Codex : ouvre le repo et pose la même question${NC}"
echo ""
echo -e "${WHITE}Pour mettre à jour les règles plus tard :${NC}"
echo -e "${GRAY}  curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.sh | bash${NC}"
echo ""
