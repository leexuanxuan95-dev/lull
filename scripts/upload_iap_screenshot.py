#!/usr/bin/env python3
"""Upload the IAP review screenshot for com.atrium.lull.lifetime.

3-step ASC process:
  1) POST  /v1/inAppPurchaseAppStoreReviewScreenshots  → reservation w/ uploadOps
  2) PUT each upload op's URL with the file bytes
  3) PATCH the reservation with sourceFileChecksum + uploaded=True
"""
import os, time, jwt, urllib.request, urllib.error, json, sys, hashlib, mimetypes

PRODUCT_ID = "com.atrium.lull.lifetime"
SCREENSHOT = "/Users/augis/Desktop/toos/14_LULL/fastlane/screenshots/en-US/iPhone_69_05_paywall.png"

def make_token():
    key = open(os.environ["ASC_KEY_PATH"]).read()
    n = int(time.time())
    return jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": n, "exp": n + 600,
         "aud": "appstoreconnect-v1"},
        key, "ES256",
        headers={"kid": os.environ["ASC_KEY_ID"]}
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
        return e.code, json.loads((e.read().decode("utf-8") or "{}"))

# Look up IAP
APP_ID = os.environ["APP_ID"]
status, body = asc("GET", f"/v1/apps/{APP_ID}/inAppPurchasesV2?limit=200")
matches = [d for d in body["data"] if d["attributes"]["productId"] == PRODUCT_ID]
iap_id = matches[0]["id"]

# Read the screenshot
with open(SCREENSHOT, "rb") as f:
    data = f.read()
filesize = len(data)
filename = os.path.basename(SCREENSHOT)
md5 = hashlib.md5(data).hexdigest()
print(f"Screenshot: {filename}  {filesize:,} bytes  md5={md5}")

# 1) Create reservation
print("Creating reservation…")
status, body = asc("POST", "/v1/inAppPurchaseAppStoreReviewScreenshots", body={
    "data": {
        "type": "inAppPurchaseAppStoreReviewScreenshots",
        "attributes": {
            "fileName": filename,
            "fileSize": filesize
        },
        "relationships": {
            "inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}
        }
    }
})
if status not in (200, 201):
    print(f"❌ HTTP {status}: {json.dumps(body, indent=2)[:500]}")
    sys.exit(1)
rid = body["data"]["id"]
ops = body["data"]["attributes"]["uploadOperations"]
print(f"  ✓ Reservation: {rid}  {len(ops)} upload op(s)")

# 2) PUT bytes for each upload op
for i, op in enumerate(ops):
    headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
    method = op["method"]
    url = op["url"]
    chunk = data[op["offset"]: op["offset"] + op["length"]]
    req = urllib.request.Request(url, headers=headers, data=chunk, method=method)
    try:
        with urllib.request.urlopen(req) as r:
            print(f"  ✓ Op {i+1}/{len(ops)}  HTTP {r.status}  {len(chunk):,} bytes")
    except urllib.error.HTTPError as e:
        print(f"  ❌ Op {i+1}/{len(ops)}  HTTP {e.code}  {e.read().decode()[:200]}")
        sys.exit(1)

# 3) Commit
print("Committing reservation…")
status, body = asc("PATCH", f"/v1/inAppPurchaseAppStoreReviewScreenshots/{rid}", body={
    "data": {
        "type": "inAppPurchaseAppStoreReviewScreenshots",
        "id": rid,
        "attributes": {
            "uploaded": True,
            "sourceFileChecksum": md5
        }
    }
})
if status in (200, 201):
    print(f"  ✓ Committed")
else:
    print(f"  ❌ HTTP {status}: {json.dumps(body, indent=2)[:400]}")
    sys.exit(1)

# Final state
status, body = asc("GET", f"/v2/inAppPurchases/{iap_id}?fields[inAppPurchases]=productId,state")
print(f"\nFinal state: {body['data']['attributes']['state']}")
