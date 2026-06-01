# Workflow Security OSS

Ce document explique le workflow GitHub Actions `.github/workflows/security-oss.yml`.

L'objectif est de mettre en place un socle de securite automatise, reutilisable sur plusieurs applications, quelle que soit la stack technique : PHP, Node, Python, Docker, application web publique, ou projet utilisant Supabase.

Le workflow ne remplace pas un pentest manuel complet. Il sert de controle continu pour detecter rapidement les erreurs classiques : secrets exposes, dependances vulnerables, problemes de code, configuration web faible, ou signaux de surface d'attaque.

## Objectif General

Le workflow couvre deux moments differents du cycle de vie du projet.

Sur les Pull Requests, il agit comme une barriere de securite. Si un risque important est detecte, la PR echoue et doit etre corrigee avant merge.

Chaque lundi, ou manuellement, il lance un audit plus large. Cet audit est non bloquant : il produit des rapports, les archive dans GitHub Actions, puis envoie une synthese Slack enrichie par une analyse IA.

## Declencheurs

Le workflow se lance dans trois cas.

```yaml
pull_request:
  branches: [main, staging, dev]
```

Sur Pull Request, les controles sont bloquants. L'objectif est d'eviter d'introduire un secret, une faille de code ou une dependance vulnerable.

```yaml
workflow_dispatch:
```

Lancement manuel depuis GitHub Actions. Utile pour tester le workflow ou relancer un audit a la demande.

```yaml
schedule:
  - cron: "0 6 * * 1"
```

Lancement automatique chaque lundi a 06:00 UTC.

## Configuration Necessaire

Le workflow peut fonctionner partiellement sans configuration, mais certaines fonctionnalites demandent des variables ou secrets GitHub.

### Secrets GitHub

```text
SLACK_WEBHOOK_URL
```

Webhook Slack utilise pour envoyer le rapport final.

```text
OPENAI_API_KEY
```

Cle OpenAI utilisee pour generer la synthese IA du rapport. Si elle est absente, le workflow continue sans analyse IA.

### Variables GitHub

```text
SECURITY_TARGET_URL
```

URL de production a auditer avec ZAP et Supabomb.

Exemple :

```text
https://www.monguydemarle.com/boite-outils/generateur-post/
```

```text
OPENAI_SECURITY_MODEL
```

Modele IA utilise pour la synthese Slack. Par defaut, le workflow utilise `gpt-5.4-mini`.

## Permissions

```yaml
permissions:
  contents: read
  actions: read
  security-events: write
```

Le workflow lit le code et les informations d'execution GitHub Actions. La permission `security-events: write` est conservee pour compatibilite avec certains outils de securite, meme si le workflow evite les integrations payantes comme l'upload SARIF GitHub Code Scanning.

## Jobs Du Workflow

## 1. PR Security - Secrets + SAST

Ce job tourne uniquement sur Pull Request.

Il cherche deux familles de problemes :

```text
1. secrets exposes
2. erreurs de code liees a la securite
```

Il est bloquant : si un probleme est trouve, la PR echoue.

### Checkout

```yaml
uses: actions/checkout@v4
```

Cette etape recupere le code du repository dans le runner GitHub Actions.

Le workflow utilise `fetch-depth: 0` pour donner a certains outils un acces plus complet a l'historique Git si necessaire.

### Gitleaks

Source : [Gitleaks GitHub](https://github.com/gitleaks/gitleaks) et [site officiel Gitleaks](https://gitleaks.org/).

Gitleaks est un scanner de secrets. Il cherche dans le repository des valeurs qui ressemblent a des informations sensibles :

```text
cles API
tokens Slack
tokens GitHub
cles OpenAI / Anthropic
mots de passe
identifiants de base de donnees
fichiers .env commites par erreur
```

Dans ce workflow, Gitleaks est lance via Docker :

```yaml
docker run --rm -v "${GITHUB_WORKSPACE}:/repo" zricethezav/gitleaks:latest detect
```

Ce choix evite d'utiliser l'action GitHub officielle `gitleaks/gitleaks-action`, qui peut demander une licence dans les organisations GitHub.

Interet :

```text
eviter qu'un secret soit merge dans le code
reduire le risque de fuite d'identifiants
forcer la rotation rapide d'une cle si une fuite est detectee
```

### Semgrep

Source : [documentation Semgrep](https://semgrep.dev/docs/) et [documentation des rulesets](https://semgrep.dev/docs/running-rules/).

Semgrep est un outil SAST, c'est-a-dire Static Application Security Testing. Il analyse le code sans l'executer.

Dans ce workflow, il utilise :

```text
p/owasp-top-ten
p/secrets
```

Ces rulesets permettent de detecter des patterns proches des risques OWASP et des secrets.

Exemples de problemes que Semgrep peut aider a detecter :

```text
injections
validation insuffisante des entrees utilisateur
usage dangereux de fonctions
exposition d'informations sensibles
patterns de code risques
```

Interet :

```text
detecter les erreurs de code avant merge
standardiser une base de controle securite
remonter des signaux sur des failles classiques
```

## 2. PR Security - OSV Scanner

Ce job tourne uniquement sur Pull Request.

Source : [OSV Scanner GitHub Action](https://github.com/google/osv-scanner-action) et [documentation OSV Scanner](https://google.github.io/osv-scanner/usage/).

OSV Scanner analyse les dependances du projet et les compare a la base de vulnerabilites OSV.

Il regarde notamment les lockfiles presents dans le repository :

```text
composer.lock
package-lock.json
requirements.txt
autres fichiers supportes par OSV
```

Contrairement au job Semgrep, OSV ne cherche pas principalement des erreurs dans le code applicatif. Il cherche si une bibliotheque utilisee est connue comme vulnerable.

Exemple :

```text
une version de symfony/options-resolver a une vulnerabilite connue
une dependance npm a une CVE
une dependance Python est affectee par un advisory
```

Le workflow lance OSV directement, sans upload SARIF. Cela evite de dependre de GitHub Advanced Security, qui peut etre payant ou non active sur certains repositories.

Interet :

```text
eviter d'introduire une dependance vulnerable
detecter les problemes de supply chain
completer les scans de code par un scan des bibliotheques
```

## 3. Weekly Security Audit

Ce job tourne chaque lundi ou manuellement.

Il est configure avec :

```yaml
continue-on-error: true
```

Cela signifie qu'un outil peut echouer sans casser tout le workflow. L'objectif est de produire un rapport, pas de bloquer le projet.

## Ordre Des Etapes Hebdomadaires

### 1. Checkout

Le workflow recupere le code.

### 2. Preparation Du Dossier De Rapports

```bash
mkdir -p reports
```

Tous les rapports generes sont stockes dans `reports/`.

### 3. Detection Automatique De La Stack

Le workflow detecte les fichiers presents.

```text
composer.lock -> active Composer audit
package-lock.json -> active npm audit
requirements*.txt -> active pip-audit
Dockerfile -> active Trivy
SECURITY_TARGET_URL -> active ZAP et Supabomb
```

Interet :

```text
utiliser le meme workflow sur plusieurs stacks
eviter les erreurs si un outil ne concerne pas le repo
skipper proprement les scans inutiles
```

### 4. Gitleaks En Mode Rapport

Gitleaks relance un scan de secrets, mais en mode non bloquant.

Il genere :

```text
reports/gitleaks-report.json
```

Interet :

```text
avoir un rapport exploitable meme hors PR
surveiller les secrets dans le temps
detecter une fuite introduite par un commit direct ou historique
```

### 5. Semgrep En Mode Rapport

Semgrep genere :

```text
reports/semgrep-report.json
```

Interet :

```text
avoir un snapshot hebdomadaire des risques de code
suivre les signaux OWASP
centraliser les findings dans les artifacts
```

### 6. OSV Scanner En Mode Rapport

OSV genere :

```text
reports/osv-scanner-report.json
```

Interet :

```text
detecter les vulnerabilites de dependances apparues depuis le dernier audit
surveiller les advisories qui changent avec le temps
```

Une dependance peut devenir vulnerable meme si le code n'a pas change.

### 7. Composer Audit

Source : [documentation Composer CLI](https://getcomposer.org/doc/03-cli.md).

Cette etape s'execute seulement si un `composer.lock` est present.

Composer est le gestionnaire de dependances PHP. La commande :

```bash
composer audit --format=json
```

verifie les packages PHP installes via le lockfile.

Interet :

```text
detecter les vulnerabilites PHP connues
completer OSV avec l'audit natif Composer
produire un rapport dedie par projet PHP
```

### 8. npm Audit

Source : [documentation npm audit](https://docs.npmjs.com/cli/v7/commands/npm-audit/).

Cette etape s'execute seulement si un `package-lock.json` est present.

Elle verifie les dependances Node/npm.

Interet :

```text
detecter les vulnerabilites npm
identifier les severites critical, high, moderate, low
completer OSV avec l'audit natif npm
```

### 9. pip-audit

Source : [pip-audit sur PyPI](https://pypi.org/project/pip-audit/) et [repository PyPA pip-audit](https://github.com/pypa/pip-audit).

Cette etape s'execute seulement si un fichier `requirements*.txt` est present.

Elle verifie les dependances Python.

Interet :

```text
detecter les packages Python vulnerables
produire un rapport JSON exploitable
standardiser l'audit des projets Python
```

### 10. Trivy

Source : [documentation Trivy filesystem scan](https://trivy.dev/docs/latest/target/filesystem/) et [documentation CLI Trivy](https://trivy.dev/docs/latest/references/configuration/cli/trivy/).

Cette etape s'execute seulement si un `Dockerfile` existe.

Trivy scanne le filesystem du projet et peut detecter :

```text
vulnerabilites connues
problemes de configuration
risques lies aux fichiers Docker
secrets selon la configuration de scan
```

Interet :

```text
ajouter une couche de controle pour les projets containerises
detecter des risques lies a l'image ou au filesystem
```

### 11. OWASP ZAP Baseline Scan

Source : [OWASP ZAP](https://www.zaproxy.org/) et [ZAP Baseline Scan](https://www.zaproxy.org/docs/docker/baseline-scan/).

Cette etape s'execute seulement si `SECURITY_TARGET_URL` est configuree.

ZAP scanne l'application web exposee publiquement.

Il peut detecter :

```text
headers de securite manquants
cookies mal configures
configuration HTTP faible
exposition de fichiers sensibles
erreurs serveur visibles
problemes web classiques
```

Rapports generes :

```text
reports/zap-report.json
reports/zap-report.md
reports/zap-report.html
```

Interet :

```text
tester l'application en conditions proches de la production
detecter des problemes visibles depuis l'exterieur
avoir un rapport HTML lisible
```

Limite : le scan baseline n'est pas un scan authentifie complet. Il teste surtout ce qui est publiquement accessible.

### 12. Supabomb

Source : [presentation Supabomb](https://dev.to/victor_yrazusta/introducing-supabomb-open-source-supabase-penetration-testing-4dnb).

Cette etape s'execute seulement si `SECURITY_TARGET_URL` est configuree.

Supabomb est utile surtout pour les applications qui utilisent Supabase. Il cherche des signaux lies a une surface Supabase exposee ou mal configuree.

Important : Supabomb n'est pas lance via `uvx supabomb`, car l'outil n'est pas publie comme package Python classique dans le registry. Le workflow clone le repository GitHub officiel puis execute :

```bash
uv run supabomb discover --url "$TARGET_URL"
```

Interet :

```text
standardiser un controle utile sur les projets Supabase
ne pas avoir a modifier le workflow selon chaque app
produire un rapport meme si l'app ne semble pas utiliser Supabase
```

Sur un projet sans Supabase, le rapport peut etre vide ou peu utile. C'est acceptable dans une logique de workflow universel.

### 12bis. Mises A Jour De Dependances (Maintenance)

En plus des scans de vulnerabilites, l'audit hebdomadaire detecte les dependances **non a jour** (mises a jour disponibles), selon la stack detectee automatiquement.

```text
requirements*.txt -> pip list --outdated (dans un venv isole)
package-lock.json -> npm outdated --json
composer.lock     -> composer outdated --direct --format=json
```

Chaque paquet outdated est classe en `major`, `minor` ou `patch` par comparaison des numeros de version. Les resultats sont :

```text
ecrits dans reports/dependency-updates.json
resumes dans reports/dependency-updates-slack.txt
ajoutes au contexte de l'analyse IA (qui commente aussi les mises a jour)
affiches dans une section "Maintenance / dependances" du message Slack
```

Cette etape est non bloquante et best-effort : si l'installation des dependances echoue, l'audit continue et la section reste vide. Elle complete les audits de securite, qui regardent les vulnerabilites, par une vue maintenance, qui regarde l'obsolescence des dependances.

Difference importante :

```text
OSV / npm audit / composer audit / pip-audit -> dependances VULNERABLES
mises a jour de dependances                   -> dependances OBSOLETES (a jour ou non)
```

### 13. Rapport De Synthese

Le workflow cree :

```text
reports/security-summary.md
```

Ce fichier resume :

```text
le repository audite
l'URL cible
l'etat de chaque outil
les fichiers detectes
les scans executes ou ignores
```

Interet :

```text
donner une vue rapide sans ouvrir tous les rapports
faciliter le suivi hebdomadaire
servir de point d'entree pour le responsable ou le mainteneur
```

### 14. Analyse IA

Source : [OpenAI Responses API](https://platform.openai.com/docs/api-reference/responses/create?api-mode=responses).

Le workflow utilise l'API OpenAI si `OPENAI_API_KEY` est configuree.

Il n'envoie pas les rapports bruts complets. Il construit un contexte filtre :

```text
etat des jobs
nombre de findings Semgrep
extraits limites des messages
packages vulnerables OSV
advisories Composer
resultats npm
alertes ZAP
extrait Supabomb limite
```

Des patterns de secrets courants sont redacted avant envoi.

Le modele par defaut est :

```text
gpt-5.4-mini
```

Il peut etre change via :

```text
OPENAI_SECURITY_MODEL
```

Interet :

```text
transformer des rapports techniques en synthese lisible
prioriser les actions
eviter de noyer l'equipe sous des fichiers JSON
obtenir une checklist claire dans Slack
```

### 15. Upload Des Artifacts

Tous les rapports sont archives dans GitHub Actions :

```text
security-audit-reports
```

Interet :

```text
garder une trace de l'audit
permettre une analyse detaillee apres notification Slack
telecharger les rapports JSON / HTML / Markdown
```

### 16. Notification Slack

Source : [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks).

Le workflow envoie un message Slack si `SLACK_WEBHOOK_URL` est configure.

Le message contient :

```text
repository
lien vers le run GitHub Actions
URL cible
etat de chaque scan
conseil IA
indication que les rapports sont disponibles en artifacts
```

Interet :

```text
ne pas devoir aller verifier GitHub Actions manuellement
centraliser la maintenance securite dans Slack
creer une routine hebdomadaire lisible
```

## Pourquoi Le Workflow Est Universel

Le workflow ne suppose pas que le projet est PHP, Node, Python, Docker ou Supabase.

Il detecte les fichiers presents et active uniquement les outils utiles :

```text
composer.lock present -> Composer audit
package-lock.json present -> npm audit
requirements*.txt present -> pip-audit
Dockerfile present -> Trivy
SECURITY_TARGET_URL configuree -> ZAP + Supabomb
```

Cela permet de copier le workflow dans plusieurs repositories avec peu de configuration.

Configuration minimale :

```text
SLACK_WEBHOOK_URL
OPENAI_API_KEY
SECURITY_TARGET_URL
```

## Difference Entre PR Et Audit Hebdomadaire

Les jobs de PR sont faits pour bloquer rapidement les risques evidents.

```text
PR = controle strict avant merge
```

L'audit hebdomadaire est fait pour surveiller dans le temps.

```text
Hebdomadaire = rapport complet et non bloquant
```

Cette distinction est importante : certaines vulnerabilites apparaissent apres coup, sans changement de code. L'audit du lundi permet donc de detecter un probleme meme si aucune PR recente n'a ete mergee.

## Ce Que Le Workflow Couvre Bien

Le workflow couvre bien :

```text
secrets exposes
erreurs de code detectables statiquement
dependances vulnerables
problemes web publics simples
problemes Docker ou filesystem
surface Supabase potentielle
rapport et notification
```

## Limites

Le workflow ne remplace pas un pentest manuel.

Il ne couvre pas completement :

```text
logique metier complexe
contournement subtil de roles
scan authentifie avance
abus fonctionnels
prompt injection avancee
tests avec plusieurs comptes utilisateurs
enchaînement de plusieurs failles faibles
```

Il doit donc etre considere comme un audit automatique recurrent, pas comme une certification de securite.

## Process Recommande

Sur chaque PR :

```text
1. Verifier que Gitleaks passe
2. Verifier que Semgrep passe
3. Verifier que OSV passe
4. Corriger avant merge si un job echoue
```

Chaque lundi :

```text
1. Lire le message Slack
2. Ouvrir le run GitHub Actions si un outil est en failure
3. Telecharger les artifacts si necessaire
4. Traiter en priorite les secrets, critical et high
5. Documenter les faux positifs si besoin
```

Chaque trimestre ou avant mise en production importante :

```text
1. Faire une revue manuelle ciblee
2. Tester les roles utilisateurs
3. Tester les formulaires sensibles
4. Verifier les rate limits
5. Revoir les variables d'environnement et secrets
```

## Conclusion

Ce workflow apporte un socle DevSecOps simple et reutilisable.

Il automatise les controles les plus utiles au quotidien, produit des rapports exploitables, notifie l'equipe dans Slack et ajoute une synthese IA pour aider a prioriser.

Il est particulierement adapte aux outils internes et petites applications web, tout en restant suffisamment generique pour etre copie dans d'autres repositories.
