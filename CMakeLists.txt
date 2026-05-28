cmake_minimum_required(VERSION 3.16)
project(SNMPBrowser VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
include(GNUInstallDirs)

# Find Qt packages
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Qml
    Quick
    QuickControls2
    Concurrent
)

set(NET_SNMP_SEARCH_HINTS)
if(DEFINED NET_SNMP_ROOT AND NOT "${NET_SNMP_ROOT}" STREQUAL "")
    list(APPEND NET_SNMP_SEARCH_HINTS "${NET_SNMP_ROOT}")
endif()

# Find net-snmp library. Net-SNMP's legacy MSVC win32 build installs import
# libraries under lib/release or lib/debug, while Unix packages usually install
# directly under lib. Search both layouts so CMAKE_PREFIX_PATH is enough for CI.
find_library(NET_SNMP_LIB
    NAMES netsnmp
    HINTS ${NET_SNMP_SEARCH_HINTS}
    PATH_SUFFIXES
        lib
        lib/release
        lib/debug
        lib/${CMAKE_BUILD_TYPE}
    REQUIRED
)

find_path(NET_SNMP_INCLUDE
    NAMES net-snmp/net-snmp-config.h
    HINTS ${NET_SNMP_SEARCH_HINTS}
    PATH_SUFFIXES include
    REQUIRED
)

message(STATUS "NET_SNMP_ROOT=${NET_SNMP_ROOT}")
message(STATUS "NET_SNMP_LIB=${NET_SNMP_LIB}")
message(STATUS "NET_SNMP_INCLUDE=${NET_SNMP_INCLUDE}")

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

# Create executable. WIN32 prevents Windows release builds from opening a
# separate console window beside the Qt Quick GUI.
qt_add_executable(${PROJECT_NAME} WIN32 MACOSX_BUNDLE
    ${SOURCES}
    ${HEADERS}
    ${QML_RESOURCES}
)

# Include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${NET_SNMP_INCLUDE}
)

if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /utf-8)
endif()

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
