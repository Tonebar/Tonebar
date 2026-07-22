# Remote Slider Control Bridge (desktop app)

The menu-bar version of the Wi-Fi bridge — same protocol and behavior as
`lr-remote-bridge/server.js`, but running as a background tray app instead
of a Terminal window.

## What this adds over the plain script
- Lives in the menu bar (macOS) / system tray (Windows) — no Terminal window
- Shows connection status, your LAN address, and pairing token in the tray
  menu instead of printed log lines
- "Start at login" toggle, so it's just always running
- "Reveal Lightroom plugin folder" — copies the bundled plugin out to
  Documents and opens it in Finder/Explorer, so the remaining manual step
  (Lightroom's Plug-in Manager → Add) has something ready to point at

## Run it in development
```
npm install
npm start
```
A tray icon should appear. Click it for status, address, and token — same
as before, just no terminal to keep open.

## Building an actual installer
```
npm run dist
```
This produces a `.dmg` (Mac) or installer `.exe` (Windows) in `dist/`. That
build will work locally, but **it will not be signed or notarized yet** —
which matters a lot for real distribution:

- **macOS**: Gatekeeper blocks unsigned apps by default. Real distribution
  needs an Apple Developer ID certificate (part of the $99/year Apple
  Developer Program) and notarization. `electron-builder` handles both
  once you set `CSC_LINK` / `CSC_KEY_PASSWORD` (your cert) and
  `APPLE_ID` / `APPLE_ID_PASS` / `APPLE_TEAM_ID` (an app-specific password,
  not your normal Apple ID password) as environment variables before
  running `npm run dist` — see electron-builder's own docs for the exact
  current variable names, since these do shift between versions.
- **Windows**: not strictly required, but without a code-signing
  certificate, Windows SmartScreen will show an "unknown publisher"
  warning on first run. A cert removes that.

None of the above can be done on your behalf — both require your own
developer identity and paid enrollment.

## Building without owning a Mac
`electron-builder` can only reliably produce a macOS build when run on
actual macOS, and needs at least some code-signing setup to do it cleanly
even for an unsigned build. The included GitHub Actions workflow
(`.github/workflows/build.yml`) currently builds **Windows only** for that
reason — the Mac job is commented out in the workflow, ready to re-enable
once you've got your Apple Developer ID:

1. Push this project to a GitHub repo (public repos get free Actions
   minutes with no monthly cap; private repos get a solid free allowance too)
2. Go to the repo's **Actions** tab — it builds automatically on push, or
   click "Run workflow" to trigger it manually
3. Once it finishes, open the run and download the **Artifact** —
   `bridge-windows`, containing the installer

When you're ready to add Mac back in: uncomment the block at the bottom of
`build.yml`, add your Apple Developer ID certificate and Apple ID
credentials as repo secrets (Settings → Secrets and variables → Actions),
and reference them as env vars in the workflow step — electron-builder
will then sign and notarize automatically as part of that same build.

## Known limitation carried over from the plain script
Same as before: whichever computer runs this needs its firewall to allow
inbound connections on port 8765, and if your Wi-Fi network has "client
isolation" enabled, phone and computer still won't be able to reach each
other no matter how this app is packaged. That's a network-level
restriction, not something any amount of app polish fixes.
