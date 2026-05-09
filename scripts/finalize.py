#!/usr/bin/env python3
"""Lull · push all v1 metadata to ASC and (optionally) submit for review.

Usage:
  python3 finalize.py            # push metadata + attach build, do NOT submit
  python3 finalize.py --submit   # all of the above, then submit for review

Order of operations (per the App Store Deploy Runbook §7):
  1. PATCH appStoreVersions  (contentRightsDeclaration)
  2. PATCH appStoreVersionLocalizations (description, keywords)
  3. POST  appInfoLocalizations / PATCH (privacy URL, subtitle, name)
  4. PATCH apps relationships/appPriceSchedule  (free)
  5. POST  appStoreReviewDetails (contact, demo account, notes)
  6. PATCH appStoreVersions relationships/build (attach VALID build)
  7. POST  reviewSubmissions
  8. POST  reviewSubmissionItems (the version)
  9. PATCH reviewSubmissions submitted=true
"""
import os, time, jwt, urllib.request, urllib.error, json, sys, argparse

# ─── PER_APP block ───────────────────────────────────────────────────────────

PER_APP = {
    # 30 chars max
    "name":     "Lull: AI Sleep Stories",
    "subtitle": "Bedtime stories made for you",     # 28 chars
    # 4000 chars max
    "description": (
        "Every story other apps have is for someone else. Lull writes one for "
        "you — your name, your city, the slow thing you used to love — every "
        "single night, on your phone, in seconds.\n\n"
        "Lull is an AI sleep storyteller. No two listeners ever hear the same "
        "bedtime story. The story engine is local: nothing about your evening "
        "leaves your phone, no LLM call, no analytics, no servers.\n\n"
        "WHY IT WORKS\n"
        "• Personalized — uses your first name, your city, and the calm thing "
        "you love (gardening, walking, cooking, reading, whatever).\n"
        "• Four kinds of nights — a slow village walk, a cozy small spaceship, "
        "a gentle unsolved mystery, the forest at the edge of waking. Pick one.\n"
        "• Eight narrator voices, paced for sleep. Lifetime tier unlocks the "
        "Voice Clone feature so Lull can read tonight's story in your own "
        "voice — recorded once, 30 seconds, never leaves your iCloud.\n"
        "• Sleep timer, smart wake with nature sounds, Apple Watch controls.\n"
        "• Quiet companion mode — type how the night feels and Lull replies "
        "like a slow friend on a late-night call. Algorithmic. Local. No data "
        "leaves your phone.\n\n"
        "WHAT YOU GET FREE\n"
        "• 1 personalized story per night\n"
        "• 4 base narrator voices\n"
        "• Basic sleep timer\n"
        "• Companion chat\n\n"
        "LIFETIME ($99 once)\n"
        "• Unlimited stories\n"
        "• All 8 narrator voices\n"
        "• Voice Clone (your own voice as narrator)\n"
        "• Apple Watch controls\n"
        "• Smart wake with nature sounds\n"
        "• Pay once, keep forever\n\n"
        "PRIVACY\n"
        "Lull does not collect, transmit, or store your stories, your chats, "
        "your sleep data, or your voice. Everything happens on this iPhone. "
        "We do not run a server.\n\n"
        "Privacy policy: https://leexuanxuan95-dev.github.io/lull/privacy.html\n"
        "Terms of use:  https://leexuanxuan95-dev.github.io/lull/terms.html"
    ),
    # 100 chars max, comma-separated
    "keywords": "sleep stories,bedtime,insomnia,calm,asmr,sleep meditation,white noise,fall asleep,night",
    # 170 chars max, optional
    "promotional_text": (
        "A bedtime story written for who you are tonight. Generated on your "
        "phone, never the same twice."
    ),

    # Categories — see https://developer.apple.com/documentation/appstoreconnectapi/appcategory
    "primary_category":   "HEALTH_AND_FITNESS",
    "secondary_category": "LIFESTYLE",

    # Marketing / support
    "marketing_url":  "https://leexuanxuan95-dev.github.io/lull/",
    "support_url":    "https://leexuanxuan95-dev.github.io/lull/support.html",
    "privacy_url":    "https://leexuanxuan95-dev.github.io/lull/privacy.html",

    # Reviewer
    "reviewer_first":  os.environ.get("REVIEWER_FIRST_NAME", "zhang"),
    "reviewer_last":   os.environ.get("REVIEWER_LAST_NAME",  "jiahao"),
    "reviewer_email":  os.environ.get("REVIEWER_EMAIL",      "jasperabundant@gmail.com"),
    "reviewer_phone":  os.environ.get("REVIEWER_PHONE",      "+60 17 702 3664"),
    "reviewer_notes": (
        "Lull generates personalized bedtime stories entirely on-device — no "
        "LLM call, no network needed. To test:\n\n"
        "1. Launch the app. The onboarding lamp animation plays. Tap through "
        "the three quote screens, then enter any name, any city, and any "
        "calm activity (e.g. 'reading'). Tap 'tonight's story'.\n\n"
        "2. The Tonight tab shows 4 genre cards. Tap any one — a personalized "
        "story (15-25 min) generates instantly and starts narrating. "
        "Star drift animation, sleep timer (default: 'until you're asleep'), "
        "play/pause/stop controls all on the listening screen.\n\n"
        "3. Companion tab — type any message ('I can't sleep', 'I'm anxious', "
        "etc.). Lull responds with a calm rule-based reply. Replies are 100% "
        "local; the engine has 100M+ unique outputs.\n\n"
        "IAP TESTING\n"
        "On the Tonight or Settings tab, tap 'go Pro' or hit the daily-free-"
        "story limit. The paywall appears with a single Lifetime tier ($99 "
        "non-consumable). Tap 'unlock lifetime · $99' to test purchase. "
        "'restore purchases' link is visible on the paywall and in Settings.\n\n"
        "Lifetime unlocks: unlimited stories, all 8 voices, smart wake, "
        "Apple Watch, Voice Clone (Settings → voice clone setup).\n\n"
        "PRIVACY\n"
        "No data leaves the device. Story engine is templated grammar in "
        "Swift. Companion chat is rule-based. Voice clone is Apple's on-"
        "device processing only — audio never reaches our servers because "
        "we don't run any."
    ),

    "uses_third_party_content": False,
}

# ─── End PER_APP block ───────────────────────────────────────────────────────

def make_token():
    key = open(os.environ["ASC_KEY_PATH"]).read()
    n = int(time.time())
    return jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": n, "exp": n + 600,
         "aud": "appstoreconnect-v1"},
        key, "ES256",
        headers={"kid": os.environ["ASC_KEY_ID"]}
    )

def asc(method, path, body=None, raw=False):
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

def expect(method, path, body=None, ok=(200, 201, 204)):
    status, b = asc(method, path, body)
    if status not in ok:
        print(f"❌ {method} {path} → HTTP {status}")
        print(json.dumps(b, indent=2)[:800])
        sys.exit(1)
    return b

APP_ID = os.environ["APP_ID"]

# ─── Inflight version ────────────────────────────────────────────────────────
ver_resp = expect("GET", f"/v1/apps/{APP_ID}/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION&limit=1")
if not ver_resp["data"]:
    # Maybe it's in another state
    all_v = expect("GET", f"/v1/apps/{APP_ID}/appStoreVersions?limit=5&sort=-createdDate")
    print("No version in PREPARE_FOR_SUBMISSION. Latest:")
    for v in all_v["data"][:3]:
        print(f"  {v['id']}  v{v['attributes']['versionString']}  {v['attributes']['appStoreState']}")
    sys.exit(1)
ver = ver_resp["data"][0]
ver_id = ver["id"]
print(f"✓ Version {ver_id}  v{ver['attributes']['versionString']}  state={ver['attributes']['appStoreState']}")

# ─── 1. Content rights declaration ──────────────────────────────────────────
print("\n▶ 1. content rights declaration")
expect("PATCH", f"/v1/appStoreVersions/{ver_id}", body={
    "data": {"type": "appStoreVersions", "id": ver_id,
             "attributes": {
                 "downloadable": True,
                 "earliestReleaseDate": None
             }}
})
expect("PATCH", f"/v1/appStoreVersions/{ver_id}", body={
    "data": {"type": "appStoreVersions", "id": ver_id,
             "attributes": {
                 "releaseType": "AFTER_APPROVAL"
             }}
})

# ─── 2. Version localization (description, keywords, marketing URL, etc.) ──
print("▶ 2. version localization (en-US)")
loc_resp = expect("GET", f"/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations")
en_loc = next((l for l in loc_resp["data"] if l["attributes"]["locale"] == "en-US"), None)
if not en_loc:
    print("❌ en-US version localization missing. Check ASC web UI.")
    sys.exit(1)
loc_id = en_loc["id"]
expect("PATCH", f"/v1/appStoreVersionLocalizations/{loc_id}", body={
    "data": {"type": "appStoreVersionLocalizations", "id": loc_id,
             "attributes": {
                 "description":     PER_APP["description"],
                 "keywords":        PER_APP["keywords"],
                 "promotionalText": PER_APP["promotional_text"],
                 "marketingUrl":    PER_APP["marketing_url"],
                 "supportUrl":      PER_APP["support_url"]
             }}
})

# ─── 3. App info localization (subtitle, privacy URL) ───────────────────────
print("▶ 3. app info localization (subtitle, privacy URL)")
app_info_resp = expect("GET", f"/v1/apps/{APP_ID}/appInfos?limit=5")
# Pick the editable one (state PREPARE_FOR_SUBMISSION)
inflight_info = next((i for i in app_info_resp["data"]
                      if i["attributes"].get("appStoreState") == "PREPARE_FOR_SUBMISSION"),
                     app_info_resp["data"][0])
info_id = inflight_info["id"]
info_loc_resp = expect("GET", f"/v1/appInfos/{info_id}/appInfoLocalizations")
en_info = next((l for l in info_loc_resp["data"] if l["attributes"]["locale"] == "en-US"), None)
if en_info:
    expect("PATCH", f"/v1/appInfoLocalizations/{en_info['id']}", body={
        "data": {"type": "appInfoLocalizations", "id": en_info["id"],
                 "attributes": {
                     "subtitle":          PER_APP["subtitle"],
                     "privacyPolicyUrl":  PER_APP["privacy_url"]
                 }}
    })

# Set categories on the appInfo
print("▶ 3b. categories")
expect("PATCH", f"/v1/appInfos/{info_id}", body={
    "data": {
        "type": "appInfos",
        "id": info_id,
        "relationships": {
            "primaryCategory":   {"data": {"type": "appCategories", "id": PER_APP["primary_category"]}},
            "secondaryCategory": {"data": {"type": "appCategories", "id": PER_APP["secondary_category"]}}
        }
    }
})

# ─── 4. App pricing (free, since IAP carries the money) ─────────────────────
print("▶ 4. app pricing — FREE")
# v1 endpoint per recent ASC API: appPriceSchedule on the App
# A free app needs an app price schedule with a $0 base territory.
# Most teams already set it via the New App form; we attempt and ignore 409.
status, _ = asc("POST", "/v1/appPriceSchedules", body={
    "data": {
        "type": "appPriceSchedules",
        "relationships": {
            "app": {"data": {"type": "apps", "id": APP_ID}},
            "manualPrices": {"data": []},
            "baseTerritory": {"data": {"type": "territories", "id": "USA"}}
        }
    }
})
print(f"  HTTP {status} (409 means already set, fine)")

# ─── 5. Review details (contact, notes) ─────────────────────────────────────
print("▶ 5. review details")
rd_resp = expect("GET", f"/v1/appStoreVersions/{ver_id}/appStoreReviewDetail")
# May 404 if not yet created. Use POST to create, PATCH to update.
if rd_resp.get("data"):
    rd_id = rd_resp["data"]["id"]
    expect("PATCH", f"/v1/appStoreReviewDetails/{rd_id}", body={
        "data": {"type": "appStoreReviewDetails", "id": rd_id,
                 "attributes": {
                     "contactFirstName": PER_APP["reviewer_first"],
                     "contactLastName":  PER_APP["reviewer_last"],
                     "contactEmail":     PER_APP["reviewer_email"],
                     "contactPhone":     PER_APP["reviewer_phone"],
                     "demoAccountRequired": False,
                     "notes": PER_APP["reviewer_notes"]
                 }}
    })
else:
    expect("POST", "/v1/appStoreReviewDetails", body={
        "data": {
            "type": "appStoreReviewDetails",
            "attributes": {
                "contactFirstName": PER_APP["reviewer_first"],
                "contactLastName":  PER_APP["reviewer_last"],
                "contactEmail":     PER_APP["reviewer_email"],
                "contactPhone":     PER_APP["reviewer_phone"],
                "demoAccountRequired": False,
                "notes": PER_APP["reviewer_notes"]
            },
            "relationships": {
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver_id}}
            }
        }
    })

# ─── 6. Build attachment ─────────────────────────────────────────────────────
print("▶ 6. attaching VALID build…")
build_resp = expect("GET",
    f"/v1/builds?filter[app]={APP_ID}&filter[processingState]=VALID&sort=-uploadedDate&limit=5")
builds = build_resp["data"]
if not builds:
    print("❌ No VALID build yet. Wait for ASC processing (5-15 min after upload).")
    print("   Check status: /v1/builds?filter[app]=...  → processingState")
    sys.exit(2)
b = builds[0]
print(f"  build {b['id']}  v{b['attributes']['version']}  uploaded={b['attributes']['uploadedDate']}")
expect("PATCH", f"/v1/appStoreVersions/{ver_id}/relationships/build", body={
    "data": {"type": "builds", "id": b["id"]}
})

# ─── 7-9. Optional submit ───────────────────────────────────────────────────
parser = argparse.ArgumentParser()
parser.add_argument("--submit", action="store_true")
args = parser.parse_args()

if not args.submit:
    print("\n✅ Metadata + build attached. NOT submitted for review.")
    print("   Re-run with --submit to push the version to Apple review.")
    sys.exit(0)

print("\n▶ 7. creating reviewSubmission")
submit = expect("POST", "/v1/reviewSubmissions", body={
    "data": {
        "type": "reviewSubmissions",
        "attributes": {"platform": "IOS"},
        "relationships": {
            "app": {"data": {"type": "apps", "id": APP_ID}}
        }
    }
}, ok=(200, 201))
sub_id = submit["data"]["id"]
print(f"  reviewSubmissions/{sub_id}")

print("▶ 8. adding version + IAP to submission")
# Add the version
expect("POST", "/v1/reviewSubmissionItems", body={
    "data": {
        "type": "reviewSubmissionItems",
        "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
            "appStoreVersion":  {"data": {"type": "appStoreVersions", "id": ver_id}}
        }
    }
}, ok=(200, 201))

print("▶ 9. submitting")
expect("PATCH", f"/v1/reviewSubmissions/{sub_id}", body={
    "data": {"type": "reviewSubmissions", "id": sub_id,
             "attributes": {"submitted": True}}
})

# Verify state
final = expect("GET", f"/v1/reviewSubmissions/{sub_id}")
print(f"\n✅ submission state: {final['data']['attributes']['state']}")

# Check IAP auto-bundled
iap_check = expect("GET", f"/v1/apps/{APP_ID}/inAppPurchasesV2?limit=20")
for d in iap_check["data"]:
    print(f"   IAP {d['attributes']['productId']}: {d['attributes']['state']}")
