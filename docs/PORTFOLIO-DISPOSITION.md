# Chromafield — Portfolio Disposition

**Status:** Release Frozen (iOS App Store) — SwiftUI + Metal generative
art instrument for iPhone and iPad on `origin/main`, with full App
Store submission scaffolding shipped: `APPSTORE-METADATA.md`, fastlane
`deliver` config, `DEVELOPMENT_TEAM` wired, Privacy Manifest, scheme
generation, `ExportOptions.plist`, copyright applied to metadata, and
AI-generated app icon replacing the placeholder. **Second member of
the iOS App Store cluster** that Calibrate founded — solidifies the
pattern (DEVELOPMENT_TEAM + Privacy Manifest + APPSTORE-METADATA +
fastlane deliver = "ready to upload").

> Disposition uses strict `origin/main` verification.
> **Confirms the iOS App Store cluster shape** — two members in two
> rounds proves the cluster is real, not a one-off.

---

## Verification posture

This repo has **only `origin`** (`saagpatel/Chromafield`) — no
`legacy-origin` remote. Clean migration state. Local clone's `main`
is tracking `origin/main` correctly.

Specifically verified on `origin/main`:

- Tip: `72c89b0` chore: replace placeholder icon with AI-generated app
  icon
- Substantive App Store prep commits on `origin/main`:
  - `72c89b0` chore: replace placeholder icon with AI-generated app icon
  - `9341cc2` chore: add fastlane deliver config for App Store metadata
    upload
  - `f56ff9e` chore: replace placeholder app icon with gradient design
  - `1861911` chore: app store archive prep (signing, icons,
    screenshots)
  - `7bfab0f` chore: add privacy policy and update metadata URLs
  - `65083c5` chore: add copyright to metadata and ExportOptions.plist
  - `14312d4` chore(docs): add App Store Connect metadata
  - `cf76108` chore: App Store prep — DEVELOPMENT_TEAM, Privacy
    Manifest, scheme generation
- **Release scaffolding shipped on canonical main:**
  - `APPSTORE-METADATA.md` (Identity, Keywords, Description,
    Promotional Text, Support/Privacy URLs, Screenshot plan)
  - `fastlane/` (deliver config for metadata upload)
  - Privacy Manifest + DEVELOPMENT_TEAM in xcodeproj
  - Copyright in metadata + ExportOptions.plist
  - AI-generated app icon (post-placeholder)
- App Store identity (from `APPSTORE-METADATA.md`):
  - Name: **Chromafield**
  - Subtitle: **Particle art instrument**
  - Bundle ID: `com.chromafield.app`, SKU: `CHROMAFIELD-001`
  - Categories: Entertainment (primary) + Graphics & Design
    (secondary)
  - Age Rating: 4+, Price: Free, Availability: All territories
- Default branch: `main`

---

## Current state in one paragraph

Chromafield is a SwiftUI + Metal generative art instrument for iPhone
and iPad. Users place forces (attractors / repellers / fields), the
Metal compute pipeline propagates thousands of triple-buffered
particles in response, and the user exports stills (PHPhotoLibrary) or
video (AVAssetWriter). Apple Pencil supported. Per memory: v1.0 App
Store ready. The release commits on canonical main confirm: the
operator has cut the placeholder icon, swapped in an AI-generated
icon, wired fastlane `deliver` for metadata upload, added the privacy
policy + Privacy Manifest, set `DEVELOPMENT_TEAM` for signing, and
shipped the App Store metadata file. The next step is App Store
Connect upload + screenshots + submit, not code.

For full detail see:
- `README.md` on `origin/main`
- `APPSTORE-METADATA.md` (identity / keywords / description /
  screenshot plan)
- `IMPLEMENTATION-ROADMAP.md` (architecture, file structure, Metal
  pipeline)

---

## Why "Release Frozen (iOS App Store)" — second cluster member

Chromafield is the second iOS app audited after Calibrate founded the
iOS App Store cluster last round. The App Store prep signature is
**identical** to Calibrate's:

| Signal | Calibrate | **Chromafield** |
|---|---|---|
| DEVELOPMENT_TEAM wired | `cd0031b` | `cf76108` |
| Privacy Manifest | `63c1b24` (Phase 3 bundle) | `cf76108` |
| APPSTORE-METADATA.md on main | Yes | Yes |
| fastlane deliver config | Implied | **`9341cc2` (explicit)** |
| ExportOptions.plist | Yes | Yes |
| Final icon shipped | Yes | **`72c89b0` (AI-generated)** |
| GitHub Actions CI | `6854549` | (TBD — check) |

The pattern is now a **stable iOS-App-Store-ready signature**:
`DEVELOPMENT_TEAM + Privacy Manifest + APPSTORE-METADATA.md +
fastlane deliver + ExportOptions + final icon`. Future iOS apps in
the portfolio (GhostRoutes next in this round; then Liminal /
Nocturne / Redact / RoomTone / Seismoscope / Terroir / TideEngine /
Wavelength) should be triaged by this signature.

Chromafield extends the cluster's distinguishing features further:
- **Pencil-first input** (Apple Pencil pressure, tilt, azimuth) —
  iPadOS-leaning distribution
- **Metal compute pipeline with triple-buffering** — performance-
  sensitive shipping concern, not "render a list view"
- **PHPhotoLibrary + AVAssetWriter export** — needs explicit Photos
  add-only entitlement, privacy nutrition label coverage

---

## Cluster taxonomy update

The iOS App Store cluster now has **two confirmed members**:

| Cluster | Count | Distribution |
|---|---|---|
| Signing (Apple desktop) | 22 | DMG via Apple Developer ID |
| **iOS App Store** | **2** | App Store Connect — Calibrate + **Chromafield** |
| Static-host (web, 3 sub-shapes) | 3 | Vercel / Netlify (PWA / static SPA / SSR+Supabase) |
| Self-hosted service | 1 | launchd + nginx |
| PyPI distribution | 1 (likely 2 this round) | `pip install` |
| Local-first pipeline | 1 | Worker + adapters |
| Operator-tool / dogfood | 1 | Operator-self |

Two members confirms the cluster shape. ~9 more iOS apps in operator
memory should batch here over subsequent rounds.

---

## Unblock trigger (operator)

When ready to ship publicly:

1. **App Store Connect record created** for `com.chromafield.app`
   (Bundle ID provisioned in Apple Developer portal first).
2. **Transfer `APPSTORE-METADATA.md` content into App Store Connect**
   — or run `fastlane deliver` to upload programmatically (config
   already on main).
3. **Privacy nutrition labels** — Chromafield's data posture is local-
   first (no analytics, no server, photos exported via
   PHPhotoLibrary). Label as "Data Not Collected" if accurate; verify
   Metal performance shaders or any embedded SDK doesn't change this.
4. **Required screenshots for all device sizes** — per
   `APPSTORE-METADATA.md` screenshot plan (4 per size, multiple
   sizes). Operator should have device-size matrix laid out before
   submission.
5. **Apple Pencil + iPad-specific marketing** — primary
   distinguisher; lead screenshots and promotional text on iPad with
   Pencil input.
6. **Archive + export** via `xcodebuild archive` +
   `-exportArchive` (config in `ExportOptions.plist`) or via Xcode
   organizer.
7. **Upload + Submit for Review** via Transporter / `xcrun altool` /
   fastlane.

Estimated operator time once App Store Connect record + screenshots
exist: ~3-4 hours (faster than Calibrate because no StoreKit IAP
configuration and no leaderboard/friend group setup).

---

## Portfolio operating system instructions

| Aspect | Posture |
|---|---|
| Portfolio status | `Release Frozen (iOS App Store)` |
| Distribution channel | **App Store Connect**, free tier, all territories |
| Review cadence | Suspend overdue counting |
| Resurface conditions | (a) Operator submits for App Store Review, (b) review feedback requires changes, (c) v1.1 scope packet (new gestures, field types, export formats), or (d) Apple Pencil API change |
| Co-batch with | iOS App Store cluster: Calibrate / **Chromafield** — **now 2 repos** |
| Special concern | **Photos add-only entitlement.** PHPhotoLibrary export needs explicit Info.plist usage description and add-only entitlement scope; full library access is the wrong posture. |
| Special concern | **Metal performance + memory.** Triple-buffered particle compute can OOM on older iPads (A10/A11). Verify minimum target iOS / iPad. |
| Special concern | **Apple Pencil API surface.** Pencil 2 vs Pencil USB-C vs Pencil Pro differ in tilt / squeeze / barrel-roll support. Document supported gestures explicitly in App Store description if any are Pencil Pro-only. |
| Special concern | **AVAssetWriter export.** Video export needs background-task handling for long captures; verify behavior under foreground-only iPad backgrounding policies. |

---

## Why this row confirms the iOS App Store cluster shape

Calibrate (R11) founded the iOS cluster, but one member is a cluster
of one — could have been the operator solving a Calibrate-specific
quirk. Chromafield demonstrates:

- **The same App Store prep cadence applies cleanly to a second,
  structurally-different iOS app.** Calibrate is a prediction game
  (forms + persistence + StoreKit IAP); Chromafield is a Metal
  rendering instrument (compute pipeline + photo/video export). Two
  different shapes, one App Store prep signature.
- **The operator's workflow is repeatable**, not ad hoc. fastlane
  `deliver` config on main means metadata upload is scripted; the
  human work is screenshots + Connect record + submission gate, not
  per-app rediscovery.
- **The cluster's reactivation procedure (audit APPSTORE-METADATA,
  verify Privacy Manifest, confirm DEVELOPMENT_TEAM, screenshot
  matrix) is stable** — it will apply identically to GhostRoutes
  (next in this round) and the remaining iOS apps without per-row
  surprise.

---

## Reactivation procedure (for the next code session)

1. Verify `git branch -vv` shows `main` tracking `origin/main`.
   Already correct as of this disposition pass.
2. Review the local stash (`r12-chromafield-stash`) — contains
   modifications to `CLAUDE.md` plus untracked `.claude/`.
3. **Open `Chromafield.xcodeproj` in Xcode** — confirm DEVELOPMENT_TEAM
   is still valid (Apple Developer Program expirations rotate yearly).
4. **Audit `APPSTORE-METADATA.md`** for any iteration since writing
   it (operator may have refined copy).
5. **Verify Privacy Manifest** declares only the APIs Chromafield
   actually uses (Required Reason API categories: PHPhotoLibrary,
   AVAssetWriter, NSPrivacyAccessedAPICategoryFileTimestamp if
   applicable).
6. **Test fastlane deliver dry run** before live upload: `fastlane
   deliver --skip_screenshots --skip_metadata --force`.
7. Run the full Xcode test target if one exists.
8. **Confirm minimum iOS / iPad target** is reasonable for Metal
   compute pipeline.

---

## Last known reference

| Field | Value |
|---|---|
| `origin/main` tip | `72c89b0` chore: replace placeholder icon with AI-generated app icon |
| Last substantive commit | `9341cc2` chore: add fastlane deliver config for App Store metadata upload |
| Default branch | `main` |
| Build system | **iOS / iPadOS / Swift / SwiftUI / Metal compute / XCTest** |
| Bundle ID | `com.chromafield.app` |
| Phases shipped | App Store-ready per release scaffolding; v1.0 per memory |
| Release scaffolding | **`APPSTORE-METADATA.md` + fastlane deliver + ExportOptions.plist + Privacy Manifest + DEVELOPMENT_TEAM** |
| Distribution channel | **App Store Connect** (Free, all territories, Entertainment + Graphics & Design) |
| Tech distinguisher | Metal compute pipeline + triple-buffered particles + PHPhotoLibrary/AVAssetWriter export + Apple Pencil support |
| Blocker | App Store Connect submission flow (operator-only) |
| Migration state | **No `legacy-origin` remote** — clean |
| Distinguishing feature | **Second iOS App Store cluster member.** Confirms the cluster shape with a structurally-different second app (Metal instrument vs. Calibrate's prediction game). Same App Store prep signature applies cleanly. |
