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

# Vérifier le .gitignore
echo -e "${CYAN}→ Vérification du .gitignore...${NC}"
if [ -f ".gitignore" ]; then
    patterns=(".ai-rules" ".cursor" "CLAUDE.md" "AGENTS.md")
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
echo -e "${GRAY}       git add .ai-rules/ .cursor/ CLAUDE.md AGENTS.md${NC}"
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
