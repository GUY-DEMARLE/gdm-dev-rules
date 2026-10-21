# Modèle : journal des décisions d'une app

**À quoi ça sert** : `docs/DECISIONS.md` est la mémoire de l'app. Il garde, pour chaque décision importante, **ce qui a été décidé, pourquoi, et ce qui a été écarté**. Le code dit *comment* l'app fonctionne ; ce journal dit *pourquoi* elle est comme ça. Il évite qu'un dev, ou son IA, défasse un choix réfléchi sans le savoir.

**Règle** : `RULES.md` section 8. Ce fichier-ci est le modèle ; le journal de l'app vit dans `docs/DECISIONS.md` et appartient à l'app (le robot gdm-dev-rules n'y touche pas).

---

## Quand écrire une entrée

Une décision mérite une entrée si quelqu'un, dans six mois, pourrait se demander « pourquoi c'est fait comme ça ? » ou être tenté de la défaire. Par exemple :

- choix d'architecture : où vit une logique (front, Edge Function, API), découpage, flux de données ;
- choix ou rejet d'une librairie, d'un service tiers, d'un modèle d'IA ;
- modèle de données : nouvelle table, relation, ce qui est stocké ou pas ;
- sécurité et droits : qui accède à quoi (GRANT, RLS, rôles), données sensibles ;
- contournement d'une limite de plateforme (hébergement, API, quota) ;
- écart volontaire à une règle GDM, avec sa justification ;
- abandon d'une approche essayée (pour ne pas la réessayer).

**Pas d'entrée** pour : un correctif simple, un renommage, une mise en forme, une montée de version sans impact.

## Comment écrire une entrée

- **En haut du journal** : la plus récente d'abord.
- **Courte** : 4 à 8 lignes. Le détail technique va dans la PR ; le journal garde l'essentiel.
- **Dans la même PR** que le changement qu'elle explique.
- **On ne supprime jamais une entrée.** Si une décision change, on ajoute une nouvelle entrée, et on passe l'ancienne en statut « Remplacée par … ».

---

## Modèle à copier dans `docs/DECISIONS.md`

```markdown
# Journal des décisions — <nom de l'app>

La mémoire de l'app : ce qui a été décidé, pourquoi, et ce qui a été écarté.
Entrée la plus récente en haut. On ne supprime jamais une entrée : une décision
qui change est « Remplacée par » une nouvelle. Règles : gdm-dev-rules, RULES.md section 8.

---

## AAAA-MM-JJ — <titre court de la décision>

- **Statut** : Active
- **Décision** : <ce qui a été décidé, en une ou deux phrases>
- **Pourquoi** : <la raison, le problème résolu>
- **Écarté** : <les alternatives envisagées et pourquoi elles n'ont pas été retenues>
- **À revoir si** : <la condition qui rendrait cette décision mauvaise>
- **Où** : <PR, fichiers ou dossiers concernés>
```

## Exemple

```markdown
## 2026-10-19 — Les appels à Gemini passent par une Edge Function

- **Statut** : Active
- **Décision** : le front n'appelle jamais Gemini ; il appelle l'Edge Function `generate`, qui détient la clé et applique un plafond de tokens par utilisateur.
- **Pourquoi** : règle GDM 1.6 ; sur un front statique, une clé côté navigateur serait publique.
- **Écarté** : appel direct depuis le front avec une clé restreinte par domaine (contournable, et coût non maîtrisé).
- **À revoir si** : l'app passe sur une API Render, qui pourrait porter ce proxy.
- **Où** : PR #42, `supabase/functions/generate/`.
```
