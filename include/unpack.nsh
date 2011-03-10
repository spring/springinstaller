; moves source recursive to destination
!macro logMove source destination
	Push "${source}"
	Push "${destination}"
	Call logMove
!macroend

Function logMove ; $source $destination
	System::Store "s"
	Pop $1 ; destination
	Pop $0 ; source

	DetailPrint "$0\*.*"

	;$0 source
	;$1 destination
	;$2 handle
	;$3 filename
	FindFirst $2 $3 "$0\*.*"
	
	loop:
		StrCmp $3 "" done
		StrCmp $3 "." skip
		StrCmp $3 ".." skip
		${If} ${FileExists} "$0\$3\*.*" ; directory
			${CreateDirectory} "$1\$3"
			Push "$0\$3"
			Push "$1\$3"
			Call logMove
			RmDir "$0\$3" ; delete empty source dir
		${Else}
			DetailPrint "$0\$3"
			${If} ${FileExists} "$0\$3" ; destination already exists, delete it for replacing
				Delete "$1\$3"
			${EndIf}
			${Rename} "$0\$3" "$1\$3"
		${EndIf}
	skip:
		FindNext $2 $3
		Goto loop
	done:
	FindClose $2
	System::Store "l"
FunctionEnd

; checks if file source\version exists and appends to dest path
!macro addVersionToPath source dest handle buf
	${If} ${FileExists} "${source}\VERSION"
		FileOpen ${handle} "${source}\VERSION" r
		FileRead ${handle} ${buf}
		FileClose ${handle}
		StrCpy ${dest} "${dest}\${buf}"
		${CreateDirectory} ${dest}
	${EndIf}
!macroend


!macro unzip source destination tempdir
	Push "${tempdir}"
	Push "${destination}"
	Push "${source}"
	Call unzip
!macroend
Function unzip
	System::Store "s"
	Pop $0 ; source
	Pop $1 ; destination
	Pop $2 ; $2 tempdir
	${If} $0 == ""
	${OrIf} $1 == ""
		MessageBox MB_OK "$0 $1"
	${EndIf}
	DetailPrint "Extracting $0 to $1"
	nsisunz::Unzip $0 $2
 	Pop $R0
	${If} $R0 != "success"
		Push "Unzipping error $0 $1"
		Call FatalError
	${EndIf}
	!insertmacro addVersionToPath $2 $1 $R0 $R1
	!insertmacro logMove $2 $1
	System::Store "l"
FunctionEnd

!macro un7zip source destination tempdir
	Push "${tempdir}"
	Push "${destination}"
	Push "${source}"
	Call un7zip
!macroend
Function un7zip
	System::Store "s"
	Pop $0 ; source
	Pop $1 ; destination
	Pop $2 ; $2 tempdir

	${If} $0 == ""
	${OrIf} $1 == ""
		MessageBox MB_OK "$0 $1"
	${EndIf}
	${SetOutPath} $2
	DetailPrint "Extracting $0 to $1"
	Nsis7z::Extract "$0"
	${SetOutPath} $INSTDIR
	!insertmacro addVersionToPath $2 $1 $R0 $R1
	!insertmacro logMove $2 $1
	System::Store "l"
FunctionEnd

