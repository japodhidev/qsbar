import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config"
import "../modules"

// [bar/main]
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 28
    color: Colors.background

    // polybar reserves space for the bar by default; ExclusionMode.Auto derives
    // the same struts from the anchors above.
    exclusionMode: ExclusionMode.Auto

    Item {
        anchors.fill: parent
        anchors.leftMargin: Theme.barPadding
        anchors.rightMargin: Theme.barPadding

        // modules-left = i3 bspwm
        RowLayout {
            anchors.left: parent.left
            height: parent.height
            spacing: Theme.moduleMargin

            Workspaces {
                screenName: bar.modelData.name
            }
        }

        // modules-center = date
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            height: parent.height
            spacing: Theme.moduleMargin

            DateTime {}
        }

        // modules-right = cpu paudio memory eth
        RowLayout {
            anchors.right: parent.right
            height: parent.height
            spacing: Theme.moduleMargin

            Cpu {}
            Separator {}
            Volume {}
            Separator {}
            Memory {}
            Separator {}
            Network {}
        }
    }
}
