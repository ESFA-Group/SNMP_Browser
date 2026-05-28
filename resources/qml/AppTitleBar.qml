import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property bool isDarkTheme: false
    property bool isScanning: false
    property int itemCount: 0
    property string appTitle: "SNMP Browser"
    property string appSubtitle: "SNMPv3 Browser & MIB Loader"
    property string hostText: ""
    property string portText: ""
    property string mibText: "No MIB loaded"
    property string statusText: "Ready"
    property color accentColor: "#0097A7"
    property color textColor: isDarkTheme ? "#F5F7FA" : "#172026"
    property color mutedTextColor: isDarkTheme ? "#A8B3BD" : "#667781"
    property color dividerColor: isDarkTheme ? "#2A363D" : "#D8E5E8"
    property color surfaceColor: isDarkTheme ? "#11191D" : "#F8FBFC"

    signal dragRequested()
    signal minimizeRequested()
    signal maximizeRestoreRequested()
    signal closeRequested()
    signal themeToggleRequested()

    implicitHeight: 64
    color: surfaceColor

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: dividerColor
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: root.dragRequested()
        onDoubleClicked: root.maximizeRestoreRequested()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 8
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 132
            Layout.preferredHeight: 44
            radius: 12
            color: root.isDarkTheme ? "#FFFFFF" : "#EEF8FA"
            border.width: 1
            border.color: root.isDarkTheme ? "#26343B" : "#D7ECEF"

            Image {
                anchors.fill: parent
                anchors.margins: 9
                source: "qrc:/assets/esfa-logo.svg"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Rectangle {
                width: 10
                height: 10
                radius: 5
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 5
                anchors.bottomMargin: 5
                color: root.isScanning ? "#76FF03" : root.accentColor
                opacity: root.isScanning ? 1.0 : 0.75
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 170
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.appTitle
                color: root.textColor
                font.pixelSize: 16
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.appSubtitle
                color: root.mutedTextColor
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 32
            color: root.dividerColor
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StatusPill {
                label: root.isScanning ? "SCANNING" : "DEVICE"
                value: root.hostText.length > 0 ? root.hostText + ":" + root.portText : "Not configured"
                active: root.isScanning || root.hostText.length > 0
                isDarkTheme: root.isDarkTheme
                accentColor: root.accentColor
            }

            StatusPill {
                label: "MIB"
                value: root.mibText
                active: root.mibText !== "No MIB loaded"
                isDarkTheme: root.isDarkTheme
                accentColor: root.accentColor
            }

            StatusPill {
                label: "ITEMS"
                value: root.itemCount.toString()
                active: root.itemCount > 0
                isDarkTheme: root.isDarkTheme
                accentColor: root.accentColor
            }

            Text {
                Layout.fillWidth: true
                text: root.statusText
                color: root.mutedTextColor
                font.pixelSize: 12
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        TitleButton {
            text: root.isDarkTheme ? "☀" : "☾"
            tooltip: root.isDarkTheme ? "Switch to light mode" : "Switch to dark mode"
            isDarkTheme: root.isDarkTheme
            onClicked: root.themeToggleRequested()
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 32
            color: root.dividerColor
        }

        TitleButton {
            text: "—"
            tooltip: "Minimize"
            isDarkTheme: root.isDarkTheme
            onClicked: root.minimizeRequested()
        }

        TitleButton {
            text: "□"
            tooltip: "Maximize / restore"
            isDarkTheme: root.isDarkTheme
            onClicked: root.maximizeRestoreRequested()
        }

        TitleButton {
            text: "✕"
            tooltip: "Close"
            danger: true
            isDarkTheme: root.isDarkTheme
            onClicked: root.closeRequested()
        }
    }

    component StatusPill: Rectangle {
        property string label: ""
        property string value: ""
        property bool active: false
        property bool isDarkTheme: false
        property color accentColor: "#0097A7"

        Layout.preferredHeight: 30
        Layout.maximumWidth: 210
        implicitWidth: Math.min(210, Math.max(96, content.implicitWidth + 24))
        radius: 15
        color: active
               ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, isDarkTheme ? 0.28 : 0.14)
               : (isDarkTheme ? "#1B252A" : "#EDF3F5")
        border.width: 1
        border.color: active ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.55)
                             : (isDarkTheme ? "#2D3B42" : "#D9E4E7")

        RowLayout {
            id: content
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 6

            Text {
                text: label
                color: active ? accentColor : (isDarkTheme ? "#8FA0AA" : "#6B7A83")
                font.pixelSize: 9
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: value
                color: isDarkTheme ? "#EEF3F5" : "#1D2B32"
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

    component TitleButton: Button {
        property bool isDarkTheme: false
        property bool danger: false
        property string tooltip: ""

        Layout.preferredWidth: 38
        Layout.preferredHeight: 34
        hoverEnabled: true
        padding: 0
        ToolTip.visible: hovered && tooltip.length > 0
        ToolTip.text: tooltip

        background: Rectangle {
            radius: 9
            color: parent.danger && parent.hovered
                   ? "#E53935"
                   : parent.hovered
                     ? (parent.isDarkTheme ? "#26343B" : "#E6F3F5")
                     : "transparent"
        }

        contentItem: Text {
            text: parent.text
            color: parent.danger && parent.hovered
                   ? "white"
                   : (parent.isDarkTheme ? "#D9E3E8" : "#223038")
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: 15
            font.bold: true
        }
    }
}
