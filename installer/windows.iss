; SNMP Browser - InnoSetup 6 installer script
; Called from CI as:
;   ISCC.exe /DMyAppVersion=1.0.0 installer\windows.iss

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#define MyAppName      "SNMP Browser"
#define MyAppPublisher "Phoenix-flame"
#define MyAppExeName   "SNMPBrowser.exe"
#define MyAppSourceDir "..\dist"
#define MyOutputDir    "output"

[Setup]
AppId={{6A8B2C3D-4E5F-7A6B-8C9D-0E1F2A3B4C5D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://github.com/Phoenix-flame/SNMP_Browser
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir={#MyOutputDir}
OutputBaseFilename=SNMPBrowser-Setup-{#MyAppVersion}-x86_64
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
; Require 64-bit Windows 10+
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; \
  GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Main executable
Source: "{#MyAppSourceDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; Qt DLLs and all plugin/QML subdirectories deployed by windeployqt
Source: "{#MyAppSourceDir}\*"; DestDir: "{app}"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}";                 Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";           Filename: "{app}\{#MyAppExeName}"; \
  Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; \
  Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; \
  Flags: nowait postinstall skipifsilent
