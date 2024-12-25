#!/bin/bash

if [ -n "$ORGANIZATION" ]; then
  echo "get Organization token"
  REG_TOKEN=$(gh api -X POST /orgs/${ORGANIZATION}/actions/runners/registration-token --jq .token)
  cd /home/docker/actions-runner
  echo "setup Organization Runner"
  ./config.sh --url https://github.com/${ORGANIZATION} --token ${REG_TOKEN}
else
  echo "get Repository token"
  REG_TOKEN=$(gh api -X POST /repos/${OWNER}/${REPO}/actions/runners/registration-token --jq .token)
  cd /home/docker/actions-runner
  echo "setup Repository Runner"
  ./config.sh --url https://github.com/${OWNER}/${REPO} --token ${REG_TOKEN}
fi

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!
