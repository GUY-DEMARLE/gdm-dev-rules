# Design system — Applications internes Guy Demarle

Version 1.0 · 21 octobre 2026 · direction « Maison sobre »

Ce document définit l'interface des **outils internes Guy Demarle** : back-offices,
référentiels (produits, conseillers, stocks), outils de pilotage et d'analyse, écrans
d'intégration ERP. Ce sont les outils des équipes Guy Demarle, pas ceux des Conseillers.

C'est le **profil interne** du design system. Le profil **Conseillers** — l'environnement
IA, la mascotte, le fond vivant — reste à la racine de `system-design/`. Les deux profils
partagent la marque et rien d'autre.

> ### Pressé ? Trois portes d'entrée
>
> | Vous êtes… | Allez à |
> |---|---|
> | **une IA** qui doit produire une interface | **[`AGENTS.md`](AGENTS.md)** — consignes exécutables et checklist |
> | **un développeur** qui démarre un outil | **[`kit/demo.html`](kit/demo.html)** (double-clic) puis § 10 |
> | **un designer / un décideur** | ce document, dans l'ordre |

> ### Le test en une seconde
>
> Un collaborateur ouvre un écran, sans logo visible. Il doit savoir en une seconde qu'il
> est **sur un outil Guy Demarle**, et que c'est **un outil de travail** : sobre, dense,
> fait pour comparer, saisir et décider. Ni un outil Conseillers, ni un tableau de bord
> générique.

---

## 1. Pourquoi un deuxième profil

Le design system est né d'Ohracle, pour les Conseillers : un public de 4 000 personnes,
majoritairement sur mobile, souvent entre 45 et 65 ans, à qui l'IA parle comme une collègue.
D'où l'échelle confort à 16 px, les cibles de 44 px, la mascotte, le fond crème qui respire.

Appliqué à un référentiel produits ou à un écran d'import, ce même langage dessert
l'utilisateur. Le collaborateur est au bureau, à la souris, sur un grand écran ; il passe
la journée sur l'outil ; il compare cinquante lignes, pas trois bulles. Une mascotte y fait
jouet, un fond animé y distrait, des contrôles de 44 px y font défiler pour rien.

Il fallait donc un profil **plus pro et plus sérieux**, sans perdre la marque. Trois pistes
ont été comparées le 21 octobre 2026 sur le même écran de référentiel :

| Piste | Principe | Verdict |
|---|---|---|
| **A · Maison sobre** | Poppins, blanc cassé chaud, arrondis 6 px, ombres brunes légères | **Retenue** |
| B · Back-office net | Inter, gris froid, filets sans ombres | Plus neutre, mais perd le lien avec la maison |
| C · Institutionnel | IBM Plex Sans, navigation anthracite, angles quasi droits | Sérieux mais froid |

« Maison sobre » garde ce qui fait Guy Demarle — le rouge, la marque O, Poppins, la chaleur
du blanc cassé et des ombres brunes — et retire tout ce qui relève de l'accompagnement des
Conseillers.

---

## 2. Ce qui est commun aux deux profils, et ce qui ne l'est pas

| | Conseillers | Interne |
|---|---|---|
| Rouge `#C8373B`, marque O, première lettre rouge | ✅ | ✅ |
| Poppins, une seule famille | ✅ | ✅ |
| Fond chaud, jamais de blanc pur en page | crème `#F5F0EB` | blanc cassé `#FAF8F5` |
| Ombres à base brune | ✅ | ✅, plus légères |
| Rien à angle vif | 8 à 18 px | 6 et 8 px |
| Corps de texte | 16 px | 14 px (tableaux 13 px) |
| Cibles | 44 px | 36 px au pointeur, 44 px sur tablette |
| Mascotte, fond vivant, objets flottants | ✅ obligatoires | ❌ interdits |
| Palette gourmande | ✅ accents | ❌ |
| Signature | « par Guy Demarle » | « Guy Demarle » |
| Ton | tutoiement, chaleureux, emojis mesurés | vouvoiement, factuel, sans emoji |
| Coquille d'application | libre | **fournie** (navigation, tableau) |

Les jetons et les classes communes portent **les mêmes noms** dans les deux kits
(`--gd-red`, `--gd-cream`, `--text-base`, `.gd-btn`, `.gd-card`…) avec des valeurs
différentes. Un composant métier écrit avec les jetons suit le profil chargé. La
contrepartie : on ne charge **jamais les deux kits dans la même page**.

---

## 3. Couleurs

### 3.1 Marque et surfaces

| Rôle | Jeton | Valeur |
|---|---|---|
| Action principale, élément actif | `--gd-red` | `#C8373B` |
| Survol du rouge, texte sur fond rouge pâle | `--gd-red-deep` | `#a42a2e` |
| Fond de l'élément de navigation actif | `--gd-red-soft` | `#f2dadb` |
| Ligne de tableau sélectionnée | `--gd-red-wash` | `#FDF4F4` |
| Fond d'application | `--gd-cream` | `#FAF8F5` |
| Zone enfoncée, champ désactivé | `--gd-cream-deep` | `#F2EDE6` |
| Navigation, en-têtes de tableau, pieds de carte | `--gd-sidebar` | `#FCFAF6` |
| Surface posée | `--gd-paper` | `#ffffff` |
| Survol | `--gd-hover` | `#F6F1EA` |
| Texte courant | `--gd-ink` | `#383634` |
| Texte secondaire | `--gd-ink-soft` | `#6b6058` |
| Filets | `--gd-border` | `#ECE5DA` |
| Contour de bouton secondaire | `--gd-border-strong` | `#D9CFC1` |
| Contour de champ | `--gd-border-field` | `#9A8D7C` |

### 3.2 Le rouge : quatre usages, pas un de plus

L'action principale, l'élément actif de la navigation, l'onglet actif, la première lettre
du nom de l'outil. C'est tout.

Sur un écran dense, chaque tache de rouge attire l'œil. Un titre rouge, un bandeau rouge ou
une erreur en rouge de marque brouillent la seule chose que le rouge doit dire : « c'est ici
que vous agissez ». Une erreur prend la couleur de statut `--color-error`, plus sombre, avec
son texte. Une suppression prend `.gd-btn--danger`, en contour, jamais en rouge plein : le
rouge plein est déjà l'action principale.

### 3.3 Statuts

| Statut | Texte | Fond |
|---|---|---|
| Succès (publié, validé) | `--color-success` `#1F6B3A` | `--color-success-bg` `#E6F2EA` |
| Attention (à valider, en retard) | `--color-warning` `#7A5208` | `--color-warning-bg` `#FBF0D9` |
| Erreur (rupture, échec) | `--color-error` `#A32D2D` | `--color-error-bg` `#FBE9E9` |
| Information (en cours) | `--color-info` `#2F5A85` | `--color-info-bg` `#E8EFF6` |
| Neutre (brouillon, archivé) | `--color-neutral` `#5A5550` | `--color-neutral-bg` `#EEECE8` |

Réservées au statut, jamais à la décoration. Un statut porte **toujours son libellé** : la
couleur confirme, elle n'informe pas seule.

### 3.4 Contrastes mesurés

WCAG 2.1, seuil AA = 4,5:1 pour du texte, 3:1 pour un contour de composant.

| Couple | Ratio | Verdict |
|---|---|---|
| `--gd-ink` sur `--gd-cream` | 11,4:1 | AAA ✅ |
| `--gd-ink-soft` sur `--gd-cream` | 5,8:1 | AA ✅ |
| `--gd-ink-soft` sur `--gd-paper` | 6,1:1 | AA ✅ |
| Blanc sur `--gd-red` (bouton principal) | 5,2:1 | AA ✅ |
| `--gd-red-deep` sur `--gd-red-soft` (navigation active) | 5,4:1 | AA ✅ |
| Les cinq statuts, texte sur fond | 5,7 à 6,3:1 | AA ✅ |
| `--gd-border-field` sur `--gd-paper` (contour de champ) | 3,2:1 | ✅ |

Contrairement au profil Conseillers, **le texte secondaire est conforme partout** : il n'y
a pas de variante `-aa` à retenir. `--gd-ink-soft-aa` existe encore, comme alias, pour
qu'un composant écrit pour les Conseillers reste conforme ici.

---

## 4. Typographie

**Poppins, poids 400 à 700.** La même famille que chez les Conseillers : c'est elle qui fait
le lien de marque le plus fort entre les deux profils.

| Jeton | Taille | Usage |
|---|---|---|
| `--text-2xs` | 11 px | Compteur, méta décorative — jamais d'information seule |
| `--text-xs` | 12 px | En-têtes de colonnes, aides, badges — **plancher pour l'information** |
| `--text-sm` | 13 px | Cellules de tableau, contrôles, navigation |
| `--text-base` | **14 px** | **Corps de texte** |
| `--text-md` | 15 px | |
| `--text-lg` | 16 px | Titres de carte, de modale |
| `--text-xl` | 18 px | Titres de section |
| `--text-2xl` | 20 px | |
| `--text-3xl` | 22 px | Titre de page, valeur d'indicateur |
| `--text-4xl` | 26 px | |
| `--text-5xl` | 32 px | |

Poids : 400 pour le texte, 500 pour les libellés et la navigation, 600 pour les titres et
les valeurs, 700 réservé au nom de l'outil. Interlignage 1,45 pour le corps.

---

## 5. Pas de mascotte, et l'IA quand même

La mascotte est l'emblème de **l'environnement IA des Conseillers**. Dans un outil interne,
elle n'apparaît pas, même quand l'outil embarque une fonction d'IA. Ni le fond vivant, ni
les objets flottants, ni les bulles gourmandes.

Une fonction d'IA se signale par le badge `.gd-badge--ia` et par un texte qui dit ce que
l'IA a fait et sur quelles sources. Un résultat d'IA ne s'enregistre jamais sans une action
explicite de l'utilisateur.

---

## 6. Formes, matière, mouvement

**Rien n'est à angle vif**, comme chez les Conseillers, mais plus serré : 6 px pour les
boutons, champs, cartes et tableaux ; 8 px pour les modales et les panneaux ; pastilles
rondes pour les badges.

**Les ombres ont une base brune**, plus légères que chez les Conseillers. Sur un écran
dense, la hiérarchie vient des filets avant de venir des ombres. Trois niveaux :
`--gd-shadow-soft` (carte, tableau), `--gd-shadow` (menu), `--gd-shadow-lift` (modale).

**Une seule courbe**, `--ease-out-soft`, et des durées courtes (80 à 240 ms). Il n'y a rien
de vivant dans un outil interne : pas de ressort, pas d'entrée en cascade. On y passe la
journée ; chaque animation se paie des centaines de fois.

**`prefers-reduced-motion` coupe tout.**

---

## 7. Les écrans d'un outil interne

Contrairement au profil Conseillers, **le kit fournit la coquille** : un outil interne se
reconnaît à sa navigation et à ses tableaux bien avant ses boutons. Deux outils qui les
dessinent chacun à leur façon ne forment plus une famille.

- **Coquille** : navigation à gauche (232 px), fixe ; contenu à droite, jusqu'à 1 440 px.
  Sous 900 px, la navigation passe au-dessus.
- **En-tête de page** : fil d'Ariane, titre, une phrase de contexte si utile, les actions à
  droite, une seule en rouge.
- **Indicateurs** : quatre au plus sur une ligne, chacun avec son évolution écrite
  (« +18 cette semaine »).
- **Barre de filtres** au-dessus du tableau : recherche, deux ou trois filtres, actions de
  masse.
- **Tableau** : lignes de 40 px (32 px en `--compact`), nombres à droite en chasse fixe,
  références en texte secondaire, ligne sélectionnée lavée de rouge, pied avec la sélection
  et la pagination. Le tableau défile dans son cadre, jamais la page.
- **Fiche** : carte avec liste de propriétés, onglets si la fiche est longue, actions en pied
  de carte.
- **Formulaire** : libellé toujours au-dessus du champ, aide sous le champ, erreur en texte
  sous le champ, deux colonnes au-delà de 720 px.
- **Suppression** : bouton `--danger`, puis modale qui nomme l'objet et ce qui disparaît.
- **État vide** : ce que contiendra l'écran, et l'action qui le remplit.

---

## 8. Ton

- **Vouvoiement**, factuel, sans emoji ni point d'exclamation.
- Boutons à l'infinitif : « Enregistrer », « Valider la fiche ».
- Une erreur dit ce qui s'est passé, puis quoi faire.
- Formats français : `21/10/2026`, `14:05`, `1 284`, `92,4 %`, `39,90 €`.
- Une donnée absente s'affiche `—` et se dit absente. Jamais de chiffre inventé.

---

## 9. Accessibilité

- Contraste AA partout (§ 3.4), contour de champ à 3:1.
- Focus visible, anneau rouge plein de 2 px : un halo pâle ne se voit pas sur un tableau.
- Cibles de 36 px au pointeur, **44 px dès qu'un écran sert sur tablette** (`.gd-btn--lg`).
- Aucune information portée par la seule couleur.
- Navigation active et page courante annoncées par `aria-current`, ligne sélectionnée par
  `aria-selected`.
- Modale sur `<dialog>` natif : focus, touche Échap et voile gérés par le navigateur.
- Zoom à 200 % sans perte de fonction ; à 375 px de large, seul un tableau défile.

---

## 10. Adopter le profil interne

1. Dans le `CLAUDE.md` (et l'`AGENTS.md`) du projet, section « Contexte du projet », écrire :

   ```markdown
   - Profil d'interface : interne
   ```

   Cette section appartient au projet : `gdm-dev-rules` ne l'écrase jamais. Sans cette
   ligne, l'app reste en profil Conseillers.

2. Servir `kit/gd-interne-tokens.css`, `kit/gd-interne-components.css` et
   `kit/gd-interne-marque-o.png` depuis le front (par exemple sous `public/gd-interne/`),
   et les charger avant les feuilles du projet. Voir [`AGENTS.md`](AGENTS.md) § 0.

3. Contrôler :

   ```bash
   node system-design/outils/verifier-interface.mjs frontend/src --profil interne
   ```

   Le profil est aussi lu dans le `CLAUDE.md` du dossier courant ; `--profil` le force.

**Ne pas modifier les fichiers du kit** pour un besoin local : une valeur qui ne convient
pas est une évolution du design system, elle se fait dans la source
(`GUY-DEMARLE/gdm-dev-rules`, `templates/system-design/interne/`), par une PR.

---

## 11. Décisions ouvertes

| Sujet | État |
|---|---|
| **Liste des apps internes** | À établir. Chaque app bascule en ajoutant la ligne « Profil d'interface : interne » ; aucune ne change de profil sans cette ligne. |
| **Graphiques** | Pas de palette de données dans le kit. À poser quand un outil de pilotage en aura besoin : séries sans rouge de marque, statuts réservés au statut. |
| **Menus déroulants, infobulles, notifications** | Non fournis en version 1.0. À ajouter au premier besoin réel, dans la source. |
| **Icônes** | Libres (16 px, trait fin, couleur du texte). Une bibliothèque commune reste à choisir. |
| **Marque O vectorielle** | Comme pour le profil Conseillers, seul le PNG existe. |

---

## Journal

| Version | Date | Ce qui change |
|---|---|---|
| 1.0 | 21 octobre 2026 | Création du profil interne, direction « Maison sobre » retenue parmi trois pistes. Jetons, composants (coquille, navigation, tableau, indicateurs, filtres, formulaire, modale, état vide), banc d'essai, consignes pour les IA, contrôle automatique avec `--profil interne`. |
