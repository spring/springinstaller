!define APP_NAME "Spring Installer"
!define APP_REG_ROOT "HKLM"
!define APP_REG_UNINSTALL "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

SetCompress force
SetCompressor /SOLID /FINAL lzma

!addplugindir "plugins"

!include "MUI2.nsh"
; http://nsis.sourceforge.net/Docs/Modern%20UI%202/Readme.html
; Config for Modern Interface
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_TEXT "Thanks for installing this game"

!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME
!define MUI_FINISHPAGE_RUN_TEXT "Start game"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Readme file for game"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION showReadme
!define MUI_FINISHPAGE_RUN ""
!define MUI_FINISHPAGE_RUN_FUNCTION runExit

!define MUI_HEADERIMAGE
;!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\nsis.bmp" ; optional

!define MUI_WELCOMEFINISHPAGE_BITMAP "graphics\SideBanner.bmp"
;!define MUI_WELCOMEPAGE_TITLE "Hey"
;!define MUI_WELCOMEPAGE_TITLE_3LINES ""
;!define MUI_WELCOMEPAGE_TEXT "blabla"

!define SPRING_MAIN_SECTION "Spring"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

!include "LogicLib.nsh"
!include "include/strrep.nsi"
!include "include/StrLoc.nsi"
!include "include/ReadCustomerData.nsi"
!include "include/UninstallLog.nsh"

Outfile "springinstaller.exe"
InstallDir "$PROGRAMFILES\Spring"
Name $GAMENAME

; hidden section to be reused for sections read from .ini
Section "" SEC_0
SectionEnd

Section "" SEC_1
SectionEnd

Section "" SEC_2
SectionEnd

Section "" SEC_3
SectionEnd

Section "" SEC_4
SectionEnd

Section "" SEC_5
SectionEnd

Section "" SEC_6
SectionEnd

Section "" SEC_7
SectionEnd

Section "" SEC_8
SectionEnd

Section "" SEC_9
SectionEnd

Section "" SEC_10
SectionEnd

Section "" SEC_11
SectionEnd

Section "" SEC_12
SectionEnd

Section "" SEC_13
SectionEnd

Section "" SEC_14
SectionEnd

Section "" SEC_15
SectionEnd

VAR /GLOBAL DESC_SECTION_0
VAR /GLOBAL DESC_SECTION_1
VAR /GLOBAL DESC_SECTION_2
VAR /GLOBAL DESC_SECTION_3
VAR /GLOBAL DESC_SECTION_4
VAR /GLOBAL DESC_SECTION_5
VAR /GLOBAL DESC_SECTION_6
VAR /GLOBAL DESC_SECTION_7
VAR /GLOBAL DESC_SECTION_8
VAR /GLOBAL DESC_SECTION_9
VAR /GLOBAL DESC_SECTION_10
VAR /GLOBAL DESC_SECTION_11
VAR /GLOBAL DESC_SECTION_12
VAR /GLOBAL DESC_SECTION_13
VAR /GLOBAL DESC_SECTION_14
VAR /GLOBAL DESC_SECTION_15

VAR /GLOBAL SPRING_INI ; name of ini file
VAR /GLOBAL README ; http url to readme
VAR /GLOBAL VERSION ; version of spring engine
VAR /GLOBAL FILES ; count of files to install
VAR /GLOBAL GAMENAME ; name of the game, is used as filename!
VAR /GLOBAL INSTALLERNAME ; name of installer.exe without .exe
VAR /GLOBAL SOURCEDIR
VAR /GLOBAL EXEC_EXIT ; to be run on exit (optional)
VAR /GLOBAL EXEC_EXIT_PARAMETER ; to be run on exit (optional)
VAR /GLOBAL SIZE ; size of installed files
VAR /GLOBAL UPDATEURL ; url of this file

; temp vars
VAR /GLOBAL MIRROR_COUNT ; count of mirrors of current file
VAR /GLOBAL MD5 ; md5 of current file
VAR /GLOBAL DIRECTORY ; subdirectory where current file to install to
VAR /GLOBAL MIRROR ; current mirror
VAR /GLOBAL FILENAME ; filename of current file
VAR /GLOBAL EXEC ; to execute after file is downladed, %SOURCEDIR% and %INSTALLDIR% are replaced
VAR /GLOBAL EXEC_PARAMS ; params for execute, %SOURCEDIR% and %INSTALLDIR% are replaced
VAR /GLOBAL 7ZIP_EXTRACT_PATH ; extract file to path
VAR /GLOBAL ZIP_EXTRACT_PATH ; extract zip file to this path
VAR /GLOBAL SHORTCUT ; name of shortcut to create in starmenu, %GAMENAME% is replaced
VAR /GLOBAL SHORTCUT_TARGET ; target of shortcut, %INSTALLDIR% is replaced
VAR /GLOBAL SHORTCUT_PARAMETER ; parameter, %INSTALLDIR% is replaced
VAR /GLOBAL SHORTCUT_ICON ; parameter, %INSTALLDIR% is replaced
VAR /GLOBAL SHORTCUT_DIRECTORY ; parameter, %INSTALLDIR% is replaced
VAR /GLOBAL SECTION ; section for current file
VAR /GLOBAL INCLUDE ; ==yes if file is to be included
VAR /GLOBAL ALWAYSUPDATE ; always redownload file

!macro escapeVar var
	!insertmacro ReplaceSubStr ${var} "%GAMENAME%" $GAMENAME
	!insertmacro ReplaceSubStr ${var} "%INSTALLERNAME%" $INSTALLERNAME
	!insertmacro ReplaceSubStr ${var} "%SOURCEDIR%" $SOURCEDIR
	!insertmacro ReplaceSubStr ${var} "%SPRING_INI%" $SPRING_INI
	!insertmacro ReplaceSubStr ${var} "%INSTALLDIR%" $INSTDIR
	!insertmacro ReplaceSubStr ${var} "%VERSION%" $VERSION
	!insertmacro ReplaceSubStr ${var} "%STARTMENU%" $SMPROGRAMS
!macroend


Function FatalError
	Pop $0
	DetailPrint $0
	MessageBox MB_YESNO "Error occured: $0, would you like to open the help forum?" IDNO noshow
	ExecShell "open" "http://springrts.com/phpbb/viewtopic.php?f=14&t=24724"
	noshow:
	Abort
FunctionEnd

; downloads a file, uses + _modifies_ global vars
; top on stack contains section name
Function fetchFile
	Push $0
	Exch
	Pop $0 ; Section name, for example File0
	DetailPrint "Section $SPRING_INI:$0"
	ReadINIStr $SECTION $SPRING_INI $0 "section"
	${If} $SECTION >= 0
	${AndIf} $Section <= 10
		IntOp $SECTION ${SEC_0} + $SECTION
                SectionGetFlags $SECTION $1 ; get current flags
                IntOp $1 $1 & ${SF_SELECTED}
                ${IfNot} $1 = ${SF_SELECTED} ; selected?
			goto noFetch
		${EndIf}
	${EndIf}

	ReadINIStr $MIRROR_COUNT $SPRING_INI $0 "mirror_count"
	ReadINIStr $MIRROR $SPRING_INI $0 "mirror1"
;TODO: retry with mirrors
;	ReadINIStr $MIRROR $SPRING_INI "Spring" "mirror2"
;	ReadINIStr $MIRROR $SPRING_INI "Spring" "mirror3"
	ReadINIStr $FILENAME $SPRING_INI $0 "filename"
	ReadINIStr $MD5 $SPRING_INI $0 "md5"
	ReadINIStr $DIRECTORY $SPRING_INI $0 "directory"
	ReadINIStr $EXEC $SPRING_INI $0 "exec"
	ReadINIStr $EXEC_PARAMS $SPRING_INI $0 "exec_params"
	ReadINIStr $7ZIP_EXTRACT_PATH $SPRING_INI $0 "un7zip"
	ReadINIStr $ZIP_EXTRACT_PATH $SPRING_INI $0 "unzip"

	ReadINIStr $SHORTCUT $SPRING_INI $0 "shortcut"
	ReadINIStr $SHORTCUT_TARGET $SPRING_INI $0 "shortcut_target"
	ReadINIStr $SHORTCUT_PARAMETER $SPRING_INI $0 "shortcut_parameter"
	ReadINIStr $SHORTCUT_ICON $SPRING_INI $0 "shortcut_icon"
	ReadINIStr $SHORTCUT_DIRECTORY $SPRING_INI $0 "shortcut_directory"
	ReadINIStr $INCLUDE $SPRING_INI $0 "isinclude"
	ReadINIStr $ALWAYSUPDATE $SPRING_INI $0 "alwaysupdate"

	!insertmacro escapeVar $FILENAME
	!insertmacro escapeVar $MIRROR

	${If} $MIRROR_COUNT == ""
		StrCpy $MIRROR_COUNT 1
	${EndIf}
	${If} $FILENAME != "" ; non-downloading actions are possible, too
		${IfNot} ${FileExists} "$SOURCEDIR\$FILENAME" ; skip download if file is already there
		${OrIf} $ALWAYSUPDATE == "yes" 
			DetailPrint "Downloading $MIRROR to $SOURCEDIR\$FILENAME"
			inetc::get $MIRROR "$SOURCEDIR\$FILENAME" /END
			Pop $R0
			${If} $R0 != "OK"
				Rename $SPRING_INI "$SPRING_INI.invalid"
				Push "Download failed $R0"
				Call FatalError
			${EndIf}
			${IfNot} ${FileExists} "$SOURCEDIR\$FILENAME"
				Push "$SOURCEDIR\$FILENAME didn't exist after download"
				Call FatalError
			${EndIf}
		${EndIf}
	${EndIf}

	${If} "$MD5" != "" ; only check md5 is set in .ini
		DetailPrint "$SOURCEDIR\$FILENAME :"
		md5dll::GetMD5File "$SOURCEDIR\$FILENAME"
		Pop $R0
		${If} $R0 == $MD5
			DetailPrint "md5 match:[$R0]"
		${Else}
			Push "$FILENAME: md5 mismatch:[$R0]"
			Call FatalError
			;TODO: prompt for redownload?
		${EndIf}
	${EndIf}
	; extract file if requested
	${If} $7ZIP_EXTRACT_PATH != ""
		${SetOutPath} "$INSTDIR\$7ZIP_EXTRACT_PATH"
		DetailPrint "Extracting $FILENAME to $INSTDIR$7ZIP_EXTRACT_PATH"
		Nsis7z::Extract "$SOURCEDIR\$FILENAME"
		${SetOutPath} $INSTDIR
	${EndIf}

	${If} $ZIP_EXTRACT_PATH != ""
		DetailPrint "Extracting $FILENAME to $ZIP_EXTRACT_PATH"
		${CreateDirectory} "$INSTDIR\$ZIP_EXTRACT_PATH"
		nsisunz::Unzip "$SOURCEDIR\$FILENAME" "$INSTDIR\$ZIP_EXTRACT_PATH"
		Pop $R0
		${If} $R0 != "success"
			Push "Unzipping error $FILENAME"
			Call FatalError
		${EndIf}
	${EndIf}

	${If} $DIRECTORY != ""
		${CreateDirectory} "$INSTDIR\$DIRECTORY"
		${CopyFiles} "$SOURCEDIR\$FILENAME" "$INSTDIR\$DIRECTORY\$FILENAME"
	${EndIf}

	; run program if requested
	${If} $EXEC != ""
		!insertmacro escapeVar $EXEC
		!insertmacro escapeVar $EXEC_PARAMS
		DetailPrint "$EXEC $EXEC_PARAMS"
		ClearErrors
		ExecWait '"$EXEC" $EXEC_PARAMS'
		${If} ${Errors}
			Push "Couldn't run $EXEC $EXEC_PARAMS'"
			Call FatalError
		${EndIf}
	${EndIf}

	${If} $SHORTCUT != ""
		!insertmacro escapeVar $SHORTCUT
		!insertmacro escapeVar $SHORTCUT_TARGET
		!insertmacro escapeVar $SHORTCUT_PARAMETER
		!insertmacro escapeVar $SHORTCUT_ICON
		!insertmacro escapeVar $SHORTCUT_DIRECTORY
		StrCpy "$SHORTCUT_DIRECTORY" "$SMPROGRAMS\$GAMENAME\$SHORTCUT_DIRECTORY" ; use same prefix for all shortcuts

		${CreateDirectory} $SHORTCUT_DIRECTORY
		${CreateShortCut} "$SHORTCUT_DIRECTORY\$SHORTCUT" $SHORTCUT_TARGET $SHORTCUT_PARAMETER $SHORTCUT_ICON 0
	${EndIf}
	${If} $INCLUDE == "yes"
		Push $SPRING_INI ; save var on stack
		Push $FILES
		StrCpy $SPRING_INI "$SOURCEDIR\$FILENAME"
		DetailPrint "Using include $SPRING_INI"
		ReadINIStr $3 $SPRING_INI ${SPRING_MAIN_SECTION} "files" ; count of files
		StrCpy $0 1
		${While} $0 <= $3
			Push "file$0"
			Call fetchFile
			IntOp $0 $0 + 1
		${EndWhile}
		Pop $FILES ; restore var from stack
		Pop $SPRING_INI
	${EndIf}

	nofetch:
	Pop $0

FunctionEnd

; called on installation end (when selected)
Function showReadme
	ExecShell "open" $README
FunctionEnd

; run on exit (when selected)
Function runExit
	${If} $EXEC_EXIT != ""
	${AndIfNot} ${Silent}
		ClearErrors
		ExecShell "open" $EXEC_EXIT $EXEC_EXIT_PARAMETER
		${If} ${Errors}
			MessageBox MB_OK "Could not run '$EXEC_EXIT' '$EXEC_EXIT_PARAMETER'"
		${EndIf}
	${EndIf}
FunctionEnd


Section "-Install" SEC_INSTALL
	${WriteRegStr} "${APP_REG_ROOT}" "${APP_REG_UNINSTALL}" "DisplayName" "${APP_NAME}"
	${WriteRegStr} "${APP_REG_ROOT}" "${APP_REG_UNINSTALL}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	${WriteRegStr} "${APP_REG_ROOT}" "${APP_REG_UNINSTALL}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	DetailPrint "Files: $FILES"
	StrCpy $0 1
	${While} $0 <= $FILES
		Push "file$0"
		Call fetchFile
		IntOp $0 $0 + 1
	${EndWhile}
	writeUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

;reads sizes from .ini and sets it to sections
Function SetSizes
	StrCpy $0 1
	${While} $0 <= $FILES
		;$0 counter
		;$1 size of file
		;$2 section #
		;$3 SEC_ID
		;$4 sectionsize
		;$5 sectionname
		StrCpy $5 "file$0"

		ReadINIStr $1 $SPRING_INI $5 "size"
		ReadINIStr $2 $SPRING_INI $5 "section"
		IntOp $3 ${SEC_0} + $2
		SectionGetSize $3 $4
		; size is in kbytes
		IntOp $1 $1 / 1024
		IntOp $4 $1 + $4
		SectionSetSize $3 $4
		IntOp $0 $0 + 1
	${EndWhile}

FunctionEnd

Function .onInit
	;initialize global vars
	StrCpy $INSTALLERNAME $EXEFILE -4 ; remove .exe suffix from installer name
	StrCpy $SOURCEDIR "$EXEDIR\$INSTALLERNAME - files"
	StrCpy $SPRING_INI "$SOURCEDIR\$INSTALLERNAME.ini"
	CreateDirectory $SOURCEDIR

	${If} ${FileExists} $SPRING_INI
		ReadINIStr $R0 $SPRING_INI ${SPRING_MAIN_SECTION} "alwaysupdate" ; count of files
	${Else}
		StrCpy $R0 "yes" ; download file
	${EndIf}

	${If} $R0 == "yes" ; ini doesn't exist, download it
		ReadINIStr $UPDATEURL $SPRING_INI ${SPRING_MAIN_SECTION} "updateurl" ; count of files
		${If} $UPDATEURL == ""
			Push "SPRING:"
			Call ReadCustomerData
			Pop $UPDATEURL
		${EndIf}

		${If} $UPDATEURL != ""
			inetc::get $UPDATEURL $SPRING_INI /END
			Pop $1
			${If} $1 != "ok"
				Push "Downloading $UPDATEURL failed."
				Call FatalError
			${EndIf}
		${Else}
			MessageBox MB_OK "Config file not updated: couldn't extract url of config file from please attach with $\necho SPRING:http://path/to/ini$\n>>$EXEPATH" /SD IDOK
		${EndIf}
	${EndIf}

	${IfNot} ${FileExists} $SPRING_INI
		Push "Couldn't open $SPRING_INI"
		Call FatalError
	${EndIf}

	ReadINIStr $R0 $SPRING_INI ${SPRING_MAIN_SECTION} "fileformat" ; count of files
	${If} $R0 != "0.2"
		Push "Invalid file format for $SPRING_INI: $R0, please update this installer!"
		Call FatalError
	${EndIf}

	StrCpy $0 0
	${While} $0 < 15
		; $0=counter
		; $1=option in .ini
		; $2=SEC_ID
		; $3=section flags
		StrCpy $1 "section$0"
		IntOp $2 ${SEC_0} + $0
		ReadINIStr $R0 $SPRING_INI ${SPRING_MAIN_SECTION} $1
		SectionSetText $2 $R0
		StrCpy $1 "section$0_force"
		ReadINIStr $R0 $SPRING_INI ${SPRING_MAIN_SECTION} $1
		${If} $R0 == "yes"
	                SectionGetFlags $2 $3 ; get current flags
	                IntOp $3 $3 | ${SF_RO}
			SectionSetFlags $2 $3
		${EndIf}
		IntOp $0 $0 + 1
	${EndWhile}

	ReadINIStr $DESC_SECTION_0 $SPRING_INI ${SPRING_MAIN_SECTION} "section0_description"
	ReadINIStr $DESC_SECTION_1 $SPRING_INI ${SPRING_MAIN_SECTION} "section1_description"
	ReadINIStr $DESC_SECTION_2 $SPRING_INI ${SPRING_MAIN_SECTION} "section2_description"
	ReadINIStr $DESC_SECTION_3 $SPRING_INI ${SPRING_MAIN_SECTION} "section3_description"
	ReadINIStr $DESC_SECTION_4 $SPRING_INI ${SPRING_MAIN_SECTION} "section4_description"
	ReadINIStr $DESC_SECTION_5 $SPRING_INI ${SPRING_MAIN_SECTION} "section5_description"
	ReadINIStr $DESC_SECTION_6 $SPRING_INI ${SPRING_MAIN_SECTION} "section6_description"
	ReadINIStr $DESC_SECTION_7 $SPRING_INI ${SPRING_MAIN_SECTION} "section7_description"
	ReadINIStr $DESC_SECTION_8 $SPRING_INI ${SPRING_MAIN_SECTION} "section8_description"
	ReadINIStr $DESC_SECTION_9 $SPRING_INI ${SPRING_MAIN_SECTION} "section9_description"
	ReadINIStr $DESC_SECTION_10 $SPRING_INI ${SPRING_MAIN_SECTION} "section10_description"
	ReadINIStr $DESC_SECTION_11 $SPRING_INI ${SPRING_MAIN_SECTION} "section11_description"
	ReadINIStr $DESC_SECTION_12 $SPRING_INI ${SPRING_MAIN_SECTION} "section12_description"
	ReadINIStr $DESC_SECTION_13 $SPRING_INI ${SPRING_MAIN_SECTION} "section13_description"
	ReadINIStr $DESC_SECTION_14 $SPRING_INI ${SPRING_MAIN_SECTION} "section14_description"
	ReadINIStr $DESC_SECTION_15 $SPRING_INI ${SPRING_MAIN_SECTION} "section15_description"


	ReadINIStr $FILES $SPRING_INI ${SPRING_MAIN_SECTION} "files" ; count of files
	ReadINIStr $README $SPRING_INI ${SPRING_MAIN_SECTION} "readme" ; url to readme
	ReadINIStr $GAMENAME $SPRING_INI ${SPRING_MAIN_SECTION} "gamename" ; name of game
	ReadINIStr $VERSION $SPRING_INI ${SPRING_MAIN_SECTION} "version" ; version of engine
	ReadINIStr $EXEC_EXIT "$SPRING_INI" ${SPRING_MAIN_SECTION} "runonexit" ; (optional) execute on clock on "Finish" button
	ReadINIStr $EXEC_EXIT_PARAMETER "$SPRING_INI" ${SPRING_MAIN_SECTION} "runonexit_parameter" ; parameter for exec_exit
	ReadINIStr $SIZE "$SPRING_INI" ${SPRING_MAIN_SECTION} "size" ; size of all installed files
	!insertmacro escapeVar $EXEC_EXIT
	!insertmacro escapeVar $EXEC_EXIT_PARAMETER
	
	call SetSizes
	

;	SectionSetSize SEC_INSTALL $SIZE
FunctionEnd

;--------------------------------
; Uninstaller
;--------------------------------
Section Uninstall
  ;Can't uninstall if uninstall log is missing!
  IfFileExists "$INSTDIR\${UninstLog}" +3
    MessageBox MB_OK|MB_ICONSTOP "$(UninstLogMissing)"
      Abort
 
  Push $R0
  Push $R1
  Push $R2
  SetFileAttributes "$INSTDIR\${UninstLog}" NORMAL
  FileOpen $UninstLog "$INSTDIR\${UninstLog}" r
  StrCpy $R1 -1
 
  GetLineCount:
    ClearErrors
    FileRead $UninstLog $R0
    IntOp $R1 $R1 + 1
    StrCpy $R0 $R0 -2
    Push $R0   
    IfErrors 0 GetLineCount
 
  Pop $R0
 
  LoopRead:
    StrCmp $R1 0 LoopDone
    Pop $R0
 
    IfFileExists "$R0\*.*" 0 +3
      RMDir $R0  #is dir
    Goto +9
    IfFileExists $R0 0 +3
      Delete $R0 #is file
    Goto +6
    StrCmp $R0 "${APP_REG_ROOT} ${APP_REG_UNINSTALL}" 0 +3
      DeleteRegKey ${APP_REG_ROOT} "${APP_REG_UNINSTALL}" #is Reg Element
    Goto +3
    StrCmp $R0 "${APP_REG_ROOT} ${APP_REG_UNINSTALL}" 0 +2
      DeleteRegKey ${APP_REG_ROOT} "${APP_REG_UNINSTALL}" #is Reg Element
 
    IntOp $R1 $R1 - 1
    Goto LoopRead
  LoopDone:
  FileClose $UninstLog
  Delete "$INSTDIR\${UninstLog}"
  Pop $R2
  Pop $R1
  Pop $R0
 
  ;Remove registry keys
    ;DeleteRegKey ${REG_ROOT} "${REG_APP_PATH}"
    ;DeleteRegKey ${REG_ROOT} "${UNINSTALL_PATH}"
SectionEnd



!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_0} $DESC_SECTION_0
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_1} $DESC_SECTION_1
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_2} $DESC_SECTION_2
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_3} $DESC_SECTION_3
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_4} $DESC_SECTION_4
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_5} $DESC_SECTION_5
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_6} $DESC_SECTION_6
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_7} $DESC_SECTION_7
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_8} $DESC_SECTION_8
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_9} $DESC_SECTION_9
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_10} $DESC_SECTION_10
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_11} $DESC_SECTION_11
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_12} $DESC_SECTION_12
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_13} $DESC_SECTION_13
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_14} $DESC_SECTION_14
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_15} $DESC_SECTION_15
!insertmacro MUI_FUNCTION_DESCRIPTION_END

