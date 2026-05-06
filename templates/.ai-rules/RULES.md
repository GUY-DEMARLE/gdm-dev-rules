# Règles Dev GDM — Version condensée pour IA

> Source unique de vérité. Si tu modifies ce fichier, modifie aussi les références dans `CLAUDE.md` et `.cursor/rules/gdm-rules.mdc` si besoin (normalement ils pointent vers ce fichier).

## Architecture imposée

Tout projet GDM suit ce schéma :

```
Front (Vercel) → Back (Render/Vercel/Supabase Edge) → Services tiers (Gemini, OpenAI, Stripe...)
```

- **Front** : React/Vite ou Next.js. Aucun secret. Appelle uniquement notre back.
- **Back** : Node.js (Express/Fastify) ou Python (FastAPI/Flask). Détient TOUTES les clés sensibles.
- **BDD** : Supabase par défaut. RLS obligatoires sur toutes les tables.

## Les 6 règles non-négociables

### 1. Aucun secret dans Git

Tout fichier qui pourrait contenir un secret est dans `.gitignore` (`.env`, `.env.local`, `.env.production`, etc.). Un hook gitleaks bloque les commits qui contiennent une clé. Si tu génères du code, tu n'écris JAMAIS une clé en dur.

### 2. Toute table Supabase a des RLS actives

Quand tu génères une migration SQL pour créer une table, tu ajoutes immédiatement après :

```sql
ALTER TABLE public.ma_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY "policy_name" ON public.ma_table
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);
```

Pas de migration sans RLS. Pas de policy qui fait confiance au client (toujours `auth.uid()`, jamais un `user_id` du body).

### 3. Pas de push direct sur `main` ou `staging`

Workflow : `dev-prenom → feature/xxx → dev → staging → main`. Toujours via Pull Request.

### 4. Variables d'env dans la plateforme, jamais dans le repo

Vraies valeurs : Vercel / Render / Supabase Edge Functions Secrets / GitHub Actions Secrets. Jamais commitées. `.env.example` contient uniquement des placeholders.

### 5. Aucun secret dans `VITE_*`, `NEXT_PUBLIC_*`, `REACT_APP_*`

Ces préfixes sont publics par construction (Vite/Next/CRA inlinent la valeur dans le bundle au build). Test mental : *"Si la fuite causait une rotation, ce n'est pas une variable VITE_*."*

| Type de valeur | Préfixe | Exemples |
|----------------|---------|----------|
| URL publique, clé anon Supabase, Stripe `pk_live_` | `VITE_` | `VITE_API_URL`, `VITE_SUPABASE_ANON_KEY` |
| Clé secrète (API Gemini/OpenAI/Stripe, password, JWT secret) | **PAS de préfixe** | `GEMINI_API_KEY`, `STRIPE_SECRET_KEY`, `DATABASE_URL` |

**Pas de fallback "mode dev" qui contourne le proxy** : si tu vois `if (proxy) {...} else { appel direct avec clé }`, refuse — supprime la branche `else`. Vite inline la clé dans le bundle même si la branche n'est pas exécutée en prod.

### 6. Front parle au back, le back parle aux services tiers

Le front ne contient JAMAIS de clé qui authentifie auprès d'un service tiers payant. Si une fonctionnalité a besoin d'une telle clé, on monte un endpoint sur notre back qui sert de proxy.

Le back qui fait proxy doit :
- Authentifier l'utilisateur avant de relayer
- Valider les inputs (Zod / Pydantic)
- Verrouiller les paramètres coûteux côté serveur (modèle Gemini, max_tokens)
- Construire le prompt système côté serveur
- Rate-limiter par IP et par utilisateur

## Patterns de clés à reconnaître

| Service | Pattern | Statut |
|---------|---------|--------|
| Anthropic | `sk-ant-api03-...` | **Secret** |
| OpenAI | `sk-...` ou `sk-proj-...` | **Secret** |
| Google API (Gemini, Maps) | `AIza` + 35 car. | **Secret** |
| Stripe Secret | `sk_live_...` ou `sk_test_...` | **Secret** |
| Stripe Publishable | `pk_live_...` ou `pk_test_...` | Public OK |
| AWS Access Key | `AKIA` + 16 car. | **Secret** |
| GitHub PAT | `ghp_` + 36 car. | **Secret** |
| JWT (Supabase, Auth0...) | `eyJ...` + 2 points | Selon le `role` |

JWT : décoder sur jwt.io. `role: anon` = public OK, `role: service_role` = JAMAIS dans le bundle.

## Comportement attendu de l'IA

Quand tu génères du code, tu :

1. **N'écris jamais de clé en dur**, même en exemple ou en commentaire. Utilise des placeholders du genre `your-key-here` ou `process.env.X`.
2. **Refuses de mettre une clé secrète dans une variable préfixée** `VITE_*`, `NEXT_PUBLIC_*`, `REACT_APP_*`. Si l'utilisateur insiste, explique pourquoi c'est dangereux.
3. **Proposes systématiquement une architecture proxy** quand l'utilisateur veut intégrer un service tiers depuis le front.
4. **Active RLS dès la création** d'une table Supabase, dans la même migration. Pas de "on l'ajoutera après".
5. **N'ajoutes pas de fallback "mode dev"** dans le code client qui utilise une clé directement. Si le proxy n'est pas dispo, le code doit `throw`, pas fournir un chemin alternatif.
6. **Vérifies les patterns de clés** dans le code généré : aucune chaîne ne doit matcher un pattern de la table ci-dessus.
7. **Utilises `.env.example`** avec des placeholders pour documenter les variables, jamais une vraie valeur.

## Stack technique (rappel)

- **Front** : React/Vite ou Next.js, TypeScript, Tailwind, shadcn/ui, Zustand ou React Context
- **Back Node.js** : Express ou Fastify, TypeScript, Zod
- **Back Python** : FastAPI ou Flask, Pydantic
- **BDD** : Supabase (PostgreSQL + Auth + Storage)
- **Hébergement** : Vercel (front), Render (back lourd), Supabase Edge Functions (proxies légers)
- **Tests** : Vitest + Playwright (Node), pytest (Python)

## Conventions

- **Branches** : `dev-prenom`, `feature/xxx`, `fix/xxx`
- **Commits** : `type(scope): description` (feat, fix, chore, docs, style, refactor, test, perf)
- **Repos** : `gdm-<type>-<nom>` sous l'org `GUY-DEMARLE`
- **Node** : v20 LTS (fixé dans `.nvmrc`)
- **Python** : 3.11+

## En cas de doute

Si l'utilisateur demande quelque chose qui violerait une de ces règles, **explique pourquoi c'est risqué et propose l'alternative correcte**. Ne te contente pas de refuser, oriente vers la bonne pratique.

Référence complète des docs GDM :
- `SETUP_MACHINE.md` — installation outils par dev
- `SETUP_PROJET.md` — config par projet
- `ARCHITECTURE_SECURITE_GDM.md` — référence permanente
