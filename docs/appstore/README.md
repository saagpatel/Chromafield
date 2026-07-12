# Chromafield — App Store Launch Packet

Everything needed to submit Chromafield v1.0, prepared up to the point that requires
the Xcode GUI / your Apple credentials. All product claims are verified against the
shipping source; all files are sanitized (no email, API keys, UUIDs, or local paths).

## Contents

| File | Purpose |
|------|---------|
| `metadata.md` | ASO copy — name, subtitle, keywords, description, promo text, what's-new, review notes |
| `privacy-and-age-rating.md` | App Privacy nutrition label + Age Rating questionnaire answers, drawn from a code audit |
| `screenshots.md` | Manual capture checklist (2026 sizes) + 5-shot plan + 3 caption options per shot |
| `captions.json` | Machine-readable ≤30-char overlay captions (5 per device) |

## App facts (verified)

- **Bundle ID:** `com.chromafield.app` · **Version:** 1.0.0 (build 3) · **iOS 17.0+** · Universal (iPhone + iPad)
- **Scheme:** `Chromafield` · **AppIcon:** 1024×1024 present · **Privacy manifest:** present & accurate
- **Data:** none collected, no network, no tracking → "Data Not Collected", 4+

## Prior App Store Connect snapshot (reverify before mutation)

The repository records the following earlier read-only observation. It is not a
current-state guarantee and must be refreshed in App Store Connect before acting:

- App record exists: **Chromafield**, bundle `com.chromafield.app`.
- **Two `1.0` version objects, both `PREPARE_FOR_SUBMISSION`** — an anomaly:
  - One holds the real metadata (description, keywords, support URL — from a prior `fastlane deliver`).
  - The other (the one ASC currently treats as primary) is **empty**.
  - **Action needed (your call, in the ASC UI):** decide which `1.0` is canonical and
    remove/ignore the duplicate so submission targets the populated one. This was left
    untouched deliberately — it needs human judgment, not a blind API write.

## Current local verification

- Xcode 26.5 and iOS Simulator 26.5 are installed and active.
- 69 tests pass on iPhone 17 Pro Simulator.
- The Release simulator bundle and unsigned device archive both build successfully.
- The launch experience was repaired and visually verified on iPhone 17 Pro.
- A signed archive requires Xcode to create or download a provisioning profile for
  `com.chromafield.app`; that Apple-account mutation remains operator-gated.

## Remaining manual steps (require Apple credentials or product judgment)

1. **Capture the remaining screenshot set** — follow `screenshots.md`; the repaired
   iPhone launch capture is present, while the iPad and composed feature shots remain.
2. **Resolve the duplicate 1.0 version** in ASC (above).
3. **Authorize provisioning, archive, validate, and upload the binary** in Xcode.
4. **Confirm metadata + privacy + age rating** in ASC, then **Submit for Review**.

## Security hygiene

- Fastlane reads identifiers and key paths from ignored environment variables.
- `.p8`, private-key directories, `.env` files, generated reports, and derived build
  data are ignored.
- Support routes through the public GitHub issues page; no personal email is stored.
