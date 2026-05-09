#!/usr/bin/env bash

[[ -n "$DEBUG" ]] && set -x

set -euo pipefail

BRANCH="nix-flake-auto-update"

export PAGER=cat

tmpdir=$(mktemp -d)
trap 'cd /; rm -Rf "$tmpdir"' EXIT

echo "Using temporary directory $tmpdir"

cd "${tmpdir}"

echo ">> creating and fetching remote"

git clone "ssh://forgejo@forgejo.c3voc.de/voc/cm.git" "."
git config user.name "Winkekatze Updater"
git config user.email "noreply@forgejo.c3voc.de"

cd "${tmpdir}/nixos/"

if ! git ls-remote --exit-code origin "$BRANCH"
then
    echo ">> branch does not exist, creating a new one"

    git checkout -b "$BRANCH"
else
    echo ">> branch already exists, using it"

    git checkout "$BRANCH"
fi

echo ">> starting flake update"

for flake in alertmanager-mqtt viri-matrix voc-telemetry
do
    echo ">>>> trying to update flake input: $flake"

    nix flake update "$flake"

    if [[ -z "$(git status --porcelain .)" ]]
    then
        echo ">>>>   no updates needed, skipping"
    else
        git add .
        git commit -m "Auto-Update flake input $flake on $(date '+%F %T')"
    fi
done

echo ">> flake updates done"
echo ">> checking if pull request needs to get created"

if [[ -n "$(git diff master...)" ]]
then
    echo ">> have diff against master, need to create a pull request"

    git push --set-upstream --force origin HEAD

else
    echo ">> no changes, exiting"
fi
