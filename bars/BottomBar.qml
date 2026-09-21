import QtQuick
import QtQuick.Layouts
import Quickshell
import "root:/config"
import "root:/modules"

// [bar/bottom]
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: Colors.background
    exclusionMode: ExclusionMode.Auto

    Item {
        anchors.fill: parent
        anchors.leftMargin: Theme.barPadding
        anchors.rightMargin: Theme.barPadding

        // modules-center = mpd
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height
            spacing: Theme.moduleMargin

            Mpd {}
        }

        // modules-right = tray
        RowLayout {
            anchors.right: parent.right
            height: parent.height
            spacing: Theme.moduleMargin

            Tray {
                anchorWindow: bar
            }
        }
    }
}
