#!/bin/bash
# leit-on.jp/ai-shain/ 本番デプロイ（ロリポップ FTPS）
#
#   1) パスワードをファイルに書く:  echo -n 'パスワード' > ~/.lolipop_pw && chmod 600 ~/.lolipop_pw
#   2) 実行:                        bash ~/hp-wireframe/deploy-ai-shain.sh
#   3) 後始末:                      rm ~/.lolipop_pw
#
# 公開フォルダは /leit-on/ （/leit-on.jp/ は空の罠フォルダなので使わない）
set -euo pipefail

HOST="ftp.lolipop.jp"
USER="main.jp-34863fca9adc9f69"
REMOTE="/leit-on/ai-shain"
LOCAL="$HOME/hp-wireframe/ai-shain"
PWFILE="${LOLIPOP_PW_FILE:-$HOME/.lolipop_pw}"
BACKUP="$HOME/hp-wireframe/backup"

[ -f "$PWFILE" ] || { echo "パスワードファイルがありません: $PWFILE" >&2; exit 1; }
PASS=$(cat "$PWFILE")

FILES=(
  "index.html"
  "privacy.html"
  "assets/favicon-32.png"
  "assets/favicon-192.png"
  "assets/apple-touch-icon.png"
  "assets/leiton-logo.png"
)

mkdir -p "$BACKUP"
STAMP=$(date +%Y%m%d_%H%M%S)

echo "== 1. 本番の既存HTMLをバックアップ（あれば） =="
for f in index.html privacy.html; do
  out="$BACKUP/ai-shain_${f%.html}_$STAMP.html"
  if curl -sS --ssl-reqd -u "$USER:$PASS" "ftp://$HOST$REMOTE/$f" -o "$out" 2>/dev/null && [ -s "$out" ]; then
    echo "   保存: backup/$(basename "$out") ($(wc -c < "$out") バイト)"
  else
    rm -f "$out"
    echo "   （$f は本番に未存在。新規アップロードとして続行）"
  fi
done

echo "== 2. アップロード =="
for f in "${FILES[@]}"; do
  [ -f "$LOCAL/$f" ] || { echo "ローカルにありません: $LOCAL/$f" >&2; exit 1; }
  curl -sS --ssl-reqd --ftp-create-dirs -u "$USER:$PASS" -T "$LOCAL/$f" "ftp://$HOST$REMOTE/$f"
  echo "   送信: $f ($(wc -c < "$LOCAL/$f") バイト)"
done

echo "== 3. 公開確認 =="
sleep 2
for u in \
  "https://leit-on.jp/ai-shain/" \
  "https://leit-on.jp/ai-shain/privacy.html" \
  "https://leit-on.jp/ai-shain/assets/leiton-logo.png"
do
  code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 20 "$u")
  echo "   $code  $u"
done
echo "完了。問題があれば $BACKUP/ の ai-shain_*_$STAMP.html を戻してください。"
