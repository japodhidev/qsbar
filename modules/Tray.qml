import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../config"

// [module/tray]
RowLayout {
    id: root

    // The PanelWindow the context menus anchor to.
    property var anchorWindow: null

    spacing: Theme.traySpacing
    Layout.alignment: Qt.AlignVCenter

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: trayItem

            required property SystemTrayItem modelData

            implicitWidth: Theme.trayIconSize + Theme.trayPadding * 2
            implicitHeight: Theme.trayIconSize
            Layout.alignment: Qt.AlignVCenter
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton && !trayItem.modelData.onlyMenu) {
                    trayItem.modelData.activate();
                    return;
                }

                if (mouse.button === Qt.MiddleButton) {
                    trayItem.modelData.secondaryActivate();
                    return;
                }
                const anchor = trayItem.mapToItem(null, trayItem.width / 2, 0);
                trayItem.modelData.display(root.anchorWindow, anchor.x, -90);
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: Theme.trayIconSize
                source: trayItem.modelData.icon
            }
        }
    }
}
