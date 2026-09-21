# Quickshell port of the polybar config

A one-to-one translation of the attached `config.ini`: a top bar (`bar/main`)
and a bottom bar (`bar/bottom`), one pair per connected output.

## Install

```sh
cp -r quickshell ~/.config/quickshell/polybar   # any name you like
quickshell -p ~/.config/quickshell/polybar      # or: quickshell -c polybar
```

## Layout

```
shell.qml            one MainBar + one BottomBar per screen
config/Colors.qml    ${xrdb:colorN} → parsed from `xrdb -query`, with fallbacks
config/Theme.qml     font, bar height, paddings, separator — edit here first
bars/MainBar.qml     top bar: workspaces | date | cpu, volume, ram, eth
bars/BottomBar.qml   bottom bar: mpd | tray
modules/             one file per polybar [module/...]
```

## Module mapping

| polybar | Quickshell | notes |
| --- | --- | --- |
| `internal/i3` | `I3Workspaces.qml` | `i3-msg -t subscribe`; works on sway too |
| `internal/bspwm` | `BspwmWorkspaces.qml` | parses `bspc subscribe report` |
| `internal/date` | `DateTime.qml` | `SystemClock`; click toggles the `-alt` format |
| `internal/cpu` | `Cpu.qml` | diffs `/proc/stat` every 2s |
| `internal/memory` | `Memory.qml` | `MemTotal - MemAvailable` from `/proc/meminfo` |
| `custom/script` (paudio) | `Volume.qml` | native PipeWire, no `sound.sh` needed |
| `internal/network` | `Network.qml` | first wired interface with an IPv4 address |
| `internal/mpd` | `Mpd.qml` | `mpc idleloop player` + `mpc current` |
| `internal/tray` | `Tray.qml` | `Quickshell.Services.SystemTray` |

`alsa`, `pulseaudio`, `xworkspaces` and `xwindow` were defined but unused in
the polybar config, so they are not ported. `Volume.qml` covers the first two.

## Runtime dependencies

- `xrdb` — optional; without it the fallback palette in `Colors.qml` is used
- `i3-msg` **or** `bspc` — whichever WM you run
- `mpc` — for the MPD module
- `iproute2` (`ip`) — for the network module
- PipeWire — for the volume module

## Differences worth knowing

- **Colors are read once at startup.** polybar re-read `.Xresources` on reload;
  here, restart Quickshell (or call `reload()` on the `Process` in `Colors.qml`)
  after changing them.
- **Workspace detection.** `Workspaces.qml` picks the i3 backend if `$I3SOCK` or
  `$SWAYSOCK` is set, bspwm if `$BSPWM_SOCKET` is, and falls back to i3. Hardcode
  `sourceComponent` if your setup doesn't export those.
- **Click on bspwm workspaces is commented out**, matching `enable-click = false`.
- **`pseudo-transparency`** has no equivalent and isn't needed — set
  `color: "transparent"` on a `PanelWindow` for real transparency on a compositor.
- **Padding units.** polybar counts spaces; `Theme.qml` uses pixels, so a few
  values are approximations you may want to nudge.
- Quickshell also ships a first-party `Quickshell.I3` module. If your build has
  it, `I3Workspaces.qml` can be reduced to a `Repeater` over `I3.workspaces`.
