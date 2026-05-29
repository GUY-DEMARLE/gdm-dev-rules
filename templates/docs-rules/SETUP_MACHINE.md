# Setup Machine — Dev GDM

**Quand utiliser ce doc** : la première fois que tu rejoins l'équipe, ou quand tu changes de machine.
**Durée** : ~30 minutes.
**Public** : dev qui sait déjà coder, qui connaît Git et la ligne de commande, mais qui n'a pas forcément utilisé tous les outils de sécurité.

À la fin de ce doc, ta machine est prête à travailler sur n'importe quel projet GDM en respectant le protocole de sécurité.

---

## Vue d'ensemble — Ce qu'on va installer/configurer

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   1. gitleaks         (scanner de secrets local)    │
│   2. Vercel CLI       (sync des var d'env)          │
│   3. Render CLI       (sync des var d'env)          │
│   4. Supabase CLI     (gestion BDD + edge func)     │
│   5. Comptes & accès  (GitHub, Actions, Slack,      │
│                        Sentry, hébergeurs, Supabase)│
│   6. uv + Supabomb    (debug audit web optionnel)   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

Tu peux faire ces étapes dans l'ordre, ou en parallèle si tu veux gagner du temps. Chaque section indique ce qu'il faut tester pour valider que c'est OK.

---

## 1. gitleaks — Scanner de secrets

**À quoi ça sert** : détecter automatiquement les clés API, passwords, et autres secrets dans un dossier ou un repo Git. En local, il sert à vérifier un dossier avant de pousser. Le blocage obligatoire se fait côté GitHub avec Security OSS.

### Installation

#### Sur Windows

Trois méthodes, choisis celle qui te parle le plus.

**Méthode A — Téléchargement direct** (le plus simple si tu n'as pas Scoop ou Chocolatey)

1. Va sur https://github.com/gitleaks/gitleaks/releases/latest
2. Télécharge le fichier qui finit par `_windows_x64.zip` (ex: `gitleaks_8.18.4_windows_x64.zip`)
3. Décompresse-le quelque part, par exemple `C:\Users\TonNom\Tools\gitleaks\`
4. Ajoute ce dossier au PATH :
   - Touche Windows → tape "variables d'environnement" → "Modifier les variables d'environnement système"
   - Bouton "Variables d'environnement" en bas
   - Section "Variables utilisateur" → sélectionne `Path` → "Modifier"
   - "Nouveau" → colle le chemin du dossier (ex: `C:\Users\TonNom\Tools\gitleaks\`)
   - OK partout
5. **Ferme et rouvre PowerShell** (sinon le PATH n'est pas rechargé)

**Méthode B — Avec Scoop** (si tu l'as déjà)

```powershell
scoop install gitleaks
```

**Méthode C — Avec Chocolatey** (si tu l'as déjà)

```powershell
choco install gitleaks
```

#### Sur Mac

```bash
brew install gitleaks
```

#### Sur Linux

```bash
# Voir https://github.com/gitleaks/gitleaks#installing pour ta distrib
# Exemple Debian/Ubuntu via téléchargement direct :
curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.18.4/gitleaks_8.18.4_linux_x64.tar.gz | tar xz
sudo mv gitleaks /usr/local/bin/
```

### Test que c'est installé

Ouvre PowerShell (ou Terminal sur Mac/Linux), tape :

```bash
gitleaks version
```

Tu dois voir quelque chose comme `v8.18.4`. Si tu as une erreur du genre `gitleaks : Le terme « gitleaks » n'est pas reconnu`, c'est que :
- Sur Windows : tu n'as pas ajouté gitleaks au PATH, ou tu n'as pas redémarré PowerShell
- Sur Mac/Linux : l'installation a échoué, retente

---

## 2. Vercel CLI — Sync des variables d'env

**À quoi ça sert** : récupérer les variables d'env d'un projet Vercel directement sur ta machine, sans avoir besoin que quelqu'un te les envoie par Slack ou par email. C'est ce qui permet à un nouveau dev de cloner un projet, lancer une commande, et avoir son `.env.local` à jour.

Pré-requis : Node.js et npm doivent être installés.

```bash
node --version
npm --version
```

### Installation

```bash
npm install -g vercel
```

### Test

```bash
vercel --version
```

Doit afficher quelque chose comme `Vercel CLI 32.x.x`.

### Connexion à ton compte Vercel

```bash
vercel login
```

Choisis "Continue with Email" ou "Continue with GitHub" selon comment tu as créé ton compte Vercel GDM. Suis les instructions (un email te sera envoyé pour valider). Tu n'as à faire ça qu'une seule fois par machine.

### Test post-connexion

```bash
vercel projects ls
```

Tu dois voir la liste des projets Vercel auxquels tu as accès. Si elle est vide ou si tu vois "Account does not have access", contacte le responsable Vercel chez GDM pour qu'on t'invite sur les projets.

---

## 3. Render CLI — Sync des variables d'env

**À quoi ça sert** : pareil que Vercel CLI, mais pour les services hébergés sur Render (les back Node.js / Python). Permet de récupérer les variables d'env définies sur Render pour les avoir en local.

### Installation

#### Sur Windows / Mac / Linux

```bash
npm install -g @render-com/cli
```

(Render n'a pas encore de installer natif Windows comme Vercel, le npm fonctionne partout.)

### Test

```bash
render --version
```

### Connexion à ton compte Render

```bash
render login
```

Suis les instructions (browser auth). Une fois fait :

```bash
render services list
```

Doit afficher la liste des services Render auxquels tu as accès.

---

## 4. Supabase CLI — Gestion BDD et Edge Functions

**À quoi ça sert** : gérer les migrations SQL, déployer des Edge Functions, lancer une instance Supabase locale pour le dev. Indispensable si tu touches à la BDD ou aux Edge Functions.

### Installation

#### Sur Windows

**Méthode A — Scoop** (recommandée)

```powershell
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

**Méthode B — Téléchargement direct**

1. Va sur https://github.com/supabase/cli/releases/latest
2. Télécharge `supabase_windows_amd64.tar.gz`
3. Décompresse, ajoute le dossier au PATH (cf. méthode pour gitleaks plus haut)

#### Sur Mac

```bash
brew install supabase/tap/supabase
```

#### Sur Linux

```bash
# Voir https://github.com/supabase/cli#install-the-cli
```

### Test

```bash
supabase --version
```

### Connexion à ton compte Supabase

```bash
supabase login
```

Va te demander un access token. Va dans https://supabase.com/dashboard/account/tokens → "Generate new token" → copie-colle dans le terminal.

### Test post-connexion

```bash
supabase projects list
```

Doit afficher la liste des projets Supabase auxquels tu as accès.

---

## 5. Comptes et accès

C'est l'étape la moins technique mais la plus importante. **Aucune clé ne doit transiter par Slack ou email.** Le bon principe : tu as un compte sur chaque plateforme, on t'invite, et tu accèdes aux secrets via les CLI installées plus haut.

### Compte GitHub

- [ ] Email pro `prenom@guydemarle.com`
- [ ] 2FA activé : Settings → Password and authentication → Two-factor authentication
- [ ] Demander à être ajouté à l'organisation `GUY-DEMARLE`
- [ ] Configurer SSH (cf. doc référentiel GDM existant)
- [ ] Avoir accès à GitHub Actions sur les repos applicatifs
- [ ] Pouvoir créer ou demander les secrets/variables Actions nécessaires à Security OSS

**Test** :

```bash
ssh -T git@github.com
# Doit dire "Hi <ton-username> ! You've successfully authenticated..."
```

### GitHub Actions — Security OSS

Pour installer ou maintenir le workflow Security OSS sur un repo, il faut pouvoir configurer :

Secrets :

```text
SLACK_WEBHOOK_URL
OPENAI_API_KEY
```

Variables :

```text
SECURITY_TARGET_URL
OPENAI_SECURITY_MODEL
```

`SLACK_WEBHOOK_URL` permet de recevoir les rapports et les alertes PR. `OPENAI_API_KEY` est optionnel : sans clé OpenAI, le workflow produit quand même les rapports, mais sans synthèse IA.

`SECURITY_TARGET_URL` est optionnel mais recommandé pour les apps web publiques. Sans cette variable, ZAP et Supabomb sont ignorés proprement.

### Compte Slack

- [ ] Être dans le workspace Slack GDM
- [ ] Avoir accès au canal ou à l'app qui reçoit les rapports Security OSS
- [ ] Si besoin, demander à l'admin Slack de créer un Incoming Webhook

### Compte Vercel

- [ ] Compte créé avec ton email pro
- [ ] Inviter par admin sur l'équipe `guy-demarle` (ou l'équipe correspondante)
- [ ] Tester `vercel projects ls` (cf. section 2)

### Compte Render

- [ ] Compte créé avec ton email pro
- [ ] Invité par admin sur le workspace GDM
- [ ] Tester `render services list` (cf. section 3)

### Compte Supabase

- [ ] Compte créé avec ton email pro
- [ ] Invité par admin sur l'organisation GDM (rôle Developer ou Admin selon ton niveau)
- [ ] Tester `supabase projects list` (cf. section 4)

### Compte Google Cloud (si tu touches à Gemini, Maps, etc.)

- [ ] Compte créé (peut être ton compte Google personnel à défaut)
- [ ] Invité sur le projet GCP GDM par admin
- [ ] Accès à la console : https://console.cloud.google.com

### Compte Sentry (si l'app est en production)

- [ ] Compte créé avec ton email pro
- [ ] Accès aux projets Sentry GDM utiles
- [ ] Pouvoir récupérer le DSN du projet si tu instrumentes une app
- [ ] Pouvoir consulter Issues, Traces, Spans et Monitors

Sentry est le complément prod de Security OSS : Security OSS bloque avant merge et audite chaque semaine, Sentry surveille ce qui se passe réellement en production.

---

## 6. uv + Supabomb — Audit web/Supabase optionnel

**À quoi ça sert** : Supabomb aide à repérer des signaux Supabase exposés depuis une application web publique : URL Supabase, anon key, Edge Functions, indices de configuration faible.

**Important** : dans le process standard, Supabomb tourne surtout dans le workflow GitHub Actions Security OSS quand `SECURITY_TARGET_URL` est configurée. L'installation locale sert seulement à reproduire ou déboguer un scan.

À utiliser uniquement sur **nos** sites, pas sur ceux des autres.

### Installation de uv

Le workflow GitHub installe `uv` automatiquement. En local, installe-le seulement si tu veux lancer Supabomb à la main.

**Sur Windows** :

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

**Sur Mac/Linux** :

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Lancer Supabomb en local

Supabomb n'est pas lancé via `uvx supabomb`, car le package n'est pas toujours disponible dans le registre Python. La méthode fiable est de cloner le repo officiel puis d'exécuter l'outil avec `uv`.

```bash
git clone https://github.com/ModernPentest/supabomb.git
cd supabomb
uv run supabomb discover --url https://simu-recrutement.guydemarle.com/
```

Sur Windows PowerShell :

```powershell
git clone https://github.com/ModernPentest/supabomb.git
cd supabomb
uv run supabomb discover --url https://simu-recrutement.guydemarle.com/
```

Tu dois voir quelque chose comme :

```
Analyzing URL: https://simu-recrutement.guydemarle.com/
✓ Supabase instance found!

Project Reference   pncickiayzfimlheeamf
URL                 https://pncickiayzfimlheeamf.supabase.co
Anon Key            eyJhbGciOiJIUzI1NiIs...
Source              external script: ...
Edge Functions      X discovered
```

C'est une commande **non destructive** — elle ne fait que lire des pages publiques. Tu peux la lancer librement sur tous nos sites pour faire un inventaire.

Dans Security OSS, cette étape est automatisée : le workflow clone Supabomb dans le runner GitHub, lance `uv run supabomb discover --url "$TARGET_URL"` et archive le rapport dans les artifacts.

### À ne pas faire avec supabomb

L'outil a aussi des sous-commandes pour tester l'écriture sur les tables (POST, PATCH, DELETE). **N'utilise jamais ces sous-commandes sur la prod.** Si tu veux tester l'écriture pour vérifier que les RLS sont bien en place, fais-le sur un projet de test isolé, pas sur les vraies données.

---

## Récap — Tout est OK ?

À la fin de ce doc, lance ces commandes pour vérifier que tout est en place :

```bash
gitleaks version
node --version
npm --version
vercel --version
render --version
supabase --version
uv --version
```

Toutes les commandes doivent retourner un numéro de version. Aucune erreur "command not found".

Et vérifie que tu peux accéder aux comptes :

```bash
vercel projects ls
render services list
supabase projects list
ssh -T git@github.com
```

Et vérifie que tu as les accès nécessaires au process Security OSS :

- GitHub Actions activé sur les repos.
- Possibilité de configurer ou demander les secrets Actions.
- Accès Slack au canal ou à l'app qui reçoit les rapports.
- Accès Sentry pour les apps déjà en production.

Si tout passe, ta machine est prête. Tu peux passer au doc `SETUP_PROJET.md` pour configurer un projet.

---

## Que faire si quelque chose ne marche pas

**Si une commande dit "command not found"** : l'outil n'est pas dans le PATH. Soit l'installation a échoué, soit le terminal n'a pas été redémarré après ajout au PATH. Ferme PowerShell, rouvre, retente.

**Si une commande dit "Authentication failed"** : tu n'es pas connecté, ou ton token est expiré. Relance la commande `<outil> login` correspondante.

**Si tu n'as pas accès à un projet Vercel/Render/Supabase** : tu n'as pas été invité, ou pas avec les bons droits. Demande à l'admin GDM de la plateforme concernée de t'ajouter.

**Si gitleaks plante avec un message bizarre** : vérifie la version (`gitleaks version`). Si c'est une vieille version, retélécharge la dernière depuis https://github.com/gitleaks/gitleaks/releases.

**Si Supabomb échoue avec `supabomb was not found in the package registry`** : c'est normal avec `uvx supabomb`. Utilise la méthode par clone GitHub indiquée section 6, ou laisse Security OSS le lancer dans GitHub Actions.

**Si Security OSS n'envoie pas de Slack** : ce n'est pas un problème machine. Vérifie côté repo GitHub que `SLACK_WEBHOOK_URL` est bien configuré dans les secrets Actions.

**Pour toute autre erreur** : copie-colle le message dans Slack #dev, quelqu'un répondra.
