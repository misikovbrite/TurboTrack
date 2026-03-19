#!/usr/bin/env python3
"""
TurboTrack v1.6.0 — Create ASC version + In-App Event + Submit for review.
"""

import jwt
import time
import os
import json
import requests
from datetime import datetime, timedelta, timezone
from PIL import Image, ImageDraw, ImageFont

# ── ASC API Config ──────────────────────────────────────────
ISSUER_ID = "f7dc851a-bdcb-47d6-b5c7-857f48cadb17"
KEY_ID = "C37442BRFH"
KEY_PATH = os.path.expanduser("~/Downloads/AuthKey_C37442BRFH.p8")
BASE_URL = "https://api.appstoreconnect.apple.com/v1"
APP_ID = "6758868326"

ALL_TERRITORIES = [
    "ALB","DZA","AGO","AIA","ATG","ARG","ARM","AUS","AUT","AZE",
    "BHS","BHR","BRB","BLR","BEL","BLZ","BEN","BMU","BTN","BOL",
    "BWA","BRA","BRN","BGR","BFA","KHM","CAN","CPV","CYM","TCD",
    "CHL","CHN","COL","COG","CRI","HRV","CYP","CZE","DNK","DMA",
    "DOM","ECU","EGY","SLV","EST","FJI","FIN","FRA","GMB","DEU",
    "GHA","GRC","GRD","GTM","GNB","GUY","HND","HKG","HUN","ISL",
    "IND","IDN","IRL","ISR","ITA","JAM","JPN","JOR","KAZ","KEN",
    "KOR","KWT","KGZ","LAO","LVA","LBN","LBR","LTU","LUX","MAC",
    "MDG","MWI","MYS","MLI","MLT","MRT","MUS","MEX","FSM","MDA",
    "MNG","MSR","MOZ","NAM","NPL","NLD","NZL","NIC","NER","NGA",
    "MKD","NOR","OMN","PAK","PLW","PAN","PNG","PRY","PER","PHL",
    "POL","PRT","QAT","ROU","RUS","LCA","STP","SAU","SEN","SYC",
    "SLE","SGP","SVK","SVN","SLB","ZAF","ESP","LKA","KNA","VCT",
    "SUR","SWZ","SWE","CHE","TWN","TJK","TZA","THA","TTO","TUN",
    "TUR","TKM","TCA","UGA","UKR","ARE","GBR","USA","URY","UZB",
    "VEN","VNM","VGB","YEM","ZWE","AFG","BIH","CMR","COD","CIV",
    "GAB","GEO","IRQ","LBY","MDV","MAR","MMR","NRU","RWA","TON",
    "VUT","ZMB","XKS","MNE","SRB"
]

# ── ASC Locales for TurboTrack (22) ────────────────────────
ASC_LOCALES = [
    "ar-SA", "da", "de-DE", "el", "en-US", "es-ES", "es-MX",
    "fi", "fr-FR", "he", "hi", "hu", "id", "it", "ja", "ko",
    "ms", "nl-NL", "no", "pt-BR", "ru", "sv", "th", "tr", "uk",
    "vi", "zh-Hans", "zh-Hant"
]

WHATS_NEW = {
    "en-US": "Search by flight number — enter UA123 to get instant turbulence forecast. Super Pro subscription with 10x accuracy.",
    "ru": "Поиск по номеру рейса — введите UA123 и получите прогноз турбулентности. Подписка Super Pro с 10x точностью.",
    "de-DE": "Suche nach Flugnummer — geben Sie UA123 ein für sofortige Turbulenzvorhersage. Super Pro Abo mit 10x Genauigkeit.",
    "es-ES": "Búsqueda por número de vuelo — ingresa UA123 para pronóstico de turbulencia. Suscripción Super Pro con 10x precisión.",
    "fr-FR": "Recherche par numéro de vol — entrez UA123 pour prévision de turbulence. Abonnement Super Pro avec précision 10x.",
    "pt-BR": "Busca por número do voo — digite UA123 para previsão de turbulência. Assinatura Super Pro com 10x precisão.",
    "ja": "フライト番号検索 — UA123を入力して乱気流予報を取得。Super Proサブスク。",
    "ko": "항공편 번호 검색 — UA123을 입력하여 난기류 예보를 확인하세요. Super Pro 구독.",
    "da": "Søg efter flynummer — indtast UA123 for turbulensforecast. Super Pro abonnement.",
    "sv": "Sök efter flygnummer — ange UA123 för turbulensforecast. Super Pro prenumeration.",
    "no": "Søk etter flynummer — skriv UA123 for turbulensvarsel. Super Pro abonnement.",
    "it": "Ricerca per numero di volo — inserisci UA123 per previsione turbolenza. Abbonamento Super Pro.",
    "nl-NL": "Zoek op vluchtnummer — voer UA123 in voor turbulentievoorspelling. Super Pro abonnement.",
    "zh-Hans": "按航班号搜索 — 输入UA123获取湍流预报。Super Pro订阅。",
    "zh-Hant": "按航班號搜尋 — 輸入UA123獲取亂流預報。Super Pro訂閱。",
}

# ── API helpers ─────────────────────────────────────────────

def generate_token():
    with open(KEY_PATH, "r") as f:
        private_key = f.read()
    now = int(time.time())
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + 1200,
        "aud": "appstoreconnect-v1",
    }
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})


def hdrs():
    return {
        "Authorization": f"Bearer {generate_token()}",
        "Content-Type": "application/json",
    }


def api_get(path, params=None):
    url = f"{BASE_URL}{path}" if path.startswith("/") else path
    r = requests.get(url, headers=hdrs(), params=params)
    if r.status_code >= 400:
        print(f"  GET {path} -> {r.status_code}: {r.text[:300]}")
    return r.json() if r.status_code < 400 else None


def api_post(path, data):
    url = f"{BASE_URL}{path}" if path.startswith("/") else path
    r = requests.post(url, headers=hdrs(), json=data)
    if r.status_code >= 400:
        print(f"  POST {path} -> {r.status_code}: {r.text[:500]}")
        return None
    return r.json()


def api_patch(path, data):
    url = f"{BASE_URL}{path}" if path.startswith("/") else path
    r = requests.patch(url, headers=hdrs(), json=data)
    if r.status_code >= 400:
        print(f"  PATCH {path} -> {r.status_code}: {r.text[:500]}")
        return None
    return r.json()


def api_delete(path):
    url = f"{BASE_URL}{path}" if path.startswith("/") else path
    r = requests.delete(url, headers=hdrs())
    if r.status_code >= 400:
        print(f"  DELETE {path} -> {r.status_code}: {r.text[:300]}")
    return r.status_code < 400


# ── Image generation ────────────────────────────────────────

def generate_event_images():
    """Generate EVENT_CARD (1920x1080) and EVENT_DETAILS_PAGE (1080x1920)."""
    os.makedirs("/tmp/turbotrack_event", exist_ok=True)

    # EVENT_CARD — 1920x1080 landscape
    card = Image.new("RGB", (1920, 1080), (10, 15, 40))
    draw = ImageDraw.Draw(card)
    # Blue gradient overlay
    for y in range(1080):
        alpha = int(80 * (1 - y / 1080))
        draw.line([(0, y), (1920, y)], fill=(30 + alpha, 80 + alpha, 200 + min(alpha, 55)))

    try:
        font_big = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 80)
        font_med = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 44)
        font_sm = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 36)
    except:
        font_big = ImageFont.load_default()
        font_med = font_big
        font_sm = font_big

    draw.text((120, 320), "Flight Number", fill=(100, 180, 255), font=font_big)
    draw.text((120, 420), "Search", fill=(255, 255, 255), font=font_big)
    draw.text((120, 540), "Enter UA123 — get instant", fill=(180, 200, 230), font=font_med)
    draw.text((120, 600), "turbulence forecast", fill=(180, 200, 230), font=font_med)
    draw.text((120, 700), "NEW IN TURBULENCE FORECAST", fill=(100, 160, 255), font=font_sm)

    # Airplane icon placeholder (circle)
    draw.ellipse([1400, 300, 1700, 600], outline=(100, 180, 255), width=4)
    draw.text((1470, 400), "✈", fill=(100, 180, 255), font=font_big)

    card.save("/tmp/turbotrack_event/event_card.png")
    print("  Generated event_card.png (1920x1080)")

    # EVENT_DETAILS_PAGE — 1080x1920 portrait
    detail = Image.new("RGB", (1080, 1920), (10, 15, 40))
    draw2 = ImageDraw.Draw(detail)
    for y in range(1920):
        alpha = int(60 * (1 - y / 1920))
        draw2.line([(0, y), (1080, y)], fill=(10 + alpha, 20 + alpha, 50 + alpha))

    draw2.text((80, 400), "Flight Number", fill=(100, 180, 255), font=font_big)
    draw2.text((80, 500), "Search", fill=(255, 255, 255), font=font_big)
    draw2.text((80, 640), "Enter your flight number", fill=(180, 200, 230), font=font_med)
    draw2.text((80, 700), "and get instant turbulence", fill=(180, 200, 230), font=font_med)
    draw2.text((80, 760), "forecast for your route", fill=(180, 200, 230), font=font_med)

    draw2.text((80, 920), "+ Super Pro Subscription", fill=(100, 160, 255), font=font_med)
    draw2.text((80, 990), "10× accuracy · 14-day forecasts", fill=(150, 170, 200), font=font_sm)
    draw2.text((80, 1040), "Priority real-time PIREP alerts", fill=(150, 170, 200), font=font_sm)

    draw2.text((80, 1200), "TURBULENCE FORECAST", fill=(80, 130, 220), font=font_sm)

    detail.save("/tmp/turbotrack_event/event_details.png")
    print("  Generated event_details.png (1080x1920)")

    return "/tmp/turbotrack_event/event_card.png", "/tmp/turbotrack_event/event_details.png"


# ── Upload asset (3-step) ──────────────────────────────────

def upload_event_asset(loc_id, file_path, asset_type):
    file_size = os.path.getsize(file_path)
    file_name = os.path.basename(file_path)

    # Step 1: Reserve
    resp = api_post("/v1/appEventScreenshots", {
        "data": {
            "type": "appEventScreenshots",
            "attributes": {
                "fileName": file_name,
                "fileSize": file_size,
                "appEventAssetType": asset_type
            },
            "relationships": {
                "appEventLocalization": {
                    "data": {"type": "appEventLocalizations", "id": loc_id}
                }
            }
        }
    })
    if not resp:
        return False

    screenshot_id = resp["data"]["id"]
    upload_ops = resp["data"]["attributes"].get("uploadOperations", [])

    # Step 2: Upload chunks
    with open(file_path, "rb") as f:
        file_data = f.read()

    for op in upload_ops:
        op_headers = {h["name"]: h["value"] for h in op["requestHeaders"]}
        chunk = file_data[op["offset"]:op["offset"] + op["length"]]
        requests.put(op["url"], headers=op_headers, data=chunk)

    # Step 3: Commit (NO sourceFileChecksum!)
    commit = api_patch(f"/v1/appEventScreenshots/{screenshot_id}", {
        "data": {
            "type": "appEventScreenshots",
            "id": screenshot_id,
            "attributes": {
                "uploaded": True
            }
        }
    })
    return commit is not None


# ── Main ────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("TurboTrack v1.6.0 — ASC Update & In-App Event")
    print("=" * 60)

    # ── 1. Find or create version ───────────────────────────
    print("\n[1] Setting up version 1.5.1...")

    version_id = "a85eb1f5-ad76-4d56-92cc-044892ab1a35"  # existing 1.5.1 PREPARE_FOR_SUBMISSION
    print(f"  Using existing version 1.5.1: {version_id}")

    # ── 2. Set release notes ────────────────────────────────
    print("\n[2] Setting release notes...")
    locs = api_get(f"/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    if locs:
        for loc in locs["data"]:
            locale = loc["attributes"]["locale"]
            loc_id = loc["id"]
            notes = WHATS_NEW.get(locale, WHATS_NEW["en-US"])
            api_patch(f"/v1/appStoreVersionLocalizations/{loc_id}", {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": loc_id,
                    "attributes": {"whatsNew": notes}
                }
            })
        print(f"  Updated {len(locs['data'])} localizations")

    # ── 3. Wait for build and link ──────────────────────────
    print("\n[3] Looking for build 1.5.1 (build 6)...")
    for attempt in range(15):
        builds = api_get(f"/v1/builds",
                         params={"filter[app]": APP_ID, "filter[version]": "6",
                                 "filter[preReleaseVersion.version]": "1.5.1",
                                 "sort": "-uploadedDate", "limit": 5})
        if builds and builds.get("data"):
            build_id = builds["data"][0]["id"]
            proc_state = builds["data"][0]["attributes"].get("processingState", "UNKNOWN")
            print(f"  Build found: {build_id} (state: {proc_state})")
            if proc_state == "VALID":
                # Link build to version
                api_patch(f"/v1/appStoreVersions/{version_id}/relationships/build", {
                    "data": {"type": "builds", "id": build_id}
                })
                print(f"  Linked build to version")
                break
            else:
                print(f"  Build processing... waiting 30s (attempt {attempt+1}/15)")
                time.sleep(30)
        else:
            print(f"  No build yet, waiting 30s (attempt {attempt+1}/15)")
            time.sleep(30)
    else:
        print("  WARNING: Build not ready yet. Link manually in ASC.")

    # ── 4. Set encryption ───────────────────────────────────
    print("\n[4] Setting encryption declaration...")
    if builds and builds.get("data"):
        build_id = builds["data"][0]["id"]
        api_post("/v1/betaAppReviewSubmissions", {
            "data": {
                "type": "betaAppReviewSubmissions",
                "relationships": {
                    "build": {"data": {"type": "builds", "id": build_id}}
                }
            }
        })

    # ── 5. Create In-App Event ──────────────────────────────
    print("\n[5] Creating In-App Event...")
    now = datetime.now(timezone.utc)
    event_start = now + timedelta(hours=6)
    event_end = event_start + timedelta(days=14)

    event = api_post("/v1/appEvents", {
        "data": {
            "type": "appEvents",
            "attributes": {
                "referenceName": "Flight Number Search v1.6",
                "badge": "MAJOR_UPDATE",
                "deepLink": f"https://apps.apple.com/app/id{APP_ID}",
                "purchaseRequirement": "NO_COST_ASSOCIATED",
                "primaryLocale": "en-US",
                "priority": "HIGH",
                "purpose": "APPROPRIATE_FOR_ALL_USERS",
                "territorySchedules": [{
                    "territories": ALL_TERRITORIES,
                    "publishStart": event_start.strftime("%Y-%m-%dT%H:%M:%S+00:00"),
                    "eventStart": event_start.strftime("%Y-%m-%dT%H:%M:%S+00:00"),
                    "eventEnd": event_end.strftime("%Y-%m-%dT%H:%M:%S+00:00")
                }]
            },
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}}
            }
        }
    })

    if not event:
        print("  ERROR: Could not create event")
        return

    event_id = event["data"]["id"]
    print(f"  Event created: {event_id}")

    # ── 6. Create event localization ────────────────────────
    print("\n[6] Creating event localization (en-US)...")
    loc = api_post("/v1/appEventLocalizations", {
        "data": {
            "type": "appEventLocalizations",
            "attributes": {
                "locale": "en-US",
                "name": "Flight Number Search",
                "shortDescription": "Enter flight number, get forecast",
                "longDescription": "Search by flight number — enter UA123 to get instant turbulence forecast for your route."
            },
            "relationships": {
                "appEvent": {
                    "data": {"type": "appEvents", "id": event_id}
                }
            }
        }
    })

    if not loc:
        print("  ERROR: Could not create localization")
        return

    loc_id = loc["data"]["id"]
    print(f"  Localization created: {loc_id}")

    # ── 7. Generate & upload event images ───────────────────
    print("\n[7] Generating event images...")
    card_path, detail_path = generate_event_images()

    print("\n[8] Uploading EVENT_CARD...")
    if upload_event_asset(loc_id, card_path, "EVENT_CARD"):
        print("  EVENT_CARD uploaded OK")
    else:
        print("  EVENT_CARD upload FAILED")

    print("\n[9] Uploading EVENT_DETAILS_PAGE...")
    if upload_event_asset(loc_id, detail_path, "EVENT_DETAILS_PAGE"):
        print("  EVENT_DETAILS_PAGE uploaded OK")
    else:
        print("  EVENT_DETAILS_PAGE upload FAILED")

    # ── 10. Submit version + event for review ───────────────
    print("\n[10] Submitting for review...")

    # Create review submission
    sub = api_post("/v1/reviewSubmissions", {
        "data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": "IOS"},
            "relationships": {
                "app": {"data": {"type": "apps", "id": APP_ID}}
            }
        }
    })

    if not sub:
        print("  ERROR: Could not create review submission")
        print("  You may need to cancel an existing submission first.")
        return

    sub_id = sub["data"]["id"]
    print(f"  Review submission created: {sub_id}")

    # Add app store version to submission
    api_post("/v1/reviewSubmissionItems", {
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
                "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}
            }
        }
    })
    print("  Added version to submission")

    # Add event to submission
    api_post("/v1/reviewSubmissionItems", {
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
                "appEvent": {"data": {"type": "appEvents", "id": event_id}}
            }
        }
    })
    print("  Added event to submission")

    # Submit
    result = api_patch(f"/v1/reviewSubmissions/{sub_id}", {
        "data": {
            "type": "reviewSubmissions",
            "id": sub_id,
            "attributes": {"submitted": True}
        }
    })

    if result:
        state = result["data"]["attributes"].get("state", "UNKNOWN")
        print(f"\n  SUBMITTED! State: {state}")
    else:
        print("\n  Submit failed — check ASC for details")

    print("\n" + "=" * 60)
    print("DONE!")
    print(f"  Version: 1.5.1 (build 6)")
    print(f"  Event: {event_id}")
    print(f"  Submission: {sub_id}")
    print("=" * 60)


if __name__ == "__main__":
    main()
