import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../config"

// [module/eth] (inherits [network-base])
// Picks the first non-loopback, non-wireless interface and reports its IPv4
// address, matching `label-connected = %ifname% %local_ip%`.
BarModule {
    id: root

    property string interfaceName: ""
    property string address: ""
    property bool connected: false

    readonly property string probe: `
for dev in /sys/class/net/*; do
    name=\${dev##*/}
    [ "$name" = lo ] && continue
    [ -d "$dev/wireless" ] && continue
    [ "$(cat "$dev/operstate" 2>/dev/null)" = up ] || continue
    addr=$(ip -4 -o addr show "$name" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
    [ -n "$addr" ] || continue
    echo "up $name $addr"
    exit 0
done
for dev in /sys/class/net/*; do
    name=\${dev##*/}
    [ "$name" = lo ] && continue
    [ -d "$dev/wireless" ] && continue
    echo "down $name"
    exit 0
done
`

    // label-connected-foreground / label-disconnected-foreground = color4
    labelColor: Colors.accent
    label: {
        if (root.interfaceName === "")
            return "";
        return root.connected
            ? root.interfaceName + " " + root.address
            : root.interfaceName + " disconnected";
    }
    visible: root.interfaceName !== ""

    Process {
        id: probeProcess
        running: true
        command: ["sh", "-c", root.probe]

        stdout: StdioCollector {
            id: probeOut

            onStreamFinished: {
                const parts = probeOut.text.trim().split(/\s+/);
                if (parts.length < 2) {
                    root.interfaceName = "";
                    root.connected = false;
                    return;
                }

                root.connected = parts[0] === "up";
                root.interfaceName = parts[1];
                root.address = parts[2] ?? "";
            }
        }
    }

    Timer {
        interval: 5000          // interval = 5
        running: true
        repeat: true
        onTriggered: probeProcess.running = true
    }
}
