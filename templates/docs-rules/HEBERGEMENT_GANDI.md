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

Vérifier que `.github/workflows/security-oss.yml` est bien présent (il est posé par `install` / `update` de `gdm-dev-rules`) et configurer la variable GitHub `SECURITY_TARGET_URL`.

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
