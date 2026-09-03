# Design system — Environnement IA Guy Demarle

Version 1.4 · 3 septembre 2026 · dérivé d'Ohracle

Ce document définit la direction artistique commune à **tous les outils d'intelligence artificielle mis à disposition des Conseillers Culinaires Guy Demarle**. Il est né d'Ohracle, le premier de ces outils, dont il extrait ce qui doit devenir transverse.

Il vit dans le dossier **`system-design/`**, qui se pose **à la racine du dépôt** de chaque application Guy Demarle — déposé et remis à jour automatiquement par les scripts de [`gdm-dev-rules`](https://github.com/GUY-DEMARLE/gdm-dev-rules). Il ne traite que de l'interface : les règles de développement et de sécurité Guy Demarle vivent ailleurs, dans `.ai-rules/RULES.md`.

> ### Pressé ? Trois portes d'entrée
>
> | Vous êtes… | Allez à |
> |---|---|
> | **une IA** (Claude, Copilot, Cursor…) qui doit produire une interface | **[`AGENTS.md`](AGENTS.md)** — les consignes exécutables, dans l'ordre, avec la checklist de fin |
> | **un développeur** qui démarre un outil | **[`kit/demo.html`](kit/demo.html)** (ouvrir par double-clic) puis § 13 ci-dessous |
> | **un designer / un décideur** | ce document, dans l'ordre |
>
> Le kit — jetons, composants, mascotte animée, marque — se copie tel quel. Rien n'est à redessiner. Voir § 13.

> ### Ce que contient le dossier
>
> | | |
> |---|---|
> | [`AGENTS.md`](AGENTS.md) | Le point d'entrée pour une IA : installation, règles vérifiables, interdits, checklist de fin. |
> | `README.md` | Ce document : la direction artistique, et le pourquoi de chaque arbitrage. |
> | [`kit/`](kit/) | Les fichiers à servir : jetons, composants, ambiance, mascotte, marque, banc d'essai. |
> | [`outils/`](outils/) | Le contrôle automatique des règles qui se lisent dans le code. |

Ce document pose l'esprit, la palette, la typographie et les règles d'usage de la mascotte. Le **rendu des briques communes** (bouton, champ, carte, bulle, pastille, alerte, lockup) et le **personnage** sont fournis prêts à l'emploi : ce sont eux qui font la reconnaissance d'un outil à l'autre. Tout le reste — mise en page, navigation, architecture des écrans, pile technique — reste libre, du moment que le résultat passe le test ci-dessous.

> ### Le test en une seconde
>
> Une Conseillère ouvre un écran, sans logo visible, sans titre. Elle doit savoir en une seconde qu'elle est **sur un outil IA Guy Demarle**, et pas sur son back-office de commandes, pas sur un site web, pas sur un outil générique.
>
> Si l'écran échoue à ce test, il est hors charte, même s'il utilise les bonnes couleurs.

---

## 1. Architecture de marque

### 1.1 Le principe retenu

Chaque outil **garde son nom propre**. Ohracle est le chatbot, pas la plateforme. Les outils suivants porteront leurs propres noms.

Ce qui fait la famille, ce n'est donc pas le nom — c'est **le triptyque** :

```
    (O)      NOM DE L'OUTIL          ← la marque O + le nom propre
             par Guy Demarle         ← l'endossement, toujours présent

    + la mascotte, présente sur chaque outil
```

Trois éléments, jamais dissociés. Un outil qui a le O mais pas la signature ressemble à un produit tiers. Un outil qui a la signature mais pas la mascotte ressemble à un outil métier ordinaire, pas à un outil IA.

### 1.2 Le lockup

Le bloc de marque se compose ainsi, de gauche à droite :

| Élément | Règle |
|---|---|
| **La marque O** | Le O rouge en volute, toujours à gauche, toujours en `--gd-red`. Jamais recolorée, jamais détourée, jamais inclinée. |
| **Le nom de l'outil** | En capitales, `--font-sans`, poids 700. **La première lettre est en `--gd-red`, le reste en `--gd-ink`.** C'est la signature typographique de la famille : `O`HRACLE, et de même pour tout nouvel outil. |
| **La signature** | « par Guy Demarle » en dessous, aligné à gauche du nom, en `--gd-ink-soft`, poids 500, à **45 %** de la hauteur de capitale du nom. Obligatoire. |

**Proportions.** La hauteur de la marque O ≈ 2,2 × la hauteur de capitale du nom de l'outil. L'écart entre la marque et le nom ≈ 1 × la largeur de la marque.

**Zone de protection.** Aucun élément à moins d'une hauteur de marque O tout autour du lockup.

**Tailles minimales.** Lockup complet : 120 px de large. En dessous, on ne garde que la marque O seule (min. 20 px), jamais le nom sans la marque.

**Sur fond sombre**, le nom passe en `--gd-ink` (crème) et la marque O en `--gd-red` version sombre (`#e85a5e`). Le lockup n'est jamais posé sur du rouge, ni sur une photo sans voile de lisibilité.

### 1.3 Nommer un nouvel outil

Un nom court, prononçable au téléphone, français ou francisé, qui ne se confond pas avec un produit du catalogue (OHRA, BE SAVE, BOREALIA, CANOFEA) ni avec un outil existant du réseau. Il doit tenir en capitales dans le lockup sans dépasser deux fois la largeur d'« OHRACLE ».

---

## 2. Les six signes de reconnaissance

Ce sont les six choses qui, ensemble, font passer le test en une seconde. Un outil de l'environnement IA les porte toutes.

1. **Le fond crème `#F5F0EB`.** Jamais de blanc pur en fond de page. C'est le signe le plus immédiat, et le moins cher à respecter : c'est ce qui distingue un outil IA GD d'un outil web quelconque.
2. **L'ambiance qui vit dessus.** Le crème nu ne suffit pas : quatre halos gourmands très dilués le traversent et dérivent lentement, des objets de cuisine montent en fond, et rien n'apparaît sec à l'écran. C'est le signe le plus souvent oublié — et celui dont l'absence donne une page beige correcte et anonyme. Voir § 8.
3. **Le rouge en accent unique.** Un seul accent d'action à l'écran. Le rouge dit « c'est ici que tu agis ». S'il y en a partout, il ne dit plus rien.
4. **La mascotte.** Présente, vivante, jamais décorative-inerte. Voir § 5.
5. **La typographie Poppins à l'échelle confort.** Corps de texte à 16 px minimum, jamais moins de 14 px nulle part.
6. **La signature « par Guy Demarle ».** Dans le lockup, et rappelée en pied de page.

---

## 3. Couleurs

### 3.1 Les couleurs de marque

| Rôle | Jeton | Clair | Sombre |
|---|---|---|---|
| Accent principal | `--gd-red` | `#C8373B` | `#e85a5e` |
| Accent enfoncé | `--gd-red-deep` | `#a42a2e` | `#C8373B` |
| Accent atténué | `--gd-red-soft` | `#f2dadb` | `#3d1f21` |
| Fond d'application | `--gd-cream` | `#F5F0EB` | `#1c1814` |
| Fond enfoncé | `--gd-cream-deep` | `#ebe3d6` | `#26211c` |
| Navigation / panneaux | `--gd-sidebar` | `#FCFAF6` | `#211c17` |
| Surface posée | `--gd-paper` | `#ffffff` | `#2a2420` |
| Surface « accueil » | `--gd-paper-warm` | `#fffdf6` | `#2f2822` |
| Texte courant | `--gd-ink` | `#383634` | `#f1e8dc` |
| Texte secondaire | `--gd-ink-soft` | `#7a6f65` | `#a89c8e` |
| Filets et contours | `--gd-border` | `#e4dbce` | `#3a3128` |

Deux choix qui ne sont pas des détails :

- **Le texte n'est pas noir** (`#383634`). Le noir pur sur du crème est trop dur, il casse la chaleur.
- **Le fond sombre est brun anthracite**, pas gris-noir. Un gris neutre transforme instantanément l'univers cuisine en univers tech.

### 3.2 La palette gourmande

`--gd-butter` `#F8D77A` · `--gd-rose` `#EFB9B9` · `--gd-mint` `#B8DFD0` · `--gd-apricot` `#F2C19F` (chacune avec sa variante `-soft`).

Elle sert aux **accents, illustrations, états d'humeur, catégories**. Dans Ohracle, elle colore les bulles de la mascotte selon ce qu'elle dit : beurre à l'accueil, menthe pour un contenu produit, rouge atténué pendant la recherche.

**Le motif « humeur »** est reproductible tel quel : une surface `--gd-paper-warm` (blanc teinté) + un filet dans la couleur gourmande correspondante. C'est ce qui distingue une bulle d'accueil d'une carte d'interface ordinaire, sans recourir à un aplat coloré.

**Jamais** en aplat de fond sur plus d'un quart de l'écran. **Jamais** pour du texte : aucune de ces teintes n'atteint le contraste requis.

### 3.3 Règles d'usage

**Répartition visée : 60 / 30 / 10.** 60 % de crème (fond), 30 % de blanc papier (cartes, bulles, champs), 10 % de rouge et de gourmand (accents). Le rouge dépasse rarement 5 %.

**Le rouge n'est jamais un fond de page.** Il est un fond de bouton, une première lettre, une bordure, une pastille. Un bandeau rouge pleine largeur fait sortir de la charte.

**Un seul rouge à la fois par zone.** Deux boutons rouges côte à côte, c'est un bouton rouge de trop : le second passe en secondaire (`--gd-paper` + bordure).

**Les couleurs sémantiques** (`--color-success`, `--color-error`, `--color-warning`) sont réservées au statut. Ne jamais les utiliser pour de la décoration : un vert décoratif fait croire à une confirmation.

### 3.4 Contrastes mesurés

Mesurés (WCAG 2.1, seuil AA = 4,5:1 pour du texte courant, 3:1 à partir de 18 px ou 14 px gras) :

| Couple | Ratio | Verdict |
|---|---|---|
| `--gd-ink` sur `--gd-cream` | 10,6:1 | AAA ✅ |
| Blanc sur `--gd-red` (bouton principal) | 5,2:1 | AA ✅ |
| `--gd-red` sur `--gd-cream` | 4,6:1 | AA, juste au-dessus du seuil ✅ |
| `--gd-ink-soft` sur `--gd-paper` (blanc) | 4,9:1 | AA ✅ |
| **`--gd-ink-soft` sur `--gd-cream`** | **4,3:1** | **échoue AA en corps de texte** ⚠️ |
| `--gd-ink-soft-aa` sur `--gd-cream` | 5,4:1 | AA ✅ |

En thème sombre, tous les couples équivalents passent AA (le plus serré est le rouge sur fond, à 5,1:1).

> ⚠️ **Point d'attention hérité d'Ohracle.** `--gd-ink-soft` (`#7a6f65`) tient sur une carte blanche (4,9:1) mais **pas sur le fond crème** (4,3:1) — or c'est justement là qu'il sert d'aide de saisie et de texte secondaire à 14-15 px. Sur une cible 50-60 ans, ce n'est pas théorique.
>
> **Règle de la charte :** sur fond crème, `--gd-ink-soft` uniquement à partir de 18 px ou en gras. Pour du texte secondaire courant sur crème, utiliser **`--gd-ink-soft-aa`** (`#6b6058`, 5,4:1), ajouté au fichier de jetons.

---

## 4. Typographie

**Une seule famille sur tout l'environnement : Poppins.** Poids 300 à 700.

```
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');
```

Une police manuscrite (Patrick Hand) a été utilisée un temps pour la voix de la mascotte, puis abandonnée au profit d'une famille unique. Si elle revient un jour, la contrainte tient toujours : **manuscrite droite, jamais italique** — les italiques manuscrites ont été testées et rejetées pour manque de lisibilité sur la cible.

### 4.1 L'échelle

| Jeton | Taille | Usage |
|---|---|---|
| `--text-2xs` | 12 px | Badges, méta — **décoratif uniquement**, jamais d'information seule |
| `--text-xs` | 14 px | Labels, aides de saisie — **plancher absolu** |
| `--text-sm` | 15 px | Petit corps de texte |
| `--text-base` | **16 px** | **Corps de texte par défaut** |
| `--text-md` | 17 px | Corps de texte confortable |
| `--text-lg` | 18 px | Petits titres |
| `--text-xl` | 20 px | Titres de section |
| `--text-2xl` | 22 px | Grands titres |
| `--text-3xl` | 24 px | Titre de page, nom d'outil |
| `--text-4xl` | 28 px | Accroche d'accueil |
| `--text-5xl` | 40 px | Hero, écran de démarrage |

Cette échelle porte environ **+2 px sur chaque palier** par rapport à une échelle classique. Ce n'est pas un oubli de calibrage : c'est un choix assumé pour le confort de lecture des Conseillères. **Ne pas « corriger » à la baisse.**

Si un futur outil doit gagner encore en lisibilité (retour terrain), bumper les onze valeurs de +2 px suffit — tout le reste suit.

### 4.2 Règles de composition

- Interlignage **1,45 à 1,6** pour le corps de texte, **1,2** pour les titres.
- Largeur de colonne de lecture : **65 à 75 caractères** maximum.
- Poids : 400 pour le corps, 500 pour les libellés, 600 pour les titres et boutons, 700 réservé au lockup et aux mentions d'insistance.
- **Pas de texte en capitales au-delà de trois mots** — hors lockup et sur-titres de cartes.
- Jamais de texte gris clair sur crème (voir § 3.4).

---

## 5. La mascotte

### 5.1 Son statut

La mascotte est **l'emblème transverse de l'environnement IA**, pas la propriété du chatbot. Elle apparaît sur chaque outil, avec le même tracé, le même caractère, le même comportement. C'est le signe qui dit à la Conseillère : *ici, c'est l'IA qui t'accompagne.*

C'est une **coquille de madeleine** dorée — base étroite, éventail cannelé, bord festonné à cinq lobes — avec bras et jambes, traitée en **monobloc** : les membres sont dans la matière du corps, sans contraste de couleur. Une version à gants crème et chaussons rouges a été explorée et écartée au profit de la sobriété.

**Version animée : [`gd-ai-mascotte.js`](kit/gd-ai-mascotte.js)**, un élément natif `<gd-mascotte>` qui fonctionne à l'identique en React, Vue, Svelte ou HTML nu. Le tracé, les pivots, les quatre étages de transform et les timings y sont embarqués — c'est ce qui empêche le personnage de dériver d'un outil à l'autre, comme il a dérivé entre le teaser et l'application.

```html
<script src="/gd-ai/gd-ai-mascotte.js" defer></script>
<gd-mascotte pose="salut" size="96"></gd-mascotte>
```

```js
const m = document.querySelector('gd-mascotte')
m.moment('attente')                            // le bon geste au bon moment
m.say('Je mijote ça…', { mood: 'thinking' })   // elle parle
m.hush()                                       // elle se tait
m.poke()                                       // saut ponctuel
```

**Brancher les `moment()` et pas les poses** : c'est ce qui fait que deux outils réagissent pareil au même instant (§ 5.2). Attributs disponibles : `pose`, `size`, `bubble`, `mood`, `bubble-align`, `label`, `ground="off"`, `no-poke`, `reduced`.

Le composant applique lui-même trois règles de charte : il remonte de force à 40 px, il prévient en console si un montant se glisse dans la bulle, et il prévient si un deuxième exemplaire apparaît à l'écran.

Pour un contexte sans JavaScript (e-mail, impression, PDF) : [`gd-ai-mascotte.svg`](kit/gd-ai-mascotte.svg), version statique. Dans Ohracle, la version React historique (`MascotFigure.jsx` + `MascotRig.jsx` + `Mascot.css`) reste en place — même tracé, mêmes timings.

> ### 🔴 Décision ouverte : le nom
>
> La mascotte s'appelle aujourd'hui « Ohracle », comme le chatbot. Ça ne tient plus dès qu'elle sert un deuxième outil : elle porterait le nom d'un produit voisin.
>
> **Il faut lui donner un nom propre, distinct de tout nom d'outil.** Critères : court, prononçable au téléphone, français, chaleureux, culinaire sans être un produit du catalogue, et qui ne soit pas un prénom courant du réseau.
>
> | Piste | Pour | Contre |
> |---|---|---|
> | **Pépite** *(recommandé)* | Gourmand, chaleureux, français. La métaphore fonctionne pour **tous** les outils, pas seulement le chat : « trouver la pépite », c'est exactement ce que fait l'IA. | Légèrement affectueux, à surveiller pour ne pas infantiliser. |
> | **Zeste** | Court, culinaire, énergique, neutre. « Un zeste d'IA ». | Un peu vif et sec face à une silhouette ronde et dorée. |
> | **Praline** | Très gourmand, très Guy Demarle, chaleureux. | Sonne comme un nom d'animal de compagnie. |
> | **Aucun nom** | Zéro décision, zéro risque : elle reste « la madeleine ». | On perd un point d'attachement fort — et le réseau finira par lui en donner un tout seul. |
>
> En attendant l'arbitrage, ce document dit « la mascotte ». Le reste de la charte est utilisable tel quel : le nom n'affecte que les textes d'interface.

### 5.2 Ce qu'elle fait

Elle **accompagne**, elle ne **conduit** pas. Elle réagit aux moments clés — et c'est le **moment** qui est transverse, pas la pose : deux outils qui font le même geste au même instant, c'est ça qui crée la famille.

| Moment | `m.moment(…)` | Pose | Attitude |
|---|---|---|---|
| Accueil | `accueil` | salut | Salue, bras levé |
| Recherche / traitement | `attente` | reflechit | « Je mijote » : bascule lente, bras qui tapote, appui qui change de jambe |
| Réponse prête | `reponse` | presente | Présente le résultat |
| Une action a abouti | `succes` | bravo | Les deux bras en l'air |
| Clic de l'utilisatrice | `clic` | saut | Saut, avec écrasement et réception |
| Rien à dire | `repos` | repos | Respire, balance les bras, cligne des yeux |

Visite guidée ou parcours en étapes : une pose par étape, choisie dans la même liste.

### 5.3 Règles non négociables

- **Une seule mascotte à l'écran à la fois.** Deux exemplaires simultanés cassent le personnage.
- **Une seule voix à la fois.** Si un indicateur de chargement parle déjà, la mascotte se tait (et n'articule pas — une bouche qui bouge sans bulle, c'est le défaut qui trahit tout).
- **Elle ne porte jamais d'information critique.** Pas de chiffre, pas de montant, pas de mention légale, pas de consigne juridique dans sa bulle. Ce qu'elle dit est du statut et de la chaleur ; ce qui compte est dans le fil principal.
- **Elle est toujours au sol.** Son ombre vit à part et ne décolle jamais avec elle.
- **Taille minimale 40 px.** En dessous, les jambes se dissolvent. Deux déclinaisons de repli sont prévues (bras rangés entre 24 et 40 px, coquille seule sous 24 px) mais **pas encore produites** — d'ici là, ne pas l'afficher sous 40 px.
- **Elle s'arrête en `prefers-reduced-motion`.** Toutes ses animations, sans exception.
- Sur petit écran, si elle risque de passer sur le texte, elle **s'efface et ne remonte que quand elle a quelque chose à dire**. Elle n'occupe jamais de place au repos sur mobile.

### 5.4 Interdits

Ne pas la recolorer · ne pas la déformer (autre que l'écrasement de son propre rig) · ne pas la détourer partiellement · ne pas la poser sur un fond rouge · ne pas lui ajouter d'accessoires métier (tablier, casque, badge) · ne pas lui faire porter le logo · ne pas la faire pointer un élément d'interface qu'elle ne touche pas · ne pas lui faire dire « je » sur un contenu réglementaire.

---

## 6. Formes et matière

**Rien n'est à angle vif.** C'est un marqueur d'identité aussi fort que la couleur : une carte à 0 px de rayon sort de la charte même en crème et rouge.

| Élément | Rayon |
|---|---|
| Boutons, champs, cartes | `--radius-lg` 8 px |
| Panneaux, modales | `--radius-2xl` 12 px |
| Bulles de conversation | `--radius-bubble` 18 px |
| Badges, pastilles, suggestions | `--radius-pill` 999 px |

**Les ombres ont une base brune**, jamais noire : `rgba(68, 42, 30, …)`. Une ombre grise neutre refroidit le crème instantanément.

Trois niveaux et pas plus : `--gd-shadow-soft` (surface posée), `--gd-shadow` (élément flottant), `--gd-shadow-lift` (élément saisi ou en survol appuyé).

**La hiérarchie des surfaces** se lit ainsi : fond crème → carte blanche avec filet `--gd-border` et ombre douce → élément flottant avec ombre pleine. Pas de quatrième niveau : au-delà, on empile de la profondeur qui ne veut plus rien dire.

---

## 7. Mouvement

**Deux courbes, pas plus.**

- `--ease-spring` `cubic-bezier(0.34, 1.56, 0.64, 1)` — tout ce qui est **vivant** : la mascotte, les apparitions, les poses, les rebonds.
- `--ease-out-soft` `cubic-bezier(0.22, 0.8, 0.32, 1)` — tout ce qui est **interface** : survol, focus, ouverture de panneau, changement de couleur.

**Cinq durées.**

| Jeton | Durée | Usage |
|---|---|---|
| `--duration-press` | 80 ms | Enfoncement d'un bouton |
| `--duration-state` | 160 ms | Survol, changement de couleur |
| `--duration-enter` | 240 ms | Apparition d'un élément |
| `--duration-move` | 420 ms | Déplacement à l'écran |
| `--duration-travel` | 700 ms | Grande transition de mise en page |

**La vie permanente.** La mascotte respire (3,2 s), balance les bras (2,6 s), cligne des yeux (4,4 s). **Trois périodes volontairement différentes** : elles se déphasent en continu, donc la boucle ne se laisse jamais deviner. Avec une seule animation, l'œil comprend le cycle en deux allers-retours et le personnage redevient un pictogramme. C'est reproductible partout où un outil anime quelque chose de vivant.

**`prefers-reduced-motion` coupe tout.** Non négociable, et aucune information ne doit être portée uniquement par le mouvement.

---

## 8. L'ambiance de page

### 8.1 Pourquoi un chapitre entier pour un fond

Les versions précédentes de cette charte décrivaient le fond en une ligne : **`--gd-cream`, jamais de blanc pur**. C'était vrai, et c'était insuffisant. Une équipe qui applique consciencieusement tous les jetons obtient une page beige, propre, avec les bons boutons — et qui ne ressemble pas à Ohracle. Le critère du test en une seconde n'est pas tenu, alors qu'aucune règle n'est enfreinte.

Ce qui manquait n'était pas une couleur, c'était un **état** : dans Ohracle, le fond est vivant. Il n'est pas plat, il n'est pas fixe, et rien n'y apparaît brutalement. On ne le remarque jamais consciemment — c'est exactement le but — mais on remarque tout de suite son absence.

Le fond est donc traité comme un composant à part entière : [`kit/gd-ai-ambiance.css`](kit/gd-ai-ambiance.css), obligatoire au même titre que les boutons.

### 8.2 Les trois couches

**1 · Les halos qui dérivent.** Quatre disques flous — rouge, beurre, rose, menthe — posés aux quatre coins, à 10-22 % d'opacité, qui dérivent en 22 secondes et repartent en sens inverse. Le rouge est volontairement le plus faible (10 %) : c'est un accent d'action, il ne doit pas colorer la page.

Trois détails font la différence entre ce fond et un dégradé quelconque :

- **La lenteur.** 22 secondes, c'est en dessous du seuil auquel l'œil attrape un mouvement. On perçoit que quelque chose n'est pas figé, sans jamais pouvoir dire quoi. À 8 secondes, le fond devient un objet qui bouge — et il capte l'attention destinée au contenu.
- **`alternate`.** L'animation fait l'aller puis le retour au lieu de sauter à sa position de départ. Sans ça, un à-coup toutes les 22 secondes, et l'illusion tombe.
- **Le débord de 20 %.** Le calque dépasse largement de la page : la dérive ne découvre jamais un bord vide.

**2 · Les objets flottants.** Sept emojis de cuisine qui montent lentement, à 25 % d'opacité globale, avec des décalages tous différents pour que la boucle ne se laisse pas deviner — le même principe que les trois périodes de respiration de la mascotte (§ 7).

C'est la couche la moins chère de tout le design system : aucun fichier à charger, aucune illustration à commander, et l'univers de la maison est posé en sept caractères. Les emojis appartiennent à chaque outil ; le kit ne fournit que les positions, les tailles et les décalages.

Deux garde-fous : `aria-hidden` — sept emojis énumérés à l'entrée d'une page sont sept obstacles pour un lecteur d'écran — et **aucun symbole d'interface ni de statut** (⚙️, 📊, ✅, ⚠️). Le décor ne doit jamais pouvoir passer pour une information.

**3 · Les entrées.** Rien n'apparaît sec. Deux gestes, pas un de plus : `.gd-enter` pour l'interface qui arrive (8 px de montée, courbe d'interface), `.gd-settle` pour ce qui est vivant et se pose (léger dépassement, courbe ressort). Une réponse d'IA se pose ; un panneau entre.

Sur une liste, échelonner avec `--gd-enter-delay` — et pas au-delà de cinq ou six éléments : le décalé en cascade est charmant sur cinq lignes et devient une lenteur sur vingt.

### 8.3 Le dosage

| Jeton | Valeur | Ce qui arrive si on y touche |
|---|---|---|
| `--gd-halo-*` | 10 à 22 % | Au-dessus de 25 %, le fond devient une image et le texte perd du contraste. |
| `--gd-ambient-drift` | 22 s | En dessous de 15 s, le mouvement devient perceptible et distrait. |
| `--gd-ambient-float` | 18 s | Idem. |
| `--gd-ambient-veil` | 0,25 | Le seul jeton qu'il est légitime d'ajuster : monter à 0,35 sur un outil très aéré, descendre à 0,15 sur un outil dense. |

**La règle qui résume tout : un fond qu'on remarque est un fond raté.** La tentation, en intégration, est de monter les valeurs « pour qu'on voie mieux le travail ». C'est l'inverse du but.

Un mot sur la règle « la palette gourmande n'est jamais un aplat de fond sur plus d'un quart de l'écran » (§ 3.3) : les halos couvrent tout l'écran, mais à 10-22 % ce sont des **voiles**, pas des aplats. L'exception est assumée et bornée par les jetons ci-dessus — elle ne s'étend à aucune autre surface.

### 8.4 Où se pose la classe

Deux formes d'application, et le choix n'est pas cosmétique.

Sur une **coquille plein écran** — un chat, un tableau de bord, tout ce qui occupe la fenêtre et confie le défilement à une zone interne — `gd-ambient` seul convient : le décor épouse la coquille et ce qui dépasse est découpé.

Sur un **document qui défile** — réglages, documentation, long formulaire — il faut `gd-ambient--fixed`, pour deux raisons. La première est visuelle : étiré sur 6 000 px de hauteur, le décor donne quatre halos géants qu'on ne voit plus. La seconde est un piège de CSS qui coûte cher à diagnostiquer : sur `<body>`, la propriété `overflow` **se propage à la fenêtre**. Un découpage posé sur le `<body>` d'un document long bloque le défilement de la page entière. La variante `--fixed` accroche le décor à la fenêtre et rend tout découpage inutile.

### 8.5 Mode sombre

Les mêmes valeurs sur le brun anthracite donnent du néon : sur fond sombre, un voile clair **ajoute** de la lumière au lieu d'en retirer. Les halos sombres sont donc à peu près divisés par deux, sauf le rouge qui remonte légèrement — c'est lui qui porte la chaleur quand tout le reste s'éteint. Le résultat visuel visé : des braises, pas une enseigne.

### 8.6 Mouvement réduit

**L'ambiance ne disparaît pas, elle s'immobilise.** Une personne qui coupe les animations demande moins de mouvement, pas un autre produit : elle doit voir le même outil, arrêté.

Le piège concret, et il est facile à manquer : les objets flottants démarrent à `opacity: 0` et ne deviennent visibles que par leur animation. Couper l'animation sans redonner une opacité les efface — la couche disparaît entièrement, et personne ne s'en aperçoit parce qu'on ne teste presque jamais avec le réglage activé. Le kit le traite ; une réécriture maison, presque jamais.

> **À corriger dans Ohracle.** L'application, qui est la source de ce motif, n'a **pas** ce garde-fou : `meshDrift` (22 s) et `floatDrift` (18 s) tournent en boucle infinie sans être coupés par `prefers-reduced-motion`. C'est un écart de la source par rapport à la charte, pas l'inverse.

---

## 9. Ton de voix

L'IA s'adresse à une Conseillère comme **une collègue expérimentée**, pas comme un service client ni comme un assistant générique.

- **Tutoiement**, toujours.
- Trois à cinq emojis par réponse, pas plus. Ils rythment, ils ne décorent pas.
- Pédagogique : on explique le *pourquoi*, pas seulement le *quoi*.
- Concret : un exemple chiffré vaut mieux qu'un paragraphe de principe.
- **Disclaimer obligatoire** sur tout ce qui touche à l'URSSAF, à la fiscalité, au juridique ou à la santé.
- **Périmètre strict** : hors Guy Demarle, on décline poliment et on ne brode pas.
- **Jamais de chiffre inventé.** Si la donnée n'est pas disponible, on le dit et on renvoie vers l'espace conseillère.

Ces règles valent pour tous les outils IA du réseau, quel que soit leur métier.

---

## 10. Accessibilité

La cible est un réseau de 4000+ Conseillers, majoritairement des femmes, dont une part importante entre 45 et 65 ans, souvent sur mobile, parfois dans de mauvaises conditions de lumière. L'accessibilité n'est pas une option de fin de projet.

- **Contraste AA minimum** partout. Voir § 3.4 et le point d'attention sur `--gd-ink-soft`.
- **Taille de texte 16 px** par défaut, plancher absolu à 14 px.
- **Cibles tactiles 44 × 44 px** minimum.
- **Focus visible** sur tout élément interactif — l'anneau `--gd-red-glow` est fourni dans les jetons. Ne jamais faire `outline: none` sans remplacement.
- **`prefers-reduced-motion`** respecté.
- **Jamais d'information portée par la couleur seule** : une erreur en rouge porte aussi un texte, une icône ou un libellé.
- Zoom navigateur jusqu'à 200 % sans perte de fonction.

---

## 11. Do / Don't

| ✅ | ❌ |
|---|---|
| Fond crème `--gd-cream` | Fond blanc pur pleine page |
| Un seul bouton rouge par zone | Trois actions rouges côte à côte |
| Rouge en accent, bouton, filet | Bandeau rouge pleine largeur |
| Palette gourmande en accent | Palette gourmande en aplat de fond |
| Ombres à base brune | Ombres grises ou noires |
| Corps de texte à 16 px | Corps de texte à 13 px « pour faire moderne » |
| Mascotte au sol, 40 px minimum | Mascotte en 24 px, jambes en bouillie |
| La mascotte commente le statut | La mascotte annonce un montant de commission |
| Une seule mascotte à l'écran | Deux exemplaires qui parlent en même temps |
| `var(--gd-red)` dans le code | `#C8373B` écrit en dur |
| « par Guy Demarle » sous le nom | Nom d'outil seul, sans endossement |
| `.gd-btn` du kit | Un bouton réécrit « vite fait » à côté |
| `<gd-mascotte>` | Un SVG de la mascotte recopié à la main |

---

## 12. Ce qui est fourni, ce qui reste libre

**Fourni, et à utiliser tel quel** (`gd-ai-components.css`) : bouton, pastille, badge, champ, carte, panneau, humeur, bulle de conversation, indicateur d'attente, alerte, lockup, colonne de lecture. Et (`gd-ai-ambiance.css`) : le fond vivant, les objets flottants, les deux entrées. Ce sont les briques qu'une Conseillère voit sur deux outils à cinq minutes d'intervalle : si elles diffèrent, la famille ne se voit plus. **N'en réécris pas une qui existe** — c'est exactement là que deux outils divergent.

> **Pourquoi ce durcissement.** La version 1 de cette charte laissait les composants libres. À l'usage, deux équipes qui partent des mêmes jetons produisent quand même deux boutons différents : pas la même hauteur, pas le même rayon, pas la même ombre au survol. Les jetons garantissent la couleur, pas la reconnaissance. La mise en page, elle, reste libre : c'est le métier qui la dicte, et l'uniformiser n'apporterait rien.

**Libre, et qui appartient à chaque outil :**

- sa **mise en page** et sa navigation, dictées par son métier ;
- ses **illustrations** et son iconographie propre — dont les **sept emojis** de la couche flottante (§ 8.2) : le kit porte les positions, l'outil choisit les objets ;
- ses **micro-interactions** spécifiques ;
- sa **pile technique** — React, Vue, Svelte, rendu serveur, peu importe : le kit est du CSS et un élément natif ;
- ses **composants métier**, tant qu'ils consomment les jetons.

Aucune bibliothèque tierce n'est imposée — et aucune n'est souhaitable **par-dessus** le kit : Material, Bootstrap ou shadcn réimposent leurs propres rayons, ombres et échelles, et l'outil sort de la famille. Si un projet en utilise déjà une, mapper ses variables sur les jetons GD plutôt qu'empiler. Ohracle a ses propres composants (`frontend/src/components/ui/`), antérieurs au kit ; ils restent une référence, pas une obligation.

---

## 13. Adopter le design system

Il n'y a **rien à copier à la main** : `install.ps1` / `install.sh` de `gdm-dev-rules` posent `system-design/` à la racine du dépôt en même temps que les règles GDM, et `update.ps1` / `update.sh` le remettent à jour. Reste à faire, côté application : **servir les fichiers du kit depuis le front** (par exemple sous `public/gd-ai/`). C'est tout — aucun build, aucune dépendance, aucun paquet à installer.

```powershell
# Windows, depuis la racine du repo
irm https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/install.ps1 | iex
```

```bash
# Mac / Linux, depuis la racine du repo
curl -sSL https://raw.githubusercontent.com/GUY-DEMARLE/gdm-dev-rules/main/install.sh | bash
```

| Fichier | Rôle | Statut |
|---|---|---|
| [`AGENTS.md`](AGENTS.md) | Les consignes exécutables pour une IA qui produit l'interface : installation, squelette, règles vérifiables, interdits, checklist de fin. | ⭐ |
| [`kit/gd-ai-tokens.css`](kit/gd-ai-tokens.css) | Tous les jetons (couleurs clair + sombre, typo, espacement, rayons, ombres, mouvement) + le socle minimal. | obligatoire |
| [`kit/gd-ai-components.css`](kit/gd-ai-components.css) | Les briques communes : bouton, champ, carte, bulle, pastille, alerte, lockup. | obligatoire |
| [`kit/gd-ai-ambiance.css`](kit/gd-ai-ambiance.css) | L'ambiance de page : les halos qui dérivent, les objets flottants, les deux entrées. | obligatoire |
| [`kit/gd-ai-mascotte.js`](kit/gd-ai-mascotte.js) | La mascotte animée, élément natif `<gd-mascotte>`. | dès qu'il y a une mascotte |
| [`kit/gd-ai-marque-o.png`](kit/gd-ai-marque-o.png) | La marque O du lockup. | recommandé |
| [`kit/gd-ai-mascotte.svg`](kit/gd-ai-mascotte.svg) | La mascotte statique, pour les contextes sans JavaScript. | au besoin |
| [`kit/demo.html`](kit/demo.html) | Le banc d'essai : tout le kit rendu à l'écran, la mascotte pilotable, clair/sombre, animations réduites. Ouvrable par double-clic. | ⭐ |
| [`outils/verifier-interface.mjs`](outils/verifier-interface.mjs) | Le contrôle automatique des règles qui se lisent dans le code (`node …/verifier-interface.mjs frontend/src`). | recommandé |

```html
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/gd-ai/gd-ai-tokens.css">
<link rel="stylesheet" href="/gd-ai/gd-ai-components.css">
<script src="/gd-ai/gd-ai-mascotte.js" defer></script>
```

**Une seule règle de code :** aucune valeur de couleur, de taille de texte, de rayon ou de durée écrite en dur. Uniquement `var(--gd-*)`. C'est ce qui permettra de faire évoluer la charte sans rouvrir chaque application.

**Le rappel dans le `CLAUDE.md` / `AGENTS.md` du projet** — pour que l'IA qui y travaille trouve la charte sans qu'on ait à le lui redire à chaque session — est posé par les mêmes scripts. Sur un dépôt qui n'utilise pas `gdm-dev-rules`, le bloc à coller est en bas de [`AGENTS.md`](AGENTS.md).

**Ne pas modifier les fichiers du kit** pour un besoin local : une valeur qui ne convient pas est une évolution du design system, elle se discute et elle se fait **dans la source**, pas dans la copie. Sinon les copies divergent et, au bout de trois applications, il n'y a plus de design system mais trois dialectes.

**Le contrôle automatique** attrape les écarts qui se lisent dans le code :

```bash
node system-design/outils/verifier-interface.mjs frontend/src
```

Il ne remplace pas le regard sur l'écran — un seul bouton rouge par zone, lockup complet, test en une seconde : ça ne se lit pas dans un fichier.

---

## 14. Décisions ouvertes

| Sujet | État |
|---|---|
| **Où vit la source** | **Tranché.** La source est `GUY-DEMARLE/gdm-dev-rules`, dossier `templates/system-design/` : toute évolution s'y fait, en PR, et se propage aux applications par `update.ps1` / `update.sh`. Les copies présentes dans les dépôts applicatifs (Ohracle, interface-ia) sont des copies de travail écrasées à chaque mise à jour. Le versionnage (pouvoir épingler une version) reste à poser : aujourd'hui `update` prend toujours `main`. |
| **Nom de la mascotte** | À trancher. Shortlist et recommandation au § 5.1. Bloque toute communication qui la nomme ; d'ici là, écrire « la mascotte ». |
| **Déclinaisons petite taille** | Non produites. Bras rangés (24-40 px) et coquille seule (< 24 px) restent à dessiner. En attendant, le composant remonte de force à 40 px. |
| **Planche d'expressions** | Six poses existent et sont jouables (§ 5.2). Une planche complète de 8 à 12 états reste à dessiner pour couvrir des outils plus variés que le chat. |
| **Marque O sans version vectorielle** | Le kit n'a que le PNG. La variante teintée `.gd-lockup__mark--tint` le contourne (le fichier sert de masque, la couleur vient des jetons) et donne le bon rouge en thème sombre, mais une vraie source SVG reste souhaitable pour les grands formats et l'impression. |
| **`--gd-ink-soft` sous le seuil AA** | `--gd-ink-soft-aa` est fourni, et la classe `.gd-text-soft` l'applique. Reste à décider si Ohracle bascule dessus ou si l'on remonte les tailles concernées. |
| **Favicon et icônes d'application** | Ohracle a les siennes. Une règle de famille (même gabarit, initiale variable) reste à poser. |
| **Mode sombre** | Complet côté jetons et composants, testable dans `demo.html`, non exposé aujourd'hui dans l'interface d'Ohracle. |
| **`prefers-reduced-motion` dans Ohracle** | Écart connu, non corrigé : les deux animations de fond de l'application (`meshDrift`, `floatDrift`) ne sont pas coupées. Le kit, lui, les fige. À reprendre dans l'application, indépendamment de l'adoption du kit (§ 8.6). |
| **Ohracle n'a pas encore adopté le kit** | L'application vit sur ses propres thèmes et ses propres composants, dont le kit est dérivé. Tant qu'elle n'en consomme pas les fichiers, les deux peuvent diverger : c'est la charte qui fait foi. |

---

## Journal

| Version | Date | Ce qui change |
|---|---|---|
| 1.4 | 3 septembre 2026 | **L'ambiance de page entre dans le kit** ([`kit/gd-ai-ambiance.css`](kit/gd-ai-ambiance.css), § 8) : les quatre halos gourmands qui dérivent, les sept objets flottants, les deux entrées `.gd-enter` / `.gd-settle`. Motif : un outil pouvait respecter tous les jetons et rendre une page beige anonyme — le fond était décrit comme une couleur alors que c'est un état. Les signes de reconnaissance passent de cinq à six (§ 2), deux règles vérifiables sont ajoutées (AGENTS § 2, règles 14 et 15) et le contrôle automatique refuse désormais un front sans ambiance. |
| 1.3 | 2 septembre 2026 | Le design system devient **distribué** : il quitte le dépôt d'Ohracle pour `GUY-DEMARLE/gdm-dev-rules` (`templates/system-design/`), d'où `install`/`update` le posent à la racine de **chaque application Guy Demarle**, à côté des règles dev et sécu. Le rappel de lecture est ajouté aux `CLAUDE.md`, `AGENTS.md` et règles Cursor distribués. Contenu de la charte inchangé. |
| 1.2 | 2 septembre 2026 | La charte devient le **design system** de l'environnement IA : le dossier passe de `docs/charte-ia/` à **`system-design/`, à la racine** du dépôt, pour être copié tel quel dans chaque application. Le kit passe sous [`kit/`](kit/), et [`outils/verifier-interface.mjs`](outils/verifier-interface.mjs) contrôle automatiquement les règles qui se lisent dans le code. Périmètre inchangé : l'interface, rien que l'interface. |
| 1.1 | 26 août 2026 | Le kit devient exécutable : `AGENTS.md` (consignes pour une IA), `gd-ai-components.css` (les briques communes, § 12), `gd-ai-mascotte.js` (le personnage animé en élément natif, § 5.1), `gd-ai-marque-o.png`, `demo.html` (banc d'essai). Les composants passent de « libres » à « fournis ». |
| 1 | 5 août 2026 | Première charte, dérivée d'Ohracle : architecture de marque, palette, typographie, mascotte, formes, mouvement, ton, accessibilité. |

---

*Charte dérivée d'Ohracle. Sources : `frontend/src/themes/`, `frontend/src/components/Mascot.css`, `frontend/src/components/MascotFigure.jsx`, `frontend/src/components/MascotRig.jsx`, `frontend/src/components/ui/ui.css`.*
