import QtQuick
import QtQuick.Layouts
import Quickshell

// polybar had both `i3` and `bspwm` in modules-left and only ever drew the one
// whose IPC socket existed. Same idea here: pick a backend at startup.
Loader {
    id: root

    property string screenName: ""

    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: true

    sourceComponent: {
        if (Quickshell.env("I3SOCK") || Quickshell.env("SWAYSOCK"))
            return i3Component;
        if (Quickshell.env("BSPWM_SOCKET"))
            return bspwmComponent;
        return i3Component;
    }

    Component {
        id: i3Component

        I3Workspaces {
            screenName: root.screenName
        }
    }

    Component {
        id: bspwmComponent

        BspwmWorkspaces {
            screenName: root.screenName
        }
    }
}
