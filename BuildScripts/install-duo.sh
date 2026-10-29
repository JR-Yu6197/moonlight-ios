#!/bin/bash
#
# Builds the personal iPhone Duo build of Moonlight and installs it on a
# connected iPhone. Apps signed with a free Apple ID expire after 7 days,
# so run this again at least once a week.
#
# Usage: BuildScripts/install-duo.sh [device name or UDID]   (default: JRiPhone)
#
set -euo pipefail

DEVICE="${1:-JRiPhone}"
BUNDLE_ID="com.jryu6197.moonlight-duo"
LOG="DerivedData/install-duo.log"

# xcodebuild matches a UDID with id= and a device name with name=
if [[ "$DEVICE" =~ ^[0-9A-Fa-f-]{24,}$ ]]; then
    DESTINATION="platform=iOS,id=$DEVICE"
else
    DESTINATION="platform=iOS,name=$DEVICE"
fi

cd "$(dirname "$0")/.."
mkdir -p DerivedData

# Release builds are optimized, which matters for streaming performance
echo "Building for $DEVICE..."
if ! xcodebuild -project Moonlight.xcodeproj -scheme Moonlight -configuration Release \
        -destination "$DESTINATION" -derivedDataPath DerivedData \
        -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
        build > "$LOG" 2>&1; then
    grep -E "error:" "$LOG" | head -20 || true
    echo "Build failed. Full log: $LOG" >&2
    exit 1
fi

xcrun devicectl device install app --device "$DEVICE" DerivedData/Build/Products/Release-iphoneos/Moonlight.app
# Launching fails while the phone is locked, which is fine since it's installed
xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID" > /dev/null 2>&1 ||
    echo "Installed. Unlock the phone and open Moonlight Duo."
