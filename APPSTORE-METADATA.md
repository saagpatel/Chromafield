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
generative art,particles,Metal,creative,art,drawing,animation,abstract,instrument,Apple Pencil
```

*(100 character limit; 94 characters)*

---

## Description

Chromafield is a particle art instrument. Place attractors, repellers, vortices, and chaos nodes on a canvas. Watch particles respond to the forces you place. Start with a preset, change its colors and behavior, and make a composition of your own.

Built on Metal, Chromafield simulates particles that pull together, scatter, and turn around field nodes.

**Four particle behaviors:**
• **Flock:** nearby particles influence one another's motion
• **Diffuse:** particles drift with added scatter
• **Crystal:** slow particles move toward points on a grid
• **Orbit:** attractors add a circling force

**Eight curated palettes:**
Ember, Glacial, Void, Toxic, Dusk, Ocean, Mono, and Forge. Particle colors vary with speed and age.

**Four field node types:**
• Attractor: pulls particles toward a point
• Repeller: pushes particles away from a point
• Vortex: applies a turning force
• Chaos: adds turbulence

**Save, load, export:**
• Save field configurations and reload them later
• 6 bundled presets to explore: Nebula, Crystal Web, Solar Wind, Void Dance, Toxic Storm, Gold Rush
• Export a PNG to your photo library
• Export a 10-second MP4 at 60fps, rendered offline
• Exports show particles without field node overlays

**No accounts. No ads. No subscriptions.** Chromafield works offline. It saves configurations in the app's local storage and does not upload them.

Use finger gestures on iPhone and iPad to place nodes. On a compatible iPad, draw with Apple Pencil to place and move an attractor. With a pressure-sensitive Pencil, pressure changes its strength.

---

## Promotional Text

*(Optional; appears above the description)*

```
Place forces. Watch particles respond. Export the art. Metal-powered generative art instrument for iPhone and iPad.
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

| # | Screen | Capture State | Headline Overlay |
|---|--------|-----------------|------------------|
| 1 | Launch canvas | Nebula loaded; actual particles, field nodes, and bottom toolbar visible | "Place forces. Watch particles respond." |
| 2 | Behavior sheet | Tap "Behavior"; show the actual Flock, Diffuse, Crystal, and Orbit rows and selected checkmark | "Choose how particles move." |
| 3 | Gallery sheet | Tap "Presets"; show the six named presets with their palette-gradient placeholders. Use a fresh install with "No saved configurations yet" in the Saved section; scroll if needed | "Start with one of six presets." |
| 4 | Export sheet | Tap "Export"; show the actual "Save Image" and "Record Loop" rows with the build's captions | "Save a PNG or a 10-second MP4." |

### How to Take Screenshots
1. Run the submission build on an iPhone and iPad, or matching simulators with Metal available.
2. Capture the four states above in portrait. The gallery scrolls; show its actual visible content rather than combining screens into an invented layout.
3. Confirm the phone captures are 1320x2868 and the iPad captures are 2064x2752 before uploading.
4. Add the headline overlays without changing the app content. Use the captured particle field; do not invent rings, ribbons, preset previews, or particle counts.

Simulator captures show that simulator's output. They do not establish physical-device performance or Apple Pencil input.

---

## App Review Notes

```
Chromafield is a generative art tool. No login or network connection is required.
It requests add-only Photo Library permission when an export is triggered, not at launch.

To test the core flow:
1. Launch the app. The canvas starts with the bundled Nebula configuration.
2. Tap an open area of the canvas to add an attractor.
3. Long-press the canvas, release, then tap "Vortex" in the radial menu.
   This adds the vortex at the long-press position. A normal tap adds an attractor.
   The other menu labels are "Attract", "Repel", and "Chaos".
4. Tap "Palette" in the bottom toolbar, then tap a palette swatch.
   Tap "Palette" again to close the selector.
5. Tap "Behavior", then choose "Flock", "Diffuse", "Crystal", or "Orbit".
   The sheet closes after selection.
6. Tap "Save" to save the current configuration. Tap "Presets" to open "Gallery".
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

Finger input supports the steps above. Drawing to move an attractor uses Apple Pencil
on a compatible iPad. Pressure control needs a pressure-sensitive Pencil.
A simulator cannot demonstrate Pencil pressure. Particle count and appearance depend
on the device and running simulation; specific rings or ribbons are not guaranteed.
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
- [ ] Verify PNG export on a physical device: saves to Photos with no node overlay; record actual pixel dimensions without assuming native-screen scaling
- [ ] Verify MP4 export on a physical device: saves to Photos, approximately 10 seconds at 60fps, no node overlay; no seamless-loop or export-time target
- [ ] Verify finger review steps and Pencil input separately; use a compatible iPad and pressure-sensitive Pencil for pressure control
- [ ] Test on an iPhone SE running iOS 17 or later for layout overflow in UI overlays
- [ ] Submit for Review

## Copyright
© 2026 saagpatel
