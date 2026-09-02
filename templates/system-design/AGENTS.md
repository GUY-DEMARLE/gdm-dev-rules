# Design system IA Guy Demarle — mode d'emploi

> **Tu construis l'interface d'un outil d'intelligence artificielle destiné aux Conseillers
> Culinaires Guy Demarle.** Ce fichier te dit quoi faire, dans l'ordre. Applique-le tel quel :
> il n'y a rien à interpréter et rien à réinventer.
>
> Ce dossier — `system-design/` — se pose **à la racine du dépôt** de chaque application
> Guy Demarle. Il y est déposé et remis à jour automatiquement par `gdm-dev-rules`
> (`install.ps1` / `install.sh`, puis `update.ps1` / `update.sh`) : **ne le modifie pas
> dans l'application**, la source fait foi (voir § 8). Il ne traite que de l'interface :
> les règles de développement et de sécurité vivent ailleurs (voir § 9).
>
> Lecture humaine complète et justifications : [`README.md`](README.md).
> Rendu visuel de tout ce qui suit : ouvre [`kit/demo.html`](kit/demo.html) dans un navigateur.

**Le seul critère qui compte.** Une Conseillère ouvre un écran, sans logo visible, sans titre.
Elle doit savoir **en une seconde** qu'elle est sur un outil IA Guy Demarle, et pas sur son
back-office de commandes, pas sur un site web, pas sur un outil générique. Un écran qui échoue
à ce test est hors charte, même s'il utilise les bonnes couleurs.

---

## 0 · Installation — avant d'écrire la moindre ligne d'interface

Copie les cinq fichiers de [`kit/`](kit/) dans le projet (par exemple sous `public/gd-ai/`
ou `assets/gd-ai/`) :

| Fichier | Rôle |
|---|---|
| `kit/gd-ai-tokens.css` | Tous les jetons : couleurs clair + sombre, typo, espacement, rayons, ombres, mouvement. **Obligatoire.** |
| `kit/gd-ai-components.css` | Boutons, champs, cartes, bulles, pastilles, alertes, lockup. **Obligatoire** — c'est ce qui rend deux outils reconnaissables comme la même famille. |
| `kit/gd-ai-mascotte.js` | La mascotte animée, en élément natif `<gd-mascotte>`. Obligatoire dès qu'il y a une mascotte à l'écran. |
| `kit/gd-ai-marque-o.png` | La marque O du lockup. |
| `kit/gd-ai-mascotte.svg` | Version statique de la mascotte (impression, e-mail, contexte sans JS). |

Puis, dans le `<head>` :

```html
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/gd-ai/gd-ai-tokens.css">
<link rel="stylesheet" href="/gd-ai/gd-ai-components.css">
<script src="/gd-ai/gd-ai-mascotte.js" defer></script>
```

Ces deux feuilles se chargent **avant** toute feuille du projet. Ne les modifie pas : si une
valeur ne convient pas, c'est une évolution du design system, elle se discute — voir § 8.

**Ne recopie jamais une valeur de ces fichiers dans ton code.** Uniquement `var(--gd-*)`.
C'est ce qui permettra de faire évoluer la charte sans rouvrir chaque application.

---

## 1 · Le squelette d'une page conforme

```html
<body>
  <header>
    <div class="gd-lockup">
      <img class="gd-lockup__mark" src="/gd-ai/gd-ai-marque-o.png" alt="">
      <span class="gd-lockup__text">
        <span class="gd-lockup__name">NomDeLOutil</span>
        <span class="gd-lockup__by">par Guy Demarle</span>
      </span>
    </div>
  </header>

  <main>
    <div class="gd-card">
      <h2 class="gd-card__title">Un titre</h2>
      <p class="gd-prose">Le corps de texte, à 16 px, sur 65 à 75 caractères de large.</p>
      <button class="gd-btn">L'action principale</button>
      <button class="gd-btn gd-btn--secondary">L'action secondaire</button>
    </div>
  </main>

  <gd-mascotte pose="salut" size="96"></gd-mascotte>
</body>
```

C'est tout. Le fond crème, la police, la couleur du texte et le mode sombre viennent des
jetons — il n'y a rien à écrire pour les obtenir.

---

## 2 · Les règles qui décident

Chaque ligne est vérifiable. Si tu ne peux pas la vérifier sur ton écran, elle n'est pas
respectée. Les lignes marquées 🤖 sont contrôlées par
[`outils/verifier-interface.mjs`](outils/verifier-interface.mjs) :

```bash
node system-design/outils/verifier-interface.mjs <dossier du front>
```

| # | Règle | Comment tu vérifies |
|---|---|---|
| 1 | **Fond crème, jamais blanc pur.** `--gd-cream` en fond de page. | 🤖 Aucun `background: #fff` ni `white` en fond de page. Le blanc est réservé aux surfaces posées dessus. |
| 2 | **Un seul accent rouge par zone.** Le second bouton passe en `--secondary`, le troisième en `--ghost`. | Compte les `.gd-btn` sans modificateur visibles en même temps : il en faut **un**. |
| 3 | **Le rouge n'est jamais un fond de page ni un bandeau pleine largeur.** | Bouton, première lettre, filet, pastille — rien de plus. |
| 4 | **Corps de texte 16 px, plancher absolu 14 px.** | 🤖 Aucune valeur `font-size` sous `--text-xs`. |
| 5 | **Texte secondaire sur crème : `.gd-text-soft`.** `--gd-ink-soft` échoue AA sur le fond crème (4,3:1) sous 18 px. | Cherche `--gd-ink-soft` dans ton CSS : sur crème, sous 18 px et sans gras, c'est une erreur. |
| 6 | **Rien à angle vif.** Rayons de `gd-ai-tokens.css` uniquement. | 🤖 Aucun `border-radius: 0`. |
| 7 | **Ombres à base brune**, jamais noires ni grises. | 🤖 Uniquement `var(--gd-shadow*)`. Un `rgba(0,0,0,…)` en ombre est hors charte. |
| 8 | **Une seule police : Poppins.** Poids 300 à 700. | 🤖 Aucune autre `font-family` que `var(--font-sans)`. |
| 9 | **« par Guy Demarle » sous le nom de l'outil.** Non négociable. | Le lockup est complet : marque O + nom + signature. |
| 10 | **Cibles tactiles ≥ 44 × 44 px**, focus visible partout. | 🤖 Ne jamais faire `outline: none` sans remplacement. `.gd-btn--sm` est réservé à l'admin au pointeur. |
| 11 | **Aucune information portée par la seule couleur.** | Une erreur en rouge porte aussi un texte ou une icône. |
| 12 | **`prefers-reduced-motion` coupe toutes les animations.** | Déjà géré par les jetons et par la mascotte. Ne le contourne pas avec `!important`. |
| 13 | **La palette gourmande n'est jamais du texte ni un aplat de fond** sur plus d'un quart de l'écran. | Beurre, rose, menthe, abricot : accents, filets, humeurs. |

**Répartition visée : 60 / 30 / 10.** 60 % de crème (fond), 30 % de blanc papier (cartes,
bulles, champs), 10 % de rouge et de gourmand (accents). Le rouge dépasse rarement 5 %.

---

## 3 · Les composants disponibles

Utilise-les tels quels. N'en réécris pas un qui existe : c'est exactement là que deux outils
divergent.

| Classe | Quoi | Variantes |
|---|---|---|
| `.gd-btn` | Bouton, hauteur 44 px | `--secondary` `--ghost` `--sm` `--lg` `--block` |
| `.gd-chip` | Pastille cliquable (suggestion) | `--active` |
| `.gd-badge` | Pastille non cliquable (qualifie) | `--butter` `--rose` `--mint` `--apricot` |
| `.gd-field` + `.gd-label` + `.gd-input` / `.gd-textarea` / `.gd-select` + `.gd-hint` | Champ complet | `.gd-field--error` + `.gd-field__error` |
| `.gd-card` + `.gd-card__title` | Surface posée | `--warm` `--float` |
| `.gd-panel` | Navigation, colonne latérale | — |
| `.gd-mood` | Le motif « humeur » : blanc teinté + filet gourmand | `--butter` `--rose` `--mint` `--apricot` |
| `.gd-bubble` | Bulle de conversation | `--user` `--ai` |
| `.gd-typing` | Les trois points d'attente | — |
| `.gd-alert` | Statut uniquement | `--success` `--error` `--warning` |
| `.gd-lockup` | Marque O + nom + signature | `--sm` `--lg` ; `.gd-lockup__mark--tint` sur un `<span>` vide au lieu de l'`<img>` = la marque suit le thème, **à préférer si l'outil a un mode sombre** |
| `.gd-prose` | Colonne de lecture 65-75 caractères | — |
| `.gd-text-soft` | Texte secondaire conforme AA | — |
| `.gd-sr-only` | Visible des lecteurs d'écran uniquement | — |

Ce qui **n'est pas** fourni et t'appartient : la grille, la navigation, l'architecture des
écrans, les icônes, les illustrations, les micro-interactions propres à ton métier.

---

## 4 · La mascotte

C'est **l'emblème transverse de l'environnement IA**, pas la propriété du chatbot. Elle
apparaît sur chaque outil, avec le même tracé et le même caractère. Elle **accompagne**, elle
ne conduit pas.

```html
<gd-mascotte pose="salut" size="96"></gd-mascotte>
```

```js
const m = document.querySelector('gd-mascotte')

m.moment('attente')                          // le bon geste au bon moment
m.say('Je mijote ça…', { mood: 'thinking' }) // elle parle
m.hush()                                     // elle se tait
m.poke()                                     // saut ponctuel
```

**Branche-la sur les moments, pas sur les poses** — c'est ce qui fait que deux outils
réagissent pareil au même instant :

| `m.moment(…)` | Quand | Pose jouée |
|---|---|---|
| `accueil` | Écran d'accueil, première visite | Salue, bras levé |
| `attente` | Traitement en cours | « Je mijote » : bascule, bras qui tapote, appui qui change |
| `reponse` | Le résultat est prêt | Présente le résultat |
| `succes` | Une action a abouti | Les deux bras en l'air |
| `clic` | L'utilisatrice la touche | Saut, écrasement, réception |
| `repos` | Rien à dire | Respire, balance les bras, cligne des yeux |

Attributs : `pose`, `size`, `bubble`, `mood` (`welcome` / `thinking` / `post`),
`bubble-align` (`left` / `center` / `right`), `label`, `ground="off"`, `no-poke`, `reduced`.

**Règles non négociables :**

- **Une seule à l'écran à la fois.** Deux exemplaires cassent le personnage.
- **Une seule voix à la fois.** Si un indicateur d'attente parle déjà, elle se tait — et
  n'articule pas : une bouche qui bouge sans bulle trahit tout.
- **Elle ne porte jamais d'information critique.** Pas de chiffre, pas de montant, pas de
  mention légale, pas de consigne juridique. Ce qu'elle dit est du statut et de la chaleur ;
  ce qui compte est dans le fil principal. Un chiffre dit par la mascotte a l'air d'un fait
  vérifié alors qu'il n'a traversé aucun contrôle.
- **Toujours au sol.** Son ombre vit à part et ne décolle jamais avec elle.
- **40 px minimum.** Sous 40 px les jambes se dissolvent ; les déclinaisons de repli ne sont
  pas encore dessinées. Le composant remonte de force à 40 px et le signale en console.
- **Ne pas la recolorer, la déformer, la détourer, la poser sur du rouge**, lui ajouter des
  accessoires métier, lui faire porter le logo, ni lui faire dire « je » sur un contenu
  réglementaire.

**Son nom n'est pas tranché.** Écris « la mascotte » — jamais « Mimi » (abandonné), jamais
« Ohracle » (c'est le nom du chatbot, pas du personnage). Voir `README.md` § 5.1.

Si tu es dans un contexte sans JavaScript (e-mail, PDF, impression), utilise
`kit/gd-ai-mascotte.svg` tel quel.

---

## 5 · Les textes que tu écris

L'outil s'adresse à une Conseillère comme **une collègue expérimentée**, pas comme un service
client ni comme un assistant générique.

- **Tutoiement**, toujours.
- Trois à cinq emojis par réponse, pas plus. Ils rythment, ils ne décorent pas.
- Pédagogique : explique le *pourquoi*, pas seulement le *quoi*.
- Concret : un exemple chiffré vaut mieux qu'un paragraphe de principe.
- **Disclaimer obligatoire** sur l'URSSAF, la fiscalité, le juridique et la santé.
- **Périmètre strict** : hors Guy Demarle, on décline poliment et on ne brode pas.
- **Jamais de chiffre inventé.** Si la donnée n'est pas disponible, le dire et renvoyer vers
  l'espace conseillère.

Nommer un nouvel outil : nom court, prononçable au téléphone, français ou francisé, qui ne se
confond ni avec un produit du catalogue (OHRA, BE SAVE, BOREALIA, CANOFEA) ni avec un outil
existant du réseau, et qui tient en capitales dans le lockup.

---

## 6 · Interdits

Ne fais **jamais** ça, même si on te le demande vite fait :

- Écrire une couleur, une taille de texte, un rayon ou une durée **en dur**.
- Mettre un fond **blanc pur** en fond de page, ou un **bandeau rouge** pleine largeur.
- Modifier `gd-ai-tokens.css` ou `gd-ai-components.css` pour un besoin local.
- Ajouter une **deuxième police**, une deuxième courbe d'animation, un quatrième niveau
  d'ombre.
- Redessiner la mascotte, la recolorer, ou en afficher deux.
- Faire dire un montant, un pourcentage ou une mention légale à la mascotte.
- Installer une bibliothèque de composants (Material, Bootstrap, shadcn…) **par-dessus** :
  elle réimpose ses propres rayons, ombres et échelles et l'outil sort de la famille. Si le
  projet en utilise déjà une, mappe ses variables sur les jetons GD au lieu d'empiler.
- Descendre une taille de texte « pour faire moderne ».
- Supprimer le focus visible.

---

## 7 · La checklist avant de dire que c'est fini

Ne réponds pas « c'est fait » avant d'avoir vérifié, sur l'écran réel :

- [ ] Fond de page en `--gd-cream`, pas de blanc pur.
- [ ] Zéro valeur en dur : uniquement des `var(--gd-*)`.
- [ ] Un seul bouton rouge par zone.
- [ ] Aucun texte sous 14 px, corps de texte à 16 px.
- [ ] Aucun `--gd-ink-soft` sur crème sous 18 px sans gras.
- [ ] Rien à angle vif, ombres brunes.
- [ ] Lockup complet, « par Guy Demarle » présent.
- [ ] Mascotte : une seule, ≥ 40 px, aucun chiffre dans sa bulle.
- [ ] Cibles tactiles ≥ 44 px, focus visible, aucune info portée par la seule couleur.
- [ ] Testé en **thème sombre** (`data-theme="dark"` sur `<html>`) et en
      **`prefers-reduced-motion`**.
- [ ] Zoom navigateur 200 % sans perte de fonction.
- [ ] **Le test en une seconde** : cache le titre et le logo — l'écran dit encore « outil IA
      Guy Demarle » ?
- [ ] La console est vide : le composant mascotte y écrit ce qu'il refuse.
- [ ] `node system-design/outils/verifier-interface.mjs <dossier du front>` ne remonte plus
      d'erreur (il attrape ce qui se lit dans le code ; le reste se voit à l'écran).

---

## 8 · Ce que tu décides seul, et ce que tu dois demander

**Tu décides seul :** la mise en page et la navigation, les illustrations et l'iconographie,
les micro-interactions propres au métier, la pile technique (React, Vue, Svelte, rendu
serveur — le kit est du CSS et un élément natif, il fonctionne partout), et tes propres
composants tant qu'ils consomment les jetons.

**Tu demandes avant de faire :** ajouter un jeton ou changer une valeur de la charte, ajouter
une deuxième police, afficher la mascotte sous 40 px, lui faire dire autre chose que du
statut, et nommer l'outil ou la mascotte.

---

## 9 · Le reste

| Question | Où |
|---|---|
| Pourquoi telle règle, l'histoire des arbitrages | [`README.md`](README.md) |
| À quoi ça ressemble, tester la mascotte | [`kit/demo.html`](kit/demo.html) |
| Les jetons, un par un, commentés | [`kit/gd-ai-tokens.css`](kit/gd-ai-tokens.css) |
| Les composants, un par un, commentés | [`kit/gd-ai-components.css`](kit/gd-ai-components.css) |
| Le rig de la mascotte, les timings, les pivots | [`kit/gd-ai-mascotte.js`](kit/gd-ai-mascotte.js) |
| Décisions encore ouvertes | `README.md` § 13 |

Règles de développement et de sécurité Guy Demarle (secrets, RLS, architecture front/back) :
elles vivent ailleurs, dans `.ai-rules/RULES.md` du dépôt concerné. Ce fichier-ci ne traite
que de l'interface.

---

### Le rappel posé dans le `CLAUDE.md` / `AGENTS.md` du projet

Sur un repo installé par `gdm-dev-rules`, ce bloc y est déjà — il est reproduit ici pour
les dépôts qui n'utilisent pas les scripts et doivent l'ajouter à la main.

```markdown
## Design system IA Guy Demarle

Cette application fait partie de l'environnement IA Guy Demarle. Avant de créer ou de
modifier la moindre interface, lis `system-design/AGENTS.md` (à la racine) et applique-le :
jetons, composants et mascotte sont fournis dans `system-design/kit/`, il n'y a rien à
redessiner. Aucune couleur, taille, rayon ou durée n'est écrite en dur — uniquement des
`var(--gd-*)`. Contrôle : `node system-design/outils/verifier-interface.mjs <dossier>`.
```
