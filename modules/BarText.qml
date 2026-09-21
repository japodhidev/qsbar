import QtQuick
import QtQuick.Layouts
import "../config"

// Every piece of text on the bars goes through here so the font is set once.
Text {
    color: Colors.foreground
    font.family: Theme.fontFamily
    font.pointSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    Layout.alignment: Qt.AlignVCenter
}
