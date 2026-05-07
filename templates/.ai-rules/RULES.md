# Règles Dev GDM — Source IA unique

Version condensée mais **opérationnelle** pour IA (Claude, Cursor, Codex).

## 0) Cadre global

Architecture imposée par défaut :

```
Front (Vercel) -> Back (Render/Vercel/Supabase Edge) -> Services tiers (Gemini/OpenAI/Stripe/etc.)
```

- **Front** : React/Vite ou Next.js, aucun secret, appelle uniquement le back.
- **Back** : Node.js (Express/Fastify) ou Python (FastAPI/Flask), détient les secrets.
- **BDD** : Supabase (PostgreSQL) avec RLS activée sur toutes les tables.

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
- Le back proxy doit :
  - authentifier l'utilisateur,
  - valider les inputs (Zod/Pydantic),
  - verrouiller les parametres couteux (modele, max tokens, etc.),
  - construire le prompt systeme cote serveur,
  - appliquer rate limit IP + utilisateur,
  - ajouter captcha si endpoint public,
  - journaliser les appels.

## 2) Checklists minimales obligatoires

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
- CI securite verte (gitleaks au minimum).

### 2.5 Avant chaque deploiement prod

- Scanner le bundle compile pour patterns de secrets.
- Si pattern trouve -> deploiement bloque, correction obligatoire.

### 2.6 Audit periodique (obligatoire)

- Frequence minimale : mensuel pendant 3 mois apres lancement, puis trimestriel.
- Lancer `gitleaks detect --source . --verbose --no-banner` sur chaque repo actif.
- Verifier les tables Supabase sans RLS via requete SQL de controle.
- Auditer les apps exposees avec :

```bash
uvx supabomb discover --url https://votre-app.example.com/
```

- Pour chaque endpoint/fonction detecte par `supabomb`, verifier :
  - auth,
  - validation input,
  - rate limiting,
  - aucun parametre sensible pilotable par le client.
- Si GitHub Advanced Security (GHAS) est disponible, activer aussi Secret Scanning + Push Protection.

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

## 6) Stack et conventions (rappel)

- **Front** : React/Vite ou Next.js, TypeScript.
- **Back** : Node.js (Express/Fastify) ou Python (FastAPI/Flask), Deno uniquement pour Supabase Edge Functions.
- **BDD** : Supabase par defaut.
- **Hosting** : Vercel (front), Render (back lourd), Supabase Edge (proxy leger).
- **Branches** : `dev-prenom`, `feature/xxx`, `fix/xxx`.
- **Commits** : Conventional commits (`feat`, `fix`, `chore`, etc.).
- **Repo** : `gdm-<type>-<nom>` sous `GUY-DEMARLE`.

## 7) References

- `SETUP_MACHINE.md` (setup poste dev)
- `SETUP_PROJET.md` (setup projet)
- `ARCHITECTURE_SECURITE_GDM.md` (reference complete)
