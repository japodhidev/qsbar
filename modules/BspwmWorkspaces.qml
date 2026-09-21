import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"

// [module/bspwm]
// `bspc subscribe report` emits one status line per change, e.g.
//   WMDP-1:Oweb:fterm:fchat:LT:TT:G
// Uppercase desktop flags mean focused, O/o occupied, F/f free, U/u urgent.
RowLayout {
    id: root

    property string screenName: ""
    property var desktops: []

    spacing: 0
    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: true

    function parseReport(line) {
        if (!line.startsWith("W"))
            return;

        const parsed = [];
        let monitor = "";

        for (const field of line.substring(1).split(":")) {
            if (field.length === 0)
                continue;

            const flag = field[0];
            const value = field.substring(1);

            if (flag === "M" || flag === "m") {
                monitor = value;
            } else if ("OFUofu".indexOf(flag) !== -1) {
                parsed.push({
                    name: value,
                    monitor: monitor,
                    focused: flag === flag.toUpperCase(),
                    occupied: flag === "O" || flag === "o",
                    urgent: flag === "U" || flag === "u"
                });
            }
        }

        root.desktops = parsed;
    }

    Process {
        running: true
        command: ["bspc", "subscribe", "report"]

        stdout: SplitParser {
            onRead: data => root.parseReport(data.trim())
        }
    }

    Repeater {
        // pin-workspaces = true
        model: root.desktops.filter(ws => root.screenName === "" || ws.monitor === root.screenName)

        delegate: Rectangle {
            id: chip

            required property var modelData

            // label-focused: fg color0 on bg color2
            // label-urgent:  fg color3 on bg color7
            color: {
                if (chip.modelData.focused)
                    return Colors.color2;
                if (chip.modelData.urgent)
                    return Colors.color7;
                return "transparent";
            }

            Layout.fillHeight: true
            implicitWidth: wsLabel.implicitWidth + Theme.workspacePadding * 2

            BarText {
                id: wsLabel
                anchors.centerIn: parent
                text: chip.modelData.name
                color: {
                    if (chip.modelData.focused)
                        return Colors.color0;
                    if (chip.modelData.urgent)
                        return Colors.color3;
                    if (chip.modelData.occupied)
                        return Colors.foreground;
                    return Colors.dimmed;   // label-empty-foreground
                }
            }

            // enable-click = false in the polybar config. Uncomment to enable.
            // MouseArea {
            //     anchors.fill: parent
            //     onClicked: Quickshell.execDetached(["bspc", "desktop", "-f", chip.modelData.name])
            // }
        }
    }
}
