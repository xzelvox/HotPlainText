#!/bin/zsh
# HotPlainText.app を作る(このフォルダで ./build.sh)
set -euo pipefail
cd "$(dirname "$0")"
APP=HotPlainText.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# macOS 14 以降向けと明示する(指定しないと、ビルドした Mac の SDK の版が「この版以降」になり、
# SDK より古い macOS では開けなくなる)。Info.plist の LSMinimumSystemVersion とそろえる
swiftc -O -target "$(uname -m)-apple-macos14.0" -o "$APP/Contents/MacOS/HotPlainText" main.swift
cp AppIcon.icns "$APP/Contents/Resources/"   # アイコン(make_icon.swift で描いたもの)
cp -R *.lproj "$APP/Contents/Resources/"     # 言語ファイル(英・日・中・韓・独・仏・西)
cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>HotPlainText</string>
  <key>CFBundleDisplayName</key><string>HotPlainText</string>
  <key>CFBundleIdentifier</key><string>io.github.xzelvox.HotPlainText</string>
  <key>CFBundleExecutable</key><string>HotPlainText</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleLocalizations</key>
  <array><string>en</string><string>ja</string><string>zh-Hans</string><string>ko</string><string>de</string><string>fr</string><string>es</string></array>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF
# 自分専用の証明書で署名する。作り直しても Mac が同じアプリと見なすので、
# アクセシビリティの許可が外れない。証明書がなければ、その場の署名にする
KCDIR="$HOME/.config/plaintext-signing"
if [[ -f "$KCDIR/signing.keychain-db" && -f "$KCDIR/keychain-pass" ]]; then
  security unlock-keychain -p "$(cat "$KCDIR/keychain-pass")" "$KCDIR/signing.keychain-db"
  codesign --force --keychain "$KCDIR/signing.keychain-db" --sign "PlainText Local Signing" "$APP"
else
  echo "注意: 署名用の証明書がないので、その場の署名にします(作り直すたびに許可が外れます)"
  codesign --force --sign - "$APP"
fi
echo "できました: $(pwd)/$APP"
