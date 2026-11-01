# MyEvent

Native macOS app that prepares editable calendar events from selected text with a global shortcut. The regular Dock application has a settings-only window and no menu bar status icon.

## Setup and use

Open `dist/MyEvent.app`. Settings opens at 512 × 471 points including the title bar, matching the compact reference. It can be enlarged; longer content scrolls. Restarting restores this default size. In General choose a language and shortcut. Default duration/time controls have been removed. There are no sound controls. In Permissions authorize Accessibility. In Accounts authorize full calendar access and check one or more writable calendars. Only accounts synced with macOS Calendar are available; each chosen calendar receives a separate copy.

Select text in another app, press your shortcut and release the keys. MyEvent parses the original dates, translates the text if needed, and opens a separate editable draft. Review the title, start/end dates, location, link and notes, then click Create event to save. Cancel or close the draft to discard it without writing to Calendar. The bottom-right Quit button exits MyEvent and disables the shortcut. The highlighted Hide button at the far right hides the app and keeps the shortcut running; click its Dock icon to show Settings again. The red close button on Settings quits MyEvent and disables the shortcut, as does ⌘Q. The yellow button only minimizes Settings and keeps the app running. Closing Help does not quit the app. Edit or delete created events in Calendar.

The twelve languages are English, Mandarin (Simplified), Hindi, Spanish, Arabic, French, Portuguese, German, Italian, Russian, Dutch and Romanian. Arabic uses a right-to-left layout. Removed language preferences fall back to English.

The language selection controls the interface **and the event title and notes**. On-device translation between different languages requires **macOS 26+**, supported source/target languages and installed translation models. The source language is detected automatically. Translation runs in the background when models and permissions are ready, without an intermediate popup before event review. If that attempt cannot complete, a temporary translation window allows macOS to request consent and download missing models before preparing the draft. Cancel or close this window to discard the request. If a download cannot complete, install the models in System Settings → General → Language & Region → Translation Languages. Settings has no translation source list or preparation button. Unsupported pairs, missing models and unidentified source languages block event creation rather than silently saving untranslated text. Same-language text can be saved on older supported macOS versions (14+). Mixed-language selections and short text may be recognized incorrectly.

Draft notes contain a labeled location if present, email references, web links and the full translated details, with generated Start/End and Details labels removed from the editor. The reviewed notes are saved as edited; dates are not regenerated inside them. No untranslated original is appended. Email references do not issue invitations. The first web link is also stored in the event URL field. Event dates come from the original selection. Without a recognized date, tomorrow at 09:00 is proposed; without an end time, a one-hour duration is proposed. Review and change these suggestions in the popup; retired defaults are ignored. One selection is one event per destination; recurrences and multi-event lists are not expanded.

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

Sound controls remain removed. The shortcut prepares a separate editable native popup without reopening Settings. Nothing is saved before Create event. The popup checks a non-empty title, end after start, and an optional http/https link. Save failures retain edits for retry; successful confirmation disables editing and removes the create button to prevent duplicate submissions. The panel stays open until manually closed. Closing an unconfirmed draft discards it. Closing Settings with its red button still quits MyEvent and disables the shortcut.

Destination calendars are captured when preparing each draft and displayed in the popup. Account changes affect future drafts; unavailable reviewed destinations block confirmation. The popup does not open Calendar or Outlook or request Automation permission. Manual edits are saved as entered, without automatic retranslation.

## Source repository

The public source repository is [yvancognasse/MyEvent](https://github.com/yvancognasse/MyEvent). This Mac folder is the working checkout for development, compilation and testing. Git history starts with the current 1.3.13 / build 17 baseline; earlier builds were not stored in Git.

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
