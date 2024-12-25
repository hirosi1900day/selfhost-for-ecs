#!/bin/bash

if [[ -z "$APP_ID" || -z "$OWNER" || -z "$REPO" || -z "$PRIVATE_KEY_BASE64" ]]; then
  echo "ERROR: APP_ID, OWNER, REPO, PRIVATE_KEY_BASE64 環境変数を設定してください"
  exit 1
fi

# Base64エンコードされた鍵をデコード
PRIVATE_KEY=$(echo "$PRIVATE_KEY_BASE64" | base64 -d)

# JWTの有効期間 (10分)
ISSUED_AT=$(date +%s)
EXPIRATION=$(($ISSUED_AT + 600))

# ヘッダーとペイロードを作成
HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 -A | tr -d '=' | tr '/+' '_-' | tr -d '\n')
PAYLOAD=$(echo -n "{\"iat\":$ISSUED_AT,\"exp\":$EXPIRATION,\"iss\":\"$APP_ID\"}" | openssl base64 -A | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# ヘッダーとペイロードを署名
SIGNATURE=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign <(echo "$PRIVATE_KEY") | openssl base64 -A | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# JWTトークン生成
JWT="$HEADER.$PAYLOAD.$SIGNATURE"

# installation_idを取得
INSTALLATION_RESPONSE=$(curl -s -X GET \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$OWNER/$REPO/installation")

INSTALLATION_ID=$(echo "$INSTALLATION_RESPONSE" | jq -r '.id')

if [[ "$INSTALLATION_ID" == "null" ]]; then
  echo "ERROR: installation_id の取得に失敗しました"
  echo "$INSTALLATION_RESPONSE"
  exit 1
fi

# インストールトークンを取得
INSTALLATION_TOKEN_RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens")

# トークンを抽出
ACCESS_TOKEN=$(echo "$INSTALLATION_TOKEN_RESPONSE" | jq -r '.token')

if [[ "$ACCESS_TOKEN" == "null" ]]; then
  echo "ERROR: アクセストークンの取得に失敗しました"
  echo "$INSTALLATION_TOKEN_RESPONSE"
  exit 1
fi

# アクセストークンを出力
echo "$ACCESS_TOKEN"
