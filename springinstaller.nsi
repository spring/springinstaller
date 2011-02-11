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

VAR /GLOBAL SPRING_INI ; name of ini file
VAR /GLOBAL README ; http url to readme
VAR /GLOBAL VERSION ; version of spring engine
VAR /GLOBAL FILES ; count of files to install
VAR /GLOBAL GAMENAME ; name of the game, is used as filename!
VAR /GLOBAL INSTALLERNAME ; name of installer.exe without .exe
VAR /GLOBAL PARAMETER ; parameters to add to spring.exe
VAR /GLOBAL SOURCEDIR

; temp vars
VAR /GLOBAL MIRROR_COUNT ; count of mirrors of current file
VAR /GLOBAL MD5 ; md5 of current file
VAR /GLOBAL DIRECTORY ; subdirectory where current file to install to
VAR /GLOBAL MIRROR ; current mirror
VAR /GLOBAL FILENAME ; filename of current file


; downloads a file, uses + _modifies_ global vars
; top on stack contains section name
Function fetchFile
	Push $0
	Exch
	Pop $0
	DetailPrint "Section $0"
	ReadINIStr $MIRROR_COUNT $SPRING_INI $0 "mirror_count"
	ReadINIStr $MIRROR $SPRING_INI $0 "mirror1"
;TODO: retry with mirrors
;	ReadINIStr $MIRROR $SPRING_INI "Spring" "mirror2"
;	ReadINIStr $MIRROR $SPRING_INI "Spring" "mirror3"
	ReadINIStr $FILENAME $SPRING_INI $0 "filename"
	ReadINIStr $MD5 $SPRING_INI $0 "md5"
	ReadINIStr $DIRECTORY $SPRING_INI $0 "directory"

	IfFileExists $FILENAME md5check
	DetailPrint "Downloading $MIRROR to $SOURCEDIR\$FILENAME"
	inetc::get $MIRROR "$SOURCEDIR\$FILENAME"
	Pop $0
	StrCmp $0 "OK" dlok
abort:
	Abort
;	MessageBox MB_OK|MB_ICONEXCLAMATION "http download Error, click OK to abort installation $0" /SD IDOK

md5check:
	IfFileExists $FILENAME +1 abort

	DetailPrint "$SOURCEDIR\$FILENAME :"
	md5dll::GetMD5File "$SOURCEDIR\$FILENAME"
	Pop $0
	${If} $0 == $MD5
		DetailPrint "md5 match:[$0]"
		${If} $DIRECTORY != ""
			CreateDirectory "$INSTDIR\$DIRECTORY"
			CopyFiles /FILESONLY "$SOURCEDIR\$FILENAME" "$INSTDIR\$DIRECTORY\$FILENAME"
		${Else}
			DetailPrint "$FILENAME has no 'directory' set in config, not copying"
		${EndIf}
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
	StrCpy $SOURCEDIR $EXEDIR
	StrCpy $SPRING_INI "$SOURCEDIR\$INSTALLERNAME.ini"
	IfFileExists $SPRING_INI configok
	MessageBox MB_OK "Couldn't read $SPRING_INI"
	Abort
configok:
	ReadINIStr $FILES $SPRING_INI "Spring" "files" ; count of files
	ReadINIStr $README $SPRING_INI "Spring" "readme" ; url to readme
	ReadINIStr $GAMENAME $SPRING_INI "Spring" "gamename" ; name of game
	ReadINIStr $VERSION $SPRING_INI "Spring" "version" ; version of engine
	ReadINIStr $PARAMETER "$SPRING_INI" "Spring" "parameter" ; version of engine
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
		Call fetchFile
		IntOp $0 $0 + 1
	${EndWhile}
	CreateDirectory "$SMPROGRAMS\$GAMENAME"
	createShortCut "$SMPROGRAMS\$GAMENAME\Readme - $GAMENAME.lnk" "$README"
	createShortCut "$SMPROGRAMS\$GAMENAME\$GAMENAME.lnk" "$INSTDIR\spring.exe" $PARAMETER
SectionEnd

