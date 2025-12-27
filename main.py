import sys
import os
import csv
import json
import datetime
from dataclasses import dataclass

from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QLabel, QLineEdit, QPushButton, 
                             QTreeWidget, QTreeWidgetItem, QSplitter, QFileDialog,
                             QMessageBox, QGroupBox, QFormLayout, QFrame, QProgressBar,
                             QMenu) # Added QMenu
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QSettings
from PyQt6.QtGui import QIcon, QFont, QPalette, QColor

# PySNMP Imports
from pysnmp.hlapi import (
    SnmpEngine,
    UsmUserData,
    nextCmd,
    UdpTransportTarget,
    ContextData,
    ObjectType,
    ObjectIdentity,
    usmHMACMD5AuthProtocol,
    usmDESPrivProtocol
)
# Import the MIB Compiler
from pysnmp.smi import compiler

# --- Data Structures ---

@dataclass
class DeviceConfig:
    ip: str
    port: int
    username: str
    auth_key: str
    priv_key: str

# --- MIB Compiler Worker (Prevents UI Freezing) ---

class MibCompilerWorker(QThread):
    """
    Handles MIB compilation in the background.
    Includes online sources to resolve dependencies.
    """
    progress_signal = pyqtSignal(str)
    finished_signal = pyqtSignal(str) # Report text

    def __init__(self, mib_path):
        super().__init__()
        self.mib_path = mib_path

    def run(self):
        self.progress_signal.emit("Initializing Compiler...")
        
        engine = SnmpEngine()
        builder = engine.getMibBuilder()
        
        try:
            # Add both local and ONLINE sources for the explicit compile step
            compiler.addMibCompiler(
                builder,
                sources=[
                    f'file://{self.mib_path}',
                    'http://mibs.thola.io/asn1/@mib@' 
                ]
            )
        except Exception as e:
            self.finished_signal.emit(f"Critical Error setting up compiler: {e}")
            return

        results = []
        errors = 0
        processed_count = 0
        
        if not os.path.exists(self.mib_path):
            self.finished_signal.emit("Error: MIB folder path does not exist.")
            return

        all_files = os.listdir(self.mib_path)
        valid_exts = ('.mib', '.my', '.txt', '.smi')
        
        for filename in all_files:
             full_path = os.path.join(self.mib_path, filename)
             
             if os.path.isdir(full_path):
                 continue

             if filename.lower().endswith(valid_exts):
                mod_name = os.path.splitext(filename)[0]
                self.progress_signal.emit(f"Compiling: {mod_name}...")
                try:
                    builder.loadModules(mod_name)
                    results.append(f"✔ {mod_name}: Compiled & Loaded")
                    processed_count += 1
                except Exception as e:
                    errors += 1
                    results.append(f"✘ {mod_name}: {str(e)}")
        
        # Summary Report
        if processed_count == 0:
            report = f"No valid MIB files found in folder.\nChecked for: {valid_exts}"
        else:
            report = f"Processed {processed_count} files.\n{errors} Errors.\n\n" + "\n".join(results)
            
        self.finished_signal.emit(report)

# --- SNMP Walker Worker ---

class SnmpWorker(QThread):
    """
    Runs the SNMP blocking calls in a separate thread.
    """
    log_signal = pyqtSignal(str)          
    result_signal = pyqtSignal(str, str, str)  # OID, RawValue, PrettyValue
    finished_signal = pyqtSignal()
    error_signal = pyqtSignal(str)

    def __init__(self, device: DeviceConfig, mib_path: str = None):
        super().__init__()
        self.device = device
        self.mib_path = mib_path
        self.is_running = True

    def _format_value(self, obj):
        class_name = obj.__class__.__name__

        if class_name == 'TimeTicks':
            try:
                ticks = int(obj)
                total_seconds = ticks / 100
                days, remainder = divmod(total_seconds, 86400)
                hours, remainder = divmod(remainder, 3600)
                minutes, seconds = divmod(remainder, 60)
                
                parts = []
                if days > 0: parts.append(f"{int(days)}d")
                if hours > 0 or days > 0: parts.append(f"{int(hours)}h")
                parts.append(f"{int(minutes)}m")
                parts.append(f"{seconds:.2f}s")
                return " ".join(parts)
            except:
                pass 

        elif class_name == 'OctetString':
            if hasattr(obj, 'asOctets'):
                val_bytes = obj.asOctets()
                allowed = {9, 10, 13}
                is_text = all((32 <= b <= 126) or (b in allowed) for b in val_bytes)

                if not is_text and val_bytes:
                    if len(val_bytes) == 6:
                        return ":".join(f"{b:02X}" for b in val_bytes)
                    return "0x " + " ".join(f"{b:02X}" for b in val_bytes)
                return obj.prettyPrint()

        elif class_name == 'IpAddress':
            return obj.prettyPrint()

        return obj.prettyPrint()

    def run(self):
        self.log_signal.emit(f"Starting SNMP Walk on {self.device.ip}...")

        snmp_engine = SnmpEngine()

        if self.mib_path and os.path.isdir(self.mib_path):
            builder = snmp_engine.getMibBuilder()
            try:
                # 1. ATTACH THE COMPILER (LOCAL ONLY)
                # Removed 'http' source to prevent hanging during connection.
                # Use "Compile MIBs" button for dependencies.
                compiler.addMibCompiler(
                    builder, 
                    sources=[f'file://{self.mib_path}']
                )
                self.log_signal.emit(f"MIB Source: {self.mib_path}")
                
                # 2. LOAD MODULES (Fast, Local Only)
                loaded_count = 0
                valid_exts = ('.mib', '.my', '.txt', '.smi')

                for filename in os.listdir(self.mib_path):
                    if filename.lower().endswith(valid_exts):
                        mod_name = os.path.splitext(filename)[0]
                        try:
                            # If compiled previously, this is fast. 
                            # If missing dependencies, it might fail silently here,
                            # but won't hang the network.
                            builder.loadModules(mod_name)
                            loaded_count += 1
                        except:
                            pass # Ignore errors during walk, focus on connection
                
                self.log_signal.emit(f"Loaded {loaded_count} MIB modules.")

            except Exception as e:
                self.log_signal.emit(f"MIB Setup Warning: {str(e)}")

        user_data = UsmUserData(
            self.device.username,
            self.device.auth_key,
            self.device.priv_key,
            authProtocol=usmHMACMD5AuthProtocol,
            privProtocol=usmDESPrivProtocol
        )

        iterator = nextCmd(
            snmp_engine,
            user_data,
            UdpTransportTarget((self.device.ip, self.device.port), timeout=2.0, retries=1),
            ContextData(),
            ObjectType(ObjectIdentity('1.3.6.1')), 
            lexicographicMode=False
        )

        try:
            for errorIndication, errorStatus, errorIndex, varBinds in iterator:
                if not self.is_running:
                    break

                if errorIndication:
                    self.error_signal.emit(str(errorIndication))
                    break
                elif errorStatus:
                    self.error_signal.emit(f'{errorStatus.prettyPrint()} at {errorIndex and varBinds[int(errorIndex) - 1][0] or "?"}')
                    break
                else:
                    for varBind in varBinds:
                        oid_str = varBind[0].prettyPrint()
                        
                        # Get RAW value (standard string rep)
                        raw_val_str = varBind[1].prettyPrint()
                        # Get PRETTY value (custom material format)
                        pretty_val_str = self._format_value(varBind[1])
                        
                        self.result_signal.emit(oid_str, raw_val_str, pretty_val_str)

        except Exception as e:
            self.error_signal.emit(f"Critical Error: {str(e)}")

        self.finished_signal.emit()

    def stop(self):
        self.is_running = False

# --- Main GUI Application ---

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("SNMPv3 Browser & MIB Loader")
        self.resize(1100, 750)
        
        self.settings = QSettings("MyCompany", "SnmpBrowser")
        self.mib_folder_path = ""
        self.current_theme = self.settings.value("theme", "dark") 
        self.oid_groups = {} # Dictionary to store tree group items

        self.init_ui()
        self.apply_theme()
        self.load_settings()

    def init_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QHBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        splitter = QSplitter(Qt.Orientation.Horizontal)
        splitter.setHandleWidth(1)
        main_layout.addWidget(splitter)

        # --- Left Panel ---
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)
        left_layout.setContentsMargins(20, 20, 20, 20)
        left_layout.setSpacing(15)
        
        # Header
        lbl_title = QLabel("SNMP Browser")
        lbl_title.setObjectName("headerLabel")
        left_layout.addWidget(lbl_title)

        # Theme Toggle
        self.btn_theme = QPushButton("Switch Theme ☀/Rx")
        self.btn_theme.setObjectName("secondaryButton")
        self.btn_theme.clicked.connect(self.toggle_theme)
        left_layout.addWidget(self.btn_theme)

        # Separator
        line = QFrame()
        line.setFrameShape(QFrame.Shape.HLine)
        line.setFrameShadow(QFrame.Shadow.Sunken)
        left_layout.addWidget(line)

        # Device Config Group
        dev_group = QGroupBox("CONNECTION SETTINGS")
        form_layout = QFormLayout()
        form_layout.setSpacing(10)

        self.input_ip = QLineEdit()
        self.input_port = QLineEdit()
        self.input_user = QLineEdit()
        self.input_auth = QLineEdit()
        self.input_auth.setPlaceholderText("MD5")
        self.input_auth.setEchoMode(QLineEdit.EchoMode.Password)
        self.input_priv = QLineEdit()
        self.input_priv.setPlaceholderText("DES")
        self.input_priv.setEchoMode(QLineEdit.EchoMode.Password)

        form_layout.addRow("Host IP:", self.input_ip)
        form_layout.addRow("Port:", self.input_port)
        form_layout.addRow("User:", self.input_user)
        form_layout.addRow("Auth Key:", self.input_auth)
        form_layout.addRow("Priv Key:", self.input_priv)
        
        dev_group.setLayout(form_layout)
        left_layout.addWidget(dev_group)

        # MIB Config Group
        mib_group = QGroupBox("MIB DEFINITIONS")
        mib_layout = QVBoxLayout()
        self.lbl_mib_status = QLabel("No MIB source selected")
        self.lbl_mib_status.setObjectName("statusLabel")
        self.lbl_mib_status.setWordWrap(True)
        
        # New Layout for MIB buttons
        mib_btn_layout = QHBoxLayout()
        self.btn_load_mib = QPushButton("Select Folder")
        self.btn_load_mib.setObjectName("secondaryButton")
        self.btn_load_mib.clicked.connect(self.select_mib_folder)
        
        self.btn_compile_mib = QPushButton("Compile MIBs")
        self.btn_compile_mib.setObjectName("secondaryButton")
        self.btn_compile_mib.clicked.connect(self.compile_mibs)
        
        mib_btn_layout.addWidget(self.btn_load_mib)
        mib_btn_layout.addWidget(self.btn_compile_mib)
        
        mib_layout.addWidget(self.lbl_mib_status)
        mib_layout.addLayout(mib_btn_layout)
        mib_group.setLayout(mib_layout)
        left_layout.addWidget(mib_group)

        left_layout.addStretch()

        # Action Buttons
        self.btn_connect = QPushButton("CONNECT DEVICE")
        self.btn_connect.setObjectName("primaryButton")
        self.btn_connect.setCursor(Qt.CursorShape.PointingHandCursor)
        self.btn_connect.clicked.connect(self.start_snmp_walk)
        left_layout.addWidget(self.btn_connect)

        self.btn_stop = QPushButton("ABORT SCAN")
        self.btn_stop.setObjectName("dangerButton")
        self.btn_stop.setCursor(Qt.CursorShape.PointingHandCursor)
        self.btn_stop.setEnabled(False)
        self.btn_stop.clicked.connect(self.stop_worker)
        left_layout.addWidget(self.btn_stop)
        
        # Export Button
        self.btn_export = QPushButton("EXPORT SNAPSHOT")
        self.btn_export.setObjectName("secondaryButton")
        self.btn_export.setCursor(Qt.CursorShape.PointingHandCursor)
        self.btn_export.clicked.connect(self.export_snapshot)
        self.btn_export.setEnabled(False) # Disabled initially
        left_layout.addWidget(self.btn_export)

        # --- Right Panel ---
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(0, 0, 0, 0)
        right_layout.setSpacing(0)

        self.tree = QTreeWidget()
        self.tree.setHeaderLabels(["OID / Parameter", "Value"])
        self.tree.setColumnWidth(0, 450)
        self.tree.setAlternatingRowColors(True)
        
        # Enable Context Menu
        self.tree.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.tree.customContextMenuRequested.connect(self.open_menu)
        
        right_layout.addWidget(self.tree)

        self.status_bar = QLabel(" Ready to connect")
        self.status_bar.setObjectName("statusBar")
        self.status_bar.setFixedHeight(30)
        right_layout.addWidget(self.status_bar)

        splitter.addWidget(left_panel)
        splitter.addWidget(right_panel)
        splitter.setSizes([340, 760])

    def toggle_theme(self):
        if self.current_theme == "dark":
            self.current_theme = "light"
        else:
            self.current_theme = "dark"
        self.settings.setValue("theme", self.current_theme)
        self.apply_theme()

    def apply_theme(self):
        base_css = """
            * { font-family: 'Segoe UI', 'Roboto', sans-serif; font-size: 14px; }
            QGroupBox { font-weight: bold; border: 1px solid palette(mid); border-radius: 6px; margin-top: 24px; padding-top: 10px; }
            QGroupBox::title { subcontrol-origin: margin; subcontrol-position: top left; padding: 0 5px; left: 10px; }
            QLineEdit { border-radius: 4px; padding: 6px; border: 1px solid palette(mid); }
            QLineEdit:focus { border: 2px solid #4CAF50; }
            QSplitter::handle { background-color: palette(mid); }
            QStatusBar { padding: 5px; }
            QPushButton { border-radius: 4px; padding: 8px 16px; font-weight: bold; border: none; }
            QPushButton#primaryButton { background-color: #4CAF50; color: white; }
            QPushButton#primaryButton:hover { background-color: #45a049; }
            QPushButton#primaryButton:pressed { background-color: #3d8b40; }
            QPushButton#dangerButton { background-color: #F44336; color: white; }
            QPushButton#dangerButton:disabled { background-color: palette(mid); color: palette(disabled); }
            QPushButton#secondaryButton { border: 1px solid palette(mid); background-color: palette(button); }
            QPushButton#secondaryButton:hover { background-color: palette(midlight); }
            QLabel#headerLabel { font-size: 20px; font-weight: bold; margin-bottom: 10px; }
            QLabel#statusBar { padding-left: 10px; font-size: 12px; }
        """

        if self.current_theme == "dark":
            palette = QPalette()
            palette.setColor(QPalette.ColorRole.Window, QColor("#121212"))
            palette.setColor(QPalette.ColorRole.WindowText, QColor("#FFFFFF"))
            palette.setColor(QPalette.ColorRole.Base, QColor("#1E1E1E"))
            palette.setColor(QPalette.ColorRole.AlternateBase, QColor("#252525"))
            palette.setColor(QPalette.ColorRole.Text, QColor("#E0E0E0"))
            palette.setColor(QPalette.ColorRole.Button, QColor("#2C2C2C"))
            palette.setColor(QPalette.ColorRole.ButtonText, QColor("#FFFFFF"))
            palette.setColor(QPalette.ColorRole.Mid, QColor("#444444"))
            QApplication.setPalette(palette)
            
            dark_css = """
                QTreeWidget { background-color: #1E1E1E; border: none; color: #E0E0E0; }
                QHeaderView::section { background-color: #2C2C2C; padding: 6px; border: none; color: #BBB; }
                QLabel#statusLabel { color: #888; }
                QLabel#statusBar { background-color: #0d0d0d; color: #888; }
                QGroupBox::title { color: #81C784; }
                QLineEdit { background-color: #2C2C2C; color: white; border: 1px solid #444; }
            """
            self.setStyleSheet(base_css + dark_css)
            self.btn_theme.setText("Switch to Light Mode ☀")

        else:
            palette = QPalette()
            palette.setColor(QPalette.ColorRole.Window, QColor("#F5F5F5"))
            palette.setColor(QPalette.ColorRole.WindowText, QColor("#000000"))
            palette.setColor(QPalette.ColorRole.Base, QColor("#FFFFFF"))
            palette.setColor(QPalette.ColorRole.AlternateBase, QColor("#F0F0F0"))
            palette.setColor(QPalette.ColorRole.Text, QColor("#212121"))
            palette.setColor(QPalette.ColorRole.Button, QColor("#E0E0E0"))
            palette.setColor(QPalette.ColorRole.ButtonText, QColor("#000000"))
            palette.setColor(QPalette.ColorRole.Mid, QColor("#BDBDBD"))
            QApplication.setPalette(palette)
            
            light_css = """
                QTreeWidget { background-color: #FFFFFF; border: none; color: #212121; }
                QHeaderView::section { background-color: #EEEEEE; padding: 6px; border: none; color: #555; }
                QLabel#statusLabel { color: #666; }
                QLabel#statusBar { background-color: #E0E0E0; color: #444; }
                QGroupBox::title { color: #2E7D32; }
                QLineEdit { background-color: #FFFFFF; color: black; border: 1px solid #CCC; }
            """
            self.setStyleSheet(base_css + light_css)
            self.btn_theme.setText("Switch to Dark Mode 🌙")

    def load_settings(self):
        self.input_ip.setText(self.settings.value("ip", "192.168.1.1"))
        self.input_port.setText(self.settings.value("port", "161"))
        self.input_user.setText(self.settings.value("username", "admin"))
        self.input_auth.setText(self.settings.value("auth_key", ""))
        self.input_priv.setText(self.settings.value("priv_key", ""))
        
        saved_path = self.settings.value("mib_path", "")
        if saved_path and os.path.exists(saved_path):
            self.mib_folder_path = saved_path
            self.lbl_mib_status.setText(f"Loaded: {os.path.basename(saved_path)}")
            self.lbl_mib_status.setStyleSheet("color: #4CAF50;") 
        
    def closeEvent(self, event):
        self.settings.setValue("ip", self.input_ip.text())
        self.settings.setValue("port", self.input_port.text())
        self.settings.setValue("username", self.input_user.text())
        self.settings.setValue("auth_key", self.input_auth.text())
        self.settings.setValue("priv_key", self.input_priv.text())
        self.settings.setValue("mib_path", self.mib_folder_path)
        self.settings.setValue("theme", self.current_theme)
        event.accept()

    def select_mib_folder(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Folder containing .mib files")
        if folder:
            self.mib_folder_path = folder
            self.lbl_mib_status.setText(f"Loaded: {os.path.basename(folder)}")
            self.lbl_mib_status.setStyleSheet("color: #4CAF50;")
            self.status_bar.setText(f"MIB path set to: {folder}")

    def compile_mibs(self):
        if not self.mib_folder_path or not os.path.exists(self.mib_folder_path):
             QMessageBox.warning(self, "Error", "Please select a MIB folder first.")
             return
        
        self.btn_compile_mib.setEnabled(False)
        self.btn_load_mib.setEnabled(False)
        self.status_bar.setText(" Compiling MIBs... check progress.")
        
        # Start Worker
        self.compiler_thread = MibCompilerWorker(self.mib_folder_path)
        self.compiler_thread.progress_signal.connect(self.update_status)
        self.compiler_thread.finished_signal.connect(self.compile_finished)
        self.compiler_thread.start()

    def compile_finished(self, report):
        self.btn_compile_mib.setEnabled(True)
        self.btn_load_mib.setEnabled(True)
        self.status_bar.setText(" Compilation finished.")
        
        msg = QMessageBox(self)
        msg.setWindowTitle("MIB Compilation Report")
        msg.setText("Compilation process completed.")
        msg.setDetailedText(report)
        msg.exec()

    def export_snapshot(self):
        if self.tree.topLevelItemCount() == 0:
            QMessageBox.warning(self, "Export", "No data to export.")
            return

        # Default filename with timestamp
        ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        ip = self.input_ip.text().replace('.', '-')
        default_name = f"snmp_snapshot_{ip}_{ts}.csv"

        file_path, _ = QFileDialog.getSaveFileName(
            self, "Save Snapshot", default_name, "CSV Files (*.csv);;JSON Files (*.json)"
        )
        
        if not file_path:
            return

        try:
            is_json = file_path.lower().endswith('.json')
            
            # Gather Data
            data = []
            
            # Iterate groups
            for i in range(self.tree.topLevelItemCount()):
                group_item = self.tree.topLevelItem(i)
                group_name = group_item.text(0)
                
                # Iterate children
                for j in range(group_item.childCount()):
                    child = group_item.child(j)
                    name = child.text(0)
                    value = child.text(1)
                    raw_val = child.data(1, Qt.ItemDataRole.UserRole)
                    
                    data.append({
                        "Group": group_name,
                        "Parameter": name,
                        "Value": value,
                        "Raw": str(raw_val) if raw_val else ""
                    })

            if is_json:
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=4)
            else:
                # CSV Export
                with open(file_path, 'w', newline='', encoding='utf-8') as f:
                    writer = csv.DictWriter(f, fieldnames=["Group", "Parameter", "Value", "Raw"])
                    writer.writeheader()
                    writer.writerows(data)
            
            self.status_bar.setText(f" Snapshot saved to {os.path.basename(file_path)}")
            QMessageBox.information(self, "Export Success", f"Successfully saved {len(data)} items.")
            
        except Exception as e:
            QMessageBox.critical(self, "Export Error", f"Failed to save file:\n{str(e)}")

    def start_snmp_walk(self):
        if not self.input_ip.text():
            QMessageBox.warning(self, "Error", "IP Address is required")
            return

        config = DeviceConfig(
            ip=self.input_ip.text(),
            port=int(self.input_port.text()),
            username=self.input_user.text(),
            auth_key=self.input_auth.text(),
            priv_key=self.input_priv.text()
        )

        self.tree.clear()
        self.oid_groups = {} # Reset groupings
        self.btn_connect.setEnabled(False)
        self.btn_stop.setEnabled(True)
        self.btn_export.setEnabled(False) # Disable export during new scan
        self.status_bar.setText(" Scanning network device...")

        self.worker = SnmpWorker(config, self.mib_folder_path)
        self.worker.log_signal.connect(self.update_status)
        self.worker.result_signal.connect(self.add_tree_item)
        self.worker.error_signal.connect(self.handle_error)
        self.worker.finished_signal.connect(self.worker_finished)
        
        self.worker.start()

    def stop_worker(self):
        if hasattr(self, 'worker'):
            self.worker.stop()
            self.status_bar.setText(" Stopping scan...")

    def update_status(self, message):
        self.status_bar.setText(f" {message}")

    def add_tree_item(self, oid, raw_value, pretty_value):
        # 1. Determine Group (Module Name) vs Child (Object Name)
        if '::' in oid:
            # Format: Module-Name::Object-Name.Index
            module_name, rest = oid.split('::', 1)
            parent_key = module_name
            display_text = rest
        else:
            # Format: 1.3.6... (Raw OID)
            parent_key = "Raw / Unknown"
            display_text = oid

        # 2. Find or Create Parent Group Item
        if parent_key not in self.oid_groups:
            group_item = QTreeWidgetItem(self.tree)
            group_item.setText(0, parent_key)
            group_item.setText(1, "") # Group headers have no value
            
            # Style the group header
            font = group_item.font(0)
            font.setBold(True)
            group_item.setFont(0, font)
            group_item.setExpanded(True) # Auto-expand groups
            
            self.oid_groups[parent_key] = group_item
        
        # 3. Add Child Item to the Group
        parent_item = self.oid_groups[parent_key]
        child_item = QTreeWidgetItem(parent_item)
        child_item.setText(0, display_text)
        child_item.setText(1, pretty_value)
        # Store raw value for context menu (hidden UserRole)
        child_item.setData(1, Qt.ItemDataRole.UserRole, raw_value)
        # Optional: Add tooltip
        child_item.setToolTip(1, f"Raw: {raw_value}")

    def open_menu(self, position):
        item = self.tree.itemAt(position)
        if not item:
            return
            
        # Create Context Menu
        menu = QMenu()
        
        # Add Actions
        action_copy_pretty = menu.addAction("Copy Value")
        action_copy_raw = menu.addAction("Copy Raw Value")
        
        # Execute Menu
        action = menu.exec(self.tree.viewport().mapToGlobal(position))
        
        clipboard = QApplication.clipboard()
        
        if action == action_copy_pretty:
            # Copy displayed text
            clipboard.setText(item.text(1))
            self.update_status(f"Copied: {item.text(1)}")
            
        elif action == action_copy_raw:
            # Copy hidden raw text
            raw_text = item.data(1, Qt.ItemDataRole.UserRole)
            if raw_text:
                clipboard.setText(raw_text)
                self.update_status(f"Copied Raw: {raw_text}")
            else:
                # Fallback if no raw data (e.g. group headers)
                clipboard.setText(item.text(1))

    def handle_error(self, msg):
        QMessageBox.critical(self, "SNMP Error", msg)

    def worker_finished(self):
        self.status_bar.setText(" Scan Complete.")
        self.btn_connect.setEnabled(True)
        self.btn_stop.setEnabled(False)
        self.btn_export.setEnabled(self.tree.topLevelItemCount() > 0) # Enable export if data exists

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())