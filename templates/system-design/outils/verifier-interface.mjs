#!/usr/bin/env node
/* ============================================================================
   verifier-interface.mjs — contrôle automatique du design system Guy Demarle
   ----------------------------------------------------------------------------
   Node seul, aucune dépendance, aucun build.

       node system-design/outils/verifier-interface.mjs frontend/src
       node system-design/outils/verifier-interface.mjs . --strict
       node system-design/outils/verifier-interface.mjs frontend/src --tout
       node system-design/outils/verifier-interface.mjs frontend/src --profil interne

   Ce que ça contrôle : les règles de `AGENTS.md` § 2 marquées 🤖 — celles qui se
   lisent dans le code. Le reste de la checklist (un seul bouton rouge par zone,
   lockup complet, test en une seconde) demande un œil sur l'écran réel.

   Deux profils : « conseillers » (par défaut, `system-design/AGENTS.md`) et
   « interne » (`system-design/interne/AGENTS.md`). Le profil vient de
   `--profil`, sinon de la ligne « Profil d'interface : … » du CLAUDE.md ou de
   l'AGENTS.md du dossier courant, sinon il vaut « conseillers ».

   Deux étages : les règles de LIGNE (une couleur en dur, un angle vif…) et les
   contrôles D'ENSEMBLE, qui portent sur le projet entier — aujourd'hui
   l'ambiance de page, qu'aucune ligne prise séparément ne trahit.

   Un outil de repérage, pas un juge : il montre où regarder. Une ligne
   légitimement hors règle se neutralise en ajoutant `gd-ok:` suivi de la
   raison, en commentaire sur la même ligne.

   Options
     --profil <conseillers|interne>   force le profil d'interface
     --strict   les avertissements font échouer aussi (code de sortie 1)
     --tout     affiche toutes les occurrences (par défaut : 12 par règle)
     --json     sortie machine, pour une CI

   Code de sortie : 1 s'il reste des erreurs, 0 sinon.
   ========================================================================== */

import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join, relative, sep } from 'node:path'

/* -------------------------------------------------------------------------- */
/* Profil d'interface                                                          */
/* -------------------------------------------------------------------------- */

const PROFILS = {
  conseillers: { doc: 'AGENTS.md', plancher: 14 },
  interne: { doc: 'interne/AGENTS.md', plancher: 12 },
}

const args = process.argv.slice(2)

function lireProfil() {
  const i = args.findIndex((a) => a === '--profil' || a.startsWith('--profil='))
  if (i >= 0) {
    const valeur = args[i].includes('=') ? args[i].split('=')[1] : args[i + 1]
    if (!PROFILS[valeur]) {
      console.error(`Profil inconnu : « ${valeur ?? ''} ». Valeurs possibles : ${Object.keys(PROFILS).join(', ')}.`)
      process.exit(2)
    }
    return { nom: valeur, source: '--profil' }
  }
  for (const fichier of ['CLAUDE.md', 'AGENTS.md']) {
    let texte
    try { texte = readFileSync(join(process.cwd(), fichier), 'utf8') } catch { continue }
    const m = /Profil d'interface\s*:\s*\**\s*(conseillers|interne)\b/i.exec(texte)
    if (m) return { nom: m[1].toLowerCase(), source: fichier }
  }
  return { nom: 'conseillers', source: 'par défaut' }
}

const PROFIL = lireProfil()
const P = PROFILS[PROFIL.nom]

/* -------------------------------------------------------------------------- */
/* Périmètre                                                                   */
/* -------------------------------------------------------------------------- */

const EXTENSIONS = ['.css', '.scss', '.less', '.html', '.jsx', '.tsx', '.js', '.ts', '.vue', '.svelte']

const DOSSIERS_IGNORES = new Set([
  'node_modules', '.git', 'dist', 'build', 'coverage', '.next', '.nuxt',
  'storybook-static', '__pycache__', 'venv', '.venv', 'vendor', '.cache',
])

/* Le kit porte les valeurs brutes : c'est sa raison d'être. */
const CHEMINS_EXCLUS = [
  'system-design' + sep + 'kit', 'gd-ai-tokens', 'gd-ai-components', 'gd-ai-mascotte',
  'system-design' + sep + 'interne' + sep + 'kit', 'gd-interne-tokens', 'gd-interne-components',
]

const EST_CODE_JS = (f) => /\.(jsx?|tsx?|vue|svelte)$/.test(f)

/* Une ligne de code JS n'est suspecte que si elle parle vraiment de style. */
const MOTS_STYLE = /style|color|background|fill|stroke|shadow|border|radius|fontsize|font-size|palette|theme|gradient/i

/* -------------------------------------------------------------------------- */
/* Règles                                                                      */
/* -------------------------------------------------------------------------- */

const COULEUR_TOLEREE = /^(transparent|currentcolor|inherit|initial|unset|none)$/i

/* Chaque règle cite la section de l'AGENTS.md du profil qui la porte : `ref`
   donne le numéro par profil, une règle absente d'un profil n'y est pas
   appliquée. `toujours` : la règle juge aussi les lignes JS qui ne parlent
   pas de style (un import de feuille, une balise). */
const REGLES = [
  {
    id: 'blanc-pur',
    gravite: 'erreur',
    titre: 'Fond blanc pur — le fond de page est `--gd-cream`',
    ref: { conseillers: '§ 2.1', interne: '§ 2.1' },
    test: (l) => /background(-color)?\s*:\s*(#fff(f{3})?\b|white\b|rgb\(\s*255\s*,\s*255\s*,\s*255)/i.test(l),
  },
  {
    id: 'couleur-en-dur',
    gravite: 'erreur',
    titre: 'Couleur écrite en dur — uniquement `var(--gd-*)`',
    ref: { conseillers: '§ 0 et § 6', interne: '§ 2.8' },
    test: (l) => {
      if (/var\(--/.test(l) && !/#[0-9a-f]{3,8}\b/i.test(l)) return false
      const brut = /#[0-9a-f]{3,8}\b|rgba?\(\s*\d|hsla?\(\s*\d/i.exec(l)
      if (!brut) return false
      if (COULEUR_TOLEREE.test(brut[0])) return false
      return true
    },
  },
  {
    id: 'ombre-noire',
    gravite: 'erreur',
    titre: 'Ombre noire ou grise — les ombres ont une base brune, `var(--gd-shadow*)`',
    ref: { conseillers: '§ 2.7', interne: '§ 2.7' },
    test: (l) => /(box-shadow|text-shadow|drop-shadow)[^;]*(rgba?\(\s*0\s*,\s*0\s*,\s*0|black|#000\b|#000000\b)/i.test(l),
  },
  {
    id: 'angle-vif',
    gravite: 'erreur',
    titre: 'Angle vif — rien n\'a de rayon nul',
    ref: { conseillers: '§ 2.6', interne: '§ 2.6' },
    test: (l) => /border-radius\s*:\s*0(px|rem|em|%)?\s*(!important)?\s*[;}]/i.test(l),
  },
  {
    id: 'texte-trop-petit',
    gravite: 'erreur',
    titre: `Texte sous le plancher de ${P.plancher} px`,
    ref: { conseillers: '§ 2.4', interne: '§ 2.4' },
    test: (l) => {
      const m = /font-size\s*:\s*([\d.]+)\s*(px|rem)/i.exec(l)
      if (!m) return false
      const val = parseFloat(m[1])
      return m[2].toLowerCase() === 'px' ? val < P.plancher : val < P.plancher / 16
    },
  },
  {
    id: 'taille-en-dur',
    gravite: 'avertissement',
    titre: 'Taille de texte en dur — passer par l\'échelle `var(--text-*)`',
    test: (l) => /font-size\s*:\s*[\d.]+\s*(px|rem)/i.test(l) && !/var\(--/.test(l),
  },
  {
    id: 'police-hors-charte',
    gravite: 'erreur',
    titre: 'Autre police que Poppins — une seule famille, `var(--font-sans)`',
    ref: { conseillers: '§ 2.8', interne: '§ 2.5' },
    test: (l) => /font-family\s*:/i.test(l) && !/var\(--font/i.test(l) && !/inherit|monospace|var\(--gd/i.test(l),
  },
  {
    id: 'focus-supprime',
    gravite: 'erreur',
    titre: 'Focus supprimé — jamais sans remplacement visible',
    ref: { conseillers: '§ 2.10', interne: '§ 2.13' },
    test: (l) => /outline\s*:\s*(none|0)\b/i.test(l),
    contexte: (src) => !/:focus-visible/.test(src), // toléré si le fichier redonne un focus visible
  },
  {
    id: 'duree-en-dur',
    gravite: 'avertissement',
    titre: 'Durée d\'animation en dur — passer par `var(--duration-*)`',
    test: (l) => /(transition|animation)(-duration)?\s*:[^;]*\b[\d.]+m?s\b/i.test(l) && !/var\(--/.test(l),
  },
  {
    id: 'important-mouvement',
    gravite: 'avertissement',
    titre: '`!important` sur du mouvement — ne pas contourner `prefers-reduced-motion`',
    ref: { conseillers: '§ 2.12', interne: '§ 2.16' },
    test: (l) => /(transition|animation)[^;]*!important/i.test(l),
  },
  {
    /* Les deux kits définissent les mêmes jetons et les mêmes classes avec des
       valeurs différentes : chargés ensemble, le dernier écrase l'autre. */
    id: 'kit-interne-charge',
    gravite: 'erreur',
    titre: 'Fichier du profil interne dans une app Conseillers — un seul kit par app',
    ref: { conseillers: '§ 0' },
    toujours: true,
    test: (l) => /gd-interne-(tokens|components)/i.test(l),
  },
  {
    id: 'signes-conseillers',
    gravite: 'erreur',
    titre: 'Mascotte, ambiance ou kit Conseillers dans un outil interne',
    ref: { interne: '§ 2.9' },
    toujours: true,
    test: (l) => /<gd-mascotte\b|\bgd-ambient\b|gd-ai-(tokens|components|ambiance|mascotte)/i.test(l),
  },
].filter((r) => !r.ref || r.ref[PROFIL.nom])
 .map((r) => ({ ...r, titre: r.ref ? `${r.titre} (${P.doc} ${r.ref[PROFIL.nom]})` : r.titre }))

/* -------------------------------------------------------------------------- */
/* Contrôles d'ensemble                                                        */
/* -------------------------------------------------------------------------- */

/* Certaines règles ne se lisent pas sur une ligne mais sur le projet entier.
   Une page peut être irréprochable ligne à ligne — bons jetons, bons composants,
   zéro valeur en dur — et rendre un crème nu, c'est-à-dire une page beige
   anonyme qui échoue au test en une seconde. C'est le cas que ce contrôle
   attrape, et c'est le plus fréquent quand une IA produit l'interface.

   Échappatoire, pour un outil qui a une vraie raison de s'en passer : écrire
   `gd-ok: ambiance` suivi du motif, en commentaire, n'importe où dans le front.

   Profil Conseillers uniquement : un outil interne n'a pas d'ambiance. */
const CONTROLES_ENSEMBLE = [
  {
    id: 'ambiance-absente',
    profils: ['conseillers'],
    gravite: 'erreur',
    titre: 'Ambiance de page absente — la page principale porte `.gd-ambient` (AGENTS.md § 2.14)',
    message: 'Aucune trace de `gd-ambient` dans le front : le fond est un crème nu. '
           + 'Charger `kit/gd-ai-ambiance.css`, poser `class="gd-ambient"` sur la coquille '
           + 'plein écran et y ajouter `.gd-ambient__layer`. Voir README § 8.',
    test: (sources) => !sources.some((src) => /gd-ambient\b/.test(src)),
    neutralise: (sources) => sources.some((src) => /gd-ok\s*:\s*ambiance/i.test(src)),
  },
]

function controlerEnsemble(sources, cible) {
  if (!sources.length) return []
  return CONTROLES_ENSEMBLE
    .filter((c) => c.profils.includes(PROFIL.nom))
    .filter((c) => !c.neutralise(sources) && c.test(sources))
    .map((c) => ({
      regle: c.id,
      gravite: c.gravite,
      titre: c.titre,
      fichier: cible,
      ligne: 0,
      ensemble: true,
      extrait: c.message,
    }))
}

/* -------------------------------------------------------------------------- */
/* Parcours                                                                    */
/* -------------------------------------------------------------------------- */

function fichiers(racine) {
  const out = []
  const pile = [racine]
  while (pile.length) {
    const courant = pile.pop()
    let infos
    try { infos = statSync(courant) } catch { continue }
    if (infos.isDirectory()) {
      for (const nom of readdirSync(courant)) {
        if (DOSSIERS_IGNORES.has(nom) || nom.startsWith('.')) continue
        pile.push(join(courant, nom))
      }
    } else if (EXTENSIONS.some((e) => courant.endsWith(e))) {
      if (!CHEMINS_EXCLUS.some((x) => courant.includes(x))) out.push(courant)
    }
  }
  return out.sort()
}

function analyser(chemin) {
  let src
  try { src = readFileSync(chemin, 'utf8') } catch { return [] }
  const lignes = src.split(/\r?\n/)
  const js = EST_CODE_JS(chemin)
  const trouvailles = []

  lignes.forEach((ligne, i) => {
    const nue = ligne.trim()
    if (!nue) return
    if (nue.startsWith('*') || nue.startsWith('//') || nue.startsWith('/*') || nue.startsWith('<!--')) return
    if (/gd-ok\s*:/i.test(ligne)) return                       // neutralisation explicite
    const style = !js || MOTS_STYLE.test(ligne)                // en JS, on ne juge que le style…

    for (const regle of REGLES) {
      if (!style && !regle.toujours) continue                  // … sauf règle qui vise aussi les imports
      if (!regle.test(ligne)) continue
      if (regle.contexte && !regle.contexte(src)) continue
      trouvailles.push({
        regle: regle.id,
        gravite: regle.gravite,
        titre: regle.titre,
        fichier: chemin,
        ligne: i + 1,
        extrait: nue.length > 110 ? nue.slice(0, 107) + '…' : nue,
      })
    }
  })
  return trouvailles
}

/* -------------------------------------------------------------------------- */
/* Sortie                                                                      */
/* -------------------------------------------------------------------------- */

const strict = args.includes('--strict')
const tout = args.includes('--tout')
const json = args.includes('--json')
const cibles = args.filter((a, i) => !a.startsWith('--') && args[i - 1] !== '--profil')
if (!cibles.length) cibles.push(process.cwd())

const trouvailles = cibles.flatMap((c) => {
  const liste = fichiers(c)
  const lues = liste.map((f) => { try { return readFileSync(f, 'utf8') } catch { return '' } })
  return [...liste.flatMap(analyser), ...controlerEnsemble(lues, c)]
})
const erreurs = trouvailles.filter((t) => t.gravite === 'erreur')
const avertis = trouvailles.filter((t) => t.gravite === 'avertissement')

if (json) {
  console.log(JSON.stringify({ profil: PROFIL.nom, erreurs: erreurs.length, avertissements: avertis.length, trouvailles }, null, 2))
  process.exit(erreurs.length || (strict && avertis.length) ? 1 : 0)
}

const PLAFOND = tout ? Infinity : 12
const racine = process.cwd()
const court = (f) => {
  const r = relative(racine, f)
  return !r || r.startsWith('..') ? f : r        // hors du dossier courant : chemin complet
}

console.log('\n  Design system Guy Demarle — contrôle de l\'interface')
console.log('  ' + '─'.repeat(66))
console.log(`  Profil    : ${PROFIL.nom} (${PROFIL.source}) — règles : system-design/${P.doc}`)
console.log(`  Périmètre : ${cibles.join(', ')}`)

for (const gravite of ['erreur', 'avertissement']) {
  const lot = trouvailles.filter((t) => t.gravite === gravite)
  if (!lot.length) continue
  const parRegle = new Map()
  for (const t of lot) {
    if (!parRegle.has(t.regle)) parRegle.set(t.regle, [])
    parRegle.get(t.regle).push(t)
  }
  console.log(`\n  ${gravite === 'erreur' ? '✖ ERREURS' : '▲ AVERTISSEMENTS'} (${lot.length})`)
  for (const [, items] of parRegle) {
    console.log(`\n  ${items[0].titre}`)
    for (const t of items.slice(0, PLAFOND)) {
      if (t.ensemble) {
        console.log(`    ${court(t.fichier)} — sur l'ensemble du périmètre`)
        console.log(`      ${t.extrait}`)
        continue
      }
      console.log(`    ${court(t.fichier)}:${t.ligne}`)
      console.log(`      ${t.extrait}`)
    }
    if (items.length > PLAFOND) console.log(`    … et ${items.length - PLAFOND} autres (--tout pour les voir)`)
  }
}

console.log('\n  ' + '─'.repeat(66))
if (!trouvailles.length) {
  console.log(`  Rien à signaler. Reste la partie qui se voit à l'écran : ${P.doc} § 7.\n`)
} else {
  console.log(`  ${erreurs.length} erreur(s), ${avertis.length} avertissement(s).`)
  console.log('  Une ligne légitimement hors règle se neutralise avec un commentaire `gd-ok: raison`.')
  console.log(`  Le reste de la checklist se vérifie à l'écran : ${P.doc} § 7.\n`)
}

process.exit(erreurs.length || (strict && avertis.length) ? 1 : 0)
