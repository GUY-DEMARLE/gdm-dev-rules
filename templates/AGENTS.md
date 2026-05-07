# Instructions pour Codex

Ce projet suit les règles de développement et de sécurité de Guy Demarle.

**Avant de générer du code ou de modifier ce projet, lis impérativement le fichier `.ai-rules/RULES.md`** à la racine. Il contient :

- L'architecture imposée (front Vercel → back Render/Vercel/Supabase Edge → services tiers)
- Les 6 règles non-négociables (gitleaks, RLS Supabase, branch protection, variables d'env, préfixes VITE_*, architecture front/back)
- Les patterns de clés à reconnaître (Anthropic, Google, Stripe, AWS, JWT...)
- Le comportement attendu de l'IA (jamais de clé en dur, proxy systématique, RLS dès la migration, etc.)
- La stack technique recommandée et les conventions

Tu dois respecter ces règles dans tout ce que tu génères. Si une demande te paraît contraire à une règle, explique pourquoi c'est risqué et propose l'alternative correcte.

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
