#!/usr/bin/env bash
# proteger-repos.sh — Pose (ou met à jour) la règle de protection
# « gdm-protection » dans les apps GDM. Nécessite le plan GitHub Team.
#
# À lancer par le lead, avec son propre compte gh (admin de l'organisation) :
# une fois après le passage en Team, puis pour chaque nouvelle app, après le
# merge de la première PR du robot.
#
# Usage :
#   bash sync/proteger-repos.sh                → toutes les apps du topic gdm-managed
#   bash sync/proteger-repos.sh interface-ia   → une ou plusieurs apps nommées
#   DRY_RUN=1 bash sync/proteger-repos.sh      → affiche la règle sans rien poser
#
# La règle s'applique à la branche par défaut et à main, staging, dev :
#   - pas de push direct, pas de force push, pas de suppression de la branche ;
#   - PR obligatoire avec 1 approbation ; la dernière modification doit être
#     approuvée par quelqu'un d'autre que son auteur ; conversations résolues ;
#   - checks bloquants : Security OSS (secrets, SAST, dépendances) et
#     GDM Rules Guard.
# Exceptions (via PR uniquement, tracées par GitHub sur chaque PR) :
#   - le robot de synchro (GitHub App GDM_SYNC_APP_ID) : il merge ses PR sans
#     approbation, après avoir lui-même attendu que les checks soient verts ;
#   - si GDM_LEAD_BYPASS=1 : les admins du repo, pour merger sans approbation
#     en urgence ou en l'absence de l'autre dev.

set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=sync/config.env
. "$HERE/config.env"

DRY_RUN="${DRY_RUN:-0}"
RULESET_NAME="gdm-protection"
REQUIRED_CHECKS=("PR Security - Secrets + SAST" "PR Security - OSV Scanner" "GDM Rules Guard")
ADMIN_ROLE_ID=5   # identifiant GitHub du rôle de repo « admin »

if [ $# -gt 0 ]; then
    repos="$*"
else
    repos=$(gh repo list "$GDM_ORG" --topic "$GDM_TOPIC" --no-archived --limit 1000 \
        --json name --jq '.[].name')
fi

ruleset_json() {
    local bypass="" sep="" c checks=""
    if [ -n "$GDM_SYNC_APP_ID" ]; then
        bypass="{\"actor_id\": $GDM_SYNC_APP_ID, \"actor_type\": \"Integration\", \"bypass_mode\": \"pull_request\"}"
        sep=", "
    fi
    if [ "${GDM_LEAD_BYPASS:-0}" = 1 ]; then
        bypass="$bypass$sep{\"actor_id\": $ADMIN_ROLE_ID, \"actor_type\": \"RepositoryRole\", \"bypass_mode\": \"pull_request\"}"
    fi
    sep=""
    for c in "${REQUIRED_CHECKS[@]}"; do
        checks="$checks$sep{\"context\": \"$c\"}"
        sep=", "
    done
    cat <<EOF
{
  "name": "$RULESET_NAME",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["~DEFAULT_BRANCH", "refs/heads/main", "refs/heads/staging", "refs/heads/dev"],
      "exclude": []
    }
  },
  "bypass_actors": [$bypass],
  "rules": [
    {"type": "deletion"},
    {"type": "non_fast_forward"},
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": true,
        "required_review_thread_resolution": true
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "required_status_checks": [$checks]
      }
    }
  ]
}
EOF
}

if [ -z "$GDM_SYNC_APP_ID" ]; then
    echo "⚠ GDM_SYNC_APP_ID est vide dans sync/config.env : le robot ne sera pas en exception."
    echo "  Ses PR attendront ton approbation au lieu de se merger seules."
    echo ""
fi

body=$(mktemp)
trap 'rm -f "$body"' EXIT
ruleset_json > "$body"

if [ "$DRY_RUN" = 1 ]; then
    echo "Règle qui serait posée (DRY_RUN) :"
    cat "$body"
    exit 0
fi

failures=0
for repo in $repos; do
    full="$GDM_ORG/$repo"
    printf '%s : ' "$repo"

    # Les checks exigés n'existent qu'une fois les règles GDM installées :
    # sans eux, plus aucune PR ne pourrait être mergée.
    default_branch=$(gh repo view "$full" --json defaultBranchRef --jq '.defaultBranchRef.name')
    if ! gh api "repos/$full/contents/.ai-rules/MANAGED.sha256?ref=$default_branch" >/dev/null 2>&1 \
        && ! gh api "repos/$full/contents/.ai-rules/MANAGED.sha256?ref=dev" >/dev/null 2>&1; then
        echo "ignorée : règles GDM pas encore installées (merger d'abord la PR du robot)"
        continue
    fi

    existing=$(gh api "repos/$full/rulesets" --jq ".[] | select(.name == \"$RULESET_NAME\") | .id" 2>&1) || {
        echo "❌ lecture impossible ($existing). Plan GitHub Team actif ? Es-tu admin du repo ?"
        failures=$((failures + 1))
        continue
    }
    if [ -n "$existing" ]; then
        gh api --method PUT "repos/$full/rulesets/$existing" --input "$body" >/dev/null \
            && echo "✓ règle mise à jour" || { echo "❌ mise à jour refusée"; failures=$((failures + 1)); }
    else
        gh api --method POST "repos/$full/rulesets" --input "$body" >/dev/null \
            && echo "✓ règle posée" || { echo "❌ création refusée"; failures=$((failures + 1)); }
    fi
done

if [ "$failures" -gt 0 ]; then
    echo ""
    echo "✗ $failures app(s) en échec."
    exit 1
fi
