import QtQuick
import Quickshell.Io

// [module/memory] — %percentage_used% from /proc/meminfo
BarModule {
    id: root

    property real percentage: 0

    prefix: "RAM "
    label: String(Math.round(root.percentage)).padStart(2, " ") + "%"

    function sample(data) {
        let total = 0;
        let available = 0;

        for (const line of data.split("\n")) {
            if (line.startsWith("MemTotal:"))
                total = Number(line.split(/\s+/)[1]);
            else if (line.startsWith("MemAvailable:"))
                available = Number(line.split(/\s+/)[1]);
        }

        if (total > 0)
            root.percentage = 100 * (total - available) / total;
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: root.sample(meminfo.text())
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: meminfo.reload()
    }
}
