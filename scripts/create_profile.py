#!/usr/bin/env python3
"""Create the App Store distribution provisioning profile for com.atrium.lull.

Profile name: "com.atrium.lull AppStore" (matches PROVISIONING_PROFILE_SPECIFIER
in project.yml). Type: IOS_APP_STORE.

After creation, the profile is downloaded as a base64 blob and written to:
  ~/Library/MobileDevice/Provisioning Profiles/com_atrium_lull_AppStore.mobileprovision
xcodebuild auto-discovers .mobileprovision files there.
"""
import os, time, jwt, urllib.request, urllib.error, json, sys, base64, pathlib

PROFILE_NAME = "com.atrium.lull AppStore"
PROFILE_TYPE = "IOS_APP_STORE"
BUNDLE_ID    = "com.atrium.lull"

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

# 1) Find the bundleId resource
status, body = asc("GET", f"/v1/bundleIds?filter[identifier]={BUNDLE_ID}")
matches = [d for d in body["data"] if d["attributes"]["identifier"] == BUNDLE_ID]
if not matches:
    print(f"❌ Bundle ID {BUNDLE_ID} not registered. Run register_bundle_id.py first.")
    sys.exit(1)
bid_resource_id = matches[0]["id"]
print(f"✓ Bundle ID resource: {bid_resource_id}")

# 2) Find the Apple Distribution certificate
status, body = asc("GET", "/v1/certificates?filter[certificateType]=DISTRIBUTION&limit=20")
certs = body.get("data", [])
if not certs:
    print("❌ No Apple Distribution cert found. Create one in Xcode → Settings → Accounts → Manage Certificates.")
    sys.exit(1)
# Prefer the longest-lived one (closest expiration in the future)
certs.sort(key=lambda c: c["attributes"].get("expirationDate", ""), reverse=True)
cert_resource_id = certs[0]["id"]
print(f"✓ Distribution cert: {cert_resource_id}  (sn={certs[0]['attributes'].get('serialNumber','?')})")

# 3) Check if profile already exists
status, body = asc("GET", f"/v1/profiles?filter[name]={urllib.request.quote(PROFILE_NAME)}&include=bundleId,certificates")
for p in body.get("data", []):
    if p["attributes"]["name"] == PROFILE_NAME:
        print(f"ℹ Profile already exists: {p['id']}  state={p['attributes']['profileState']}")
        # Re-download to ensure local copy is current
        prof_id = p["id"]
        break
else:
    # 4) Create
    print(f"Creating profile '{PROFILE_NAME}'…")
    status, body = asc("POST", "/v1/profiles", body={
        "data": {
            "type": "profiles",
            "attributes": {
                "name": PROFILE_NAME,
                "profileType": PROFILE_TYPE
            },
            "relationships": {
                "bundleId":     {"data": {"type": "bundleIds",     "id": bid_resource_id}},
                "certificates": {"data": [{"type": "certificates", "id": cert_resource_id}]}
            }
        }
    })
    if status not in (200, 201):
        print(f"❌ Failed (HTTP {status}):")
        print(json.dumps(body, indent=2))
        sys.exit(1)
    prof_id = body["data"]["id"]
    print(f"✓ Created profile: {prof_id}")

# 5) Fetch the profile content (base64 .mobileprovision blob)
status, body = asc("GET", f"/v1/profiles/{prof_id}?fields[profiles]=profileContent,name,uuid,profileState,expirationDate")
attr = body["data"]["attributes"]
content_b64 = attr.get("profileContent")
if not content_b64:
    print("❌ Profile has no content field — Apple may still be issuing it. Try again in 30s.")
    sys.exit(1)
print(f"✓ Profile state={attr['profileState']}, expires={attr['expirationDate']}, uuid={attr['uuid']}")

# 6) Save to ~/Library/MobileDevice/Provisioning Profiles/<UUID>.mobileprovision
dest_dir = pathlib.Path.home() / "Library" / "MobileDevice" / "Provisioning Profiles"
dest_dir.mkdir(parents=True, exist_ok=True)
dest = dest_dir / f"{attr['uuid']}.mobileprovision"
dest.write_bytes(base64.b64decode(content_b64))
print(f"✓ Wrote {dest}  ({dest.stat().st_size:,} bytes)")
