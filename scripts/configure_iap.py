#!/usr/bin/env python3
"""Configure the already-created IAP com.atrium.lull.lifetime.

Sets:
  - English (US) localization (POST /v1/inAppPurchaseLocalizations)
  - Manual price USA = $99.00, automaticPrices for other 174 territories
    (POST /v1/inAppPurchasePriceSchedules)
  - Availability across all territories (POST /v1/inAppPurchaseAvailabilities)
"""
import os, time, jwt, urllib.request, urllib.error, json, sys

PRODUCT_ID   = "com.atrium.lull.lifetime"
DISPLAY_NAME = "Lull Lifetime"
DESCRIPTION  = "Unlimited stories, all 8 voices, voice clone."  # 45 chars
TARGET_PRICE = "99.00"   # USD

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
            return r.status, (json.loads(txt) if txt else {}), dict(r.headers)
    except urllib.error.HTTPError as e:
        body_txt = e.read().decode("utf-8")
        return e.code, (json.loads(body_txt) if body_txt else {}), {}

# Locate IAP — use the app's IAP list (correct nested endpoint).
APP_ID = os.environ["APP_ID"]
status, body, _ = asc("GET", f"/v1/apps/{APP_ID}/inAppPurchasesV2?limit=200")
matches = [d for d in body.get("data", []) if d["attributes"]["productId"] == PRODUCT_ID]
if not matches:
    print(f"❌ IAP {PRODUCT_ID} not found. Run create_iap.py first.")
    sys.exit(1)
iap_id = matches[0]["id"]
print(f"✓ IAP id: {iap_id}  state={matches[0]['attributes']['state']}")

# 1) Localization (v1 IAP localization, v2 relationship key)
print("\n=== Localization ===")
status, body, _ = asc("GET", f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations")
existing = body.get("data", [])
en_loc = next((l for l in existing if l["attributes"]["locale"] == "en-US"), None)
if en_loc:
    loc_id = en_loc["id"]
    status, body, _ = asc("PATCH", f"/v1/inAppPurchaseLocalizations/{loc_id}", body={
        "data": {"type": "inAppPurchaseLocalizations", "id": loc_id,
                 "attributes": {"name": DISPLAY_NAME, "description": DESCRIPTION}}
    })
    print(f"  PATCH en-US HTTP {status}")
else:
    # The v2 IAP type expects relationship key 'inAppPurchaseV2', not 'inAppPurchase'.
    status, body, _ = asc("POST", "/v1/inAppPurchaseLocalizations", body={
        "data": {
            "type": "inAppPurchaseLocalizations",
            "attributes": {"locale": "en-US", "name": DISPLAY_NAME, "description": DESCRIPTION},
            "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}}
        }
    })
    if status in (200, 201):
        print(f"  ✓ Created en-US: {body['data']['id']}")
    else:
        print(f"  ❌ HTTP {status}: {json.dumps(body, indent=2)[:500]}")

# 2) Price — paginate, prefer exact $99.00, fall back to closest >= $99.00
print("\n=== Pricing ===")
target_pp = None
closest = None
closest_diff = float("inf")
url = f"/v2/inAppPurchases/{iap_id}/pricePoints?filter[territory]=USA&limit=200"
page = 0
while url:
    page += 1
    status, body, _ = asc("GET", url)
    for p in body.get("data", []):
        try:
            price = float(p["attributes"]["customerPrice"])
        except (ValueError, KeyError):
            continue
        if abs(price - 99.00) < 0.005:
            target_pp = p
            break
        # Track closest >= 99
        if price >= 99.00 and (price - 99.00) < closest_diff:
            closest_diff = price - 99.00
            closest = p
    if target_pp:
        break
    nxt = body.get("links", {}).get("next")
    url = nxt.replace("https://api.appstoreconnect.apple.com", "") if nxt else None
    if page > 100:
        break

if not target_pp and closest:
    target_pp = closest
    print(f"  ⚠ No exact $99.00 — using closest >= 99: ${closest['attributes']['customerPrice']}")
if not target_pp:
    print(f"  ❌ No suitable price point across {page} pages.")
    sys.exit(1)
pp_id = target_pp["id"]
print(f"  ✓ USA price point: {pp_id}  customerPrice=${target_pp['attributes']['customerPrice']}  (page {page})")

# Create price schedule — manual price USA, automatic for everywhere else
status, body, _ = asc("POST", "/v1/inAppPurchasePriceSchedules", body={
    "data": {
        "type": "inAppPurchasePriceSchedules",
        "relationships": {
            "inAppPurchase":   {"data": {"type": "inAppPurchases", "id": iap_id}},
            "manualPrices":    {"data": [{"type": "inAppPurchasePrices", "id": "${price1}"}]},
            "baseTerritory":   {"data": {"type": "territories", "id": "USA"}}
        }
    },
    "included": [{
        "type": "inAppPurchasePrices",
        "id": "${price1}",
        "attributes": {"startDate": None, "endDate": None},
        "relationships": {
            "inAppPurchasePricePoint": {"data": {"type": "inAppPurchasePricePoints", "id": pp_id}}
        }
    }]
})
print(f"  Price schedule HTTP {status}")
if status not in (200, 201):
    print(f"    {json.dumps(body, indent=2)[:600]}")

# 3) Availability — all territories
print("\n=== Availability ===")
# Fetch list of all territories
status, body, _ = asc("GET", "/v1/territories?limit=200")
all_territories = [{"type": "territories", "id": t["id"]} for t in body.get("data", [])]
print(f"  Fetched {len(all_territories)} territories")

status, body, _ = asc("POST", "/v1/inAppPurchaseAvailabilities", body={
    "data": {
        "type": "inAppPurchaseAvailabilities",
        "attributes": {"availableInNewTerritories": True},
        "relationships": {
            "inAppPurchase":  {"data": {"type": "inAppPurchases", "id": iap_id}},
            "availableTerritories": {"data": all_territories}
        }
    }
})
print(f"  Availability HTTP {status}")
if status not in (200, 201):
    print(f"    {json.dumps(body, indent=2)[:500]}")

# Final state
status, body, _ = asc("GET", f"/v2/inAppPurchases/{iap_id}?fields[inAppPurchases]=productId,state,name")
print(f"\n=== Final ===")
print(f"  IAP id:     {iap_id}")
print(f"  productId:  {body['data']['attributes']['productId']}")
print(f"  state:      {body['data']['attributes']['state']}")
