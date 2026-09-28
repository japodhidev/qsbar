# Quickshell Bars

A two-bar desktop panel built with [Quickshell](https://quickshell.org): a **top
bar** with workspaces, clock and system stats, and a **bottom bar** with the
current MPD track and the system tray. One pair of bars is created for every
connected monitor. Colors come from the X resource database (`xrdb`) and can be
reloaded on the fly without restarting the shell.

```
top bar     [ workspaces ]      [ date and time ]      [ CPU | VOL | RAM | network ]

                               (your windows)

bottom bar                       [ MPD track ]                          [ tray icons ]
```

## Contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [Running and autostart](#running-and-autostart)
4. [Project structure](#project-structure)
5. [How it works](#how-it-works)
6. [Modules](#modules)
7. [Colors and live reloading](#colors-and-live-reloading)
8. [Configuration](#configuration)
9. [Extending the bars](#extending-the-bars)
10. [Troubleshooting](#troubleshooting)

---

## Requirements

### Quickshell

Developed against **Quickshell 0.3.x** (Qt 6). Your Quickshell build must include
the following optional features, which most distribution packages enable by
default:

| Feature | Used by |
| --- | --- |
| Window/panel support for your session (X11, or Wayland with layer-shell) | Both bars |
| System tray (`Quickshell.Services.SystemTray`) | Tray |
| PipeWire (`Quickshell.Services.Pipewire`) | Volume |

The command is installed as both `quickshell` and `qs`; this document uses `qs`.

### Programs

| Program | Needed for | If missing |
| --- | --- | --- |
| `xrdb` | Reading colors from `.Xresources` | Built-in fallback palette is used |
| `i3-msg` | Workspaces on i3 (and sway's i3-compatible socket) | No workspaces shown |
| `bspc` | Workspaces on bspwm | No workspaces shown |
| `mpc` | MPD track display | MPD module stays hidden |
| `ip` (iproute2) | Network module | Network module stays hidden |
| PipeWire (running) | Volume module | Volume shows `VOL 0%` |

You only need the workspace tool for the window manager you actually run.

### Font

The bars use **Cousine Nerd Font** at 9 pt. If it is not installed, Qt falls back
to a default font. To use another font, change `fontFamily` in
[`config/Theme.qml`](config/Theme.qml).

---

## Installation

Quickshell loads configurations from `~/.config/quickshell/<name>/`. Copy the
project there under any name you like:

```sh
mkdir -p ~/.config/quickshell
cp -r quickshell ~/.config/quickshell/bars
```

The directory must contain `shell.qml` at its top level, plus the `bars/`,
`config/` and `modules/` folders exactly as laid out below. In particular,
**`config/qmldir` must be present** — without it `Colors` and `Theme` do not
resolve as singletons and the bars will fail with "unable to assign undefined"
errors.

### Defining colors

Colors are read from the X resource database. Add entries for `color0`–`color8`
to `~/.Xresources` and load them:

```
*.color0: #282a2e
*.color1: #a54242
*.color2: #8c9440
*.color3: #de935f
*.color4: #5f819d
*.color5: #85678f
*.color6: #5e8d87
*.color7: #c5c8c6
*.color8: #707880
```

```sh
xrdb -merge ~/.Xresources
```

This step is optional. Any color that is not defined falls back to the built-in
palette shown above.

---

## Running and autostart

Start the bars from a terminal first, so that any QML warnings are visible:

```sh
qs -c bars              # loads ~/.config/quickshell/bars
qs -p /path/to/project  # or load from an explicit path
```

`console.log` output and QML errors are printed to the terminal that launched
Quickshell.

To start the bars with your session, launch them from your window manager's
startup file. Use the same `-c` / `-p` flag you tested with.

**i3** (`~/.config/i3/config`) — use `exec`, not `exec_always`, so reloading i3
does not start a second copy:

```
exec --no-startup-id qs -c bars
```

**bspwm** (`~/.config/bspwm/bspwmrc`):

```sh
pgrep -x quickshell >/dev/null || qs -c bars &
```

Quickshell watches its configuration directory and hot-reloads automatically when
you save a file, so edits to the QML files show up immediately.

---

## Project structure

```
quickshell/
├── shell.qml                 Entry point: one top bar and one bottom bar per screen
├── config/
│   ├── qmldir                Registers Colors and Theme as singletons (required)
│   ├── Colors.qml            Palette loaded from xrdb, plus the IPC reload handler
│   └── Theme.qml             Font, sizes, spacing, separator character
├── bars/
│   ├── MainBar.qml           Top bar layout
│   └── BottomBar.qml         Bottom bar layout
└── modules/
    ├── BarText.qml           Shared text element (font set in one place)
    ├── BarModule.qml         "PREFIX value" pair, e.g. `CPU ` + `7%`
    ├── Separator.qml         The `|` between modules
    ├── Workspaces.qml        Picks the i3 or bspwm backend
    ├── I3Workspaces.qml      Workspaces via i3-msg
    ├── BspwmWorkspaces.qml   Workspaces via bspc
    ├── DateTime.qml          Clock
    ├── Cpu.qml               CPU usage
    ├── Memory.qml            RAM usage
    ├── Volume.qml            Default audio sink volume
    ├── Network.qml           Wired interface and IPv4 address
    ├── Mpd.qml               Current MPD track
    └── Tray.qml              System tray icons and menus
```

---

## How it works

### Startup

`shell.qml` is the root of the configuration. It creates two `Variants` objects,
each with `Quickshell.screens` as its model, so a `MainBar` and a `BottomBar`
window are created for every connected monitor and are added or removed
automatically as monitors are connected and disconnected.

The first line of `shell.qml`, `//@ pragma UseQApplication`, switches Quickshell
to a full `QApplication`. This is required for system tray context menus to be
able to display.

### Bars

Both bars are `PanelWindow`s anchored to the top (or bottom) edge and spanning
the full width of the screen. Their height comes from `Theme.barHeight`, and the
window reserves that space (`ExclusionMode.Auto`) so other windows do not overlap
it. Each bar is divided into three regions — left, center, right — each a
`RowLayout` pinned to its edge, with modules placed inside.

### Singletons and imports

`Colors` and `Theme` are singletons: one shared instance for the whole shell.
Each is declared with `pragma Singleton`, uses Quickshell's `Singleton` base
type, and is registered in `config/qmldir`. Any file can then read
`Colors.color4` or `Theme.barHeight` after `import "../config"`.

All imports in this project are **relative** (`import "../config"`,
`import "./bars"`). Quickshell's documentation discourages `root:/` imports
because they break the language server and singleton resolution. If you move a
file to a different folder, update its relative imports to match.

### Data sources

Modules do not poll a helper script. Each one gets its data directly:

| Module | Source | Update trigger |
| --- | --- | --- |
| Workspaces (i3) | `i3-msg -t get_workspaces`, `i3-msg -t subscribe` | Pushed by i3 on every workspace event |
| Workspaces (bspwm) | `bspc subscribe report` | Pushed by bspwm on every change |
| Clock | Quickshell `SystemClock` | Every second |
| CPU | `/proc/stat` | Every 2 seconds |
| Memory | `/proc/meminfo` | Every 2 seconds |
| Volume | Quickshell PipeWire service | Event-driven |
| Network | `/sys/class/net` and `ip -4` | Every 5 seconds |
| MPD | `mpc current`, `mpc idleloop player` | Player events, plus every 2 seconds |
| Tray | Quickshell SystemTray service (D-Bus) | Event-driven |

---

## Modules

### Top bar

| Region | Contents |
| --- | --- |
| Left | Workspaces |
| Center | Date and time |
| Right | CPU, Volume, RAM, Network — separated by `\|` |

**Workspaces.** `Workspaces.qml` chooses a backend at startup:

- If `$I3SOCK` or `$SWAYSOCK` is set, the i3 backend is used.
- Otherwise, if `$BSPWM_SOCKET` is set, the bspwm backend is used.
- Otherwise it defaults to i3.

If your session does not export those variables and the wrong backend is chosen,
edit `sourceComponent` in [`modules/Workspaces.qml`](modules/Workspaces.qml) to
return the component you want. The sway path relies on sway's i3-compatible
socket and has not been tested.

Each bar only shows workspaces that belong to its own monitor.

*i3 backend.* Numeric prefixes are stripped from names (`2:web` is shown as
`web`). The focused workspace has an underline in `color8`; an urgent workspace
has a `color3` background. Clicking a workspace switches to it.

*bspwm backend.* The focused desktop is drawn as `color0` text on a `color2`
background; an urgent desktop as `color3` text on `color7`; occupied desktops in
the normal foreground; empty desktops dimmed. Clicking is disabled by default —
uncomment the `MouseArea` in
[`modules/BspwmWorkspaces.qml`](modules/BspwmWorkspaces.qml) to enable it.

**Date and time.** Displays, in `color2`, for example
`Monday, 28 September 2026 14:05 PM`. **Click** to toggle an alternative format
that includes seconds and a 12-hour clock. The format strings are in
[`modules/DateTime.qml`](modules/DateTime.qml) and use Qt's
`Qt.formatDateTime` syntax. Note that the default format combines a 24-hour hour
(`HH`) with an AM/PM marker (`AP`); remove `AP` or change `HH` to `hh` if you
want them to agree.

**CPU / RAM.** `CPU  7%` and `RAM 31%`. Usage is computed from `/proc/stat` (the
difference between two samples) and from `MemTotal − MemAvailable` in
`/proc/meminfo`. The prefix is drawn in `color4`.

**Volume.** Shows `VOL 40%` for the default PipeWire output, or `muted` (in
`color6`). Interactions:

- **Left click** — toggle mute
- **Scroll up / down** — volume ±2%

Volume is capped between 0% and 100%.

**Network.** Shows the first wired (non-wireless, non-loopback) interface that is
up and has an IPv4 address, e.g. `eth0 192.168.1.20`. If no wired interface is up
it shows `<interface> disconnected`. If the machine has no wired interface at
all — for example a Wi-Fi-only laptop — the module hides itself.

### Bottom bar

| Region | Contents |
| --- | --- |
| Left | (empty) |
| Center | MPD track |
| Right | System tray |

**MPD.** Shows `Artist - Title | Album`, truncated with an ellipsis after 100
characters. The module is hidden when nothing is playing or the MPD server cannot
be reached. `mpc` honors the standard `MPD_HOST` and `MPD_PORT` environment
variables, so export them in the session that starts Quickshell if your server is
not on `localhost:6600`.

**System tray.** Shows the icons of running tray applications (20 px, spaced 8 px
apart). Interactions:

- **Left click** — activate the application (or open its menu, if the item only
  offers a menu)
- **Middle click** — secondary action
- **Right click** — open the context menu

The menu opens directly above the clicked icon, positioned flush with the top
edge of the bar.

---

## Colors and live reloading

### Palette roles

Only `color0`–`color8` are read. `color1` and `color5` are loaded but not
currently used by any module.

| Color | Used for |
| --- | --- |
| `color0` | Bar background; text on highlighted bspwm workspace; text on urgent i3 workspace |
| `color2` | Clock text; focused bspwm workspace background |
| `color3` | Urgent workspace highlight |
| `color4` | `CPU` / `VOL` / `RAM` prefixes; network text |
| `color6` | Separators; `muted` label |
| `color7` | Default foreground text; urgent bspwm workspace background |
| `color8` | Focused i3 workspace underline |

Empty bspwm workspaces use a fixed `#555555`. Everywhere else in QML, colors are
referenced as `Colors.color0` … `Colors.color8`, or through the aliases
`Colors.background`, `Colors.foreground`, `Colors.accent` and `Colors.separator`.

### How colors are loaded

At startup `Colors.qml` runs `xrdb -query` and extracts every `colorN: value`
line. For each index, if the database has a value it is used; otherwise the
built-in fallback palette is used. Because every color property is a reactive
binding, updating the palette repaints all bars immediately — nothing needs to
be rebuilt.

If more than one resource defines the same `colorN`, the last one in the
`xrdb -query` output wins.

### Reloading colors while running

`Colors.qml` exposes an IPC handler named `colors`. Calling it makes Quickshell
re-run `xrdb -query` and repaint the bars in place; it does not restart the shell
or reload the configuration.

```sh
xrdb -merge ~/.Xresources          # 1. update the X resource database
qs -c bars ipc call colors reload  # 2. tell the bars to pick it up
```

Notes:

- Run the reload **after** `xrdb -merge` has finished, otherwise the old palette
  is read.
- Address the instance with the same flag you started it with (`-c bars` or
  `-p /path`). This only affects that instance; other Quickshell instances are
  untouched.
- If reloads arrive while a query is still running, one further query is queued
  so the newest palette always wins.
- `qs -c bars ipc show` lists all registered IPC targets, which is a quick way to
  confirm the shell is running and the handler is registered.

**Automating it.** Any program that changes the palette can trigger a reload by
running the command above after it merges its colors. For example, a small
wrapper script:

```sh
#!/bin/sh
xrdb -merge "$1" && qs -c bars ipc call colors reload
```

From C++ or another language, run `qs -c bars ipc call colors reload` as a
detached child process.

---

## Configuration

Most adjustments belong in [`config/Theme.qml`](config/Theme.qml):

| Property | Default | Meaning |
| --- | --- | --- |
| `fontFamily` | `Cousine Nerd Font` | Font used for all text |
| `fontSize` | `9` | Font size in points |
| `barHeight` | `24` | Height of each bar in pixels |
| `barPadding` | `8` | Padding at the left and right ends of a bar |
| `moduleMargin` | `8` | Gap between adjacent modules |
| `lineSize` | `3` | Thickness of the focused-workspace underline |
| `workspacePadding` | `8` | Horizontal padding inside each workspace label |
| `separator` | `\|` | Character drawn between modules |
| `trayIconSize` | `20` | Tray icon size |
| `traySpacing` | `8` | Gap between tray icons |
| `trayPadding` | `4` | Extra horizontal click area around each tray icon |

Other common changes:

- **Show bars on one monitor only.** In `shell.qml`, replace the `Variants`
  models with a filtered list, e.g.
  `model: Quickshell.screens.filter(s => s.name === "DP-1")`. Find monitor names
  with `xrandr -q` (X11).
- **Transparent bars.** In `bars/MainBar.qml` and `bars/BottomBar.qml`, change
  `color: Colors.background` to `color: "transparent"` (requires a compositor)
  or to a color with an alpha channel such as `"#cc282a2e"`.
- **Change the refresh rates.** Each polling module has a `Timer` with an
  `interval` in milliseconds (`Cpu.qml`, `Memory.qml`, `Network.qml`, `Mpd.qml`).
- **Change the fallback palette.** Edit the `fallback` array in
  `config/Colors.qml`.

---

## Extending the bars

### Reorder or remove modules

Module placement is plain QML in `bars/MainBar.qml` and `bars/BottomBar.qml`.
Each region is a `RowLayout`; reorder, delete or add items inside it. When you
add or remove a module on the right side, add or remove the neighboring
`Separator {}` as well.

### Add a module

1. Create `modules/MyModule.qml`. For a `PREFIX value` style label, use
   `BarModule` as the root type:

   ```qml
   import QtQuick
   import Quickshell.Io

   BarModule {
       id: root

       property string temperature: "--"

       prefix: "TMP "
       label: root.temperature

       Process {
           id: sensor
           command: ["sh", "-c", "cat /sys/class/thermal/thermal_zone0/temp"]
           stdout: StdioCollector {
               id: out
               onStreamFinished: root.temperature =
                   Math.round(Number(out.text) / 1000) + "°C"
           }
       }

       Timer {
           interval: 5000
           running: true
           repeat: true
           triggeredOnStart: true
           onTriggered: sensor.running = true
       }
   }
   ```

2. Place it in a bar, e.g. in the right-hand `RowLayout` of
   `bars/MainBar.qml`:

   ```qml
   MyModule {}
   Separator {}
   ```

Files in `modules/` can reference each other by name (`BarModule`, `BarText`,
`Separator`) without an import because they share a folder. To use colors or
theme values in a new file, add `import "../config"`.

For free-form modules, use `BarText` for any text so the font stays consistent,
and set `Layout.alignment: Qt.AlignVCenter` on the root item so it centers
vertically in the bar.

---

## Troubleshooting

**`Unable to assign [undefined] to QColor`**
`Colors` is not resolving as a singleton. Confirm `config/qmldir` exists and
contains both `singleton` lines, that `Colors.qml` begins with
`pragma Singleton`, and that it imports `QtQuick` (which provides the `color`
type). Also make sure no file still uses a `root:/…` import.

**To inspect a color where it is used**, turn the binding into a block and log it:

```qml
property color labelColor: {
    console.log("Colors:", Colors, "foreground:", Colors.foreground);
    return Colors.foreground;
}
```

If `Colors` itself prints as `undefined`/`null`, the singleton is not resolving;
if only `foreground` is undefined, the problem is inside `Colors.qml`.

**The bars have my fallback colors, not my `.Xresources` colors**
Check that `xrdb` is installed (`which xrdb`) and that
`xrdb -query | grep color` prints your values. Colors are only read at startup
and on `colors reload`; after changing them, run `xrdb -merge` and then
`qs -c bars ipc call colors reload`.

**`ipc call` says no instance was found, or hits the wrong one**
`qs ipc` needs to identify the running instance. Pass the same `-c <name>` or
`-p <path>` you launched with. If several instances of the same config are
running, close the extras first.

**No workspaces appear**
Check that `i3-msg` (or `bspc`) works in a terminal. If the wrong backend is
selected, see [Modules → Workspaces](#modules) and set `sourceComponent`
explicitly. Workspaces are filtered by monitor name, so an output name that
differs between the window manager and Quickshell hides them; temporarily
removing the filter in the workspace module confirms this.

**Tray menu does not open, or opens in the wrong place**
Make sure the first line of `shell.qml` is `//@ pragma UseQApplication`; without
it tray menus cannot be shown. Menu placement is controlled by the last two lines
of the click handler in `modules/Tray.qml`: the X position is the icon's center
mapped into the bar window, and Y is `0` (the top edge of the bar).

**The volume always reads 0%, or scrolling does nothing**
The module talks to PipeWire directly. Confirm PipeWire is running and that your
Quickshell build includes the PipeWire feature.

**The network module is missing**
It only shows wired interfaces. It is hidden when the machine has none, and
requires `ip` (iproute2).

**The MPD module is missing**
It is hidden when `mpc current` returns nothing. Run `mpc current` in a terminal
to check; if it cannot connect, export `MPD_HOST` / `MPD_PORT` in the environment
that launches Quickshell.

**Text looks wrong or icons are missing**
Install Cousine Nerd Font or set another installed font in `config/Theme.qml`.
