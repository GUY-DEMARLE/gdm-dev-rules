# Design system interne Guy Demarle — mode d'emploi

> **Tu construis l'interface d'un outil interne Guy Demarle** : back-office, référentiel,
> outil de pilotage, écran d'intégration — un outil utilisé par les équipes Guy Demarle, pas
> par les Conseillers. Ce fichier te dit quoi faire, dans l'ordre. Applique-le tel quel.
>
> Ce dossier — `system-design/interne/` — est le **profil interne** du design system. Le
> profil Conseillers, lui, est à la racine de `system-design/`. Les deux sont posés et mis à
> jour par `gdm-dev-rules` : **ne modifie rien ici**, la source fait foi (voir § 8).
>
> Lecture humaine complète et justifications : [`README.md`](README.md).
> Rendu visuel de tout ce qui suit : ouvre [`kit/demo.html`](kit/demo.html) dans un navigateur.

**Es-tu dans le bon profil ?** Ouvre le `CLAUDE.md` du projet, section « Contexte du
projet ». La ligne `Profil d'interface : interne` t'amène ici. Sans cette ligne, l'app est
en profil **Conseillers** : lis `system-design/AGENTS.md` et pas ce fichier. Dans le doute,
demande avant de produire une interface.

**Le seul critère qui compte.** Un collaborateur Guy Demarle ouvre un écran, sans logo
visible. Il doit savoir **en une seconde** qu'il est sur un outil Guy Demarle — et que c'est
un outil **de travail** : sobre, dense, sérieux. Ni un outil pour les Conseillers (pas de
mascotte, pas de fond vivant), ni un tableau de bord générique sorti d'une bibliothèque.

---

## 0 · Installation — avant d'écrire la moindre ligne d'interface

Sers les fichiers de [`kit/`](kit/) depuis le front (par exemple sous `public/gd-interne/`) :

| Fichier | Rôle |
|---|---|
| `kit/gd-interne-tokens.css` | Tous les jetons : palette, typo, espacement, hauteurs, rayons, ombres, mouvement. **Obligatoire.** |
| `kit/gd-interne-components.css` | Coquille, navigation, boutons, champs, tableaux, indicateurs, modale… **Obligatoire.** |
| `kit/gd-interne-marque-o.png` | La marque O du lockup. |

Puis, dans le `<head>` :

```html
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/gd-interne/gd-interne-tokens.css">
<link rel="stylesheet" href="/gd-interne/gd-interne-components.css">
```

Ces deux feuilles se chargent **avant** toute feuille du projet. **Ne charge jamais les
fichiers `gd-ai-*` du profil Conseillers dans un outil interne** : les deux kits définissent
les mêmes noms de jetons et de classes, avec des valeurs différentes.

**Ne recopie jamais une valeur de ces fichiers dans ton code.** Uniquement `var(--gd-*)`,
`var(--text-*)`, `var(--space-*)`, `var(--radius-*)`.

---

## 1 · Le squelette d'une page conforme

```html
<body>
  <div class="gd-shell">

    <aside class="gd-shell__sidebar">
      <div class="gd-lockup">
        <img class="gd-lockup__mark" src="/gd-interne/gd-interne-marque-o.png" alt="">
        <span class="gd-lockup__text">
          <span class="gd-lockup__name">NomDeLOutil</span>
          <span class="gd-lockup__by">Guy Demarle</span>
        </span>
      </div>
      <nav class="gd-nav" aria-label="Navigation principale">
        <p class="gd-nav__section">Référentiel</p>
        <a class="gd-nav__item" href="/produits" aria-current="page">Produits</a>
        <a class="gd-nav__item" href="/imports">Imports</a>
      </nav>
    </aside>

    <main class="gd-shell__main">
      <div class="gd-page-header">
        <div class="gd-page-header__text">
          <ol class="gd-breadcrumb"><li><a href="/">Référentiel</a></li><li aria-current="page">Produits</li></ol>
          <h1 class="gd-page-title">Produits</h1>
        </div>
        <div class="gd-page-actions">
          <button class="gd-btn gd-btn--secondary">Exporter</button>
          <button class="gd-btn">Nouveau produit</button>
        </div>
      </div>

      <div class="gd-table-wrap">
        <table class="gd-table">…</table>
      </div>
    </main>

  </div>
</body>
```

C'est tout. Le fond blanc cassé, la police, la couleur du texte et l'anneau de focus
viennent des jetons. **L'apparence est toujours claire** : pas de sélecteur de thème.

---

## 2 · Les règles qui décident

Chaque ligne est vérifiable. Les lignes marquées 🤖 sont contrôlées par
[`../outils/verifier-interface.mjs`](../outils/verifier-interface.mjs) :

```bash
node system-design/outils/verifier-interface.mjs <dossier du front> --profil interne
```

| # | Règle | Comment tu vérifies |
|---|---|---|
| 1 | **Fond blanc cassé `--gd-cream`, jamais blanc pur.** Le blanc est réservé à ce qui est posé dessus : cartes, tableaux, champs, modales. | 🤖 Aucun `background: #fff` ni `white` en fond de page. |
| 2 | **Un seul bouton rouge par zone.** Le second passe en `--secondary`, le reste en `--ghost`. | Compte les `.gd-btn` sans modificateur visibles en même temps : il en faut **un** par zone. |
| 3 | **Le rouge a quatre usages, pas un de plus** : l'action principale, l'élément actif de la navigation, l'onglet actif, la première lettre du nom. | Pas de bandeau rouge, pas de titre rouge, pas de rouge pour une erreur : une erreur prend `--color-error`. |
| 4 | **Corps de texte 14 px, tableaux 13 px, plancher 12 px** pour toute information. | 🤖 Aucune valeur `font-size` sous 12 px. `--text-2xs` (11 px) ne porte jamais une information seule. |
| 5 | **Une seule police : Poppins.** | 🤖 Aucune autre `font-family` que `var(--font-sans)`. |
| 6 | **Rien à angle vif.** Rayons du kit : 6 px pour les contrôles et les cartes, 8 px pour ce qui flotte, pastilles rondes pour les badges. | 🤖 Aucun `border-radius: 0`. |
| 7 | **Ombres à base brune**, jamais noires ni grises. | 🤖 Uniquement `var(--gd-shadow*)`. |
| 8 | **Zéro valeur en dur** : couleur, taille de texte, rayon, durée. | 🤖 Aucun hex, `rgb()` ou `hsl()` hors des fichiers du kit. |
| 9 | **Pas de mascotte, pas d'ambiance, pas d'emoji.** Ce sont les signes du profil Conseillers. Une fonction d'IA se signale par le badge `.gd-badge--ia`. | 🤖 Aucun `<gd-mascotte>`, aucun `gd-ambient`, aucun fichier `gd-ai-*` chargé. |
| 10 | **Coquille, navigation et tableau du kit.** `.gd-shell`, `.gd-nav`, `.gd-table` : c'est à eux qu'on reconnaît la famille d'un outil à l'autre. | Pas de tableau ni de menu latéral réécrit à côté. |
| 11 | **Nombres et montants à droite, en chasse fixe** : `.gd-num` sur l'en-tête et sur les cellules. | Une colonne de prix alignée à gauche est une erreur. |
| 12 | **Un statut porte un texte.** Badge `.gd-badge--success` / `--warning` / `--error` / `--info` avec son libellé. | Jamais une pastille de couleur seule, jamais une ligne colorée sans mot. |
| 13 | **Focus visible partout, cibles de 36 px au pointeur, 44 px si l'écran sert sur tablette** (`.gd-btn--lg`, `--control-h-lg`). | 🤖 Jamais `outline: none` sans remplacement. |
| 14 | **Une action destructive est en `.gd-btn--danger`** et passe par une modale de confirmation qui nomme ce qui va disparaître. | Pas de suppression en un clic, pas de suppression en rouge plein. |
| 15 | **Lockup complet** : marque O + nom de l'outil (première lettre rouge, automatique) + « Guy Demarle ». | En haut de la navigation, toujours visible. |
| 16 | **`prefers-reduced-motion` coupe toutes les animations.** | 🤖 Ne le contourne pas avec `!important`. |

---

## 3 · Les composants disponibles

Utilise-les tels quels. N'en réécris pas un qui existe.

| Classe | Quoi | Variantes, parties |
|---|---|---|
| `.gd-shell` | Coquille : navigation à gauche, contenu à droite | `__sidebar` `__main` |
| `.gd-lockup` | Marque O + nom + « Guy Demarle » | `--sm` ; `__mark` `__text` `__name` `__by` |
| `.gd-nav` | Navigation latérale | `__section` `__item` (actif : `aria-current="page"`) `__count` |
| `.gd-page-header` | En-tête de page | `__text` ; `.gd-breadcrumb` `.gd-page-title` `.gd-page-subtitle` `.gd-page-actions` |
| `.gd-btn` | Bouton, 36 px | `--secondary` `--ghost` `--danger` `--sm` `--lg` `--block` `--icon` |
| `.gd-badge` | Statut, pastille non cliquable | `--success` `--warning` `--error` `--info` `--ia` |
| `.gd-field` + `.gd-label` + `.gd-input` / `.gd-textarea` / `.gd-select` + `.gd-hint` | Champ complet | `.gd-field--error` + `.gd-field__error` ; `.gd-label__optional` |
| `.gd-check` / `.gd-checkbox` | Case à cocher, bouton radio | — |
| `.gd-form-grid` | Grille de formulaire, 2 colonnes puis 1 | — |
| `.gd-toolbar` | Barre de filtres au-dessus d'un tableau | `__spacer` ; `.gd-search` sur un `.gd-input` |
| `.gd-kpis` + `.gd-kpi` | Indicateurs, 4 maximum par ligne | `__label` `__value` `__delta` (`--up` `--down`) |
| `.gd-card` | Surface posée | `__header` `__title` `__footer` |
| `.gd-panel` | Zone secondaire, colonne latérale | — |
| `.gd-properties` | Liste libellé / valeur d'une fiche (`<dl>`) | — |
| `.gd-table-wrap` + `.gd-table` | Tableau | `--compact` ; `.gd-col-check` `.gd-table__sort` `.gd-table__foot` ; ligne sélectionnée : `aria-selected="true"` |
| `.gd-num` / `.gd-ref` | Nombre aligné à droite / référence secondaire | — |
| `.gd-pagination` | Pagination | `__item` (courant : `aria-current="page"`) |
| `.gd-tabs` + `.gd-tab` | Onglets | actif : `aria-selected="true"` ou `aria-current="page"` |
| `.gd-alert` | Statut uniquement (info par défaut) | `--success` `--warning` `--error` ; `__title` |
| `.gd-modal` | Modale sur `<dialog>`, ouverte par `showModal()` | `__header` `__title` `__body` `__footer` |
| `.gd-empty` | État vide | `__title` `__text` |
| `.gd-prose` | Colonne de lecture (aide, documentation) | — |
| `.gd-text-soft` / `.gd-sr-only` / `.gd-divider` | Utilitaires | — |

Les noms communs avec le profil Conseillers (`.gd-btn`, `.gd-field`, `.gd-card`,
`.gd-badge`, `.gd-alert`, `.gd-lockup`, `.gd-prose`) sont **volontaires** : un composant
métier écrit pour un profil reste lisible dans l'autre.

Ce qui **n'est pas** fourni et t'appartient : l'architecture des écrans, les icônes (16 px,
trait fin, couleur du texte), les graphiques, les micro-interactions de ton métier.

---

## 4 · L'IA dans un outil interne

Un outil interne peut embarquer une fonction d'IA (recherche, rédaction, contrôle). Elle se
signale **sobrement** :

- le badge `.gd-badge--ia` à côté du titre de la fonction ou du résultat produit ;
- un texte qui dit ce que l'IA a fait et sur quelles sources ;
- **jamais la mascotte, jamais l'ambiance, jamais la bulle gourmande** : ce sont les signes
  de l'environnement Conseillers. Dans un outil de travail, ils font jouet.

Un résultat d'IA ne s'enregistre jamais sans une action explicite de l'utilisateur.

---

## 5 · Les textes que tu écris

- **Sobre et factuel.** Pas d'emoji, pas de point d'exclamation, pas de « Super ! ».
- **Vouvoiement** dans les messages (« Corrigez le fichier, puis relancez l'import »).
  Les boutons sont à l'infinitif : « Enregistrer », « Valider la fiche », « Exporter ».
- **Un message d'erreur dit ce qui s'est passé, puis quoi faire.** Jamais un code brut seul.
- **Un état vide dit ce que contiendra l'écran et comment le remplir.**
- **Dates** au format `21/10/2026`, heures `14:05`, **nombres** avec espace des milliers
  (`1 284`), virgule décimale (`92,4 %`), **montants** suivis de `€` (`39,90 €`).
- **Jamais de chiffre inventé** : une donnée absente s'affiche `—` et se dit absente.

---

## 6 · Interdits

Ne fais **jamais** ça, même si on te le demande vite fait :

- Écrire une couleur, une taille de texte, un rayon ou une durée **en dur**.
- Mettre un fond **blanc pur** en fond de page, ou un **bandeau rouge** pleine largeur.
- Charger les fichiers `gd-ai-*` du profil Conseillers, afficher la **mascotte**, poser
  **`gd-ambient`**, mettre des **emojis** dans l'interface.
- Utiliser le rouge pour autre chose que ses quatre usages (règle 3).
- Supprimer sans confirmation, ou présenter une suppression en rouge plein.
- Modifier `gd-interne-tokens.css` ou `gd-interne-components.css` pour un besoin local.
- Ajouter une **deuxième police**, une deuxième courbe d'animation, un quatrième niveau
  d'ombre.
- Installer une bibliothèque de composants (Material, Bootstrap, shadcn, Ant Design…)
  **par-dessus** le kit. Si le projet en utilise déjà une, mappe ses variables sur les
  jetons GD au lieu d'empiler, et garde le tableau et la navigation du kit.
- Descendre une information sous 12 px.
- Supprimer le focus visible.

---

## 7 · La checklist avant de dire que c'est fini

Ne réponds pas « c'est fait » avant d'avoir vérifié, sur l'écran réel :

- [ ] Fond de page en `--gd-cream`, surfaces blanches posées dessus.
- [ ] Coquille `.gd-shell`, navigation `.gd-nav` avec l'élément actif en `aria-current`.
- [ ] Lockup complet en haut de la navigation.
- [ ] Zéro valeur en dur : uniquement des jetons.
- [ ] Un seul bouton rouge par zone ; le rouge n'a que ses quatre usages.
- [ ] Corps à 14 px, tableaux à 13 px, rien d'informatif sous 12 px.
- [ ] Nombres et montants à droite (`.gd-num`), statuts avec leur texte.
- [ ] Toute suppression passe par une modale qui nomme l'objet.
- [ ] Ni mascotte, ni ambiance, ni emoji, ni fichier `gd-ai-*`.
- [ ] Focus visible au clavier, cibles de 36 px (44 px si tablette).
- [ ] Apparence claire même si l'appareil préfère le sombre.
- [ ] Testé en `prefers-reduced-motion` et en zoom navigateur 200 %.
- [ ] À 375 px de large, la page ne défile pas horizontalement (seul un tableau défile
      dans son cadre).
- [ ] **Le test en une seconde** : cache le logo — l'écran dit encore « outil de travail
      Guy Demarle » ?
- [ ] `node system-design/outils/verifier-interface.mjs <dossier du front> --profil interne`
      ne remonte plus d'erreur.

---

## 8 · Ce que tu décides seul, et ce que tu dois demander

**Tu décides seul :** l'architecture des écrans, les colonnes des tableaux, les filtres, les
icônes, les graphiques, la pile technique (le kit est du CSS, il fonctionne partout), et tes
propres composants tant qu'ils consomment les jetons.

**Tu demandes avant de faire :** ajouter un jeton ou changer une valeur du kit, ajouter une
police, une couleur ou une bibliothèque de composants, changer le profil d'interface de
l'app, et nommer l'outil.

Toute évolution du kit se fait dans la source : `GUY-DEMARLE/gdm-dev-rules`,
`templates/system-design/interne/`, par une PR.

---

## 9 · Le reste

| Question | Où |
|---|---|
| Pourquoi telle règle, l'histoire des arbitrages | [`README.md`](README.md) |
| À quoi ça ressemble | [`kit/demo.html`](kit/demo.html) |
| Les jetons, un par un, commentés | [`kit/gd-interne-tokens.css`](kit/gd-interne-tokens.css) |
| Les composants, un par un, commentés | [`kit/gd-interne-components.css`](kit/gd-interne-components.css) |
| Le profil Conseillers | [`../AGENTS.md`](../AGENTS.md) |

Règles de développement et de sécurité Guy Demarle : `.ai-rules/RULES.md` du dépôt. Ce
fichier-ci ne traite que de l'interface.
