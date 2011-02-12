SetCompress force
SetCompressor /SOLID /FINAL lzma

!addplugindir "plugins"

!include "MUI2.nsh"
;http://nsis.sourceforge.net/Docs/Modern%20UI%202/Readme.html
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
!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\nsis.bmp" ; optional

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


VAR /GLOBAL SPRING_INI ; name of ini file
VAR /GLOBAL README ; http url to readme
VAR /GLOBAL VERSION ; version of spring engine
VAR /GLOBAL FILES ; count of files to install
VAR /GLOBAL GAMENAME ; name of the game, is used as filename!
VAR /GLOBAL INSTALLERNAME ; name of installer.exe without .exe
VAR /GLOBAL PARAMETER ; parameters to add to spring.exe
VAR /GLOBAL SOURCEDIR
VAR /GLOBAL EXEC_EXIT ; to be run on exit (optional)
VAR /GLOBAL SIZE ; size of installed files

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


; downloads a file, uses + _modifies_ global vars
; top on stack contains section name
Function fetchFile
	Push $0
	Exch
	Pop $0
	DetailPrint "Section $0"
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


	${If} $MIRROR_COUNT == ""
		StrCpy $MIRROR_COUNT 1
	${EndIf}

	${IfNot} ${FileExists} "$SOURCEDIR\$FILENAME"  ; skip download if file is already there
		DetailPrint "Downloading $MIRROR to $SOURCEDIR\$FILENAME"
		inetc::get $MIRROR "$SOURCEDIR\$FILENAME" /END
		Pop $0
		${If} $0 != "OK"
			DetailPrint "Download failed"
			Abort
		${EndIf}

		${IfNot} ${FileExists} "$SOURCEDIR\$FILENAME"
			DetailPrint "$SOURCEDIR\$FILENAME didn't exist after download"
			Abort
		${EndIf}
	${EndIf}

	${If} "$MD5" != "" ; only check md5 is set in .ini
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
			DetailPrint "expected:    [$MD5]"
			Abort
			;TODO: prompt for redownload?
		${EndIf}
	${EndIf}
	; extract file if requested
	${If} $7ZIP_EXTRACT_PATH != ""
		SetOutPath "$INSTDIR\$7ZIP_EXTRACT_PATH"
		DetailPrint "Extracting $FILENAME to $INSTDIR$7ZIP_EXTRACT_PATH"
		Nsis7z::Extract "$SOURCEDIR\$FILENAME"
		SetOutPath $INSTDIR
	${EndIf}

	${If} $ZIP_EXTRACT_PATH != ""
		DetailPrint "Extracting $FILENAME to $ZIP_EXTRACT_PATH"
		nsisunz::Unzip "$SOURCEDIR\$FILENAME" "$INSTDIR\$ZIP_EXTRACT_PATH"
		Pop $0
		${If} $0 != "success"
			DetailPrint "Unzipping error"
			Abort
		${EndIf}
	${EndIf}

	; run program if requested
	${If} $EXEC != ""
		!insertmacro ReplaceSubStr $EXEC "%SOURCEDIR%" $SOURCEDIR
		!insertmacro ReplaceSubStr $EXEC "%INSTALLDIR%" $INSTDIR
		${If} $EXEC_PARAMS != ""
			!insertmacro ReplaceSubStr $EXEC_PARAMS "%SOURCEDIR%" $SOURCEDIR
			!insertmacro ReplaceSubStr $EXEC_PARAMS "%INSTALLDIR%" $INSTDIR
		${EndIf}
		DetailPrint "$EXEC $EXEC_PARAMS"
		ExecWait '"$EXEC" $EXEC_PARAMS'
	${EndIf}

	${If} $SHORTCUT != ""
		!insertmacro ReplaceSubStr $SHORTCUT "%GAMENAME%" $GAMENAME
		!insertmacro ReplaceSubStr $SHORTCUT_TARGET "%INSTALLDIR%" $INSTDIR
		!insertmacro ReplaceSubStr $SHORTCUT_PARAMETER "%INSTALLDIR%" $INSTDIR
		!insertmacro ReplaceSubStr $SHORTCUT_ICON "%INSTALLDIR%" $INSTDIR
		!insertmacro ReplaceSubStr $SHORTCUT_DIRECTORY "%GAMENAME%" $GAMENAME
		${If} $SHORTCUT_DIRECTORY == ""
			StrCpy $SHORTCUT_DIRECTORY $GAMENAME
		${EndIf}
		CreateDirectory "$SMPROGRAMS\$SHORTCUT_DIRECTORY"
		CreateShortCut "$SMPROGRAMS\$SHORTCUT_DIRECTORY\$SHORTCUT" $SHORTCUT_TARGET $SHORTCUT_PARAMETER $SHORTCUT_ICON

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
		Exec $EXEC_EXIT
	${EndIf}
FunctionEnd

Section "-Install" SEC_INSTALL
	DetailPrint "Files: $FILES"
	StrCpy $0 1
	${While} $0 <= $FILES
		Push "file$0"
		Call fetchFile
		IntOp $0 $0 + 1
	${EndWhile}
SectionEnd

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
		Push "SPRING:"
		Call ReadCustomerData
		Pop $0
		${If} $0 != ""
			inetc::get $0 $SPRING_INI /END
			Pop $1
			${If} $1 != "ok"
				MessageBox MB_OK "Downloading $0 failed."
				Abort
			${EndIf}
		${Else}
			MessageBox MB_OK "Config file not updated: couldn't extract url of config file from please attach with $\necho SPRING:http://path/to/ini$\n>>$EXEPATH"
		${EndIf}
	${EndIf}

	${IfNot} ${FileExists} $SPRING_INI
		MessageBox MB_OK "Couldn't open $SPRING_INI"
		Abort
	${EndIf}

	ReadINIStr $R0 $SPRING_INI ${SPRING_MAIN_SECTION} "fileformat" ; count of files
	${If} $R0 != "0.1"
		MessageBox MB_OK "Invalid file format for $SPRING_INI: $R0, please update this installer!"
		Abort
	${EndIf}

	StrCpy $0 0
	${While} $0 < 10
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

	ReadINIStr $FILES $SPRING_INI ${SPRING_MAIN_SECTION} "files" ; count of files
	ReadINIStr $README $SPRING_INI ${SPRING_MAIN_SECTION} "readme" ; url to readme
	ReadINIStr $GAMENAME $SPRING_INI ${SPRING_MAIN_SECTION} "gamename" ; name of game
	ReadINIStr $VERSION $SPRING_INI ${SPRING_MAIN_SECTION} "version" ; version of engine
	ReadINIStr $PARAMETER "$SPRING_INI" ${SPRING_MAIN_SECTION} "parameter" ; version of engine
	ReadINIStr $EXEC_EXIT "$SPRING_INI" ${SPRING_MAIN_SECTION} "runonexit" ; version of engine
	ReadINIStr $SIZE "$SPRING_INI" ${SPRING_MAIN_SECTION} "size" ; size of all installed files
	!insertmacro ReplaceSubStr $EXEC_EXIT "%INSTALLDIR%" $INSTDIR

;	SectionSetSize SEC_INSTALL $SIZE
FunctionEnd

