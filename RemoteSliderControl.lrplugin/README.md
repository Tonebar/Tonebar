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

Valid `ACTION` names: `pick`, `reject`, `auto`, `clipping`
(`before_after` was removed -- there's no documented SDK hook for toggling
Lightroom's before/after view, confirmed against the full LrDevelopController
function list, so it can't be implemented this way.)

## Known rough edges to sanity-check on your machine
- `Texture` and `Dehaze` parameter names are best-effort (same naming
  pattern as the confirmed ones, but not individually re-verified against
  every SDK version) — worth a quick manual test.
- `RESET` sets a slider to 0, which is not always identical to Lightroom's
  own Reset button (that can fall back to non-zero per-camera defaults).
- The plugin switches Lightroom into the Develop module automatically when
  it starts, since `LrDevelopController` calls require Develop to be active.
