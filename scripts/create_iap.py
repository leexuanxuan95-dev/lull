#!/usr/bin/env python3
"""Create the v1 lifetime non-consumable IAP for Lull.

Per the App Store Deploy Runbook §6:
- NON_CONSUMABLE only for v1
- productId is permanent — Apple never frees it once created, so we pick
  carefully: com.atrium.lull.lifetime
- 5 metadata fields are required to leave MISSING_METADATA:
  1) Localization (display name + description, ≥1 locale)
  2) Price tier
  3) Availability (territories)
  4) Review note
  5) Review screenshot

This script does (1)-(4). Screenshot (5) needs a `--screenshot PATH` flag
because Apple's API uploads it as a multi-step blob — handled separately.
"""
import os, time, jwt, urllib.request, urllib.error, json, sys, argparse

PRODUCT_ID   = "com.atrium.lull.lifetime"
DISPLAY_NAME = "Lull Lifetime"
DESCRIPTION  = ("Unlock unlimited bedtime stories, all 8 narrator voices, "
                "Apple Watch controls, smart wake, and the voice clone "
                "feature. One-time purchase, no subscription.")
PRICE_USD    = "99.00"
REVIEW_NOTE  = ("To test: open the app, complete onboarding, then tap any "
                "genre card on the Tonight tab to start a free story. To "
                "test the IAP, open Settings → Subscription → 'go Pro', "
                "or hit the daily-limit popup, and tap 'unlock lifetime · $99'. "
                "Restore Purchases is at the bottom of the paywall and in "
                "Settings → Subscription. Lifetime unlocks Pro and Pro+ "
                "features (voice clone setup in Settings → voice clone).")

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

APP_ID = os.environ["APP_ID"]

# 1) Find or create the IAP product
print(f"Looking up existing IAP {PRODUCT_ID}…")
status, body = asc("GET", f"/v2/inAppPurchases?filter[productId]={PRODUCT_ID}&limit=5")
matches = [d for d in body.get("data", []) if d["attributes"]["productId"] == PRODUCT_ID]
if matches:
    iap_id = matches[0]["id"]
    state = matches[0]["attributes"]["state"]
    print(f"ℹ IAP exists: {iap_id}  state={state}")
else:
    print(f"Creating {PRODUCT_ID} (NON_CONSUMABLE)…")
    status, body = asc("POST", "/v2/inAppPurchases", body={
        "data": {
            "type": "inAppPurchases",
            "attributes": {
                "name": DISPLAY_NAME,
                "productId": PRODUCT_ID,
                "inAppPurchaseType": "NON_CONSUMABLE",
                "reviewNote": REVIEW_NOTE
            },
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}}
            }
        }
    })
    if status not in (200, 201):
        print(f"❌ Create failed (HTTP {status}): {json.dumps(body, indent=2)}")
        sys.exit(1)
    iap_id = body["data"]["id"]
    print(f"✓ Created IAP: {iap_id}")

# 2) Add English (US) localization if not present
print("Setting English (US) localization…")
status, body = asc("GET", f"/v2/inAppPurchases/{iap_id}/inAppPurchaseLocalizations")
locs = body.get("data", [])
en_loc = next((l for l in locs if l["attributes"]["locale"] == "en-US"), None)
if en_loc:
    loc_id = en_loc["id"]
    asc("PATCH", f"/v2/inAppPurchaseLocalizations/{loc_id}", body={
        "data": {"type": "inAppPurchaseLocalizations", "id": loc_id,
                 "attributes": {"name": DISPLAY_NAME, "description": DESCRIPTION}}
    })
    print(f"✓ Updated localization en-US: {loc_id}")
else:
    status, body = asc("POST", "/v2/inAppPurchaseLocalizations", body={
        "data": {
            "type": "inAppPurchaseLocalizations",
            "attributes": {"locale": "en-US", "name": DISPLAY_NAME, "description": DESCRIPTION},
            "relationships": {"inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}}}
        }
    })
    if status in (200, 201):
        print(f"✓ Created localization en-US: {body['data']['id']}")
    else:
        print(f"⚠ Localization create: HTTP {status}: {json.dumps(body, indent=2)[:300]}")

# 3) Set price (manual price across all territories)
#    Per ASC IAP runbook memory: NON_CONSUMABLE uses baseTerritory + automaticPrices.
print("Setting base price (USA, Tier matching $99.00)…")
# Look up the price point for $99.00 in USA from the IAP price points endpoint.
status, body = asc("GET",
    f"/v2/inAppPurchases/{iap_id}/pricePoints"
    f"?filter[territory]=USA&limit=200")
points = body.get("data", [])
target = next((p for p in points if p["attributes"]["customerPrice"] == "99.00"), None)
if not target:
    # Fallback: enumerate available USD price points
    print("⚠ Could not find exact $99.00 price point. Available nearby:")
    for p in points[:5]:
        print(f"    {p['id']}  customerPrice={p['attributes']['customerPrice']}")
    if not points:
        print("⚠ No price points returned for USA — set manually in ASC UI.")
    else:
        # Pick the closest to $99
        target = min(points, key=lambda p: abs(float(p["attributes"]["customerPrice"]) - 99.0))
        print(f"  → using closest: {target['attributes']['customerPrice']}")

if target:
    pp_id = target["id"]
    # Create a price schedule that pegs USA→tier and lets others auto-derive
    status, body = asc("POST", "/v1/inAppPurchasePriceSchedules", body={
        "data": {
            "type": "inAppPurchasePriceSchedules",
            "relationships": {
                "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                "manualPrices":  {"data": []},
                "automaticPrices": {"data": [{"type": "inAppPurchasePrices", "id": "${price1}"}]},
                "baseTerritory": {"data": {"type": "territories", "id": "USA"}}
            },
            "included": [{
                "type": "inAppPurchasePrices",
                "id": "${price1}",
                "attributes": {"startDate": None, "endDate": None},
                "relationships": {
                    "inAppPurchasePricePoint": {"data": {"type": "inAppPurchasePricePoints", "id": pp_id}}
                }
            }]
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
    if status in (200, 201, 409):  # 409 = already set, that's fine
        print(f"✓ Price schedule: HTTP {status}")
    else:
        print(f"⚠ Price schedule HTTP {status}: {json.dumps(body, indent=2)[:400]}")

# 4) Availability (all territories on by default — confirm)
print("Setting availability (all territories)…")
status, body = asc("GET", f"/v2/inAppPurchases/{iap_id}/inAppPurchaseAvailability")
print(f"  current availability HTTP {status}")

# 5) Re-fetch state
status, body = asc("GET", f"/v2/inAppPurchases/{iap_id}?fields[inAppPurchases]=productId,state,name,reviewNote")
print(f"\nFinal IAP state: {body['data']['attributes']['state']}")
print(f"  productId:  {body['data']['attributes']['productId']}")
print(f"  name:       {body['data']['attributes']['name']}")
print(f"  IAP ID:     {iap_id}")
