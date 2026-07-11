; SNMP Browser - InnoSetup 6 installer script
; Called from CI as:
;   ISCC.exe /DMyAppVersion=1.0.0 installer\windows.iss

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif

#define MyAppName      "SNMP Browser"
#define MyAppPublisher "ESFA Group"
#define MyAppExeName   "SNMPBrowser.exe"
#ifndef MyAppSourceDir
  #define MyAppSourceDir "..\dist"
#endif
#define MyOutputDir    "output"

[Setup]
AppId={{6A8B2C3D-4E5F-7A6B-8C9D-0E1F2A3B4C5D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://esfagroup.com
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir={#MyOutputDir}
OutputBaseFilename=SNMPBrowser-Setup-{#MyAppVersion}-x86_64
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}
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

; MSVC runtime redistributable (deployed by windeployqt --compiler-runtime).
; Extracted to {tmp} and installed from [Run]; not kept in {app}.
Source: "{#MyAppSourceDir}\vc_redist.x64.exe"; DestDir: "{tmp}"; \
  Flags: deleteafterinstall skipifsourcedoesntexist

; Qt DLLs and all plugin/QML subdirectories deployed by windeployqt
Source: "{#MyAppSourceDir}\*"; DestDir: "{app}"; \
  Excludes: "vc_redist.x64.exe"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}";                 Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}";           Filename: "{app}\{#MyAppExeName}"; \
  Tasks: desktopicon

[Run]
; Install the MSVC runtime quietly before offering to launch the app.
; /norestart + exit code 3010 (reboot required) must not abort the install.
Filename: "{tmp}\vc_redist.x64.exe"; \
  Parameters: "/install /quiet /norestart"; \
  StatusMsg: "Installing Microsoft Visual C++ Runtime..."; \
  Flags: skipifdoesntexist waituntilterminated

Filename: "{app}\{#MyAppExeName}"; \
  Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; \
  Flags: nowait postinstall skipifsilent
