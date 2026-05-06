#!/usr/bin/env bash
# update.sh — Mise à jour des règles IA GDM dans un repo existant
#
# Met à jour les fichiers de règles SANS toucher aux sections personnalisées
# de CLAUDE.md (contexte du projet, règles spécifiques).
#
# Usage depuis n'importe quel repo GDM :
#   cd /chemin/vers/ton/repo
#   curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.sh | bash

set -e

REPO_URL="${REPO_URL:-https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/templates}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   Mise à jour des règles IA GDM${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier qu'on est dans un repo Git
if [ ! -d ".git" ]; then
    echo -e "${RED}✗ Ce dossier n'est pas un repo Git.${NC}"
    exit 1
fi

# Vérifier que les règles sont déjà installées
if [ ! -f ".ai-rules/RULES.md" ]; then
    echo -e "${RED}✗ Les règles ne sont pas encore installées dans ce repo.${NC}"
    echo -e "${RED}  Utilise install.sh à la place :${NC}"
    echo -e "${YELLOW}  curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/install.sh | bash${NC}"
    exit 1
fi

# Mise à jour de RULES.md (écrasement complet)
echo -e "${CYAN}→ Mise à jour de .ai-rules/RULES.md...${NC}"
if curl -sSL -f "$REPO_URL/.ai-rules/RULES.md" -o ".ai-rules/RULES.md"; then
    echo -e "${GREEN}✓ .ai-rules/RULES.md${NC}"
else
    echo -e "${RED}✗ Échec du téléchargement${NC}"
    exit 1
fi

# Mise à jour de gdm-rules.mdc
echo -e "${CYAN}→ Mise à jour de .cursor/rules/gdm-rules.mdc...${NC}"
if curl -sSL -f "$REPO_URL/.cursor/rules/gdm-rules.mdc" -o ".cursor/rules/gdm-rules.mdc"; then
    echo -e "${GREEN}✓ .cursor/rules/gdm-rules.mdc${NC}"
else
    echo -e "${RED}✗ Échec du téléchargement${NC}"
    exit 1
fi

# Mise à jour de CLAUDE.md (avec préservation des sections projet)
echo -e "${CYAN}→ Mise à jour de CLAUDE.md (préservation du contexte projet)...${NC}"

if [ -f "CLAUDE.md" ]; then
    # Extraire la section "## Contexte du projet" jusqu'à la fin
    if grep -q "^## Contexte du projet" CLAUDE.md; then
        # Sauvegarder la section projet
        project_section=$(awk '/^## Contexte du projet/,EOF' CLAUDE.md)
        echo -e "${GREEN}✓ Sections projet détectées et préservées${NC}"

        # Télécharger le nouveau template
        new_template=$(curl -sSL -f "$REPO_URL/CLAUDE.md")

        # Remplacer la section projet du template par celle préservée
        # On garde tout ce qui est avant "## Contexte du projet" du nouveau template,
        # puis on colle la section projet préservée
        echo "$new_template" | sed -n '1,/^## Contexte du projet/p' | sed '$d' > CLAUDE.md.tmp
        echo "$project_section" >> CLAUDE.md.tmp
        mv CLAUDE.md.tmp CLAUDE.md

        echo -e "${GREEN}✓ CLAUDE.md${NC}"
    else
        # Pas de section projet, écrasement complet
        curl -sSL -f "$REPO_URL/CLAUDE.md" -o "CLAUDE.md"
        echo -e "${YELLOW}⚠ Pas de section projet détectée, fichier complètement remplacé${NC}"
    fi
else
    curl -sSL -f "$REPO_URL/CLAUDE.md" -o "CLAUDE.md"
    echo -e "${YELLOW}⚠ CLAUDE.md créé (n'existait pas), pense à remplir le contexte projet${NC}"
fi

# Afficher le diff Git
echo ""
echo -e "${CYAN}→ Changements détectés :${NC}"
echo ""
git diff --stat .ai-rules/ .cursor/ CLAUDE.md 2>/dev/null || true
echo ""

# Message final
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Mise à jour terminée ✓${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${WHITE}Prochaines étapes :${NC}"
echo ""
echo -e "${WHITE}  1. Vérifie le diff avec :${NC}"
echo -e "${GRAY}       git diff .ai-rules/ .cursor/ CLAUDE.md${NC}"
echo ""
echo -e "${WHITE}  2. Si OK, commit :${NC}"
echo -e "${GRAY}       git add .ai-rules/ .cursor/ CLAUDE.md${NC}"
echo -e "${GRAY}       git commit -m \"chore: update GDM AI rules\"${NC}"
echo ""
