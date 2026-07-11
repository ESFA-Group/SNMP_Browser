import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Window
import QtQml.Models

ApplicationWindow {
    id: window
    width: 1200
    height: 780
    minimumWidth: 940
    minimumHeight: 640
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
    property color hoverRowColor: isDarkTheme ? "#31393B" : "#E3F1F3"
    property color accentColor: "#0097A7"
    property color groupTitleColor: isDarkTheme ? "#4DD0E1" : "#007C89"

    // Tree display settings
    readonly property string monoFont: Qt.platform.os === "windows" ? "Consolas" : "DejaVu Sans Mono"
    property int treeFontSize: 13
    property real oidColumnWidth: 430
    property bool autoExpandDuringScan: true

    // Currently selected leaf (drives the detail pane)
    property string selOid: ""
    property string selValue: ""
    property string selRaw: ""
    property string selType: ""

    function clearSelection() {
        selOid = ""
        selValue = ""
        selRaw = ""
        selType = ""
    }

    function adjustFontSize(delta) {
        treeFontSize = Math.max(10, Math.min(20, treeFontSize + delta))
    }

    function typeColor(t) {
        switch (t) {
        case "number": return isDarkTheme ? "#CE93D8" : "#7B1FA2"
        case "ip":     return isDarkTheme ? "#81C784" : "#2E7D32"
        case "hex":    return isDarkTheme ? "#FFB74D" : "#E65100"
        case "mac":    return isDarkTheme ? "#FFB74D" : "#E65100"
        case "time":   return isDarkTheme ? "#64B5F6" : "#1565C0"
        case "oid":    return isDarkTheme ? "#90A4AE" : "#546E7A"
        default:       return textColor
        }
    }

    function typeLabel(t) {
        switch (t) {
        case "number": return "NUM"
        case "text":   return "STR"
        case "hex":    return "HEX"
        case "mac":    return "MAC"
        case "ip":     return "IP"
        case "time":   return "TIME"
        case "oid":    return "OID"
        default:       return ""
        }
    }

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

    // Keyboard shortcuts
    Shortcut {
        sequences: [StandardKey.Find]
        onActivated: {
            searchField.forceActiveFocus()
            searchField.selectAll()
        }
    }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (searchField.text.length > 0) {
                searchField.text = ""
                searchField.focus = false
            } else if (window.selOid !== "") {
                window.clearSelection()
            } else {
                searchField.focus = false
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+E"
        onActivated: treeView.expandRecursively()
    }
    Shortcut {
        sequence: "Ctrl+Shift+E"
        onActivated: {
            window.autoExpandDuringScan = false
            treeView.collapseRecursively()
        }
    }
    Shortcut {
        sequences: [StandardKey.ZoomIn, "Ctrl+="]
        onActivated: window.adjustFontSize(1)
    }
    Shortcut {
        sequence: StandardKey.ZoomOut
        onActivated: window.adjustFontSize(-1)
    }
    Shortcut {
        sequence: "Ctrl+0"
        onActivated: window.treeFontSize = 13
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

        function onIsScanningChanged() {
            if (controller.isScanning) {
                window.autoExpandDuringScan = true
                window.clearSelection()
            } else {
                scanFinishedExpandTimer.start()
            }
        }
    }

    // Keep newly discovered groups visible while results stream in,
    // unless the user collapsed something on purpose.
    Timer {
        interval: 700
        repeat: true
        running: controller.isScanning && window.autoExpandDuringScan
        onTriggered: treeView.expandRecursively()
    }

    Timer {
        id: scanFinishedExpandTimer
        interval: 100
        onTriggered: treeView.expandRecursively()
    }

    Timer {
        id: filterDebounce
        interval: 250
        onTriggered: {
            controller.proxyModel.filterText = searchField.text
            if (searchField.text.length > 0)
                treeView.expandRecursively()
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
            id: rightPane
            SplitView.fillWidth: true
            color: panelColor

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ---- Toolbar: search / filter + tree controls ----
                Rectangle {
                    Layout.fillWidth: true
                    height: 46
                    color: panelColor

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: borderColor
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.maximumWidth: 420
                            Layout.preferredHeight: 30
                            radius: 6
                            color: inputBgColor
                            border.color: searchField.activeFocus ? accentColor : borderColor
                            border.width: searchField.activeFocus ? 2 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 4
                                spacing: 4

                                TextField {
                                    id: searchField
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    placeholderText: "Filter by parameter or value…   (Ctrl+F)"
                                    placeholderTextColor: secondaryTextColor
                                    color: textColor
                                    font.pixelSize: 13
                                    background: null
                                    padding: 0
                                    verticalAlignment: TextInput.AlignVCenter
                                    onTextChanged: filterDebounce.restart()
                                }

                                Rectangle {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    radius: 4
                                    visible: searchField.text.length > 0
                                    color: clearSearchMouse.containsMouse ? hoverRowColor : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        color: secondaryTextColor
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        id: clearSearchMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: searchField.text = ""
                                    }
                                }
                            }
                        }

                        Label {
                            visible: controller.proxyModel.filterText !== ""
                            text: controller.proxyModel.matchCount + " match" +
                                  (controller.proxyModel.matchCount === 1 ? "" : "es")
                            color: controller.proxyModel.matchCount > 0 ? accentColor : "#E57373"
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        FlatToolButton {
                            text: "Expand"
                            tip: "Expand all groups (Ctrl+E)"
                            onClicked: treeView.expandRecursively()
                        }

                        FlatToolButton {
                            text: "Collapse"
                            tip: "Collapse all groups (Ctrl+Shift+E)"
                            onClicked: {
                                window.autoExpandDuringScan = false
                                treeView.collapseRecursively()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 24
                            color: borderColor
                        }

                        FlatToolButton {
                            text: "A−"
                            tip: "Smaller text (Ctrl+-)"
                            onClicked: window.adjustFontSize(-1)
                        }

                        FlatToolButton {
                            text: "A+"
                            tip: "Larger text (Ctrl+=)"
                            onClicked: window.adjustFontSize(1)
                        }
                    }
                }

                // ---- Column header with draggable divider ----
                Rectangle {
                    id: columnHeader
                    Layout.fillWidth: true
                    height: 34
                    color: headerBgColor

                    Label {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: window.oidColumnWidth - 24
                        text: "OID / Parameter"
                        color: secondaryTextColor
                        font.bold: true
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        x: window.oidColumnWidth
                        width: 1
                        height: parent.height
                        color: borderColor
                    }

                    Label {
                        x: window.oidColumnWidth + 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Value"
                        color: secondaryTextColor
                        font.bold: true
                        font.pixelSize: 12
                    }

                    MouseArea {
                        x: window.oidColumnWidth - 4
                        width: 9
                        height: parent.height
                        cursorShape: Qt.SplitHCursor
                        onMouseXChanged: {
                            if (pressed)
                                window.oidColumnWidth = Math.max(240,
                                    Math.min(rightPane.width - 240, window.oidColumnWidth + mouseX - 4))
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: borderColor
                    }
                }

                // ---- Results tree ----
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TreeView {
                        id: treeView
                        anchors.fill: parent
                        model: controller.proxyModel
                        clip: true
                        alternatingRows: true
                        flickableDirection: Flickable.VerticalFlick
                        boundsBehavior: Flickable.StopAtBounds
                        selectionModel: ItemSelectionModel { model: treeView.model }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: Item {
                            id: treeDelegate
                            implicitWidth: treeView.width
                            implicitHeight: Math.max(28, Math.round(window.treeFontSize * 2.2))

                            required property TreeView treeView
                            required property bool expanded
                            required property bool hasChildren
                            required property int depth
                            required property int row
                            required property bool current
                            required property var model

                            readonly property real indent: 18
                            readonly property bool isGroupRow: hasChildren
                            readonly property color valueColor: window.typeColor(model.valueType || "")

                            function selectRow() {
                                // Qt 6.4.2: TreeView.index() only exists from 6.4.3; the
                                // point-based modelIndex(cell) is available since 6.4.0.
                                treeView.selectionModel.setCurrentIndex(
                                    treeView.modelIndex(Qt.point(0, treeDelegate.row)),
                                    ItemSelectionModel.NoUpdate)
                                if (!isGroupRow) {
                                    window.selOid = model.oid || ""
                                    window.selValue = model.value || ""
                                    window.selRaw = model.rawValue || ""
                                    window.selType = model.valueType || ""
                                }
                            }

                            function toggleRow() {
                                if (treeDelegate.expanded && controller.isScanning)
                                    window.autoExpandDuringScan = false
                                treeView.toggleExpanded(treeDelegate.row)
                            }

                            ToolTip.visible: rowMouse.containsMouse && !isGroupRow &&
                                             (valueText.truncated || oidText.truncated)
                            ToolTip.delay: 500
                            ToolTip.text: (model.oid || "") + "\n" + (model.value || "")

                            Rectangle {
                                anchors.fill: parent
                                color: {
                                    if (treeDelegate.current)
                                        return Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
                                    if (rowMouse.containsMouse)
                                        return hoverRowColor
                                    if (treeDelegate.row % 2 === 1)
                                        return alternateRowColor
                                    return panelColor
                                }
                            }

                            // Accent stripe on the selected row
                            Rectangle {
                                width: 3
                                height: parent.height
                                color: accentColor
                                visible: treeDelegate.current
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton

                                onClicked: function(mouse) {
                                    treeDelegate.selectRow()
                                    if (mouse.button === Qt.RightButton) {
                                        contextMenu.currentOid = treeDelegate.model.oid || ""
                                        contextMenu.currentValue = treeDelegate.model.value || ""
                                        contextMenu.currentRawValue = treeDelegate.model.rawValue || ""
                                        contextMenu.isGroup = treeDelegate.isGroupRow
                                        contextMenu.popup()
                                    } else if (treeDelegate.isGroupRow) {
                                        treeDelegate.toggleRow()
                                    }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Item {
                                    id: indentItem
                                    Layout.preferredWidth: treeDelegate.depth * treeDelegate.indent +
                                                           (treeDelegate.isGroupRow ? 18 : 22)
                                    Layout.fillHeight: true

                                    Text {
                                        visible: treeDelegate.isGroupRow
                                        anchors.right: parent.right
                                        anchors.rightMargin: 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: treeDelegate.expanded ? "▼" : "▶"
                                        color: groupTitleColor
                                        font.pixelSize: 10
                                    }
                                }

                                Text {
                                    id: oidText
                                    Layout.preferredWidth: Math.max(60,
                                        window.oidColumnWidth - indentItem.width - 22)
                                    text: treeDelegate.model.oid || ""
                                    color: treeDelegate.isGroupRow ? groupTitleColor : textColor
                                    font.bold: treeDelegate.isGroupRow
                                    font.pixelSize: window.treeFontSize
                                    font.family: treeDelegate.isGroupRow ? window.font.family : window.monoFont
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }

                                // Child count badge on group rows
                                Rectangle {
                                    visible: treeDelegate.isGroupRow
                                    Layout.preferredWidth: groupCountText.implicitWidth + 14
                                    Layout.preferredHeight: 18
                                    radius: 9
                                    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.18)

                                    Text {
                                        id: groupCountText
                                        anchors.centerIn: parent
                                        text: (treeDelegate.model.childCount || 0) + " items"
                                        color: groupTitleColor
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                // Value type badge on leaf rows
                                Rectangle {
                                    visible: !treeDelegate.isGroupRow &&
                                             window.typeLabel(treeDelegate.model.valueType || "") !== ""
                                    Layout.preferredWidth: 40
                                    Layout.preferredHeight: 17
                                    radius: 4
                                    color: Qt.rgba(treeDelegate.valueColor.r, treeDelegate.valueColor.g,
                                                   treeDelegate.valueColor.b, 0.16)
                                    border.color: Qt.rgba(treeDelegate.valueColor.r, treeDelegate.valueColor.g,
                                                          treeDelegate.valueColor.b, 0.45)
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: window.typeLabel(treeDelegate.model.valueType || "")
                                        color: treeDelegate.valueColor
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }

                                Text {
                                    id: valueText
                                    Layout.fillWidth: true
                                    text: treeDelegate.isGroupRow ? "" : (treeDelegate.model.value || "")
                                    color: treeDelegate.valueColor
                                    font.pixelSize: window.treeFontSize
                                    font.family: window.monoFont
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }

                                // Quick copy button, shown on hover
                                Rectangle {
                                    visible: !treeDelegate.isGroupRow &&
                                             (rowMouse.containsMouse || copyMouse.containsMouse)
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 22
                                    radius: 4
                                    color: copyMouse.containsMouse ?
                                           Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "⧉"
                                        color: accentColor
                                        font.pixelSize: 13
                                    }

                                    MouseArea {
                                        id: copyMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: controller.copyToClipboard(treeDelegate.model.value || "")

                                        ToolTip.visible: containsMouse
                                        ToolTip.delay: 400
                                        ToolTip.text: "Copy value"
                                    }
                                }
                            }
                        }
                    }

                    // Empty / no-match state
                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: controller.treeModel.itemCount === 0 ||
                                 (controller.proxyModel.filterText !== "" &&
                                  controller.proxyModel.matchCount === 0)

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controller.treeModel.itemCount === 0
                                  ? (controller.isScanning ? "Scanning device…" : "No data yet")
                                  : "No matches"
                            font.pixelSize: 18
                            font.bold: true
                            color: secondaryTextColor
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: controller.treeModel.itemCount === 0
                                  ? (controller.isScanning
                                     ? "Waiting for the first SNMP response…"
                                     : "Configure the device on the left, then press CONNECT DEVICE")
                                  : "Nothing matches \"" + controller.proxyModel.filterText +
                                    "\" — press Esc to clear the filter"
                            font.pixelSize: 12
                            color: secondaryTextColor
                        }
                    }
                }

                // ---- Detail pane for the selected object ----
                Rectangle {
                    visible: window.selOid !== ""
                    Layout.fillWidth: true
                    Layout.preferredHeight: 170
                    color: isDarkTheme ? "#181818" : "#FAFAFA"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: 1
                        color: borderColor
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Label {
                                text: "SELECTED OBJECT"
                                color: groupTitleColor
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Rectangle {
                                visible: window.typeLabel(window.selType) !== ""
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 17
                                radius: 4
                                color: Qt.rgba(window.typeColor(window.selType).r,
                                               window.typeColor(window.selType).g,
                                               window.typeColor(window.selType).b, 0.16)
                                border.color: window.typeColor(window.selType)
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: window.typeLabel(window.selType)
                                    color: window.typeColor(window.selType)
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            FlatToolButton {
                                text: "Copy Value"
                                onClicked: controller.copyToClipboard(window.selValue)
                            }

                            FlatToolButton {
                                text: "Copy Raw"
                                onClicked: controller.copyToClipboard(window.selRaw)
                            }

                            FlatToolButton {
                                text: "✕"
                                tip: "Close (Esc)"
                                onClicked: window.clearSelection()
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 2
                            columnSpacing: 12
                            rowSpacing: 4

                            Label {
                                text: "OID"
                                color: secondaryTextColor
                                font.pixelSize: 11
                                font.bold: true
                                Layout.alignment: Qt.AlignTop
                            }
                            TextEdit {
                                Layout.fillWidth: true
                                text: window.selOid
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.WrapAnywhere
                                color: textColor
                                selectionColor: accentColor
                                font.family: window.monoFont
                                font.pixelSize: 12
                            }

                            Label {
                                text: "Value"
                                color: secondaryTextColor
                                font.pixelSize: 11
                                font.bold: true
                                Layout.alignment: Qt.AlignTop
                            }
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentWidth: availableWidth
                                clip: true

                                TextEdit {
                                    width: parent.width
                                    text: window.selValue
                                    readOnly: true
                                    selectByMouse: true
                                    wrapMode: TextEdit.WrapAnywhere
                                    color: window.typeColor(window.selType)
                                    selectionColor: accentColor
                                    font.family: window.monoFont
                                    font.pixelSize: window.treeFontSize + 1
                                }
                            }

                            Label {
                                text: "Raw"
                                color: secondaryTextColor
                                font.pixelSize: 11
                                font.bold: true
                                Layout.alignment: Qt.AlignTop
                            }
                            TextEdit {
                                Layout.fillWidth: true
                                text: window.selRaw
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.WrapAnywhere
                                color: secondaryTextColor
                                selectionColor: accentColor
                                font.family: window.monoFont
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                // ---- Status bar ----
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
                        text: controller.proxyModel.filterText !== ""
                              ? controller.proxyModel.matchCount + " of " +
                                controller.treeModel.itemCount + " items"
                              : controller.treeModel.itemCount + " items"
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
        property string currentOid: ""
        property string currentValue: ""
        property string currentRawValue: ""
        property bool isGroup: false

        background: Rectangle {
            implicitWidth: 180
            color: panelColor
            border.color: borderColor
            radius: 4
        }

        MenuItem {
            text: "Copy Name / OID"
            onTriggered: controller.copyToClipboard(contextMenu.currentOid)
            background: Rectangle { color: parent.highlighted ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) : "transparent" }
            contentItem: Text { text: parent.text; color: textColor }
        }

        MenuItem {
            text: "Copy Value"
            enabled: !contextMenu.isGroup
            onTriggered: controller.copyToClipboard(contextMenu.currentValue)
            background: Rectangle { color: parent.highlighted ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) : "transparent" }
            contentItem: Text { text: parent.text; color: parent.enabled ? textColor : secondaryTextColor }
        }

        MenuItem {
            text: "Copy Raw Value"
            enabled: !contextMenu.isGroup
            onTriggered: controller.copyToClipboard(contextMenu.currentRawValue)
            background: Rectangle { color: parent.highlighted ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) : "transparent" }
            contentItem: Text { text: parent.text; color: parent.enabled ? textColor : secondaryTextColor }
        }

        MenuItem {
            text: "Copy Row"
            enabled: !contextMenu.isGroup
            onTriggered: controller.copyToClipboard(contextMenu.currentOid + "\t" + contextMenu.currentValue)
            background: Rectangle { color: parent.highlighted ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3) : "transparent" }
            contentItem: Text { text: parent.text; color: parent.enabled ? textColor : secondaryTextColor }
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

    component FlatToolButton: Button {
        property string tip: ""
        implicitHeight: 30
        leftPadding: 10
        rightPadding: 10
        hoverEnabled: true

        ToolTip.visible: hovered && tip.length > 0
        ToolTip.delay: 400
        ToolTip.text: tip

        background: Rectangle {
            radius: 6
            color: parent.pressed ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.3)
                 : parent.hovered ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
                 : "transparent"
            border.color: borderColor
            border.width: 1
        }

        contentItem: Text {
            text: parent.text
            color: textColor
            font.pixelSize: 12
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
