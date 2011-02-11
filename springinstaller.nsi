SetCompress force
SetCompressor /SOLID /FINAL lzma

!addplugindir "plugins"

!include "MUI2.nsh"
;http://nsis.sourceforge.net/Docs/Modern%20UI%202/Readme.html
; Config for Modern Interface
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_TEXT "Thanks for installing this game"
!define MUI_WELCOMEFINISHPAGE_BITMAP "graphics\SideBanner.bmp"

!define MUI_CUSTOMFUNCTION_GUIINIT guiInit
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME
!define MUI_FINISHPAGE_RUN_TEXT "Start game"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Readme file for game"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION showReadme

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_FUNCTION runExit

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!include "LogicLib.nsh"

Outfile "springinstaller.exe"
InstallDir "$PROGRAMFILES\Spring"
Name $GAMENAME

VAR /GLOBAL README
VAR /GLOBAL MIRROR_COUNT
VAR /GLOBAL MIRROR
VAR /GLOBAL FILENAME
VAR /GLOBAL VERSION
VAR /GLOBAL MD5
VAR /GLOBAL FILES
VAR /GLOBAL GAMENAME
VAR /GLOBAL INSTALLERNAME
VAR /GLOBAL PARAMETER

!define SPRING_INI "springinstaller.ini"

; downloads a file, uses + _modifies_ global vars
; top on stack contains section name
Function fetchFile
	Push $0
	Exch
	Pop $0

	ReadINIStr $MIRROR_COUNT "$EXEDIR\springinstaller.ini" $0 "mirror_count"
	ReadINIStr $MIRROR "$EXEDIR\springinstaller.ini" $0 "mirror1"
;TODO: retry with mirrors
;	ReadINIStr $MIRROR "springinstaller.ini" "Spring" "mirror2"
;	ReadINIStr $MIRROR "springinstaller.ini" "Spring" "mirror3"
	ReadINIStr $FILENAME "$EXEDIR\springinstaller.ini" $0 "filename"
	ReadINIStr $MD5 "$EXEDIR\springinstaller.ini" $0 "md5"

	IfFileExists $FILENAME md5check
	DetailPrint "Downloading $MIRROR"
	inetc::get $MIRROR "$EXEDIR\$FILENAME"
	Pop $0
	StrCmp $0 "OK" dlok
abort:
	Abort
;	MessageBox MB_OK|MB_ICONEXCLAMATION "http download Error, click OK to abort installation $0" /SD IDOK

md5check:
	IfFileExists $FILENAME +1 abort

	DetailPrint "$EXEDIR\$FILENAME :"
	md5dll::GetMD5File "$EXEDIR\$FILENAME"
	Pop $0
	${If} $0 == $MD5
		DetailPrint "md5 match:[$0]"
		;TODO: install file here
	${Else}
		DetailPrint "md5 mismatch:[$0]"
		;TODO: prompt for redownload?
	${EndIf}
dlok:
	Pop $0

FunctionEnd

; called on installation end (when selected)
Function showReadme
	ExecShell "open" $README
FunctionEnd

; run on exit (when selected)
Function runExit
	Exec '"$INSTDIR\spring.exe" $PARAMETER'
	MessageBox MB_OK '"$INSTDIR\spring.exe" $PARAMETER'
FunctionEnd

Function .onInit
	;initialize global vars
	StrCpy $INSTALLERNAME $EXEFILE -4 ; remove .exe suffix from installer name

	IfFileExists "$EXEDIR\$INSTALLERNAME.ini" configok
	MessageBox MB_OK "Couldn't read $EXEDIR\$INSTALLERNAME.ini"
	Abort
configok:
	ReadINIStr $FILES "$EXEDIR\$INSTALLERNAME.ini" "Spring" "files" ; count of files
	ReadINIStr $README "$EXEDIR\$INSTALLERNAME.ini" "Spring" "readme" ; url to readme
	ReadINIStr $GAMENAME "$EXEDIR\$INSTALLERNAME.ini" "Spring" "gamename" ; name of game
	ReadINIStr $VERSION "$EXEDIR\$INSTALLERNAME.ini" "Spring" "version" ; version of engine
	ReadINIStr $PARAMETER "$EXEDIR\$INSTALLERNAME.ini" "Spring" "parameter" ; version of engine
FunctionEnd

Section "Install"

	Push "Spring"
	Call fetchFile
;	ExecWait '"$EXEDIR\$FILENAME" /S /D=$INSTDIR'
	DetailPrint 'ExecWait "$EXEDIR\$FILENAME" /S /D=$INSTDIR'

	DetailPrint "Files: $FILES"
	StrCpy $0 1
	${While} $0 <= $FILES
		Push "file$0"
		DetailPrint $0
		Call fetchFile
		IntOp $0 $0 + 1
	${EndWhile}
	CreateDirectory "$SMPROGRAMS\$GAMENAME"
	createShortCut "$SMPROGRAMS\$GAMENAME\Readme - $GAMENAME.lnk" "$README"
	createShortCut "$SMPROGRAMS\$GAMENAME\$GAMENAME.lnk" "$INSTDIR\spring.exe" $PARAMETER
SectionEnd

