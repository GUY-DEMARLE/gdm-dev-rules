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
#   - règles, docs, design system, CLAUDE.md / AGENTS.md → merge automatique
#     dès que les checks sont verts ;
#   - tout changement sous .github/ (workflows) ou dans CODEOWNERS → PR qui
#     attend la validation de GDM_LEAD.

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
    local target
    if git -C "$dir" ls-remote --exit-code --heads origin dev >/dev/null 2>&1; then
        target=dev
        git -C "$dir" fetch --quiet origin dev
    else
        target=$(git -C "$dir" symbolic-ref --short refs/remotes/origin/HEAD)
        target=${target#origin/}
    fi
    git -C "$dir" checkout --quiet -B "$GDM_SYNC_BRANCH" "origin/$target"

    GDM_LEAD="$GDM_LEAD" GDM_NOTES="$notes" GDM_TOUCHED="$touched" \
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

    local changed sensitive=0
    changed=$(git -C "$dir" diff --cached --name-status)
    if git -C "$dir" diff --cached --name-only | grep -qE '^(\.github/|docs/CODEOWNERS$|CODEOWNERS$)'; then
        sensitive=1
    fi

    if [ "$DRY_RUN" = 1 ]; then
        report "$repo" "$target" "changements détectés (dry run, rien poussé)"
        echo "$changed"
        return 0
    fi

    git -C "$dir" -c user.name="$GDM_BOT_NAME" -c user.email="$GDM_BOT_EMAIL" \
        commit --quiet -m "chore(gdm-rules): synchro des règles GDM ($SRC_SHA)"
    git -C "$dir" push --quiet --force origin "$GDM_SYNC_BRANCH"

    {
        echo "Mise à jour automatique des fichiers gérés par [gdm-dev-rules](https://github.com/$SRC_REPO/commit/$SRC_SHA)."
        echo ""
        echo "Ces fichiers évoluent uniquement dans gdm-dev-rules : ne les modifie pas dans cette app."
        echo ""
        if [ "$sensitive" = 1 ]; then
            echo "**⚠ Cette PR touche aux workflows GitHub ou à CODEOWNERS : elle attend une validation humaine.**"
        else
            echo "Merge automatique dès que les checks sont verts."
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

    if [ "$sensitive" = 1 ]; then
        # Une PR réutilisée peut avoir gardé le merge auto d'une synchro
        # précédente : on le coupe, un humain doit valider.
        gh pr merge "$pr" -R "$full" --disable-auto >/dev/null 2>&1 || true
        if [ -n "$GDM_LEAD" ]; then
            gh pr edit "$pr" -R "$full" --add-reviewer "${GDM_LEAD#@}" >/dev/null 2>&1 || true
        fi
        report "$repo" "$target" "[PR #$pr]($url) à valider (workflows / CODEOWNERS)"
        return 0
    fi

    local method
    method=$(gh repo view "$full" --json rebaseMergeAllowed,squashMergeAllowed \
        --jq 'if .rebaseMergeAllowed then "rebase" elif .squashMergeAllowed then "squash" else "merge" end')
    if gh pr merge "$pr" -R "$full" --auto "--$method" >/dev/null 2>&1; then
        report "$repo" "$target" "[PR #$pr]($url) en merge automatique"
    else
        report "$repo" "$target" "[PR #$pr]($url) ouverte, merge auto indisponible (activer « Allow auto-merge » dans le repo)"
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

if [ "$failures" -gt 0 ]; then
    echo ""
    echo "✗ $failures app(s) en échec."
    exit 1
fi
