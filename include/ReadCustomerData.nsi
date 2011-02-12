; ReadCustomerData ( data_prefix -> customer_data )
;   Reads string data appended to the end of the installer EXE.
;   The data must be preceded by a known string.
;   Only last 4Kb of EXE is searched for the prefix
;   (but this can be easily changed, see comment below).
; Inputs:
;   data_prefix (string) -- the string after which customer data begins
; Outputs:
;   customer_data (string) -- the data after the prefix (does NOT include the prefix),
;                             empty if prefix not found
; Author:
;   Andrey Tarantsov <andreyvit@gmail.com> -- please e-mail me useful modifications you make
;   Stephen White <swhite-nsiswiki@corefiling.com>
; Example:
;   Push "CUSTDATA:"
;   Call ReadCustomerData
;   Pop $1
;   StrCmp $1 "" 0 +3
;   MessageBox MB_OK "No data found"
;   Abort
;   MessageBox MB_OK "Customer data: '$1'"
Function ReadCustomerData
  ; arguments
  Exch $R1            ; customer data magic value
  ; locals
  Push $1             ; file name or (later) file handle
  Push $2             ; current trial offset
  Push $3             ; current trial string (which will match $R1 when customer data is found)
  Push $4             ; length of $R1
  Push $5             ; half length of $R1
  Push $6             ; first half of $R1
  Push $7             ; tmp
 
  FileOpen $1 $EXEPATH r
 
; change 4096 here to, e.g., 2048 to scan just the last 2Kb of EXE file
  IntOp $2 0 - 1024
 
  StrLen $4 $R1
 
  IntOp $5 $4 / 2
  StrCpy $6 $R1 $5
 
 
loop:
  FileSeek $1 $2 END
  FileRead $1 $3 $4
  StrCmpS $3 $R1 found
 
  ${StrLoc} $7 $3 $6 ">"
  StrCmpS $7 "" NotFound
    IntCmp $7 0 FoundAtStart
      ; We can jump forwards to the position at which we found the partial match
      IntOp $2 $2 + $7
      IntCmp $2 0 loop loop
FoundAtStart:
    ; We should make progress
    IntOp $2 $2 + 1
    IntCmp $2 0 loop loop
NotFound:
    ; We can safely jump forward half the length of the magic
    IntOp $2 $2 + $5
    IntCmp $2 0 loop loop
 
  StrCpy $R1 ""
  goto fin
 
found:
  IntOp $2 $2 + $4
  FileSeek $1 $2 END
  FileRead $1 $3
  StrCpy $R1 $3
 
fin:
  Pop $7
  Pop $6
  Pop $5
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Exch $R1
FunctionEnd
