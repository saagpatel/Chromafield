# Chromafield — App Store Connect Metadata

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

---

## Keywords

```
generative art,particles,Metal,creative,art,drawing,animation,abstract,instrument,Apple Pencil
```

*(100 character limit — these are 89 characters)*

---

## Description

Chromafield is a particle art instrument. Place field nodes on a canvas — attractors, repellers, vortices, chaos emitters — and watch thousands of particles respond in real time. Every placement is a brushstroke. Every configuration is a composition.

Built on Metal, Chromafield runs up to 200,000 particles at 60fps. The physics are real: particles are pulled, pushed, spun, and scattered according to the forces you place. Apple Pencil pressure maps to field strength — a light touch creates gentle currents; full pressure warps the field.

**Four particle behaviors:**
• **Flock** — particles align into murmurations, streaming like starlings
• **Diffuse** — particles drift with Brownian scatter, filling the canvas like ink in water
• **Crystal** — particles lock into geometric lattices, snapping to invisible grids
• **Orbit** — particles circle attractors in rings, forming solar system–like structures

**Eight curated palettes:**
Ember, Glacial, Void, Toxic, Dusk, Ocean, Mono, Forge — each carefully tuned so fast particles glow brighter than slow ones, giving the field a sense of energy and depth.

**Four field node types:**
• Attractor — pulls particles toward a point with configurable falloff
• Repeller — pushes particles outward in a radial burst
• Vortex — rotates particles in a circular current
• Chaos — introduces turbulence, breaking ordered patterns apart

**Save, load, export:**
• Save field configurations and reload them later
• 6 bundled presets to explore: Nebula, Crystal Web, Solar Wind, Void Dance, Toxic Storm, Gold Rush
• Export as a full-resolution PNG (2× screen resolution) to your photo library
• Export as a 10-second MP4 loop at 60fps, rendered offline for maximum quality
• Field nodes are never visible in exports — only the particle art

**No accounts. No cloud. No ads. No subscriptions.** Chromafield is entirely offline. Your saved configurations live in your app's local storage, nothing more.

Works with finger and Apple Pencil on iPhone and iPad.

---

## Promotional Text

*(Optional — appears above description, can be updated without new app version)*

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
- **12.9" iPad Display** — 2048 × 2732 px (iPad Pro 12.9") — **required for universal app**
- **6.7" Display** — 1290 × 2796 px (iPhone 16 Pro Max / iPhone 15 Pro Max)

### Screenshot Plan (4 screenshots per size)

| # | Screen | Simulator State | Headline Overlay |
|---|--------|-----------------|------------------|
| 1 | Live canvas — Orbit behavior | Forge palette active; 1 central attractor + 4 radial repellers; 50K+ particles forming concentric ring orbits; trail accumulation on; visually stunning gold rings against black | "Place forces. Watch them orbit." |
| 2 | Live canvas — Flock behavior | Ocean palette; 2 attractors; particles streaming in murmuration-like ribbons across the canvas; trails showing the path of the flock | "Thousands of particles. One field." |
| 3 | Preset Gallery sheet | Grid of 6 bundled preset thumbnails (Nebula, Crystal Web, Solar Wind, Void Dance, Toxic Storm, Gold Rush) + 2–3 user-saved configs below; dark background | "Six presets. Infinite variations." |
| 4 | Export Controls sheet | "Save Image" and "Record Loop" rows visible; a stunning Void palette crystallization config visible in the background canvas | "Export your art. 2× resolution PNG or 60fps MP4." |

### How to Take Screenshots
1. Open Xcode → Simulator → select iPad Pro 12.9" (or iPhone 16 Pro Max for phone size)
2. Build and run the Chromafield target
3. Load a preset or place nodes manually to create a visually compelling state
4. Let the simulation run for 15–30 seconds so trails build up
5. **Xcode menu: Product → Simulator → Take Screenshot** (saves to Desktop)
   OR: `xcrun simctl io booted screenshot ~/Desktop/screenshot.png`
6. Repeat for iPhone 16 Pro Max (6.7") by switching simulator
7. Add marketing text overlays in Sketch, Figma, or Canva before uploading

*Note: For the most compelling screenshots, use a physical iPad Pro with Apple Pencil — the particle density and rendering quality is significantly better than the simulator.*

---

## App Review Notes

```
Chromafield is a generative art tool. No login, no network requests, no special permissions required
beyond Photo Library (requested only when the user first triggers an export — not at launch).

To test the core flow:
1. Launch app — full-screen dark canvas with default particle field
2. Tap anywhere to place an attractor node — particles stream toward it
3. Long-press to open the radial node menu — select Vortex
4. Place a vortex node — particles rotate around it
5. Tap the palette selector (bottom bar) to switch color palettes
6. Tap "Behaviors" to switch between Flock, Diffuse, Crystal, Orbit
7. Tap the export icon → "Save Image" to export a PNG (will request Photo Library permission)

To load a preset:
1. Tap the gallery icon
2. Select "Nebula" from the bundled presets — canvas reconfigures immediately

Apple Pencil input maps pressure to field node strength, but all features work with finger input.
No reviewer account, credentials, or network connectivity required.
```

---

## Checklist Before Submission

- [ ] Bundle ID `com.chromafield.app` registered in Apple Developer portal
- [ ] App icon 1024×1024 appears correctly in Xcode asset catalog (no warnings)
- [ ] `NSPhotoLibraryAddUsageDescription` in Info.plist: "Chromafield saves your particle art to your photo library."
- [ ] No network entitlements declared in entitlements file
- [ ] `PrivacyInfo.xcprivacy` present — no data collected, no tracking, Photo Library API declared
- [ ] Archive succeeds: `Product → Archive` with no errors
- [ ] Validate App passes with 0 errors
- [ ] All 8 screenshots uploaded (4 per required size: iPad 12.9" + iPhone 6.7")
- [ ] Description, keywords, subtitle filled in App Store Connect
- [ ] Price set to Free in Pricing and Availability
- [ ] Age rating questionnaire complete (4+)
- [ ] Support URL and Privacy Policy URL provided
- [ ] Privacy nutrition label: no data collected or linked to user
- [ ] TestFlight test complete: place all 4 node types, switch all 4 behaviors, switch all 8 palettes, save config, load preset, export PNG, export MP4
- [ ] Verify PNG export on physical device: < 3 seconds, 2× screen resolution, no node overlay visible
- [ ] Verify MP4 export on physical device: < 30 seconds, 10-second loop, plays at 60fps in Photos
- [ ] Test on iPhone SE (smallest supported screen) — no layout overflow in UI overlays
- [ ] Submit for Review

## Copyright
© 2026 saagpatel
