# SNMPv3 Browser - Qt C++ with QML

A cross-platform SNMP browser application built with Qt6/C++ and QML.

## Features

- SNMPv3 support with authentication and privacy (MD5/DES)
- MIB file loading and compilation
- Tree view with grouped OID display
- Light/Dark theme support
- Export to CSV/JSON
- Persistent settings

## Prerequisites

### System Dependencies

**Ubuntu/Debian:**
```bash
sudo apt install qt6-base-dev qt6-declarative-dev qt6-quickcontrols2-dev \
                 libsnmp-dev cmake build-essential
```

**Fedora:**
```bash
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtquickcontrols2-devel \
                 net-snmp-devel cmake gcc-c++
```

**Arch Linux:**
```bash
sudo pacman -S qt6-base qt6-declarative qt6-quickcontrols2 net-snmp cmake
```

**macOS (with Homebrew):**
```bash
brew install qt@6 net-snmp cmake
```

## Building

```bash
# Create build directory
mkdir build && cd build

# Configure with CMake
cmake ..

# Build
make -j$(nproc)

# Run
./SNMPBrowser
```

## Project Structure

```
cpp_qt/
├── CMakeLists.txt          # Build configuration
├── README.md               # This file
├── resources/
│   ├── qml.qrc             # QML resource file
│   └── qml/
│       └── Main.qml        # Main QML UI
└── src/
    ├── main.cpp            # Application entry point
    ├── deviceconfig.h      # Device configuration struct
    ├── snmpcontroller.h/cpp # Main controller
    ├── snmpworker.h/cpp    # SNMP walk worker thread
    ├── mibcompilerworker.h/cpp # MIB compilation worker
    ├── treemodel.h/cpp     # Tree model for QML
    └── settingsmanager.h/cpp # Settings persistence
```

## Usage

1. **Connection Settings**: Enter the target device's IP, port, and SNMPv3 credentials
2. **MIB Definitions**: Optionally load MIB files for better OID resolution
3. **Connect**: Click "CONNECT DEVICE" to start the SNMP walk
4. **Export**: Save results as CSV or JSON

## License

This project is provided as-is for educational purposes.
