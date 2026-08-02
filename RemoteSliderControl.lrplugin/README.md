# Remote Slider Control — Lightroom Classic plugin

## What this is
The Lightroom-side half of the remote slider controller. It listens for
simple text commands and applies them live to the Develop module sliders
of whatever photo is currently active, using the official
`LrDevelopController` API (the same mechanism hardware controllers like
Loupedeck/Palette Gear use).

## Install
1. In Lightroom Classic: File → Plug-in Manager → Add.
2. Select the `RemoteSliderControl.lrplugin` folder.
3. It auto-starts a listener on **127.0.0.1:41102** as soon as it's enabled.
4. Use File → Plug-in Extras → "Remote Slider Control: Show Status" to confirm
   it's running, or "...Restart Listener" if it ever seems stuck.

## Important limitation — read this before building the bridge
`LrSocket` can only bind a socket on **localhost**. It cannot accept
connections from another device on your Wi-Fi network directly. That
means the phone can't talk to this plugin by itself — you need a small
relay program running on the same Mac/PC that:
1. Listens on your LAN for the phone app to connect (e.g. a WebSocket
   server on `0.0.0.0:some_port`)
2. Forwards each received command as a line of text to `127.0.0.1:41102`

That relay is the "Wi-Fi bridge" piece we scoped earlier — build that next
and this plugin will just start working with it.

## Protocol
Newline-terminated ASCII lines, sent to 127.0.0.1:41102:

```
SET exposure 1.35
SET contrast -20
RESET shadows
ACTION pick
ACTION reject
ACTION auto
```

Valid `SET`/`RESET` keys (matching the mobile app's slider keys):
`exposure, contrast, highlights, shadows, whites, blacks, texture, clarity,
dehaze, temp, tint, vibrance, saturation, sharp_amount, sharp_radius,
sharp_detail, sharp_masking, noise_luminance, noise_luminance_detail,
noise_luminance_contrast, vignette_amount, vignette_midpoint,
vignette_feather, vignette_roundness, vignette_highlights,
calib_shadow_tint, calib_red_hue, calib_red_sat, calib_green_hue,
calib_green_sat, calib_blue_hue, calib_blue_sat, mixer_<color>_hue,
mixer_<color>_sat, mixer_<color>_lum` (color = red, orange, yellow, green,
aqua, blue, purple, magenta)

Valid `ACTION` names: `pick`, `reject`, `auto`, `clipping`, `undo`, `redo`,
`rate_1`, `rate_2`, `rate_3`, `rate_4`, `rate_5`,
`copy_settings`, `paste_settings`, `next_photo`, `prev_photo`
(`before_after` was removed -- there's no documented SDK hook for toggling
Lightroom's before/after view, confirmed against the full LrDevelopController
function list, so it can't be implemented this way.)

## Known rough edges to sanity-check on your machine
- `Texture` and `Dehaze` parameter names are best-effort (same naming
  pattern as the confirmed ones, but not individually re-verified against
  every SDK version) — worth a quick manual test.
- The Temp slider's "0" point is captured once (on reset/assign) as
  whatever the current photo's Temperature already was, then reused for
  subsequent drags. If you switch to a different photo *without* resetting
  the Temp slider first, that old baseline carries over and won't match the
  new photo's actual white balance — double-tap (or the Reset quick action)
  to re-sync it to the photo you're now on.
- `next_photo`/`prev_photo` use `LrSelection.nextPhoto()`/`previousPhoto()`,
  which are documented in the SDK reference but haven't been manually
  re-tested against a live catalog yet — worth confirming they move the
  filmstrip selection the way the Left/Right arrow keys do.
- There is no "drive the active brush/local adjustment mask remotely"
  feature, and there can't be one with this plugin's approach:
  `LrDevelopController.setValue`/`getValue` (the only mechanism used here
  for sliders) only reads/writes a photo's global Develop settings, not an
  active local adjustment mask's values. Confirmed by testing on-device,
  not just a documentation read. If you paint a mask manually in Lightroom
  and then use the app's sliders, they'll adjust the whole photo, same as
  always — there's no supported SDK hook to change that.
- Copy/Paste Settings (`copy_settings`/`paste_settings`) *does* carry mask
  geometry across via `getDevelopSettings()`/`applyDevelopSettings()`, but
  pastes it as a literal, static shape rather than re-running Lightroom's
  AI subject detection against the new photo -- so an AI-placed mask (e.g.
  "Select Subject") can land in the wrong spot if the new photo's subject
  isn't in the same position as the one it was copied from. That AI
  re-placement on paste/sync appears to be built into Lightroom's native
  Sync/Copy-Paste commands specifically, not exposed through this SDK
  method -- tried targeting a newer `LrSdkVersion` (13.0) in case it
  unlocked different behavior, no change, reverted back to 6.0. Masks
  copied this way are best treated as a rough starting point to
  reposition by hand, not a finished result.
- No native "Copy Settings" checkbox dialog (choosing which specific
  settings to include) — that's Lightroom's own internal UI with no
  documented plugin hook to invoke or replicate it. This plugin's
  Copy/Paste is always all global-settings-or-nothing.
- `RESET` sets a slider to 0, which is not always identical to Lightroom's
  own Reset button (that can fall back to non-zero per-camera defaults).
- The plugin switches Lightroom into the Develop module automatically when
  it starts, since `LrDevelopController` calls require Develop to be active.
