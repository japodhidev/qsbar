import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../config"

// [module/paudio] — the polybar version shelled out to sound.sh + wpctl on
// every tick. Quickshell speaks to PipeWire directly, so the value is
// event-driven and the click/scroll bindings are kept identical.
Item {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0

    Layout.alignment: Qt.AlignVCenter
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    // Bind the sink so its audio properties stay live.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    BarModule {
        id: content
        anchors.centerIn: parent

        prefix: root.muted ? "" : "VOL "
        label: root.muted ? "muted" : Math.round(root.volume * 100) + "%"
        labelColor: root.muted ? Colors.color6 : Colors.foreground
    }

    MouseArea {
        anchors.fill: parent

        // click-left = wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        onClicked: {
            if (root.sink?.audio)
                root.sink.audio.muted = !root.sink.audio.muted;
        }

        // scroll-up / scroll-down = set-volume ... 2%+ / 2%-
        onWheel: wheel => {
            if (!root.sink?.audio)
                return;

            const step = wheel.angleDelta.y > 0 ? 0.02 : -0.02;
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step));
        }
    }
}
