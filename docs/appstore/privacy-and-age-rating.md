# Chromafield — Privacy & Age Rating Answers

> Drafted from a direct audit of the shipping source, not assumptions.
> Use these to fill the App Privacy and Age Rating questionnaires in App Store Connect.

## Code audit basis

| Area | Finding | Evidence |
|------|---------|----------|
| Network | **None.** No `URLSession`, `NWConnection`, or any networking API anywhere in the source. | grep of all `*.swift` — zero matches |
| Tracking / analytics | **None.** No Firebase, Crashlytics, Mixpanel, Amplitude, ATT, or third-party SDKs. No SPM dependencies at all. | grep + `project.yml` has no packages |
| Photo Library | **Write-only.** `PHPhotoLibrary.requestAuthorization(for: .addOnly)` then `PHAssetChangeRequest.creationRequest…`. The app never reads or enumerates the user's photos. | `Export/ImageExporter.swift`, `Export/VideoExporter.swift` |
| Local storage | Field configs saved as JSON in the app sandbox `Documents/configs/` via `FileManager`. Never leaves the device. | `Persistence/PersistenceManager.swift` |
| Location / Contacts / Mic / Camera / Health | **None.** No CoreLocation, Contacts, AVCaptureSession, AVAudioSession record, or HealthKit usage. | grep — zero matches |
| `UserDefaults` | **Not used.** | grep — zero matches |
| Privacy manifest | `PrivacyInfo.xcprivacy` present and accurate: no collected data types, tracking = false, no tracking domains, empty accessed-API types. | `Chromafield/Resources/PrivacyInfo.xcprivacy` |

---

## App Privacy — Nutrition Label

**Answer to "Do you or your third-party partners collect data from this app?" → `No`.**

This yields a **"Data Not Collected"** privacy label. Rationale: writing a user-created
image/video to the user's own Photo Library is not data *collection* — nothing is
transmitted off-device, linked to the user, or used for tracking.

| Question | Answer |
|----------|--------|
| Contact info | Not collected |
| Health & fitness | Not collected |
| Financial info | Not collected |
| Location | Not collected |
| Sensitive info | Not collected |
| Contacts | Not collected |
| User content | Not collected (created art is saved only to the user's own Photos, at their request) |
| Browsing / search history | Not collected |
| Identifiers | Not collected |
| Usage data / diagnostics | Not collected |
| **Tracking** | **No tracking** (no ATT, no cross-app/site identifiers) |

### Privacy manifest required-reason APIs
`NSPrivacyAccessedAPITypes` is empty, which is correct for this app:
- `FileManager` usage here creates/writes/removes files in the app sandbox; it does
  **not** read file timestamps, free disk space, or system boot time, so no
  required-reason category (`FileTimestamp`, `DiskSpace`, `SystemBootTime`) is triggered.
- No `UserDefaults` → no `UserDefaults` reason needed.

> If Apple's automated check ever flags an API, the only plausible candidate is
> `NSPrivacyAccessedAPICategoryFileTimestamp` — add it with reason code `C617.1`
> (display to user / files created by the app) only if prompted. Current usage does
> not require it.

---

## Export Compliance (encryption)

**`ITSAppUsesNonExemptEncryption` is not set in `project.yml` / Info.plist.** The app
uses no encryption beyond OS-standard system functionality (it makes no network
calls at all).

**Answer the App Store Connect export-compliance question: "Does your app use
encryption?" → `No`.**

To suppress the per-build prompt permanently, add one line to `project.yml` settings
(then `xcodegen generate`):
```yaml
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: false
```
*(Left as a flagged step — not applied here, because it requires regenerating the
Xcode project and a build to verify, which needs the iOS platform installed.)*

---

## Age Rating Questionnaire → **4+**

Answer **None / No** to every content category — the app is abstract generative art
with no text, communication, or objectionable content.

| Category | Answer |
|----------|--------|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic/Sadistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Info | None |
| Alcohol, Tobacco, or Drug Use | None |
| Simulated Gambling | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Contests | None |
| **Unrestricted Web Access** | **No** (no web view, no network) |
| **Gambling (real)** | No |
| **User-Generated Content** | No (no sharing, comments, or accounts — art stays on device) |
| Age Assurance / parental controls needed | No |

**Resulting rating: 4+.**

---

## Permission strings (already in build config — verified)

| Key | Value | Source |
|-----|-------|--------|
| `NSPhotoLibraryAddUsageDescription` | "Chromafield saves your particle art to your photo library." | `project.yml` line 39 |

No other usage-description strings are needed (no other protected resources are accessed).
