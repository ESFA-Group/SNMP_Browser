import sys
import os
from dataclasses import dataclass

from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QLabel, QLineEdit, QPushButton, 
                             QTreeWidget, QTreeWidgetItem, QSplitter, QFileDialog,
                             QMessageBox, QGroupBox, QFormLayout, QFrame)
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

# --- Worker Thread for SNMP Operations ---

class SnmpWorker(QThread):
    """
    Runs the SNMP blocking calls in a separate thread.
    """
    log_signal = pyqtSignal(str)          
    result_signal = pyqtSignal(str, str)  
    finished_signal = pyqtSignal()
    error_signal = pyqtSignal(str)

    def __init__(self, device: DeviceConfig, mib_path: str = None):
        super().__init__()
        self.device = device
        self.mib_path = mib_path
        self.is_running = True

    def _format_value(self, obj):
        """
        Intelligent type handler to format SNMP values (Time, MAC, IP) 
        into a human-readable 'Material' style.
        """
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
                # 1. ATTACH THE COMPILER
                # Added 'http' source to fetch standard MIBs (like SNMPv2-SMI) if missing locally
                compiler.addMibCompiler(
                    builder, 
                    sources=[
                        f'file://{self.mib_path}',
                        'http://mibs.thola.io/asn1/@mib@' 
                    ]
                )
                self.log_signal.emit(f"MIB Compiler attached to: {self.mib_path}")
                
                # 2. EXPLICITLY LOAD MODULES
                loaded_count = 0
                errors = []
                for filename in os.listdir(self.mib_path):
                    if filename.endswith(('.mib', '.my', '.txt')):
                        mod_name = os.path.splitext(filename)[0]
                        try:
                            builder.loadModules(mod_name)
                            loaded_count += 1
                        except Exception as e:
                            # Capture error to show user
                            err_msg = str(e)
                            errors.append(f"{mod_name}: {err_msg}")
                            print(f"Warning: Could not load MIB {mod_name}: {e}")
                
                if loaded_count == 0 and errors:
                     # Show the first error to help debug
                    self.log_signal.emit(f"MIB Error: {errors[0]}")
                else:
                    self.log_signal.emit(f"Compiled & Loaded {loaded_count} MIB modules.")

            except Exception as e:
                self.log_signal.emit(f"MIB Setup Error: {str(e)}\nHint: Check MIB syntax.")

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
                        val_str = self._format_value(varBind[1])
                        self.result_signal.emit(oid_str, val_str)

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
        self.current_theme = self.settings.value("theme", "dark") # Default to dark

        self.init_ui()
        self.apply_theme() # Apply initial theme
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
        
        self.btn_load_mib = QPushButton("Select Folder")
        self.btn_load_mib.setObjectName("secondaryButton")
        self.btn_load_mib.clicked.connect(self.select_mib_folder)
        
        mib_layout.addWidget(self.lbl_mib_status)
        mib_layout.addWidget(self.btn_load_mib)
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

        # --- Right Panel ---
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(0, 0, 0, 0)
        right_layout.setSpacing(0)

        self.tree = QTreeWidget()
        self.tree.setHeaderLabels(["OID / Parameter", "Value"])
        self.tree.setColumnWidth(0, 450)
        self.tree.setAlternatingRowColors(True)
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
        # Common Styles
        base_css = """
            * { font-family: 'Segoe UI', 'Roboto', sans-serif; font-size: 14px; }
            QGroupBox { font-weight: bold; border: 1px solid palette(mid); border-radius: 6px; margin-top: 24px; padding-top: 10px; }
            QGroupBox::title { subcontrol-origin: margin; subcontrol-position: top left; padding: 0 5px; left: 10px; }
            QLineEdit { border-radius: 4px; padding: 6px; border: 1px solid palette(mid); }
            QLineEdit:focus { border: 2px solid #4CAF50; }
            QSplitter::handle { background-color: palette(mid); }
            QStatusBar { padding: 5px; }
            
            /* Button Styles */
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
            # Dark Material Palette
            palette = QPalette()
            palette.setColor(QPalette.ColorRole.Window, QColor("#121212"))
            palette.setColor(QPalette.ColorRole.WindowText, QColor("#FFFFFF"))
            palette.setColor(QPalette.ColorRole.Base, QColor("#1E1E1E")) # Inputs/Tree
            palette.setColor(QPalette.ColorRole.AlternateBase, QColor("#252525")) # Tree Alternate
            palette.setColor(QPalette.ColorRole.Text, QColor("#E0E0E0"))
            palette.setColor(QPalette.ColorRole.Button, QColor("#2C2C2C"))
            palette.setColor(QPalette.ColorRole.ButtonText, QColor("#FFFFFF"))
            palette.setColor(QPalette.ColorRole.Mid, QColor("#444444")) # Borders
            
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
            # Light Material Palette
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
            self.lbl_mib_status.setStyleSheet("color: #4CAF50;") # Green text for success
        
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
        self.btn_connect.setEnabled(False)
        self.btn_stop.setEnabled(True)
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

    def add_tree_item(self, oid, value):
        item = QTreeWidgetItem(self.tree)
        item.setText(0, oid)
        item.setText(1, value)

    def handle_error(self, msg):
        QMessageBox.critical(self, "SNMP Error", msg)

    def worker_finished(self):
        self.status_bar.setText(" Scan Complete.")
        self.btn_connect.setEnabled(True)
        self.btn_stop.setEnabled(False)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())