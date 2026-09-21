pragma Singleton

import Quickshell

// polybar measures padding and margins in "spaces"; these are the pixel
// equivalents at the configured font size. Tweak here, not in the modules.
Singleton {
    readonly property string fontFamily: "Cousine Nerd Font"
    readonly property int fontSize: 9        // font-0 = ...:size=9

    readonly property int barHeight: 24      // height = 24pt / 24
    readonly property int barPadding: 8      // padding-left/right = 2
    readonly property int moduleMargin: 8    // module-margin = 1
    readonly property int lineSize: 3        // line-size = 3pt (underlines)

    readonly property int workspacePadding: 8   // label-*-padding = 2..3
    readonly property string separator: "|"

    readonly property int trayIconSize: 20   // tray-size = 20
    readonly property int traySpacing: 8     // tray-spacing = 8px
    readonly property int trayPadding: 4     // tray-padding = 4
}
