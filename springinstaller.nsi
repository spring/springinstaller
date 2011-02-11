!include "MUI.nsh"
!include "LogicLib.nsh"

!addplugindir "plugins"
; Config for Modern Interface
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_TEXT "Thanks for installing this game"

Outfile "springinstaller.exe"
InstallDir "$PROGRAMFILES\Spring"

VAR /GLOBAL MIRROR_COUNT
VAR /GLOBAL MIRROR
VAR /GLOBAL FILENAME
VAR /GLOBAL MD5
VAR /GLOBAL FILES

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


Section "Install"

	Push "Spring"
	Call fetchFile
;	ExecWait '"$EXEDIR\$FILENAME" /S /D=$INSTDIR'
	DetailPrint 'ExecWait "$EXEDIR\$FILENAME" /S /D=$INSTDIR'

; get count of files
	ReadINIStr $FILES "$EXEDIR\springinstaller.ini" "Spring" "files"
	DetailPrint "Files: $FILES"
	StrCpy $0 1
	${While} $0 <= $FILES
		Push "file$0"
		DetailPrint $0
		Call fetchFile
		IntOp $0 $0 + 1
	${EndWhile}

SectionEnd

