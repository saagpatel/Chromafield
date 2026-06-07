# Chromafield — App Store Screenshots (Manual Capture Checklist)

> **Why manual:** automated simulator capture is blocked in the current
> environment — Xcode 26.5 has the iOS **SDK** but no iOS **simulator runtime**
> installed (`xcrun simctl list runtimes` is empty; the only build destinations are
> unusable placeholders). Capture must be done after installing the iOS platform
> (see the build-readiness note in the session report) or on a physical device.
> Physical-device capture is recommended regardless — particle density and render
> quality far exceed the simulator.

## Required sizes (2026 App Store)

| Device slot | Capture device | Exact pixel dimensions | Output dir |
|-------------|----------------|------------------------|------------|
| **iPhone 6.9"** | iPhone 16 Pro Max (or 17 Pro Max) | **1320 × 2868** (portrait) | `screenshots/iphone-69/` |
| **iPad 13"** | iPad Pro 13-inch (M4) | **2064 × 2752** (portrait) | `screenshots/ipad-13/` |

> These two sizes are the only ones required for 2026 submissions. The older
> 6.7"/12.9" sizes referenced in the legacy root `APPSTORE-METADATA.md` are
> **superseded** — do not use them.

Up to 10 screenshots allowed per size; this plan uses **5**. Capture the same 5
states on both devices (10 images total). Field nodes are intentionally invisible in
the live render, so each shot is pure particle art plus the on-screen UI you choose to
include.

---

## Capture procedure (per device)

1. Install the iOS platform if needed: **Xcode → Settings → Components → iOS 26.5**
   (or `xcodebuild -downloadPlatform iOS`).
2. Boot the target simulator (or connect a physical device):
   ```bash
   xcrun simctl boot "iPhone 16 Pro Max"   # or "iPad Pro 13-inch (M4)"
   open -a Simulator
   ```
3. Build & install (signing off for simulator):
   ```bash
   xcodebuild -scheme Chromafield -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
     -derivedDataPath /tmp/cf-dd build
   xcrun simctl install booted "$(find /tmp/cf-dd -name '*.app' -not -path '*/PlugIns/*' | head -1)"
   xcrun simctl launch booted com.chromafield.app
   ```
4. Drive the app into each state below, let the simulation run **15–30 s** so trails
   build, then capture:
   ```bash
   xcrun simctl io booted screenshot screenshots/iphone-69/01-orbit.png
   ```
5. Verify dimensions on every file — do not ship a mismatch:
   ```bash
   sips -g pixelWidth -g pixelHeight screenshots/iphone-69/01-orbit.png
   # expect 1320 x 2868 (iPhone) / 2064 x 2752 (iPad)
   ```

---

## Shot plan (5 shots, with 3 caption options each)

Captions are overlay text you composite on top in Figma/Sketch/Canva before upload —
App Store has no separate caption field. Option **A** of each is ≤30 chars (matches
`captions.json`); B and C are richer alternates.

### 01 — Orbit behavior · `01-orbit.png`
- **Setup:** Forge palette · 1 central Attractor + 4 radial Repellers · Orbit
  behavior · let concentric gold rings form against black.
- **Captions:**
  - A. `Place forces. Watch them orbit`
  - B. `Forces in, order out — particle orbits you compose`
  - C. `One attractor, infinite rings`

### 02 — Flock behavior · `02-flock.png`
- **Setup:** Ocean palette · 2 Attractors · Flock behavior · particles streaming in
  murmuration ribbons across the canvas.
- **Captions:**
  - A. `200K particles, one field`
  - B. `Murmurations you shape with a touch`
  - C. `Up to 200,000 particles at 60fps`

### 03 — Preset Gallery · `03-presets.png`
- **Setup:** Open the gallery sheet showing the 6 bundled presets (Nebula, Crystal
  Web, Solar Wind, Void Dance, Toxic Storm, Gold Rush).
- **Captions:**
  - A. `Six presets, endless variants`
  - B. `Start from a preset, make it yours`
  - C. `Nebula to Gold Rush in one tap`

### 04 — Export · `04-export.png`
- **Setup:** Export sheet open ("Save Image" / "Record Loop") over a striking Void
  palette Crystal config in the background canvas.
- **Captions:**
  - A. `Export as PNG or 60fps video`
  - B. `Save your art — full-res PNG or MP4 loop`
  - C. `Your art, straight to Photos`

### 05 — Apple Pencil / node placement · `05-pencil.png`
- **Setup (iPad ideal):** Mid-gesture placing a Vortex with Apple Pencil, radial node
  menu visible, Toxic or Dusk palette · turbulence breaking up an ordered field.
- **Captions:**
  - A. `Apple Pencil bends the field`
  - B. `Press harder, bend the field further`
  - C. `Draw forces with finger or Pencil`

---

## Definition of done

- 10 PNGs total (5 per device) in `screenshots/iphone-69/` and `screenshots/ipad-13/`.
- Every file passes `sips` at exactly 1320×2868 (iPhone) / 2064×2752 (iPad).
- `captions.json` (this directory) has 5 entries per device, each ≤30 chars.
- Each frame shows **only the app** — no simulator chrome, desktop, or personal data.
- Upload via App Store Connect or `fastlane deliver` (the repo's fastlane lane already
  has `overwrite_screenshots: true`, `skip_binary_upload: true`).
