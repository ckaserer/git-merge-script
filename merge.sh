#!/bin/bash -e

: "${BRANCHES_TO_MERGE_REGEX?}" "${BRANCH_TO_MERGE_INTO?}"
: "${GIT_SECRET_TOKEN?}" "${GIT_REPO}"

export GIT_COMMITTER_EMAIL='ci@cd'
export GIT_COMMITTER_NAME='pipeline'

if ! grep -q "${BRANCHES_TO_MERGE_REGEX}" <<< "${TRAVIS_BRANCH:-$CI_COMMIT_REF_NAME}"; then
    printf "Current branch %s doesn't match regex %s, exiting\\n" \
        "${TRAVIS_BRANCH:-$CI_COMMIT_REF_NAME}" "${BRANCHES_TO_MERGE_REGEX}" >&2
    exit 0
fi

# Since Travis does a partial checkout, we need to get the whole thing
repo_temp=$(mktemp -d)
git clone "https://${GIT_SERVER}/${GIT_REPO}" "${repo_temp}"

# shellcheck disable=SC2164
cd "${repo_temp}"

printf 'Checking out %s\n' "${BRANCH_TO_MERGE_INTO}" >&2
git checkout "${BRANCH_TO_MERGE_INTO}"

printf 'Merging %s\n' "${TRAVIS_COMMIT:-CI_COMMIT_SHA}" >&2
git merge --ff-only "${TRAVIS_COMMIT:-CI_COMMIT_SHA}"

printf 'Pushing to %s\n' "${GIT_REPO}" >&2

push_uri="https://$GIT_SECRET_TOKEN@${GIT_SERVER}/$GIT_REPO"

# Redirect to /dev/null to avoid secret leakage
git push "$push_uri" "$BRANCH_TO_MERGE_INTO" >/dev/null 2>&1

# delete current branch
# git push "$push_uri" :"${TRAVIS_BRANCH:-$CI_COMMIT_REF_NAME}" >/dev/null 2>&1