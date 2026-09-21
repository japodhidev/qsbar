//@ pragma UseQApplication
// Needed so system tray context menus (QMenu) can be shown.

import QtQuick
import Quickshell
import "./bars"
import "./modules"
import "./config"

ShellRoot {
    // polybar was launched once per output via ${env:MONITOR:}.
    // Quickshell does the same thing with Variants: one window per screen.
    // To pin a bar to a single output instead, replace the model with e.g.
    //   model: Quickshell.screens.filter(s => s.name === "DP-1")

    Variants {
        model: Quickshell.screens
        /*property color debugLabelColor: {
            console.debug(JSON.stringify(Colors.resources));
            return Colors.foreground;
        }*/
        MainBar {}
    }

    Variants {
        model: Quickshell.screens
        BottomBar {}
    }
}
