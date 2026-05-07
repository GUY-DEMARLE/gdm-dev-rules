# Setup Projet — Dev GDM

**Quand utiliser ce doc** : à chaque création d'un nouveau projet GDM, ou pour mettre à jour un projet existant aux standards GDM.
**Durée** : ~25 minutes pour un nouveau projet, ~10 minutes pour une mise à jour.
**Prérequis** : avoir suivi `SETUP_MACHINE.md` (gitleaks, npm, comptes Vercel/Render/Supabase OK).

À la fin de ce doc, ton projet a tous les garde-fous de sécurité GDM en place : pas de secret possible dans Git, branches protégées, RLS Supabase, et architecture front/back propre.

---

## Vue d'ensemble — Ce qu'on va faire

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   1. Création du repo GitHub                            │
│   2. Installation des règles IA GDM                     │
│   3. Configuration .gitignore                           │
│   4. Fichier .env.example                               │
│   5. Installation Husky + hook gitleaks                 │
│   6. Workflow GitHub Actions (CI sécurité)              │
│   7. Branch protection (main, staging)                  │
│   8. GitHub Secret Scanning                             │
│   9. Setup Supabase (RLS dès le début)                  │
│   10. Setup Vercel et/ou Render                         │
│   11. Test final : tentative de commit piégée           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

L'ordre compte : on configure les garde-fous **avant** d'écrire du code, pour qu'aucun secret n'ait l'occasion de passer à travers.

---

## 1. Création du repo GitHub

### Convention de nommage

```
gdm-<type>-<nom>
```

Exemples :
- `gdm-app-catalogue` — App client-facing
- `gdm-api-catalogue` — API backend (si séparée du front)
- `gdm-app-dashboard` — Dashboard interne
- `gdm-lib-shared` — Librairie partagée

### Création

1. Va sur https://github.com/organizations/GUY-DEMARLE/repositories/new
2. **Repository name** : `gdm-<type>-<nom>` (cf. convention)
3. **Description** : courte phrase décrivant l'app
4. **Privacy** : **Private** (par défaut sur tous les projets GDM, sauf décision explicite contraire)
5. **Initialize this repository with** : ne rien cocher (on va clone et init en local pour avoir la main sur les premiers commits)
6. Bouton "Create repository"

### Clone en local

```bash
cd C:\Users\TonNom\Travail
git clone git@github.com:GUY-DEMARLE/gdm-app-exemple.git
cd gdm-app-exemple
```

Si tu as configuré le SSH avec un host alias (cf. doc référentiel GitHub GDM), utilise `git@github-gdm:GUY-DEMARLE/gdm-app-exemple.git` à la place.

---

## 2. Installation des règles IA GDM

**Pourquoi** : ces fichiers permettent à Claude Code, Cursor et Codex de respecter automatiquement les règles GDM (sécurité, stack, conventions, patterns). Sans eux, l'IA répond "selon les habitudes générales du web", qui ne sont pas toujours alignées avec nos contraintes — et c'est exactement comme ça que les incidents Safercy de mai 2026 sont arrivés (clé Gemini dans `VITE_*`, fallback "mode dev" qui exposait le secret, etc.).

### Installation automatique

Une seule commande à lancer depuis la racine du repo (juste après le clone). Le script télécharge les fichiers de règles depuis le repo central `gdm-dev-rules` et les place aux bons endroits.

**Windows (PowerShell)** :

```powershell
irm https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/install.ps1 | iex
```

**Mac / Linux (bash)** :

```bash
curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/install.sh | bash
```

Le script crée 4 fichiers dans ton repo :

```
ton-repo/
├── .ai-rules/
│   └── RULES.md              ← Règles condensées GDM (source unique)
├── .cursor/
│   └── rules/
│       └── gdm-rules.mdc     ← Lu automatiquement par Cursor
├── CLAUDE.md                 ← Lu automatiquement par Claude Code
└── AGENTS.md                 ← Lu automatiquement par Codex
```

### Personnaliser CLAUDE.md

Ouvre `CLAUDE.md` à la racine et remplis les sections en commentaire :

```markdown
## Contexte du projet

- Type d'app : interne (dashboard de suivi commandes)
- Stack : React/Vite + Supabase + Render Node Express
- Services tiers : Supabase Auth, Brevo (email), Stripe
- Particularités : utilise Inngest pour les jobs cron

## Règles spécifiques à ce projet

- Tous les endpoints de paiement doivent avoir des tests E2E Playwright
- La table `orders` ne doit jamais être modifiée directement, passer par
  la fonction `update_order` qui logge les changements
- Les emails partent via la edge function `send-email` qui exige un user
  authentifié (cf. incident Safercy mai 2026)
```

C'est ce qui aide l'IA à donner des réponses adaptées **à ton projet**, pas juste les règles GDM génériques. Sans cette section remplie, l'IA connaît les règles globales mais ignore les particularités du projet.

### Vérification

Ouvre Claude Code, Cursor ou Codex sur ton repo et tape :

> Quelles sont les règles de sécurité GDM que tu dois respecter ?

L'IA doit te répondre en listant les 6 règles (gitleaks, RLS Supabase, branch protection, variables d'env, préfixes VITE_*, architecture front/back). Si elle dit qu'elle n'a pas accès aux règles, vérifie que les 4 fichiers sont bien à la racine du repo.

### Mise à jour des règles plus tard

Quand les règles GDM évoluent (nouvelle règle de sécu, changement de stack, etc.), tu mets à jour les règles dans ton repo en une commande :

**Windows** :
```powershell
irm https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.ps1 | iex
```

**Mac / Linux** :
```bash
curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/update.sh | bash
```

Le script préserve les sections "Contexte du projet" et "Règles spécifiques" de `CLAUDE.md` et `AGENTS.md` que tu as personnalisées. Tu ne perds pas tes ajouts.

---

## 3. .gitignore standard

À ce stade, ton dossier est vide. **Avant d'initialiser quoi que ce soit d'autre**, crée le `.gitignore` pour ne jamais versionner accidentellement un secret.

Crée un fichier `.gitignore` à la racine avec ce contenu :

```gitignore
# Dependencies
node_modules/
.pnp
.pnp.js

# Build output
.next/
out/
build/
dist/

# Env files — TOUS sauf .env.example
.env
.env.local
.env.*.local
.env.production
.env.development
.env.staging

# IDE
.vscode/settings.json
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
*.log

# Coverage
coverage/

# Misc
.cache/
.turbo/
```

### Test que c'est bien pris en compte

```bash
# Crée un faux .env pour tester
echo "FAKE_SECRET=test" > .env
git status
# .env ne doit PAS apparaître dans la liste des fichiers à commiter
rm .env
```

Si `.env` apparaît dans `git status`, le `.gitignore` n'est pas correctement configuré ou pas encore appliqué (vérifie qu'il est bien à la racine, pas dans un sous-dossier).

---

## 4. Fichier .env.example

Ce fichier sert deux buts :
- Documenter les variables d'env nécessaires pour faire tourner l'app
- Permettre à un nouveau dev de copier `.env.example` en `.env.local` et de remplir les valeurs

**Règle absolue** : `.env.example` ne contient **que des placeholders**, jamais de vraie valeur.

Crée un fichier `.env.example` à la racine. Adapte selon ton projet, voici un template :

```bash
# .env.example — Template des variables d'environnement
# Copie ce fichier en .env.local et remplis avec les vraies valeurs.
# Récupère les vraies valeurs via : vercel env pull .env.local

# === Côté Front (peuvent être publiques) ===
VITE_API_URL=https://api.example.com
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here

# === Côté Back (JAMAIS de préfixe VITE_/NEXT_PUBLIC_/REACT_APP_) ===
GEMINI_API_KEY=your-gemini-key-here
STRIPE_SECRET_KEY=sk_live_your_stripe_key_here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-jwt-here
DATABASE_URL=postgresql://user:password@host:5432/db
```

**Le piège à éviter** : ne mets jamais une vraie clé en commentaire dans `.env.example`. Genre :

```bash
# Ancienne clé (à ne plus utiliser) : AIzaSyDaGt24q...    ← ❌ NON
GEMINI_API_KEY=your-gemini-key-here
```

Le commentaire est dans Git, donc la clé est dans Git. Même retirée plus tard, elle reste dans l'historique.

---

## 5. Husky + hook gitleaks pre-commit

**Pourquoi** : Husky permet d'exécuter automatiquement des scripts à des moments précis du workflow Git (avant un commit, avant un push, etc.). On va l'utiliser pour lancer gitleaks **avant** chaque commit. Si gitleaks détecte un secret, le commit est annulé.

### Init du package.json (si pas déjà fait)

```bash
npm init -y
```

### Installation Husky

```bash
npm install --save-dev husky
npx husky init
```

La commande `husky init` :
- Crée un dossier `.husky/`
- Ajoute un script `prepare` dans `package.json`
- Crée un hook par défaut `.husky/pre-commit` (qui contient `npm test` à l'origine)

### Configuration du hook pour gitleaks

Remplace le contenu du hook pre-commit par gitleaks :

```bash
echo "gitleaks protect --staged --verbose" > .husky/pre-commit
```

(Sur Windows, si la commande `echo >` te pose problème, ouvre `.husky/pre-commit` dans VS Code et remplace son contenu manuellement par la ligne ci-dessus.)

### Test que le hook fonctionne

Crée un commit volontairement piégé :

```bash
echo "GEMINI_API_KEY=AIzaSyDaGt24qMlfCXQlYhJSSdsum6FrKTxSLn8" > test_leak.txt
git add test_leak.txt
git commit -m "test"
```

Tu dois voir gitleaks lancer un scan et **bloquer le commit** avec un message d'erreur du type :

```
Finding:     AIzaSyDaGt24qMlfCXQlYhJSSdsum6FrKTxSLn8
RuleID:      gcp-api-key
File:        test_leak.txt
WRN leaks found: 1
```

Le commit échoue. Nettoie :

```bash
rm test_leak.txt
git restore --staged test_leak.txt 2>$null
```

Si le commit **passe** sans erreur, le hook n'est pas correctement installé. Vérifie :
- Le fichier `.husky/pre-commit` existe et contient `gitleaks protect --staged --verbose`
- Sur Mac/Linux : le fichier a les droits d'exécution (`chmod +x .husky/pre-commit`)
- gitleaks est bien dans le PATH (`gitleaks version` doit fonctionner)

---

## 6. Workflow GitHub Actions — CI de sécurité

**Pourquoi** : le hook pre-commit est local à ta machine. Si un dev oublie de l'installer ou le contourne avec `--no-verify`, le secret peut quand même partir sur GitHub. Le workflow CI scanne le repo côté GitHub, c'est la deuxième couche.

### Création du workflow

Crée le fichier `.github/workflows/security.yml` :

```yaml
name: Security

on:
  pull_request:
  push:
    branches: [main, staging, dev]

jobs:
  gitleaks:
    name: Scan secrets (gitleaks)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Récupère tout l'historique pour scanner aussi les vieux commits
      - name: Run gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Test que le workflow se lance

Commit ce fichier et pousse :

```bash
git add .github/workflows/security.yml
git commit -m "chore(security): add gitleaks workflow"
git push
```

Va sur https://github.com/GUY-DEMARLE/gdm-app-exemple/actions et tu dois voir le workflow "Security" en train de tourner ou terminé en succès.

Si tu veux le tester en cas de fuite, tente de pousser le commit piégé de l'étape 5 (avec `--no-verify` pour bypass le hook local) et regarde le workflow Actions s'exécuter et échouer.

---

## 7. Branch protection rules

**Pourquoi** : empêcher tout push direct sur `main` et `staging`. Les modifications passent par PR, avec review et CI qui doivent valider avant merge.

### Configuration sur GitHub

1. Va sur ton repo : https://github.com/GUY-DEMARLE/gdm-app-exemple
2. **Settings** (onglet en haut)
3. **Branches** (menu de gauche, sous "Code and automation")
4. **Branch protection rules** → **Add classic branch protection rule**

### Règle pour `main`

**Branch name pattern** : `main`

Coche les options suivantes :

- ✅ **Require a pull request before merging**
  - Require approvals : `1`
  - Dismiss stale pull request approvals when new commits are pushed
- ✅ **Require status checks to pass before merging**
  - Require branches to be up to date before merging
  - Status checks : tape `Scan secrets (gitleaks)` et sélectionne-le quand il apparaît (le workflow doit avoir tourné au moins une fois pour apparaître ici)
- ✅ **Require conversation resolution before merging**
- ✅ **Do not allow bypassing the above settings**

Bouton **Create** ou **Save changes**.

### Règle pour `staging`

Même chose, branch name pattern : `staging`. Tu peux décocher "Require approvals" si l'équipe est petite (2 devs), mais garde au minimum les status checks et le PR obligatoire.

### Test

Tente de pousser directement sur main :

```bash
git checkout main
echo "test" > test.txt
git add test.txt
git commit -m "test"
git push origin main
```

GitHub doit refuser le push avec un message du type *"protected branch hook declined"*.

---

## 8. GitHub Secret Scanning (optionnel — selon le plan de l'org)

**À quoi ça sert** : système de GitHub qui scanne en continu tes commits et alerte si une clé connue (Stripe, AWS, Google, Anthropic, etc.) est détectée. Vient **en plus** de gitleaks — gitleaks scanne au moment du commit/PR, Secret Scanning scanne en permanence et peut alerter directement le service tiers (ex: Stripe révoque automatiquement une clé détectée).

### Important — Disponibilité

Secret Scanning sur les repos **privés** nécessite **GitHub Advanced Security (GHAS)**, qui est une option **payante** au niveau de l'organisation (environ 50$/mois/développeur sur un plan Enterprise).

Sur les repos **publics**, Secret Scanning est gratuit — mais nous, GDM, on travaille en privé.

### Comment savoir si GHAS est activé chez GDM

Va sur :

```
https://github.com/organizations/GUY-DEMARLE/settings/security_analysis
```

(Tu dois être admin de l'organisation pour voir cette page. Si tu obtiens un 404 ou un message "you don't have permission", demande à l'admin org.)

Sur cette page, regarde la section **GitHub Advanced Security** :

- Si tu vois un bouton **Enable for all repositories** ou un statut "GHAS enabled on X repositories" → GHAS est dispo, tu peux activer Secret Scanning sur ton repo (suis l'étape "Activation" plus bas).
- Si tu vois un message du type "GitHub Advanced Security is not available on your plan" ou "Upgrade to enable" → GHAS n'est pas activé chez GDM. Tu peux faire une demande à la direction technique pour évaluer la dépense, mais pour l'instant **tu n'as pas accès à Secret Scanning**.

### Si GHAS n'est pas dispo (le cas le plus probable aujourd'hui)

Pas grave — gitleaks (étapes 4 et 5 de ce doc) couvre déjà les commits locaux et les PR sur GitHub. Secret Scanning serait une **troisième couche**, pas la première.

Concrètement, gitleaks attrape :

- Les secrets au moment du commit local (étape 5)
- Les secrets dans les PR avant merge (étape 6)
- Les secrets dans tout l'historique lors d'un audit ponctuel (`gitleaks detect`)

Ce que Secret Scanning attraperait en plus :

- Les secrets dans des commits déjà mergés (gitleaks aussi peut, via un audit régulier)
- L'alerte automatique au service tiers pour révocation rapide (gitleaks ne fait pas ça)
- La **Push Protection** : un blocage côté GitHub si un push contient un secret connu, même si gitleaks local n'est pas installé

C'est utile, mais pas indispensable si l'équipe respecte les autres règles. Note dans le README du projet que Secret Scanning n'est pas activé.

### Activation — Si GHAS est dispo

1. Va sur ton repo : `https://github.com/GUY-DEMARLE/gdm-app-exemple`
2. **Settings** (onglet en haut)
3. **Code security** dans le menu de gauche
4. Tu devrais voir une section **Secret scanning** (en plus de Dependabot)
5. **Enable** sur :
   - **Secret scanning** : active la détection
   - **Push protection** : bloque les pushs qui contiennent un secret connu (ceinture + bretelles avec gitleaks)

### Si tu ne vois que les options Dependabot dans Code security

C'est le signal que **GHAS n'est pas activé pour ce repo**. Confirme via l'étape "Comment savoir si GHAS est activé chez GDM" plus haut.

C'est un cas normal — la majorité des PME en France n'ont pas GHAS, et ce n'est pas un blocage tant que gitleaks tourne.

---

## 9. Setup Supabase (RLS dès le début)

**À faire uniquement si l'app utilise Supabase.** Si pas de Supabase, passe à l'étape 10.

### Création du projet Supabase

1. Va sur https://supabase.com/dashboard
2. **New project**
3. **Organization** : sélectionne celle de GDM (Guy Demarle)
4. **Name** : nom du projet, en cohérence avec le repo (ex: `gdm-app-catalogue`)
5. **Database password** : génère un mot de passe fort, **note-le immédiatement dans le password manager d'équipe** (1Password, Bitwarden, etc.). Ce password sert pour les connexions directes PostgreSQL, pas pour l'auth des utilisateurs.
6. **Region** : `West EU (Paris)` ou la région la plus proche des utilisateurs
7. **Pricing plan** : Free pour démarrer, Pro si besoin (à valider avec la direction)

### Lien du projet local au projet Supabase

Dans ton repo :

```bash
supabase init
# Crée un dossier supabase/ avec la config locale

supabase link --project-ref <ref-du-projet>
# Le project ref est dans l'URL Supabase : https://supabase.com/dashboard/project/<ref-du-projet>
```

Va te demander le password DB que tu viens de noter.

### Première migration avec RLS active

Crée une première migration :

```bash
supabase migration new init_with_rls
```

Édite le fichier généré dans `supabase/migrations/` :

```sql
-- supabase/migrations/<timestamp>_init_with_rls.sql

-- Exemple : table profiles
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  created_at timestamptz DEFAULT now()
);

-- ✓ RLS activée IMMÉDIATEMENT, pas en deuxième temps
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy : un utilisateur ne voit que son propre profil
CREATE POLICY "users_read_own_profile" ON public.profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Policy : un utilisateur peut modifier son propre profil
CREATE POLICY "users_update_own_profile" ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);
```

**La règle absolue** : à chaque fois que tu créés une table dans une migration, ajoute immédiatement après `ALTER TABLE x ENABLE ROW LEVEL SECURITY` et au moins une policy. Ne reporte jamais à plus tard.

### Vérification que toutes les tables ont RLS

Crée le fichier `scripts/check-rls.sql` :

```sql
-- Échoue si une table publique n'a pas RLS activée
DO $$
DECLARE
  unprotected text[];
BEGIN
  SELECT array_agg(tablename) INTO unprotected
  FROM pg_tables
  WHERE schemaname = 'public'
    AND rowsecurity = false;

  IF array_length(unprotected, 1) > 0 THEN
    RAISE EXCEPTION 'Tables sans RLS détectées : %', unprotected;
  END IF;
  RAISE NOTICE 'Toutes les tables ont RLS activée ✓';
END $$;
```

À lancer après chaque migration via :

```bash
supabase db remote run --file scripts/check-rls.sql
```

Ou intégré au workflow CI (cf. évolution future de `security.yml`).

### Audit ponctuel du dashboard

Va sur https://supabase.com/dashboard/project/<ref>/auth/policies. Toute table avec une icône orange "RLS disabled" est à corriger immédiatement.

---

## 10. Setup Vercel et/ou Render

### Si tu déploies un front sur Vercel

1. Va sur https://vercel.com/new
2. **Import Git Repository** → sélectionne ton repo `gdm-app-exemple`
3. Vercel détecte automatiquement le framework (Next.js, Vite, etc.)
4. **Environment Variables** : ajoute toutes les variables d'env nécessaires (cf. `.env.example`)
   - **Production** : variables pour le déploiement de `main`
   - **Preview** : variables pour les PR (souvent identiques à production, parfois variantes)
   - **Development** : pour `vercel env pull .env.local` côté dev local
5. **Deploy**

#### Sync des variables vers ton .env.local

```bash
vercel link
# Te demande de quel projet tu veux tracker les vars

vercel env pull .env.local
# Récupère les variables Production de Vercel dans .env.local
```

À ce stade, tu peux lancer `npm run dev` et l'app fonctionne en local avec les vraies valeurs Vercel.

### Si tu déploies un back sur Render

1. Va sur https://dashboard.render.com/
2. **New +** → **Web Service**
3. **Connect a repository** → sélectionne ton repo
4. **Name** : nom du service (idem repo)
5. **Region** : `Frankfurt` (le plus proche pour la France)
6. **Branch** : `main`
7. **Build command** et **Start command** : selon le langage
   - Node.js : `npm install` / `npm start`
   - Python : `pip install -r requirements.txt` / `uvicorn main:app --host 0.0.0.0 --port 10000`
8. **Environment Variables** : ajoute les variables sensibles ici (clés API tiers, JWT secrets, etc.)
9. **Create Web Service**

#### Sync des variables vers ton .env.local

```bash
render services list
# Identifie l'ID de ton service

render env --service-id <id> > .env.local
# Récupère les variables Render dans .env.local
# (À adapter selon la version actuelle de la CLI Render)
```

### Si tu déploies sur Supabase Edge Functions

Pour un proxy léger côté serveur :

```bash
supabase functions new ma-fonction
# Crée le squelette dans supabase/functions/ma-fonction/

# Définir les secrets côté Supabase (jamais dans le code !)
supabase secrets set GEMINI_API_KEY=AIzaSy... --project-ref <ref>

# Déployer
supabase functions deploy ma-fonction --project-ref <ref>
```

Les secrets définis avec `supabase secrets set` sont accessibles dans la fonction via `Deno.env.get('GEMINI_API_KEY')`. Ils ne sont **jamais** exposés au client.

---

## 11. Test final — Vérifier que tout fonctionne

Lance cette série de tests pour valider que tous les garde-fous sont en place.

### Test 1 — Hook gitleaks

```bash
echo "GEMINI_API_KEY=AIzaSyTestFakeKey1234567890123456789012" > test_leak.txt
git add test_leak.txt
git commit -m "test"
# → Doit échouer
rm test_leak.txt
git restore --staged test_leak.txt 2>$null
```

### Test 2 — Workflow CI

Pousse une branche test, ouvre une PR, vérifie que le workflow "Security" tourne automatiquement et que la PR ne peut pas être mergée si le workflow échoue.

### Test 3 — Branch protection

```bash
git checkout main
echo "test" > test.txt
git add test.txt
git commit -m "test direct push"
git push origin main
# → Doit échouer avec "protected branch"
git restore --staged .
rm test.txt
```

### Test 4 — Supabase RLS (si applicable)

Dans le SQL editor du dashboard Supabase, lance :

```sql
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```

Toutes les tables doivent avoir `rowsecurity = true`.

### Test 5 — .env non versionné

```bash
echo "FAKE=test" > .env
git status
# .env ne doit PAS apparaître
rm .env
```

Si tous les tests passent, ton projet est aux standards GDM. Tu peux commencer à développer.

---

## Récap — Checklist du projet OK

À la fin de ce doc, ton projet doit avoir :

- [x] Repo créé sous `GUY-DEMARLE/gdm-<type>-<nom>` en privé
- [x] Règles IA GDM installées (`.ai-rules/`, `.cursor/`, `CLAUDE.md`, `AGENTS.md`) avec contexte projet rempli
- [x] `.gitignore` standard avec tous les `.env*` exclus
- [x] `.env.example` avec placeholders uniquement
- [x] Husky installé + hook pre-commit gitleaks fonctionnel
- [x] Workflow `.github/workflows/security.yml` qui tourne sur PR/push
- [x] Branch protection sur `main` (et `staging` si applicable)
- [x] GitHub Secret Scanning activé (si dispo)
- [x] Projet Supabase créé avec RLS activée sur toutes les tables (si applicable)
- [x] Projet Vercel/Render configuré avec variables d'env stockées côté plateforme
- [x] Aucun secret jamais commité dans Git

À chaque ajout de fonctionnalité ou de nouvelle table, retourne au doc principal `ARCHITECTURE_SECURITE_GDM.md` Partie 4 pour la checklist quotidienne.

---

## Que faire si quelque chose ne marche pas

**Le hook gitleaks ne se déclenche pas au commit** : vérifie que `.husky/pre-commit` existe et contient `gitleaks protect --staged --verbose`. Sur Mac/Linux, `chmod +x .husky/pre-commit`.

**Le workflow GitHub Actions ne tourne pas** : vérifie que le fichier est bien dans `.github/workflows/` (pas `.github/workflow/` ou autre faute de frappe), et que tu as poussé le commit qui le contient.

**Branch protection refuse de m'inviter sur main même via PR** : vérifie que tu as bien créé une PR (pas un push direct) et que le workflow "Security" est bien terminé en succès.

**Supabase refuse mes requêtes après avoir activé RLS** : c'est normal, le DENY ALL par défaut bloque tout. Crée des policies explicites pour chaque opération autorisée (cf. exemples étape 9).

**Vercel ne récupère pas mes variables** : vérifie que tu as bien coché les bons environnements (Production / Preview / Development) au moment de définir la variable.

**Cursor, Claude Code ou Codex ignore les règles GDM** : vérifie que les fichiers `.ai-rules/RULES.md`, `.cursor/rules/gdm-rules.mdc`, `CLAUDE.md` et `AGENTS.md` sont bien à la racine du repo (pas dans un sous-dossier). Pour Cursor, vérifie aussi dans Settings → Rules → Project Rules que `gdm-rules` apparaît dans la liste. Si manquant, relance le script d'installation depuis la racine du repo.

**Pour toute autre erreur** : cherche le message exact dans Slack #dev, copie-colle, quelqu'un répondra.
