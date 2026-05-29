# Design — Hébergement Gandi & cadre de décision stack

**Date** : 2026-05-29
**Statut** : validé (design), prêt pour plan d'implémentation
**Périmètre** : documentation des règles GDM (`gdm-dev-rules`)

---

## 1. Contexte & problème

Beaucoup d'apps GDM sont hébergées sur un **serveur Gandi FTP classique** (mutualisé, sous `guydemarle.com`). Or les docs de règles (`templates/.ai-rules/RULES.md`, `templates/docs-rules/ARCHITECTURE_SECURITE_GDM.md`) décrivent une architecture **exclusivement** orientée Vercel (front) / Render / Supabase Edge (back), sans jamais traiter Gandi comme un choix d'architecture. Gandi n'apparaît que comme un effet de bord d'incident (Incident 3 : `GANDI_SFTP_PASSWORD` en clair) et dans la liste des accès à auditer.

Réalité technique constatée :
- Gandi héberge surtout la couche **front** (JS, parfois build React/Vite uploadé), **+ du PHP/MySQL** pour certaines apps.
- La couche API est souvent **Supabase Edge Functions** (+ PostgREST).
- Choix de Gandi motivé par **coût / simplicité / un seul hébergement déjà payé** sous `guydemarle.com`.
- Déploiement **non standardisé** : tantôt GitHub Actions (FTP deploy), tantôt upload manuel (FileZilla/WinSCP).
- Secrets serveur : `.env` posé sur le serveur et **protégé par `.htaccess`** (non téléchargeable via HTTP), ou variables **injectées au build distant** (GitHub Actions) pour le front.

**But** : documenter Gandi comme choix d'hébergement légitime, expliquer **quand** c'est le bon choix et **tout ce que ça implique** (sécurité, secrets, déploiement), et l'**intégrer** au cadre de décision d'architecture existant.

---

## 2. Décisions prises (issues du cadrage)

1. **Type d'apps** : front JS + PHP/MySQL (legacy) + petites API Supabase Edge Functions.
2. **Moteur du choix Gandi** : coût / simplicité / un seul hébergement.
3. **Déploiement** : varie aujourd'hui ; on veut **définir un standard** (Actions + SFTP, transport sécurisé, creds en GitHub Secrets).
4. **Secrets** : `.env` hors webroot protégé par `.htaccess`, ou injection au build distant.
5. **Positionnement** : pour la plupart des apps, **prioriser Supabase (PostgREST + Edge)** plutôt qu'une API maison Render. Quand l'API est **100 % Supabase**, le front n'est que du statique → **Gandi FTP est le meilleur choix d'hébergement front**. Cas **hybrides** (ex. RAG maison) = besoin d'un back maison Render → chemin Vercel/Render standard.
6. **PHP/MySQL** : traité comme **legacy encadré**, pas comme voie recommandée. La voie recommandée pour une nouvelle app simple = front statique Gandi + Supabase PostgREST/Edge.
7. **Approche d'intégration retenue** : **A** — cadre de décision tissé dans les docs existantes + 1 doc dédié Gandi.
8. **Ajout** : un **encadré « Prompt IA de démarrage »** à chaque point de décision, pour interroger l'IA au kickoff du projet.

---

## 3. Le modèle de décision (cœur du livrable)

Deux décisions chaînées :

```
1. BACK / API — quelle couche logique ?
   ├─ Surtout du CRUD sur Postgres + proxy léger vers tiers ?
   │     → Supabase : PostgREST (CRUD auto) + Edge Functions (proxy/logique légère)   ◄ PRIORISER
   │
   └─ Logique hors PostgREST/Edge (async lourd, orchestration, long-running,
      RAG, libs Python/ML) ?
         → API maison sur Render (Node/Python)                                         ◄ cas hybride

2. FRONT — hébergement ? (découle de 1)
   ├─ SPA statique, pas de rendu serveur ?
   │     → Gandi FTP (statique sous guydemarle.com)                                    ◄ moins cher/simple
   │
   └─ Besoin SSR/SEO (Next.js) / serverless / preview deploys par PR ?
         → Vercel
```

**Nuance documentée** : le vrai déclencheur « Gandi vs Vercel » est *« le front a-t-il besoin de rendu serveur ? »*. En pratique cela coïncide avec « l'API est-elle Supabase-only ? » (une app assez simple pour être Supabase-only est presque toujours une SPA statique). On garde l'heuristique en mentionnant le cas SSR comme exception.

**Règles de sécurité attachées** (à écrire noir sur blanc) :
- Front statique Gandi + Supabase en **accès direct** ⇒ **les RLS sont l'unique barrière de sécurité** → Règle 2 (RLS dès la migration + policies strictes) devient **vitale**.
- Tout **tiers sensible/payant** (Gemini, OpenAI, Stripe…) **reste derrière une Edge Function** (Règle 6). Jamais d'appel direct depuis le front Gandi (sinon = Incident `simu-recrutement` rejoué).

---

## 4. Fichiers touchés (détaillé)

### 4.1 `templates/.ai-rules/RULES.md`
- **§0 Cadre global** : ajouter le modèle de décision condensé (Supabase-first pour l'API ; Gandi pour front statique ; Render/Vercel pour les cas serveur). Ajouter un encadré « Prompt IA de démarrage » court.
- **§6 Stack et conventions** : enrichir la ligne *Hosting* → `Vercel (front SSR/serverless) | Gandi FTP (front statique) | Render (back lourd) | Supabase Edge (proxy léger)`. Ajouter les **non-négociables Gandi** : SFTP/FTPS jamais FTP en clair ; `.env` hors webroot via `.htaccess`, jamais commité ; RLS strictes obligatoires car seule barrière.
- **§7 Références** : ajouter `HEBERGEMENT_GANDI.md`.

### 4.2 `templates/docs-rules/ARCHITECTURE_SECURITE_GDM.md`
- **En-tête « Les docs GDM de reference »** : nouvelle ligne pour `HEBERGEMENT_GANDI.md`.
- **Partie 3 — Stack** :
  - Sous-section **Back** : insérer l'arbre de décision Supabase-first > Render, avec encadré prompt IA.
  - Nouvelle sous-section **Hébergement du front** : arbre Gandi (statique) vs Vercel (SSR/serverless), règle de sécu attachée, encadré prompt IA.
- **Version** : 1.2 → **1.3** (+ date).
- Mention courte dans le schéma Partie 1 que l'hébergement front peut être Gandi (statique) ou Vercel.

### 4.3 `templates/docs-rules/HEBERGEMENT_GANDI.md` (nouveau)
Voir plan détaillé section 5.

### 4.4 `templates/docs-rules/SETUP_PROJET.md`
- À l'étape « architecture de l'app », ajouter un renvoi vers l'arbre de décision et `HEBERGEMENT_GANDI.md`, et le **prompt IA de démarrage complet** (regroupant les deux décisions).

---

## 5. Plan du nouveau doc `HEBERGEMENT_GANDI.md`

1. **Quand choisir Gandi** — critères : front statique + API Supabase-only + priorité coût/simplicité. Quand *ne pas* : besoin SSR/SEO, back maison lourd, preview deploys par PR.
2. **Place dans l'archi GDM** — Gandi = couche front (statique) ; Supabase = back (PostgREST + Edge) ; schéma front → Supabase, et front → Edge → tiers.
3. **Le piège sécu n°1** — RLS = unique barrière + Edge obligatoire pour tiers sensibles.
4. **Secrets & config** — `.env` hors webroot protégé par `.htaccess` (PHP) ; injection au build distant (front, GitHub Actions) ; rien de commité ; `.env.example` avec placeholders.
5. **Transport & identifiants** — SFTP/FTPS jamais FTP en clair ; identifiants FTP/SFTP en **GitHub Secrets**, jamais dans le repo ; rotation (rappel Incident 3 : `GANDI_SFTP_PASSWORD` en clair).
6. **Standard de déploiement** — GitHub Actions : build front en CI → deploy SFTP ; **exemple de workflow** commenté.
7. **Hygiène du webroot** — interdire l'accès HTTP à `.git/`, `.env`, fichiers de config, backups, `.map` ; **exemple de règles `.htaccess`**.
8. **Garde-fous MySQL legacy** — requêtes préparées (PDO/paramétrées), user MySQL **least-privilege**, DB non exposée publiquement, pas de creds commités. Note : MySQL n'a pas de RLS → l'access control est dans le code PHP.
9. **Security OSS sur ces apps** — `composer audit` si `composer.lock`, scan bundle front, OWASP ZAP sur l'URL publique via `SECURITY_TARGET_URL`.
10. **Checklist de mise en prod Gandi** — liste actionnable récapitulant 3→9.
11. **Prompts IA** — prompt de démarrage + prompt de revue sécu Gandi.

---

## 6. Pattern « Prompt IA de démarrage »

Format constant : un encadré markdown (citation + 💬) placé à **chaque nœud de décision** (arbre back, arbre front-hosting) et un prompt « complet » dans `SETUP_PROJET.md`.

Exemple (prompt complet de kickoff) :

> 💬 **Prompt IA de démarrage**
> « Mon app doit [décrire le besoin métier + volumétrie + tiers utilisés]. D'après les règles GDM (`.ai-rules/RULES.md`), conseille-moi : (1) API Supabase PostgREST/Edge ou API maison Render ? (2) front statique sur Gandi FTP ou Vercel ? Justifie selon l'arbre de décision et liste les implications sécu (RLS, Edge Functions, gestion des secrets). »

Variantes courtes ciblées :
- Au nœud **back** : « …dois-je rester sur Supabase PostgREST/Edge ou ai-je besoin d'une API maison Render ? »
- Au nœud **front** : « …mon front a-t-il besoin de rendu serveur, ou un statique sur Gandi FTP suffit-il ? »

---

## 7. Hors périmètre (YAGNI)

- Migration effective des apps PHP existantes vers Supabase (pas dans ce lot ; on documente, on ne migre pas).
- Refonte du modèle d'archi des Parties 1 & 5 (approche C écartée).
- Tooling de déploiement (script/CLI) — on fournit un exemple de workflow, pas un outil.

---

## 8. Critères d'acceptation

- [ ] L'arbre de décision (back puis front) figure dans `ARCHITECTURE_SECURITE_GDM.md` Partie 3 et en version condensée dans `RULES.md` §0.
- [ ] `HEBERGEMENT_GANDI.md` existe dans `templates/docs-rules/` et couvre les 11 points du plan.
- [ ] `RULES.md` §6 liste Gandi dans les options d'hosting + les non-négociables Gandi ; §7 référence le nouveau doc.
- [ ] Un encadré « Prompt IA de démarrage » est présent à chaque point de décision + un complet dans `SETUP_PROJET.md`.
- [ ] La règle « RLS = unique barrière » et « Edge obligatoire pour tiers » est explicite (renforce Règles 2 et 6, ne les contredit pas).
- [ ] Tous les liens internes (tables de références, renvois) pointent vers le nouveau doc ; version d'archi bumpée à 1.3.
- [ ] Aucune contradiction introduite avec les 6 règles non-négociables.
