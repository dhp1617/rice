import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root
    anchors.top: true
    anchors.left: true
    margins.top: 492
    margins.left: 1593

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "desktop-stats"
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 260
    implicitHeight: 60

    property color bg:     "#1e1e2e"
    property color fg:     "#cdd6f4"
    property color accent: "#89b4fa"

    FileView {
        path: "/home/dhp/.cache/ambxst/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            try {
                const c = JSON.parse(text())
                bg = c.background || bg
                fg = c.overBackground || fg
                accent = c.blue || accent
            } catch(e) {}
        }
    }

    property real cpu: 0
    property real ram: 0
    property int  bat: 0
    property bool charging: false

    Process {
        id: p
        command: ["bash","-c",
          "read _ u n s i w q sq st _ </proc/stat; " +
          "echo \"C $u $((u+n+s+i+w+q+sq+st))\"; " +
          "awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print \"R \"t\" \"a}' /proc/meminfo; " +
          "for b in /sys/class/power_supply/BAT*; do [ -d $b ] && echo \"B $(cat $b/capacity) $(cat $b/status)\"; done"]
        property real lu: 0
        property real lt: 0
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const s = line.split(" ")
                    if (s[0]==="C") {
                        const u=+s[1], t=+s[2]
                        if (p.lt>0) root.cpu = Math.min(100,(u-p.lu)/(t-p.lt)*100)
                        p.lu=u; p.lt=t
                    } else if (s[0]==="R") root.ram = (1-(+s[2])/(+s[1]))*100
                    else if (s[0]==="B") { root.bat=+s[1]; root.charging=(s[2]==="Charging"||s[2]==="Full") }
                }
            }
        }
    }

    Timer { interval: 1500; running: true; repeat: true; triggeredOnStart: true
            onTriggered: { p.running=false; p.running=true } }

    // Drag anywhere
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.SizeAllCursor
        property real sx; property real sy; property real mx; property real my
        onPressed: (m) => { sx=m.x; sy=m.y; mx=root.margins.left; my=root.margins.top }
        onPositionChanged: (m) => {
            root.margins.left = mx + (m.x - sx)
            root.margins.top  = my + (m.y - sy)
        }
        onReleased: {
            console.log("POSITION → left:" + Math.round(root.margins.left) +
                        "  top:" + Math.round(root.margins.top))
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 30
        color: Qt.rgba(bg.r,bg.g,bg.b,0.88)
        border.color: Qt.rgba(1,1,1,0.08)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 18

            Repeater {
                model: [
                    { label:"CPU", val: Math.round(root.cpu)+"%", p: root.cpu/100 },
                    { label:"RAM", val: Math.round(root.ram)+"%", p: root.ram/100 },
                    { label:"BAT", val: root.bat+"%",             p: root.bat/100, glow: root.charging }
                ]
                delegate: RowLayout {
                    spacing: 8
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: root.accent
                        opacity: modelData.glow ? 1.0 : 0.85
                    }
                    ColumnLayout {
                        spacing: 0
                        Text { text: modelData.label; color: root.fg; opacity: 0.5; font.pixelSize: 10; font.bold: true }
                        Text { text: modelData.val;   color: root.fg; font.pixelSize: 15; font.bold: true }
                    }
                }
            }
        }
    }
}
