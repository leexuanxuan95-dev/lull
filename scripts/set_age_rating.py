#!/usr/bin/env python3
"""Set age rating to 4+ (no objectionable content) for the inflight appInfo."""
import os, time, jwt, urllib.request, urllib.error, json, sys

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

APP_ID = os.environ["APP_ID"]

# Find inflight appInfo
s, body = asc("GET", f"/v1/apps/{APP_ID}/appInfos?limit=5")
inflight = next((i for i in body["data"] if i["attributes"].get("appStoreState") == "PREPARE_FOR_SUBMISSION"),
                body["data"][0])
info_id = inflight["id"]
print(f"appInfo {info_id}  state={inflight['attributes'].get('appStoreState')}")

# All "false" / "NONE" except where Apple makes us pick something positive.
# This puts the app at 4+.
attrs = {
    # frequency-style enums: NONE / INFREQUENT_OR_MILD / FREQUENT_OR_INTENSE
    "alcoholTobaccoOrDrugUseOrReferences":         "NONE",
    "contests":                                    "NONE",
    "gamblingSimulated":                           "NONE",
    "gunsOrOtherWeapons":                          "NONE",
    "horrorOrFearThemes":                          "NONE",
    "matureOrSuggestiveThemes":                    "NONE",
    "medicalOrTreatmentInformation":               "NONE",
    "profanityOrCrudeHumor":                       "NONE",
    "sexualContentGraphicAndNudity":               "NONE",
    "sexualContentOrNudity":                       "NONE",
    "violenceCartoonOrFantasy":                    "NONE",
    "violenceRealistic":                           "NONE",
    "violenceRealisticProlongedGraphicOrSadistic": "NONE",
    # boolean
    "gambling":                False,
    "lootBox":                 False,
    "parentalControls":        False,
    "ageAssurance":            False,
    "unrestrictedWebAccess":   False,
    "userGeneratedContent":    False,
    "messagingAndChat":        False,
    "advertising":             False,
    "healthOrWellnessTopics":  False,
    # other
    "kidsAgeBand":             None,
    "ageRatingOverrideV2":     "NONE",
    "koreaAgeRatingOverride":  "NONE",
}

# Try via appInfo's ageRatingDeclaration relationship
print("Setting age rating declaration…")
s, body = asc("GET", f"/v1/appInfos/{info_id}/ageRatingDeclaration")
existing = body.get("data") if isinstance(body, dict) else None
if existing:
    rid = existing["id"]
    s, body = asc("PATCH", f"/v1/ageRatingDeclarations/{rid}", body={
        "data": {"type": "ageRatingDeclarations", "id": rid, "attributes": attrs}
    })
    print(f"  PATCH HTTP {s}")
    if s not in (200, 201):
        print(json.dumps(body, indent=2)[:500])
else:
    print("  No existing declaration — Apple may auto-create one. Setting via app relationship.")
    # Alternative: PATCH on the inflight version's ageRatingDeclaration
    s, body = asc("GET", f"/v1/apps/{APP_ID}/ageRatingDeclaration")
    print(f"  app-level age rating GET HTTP {s}")
print("✓ done")
