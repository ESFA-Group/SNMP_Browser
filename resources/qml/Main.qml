import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window

ApplicationWindow {
    id: window
    width: 1100
    height: 750
    minimumWidth: 900
    minimumHeight: 620
    title: "SNMPv3 Browser & MIB Loader"
    flags: Qt.Window | Qt.FramelessWindowHint

    property bool isDarkTheme: controller.settings.theme === "dark"

    property color bgColor: isDarkTheme ? "#121212" : "#F5F5F5"
    property color panelColor: isDarkTheme ? "#1E1E1E" : "#FFFFFF"
    property color textColor: isDarkTheme ? "#E0E0E0" : "#212121"
    property color secondaryTextColor: isDarkTheme ? "#888888" : "#666666"
    property color borderColor: isDarkTheme ? "#444444" : "#BDBDBD"
    property color inputBgColor: isDarkTheme ? "#2C2C2C" : "#FFFFFF"
    property color headerBgColor: isDarkTheme ? "#2C2C2C" : "#EEEEEE"
    property color alternateRowColor: isDarkTheme ? "#252525" : "#F0F0F0"
    property color accentColor: "#0097A7"
    property color groupTitleColor: isDarkTheme ? "#4DD0E1" : "#007C89"

    color: bgColor

    function toggleMaximized() {
        if (window.visibility === Window.Maximized)
            window.showNormal()
        else
            window.showMaximized()
    }

    Component.onCompleted: {
        controller.settings.load()
        window.visible = true
    }
    Component.onDestruction: controller.settings.save()

    header: AppTitleBar {
        isDarkTheme: window.isDarkTheme
        isScanning: controller.isScanning
        itemCount: controller.treeModel.itemCount
        appTitle: "SNMP Browser"
        appSubtitle: "ESFA SNMPv3 MIB Loader"
        hostText: controller.settings.ip
        portText: controller.settings.port.toString()
        mibText: controller.settings.mibPath ? controller.settings.mibPath.split('/').pop() : "No MIB loaded"
        statusText: controller.statusMessage
        accentColor: window.accentColor

        onDragRequested: window.startSystemMove()
        onMinimizeRequested: window.showMinimized()
        onMaximizeRestoreRequested: window.toggleMaximized()
        onCloseRequested: window.close()
        onThemeToggleRequested: controller.settings.theme = window.isDarkTheme ? "light" : "dark"
    }

    background: Rectangle {
        color: bgColor
        border.color: borderColor
        border.width: window.visibility === Window.Maximized ? 0 : 1
    }

    MessageDialog {
        id: errorDialog
        title: "Error"
        buttons: MessageDialog.Ok
    }

    MessageDialog {
        id: infoDialog
        title: "Information"
        buttons: MessageDialog.Ok
    }

    Dialog {
        id: compileReportDialog
        title: "MIB Compilation Report"
        width: 500
        height: 400
        anchors.centerIn: parent
        standardButtons: Dialog.Ok
        property string reportText: ""

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                text: "Compilation process completed."
                color: textColor
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextArea {
                    text: compileReportDialog.reportText
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    color: textColor
                    background: Rectangle {
                        color: inputBgColor
                        border.color: borderColor
                        radius: 4
                    }
                }
            }
        }
    }

    FolderDialog {
        id: mibFolderDialog
        title: "Select Folder containing .mib files"
        onAccepted: controller.selectMibFolder(selectedFolder)
    }

    FileDialog {
        id: exportFileDialog
        title: "Save Snapshot"
        fileMode: FileDialog.SaveFile
        nameFilters: ["CSV Files (*.csv)", "JSON Files (*.json)"]
        currentFile: "snmp_snapshot_" + controller.settings.ip.replace(/\./g, "-") + "_" +
                     Qt.formatDateTime(new Date(), "yyyyMMdd_hhmmss") + ".csv"
        onAccepted: controller.exportSnapshot(selectedFile)
    }

    Connections {
        target: controller

        function onErrorOccurred(title, message) {
            errorDialog.title = title
            errorDialog.text = message
            errorDialog.open()
        }

        function onInfoMessage(title, message) {
            infoDialog.title = title
            infoDialog.text = message
            infoDialog.open()
        }

        function onCompileFinished(report) {
            compileReportDialog.reportText = report
            compileReportDialog.open()
        }
    }

    SplitView {
        anchors.fill: parent
        anchors.margins: window.visibility === Window.Maximized ? 0 : 1
        orientation: Qt.Horizontal

        handle: Rectangle {
            implicitWidth: 1
            color: borderColor
        }

        Rectangle {
            SplitView.preferredWidth: 340
            SplitView.minimumWidth: 280
            color: bgColor

            ScrollView {
                anchors.fill: parent
                anchors.margins: 20
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: 15

                    Label {
                        text: "Connection Settings"
                        font.pixelSize: 20
                        font.bold: true
                        color: textColor
                    }

                    GroupBox {
                        Layout.fillWidth: true
                        title: "SNMPV3 DEVICE"

                        label: Label {
                            text: parent.title
                            color: groupTitleColor
                            font.bold: true
                        }

                        background: Rectangle {
                            y: parent.topPadding - parent.bottomPadding
                            width: parent.width
                            height: parent.height - parent.topPadding + parent.bottomPadding
                            color: "transparent"
                            border.color: borderColor
                            radius: 8
                        }

                        GridLayout {
                            anchors.fill: parent
                            columns: 2
                            columnSpacing: 10
                            rowSpacing: 10

                            Label { text: "Host IP:"; color: textColor }
                            TextField {
                                Layout.fillWidth: true
                                text: controller.settings.ip
                                onTextChanged: controller.settings.ip = text
                                color: textColor
                                placeholderTextColor: secondaryTextColor
                                background: InputBackground {}
                            }

                            Label { text: "Port:"; color: textColor }
                            TextField {
                                Layout.fillWidth: true
                                text: controller.settings.port.toString()
                                validator: IntValidator { bottom: 1; top: 65535 }
                                onTextChanged: {
                                    var val = parseInt(text)
                                    if (!isNaN(val)) controller.settings.port = val
                                }
                                color: textColor
                                background: InputBackground {}
                            }

                            Label { text: "User:"; color: textColor }
                            TextField {
                                Layout.fillWidth: true
                                text: controller.settings.username
                                onTextChanged: controller.settings.username = text
                                color: textColor
                                background: InputBackground {}
                            }

                            Label { text: "Auth Key:"; color: textColor }
                            TextField {
                                Layout.fillWidth: true
                                text: controller.settings.authKey
                                onTextChanged: controller.settings.authKey = text
                                placeholderText: "Auth passphrase, min 8 chars"
                                echoMode: TextInput.Password
                                color: textColor
                                placeholderTextColor: secondaryTextColor
                                background: InputBackground {}
                            }

                            Label { text: "Priv Key:"; color: textColor }
                            TextField {
                                Layout.fillWidth: true
                                text: controller.settings.privKey
                                onTextChanged: controller.settings.privKey = text
                                placeholderText: "Privacy passphrase, min 8 chars"
                                echoMode: TextInput.Password
                                color: textColor
                                placeholderTextColor: secondaryTextColor
                                background: InputBackground {}
                            }
                        }
                    }

                    GroupBox {
                        Layout.fillWidth: true
                        title: "MIB DEFINITIONS"

                        label: Label {
                            text: parent.title
                            color: groupTitleColor
                            font.bold: true
                        }

                        background: Rectangle {
                            y: parent.topPadding - parent.bottomPadding
                            width: parent.width
                            height: parent.height - parent.topPadding + parent.bottomPadding
                            color: "transparent"
                            border.color: borderColor
                            radius: 8
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            Label {
                                text: controller.settings.mibPath ?
                                      "Loaded: " + controller.settings.mibPath.split('/').pop() :
                                      "No MIB source selected"
                                color: controller.settings.mibPath ? accentColor : secondaryTextColor
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Button {
                                    Layout.fillWidth: true
                                    text: "Select Folder"
                                    enabled: !controller.isCompiling
                                    onClicked: mibFolderDialog.open()
                                    background: SecondaryButtonBackground {}
                                    contentItem: ButtonText {}
                                }

                                Button {
                                    Layout.fillWidth: true
                                    text: "Compile MIBs"
                                    enabled: !controller.isCompiling && controller.settings.mibPath
                                    onClicked: controller.compileMibs()
                                    background: SecondaryButtonBackground {}
                                    contentItem: ButtonText {}
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.minimumHeight: 20
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "CONNECT DEVICE"
                        enabled: !controller.isScanning
                        onClicked: controller.startScan()
                        background: Rectangle {
                            color: parent.enabled ?
                                   (parent.pressed ? "#007C89" : parent.hovered ? "#00ACC1" : accentColor) :
                                   borderColor
                            radius: 6
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.bold: true
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "ABORT SCAN"
                        enabled: controller.isScanning
                        onClicked: controller.stopScan()
                        background: Rectangle {
                            color: parent.enabled ?
                                   (parent.pressed ? "#c62828" : parent.hovered ? "#e53935" : "#F44336") :
                                   borderColor
                            radius: 6
                        }
                        contentItem: Text {
                            text: parent.text
                            color: parent.enabled ? "white" : secondaryTextColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.bold: true
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "EXPORT SNAPSHOT"
                        enabled: controller.canExport
                        onClicked: exportFileDialog.open()
                        background: SecondaryButtonBackground {}
                        contentItem: ButtonText {}
                    }
                }
            }
        }

        Rectangle {
            SplitView.fillWidth: true
            color: panelColor

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: headerBgColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 0

                        Label {
                            text: "OID / Parameter"
                            color: secondaryTextColor
                            font.bold: true
                            Layout.preferredWidth: 450
                        }

                        Label {
                            text: "Value"
                            color: secondaryTextColor
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }
                }

                TreeView {
                    id: treeView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: controller.treeModel
                    clip: true
                    alternatingRows: true

                    selectionModel: ItemSelectionModel { model: treeView.model }

                    delegate: Item {
                        id: treeDelegate
                        implicitWidth: treeView.width
                        implicitHeight: 32

                        required property TreeView treeView
                        required property bool expanded
                        required property bool hasChildren
                        required property int depth
                        required property int row
                        required property bool current
                        required property var model

                        readonly property real indent: 20

                        Rectangle {
                            anchors.fill: parent
                            color: {
                                if (treeDelegate.current)
                                    return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
                                if (treeDelegate.row % 2 === 1)
                                    return alternateRowColor
                                return panelColor
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 5
                            anchors.rightMargin: 5
                            spacing: 5

                            Item {
                                width: treeDelegate.depth * treeDelegate.indent + (treeDelegate.hasChildren ? 20 : 0)
                                height: parent.height

                                Text {
                                    visible: treeDelegate.hasChildren
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: treeDelegate.expanded ? "▼" : "▶"
                                    color: secondaryTextColor
                                    font.pixelSize: 10

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: treeView.toggleExpanded(treeDelegate.row)
                                    }
                                }
                            }

                            Text {
                                Layout.preferredWidth: 450 - treeDelegate.depth * treeDelegate.indent - (treeDelegate.hasChildren ? 20 : 0)
                                text: treeDelegate.model.oid || ""
                                color: treeDelegate.hasChildren ? groupTitleColor : textColor
                                font.bold: treeDelegate.hasChildren
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter

                                ToolTip.visible: truncated && oidMouseArea.containsMouse
                                ToolTip.text: treeDelegate.model.oid || ""

                                MouseArea {
                                    id: oidMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            contextMenu.currentValue = treeDelegate.model.value || ""
                                            contextMenu.currentRawValue = treeDelegate.model.rawValue || ""
                                            contextMenu.popup()
                                        } else if (treeDelegate.hasChildren) {
                                            treeView.toggleExpanded(treeDelegate.row)
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: treeDelegate.model.value || ""
                                color: textColor
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter

                                ToolTip.visible: truncated && valueMouseArea.containsMouse
                                ToolTip.text: "Raw: " + (treeDelegate.model.rawValue || "")

                                MouseArea {
                                    id: valueMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.RightButton

                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.RightButton) {
                                            contextMenu.currentValue = treeDelegate.model.value || ""
                                            contextMenu.currentRawValue = treeDelegate.model.rawValue || ""
                                            contextMenu.popup()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    color: isDarkTheme ? "#0d0d0d" : "#E0E0E0"

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: " " + controller.statusMessage
                        color: secondaryTextColor
                        font.pixelSize: 12
                    }

                    Label {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: controller.treeModel.itemCount + " items"
                        color: secondaryTextColor
                        font.pixelSize: 12
                        visible: controller.treeModel.itemCount > 0
                    }
                }
            }
        }
    }

    Menu {
        id: contextMenu
        property string currentValue: ""
        property string currentRawValue: ""

        background: Rectangle {
            implicitWidth: 150
            color: panelColor
            border.color: borderColor
            radius: 4
        }

        MenuItem {
            text: "Copy Value"
            onTriggered: controller.copyToClipboard(contextMenu.currentValue)
            background: Rectangle { color: parent.highlighted ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) : "transparent" }
            contentItem: Text { text: parent.text; color: textColor }
        }

        MenuItem {
            text: "Copy Raw Value"
            onTriggered: controller.copyToClipboard(contextMenu.currentRawValue)
            background: Rectangle { color: parent.highlighted ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) : "transparent" }
            contentItem: Text { text: parent.text; color: textColor }
        }
    }

    component InputBackground: Rectangle {
        color: inputBgColor
        border.color: parent.activeFocus ? accentColor : borderColor
        border.width: parent.activeFocus ? 2 : 1
        radius: 5
    }

    component SecondaryButtonBackground: Rectangle {
        color: parent.enabled ?
               (parent.pressed ? Qt.darker(inputBgColor, 1.1) : parent.hovered ? Qt.lighter(inputBgColor, 1.1) : inputBgColor) :
               borderColor
        border.color: borderColor
        border.width: 1
        radius: 6
    }

    component ButtonText: Text {
        text: parent.text
        color: parent.enabled ? textColor : secondaryTextColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.bold: true
    }
}
