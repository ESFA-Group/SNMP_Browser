# SNMPv3 Browser & MIB Loader

A cross-platform SNMP browser application with SNMPv3 support, MIB file loading, and a modern UI with dark/light themes.

![SNMP Browser](https://img.shields.io/badge/SNMPv3-Supported-green) ![Python](https://img.shields.io/badge/Python-3.8+-blue) ![Qt](https://img.shields.io/badge/Qt-6-brightgreen)

## Features

- **SNMPv3 Support** - Authentication (MD5) and Privacy (DES) protocols
- **MIB Loading** - Load and compile custom MIB files for OID resolution
- **Tree View Display** - Grouped, hierarchical view of SNMP data
- **Dark/Light Themes** - Modern UI with theme switching
- **Export** - Save snapshots to CSV or JSON format
- **Persistent Settings** - Remembers connection details and preferences

## Installation

Choose either the **Python** version or the **C++/Qt** version:

---

### Python Version (Recommended for quick start)

#### Prerequisites

- Python 3.8 or higher
- pip package manager

#### Install Dependencies

```bash
# Clone the repository
git clone https://github.com/Phoenix-flame/SNMP_Browser.git
cd SNMP_Browser

# Install required packages
pip install PyQt6 pysnmp

# Or use requirements (if available)
pip install -r requirements.txt
```

#### Run

```bash
python main.py
```

---

### C++/Qt Version

#### Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y \
    qt6-base-dev \
    qt6-declarative-dev \
    qml6-module-qtquick \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    qml6-module-qtquick-dialogs \
    qml6-module-qt-labs-platform \
    qml6-module-qtqml-workerscript \
    libsnmp-dev \
    cmake \
    build-essential
```

**Fedora:**
```bash
sudo dnf install -y \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    qt6-qtquickcontrols2-devel \
    net-snmp-devel \
    cmake \
    gcc-c++
```

**Arch Linux:**
```bash
sudo pacman -S qt6-base qt6-declarative qt6-quickcontrols2 net-snmp cmake
```

**macOS (Homebrew):**
```bash
brew install qt@6 net-snmp cmake
```

#### Build

```bash
cd cpp_qt
mkdir build && cd build
cmake ..
make -j$(nproc)
```

#### Run

```bash
./SNMPBrowser
```

---

## Usage

1. **Configure Connection**
   - Enter the target device IP address
   - Set the SNMP port (default: 161)
   - Enter SNMPv3 credentials (username, auth key, priv key)

2. **Load MIB Files** (Optional)
   - Click "Select Folder" to choose a directory containing `.mib` files
   - Click "Compile MIBs" to process the MIB definitions

3. **Connect**
   - Click "CONNECT DEVICE" to start the SNMP walk
   - Results appear in the tree view, grouped by MIB module

4. **Export**
   - Click "EXPORT SNAPSHOT" to save results as CSV or JSON

## Project Structure

```
SNMP_Browser/
├── main.py                 # Python version entry point
├── README.md               # This file
└── cpp_qt/                 # C++/Qt version
    ├── CMakeLists.txt      # Build configuration
    ├── README.md           # C++ specific docs
    ├── resources/
    │   ├── qml.qrc         # QML resources
    │   └── qml/
    │       └── Main.qml    # QML UI
    └── src/
        ├── main.cpp
        ├── deviceconfig.h
        ├── snmpcontroller.h/cpp
        ├── snmpworker.h/cpp
        ├── mibcompilerworker.h/cpp
        ├── treemodel.h/cpp
        └── settingsmanager.h/cpp
```

## Screenshots

The application features a split-pane interface:
- **Left panel**: Connection settings, MIB configuration, action buttons
- **Right panel**: Tree view displaying SNMP walk results

## License

This project is provided as-is for educational and personal use.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
