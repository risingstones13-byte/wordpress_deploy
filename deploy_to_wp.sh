#!/bin/bash
# deploy_to_wp.sh
# posts/*.html を WordPress に自動投稿する（サブディレクトリ対応）

# === 設定 ===
WP_URL="https://kabu24h365dojo.shop/wp-json/wp/v2/posts"
WP_USER="risingstones13-byte"          # WordPress 管理者ユーザー名
WP_PASS="4bBp gccg q6JQ Gtk1 ia1j Ow7Y" # 作成済みアプリケーションパスワード
POST_DIR="./posts"

# === 依存チェック ===
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq がインストールされていません。"
  exit 1
fi

# === 投稿処理 ===
for file in "$POST_DIR"/*.html; do
  # ファイル存在チェック
  if [ ! -f "$file" ]; then
    echo "投稿用 HTML ファイルが見つかりません: $file"
    continue
  fi

  # タイトルはファイル名（拡張子なし）
  TITLE=$(basename "$file" .html)

  # HTML を安全に JSON 形式に変換
  jq -Rs --arg title "$TITLE" '{title:$title, content:., status:"publish"}' < "$file" > temp.json

  # 投稿実行
  echo "=== 投稿中: $TITLE ==="
  RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" -u "$WP_USER:$WP_PASS" \
    -X POST "$WP_URL" \
    -H "Content-Type: application/json" \
    --data-binary @temp.json)

  # 結果確認
  HTTP_STATUS=$(echo "$RESPONSE" | grep HTTP_STATUS | cut -d: -f2)
  if [ "$HTTP_STATUS" == "201" ]; then
    echo "投稿成功: $TITLE"
  else
    echo "投稿失敗: $TITLE"
    echo "$RESPONSE"
  fi

  # 一時ファイル削除
  rm -f temp.json
done

