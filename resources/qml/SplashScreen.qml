import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property bool isDarkTheme: false
    property color accentColor: "#0097A7"
    signal finished()
    
    color: "transparent"
    opacity: 1.0

    Behavior on opacity {
        NumberAnimation { duration: 260; easing.type: Easing.InOutQuad }
    }

    Timer {
        id: closeTimer
        interval: 3000
        repeat: false
        running: root.visible
        onTriggered: {
            root.opacity = 0
            finishDelay.restart()
        }
    }

    Timer {
        id: finishDelay
        interval: 280
        repeat: false
        onTriggered: root.finished()
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 520)
        height: 300
        radius: 28
        color: isDarkTheme ? "#111B20" : "#FFFFFF"
        border.width: 1
        border.color: isDarkTheme ? "#23343B" : "#DCECEF"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 34
            spacing: 18

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 92

                Image {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, 320)
                    height: 94
                    source: "qrc:/assets/esfa-logo.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            Text {
                Layout.fillWidth: true
                text: "SNMP Browser"
                color: isDarkTheme ? "#F5F7FA" : "#14242B"
                font.pixelSize: 30
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: "ESFA SNMPv3 MIB Loader"
                color: isDarkTheme ? "#9AAAB3" : "#60727A"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 210
                Layout.preferredHeight: 5
                radius: 3
                color: isDarkTheme ? "#223238" : "#D8ECEF"
                clip: true

                Rectangle {
                    height: parent.height
                    width: parent.width * 0.42
                    radius: 3
                    color: accentColor

                    SequentialAnimation on x {
                        loops: Animation.Infinite
                        NumberAnimation { from: -90; to: 210; duration: 900; easing.type: Easing.InOutQuad }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Loading application..."
                color: isDarkTheme ? "#738791" : "#7C8C93"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
