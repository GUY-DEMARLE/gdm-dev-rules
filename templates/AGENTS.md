# Instructions pour Codex

Ce projet suit les règles de développement et de sécurité de Guy Demarle.

## Au début de chaque session

Les règles GDM arrivent dans ce repo par des PR automatiques : une copie locale en retard, ce sont des règles périmées et des conflits à venir. Avant toute modification :

1. Lance `git fetch` puis `git status -sb`.
2. Si la branche locale est en retard sur son origine (`behind`), ou si la branche de travail est en retard sur `origin/dev` (`git rev-list --count HEAD..origin/dev`, quand `dev` existe), **rappelle à l'utilisateur de faire `git pull`** (ou de rebaser sa branche sur `dev`) avant de commencer, et attends sa réponse.
3. Ne lance pas le `pull` ou le rebase toi-même sans son accord : il peut avoir du travail en cours.
4. Lis `docs/DECISIONS.md` s'il existe : c'est la mémoire de l'app (décisions importantes, leurs raisons, ce qui a été écarté). Ne contredis jamais une décision active sans le signaler à l'utilisateur.

**Avant de générer du code ou de modifier ce projet, lis impérativement le fichier `.ai-rules/RULES.md`** à la racine. Il contient :

- L'architecture imposée (front Vercel → back Render/Vercel/Supabase Edge → services tiers)
- Les 6 règles non-négociables (gitleaks, GRANT + RLS Supabase, branch protection, variables d'env, préfixes VITE_*, architecture front/back)
- Les patterns de clés à reconnaître (Anthropic, Google, Stripe, AWS, JWT...)
- Le comportement attendu de l'IA (jamais de clé en dur, proxy systématique, GRANT minimaux et RLS dès la migration, etc.)
- La stack technique recommandée et les conventions
- Les règles de tests et de CI (§ 7) : tests dans chaque PR, jamais affaiblis pour passer, CI de moins de 10 minutes ; modèles dans `docs-rules/TESTS_CI.md`
- Le process Security OSS : Gitleaks/Semgrep/OSV sur PR, audit hebdomadaire Slack, artifacts GitHub Actions
- Le process Sentry : erreurs, performance, routes lentes, tokens et couts IA en production

Tu dois respecter ces règles dans tout ce que tu génères. Si une demande te paraît contraire à une règle, explique pourquoi c'est risqué et propose l'alternative correcte.

Le pipeline de sécurité `.github/workflows/security-oss.yml` est **obligatoire** (`RULES.md` § 2.6) et posé automatiquement par `gdm-dev-rules`. Il est distribué en **copie complète, délibérément** : une app n'appelle jamais un workflow hébergé dans un autre dépôt. **Ne remplace pas cette copie par un caller `workflow_call`**, ne la modifie pas localement, n'en écris pas un second — toute évolution se fait dans la source et arrive automatiquement par le robot de synchro.

## Fichiers gérés par gdm-dev-rules

Ces fichiers sont posés et mis à jour automatiquement par le robot de synchro (PR « chore(gdm-rules) ») : **ne les modifie jamais dans ce repo**, la CI « GDM Rules Guard » bloquerait la PR.

- `.ai-rules/` (règles, script de vérification, empreintes `MANAGED.sha256`)
- `.cursor/rules/gdm-rules.mdc`, `docs-rules/`, `system-design/`
- `.github/workflows/security-oss.yml` et `.github/workflows/gdm-rules-guard.yml`
- la partie de ce fichier qui précède « ## Contexte du projet »

Si l'utilisateur demande de changer l'un d'eux, explique que l'évolution se fait par une PR sur `GUY-DEMARLE/gdm-dev-rules`. Les sections « Contexte du projet » et « Règles spécifiques » ci-dessous appartiennent au projet : tu peux les compléter.

## Design system Guy Demarle

Le dossier `system-design/` est à la racine du repo. Il est posé et mis à jour automatiquement par `gdm-dev-rules` : ne le modifie pas ici, toute évolution se fait dans la source (`GUY-DEMARLE/gdm-dev-rules`, `templates/system-design/`).

**Avant de créer ou de modifier la moindre interface, lis `system-design/AGENTS.md` et applique-le.** Jetons, composants et mascotte sont fournis dans `system-design/kit/`, il n'y a rien à redessiner. Aucune couleur, taille de texte, rayon ou durée n'est écrite en dur — uniquement des `var(--gd-*)`.

- Rendu visuel de tout le kit : ouvre `system-design/kit/demo.html` dans un navigateur.
- Direction artistique et justification des arbitrages : `system-design/README.md`.
- Contrôle automatique avant de dire que c'est fini : `node system-design/outils/verifier-interface.mjs <dossier du front>`.

## Journal des décisions de l'app

`docs/DECISIONS.md` est la mémoire de l'app (`.ai-rules/RULES.md` section 8, modèle dans `docs-rules/DECISIONS_TEMPLATE.md`). À chaque décision importante prise pendant la session (architecture, librairie ou service choisi ou rejeté, modèle de données, droits, contournement d'une limite, écart à une règle GDM, approche abandonnée), ajoute une entrée courte en haut du fichier, dans la même PR : date, statut, décision, pourquoi, écarté, à revoir si, où. Crée le fichier à partir du modèle s'il n'existe pas. Une décision qui change : nouvelle entrée, et l'ancienne passe en « Remplacée par … » ; on ne supprime jamais une entrée.

## Code Review Rules

Consignes pour les revues de code automatiques des pull requests (Codex, Claude `/code-review`). Ne signaler que des problèmes réels et concrets, avec le fichier et la ligne concernés.

### Accès et données

- Toute nouvelle route, requête ou table : vérifier que l'utilisateur ne peut lire ou modifier que ce qui lui appartient. Le contrôle se fait côté serveur ; un identifiant d'utilisateur envoyé par le client ne prouve rien. Une table Supabase doit avoir, dès la migration qui la crée, des GRANT minimaux et la RLS avec ses policies : signaler toute table créée sans GRANT, ou avec des GRANT plus larges que l'usage réel (surtout vers `anon`).

### Tests

- Signaler tout test supprimé, désactivé (`skip`, `xfail`, `.only`) ou assoupli, et toute fonctionnalité ou correction livrée sans test (`.ai-rules/RULES.md` section 7).

### Décisions

- Signaler une PR qui va contre une décision active de `docs/DECISIONS.md` sans ajouter d'entrée qui la remplace, ou qui prend une décision importante (architecture, librairie, modèle de données, droits) sans l'y consigner.

### Secrets et architecture

- Signaler tout secret écrit en dur (même en commentaire ou en exemple), toute valeur secrète dans `VITE_*`, `NEXT_PUBLIC_*` ou `REACT_APP_*`, et tout appel direct du front vers un service tiers sensible ou payant : il doit passer par le back.

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
