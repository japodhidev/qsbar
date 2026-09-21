import QtQuick
import Quickshell.Io

// [module/cpu] — internal/cpu reads /proc/stat; so do we, diffing two samples.
BarModule {
    id: root

    property var previous: null
    property real percentage: 0

    prefix: "CPU "
    // %percentage:2%% — minimum width 2, space padded
    label: String(Math.round(root.percentage)).padStart(2, " ") + "%"

    function sample(data) {
        const fields = data.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (fields.length < 5)
            return;

        const total = fields.reduce((a, b) => a + b, 0);
        const idle = fields[3] + fields[4];   // idle + iowait

        if (root.previous) {
            const totalDelta = total - root.previous.total;
            const idleDelta = idle - root.previous.idle;
            if (totalDelta > 0)
                root.percentage = 100 * (totalDelta - idleDelta) / totalDelta;
        }

        root.previous = { total: total, idle: idle };
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: root.sample(stat.text())
    }

    Timer {
        interval: 2000          // interval = 2
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: stat.reload()
    }
}
