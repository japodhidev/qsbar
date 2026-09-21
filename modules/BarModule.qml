import QtQuick
import QtQuick.Layouts
import "../config"

// polybar's format-prefix + label pairing, e.g. `CPU ` in color4 followed by
// the value in the bar foreground.
Row {
    id: root

    property string prefix: ""
    property color prefixColor: Colors.accent
    property string label: ""
    property color labelColor: Colors.foreground

    spacing: 0
    Layout.alignment: Qt.AlignVCenter

    BarText {
        text: root.prefix
        color: root.prefixColor
        visible: root.prefix !== ""
    }

    BarText {
        text: root.label
        color: root.labelColor
    }
}
