#!/usr/bin/env bash

source "$(dirname "$0")/log.sh"
source "$(dirname "$0")/progress-bar.sh"

function usage {
    cat >&2<<EOM
Usage: $(basename "$0") [OPTION]...
    -r VALUE    GitHub repository
    -u VALUE    GitHub account
    -h          Display help
EOM
}

while getopts ":r:u:h" optKey; do
    case "$optKey" in
    r)
        repository="${OPTARG}"
        ;;
    u)
        user="${OPTARG}"
        ;;
    h|*)
      usage
      exit 2
      ;;
    esac
done

if [ -z "${repository}" ] || [ -z "${user}" ]; then
    usage
    exit 2
fi

echo "Repository: ${repository}, User: ${user}"

if ! gh auth status > /dev/null 2>&1; then
    log "GitHub CLI is not authenticated. Please run 'gh auth login' to authenticate."
    exit 2
fi

log "Counting commits..."
for n in $(
    gh api -X GET "repos/${repository}/commits" \
        --jq "[.[] | select(.author.login == \"${user}\")] | length" \
        --paginate
); do
    commits_count=$((commits_count + n))
done

log "Counting pull requests..." >&2
for n in $(
    gh api -X GET "repos/${repository}/pulls?state=all" \
        --jq "[.[] | select(.user.login == \"${user}\")] | length" \
        --paginate
); do
    pulls_count=$((pulls_count + n))
done

log "Counting issues..." >&2
for n in $(
    gh api -X GET "repos/${repository}/issues?state=all" \
        --jq "[.[] | select(.user.login == \"${user}\") | select(.pull_request | not)] | length" \
        --paginate
); do
    issues_count=$((issues_count + n))
done

log "Counting reviews..." >&2
latest=0
for pulls in $(
    gh api -X GET "repos/${repository}/pulls?state=all" \
        --jq "[.[] | select(.user.login == \"${user}\" | not) | .number]" \
        --paginate \
    | jq .[]
); do
    for p in $pulls; do
        c=$(gh api -X GET "repos/${repository}/pulls/${p}/reviews" --jq "[.[] | select(.user.login == \"${user}\")] | length")
        if [ "${c}" -ge 1 ]; then
            reviews_count=$((reviews_count + 1))
        fi

        if [ "${latest}" -eq 0 ]; then
            latest="${p}"
        fi
        progress_bar "$((latest - p))" "${latest}"
    done
done
finish_progress_bar

echo "==== RESULTS ===="
echo "Commits: ${commits_count}"
echo "Pull Requests: ${pulls_count}"
echo "Issues: ${issues_count}"
echo "Reviews: ${reviews_count}"
