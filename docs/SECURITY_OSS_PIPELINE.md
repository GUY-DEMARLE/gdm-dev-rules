# Pipeline sécurité OSS — gitleaks + semgrep + osv + zap + supabomb

Ce document explique le rôle de chaque outil du pipeline open source proposé dans `templates/.github/workflows/security-oss.yml`.

## Installation rapide dans un repo projet

### Bash

```bash
mkdir -p .github/workflows
curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/templates/.github/workflows/security-oss.yml -o .github/workflows/security-oss.yml
```

### PowerShell

```powershell
New-Item -ItemType Directory -Path ".github/workflows" -Force | Out-Null
Invoke-WebRequest https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/templates/.github/workflows/security-oss.yml -OutFile .github/workflows/security-oss.yml
```

Puis configurer la variable GitHub :

- `SECURITY_TARGET_URL` (URL de preview/prod à auditer)

## Mise en place dans GitHub (pas à pas)

### 1) Commit et push dans ton repo projet

```bash
git add .github/workflows/security-oss.yml
git commit -m "chore(security): add OSS security pipeline"
git push
```

### 2) Ajouter la variable dans GitHub

- Repo GitHub -> `Settings` -> `Secrets and variables` -> `Actions` -> `Variables`
- Créer `SECURITY_TARGET_URL`
- Exemple de valeur : `https://app.guydemarle.com`

### 3) Lancer le workflow manuellement (premier test)

- Ouvrir l'onglet `Actions`
- Ouvrir le workflow `Security OSS`
- Cliquer `Run workflow`
- Optionnel : renseigner `target_url` si tu veux surcharger temporairement `SECURITY_TARGET_URL`

### 4) Vérifier ce qui doit apparaître

- Sur PR : jobs bloquants
  - `PR Security - Gitleaks + Semgrep`
  - `PR Security - OSV Scanner`
- En manuel/planifié : job non bloquant
  - `Scheduled Audit - ZAP + Supabomb`

### 5) Récupérer les rapports d'audit

- Ouvrir le run du job `Scheduled Audit - ZAP + Supabomb`
- Télécharger l'artefact `security-audit-reports`
- Fichiers attendus : `zap-report.json`, `zap-report.md`, `zap-report.html`, `supabomb-report.txt`

## Objectif du pipeline

Couverture en profondeur :

1. Empêcher l'introduction de secrets
2. Détecter les failles dans le code
3. Détecter les dépendances vulnérables
4. Scanner l'app déployée comme un attaquant
5. Auditer la surface exposée Supabase

## Outils et rôle exact

### 1) gitleaks (PR bloquant)

- **But** : détecter secrets et credentials dans le code/historique Git.
- **Détecte** : clés API, tokens cloud, PAT GitHub, mots de passe hardcodés, etc.
- **Pourquoi bloquant en PR** : une fuite doit être stoppée avant merge.
- **Limite** : faux positifs possibles ; nécessite revue humaine.

### 2) semgrep (PR bloquant)

- **But** : SAST (analyse statique de sécurité du code).
- **Détecte** : patterns dangereux (validation manquante, injections, pratiques à risque, etc.).
- **Pourquoi bloquant en PR** : éviter de merger une faille évidente.
- **Limite** : dépend du ruleset ; les règles doivent évoluer avec la stack.

### 3) osv-scanner (PR bloquant)

- **But** : détecter les vulnérabilités connues dans les dépendances.
- **Détecte** : dépendances lockfiles/manifests exposées à CVE/OSV.
- **Pourquoi bloquant en PR** : empêcher l'ajout de dépendances connues vulnérables.
- **Limite** : ne détecte pas les failles métier de ton code.

### 4) OWASP ZAP baseline (planifié non bloquant)

- **But** : DAST léger sur app déployée (scan HTTP externe).
- **Détecte** : headers manquants, routes exposées, signaux de config faible.
- **Pourquoi non bloquant** : scan périodique de surveillance ; résultats en rapports.
- **Limite** : baseline != pentest complet ; complète mais ne remplace pas un audit humain.

### 5) supabomb (planifié non bloquant)

- **But** : découverte de surface exposée pour apps liées à Supabase.
- **Détecte** : endpoints/fonctions accessibles, signaux d'exposition.
- **Pourquoi non bloquant** : outil d'audit périodique et de triage.
- **Limite** : nécessite vérification manuelle auth/validation/rate-limit/RLS.

## Stratégie recommandée

- **PR (bloquant)** : gitleaks + semgrep + osv-scanner
- **Hebdo (non bloquant + rapports)** : zap baseline + supabomb
- **Mensuel/trimestriel** : revue manuelle des rapports et plan de remédiation

## Variable GitHub requise

Le job planifié utilise :

- `SECURITY_TARGET_URL` : URL de l'app à auditer (preview ou prod)

Exemple :

`https://app.guydemarle.com`

## Artefacts produits

Le job planifié exporte :

- `zap-report.json`
- `zap-report.md`
- `zap-report.html`
- `supabomb-report.txt`

Ces artefacts servent de base de revue sécurité périodique.
