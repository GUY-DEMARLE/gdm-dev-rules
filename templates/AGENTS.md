# Instructions pour Codex

Ce projet suit les règles de développement et de sécurité de Guy Demarle.

**Avant de générer du code ou de modifier ce projet, lis impérativement le fichier `.ai-rules/RULES.md`** à la racine. Il contient :

- L'architecture imposée (front Vercel → back Render/Vercel/Supabase Edge → services tiers)
- Les 6 règles non-négociables (gitleaks, RLS Supabase, branch protection, variables d'env, préfixes VITE_*, architecture front/back)
- Les patterns de clés à reconnaître (Anthropic, Google, Stripe, AWS, JWT...)
- Le comportement attendu de l'IA (jamais de clé en dur, proxy systématique, RLS dès la migration, etc.)
- La stack technique recommandée et les conventions
- Le process Security OSS : Gitleaks/Semgrep/OSV sur PR, audit hebdomadaire Slack, artifacts GitHub Actions
- Le process Sentry : erreurs, performance, routes lentes, tokens et couts IA en production

Tu dois respecter ces règles dans tout ce que tu génères. Si une demande te paraît contraire à une règle, explique pourquoi c'est risqué et propose l'alternative correcte.

Le pipeline de sécurité `.github/workflows/security-oss.yml` est **obligatoire** (`RULES.md` § 2.6) et posé automatiquement par `gdm-dev-rules`. Il est distribué en **copie complète, délibérément** : une app n'appelle jamais un workflow hébergé dans un autre dépôt. **Ne remplace pas cette copie par un caller `workflow_call`**, ne la modifie pas localement, n'en écris pas un second — toute évolution se fait dans la source et arrive par `update`.

## Design system Guy Demarle

Le dossier `system-design/` est à la racine du repo. Il est posé et mis à jour automatiquement par `gdm-dev-rules` : ne le modifie pas ici, toute évolution se fait dans la source (`GUY-DEMARLE/gdm-dev-rules`, `templates/system-design/`).

**Avant de créer ou de modifier la moindre interface, lis `system-design/AGENTS.md` et applique-le.** Jetons, composants et mascotte sont fournis dans `system-design/kit/`, il n'y a rien à redessiner. Aucune couleur, taille de texte, rayon ou durée n'est écrite en dur — uniquement des `var(--gd-*)`.

- Rendu visuel de tout le kit : ouvre `system-design/kit/demo.html` dans un navigateur.
- Direction artistique et justification des arbitrages : `system-design/README.md`.
- Contrôle automatique avant de dire que c'est fini : `node system-design/outils/verifier-interface.mjs <dossier du front>`.

## Contexte du projet

<!-- À compléter par dev pour chaque projet : -->
<!-- - Type d'app : (interne / client-facing) -->
<!-- - Stack utilisée : (Next.js + Render Node, ou React/Vite + Render Python, etc.) -->
<!-- - Services tiers intégrés : (Supabase, Gemini, Stripe...) -->
<!-- - Particularités : (chose à savoir avant de coder dans ce repo) -->

## Règles spécifiques à ce projet

<!-- À compléter par dev si ce projet a des règles en plus des règles GDM générales -->
<!-- Exemple : -->
<!-- - Cette app utilise FastAPI côté back, pas Express -->
<!-- - La BDD utilise un schéma `inventory` en plus du schéma `public` -->
<!-- - Les tests E2E sont obligatoires pour les endpoints de paiement -->
