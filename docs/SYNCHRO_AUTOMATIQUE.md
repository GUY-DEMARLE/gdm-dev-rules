# Synchro automatique des apps

Ce document explique comment `gdm-dev-rules` se propage tout seul dans toutes les apps GDM, et comment le mettre en place (une seule fois, ~20 minutes).

## En bref

```
Le lead modifie gdm-dev-rules → merge sur main
        │
        ▼
Workflow « Synchro des apps » (.github/workflows/sync-apps.yml)
        │  pour chaque repo qui porte le topic gdm-managed
        ▼
PR « chore(gdm-rules): synchro des règles GDM » dans l'app
        │  vers dev (ou la branche par défaut si l'app n'a pas de dev)
        ▼
Merge automatique si les checks sont verts
        │  (sauf si la PR touche aux workflows ou à CODEOWNERS : validation du lead)
        ▼
Les devs font git pull → Claude, Codex et Cursor lisent les nouvelles règles
```

Le robot tourne :

- à chaque merge sur `main` qui touche `templates/`, `sync/` ou `security-oss.yml` ;
- **chaque nuit** (05:00 UTC), pour équiper les apps nouvellement marquées et réparer une copie modifiée à la main ;
- à la demande : onglet **Actions → Synchro des apps → Run workflow** (une seule app possible, ou simulation sans rien pousser).

Il fonctionne sur **n'importe quelle app**, quelle que soit sa stack : il ne fait que poser des fichiers et ouvrir des PR.

## Ce que le robot pose dans chaque app

| Fichier | Traitement |
|---|---|
| `.ai-rules/RULES.md`, `.cursor/rules/gdm-rules.mdc` | écrasés |
| `docs-rules/`, `system-design/` | écrasés ; un fichier retiré de la source est supprimé de l'app |
| `.github/workflows/security-oss.yml` | écrasé (copie complète, voulue) |
| `.github/workflows/gdm-rules-guard.yml` | écrasé : la CI qui bloque les modifications locales |
| `.ai-rules/verify-managed.sh`, `.ai-rules/MANAGED.sha256` | script de vérification et empreintes des fichiers gérés |
| `CLAUDE.md`, `AGENTS.md` | partie GDM mise à jour, **« ## Contexte du projet » et la suite préservés** |
| `CODEOWNERS` | bloc `gdm-dev-rules` ajouté en fin de fichier, le reste du fichier n'est pas touché |

Si un `CLAUDE.md` ou `AGENTS.md` existant n'a pas de section `## Contexte du projet`, le robot le laisse intact et le signale dans la PR.

## Les 3 verrous « seul le lead modifie les règles »

1. **Dans `gdm-dev-rules`** : seul le lead a les droits d'écriture, les autres devs sont en lecture seule.
2. **Dans chaque app, la CI « GDM Rules Guard »** compare les fichiers gérés à leurs empreintes. Une modification locale, par un dev ou par son IA, fait échouer la PR.
3. **Le robot répare** : même si une modification passe (par exemple en recalculant aussi les empreintes), la synchro suivante, au plus tard la nuit d'après, ouvre une PR qui remet l'original.

En complément, le bloc CODEOWNERS ajoute automatiquement le lead en relecteur de toute PR qui touche ces fichiers : tu es prévenu à chaque tentative.

> Pourquoi ne pas rendre « Require review from Code Owners » obligatoire dans les apps : tu es le seul code owner de ces fichiers, et GitHub interdit d'approuver sa propre PR. Chaque PR de release que tu ouvrirais (dev → staging → main) contenant une synchro serait bloquée. La garde CI et la réparation automatique suffisent.

---

## Mise en place (une seule fois)

### 1. Créer la GitHub App du robot

Une GitHub App plutôt qu'un token personnel : jetons valables 1 heure, droits limités au strict nécessaire, et pas liée au compte d'une personne (rien ne casse si quelqu'un quitte l'équipe).

1. GitHub → organisation **GUY-DEMARLE** → **Settings** → **Developer settings** → **GitHub Apps** → **New GitHub App**.
2. **GitHub App name** : `gdm-dev-rules-sync`.
3. **Homepage URL** : `https://github.com/GUY-DEMARLE/gdm-dev-rules`.
4. **Webhook** : décoche **Active** (le robot n'en a pas besoin).
5. **Repository permissions**, uniquement :
   - **Contents** : Read and write (pousser la branche du robot)
   - **Pull requests** : Read and write (ouvrir, mettre à jour, merger les PR)
   - **Workflows** : Read and write (indispensable pour mettre à jour `security-oss.yml` et `gdm-rules-guard.yml`)
   - **Metadata** : Read-only (ajouté automatiquement)
6. **Where can this GitHub App be installed?** : **Only on this account**.
7. **Create GitHub App**, puis note l'**App ID** affiché en haut de la page.
8. En bas de la page : **Generate a private key**. Un fichier `.pem` se télécharge.

### 2. Installer l'App sur l'organisation

1. Toujours sur la page de l'App : **Install App** → **GUY-DEMARLE**.
2. Choisis **All repositories**.
   - Ainsi, ajouter une app plus tard = juste lui mettre le topic `gdm-managed`, sans retoucher l'installation. C'est le topic qui décide quels repos le robot modifie.
   - Si tu préfères restreindre (**Only select repositories**), il faudra ajouter chaque nouvelle app à l'installation, en plus du topic.

### 3. Ranger les identifiants dans gdm-dev-rules

On utilise un **environnement** GitHub réservé à `main` : un workflow lancé depuis une autre branche ne peut pas lire la clé, même si quelqu'un modifie `sync-apps.yml` sur sa branche.

1. `gdm-dev-rules` → **Settings** → **Environments** → **New environment** → nom : `sync-apps`.
2. **Deployment branches and tags** → **Selected branches and tags** → ajoute la règle `main`.
3. **Environment variables** → **Add variable** : `GDM_SYNC_APP_ID` = l'App ID noté à l'étape 1.
4. **Environment secrets** → **Add secret** : `GDM_SYNC_APP_PRIVATE_KEY` = **tout** le contenu du fichier `.pem` (y compris les lignes `-----BEGIN…` et `-----END…`).
5. Supprime le fichier `.pem` de ton poste. Si tu veux une sauvegarde, range-la dans le gestionnaire de mots de passe d'équipe, jamais dans un dossier partagé ni dans Slack. En cas de perte, il suffit d'en générer une nouvelle.

### 4. Renseigner le lead dans la config

Dans `sync/config.env`, remplis :

```bash
GDM_LEAD="@ton-pseudo-github"
```

C'est lui qui est propriétaire des fichiers gérés (CODEOWNERS) et à qui le robot demande la relecture des PR sensibles. Une équipe GitHub fonctionne aussi (`@GUY-DEMARLE/lead`).

### 5. Protéger gdm-dev-rules

Le plus simple et le plus solide : **les autres devs ont l'accès `Read` sur `gdm-dev-rules`**. Ils lisent tout, mais ne peuvent ni pousser ni merger. Une idée de règle passe par une issue ou une discussion avec toi, et c'est toi qui modifies.

1. `gdm-dev-rules` → **Settings** → **Collaborators and teams** : toi en **Admin**, les autres en **Read**.
2. **Settings** → **Branches** → règle sur `main` : **Require a pull request before merging** (sans approbation obligatoire : tu es seul à valider, et GitHub interdit d'approuver sa propre PR) + checks obligatoires `PR Security - Secrets + SAST` et `PR Security - OSV Scanner`. Tu gardes ainsi un historique propre et les contrôles de sécurité, même seul.

### 6. Marquer les apps à synchroniser

Sur chaque repo d'app : page d'accueil du repo → roue dentée à côté de **About** → **Topics** → ajoute `gdm-managed`.

### 7. Régler chaque app (une fois par app)

**Settings → General → Pull Requests** :

- coche **Allow auto-merge** (sans ça, les PR du robot restent ouvertes et il faut les merger à la main) ;
- garde **Allow rebase merging** (le robot l'utilise s'il est autorisé, sinon squash, sinon merge).

**Settings → Branches** :

| Branche | Règles |
|---|---|
| `dev` | PR obligatoire ; checks obligatoires : `PR Security - Secrets + SAST`, `PR Security - OSV Scanner`, `GDM Rules Guard`. **Pas d'approbation obligatoire**, sinon le merge automatique attend une validation humaine. |
| `staging`, `main` | Comme dans `SETUP_PROJET.md`, plus `GDM Rules Guard` dans les checks. |
| App sans `dev` | Mêmes checks sur la branche par défaut. Si elle exige une approbation, chaque PR du robot attendra ta validation : c'est voulu sur une branche de prod. |

Les noms de checks n'apparaissent dans la liste de GitHub qu'après leur premier passage : règle la protection **après** le merge de la première PR du robot.

### 8. Premier lancement

1. `gdm-dev-rules` → **Actions** → **Synchro des apps** → **Run workflow**, coche **Simulation**. Le résumé liste, pour chaque app, ce qui changerait.
2. Si c'est bon, relance sans la simulation.
3. La première PR de chaque app touche aux workflows : elle attend ta validation. Relis-la et merge-la. Les suivantes (règles, docs, design system) passeront toutes seules.

Une fois le robot en place, tu peux passer `gdm-dev-rules` en **privé** : le robot s'authentifie avec son App. Seuls les anciens scripts `install` / `update` (téléchargement sans authentification) cesseront de fonctionner, et ils ne sont plus nécessaires.

---

## Au quotidien

**Pour le lead :**

1. Modifie `gdm-dev-rules` sur une branche, ouvre une PR, merge sur `main`.
2. Quelques minutes plus tard : **Actions → Synchro des apps** affiche un tableau par app (à jour / PR en merge automatique / PR à valider / échec).
3. Les PR « à valider » touchent aux workflows ou à CODEOWNERS : relis-les et merge-les.

**Pour les devs : rien à faire.** Les règles arrivent dans `dev` comme n'importe quel commit. Il suffit de faire `git pull` en début de session, et les fichiers `CLAUDE.md` / `AGENTS.md` demandent à l'IA de le rappeler.

**Ajouter une app :** topic `gdm-managed` + réglages de l'étape 7. Le robot l'équipe au plus tard la nuit suivante, ou tout de suite via **Run workflow** avec le nom du repo.

**Retirer une app :** enlève le topic. Le robot ne la touche plus ; les fichiers déjà posés restent en place.

## Si quelque chose ne marche pas

| Symptôme | Cause probable |
|---|---|
| Le job échoue à l'étape « Jeton de la GitHub App » | `GDM_SYNC_APP_ID` ou `GDM_SYNC_APP_PRIVATE_KEY` absent de l'environnement `sync-apps`, ou clé tronquée. |
| `refusing to allow a GitHub App to create or update workflow` | Permission **Workflows : Read and write** manquante sur l'App (étape 1.5). Après l'avoir ajoutée, accepte la nouvelle permission dans **Settings → GitHub Apps → Configure** de l'organisation. |
| « Aucune app avec le topic gdm-managed » | Topic absent, ou App non installée sur ces repos (étape 2). |
| « merge auto indisponible » dans le résumé | **Allow auto-merge** non coché dans l'app (étape 7). La PR reste ouverte, merge-la à la main. |
| La PR du robot reste ouverte alors que les checks sont verts | `dev` exige une approbation : retire « Require approvals » sur `dev` (étape 7). |
| La PR mentionne « CLAUDE.md n'a pas de section Contexte du projet » | Ajoute `## Contexte du projet` dans le fichier de l'app, en dessous de ce qui doit être remplacé par la version GDM. |
| « GDM_LEAD non configuré » | Étape 4. |

## Tester les scripts en local

Pour poser les fichiers dans une app sans passer par GitHub (debug, ou app hors organisation) :

```bash
GDM_LEAD="@ton-pseudo" bash sync/apply.sh /chemin/vers/gdm-dev-rules /chemin/vers/app
cd /chemin/vers/app && bash .ai-rules/verify-managed.sh
```
