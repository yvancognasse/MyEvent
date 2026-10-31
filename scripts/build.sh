#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/ModuleCache"
python3 scripts/update_release.py
swift build -c release --disable-sandbox --cache-path .build/cache
APP="$PWD/dist/MyEvent.app"
# Remove retired language resources from earlier packaged versions.
for retired in bn id ur; do
    rm -rf "$APP/Contents/Resources/$retired.lproj"
done
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/MyEvent "$APP/Contents/MacOS/MyEvent"
cp Info.plist "$APP/Contents/Info.plist"
cp -R Resources/. "$APP/Contents/Resources/"
swift scripts/make-icon.swift "$PWD/Assets"
iconutil -c icns Assets/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
# A certificate-based identity preserves the designated requirement across builds.
# Do not silently fall back to ad-hoc signing: that invalidates Accessibility grants.
SIGNING_IDENTITY="${MYEVENT_SIGNING_IDENTITY:-Apple Development}"
codesign --force --sign "$SIGNING_IDENTITY" --timestamp=none "$APP"
touch "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
echo "Application créée : $APP"
