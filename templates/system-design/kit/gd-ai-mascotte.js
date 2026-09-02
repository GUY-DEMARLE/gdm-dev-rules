/* ============================================================================
   Guy Demarle — Environnement IA Conseillers
   La mascotte animée, en composant natif (gd-ai-mascotte.js)
   ----------------------------------------------------------------------------
   Un seul fichier, aucune dépendance, aucun build. Fonctionne à l'identique en
   React, Vue, Svelte, Angular ou HTML nu — c'est tout l'intérêt : le
   personnage ne peut pas diverger d'un outil à l'autre.

       <script src="/gd-ai/gd-ai-mascotte.js" defer></script>
       <gd-mascotte pose="salut" size="96"></gd-mascotte>

   Piloter depuis le code :

       const m = document.querySelector('gd-mascotte')
       m.pose = 'reflechit'                       // repos | salut | presente
                                                  // saut | reflechit | bravo
       m.say('Je mijote ça…', { mood: 'thinking' })
       m.hush()
       m.poke()                                   // saut ponctuel

   POURQUOI UN COMPOSANT ET PAS UN SVG À RECOPIER
   Le tracé seul ne fait pas le personnage : ce sont les pivots, les quatre
   étages de transform et les trois périodes d'animation qui le rendent vivant.
   Recopiés à la main, ils dérivent — c'est déjà arrivé entre le teaser et
   l'application. Ici le rig voyage avec le dessin.

   CE QUI EST VERROUILLÉ, ET POURQUOI
   - Le tracé, les couleurs et les pivots : c'est la signature de
     l'environnement IA, elle doit être identique partout.
   - La taille plancher de 40 px : en dessous les jambes se dissolvent. Les
     deux déclinaisons de repli (bras rangés, coquille seule) ne sont pas
     encore dessinées, donc le composant remonte à 40 px et prévient en
     console plutôt que d'afficher une bouillie.
   - prefers-reduced-motion : coupe tout, sans exception possible.

   Source : MascotFigure.jsx + MascotRig.jsx + Mascot.css du projet Ohracle.
   Design system : system-design/README.md § 5
   ========================================================================== */

(() => {
  'use strict'

  if (customElements.get('gd-mascotte')) return

  /* --------------------------------------------------------------------------
     Les poses. Quatre angles de membres + un effet ponctuel + la bouche tenue
     après la réplique. Convention : positif = horaire, donc un angle positif
     LÈVE le bras gauche et RENTRE le droit.
     Valeurs reprises telles quelles de la fiche personnage : ne pas les
     « arrondir », ce sont elles qui donnent le mouvement validé.
     ------------------------------------------------------------------------ */
  const POSES = {
    repos:     { al: 0,   ar: 0,   ll: 0,   lr: 0,  fx: null,    mouth: '' },
    salut:     { al: 0,   ar: 0,   ll: 0,   lr: 0,  fx: 'wave',  mouth: '' },
    presente:  { al: 14,  ar: -78, ll: -6,  lr: 3,  fx: null,    mouth: '' },
    saut:      { al: 0,   ar: 0,   ll: 0,   lr: 0,  fx: 'jump',  mouth: 'ronde' },
    reflechit: { al: -16, ar: -46, ll: 4,   lr: -6, fx: 'think', mouth: 'pincee' },
    bravo:     { al: 78,  ar: -78, ll: -10, lr: 11, fx: null,    mouth: 'grand' },
  }

  /* Moments d'usage -> pose. Table volontairement exposée : deux outils qui
     font saluer la mascotte au même moment, c'est ça la famille. */
  const MOMENTS = {
    accueil: 'salut',
    attente: 'reflechit',
    reponse: 'presente',
    succes: 'bravo',
    clic: 'saut',
    repos: 'repos',
  }

  const FX_DURATION_MS = 1600   // coucou 1,3 s + saut 1,5 s, marge comprise
  const MIN_SIZE = 40           // plancher de la charte, cf. README § 5.3
  const DEFAULT_SIZE = 96
  const RATIO = 148 / 153       // hauteur / largeur du viewBox

  /* Le morphing de bouche passe par la propriété CSS `d`, que tous les
     moteurs ne servent pas encore. Sans elle on retombe sur un étirement
     vertical : moins fin, mais la bouche bouge quand même — une bulle avec
     une bouche immobile a l'air d'appartenir à quelqu'un d'autre. */
  const SUPPORTS_D =
    typeof CSS !== 'undefined' &&
    typeof CSS.supports === 'function' &&
    CSS.supports('d', 'path("M0 0Z")')

  let instanceCount = 0
  let soloWarned = false

  /* --------------------------------------------------------------------------
     Le dessin. Identique au trait près à MascotFigure.jsx et au teaser.
     Les ids de dégradés sont sûrs : le shadow DOM les isole, deux exemplaires
     sur la page ne se marchent pas dessus.
     ------------------------------------------------------------------------ */
  const FIGURE = `
    <svg class="fig" part="figure" viewBox="-16 0 153 148" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
      <defs>
        <radialGradient id="body" cx="40%" cy="26%" r="84%">
          <stop offset="0%" stop-color="#FCE9AF"/>
          <stop offset="42%" stop-color="#F3C86C"/>
          <stop offset="76%" stop-color="#DFA246"/>
          <stop offset="100%" stop-color="#B8762F"/>
        </radialGradient>
        <linearGradient id="shade" x1="0" y1=".38" x2="0" y2="1">
          <stop offset="0%" stop-color="#7A3F10" stop-opacity="0"/>
          <stop offset="100%" stop-color="#7A3F10" stop-opacity=".44"/>
        </linearGradient>
        <linearGradient id="limb" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stop-color="#EFC470"/>
          <stop offset="100%" stop-color="#C6873A"/>
        </linearGradient>
      </defs>

      <!-- jambes : dessinées avant le corps pour passer dessous -->
      <g class="leg-l">
        <path d="M53 99 C 51 108 48 118 46 127" stroke="url(#limb)" stroke-width="11.5" fill="none" stroke-linecap="round"/>
        <ellipse cx="42" cy="133" rx="11.5" ry="6.3" fill="#D9A252" stroke="#A8692B" stroke-width="1.6"/>
      </g>
      <g class="leg-r">
        <path d="M67 99 C 69 108 72 118 74 127" stroke="url(#limb)" stroke-width="11.5" fill="none" stroke-linecap="round"/>
        <ellipse cx="78" cy="133" rx="11.5" ry="6.3" fill="#D9A252" stroke="#A8692B" stroke-width="1.6"/>
      </g>

      <!-- bras : épaule (rotation de pose) puis avant-bras (balancement continu) -->
      <g class="arm-l"><g class="sec-l">
        <path d="M30 76 C 19 84 6 93 -2 99" stroke="url(#limb)" stroke-width="11" fill="none" stroke-linecap="round"/>
        <circle cx="-4" cy="102" r="8.5" fill="#EFC470" stroke="#A8692B" stroke-width="1.6"/>
      </g></g>
      <g class="arm-r"><g class="sec-r">
        <path d="M90 76 C 101 84 114 93 122 99" stroke="url(#limb)" stroke-width="11" fill="none" stroke-linecap="round"/>
        <circle cx="124" cy="102" r="8.5" fill="#EFC470" stroke="#A8692B" stroke-width="1.6"/>
      </g></g>

      <!-- coquille de madeleine : base étroite, éventail cannelé, bord festonné à 5 lobes -->
      <path d="M60 108 C38 106 18 88 14 64 Q4.6 45.9 22.8 37 Q25.7 16.8 45.8 20.3 Q60 5.7 74.2 20.3 Q94.3 16.8 97.2 37 Q115.4 45.9 106 64 C102 88 82 106 60 108 Z" fill="url(#body)"/>
      <g stroke="#A9662A" stroke-width="1.7" fill="none" opacity=".34" stroke-linecap="round">
        <path d="M60 99 Q44 76 25.8 40.3"/>
        <path d="M60 99 Q54 70 47.2 24.1"/>
        <path d="M60 99 Q66 70 72.8 24.1"/>
        <path d="M60 99 Q76 76 94.2 40.3"/>
      </g>
      <g stroke="#FCE7AE" stroke-width="1.5" fill="none" opacity=".42" stroke-linecap="round">
        <path d="M60 99 Q36 82 16 52"/>
        <path d="M60 99 Q46 68 33 27"/>
        <path d="M60 99 L60 18"/>
        <path d="M60 99 Q74 68 87 27"/>
        <path d="M60 99 Q84 82 104 52"/>
      </g>
      <path d="M60 108 C38 106 18 88 14 64 Q4.6 45.9 22.8 37 Q25.7 16.8 45.8 20.3 Q60 5.7 74.2 20.3 Q94.3 16.8 97.2 37 Q115.4 45.9 106 64 C102 88 82 106 60 108 Z" fill="url(#shade)"/>
      <ellipse cx="40" cy="35" rx="15" ry="8.5" fill="#FFF3CE" opacity=".38" transform="rotate(-26 40 35)"/>
      <path d="M60 108 C38 106 18 88 14 64 Q4.6 45.9 22.8 37 Q25.7 16.8 45.8 20.3 Q60 5.7 74.2 20.3 Q94.3 16.8 97.2 37 Q115.4 45.9 106 64 C102 88 82 106 60 108 Z" fill="none" stroke="#8B4E1C" stroke-width="2.1" stroke-linejoin="round" opacity=".82"/>

      <ellipse cx="31" cy="72" rx="7" ry="4.4" fill="#E79A9A" opacity=".5"/>
      <ellipse cx="89" cy="72" rx="7" ry="4.4" fill="#E79A9A" opacity=".5"/>

      <g class="eye eye-l">
        <ellipse cx="45" cy="58" rx="6.4" ry="7.8" fill="#40291A"/>
        <circle cx="47.4" cy="54.6" r="2.3" fill="#fff"/>
        <circle cx="42.8" cy="61.6" r="1.2" fill="#fff" opacity=".45"/>
      </g>
      <g class="eye eye-r">
        <ellipse cx="75" cy="58" rx="6.4" ry="7.8" fill="#40291A"/>
        <circle cx="77.4" cy="54.6" r="2.3" fill="#fff"/>
        <circle cx="72.8" cy="61.6" r="1.2" fill="#fff" opacity=".45"/>
      </g>

      <!-- Tracé fermé et rempli, pas un trait : un trait ne peut pas s'ouvrir.
           Toutes les formes de bouche partagent la même suite de commandes
           (M · Q · Q · Z) — c'est la condition pour qu'elles s'interpolent. -->
      <path class="mouth" d="M51 73 Q60 82 69 73 Q60 76.6 51 73 Z" fill="#40291A"/>
    </svg>
  `

  /* --------------------------------------------------------------------------
     Le rig. Quatre étages de transform, chacun avec le sien : le saut
     translate, l'écrasement scale, la respiration flotte, le survol soulève.
     Empilés sur un seul élément, ils se marcheraient dessus.
     ------------------------------------------------------------------------ */
  const STYLE = `
    :host {
      /* Taille pilotée par l'attribut size ; --gd-mascotte-size permet de la
         piloter en CSS (media queries) sans toucher au HTML. */
      --size: ${DEFAULT_SIZE}px;
      display: inline-block;
      position: relative;
      width: var(--gd-mascotte-size, var(--size));
      height: calc(var(--gd-mascotte-size, var(--size)) * ${RATIO});
      flex-shrink: 0;
      /* Le personnage déborde de sa boîte quand il saute et quand il parle. */
      overflow: visible;
      --spring: cubic-bezier(0.34, 1.42, 0.5, 1);
      --al: 0deg; --ar: 0deg; --ll: 0deg; --lr: 0deg;
    }

    :host([hidden]) { display: none; }

    /* Ombre au sol. Elle vit HORS du vaisseau qui saute : une ombre qui
       décolle avec le personnage, c'est le défaut qui trahit tout de suite
       le bricolage. */
    .ground {
      position: absolute;
      left: 50%;
      bottom: 1px;
      translate: -50% 0;
      width: 58%;
      height: 9px;
      border-radius: 50%;
      background: radial-gradient(circle, rgba(96, 52, 20, 0.3), rgba(96, 52, 20, 0) 70%);
    }

    :host([ground="off"]) .ground { display: none; }

    .rig, .lift, .hop, .squash, .breathe {
      display: block;
      width: 100%;
      height: 100%;
    }

    .lift { transition: transform 200ms var(--spring); }
    :host(:not([no-poke]):hover) .lift { transform: translateY(-3px); }
    :host(:not([no-poke]):active) .lift { transform: scale(0.96); }
    :host(:not([no-poke])) { cursor: pointer; }

    .hop, .squash { transform-origin: 50% 100%; }

    .fig {
      width: 100%;
      height: 100%;
      display: block;
      overflow: visible;
      filter: drop-shadow(0 5px 7px rgba(96, 52, 20, 0.22));
    }

    /* Pivots exprimés dans le repère du viewBox. */
    .arm-l, .arm-r, .leg-l, .leg-r, .sec-l, .sec-r { transform-box: view-box; }
    .arm-l, .sec-l { transform-origin: 30px 76px; }
    .arm-r, .sec-r { transform-origin: 90px 76px; }
    .leg-l { transform-origin: 53px 99px; }
    .leg-r { transform-origin: 67px 99px; }

    .arm-l { transform: rotate(var(--al)); transition: transform 0.5s var(--spring); }
    .arm-r { transform: rotate(var(--ar)); transition: transform 0.5s var(--spring); }
    .leg-l { transform: rotate(var(--ll)); transition: transform 0.5s var(--spring); }
    .leg-r { transform: rotate(var(--lr)); transition: transform 0.5s var(--spring); }

    /* ── la vie permanente ─────────────────────────────────────────────────
       Ces trois-là ne s'arrêtent jamais, et leurs périodes sont
       VOLONTAIREMENT différentes (3,2 / 2,6 / 4,4 s) : elles se déphasent en
       continu, donc la boucle ne se laisse jamais deviner. Avec une seule
       animation, l'œil comprend le cycle en deux allers-retours et le
       personnage redevient un pictogramme. */
    .breathe { animation: breathe 3.2s ease-in-out infinite; }
    @keyframes breathe {
      0%, 100% { transform: translateY(0.35%) rotate(-1.6deg) scale(1, 0.99); }
      50%      { transform: translateY(-2.4%) rotate(1.6deg) scale(0.995, 1.015); }
    }

    .sec-l { animation: sway 2.6s ease-in-out infinite; }
    .sec-r { animation: sway 2.6s ease-in-out infinite -1.1s; }
    @keyframes sway {
      0%, 100% { transform: rotate(-3deg); }
      50%      { transform: rotate(3deg); }
    }

    .eye {
      transform-origin: center;
      transform-box: fill-box;
      animation: blink 4.4s ease-in-out infinite;
    }
    .eye-r { animation-delay: 40ms; }
    @keyframes blink {
      0%, 90%, 100% { transform: scaleY(1); }
      92%, 94%      { transform: scaleY(0.08); }
    }

    /* ── la bouche ─────────────────────────────────────────────────────────
       ⚠️ VITESSE — ce qui compte n'est pas la durée du cycle mais le nombre
       d'OUVERTURES par seconde. Deux ouvertures en 0,52 s ≈ quatre par
       seconde, le rythme d'une diction normale. Et les deux ouvertures
       doivent avoir une amplitude COMPARABLE, sinon la bouche paraît battre
       irrégulièrement (hauteurs notées en commentaire).

       4,6 itérations ≈ 2,4 s : elle s'arrête de parler AVANT que la bulle ne
       disparaisse — l'inverse donne l'impression qu'on lui coupe la parole.
       Le compte d'itérations remplace un timer JS. */
    .mouth { transition: d 0.3s ease, transform 0.3s ease; }
    .rig.talking .mouth { animation: mouthTalk 0.52s ease-in-out 4.6; }

    @keyframes mouthTalk {
      0%   { d: path("M51 73 Q60 80 69 73 Q60 77.4 51 73 Z"); }       /* fermée  3,5 */
      35%  { d: path("M52 71.5 Q60 86 68 71.5 Q60 72.5 52 71.5 Z"); } /* ouverte 7,3 */
      57%  { d: path("M51 73 Q60 80.5 69 73 Q60 77.2 51 73 Z"); }     /* fermée  3,6 */
      80%  { d: path("M54 71 Q60 86 66 71 Q60 69.5 54 71 Z"); }       /* ouverte 8,2 */
      100% { d: path("M51 73 Q60 80 69 73 Q60 77.4 51 73 Z"); }       /* fermée  3,5 */
    }

    /* Bouche tenue après la réplique, selon l'humeur. */
    .rig[data-mouth="grand"]  .mouth { d: path("M48 71 Q60 88 72 71 Q60 76 48 71 Z"); }
    .rig[data-mouth="pincee"] .mouth { d: path("M55 73 Q60 79 65 73 Q60 76 55 73 Z"); }
    .rig[data-mouth="ronde"]  .mouth { d: path("M54 71 Q60 86 66 71 Q60 69 54 71 Z"); }

    /* Repli pour les moteurs sans propriété CSS « d » animable : la bouche
       s'étire depuis son bord haut au lieu de se déformer. */
    :host(.no-d) .mouth { transform-box: fill-box; transform-origin: 50% 0%; }
    :host(.no-d) .rig.talking .mouth { animation: mouthTalkFallback 0.52s ease-in-out 4.6; }
    @keyframes mouthTalkFallback {
      0%, 57%, 100% { transform: scaleY(1); }
      35%           { transform: scaleY(2.1); }
      80%           { transform: scaleY(2.4); }
    }
    :host(.no-d) .rig[data-mouth="grand"]  .mouth { transform: scaleY(2.4); }
    :host(.no-d) .rig[data-mouth="pincee"] .mouth { transform: scaleY(0.7) scaleX(0.6); }
    :host(.no-d) .rig[data-mouth="ronde"]  .mouth { transform: scaleY(2.2) scaleX(0.75); }

    /* ── effets ponctuels ──────────────────────────────────────────────────
       Posés / retirés à la main sur .rig : une animation CSS ne se rejoue que
       si la classe a été retirée avant d'être remise. */
    .fx-wave .arm-r { animation: wave 1.3s var(--spring); }
    @keyframes wave {
      0%   { transform: rotate(0deg); }
      22%  { transform: rotate(-92deg); }
      42%  { transform: rotate(-68deg); }
      60%  { transform: rotate(-94deg); }
      78%  { transform: rotate(-68deg); }
      100% { transform: rotate(0deg); }
    }

    /* Le saut : deux rebonds puis la réception. Montée en ease-out, chute en
       ease-in — la gravité est entièrement dans les courbes.
       Hauteurs en % de la taille du personnage et pas en px : la mascotte est
       affichée de 40 à 300 px selon les écrans, un saut en px la ferait bondir
       trois fois plus haut en petit. */
    .fx-jump .hop { animation: jump 1.5s linear; }
    @keyframes jump {
      0%   { transform: translateY(0);      animation-timing-function: cubic-bezier(0.5, 0, 0.9, 0.5); }
      7%   { transform: translateY(4.1%);   animation-timing-function: cubic-bezier(0.15, 0.7, 0.4, 1); }
      28%  { transform: translateY(-20%);   animation-timing-function: cubic-bezier(0.55, 0, 0.85, 0.45); }
      46%  { transform: translateY(0);      animation-timing-function: cubic-bezier(0.12, 0.72, 0.38, 1); }
      72%  { transform: translateY(-33%);   animation-timing-function: cubic-bezier(0.6, 0, 0.9, 0.4); }
      90%  { transform: translateY(0);      animation-timing-function: cubic-bezier(0.45, 0, 0.55, 1); }
      95%  { transform: translateY(-3.1%); }
      100% { transform: translateY(0); }
    }

    .fx-jump .squash { animation: squash 1.5s linear; }
    @keyframes squash {
      0%, 20% { transform: scale3d(1, 1, 1); }
      5%      { transform: scale3d(1.14, 0.87, 1); }  /* l'armé */
      46%     { transform: scale3d(1.16, 0.86, 1); }  /* contact 1 */
      56%     { transform: scale3d(0.95, 1.06, 1); }
      90%     { transform: scale3d(1.3, 0.72, 1); }   /* réception */
      97%     { transform: scale3d(0.93, 1.09, 1); }
      100%    { transform: scale3d(1, 1, 1); }
    }

    .fx-jump .arm-r { animation: jumpArmR 1.5s ease-in-out; }
    .fx-jump .arm-l { animation: jumpArmL 1.5s ease-in-out; }
    @keyframes jumpArmR {
      0% { transform: rotate(0deg); }   7%  { transform: rotate(52deg); }
      28% { transform: rotate(-62deg); } 46% { transform: rotate(30deg); }
      72% { transform: rotate(-84deg); } 90% { transform: rotate(26deg); }
      100% { transform: rotate(0deg); }
    }
    @keyframes jumpArmL {
      0% { transform: rotate(0deg); }   7%  { transform: rotate(-52deg); }
      28% { transform: rotate(62deg); }  46% { transform: rotate(-30deg); }
      72% { transform: rotate(84deg); }  90% { transform: rotate(-26deg); }
      100% { transform: rotate(0deg); }
    }

    .fx-jump .leg-l { animation: jumpLegL 1.5s ease-in-out; }
    .fx-jump .leg-r { animation: jumpLegR 1.5s ease-in-out; }
    @keyframes jumpLegL {
      0% { transform: rotate(14deg); }  7%  { transform: rotate(-18deg); }
      28% { transform: rotate(24deg); }  46% { transform: rotate(-14deg); }
      72% { transform: rotate(26deg); }  90% { transform: rotate(-16deg); }
      100% { transform: rotate(0deg); }
    }
    @keyframes jumpLegR {
      0% { transform: rotate(-12deg); } 7%  { transform: rotate(20deg); }
      28% { transform: rotate(-21deg); } 46% { transform: rotate(17deg); }
      72% { transform: rotate(-23deg); } 90% { transform: rotate(15deg); }
      100% { transform: rotate(0deg); }
    }

    /* L'ombre suit le saut en négatif : petite et pâle en l'air, large au sol. */
    :host(.jumping) .ground { animation: groundJump 1.5s linear; }
    @keyframes groundJump {
      0%, 46%, 90%, 100% { opacity: 1;    transform: scale(1); }
      28%                { opacity: 0.28; transform: scale(0.6); }
      72%                { opacity: 0.18; transform: scale(0.48); }
    }

    /* « Je mijote ». Trois mouvements de périodes différentes (2,2 / 1,5 /
       3,3 s), pour la même raison que la vie permanente : déphasage continu.
       Les membres animés partent de leur angle de pose (var(--ar), var(--ll)…)
       au lieu d'une valeur en dur, sinon l'animation écraserait la pose et le
       bras reviendrait le long du corps. */
    .fx-think .fig { animation: thinkTilt 2.2s ease-in-out infinite; }
    @keyframes thinkTilt {
      0%, 100% { rotate: -5.5deg; }
      50%      { rotate: 5.5deg; }
    }

    .fx-think .arm-r { animation: thinkTap 1.5s ease-in-out infinite; }
    @keyframes thinkTap {
      0%, 100% { transform: rotate(var(--ar)); }
      50%      { transform: rotate(calc(var(--ar) - 10deg)); }
    }

    .fx-think .leg-l { animation: thinkWeightL 3.3s ease-in-out infinite; }
    .fx-think .leg-r { animation: thinkWeightR 3.3s ease-in-out infinite; }
    @keyframes thinkWeightL {
      0%, 100% { transform: rotate(var(--ll)); }
      50%      { transform: rotate(calc(var(--ll) + 4deg)); }
    }
    @keyframes thinkWeightR {
      0%, 100% { transform: rotate(var(--lr)); }
      50%      { transform: rotate(calc(var(--lr) + 4deg)); }
    }

    /* ── la bulle ──────────────────────────────────────────────────────────
       Positionnée en absolute : sa taille variable ne doit JAMAIS déplacer le
       personnage. Elle porte du statut et de la chaleur, jamais une donnée
       (cf. README § 5.3) — say() prévient en console si un montant s'y
       glisse. */
    .bubble {
      position: absolute;
      bottom: calc(100% + 8px);
      left: 50%;
      transform: translate(-50%, 6px) scale(0.85);
      transform-origin: bottom center;
      width: max-content;
      max-width: 210px;
      padding: 8px 12px;
      border-radius: 16px;
      background: var(--gd-paper, #fff);
      border: 1px solid var(--gd-border, #e4dbce);
      color: var(--gd-ink, #383634);
      font-family: var(--font-sans, system-ui, sans-serif);
      font-size: var(--text-sm, 15px);
      font-weight: 500;
      line-height: 1.25;
      text-align: center;
      box-shadow: var(--gd-shadow, 0 2px 12px rgba(68, 42, 30, 0.08));
      opacity: 0;
      pointer-events: none;
      transition:
        opacity var(--duration-enter, 240ms) var(--ease-out-soft, ease),
        transform 320ms var(--ease-spring, var(--spring));
    }

    .bubble::after {
      content: '';
      position: absolute;
      bottom: -6px;
      left: 50%;
      margin-left: -5px;
      width: 10px;
      height: 10px;
      background: inherit;
      border-right: 1px solid var(--gd-border, #e4dbce);
      border-bottom: 1px solid var(--gd-border, #e4dbce);
      transform: rotate(45deg);
      border-bottom-right-radius: 3px;
    }

    .bubble.on { opacity: 1; transform: translate(-50%, 0) scale(1); }

    /* Humeurs : le motif « surface blanc teinté + filet gourmand » de la
       charte (§ 3.2), transposé sur la bulle. */
    .bubble.mood-welcome  { background: var(--gd-paper-warm, #fffdf6); border-color: var(--gd-butter, #F8D77A); }
    .bubble.mood-welcome::after { border-color: var(--gd-butter, #F8D77A); }
    .bubble.mood-thinking { border-color: var(--gd-red-soft, #f2dadb); color: var(--gd-red-deep, #a42a2e); }
    .bubble.mood-thinking::after { border-color: var(--gd-red-soft, #f2dadb); }
    .bubble.mood-post     { border-color: var(--gd-mint, #B8DFD0); }
    .bubble.mood-post::after { border-color: var(--gd-mint, #B8DFD0); }

    :host([bubble-align="left"])  .bubble { left: 0; transform: translate(0, 6px) scale(0.85); transform-origin: bottom left; }
    :host([bubble-align="left"])  .bubble.on { transform: translate(0, 0) scale(1); }
    :host([bubble-align="left"])  .bubble::after { left: 16px; margin-left: 0; }
    :host([bubble-align="right"]) .bubble { left: auto; right: 0; transform: translate(0, 6px) scale(0.85); transform-origin: bottom right; }
    :host([bubble-align="right"]) .bubble.on { transform: translate(0, 0) scale(1); }
    :host([bubble-align="right"]) .bubble::after { left: auto; right: 16px; margin-left: 0; }

    /* Non négociable, aucune exception : toutes les animations s'éteignent.
       Les angles de pose restent, eux : c'est de la posture, pas du mouvement,
       et la charte interdit qu'une information ne soit portée QUE par le
       mouvement.

       Deux déclencheurs et pas un seul : la préférence système, et l'attribut
       reduced. Un outil qui propose son propre réglage « réduire les
       animations » dans ses préférences doit pouvoir l'appliquer sans que
       l'utilisatrice ait à toucher aux réglages de son téléphone. */
    @media (prefers-reduced-motion: reduce) {
      :host *, :host *::before, :host *::after {
        animation: none !important;
        transition-duration: 0.001ms !important;
      }
    }

    :host([reduced]) *,
    :host([reduced]) *::before,
    :host([reduced]) *::after {
      animation: none !important;
      transition-duration: 0.001ms !important;
    }
  `

  class GdMascotte extends HTMLElement {
    static get observedAttributes() {
      return ['pose', 'size', 'bubble', 'mood', 'label']
    }

    static get POSES() { return Object.keys(POSES) }
    static get MOMENTS() { return { ...MOMENTS } }

    constructor() {
      super()
      const root = this.attachShadow({ mode: 'open' })
      root.innerHTML = `
        <style>${STYLE}</style>
        <span class="ground" part="ground"></span>
        <span class="rig">
          <span class="lift"><span class="hop"><span class="squash"><span class="breathe">
            ${FIGURE}
          </span></span></span></span>
        </span>
        <span class="bubble" part="bubble"></span>
      `
      this._rig = root.querySelector('.rig')
      this._bubble = root.querySelector('.bubble')
      this._fxTimer = null
      this._sayTimer = null
      this._onClick = () => { if (!this.hasAttribute('no-poke')) this.poke() }
    }

    connectedCallback() {
      /* La mascotte est décorative par défaut : ce qu'elle dit est du statut
         et de la chaleur, jamais une information qui manquerait ailleurs.
         L'attribut label permet de l'exposer si un outil en fait autre chose. */
      if (!this.hasAttribute('label') && !this.hasAttribute('aria-hidden')) {
        this.setAttribute('aria-hidden', 'true')
      }
      /* La classe est posée ici et pas dans le constructeur : la spec des
         custom elements interdit à un élément de gagner un attribut avant
         d'être connecté. */
      if (!SUPPORTS_D) this.classList.add('no-d')
      this._applySize()
      this._applyPose()
      this._applyBubble()
      this.addEventListener('click', this._onClick)

      instanceCount += 1
      if (instanceCount > 1 && !soloWarned && !window.GD_MASCOTTE_ALLOW_DUPLICATES) {
        soloWarned = true
        console.warn(
          '[gd-mascotte] Deux exemplaires à l\'écran en même temps. La charte n\'en autorise ' +
          'qu\'un seul (README § 5.3) : deux personnages qui parlent en parallèle cassent ' +
          'l\'illusion. Sur une planche de référence, poser window.GD_MASCOTTE_ALLOW_DUPLICATES = true.'
        )
      }
    }

    disconnectedCallback() {
      instanceCount = Math.max(0, instanceCount - 1)
      this.removeEventListener('click', this._onClick)
      clearTimeout(this._fxTimer)
      clearTimeout(this._sayTimer)
    }

    attributeChangedCallback(name) {
      if (!this._rig) return
      if (name === 'size') this._applySize()
      else if (name === 'pose') this._applyPose()
      else if (name === 'bubble' || name === 'mood') this._applyBubble()
      else if (name === 'label') {
        if (this.hasAttribute('label')) {
          this.removeAttribute('aria-hidden')
          this.setAttribute('role', 'img')
          this.setAttribute('aria-label', this.getAttribute('label'))
        }
      }
    }

    /* ---- propriétés ------------------------------------------------------ */

    get pose() { return this.getAttribute('pose') || 'repos' }
    set pose(v) { this.setAttribute('pose', v) }

    get size() { return Number(this.getAttribute('size')) || DEFAULT_SIZE }
    set size(v) { this.setAttribute('size', String(v)) }

    /* ---- API ------------------------------------------------------------- */

    /** Joue la pose correspondant à un moment d'usage (accueil, attente,
     *  reponse, succes, clic, repos). Passer par les moments plutôt que par
     *  les poses garde le même geste au même moment d'un outil à l'autre. */
    moment(name) {
      const pose = MOMENTS[name]
      if (!pose) {
        console.warn(`[gd-mascotte] Moment inconnu : "${name}". Connus : ${Object.keys(MOMENTS).join(', ')}.`)
        return
      }
      this.play(pose)
    }

    /** Rejoue une pose même si c'est déjà la pose courante. */
    play(pose) {
      if (this.pose === pose) this._applyPose()
      else this.pose = pose
    }

    /** Fait parler la mascotte. mood ∈ welcome | thinking | post | (aucun).
     *  La durée est calculée sur la longueur du texte si elle n'est pas donnée. */
    say(text, options = {}) {
      const { mood = '', duration } = options
      if (!text) return this.hush()

      /* Garde-fou de charte, pas de sécurité : la bulle ne porte jamais de
         montant ni de pourcentage. Un chiffre affiché par la mascotte a l'air
         d'un fait vérifié alors qu'il n'a traversé aucun contrôle. */
      if (/[€%]|\d+[\s.,]?\d*\s?(€|euros?|%)/i.test(text)) {
        console.warn(
          '[gd-mascotte] La bulle contient un montant ou un pourcentage : ' +
          `"${text}". La charte l'interdit (README § 5.3) — la donnée chiffrée ` +
          'appartient au fil principal, pas à la mascotte.'
        )
      }

      this.setAttribute('bubble', text)
      if (mood) this.setAttribute('mood', mood)
      else this.removeAttribute('mood')

      /* La bouche se rejoue à CHAQUE réplique, alors que le balancement de
         « je mijote » doit tourner sans discontinuer pendant toute la
         recherche : deux mécanismes distincts et pas un seul, sinon chaque
         changement de phrase remet la boucle à zéro et le personnage
         sursaute toutes les trois secondes. */
      this._rig.classList.remove('talking')
      void this._rig.offsetWidth
      this._rig.classList.add('talking')

      clearTimeout(this._sayTimer)
      const ms = duration != null ? duration : Math.max(2600, text.length * 55)
      if (ms > 0 && Number.isFinite(ms)) {
        this._sayTimer = setTimeout(() => this.hush(), ms)
      }
    }

    hush() {
      clearTimeout(this._sayTimer)
      this.removeAttribute('bubble')
      this._rig.classList.remove('talking')
    }

    /** Le saut ponctuel. Rend la main à la pose courante une fois retombée. */
    poke() {
      this._rig.classList.remove('fx-jump')
      this.classList.remove('jumping')
      void this._rig.offsetWidth
      this._rig.classList.add('fx-jump')
      this.classList.add('jumping')
      this._rig.dataset.mouth = 'ronde'
      clearTimeout(this._fxTimer)
      this._fxTimer = setTimeout(() => {
        this._rig.classList.remove('fx-jump')
        this.classList.remove('jumping')
        this._applyPose()
      }, FX_DURATION_MS)
    }

    /* ---- interne --------------------------------------------------------- */

    _applySize() {
      let size = this.size
      if (!(size > 0)) size = DEFAULT_SIZE
      if (size < MIN_SIZE) {
        /* Une fois par élément : attributeChangedCallback et connectedCallback
           passent tous les deux ici au premier rendu. */
        if (!this._sizeWarned) console.warn(
          `[gd-mascotte] Taille demandée ${size}px, remontée à ${MIN_SIZE}px. ` +
          'Sous 40 px les jambes se dissolvent ; les déclinaisons de repli ' +
          '(bras rangés, coquille seule) ne sont pas encore dessinées.'
        )
        this._sizeWarned = true
        size = MIN_SIZE
      }
      this.style.setProperty('--size', `${size}px`)
    }

    _applyPose() {
      const name = this.pose
      const p = POSES[name]
      if (!p) {
        console.warn(`[gd-mascotte] Pose inconnue : "${name}". Connues : ${Object.keys(POSES).join(', ')}.`)
        return this._setPose(POSES.repos)
      }
      this._setPose(p)
    }

    _setPose(p) {
      const rig = this._rig
      rig.style.setProperty('--al', `${p.al}deg`)
      rig.style.setProperty('--ar', `${p.ar}deg`)
      rig.style.setProperty('--ll', `${p.ll}deg`)
      rig.style.setProperty('--lr', `${p.lr}deg`)
      if (p.mouth) rig.dataset.mouth = p.mouth
      else delete rig.dataset.mouth

      /* Une animation CSS ne se rejoue que si la classe a été retirée avant
         d'être remise — d'où le retrait, le reflow forcé, puis la pose. */
      rig.classList.remove('fx-wave', 'fx-jump', 'fx-think')
      this.classList.remove('jumping')
      clearTimeout(this._fxTimer)
      void rig.offsetWidth
      if (!p.fx) return

      rig.classList.add(`fx-${p.fx}`)
      if (p.fx === 'jump') this.classList.add('jumping')
      /* « think » boucle tant qu'on ne change pas de pose ; les autres se
         rendent d'eux-mêmes pour pouvoir être rejoués. */
      if (p.fx === 'think') return
      this._fxTimer = setTimeout(() => {
        rig.classList.remove(`fx-${p.fx}`)
        this.classList.remove('jumping')
      }, FX_DURATION_MS)
    }

    _applyBubble() {
      const text = this.getAttribute('bubble')
      const mood = this.getAttribute('mood')
      this._bubble.className = 'bubble' + (mood ? ` mood-${mood}` : '')
      if (text) {
        this._bubble.textContent = text
        /* Rendu puis affiché : sans le reflow, la transition d'entrée est
           avalée quand le texte et la classe arrivent dans la même frame. */
        void this._bubble.offsetWidth
        this._bubble.classList.add('on')
      } else {
        this._bubble.classList.remove('on')
      }
    }
  }

  customElements.define('gd-mascotte', GdMascotte)
  window.GdMascotte = GdMascotte
})()
