#!/usr/bin/env node
/* ============================================================================
   verifier-interface.mjs — contrôle automatique du design system Guy Demarle
   ----------------------------------------------------------------------------
   Node seul, aucune dépendance, aucun build.

       node system-design/outils/verifier-interface.mjs frontend/src
       node system-design/outils/verifier-interface.mjs . --strict
       node system-design/outils/verifier-interface.mjs frontend/src --tout

   Ce que ça contrôle : les règles de `AGENTS.md` § 2 marquées 🤖 — celles qui se
   lisent dans le code. Le reste de la checklist (un seul bouton rouge par zone,
   lockup complet, test en une seconde) demande un œil sur l'écran réel.

   Un outil de repérage, pas un juge : il montre où regarder. Une ligne
   légitimement hors règle se neutralise en ajoutant `gd-ok:` suivi de la
   raison, en commentaire sur la même ligne.

   Options
     --strict   les avertissements font échouer aussi (code de sortie 1)
     --tout     affiche toutes les occurrences (par défaut : 12 par règle)
     --json     sortie machine, pour une CI

   Code de sortie : 1 s'il reste des erreurs, 0 sinon.
   ========================================================================== */

import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join, relative, sep } from 'node:path'

/* -------------------------------------------------------------------------- */
/* Périmètre                                                                   */
/* -------------------------------------------------------------------------- */

const EXTENSIONS = ['.css', '.scss', '.less', '.html', '.jsx', '.tsx', '.js', '.ts', '.vue', '.svelte']

const DOSSIERS_IGNORES = new Set([
  'node_modules', '.git', 'dist', 'build', 'coverage', '.next', '.nuxt',
  'storybook-static', '__pycache__', 'venv', '.venv', 'vendor', '.cache',
])

/* Le kit porte les valeurs brutes : c'est sa raison d'être. */
const CHEMINS_EXCLUS = ['system-design' + sep + 'kit', 'gd-ai-tokens', 'gd-ai-components', 'gd-ai-mascotte']

const EST_CODE_JS = (f) => /\.(jsx?|tsx?|vue|svelte)$/.test(f)

/* Une ligne de code JS n'est suspecte que si elle parle vraiment de style. */
const MOTS_STYLE = /style|color|background|fill|stroke|shadow|border|radius|fontsize|font-size|palette|theme|gradient/i

/* -------------------------------------------------------------------------- */
/* Règles                                                                      */
/* -------------------------------------------------------------------------- */

const COULEUR_TOLEREE = /^(transparent|currentcolor|inherit|initial|unset|none)$/i

const REGLES = [
  {
    id: 'blanc-pur',
    gravite: 'erreur',
    titre: 'Fond blanc pur — le fond de page est `--gd-cream` (AGENTS.md § 2.1)',
    test: (l) => /background(-color)?\s*:\s*(#fff(f{3})?\b|white\b|rgb\(\s*255\s*,\s*255\s*,\s*255)/i.test(l),
  },
  {
    id: 'couleur-en-dur',
    gravite: 'erreur',
    titre: 'Couleur écrite en dur — uniquement `var(--gd-*)` (AGENTS.md § 0 et § 6)',
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
    titre: 'Ombre noire ou grise — les ombres ont une base brune, `var(--gd-shadow*)` (AGENTS.md § 2.7)',
    test: (l) => /(box-shadow|text-shadow|drop-shadow)[^;]*(rgba?\(\s*0\s*,\s*0\s*,\s*0|black|#000\b|#000000\b)/i.test(l),
  },
  {
    id: 'angle-vif',
    gravite: 'erreur',
    titre: 'Angle vif — rien n\'a de rayon nul (AGENTS.md § 2.6)',
    test: (l) => /border-radius\s*:\s*0(px|rem|em|%)?\s*(!important)?\s*[;}]/i.test(l),
  },
  {
    id: 'texte-trop-petit',
    gravite: 'erreur',
    titre: 'Texte sous le plancher de 14 px (AGENTS.md § 2.4)',
    test: (l) => {
      const m = /font-size\s*:\s*([\d.]+)\s*(px|rem)/i.exec(l)
      if (!m) return false
      const val = parseFloat(m[1])
      return m[2].toLowerCase() === 'px' ? val < 14 : val < 0.875
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
    titre: 'Autre police que Poppins — une seule famille, `var(--font-sans)` (AGENTS.md § 2.8)',
    test: (l) => /font-family\s*:/i.test(l) && !/var\(--font/i.test(l) && !/inherit|monospace|var\(--gd/i.test(l),
  },
  {
    id: 'focus-supprime',
    gravite: 'erreur',
    titre: 'Focus supprimé — jamais sans remplacement visible (AGENTS.md § 2.10)',
    test: (l) => /outline\s*:\s*(none|0)\b/i.test(l),
    contexte: (src) => !/:focus-visible/.test(src), // toléré si le fichier redonne un focus visible
  },
  {
    id: 'duree-en-dur',
    gravite: 'avertissement',
    titre: 'Durée d\'animation en dur — passer par `var(--dur-*)`',
    test: (l) => /(transition|animation)(-duration)?\s*:[^;]*\b[\d.]+m?s\b/i.test(l) && !/var\(--/.test(l),
  },
  {
    id: 'important-mouvement',
    gravite: 'avertissement',
    titre: '`!important` sur du mouvement — ne pas contourner `prefers-reduced-motion` (AGENTS.md § 2.12)',
    test: (l) => /(transition|animation)[^;]*!important/i.test(l),
  },
]

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
    if (js && !MOTS_STYLE.test(ligne)) return                  // en JS, on ne juge que le style

    for (const regle of REGLES) {
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

const args = process.argv.slice(2)
const strict = args.includes('--strict')
const tout = args.includes('--tout')
const json = args.includes('--json')
const cibles = args.filter((a) => !a.startsWith('--'))
if (!cibles.length) cibles.push(process.cwd())

const trouvailles = cibles.flatMap((c) => fichiers(c).flatMap(analyser))
const erreurs = trouvailles.filter((t) => t.gravite === 'erreur')
const avertis = trouvailles.filter((t) => t.gravite === 'avertissement')

if (json) {
  console.log(JSON.stringify({ erreurs: erreurs.length, avertissements: avertis.length, trouvailles }, null, 2))
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
      console.log(`    ${court(t.fichier)}:${t.ligne}`)
      console.log(`      ${t.extrait}`)
    }
    if (items.length > PLAFOND) console.log(`    … et ${items.length - PLAFOND} autres (--tout pour les voir)`)
  }
}

console.log('\n  ' + '─'.repeat(66))
if (!trouvailles.length) {
  console.log('  Rien à signaler. Reste la partie qui se voit à l\'écran : AGENTS.md § 7.\n')
} else {
  console.log(`  ${erreurs.length} erreur(s), ${avertis.length} avertissement(s).`)
  console.log('  Une ligne légitimement hors règle se neutralise avec un commentaire `gd-ok: raison`.')
  console.log('  Le reste de la checklist se vérifie à l\'écran : AGENTS.md § 7.\n')
}

process.exit(erreurs.length || (strict && avertis.length) ? 1 : 0)
