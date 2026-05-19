#!/bin/bash

[[ -n "$DEBUG" ]] && set -x

set -euo pipefail

BRANCH="nix-flake-auto-update"

export PAGER=cat

git fetch --all
git config user.name "Winkekatze Updater"
git config user.email "noreply@forgejo.c3voc.de"

cd "nixos/"

if ! git ls-remote --exit-code origin "$BRANCH"
then
    echo ">> branch does not exist, creating a new one"

    git checkout -b "$BRANCH"
else
    echo ">> branch already exists, using it"

    git checkout "$BRANCH"
fi

echo ">> starting flake update"

had_changes=0

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
        had_changes=1
    fi
done

echo ">> flake updates done"
echo ">> checking if pull request needs to get created"

if (( $had_changes > 0 ))
then
    echo ">> have diff against master, need to create a pull request"

    git push --set-upstream --force origin HEAD

    OPEN_PRS="$(curl -X 'GET' -s 'https://forgejo.c3voc.de/api/v1/repos/voc/cm/pulls?state=open&page=1' -H 'accept: application/json' | jq 'map(select(.head.label == "nix-flake-auto-update")) | length')"

    if (( $OPEN_PRS > 0 ))
    then
        echo ">> there's already an open pull request which we probably just updated."
    else
        echo ">> creating pull request"

        curl -X 'POST' \
          "https://forgejo.c3voc.de/api/v1/repos/voc/cm/pulls" \
          -H 'accept: application/json' \
          -H "Authorization: token ${FORGEJO_TOKEN}" \
          -H 'Content-Type: application/json' \
          -d "{ \"base\": \"master\", \"head\": \"${BRANCH}\", \"title\": \"nix-flake-auto-update\"}"

        echo ">> created pull request"
    fi
else
    echo ">> no changes, exiting"
fi
