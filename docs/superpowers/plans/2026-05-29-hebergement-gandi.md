# Hébergement Gandi & cadre de décision stack — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Documenter l'hébergement Gandi FTP comme choix d'architecture légitime (quand le choisir, ce que ça implique côté sécurité/déploiement) et l'intégrer au cadre de décision stack des règles GDM.

**Architecture:** Approche A — un nouveau doc dédié `templates/docs-rules/HEBERGEMENT_GANDI.md` + un cadre de décision (arbre back Supabase-first > Render, puis hébergement front Gandi-statique vs Vercel) tissé dans `RULES.md` et `ARCHITECTURE_SECURITE_GDM.md`, avec des encadrés « Prompt IA de démarrage » aux points de décision.

**Tech Stack:** Markdown (docs GDM). Diffusion automatique via `templates/docs-rules/` (scripts install/update existants). Pas de code applicatif.

**Note de méthode (doc, pas code) :** il n'y a pas de tests unitaires. La « vérification » de chaque tâche = un `grep`/contrôle de présence du contenu et de cohérence des liens. Les commits sont laissés à l'utilisateur (il gère son git lui-même) ; les étapes « Commit » servent de jalons.

**Spec de référence :** `docs/superpowers/specs/2026-05-29-hebergement-gandi-design.md`

---

## File Structure

| Fichier | Rôle | Action |
|---|---|---|
| `templates/docs-rules/HEBERGEMENT_GANDI.md` | Doc concret Gandi (quand, déploiement, secrets, sécurité, checklist, prompts) | **Créer** |
| `templates/.ai-rules/RULES.md` | Source IA condensée — §0 cadre de décision, §6 hosting, §7 références | Modifier |
| `templates/docs-rules/ARCHITECTURE_SECURITE_GDM.md` | Référence archi — table des docs, version, Partie 3 (back + hébergement front) | Modifier |
| `templates/docs-rules/SETUP_PROJET.md` | Setup projet — étape 10 : callout décision + prompt + sous-section Gandi | Modifier |

Ordre : on crée d'abord le doc cible (Task 1) pour que les renvois des autres fichiers pointent vers quelque chose d'existant, puis on tisse les références (Tasks 2-4), puis vérif globale (Task 5).

---

## Task 1 : Créer le doc `HEBERGEMENT_GANDI.md`

**Files:**
- Create: `templates/docs-rules/HEBERGEMENT_GANDI.md`

- [ ] **Step 1 : Écrire le fichier complet**

Créer `templates/docs-rules/HEBERGEMENT_GANDI.md` avec exactement ce contenu :

~~~~markdown
# Hébergement Gandi FTP — Dev GDM

**Pour** : choisir et sécuriser un hébergement Gandi FTP (mutualisé, sous `guydemarle.com`).
**Lecture** : ~10 min. À lire au démarrage d'un projet quand l'hébergement Gandi est envisagé.

Ce doc complète `ARCHITECTURE_SECURITE_GDM.md` (Partie 3) et `RULES.md`. Il ne remplace aucune des 6 règles non-négociables : il explique comment les appliquer dans le contexte Gandi.

---

## 1. Quand choisir Gandi (et quand ne pas)

Gandi FTP héberge la **couche front statique**. Le bon cas d'usage :

- Le front est une **SPA statique** (React/Vite buildé, ou HTML/JS), **sans rendu serveur**.
- L'API est **Supabase-only** : PostgREST (CRUD auto) + Edge Functions (proxy/logique légère).
- La priorité est **coût / simplicité / un seul hébergement** déjà payé sous `guydemarle.com`.

**Ne pas choisir Gandi si :**

- Le front a besoin de **SSR/SEO** (Next.js rendu serveur), de **serverless**, ou de **preview deploys par PR** → **Vercel**.
- L'app a besoin d'un **back maison** (async lourd, orchestration, long-running, RAG, libs Python/ML) → **Render** pour le back (le front, lui, peut toujours rester statique sur Gandi s'il n'a pas besoin de rendu serveur).

Le vrai déclencheur « Gandi vs Vercel » est : *le front a-t-il besoin de rendu serveur ?* En pratique, « API Supabase-only » et « front statique » coïncident presque toujours.

> 💬 **Prompt IA — hébergement front** : « Mon front [décrire : SPA Vite ? besoin SEO/SSR ?] et mon API est [Supabase-only ? maison ?]. D'après les règles GDM, un statique sur Gandi FTP suffit-il, ou faut-il Vercel ? Justifie. »

---

## 2. Place dans l'architecture GDM

Gandi joue le rôle que Vercel joue dans l'archi standard : **héberger le front**. Le back reste Supabase.

```
┌──────────────┐   HTTPS    ┌─────────────────────────┐
│  FRONT       │ ─────────► │  SUPABASE                │
│  (Gandi FTP) │            │  - PostgREST (CRUD, RLS) │
│  statique    │ ◄───────── │  - Edge Functions (proxy)│
│  Pas de clé  │            └───────────┬─────────────┘
└──────────────┘                        │ (clés tierces ici)
                                         ▼
                              Gemini / OpenAI / Stripe …
```

- Le front sur Gandi **ne contient aucun secret** (Règle 5).
- Il parle à Supabase : PostgREST pour les données (protégé par RLS), Edge Functions pour tout tiers sensible/payant (Règle 6).

---

## 3. Le piège sécu n°1 — les RLS sont l'unique barrière

Quand un front statique parle **directement** à Supabase PostgREST, **il n'y a plus de back maison pour filtrer** : la sécurité des données repose **entièrement** sur les **RLS**.

- Règle 2 (RLS dès la migration + policies explicites) passe de *importante* à **vitale**.
- Chaque table exposée via PostgREST **doit** avoir RLS activée + au moins une policy basée sur `auth.uid()`.
- Les tiers sensibles/payants (Gemini, OpenAI, Stripe…) **restent derrière une Edge Function** qui authentifie, valide les inputs et verrouille les paramètres coûteux. Jamais d'appel direct front → tiers (sinon = incident `simu-recrutement` rejoué depuis Gandi).

---

## 4. Secrets & configuration

Pas de plateforme de variables d'env type Vercel/Render sur Gandi mutualisé. Deux mécanismes propres :

**Front (build) — injection au build distant.** Les variables publiques (URL Supabase, clé anon) sont injectées au **build en CI** (GitHub Actions) depuis les GitHub Secrets/Variables. Règle 5 : **seules des valeurs publiques** finissent dans le bundle (`VITE_*` / `NEXT_PUBLIC_*`). Aucun secret au build.

**Serveur (PHP legacy) — `.env` hors webroot + `.htaccess`.** Le fichier `.env` (identifiants MySQL, clés serveur) est posé sur le serveur, **hors du dossier public** ou rendu **non téléchargeable** par `.htaccess` (cf. section 7). Il n'est **jamais commité**. Un `.env.example` avec placeholders vit dans le repo.

Rappel : un secret en clair dans une doc ou un fichier commité est aussi grave qu'un secret dans le code (cf. Incident 3 ci-dessous).

---

## 5. Transport & identifiants de déploiement

- **SFTP/FTPS uniquement, jamais FTP en clair.** Le FTP classique transmet identifiants et fichiers en clair sur le réseau.
- Les **identifiants SFTP** vivent dans **GitHub Secrets** (pour la CI) ou un gestionnaire de secrets — **jamais** dans le repo, jamais dans une doc.
- **Rotation** possible et documentée : si un identifiant fuite, le roter depuis le panel Gandi (cf. procédure d'incident de `ARCHITECTURE_SECURITE_GDM.md`).

> **Incident 3 (rappel)** : `GANDI_SFTP_PASSWORD=...` avait été commité en clair dans une doc de déploiement, donnant un accès écriture au serveur de prod. Fix : rotation, doc réécrite, nettoyage Git. Les identifiants Gandi se traitent comme n'importe quel secret.

---

## 6. Standard de déploiement (recommandé)

Cible : **build du front en CI puis déploiement SFTP**, déclenché au merge sur `main`. Pas d'upload manuel pour la prod (sauf dépannage ponctuel).

Exemple de workflow (`.github/workflows/deploy-gandi.yml`), à adapter :

~~~yaml
name: Deploy front (Gandi SFTP)

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - run: npm ci

      # Variables PUBLIQUES uniquement (Règle 5). Jamais de secret au build.
      - run: npm run build
        env:
          VITE_SUPABASE_URL: ${{ vars.VITE_SUPABASE_URL }}
          VITE_SUPABASE_ANON_KEY: ${{ vars.VITE_SUPABASE_ANON_KEY }}

      # Déploiement SFTP — identifiants en GitHub Secrets, jamais dans le repo.
      - name: Deploy via SFTP
        uses: SamKirkland/FTP-Deploy-Action@v4.3.5
        with:
          protocol: ftps          # FTPS (TLS) — jamais 'ftp' en clair
          server: ${{ secrets.GANDI_SFTP_HOST }}
          username: ${{ secrets.GANDI_SFTP_USER }}
          password: ${{ secrets.GANDI_SFTP_PASSWORD }}
          local-dir: ./dist/      # dossier de build à adapter
          server-dir: ./          # webroot Gandi à adapter
~~~

Secrets/variables GitHub à configurer (Settings → Secrets and variables → Actions) :

- Secrets : `GANDI_SFTP_HOST`, `GANDI_SFTP_USER`, `GANDI_SFTP_PASSWORD`.
- Variables : `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` (publiques).

> Si Gandi propose SFTP (port 22) plutôt que FTPS, utiliser une action SFTP (clé SSH) et stocker la clé privée en secret. Le principe est identique : transport chiffré + identifiants en secrets.

---

## 7. Hygiène du webroot

Un hébergement mutualisé sert tout ce qui est dans le dossier public. À **interdire d'accès HTTP** :

- `.git/` (sinon tout l'historique du repo est téléchargeable)
- `.env`, `*.env`, fichiers de config (`config.php`, etc.)
- sauvegardes (`*.sql`, `*.bak`, `*.zip`), `*.map` de source

Exemple `.htaccess` (Apache) à la racine du webroot :

~~~apache
# Bloquer les fichiers et dossiers sensibles
RedirectMatch 404 /\.git
<FilesMatch "(^\.env|\.env$|\.(bak|sql|zip|map)$|config\.php$)">
    Require all denied
</FilesMatch>
~~~

Vérifier après déploiement qu'aucune de ces URL ne répond (test rapide) :

~~~bash
for p in .git/config .env config.php backup.sql; do
  echo -n "$p -> "; curl -s -o /dev/null -w "%{http_code}\n" "https://app.guydemarle.com/$p"
done
# Tout doit répondre 403 ou 404 (jamais 200)
~~~

---

## 8. Garde-fous MySQL (PHP legacy)

Pour les apps PHP+MySQL existantes (legacy — la voie recommandée pour une nouvelle app simple reste Supabase) :

- **Requêtes préparées** (PDO ou mysqli paramétré) systématiques — jamais de concaténation de variables dans le SQL (anti-injection).
- **User MySQL au moindre privilège** : pas de `root`, droits limités à la base/app concernée.
- **Base non exposée publiquement** : accès MySQL restreint au serveur, pas d'admin (phpMyAdmin) ouvert sans protection.
- **Aucun identifiant commité** : ils vivent dans le `.env` hors webroot (section 4).

MySQL n'a **pas** de RLS façon Supabase : l'access control est **dans le code PHP**. À traiter avec la même rigueur que les policies RLS.

---

## 9. Security OSS sur les apps Gandi

Le workflow Security OSS s'applique aussi à ces repos :

- `composer audit` si `composer.lock` (dépendances PHP vulnérables).
- Scan du bundle front compilé (patterns de secrets — cf. `ARCHITECTURE_SECURITE_GDM.md` Étape 5).
- OWASP ZAP sur l'URL publique via la variable `SECURITY_TARGET_URL`.

Installer le caller Security OSS qui référence `GUY-DEMARLE/gdm-dev-rules` (ne pas copier le gros workflow central).

---

## 10. Checklist de mise en prod Gandi

- [ ] Front buildé en CI, **aucun secret** dans le bundle (Règle 5).
- [ ] Déploiement par **SFTP/FTPS** (jamais FTP en clair), identifiants en **GitHub Secrets**.
- [ ] `.env` serveur **hors webroot** / bloqué par `.htaccess`, **non commité** ; `.env.example` à jour.
- [ ] `.git/`, `.env`, configs, backups **inaccessibles** en HTTP (test section 7 = 403/404).
- [ ] Toutes les tables Supabase exposées ont **RLS + policies** (barrière unique).
- [ ] Tiers sensibles/payants **derrière une Edge Function** (jamais d'appel direct front → tiers).
- [ ] (PHP) requêtes préparées + user MySQL least-privilege.
- [ ] Security OSS actif (composer audit / scan bundle / ZAP).

---

## 11. Prompts IA

> 💬 **Prompt de démarrage (archi complète)** : « Mon app doit [besoin métier + volumétrie + tiers utilisés]. D'après les règles GDM (`.ai-rules/RULES.md`), conseille-moi : (1) API Supabase PostgREST/Edge ou API maison Render ? (2) front statique sur Gandi FTP ou Vercel ? Justifie selon l'arbre de décision et liste les implications sécu (RLS, Edge Functions, secrets). »

> 💬 **Prompt de revue sécu Gandi** : « Mon app est hébergée sur Gandi FTP avec un front statique + Supabase. Vérifie avec moi la checklist de `HEBERGEMENT_GANDI.md` : transport SFTP, secrets hors webroot, hygiène du webroot, RLS comme barrière unique, Edge Functions pour les tiers. Liste ce qui manque. »
~~~~

- [ ] **Step 2 : Vérifier la présence et la structure**

Run :
~~~bash
grep -c "^## " templates/docs-rules/HEBERGEMENT_GANDI.md
~~~
Expected : `11` (les 11 sections `##`).

- [ ] **Step 3 : Commit** *(jalon — laisser l'utilisateur committer ; sinon)*

~~~bash
git add templates/docs-rules/HEBERGEMENT_GANDI.md
git commit -m "docs: ajoute HEBERGEMENT_GANDI.md (hebergement Gandi FTP)"
~~~

---

## Task 2 : Tisser le cadre de décision dans `RULES.md`

**Files:**
- Modify: `templates/.ai-rules/RULES.md` (§0 fin, §6 ligne Hosting, §7 références)

- [ ] **Step 1 : Ajouter le cadre de décision en fin de §0**

Dans `templates/.ai-rules/RULES.md`, juste **après** le bloc `## 0) Cadre global` (après la ligne `- **BDD** : Supabase (PostgREST) avec RLS activée sur toutes les tables.`) et **avant** `## 1) Les 6 règles non-negociables`, insérer :

~~~markdown

### Choix de stack et d'hébergement (à trancher au démarrage)

Deux décisions chaînées :

1. **Back / API** — prioriser **Supabase (PostgREST + Edge Functions)** tant que le besoin est du CRUD sur Postgres + proxy léger vers les tiers. Monter une **API maison sur Render** (Node/Python) seulement pour la logique qui ne rentre pas dans PostgREST/Edge : async lourd, orchestration, long-running, RAG, libs Python/ML.
2. **Front / hébergement** — si le front est une **SPA statique** (pas de rendu serveur) et que l'API est Supabase-only, l'héberger sur **Gandi FTP** (statique, sous `guydemarle.com`, le moins cher/simple). Passer à **Vercel** seulement si besoin de SSR/SEO (Next.js), de serverless, ou de preview deploys par PR.

> ⚠️ Front statique Gandi + Supabase en accès direct ⇒ **les RLS sont l'unique barrière de sécurité** (règle 1.2 devient vitale) **et** tout tiers sensible/payant reste **derrière une Edge Function** (règle 1.6). Jamais d'appel direct front → tiers.

> 💬 **Prompt IA de démarrage** : « Mon app doit [besoin métier + volumétrie + tiers utilisés]. D'après les règles GDM, conseille-moi : (1) API Supabase PostgREST/Edge ou API maison Render ? (2) front statique sur Gandi FTP ou Vercel ? Justifie selon l'arbre de décision et liste les implications sécu (RLS, Edge Functions, secrets). »

Détail complet : `HEBERGEMENT_GANDI.md`.
~~~

- [ ] **Step 2 : Remplacer la ligne Hosting de §6**

Dans `## 6) Stack et conventions (rappel)`, remplacer la ligne :

`- **Hosting** : Vercel (front), Render (back lourd), Supabase Edge (proxy leger).`

par :

~~~markdown
- **Hosting** :
  - **Vercel** : front avec SSR/SEO ou serverless (Next.js), preview deploys.
  - **Gandi FTP** : front statique (SPA) quand l'API est Supabase-only — le moins cher/simple. Transport **SFTP/FTPS, jamais FTP en clair** ; `.env` hors webroot via `.htaccess`, jamais commité ; identifiants en GitHub Secrets ; RLS strictes obligatoires (seule barrière).
  - **Render** : back lourd (Node/Python).
  - **Supabase Edge** : proxy léger / logique liée à la BDD.
~~~

- [ ] **Step 3 : Ajouter la référence en §7**

Dans `## 7) References`, après la ligne :

`- \`ARCHITECTURE_SECURITE_GDM.md\` (reference complete)`

ajouter :

~~~markdown
- `HEBERGEMENT_GANDI.md` (hebergement Gandi FTP : quand le choisir, deploiement, securite)
~~~

- [ ] **Step 4 : Vérifier**

Run :
~~~bash
grep -n "Gandi" templates/.ai-rules/RULES.md
~~~
Expected : au moins 4 lignes (§0 décision, §0 prompt, §6 hosting, §7 référence).

- [ ] **Step 5 : Commit** *(jalon)*

~~~bash
git add templates/.ai-rules/RULES.md
git commit -m "docs(rules): cadre de decision stack + Gandi dans RULES.md"
~~~

---

## Task 3 : Tisser le cadre dans `ARCHITECTURE_SECURITE_GDM.md`

**Files:**
- Modify: `templates/docs-rules/ARCHITECTURE_SECURITE_GDM.md` (version, table des docs, Partie 3 Front + Back)

- [ ] **Step 1 : Bumper la version**

Remplacer la ligne :

`**Version** : 1.2 (mai 2026)`

par :

`**Version** : 1.3 (mai 2026)`

- [ ] **Step 2 : Ajouter la ligne dans la table « Les docs GDM de reference »**

Dans le tableau en tête, après la ligne :

`| **\`SECURITY_OSS_PIPELINE.md\`** | Détail du workflow GitHub Actions Security OSS | ~15 min |`

ajouter :

~~~markdown
| **`HEBERGEMENT_GANDI.md`** | Choisir et sécuriser un hébergement Gandi FTP (front statique) | ~10 min |
~~~

- [ ] **Step 3 : Enrichir la sous-section « Back » de la Partie 3**

Dans `## Partie 3 — Stack technique recommandée`, sous-section `### Back`, juste **après** le bloc « **Règle de choix** » (les 3 bullets se terminant par `→ **Supabase Edge Function**`), insérer :

~~~markdown

**Priorité : Supabase d'abord.** Pour la plupart des apps, le besoin est du CRUD sur Postgres + un proxy léger vers les tiers. Dans ce cas, **PostgREST** (API REST auto-générée par Supabase, sécurisée par les RLS) + **Edge Functions** (proxy/logique légère) suffisent et évitent de maintenir une API maison. Ne monter une **API Render** que si la logique ne rentre pas dans PostgREST/Edge : async lourd, orchestration, long-running, RAG, libs Python/ML.

> 💬 **Prompt IA — choix du back** : « Voici ce que doit faire mon app : [détail]. Une API Supabase PostgREST/Edge suffit-elle, ou ai-je besoin d'une API maison sur Render ? Justifie. »
~~~

- [ ] **Step 4 : Remplacer la ligne d'hébergement de la sous-section « Front »**

Dans `### Front`, remplacer la ligne :

`Hébergement : **Vercel** (déploiement auto depuis GitHub, preview deploys par PR, CDN intégré).`

par :

~~~markdown
**Hébergement du front** — deux options selon que le front a besoin de rendu serveur :

| Hébergeur | Quand l'utiliser |
|-----------|------------------|
| **Gandi FTP** (statique) | Front SPA statique + API Supabase-only. Le moins cher/simple, sous `guydemarle.com`. Détail : `HEBERGEMENT_GANDI.md`. |
| **Vercel** | Besoin de SSR/SEO (Next.js), de serverless, ou de preview deploys par PR. Déploiement auto depuis GitHub, CDN intégré. |

En pratique, « API Supabase-only » et « front statique » coïncident presque toujours (une app simple est une SPA). Le déclencheur Vercel est le besoin de **rendu serveur**.

> ⚠️ Front statique Gandi + Supabase en accès direct ⇒ **les RLS sont l'unique barrière** (Règle 2 vitale) et tout tiers sensible reste **derrière une Edge Function** (Règle 6).

> 💬 **Prompt IA — hébergement front** : « Mon front [SPA Vite ? besoin SEO/SSR ?]. D'après les règles GDM, un statique sur Gandi FTP suffit-il ou faut-il Vercel ? »
~~~

- [ ] **Step 5 : Vérifier**

Run :
~~~bash
grep -n "Version. : 1.3\|HEBERGEMENT_GANDI\|Priorité : Supabase\|Hébergement du front" templates/docs-rules/ARCHITECTURE_SECURITE_GDM.md
~~~
Expected : la version 1.3, la ligne de table, le titre « Priorité : Supabase d'abord », et « Hébergement du front ».

- [ ] **Step 6 : Commit** *(jalon)*

~~~bash
git add templates/docs-rules/ARCHITECTURE_SECURITE_GDM.md
git commit -m "docs(archi): arbre de decision back + hebergement front (Gandi/Vercel), v1.3"
~~~

---

## Task 4 : Ajouter le prompt de démarrage et la sous-section Gandi dans `SETUP_PROJET.md`

**Files:**
- Modify: `templates/docs-rules/SETUP_PROJET.md` (étape 10)

- [ ] **Step 1 : Ajouter le callout décision + prompt au début de l'étape 10**

Juste **après** le titre `## 10. Setup Vercel et/ou Render` et **avant** `### Si tu déploies un front sur Vercel`, insérer :

~~~markdown

> **Avant de choisir où déployer**, tranche l'archi (cf. `ARCHITECTURE_SECURITE_GDM.md` Partie 3) : API Supabase PostgREST/Edge en priorité, API maison Render seulement si nécessaire ; front statique → **Gandi FTP**, front avec rendu serveur → **Vercel**.
>
> 💬 **Prompt IA de démarrage** : « Mon app doit [besoin métier + volumétrie + tiers utilisés]. D'après les règles GDM (`.ai-rules/RULES.md`), conseille-moi : (1) API Supabase PostgREST/Edge ou API maison Render ? (2) front statique sur Gandi FTP ou Vercel ? Justifie selon l'arbre de décision et liste les implications sécu (RLS, Edge Functions, secrets). »
~~~

- [ ] **Step 2 : Ajouter la sous-section Gandi**

Juste **après** la sous-section `### Si tu déploies sur Supabase Edge Functions` (après le paragraphe se terminant par « Ils ne sont **jamais** exposés au client. ») et **avant** le `---` qui clôt l'étape 10, insérer :

~~~markdown

### Si tu déploies un front statique sur Gandi FTP

Pour une SPA statique (API Supabase-only), Gandi FTP est le choix le moins cher/simple. Détail complet (déploiement, secrets, sécurité) : `HEBERGEMENT_GANDI.md`. En résumé :

1. Build du front en **CI** (GitHub Actions), pas en local pour la prod.
2. Déploiement par **SFTP/FTPS** (jamais FTP en clair), identifiants en **GitHub Secrets**.
3. Aucun secret dans le build (règle `VITE_*`) ; `.env` serveur éventuel **hors webroot**, protégé par `.htaccess`.
4. RLS Supabase strictes obligatoires (le front parle à Supabase en direct).
~~~

- [ ] **Step 3 : Vérifier**

Run :
~~~bash
grep -n "Prompt IA de démarrage\|front statique sur Gandi FTP" templates/docs-rules/SETUP_PROJET.md
~~~
Expected : 2 occurrences (le callout au début de l'étape 10, et le titre de la sous-section).

- [ ] **Step 4 : Commit** *(jalon)*

~~~bash
git add templates/docs-rules/SETUP_PROJET.md
git commit -m "docs(setup): prompt de demarrage + sous-section deploiement Gandi"
~~~

---

## Task 5 : Vérification globale de cohérence

**Files:** (lecture seule)

- [ ] **Step 1 : Tous les renvois pointent vers le nouveau doc**

Run :
~~~bash
grep -rn "HEBERGEMENT_GANDI" templates/
~~~
Expected : présence dans `RULES.md` (§7), `ARCHITECTURE_SECURITE_GDM.md` (table + Front), `SETUP_PROJET.md` (sous-section Gandi), et le fichier lui-même.

- [ ] **Step 2 : Aucune contradiction sur les tiers / RLS**

Run :
~~~bash
grep -rn "Edge Function\|unique barrière\|seule barrière" templates/docs-rules/HEBERGEMENT_GANDI.md templates/.ai-rules/RULES.md
~~~
Expected : la règle « tiers derrière Edge Function » et « RLS = barrière unique » apparaît de façon cohérente (renforce Règles 2 et 6, ne les remplace pas).

- [ ] **Step 3 : Cohérence terminologique des prompts**

Run :
~~~bash
grep -rn "Prompt IA" templates/
~~~
Expected : encadrés présents dans `RULES.md`, `ARCHITECTURE_SECURITE_GDM.md` (back + front), `SETUP_PROJET.md`, `HEBERGEMENT_GANDI.md` — tous au format « 💬 **Prompt IA … » ».

- [ ] **Step 4 : Diff de revue**

Run :
~~~bash
git diff --stat
~~~
Expected : 4 fichiers touchés (1 créé + 3 modifiés). Relire le diff avant de pousser.

---

## Self-Review (effectuée pendant la rédaction)

**Couverture du spec :**
- Modèle de décision (spec §3) → Task 2 Step 1 (RULES §0) + Task 3 Steps 3-4 (ARCHITECTURE Partie 3). ✓
- Fichiers touchés (spec §4) → Tasks 2, 3, 4. ✓
- Nouveau doc, 11 points (spec §5) → Task 1 (sections 1-11). ✓
- Pattern prompt IA (spec §6) → encadrés dans Tasks 1, 2, 3, 4. ✓
- PHP legacy encadré (spec §2.6 / nouveau doc §8) → Task 1 section 8. ✓
- Règle RLS unique + Edge (spec §3) → Task 1 section 3, RULES §0, ARCHITECTURE Front. ✓
- Critères d'acceptation (spec §8) → couverts par Tasks 1-4 + vérifs Task 5. ✓

**Placeholder scan :** les `[...]` dans les prompts IA sont **volontaires** (champs à remplir par le dev) ; ce ne sont pas des placeholders de plan. Aucun « TODO/TBD » de plan.

**Cohérence des noms :** `HEBERGEMENT_GANDI.md`, `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `GANDI_SFTP_HOST/USER/PASSWORD` utilisés de façon identique entre Task 1 (workflow) et les renvois. ✓
