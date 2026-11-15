#!/bin/zsh
# HotPlainText をビルドして /Applications に入れ、開く(このフォルダで ./install.sh)。
# 前の HotPlainText があれば終了させて消す。
# その場の署名のときは、前のアクセシビリティの許可も消す。その場の署名は作り直すたびに
# 別のアプリと見なされ、一覧で ON のままでも前の許可は効かないため。
set -euo pipefail
cd "$(dirname "$0")"
ID=io.github.xzelvox.HotPlainText
DEST=/Applications/HotPlainText.app
ME=$(id -u)   # 自分が動かしているものだけを対象にする

./build.sh

# 動いていれば終了させ、終わるのを待つ(最大 5 秒)。終わらなければ入れ替えない
pkill -U "$ME" -x HotPlainText || true
for i in {1..50}; do
  pgrep -U "$ME" -x HotPlainText >/dev/null || break
  sleep 0.1
done
if pgrep -U "$ME" -x HotPlainText >/dev/null; then
  echo "HotPlainText が終了しませんでした。メニューから「終了」してから、もう一度動かしてください。" >&2
  exit 1
fi

rm -rf "$DEST"
cp -R HotPlainText.app "$DEST"

sig=$(codesign -dv "$DEST" 2>&1)   # 署名を読めなければ、ここで止まる
if print -r -- "$sig" | grep -Fxq "Signature=adhoc"; then
  if tccutil reset Accessibility "$ID"; then
    echo "前のアクセシビリティの許可を消しました。開いたら、案内どおりに付け直してください。"
  else
    echo "前のアクセシビリティの許可を消せませんでした。システム設定のアクセシビリティの一覧に HotPlainText があれば「−」で消してから、案内どおりに付け直してください。" >&2
  fi
fi

open "$DEST"
echo "入れました: $DEST"
