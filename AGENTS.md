# MyEvent maintenance rules

These requirements come from the user's explicit instructions.

- On every code modification, review and update the English user guide in `docs/help.template.html` to describe the resulting behavior and limitations. Never edit the generated `Resources/help.html` directly.
- Build with `./scripts/build.sh`. Its release updater increments the build number, records the UTC build date, increments the patch version on code changes, and regenerates the bundled guide. The footer must show that same version, build and date.
- `python3 scripts/update_release.py --check` must pass after the final build. A code change without a guide edit is deliberately rejected by the release updater.
- The request for an online guide remains in scope. Online hosting is currently blocked because Sites is disabled in this workspace. Do not invent a hosted URL or call the local HTML guide online. If hosting becomes available, publish the updated guide on every release and verify the live version.
- Supported languages: English, Mandarin (Simplified), Hindi, Spanish, Arabic, French, Portuguese, German, Italian, Russian, Dutch. Do not restore Bengali, Indonesian, Urdu or Romanian.
- The selected language governs the event title and notes as well as the UI. Never silently save an untranslated fallback if translation is needed and unavailable. Keep original dates, preserve selected details in translated notes, and never invent attendees or issue calendar invitations.
- Test using mocks/fixtures where possible; do not create arbitrary events in the user's real calendars.

## GitHub source management

- The public source repository is `https://github.com/yvancognasse/MyEvent`; the local MyEvent folder remains the working checkout for native macOS builds and tests.
- Use `main` and the `origin` remote. Preserve unrelated user changes. After an authorized code change, update help/version metadata, run the appropriate checks, and commit/push the completed source changes when GitHub authentication is available. Report a failed or blocked push; never imply that unpushed local edits are backed up remotely.
- Keep compiled applications, build caches, generated iconset files, credentials and signing material excluded. Do not make the repository public or change its access without explicit instruction.
