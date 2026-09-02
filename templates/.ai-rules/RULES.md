# Règles Dev GDM — Source IA unique

Version condensée mais **opérationnelle** pour IA (Claude, Cursor, Codex).

## 0) Cadre global

Architecture par défaut (à adapter selon la décision ci-dessous) :

```
Front (SPA statique -> Gandi FTP  |  SSR/serverless -> Vercel)
   -> Back (Supabase PostgREST + Edge Functions en priorité  |  Render si logique lourde)
   -> Services tiers (Gemini/OpenAI/Stripe/etc.)
```

- **Front** : React/Vite (SPA) ou Next.js (SSR). Aucun secret, appelle uniquement le back. Hébergé sur **Gandi FTP** (statique) ou **Vercel** (SSR/serverless) — cf. décision ci-dessous.
- **Back** : **Supabase (PostgREST + Edge Functions)** en priorité ; **Render** (Node.js Express/Fastify, ou Python FastAPI/Flask) pour la logique lourde. Détient les secrets.
- **BDD** : Supabase (PostgreSQL) avec RLS activée sur toutes les tables.

### Choix de stack et d'hébergement (à trancher au démarrage)

Deux décisions chaînées :

1. **Back / API** — prioriser **Supabase (PostgREST + Edge Functions)** tant que le besoin est du CRUD sur Postgres + proxy léger vers les tiers. Monter une **API maison sur Render** (Node/Python) seulement pour la logique qui ne rentre pas dans PostgREST/Edge : async lourd, orchestration, long-running, RAG, libs Python/ML.
2. **Front / hébergement** — si le front est une **SPA statique** (pas de rendu serveur) et que l'API est Supabase-only, l'héberger sur **Gandi FTP** (statique, sous `guydemarle.com`, le moins cher/simple). Passer à **Vercel** seulement si besoin de SSR/SEO (Next.js), de serverless, ou de preview deploys par PR.

> ⚠️ Front statique Gandi + Supabase en accès direct ⇒ **les RLS sont l'unique barrière de sécurité** (règle 1.2 devient vitale) **et** tout tiers sensible/payant reste **derrière une Edge Function** (règle 1.6). Jamais d'appel direct front → tiers.

> 💬 **Prompt IA de démarrage** : « Mon app doit [besoin métier + volumétrie + tiers utilisés]. D'après les règles GDM, conseille-moi : (1) API Supabase PostgREST/Edge ou API maison Render ? (2) front statique sur Gandi FTP ou Vercel ? Justifie selon l'arbre de décision et liste les implications sécu (RLS, Edge Functions, secrets). »

Détail complet : `HEBERGEMENT_GANDI.md`.

## 1) Les 6 règles non-negociables

### 1.1 Aucun secret dans Git

- Interdit : clés API, tokens, mots de passe, certificats, credentials committés.
- `.env*` (sauf `.env.example`) doit etre ignore.
- `gitleaks` doit bloquer localement + en CI.
- **Jamais de clé en dur**, meme dans commentaires/exemples.

### 1.2 Toute table Supabase a RLS active des la migration

Chaque `CREATE TABLE` doit etre suivi de :

```sql
ALTER TABLE public.ma_table ENABLE ROW LEVEL SECURITY;
CREATE POLICY "policy_name" ON public.ma_table
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);
```

- Pas de "on ajoutera RLS plus tard".
- Policy basee sur `auth.uid()`, jamais confiance a un `user_id` venant du client.

### 1.3 Pas de push direct sur `main` / `staging`

- Merge uniquement via PR.
- Branch protection active (`Require PR`, checks obligatoires, pas de bypass).

### 1.4 Variables d'env dans la plateforme, jamais dans le repo

- Vraies valeurs dans Vercel / Render / Supabase Secrets / GitHub Secrets.
- Sur **Gandi** (pas de plateforme de variables) : `.env` hors webroot protégé par `.htaccess`, et identifiants de déploiement en GitHub Secrets. Jamais commité.
- `.env.example` contient des placeholders uniquement.
- Aucun historique Git ne doit contenir de secret.

### 1.5 Aucun secret dans `VITE_*`, `NEXT_PUBLIC_*`, `REACT_APP_*`

Ces préfixes sont **publics par design** (inline dans bundle).

Test mental obligatoire :
> Si la fuite impose une rotation, ce n'est PAS une variable publique.

| Type de valeur | Prefixe |
|---|---|
| URL publique, clé anon Supabase, Stripe `pk_*` | `VITE_` / `NEXT_PUBLIC_` / `REACT_APP_` |
| Clé secrete, password, token admin, `service_role` | Aucun prefixe, back uniquement |

Interdit absolu : fallback client du type "si proxy indisponible, appel direct avec clé".

### 1.6 Front -> Back -> Services tiers

- Le front ne parle pas directement aux services tiers sensibles/payant.
- Ce « back » peut être une **Edge Function Supabase** (cas front statique Gandi + Supabase) ou une API Render. PostgREST seul n'expose que les tables : il ne remplace pas le proxy pour les tiers.
- Le back proxy doit :
  - authentifier l'utilisateur,
  - valider les inputs (Zod/Pydantic),
  - verrouiller les parametres couteux (modele, max tokens, etc.),
  - construire le prompt systeme cote serveur,
  - appliquer rate limit IP + utilisateur,
  - ajouter captcha si endpoint public,
  - journaliser les appels.

## 2) Checklists minimales obligatoires

Le socle standard sur les apps actives est :

```text
Avant merge  -> Security OSS bloque Gitleaks, Semgrep et OSV.
Chaque lundi -> Security OSS lance l'audit complet et envoie Slack.
Production   -> Sentry surveille erreurs, latence, routes critiques et couts IA.
```

### 2.1 Avant de coder une fonctionnalite

- Identifier les secrets impliques.
- Si service tiers sensible/payant : back obligatoire.
- Verifier les variables env (public vs secret).
- Definir le flux de donnees front -> back -> tiers.

### 2.2 A chaque ajout de variable d'env

- Secret ? -> back uniquement, sans prefixe public.
- Non secret ? -> variable publique possible.
- Ajouter placeholder dans `.env.example`.
- Mettre la vraie valeur en plateforme, jamais en repo.

### 2.3 A chaque nouvelle table Supabase

- RLS activee dans la meme migration.
- Policies explicites ajoutees.
- Verification anti-regression des tables sans RLS (script SQL ou CI).

### 2.4 Avant chaque PR

- Aucun `.env*` (hors `.env.example`) commite.
- Aucune chaine ressemblant a un secret.
- Architecture front/back respectee.
- CI securite verte :
  - `PR Security - Secrets + SAST` : Gitleaks + Semgrep.
  - `PR Security - OSV Scanner` : dependances vulnerables.
- Si Security OSS envoie un Slack d'echec : corriger les fichiers/packages cites avant merge.

### 2.5 Avant chaque deploiement prod

- Scanner le bundle compile pour patterns de secrets.
- Si pattern trouve -> deploiement bloque, correction obligatoire.

### 2.6 Audit periodique et monitoring (obligatoire)

- Frequence minimale : audit Security OSS chaque lundi.
- Le workflow Security OSS detecte la stack et lance selon les fichiers presents :
  - Gitleaks, Semgrep, OSV Scanner,
  - Composer audit si `composer.lock`,
  - npm audit si `package-lock.json`,
  - pip-audit si `requirements*.txt`,
  - Trivy si `Dockerfile`,
  - ZAP + Supabomb si `SECURITY_TARGET_URL`.
- Supabomb n'est pas lance via `uvx supabomb`; le workflow clone le repo officiel puis execute `uv run supabomb discover --url "$TARGET_URL"`.
- Les rapports sont envoyes dans Slack et conserves en artifacts GitHub Actions.
- Sentry doit etre installe sur les apps en prod pour suivre erreurs, latence, routes critiques, tokens et couts IA.
- Revue manuelle trimestrielle : RLS Supabase, variables d'env, acces dashboards, endpoints admin, roles utilisateurs.

## 3) Patterns de secrets a reconnaitre

| Service | Pattern indicatif | Statut |
|---|---|---|
| Anthropic | `sk-ant-api03-...` | Secret |
| OpenAI | `sk-...`, `sk-proj-...` | Secret |
| Google API | `AIza` + 35 caracteres | Secret |
| Stripe secret | `sk_live_...`, `sk_test_...` | Secret |
| Stripe publishable | `pk_live_...`, `pk_test_...` | Public OK |
| AWS access key id | `AKIA` + 16 caracteres | Secret |
| GitHub PAT classique | `ghp_...` | Secret |
| GitHub fine-grained PAT | `github_pat_...` | Secret |
| Slack bot/user | `xoxb-...`, `xoxp-...` | Secret |
| JWT | `eyJ...` + 2 points | Selon role |

JWT : decoder le payload. `role=anon` peut etre public, `role=service_role` est strictement secret.

## 4) Procedure incident (si fuite detectee)

1. Considerer le secret comme compromis.
2. Rotation immediate de la cle.
3. Mise a jour des plateformes + redeploiement.
4. Nettoyage historique Git si necessaire.
5. Verification des logs d'usage suspect.
6. Analyse de la cause racine (hook absent, CI absente, regle contournee, etc.).
7. Compte-rendu court + action preventive.

## 5) Comportement attendu de l'IA

Quand tu proposes ou modifies du code :

1. Ne jamais ecrire de secret en dur.
2. Refuser les secrets dans `VITE_*` / `NEXT_PUBLIC_*` / `REACT_APP_*`.
3. Proposer un proxy back pour tout service tiers sensible.
4. Activer RLS des la migration, avec policy.
5. Interdire les fallbacks client qui exposent la clé.
6. Verifier les patterns de secret dans le code genere.
7. Documenter les variables dans `.env.example` avec placeholders.
8. Si la demande viole une regle, expliquer le risque et proposer l'alternative sure.
9. Pour une demande d'audit securite app exposee, inclure un plan `supabomb` + controles auth/RLS.
10. Le workflow Security OSS est **obligatoire** sur toute app GDM (cf. 2.6) : il est pose a la racine par les scripts `gdm-dev-rules`. S'il manque dans `.github/workflows/`, le signaler et le remettre avant tout merge. Proposer en plus des monitors Sentry si absents.
11. Le workflow Security OSS est distribue **en copie complete** dans `.github/workflows/security-oss.yml` de chaque app, et c'est **voulu**. Une app n'appelle jamais un workflow heberge dans un autre depot : un `workflow_call` vers `gdm-dev-rules` ferait tourner du code central dans la CI de l'app avec les secrets de l'app, a chaque modification du depot central. **Ne pas remplacer cette copie par un caller**, ne pas la modifier localement, ne pas en ecrire un second. Toute evolution se fait dans `gdm-dev-rules` et se recupere avec `update`.
12. Au démarrage d'un projet, proposer le bon couple stack/hébergement : API Supabase PostgREST/Edge par défaut (Render seulement si logique lourde), front statique → Gandi FTP, front avec rendu serveur → Vercel. Rappeler que sur Gandi + Supabase en accès direct, les RLS sont l'unique barrière (cf. `HEBERGEMENT_GANDI.md`).
13. Pour toute interface (nouvel ecran, refonte, composant), appliquer le design system GDM : lire `system-design/AGENTS.md` avant de coder, consommer les jetons `var(--gd-*)`, ne pas reecrire un composant deja fourni par le kit.

## 6) Stack et conventions (rappel)

- **Front** : React/Vite ou Next.js, TypeScript.
- **Back** : **Supabase (PostgREST + Edge Functions)** par défaut ; Render avec Node.js (Express/Fastify) ou Python (FastAPI/Flask) pour la logique lourde. Deno uniquement pour les Edge Functions.
- **BDD** : Supabase par defaut.
- **Hosting** :
  - **Vercel** : front avec SSR/SEO ou serverless (Next.js), preview deploys.
  - **Gandi FTP** : front statique (SPA) quand l'API est Supabase-only — le moins cher/simple. Transport **SFTP/FTPS, jamais FTP en clair** ; `.env` hors webroot via `.htaccess`, jamais commité ; identifiants en GitHub Secrets ; RLS strictes obligatoires (seule barrière).
  - **Render** : back lourd (Node/Python).
  - **Supabase Edge** : proxy léger / logique liée à la BDD.
- **Branches** : `dev-prenom`, `feature/xxx`, `fix/xxx`.
- **Commits** : Conventional commits (`feat`, `fix`, `chore`, etc.).
- **Repo** : `gdm-<type>-<nom>` sous `GUY-DEMARLE`.
- **Interface** : design system GDM obligatoire (`system-design/` a la racine, pose par `gdm-dev-rules`). Jetons `var(--gd-*)` et composants du kit, aucune valeur en dur, aucune librairie de composants empilee par-dessus.

## 7) References

- `SETUP_MACHINE.md` (setup poste dev)
- `SETUP_PROJET.md` (setup projet)
- `ARCHITECTURE_SECURITE_GDM.md` (reference complete)
- `HEBERGEMENT_GANDI.md` (hebergement Gandi FTP : quand le choisir, deploiement, securite)
- `SECURITY_OSS_PIPELINE.md` (workflow GitHub Actions Security OSS)
- `security-monitoring-process.md` (process Security OSS + Sentry)
- `system-design/AGENTS.md` (design system GDM : jetons, composants, mascotte, checklist interface ; direction artistique complete dans `system-design/README.md`)
