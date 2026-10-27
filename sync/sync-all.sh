#!/usr/bin/env bash
# sync-all.sh — Robot de synchro : met à jour les fichiers gérés par
# gdm-dev-rules dans toutes les apps qui portent le topic GDM_TOPIC, avec une PR
# par app.
#
# Lancé par .github/workflows/sync-apps.yml. Prérequis : GH_TOKEN (jeton de la
# GitHub App) et `gh auth setup-git` déjà exécuté.
#
# Variables :
#   ONLY_REPO   ne synchroniser qu'une app (nom du repo)
#   DRY_RUN=1   tout calculer sans rien pousser ni ouvrir de PR
#
# Règles de merge :
#   - première installation dans une app (pas encore de .ai-rules/MANAGED.sha256)
#     → PR qui attend la validation de GDM_LEAD : elle ajoute des workflows qui
#     peuvent entrer en conflit avec l'existant ;
#   - toutes les synchros suivantes, workflows compris → le robot attend que les
#     checks soient verts puis merge lui-même (le lead a déjà relu le changement
#     dans gdm-dev-rules). Il est en exception de la règle d'approbation
#     gdm-protection posée par proteger-repos.sh ; un check en échec bloque.

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$(cd "$HERE/.." && pwd)
# shellcheck source=sync/config.env
. "$HERE/config.env"

ONLY_REPO="${ONLY_REPO:-}"
DRY_RUN="${DRY_RUN:-0}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/stdout}"
SRC_SHA=$(git -C "$SRC" rev-parse --short HEAD)
SRC_REPO="${GITHUB_REPOSITORY:-$GDM_ORG/gdm-dev-rules}"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

if [ -n "$ONLY_REPO" ]; then
    if ! [[ "$ONLY_REPO" =~ ^[A-Za-z0-9._-]+$ ]]; then
        echo "Nom de repo invalide : $ONLY_REPO" >&2
        exit 2
    fi
    repos="$ONLY_REPO"
else
    repos=$(gh repo list "$GDM_ORG" --topic "$GDM_TOPIC" --no-archived --limit 1000 \
        --json name --jq '.[].name')
fi

if [ -z "$repos" ]; then
    echo "Aucune app avec le topic $GDM_TOPIC."
    exit 0
fi

{
    echo "## Synchro gdm-dev-rules ($SRC_SHA)"
    echo ""
    echo "| App | Branche | Résultat |"
    echo "|---|---|---|"
} >> "$SUMMARY"

report() {
    echo "| $1 | $2 | $3 |" >> "$SUMMARY"
    echo "→ $1 ($2) : $3"
}

sync_repo() {
    local repo=$1
    local full="$GDM_ORG/$repo" dir="$WORK/$repo"
    local notes="$WORK/$repo.notes" touched="$WORK/$repo.touched" body="$WORK/$repo.body"
    : > "$notes"
    : > "$touched"

    git clone --quiet --no-tags "https://github.com/$full.git" "$dir"
    if ! git -C "$dir" rev-parse -q --verify HEAD >/dev/null; then
        report "$repo" "-" "ignorée (repo vide)"
        return 0
    fi

    # Branche cible : dev si elle existe, sinon la branche par défaut de l'app.
    # Les PR Dependabot visent la même branche.
    local target dependabot_branch=""
    if git -C "$dir" ls-remote --exit-code --heads origin dev >/dev/null 2>&1; then
        target=dev
        git -C "$dir" fetch --quiet origin dev
        [ "$(git -C "$dir" symbolic-ref --short refs/remotes/origin/HEAD)" = origin/dev ] \
            || dependabot_branch=dev
    else
        target=$(git -C "$dir" symbolic-ref --short refs/remotes/origin/HEAD)
        target=${target#origin/}
    fi
    git -C "$dir" checkout --quiet -B "$GDM_SYNC_BRANCH" "origin/$target"

    local first_install=0
    [ -f "$dir/.ai-rules/MANAGED.sha256" ] || first_install=1

    GDM_NOTES="$notes" GDM_TOUCHED="$touched" GDM_DEPENDABOT_BRANCH="$dependabot_branch" \
        bash "$HERE/apply.sh" "$SRC" "$dir"

    # -f : les fichiers gérés doivent être versionnés même si le .gitignore
    # de l'app les exclut.
    sort -u "$touched" -o "$touched"
    git -C "$dir" add -A -f --pathspec-from-file="$touched"

    local open_pr
    open_pr=$(gh pr list -R "$full" --head "$GDM_SYNC_BRANCH" --state open \
        --json number --jq '.[0].number // empty')

    if git -C "$dir" diff --cached --quiet; then
        if [ -n "$open_pr" ] && [ "$DRY_RUN" != 1 ]; then
            gh pr close "$open_pr" -R "$full" --delete-branch \
                --comment "Plus rien à synchroniser : l'app est déjà à jour."
        fi
        report "$repo" "$target" "à jour"
        return 0
    fi

    local changed
    changed=$(git -C "$dir" diff --cached --name-status)

    if [ "$DRY_RUN" = 1 ]; then
        report "$repo" "$target" "changements détectés (dry run, rien poussé)"
        echo "$changed"
        return 0
    fi

    # Si la PR ouverte contient déjà exactement ce contenu, on ne repousse pas :
    # un nouveau commit relancerait tous les checks pour rien.
    local same_content=0
    if [ -n "$open_pr" ] && git -C "$dir" fetch --quiet origin "$GDM_SYNC_BRANCH" 2>/dev/null; then
        if [ "$(git -C "$dir" write-tree)" = "$(git -C "$dir" rev-parse "FETCH_HEAD^{tree}")" ]; then
            same_content=1
        fi
    fi
    if [ "$same_content" = 0 ]; then
        git -C "$dir" -c user.name="$GDM_BOT_NAME" -c user.email="$GDM_BOT_EMAIL" \
            commit --quiet -m "chore(gdm-rules): synchro des règles GDM ($SRC_SHA)"
        git -C "$dir" push --quiet --force origin "$GDM_SYNC_BRANCH"
    fi

    {
        echo "Mise à jour automatique des fichiers gérés par [gdm-dev-rules](https://github.com/$SRC_REPO/commit/$SRC_SHA)."
        echo ""
        echo "Ces fichiers évoluent uniquement dans gdm-dev-rules : ne les modifie pas dans cette app."
        echo ""
        if [ "$first_install" = 1 ]; then
            echo "**⚠ Première installation des règles GDM dans cette app : elle attend une validation humaine.** Vérifie qu'elle n'entre pas en conflit avec les workflows existants. Les synchros suivantes se mergeront automatiquement."
        else
            echo "Le robot la merge lui-même dès que les checks sont verts (il est en exception de la règle d'approbation)."
        fi
        echo ""
        echo "### Fichiers modifiés"
        echo ""
        echo '```'
        echo "$changed"
        echo '```'
        if [ -s "$notes" ]; then
            echo ""
            echo "### À noter"
            echo ""
            cat "$notes"
        fi
    } > "$body"

    local pr title="chore(gdm-rules): synchro des règles GDM ($SRC_SHA)"
    if [ -n "$open_pr" ]; then
        pr=$open_pr
        gh pr edit "$pr" -R "$full" --title "$title" --body-file "$body" --base "$target" >/dev/null
    else
        gh pr create -R "$full" --base "$target" --head "$GDM_SYNC_BRANCH" \
            --title "$title" --body-file "$body" >/dev/null
        pr=$(gh pr list -R "$full" --head "$GDM_SYNC_BRANCH" --state open \
            --json number --jq '.[0].number')
    fi
    local url="https://github.com/$full/pull/$pr"

    if [ "$first_install" = 1 ]; then
        if [ -n "$GDM_LEAD" ]; then
            gh pr edit "$pr" -R "$full" --add-reviewer "${GDM_LEAD#@}" >/dev/null 2>&1 || true
        fi
        report "$repo" "$target" "[PR #$pr]($url) à valider (première installation)$(protection_note "$full")"
        return 0
    fi

    # Merge différé : on ouvre d'abord les PR de toutes les apps, puis on attend
    # leurs checks (phase 2), au lieu d'attendre app par app.
    echo "$repo $target $pr" >> "$WORK/to-merge"
}

# Signale une app où la règle de protection gdm-protection n'est pas posée
# (voir sync/proteger-repos.sh). Silencieux si l'App n'a pas le droit de lire.
protection_note() {
    local n
    n=$(gh api "repos/$1/rulesets" --jq '[.[] | select(.name == "gdm-protection")] | length' 2>/dev/null) || return 0
    if [ "$n" = 0 ]; then
        echo " — ⚠ protection des branches absente (lancer sync/proteger-repos.sh)"
    fi
    return 0
}

# Lit l'état des checks du dernier commit d'une PR, via l'API REST (droits
# « Checks » et « Commit statuses » en lecture). Pas de `gh pr view --json
# statusCheckRollup` : sa requête GraphQL demande aussi les workflows, ce que
# l'App n'a pas le droit de lire (« Resource not accessible by integration »).
# Affiche une liste de mots ok / pending / fail ; échoue si la lecture échoue.
read_checks() {
    local full=$1 sha=$2 runs statuses
    runs=$(gh api "repos/$full/commits/$sha/check-runs?per_page=100&filter=latest" --jq '
        [.check_runs[] |
          if .status != "completed" then "pending"
          elif (.conclusion == "success" or .conclusion == "neutral" or .conclusion == "skipped") then "ok"
          else "fail" end] | join(" ")') || return 1
    statuses=$(gh api "repos/$full/commits/$sha/status" --jq '
        [.statuses[] |
          if .state == "success" then "ok"
          elif .state == "pending" then "pending"
          else "fail" end] | join(" ")') || return 1
    echo "$runs $statuses"
}

# Attend la fin des checks d'une PR.
# Retour : 0 au moins un check et tous verts, 1 au moins un check en échec,
# 2 délai dépassé (checks en cours, absents, ou illisibles).
# Règle de sûreté : jamais de merge sur une erreur de lecture ni en l'absence
# de check. Toute app gérée a au moins GDM Rules Guard : « aucun check » veut
# dire « pas encore visible » ou « problème », jamais « rien à attendre ».
# Le SHA vérifié est laissé dans CHECKED_SHA pour merger exactement ce commit.
wait_checks() {
    local full=$1 pr=$2 start=$SECONDS states sha
    local timeout="${GDM_CHECKS_TIMEOUT:-1800}" poll="${GDM_POLL:-30}"
    CHECKED_SHA=""
    while :; do
        if sha=$(gh pr view "$pr" -R "$full" --json headRefOid --jq .headRefOid) \
            && [ -n "$sha" ] && states=$(read_checks "$full" "$sha"); then
            CHECKED_SHA=$sha
        else
            echo "  ⚠ $full#$pr : lecture des checks impossible, nouvel essai" >&2
            states="pending"
        fi
        echo "  $full#$pr : checks = [$(echo $states)]" >&2
        case " $states " in
            *" fail "*) return 1 ;;
            *" pending "*) ;;
            *ok*) return 0 ;;
            *) ;; # aucun check visible : on attend, jamais de merge à l'aveugle
        esac
        if [ $((SECONDS - start)) -ge "$timeout" ]; then return 2; fi
        sleep "$poll"
    done
}

merge_pr() {
    local repo=$1 target=$2 pr=$3
    local full="$GDM_ORG/$repo" url="https://github.com/$GDM_ORG/$repo/pull/$3" rc=0 method
    wait_checks "$full" "$pr" || rc=$?
    case "$rc" in
        1) report "$repo" "$target" "[PR #$pr]($url) ❌ checks en échec : à regarder$(protection_note "$full")"; return 0 ;;
        2) report "$repo" "$target" "[PR #$pr]($url) checks en cours, absents ou illisibles : pas de merge, nouvel essai la nuit prochaine"; return 0 ;;
    esac
    method=$(gh repo view "$full" --json rebaseMergeAllowed,squashMergeAllowed \
        --jq 'if .rebaseMergeAllowed then "rebase" elif .squashMergeAllowed then "squash" else "merge" end')
    # --match-head-commit : on ne merge que le commit dont on a vu les checks
    # verts (refus si quelqu'un a poussé autre chose entre-temps).
    if gh pr merge "$pr" -R "$full" "--$method" --delete-branch \
        --match-head-commit "$CHECKED_SHA" >/dev/null 2>&1; then
        report "$repo" "$target" "[PR #$pr]($url) ✓ mergée$(protection_note "$full")"
    else
        report "$repo" "$target" "[PR #$pr]($url) checks verts mais merge refusé : le robot est-il en exception de la règle gdm-protection ?"
    fi
}

failures=0
for repo in $repos; do
    [ "$repo" = "${SRC_REPO#*/}" ] && continue
    echo ""
    echo "=== $repo ==="
    # Sous-shell hors condition : set -e reste actif dans sync_repo, et l'échec
    # d'une app n'empêche pas de traiter les suivantes.
    set +e
    (sync_repo "$repo")
    rc=$?
    set -e
    if [ "$rc" -ne 0 ]; then
        failures=$((failures + 1))
        report "$repo" "-" "❌ échec (voir les logs)"
    fi
done

# Phase 2 : attendre les checks et merger.
if [ -s "$WORK/to-merge" ]; then
    echo ""
    echo "=== Attente des checks et merge ==="
    while read -r repo target pr; do
        set +e
        (merge_pr "$repo" "$target" "$pr") < /dev/null
        rc=$?
        set -e
        if [ "$rc" -ne 0 ]; then
            failures=$((failures + 1))
            report "$repo" "$target" "❌ échec du merge (voir les logs)"
        fi
    done < "$WORK/to-merge"
fi

if [ "$failures" -gt 0 ]; then
    echo ""
    echo "✗ $failures app(s) en échec."
    exit 1
fi
