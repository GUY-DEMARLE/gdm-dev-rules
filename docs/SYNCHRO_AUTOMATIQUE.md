# Synchro automatique et protection des apps

Ce document explique comment `gdm-dev-rules` se propage tout seul dans toutes les apps GDM, comment chaque app est protégée (relecture obligatoire, contrôles bloquants), et comment mettre tout ça en place (une seule fois, ~30 minutes).

**Prérequis : l'organisation GitHub doit être en plan Team.** En plan Free, GitHub ne permet aucune protection de branche sur les repos privés : pas de relecture obligatoire, pas de contrôle bloquant, push direct possible sur `main`.

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
Le robot attend que les checks soient verts, puis merge lui-même
        │  (il est en exception de la règle d'approbation)
        │  sauf la toute première installation dans une app : validation du lead
        ▼
Les devs font git pull → Claude, Codex et Cursor lisent les nouvelles règles
```

Le robot tourne :

- à chaque merge sur `main` qui touche `templates/`, `sync/` ou `security-oss.yml` ;
- **chaque nuit** (05:00 UTC), pour équiper les apps nouvellement marquées, retenter les PR restées ouvertes et réparer une copie modifiée à la main ;
- à la demande : onglet **Actions → Synchro des apps → Run workflow** (une seule app possible, ou simulation sans rien pousser).

Il fonctionne sur **n'importe quelle app**, quelle que soit sa stack : il ne fait que poser des fichiers, ouvrir des PR et les merger.

## Ce que le robot pose dans chaque app

| Fichier | Traitement |
|---|---|
| `.ai-rules/RULES.md`, `.cursor/rules/gdm-rules.mdc` | écrasés |
| `docs-rules/`, `system-design/` | écrasés ; un fichier retiré de la source est supprimé de l'app |
| `.github/workflows/security-oss.yml` | écrasé (copie complète, voulue) |
| `.github/workflows/gdm-rules-guard.yml` | écrasé : la CI qui bloque les modifications locales |
| `.ai-rules/verify-managed.sh`, `.ai-rules/MANAGED.sha256` | script de vérification et empreintes des fichiers gérés |
| `CLAUDE.md`, `AGENTS.md` | partie GDM mise à jour, **« ## Contexte du projet » et la suite préservés** |

Si un `CLAUDE.md` ou `AGENTS.md` existant n'a pas de section `## Contexte du projet`, le robot le laisse intact et le signale dans la PR.

## La protection de chaque app : la règle `gdm-protection`

Posée par `sync/proteger-repos.sh` sur la branche par défaut, `main`, `staging` et `dev` :

- **pas de push direct**, pas de force push, pas de suppression de la branche ;
- **PR obligatoire avec 1 approbation**. La dernière modification doit être approuvée par quelqu'un d'autre que son auteur : le lead relit les PR de l'autre dev, l'autre dev relit celles du lead. Les conversations doivent être résolues ;
- **checks bloquants** : `PR Security - Secrets + SAST`, `PR Security - OSV Scanner`, `GDM Rules Guard`.

Exceptions, via PR uniquement, et GitHub affiche sur la PR que la règle a été contournée :

- **le robot de synchro** merge ses PR sans approbation, après avoir lui-même attendu que les checks soient verts. Un check en échec l'arrête ;
- **le lead** (rôle admin du repo) peut merger sa propre PR sans approbation, en urgence ou en l'absence de l'autre dev. Désactivable avec `GDM_LEAD_BYPASS=0` dans `sync/config.env`.

## Les verrous « seul le lead modifie les règles »

1. **Dans `gdm-dev-rules`** : seul le lead a les droits d'écriture, les autres devs sont en lecture seule.
2. **Dans chaque app, la CI « GDM Rules Guard »** compare les fichiers gérés à leurs empreintes. Une modification locale, par un dev ou par son IA, fait échouer la PR, et ce check est bloquant.
3. **Le robot répare** : même si une modification passe, la synchro suivante, au plus tard la nuit d'après, remet l'original.

> Pas de `CODEOWNERS` : avec la relecture obligatoire par l'autre dev (règle `gdm-protection`) et la garde, il ne ferait que doubler les notifications. Les premières versions du robot en posaient un ; il le retire désormais. À réintroduire si l'équipe grandit et qu'une PR peut être approuvée sans le lead.

---

## Mise en place (une seule fois)

### 1. Créer la GitHub App du robot

Une GitHub App plutôt qu'un token personnel : jetons valables 1 heure, droits limités au strict nécessaire, et pas liée au compte d'une personne (rien ne casse si quelqu'un quitte l'équipe).

1. GitHub → organisation **GUY-DEMARLE** → **Settings** → **Developer settings** → **GitHub Apps** → **New GitHub App**.
2. **GitHub App name** : `gdm-dev-rules-sync`.
3. **Homepage URL** : `https://github.com/GUY-DEMARLE/gdm-dev-rules`.
4. **Webhook** : décoche **Active** (le robot n'en a pas besoin).
5. **Repository permissions**, uniquement :
   - **Contents** : Read and write (pousser la branche du robot, merger)
   - **Pull requests** : Read and write (ouvrir, mettre à jour, merger les PR)
   - **Workflows** : Read and write (indispensable pour mettre à jour `security-oss.yml` et `gdm-rules-guard.yml`)
   - **Checks** : Read-only et **Commit statuses** : Read-only (attendre le résultat des checks)
   - **Administration** : Read-only (signaler les apps où la protection manque ; le robot ne peut rien y modifier)
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

### 4. Compléter `sync/config.env`

```bash
GDM_LEAD="@naboucaya-guydemarle"   # déjà rempli
GDM_SYNC_APP_ID="123456"           # l'App ID de l'étape 1 (pas un secret)
GDM_LEAD_BYPASS=1                  # 1 = le lead peut merger sa PR seul en urgence
```

### 5. Protéger gdm-dev-rules

**Les autres devs ont l'accès `Read` sur `gdm-dev-rules`** : ils lisent tout, mais ne peuvent ni pousser ni merger. Une idée de règle passe par une issue ou une discussion avec toi, et c'est toi qui modifies.

1. `gdm-dev-rules` → **Settings** → **Collaborators and teams** : toi en **Admin**, les autres en **Read**.
2. **Settings** → **Rules** → **Rulesets** → **New branch ruleset** sur `main` : **Require a pull request before merging**, sans approbation obligatoire (tu es seul à valider ce dépôt) + **Require status checks** `PR Security - Secrets + SAST` et `PR Security - OSV Scanner`.

### 6. Marquer les apps à synchroniser

Sur chaque repo d'app : page d'accueil du repo → roue dentée à côté de **About** → **Topics** → ajoute `gdm-managed`.

### 7. Premier lancement du robot

1. `gdm-dev-rules` → **Actions** → **Synchro des apps** → **Run workflow**, coche **Simulation**. Le résumé liste, pour chaque app, ce qui changerait.
2. Si c'est bon, relance sans la simulation.
3. La première PR de chaque app (installation) attend ta validation : vérifie qu'elle n'entre pas en conflit avec les workflows existants, approuve-la et merge-la.

### 8. Poser la protection dans toutes les apps

Une fois les PR d'installation mergées, depuis ton poste, avec ton compte `gh` (admin de l'organisation) :

```bash
DRY_RUN=1 bash sync/proteger-repos.sh
```

pour voir la règle, puis :

```bash
bash sync/proteger-repos.sh
```

Le script pose (ou met à jour) la règle `gdm-protection` dans toutes les apps `gdm-managed`. Il ignore une app où les règles GDM ne sont pas encore installées : les checks exigés n'y existeraient pas et plus aucune PR ne pourrait être mergée. Relance-le à chaque nouvelle app, ou après une modification de la règle.

Une fois le robot en place, tu peux passer `gdm-dev-rules` en **privé** : le robot s'authentifie avec son App. Seuls les anciens scripts `install` / `update` (téléchargement sans authentification) cesseront de fonctionner, et ils ne sont plus nécessaires.

---

## Au quotidien

**Pour le lead :**

1. Modifie `gdm-dev-rules` sur une branche, ouvre une PR, merge sur `main`.
2. Quelques minutes plus tard, **Actions → Synchro des apps** affiche un tableau par app : à jour, ✓ mergée, ❌ checks en échec, à valider, protection absente.
3. Les PR « à valider » sont des premières installations : relis-les, merge-les, puis lance `sync/proteger-repos.sh <app>`.
4. Une PR « checks en échec » veut dire que la nouvelle version des règles fait échouer un contrôle dans cette app. C'est souvent une alerte de sécurité réelle remontée par une version plus récente du pipeline : regarde le run.

**Pour les devs : rien à faire.** Les règles arrivent dans `dev` comme n'importe quel commit. Il suffit de faire `git pull` en début de session, et les fichiers `CLAUDE.md` / `AGENTS.md` demandent à l'IA de le rappeler.

**Ajouter une app :** topic `gdm-managed`. Le robot l'équipe au plus tard la nuit suivante, ou tout de suite via **Run workflow** avec le nom du repo. Après le merge de sa première PR : `bash sync/proteger-repos.sh <app>`.

**Retirer une app :** enlève le topic. Le robot ne la touche plus ; les fichiers déjà posés et la protection restent en place.

## Si quelque chose ne marche pas

| Symptôme | Cause probable |
|---|---|
| Le job échoue à l'étape « Jeton de la GitHub App » | `GDM_SYNC_APP_ID` ou `GDM_SYNC_APP_PRIVATE_KEY` absent de l'environnement `sync-apps`, ou clé tronquée. |
| `refusing to allow a GitHub App to create or update workflow` | Permission **Workflows : Read and write** manquante sur l'App (étape 1.5). Après l'avoir ajoutée, accepte la nouvelle permission dans **Settings → GitHub Apps → Configure** de l'organisation. |
| « Aucune app avec le topic gdm-managed » | Topic absent, ou App non installée sur ces repos (étape 2). |
| « checks verts mais merge refusé » | Le robot n'est pas en exception de la règle : `GDM_SYNC_APP_ID` était vide au lancement de `proteger-repos.sh`. Remplis-le et relance le script. |
| « checks toujours en cours, nouvel essai la nuit prochaine » | Les checks ont dépassé `GDM_CHECKS_TIMEOUT` (30 min par défaut). La PR reste ouverte, le robot la merge au passage suivant si elle est verte. |
| « protection des branches absente » | `sync/proteger-repos.sh` pas encore lancé sur cette app. |
| `proteger-repos.sh` : « lecture impossible » | Organisation pas encore en plan Team, ou tu n'es pas admin du repo. |
| La PR mentionne « CLAUDE.md n'a pas de section Contexte du projet » | Ajoute `## Contexte du projet` dans le fichier de l'app, en dessous de ce qui doit être remplacé par la version GDM. |

## Tester les scripts en local

Pour poser les fichiers dans une app sans passer par GitHub (debug, ou app hors organisation) :

```bash
GDM_LEAD="@ton-pseudo" bash sync/apply.sh /chemin/vers/gdm-dev-rules /chemin/vers/app
cd /chemin/vers/app && bash .ai-rules/verify-managed.sh
```
