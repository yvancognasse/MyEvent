# MyEvent

Native macOS app that creates calendar events immediately from selected text with a global shortcut. The regular Dock application has a settings-only window and no menu bar status icon.

## Setup and use

Open `dist/MyEvent.app`. In General choose a language, shortcut and default duration/time. There are no sound controls. In Permissions authorize Accessibility. In Accounts authorize full calendar access and check one or more writable calendars. Only accounts synced with macOS Calendar are available; each chosen calendar receives a separate copy.

Select text in another app, press your shortcut and release the keys. MyEvent parses the original dates, translates the text if needed, and saves immediately without a preview. The red close button on Settings quits MyEvent and disables the shortcut, as does ⌘Q. The yellow button only minimizes Settings and keeps the app running. Closing Help does not quit the app. Edit or delete created events in Calendar.

The nine languages are English, Mandarin (Simplified), Hindi, Spanish, Arabic, French, Portuguese, German and Italian. Arabic uses a right-to-left layout. Removed language preferences fall back to English.

The language selection controls the interface **and the event title and notes**. On-device translation between different languages requires **macOS 26+**, supported source/target languages and installed translation models. The source language is detected automatically. If models are missing, install them in System Settings → General → Language & Region → Translation Languages. Settings has no translation source list or preparation button. Unsupported pairs, missing models and unidentified source languages block event creation rather than silently saving untranslated text. Same-language text can be saved on older supported macOS versions (14+). Mixed-language selections and short text may be recognized incorrectly.

Notes contain localized start/end dates, a labeled location if present, email references, web links and the full translated details. No untranslated original is appended. Email references do not issue invitations. The first web link is also stored in the event URL field. Event dates come from the original selection. Without a recognized date, tomorrow and the default time are used; without an end time, the default duration applies. One selection is one event per destination; recurrences and multi-event lists are not expanded.

## Help and release metadata

Open the English guide via **?**, Help → Help (English), or ⌘?. The bundled guide opens in one reusable native MyEvent help window and works offline; it never launches a browser. The application uses a pure AppKit lifecycle with a SwiftUI settings view, so it creates no residual empty Settings scene. Its editable source is `docs/help.template.html`; `Resources/help.html` is generated during each build.

Online publication remains blocked: Sites is disabled for this workspace. No live URL is configured or claimed. Publish the guide for each release once hosting is available, as required by `AGENTS.md`.

Settings displays the version, build number and build date at the bottom. `scripts/build.sh` increments the build number on each invocation, records its UTC date, updates the patch version on source/script changes and regenerates help. A code change without an English guide edit is rejected. A failed build can consume a build number. `.release-state.json` tracks the release fingerprint and must be retained.

## Build and verify

No external dependencies or API key. Requires Xcode with the Translation SDK. The app supports macOS 14+; unattended cross-language translation requires macOS 26+.

```sh
./scripts/build.sh
python3 scripts/update_release.py --check
open dist/MyEvent.app
```

```sh
CLANG_MODULE_CACHE_PATH="$PWD/.build/ModuleCache" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/ModuleCache" \
swift test --disable-sandbox --cache-path .build/cache
python3 -m unittest discover -s Tests -p 'test_*.py'
```

The application is signed with the installed Apple Development certificate by default. Set MYEVENT_SIGNING_IDENTITY to use another certificate; there is no automatic ad-hoc fallback. The one-time change from earlier ad-hoc builds requires removing the old Accessibility entry, re-adding the current app, enabling it and restarting MyEvent. The Permissions tab shows the actual running bundle path and rechecks live status; it never overrides a negative macOS trust result. Distribution to other users needs Developer ID signing and notarization. The stable bundle identifier is retained to preserve preferences from the old MyTime name.

Selected text is processed locally. Apple Translation may collect API-usage and language-pair metrics, excluding source/translated content; see [Apple's documentation](https://developer.apple.com/documentation/translation/translationsession). Calendar account providers may sync event content. MyEvent tries Accessibility first, then Copy and clipboard restoration where needed.

The bundle explicitly declares `AppIcon.icns`, encoded by Apple’s native `iconutil` for correct small Finder list icons; builds refresh its Launch Services registration and the app also sets the Dock icon at launch.


When an accepted shortcut request starts, the Dock icon immediately pulses with a blue ring for at least 1.2 seconds and throughout processing. The indicator acknowledges receipt, not success. The normal icon is restored when processing ends, including on errors. It does not activate MyEvent or disturb the source selection.

## Creation feedback

Sound playback, Preview and all sound controls have been removed. After a successful save, a separate non-activating native popup summarizes the title, start/end times, location, destination calendars and detailed notes. It stays open until you click Close or its window close button. There is no automatic dismissal, and creating another event leaves earlier receipts open. Quitting MyEvent closes all windows. Failure popups also leave Settings alone. A minimized or hidden Settings window stays minimized or hidden; the source app keeps focus. The red Settings close button still quits MyEvent and disables the shortcut, as requested; creation cannot run after the app has quit.

The confirmation popup has only Close. Calendar-opening buttons, the Outlook/Apple Calendar application selector and their automation code have been removed. Accounts still selects the destination calendars for event creation. Open Calendar or Outlook manually to view or edit events. No Automation permission is requested by MyEvent.

The popup notes area omits the generated Start/End preamble and Details heading. The date summary above the divider and the complete calendar event notes are preserved.

## Source repository

The private source repository is [yvancognasse/MyEvent](https://github.com/yvancognasse/MyEvent). This Mac folder is the working checkout for development, compilation and testing. Git history starts with the current 1.3.13 / build 17 baseline; earlier builds were not stored in Git.

The repository contains Swift source, tests, English help, translations, original icon artwork/generator, build scripts and release metadata. Local build outputs, compiled applications, caches and signing material are excluded. No certificate or private key is needed to read the source.

For subsequent development, pull the latest `main`, make changes locally, update the English guide when code changes, run the appropriate checks and `./scripts/build.sh`, then commit and push the reviewed source state. GitHub stores the committed versions; local changes are uploaded when a push succeeds, rather than automatically on every file save.

```sh
git pull --ff-only
# Make and verify the change, then:
git add .
git commit -m "Describe the change"
git push origin main
```

Private clone/push access requires GitHub authentication on the Mac. Never put tokens, credentials or signing certificates in the repository.
