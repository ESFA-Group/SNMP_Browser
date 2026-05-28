cmake_minimum_required(VERSION 3.16)
project(SNMPBrowser VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find Qt packages
find_package(Qt6 REQUIRED COMPONENTS 
    Core 
    Gui 
    Qml 
    Quick 
    QuickControls2
    Concurrent
)

# Find net-snmp library
find_library(NET_SNMP_LIB netsnmp REQUIRED)
find_path(NET_SNMP_INCLUDE net-snmp/net-snmp-config.h)

# Source files
set(SOURCES
    src/main.cpp
    src/snmpcontroller.cpp
    src/snmpworker.cpp
    src/mibcompilerworker.cpp
    src/treemodel.cpp
    src/settingsmanager.cpp
)

set(HEADERS
    src/snmpcontroller.h
    src/snmpworker.h
    src/mibcompilerworker.h
    src/treemodel.h
    src/settingsmanager.h
    src/deviceconfig.h
)

# QML Resources
qt_add_resources(QML_RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/resources/qml.qrc)

# Create executable
qt_add_executable(${PROJECT_NAME}
    ${SOURCES}
    ${HEADERS}
    ${QML_RESOURCES}
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${NET_SNMP_INCLUDE}
)

# Link libraries
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Concurrent
    ${NET_SNMP_LIB}
)

# Set QML import path
set_target_properties(${PROJECT_NAME} PROPERTIES
    QT_QML_MODULE_VERSION 1.0
    QT_QML_MODULE_URI SNMPBrowser
)

# Install rules
install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
