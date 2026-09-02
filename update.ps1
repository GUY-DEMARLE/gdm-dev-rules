# update.ps1 — Mise à jour des règles IA GDM dans un repo existant
#
# Met à jour les fichiers de règles SANS toucher aux sections personnalisées
# de CLAUDE.md (contexte du projet, règles spécifiques).
#
# Usage depuis n'importe quel repo GDM :
#   cd C:\chemin\vers\ton\repo
#   irm https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.ps1 | iex

param(
    [string]$RepoUrl = "https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/templates",
    [string]$DocsApiUrl = "https://api.github.com/repos/GUY-DEMARLE/gdm-dev-rules/contents/templates/docs-rules?ref=main",
    [string]$WorkflowUrl = "https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/.github/workflows/security-oss.yml"
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

        # Télécharger le nouveau template et réinjecter la section projet préservée
        $newTemplate = Invoke-RestMethod -Uri "$RepoUrl/CLAUDE.md"
        $newContent = [regex]::Replace($newTemplate, '## Contexte du projet[\s\S]*$', $projectSection)
        Set-Content -Path "CLAUDE.md" -Value $newContent -NoNewline
        Write-Ok "CLAUDE.md (section projet préservée)"
    } else {
        # Sécurité : on ne touche PAS à un fichier existant dont on ne sait pas
        # isoler la partie projet, pour ne jamais écraser du contenu custom.
        Write-Warn "Section '## Contexte du projet' non détectée dans CLAUDE.md : fichier laissé intact (aucune mise à jour pour éviter d'écraser du contenu)."
    }
} else {
    Invoke-RestMethod -Uri "$RepoUrl/CLAUDE.md" -OutFile "CLAUDE.md"
    Write-Warn "CLAUDE.md créé (n'existait pas), pense à remplir le contexte projet"
}

# Mise à jour de AGENTS.md (avec préservation des sections projet)
Write-Step "Mise à jour de AGENTS.md (préservation du contexte projet)..."

if (Test-Path "AGENTS.md") {
    $existingContent = Get-Content "AGENTS.md" -Raw

    # Extraire les sections personnalisées (entre "## Contexte du projet" et la fin)
    $projectSectionMatch = [regex]::Match($existingContent, '## Contexte du projet[\s\S]*$', 'Multiline')

    if ($projectSectionMatch.Success) {
        $projectSection = $projectSectionMatch.Value

        # Télécharger le nouveau template et réinjecter la section projet préservée
        $newTemplate = Invoke-RestMethod -Uri "$RepoUrl/AGENTS.md"
        $newContent = [regex]::Replace($newTemplate, '## Contexte du projet[\s\S]*$', $projectSection)
        Set-Content -Path "AGENTS.md" -Value $newContent -NoNewline
        Write-Ok "AGENTS.md (section projet préservée)"
    } else {
        # Sécurité : on ne touche PAS à un fichier existant dont on ne sait pas
        # isoler la partie projet, pour ne jamais écraser du contenu custom.
        Write-Warn "Section '## Contexte du projet' non détectée dans AGENTS.md : fichier laissé intact (aucune mise à jour pour éviter d'écraser du contenu)."
    }
} else {
    Invoke-RestMethod -Uri "$RepoUrl/AGENTS.md" -OutFile "AGENTS.md"
    Write-Warn "AGENTS.md créé (n'existait pas), pense à remplir le contexte projet"
}

# Mise à jour de la documentation GDM (docs-rules/) — écrasement complet, source de vérité
Write-Step "Mise à jour de la documentation (docs-rules/)..."
try {
    $docsFiles = Invoke-RestMethod -Uri $DocsApiUrl -Headers @{ "User-Agent" = "gdm-dev-rules-updater" }
    if (-not (Test-Path "docs-rules")) {
        New-Item -ItemType Directory -Path "docs-rules" -Force | Out-Null
    }
    foreach ($docFile in $docsFiles) {
        if ($docFile.type -eq "file") {
            Invoke-RestMethod -Uri $docFile.download_url -OutFile "docs-rules/$($docFile.name)"
            Write-Ok "docs-rules/$($docFile.name)"
        }
    }
} catch {
    Write-Warn "Impossible de mettre à jour docs-rules/ : $($_.Exception.Message)"
}

# Mise à jour du design system IA GDM (system-design/) — écrasement complet,
# c'est une source de vérité : le kit ne se modifie pas dans les applications.
# La liste des fichiers vient de MANIFEST.txt (le dossier a des sous-dossiers,
# et raw.githubusercontent n'a pas la limite de 60 req/h de l'API GitHub).
Write-Step "Mise à jour du design system (system-design/)..."
$sdBase = "$RepoUrl/system-design"
$prevProgress = $ProgressPreference
$ProgressPreference = "SilentlyContinue"
try {
    $manifest = Invoke-RestMethod -Uri "$sdBase/MANIFEST.txt"
    $sdFiles = $manifest -split "`n" |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" -and -not $_.StartsWith("#") }
    if (-not $sdFiles) { throw "MANIFEST.txt vide ou illisible" }
    foreach ($rel in $sdFiles) {
        $target = "system-design/$rel"
        $targetDir = Split-Path -Parent $target
        if ($targetDir -and -not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        # Invoke-WebRequest et pas Invoke-RestMethod : le kit contient un PNG,
        # il faut une écriture binaire fidèle.
        Invoke-WebRequest -Uri "$sdBase/$rel" -OutFile $target -UseBasicParsing
        Write-Ok $target
    }
} catch {
    Write-Warn "Impossible de mettre à jour system-design/ : $($_.Exception.Message)"
    Write-Warn "Le reste des règles est à jour ; tu peux relancer plus tard."
} finally {
    $ProgressPreference = $prevProgress
}

# Mise à jour du workflow GitHub Actions Security OSS (écrasement complet, source de vérité)
Write-Step "Mise à jour de .github/workflows/security-oss.yml..."
try {
    if (-not (Test-Path ".github/workflows")) {
        New-Item -ItemType Directory -Path ".github/workflows" -Force | Out-Null
    }
    Invoke-RestMethod -Uri $WorkflowUrl -OutFile ".github/workflows/security-oss.yml"
    Write-Ok ".github/workflows/security-oss.yml"
} catch {
    Write-Warn "Impossible de mettre à jour le workflow security-oss : $($_.Exception.Message)"
}

# Afficher le diff Git
# On bascule temporairement sur "Continue" : sous PowerShell 5.1, un warning git
# sur stderr (ex. "LF will be replaced by CRLF") serait promu en erreur terminante
# avec ErrorActionPreference="Stop" et ferait planter le script ici.
Write-Step "Changements détectés :"
Write-Host ""
$ErrorActionPreference = "Continue"
git diff --stat .ai-rules/ .cursor/ CLAUDE.md AGENTS.md docs-rules/ system-design/ .github/ 2>$null
$ErrorActionPreference = "Stop"
Write-Host ""

# Message final
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "   Mise à jour terminée ✓" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaines étapes :" -ForegroundColor White
Write-Host ""
Write-Host "  1. Vérifie le diff avec :" -ForegroundColor White
Write-Host "       git diff .ai-rules/ .cursor/ CLAUDE.md AGENTS.md docs-rules/ system-design/ .github/" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Si OK, commit :" -ForegroundColor White
Write-Host "       git add .ai-rules/ .cursor/ CLAUDE.md AGENTS.md docs-rules/ system-design/ .github/" -ForegroundColor Gray
Write-Host "       git commit -m `"chore: update GDM AI rules`"" -ForegroundColor Gray
Write-Host ""
