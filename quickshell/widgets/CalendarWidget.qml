// ~/.config/quickshell/widgets/CalendarWidget.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    margins.top: 571
    margins.left: 1549

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "desktop-calendar"
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 360
    implicitHeight: 460

    // ---- Theme ----
    property color themeBg:      "#1e1e2e"
    property color themeSurface: "#313244"
    property color themeFg:      "#cdd6f4"
    property color themeAccent:  "#89b4fa"
    property color themeOnAcc:   "#1e1e2e"

    FileView {
        path: "/home/dhp/.cache/ambxst/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            try {
                const c = JSON.parse(text());
                themeBg      = c.background        || themeBg;
                themeSurface = c.surfaceContainer  || themeSurface;
                themeFg      = c.overBackground    || themeFg;
                themeAccent  = c.blue              || themeAccent;
                themeOnAcc   = c.background        || themeOnAcc;
            } catch (e) {}
        }
    }

    // ---- Container ----
    Rectangle {
        id: box
        anchors.fill: parent
        radius: 18
        color: Qt.rgba(themeBg.r, themeBg.g, themeBg.b, 0.9)
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        // Soft inner gradient for depth
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.04) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.10) }
            }
        }

        // ---- Big day header ----
        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 22
            spacing: 16

            // Day number + weekday
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                // Big day number in a soft accent badge
                Rectangle {
                    implicitWidth: 64
                    implicitHeight: 64
                    radius: 18
                    color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.18)
                    border.color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.45)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: new Date().getDate()
                        color: themeAccent
                        font.pixelSize: 32
                        font.bold: true
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: Qt.formatDateTime(new Date(), "dddd")
                        color: themeFg
                        font.pixelSize: 18
                        font.bold: true
                    }
                    Text {
                        text: Qt.formatDateTime(new Date(), "MMMM yyyy")
                        color: themeFg
                        opacity: 0.55
                        font.pixelSize: 12
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            // ---- Month nav ----
            RowLayout {
                Layout.fillWidth: true

                NavButton { glyph: "‹"; onClicked: root.shiftMonth(-1) }
                Item { Layout.fillWidth: true }
                Text {
                    text: cal.monthName
                    color: themeFg
                    font.pixelSize: 14
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                NavButton { glyph: "›"; onClicked: root.shiftMonth(1) }
            }

            // ---- Weekday row ----
            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: ["M","T","W","T","F","S","S"]
                    delegate: Text {
                        Layout.fillWidth: true
                        text: modelData
                        color: themeFg
                        opacity: 0.4
                        font.pixelSize: 11
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // ---- Days ----
            Grid {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7

                Repeater {
                    model: cal.daysInMonthGrid
                    delegate: Item {
                        width: parent.width / 7
                        height: parent.height / 6

                        property bool isToday: {
                            const d = new Date()
                            return modelData.day === d.getDate()
                                && cal.currentMonth === d.getMonth()
                                && cal.currentYear === d.getFullYear()
                        }

                        // hover highlight
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) * 0.78
                            height: width
                            radius: width / 2
                            color: themeSurface
                            opacity: hover.containsMouse && !parent.isToday ? 0.6 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        // today glow ring
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) * 0.72
                            height: width
                            radius: width / 2
                            color: "transparent"
                            border.color: parent.isToday ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.35) : "transparent"
                            border.width: 2
                            visible: parent.isToday
                        }

                        // today fill
                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) * 0.6
                            height: width
                            radius: width / 2
                            color: parent.isToday ? themeAccent : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day > 0 ? modelData.day : ""
                            color: parent.isToday ? themeOnAcc : themeFg
                            font.pixelSize: 13
                            font.bold: parent.isToday
                            opacity: modelData.day > 0 ? 1 : 0
                        }

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
                    }
                }
            }
        }
    }

    // ---- Nav button component ----
    component NavButton: Rectangle {
        signal clicked()
        property string glyph: "‹"
        implicitWidth: 28
        implicitHeight: 28
        radius: 4
        color: hover.containsMouse
            ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.20)
            : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: parent.glyph
            color: themeFg
            font.pixelSize: 18
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }

    function shiftMonth(delta) {
        let m = cal.currentMonth + delta
        if (m < 0)  { m = 11; cal.currentYear-- }
        if (m > 11) { m = 0;  cal.currentYear++ }
        cal.currentMonth = m
        cal.update()
    }

    // ---- Backend ----
    property QtObject cal: QtObject {
        id: cal
        property int currentYear: new Date().getFullYear()
        property int currentMonth: new Date().getMonth()
        property var daysInMonthGrid: []

        readonly property var monthNames: ["January","February","March","April","May","June","July","August","September","October","November","December"]
        readonly property string monthName: monthNames[currentMonth]

        function update() {
            let days = []
            const firstDay = new Date(currentYear, currentMonth, 1).getDay()
            const offset = (firstDay === 0) ? 6 : firstDay - 1
            const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate()
            for (let i = 0; i < offset; i++) days.push({ day: 0 })
            for (let i = 1; i <= daysInMonth; i++) days.push({ day: i })
            while (days.length < 42) days.push({ day: 0 })
            daysInMonthGrid = days
        }
        Component.onCompleted: update()
    }
}
