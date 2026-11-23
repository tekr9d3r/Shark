#!/bin/sh
# Build one or more target devices. With no arguments, builds the
# representative spread: the largest round screen, the mid-size MIP round
# screens, the rectangle, and the smallest screen in the target list - the
# four shapes/sizes the procedural layout has to survive.
#
#   ./build.sh                    # the spread
#   ./build.sh fenix7 venu3       # named devices
set -e

export JAVA_HOME="${JAVA_HOME:-/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home}"
export PATH="$JAVA_HOME/bin:$PATH"

SDK="${CIQ_SDK:-$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-9.2.0-2026-06-09-92a1605b2}"
KEY="${CIQ_KEY:-keys/developer_key.der}"

DEVICES="$*"
if [ -z "$DEVICES" ]; then
    DEVICES="instinct3amoled50mm fenix7 venusq2 fr55 venu3 fenix7s"
fi

mkdir -p dist
for device in $DEVICES; do
    printf '%s ... ' "$device"
    "$SDK/bin/monkeyc" -f monkey.jungle -o "dist/Shark-$device.prg" -y "$KEY" -d "$device" -w
    printf 'ok\n'
done
