#!/usr/bin/env python3
"""Register bundle ID com.atrium.lull at developer.apple.com via ASC API.

Once this completes, the bundle ID will appear in the ASC "New App" dropdown.
"""
import os, time, jwt, urllib.request, urllib.error, json, sys

BUNDLE_ID = "com.atrium.lull"
NAME = "Lull"

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
            return r.status, json.loads(txt) if txt else {}
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode("utf-8") or "{}")

# 1) Check if already registered
status, body = asc("GET", f"/v1/bundleIds?filter[identifier]={BUNDLE_ID}&limit=5")
existing = [d for d in body.get("data", []) if d["attributes"]["identifier"] == BUNDLE_ID]
if existing:
    print(f"✓ Bundle ID already registered: {BUNDLE_ID}  (id={existing[0]['id']})")
    sys.exit(0)

# 2) Register
print(f"Registering {BUNDLE_ID}…")
status, body = asc("POST", "/v1/bundleIds", body={
    "data": {
        "type": "bundleIds",
        "attributes": {
            "identifier": BUNDLE_ID,
            "name": NAME,
            "platform": "IOS"
        }
    }
})

if status in (200, 201):
    print(f"✓ Created: {BUNDLE_ID}  (id={body['data']['id']})")
else:
    print(f"❌ Failed (HTTP {status}):")
    print(json.dumps(body, indent=2))
    sys.exit(1)
