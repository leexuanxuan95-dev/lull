#!/usr/bin/env bash
# Lull · archive + upload to ASC.
# Source scripts/env.sh first. Bumps CURRENT_PROJECT_VERSION automatically.
set -euo pipefail

: "${PROJECT_ROOT:?source scripts/env.sh first}"
cd "$PROJECT_ROOT"

# 0) Regenerate Xcode project from project.yml (idempotent, fast)
echo "▶ xcodegen generate"
xcodegen generate >/dev/null

# 1) Bump CURRENT_PROJECT_VERSION (build number) — query existing builds and +1
echo "▶ querying current build numbers from ASC…"
LATEST_BUILD=$(python3 - <<PY
import os, time, jwt, urllib.request, json
key = open(os.environ['ASC_KEY_PATH']).read()
n = int(time.time())
tok = jwt.encode({'iss': os.environ['ASC_ISSUER_ID'], 'iat': n, 'exp': n+600,
                  'aud': 'appstoreconnect-v1'},
                 key, 'ES256', headers={'kid': os.environ['ASC_KEY_ID']})
r = urllib.request.Request(
    f'https://api.appstoreconnect.apple.com/v1/builds?filter[app]={os.environ["APP_ID"]}&sort=-uploadedDate&limit=10',
    headers={'Authorization': f'Bearer {tok}'})
data = json.load(urllib.request.urlopen(r))['data']
nums = []
for b in data:
    try: nums.append(int(b['attributes']['version']))
    except: pass
print(max(nums) if nums else 0)
PY
)
NEW_BUILD=$((LATEST_BUILD + 1))
echo "  latest uploaded build = $LATEST_BUILD  →  new = $NEW_BUILD"

# Patch project.yml in place (sed)
sed -i.bak "s|CURRENT_PROJECT_VERSION: \"[0-9]*\"|CURRENT_PROJECT_VERSION: \"$NEW_BUILD\"|" project.yml
rm -f project.yml.bak
xcodegen generate >/dev/null
echo "  project.yml CURRENT_PROJECT_VERSION → $NEW_BUILD"

# 2) Clean + archive
ARCHIVE_PATH="$BUILD_DIR/Lull.xcarchive"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "▶ xcodebuild archive (Release, manual signing)"
xcodebuild archive \
  -project "$XCODEPROJ" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="$DISTRIBUTION_IDENTITY" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  PROVISIONING_PROFILE_SPECIFIER="$PROVISIONING_PROFILE_NAME" \
  -allowProvisioningUpdates 2>&1 | xcbeautify --quiet || {
    echo "❌ archive failed"
    exit 1
  }

# 3) Export IPA
echo "▶ xcodebuild -exportArchive"
EXPORT_DIR="$BUILD_DIR/export"
mkdir -p "$EXPORT_DIR"
cat > "$BUILD_DIR/export-options.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>teamID</key>
  <string>$TEAM_ID</string>
  <key>signingStyle</key>
  <string>manual</string>
  <key>signingCertificate</key>
  <string>$DISTRIBUTION_IDENTITY</string>
  <key>provisioningProfiles</key>
  <dict>
    <key>$BUNDLE_ID</key>
    <string>$PROVISIONING_PROFILE_NAME</string>
  </dict>
  <key>uploadSymbols</key>
  <true/>
  <key>stripSwiftSymbols</key>
  <true/>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$BUILD_DIR/export-options.plist" 2>&1 | xcbeautify --quiet

IPA="$EXPORT_DIR/Lull.ipa"
if [[ ! -f "$IPA" ]]; then
  echo "❌ export failed — no IPA at $IPA"
  ls -la "$EXPORT_DIR"
  exit 1
fi
echo "  IPA: $(du -h "$IPA" | cut -f1)  $IPA"

# 4) Upload via altool
echo "▶ altool upload"
xcrun altool --upload-app \
  -f "$IPA" \
  -t ios \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID" 2>&1 | tee "$BUILD_DIR/altool.log"

echo ""
echo "✅ Build $NEW_BUILD uploaded. ASC processing usually takes 5–15 min."
echo "   Poll with: python3 scripts/wait_for_build.py"
