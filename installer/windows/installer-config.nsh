; Feral Desktop Windows Installer Configuration
; This creates a simple, user-friendly installer experience

!define PRODUCT_NAME "Feral Desktop"
!define PRODUCT_VERSION "1.0.0"
!define PRODUCT_PUBLISHER "Feral Community"
!define PRODUCT_WEB_SITE "https://feral.io"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\feral-desktop.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "..\..\build\icons\feral.ico"
!define MUI_UNICON "..\..\build\icons\feral.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "..\..\build\icons\feral-installer-sidebar.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "..\..\build\icons\feral-installer-header.bmp"

; Welcome page settings
!define MUI_WELCOMEPAGE_TITLE "Welcome to Feral Desktop"
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of Feral Desktop.$\r$\n$\r$\nFeral Desktop is a secure messaging app for the Feralism community.$\r$\n$\r$\nClick Next to continue."

; License page (optional, can be skipped for simpler install)
!define MUI_LICENSEPAGE_CHECKBOX

; Directory page
!define MUI_DIRECTORYPAGE_TEXT_TOP "Setup will install Feral Desktop in the following folder. To install in a different folder, click Browse and select another folder. Click Next to continue."

; Install page
!define MUI_INSTFILESPAGE_COLORS "FFFFFF 000000"

; Finish page
!define MUI_FINISHPAGE_TITLE "Installation Complete"
!define MUI_FINISHPAGE_TEXT "Feral Desktop has been installed on your computer.$\r$\n$\r$\nClick Finish to close this wizard."
!define MUI_FINISHPAGE_RUN "$INSTDIR\feral-desktop.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch Feral Desktop"
!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_LINK "Visit Feral Community"
!define MUI_FINISHPAGE_LINK_LOCATION "https://feral.io"

; Language
!insertmacro MUI_LANGUAGE "English"

; Installer sections
Section "Feral Desktop" SEC01
  SetOutPath "$INSTDIR"
  SetOverwrite on
  
  ; Copy all application files
  File /r "..\..\dist\win-unpacked\*.*"
  
  ; Create desktop shortcut
  CreateShortCut "$DESKTOP\Feral Desktop.lnk" "$INSTDIR\feral-desktop.exe"
  
  ; Create Start Menu shortcuts
  CreateDirectory "$SMPROGRAMS\Feral Desktop"
  CreateShortCut "$SMPROGRAMS\Feral Desktop\Feral Desktop.lnk" "$INSTDIR\feral-desktop.exe"
  CreateShortCut "$SMPROGRAMS\Feral Desktop\Uninstall.lnk" "$INSTDIR\uninstall.exe"
SectionEnd

; Post-installation
Section -Post
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  ; Registry entries for Windows
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\feral-desktop.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\feral-desktop.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  
  ; Register Matrix protocol handler
  WriteRegStr HKCR "matrix" "" "URL:Matrix Protocol"
  WriteRegStr HKCR "matrix" "URL Protocol" ""
  WriteRegStr HKCR "matrix\DefaultIcon" "" "$INSTDIR\feral-desktop.exe,1"
  WriteRegStr HKCR "matrix\shell\open\command" "" '"$INSTDIR\feral-desktop.exe" "%1"'
SectionEnd

; Uninstaller
Section Uninstall
  ; Remove shortcuts
  Delete "$DESKTOP\Feral Desktop.lnk"
  Delete "$SMPROGRAMS\Feral Desktop\*.*"
  RMDir "$SMPROGRAMS\Feral Desktop"
  
  ; Remove application files
  RMDir /r "$INSTDIR"
  
  ; Remove registry entries
  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  DeleteRegKey HKCR "matrix"
SectionEnd