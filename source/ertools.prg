#INCLUDE "FiveWin.ch"
#INCLUDE "VRD.ch"
#INCLUDE "Mail.ch"

MEMVAR aItems, aAreaIni, aWnd
MEMVAR cDefaultPath
MEMVAR nAktArea
MEMVAR aVRDSave
MEMVAR lBeta
MEMVAR lProfi, nUndoCount, nRedoCount, lPersonal, oGenVar
MEMVAR oER

function GetFreeSystemResources()
return 0


//-----------------------------------------------------------------------------//

function CheckPath( cPath )

   cPath := ALLTRIM( cPath )

   if .NOT. EMPTY( cPath ) .AND. SUBSTR( cPath, LEN( cPath ) ) <> "\"
      cPath += "\"
   endif

return ( cPath )

//-----------------------------------------------------------------------------//

function InsertArea( lBefore, cTitle )

   local i, oGet, oDlg, cTmpFile
   local aAreaInis   := {}
   local lreturn     := .F.
   local cFile       := SPACE( 200 )
   local aIniEntries := GetIniSection( "Areas", oER:cDefIni )
   local nNewArea    := nAktArea + IIF( lBefore, 0, 1 )
   local cDir        := CheckPath( oER:GetDefIni( "General", "AreaFilesDir", "" ) )
   LOCAL nDecimals   := IIF( oER:nMeasure = 2, 2, 0 )

   if EMPTY( cDir )
      cDir := cDefaultPath
   endif

   for i := 1 TO Len( aWnd )
      AADD( aAreaInis, ALLTRIM( GetIniEntry( aIniEntries, ALLTRIM(STR( i, 5 )) , "" ) ) )
   NEXT

   DEFINE DIALOG oDlg NAME "NEWFILENAME" TITLE cTitle

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION ;
      IIF( FILE( cDir + cFile ), MsgStop( GL("The file already exists."), GL("Stop!") ), ;
                                 ( lreturn := .T., oDlg:End() ) )

   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE SAY PROMPT GL("Name of the new area file") + ":" ID 171 OF oDlg

   REDEFINE GET oGet VAR cFile ID 201 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED

   if lreturn

      nNewArea := IIF( nNewArea < 1, 1, nNewArea )
      AINS( aAreaInis, nNewArea )
      aAreaInis[nNewArea] := cFile

      DelIniSection( "Areas", oER:cDefIni )

      for i := 1 TO LEN( aAreaInis )
         if .NOT. EMPTY( aAreaInis[i] )
            WritePProString( "Areas", ALLTRIM(STR( i, 3 )), ALLTRIM( aAreaInis[i] ), oER:cDefIni )
         endif
      NEXT

      MEMOWRIT( cDir + cFile, ;
         "[General]" + CRLF + ;
         "Title=New Area" + CRLF + ;
         "Width="  + ALLTRIM(STR( oGenVar:aAreaSizes[nAktArea,1], 5, nDecimals )) + CRLF + ;
         "Height=" + ALLTRIM(STR( oGenVar:aAreaSizes[nAktArea,2], 5, nDecimals )) )

      OpenFile( oER:cDefIni )

      aWnd[nNewArea]:SetFocus()

      AreaProperties( nAktArea )

   endif

return .T.

//-----------------------------------------------------------------------------//

function DeleteArea()

   if MsgNoYes( GL("Do you really want to delete this area?"), GL("Select an option") ) = .T.

      DelFile( aVRDSave[nAktArea,1] )
      DelIniEntry( "Areas", ALLTRIM(STR( nAktArea, 5 )), oER:cDefIni )

      OpenFile( oER:cDefIni )

   endif

return .T.

//-----------------------------------------------------------------------------//

function IniColor( cColor, nDefColor )

   local nColor

   DEFAULT nDefColor := 0

   if EMPTY( cColor )
      nColor := nDefColor
   ELSEif AT( ",", cColor ) <> 0
      nColor := RGB( VAL(StrToken( cColor, 1, "," )), ;
                     VAL(StrToken( cColor, 2, "," )), ;
                     VAL(StrToken( cColor, 3, "," )) )
   ELSE
      nColor := VAL( cColor )
   endif

return ( nColor )

//-----------------------------------------------------------------------------//

function GetDBField( oGet, lInsert )

   local oDlg, oLbx1, oLbx2, i, cDbase, cField, oBtn, aTemp, cGeneral, cUser
   local nShowExpr  := VAL( oER:GetDefIni( "General", "Expressions", "0" ) )
   local nShowDBase := VAL( oER:GetDefIni( "General", "EditDatabases", "1" ) )
   local cGenExpr   := ALLTRIM( oEr:cDataPath + oER:GetDefIni( "General", "GeneralExpressions", "" ) )  // change CDefaultPath
   local cUserExpr  := ALLTRIM( oEr:cDataPath + oER:GetDefIni( "General", "UserExpressions", "" ) )      // change CDefaultPath
  // local cGenExpr   := ALLTRIM( cDefaultPath + GetPvProfString( "General", "GeneralExpressions", "", oER:cDefIni ) )
  // local cUserExpr  := ALLTRIM( cDefaultPath + GetPvProfString( "General", "UserExpressions", "", oER:cDefIni ) )
   local nLen       := LEN( oGenVar:aDBFile )
   local aDbase     := {}
   local lOK        := .T.
   local lreturn    := .F.
   local aFields    := {}

   DEFAULT lInsert := .F.

   if nShowDbase > 0

      for i := 1 TO nLen
         if .NOT. EMPTY( oGenVar:aDBFile[i,2] )
            AADD( aDbase , ALLTRIM( oGenVar:aDBFile[i,2] ) )
            AADD( aFields, oGenVar:aDBFile[i,3] )
         endif
      NEXT

   endif

   if nShowExpr > 0 .AND. lInsert = .F.
      AADD( aDbase, GL("Expressions") + ": " + GL("General") )
      AADD( aFields, GetExprFields( cGenExpr ) )
      cGeneral := aDbase[ LEN( aDbase ) ]
   endif

   if nShowExpr <> 2 .AND. lInsert = .F.
      AADD( aDbase, GL("Expressions") + ": " + GL("User defined") )
      AADD( aFields, GetExprFields( cUserExpr ) )
      cUser := aDbase[ LEN( aDbase ) ]
   endif

   if LEN( aDbase ) = 0
      MsgStop( GL("No databases defined."), GL("Stop!") )
      return .T.
   endif

  IF Len(AFields[1]) == 0
      MsgStop( GL("No databases defined."), GL("Stop!") )
      IF MsgYesNo( "Quiere definir una Base de Datos ?"   )
         Databases()
      ENDIF
      return .T.
   endif

   cDbase := aDbase[ 1 ]
   cField := aFields[ 1, 1 ]
   //cField := oGenVar:aDBFile[1,3][1]

   DEFINE DIALOG oDlg NAME "DATABASEFIELDS" TITLE GL("Databases and Expressions")

   REDEFINE BUTTON oBtn PROMPT GL("&OK") ID 101 OF oDlg WHEN lOK ;
      ACTION ( lreturn := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE LISTBOX oLbx1 VAR cDbase ITEMS aDbase ID 201 OF oDlg ;
      ON CHANGE ( oLbx2:SetItems( aFields[oLbx1:GetPos()] ), oLbx2:Refresh(), ;
                  IIF( LEN( aFields[oLbx1:GetPos()] ) = 0, ;
                  ( oLbx2:Disable(), oBtn:Disable() ), ( oLbx2:Enable(), oBtn:Enable() ) ) ) ;
      ON DBLCLICK ( lreturn := .T. , oDlg:End() )

   REDEFINE LISTBOX oLbx2 VAR cField ITEMS aFields[oLbx1:GetPos()] ID 202 OF oDlg ;
      ON DBLCLICK ( lreturn := .T. , oDlg:End() )

   REDEFINE SAY PROMPT GL("Sources") ID 171 OF oDlg
   REDEFINE SAY PROMPT GL("Fields")  ID 172 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED

   if lreturn = .T. .AND. .NOT. EMPTY( cField ) .AND. lInsert = .T.
      oGet:Paste( "[" + ALLTRIM( cDbase ) + ":" + ALLTRIM( cField ) + "]" )
   ELSEif lreturn = .T. .AND. .NOT. EMPTY( cField )
      if ALLTRIM( cDbase ) == cGeneral
         oGet:VarPut( "[1]" + ALLTRIM( cField ) )
      ELSEif ALLTRIM( cDbase ) == cUser
         oGet:VarPut( "[2]" + ALLTRIM( cField ) )
      ELSE
         oGet:VarPut( "[" + ALLTRIM( cDbase ) + ":" + ALLTRIM( cField ) + "]" )
      endif
      oGet:Refresh()
   endif

return .T.

//-----------------------------------------------------------------------------//

function GetExprFields( cDatabase )

   local nSelect := SELECT()
   local aTemp   := {}

   DBUSEAREA( .T.,, cDatabase, "TEMPEXPR" )

   DO WHILE .NOT. EOF()
      if .NOT. EMPTY( TEMPEXPR->NAME )
         AADD( aTemp, ALLTRIM( TEMPEXPR->NAME ) )
      endif
      TEMPEXPR->(DBSKIP())
   ENDDO

   TEMPEXPR->(DBCLOSEAREA())
   SELECT( nSelect )

return ( aTemp )

//-----------------------------------------------------------------------------//

function CreateDbfsExpressions()

  local cGenExpr   := ALLTRIM( oEr:cDataPath + oER:GetDefIni( "General", "GeneralExpressions", "" ) )
  local cUserExpr  := ALLTRIM( oEr:cDataPath + oER:GetDefIni( "General", "UserExpressions", "" ) )

 local aGeneral := {;
                    { "NAME"      , "C",    60,    0 },;
                    { "EXPRESSION", "C",   200,    0 },;
                    { "INFO"      , "C",   200,    0 } }


 local aUser := {;
                 { "NAME"      , "C",   100,    0 },;
                 { "EXPRESSION", "C",   200,    0 },;
                 { "INFO"      , "C",   200,    0 } }

  if ! lIsDir( oEr:cDataPath )
     lMkDir( oEr:cDataPath )
  endif
  if !File( cGenExpr  )
     DBCreate( cGenExpr, aGeneral )
  endif
  if  !File( cUserExpr  )
     DBCreate( cUserExpr, aUser )

  endif

return nil

//-----------------------------------------------------------------------------//

function OpenDatabases()

   local i, x, cEntry, cDbase, aFields, cFilter, cFieldNames, cFieldPos
   local nSelect     := SELECT()
   local cSeparator  := oER:GetDefIni( "Databases", "Separator" , ";" )

   CreateDbfsExpressions()

   oGenVar:aDBFile := {}

   for i := 1 TO 12

      cEntry      := oER:GetDefIni( "Databases", ALLTRIM(STR( i, 3 )), "" )
      cDbase      := ALLTRIM( GetField( cEntry, 1 ) )
      cFilter     := ""
      cFieldNames := ""
      cFieldPos   := ""

      aFields := {}

      if FILE( cDbase ) = .T.

         if Upper( cFileExt( cDBase ) ) = "DBF"

            DBUSEAREA( .T.,, cDbase, "DBTEMP", .T. )
            DBGOTOP()
            for x := 1 to DBTEMP->(FCOUNT())
              AADD( aFields, LOWER( FieldName( x ) ) )
            NEXT
            DBTEMP->(DBCLOSEAREA())
            SELECT( nSelect )

         ELSE

            cFilter     := ALLTRIM( GetField( cEntry, 3 ) )
            cFieldNames := ALLTRIM( GetField( cEntry, 4 ) )
            cFieldPos   := ALLTRIM( GetField( cEntry, 5 ) )

            if EMPTY( cFieldNames )
               aFields := VRD_aToken( MEMOLINE( MEMOREAD( cDBase ), 10000, 1,,, .T. ), cSeparator )
            ELSE
               aFields := VRD_aToken( cFieldNames, ";" )
            endif

            AEVAL( aFields, {|x,y| aFields[y] := ALLTRIM( x ) } )

         endif

      endif

      AADD( oGenVar:aDBFile, ;
         { PADR( cDbase, 200 ), ;
         LOWER( PADR( ALLTRIM( GetField( cEntry, 2 ) ), 30 ) ), ;
         aFields, ;
         cFilter, ;
         cFieldNames, ;
         cFieldPos } )

   NEXT

return .T.

//-----------------------------------------------------------------------------//

function SaveDatabases()

   AEVAL( oGenVar:aDBFile, {|x,y| ;
      WritePProString( "Databases", ALLTRIM(STR( y, 3 )), ;
                       ALLTRIM( x[1] ) + "|" + ;
                       ALLTRIM( x[2] ) + "|" + ;
                       ALLTRIM( x[4] ) + "|" + ;
                       ALLTRIM( x[5] ) + "|" + ;
                       ALLTRIM( x[6] ), oER:cDefIni ) } )

return .T.

//-----------------------------------------------------------------------------//

function Databases( lTake )

   local oDlg, aDBGet1[12], aDBGet2[12]

   DEFINE DIALOG oDlg NAME "DATABASES" TITLE GL("Databases")

   REDEFINE SAY PROMPT GL("Nr.")      ID 170 OF oDlg
   REDEFINE SAY PROMPT GL("Database") ID 171 OF oDlg
   REDEFINE SAY PROMPT GL("Alias")    ID 172 OF oDlg

   REDEFINE GET aDBGet1[ 1] VAR oGenVar:aDBFile[ 1,1] ID 201 OF oDlg
   REDEFINE GET aDBGet1[ 2] VAR oGenVar:aDBFile[ 2,1] ID 202 OF oDlg
   REDEFINE GET aDBGet1[ 3] VAR oGenVar:aDBFile[ 3,1] ID 203 OF oDlg
   REDEFINE GET aDBGet1[ 4] VAR oGenVar:aDBFile[ 4,1] ID 204 OF oDlg
   REDEFINE GET aDBGet1[ 5] VAR oGenVar:aDBFile[ 5,1] ID 205 OF oDlg
   REDEFINE GET aDBGet1[ 6] VAR oGenVar:aDBFile[ 6,1] ID 206 OF oDlg
   REDEFINE GET aDBGet1[ 7] VAR oGenVar:aDBFile[ 7,1] ID 207 OF oDlg
   REDEFINE GET aDBGet1[ 8] VAR oGenVar:aDBFile[ 8,1] ID 208 OF oDlg
   REDEFINE GET aDBGet1[ 9] VAR oGenVar:aDBFile[ 9,1] ID 209 OF oDlg
   REDEFINE GET aDBGet1[10] VAR oGenVar:aDBFile[10,1] ID 210 OF oDlg
   REDEFINE GET aDBGet1[11] VAR oGenVar:aDBFile[11,1] ID 211 OF oDlg
   REDEFINE GET aDBGet1[12] VAR oGenVar:aDBFile[12,1] ID 212 OF oDlg

   REDEFINE GET aDBGet2[ 1] VAR oGenVar:aDBFile[ 1,2] ID 221 OF oDlg
   REDEFINE GET aDBGet2[ 2] VAR oGenVar:aDBFile[ 2,2] ID 222 OF oDlg
   REDEFINE GET aDBGet2[ 3] VAR oGenVar:aDBFile[ 3,2] ID 223 OF oDlg
   REDEFINE GET aDBGet2[ 4] VAR oGenVar:aDBFile[ 4,2] ID 224 OF oDlg
   REDEFINE GET aDBGet2[ 5] VAR oGenVar:aDBFile[ 5,2] ID 225 OF oDlg
   REDEFINE GET aDBGet2[ 6] VAR oGenVar:aDBFile[ 6,2] ID 226 OF oDlg
   REDEFINE GET aDBGet2[ 7] VAR oGenVar:aDBFile[ 7,2] ID 227 OF oDlg
   REDEFINE GET aDBGet2[ 8] VAR oGenVar:aDBFile[ 8,2] ID 228 OF oDlg
   REDEFINE GET aDBGet2[ 9] VAR oGenVar:aDBFile[ 9,2] ID 229 OF oDlg
   REDEFINE GET aDBGet2[10] VAR oGenVar:aDBFile[10,2] ID 230 OF oDlg
   REDEFINE GET aDBGet2[11] VAR oGenVar:aDBFile[11,2] ID 231 OF oDlg
   REDEFINE GET aDBGet2[12] VAR oGenVar:aDBFile[12,2] ID 232 OF oDlg

   REDEFINE BTNBMP ID 301 OF oDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 1,1], aDBGet1[ 1], aDBGet2[ 1] )
   REDEFINE BTNBMP ID 302 OF oDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 2,1], aDBGet1[ 2], aDBGet2[ 2] )
   REDEFINE BTNBMP ID 303 OF oDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 3,1], aDBGet1[ 3], aDBGet2[ 3] )
   REDEFINE BTNBMP ID 304 OF oDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 4,1], aDBGet1[ 4], aDBGet2[ 4] )
   REDEFINE BTNBMP ID 305 OF oDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 5,1], aDBGet1[ 5], aDBGet2[ 5] )
   REDEFINE BTNBMP ID 306 OF oDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 6,1], aDBGet1[ 6], aDBGet2[ 6] )
   REDEFINE BTNBMP ID 307 OF oDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 7,1], aDBGet1[ 7], aDBGet2[ 7] )
   REDEFINE BTNBMP ID 308 OF oDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 8,1], aDBGet1[ 8], aDBGet2[ 8] )
   REDEFINE BTNBMP ID 309 OF oDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 9,1], aDBGet1[ 9], aDBGet2[ 9] )
   REDEFINE BTNBMP ID 310 OF oDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[10,1], aDBGet1[10], aDBGet2[10] )
   REDEFINE BTNBMP ID 311 OF oDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[11,1], aDBGet1[11], aDBGet2[11] )
   REDEFINE BTNBMP ID 312 OF oDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[12,1], aDBGet1[12], aDBGet2[12] )

   REDEFINE BTNBMP ID 321 OF oDlg RESOURCE "B_DEL" TRANSPARENT NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 1], aDBGet2[ 1] )
   REDEFINE BTNBMP ID 322 OF oDlg RESOURCE "B_DEL" TRANSPARENT NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 2], aDBGet2[ 2] )
   REDEFINE BTNBMP ID 323 OF oDlg RESOURCE "B_DEL" TRANSPARENT NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 3], aDBGet2[ 3] )
   REDEFINE BTNBMP ID 324 OF oDlg RESOURCE "B_DEL" TRANSPARENT NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 4], aDBGet2[ 4] )
   REDEFINE BTNBMP ID 325 OF oDlg RESOURCE "B_DEL" TRANSPARENT NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 5], aDBGet2[ 5] )
   REDEFINE BTNBMP ID 326 OF oDlg RESOURCE "B_DEL" TRANSPARENT NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 6], aDBGet2[ 6] )
   REDEFINE BTNBMP ID 327 OF oDlg RESOURCE "B_DEL" TRANSPARENT NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 7], aDBGet2[ 7] )
   REDEFINE BTNBMP ID 328 OF oDlg RESOURCE "B_DEL" TRANSPARENT NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 8], aDBGet2[ 8] )
   REDEFINE BTNBMP ID 329 OF oDlg RESOURCE "B_DEL" TRANSPARENT NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 9], aDBGet2[ 9] )
   REDEFINE BTNBMP ID 330 OF oDlg RESOURCE "B_DEL" TRANSPARENT NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[10], aDBGet2[10] )
   REDEFINE BTNBMP ID 331 OF oDlg RESOURCE "B_DEL" TRANSPARENT NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[11], aDBGet2[11] )
   REDEFINE BTNBMP ID 332 OF oDlg RESOURCE "B_DEL" TRANSPARENT NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[12], aDBGet2[12] )

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION oDlg:End()

   ACTIVATE DIALOG oDlg CENTER

   SaveDatabases()
   OpenDatabases()

return ( NIL )

//-----------------------------------------------------------------------------//

function GetDBase( cOldFile, oGet1, oGet2 )

   local cFile := GetFile( GL("Databases") + " (DBF,TXT,XML)" + "|*.DBF;*.TXT;*.XML|" + ;
                           "dBase (*.dbf)| *.dbf|" + ;
                           GL("Textfile") + "(*.txt)| *.txt|" + ;
                           "XML (*.xml)| *.xml|" + ;
                           GL("All Files") + "(*.*)| *.*", ;
                           GL("Open Database"), 1 )

   local cNewFile := ALLTRIM( IIF( EMPTY( cFile ), cOldFile, cFile ) )

   oGet1:VarPut( PADR( cNewFile, 200 ) )
   oGet1:Refresh()

   oGet2:VarPut( LOWER( PADR( cFileNoExt( cNewFile ), 30 ) ) )
   oGet2:Refresh()

return NIL

//-----------------------------------------------------------------------------//

function DelDBase( oGet1, oGet2 )

   oGet1:VarPut( SPACE( 200 ) )
   oGet2:VarPut( SPACE( 30 ) )
   oGet1:Refresh()
   oGet2:Refresh()

return NIL

//-----------------------------------------------------------------------------//
/*
function VRD_MsgRun( cCaption, cTitle, bAction )

   local oDlg, nWidth, oFont

   DEFINE FONT oFont NAME "Ms Sans Serif" SIZE 0, -8

   DEFAULT cCaption := "Please, wait...", cTitle := "", bAction  := { || Inkey( 1 ) }

   if EMPTY( cTitle )
      DEFINE DIALOG oDlg ;
         FROM 0,0 TO 3, Len( cCaption ) + 4 ;
         STYLE nOr( DS_MODALFRAME, WS_POPUP ) FONT oFont
   ELSE
      DEFINE DIALOG oDlg ;
         FROM 0,0 TO 4, Max( Len( cCaption ), Len( cTitle ) ) + 4 ;
         TITLE cTitle ;
         STYLE DS_MODALFRAME FONT oFont
   endif

   oDlg:bStart := { || Eval( bAction, oDlg ), oDlg:End(), SysRefresh() }
   oDlg:cMsg   := cCaption

   nWidth := oDlg:nRight - oDlg:nLeft

   ACTIVATE DIALOG oDlg CENTER ;
      ON PAINT oDlg:Say( 1, 0, xPadC( oDlg:cMsg, nWidth ) )

return NIL
*/

//------------------------------------------------------------------------------

function CreateNewFile( cFile )

   local cTmpFile := cTempFile() + ".TMP"
   local hFile    := lCreat( cTmpFile, 0 )

   lClose( hFile )
   CopyFile( cTmpFile, cFile )
   DelFile( cTmpFile )

return .T.

//------------------------------------------------------------------------------
/*  ya existe en fwh
function CopyFile( cSource, cTarget )

   COPY FILE ( cSource ) TO ( cTarget )

return .T.
*/
//------------------------------------------------------------------------------

function GetDivisible( nNr, nDivisor, lPrevious )

   local i

   DEFAULT lPrevious := .F.

   for i := 1 TO nDivisor
      if IsDivisible( nNr, nDivisor )
         EXIT
      ELSE
         IIF( lPrevious, --nNr, ++nNr )
      endif
   NEXT

return ( nNr )

//------------------------------------------------------------------------------

function IsDivisible( nNr, nDivisor )

   local lreturn := .F.

   if nNr / nDivisor == INT( nNr / nDivisor )
      lreturn := .T.
   endif

return ( lreturn )

//------------------------------------------------------------------------------

function ADelete( aArray, nIndex )

   local i
   local aNewArray := {}

   ADEL( aArray, nIndex )

   for i := 1 TO LEN( aArray ) - 1
      AADD( aNewArray, aArray[i] )
   NEXT

return ( aNewArray )


*-- function -----------------------------------------------------------------
* Name........: StrAtNum( <cSearch>, <cString>, <nCount> )
* Beschreibung: n-tes Auftreten einer Zeichenfolge in Strings ermitteln
*               StrAtNum() sucht das <nCount>-te Auftreten von <cSearch>
*               in <cString>. War die Suche erfolgreich, wird die Position
*               innerhalb <cString> zur�ckgegeben, andernfalls 0.
* R�ckgabewert: die Position des <nCount>-ten Auftretens von <cSearch>.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function StrAtNum( cSearch, cString, nNr )

   cString := STRTRAN( cString, cSearch, REPLICATE( "@", LEN( cSearch ) ),, nNr - 1 )

return AT( cSearch, cString )


*-- function -----------------------------------------------------------------
* Name........: GoBottom
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function GoBottom()

  GO BOTTOM

return !Eof()


*-- function -----------------------------------------------------------------
* Name........: GetFile
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function GetFile( cFileMask, cTitle, nDefaultMask, cInitDir, lSave, nFlags )

   local cTmpPath := CheckPath( oER:GetGeneralIni( "General", "DefaultPath", "" ) )

   if !EMPTY( cTmpPath )
      cInitDir := cTmpPath
   endif

   DEFAULT cInitDir := cFilePath( GetModuleFileName( GetInstance() ) )

return cGetFile32( cFileMask, cTitle, nDefaultMask, cInitDir, lSave, nFlags )

//------------------------------------------------------------------------------

function IsIntersectRect( aRect1, aBoxRect )

   local aSect
   local lreturn := .F.

   if aBoxRect[1] > aBoxRect[3]
      aBoxRect := { aBoxRect[3], aBoxRect[2], aBoxRect[1], aBoxRect[4] }
   endif
   if aBoxRect[2] > aBoxRect[4]
      aBoxRect := { aBoxRect[1], aBoxRect[4], aBoxRect[3], aBoxRect[2] }
   endif

   aSect := { MAX( aRect1[1], aBoxRect[1] ), ;
              MAX( aRect1[2], aBoxRect[2] ), ;
              MIN( aRect1[3], aBoxRect[3] ), ;
              MIN( aRect1[4], aBoxRect[4] ) }

   if IsPointInRect( { aSect[1], aSect[2] }, aRect1 ) .AND. ;
      IsPointInRect( { aSect[1], aSect[2] }, aBoxRect ) .OR. ;
      IsPointInRect( { aSect[3], aSect[4] }, aRect1 ) .AND. ;
      IsPointInRect( { aSect[3], aSect[4] }, aBoxRect )
      lreturn := .T.
   endif

return ( lreturn )

//------------------------------------------------------------------------------

function IsPointInRect( aPoint, aRect )

   local lreturn := .F.

   if aRect[1] <= aPoint[1] .AND. aRect[3] >= aPoint[1] .AND. ;
      aRect[2] <= aPoint[2] .AND. aRect[4] >= aPoint[2]
      lreturn := .T.
   endif

return ( lreturn )


*-- function -----------------------------------------------------------------
* Name........: GetSourceToolTip
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function GetSourceToolTip( cSourceCode )

   local cText := GL("Formula")

   if EMPTY( cSourceCode ) = .F.
      cText += ":" + CRLF
      if LEN( cSourceCode ) >= 200
         cText += SUBSTR( cSourceCode,   1, 100 ) + CRLF + ;
                  SUBSTR( cSourceCode, 100, 100 ) + CRLF + ;
                  SUBSTR( cSourceCode, 200 )
      ELSEif LEN( cSourceCode ) >= 100
         cText += SUBSTR( cSourceCode,   1, 100 ) + CRLF + ;
                  SUBSTR( cSourceCode, 100 )
      ELSE
         cText += cSourceCode
      endif
   endif

return ( cText )


*-- function -----------------------------------------------------------------
* Name........: AddToRecentDocs
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function AddToRecentDocs( cFullPathFile )

   local hDLL, uResult, cFarProc

   hDLL := LoadLib32( "Shell32.dll" )

   if ABS( hDLL ) <= 32

      MsgAlert( "Error code: " + LTrim( Str( hDLL ) ) + ;
      " loading " + "Shell32.dll" )

   ELSE

      cFarProc := GetProcAdd( hDLL, "SHAddToRecentDocs", .T., 7, 7, 8 )
      uResult  := FWCallDLL( cFarProc, 2, cFullPathFile + Chr(0) )
      FreeLibrary( hDLL )

   endif

return uResult


*-- function -----------------------------------------------------------------
* Name........: GetBarCodes
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function GetBarCodes()

   local aBarcodes := { "Code 39", ;
                        "Code 39 check digit", ;
                        "Code 128 auto select", ;
                        "Code 128 mode A", ;
                        "Code 128 mode B", ;
                        "Code 128 mode C", ;
                        "EAN 8", ;
                        "EAN 13", ;
                        "UPC-A", ;
                        "Codabar", ;
                        "Suplemento 5", ;
                        "Industrial 2 of 5", ;
                        "Industrial 2 of 5 check digit", ;
                        "Interleaved 2 of 5", ;
                        "Interleaved 2 of 5 check digit", ;
                        "Matrix 2 of 5", ;
                        "Matrix 2 of 5 check digit" ;
                      }

return ( aBarcodes )

//------------------------------------------------------------------------------

function MainCaption()

   local cUserApp   := ALLTRIM( oER:GetGeneralIni( "General", "MainAppTitle", "" ) )
   LOCAL cVersion := IIF ( lBeta , " - Beta Version" , " - Full version" )
   LOCAL cMainTitle := IIf(  !EMPTY( oER:cDefIni ), ALLTRIM( oER:GetDefIni( "General", "Title", "" ) ), "" )

   LOCAL cReturn := IIF( EMPTY( cUserApp ), "EasyReport", cUserApp ) + ;
              cVersion + ;
              IIF( EMPTY(cMainTitle), "", " - " + cMainTitle )

return ( cReturn )


*-- function -----------------------------------------------------------------
* Name........: Expressions
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function Expressions( lTake, cAltText )

   local i, oDlg, oFld, oBrw, oBrw2, oBrw3, oFont, creturn, oSay1, nTyp, oGet1
   local oBtn1, aBtn[3], aGet[5], cName
   local nAltSel    := SELECT()
   local nShowExpr  := VAL( oER:GetDefIni( "General", "Expressions", "0" ) )
   local cGenExpr   := ALLTRIM( oEr:cDataPath + oER:GetDefIni( "General", "GeneralExpressions", "General.dbf" ) )
   local cUserExpr  := ALLTRIM( oEr:cDataPath + oER:GetDefIni( "General", "UserExpressions", "User.dbf") )
 //  local cGenExpr   := ALLTRIM( cDefaultPath + GetPvProfString( "General", "GeneralExpressions", "", oER:cDefIni ) )
 //  local cUserExpr  := ALLTRIM( cDefaultPath + GetPvProfString( "General", "UserExpressions", "", oER:cDefIni ) )
   local aUndo      := {}
   local cErrorFile := ""
   //local aRDD      := { "DBFNTX", "COMIX", "DBFCDX" }

   DEFAULT cAltText := ""
   DEFAULT lTake    := .F.

   if FILE( VRD_LF2SF( cGenExpr ) ) = .F.
      cErrorFile += cGenExpr + CRLF
   endif
   if FILE( VRD_LF2SF( cUserExpr ) ) = .F.
      cErrorFile += cUserExpr + CRLF
   endif

   if .NOT. EMPTY( cErrorFile )
      MsgStop( GL("This file(s) could no be found:") + CRLF + CRLF + cErrorFile, GL("Stop!") )
      return( cAltText )
   endif

   DEFINE FONT oFont NAME "Arial" SIZE 0, -12

   DEFINE DIALOG oDlg NAME "EXPRESSIONS" TITLE GL("Expressions")

   REDEFINE SAY oSay1 ID 170 OF oDlg ;
      PROMPT GL("Please doubleclick an expression to take it over.")

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION oDlg:End()

   if nShowExpr = 2
      REDEFINE FOLDER oFld ID 110 OF oDlg ;
         PROMPT " " + GL("General") + " " ;
         DIALOGS "EXPRESS_FOLDER1"
   ELSE
      REDEFINE FOLDER oFld ID 110 OF oDlg ;
         PROMPT " " + GL("General") + " ", ;
                " " + GL("User defined") + " " ;
         DIALOGS "EXPRESS_FOLDER1", ;
                 "EXPRESS_FOLDER2"
   endif

   SELECT 0
   USE ( VRD_LF2SF( cGenExpr ) ) ALIAS "GENEXPR"

   REDEFINE LISTBOX oBrw ;
      FIELDS GENEXPR->NAME, GENEXPR->INFO ;
      FIELDSIZES 180, 400 ;
      HEADERS " " + GL("Name"), " " + GL("Description") ;
      ID 301 OF oFld:aDialogs[1] FONT oFont ;
      ON LEFT DBLCLICK ( creturn := GENEXPR->NAME, nTyp := 1, oDlg:End() )

   oBrw:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, ;
                     EVAL( {|| creturn := GENEXPR->NAME, nTyp := 1, oDlg:End() } ), .T. ) }

   if nShowExpr = 1

   i := 2
   SELECT 0
   USE ( VRD_LF2SF( cUserExpr ) ) ALIAS "USEREXPR"

   REDEFINE LISTBOX oBrw2 ;
      FIELDS USEREXPR->NAME, USEREXPR->INFO ;
      FIELDSIZES 220, 400 ;
      HEADERS " " + GL("Name"), " " + GL("Description") ;
      ID 301 OF oFld:aDialogs[i] FONT oFont ;
      ON CHANGE ( oDlg:Update(), aUndo := {} ) ;
      ON LEFT DBLCLICK ( creturn := USEREXPR->NAME, nTyp := 2, oDlg:End() )

   oBrw2:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, ;
                      EVAL( {|| creturn := USEREXPR->NAME, nTyp := 2, oDlg:End() } ), .T. ) }

   REDEFINE BUTTON PROMPT GL("&New")    ID 101 OF oFld:aDialogs[i] ;
      ACTION ( USEREXPR->(DBAPPEND()), oBrw2:Refresh(), oBrw2:GoBottom(), oDlg:Update() )
   REDEFINE BUTTON PROMPT GL("&Delete") ID 102 OF oFld:aDialogs[i] ;
      ACTION ( USEREXPR->(DBDELETE()), USEREXPR->(DBPACK()), ;
               USEREXPR->(DBSKIP(-1)), oBrw2:Refresh(), oDlg:Update() )

   REDEFINE GET           USEREXPR->NAME       ID 201 OF oFld:aDialogs[i] UPDATE ;
      VALID ( oBrw2:Refresh(), .T. )
   REDEFINE GET oGet1 VAR USEREXPR->EXPRESSION ID 202 OF oFld:aDialogs[i] UPDATE ;
      VALID ( oBrw2:Refresh(), .T. )
   REDEFINE GET           USEREXPR->INFO       ID 203 OF oFld:aDialogs[i] UPDATE ;
      VALID ( oBrw2:Refresh(), .T. )

   REDEFINE BUTTON ID 401 OF oFld:aDialogs[i] ACTION CopyToExpress( "="   , oGet1, @aUndo )
   REDEFINE BUTTON ID 402 OF oFld:aDialogs[i] ACTION CopyToExpress( "<>"  , oGet1, @aUndo )
   REDEFINE BUTTON ID 403 OF oFld:aDialogs[i] ACTION CopyToExpress( "<"   , oGet1, @aUndo )
   REDEFINE BUTTON ID 404 OF oFld:aDialogs[i] ACTION CopyToExpress( ">"   , oGet1, @aUndo )
   REDEFINE BUTTON ID 405 OF oFld:aDialogs[i] ACTION CopyToExpress( "<="  , oGet1, @aUndo )
   REDEFINE BUTTON ID 406 OF oFld:aDialogs[i] ACTION CopyToExpress( ">="  , oGet1, @aUndo )
   REDEFINE BUTTON ID 407 OF oFld:aDialogs[i] ACTION CopyToExpress( "=="  , oGet1, @aUndo )
   REDEFINE BUTTON ID 408 OF oFld:aDialogs[i] ACTION CopyToExpress( "("   , oGet1, @aUndo )
   REDEFINE BUTTON ID 409 OF oFld:aDialogs[i] ACTION CopyToExpress( ")"   , oGet1, @aUndo )
   REDEFINE BUTTON ID 410 OF oFld:aDialogs[i] ACTION CopyToExpress( '"'   , oGet1, @aUndo )
   REDEFINE BUTTON ID 411 OF oFld:aDialogs[i] ACTION CopyToExpress( "!"   , oGet1, @aUndo )
   REDEFINE BUTTON ID 412 OF oFld:aDialogs[i] ACTION CopyToExpress( "$"   , oGet1, @aUndo )
   REDEFINE BUTTON ID 413 OF oFld:aDialogs[i] ACTION CopyToExpress( "+"   , oGet1, @aUndo )
   REDEFINE BUTTON ID 414 OF oFld:aDialogs[i] ACTION CopyToExpress( "-"   , oGet1, @aUndo )
   REDEFINE BUTTON ID 415 OF oFld:aDialogs[i] ACTION CopyToExpress( "*"   , oGet1, @aUndo )
   REDEFINE BUTTON ID 416 OF oFld:aDialogs[i] ACTION CopyToExpress( "/"   , oGet1, @aUndo )
   REDEFINE BUTTON ID 417 OF oFld:aDialogs[i] ACTION CopyToExpress( ".T." , oGet1, @aUndo )
   REDEFINE BUTTON ID 418 OF oFld:aDialogs[i] ACTION CopyToExpress( ".F." , oGet1, @aUndo )

   REDEFINE BUTTON ID 502 OF oFld:aDialogs[i] ACTION CopyToExpress( ".or." , oGet1, @aUndo )
   REDEFINE BUTTON ID 503 OF oFld:aDialogs[i] ACTION CopyToExpress( ".and.", oGet1, @aUndo )
   REDEFINE BUTTON ID 504 OF oFld:aDialogs[i] ACTION CopyToExpress( ".not.", oGet1, @aUndo )

   REDEFINE BUTTON ID 601 OF oFld:aDialogs[i] ACTION CopyToExpress( "If( , , )", oGet1, @aUndo )
   REDEFINE BUTTON ID 602 OF oFld:aDialogs[i] ACTION CopyToExpress( "Val(  )"  , oGet1, @aUndo )
   REDEFINE BUTTON ID 603 OF oFld:aDialogs[i] ACTION CopyToExpress( "Str(  )"  , oGet1, @aUndo )

   REDEFINE BUTTON  PROMPT GL("Check") ID 505 OF oFld:aDialogs[i] ;
      ACTION CheckExpression( USEREXPR->EXPRESSION )
   REDEFINE BUTTON oBtn1 PROMPT GL("Undo") ID 506 OF oFld:aDialogs[i] WHEN LEN( aUndo ) > 0 ;
      ACTION aUndo := UnDoExpression( oGet1, aUndo )

   REDEFINE SAY ID 170 OF oFld:aDialogs[i] PROMPT GL("Name") + ":"
   REDEFINE SAY ID 171 OF oFld:aDialogs[i] PROMPT GL("Expression") + ":"
   REDEFINE SAY ID 172 OF oFld:aDialogs[i] PROMPT GL("Description") + ":"

   endif

   ACTIVATE DIALOG oDlg CENTER ;
      ON INIT IIF( lTake = .F., oSay1:Hide, .T. )

   if .NOT. EMPTY( creturn )
      creturn := "[" + ALLTRIM(STR( nTyp , 1 )) + "]" + ALLTRIM( creturn )
   ELSEif .NOT. EMPTY( cAltText )
      creturn := cAltText
   endif

   GENEXPR->(DBCLOSEAREA())

   if nShowExpr = 1
      USEREXPR->(DBCLOSEAREA())
   endif

   SELECT( nAltSel )
   oFont:End()
   aUndo := {}

return ( creturn )

//------------------------------------------------------------------------------

function CheckExpression( cText )

   local lreturn, xreturn, oScript

   oScript := TScript():New( "function TEST()" + CRLF + cText + CRLF + "return" )

   oScript:Compile()

   if EMPTY( oScript:cError )
      MsgWait( GL("Correct expression"), GL("Check"), 1.5 )
      lreturn := .T.
   ELSE
      MsgStop( GL("Incorrect expression"), GL("Check") )
      lreturn := .F.
   endif

return .T.


*-- function -----------------------------------------------------------------
* Name........: DBPack
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function DBPack()

   PACK

return .T.


*-- function -----------------------------------------------------------------
* Name........: DBReplace
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
/*  no usado
function DBReplace( cReplFeld, xAusdruck )

   REPLACE &cReplFeld with xAusdruck

return .T.
*/

*-- function -----------------------------------------------------------------
* Name........: CopyToExpress
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function CopyToExpress( cText, oGet, aUndo )

   AADD( aUndo, oGet:cText )

   oGet:SetFocus()
   oGet:Paste( cText )
   oGet:SetPos( oGet:nPos + LEN( cText ) )

return .T.


*-- function -----------------------------------------------------------------
* Name........: UndoExpression
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function UnDoExpression( oGet, aUndo )

   if Len( aUndo ) > 0
      if .NOT. EMPTY( ATAIL( aUndo ) )
         oGet:cText( ATAIL( aUndo ) )
         oGet:Refresh()
         ASIZE( aUndo, Len( aUndo ) - 1 )
      endif
   endif

   oGet:SetFocus()

return ( aUndo )


//------------------------------------------------------------------------------

function EditLanguage()

   local oDlg, oBrw
   local aHeader    := ARRAY(20)
   local aCol       := ARRAY(20)
   local nVorColor  := RGB( 0, 0, 0 )
   local nHinColor  := RGB( 224, 239, 223 )
   local nHinColor2 := RGB( 223, 231, 224 )
   local nHinColor3 := RGB( 235, 234, 203 )
   local nHVorCol   := RGB( 0, 0, 0 )
   local nSelect    := SELECT()

   DBUSEAREA( .T.,, "LANGUAGE.DBF",, .F. )

   DEFINE DIALOG oDlg NAME "EDITLANGUAGE" TITLE GL("Language Database")

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION oDlg:End()

   REDEFINE SAY PROMPT GL("Please restart the programm to activate the changes.") ;
      ID 170 OF oDLg

   SELECT LANGUAGE
   SET ORDER TO 1
   GO TOP

   REDEFINE xbrowse oBrw ;
      FIELDS LANGUAGE->LANGUAGE1, ;
             LANGUAGE->LANGUAGE2, ;
             LANGUAGE->LANGUAGE3, ;
             LANGUAGE->LANGUAGE4, ;
             LANGUAGE->LANGUAGE5, ;
             LANGUAGE->LANGUAGE6, ;
             LANGUAGE->LANGUAGE7, ;
             LANGUAGE->LANGUAGE8, ;
             LANGUAGE->LANGUAGE9 ;
         FIELDSIZES 300, 300, 300, 300, 300, 300, 300, 300, 300 ;
         HEADERS " " + oER:GetGeneralIni( "Languages", "1", "Language 1" ), ;
                 " " + oER:GetGeneralIni( "Languages", "2", "Language 2" ), ;
                 " " + oER:GetGeneralIni( "Languages", "3", "Language 3" ), ;
                 " " + oER:GetGeneralIni( "Languages", "4", "Language 4" ), ;
                 " " + oER:GetGeneralIni( "Languages", "5", "Language 5" ), ;
                 " " + oER:GetGeneralIni( "Languages", "6", "Language 6" ), ;
                 " " + oER:GetGeneralIni( "Languages", "7", "Language 7" ), ;
                 " " + oER:GetGeneralIni( "Languages", "8", "Language 8" ), ;
                 " " + oER:GetGeneralIni( "Languages", "9", "Language 9" ) ;
         ID 301 OF oDlg ;
         ON LEFT DBLCLICK GetLanguage()

   oBrw:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, GetLanguage(), .T. ) }

   ACTIVATE DIALOG oDlg CENTERED

   LANGUAGE->(DBCLOSEAREA())
   SELECT( nSelect )

return .T.

//------------------------------------------------------------------------------

function GetLanguage()

   local oDlg

   LANGUAGE->(RLOCK())

   DEFINE DIALOG oDlg NAME "GETLANGUAGE"

   REDEFINE BUTTON ID 101 OF oDlg ACTION oDlg:End()

   REDEFINE SAY PROMPT oER:GetGeneralIni( "Languages", "1", "Language 1" ) + ":" ID 151 OF oDlg
   REDEFINE SAY PROMPT oER:GetGeneralIni( "Languages", "2", "Language 2" ) + ":" ID 152 OF oDlg
   REDEFINE SAY PROMPT oER:GetGeneralIni( "Languages", "3", "Language 3" ) + ":" ID 153 OF oDlg
   REDEFINE SAY PROMPT oER:GetGeneralIni( "Languages", "4", "Language 4" ) + ":" ID 154 OF oDlg
   REDEFINE SAY PROMPT oER:GetGeneralIni( "Languages", "5", "Language 5" ) + ":" ID 155 OF oDlg
   REDEFINE SAY PROMPT oER:GetGeneralIni( "Languages", "6", "Language 6" ) + ":" ID 156 OF oDlg
   REDEFINE SAY PROMPT oER:GetGeneralIni( "Languages", "7", "Language 7" ) + ":" ID 157 OF oDlg
   REDEFINE SAY PROMPT oER:GetGeneralIni( "Languages", "8", "Language 8" ) + ":" ID 158 OF oDlg
   REDEFINE SAY PROMPT oER:GetGeneralIni( "Languages", "9", "Language 9" ) + ":" ID 159 OF oDlg

   REDEFINE SAY PROMPT " " + LANGUAGE->LANGUAGE1 ID 201 OF oDlg

   REDEFINE GET LANGUAGE->LANGUAGE2 ID 202 OF oDlg
   REDEFINE GET LANGUAGE->LANGUAGE3 ID 203 OF oDlg
   REDEFINE GET LANGUAGE->LANGUAGE4 ID 204 OF oDlg
   REDEFINE GET LANGUAGE->LANGUAGE5 ID 205 OF oDlg
   REDEFINE GET LANGUAGE->LANGUAGE6 ID 206 OF oDlg
   REDEFINE GET LANGUAGE->LANGUAGE7 ID 207 OF oDlg
   REDEFINE GET LANGUAGE->LANGUAGE8 ID 208 OF oDlg
   REDEFINE GET LANGUAGE->LANGUAGE9 ID 209 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED

   LANGUAGE->(DBUNLOCK())

return .T.

//------------------------------------------------------------------------------

function ER_GetPixel( nValue )

   if Upper( ValType( oER:nMeasure ) ) = "L"
      oER:nMeasure := 1
   endif

   if oER:nMeasure = 1
      //mm
      nValue := nValue * 3
   ELSEif oER:nMeasure = 2
      //Inch
      nValue := nValue * 100
   endif

return ( nValue )


*-- function -----------------------------------------------------------------
* Name........: GetCmInch
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function GetCmInch( nValue )

   if oER:nMeasure = 1
      //mm
      nValue := ROUND( nValue / 3, 0 )
   ELSEif oER:nMeasure = 2
      //Inch
      nValue := ROUND( nValue / 100, 2 )
   endif

return ( nValue )

//------------------------------------------------------------------------------

function GetField( cString, nNr, cSepChar )

   DEFAULT cSepChar := "|"

return StrToken( cString, nNr, cSepChar )



//------------------------------------------------------------------------------
/*  no usada
function StrCount( cText, cString )

   local i
   local nCount := 0

   for i := 1 TO LEN( ALLTRIM( cText ) )
      if SUBSTR( cText, i, LEN( cString ) ) == cString
         ++nCount
      endif
   NEXT

return ( nCount )
 */
//------------------------------------------------------------------------------
/*   no usada
function GetResDLL()

   local cDLLName
   local nLanguage := VAL( GetPvProfString( "General", "Language", "1", oER:cGeneralIni ) )

   if nLanguage < 1
      nLanguage := 1
   endif

   cDLLName := "VRD" + ALLTRIM(STR( nLanguage, 1, 3)) + ".DLL"

   if FILE( cDLLName ) = .F.
      MsgInfo( GL("Language specific file") + " " + cDLLName + " " + GL("not found!") + CRLF + CRLF + ;
               GL("The english file will be used instead.") )
      cDLLName := "VRD1.DLL"
   endif

return ( cDLLName )
 */
//------------------------------------------------------------------------------
 /*
function OpenLanguage()

   USE LANGUAGE.DBF

   DO WHILE !LANGUAGE->(EOF())

      AADD( oGenVar:aLanguages, { LANGUAGE->LANGUAGE1, LANGUAGE->LANGUAGE2, ;
                                  LANGUAGE->LANGUAGE3, LANGUAGE->LANGUAGE4, ;
                                  LANGUAGE->LANGUAGE5, LANGUAGE->LANGUAGE6, ;
                                  LANGUAGE->LANGUAGE7, LANGUAGE->LANGUAGE8, ;
                                  LANGUAGE->LANGUAGE9 } )
      LANGUAGE->(DBSKIP())

   ENDDO

   LANGUAGE->(DBCLOSEAREA())

return .T.
 */

function OpenLanguage()
   LOCAL aStrings:= FWGetStrings()
   FOR i = 1 TO Len(aStrings  )

        AADD( oGenVar:aLanguages, { aStrings[i,1],;
                                    aStrings[i,5],;
                                    aStrings[i,6],;
                                    aStrings[i,2],;
                                    aStrings[i,4],;
                                    aStrings[i,3] } )
   next

  /*
   USE LANGUAGE.DBF

   DO WHILE !LANGUAGE->(EOF())

      AADD( oGenVar:aLanguages, { LANGUAGE->LANGUAGE1, LANGUAGE->LANGUAGE2, ;
                                  LANGUAGE->LANGUAGE3, LANGUAGE->LANGUAGE4, ;
                                  LANGUAGE->LANGUAGE5, LANGUAGE->LANGUAGE6, ;
                                  LANGUAGE->LANGUAGE7, LANGUAGE->LANGUAGE8, ;
                                  LANGUAGE->LANGUAGE9 } )
      LANGUAGE->(DBSKIP())

   ENDDO

   LANGUAGE->(DBCLOSEAREA())
   */
return .T.

//------------------------------------------------------------------------------
/*
function GL( cOriginal )

   local cAltText := strtran( cOriginal, " ", "_" )
   local cText    := cAltText
   local nSelect  := Select()
   local nPos     := ASCAN( oGenVar:aLanguages, ;
                            { |aVal| ALLTRIM( aVal[1] ) == ALLTRIM( cAltText ) } )

   if nPos = 0
      //New String
      SELECT 0
      USE LANGUAGE
      FLOCK()
      APPEND BLANK
      REPLACE LANGUAGE->LANGUAGE1 WITH cText
      UNLOCK
      LANGUAGE->(DBCLOSEAREA())
      oGenVar:aLanguages := {}
      OpenLanguage()
      SELECT( nSelect )
   ELSE
      cText := oGenVar:aLanguages[ nPos, oGenVar:nLanguage ]
      if EMPTY( cText )
         cText := oGenVar:aLanguages[ nPos, 1 ]
      endif
   endif

return ( STRTRAN(ALLTRIM( cText ), "_", " " ) )
   */
//------------------------------------------------------------------------------

function GL( cOriginal )

   local cAltText := cOriginal   //strtran( cOriginal, " ", "_" )
   local cText    := cAltText
   LOCAL aLanguage
   LOCAL aStrings:= FWGetStrings()

   LOCAL cFileName := cFilePath( GetModuleFileName( GetInstance() ) ) + ;
                        "fwstrings.ini"

   local nPos     := ASCAN( aStrings, ;
                            { |aVal| ALLTRIM( aVal[1] ) == ALLTRIM( cAltText ) } )

   if nPos = 0

      aLanguage :=  ER_LoadStrings()
      AAdd( aLanguage,{ cOriginal,,,,, } )
      FWSaveStrings( cFileName , aLanguage )
      FWAddString( { cOriginal,,,,, } )

      //New String
   //   SELECT 0
    //  USE LANGUAGE
    //  FLOCK()
    //  APPEND BLANK
    //  REPLACE LANGUAGE->LANGUAGE1 WITH cText
    //  UNLOCK
    //  LANGUAGE->(DBCLOSEAREA())

      oGenVar:aLanguages := {}
      OpenLanguage()

    //  SELECT( nSelect )
   ELSE
      cText := oGenVar:aLanguages[ nPos, oGenVar:nLanguage ]
      if EMPTY( cText )
         cText := oGenVar:aLanguages[ nPos, 1 ]
      endif
   endif

return ALLTRIM( cText )  //( STRTRAN(ALLTRIM( cText ), "_", " " ) )

//------------------------------------------------------------------------------

function ER_LoadStrings( cFileName )

   local cLine, n := 1
   loca aLanguage

   DEFAULT cFileName := cFilePath( GetModuleFileName( GetInstance() ) ) + ;
                        "fwstrings.ini"

   while ! Empty( cLine := GetPvProfString( "strings", AllTrim( Str( n++ ) ), "", cFileName ) )
      AAdd( aLanguage, { AllTrim( StrToken( cLine, 1, "|" ) ),;
                        AllTrim( StrToken( cLine, 2, "|" ) ),;
                        AllTrim( StrToken( cLine, 3, "|" ) ),;
                        AllTrim( StrToken( cLine, 4, "|" ) ),;
                        AllTrim( StrToken( cLine, 5, "|" ) ),;
                        AllTrim( StrToken( cLine, 6, "|" ) ) } )
   end

RETURN aLanguage

//------------------------------------------------------------------------------

function PrintReport( lPreview, lDeveloper, lPrintDlg, LPrintIDs )

   local i, oVRD, cCondition
   //local lPrintIDs := IIF( GetPvProfString( "General", "PrintIDs", "0", oER:cDefIni ) = "0", .F., .T. )

   DEFAULT lPrintIDs := .F.

   DEFAULT lPreview   := .F.
   DEFAULT lDeveloper := .F.
   DEFAULT lPrintDlg  := .T.

   lpreview := .t. // de momento para ver como sale
   lDeveloper:= .t.   // de momento para ver como sale

 //  if lDeveloper = .F.
 //     ShellExecute( 0, "Open", ;
 //        "ERSTART.EXE", ;
 //        "-File=" + ALLTRIM( oER:cDefIni ) + ;
  //       IIF( lPreview, " -PREVIEW", " -PRINTDIALOG" ) + ;
   //      "-CHECK", ;
   //      NIL, 1 )
   //   return .T.
 //  ELSE
      EASYREPORT oVRD NAME oER:cDefIni OF oEr:oMainWnd PREVIEW lPreview ;
                 PRINTDIALOG IIF( lPreview, .F., lPrintDlg ) PRINTIDS NOEXPR
 //  endif

   oVRD:LPrintIDs :=  lPrintIDs
   oVrd:lAutoPageBreak := .T.

   if oVRD:lDialogCancel
      return( .F. )
   endif

   //erste Seite
   for i := 1 TO LEN( oVRD:aAreaInis )

      if GetPvProfString( "General", "Condition", "0", oVRD:aAreaInis[i] ) <> "4"
         PRINTAREA i OF oVRD
      endif

   NEXT

   //zweite Seite
   if IsSecondPage( oVRD )

      oVRD:PageBreak()

      for i := 1 TO LEN( oVRD:aAreaInis )
         cCondition := GetPvProfString( "General", "Condition", "0", oVRD:aAreaInis[i] )
         if cCondition = "1" .OR. cCondition = "4"
            PRINTAREA i OF oVRD
         endif
      NEXT

   endif

   END EASYREPORT oVRD

return .T.

//------------------------------------------------------------------------------

function AltPrintReport( lPreview, cPrinter )

   local i, oVRD, cCondition
   local lPrintIDs := IIF( oER:GetDefIni( "General", "PrintIDs", "0" ) = "0", .F., .T. )

   oVRD := VRD():New( oER:cDefIni, lPreview, cPrinter, oEr:oMainWnd,, lPrintIDs,, .T. )

   //erste Seite
   for i := 1 TO LEN( oVRD:aAreaInis )

      if GetPvProfString( "General", "Condition", "0", oVRD:aAreaInis[i] ) <> "4"
         oVRD:PrintArea( i )
      endif

   NEXT

   //zweite Seite
   if IsSecondPage( oVRD )

      oVRD:PageBreak()

      for i := 1 TO LEN( oVRD:aAreaInis )
         cCondition := GetPvProfString( "General", "Condition", "0", oVRD:aAreaInis[i] )
         if cCondition = "1" .OR. cCondition = "4"
            oVRD:PrintArea( i )
         endif
      NEXT

   endif

   oVrd:End()

return .T.

//------------------------------------------------------------------------------

function IsSecondPage( oVRD )

   local i
   local lreturn := .F.

   for i := 1 TO LEN( oVRD:aAreaInis )

      if GetPvProfString( "General", "Condition", "0", oVRD:aAreaInis[i] ) = "4"
         lreturn := .T.
         EXIT
      endif

   NEXT

return ( lreturn )

//------------------------------------------------------------------------------

function OpenUndo()

   local nSelect := SELECT()

   oGenVar:AddMember( "cUndoFileName",, cTempFile() )
   oGenVar:AddMember( "cRedoFileName",, cTempFile() )

   cTempFile()
   SELECT 0
   CREATE TMPST

   APPEND BLANK
   REPLACE FIELD_NAME WITH "ENTRYTEXT" , FIELD_TYPE WITH "C", FIELD_LEN WITH 250, FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "ENTRYNR"   , FIELD_TYPE WITH "N", FIELD_LEN WITH   5, FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "AREANR"    , FIELD_TYPE WITH "N", FIELD_LEN WITH   5, FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "AREATEXT"  , FIELD_TYPE WITH "M", FIELD_LEN WITH  10, FIELD_DEC WITH 0

   CREATE ( oGenVar:cUndoFileName + ".dbf" ) FROM TMPST ALIAS TMPUNDO
   CREATE ( oGenVar:cRedoFileName + ".dbf" ) FROM TMPST ALIAS TMPREDO

   ERASE TMPST.DBF
   TMPREDO->(DBCLOSEAREA())
   SELECT( nSelect )

return .T.

//------------------------------------------------------------------------------

function CloseUndo()

  DelFile( ".\" + oGenVar:cUndoFileName + ".dbf" )
  DelFile( ".\" + oGenVar:cUndoFileName + ".dbt" )
  DelFile( ".\" + oGenVar:cRedoFileName + ".dbf" )
  DelFile( ".\" + oGenVar:cRedoFileName + ".dbt" )

return .T.

//------------------------------------------------------------------------------

function Add2Undo( cEntryText, nEntryNr, nAreaNr, cAreaText )

   local nSelect := SELECT()

   DEFAULT cAreaText := ""

   SELECT 0
   USE ( oGenVar:cUndoFileName + ".dbf" ) ALIAS TMPUNDO

   APPEND BLANK
   REPLACE TMPUNDO->ENTRYTEXT WITH cEntryText
   REPLACE TMPUNDO->ENTRYNR   WITH nEntryNr
   REPLACE TMPUNDO->AREANR    WITH nAreaNr
   REPLACE TMPUNDO->AREATEXT  WITH cAreaText

   RefreshUndo()

   TMPUNDO->(DBCLOSEAREA())
   SELECT( nSelect )

   oEr:oMainWnd:oBar:AEvalWhen()

return .T.

//------------------------------------------------------------------------------

function Undo()

   local oIni, oItemInfo, nOldWidth, nOldHeight
   local nSelect   := SELECT()
   local aFirst    := { .F., 0, 0, 0, 0, 0 }
   local nElemente := 0

   UnSelectAll()

   SELECT 0
   USE ( oGenVar:cUndoFileName + ".dbf" ) ALIAS TMPUNDO
   TMPUNDO->(GOBOTTOM())

   SELECT 0
   USE ( oGenVar:cRedoFileName + ".dbf" ) ALIAS TMPREDO

   APPEND BLANK
   REPLACE TMPREDO->ENTRYTEXT WITH ALLTRIM( GetPvProfString( ;
      "Items", ALLTRIM(STR(TMPUNDO->ENTRYNR,5)) , "", aAreaIni[ TMPUNDO->AREANR ] ) )
   REPLACE TMPREDO->ENTRYNR   WITH TMPUNDO->ENTRYNR
   REPLACE TMPREDO->AREANR    WITH TMPUNDO->AREANR
   REPLACE TMPREDO->AREATEXT  WITH MEMOREAD( aAreaIni[ TMPUNDO->AREANR ] )

   SELECT TMPUNDO

   if TMPUNDO->ENTRYNR = 0

      //Area undo
      nOldWidth  := VAL( GetPvProfString( "General", "Width", "600", aAreaIni[ TMPUNDO->AREANR ] ) )
      nOldHeight := VAL( GetPvProfString( "General", "Height", "300", aAreaIni[ TMPUNDO->AREANR ] ) )

      MEMOWRIT( aAreaIni[ TMPUNDO->AREANR ], TMPUNDO->AREATEXT )

      MEMOWRIT( ".\TMPAREA.INI", TMPUNDO->AREATEXT )

      AreaChange( TMPUNDO->AREANR, ;
                  GetPvProfString( "General", "Title", "", ".\TMPAREA.INI" ), ;
                  nOldWidth, ;
                  VAL( GetPvProfString( "General", "Width", "600", ".\TMPAREA.INI" ) ), ;
                  nOldHeight, ;
                  VAL( GetPvProfString( "General", "Height", "300", ".\TMPAREA.INI" ) ) )

      ERASE ".\TMPAREA.INI"

   ELSEif EMPTY( TMPUNDO->ENTRYTEXT )

      //New item was build
      DeleteItem( TMPUNDO->ENTRYNR, TMPUNDO->AREANR, .T.,, .T. )
      DelIniEntry( "Items", ALLTRIM(STR(TMPUNDO->ENTRYNR,5)), aAreaIni[ TMPUNDO->AREANR ] )

   ELSE

      if aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ] <> NIL
         DeleteItem( TMPUNDO->ENTRYNR, TMPUNDO->AREANR, .T.,, .T. )
      endif

      INI oIni FILE aAreaIni[ TMPUNDO->AREANR ]
         SET SECTION "Items" ENTRY ALLTRIM(STR(TMPUNDO->ENTRYNR,5)) TO TMPUNDO->ENTRYTEXT OF oIni
      ENDINI

      oItemInfo := VRDItem():New( TMPUNDO->ENTRYTEXT )

      if oItemInfo:nShow = 1
         aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ] := NIL
         ShowItem( TMPUNDO->ENTRYNR, TMPUNDO->AREANR, aAreaIni[ TMPUNDO->AREANR ], aFirst, nElemente )
         aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ]:lDrag := .T.
      endif

   endif

   DELETE
   PACK

   RefreshUndo()
   RefreshRedo()
   oEr:oMainWnd:oBar:AEvalWhen()

   TMPUNDO->(DBCLOSEAREA())
   TMPREDO->(DBCLOSEAREA())
   SELECT( nSelect )

return .T.

//------------------------------------------------------------------------------

function Redo()

   local oIni, oItemInfo, nOldWidth, nOldHeight
   local nSelect   := SELECT()
   local aFirst    := { .F., 0, 0, 0, 0, 0 }
   local nElemente := 0

   UnSelectAll()

   SELECT 0
   USE ( oGenVar:cRedoFileName + ".dbf" ) ALIAS TMPREDO
   TMPREDO->(GOBOTTOM())

   SELECT 0
   USE ( oGenVar:cUndoFileName + ".dbf" ) ALIAS TMPUNDO

   APPEND BLANK
   REPLACE TMPUNDO->ENTRYTEXT WITH ALLTRIM( GetPvProfString( ;
      "Items", ALLTRIM(STR(TMPREDO->ENTRYNR,5)) , "", aAreaIni[ TMPREDO->AREANR ] ) )
   REPLACE TMPUNDO->ENTRYNR   WITH TMPREDO->ENTRYNR
   REPLACE TMPUNDO->AREANR    WITH TMPREDO->AREANR
   REPLACE TMPUNDO->AREATEXT  WITH MEMOREAD( aAreaIni[ TMPREDO->AREANR ] )

   SELECT TMPREDO

   if TMPREDO->ENTRYNR = 0

      //Area redo
      nOldWidth  := VAL( GetPvProfString( "General", "Width", "600", aAreaIni[ TMPREDO->AREANR ] ) )
      nOldHeight := VAL( GetPvProfString( "General", "Height", "300", aAreaIni[ TMPREDO->AREANR ] ) )

      MEMOWRIT( aAreaIni[ TMPREDO->AREANR ], TMPREDO->AREATEXT )
      MEMOWRIT( ".\TMPAREA.INI", TMPREDO->AREATEXT )

      AreaChange( TMPREDO->AREANR, ;
                  GetPvProfString( "General", "Title", "", ".\TMPAREA.INI" ), ;
                  nOldWidth, ;
                  VAL( GetPvProfString( "General", "Width", "600", ".\TMPAREA.INI" ) ), ;
                  nOldHeight, ;
                  VAL( GetPvProfString( "General", "Height", "300", ".\TMPAREA.INI" ) ) )

      ERASE ".\TMPAREA.INI"

   ELSEif EMPTY( TMPREDO->ENTRYTEXT )

      //New item was build
      DeleteItem( TMPREDO->ENTRYNR, TMPREDO->AREANR, .T.,, .T. )
      DelIniEntry( "Items", ALLTRIM(STR(TMPREDO->ENTRYNR,5)), aAreaIni[ TMPREDO->AREANR ] )

   ELSE

      if aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ] <> NIL
         DeleteItem( TMPREDO->ENTRYNR, TMPREDO->AREANR, .T.,, .T. )
      endif

      INI oIni FILE aAreaIni[ TMPREDO->AREANR ]
         SET SECTION "Items" ENTRY ALLTRIM(STR(TMPREDO->ENTRYNR,5)) TO TMPREDO->ENTRYTEXT OF oIni
      ENDINI

      oItemInfo := VRDItem():New( TMPREDO->ENTRYTEXT )

      if oItemInfo:nShow = 1
         aItems[ TMPREDO->AREANR, TMPREDO->ENTRYNR ] := NIL
         ShowItem( TMPREDO->ENTRYNR, TMPREDO->AREANR, aAreaIni[ TMPREDO->AREANR ], aFirst, nElemente )
         aItems[ TMPREDO->AREANR, TMPREDO->ENTRYNR ]:lDrag := .T.
      endif

   endif

   DELETE
   PACK

   RefreshUndo()
   RefreshRedo()
   oEr:oMainWnd:oBar:AEvalWhen()

   TMPUNDO->(DBCLOSEAREA())
   TMPREDO->(DBCLOSEAREA())
   SELECT( nSelect )

return .T.


*-- function -----------------------------------------------------------------
* Name........: RefreshUndo()
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function RefreshUndo()

   nUndoCount := TMPUNDO->(LASTREC())

return .T.


*-- function -----------------------------------------------------------------
* Name........: RefreshRedo()
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function RefreshRedo()

   nRedoCount := TMPREDO->(LASTREC())

return .T.


*-- function -----------------------------------------------------------------
* Name........: ClearUndoRedo
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function ClearUndoRedo()

   local nSelect := SELECT()

   SELECT 0
   USE ( oGenVar:cUndoFileName + ".dbf" ) ALIAS TMPUNDO
   ZAP

   USE ( oGenVar:cRedoFileName + ".dbf" ) ALIAS TMPREDO
   ZAP

   TMPREDO->(DBCLOSEAREA())
   SELECT( nSelect )

   nUndoCount := 0
   nRedoCount := 0

   oEr:oMainWnd:oBar:AEvalWhen()

return .T.


* - function ---------------------------------------------------------------
*  function....: UndoRedoMenu
*  Beschreibung: Shell-Menu anzeigen
*  Argumente...: None
*  R�ckgabewert: ( NIL )
*  Author......: Timm Sodtalbers
* --------------------------------------------------------------------------
function UndoRedoMenu( nTyp, oBtn )

   local i, oMenu
   local cText1 := "" //IIF( nTyp = 1, GL("Undo"), GL("Redo") )
   local cText2 := IIF( nTyp = 1, GL("Undo all"), GL("Redo all") )
   local nCount := IIF( nTyp = 1, nUndoCount, nRedoCount )
   local aRect  := GetClientRect( oBtn:hWnd )

   MENU oMenu POPUP

      MENUITEM cText1 + "1 " + GL("action") ;
         WHEN IIF( nTyp = 1, nUndoCount, nRedoCount ) > 0 ;
         ACTION MultiUndoRedo( nTyp, 1 )
      MENUITEM cText1 + "2 " + GL("actions") ;
         WHEN IIF( nTyp = 1, nUndoCount, nRedoCount ) > 1 ;
         ACTION MultiUndoRedo( nTyp, 2 )
      MENUITEM cText1 + "3 " + GL("actions") ;
         WHEN IIF( nTyp = 1, nUndoCount, nRedoCount ) > 2 ;
         ACTION MultiUndoRedo( nTyp, 3 )
      MENUITEM cText1 + "4 " + GL("actions") ;
         WHEN IIF( nTyp = 1, nUndoCount, nRedoCount ) > 3 ;
         ACTION MultiUndoRedo( nTyp, 4 )
      MENUITEM cText1 + "5 " + GL("actions") ;
         WHEN IIF( nTyp = 1, nUndoCount, nRedoCount ) > 4 ;
         ACTION MultiUndoRedo( nTyp, 5 )
      MENUITEM cText1 + "6 " + GL("actions") ;
         WHEN IIF( nTyp = 1, nUndoCount, nRedoCount ) > 5 ;
         ACTION MultiUndoRedo( nTyp, 6 )
      MENUITEM cText1 + "7 " + GL("actions") ;
         WHEN IIF( nTyp = 1, nUndoCount, nRedoCount ) > 6 ;
         ACTION MultiUndoRedo( nTyp, 7 )
      MENUITEM cText1 + "8 " + GL("actions") ;
         WHEN IIF( nTyp = 1, nUndoCount, nRedoCount ) > 7 ;
         ACTION MultiUndoRedo( nTyp, 8 )
      MENUITEM cText1 + "9 " + GL("actions") ;
         WHEN IIF( nTyp = 1, nUndoCount, nRedoCount ) > 8 ;
         ACTION MultiUndoRedo( nTyp, 9 )
      MENUITEM cText1 + "10 " + GL("actions") ;
         WHEN IIF( nTyp = 1, nUndoCount, nRedoCount ) > 9 ;
         ACTION MultiUndoRedo( nTyp, 10 )

      MENUITEM cText2 ACTION MultiUndoRedo( nTyp, IIF( nTyp = 1, nUndoCount, nRedoCount ) )

   ENDMENU

   ACTIVATE POPUP oMenu AT aRect[3], aRect[2] OF oBtn

return( oMenu )



function MultiUndoRedo( nTyp, nCount )

   local i

   for i := 1 TO nCount
      IIF( nTyp = 1, Undo(), Redo() )
   NEXT

   return .T.


//------------------------------------------------------------------------------


/*
FUNCTION CreateIniStrings(cFileName)
   LOCAL aLanguage:= {}
   LOCAL aStrings

   local cText := "[strings]" + CRLF, n

   DEFAULT cFileName := cFilePath( GetModuleFileName( GetInstance() ) ) + ;
                        "fwstrings.ini"
   msginfo(cfileName)
   use language new
   go top
   DO WHILE !Eof()
      aString:= {  STRTRAN(ALLTRIM( AllTrim(FIELD->language1) ), "_", " " ) ,;
                  STRTRAN(ALLTRIM( AllTrim(FIELD->language4) ), "_", " " ) ,;
                  STRTRAN(ALLTRIM( AllTrim(FIELD->language7) ), "_", " " ) ,;
                STRTRAN(ALLTRIM( AllTrim(FIELD->language5) ), "_", " " ) ,;
                 STRTRAN(ALLTRIM( AllTrim(FIELD->language2) ), "_", " " ) ,;
                 STRTRAN(ALLTRIM( AllTrim(FIELD->language3) ), "_", " " ) }

       AAdd( aLanguage , aString  )

      skip
   enddo

    FWSaveStrings( cFileName , aLanguage )

   close language
RETURN nil
 */


