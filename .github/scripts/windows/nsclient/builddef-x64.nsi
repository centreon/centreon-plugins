; builddef-x64.nsi

; The bundled third-party plugins (ZipDLL, Registry) are ANSI (NSIS 2.x era);
; force an ANSI build so they load with a modern NSIS 3.x compiler.
Unicode false

; PRODUCT_VERSION / PACKAGE_VERSION / MSI_NSCLIENT can be overridden from the
; command line (makensis /D...) so the CI wires them from versions.json and
; get-environment. The values below are fallbacks for a manual local build.
!ifndef PRODUCT_VERSION
  !define PRODUCT_VERSION "0.11.8"
!endif
!ifndef PACKAGE_VERSION
  !define PACKAGE_VERSION "00000000"
!endif
!ifndef MSI_NSCLIENT
  !define MSI_NSCLIENT "NSCP-0.11.8-x64.msi"
!endif

!define MULTIUSER_EXECUTIONLEVEL Admin
!include MultiUser.nsh
!include Registry.nsh
!include StrFunc.nsh
${StrStrAdv}
${unStrStrAdv}

!define MULTIUSER_INIT_TEXT_ADMINREQUIRED "The user has not enough privileges. Aborting the operation."

; These constants specify the installer
!define INSTALLER_LOGO "resources\logo.bmp"
!define INSTALLER_ICON "resources\centreon.ico"
!define ARCH "x64"
!define PRODUCT_NAME "Centreon NSClient++"
!define PRODUCT_LABEL "Centreon-NSClient"
!define PRODUCT_ICON "${INSTALLER_ICON}"
!define REG_UNINSTALL "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
!define REG_CININSTALL "SOFTWARE\Centreon"
RequestExecutionLevel Admin

; These constants specify the installer file name.
!define INSTALLER_FILE "${PRODUCT_LABEL}-${PRODUCT_VERSION}-${PACKAGE_VERSION}-${ARCH}.exe"

; These constant specify the uninstaller file name.
!define UNINSTALLER_FILE "Uninst.exe"

Var UninstallNSClientID
Var OptionNoUninstall

Name "${PRODUCT_NAME} (${ARCH}) ${PRODUCT_VERSION}-${PACKAGE_VERSION}"
OutFile "${INSTALLER_FILE}"
InstallDir "$PROGRAMFILES64\${PRODUCT_NAME}"

; Interface configuration
; Header file
!include MUI2.nsh
; Page header
!define MUI_ICON "${INSTALLER_ICON}"
!define MUI_UNICON "${INSTALLER_ICON}"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${INSTALLER_LOGO}"
!define MUI_HEADERIMAGE_RIGHT
; Installer and Uninstaller finish page
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_UNFINISHPAGE_NOAUTOCLOSE
; Installer and Uninstaller Abort warning
!define MUI_ABORTWARNING
!define MUI_ABORTWARNING_CANCEL_DEFAULT
!define MUI_UNABORTWARNING
!define MUI_UNABORTWARNING_CANCEL_DEFAULT
; Pages
; Installer Pages
!define MUI_WELCOMEPAGE_TITLE_3LINES
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_TITLE_3LINES
!insertmacro MUI_PAGE_FINISH
; Uninstaller Pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_COMPONENTS
!insertmacro MUI_UNPAGE_INSTFILES
; Language files
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "French"

!insertmacro GetParameters
!insertmacro GetOptions

; Install Centreon NSClient++
Section "${PRODUCT_NAME}" sec_install
    SetOutPath "$INSTDIR"

    StrCmp $OptionNoUninstall 1 0 Uninstall
    DetailPrint "Test if Centreon NSClient++ is already installed"
    ClearErrors
    ReadRegDWORD $0 HKLM "${REG_CININSTALL}" "Centreon NSClient++"
    IfErrors 0 End

    Uninstall:
    StrCpy $UninstallNSClientID ''
    DetailPrint "Looking for NSClient++ installation"
    nsExec::ExecToStack "wmic product where $\"Name like 'NSClient%'$\" get IdentifyingNumber"
    Pop $0
    Pop $1
    ${StrStrAdv} $9 $1 "{" "<" ">" "0" "0" "0"
    StrCpy $UninstallNSClientID $9
    ${StrStrAdv} $9 $UninstallNSClientID "}" "<" "<" "0" "0" "0"
    StrCpy $UninstallNSClientID $9

    StrCmp $UninstallNSClientID '' Install

    DetailPrint "Found id '$UninstallNSClientID'"
    ExecWait "msiexec /qn /x {$UninstallNSClientID}" $0

    Install:
    WriteUninstaller "$INSTDIR\${UNINSTALLER_FILE}"
    File "resources\${MSI_NSCLIENT}"
    ExecWait 'msiexec /norestart /qr /i "$INSTDIR\${MSI_NSCLIENT}" /quiet INSTALLLOCATION="$INSTDIR\" CONF_CHECKS=1 CONF_NRPE=1 CONF_CAN_CHANGE=1' $0

    File "resources\resources.zip"
    ZipDLL::extractall "$INSTDIR\resources.zip" "$INSTDIR\"

    nsExec::ExecToLog 'net stop nscp'
    nsExec::ExecToLog 'net start nscp'

    Delete "$INSTDIR\resources.zip"
    Delete "$INSTDIR\${MSI_NSCLIENT}"

    WriteRegStr HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "DisplayName" "${PRODUCT_NAME}"
    WriteRegStr HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "UninstallString" "$\"$INSTDIR\${UNINSTALLER_FILE}$\""
    WriteRegStr HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "QuietUninstallString" "$\"$INSTDIR\${UNINSTALLER_FILE}$\" /S"
    WriteRegStr HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "RegOwner" "Centreon"
    WriteRegStr HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "RegCompany" "Centreon"
    WriteRegStr HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "Publisher" "Centreon"
    WriteRegStr HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "DisplayIcon" "$INSTDIR\centreon.ico"
    WriteRegStr HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "PackageVersion" "${PACKAGE_VERSION}"
    WriteRegStr HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "URLInfoAbout" "https://www.centreon.com/"
    WriteRegStr HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "Comments" "Centreon NSClient++ agent integration (Visit https://github.com/mickem/nscp)"
    WriteRegDWORD HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "EstimatedSize" "136192"
    WriteRegDWORD HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "NoModify" "1"
    WriteRegDWORD HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}" "NoRepair" "1"
    WriteRegDWORD HKLM "${REG_CININSTALL}" "Centreon NSClient++" "1"
    End:
SectionEnd

; Uninstall Centreon NSClient++
Section "un.${PRODUCT_NAME}" sec_uninstall
    StrCpy $UninstallNSClientID ''
    DetailPrint "Looking for NSClient++ installation"
    nsExec::ExecToStack "wmic product where $\"Name like 'NSClient%'$\" get IdentifyingNumber"
    Pop $0
    Pop $1
    ${unStrStrAdv} $9 $1 "{" "<" ">" "0" "0" "0"
    StrCpy $UninstallNSClientID $9
    ${unStrStrAdv} $9 $UninstallNSClientID "}" "<" "<" "0" "0" "0"
    StrCpy $UninstallNSClientID $9

    StrCmp $UninstallNSClientID '' 0 Uninstall
    DetailPrint "Cannot find product id for uninstall"
    Goto End

    Uninstall:
    DetailPrint "Found id '$UninstallNSClientID'"
    ExecWait "msiexec /qn /x {$UninstallNSClientID}" $0

    Delete "$INSTDIR\${UNINSTALLER_FILE}"
    Delete "$INSTDIR\${PRODUCT_ICON}"
    RMDir /r "$INSTDIR"
    DeleteRegKey HKLM "${REG_UNINSTALL}\${PRODUCT_NAME}"
    DeleteRegValue HKLM "${REG_CININSTALL}" "Centreon NSClient++"
    End:
SectionEnd

; Parse parameters for /nouninstall flag
Function parseParameters
    ${GetOptions} $cmdLineParams '/nouninstall' $R0
    IfErrors +2 0
    StrCpy $OptionNoUninstall 1
FunctionEnd

; Installation Init function
Function .onInit
    !insertmacro MULTIUSER_INIT
    SectionSetSize ${sec_install} 136192

    System::Call 'kernel32::CreateMutexA(i 0, i 0, t "myMutex${PRODUCT_NAME}") i .r1 ?e'
    Pop $R0
    StrCmp $R0 0 +3
        MessageBox MB_OK|MB_ICONEXCLAMATION "The installer is already running."
        Abort

    Var /GLOBAL cmdLineParams
    Push $R0

    ${GetParameters} $cmdLineParams
    ${GetOptions} $cmdLineParams '/?' $R0

    IfErrors +3 0
        MessageBox MB_OK "Options: /S = silent installation, /nouninstall = Don't uninstall if already installed"
        Abort

    Pop $R0
    StrCpy $OptionNoUninstall 0

    ; Parse Parameters
    Push $R0
    Call parseParameters
    Pop $R0
FunctionEnd

; Uninstallation Init function
Function un.onInit
    !insertmacro MULTIUSER_UNINIT
FunctionEnd
