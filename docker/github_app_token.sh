#!/usr/bin/env bash

# GitHub CLI を使用して JWT を生成する関数
generate_jwt() {
  now=$(date '+%s')
  iat=$((now - 60))
  exp=$((now + 180)) # 3 minutes expiration

  header=$(printf '{"alg":"RS256","typ":"JWT"}' | openssl enc -base64 -A | tr '+/' '-_' | tr -d '=')
  payload=$(printf '{"iss":"%s","iat":%s,"exp":%s}' "$APP_ID" "$iat" "$exp" | openssl enc -base64 -A | tr '+/' '-_' | tr -d '=')

  signature=$(printf '%s.%s' "$header" "$payload" | \
    openssl dgst -binary -sha256 -sign "$PRIVATE_KEY" | \
    openssl enc -base64 -A | tr '+/' '-_' | tr -d '=')

  echo "$header.$payload.$signature"
}

# JWT の生成
jwt=$(generate_jwt)

# GitHub App Installation ID の取得
installation_id=$(gh api \
  -H "Authorization: Bearer $jwt" \
  -H "Accept: application/vnd.github+json" \
  "/repos/$REPO/$ORGANIZATION/installation" | jq -r '.id')

if [ -z "$installation_id" ]; then
  echo "Failed to fetch installation ID" >&2
  exit 1
fi

# Installation Access Token の生成
token=$(gh api \
  -H "Authorization: Bearer $jwt" \
  -H "Accept: application/vnd.github+json" \
  -X POST \
  "/app/installations/$installation_id/access_tokens" | jq -r '.token')

if [ -z "$token" ]; then
  echo "Failed to fetch access token" >&2
  exit 1
fi

echo "$token"
