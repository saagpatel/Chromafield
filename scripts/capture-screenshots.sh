#!/bin/bash
set -euo pipefail

# Run from any directory. Output is raw simulator UI; headline overlays are separate.
# DERIVED overrides build storage. SHOT_<n>_WAIT overrides post-readiness settling
# (shot 1: 8 seconds; others: 4). READY_TIMEOUT bounds Metal warm-up (default 120).
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
DERIVED=${DERIVED:-.build/shots}
READY_TIMEOUT=${READY_TIMEOUT:-120}

fail() { echo "Screenshot capture: $*" >&2; exit 1; }
for tool in xcodebuild xcrun python3 sips; do
    command -v "$tool" >/dev/null || fail "Required tool missing: $tool"
done
[[ "$READY_TIMEOUT" =~ ^[1-9][0-9]*$ ]] || fail "READY_TIMEOUT must be a positive integer."

# Select the newest available runtime for each exact device name; tie-break by UDID.
# Resolve both devices before building or booting so a missing runtime fails early.
device_rows=$(xcrun simctl list devices available -j | python3 -c '
import json, re, sys
devices = json.load(sys.stdin)["devices"]
required = [
    ("iPhone 18 Pro Max", "iphone-18-pro-max", 1320, 2868),
    ("iPad Pro 13-inch (M5)", "ipad-pro-13-inch-m5", 2064, 2752),
]
rows = []
for name, slug, width, height in required:
    matches = [(tuple(map(int, re.findall(r"\d+", runtime))), device["udid"], device)
               for runtime, entries in devices.items() if ".iOS-" in runtime
               for device in entries if device["name"] == name and device.get("isAvailable", False)]
    if not matches:
        sys.exit(f"Screenshot capture: Missing available simulator {name!r}. Install its iOS runtime and create that exact device in Xcode.")
    _, udid, device = max(matches, key=lambda match: (match[0], match[1]))
    rows.append("\t".join(map(str, (udid, slug, width, height, device["state"]))))
print("\n".join(rows))
')

booted_devices=()
overridden_devices=()
cleanup() {
    local result=$?
    trap - EXIT
    for id in "${overridden_devices[@]-}"; do
        [[ -n "$id" ]] || continue
        if ! xcrun simctl status_bar "$id" clear; then
            echo "Screenshot capture: Could not clear status bar on $id." >&2
            result=1
        fi
    done
    for id in "${booted_devices[@]-}"; do
        [[ -n "$id" ]] || continue
        if ! xcrun simctl shutdown "$id"; then
            echo "Screenshot capture: Could not shut down $id." >&2
            result=1
        fi
    done
    exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

xcodebuild build -project Chromafield.xcodeproj -scheme Chromafield \
    -configuration Debug -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO

# Avoid accidentally installing a stale test host or a different .app.
app=$(python3 -c '
from pathlib import Path
import sys
matches = list((Path(sys.argv[1]) / "Build/Products/Debug-iphonesimulator").glob("Chromafield.app"))
if len(matches) != 1:
    sys.exit("Screenshot capture: Expected one built Chromafield.app in Debug-iphonesimulator.")
print(matches[0].resolve())
' "$DERIVED")
bundle_id=$(python3 -c '
import plistlib, sys
with open(sys.argv[1], "rb") as source:
    identifier = plistlib.load(source).get("CFBundleIdentifier")
if not isinstance(identifier, str) or not identifier:
    sys.exit("Screenshot capture: Built Info.plist has no CFBundleIdentifier.")
print(identifier)
' "$app/Info.plist")

while IFS=$'\t' read -r id slug width height state; do
    if [[ "$state" != "Booted" ]]; then
        xcrun simctl boot "$id"
        booted_devices+=("$id")
    fi
    xcrun simctl bootstatus "$id" -b
    overridden_devices+=("$id")
    xcrun simctl status_bar "$id" override --time 9:41 --dataNetwork wifi \
        --wifiBars 3 --cellularBars 4 --batteryState charged --batteryLevel 100
    xcrun simctl install "$id" "$app"
    xcrun simctl ui "$id" appearance dark
    container=$(xcrun simctl get_app_container "$id" "$bundle_id" data)
    marker="$container/tmp/appstore-screenshot-ready"
    output="$ROOT/screenshots/appstore/$slug"
    mkdir -p "$output"

    for n in 1 2 3 4; do
        # terminate returns nonzero when the app is already stopped.
        xcrun simctl terminate "$id" "$bundle_id" >/dev/null 2>&1 || true
        rm -f "$marker"
        xcrun simctl launch "$id" "$bundle_id" -AppStoreScreenshot "$n"

        deadline=$((SECONDS + READY_TIMEOUT))
        until [[ -f "$marker" && "$(cat "$marker")" == "$n" ]]; do
            (( SECONDS < deadline )) || fail "Shot $n on $slug did not finish Metal warm-up within ${READY_TIMEOUT}s. Inspect the app for Metal or preset errors."
            sleep 1
        done
        wait_variable="SHOT_${n}_WAIT"
        default_wait=4
        [[ "$n" != 1 ]] || default_wait=8
        settle=${!wait_variable:-$default_wait}
        [[ "$settle" =~ ^[0-9]+([.][0-9]+)?$ ]] || fail "$wait_variable must be a nonnegative number of seconds."
        sleep "$settle"

        printf -v filename '%02d.png' "$n"
        image="$output/$filename"
        xcrun simctl io "$id" screenshot "$image"
        dimensions=$(sips -g pixelWidth -g pixelHeight "$image")
        actual_width=$(printf '%s\n' "$dimensions" | awk '/pixelWidth:/ {print $2}')
        actual_height=$(printf '%s\n' "$dimensions" | awk '/pixelHeight:/ {print $2}')
        [[ "$actual_width" == "$width" && "$actual_height" == "$height" ]] || \
            fail "$image is ${actual_width}x${actual_height}; expected ${width}x${height} portrait."
        echo "Captured $image (${width}x${height})"
    done
done < <(printf '%s\n' "$device_rows")

echo "Captured all eight raw App Store screenshots. Review visible UI before adding overlays or uploading."
