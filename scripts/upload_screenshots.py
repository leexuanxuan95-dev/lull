#!/usr/bin/env python3
"""Upload the 5 iPhone 6.9" screenshots to the v1.0 version localization."""
import os, time, jwt, urllib.request, urllib.error, json, sys, hashlib, glob

DISPLAY_TYPE = "APP_IPHONE_67"   # 6.7"/6.9" Pro Max class — same 1320×2868 res
LOCALE       = "en-US"
SCREENSHOT_GLOB = "/Users/augis/Desktop/toos/14_LULL/fastlane/screenshots/en-US/iPhone_69_*.png"

def make_token():
    key = open(os.environ["ASC_KEY_PATH"]).read()
    n = int(time.time())
    return jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": n, "exp": n + 600,
         "aud": "appstoreconnect-v1"},
        key, "ES256", headers={"kid": os.environ["ASC_KEY_ID"]}
    )

def asc(method, path, body=None):
    url = f"https://api.appstoreconnect.apple.com{path}"
    headers = {"Authorization": f"Bearer {make_token()}"}
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, headers=headers, data=data, method=method)
    try:
        with urllib.request.urlopen(req) as r:
            txt = r.read().decode("utf-8")
            return r.status, (json.loads(txt) if txt else {})
    except urllib.error.HTTPError as e:
        body_txt = e.read().decode("utf-8")
        try:
            return e.code, json.loads(body_txt)
        except json.JSONDecodeError:
            return e.code, {"raw": body_txt}

def must(method, path, body=None, ok=(200, 201)):
    s, b = asc(method, path, body)
    if s not in ok:
        print(f"❌ {method} {path} → HTTP {s}")
        print(json.dumps(b, indent=2)[:600])
        sys.exit(1)
    return b

APP_ID = os.environ["APP_ID"]

# Find the inflight version
v = must("GET", f"/v1/apps/{APP_ID}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION&limit=1")
if not v["data"]:
    print("❌ no inflight version")
    sys.exit(1)
ver_id = v["data"][0]["id"]

# Get en-US localization
locs = must("GET", f"/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations")
loc_id = next(l["id"] for l in locs["data"] if l["attributes"]["locale"] == LOCALE)
print(f"✓ version {ver_id}  localization {loc_id}")

# Find or create screenshot set for 6.9"
sets = must("GET", f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets")
existing_set = next((s for s in sets["data"]
                     if s["attributes"]["screenshotDisplayType"] == DISPLAY_TYPE),
                    None)
if existing_set:
    set_id = existing_set["id"]
    print(f"  using existing set: {set_id}")
    # Delete existing screenshots so the upload is idempotent
    inner = must("GET", f"/v1/appScreenshotSets/{set_id}/appScreenshots")
    for s in inner["data"]:
        asc("DELETE", f"/v1/appScreenshots/{s['id']}")
        print(f"  deleted prior screenshot {s['id']}")
else:
    body = must("POST", "/v1/appScreenshotSets", body={
        "data": {
            "type": "appScreenshotSets",
            "attributes": {"screenshotDisplayType": DISPLAY_TYPE},
            "relationships": {
                "appStoreVersionLocalization": {
                    "data": {"type": "appStoreVersionLocalizations", "id": loc_id}
                }
            }
        }
    })
    set_id = body["data"]["id"]
    print(f"  created set: {set_id}")

# Upload each screenshot
files = sorted(glob.glob(SCREENSHOT_GLOB))
if not files:
    print(f"❌ no screenshots match {SCREENSHOT_GLOB}")
    sys.exit(1)
print(f"  uploading {len(files)} screenshot(s)…")

uploaded_ids = []
for path in files:
    data = open(path, "rb").read()
    md5 = hashlib.md5(data).hexdigest()
    fname = os.path.basename(path)
    print(f"\n• {fname}  {len(data):,} bytes  md5={md5}")

    # 1) reservation
    body = must("POST", "/v1/appScreenshots", body={
        "data": {
            "type": "appScreenshots",
            "attributes": {"fileSize": len(data), "fileName": fname},
            "relationships": {
                "appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}
            }
        }
    })
    sid = body["data"]["id"]
    ops = body["data"]["attributes"]["uploadOperations"]
    print(f"  reservation {sid}, {len(ops)} op(s)")

    # 2) upload bytes
    for i, op in enumerate(ops):
        headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        chunk = data[op["offset"]: op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], headers=headers, data=chunk, method=op["method"])
        with urllib.request.urlopen(req) as r:
            print(f"  op {i+1}/{len(ops)}  HTTP {r.status}  {len(chunk):,} bytes")

    # 3) commit
    must("PATCH", f"/v1/appScreenshots/{sid}", body={
        "data": {"type": "appScreenshots", "id": sid,
                 "attributes": {"uploaded": True, "sourceFileChecksum": md5}}
    })
    uploaded_ids.append(sid)
    print(f"  ✓ committed")

# Reorder to match filename sort
print(f"\n▶ ordering set: {len(uploaded_ids)} screenshots")
must("PATCH", f"/v1/appScreenshotSets/{set_id}/relationships/appScreenshots", body={
    "data": [{"type": "appScreenshots", "id": sid} for sid in uploaded_ids]
}, ok=(200, 201, 204))
print("✅ all screenshots uploaded + ordered.")
