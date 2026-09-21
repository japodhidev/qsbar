import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config"

// [module/date] — click toggles to the *-alt formats, as polybar does.
Item {
    id: root

    property bool alternate: false

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    BarText {
        id: label
        anchors.centerIn: parent
        color: Colors.color2   // label-foreground = ${colors.color2}

        // date = %A, %d %B %Y   time = %H:%M %p
        // date-alt = %A, %d %B %Y   time-alt = %I:%M:%S %p
        text: root.alternate
            ? Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy hh:mm:ss AP")
            : Qt.formatDateTime(clock.date, "dddd, dd MMMM yyyy HH:mm AP")
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.alternate = !root.alternate
    }
}
