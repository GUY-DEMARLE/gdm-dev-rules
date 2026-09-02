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
DOCS_API_URL="${DOCS_API_URL:-https://api.github.com/repos/GUY-DEMARLE/gdm-dev-rules/contents/templates/docs-rules?ref=main}"
WORKFLOW_URL="${WORKFLOW_URL:-https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/.github/workflows/security-oss.yml}"

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
        # Sécurité : on ne touche PAS à un fichier existant dont on ne sait pas
        # isoler la partie projet, pour ne jamais écraser du contenu custom.
        echo -e "${YELLOW}⚠ Section '## Contexte du projet' non détectée dans CLAUDE.md : fichier laissé intact (aucune mise à jour pour éviter d'écraser du contenu).${NC}"
    fi
else
    curl -sSL -f "$REPO_URL/CLAUDE.md" -o "CLAUDE.md"
    echo -e "${YELLOW}⚠ CLAUDE.md créé (n'existait pas), pense à remplir le contexte projet${NC}"
fi

# Mise à jour de AGENTS.md (avec préservation des sections projet)
echo -e "${CYAN}→ Mise à jour de AGENTS.md (préservation du contexte projet)...${NC}"

if [ -f "AGENTS.md" ]; then
    # Extraire la section "## Contexte du projet" jusqu'à la fin
    if grep -q "^## Contexte du projet" AGENTS.md; then
        # Sauvegarder la section projet
        project_section=$(awk '/^## Contexte du projet/,EOF' AGENTS.md)
        echo -e "${GREEN}✓ Sections projet AGENTS.md détectées et préservées${NC}"

        # Télécharger le nouveau template
        new_template=$(curl -sSL -f "$REPO_URL/AGENTS.md")

        # Remplacer la section projet du template par celle préservée
        echo "$new_template" | sed -n '1,/^## Contexte du projet/p' | sed '$d' > AGENTS.md.tmp
        echo "$project_section" >> AGENTS.md.tmp
        mv AGENTS.md.tmp AGENTS.md

        echo -e "${GREEN}✓ AGENTS.md${NC}"
    else
        # Sécurité : on ne touche PAS à un fichier existant dont on ne sait pas
        # isoler la partie projet, pour ne jamais écraser du contenu custom.
        echo -e "${YELLOW}⚠ Section '## Contexte du projet' non détectée dans AGENTS.md : fichier laissé intact (aucune mise à jour pour éviter d'écraser du contenu).${NC}"
    fi
else
    curl -sSL -f "$REPO_URL/AGENTS.md" -o "AGENTS.md"
    echo -e "${YELLOW}⚠ AGENTS.md créé (n'existait pas), pense à remplir le contexte projet${NC}"
fi

# Mise à jour de la documentation GDM (docs-rules/) — écrasement complet, source de vérité
echo -e "${CYAN}→ Mise à jour de la documentation (docs-rules/)...${NC}"
mkdir -p docs-rules
# Extraire les "download_url" du JSON renvoyé par l'API GitHub (sans dépendre de jq)
download_urls=$(curl -sSL -H "User-Agent: gdm-dev-rules-updater" "$DOCS_API_URL" \
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
    echo -e "${YELLOW}⚠ Impossible de lister docs-rules/ via l'API GitHub.${NC}"
fi

# Design system IA GDM (system-design/) — écrasement complet, c'est une source
# de vérité : le kit ne se modifie pas dans les applications.
# La liste des fichiers vient de MANIFEST.txt (le dossier a des sous-dossiers,
# et raw.githubusercontent n'a pas la limite de 60 req/h de l'API GitHub).
echo -e "${CYAN}→ Mise à jour du design system (system-design/)...${NC}"
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
    echo -e "${YELLOW}⚠ Impossible de lire system-design/MANIFEST.txt (design system non mis à jour).${NC}"
fi

# Workflow GitHub Actions Security OSS — obligatoire sur toute app GDM
# (RULES.md § 2.6 : Gitleaks/Semgrep/OSV bloquants sur PR, audit complet chaque lundi).
echo -e "${CYAN}→ Mise à jour de .github/workflows/security-oss.yml...${NC}"
mkdir -p .github/workflows
if curl -sSL -f "$WORKFLOW_URL" -o ".github/workflows/security-oss.yml"; then
    echo -e "${GREEN}✓ .github/workflows/security-oss.yml${NC}"
else
    echo -e "${YELLOW}⚠ Impossible de télécharger le workflow security-oss.${NC}"
    echo -e "${YELLOW}⚠ Il est OBLIGATOIRE (RULES.md § 2.6) : relance le script.${NC}"
fi

# Afficher le diff Git
echo ""
echo -e "${CYAN}→ Changements détectés :${NC}"
echo ""
git diff --stat .ai-rules/ .cursor/ CLAUDE.md AGENTS.md docs-rules/ system-design/ .github/ 2>/dev/null || true
echo ""

# Message final
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Mise à jour terminée ✓${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${WHITE}Prochaines étapes :${NC}"
echo ""
echo -e "${WHITE}  1. Vérifie le diff avec :${NC}"
echo -e "${GRAY}       git diff .ai-rules/ .cursor/ CLAUDE.md AGENTS.md docs-rules/ system-design/ .github/${NC}"
echo ""
echo -e "${WHITE}  2. Si OK, commit :${NC}"
echo -e "${GRAY}       git add .ai-rules/ .cursor/ CLAUDE.md AGENTS.md docs-rules/ system-design/ .github/${NC}"
echo -e "${GRAY}       git commit -m \"chore: update GDM AI rules\"${NC}"
echo ""
