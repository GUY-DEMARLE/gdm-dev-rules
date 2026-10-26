# Tests et CI — Dev GDM

**Quand utiliser ce doc** : à chaque fonctionnalité ou correctif, et pour créer ou adapter le `ci.yml` d'une app.
**Règle de référence** : `RULES.md` section 7. Ce doc donne le comment : exemples de tests et modèles de `ci.yml`.

Le code écrit avec l'IA, personne ne l'a tapé : les tests sont le moyen de le vérifier vite, et d'empêcher qu'un bug corrigé revienne.

---

## 1. Les règles en bref

| Règle | Détail |
|---|---|
| **Tests dans la même PR** | une fonctionnalité ou un correctif arrive avec ses tests |
| **Un bug = d'abord un test qui le reproduit** | il échoue avant le correctif, passe après |
| **D'abord la liste des cas** | normal, refusé, limites, panne du tiers ; validée par l'utilisateur, recopiée dans la PR |
| **Priorités obligatoires** | droits et authentification, RLS, proxys vers les tiers, écriture de données et argent |
| **Le niveau selon le risque** | unitaire pour la logique pure, intégration sur une vraie base pour les données et les droits, Playwright conseillé, test de fumée après déploiement |
| **Pas de faux test** | un test passe au rouge quand on casse le code qu'il vérifie |
| **Jamais affaiblir un test pour le faire passer** | ni `skip`, ni suppression, ni assertion assouplie |
| **Tests hermétiques** | pas de vraie donnée (sauf messages réels anonymisés), pas de vrai secret, pas d'appel réseau réel |
| **CI de moins de 10 minutes** | jobs en parallèle, tests parallélisés, cache, timeout de 15 min par job |
| **Un contrôle final `Tests`** | c'est lui qu'on rend obligatoire dans la protection des branches |

---

## 2. Quoi tester, et à quel niveau

### D'abord, la liste des cas

Avant d'écrire le moindre test, l'IA liste les cas en quelques lignes et l'utilisateur la valide. C'est là qu'on réfléchit ; les tests ne font ensuite que traduire la liste. Elle finit dans la description de la PR :

```markdown
## Cas testés — question au chatbot (proxy Gemini)
- un conseiller connecté pose une question : la réponse s'affiche
- sans connexion : refusé (401), Gemini n'est pas appelé
- question vide ou de plus de 2 000 caractères : refusée avant l'appel
- Gemini répond 500 ou ne répond pas en 30 s : message d'erreur clair, pas de nouvel essai en boucle

Non testé : la qualité des réponses (évaluée à part)
```

### Le bon niveau selon le risque

On part du bug qui coûterait cher, puis on prend le niveau le plus bas qui l'attrape.

| Ce qu'on vérifie | Niveau | Outil |
|---|---|---|
| Logique pure : calcul, conversion, lecture d'un format | unitaire | Vitest, pytest, PHPUnit |
| Données, droits, RLS, routes d'API, proxys | intégration, contre une vraie base de test (§ 6) | pytest, Vitest, pgTAP |
| Messages reçus d'un tiers : webhook ERP, réponse d'API | rejeu de vrais messages anonymisés (§ 3) | pytest, Vitest |
| 1 à 3 parcours vitaux, **conseillé** | bout en bout | Playwright |
| L'app déployée répond | test de fumée après chaque déploiement (§ 3) | `curl` dans un workflow |

Pour une app faite surtout de formulaires et de tables, l'essentiel de l'effort va à l'**intégration** : un test unitaire qui simule toute la base ne prouve presque rien. Le bout en bout reste rare : chaque test prend plusieurs secondes et casse au moindre changement d'écran.

### Les faux tests à refuser

Ils sont verts mais ne prouvent rien, et ce sont les plus fréquents dans le code écrit par une IA.

| Faux test | Pourquoi il ne prouve rien | À la place |
|---|---|---|
| Il vérifie que le mock renvoie ce qu'on lui a donné | il teste la simulation, pas le code | simuler seulement la frontière (`fetch`) et vérifier ce que le code en fait |
| Il refait le calcul du code : `expect(prixTTC(100)).toBe(100 * 1.2)` | une erreur de formule est recopiée dans le test | une valeur écrite à la main : `toBe(120)` |
| Il vérifie un détail interne : fonction appelée, état d'un composant | il casse au moindre remaniement et ne voit pas le bug visible | vérifier ce que voit l'utilisateur ou ce que renvoie l'API |
| Pause fixe ou sélecteur CSS dans un test d'interface | lent et instable | `getByRole` / `getByLabel`, attendre un état visible |

Le contrôle qui démasque un faux test : **casser volontairement le code** (inverser une condition, supprimer une ligne), lancer le test, constater qu'il passe au rouge, puis remettre le code.

---

## 3. Exemples de tests

### Unitaire (Vitest)

```ts
// src/lib/prix.test.ts
import { describe, it, expect } from "vitest";
import { prixTTC } from "./prix";

describe("prixTTC", () => {
  it("applique la TVA à 20 %", () => {
    expect(prixTTC(100)).toBe(120);
  });

  it("refuse un prix négatif", () => {
    expect(() => prixTTC(-1)).toThrow();
  });
});
```

### Droits d'accès sur une API (pytest)

Tester le cas autorisé **et** le cas refusé : c'est le refus qui protège.

```python
# api/tests/test_conversations.py
def test_un_utilisateur_ne_lit_pas_la_conversation_d_un_autre(client, user_a, user_b):
    conv = client.post("/conversations", headers=user_a.headers).json()

    reponse = client.get(f"/conversations/{conv['id']}", headers=user_b.headers)

    assert reponse.status_code == 404  # ni 200, ni 403 qui confirmerait l'existence


def test_sans_jeton_on_est_refuse(client):
    assert client.get("/conversations").status_code == 401
```

### Policy RLS Supabase (SQL, pgTAP)

Les fonctions `tests.*` (créer un utilisateur, se connecter en tant que…) viennent de l'extension [`supabase-test-helpers`](https://github.com/usebasejump/supabase-test-helpers), à installer une fois dans le projet de test. Sans elle, il faut créer les utilisateurs et simuler le JWT à la main.

```sql
-- supabase/tests/rls_profiles.test.sql   (lancé par : supabase test db)
begin;
select plan(2);

select tests.create_supabase_user('alice');
select tests.create_supabase_user('bob');
insert into public.profiles (id, email) values
  (tests.get_supabase_uid('alice'), 'alice@test.local'),
  (tests.get_supabase_uid('bob'),   'bob@test.local');

select tests.authenticate_as('alice');
select results_eq(
  'select count(*)::int from public.profiles',
  array[1],
  'Alice ne voit que son propre profil'
);
select is_empty(
  $$ update public.profiles set email = 'pirate@test.local'
     where id = tests.get_supabase_uid('bob') returning id $$,
  'Alice ne peut pas modifier le profil de Bob'
);

select * from finish();
rollback;
```

### Parcours vital de bout en bout (Playwright, conseillé)

Conseillé dès que l'app a un parcours clé : se connecter, puis faire l'action principale. L'app choisit ses 1 à 3 parcours et peut les rendre obligatoires dans « Règles spécifiques à ce projet » de son `CLAUDE.md`. On les marque `@critique` : ce sont les seuls lancés sur chaque PR.

La connexion dépend de l'app : le test utilise un utilisateur créé pour les tests (par exemple dans `supabase/seed.sql` de la base locale), jamais un vrai compte ni la prod.

```ts
// e2e/connexion.spec.ts
import { test, expect } from "@playwright/test";

test("un conseiller se connecte et pose une question @critique", async ({ page }) => {
  await page.goto("/");
  await page.getByLabel("E-mail").fill("conseiller@test.local"); // utilisateur du seed de test
  await page.getByLabel("Mot de passe").fill("mot-de-passe-de-test");
  await page.getByRole("button", { name: "Se connecter" }).click();
  await expect(page.getByRole("textbox", { name: "Votre question" })).toBeVisible();
});
```

Dans `playwright.config.ts`, lance l'app avant les tests et parallélise :

```ts
export default defineConfig({
  fullyParallel: true,
  workers: process.env.CI ? "100%" : undefined,
  retries: process.env.CI ? 1 : 0,  // 1 essai de plus en CI ; un test qui ne passe qu'au 2e essai est à corriger
  webServer: { command: "npm run build && npm run preview", url: "http://localhost:4173", reuseExistingServer: !process.env.CI },
  use: { baseURL: "http://localhost:4173" },
});
```

### Simuler un service tiers

On simule **la frontière** (l'appel HTTP vers Gemini, Stripe…), jamais la logique qu'on teste.

```ts
import { vi } from "vitest";

vi.spyOn(globalThis, "fetch").mockResolvedValue(
  new Response(JSON.stringify({ texte: "réponse simulée" }), { status: 200 })
);
```

### Rejouer de vrais messages reçus

Les surprises de format (champ absent, date dans un autre format, accent mal encodé) ne s'inventent pas : on les récolte. Chaque vrai message reçu d'un tiers devient un fichier de test, **anonymisé** (noms, e-mails, adresses, téléphones remplacés) : un message brut contient des données personnelles et n'entre jamais dans le repo. Quand un message fait planter l'app, on l'ajoute au dossier : c'est le test du bug.

```python
# api/tests/test_messages_erp.py
import json
from pathlib import Path

import pytest

from api.erp import lire_commande

MESSAGES = sorted((Path(__file__).parent / "messages_erp").glob("*.json"))


@pytest.mark.parametrize("fichier", MESSAGES, ids=lambda f: f.name)
def test_chaque_message_reel_se_lit(fichier):
    commande = lire_commande(json.loads(fichier.read_text(encoding="utf-8")))

    assert commande.numero
    assert commande.lignes
```

### Test de fumée après déploiement

Vercel signale chaque déploiement à GitHub : ce workflow vérifie, juste après, que l'app et sa base répondent. Pour un déploiement fait par un workflow (Gandi), ajoute les deux `curl` à la fin de ce workflow.

```yaml
# .github/workflows/fumee.yml
name: Fumée

on: deployment_status

permissions:
  contents: read

jobs:
  fumee:
    if: github.event.deployment_status.state == 'success'
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - name: L'app et sa base répondent
        env:
          URL: ${{ github.event.deployment_status.target_url }}
        run: |
          curl --fail --silent --show-error --retry 3 --retry-delay 10 "$URL" > /dev/null
          curl --fail --silent --show-error --retry 3 --retry-delay 10 "$URL/api/sante"
```

`/api/sante` est une route qui fait une requête minimale à la base et renvoie 200 ; sans elle, retire le second `curl` : seule la page d'accueil est alors vérifiée. Si les aperçus Vercel sont protégés, limite le job à la prod (`&& github.event.deployment_status.environment == 'Production'`).

---

## 4. Structure d'une CI rapide

```mermaid
flowchart LR
    pr["PR ouverte<br/>ou nouveau push"] --> lint["Lint et typage"]
    pr --> unit["Tests unitaires"]
    pr --> back["Tests API"]
    pr --> build["Build"]
    pr --> e2e1["E2E critique<br/>partie 1/2"]
    pr --> e2e2["E2E critique<br/>partie 2/2"]
    lint --> tests{"Tests<br/>contrôle final"}
    unit --> tests
    back --> tests
    build --> tests
    e2e1 --> tests
    e2e2 --> tests
```

Tous les jobs démarrent **en même temps** : la durée totale est celle du plus long, pas la somme. Le job final **`Tests`** ne fait que vérifier qu'aucun n'a échoué ; c'est le seul nom à rendre obligatoire, même si on ajoute ou renomme des jobs.

Les 6 réglages qui gardent la CI sous 10 minutes, présents dans tous les modèles :

1. `timeout-minutes` sur chaque job ;
2. jobs sans `needs` entre eux (sauf le contrôle final) ;
3. `cache: npm` / `cache: pip` ;
4. `concurrency` + `cancel-in-progress: true` ;
5. tests parallélisés : Vitest par défaut, `pytest -n auto`, `fullyParallel` + `--shard` pour Playwright ;
6. E2E de la PR limités à `@critique`, suite complète la nuit (`schedule`) et sur les PR vers `main`.

---

## 5. Modèles de `ci.yml`

Copie le modèle qui correspond à l'app dans `.github/workflows/ci.yml`, puis adapte les commandes. **Ce fichier appartient à l'app** (il n'est pas géré par le robot) : tu peux le modifier librement.

Les actions sont épinglées sur un commit précis, comme dans `security-oss.yml`.

### Modèle A — Front React/Vite ou app Node

```yaml
name: CI

on:
  pull_request:
  workflow_dispatch:
  schedule:
    - cron: "0 3 * * *" # suite E2E complète chaque nuit

concurrency:
  group: ci-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  lint:
    name: Lint et typage
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
        with:
          persist-credentials: false
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - run: npm run lint --if-present
      - run: npm run typecheck --if-present

  unit:
    name: Tests unitaires
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
        with:
          persist-credentials: false
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - run: npx vitest run

  build:
    name: Build
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
        with:
          persist-credentials: false
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - run: npm run build

  # Facultatif (Playwright est conseillé, pas imposé) : sans tests Playwright, supprime ce job et retire-le de `needs` plus bas.
  e2e:
    name: E2E (${{ matrix.shard }})
    runs-on: ubuntu-latest
    timeout-minutes: 15
    strategy:
      fail-fast: false
      matrix:
        shard: ["1/2", "2/2"]
    env:
      # Sur une PR : chemin critique seulement. La nuit et sur une PR vers `main` : suite complète.
      PW_FILTRE: ${{ (github.event_name == 'schedule' || github.base_ref == 'main') && '.*' || '@critique' }}
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
        with:
          persist-credentials: false
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0
        with:
          node-version-file: .nvmrc
          cache: npm
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npx playwright test --grep "$PW_FILTRE" --shard=${{ matrix.shard }}

  tests:
    name: Tests
    if: always()
    needs: [lint, unit, build, e2e]
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - name: Tous les jobs sont-ils verts ?
        env:
          RESULTATS: ${{ join(needs.*.result, ' ') }}
        run: |
          echo "Résultats : $RESULTATS"
          case " $RESULTATS " in
            *" failure "*|*" cancelled "*) exit 1 ;;
          esac
```

> `skipped` est accepté : un job sauté volontairement ne bloque pas. Attention : `hashFiles()` n'est pas utilisable dans le `if:` d'un job, seulement dans ses étapes.

### Modèle B — API Python

```yaml
name: CI

on:
  pull_request:
  workflow_dispatch:

concurrency:
  group: ci-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
        with:
          persist-credentials: false
      - uses: actions/setup-python@a26af69be951a213d495a4c3e4e4022e16d87065 # v5.6.0
        with:
          python-version: "3.12"
          cache: pip
      - run: pip install ruff
      - run: ruff check .

  pytest:
    name: Tests API
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
        with:
          persist-credentials: false
      - uses: actions/setup-python@a26af69be951a213d495a4c3e4e4022e16d87065 # v5.6.0
        with:
          python-version: "3.12"
          cache: pip
      - run: pip install -r requirements.txt pytest pytest-xdist
      - run: pytest -n auto -q

  tests:
    name: Tests
    if: always()
    needs: [lint, pytest]
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - name: Tous les jobs sont-ils verts ?
        env:
          RESULTATS: ${{ join(needs.*.result, ' ') }}
        run: |
          echo "Résultats : $RESULTATS"
          case " $RESULTATS " in
            *" failure "*|*" cancelled "*) exit 1 ;;
          esac
```

### Modèle C — Front et API dans le même repo (`frontend/` + `api/`)

Même principe : un job par partie, tous en parallèle. Seuls les jobs changent ; reprends `on`, `concurrency`, `permissions` et le job `tests` du modèle A.

```yaml
jobs:
  front:
    name: Front (lint, tests, build)
    runs-on: ubuntu-latest
    timeout-minutes: 10
    defaults:
      run:
        working-directory: frontend
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
        with:
          persist-credentials: false
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0
        with:
          node-version-file: frontend/.nvmrc
          cache: npm
          cache-dependency-path: frontend/package-lock.json
      - run: npm ci
      - run: npm run lint --if-present
      - run: npx vitest run
      - run: npm run build

  api:
    name: Tests API
    runs-on: ubuntu-latest
    timeout-minutes: 15
    defaults:
      run:
        working-directory: api
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
        with:
          persist-credentials: false
      - uses: actions/setup-python@a26af69be951a213d495a4c3e4e4022e16d87065 # v5.6.0
        with:
          python-version: "3.12"
          cache: pip
          cache-dependency-path: api/requirements.txt
      - run: pip install -r requirements.txt pytest pytest-xdist
      - run: pytest -n auto -q

  tests:
    name: Tests
    if: always()
    needs: [front, api]
    # … étapes identiques au modèle A
```

### Modèle D — App PHP

```yaml
name: CI

on:
  pull_request:
  workflow_dispatch:

concurrency:
  group: ci-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  phpunit:
    name: Tests PHP
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # v4.4.0
        with:
          persist-credentials: false
      - uses: shivammathur/setup-php@f3e473d116dcccaddc5834248c87452386958240 # 2.37.2
        with:
          php-version: "8.3"
          tools: composer
          coverage: none
      - run: composer install --no-interaction --no-progress --prefer-dist
      - run: vendor/bin/phpunit --testdox

  tests:
    name: Tests
    if: always()
    needs: [phpunit]
    runs-on: ubuntu-latest
    timeout-minutes: 2
    steps:
      - name: Tous les jobs sont-ils verts ?
        env:
          RESULTATS: ${{ join(needs.*.result, ' ') }}
        run: |
          case " $RESULTATS " in
            *" failure "*|*" cancelled "*) exit 1 ;;
          esac
```

---

## 6. Base de données pour les tests

Les tests d'intégration et de RLS ont besoin d'une base. **Jamais la base de prod.** Deux options :

| Option | Quand | Comment |
|---|---|---|
| **Supabase local dans la CI** | recommandé : isolé, gratuit, repart de zéro à chaque run | `supabase start` (Docker est disponible sur les runners GitHub), applique les migrations du repo, puis `supabase test db` pour les tests SQL. Compte 1 à 2 minutes de démarrage. |
| **Un projet Supabase de test** | quand le local ne suffit pas | URL et clés du projet de test en **Secrets** GitHub (cf. `CONFIG_GITHUB.md`), jamais celles de prod |

---

## 7. Rendre les tests obligatoires

Quand une app a son `ci.yml` et qu'il est vert de façon stable, le lead ajoute le contrôle **`Tests`** aux contrôles obligatoires de la règle `gdm-protection`. Une PR avec des tests rouges ne pourra alors plus être mergée.

Tant qu'une app n'a pas de CI de tests, on ne l'exige pas : le contrôle n'existerait pas et bloquerait toutes les PR.

---

## 8. Checklist : ma PR est-elle prête ?

- [ ] La liste des cas testés, et de ce qui ne l'est pas, est dans la description de la PR
- [ ] Chaque comportement est testé au niveau le plus bas qui attrape le bug
- [ ] Un bug corrigé a son test de non-régression
- [ ] Les cas **refusés** sont testés (droits, RLS, entrées invalides)
- [ ] Chaque nouveau test passe au rouge quand on casse le code qu'il vérifie
- [ ] Aucun test n'a été supprimé, désactivé ou assoupli pour passer
- [ ] Aucune vraie donnée (messages réels : anonymisés), aucun vrai secret, aucun appel réseau réel dans les tests
- [ ] Les tests passent en local et le contrôle `Tests` est vert
- [ ] La CI reste sous 10 minutes

---

## 9. Si quelque chose ne va pas

| Symptôme | Que faire |
|---|---|
| La CI dépasse 10 minutes | regarde le job le plus long : le découper, le paralléliser (`-n auto`, `--shard`), réduire les E2E de PR au chemin critique, vérifier le cache |
| Un test passe puis échoue sans changement (flaky) | le corriger tout de suite (attente explicite plutôt que `sleep`, données isolées, horloge simulée) ou le mettre en quarantaine avec une issue |
| Un test E2E échoue seulement en CI | télécharger la trace Playwright (`--trace on-first-retry`) dans les artifacts du run |
| L'IA propose de supprimer ou d'assouplir un test | refuser : `RULES.md` 7.3. Demander pourquoi le test échoue, corriger le code |
