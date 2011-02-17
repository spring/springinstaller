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
			CreateDirectory "$1\$3"
			Push "$0\$3"
			Push "$1\$3"
			Call logMove
			RmDir "$0\$3"
		${Else}
			DetailPrint "$0\$3"
			Rename "$0\$3" "$1\$3"
		${EndIf}
	skip:
		FindNext $2 $3
		Goto loop
	done:
	FindClose $2
	System::Store "l"
FunctionEnd

