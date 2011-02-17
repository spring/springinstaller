; moves source recursive to destination
!macro logMove source destination
	Push "${source}"
	Push "${destination}"
	Call logMove
!macroend

Function logMove ; $source $destinat
	System::Store "s"
	Pop $1
	Pop $0

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
			${Rename} "$0\$3" "$1\$3"
		${EndIf}
	skip:
		FindNext $2 $3
		Goto loop
	done:
	FindClose $2
	System::Store "l"
FunctionEnd

!macro createTempDir returnvar basepath
	GetTempFileName ${returnvar} ${basepath}
	Delete ${returnvar}
	CreateDirectory ${returnvar}
!macroend

!macro unzip source destination
	Push "${destination}"
	Push "${source}"
	Call unzip
!macroend

Function unzip
	System::Store "s"
	Pop $0 ; source
	Pop $1 ; destination
	; $2 tempdir
	DetailPrint "Extracting $0 to $1"
	${CreateDirectory} "$1"
	!insertmacro createTempDir $2 "$1"
	MessageBox MB_OK "$1 $2"
	nsisunz::Unzip $0 $2
	!insertmacro logMove $2 $1
	RmDir $2
 	Pop $R0
	${If} $R0 != "success"
		Push "Unzipping error $0 $1"
		Call FatalError
	${EndIf}
	System::Store "l"
FunctionEnd


