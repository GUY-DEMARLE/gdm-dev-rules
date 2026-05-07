# install.ps1 — Installation des règles IA GDM dans un repo
#
# Usage depuis n'importe quel repo GDM :
#   cd C:\chemin\vers\ton\repo
#   irm https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/install.ps1 | iex
#
# Ou en local (si tu as cloné gdm-dev-rules) :
#   .\install.ps1

param(
    [string]$RepoUrl = "https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/templates",
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

# Couleurs ANSI pour PowerShell
function Write-Step { param($Msg) Write-Host "→ $Msg" -ForegroundColor Cyan }
function Write-Ok { param($Msg) Write-Host "✓ $Msg" -ForegroundColor Green }
function Write-Warn { param($Msg) Write-Host "⚠ $Msg" -ForegroundColor Yellow }
function Write-Err { param($Msg) Write-Host "✗ $Msg" -ForegroundColor Red }

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Installation des règles IA GDM" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Vérifier qu'on est dans un repo Git
if (-not (Test-Path ".git")) {
    Write-Err "Ce dossier n'est pas un repo Git. Lance 'git init' d'abord."
    exit 1
}

# Liste des fichiers à installer
$files = @(
    @{ Source = ".ai-rules/RULES.md"; Target = ".ai-rules/RULES.md" },
    @{ Source = ".cursor/rules/gdm-rules.mdc"; Target = ".cursor/rules/gdm-rules.mdc" },
    @{ Source = "CLAUDE.md"; Target = "CLAUDE.md" },
    @{ Source = "AGENTS.md"; Target = "AGENTS.md" }
)

# Vérifier si des fichiers existent déjà
$existingFiles = @()
foreach ($file in $files) {
    if (Test-Path $file.Target) {
        $existingFiles += $file.Target
    }
}

if ($existingFiles.Count -gt 0 -and -not $Force) {
    Write-Warn "Les fichiers suivants existent déjà :"
    foreach ($f in $existingFiles) {
        Write-Host "    $f" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Pour mettre à jour ces fichiers, utilise update.ps1 à la place :" -ForegroundColor Yellow
    Write-Host "  irm https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.ps1 | iex" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Ou relance avec -Force pour écraser :" -ForegroundColor Yellow
    Write-Host "  .\install.ps1 -Force" -ForegroundColor Yellow
    exit 1
}

# Créer les dossiers nécessaires
Write-Step "Création des dossiers..."
$dirs = @(".ai-rules", ".cursor", ".cursor/rules")
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}
Write-Ok "Dossiers OK"

# Télécharger chaque fichier
Write-Step "Téléchargement des fichiers depuis $RepoUrl..."
foreach ($file in $files) {
    $url = "$RepoUrl/$($file.Source)"
    try {
        Invoke-RestMethod -Uri $url -OutFile $file.Target
        Write-Ok "$($file.Target)"
    } catch {
        Write-Err "Échec du téléchargement de $url"
        Write-Err $_.Exception.Message
        exit 1
    }
}

# Vérifier que .gitignore ne ignore pas ces fichiers
Write-Step "Vérification du .gitignore..."
if (Test-Path ".gitignore") {
    $gitignore = Get-Content ".gitignore" -Raw
    $patterns = @(".ai-rules", ".cursor", "CLAUDE.md", "AGENTS.md")
    $ignoredFiles = @()
    foreach ($pattern in $patterns) {
        if ($gitignore -match [regex]::Escape($pattern)) {
            $ignoredFiles += $pattern
        }
    }
    if ($ignoredFiles.Count -gt 0) {
        Write-Warn "Les patterns suivants sont dans .gitignore et empêchent de commit les règles :"
        foreach ($f in $ignoredFiles) {
            Write-Host "    $f" -ForegroundColor Yellow
        }
        Write-Warn "Retire-les manuellement si tu veux versionner les règles."
    } else {
        Write-Ok ".gitignore OK"
    }
} else {
    Write-Ok "Pas de .gitignore (les règles seront versionnées)"
}

# Message final
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "   Installation terminée ✓" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaines étapes :" -ForegroundColor White
Write-Host ""
Write-Host "  1. Ouvre CLAUDE.md et remplis les sections 'Contexte du projet'" -ForegroundColor White
Write-Host "     et 'Règles spécifiques à ce projet'." -ForegroundColor White
Write-Host ""
Write-Host "  2. Commit les fichiers :" -ForegroundColor White
Write-Host "       git add .ai-rules/ .cursor/ CLAUDE.md AGENTS.md" -ForegroundColor Gray
Write-Host "       git commit -m `"chore: add GDM AI rules`"" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Vérifie que ça marche :" -ForegroundColor White
Write-Host "     - Avec Claude Code : lance 'claude' et demande" -ForegroundColor White
Write-Host "       'Quelles sont les règles GDM ?'" -ForegroundColor White
Write-Host "     - Avec Cursor : Cmd/Ctrl+L et même question" -ForegroundColor White
Write-Host "     - Avec Codex : ouvre le repo et pose la même question" -ForegroundColor White
Write-Host ""
Write-Host "Pour mettre à jour les règles plus tard :" -ForegroundColor White
Write-Host "  irm https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.ps1 | iex" -ForegroundColor Gray
Write-Host ""
