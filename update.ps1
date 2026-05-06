# update.ps1 — Mise à jour des règles IA GDM dans un repo existant
#
# Met à jour les fichiers de règles SANS toucher aux sections personnalisées
# de CLAUDE.md (contexte du projet, règles spécifiques).
#
# Usage depuis n'importe quel repo GDM :
#   cd C:\chemin\vers\ton\repo
#   irm https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.ps1 | iex

param(
    [string]$RepoUrl = "https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/templates"
)

$ErrorActionPreference = "Stop"

function Write-Step { param($Msg) Write-Host "→ $Msg" -ForegroundColor Cyan }
function Write-Ok { param($Msg) Write-Host "✓ $Msg" -ForegroundColor Green }
function Write-Warn { param($Msg) Write-Host "⚠ $Msg" -ForegroundColor Yellow }
function Write-Err { param($Msg) Write-Host "✗ $Msg" -ForegroundColor Red }

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Mise à jour des règles IA GDM" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Vérifier qu'on est dans un repo Git
if (-not (Test-Path ".git")) {
    Write-Err "Ce dossier n'est pas un repo Git."
    exit 1
}

# Vérifier que les règles sont déjà installées
if (-not (Test-Path ".ai-rules/RULES.md")) {
    Write-Err "Les règles ne sont pas encore installées dans ce repo."
    Write-Err "Utilise install.ps1 à la place :"
    Write-Host "  irm https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/install.ps1 | iex" -ForegroundColor Yellow
    exit 1
}

# Mise à jour de RULES.md (écrasement complet, c'est la source de vérité)
Write-Step "Mise à jour de .ai-rules/RULES.md..."
try {
    Invoke-RestMethod -Uri "$RepoUrl/.ai-rules/RULES.md" -OutFile ".ai-rules/RULES.md"
    Write-Ok ".ai-rules/RULES.md"
} catch {
    Write-Err "Échec : $($_.Exception.Message)"
    exit 1
}

# Mise à jour de gdm-rules.mdc (écrasement complet, c'est juste un loader)
Write-Step "Mise à jour de .cursor/rules/gdm-rules.mdc..."
try {
    Invoke-RestMethod -Uri "$RepoUrl/.cursor/rules/gdm-rules.mdc" -OutFile ".cursor/rules/gdm-rules.mdc"
    Write-Ok ".cursor/rules/gdm-rules.mdc"
} catch {
    Write-Err "Échec : $($_.Exception.Message)"
    exit 1
}

# Mise à jour de CLAUDE.md (avec préservation des sections projet)
Write-Step "Mise à jour de CLAUDE.md (préservation du contexte projet)..."

if (Test-Path "CLAUDE.md") {
    $existingContent = Get-Content "CLAUDE.md" -Raw

    # Extraire les sections personnalisées (entre "## Contexte du projet" et la fin)
    $projectSectionMatch = [regex]::Match($existingContent, '## Contexte du projet[\s\S]*$', 'Multiline')

    if ($projectSectionMatch.Success) {
        $projectSection = $projectSectionMatch.Value
        Write-Ok "Sections projet détectées et préservées"
    } else {
        $projectSection = $null
        Write-Warn "Pas de section projet détectée, le fichier sera complètement remplacé"
    }

    # Télécharger le nouveau template
    $newTemplate = Invoke-RestMethod -Uri "$RepoUrl/CLAUDE.md"

    if ($projectSection) {
        # Remplacer les sections projet du nouveau template par celles préservées
        $newContent = [regex]::Replace($newTemplate, '## Contexte du projet[\s\S]*$', $projectSection)
        Set-Content -Path "CLAUDE.md" -Value $newContent -NoNewline
    } else {
        Set-Content -Path "CLAUDE.md" -Value $newTemplate -NoNewline
    }
    Write-Ok "CLAUDE.md"
} else {
    Invoke-RestMethod -Uri "$RepoUrl/CLAUDE.md" -OutFile "CLAUDE.md"
    Write-Warn "CLAUDE.md créé (n'existait pas), pense à remplir le contexte projet"
}

# Afficher le diff Git
Write-Step "Changements détectés :"
Write-Host ""
git diff --stat .ai-rules/ .cursor/ CLAUDE.md 2>$null
Write-Host ""

# Message final
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "   Mise à jour terminée ✓" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaines étapes :" -ForegroundColor White
Write-Host ""
Write-Host "  1. Vérifie le diff avec :" -ForegroundColor White
Write-Host "       git diff .ai-rules/ .cursor/ CLAUDE.md" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Si OK, commit :" -ForegroundColor White
Write-Host "       git add .ai-rules/ .cursor/ CLAUDE.md" -ForegroundColor Gray
Write-Host "       git commit -m `"chore: update GDM AI rules`"" -ForegroundColor Gray
Write-Host ""
