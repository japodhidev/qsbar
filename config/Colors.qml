pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Equivalent of polybar's ${xrdb:colorN}. Quickshell has no xrdb reader, so we
// shell out to `xrdb -query` at startup and parse colorN entries out of it.
// The fallback palette is used until that returns, and for any missing entry.
//
// The palette is re-read on demand, replacing polybar's `pkill -USR1 polybar`:
//   qs -c <config-name> ipc call colors reload
// Every colorN binding is reactive, so the bars repaint without restarting.
Singleton {
    id: root

    readonly property var fallback: [
        "#282a2e", // 0  background
        "#a54242", // 1  red
        "#8c9440", // 2  green
        "#de935f", // 3  yellow
        "#5f819d", // 4  blue
        "#85678f", // 5  magenta
        "#5e8d87", // 6  cyan
        "#c5c8c6", // 7  foreground
        "#707880"  // 8  bright black
    ]

    property var resources: ({})

    function query(index) {
        const key = "color" + index;
        const value = root.resources[key];
        return (value !== undefined && value !== null && value !== "") ? value : root.fallback[index];
    }

    readonly property color color0: query(0)
    readonly property color color1: query(1)
    readonly property color color2: query(2)
    readonly property color color3: query(3)
    readonly property color color4: query(4)
    readonly property color color5: query(5)
    readonly property color color6: query(6)
    readonly property color color7: query(7)
    readonly property color color8: query(8)

    // Semantic names, mapped exactly as the polybar config did.
    readonly property color background: color0
    readonly property color foreground: color7
    readonly property color accent: color4      // format-prefix-foreground
    readonly property color separator: color6   // separator-foreground
    readonly property color dimmed: "#555555"

    // Re-run `xrdb -query`. If a query is already in flight (e.g. two reloads
    // arrive back to back), queue exactly one more so the newest palette wins.
    property bool refreshQueued: false

    function refresh() {
        if (xrdb.running) {
            root.refreshQueued = true;
            return;
        }
        xrdb.running = true;
    }

    IpcHandler {
        target: "colors"

        function reload(): void {
            root.refresh();
        }
    }

    Process {
        id: xrdb
        running: true
        command: ["xrdb", "-query"]

        onExited: {
            if (root.refreshQueued) {
                root.refreshQueued = false;
                xrdb.running = true;
            }
        }

        stdout: StdioCollector {
            id: xrdbOut

            onStreamFinished: {
                const parsed = {};
                for (const line of xrdbOut.text.split("\n")) {
                    const match = line.match(/color(\d+)\s*:\s*(\S+)/);
                    if (match)
                        parsed["color" + match[1]] = match[2];
                }
                root.resources = parsed;
            }
        }
    }
}
