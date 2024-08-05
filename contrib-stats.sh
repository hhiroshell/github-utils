#!/usr/bin/env bash

function usage {
    cat <<EOM
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
    echo "GitHub CLI is not authenticated. Please run 'gh auth login' to authenticate."
    exit 2
fi

echo "Counting commits..." >&2
for n in $(
    gh api -X GET "repos/${repository}/commits" \
        --jq "[.[] | select(.author.login == \"${user}\")] | length" \
        --paginate
); do
    commits_count=$((commits_count + n))
done

echo "Counting pull requests..." >&2
for n in $(
    gh api -X GET "repos/${repository}/pulls?state=all" \
        --jq "[.[] | select(.user.login == \"${user}\")] | length" \
        --paginate
); do
    pulls_count=$((pulls_count + n))
done

echo "Counting issues..." >&2
for n in $(
    gh api -X GET "repos/${repository}/issues?state=all" \
        --jq "[.[] | select(.user.login == \"${user}\") | select(.pull_request | not)] | length" \
        --paginate
); do
    issues_count=$((issues_count + n))
done

echo "==== RESULTS ===="
echo "Commits: ${commits_count}"
echo "Pull Requests: ${pulls_count}"
echo "Issues: ${issues_count}"
