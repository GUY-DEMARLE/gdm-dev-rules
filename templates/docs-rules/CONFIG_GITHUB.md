# Config GitHub d'une app GDM : Variables, Secrets et réglages

**Quand utiliser ce doc** : à la création d'une app, ou quand un workflow saute une étape « parce que X n'est pas configuré ».

Tout se règle dans le repo de l'app : **Settings → Secrets and variables → Actions**.

Cette page a **deux onglets**. Les workflows lisent `vars.NOM` dans l'onglet **Variables** et `secrets.NOM` dans l'onglet **Secrets**. Une valeur rangée dans le mauvais onglet est **invisible** pour le workflow : il fait comme si elle n'existait pas.

## La règle pour choisir l'onglet

> **Si la fuite de la valeur impose une rotation → Secret. Sinon → Variable.**

Une URL publique, un nom de modèle, une clé `anon` Supabase vont dans **Variables**. Elles restent lisibles, ce qui aide au débogage. Une clé d'API, un mot de passe, un webhook vont dans **Secrets**.

## Ce qu'il faut créer

### Security OSS (toutes les apps)

| Nom | Onglet | Obligatoire | À quoi ça sert |
|---|---|---|---|
| `SLACK_WEBHOOK_URL` | **Secrets** | Recommandé | Envoie les alertes de PR et le rapport du lundi dans Slack. Sans lui, les rapports restent seulement dans les artifacts GitHub Actions. |
| `SECURITY_TARGET_URL` | **Variables** | Recommandé pour toute app web en ligne | URL publique de l'app (ex : `https://mon-app.guydemarle.com`). Active ZAP et Supabomb dans l'audit du lundi. Absente, ou rangée dans Secrets : les deux scans sont sautés, avec un avertissement dans le log. |
| `OPENAI_API_KEY` | **Secrets** | Optionnel | Ajoute une synthèse IA en français au rapport Slack. Sans elle, le rapport part quand même. |
| `OPENAI_SECURITY_MODEL` | **Variables** | Optionnel | Modèle utilisé pour cette synthèse. Par défaut : `gpt-5.4-mini`. |

### Déploiement sur Gandi (apps front statiques uniquement)

Voir `HEBERGEMENT_GANDI.md` pour le workflow complet.

| Nom | Onglet | À quoi ça sert |
|---|---|---|
| `GANDI_SFTP_HOST` | **Secrets** | Serveur de déploiement |
| `GANDI_SFTP_USER` | **Secrets** | Identifiant de déploiement |
| `GANDI_SFTP_PASSWORD` | **Secrets** | Mot de passe de déploiement (ou clé SSH privée si SFTP par clé) |
| `VITE_SUPABASE_URL` | **Variables** | URL Supabase injectée au build (publique) |
| `VITE_SUPABASE_ANON_KEY` | **Variables** | Clé `anon` Supabase injectée au build (publique par construction, protégée par les RLS) |

### Ce qui ne va PAS sur GitHub

Les variables d'environnement de l'app elle-même (clés Gemini, Stripe, `SUPABASE_SERVICE_ROLE_KEY`, `SENTRY_DSN`…) vont sur la **plateforme qui exécute l'app** : Vercel, Render, Supabase Secrets. GitHub ne les connaît que si un workflow en a besoin pour builder ou déployer. Voir `SETUP_PROJET.md` étape 10.

## Où les créer : repository, pas environment

- Crée-les en **Repository** (bouton **New repository variable** / **New repository secret**).
- **Pas dans Settings → Environments.** Le workflow Security OSS ne déclare aucun environnement : une valeur rangée dans un environnement ne lui parvient pas.
- Une valeur commune à toutes les apps (par exemple `SLACK_WEBHOOK_URL`) peut être créée **au niveau de l'organisation**. Il faut alors vérifier que sa **Repository access** inclut bien l'app.

## Réglages du repo (une fois par app)

| Où | Quoi |
|---|---|
| Page d'accueil du repo → **About** → **Topics** | Ajouter `gdm-managed` : le robot de synchro de `gdm-dev-rules` équipe et tient l'app à jour. |
| **Settings → General → Pull Requests** | Cocher **Allow auto-merge** ; garder **Allow rebase merging**. |
| **Settings → Branches** → `dev` | PR obligatoire ; checks obligatoires : `PR Security - Secrets + SAST`, `PR Security - OSV Scanner`, `GDM Rules Guard` ; pas d'approbation obligatoire (les PR du robot se mergent seules). |
| **Settings → Branches** → `staging`, `main` | Voir `SETUP_PROJET.md` étape 7, avec en plus `GDM Rules Guard` dans les checks. |

Les noms de checks n'apparaissent dans la liste qu'après leur premier passage : règle la protection des branches après la première PR.

## Vérifier que c'est bon

1. **Actions → Security OSS → Run workflow** (laisse le champ URL vide pour tester la variable).
2. Sur la page du run, la section **Annotations** ne doit pas afficher d'avertissement « ZAP et Supabomb sautés ».
3. Dans l'artifact `security-audit-reports`, le fichier `security-summary.md` doit afficher ton URL sur la ligne `Target URL`, et non `not configured`.
4. Si `SLACK_WEBHOOK_URL` est configuré, le rapport arrive dans Slack.
