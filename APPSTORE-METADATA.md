# Chromafield: App Store Connect Metadata

## Identity

| Field | Value |
|-------|-------|
| **Name** | Chromafield |
| **Subtitle** | Particle art instrument |
| **Bundle ID** | com.chromafield.app |
| **SKU** | CHROMAFIELD-001 |
| **Primary Category** | Entertainment |
| **Secondary Category** | Graphics & Design |
| **Age Rating** | 4+ |
| **Price** | Free |
| **Availability** | All territories |

Store settings above are submission targets. Confirm them in App Store Connect before submission.

---

## Keywords

```
generative art,particles,physics,flocking,creative,drawing,animation,abstract,visualizer,pencil
```

*(100 character limit; 95 characters)*

---

## Description

Chromafield is a particle art instrument. Place Attract, Repel, Vortex, and Chaos nodes on a canvas, and thousands of particles pull toward, scatter from, and swirl around them. Start with a preset, change its colors and behavior, and make a composition of your own.

Particles leave trails that fade behind them as your forces move them.

**Four particle behaviors:**
• **Flock:** nearby particles influence one another's motion
• **Diffuse:** particles drift with added scatter
• **Crystal:** slow particles move toward points on a grid
• **Orbit:** attractors add a circling force

**Eight curated palettes:**
Ember, Glacial, Void, Toxic, Dusk, Ocean, Mono, and Forge. Particle colors vary with speed and age.

**Four field node types:**
• Attract: pulls particles toward a point
• Repel: pushes particles away from a point
• Vortex: applies a turning force
• Chaos: adds turbulence

**Save, load, export:**
• Save your setups and reload them later
• 6 bundled presets to explore: Nebula, Crystal Web, Solar Wind, Void Dance, Toxic Storm, Gold Rush
• Export a PNG to your photo library
• Export a 10-second MP4 at 60fps, rendered frame by frame rather than screen-recorded

No accounts, ads, or subscriptions. Chromafield works offline and saves your setups in the app's local storage.

Place nodes with a finger on iPhone or iPad. On a compatible iPad, Apple Pencil places an Attract node and drags it across the canvas; with a pressure-sensitive Pencil, pressing harder makes it stronger.

---

## Promotional Text

*(Optional; appears above the description)*

```
Drop Attract, Repel, and Vortex nodes on a canvas and watch thousands of particles bend around them. Save the result as a PNG or a 10-second MP4. iPhone and iPad.
```

---

## Support URL

https://github.com/saagpatel/Chromafield/issues

---

## Privacy Policy URL

https://github.com/saagpatel/Chromafield/blob/main/PRIVACY.md

---

## Screenshots

### Required Sizes
- **6.9-inch iPhone:** 1320x2868 px (portrait)
- **13-inch iPad:** 2064x2752 px (portrait)

Both sizes are required for this submission. `project.yml` declares `TARGETED_DEVICE_FAMILY: "1,2"`.

### Screenshot Plan (4 screenshots per size)

| n (`-AppStoreScreenshot`) | Screen | Capture State | Device Sizes (portrait) | Capture Route | Headline Overlay |
|---|--------|-----------------|-------------------------|---------------|------------------|
| 1 | Launch canvas | Nebula loaded; actual particles, HUD node count, and bottom toolbar visible | 6.9-inch iPhone 1320x2868; 13-inch iPad 2064x2752 | Simulator | "Place forces. Watch particles respond." |
| 2 | Behavior sheet | Open "Behavior"; show the actual Flock, Diffuse, Crystal, and Orbit rows with Diffuse selected from Nebula | 6.9-inch iPhone 1320x2868; 13-inch iPad 2064x2752 | Simulator | "Choose how particles move." |
| 3 | Gallery sheet | Open "Presets"; show the six named presets with their palette-gradient placeholders and "No saved configurations yet" in the Saved section; scroll if needed | 6.9-inch iPhone 1320x2868; 13-inch iPad 2064x2752 | Simulator | "Start with one of six presets." |
| 4 | Export sheet | Open "Export"; show the actual "Save Image" and "Record Loop" rows with the build's captions; do not trigger an export or Photos prompt | 6.9-inch iPhone 1320x2868; 13-inch iPad 2064x2752 | Simulator | "Save a PNG or a 10-second MP4." |

All four states are simulator-capturable using the real Metal canvas and existing sheets. No `OPERATOR: capture on device` rows are needed for this plan.

### How to Take Screenshots
1. On a Mac with full Xcode and Metal-capable simulators named exactly `iPhone 18 Pro Max` and `iPad Pro 13-inch (M5)`, run `scripts/capture-screenshots.sh`. When multiple installed iOS runtimes have that name, the script selects the newest available runtime. It builds Debug once without signing, reads the built bundle ID, installs, sets dark appearance and a 9:41 status bar, and captures all four states per device. Release has no screenshot launch mode; compare the captured UI with the submission build before uploading.
2. Debug screenshot mode uses bundled Nebula (including its fixed IDs and creation date), a fixed particle seed, the device's normal launch budget with adaptive reduction disabled, and 240 rendered frames at a fixed simulation step before freezing the actual trail texture. The script waits for the app's warm-up marker, then settles for 8 seconds for shot 1 and 4 seconds for other shots. Override a wait with `SHOT_1_WAIT=12` (or `SHOT_2_WAIT`, `SHOT_3_WAIT`, `SHOT_4_WAIT`); `READY_TIMEOUT` defaults to 120 seconds, and `DERIVED` defaults to `.build/shots`. Saved entries are hidden for the fresh-install gallery state without deleting existing configurations. No onboarding or permissions are requested in these launch/sheet paths.
3. Raw PNGs are written to `screenshots/appstore/iphone-18-pro-max/01.png` through `04.png` and `screenshots/appstore/ipad-pro-13-inch-m5/01.png` through `04.png`. The script checks every PNG with `sips`, fails on a size mismatch, clears its status bar overrides even on failure, and shuts down only simulators it booted. Review the visible states, including all six gallery tiles and the empty Saved section. The gallery scrolls; show its actual visible content rather than combining screens into an invented layout.
4. Add the headline overlays without changing the app content. Use the captured particle field; do not invent rings, ribbons, preset previews, or particle counts. Generated PNGs and screenshot build output are ignored by Git and are not committed.

Simulator captures show that simulator's output. They do not establish physical-device performance or Apple Pencil input.

---

## App Review Notes

```
Chromafield is a generative art tool. No login or network connection is required.
It requests add-only Photo Library permission when an export is triggered, not at launch.

To test the core flow:
1. Launch the app. The canvas starts with the bundled Nebula configuration.
2. Tap an open area of the canvas to add an Attract node.
3. Long-press the canvas to open the radial menu, then tap "Vortex".
   This adds the Vortex node at the long-press position. A normal tap adds an Attract node.
   The other menu labels are "Attract", "Repel", and "Chaos".
4. Tap "Palette" in the bottom toolbar, then tap a palette swatch.
   Tap "Palette" again to close the selector.
5. Tap "Behavior", then choose "Flock", "Diffuse", "Crystal", or "Orbit".
   The sheet closes after selection.
6. Tap "Save" to save the current configuration.
   Save shows no confirmation; the entry appears under Saved in Gallery.
   Tap "Presets" to open "Gallery".
   Tap the saved configuration under "Saved" to load it and close the sheet.
7. Tap "Export", then "Save Image". Allow adding to Photos when prompted.
   A successful export shows "Exported" and "Saved to your photo library."
8. Tap "OK" to dismiss the success alert, then tap "Record Loop" in the export sheet.
   This exports a 10-second MP4 at 60fps.
   It renders successive simulation frames; the clip is not a seamless loop.
   PNG dimensions vary with the canvas size and device budget. The displayed
   PNG multiplier does not mean a multiple of native screen pixels.

To load a preset:
1. Dismiss any open sheet, then tap "Presets".
2. In "Gallery", tap "Nebula" under "Presets". The sheet closes and loads the configuration.
   Bundled preset tiles use palette gradients, not rendered previews.

Finger input supports the steps above. Drawing to move an Attract node uses Apple Pencil
on a compatible iPad. Pressure control needs a pressure-sensitive Pencil.
A simulator cannot demonstrate Pencil pressure. Particle count and appearance depend
on the device and running simulation.
Metal is required. If unavailable, the app shows "Metal Unavailable" instead of a canvas.
Review from any location: the app does not request or use location.
No reviewer account or credentials are required.
```

---

## Checklist Before Submission

- [ ] Bundle ID `com.chromafield.app` registered in Apple Developer portal
- [ ] App icon 1024×1024 appears correctly in Xcode asset catalog (no warnings)
- [ ] `NSPhotoLibraryAddUsageDescription` in Info.plist: "Chromafield saves your particle art to your photo library."
- [ ] No network entitlements declared in entitlements file
- [x] `PrivacyInfo.xcprivacy` present: declares no data collection or tracking; no required-reason API uses found in the source audit
- [ ] Archive succeeds: `Product → Archive` with no errors
- [ ] Validate App passes with 0 errors
- [ ] All 8 screenshots uploaded (4 per required size: iPad 13" + iPhone 6.9")
- [ ] Description, keywords, subtitle filled in App Store Connect
- [ ] Price set to Free in Pricing and Availability
- [ ] Age rating questionnaire complete (4+)
- [ ] Support URL and Privacy Policy URL provided
- [ ] Privacy nutrition label: no data collected or linked to user
- [ ] TestFlight test complete: place all 4 node types, switch all 4 behaviors, switch all 8 palettes, save config, load preset, export PNG, export MP4
- [ ] Verify PNG export on a physical device: saves to Photos; record actual pixel dimensions without assuming native-screen scaling
- [ ] Verify MP4 export on a physical device: saves to Photos, approximately 10 seconds at 60fps; no seamless-loop or export-time target
- [ ] Verify finger review steps and Pencil input separately; use a compatible iPad and pressure-sensitive Pencil for pressure control
- [ ] Test on an iPhone SE running iOS 17 or later for layout overflow in UI overlays
- [ ] Submit for Review

## Copyright
© 2026 saagpatel
