# Architecture & Sécurité — Dev GDM

**Version** : 1.1 (mai 2026)
**Pour** : équipe dev interne + prestataires
**Lecture rapide** : Parties 1 et 2 (5 min) — le reste sert de référence détaillée.

## Le trio de docs GDM

Ce document fait partie d'un ensemble de 3 docs complémentaires :

| Doc | Quand l'utiliser | Durée |
|-----|------------------|-------|
| **`SETUP_MACHINE.md`** | Une seule fois, à l'arrivée dans l'équipe | ~30 min |
| **`SETUP_PROJET.md`** | À chaque nouveau projet | ~20 min |
| **`ARCHITECTURE_SECURITE_GDM.md`** *(ce doc)* | Référence permanente pour les décisions d'archi et de sécu | Lecture continue |

Si tu débutes : commence par `SETUP_MACHINE.md`, puis `SETUP_PROJET.md` sur ton premier projet, puis reviens ici pour la suite.

---

## Partie 1 — L'architecture en un coup d'œil

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   UTILISATEUR                                               │
│        │                                                    │
│        ▼                                                    │
│   ┌────────────┐                                            │
│   │  FRONT     │   Vercel                                   │
│   │  (public)  │   React/Vite ou Next.js                    │
│   └─────┬──────┘                                            │
│         │ HTTP                                              │
│         │ (uniquement vers notre back)                      │
│         ▼                                                   │
│   ┌────────────┐                                            │
│   │   BACK     │   Render OU Vercel OU Supabase Edge        │
│   │  (privé)   │   Node.js OU Python                        │
│   └─────┬──────┘                                            │
│         │                                                   │
│    ┌────┴────┬─────────┬──────────┐                         │
│    ▼         ▼         ▼          ▼                         │
│ ┌──────┐ ┌──────┐ ┌────────┐ ┌────────┐                     │
│ │Supa- │ │Gemini│ │Stripe  │ │Autres  │                     │
│ │base  │ │OpenAI│ │        │ │APIs    │                     │
│ └──────┘ └──────┘ └────────┘ └────────┘                     │
│   ↑ Toutes les clés sensibles vivent ici, côté back ↑       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Trois principes simples** :

1. **Le front ne contient AUCUN secret.** Il appelle uniquement le back.
2. **Le back détient TOUTES les clés sensibles.** Il appelle les services tiers.
3. **Les variables d'env vivent dans la plateforme** (Vercel/Render/Supabase), jamais dans le repo.

---

## Partie 2 — Les 6 règles non-négociables

| # | Règle | Outil qui l'applique | Setup |
|---|-------|---------------------|-------|
| 1 | Aucun secret dans Git | gitleaks pre-commit + CI | Cf. `SETUP_PROJET.md` étape 4-5 |
| 2 | Toute table Supabase a des RLS actives | Migration template + check CI | Cf. `SETUP_PROJET.md` étape 8 |
| 3 | Pas de push direct sur `main` ou `staging` | Branch protection GitHub | Cf. `SETUP_PROJET.md` étape 6 |
| 4 | Variables d'env dans la plateforme, jamais dans le repo | `.gitignore` + revue PR | Cf. `SETUP_PROJET.md` étape 2-3 |
| 5 | Aucun secret dans `VITE_*`, `NEXT_PUBLIC_*`, `REACT_APP_*` | Test mental + scan bundle | Cf. Partie 5 ci-dessous |
| 6 | Front parle au back, le back parle aux services tiers | Architecture imposée dès l'init | Cf. Partie 5 ci-dessous |

Si une règle est violée, le déploiement échoue ou la PR est bloquée. C'est tout.

---

## Partie 3 — Stack technique recommandée

### Front

| Choix | Quand l'utiliser |
|-------|------------------|
| **React + Vite + TypeScript** | App SPA classique sans besoin de SEO (outils internes, dashboards) |
| **Next.js + TypeScript** | App client-facing avec SEO important (catalogue, vitrine) |

Hébergement : **Vercel** (déploiement auto depuis GitHub, preview deploys par PR, CDN intégré).

### Back

Trois options selon le cas :

| Hébergeur | Langage | Quand l'utiliser |
|-----------|---------|------------------|
| **Render** | Node.js (Express/Fastify) ou Python (FastAPI/Flask) | API standalone, logique métier complexe, cron jobs, workers async |
| **Vercel** (API Routes Next.js) | Node.js / TypeScript | Si on est sur Next.js fullstack et que la logique back reste simple |
| **Supabase Edge Functions** | Deno / TypeScript | Petits proxies et triggers liés à la BDD Supabase, sans logique métier lourde |

**Règle de choix** :
- Le back fait > 5 endpoints métier ou de la logique async ? → **Render**
- L'app est un Next.js fullstack et le back tient en quelques routes simples ? → **Vercel API Routes**
- Le back est juste un proxy sécurisé vers un service tiers (Gemini, OpenAI, Stripe) avec validation ? → **Supabase Edge Function**

### Base de données

**Supabase (PostgreSQL managé)** par défaut. Auth intégrée, dashboard, real-time, storage. Pour les cas où Supabase n'est pas adapté (besoins spécifiques en prod), Render PostgreSQL en alternative.

### Langages back — cadrage

| Langage | Frameworks autorisés | Cas d'usage |
|---------|----------------------|-------------|
| **Node.js (TypeScript)** | Express, Fastify | API standard, intégrations diverses, cohérence avec le front TS |
| **Python** | FastAPI, Flask | Si l'app fait de la data/ML/IA, du scraping, ou utilise des libs Python spécifiques (pandas, requests) |
| **Deno** | Supabase Functions runtime uniquement | Edge Functions Supabase exclusivement |

**Pas d'autre langage back** sans validation explicite par la direction technique. PHP, Ruby, Go, Rust, Java ne sont pas exclus pour toujours, mais leur introduction doit être justifiée par un besoin précis qui n'a pas de bonne réponse en Node.js ou Python.

---

## Partie 4 — Protocole de sécurité au quotidien

À chaque moment du cycle de vie d'une app, voilà ce qu'il faut vérifier. Aucune étape ne doit prendre plus de 5 minutes.

### Étape 1 — Initialisation du projet

**Quand** : au moment du `git init`, avant le premier commit.

**Comment** : suivre `SETUP_PROJET.md` étapes 1 à 10. Ce doc t'amène d'un dossier vide à un projet entièrement configuré (gitleaks, Husky, CI, branch protection, RLS Supabase, etc.).

**Validation** : à la fin de `SETUP_PROJET.md`, les 5 tests de l'étape 10 doivent tous passer.

---

### Étape 2 — Architecture de l'app (avant de coder)

**Quand** : juste après l'init, avant d'écrire la première ligne de code métier.

**Décision à prendre** :

```
┌──────────────────────────────────────────────────┐
│  Mon app a besoin de quoi ?                      │
└──────────────────────────────────────────────────┘
              │
              ▼
   ┌──────────────────────┐
   │ Services tiers       │     OUI    ┌──────────────────┐
   │ payants ou sensibles │ ─────────► │  Back obligatoire│
   │ (Gemini, OpenAI,     │            │  (cf. tableau    │
   │  Stripe, AWS, etc.)  │            │   Partie 3)      │
   └──────────────────────┘            └──────────────────┘
              │ NON
              ▼
   ┌──────────────────────┐
   │ Données sensibles    │     OUI    ┌──────────────────┐
   │ ou logique métier    │ ─────────► │  Back obligatoire│
   │ qui doit pas fuiter  │            └──────────────────┘
   └──────────────────────┘
              │ NON
              ▼
   ┌──────────────────────┐
   │ Front seul OK        │
   │ (rare : juste UI     │
   │  + Supabase + auth)  │
   └──────────────────────┘
```

**Checklist** :

- [ ] Choix de l'hébergeur back (Render / Vercel API Routes / Supabase Edge)
- [ ] Choix du langage back (Node.js / Python / Deno)
- [ ] Liste des services tiers à intégrer → identifier où vivront leurs clés (toujours côté back)
- [ ] Schéma des appels : qui appelle qui (front → back → tiers)
- [ ] Aucun appel direct front → service tiers payant prévu

**Test mental à appliquer pour chaque variable d'env envisagée** :

> *"Si la fuite de cette valeur causait une rotation, ce n'est pas une variable VITE_*. Donc cette valeur vit côté back."*

---

### Étape 3 — Pendant le développement

**Quand** : au quotidien, à chaque fonctionnalité ajoutée.

**Le pattern correct pour appeler un service tiers** :

```
┌───────────────────────────┐         ┌──────────────────────┐
│        FRONT              │         │       BACK           │
│  (Vercel)                 │         │  (Render/Vercel/     │
│                           │         │   Supabase Edge)     │
│                           │         │                      │
│  fetch('/api/chat', {     │  POST   │  GEMINI_API_KEY      │
│    method: 'POST',        │ ──────► │  (var d'env back)    │
│    body: { message }      │         │                      │
│  })                       │         │  Valide message      │
│                           │         │  Verrouille modèle   │
│                           │         │  Construit prompt    │
│                           │         │  Appelle Gemini      │
│                           │         │  Retourne réponse    │
│                           │ ◄────── │                      │
└───────────────────────────┘         └──────────────────────┘

   ❌ JAMAIS                              ✓ TOUJOURS
   const ai = new GoogleGenAI({apiKey})  Le back détient la clé
```

**Checklist à chaque ajout de variable d'env** :

- [ ] La variable est-elle un secret ?
  - Oui → côté back uniquement, **sans préfixe** `VITE_*` / `NEXT_PUBLIC_*` / `REACT_APP_*`
  - Non → peut aller côté front avec le préfixe approprié
- [ ] La vraie valeur est dans la plateforme (Vercel/Render/Supabase), pas dans le repo
- [ ] `.env.example` mis à jour avec un placeholder

**Checklist à chaque création de table Supabase** :

- [ ] RLS activée dès la migration : `ALTER TABLE x ENABLE ROW LEVEL SECURITY`
- [ ] Au moins une policy explicite (sinon DENY ALL par défaut)
- [ ] La policy ne fait pas confiance au client (utiliser `auth.uid()`, pas un champ `user_id` du body)

**Checklist à chaque création d'endpoint back qui appelle un service tiers** :

- [ ] Authentification utilisateur vérifiée avant relais
- [ ] Inputs du client validés (schéma Zod ou Pydantic)
- [ ] Paramètres coûteux verrouillés côté serveur (modèle Gemini, max_tokens, etc.)
- [ ] Prompt système construit côté serveur (le client n'envoie que son input)
- [ ] Rate limiting par IP et par utilisateur
- [ ] Captcha (Turnstile/reCAPTCHA) validé côté serveur si exposé public
- [ ] Logs des appels pour détecter les abus

**Test rapide une fois par sprint** :

```powershell
# Vérifier qu'aucune variable VITE_ ne contient un mot suspect
Get-ChildItem -Recurse -File -Include *.ts,*.tsx,*.js,*.jsx -Exclude node_modules,dist,build |
    Select-String -Pattern "VITE_.*(API_KEY|SECRET|PASSWORD|TOKEN)"
```

Toute occurrence est suspecte → vérifier au cas par cas.

---

### Étape 4 — Avant chaque Pull Request

**Quand** : avant de cliquer sur "Create pull request".

**Checks automatiques (par la CI configurée dans `SETUP_PROJET.md`)** :

```
┌──────────────────────────────────────────┐
│  PR ouverte                              │
│        │                                 │
│        ▼                                 │
│  ┌─────────────┐                         │
│  │  gitleaks   │ ─── secret trouvé ──► ❌ Bloqué
│  └─────┬───────┘                         │
│        │ OK                              │
│        ▼                                 │
│  ┌─────────────┐                         │
│  │  lint       │ ─── erreur ──────────► ❌ Bloqué
│  └─────┬───────┘                         │
│        │ OK                              │
│        ▼                                 │
│  ┌─────────────┐                         │
│  │ type-check  │ ─── erreur ──────────► ❌ Bloqué
│  └─────┬───────┘                         │
│        │ OK                              │
│        ▼                                 │
│  ┌─────────────┐                         │
│  │ tests       │ ─── erreur ──────────► ❌ Bloqué
│  └─────┬───────┘                         │
│        │ OK                              │
│        ▼                                 │
│  ┌─────────────┐                         │
│  │check-rls.sql│ ─── table sans RLS ──► ❌ Bloqué
│  └─────┬───────┘                         │
│        │ OK                              │
│        ▼                                 │
│      Merge OK ✓                          │
└──────────────────────────────────────────┘
```

**Checklist du dev qui ouvre la PR** :

- [ ] Aucun fichier `.env*` ajouté (autre que `.env.example`)
- [ ] Aucun fichier de credentials, certificat, clé privée
- [ ] Aucune chaîne ressemblant à un secret hardcodé
- [ ] Si nouvelle variable d'env : ajoutée dans `.env.example` avec placeholder
- [ ] Si nouvelle table Supabase : RLS activée + policy explicite
- [ ] Si nouvel endpoint qui appelle un service tiers : validations en place

**Checklist du reviewer** :

- [ ] La PR ne mélange pas plusieurs sujets
- [ ] Les variables d'env nouvelles ont le bon préfixe (ou pas de préfixe pour les secrets)
- [ ] Pas de `console.log` qui logge un objet contenant un token, une session, ou un secret
- [ ] L'architecture front → back → tiers est respectée (pas d'appel direct front → tiers)

---

### Étape 5 — Avant chaque déploiement de prod

**Quand** : avant le merge `staging → main`, ou avant un déploiement manuel.

**Le test du bundle compilé — à lancer avant le déploiement** :

```powershell
# Après npm run build
$bundlePath = "dist/assets"  # Adapter selon la structure
$patterns = @{
    "Google API"       = "AIza[A-Za-z0-9_\-]{35}"
    "Anthropic"        = "sk-ant-api"
    "OpenAI"           = "sk-(proj-)?[A-Za-z0-9]{40,}"
    "Stripe Live"      = "sk_live_"
    "AWS Key"          = "AKIA[A-Z0-9]{16}"
    "GitHub PAT"       = "ghp_[A-Za-z0-9]{36}"
    "Service Role JWT" = '"role":"service_role"'
}

$found = $false
Get-ChildItem -Path $bundlePath -Recurse -File -Include *.js | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    foreach ($name in $patterns.Keys) {
        if ($content -match $patterns[$name]) {
            Write-Host "⚠️ $name trouvé dans $($_.Name)" -ForegroundColor Red
            $found = $true
        }
    }
}

if (-not $found) {
    Write-Host "✓ Bundle propre, déploiement autorisé" -ForegroundColor Green
}
```

**Si un seul pattern remonte → déploiement bloqué.** Refactorer pour passer par le back, supprimer la variable du build, rebuilder.

**Le test du bundle déployé — à lancer après le déploiement** :

```powershell
# Vérifier le site en prod comme un attaquant le ferait
$siteUrl = "https://votre-app.guydemarle.com"
$html = (Invoke-WebRequest -Uri $siteUrl -UseBasicParsing).Content
$jsFiles = [regex]::Matches($html, '/assets/[^"]+\.js') |
    ForEach-Object { $_.Value } | Sort-Object -Unique

foreach ($file in $jsFiles) {
    $url = "$siteUrl$file"
    $content = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    foreach ($name in $patterns.Keys) {
        if ($content -match $patterns[$name]) {
            Write-Host "⚠️ $name trouvé dans $url" -ForegroundColor Red
        }
    }
}
```

C'est exactement ce que font les bots de Google et de GitHub Secret Scanning.

---

### Étape 6 — Audit périodique

**Quand** : tous les mois pendant les 3 premiers mois d'application, puis tous les trimestres.

**Checklist trimestrielle** :

**1. Scan global gitleaks de tous les repos**

```powershell
$repos = @(
    "C:\Users\$env:USERNAME\Travail\repo-1",
    "C:\Users\$env:USERNAME\Travail\repo-2"
    # ... ajouter tous les repos actifs
)

foreach ($repo in $repos) {
    Write-Host "`n=== $repo ===" -ForegroundColor Cyan
    cd $repo
    gitleaks detect --source . --verbose --no-banner
}
```

**2. Vérification RLS sur tous les projets Supabase**

Pour chaque projet, dans le SQL editor :

```sql
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY rowsecurity, tablename;
```

Toute table avec `rowsecurity = false` est à corriger.

**3. Audit des bundles de prod**

Pour chaque app déployée, lancer le test du bundle déployé (Étape 5).

**4. Audit `supabomb` sur nos sites**

Pour chaque site GDM utilisant Supabase, vérifier ce que voit un attaquant externe :

```bash
uvx supabomb discover --url https://app.guydemarle.com/
```

Note les Edge Functions découvertes et vérifie qu'elles font bien leurs validations (modèle, prompt, auth, rate limit).

**5. Audit des variables d'env de chaque plateforme**

- Vercel → Settings → Environment Variables : vérifier qu'aucune `VITE_*` ne contient un secret
- Render → Service → Environment : lister toutes les variables, vérifier qu'elles sont toutes documentées
- Supabase → Edge Functions Secrets : pareil

**6. Audit des accès aux dashboards**

Lister les utilisateurs ayant accès à : Supabase, Vercel, Render, GitHub, Google Cloud, panel Gandi, Cloudflare. Révoquer les accès des anciens devs et prestataires terminés.

---

# DÉTAILS — RÉFÉRENCE COMPLÈTE

À partir d'ici, c'est la documentation détaillée. Tu n'as pas besoin de lire dans l'ordre — utilise comme une référence quand tu as une question précise.

---

## Partie 5 — Détail des règles 5 et 6 (les plus subtiles)

Les règles 1 à 4 sont expliquées en pratique dans `SETUP_PROJET.md`. Les règles 5 et 6 méritent un détail conceptuel ici parce qu'elles ne sont pas "un outil à installer" mais "une façon de penser l'architecture".

### Règle 5 — Aucun secret dans `VITE_*`, `NEXT_PUBLIC_*`, `REACT_APP_*`

**Pourquoi** : ces préfixes sont conçus pour exposer la valeur au navigateur. Vite/Next.js/CRA remplacent `import.meta.env.VITE_X` (ou équivalent) par la **valeur littérale** dans le bundle au moment du build. Le bundle est ensuite servi publiquement.

**Cas concret GDM (mai 2026)** : la clé `AIzaSyDaGt24qMlfCXQlYhJSSdsum6FrKTxSLn8` était dans le bundle public de `simu-recrutement.guydemarle.com`, accessible via F12 → Sources → Ctrl+F. Le projet GCP a été banni par Google après détection automatique. Cause : variable `VITE_GEMINI_API_KEY` lue dans une branche de fallback "mode dev". Vite inline la valeur même dans les branches non exécutées.

**Le piège technique à comprendre** :

JavaScript n'a **pas de code mort**. Tout le code part dans le bundle, même les branches `else` jamais atteintes en prod. Et Vite remplace **toutes** les références à `import.meta.env.VITE_X` par leur valeur, peu importe si la branche est exécutée ou pas.

```typescript
// Code source du dev
if (proxy.disponible()) {
  // OK, on passe par le back
} else {
  // ❌ Cette branche n'est jamais exécutée en prod, MAIS
  const apiKey = import.meta.env.VITE_GEMINI_API_KEY  // Vite inline ici
  new GoogleGenAI({ apiKey })
}
```

```javascript
// Bundle compilé (ce qui est servi au client)
if (proxy.disponible()) {
  // ...
} else {
  const apiKey = "AIzaSyDaGt24qMlfCXQlYhJSSdsum6FrKTxSLn8"  // valeur en dur
  new GoogleGenAI({ apiKey })
}
```

Même si la branche `else` n'est jamais atteinte, **la clé est lisible dans le bundle**. F12 → Ctrl+F → trouvée.

**Le test mental à appliquer** :

> *"Si la fuite de cette valeur causait une rotation, ce n'est pas une variable VITE_*."*

**Tableau de décision** :

| Type de valeur | Préfixe | Exemples |
|----------------|---------|----------|
| URL publique | `VITE_` | `VITE_API_URL`, `VITE_SUPABASE_URL` |
| Clé conçue pour être publique | `VITE_` | `VITE_SUPABASE_ANON_KEY`, Stripe `pk_live_...` |
| Clé secrète qui authentifie | **PAS de préfixe**, côté back uniquement | `GEMINI_API_KEY`, `STRIPE_SECRET_KEY`, `OPENAI_API_KEY` |
| Password, token admin | **PAS de préfixe**, côté back uniquement | `DATABASE_URL`, `JWT_SECRET`, `ADMIN_PASSWORD` |

**Pas de fallback "mode dev"** : ne jamais coder un `if (proxy disponible) { ... } else { appel direct avec clé en dur }`. Si le proxy n'est pas dispo en local, le code doit échouer franchement (`throw`) — pas fournir un chemin alternatif qui expose la clé.

---

### Règle 6 — Front parle au back, le back parle aux services tiers

**Pourquoi** : c'est l'architecture qui rend les Règles 1, 4 et 5 simples à respecter. Si le front n'a aucun secret par construction, il n'y a plus rien à protéger côté client.

**Cas concret GDM (mai 2026)** : le simulateur de recrutement appelait Gemini directement depuis le client en mode "Live API" (WebSocket vocal), avec la clé en dur. Refactor : le proxy Fly.io (`gemini-ws-proxy-gd.fly.dev`) détient la clé, le client se connecte au proxy, le proxy se connecte à Gemini.

**Architecture standard** :

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│              │  HTTPS  │              │  HTTPS  │              │
│   FRONT      │ ──────► │    BACK      │ ──────► │   GEMINI     │
│   (Vercel)   │         │   (Render)   │         │   OPENAI     │
│              │ ◄────── │              │ ◄────── │   STRIPE     │
│  Pas de clé  │  JSON   │  Toutes les  │  JSON   │              │
│              │         │  clés ici    │         │              │
└──────────────┘         └──────────────┘         └──────────────┘
```

**Règle structurelle** :

| Composant | Connaît les clés tierces ? | Hébergement |
|-----------|---------------------------|-------------|
| Front (navigateur) | Non, jamais | Vercel |
| Back (serveur) | Oui, dans ses var d'env | Render / Vercel API / Supabase Edge |
| Services tiers | Authentifiés par le back uniquement | Externes |

**Cas où une exception est tolérée** :

- Le front utilise Stripe Elements avec une **publishable key** (`pk_live_...`) → c'est conçu pour être public, OK.
- Le front utilise Supabase auth avec la **clé anon** → publique par design, OK (avec RLS strictes en complément).
- Le front utilise Sentry avec un **DSN public** → conçu pour être public, OK.

Toute autre situation où le front "doit" avoir une clé : c'est un signal qu'il manque un back, ou qu'on viole la Règle 5.

**Le piège du proxy mal sécurisé** :

Avoir un back qui sert de proxy ne suffit pas — il doit aussi **valider** ce qu'il relaie. Sur `simu-recrutement`, l'edge function `gemini-chat` existait bien (l'architecture était correcte sur le principe), mais elle acceptait n'importe quel modèle et n'importe quel prompt depuis le client. Résultat : un attaquant pouvait l'utiliser comme un service IA gratuit, faire dire n'importe quoi au chatbot "Sophie", désactiver les filtres de sécurité Google.

Le back doit donc :
- **Verrouiller les paramètres coûteux** côté serveur (modèle, max_tokens, etc.)
- **Construire le prompt système** côté serveur
- **Valider l'input utilisateur** (schéma Zod/Pydantic)
- **Authentifier l'utilisateur** avant de relayer
- **Limiter le rate** par IP et par utilisateur

Sans ces validations, le back est juste un relais aveugle — la clé ne fuit pas en clair, mais l'usage est détourné. C'est l'objet de la checklist "création d'endpoint back" à l'Étape 3 du quotidien (Partie 4).

---

## Partie 6 — Patterns de clés à reconnaître

Cette table sert à identifier rapidement un secret dans du code, un bundle, un screenshot, un email.

| Service | Pattern | Public/Secret |
|---------|---------|---------------|
| Anthropic | `sk-ant-api03-...` (~108 car.) | **Secret** |
| OpenAI | `sk-...` ou `sk-proj-...` | **Secret** |
| Google API (Gemini, Maps, Cloud) | `AIza` + 35 car. (39 total) | **Secret** |
| Stripe Secret | `sk_live_...` ou `sk_test_...` | **Secret** |
| Stripe Publishable | `pk_live_...` ou `pk_test_...` | Public OK |
| AWS Access Key ID | `AKIA` + 16 car. | **Secret** |
| AWS Secret Access Key | 40 car. base64 | **Secret** |
| GitHub Personal Access Token | `ghp_` + 36 car. | **Secret** |
| GitHub Fine-grained PAT | `github_pat_` + 82 car. | **Secret** |
| Slack Bot Token | `xoxb-...` | **Secret** |
| Slack User Token | `xoxp-...` | **Secret** |
| Supabase Anon (JWT `role: anon`) | `eyJ...` + 2 points | Public OK |
| Supabase Service Role (JWT `role: service_role`) | `eyJ...` + 2 points | **Secret** (admin BDD) |
| JWT générique | `eyJ` + `.` + `eyJ` + `.` + sig | Selon le `role` |

**Le piège des JWT** : tous commencent par `eyJ` (base64 de `{"`). Pour distinguer, décoder le payload sur https://jwt.io et lire le champ `role` :
- `"role": "anon"` → publique, OK
- `"role": "authenticated"` → token utilisateur, ne devrait pas traîner
- `"role": "service_role"` → JAMAIS dans le bundle, accès admin total

**Convention universelle** : `sk_` ou `sk-` = Secret Key (jamais côté client), `pk_` ou `pk-` = Publishable Key (OK côté client).

---

## Partie 7 — Procédure d'incident

Si un secret a été exposé :

**1. Considérer le secret comme définitivement compromis**

Pas de débat sur l'ampleur du leak. Le coût d'une rotation est faible, le coût de se tromper est potentiellement énorme.

**2. Rotation immédiate**

| Service | Où roter |
|---------|----------|
| Supabase | Project Settings → API → Reset anon key / Reset service role key |
| Google Cloud | APIs & Services → Credentials → Delete + Create new |
| Anthropic | https://console.anthropic.com/settings/keys |
| OpenAI | https://platform.openai.com/api-keys |
| Stripe | Developers → API keys → Roll keys |
| GitHub PAT | Settings → Developer settings → Personal access tokens |
| AWS | IAM → Users → Security credentials |
| SFTP / SSH | Panel de l'hébergeur (Gandi, OVH, etc.) |

**3. Mettre à jour toutes les apps consommatrices**

Variables Vercel, Render, GitHub Actions Secrets, Supabase Edge Functions Secrets. Re-déployer.

**4. Nettoyer l'historique Git** (si le repo est ou peut devenir public)

```bash
# Avec git filter-repo (à installer : pip install git-filter-repo)
git filter-repo --replace-text <(echo "AIzaSyDaGt24qMlfCXQlYhJSSdsum6FrKTxSLn8==>REDACTED")
git push --force-with-lease
```

Destructif : à coordonner avec l'équipe (chaque dev devra re-cloner).

**5. Investiguer l'origine**

Pourquoi le hook gitleaks n'a pas attrapé ? Hook installé ? CI active ? Pattern manquant ?

**6. Vérifier les logs du service**

Pic anormal, requêtes inattendues, IP inconnues, actions suspectes. Si activité détectée, c'est un incident d'intrusion (notification CNIL si données perso, audit forensique éventuel).

**7. Documenter l'incident**

Un compte-rendu d'une page : quoi, quand, comment, durée d'exposition, actions correctives, mesures préventives. Sert pour le RGPD et pour ne pas refaire la même erreur.

---

## Partie 8 — Cas concrets GDM (mai 2026)

Ces incidents ont déclenché ce doc. Ils servent d'exemples pour l'équipe.

### Incident 1 — Clé Supabase de `gestionnaire-kit` (Règle 1 violée)

7 commits sur 1 mois, clé dans le code et la doc. Détection : audit Safercy + `gitleaks detect`. Cause : pas de hook pre-commit. Fix : rotation Supabase, nettoyage Git, hook installé. **Leçon** : la Règle 1 aurait bloqué les 7 commits.

### Incident 2 — Clé Gemini dans le bundle de `simu-recrutement` (Règles 5 et 6 violées)

Clé `AIzaSyDaGt...` dans le bundle public, accessible F12. Projet GCP banni par Google. Cause : variable `VITE_GEMINI_API_KEY` lue dans une branche de fallback "mode dev". Vite inline la valeur au build. Fix : suppression de la branche, refactor pour passer toujours par le proxy, rotation. **Leçon** : la Règle 5 aurait évité le problème dès l'écriture du code.

### Incident 3 — Password SFTP Gandi en clair dans la doc (Règle 1 violée)

`GANDI_SFTP_PASSWORD=e9f4af68...` dans `DEPLOY_GUIDE.md`. Donne accès en écriture au serveur de prod. Détection : `gitleaks detect`. Fix : rotation password, doc réécrite, nettoyage Git, vérif logs SFTP. **Leçon** : un secret en clair dans une doc est aussi grave qu'un secret dans le code.

### Incident 4 — Tables Supabase sans RLS (Règle 2 violée)

Table `operations` lisible et écrivable par n'importe qui. L'auditeur a fait un INSERT en 1 requête. Détection : audit Safercy + `supabomb`. Cause : RLS non activée. Fix : activation RLS + policies sur toutes les tables. **Leçon** : la Règle 2 aurait évité l'exposition.

---

## Partie 9 — Évolutions du doc

Ce doc évolue avec les incidents. À chaque nouveau cas significatif, ajouter en Partie 8 et mettre à jour la version en haut.

Idées d'extensions futures (à ajouter quand le besoin se confirme, pas avant) :

- Procédure de départ d'un dev (révocation accès, rotation des secrets vus)
- Convention de nommage des secrets dans Vercel/Render/GitHub Actions
- Politique de rétention et chiffrement des sauvegardes
- Procédure de notification CNIL
- Tests d'intrusion réguliers (annuels) avec un prestataire externe

Avant d'ajouter quoi que ce soit, **les 6 règles de la Partie 2 doivent être appliquées sur 100% des projets actifs**. Sinon on empile sans solidifier.
