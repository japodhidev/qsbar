import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config"

// [module/i3]
// Quickshell also ships a first-party `Quickshell.I3` module with an `I3`
// singleton exposing `workspaces`; this version talks to i3-msg directly so it
// works on any Quickshell build and on sway unchanged.
RowLayout {
    id: root

    property string screenName: ""
    property var workspaces: []

    spacing: 0
    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: true

    // strip-wsnumbers = true: "2:web" renders as "web", bare "2" stays "2".
    function stripNumber(name) {
        const stripped = String(name).replace(/^\d+\s*:\s*/, "");
        return stripped.length > 0 ? stripped : String(name);
    }

    Process {
        id: fetch
        running: true
        command: ["i3-msg", "-t", "get_workspaces"]

        stdout: StdioCollector {
            id: fetchOut

            onStreamFinished: {
                try {
                    root.workspaces = JSON.parse(fetchOut.text);
                } catch (e) {
                    root.workspaces = [];
                }
            }
        }
    }

    // One JSON object per line whenever a workspace changes; each line just
    // triggers a refetch, which keeps the parsing in one place.
    Process {
        running: true
        command: ["i3-msg", "-t", "subscribe", "-m", "[\"workspace\"]"]

        stdout: SplitParser {
            onRead: fetch.running = true
        }
    }

    Repeater {
        // pin-workspaces = true
        model: root.workspaces.filter(ws => root.screenName === "" || ws.output === root.screenName)

        delegate: Rectangle {
            id: chip

            required property var modelData

            // label-focused/-unfocused-background = color0,
            // label-urgent-background = color3
            color: modelData.urgent ? Colors.color3 : Colors.color0
            Layout.fillHeight: true
            implicitWidth: wsLabel.implicitWidth + Theme.workspacePadding * 5

            BarText {
                id: wsLabel
                anchors.centerIn: parent
                text: root.stripNumber(chip.modelData.name)
                color: chip.modelData.urgent ? Colors.color0 : Colors.foreground
            }

            // label-focused-underline = ${colors.color8}
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Theme.lineSize
                color: Colors.color8
                visible: chip.modelData.focused
            }

            // enable-click = true
            MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached(["i3-msg", "workspace", chip.modelData.name])
            }
        }
    }
}
