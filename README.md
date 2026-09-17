# gdm-dev-rules

Règles de développement et de sécurité pour les projets Guy Demarle, à charger automatiquement par Claude Code, Cursor et Codex sur chaque repo.

## Pour quoi faire

Quand tu codes avec Claude Code, Cursor ou Codex, l'IA suit naturellement nos règles GDM :

- Pas de secret en dur dans le code
- Pas de variable `VITE_*` qui contient une clé secrète
- Architecture front → back → services tiers respectée
- RLS Supabase activée dès la création des tables
- Conventions de nommage respectées (branches, commits, repos)

Sans ces fichiers, l'IA répond "selon les habitudes générales du web" — qui ne sont pas toujours alignées avec nos contraintes (incidents Safercy de mai 2026, ban GCP, etc.).

## Installation dans un nouveau repo

Une seule commande à lancer depuis la racine du repo, après le `git init` :

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/install.ps1 | iex
```

### Mac / Linux (bash)

```bash
curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/install.sh | bash
```

Le script télécharge les fichiers et les place aux bons endroits :

```
ton-repo/
├── .ai-rules/
│   └── RULES.md              ← Règles condensées (1 page)
├── .cursor/
│   └── rules/
│       └── gdm-rules.mdc     ← Lu automatiquement par Cursor
├── .github/
│   └── workflows/
│       └── security-oss.yml  ← Pipeline sécurité OSS (obligatoire)
├── docs-rules/               ← Doc GDM détaillée (setup, archi, sécu, hébergement)
├── system-design/            ← Design system GDM — interface (voir plus bas)
│   ├── AGENTS.md             ← Le mode d'emploi pour l'IA qui produit l'UI
│   ├── README.md             ← La direction artistique et ses arbitrages
│   ├── kit/                  ← Jetons, composants, mascotte, marque, demo.html
│   └── outils/               ← verifier-interface.mjs (contrôle automatique)
├── CLAUDE.md                 ← Lu automatiquement par Claude Code
└── AGENTS.md                 ← Lu automatiquement par Codex
```

Le script vérifie aussi que ton `.gitignore` n'ignore pas ces fichiers.

### Étape suivante : personnaliser CLAUDE.md

Ouvre `CLAUDE.md` et remplis les sections en commentaire :

```markdown
## Contexte du projet

- Type d'app : interne (dashboard de suivi commandes)
- Stack : Next.js fullstack + Supabase + Render (workers async)
- Services tiers : Supabase, Stripe, Gemini
- Particularités : utilise Inngest pour les jobs cron

## Règles spécifiques à ce projet

- Tous les endpoints de paiement doivent avoir des tests E2E Playwright
- La table `orders` ne doit jamais être modifiée directement, passer par la fonction `update_order` qui logge les changements
```

C'est ce qui aide l'IA à donner des réponses adaptées **à ton projet**, en plus des règles génériques GDM.

### Commit

```bash
git add .ai-rules/ .cursor/ CLAUDE.md AGENTS.md docs-rules/ system-design/ .github/
git commit -m "chore: add GDM AI rules"
```

---

## Mise à jour des règles dans un repo existant

Quand les règles centrales évoluent (nouvelle règle de sécu, mise à jour d'un pattern, etc.), tu peux les mettre à jour dans n'importe quel repo en une commande.

### Windows

```powershell
irm https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.ps1 | iex
```

### Mac / Linux

```bash
curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.sh | bash
```

**Bon à savoir** : `update` préserve les sections "Contexte du projet" et "Règles spécifiques" de `CLAUDE.md` et `AGENTS.md` que tu as personnalisées. Tu ne perds pas tes ajouts.

### Mise à jour de tous tes repos en batch

```powershell
# Windows
$repos = @(
    "C:\Users\$env:USERNAME\Travail\gestionnaire-kit",
    "C:\Users\$env:USERNAME\Travail\simu-recrutement",
    "C:\Users\$env:USERNAME\Travail\kpi"
)

foreach ($repo in $repos) {
    Write-Host "`n=== $repo ===" -ForegroundColor Cyan
    cd $repo
    irm https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.ps1 | iex
    git add .ai-rules/ .cursor/ CLAUDE.md AGENTS.md docs-rules/ system-design/ .github/
    git commit -m "chore: update GDM AI rules"
    git push
}
```

```bash
# Mac/Linux
repos=(
    "$HOME/Travail/gestionnaire-kit"
    "$HOME/Travail/simu-recrutement"
    "$HOME/Travail/kpi"
)

for repo in "${repos[@]}"; do
    echo -e "\n=== $repo ==="
    cd "$repo"
    curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.sh | bash
    git add .ai-rules/ .cursor/ CLAUDE.md AGENTS.md docs-rules/ system-design/ .github/
    git commit -m "chore: update GDM AI rules"
    git push
done
```

---

## Design system GDM (interface)

Depuis la version 1.3 du design system, `install` et `update` posent aussi **`system-design/` à la racine de chaque app Guy Demarle**, à côté des règles dev et sécu. C'est la charte d'interface commune à tous les outils du réseau : jetons, composants, mascotte, marque.

```
system-design/
├── AGENTS.md                  ← Le point d'entrée pour une IA : règles, interdits, checklist
├── README.md                  ← La direction artistique et le pourquoi de chaque arbitrage
├── kit/
│   ├── gd-ai-tokens.css       ← Les jetons (palette claire, typo, rayons, ombres…)
│   ├── gd-ai-components.css   ← Boutons, champs, cartes, bulles, pastilles, alertes, lockup
│   ├── gd-ai-mascotte.js      ← La mascotte animée, élément natif <gd-mascotte>
│   ├── gd-ai-mascotte.svg     ← Version statique (impression, e-mail, sans JS)
│   ├── gd-ai-marque-o.png     ← La marque O du lockup
│   └── demo.html              ← Le banc d'essai : tout le kit à l'écran (double-clic)
└── outils/
    └── verifier-interface.mjs ← Contrôle automatique des règles lisibles dans le code
```

Les `CLAUDE.md`, `AGENTS.md` et règles Cursor installés pointent dessus : l'IA lit `system-design/AGENTS.md` avant de produire la moindre interface.

**Le dossier est écrasé à chaque `update`** — c'est une source de vérité, comme `.ai-rules/RULES.md`. Ne le modifie pas dans une app : une valeur qui ne convient pas est une évolution de la charte, elle se fait en PR sur ce repo (`templates/system-design/`).

Côté app, il reste une chose à faire à la main : **servir les fichiers du kit depuis le front** (par exemple `public/gd-ai/`), puis dans le `<head>` :

```html
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/gd-ai/gd-ai-tokens.css">
<link rel="stylesheet" href="/gd-ai/gd-ai-components.css">
<script src="/gd-ai/gd-ai-mascotte.js" defer></script>
```

Pour voir à quoi ça ressemble sans rien installer : ouvre `templates/system-design/kit/demo.html` par double-clic.

---

## Vérification que ça marche

### Avec Claude Code (terminal)

```bash
cd ton-repo
claude
```

Dans la conversation, tape :

> Quelles sont les règles de sécurité GDM que tu dois respecter ?

Claude doit te répondre en listant les 6 règles. Si non, vérifie que `CLAUDE.md` est bien à la racine du repo.

### Avec Cursor

Ouvre une nouvelle conversation Cursor (Cmd/Ctrl+L) et tape :

> Quelles sont les règles de sécurité GDM que tu dois respecter ?

Pareil, Cursor doit lister les règles. Vérifie aussi que dans Cursor → Settings → Rules → Project Rules, tu vois bien `gdm-rules` dans la liste.

### Avec Codex

Lance Codex dans le repo puis tape :

> Quelles sont les règles de sécurité GDM que tu dois respecter ?

Codex doit aussi lister les règles. Si non, vérifie que `AGENTS.md` est bien à la racine du repo.

### Test pratique

Demande à l'IA de générer du code qui violerait une règle (volontairement) :

> Génère-moi un composant React qui appelle l'API Gemini directement avec ma clé d'API.

L'IA doit refuser et proposer l'architecture proxy à la place. Si elle le fait sans broncher, les règles ne sont pas chargées correctement.

---

## Pipeline sécurité OSS (obligatoire)

**Ce pipeline n'est pas optionnel.** `RULES.md` § 2.6 (« Audit periodique et monitoring (obligatoire) ») impose : Gitleaks / Semgrep / OSV bloquants avant chaque merge, et audit complet chaque lundi. `install` et `update` le posent donc automatiquement dans `.github/workflows/security-oss.yml`, sur les quatre scripts (Windows et Mac/Linux).

Il contient :

- Jobs PR bloquants : `gitleaks`, `semgrep`, `osv-scanner`
- Job planifié non bloquant : `zap baseline` + `supabomb` avec artefacts, rapports en Slack et en artifacts GitHub Actions

**Une chose reste à faire à la main dans chaque app** : configurer la variable GitHub `SECURITY_TARGET_URL` (l'URL à auditer en planifié). Sans elle, les jobs ZAP et Supabomb sont sautés — le reste du pipeline tourne quand même.

Si jamais tu dois le reposer seul (le script a échoué sur cette étape, par exemple) :

```bash
mkdir -p .github/workflows
curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/.github/workflows/security-oss.yml -o .github/workflows/security-oss.yml
```

```powershell
New-Item -ItemType Directory -Path ".github/workflows" -Force | Out-Null
Invoke-WebRequest https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/.github/workflows/security-oss.yml -OutFile .github/workflows/security-oss.yml
```

> **Pourquoi une copie complète et pas un caller.** Chaque app reçoit les ~900 lignes du workflow, et c'est un choix assumé. Un caller `workflow_call` vers ce dépôt ferait tourner du code central dans la CI de chaque app, **avec les secrets de l'app**, et toute modification poussée ici s'exécuterait immédiatement partout. On préfère la copie : chaque app est autonome, et une évolution du pipeline se relit app par app.
>
> La contrepartie est qu'il faut **relancer `update` sur toutes les apps** à chaque évolution du pipeline, sans quoi les copies dérivent.
>
> ⚠️ `security-oss.yml` n'a d'ailleurs **pas** de déclencheur `workflow_call` : un caller vers lui échouerait avec « invalid workflow file ». Si une IA propose de remplacer la copie par un caller, c'est une régression de sécurité — le pipeline cesserait de bloquer les PR.

Explications détaillées + guide pas à pas (ajout au repo, variable GitHub, lancement manuel, récupération des rapports) :
`templates/docs-rules/SECURITY_OSS_PIPELINE.md` (distribué dans les projets sous `docs-rules/`)

---

## Pour les contributeurs (modification des règles)

Le contenu source unique est dans `templates/.ai-rules/RULES.md`. Quand tu modifies ce fichier :

1. Crée une PR sur ce repo
2. Une fois mergée, les règles sont disponibles via les scripts d'install/update
3. Les autres devs peuvent lancer `update.ps1` ou `update.sh` sur leurs projets pour récupérer la mise à jour

Les fichiers `templates/CLAUDE.md`, `templates/AGENTS.md` et `templates/.cursor/rules/gdm-rules.mdc` sont des fichiers d'amorçage minimalistes qui pointent vers `.ai-rules/RULES.md`. Tu n'as normalement pas besoin de les modifier sauf changement de structure.

### Modifier le design system

La source est `templates/system-design/`. Même circuit : PR sur ce repo, puis `update` dans les apps.

⚠️ **Si tu ajoutes ou supprimes un fichier du design system, mets `templates/system-design/MANIFEST.txt` à jour.** C'est cette liste que lisent `install` et `update` pour savoir quoi télécharger — un fichier absent du manifeste ne partira jamais dans les applications. (Le manifeste sert aussi à éviter l'API GitHub, limitée à 60 requêtes/heure sans token, et permet des sous-dossiers, ce que la liste dynamique de `docs-rules/` ne sait pas faire.)

---

## Structure du repo

```
gdm-dev-rules/
├── README.md                    ← Ce fichier
├── install.ps1                  ← Script Windows install
├── install.sh                   ← Script Mac/Linux install
├── update.ps1                   ← Script Windows update
├── update.sh                    ← Script Mac/Linux update
├── .github/
│   └── workflows/
│       └── security-oss.yml     ← Le pipeline, distribué tel quel dans les apps
└── templates/
    ├── .ai-rules/
    │   └── RULES.md             ← LA source de vérité (dev + sécu)
    ├── .cursor/
    │   └── rules/
    │       └── gdm-rules.mdc
    ├── docs-rules/              ← Doc détaillée (liste dynamique via l'API GitHub)
    ├── system-design/           ← LA source de vérité (interface)
    │   ├── MANIFEST.txt         ← Liste des fichiers à distribuer — à tenir à jour
    │   ├── AGENTS.md
    │   ├── README.md
    │   ├── kit/
    │   └── outils/
    ├── CLAUDE.md
    └── AGENTS.md
```

---

## FAQ

**Pourquoi 4 fichiers d'IA et pas un seul ?**

Parce que Claude Code, Cursor et Codex lisent automatiquement leurs fichiers respectifs. Avoir un seul fichier ne marcherait pas — l'IA ne saurait pas qu'il existe. Solution : des fichiers d'amorçage minimalistes (`CLAUDE.md`, `AGENTS.md`, `.cursor/rules/gdm-rules.mdc`) qui pointent tous vers `.ai-rules/RULES.md` (la source unique).

**Est-ce que ça remplace gitleaks et les autres protections ?**

Non. C'est de la prévention en amont. Si l'IA fait une erreur ou si tu codes à la main, gitleaks reste indispensable comme garde-fou. C'est de la défense en profondeur.

**Pourquoi un repo public ?**

Le repo `gdm-dev-rules` peut être public (il ne contient aucun secret, juste des règles génériques). Ça simplifie les `curl` / `irm` qui sinon nécessiteraient un token GitHub. Mais c'est un choix d'org — si tu veux le garder privé, il faut adapter les scripts pour authentifier les téléchargements.

**Est-ce que les prestataires externes verront ces règles ?**

Oui, dès qu'ils clonent le repo. C'est une bonne chose : ça leur communique automatiquement les standards GDM sans qu'on ait à leur envoyer un PDF en pièce jointe. Leur IA suivra les mêmes règles que la nôtre.

**Comment je sais si un projet existant utilise une vieille version des règles ?**

Tu peux comparer le contenu de `.ai-rules/RULES.md` du repo avec celui du repo central. Plus simple : lance `update.ps1` ou `update.sh`, qui te montre le diff Git après mise à jour.
