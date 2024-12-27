#!/bin/bash
ACCESS_TOKEN=$(./github_app_token.sh)

# エラーチェック
if [[ -z "$ACCESS_TOKEN" ]]; then
  echo "ERROR: アクセストークンの取得に失敗しました"
  exit 1
fi

if [ -n "$ORGANIZATION" ]; then
  echo "get Organization token"
  REG_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" https://api.github.com/orgs/${ORGANIZATION}/actions/runners/registration-token | jq .token --raw-output)
  cd /home/docker/actions-runner
  echo "setup Organization Runner"
  ./config.sh --url https://github.com/${ORGANIZATION} --token ${REG_TOKEN}  
else
  echo "https://github.com/${OWNER}/${REPO}"
  echo "get Repository token"
  REG_TOKEN=$(curl -sX POST -H "Authorization: token ${ACCESS_TOKEN}" https://api.github.com/repos/${OWNER}/${REPO}/actions/runners/registration-token | jq .token --raw-output)
  cd /home/docker/actions-runner
  echo "setup Repository Runner"
  ./config.sh --url https://github.com/${OWNER}/${REPO} --token ${REG_TOKEN}  
fi

sudo chown docker:docker /run/user/1000/docker.sock

cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

./run.sh & wait $!