import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../config"

// [module/mpd]
// `mpc idleloop player` wakes us on every state change, and a 2s timer keeps
// the label fresh the way polybar's interval = 2 did. If you run mpDris2, the
// Quickshell.Services.Mpris module is a drop-in alternative to both processes.
Item {
    id: root

    property string song: ""

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    visible: root.song !== ""

    BarText {
        id: label
        anchors.centerIn: parent

        // label-song-maxlen = 100, label-song-ellipsis = true
        text: root.song.length > 100 ? root.song.substring(0, 100) + "…" : root.song
    }

    Process {
        id: current
        running: true
        // label-song = "%artist% - %title% | %album%"
        command: ["ncmpcpp", "-q", "--current-song", "%a - %t | %b"]

        stdout: StdioCollector {
            id: currentOut
            onStreamFinished: root.song = currentOut.text.trim()
        }
    }

    Process {
        running: true
        command: ["mpc", "idleloop", "player"]

        stdout: SplitParser {
            onRead: current.running = true
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: current.running = true
    }
}
