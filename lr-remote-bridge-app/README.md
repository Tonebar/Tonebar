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
The GitHub Actions workflow (`.github/workflows/build.yml`) builds **both**
Windows and macOS in GitHub's cloud, using a real macOS runner for the Mac
build — so you don't need to personally own or sit at a Mac to produce the
`.dmg`. You do need five repo secrets set up first (Settings → Secrets and
variables → Actions → "New repository secret"), all obtained from Apple's
side, not from any Mac software:

| Secret name | Where it comes from |
|---|---|
| `APPLE_ID` | Your Apple ID email address |
| `APPLE_TEAM_ID` | Apple Developer account → Membership page (a 10-character code) |
| `APPLE_APP_SPECIFIC_PASSWORD` | Generate at appleid.apple.com → Sign-In and Security → App-Specific Passwords. **Not** your normal Apple ID password. |
| `MAC_CERT_P12_BASE64` | See below — this is the one step that needs a Mac |
| `MAC_CERT_PASSWORD` | A password you choose yourself when exporting that certificate |

**The one step that needs a Mac** (borrow your partner's for ~10 minutes):
1. On the Mac, open **Keychain Access** → menu bar → Certificate Assistant →
   Request a Certificate From a Certificate Authority. Save the `.certSigningRequest`
   file to disk (email address + "Saved to disk", no CA needed).
2. In Apple's [developer portal](https://developer.apple.com/account/resources/certificates/list),
   create a new certificate → **Developer ID Application** → upload that
   request file → download the resulting `.cer`.
3. Double-click the downloaded `.cer` to install it into Keychain Access —
   it'll appear nested under the private key you generated in step 1.
4. In Keychain Access, right-click that certificate → **Export** → save as
   a `.p12` file, and set an export password (this becomes `MAC_CERT_PASSWORD`).
5. In Terminal on the Mac: `base64 -i YourCert.p12 | pbcopy` — this copies
   the base64-encoded certificate to the clipboard. Paste that directly into
   the `MAC_CERT_P12_BASE64` GitHub secret.

Once all five secrets are set, push to `main` (or click "Run workflow" on
the Actions tab) and the `build-mac` job will produce a signed, notarized
`.dmg` — download it from the finished run under **Artifacts** as
`bridge-mac`, same as the Windows one.

## Known limitation carried over from the plain script
Same as before: whichever computer runs this needs its firewall to allow
inbound connections on port 8765, and if your Wi-Fi network has "client
isolation" enabled, phone and computer still won't be able to reach each
other no matter how this app is packaged. That's a network-level
restriction, not something any amount of app polish fixes.
