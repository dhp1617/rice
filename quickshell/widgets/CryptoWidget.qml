// ~/.config/quickshell/widgets/CryptoWidget.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root

    anchors.top: true
    anchors.left: true
    margins.top: 27
    margins.left: 1489

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "desktop-crypto"
    exclusiveZone: 0
    color: "transparent"

    implicitWidth: 420
    implicitHeight: 170

    property color themeBg:     "#0b0e10"
    property color themeFg:     "#e0e2e8"
    property color themeAccent: "#89b4fa"

    FileView {
        path: "/home/dhp/.cache/ambxst/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            try {
                const c = JSON.parse(text())
                themeBg     = c.background     || themeBg
                themeFg     = c.overBackground || themeFg
                themeAccent = c.blue           || themeAccent
            } catch(e) {}
        }
    }

    readonly property var coins: [
        { id:"bitcoin",  sym:"BTC",  name:"Bitcoin",  color:"#f7931a" },
        { id:"ethereum", sym:"ETH",  name:"Ethereum", color:"#7b88f0" },
        { id:"dogecoin", sym:"DOGE", name:"Dogecoin", color:"#c2a633" }
    ]

    property var prices: ({})
    property string lastUpdated: "never"
    property bool loading: false

    FileView {
        id: cache
        path: "/home/dhp/.cache/ambxst/crypto-prices.json"
        watchChanges: false
        onTextChanged: {
            try {
                const c = JSON.parse(text())
                if (c.prices)  root.prices = c.prices
                if (c.updated) root.lastUpdated = c.updated
            } catch(e) {}
        }
    }

    Process {
        id: fetchProc
        command: ["bash", "-c",
            "curl -s --max-time 8 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,dogecoin&vs_currencies=inr&include_24hr_change=true'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim())
                    if (d.bitcoin && d.ethereum && d.dogecoin) {
                        root.prices = {
                            bitcoin:  d.bitcoin.inr,
                            ethereum: d.ethereum.inr,
                            dogecoin: d.dogecoin.inr,
                            _changes: {
                                bitcoin:  d.bitcoin.inr_24h_change,
                                ethereum: d.ethereum.inr_24h_change,
                                dogecoin: d.dogecoin.inr_24h_change
                            }
                        }
                        root.lastUpdated = Qt.formatDateTime(new Date(), "hh:mm AP")
                        const payload = JSON.stringify({ prices: root.prices, updated: root.lastUpdated })
                        Quickshell.execDetached(["bash","-c",
                            "echo '" + payload.replace(/'/g, "'\\''") +
                            "' > ~/.cache/ambxst/crypto-prices.json"])
                    }
                } catch(e) { console.log("crypto fetch failed:", e) }
                root.loading = false
            }
        }
    }

    function refresh() {
        if (root.loading) return
        root.loading = true
        fetchProc.running = false
        fetchProc.running = true
    }

    Timer { interval: 900000; running: true; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()

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
        radius: 10
        color: Qt.rgba(themeBg.r, themeBg.g, themeBg.b, 0.90)
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.08) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.18) }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // ---- HEADER ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: root.loading ? "#f0a14a"
                        : (root.lastUpdated === "never" ? "#e57070" : "#6dbf7a")
                    SequentialAnimation on opacity {
                        running: root.loading
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 500 }
                        NumberAnimation { to: 1.0; duration: 500 }
                    }
                }

                Text {
                    text: "MARKETS"
                    color: themeFg
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 3
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.lastUpdated === "never" ? "offline" : root.lastUpdated
                    color: themeFg
                    opacity: 0.35
                    font.pixelSize: 10
                }

                Rectangle {
                    width: 22; height: 22; radius: 4
                    color: refreshHover.containsMouse
                        ? Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.28)
                        : Qt.rgba(themeAccent.r, themeAccent.g, themeAccent.b, 0.12)
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        color: themeAccent
                        font.pixelSize: 13
                        font.bold: true
                        RotationAnimation on rotation {
                            running: root.loading
                            from: 0; to: 360; duration: 900; loops: Animation.Infinite
                        }
                    }
                    MouseArea {
                        id: refreshHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.refresh()
                    }
                }
            }

            // ---- COINS ----
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                Repeater {
                    model: root.coins
                    delegate: Rectangle {
                        id: coinCard
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6

                        readonly property var  c1: modelData.color
                        readonly property real cr: parseInt(c1.slice(1,3),16)/255
                        readonly property real cg: parseInt(c1.slice(3,5),16)/255
                        readonly property real cb: parseInt(c1.slice(5,7),16)/255

                        readonly property var price: root.prices[modelData.id] || 0
                        readonly property var change: root.prices._changes
                            ? root.prices._changes[modelData.id] || 0 : 0
                        readonly property bool up: change >= 0

                        color: Qt.rgba(cr, cg, cb, hover.containsMouse ? 0.16 : 0.08)
                        border.color: Qt.rgba(cr, cg, cb, hover.containsMouse ? 0.60 : 0.28)
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: 180 } }
                        Behavior on border.color { ColorAnimation { duration: 180 } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 2

                            Text {
                                text: modelData.sym
                                color: themeFg
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 1.5
                            }
                            Text {
                                text: modelData.name
                                color: themeFg
                                opacity: 0.45
                                font.pixelSize: 9
                            }

                            Item { Layout.fillHeight: true }

                            Text {
                                text: price > 0 ? "₹" + formatINR(price) : "—"
                                color: themeFg
                                font.pixelSize: 16
                                font.bold: true
                            }

                            Text {
                                visible: change !== 0
                                text: (coinCard.up ? "▲ " : "▼ ") +
                                      Math.abs(coinCard.change).toFixed(2) + "%"
                                color: coinCard.up ? "#6dbf7a" : "#e57070"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true }
                    }
                }
            }
        }
    }

    function formatINR(n) {
        if (!n || n === 0) return "—"
        if (n >= 10000000) return (n/10000000).toFixed(2) + " Cr"
        if (n >= 100000)   return (n/100000).toFixed(2) + " L"
        if (n >= 1000)     return (n/1000).toFixed(1) + "K"
        return Math.round(n).toString()
    }
}
