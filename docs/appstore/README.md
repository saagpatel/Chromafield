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

- **Bundle ID:** `com.chromafield.app` · **Version:** 1.0.0 (build 1) · **iOS 17.0+** · Universal (iPhone + iPad)
- **Scheme:** `Chromafield` · **AppIcon:** 1024×1024 present · **Privacy manifest:** present & accurate
- **Data:** none collected, no network, no tracking → "Data Not Collected", 4+

## Live App Store Connect state (read-only, nothing was mutated)

- App record exists: **Chromafield**, bundle `com.chromafield.app`.
- **Two `1.0` version objects, both `PREPARE_FOR_SUBMISSION`** — an anomaly:
  - One holds the real metadata (description, keywords, support URL — from a prior `fastlane deliver`).
  - The other (the one ASC currently treats as primary) is **empty**.
  - **Action needed (your call, in the ASC UI):** decide which `1.0` is canonical and
    remove/ignore the duplicate so submission targets the populated one. This was left
    untouched deliberately — it needs human judgment, not a blind API write.

## Remaining manual steps (require Xcode GUI / your credentials)

1. **Install the iOS platform** — Xcode → Settings → Components → iOS 26.5 (this env
   has only the SDK headers, no runtime, so neither a verifying build nor simulator
   screenshots can run here).
2. **Verify the build** — `xcodebuild -scheme Chromafield -destination 'generic/platform=iOS' build` (no compile errors were found; the build simply could not run without the platform).
3. **Capture screenshots** — follow `screenshots.md` (10 PNGs at 1320×2868 / 2064×2752).
4. **Resolve the duplicate 1.0 version** in ASC (above).
5. **Archive & upload the binary** — Xcode → Product → Archive → Distribute, or Transporter.
6. **Answer export compliance** — encryption = No (see `privacy-and-age-rating.md`).
7. **Confirm metadata + privacy + age rating** in ASC, then **Submit for Review** (not done here, by design).

## Security hygiene flags (surfaced, not changed)

- `fastlane/Fastfile` hardcodes the ASC **Key ID** and **Issuer ID**. The `.p8`
  private key is correctly *not* committed, but move these identifiers to fastlane's
  env vars (`APP_STORE_CONNECT_API_KEY_*`) before this repo is public.
- `.gitignore` has **no secret patterns** — add `*.p8` and `**/private_keys/`.
- Root `PRIVACY.md` contains a personal email; consider routing support through the
  GitHub issues URL only.
