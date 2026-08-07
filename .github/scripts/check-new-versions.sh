#!/bin/bash
#
# check-new-versions
# ==================
#
# Compares the most recent upstream tags on GitHub against the versions that are
# actually built by the workflows in .github/workflows, and exits non-zero when a
# recent tag is not built yet.
#
# Only the RECENT_TAG_LIMIT newest tags per product are considered, so historical
# versions that were deliberately never added do not keep the check red forever.
# Pre-releases (alpha, beta, rc) are ignored.
#
# Requires: gh (authenticated), jq.
#
# Usage: .github/scripts/check-new-versions.sh

set -euo pipefail

RECENT_TAG_LIMIT=${RECENT_TAG_LIMIT:-20}

WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../workflows" && pwd)"

TAG_QUERY='
query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    refs(refPrefix: "refs/tags/", first: 100, orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) {
      nodes {
        name
        target {
          ... on Commit { committedDate }
          ... on Tag { target { ... on Commit { committedDate } } }
        }
      }
    }
  }
}'

fetchRecentTags() {
    local repository=$1

    gh api graphql \
        -f query="$TAG_QUERY" \
        -f owner="${repository%%/*}" \
        -f name="${repository##*/}" \
        -q '.data.repository.refs.nodes[] | "\(.target.committedDate // .target.target.committedDate) \(.name)"' \
        | grep -viE -- '-(alpha|beta|rc)' \
        | sort -r \
        | head -n "$RECENT_TAG_LIMIT" \
        | awk '{print $2}'
}

getBuiltVersions() {
    local variable=$1
    shift

    grep -ohE "${variable}: [0-9][^,}[:space:]]*" "$@" \
        | sed "s/${variable}: //" \
        | sort -u
}

checkProduct() {
    local label=$1
    local repository=$2
    local variable=$3
    shift 3

    local workflows=()
    for workflow in "$@"; do
        workflows+=("$WORKFLOW_DIR/$workflow")
    done

    echo "$label ($repository), $RECENT_TAG_LIMIT most recent tags:"

    local built
    built=$(getBuiltVersions "$variable" "${workflows[@]}")

    local missing=()
    while read -r tag; do
        if grep -qxF "$tag" <<< "$built"; then
            echo "  [ok]      $tag"
            continue
        fi

        echo "  [MISSING] $tag"
        missing+=("$tag")
    done < <(fetchRecentTags "$repository")

    echo

    if [ ${#missing[@]} -eq 0 ]; then
        return 0
    fi

    {
        echo "### $label: ${#missing[@]} version(s) not built"
        echo
        echo "Add the following to \`${workflows[0]##*/}\`:"
        echo
        for version in "${missing[@]}"; do
            echo "- \`$version\`"
        done
        echo
    } >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

    FAILED_PRODUCTS+=("$label: ${missing[*]}")
}

FAILED_PRODUCTS=()

checkProduct "Mage-OS" "mage-os/mageos-magento2" "MAGEOS_VERSION" mage-os.yml
checkProduct "Magento" "magento/magento2" "MAGENTO_VERSION" magento-2.4.yml magento-2.3.yml

if [ ${#FAILED_PRODUCTS[@]} -eq 0 ]; then
    echo "All recent upstream tags are built."
    exit 0
fi

echo "Missing versions found:"
printf '  %s\n' "${FAILED_PRODUCTS[@]}"
exit 1
