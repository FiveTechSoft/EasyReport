
#INCLUDE "FiveWin.ch"
#INCLUDE "VRD.ch"
#INCLUDE "Mail.ch"

MEMVAR aItems, aFonts, oAppFont, aAreaIni, aWnd, aWndTitle, oBar, oMru
MEMVAR oCbxArea, aCbxItems, nAktuellItem, aRuler, cLongDefIni, cDefaultPath
MEMVAR nAktItem, nAktArea, nSelArea, cAktIni, aSelection, nTotalHeight, nTotalWidth
MEMVAR nHinCol1, nHinCol2, nHinCol3, oMsgInfo
MEMVAR aVRDSave, lVRDSave, lFillWindow, nDeveloper, oRulerBmp1, oRulerBmp2
MEMVAR lBoxDraw, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight
MEMVAR cItemCopy, nCopyEntryNr, nCopyAreaNr, aSelectCopy, aItemCopy, nXMove, nYMove
MEMVAR cInfoWidth, cInfoHeight, nInfoRow, nInfoCol, aItemPosition, aItemPixelPos
MEMVAR oClpGeneral, cDefIni, cGeneralIni, nMeasure, cMeasure, lDemo, lBeta, oTimer
MEMVAR oMainWnd, lProfi, nUndoCount, nRedoCount, lPersonal, lStandard, oGenVar

Function GetFreeSystemResources()
Return 0

*-- FUNCTION -----------------------------------------------------------------
*         Name: CheckPath
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CheckPath( cPath )

   cPath := ALLTRIM( cPath )

   IF .NOT. EMPTY( cPath ) .AND. SUBSTR( cPath, LEN( cPath ) ) <> "\"
      cPath += "\"
   ENDIF

RETURN ( cPath )


*-- FUNCTION -----------------------------------------------------------------
*         Name: InsertArea
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION InsertArea( lBefore, cTitle )

   LOCAL i, oGet, oDlg, cTmpFile
   LOCAL aAreaInis   := {}
   LOCAL lReturn     := .T.
   LOCAL cFile       := SPACE( 200 )
   LOCAL aIniEntries := GetIniSection( "Areas", cDefIni )
   LOCAL nNewArea    := nAktArea + IIF( lBefore, 0, 1 )
   LOCAL cDir        := CheckPath( GetPvProfString( "General", "AreaFilesDir", "", cDefIni ) )

   IF EMPTY( cDir )
      cDir := cDefaultPath
   ENDIF

   FOR i := 1 TO 100
      AADD( aAreaInis, ALLTRIM( GetIniEntry( aIniEntries, ALLTRIM(STR( i, 5 )) , "" ) ) )
   NEXT

   DEFINE DIALOG oDlg NAME "NEWFILENAME" TITLE cTitle

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION ;
      IIF( FILE( cDir + cFile ), MsgStop( GL("The file already exists."), GL("Stop!") ), ;
                                 ( lReturn := .T., oDlg:End() ) )

   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE SAY PROMPT GL("Name of the new area file") + ":" ID 171 OF oDlg

   REDEFINE GET oGet VAR cFile ID 201 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED

   IF lReturn = .T.

      nNewArea := IIF( nNewArea < 1, 1, nNewArea )
      AINS( aAreaInis, nNewArea )
      aAreaInis[nNewArea] := cFile

      DelIniSection( "Areas", cDefIni )

      FOR i := 1 TO LEN( aAreaInis )
         IF .NOT. EMPTY( aAreaInis[i] )
            WritePProString( "Areas", ALLTRIM(STR( i, 3 )), ALLTRIM( aAreaInis[i] ), cDefIni )
         ENDIF
      NEXT

      MEMOWRIT( cDir + cFile, ;
         "[General]" + CRLF + ;
         "Title=New Area" + CRLF + ;
         "Width="  + ALLTRIM(STR( oGenVar:aAreaSizes[nAktArea,1], 5, IIF( nMeasure = 2, 2, 0 ) )) + CRLF + ;
         "Height=" + ALLTRIM(STR( oGenVar:aAreaSizes[nAktArea,2], 5, IIF( nMeasure = 2, 2, 0 ) )) )

      OpenFile( cDefIni )

      aWnd[nNewArea]:SetFocus()

      AreaProperties( nAktArea )

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: DeleteArea
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DeleteArea()

   IF MsgNoYes( GL("Do you really want to delete this area?"), GL("Select an option") ) = .T.

      DelFile( aVRDSave[nAktArea,1] )
      DelIniEntry( "Areas", ALLTRIM(STR( nAktArea, 5 )), cDefIni )

      OpenFile( cDefIni )

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: IniGetColor
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION IniColor( cColor, nDefColor )

   LOCAL nColor

   DEFAULT nDefColor := 0

   IF EMPTY( cColor )
      nColor := nDefColor
   ELSEIF AT( ",", cColor ) <> 0
      nColor := RGB( VAL(StrToken( cColor, 1, "," )), ;
                     VAL(StrToken( cColor, 2, "," )), ;
                     VAL(StrToken( cColor, 3, "," )) )
   ELSE
      nColor := VAL( cColor )
   ENDIF

RETURN ( nColor )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetDBField
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetDBField( oGet, lInsert )

   LOCAL oDlg, oLbx1, oLbx2, i, cDbase, cField, oBtn, aTemp, cGeneral, cUser
   LOCAL nShowExpr  := VAL( GetPvProfString( "General", "Expressions", "0", cDefIni ) )
   LOCAL nShowDBase := VAL( GetPvProfString( "General", "EditDatabases", "1", cDefIni ) )
   LOCAL cGenExpr   := ALLTRIM( cDefaultPath + GetPvProfString( "General", "GeneralExpressions", "", cDefIni ) )
   LOCAL cUserExpr  := ALLTRIM( cDefaultPath + GetPvProfString( "General", "UserExpressions", "", cDefIni ) )
   LOCAL nLen       := LEN( oGenVar:aDBFile )
   LOCAL aDbase     := {}
   LOCAL lOK        := .T.
   LOCAL lReturn    := .F.
   LOCAL aFields    := {}

   DEFAULT lInsert := .F.

   IF nShowDbase > 0

      FOR i := 1 TO nLen
         IF .NOT. EMPTY( oGenVar:aDBFile[i,2] )
            AADD( aDbase , ALLTRIM( oGenVar:aDBFile[i,2] ) )
            AADD( aFields, oGenVar:aDBFile[i,3] )
         ENDIF
      NEXT

   ENDIF

   IF nShowExpr > 0 .AND. lInsert = .F.
      AADD( aDbase, GL("Expressions") + ": " + GL("General") )
      AADD( aFields, GetExprFields( cGenExpr ) )
      cGeneral := aDbase[ LEN( aDbase ) ]
   ENDIF

   IF nShowExpr <> 2 .AND. lInsert = .F.
      AADD( aDbase, GL("Expressions") + ": " + GL("User defined") )
      AADD( aFields, GetExprFields( cUserExpr ) )
      cUser := aDbase[ LEN( aDbase ) ]
   ENDIF

   IF LEN( aDbase ) = 0
      MsgStop( GL("No databases defined."), GL("Stop!") )
      RETURN (.T.)
   ENDIF

   cDbase := aDbase[1]
   cField := aFields[1,1]
   //cField := oGenVar:aDBFile[1,3][1]

   DEFINE DIALOG oDlg NAME "DATABASEFIELDS" TITLE GL("Databases and Expressions")

   REDEFINE BUTTON oBtn PROMPT GL("&OK") ID 101 OF oDlg WHEN lOK ;
      ACTION ( lReturn := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE LISTBOX oLbx1 VAR cDbase ITEMS aDbase ID 201 OF oDlg ;
      ON CHANGE ( oLbx2:SetItems( aFields[oLbx1:GetPos()] ), oLbx2:Refresh(), ;
                  IIF( LEN( aFields[oLbx1:GetPos()] ) = 0, ;
                  ( oLbx2:Disable(), oBtn:Disable() ), ( oLbx2:Enable(), oBtn:Enable() ) ) ) ;
      ON DBLCLICK ( lReturn := .T. , oDlg:End() )

   REDEFINE LISTBOX oLbx2 VAR cField ITEMS aFields[oLbx1:GetPos()] ID 202 OF oDlg ;
      ON DBLCLICK ( lReturn := .T. , oDlg:End() )

   REDEFINE SAY PROMPT GL("Sources") ID 171 OF oDlg
   REDEFINE SAY PROMPT GL("Fields")  ID 172 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED

   IF lReturn = .T. .AND. .NOT. EMPTY( cField ) .AND. lInsert = .T.
      //oClpGeneral:SetText( "[" + ALLTRIM( cDbase ) + ":" + ALLTRIM( cField ) + "]" )
      oGet:Paste( "[" + ALLTRIM( cDbase ) + ":" + ALLTRIM( cField ) + "]" )
   ELSEIF lReturn = .T. .AND. .NOT. EMPTY( cField )
      IF ALLTRIM( cDbase ) == cGeneral
         oGet:VarPut( "[1]" + ALLTRIM( cField ) )
      ELSEIF ALLTRIM( cDbase ) == cUser
         oGet:VarPut( "[2]" + ALLTRIM( cField ) )
      ELSE
         oGet:VarPut( "[" + ALLTRIM( cDbase ) + ":" + ALLTRIM( cField ) + "]" )
      ENDIF
      oGet:Refresh()
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: GetExprFields
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetExprFields( cDatabase )

   LOCAL nSelect := SELECT()
   LOCAL aTemp   := {}

   DBUSEAREA( .T.,, cDatabase, "TEMPEXPR" )

   DO WHILE .NOT. EOF()
      IF .NOT. EMPTY( TEMPEXPR->NAME )
         AADD( aTemp, ALLTRIM( TEMPEXPR->NAME ) )
      ENDIF
      TEMPEXPR->(DBSKIP())
   ENDDO

   TEMPEXPR->(DBCLOSEAREA())
   SELECT( nSelect )

RETURN ( aTemp )


*-- FUNCTION -----------------------------------------------------------------
*         Name: OpenDatabases
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION OpenDatabases()

   LOCAL i, x, cEntry, cDbase, aFields, cFilter, cFieldNames, cFieldPos
   LOCAL nSelect     := SELECT()
   LOCAL cSeparator  := GetPvProfString( "Databases", "Separator" , ";", cDefIni )

   oGenVar:aDBFile := {}

   FOR i := 1 TO 12

      cEntry      := GetPvProfString( "Databases", ALLTRIM(STR( i, 3 )), "", cDefIni )
      cDbase      := ALLTRIM( GetField( cEntry, 1 ) )
      cFilter     := ""
      cFieldNames := ""
      cFieldPos   := ""

      aFields := {}

      IF FILE( cDbase ) = .T.

         IF cFileExt( cDBase ) = "DBF"

            DBUSEAREA( .T.,, cDbase, "DBTEMP", .T. )
            DBGOTOP()
            FOR x := 1 to DBTEMP->(FCOUNT())
              AADD( aFields, LOWER( FieldName( x ) ) )
            NEXT
            DBTEMP->(DBCLOSEAREA())
            SELECT( nSelect )

         ELSE

            cFilter     := ALLTRIM( GetField( cEntry, 3 ) )
            cFieldNames := ALLTRIM( GetField( cEntry, 4 ) )
            cFieldPos   := ALLTRIM( GetField( cEntry, 5 ) )

            IF EMPTY( cFieldNames )
               aFields := VRD_aToken( MEMOLINE( MEMOREAD( cDBase ), 10000, 1,,, .T. ), cSeparator )
            ELSE
               aFields := VRD_aToken( cFieldNames, ";" )
            ENDIF

            AEVAL( aFields, {|x,y| aFields[y] := ALLTRIM( x ) } )

         ENDIF

      ENDIF

      AADD( oGenVar:aDBFile, ;
         { PADR( cDbase, 200 ), ;
         LOWER( PADR( ALLTRIM( GetField( cEntry, 2 ) ), 30 ) ), ;
         aFields, ;
         cFilter, ;
         cFieldNames, ;
         cFieldPos } )

   NEXT

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: SaveDatabases
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SaveDatabases()

   AEVAL( oGenVar:aDBFile, {|x,y| ;
      WritePProString( "Databases", ALLTRIM(STR( y, 3 )), ;
                       ALLTRIM( x[1] ) + "|" + ;
                       ALLTRIM( x[2] ) + "|" + ;
                       ALLTRIM( x[4] ) + "|" + ;
                       ALLTRIM( x[5] ) + "|" + ;
                       ALLTRIM( x[6] ), cDefIni ) } )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: Databases
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION Databases( lTake )

   LOCAL oDlg, aDBGet1[12], aDBGet2[12]

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

   REDEFINE BTNBMP ID 301 OF oDlg RESOURCE "B_OPEN" NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 1,1], aDBGet1[ 1], aDBGet2[ 1] )
   REDEFINE BTNBMP ID 302 OF oDlg RESOURCE "B_OPEN" NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 2,1], aDBGet1[ 2], aDBGet2[ 2] )
   REDEFINE BTNBMP ID 303 OF oDlg RESOURCE "B_OPEN" NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 3,1], aDBGet1[ 3], aDBGet2[ 3] )
   REDEFINE BTNBMP ID 304 OF oDlg RESOURCE "B_OPEN" NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 4,1], aDBGet1[ 4], aDBGet2[ 4] )
   REDEFINE BTNBMP ID 305 OF oDlg RESOURCE "B_OPEN" NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 5,1], aDBGet1[ 5], aDBGet2[ 5] )
   REDEFINE BTNBMP ID 306 OF oDlg RESOURCE "B_OPEN" NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 6,1], aDBGet1[ 6], aDBGet2[ 6] )
   REDEFINE BTNBMP ID 307 OF oDlg RESOURCE "B_OPEN" NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 7,1], aDBGet1[ 7], aDBGet2[ 7] )
   REDEFINE BTNBMP ID 308 OF oDlg RESOURCE "B_OPEN" NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 8,1], aDBGet1[ 8], aDBGet2[ 8] )
   REDEFINE BTNBMP ID 309 OF oDlg RESOURCE "B_OPEN" NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[ 9,1], aDBGet1[ 9], aDBGet2[ 9] )
   REDEFINE BTNBMP ID 310 OF oDlg RESOURCE "B_OPEN" NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[10,1], aDBGet1[10], aDBGet2[10] )
   REDEFINE BTNBMP ID 311 OF oDlg RESOURCE "B_OPEN" NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[11,1], aDBGet1[11], aDBGet2[11] )
   REDEFINE BTNBMP ID 312 OF oDlg RESOURCE "B_OPEN" NOBORDER TOOLTIP GL("Open") ACTION GetDBase( oGenVar:aDBFile[12,1], aDBGet1[12], aDBGet2[12] )

   REDEFINE BTNBMP ID 321 OF oDlg RESOURCE "B_DEL" NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 1], aDBGet2[ 1] )
   REDEFINE BTNBMP ID 322 OF oDlg RESOURCE "B_DEL" NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 2], aDBGet2[ 2] )
   REDEFINE BTNBMP ID 323 OF oDlg RESOURCE "B_DEL" NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 3], aDBGet2[ 3] )
   REDEFINE BTNBMP ID 324 OF oDlg RESOURCE "B_DEL" NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 4], aDBGet2[ 4] )
   REDEFINE BTNBMP ID 325 OF oDlg RESOURCE "B_DEL" NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 5], aDBGet2[ 5] )
   REDEFINE BTNBMP ID 326 OF oDlg RESOURCE "B_DEL" NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 6], aDBGet2[ 6] )
   REDEFINE BTNBMP ID 327 OF oDlg RESOURCE "B_DEL" NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 7], aDBGet2[ 7] )
   REDEFINE BTNBMP ID 328 OF oDlg RESOURCE "B_DEL" NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 8], aDBGet2[ 8] )
   REDEFINE BTNBMP ID 329 OF oDlg RESOURCE "B_DEL" NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[ 9], aDBGet2[ 9] )
   REDEFINE BTNBMP ID 330 OF oDlg RESOURCE "B_DEL" NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[10], aDBGet2[10] )
   REDEFINE BTNBMP ID 331 OF oDlg RESOURCE "B_DEL" NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[11], aDBGet2[11] )
   REDEFINE BTNBMP ID 332 OF oDlg RESOURCE "B_DEL" NOBORDER TOOLTIP GL("Delete") ACTION DelDBase( aDBGet1[12], aDBGet2[12] )

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION oDlg:End()

   ACTIVATE DIALOG oDlg CENTER

   SaveDatabases()
   OpenDatabases()

RETURN ( NIL )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetDBase
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetDBase( cOldFile, oGet1, oGet2 )

   LOCAL cFile := GetFile( GL("Databases") + " (DBF,TXT,XML)" + "|*.DBF;*.TXT;*.XML|" + ;
                           "dBase (*.dbf)| *.dbf|" + ;
                           GL("Textfile") + "(*.txt)| *.txt|" + ;
                           "XML (*.xml)| *.xml|" + ;
                           GL("All Files") + "(*.*)| *.*", ;
                           GL("Open Database"), 1 )

   LOCAL cNewFile := ALLTRIM( IIF( EMPTY( cFile ), cOldFile, cFile ) )

   oGet1:VarPut( PADR( cNewFile, 200 ) )
   oGet1:Refresh()

   oGet2:VarPut( LOWER( PADR( cFileNoExt( cNewFile ), 30 ) ) )
   oGet2:Refresh()

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: DelDBase
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DelDBase( oGet1, oGet2 )

   oGet1:VarPut( SPACE( 200 ) )
   oGet2:VarPut( SPACE( 30 ) )
   oGet1:Refresh()
   oGet2:Refresh()

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_MsgRun
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_MsgRun( cCaption, cTitle, bAction )

   LOCAL oDlg, nWidth, oFont

   DEFINE FONT oFont NAME "Ms Sans Serif" SIZE 0, -8

   DEFAULT cCaption := "Please, wait...", cTitle := "", bAction  := { || Inkey( 1 ) }

   IF EMPTY( cTitle )
      DEFINE DIALOG oDlg ;
         FROM 0,0 TO 3, Len( cCaption ) + 4 ;
         STYLE nOr( DS_MODALFRAME, WS_POPUP ) FONT oFont
   ELSE
      DEFINE DIALOG oDlg ;
         FROM 0,0 TO 4, Max( Len( cCaption ), Len( cTitle ) ) + 4 ;
         TITLE cTitle ;
         STYLE DS_MODALFRAME FONT oFont
   ENDIF

   oDlg:bStart := { || Eval( bAction, oDlg ), oDlg:End(), SysRefresh() }
   oDlg:cMsg   := cCaption

   nWidth := oDlg:nRight - oDlg:nLeft

   ACTIVATE DIALOG oDlg CENTER ;
      ON PAINT oDlg:Say( 1, 0, xPadC( oDlg:cMsg, nWidth ) )

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: CreateNewFile
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CreateNewFile( cFile )

   LOCAL cTmpFile := cTempFile() + ".TMP"
   LOCAL hFile    := lCreat( cTmpFile, 0 )

   lClose( hFile )
   CopyFile( cTmpFile, cFile )
   DelFile( cTmpFile )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: CopyFile
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CopyFile( cSource, cTarget )

   COPY FILE &cSource TO &cTarget

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetSysFont
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetSysFont()

   do case
   case !IsWinNt() .and. !IsWin95()              // Win 3.1
      RETURN "System"
   case IsWin2000()     // Win2000
      RETURN "Ms Sans Serif" //"SysTahoma"
   endcase

RETURN "Ms Sans Serif"                           // Resto (Win NT, 95, 98)


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetDivisible
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetDivisible( nNr, nDivisor, lPrevious )

   LOCAL i

   DEFAULT lPrevious := .F.

   FOR i := 1 TO nDivisor
      IF IsDivisible( nNr, nDivisor ) = .T.
         EXIT
      ELSE
         IIF( lPrevious, --nNr, ++nNr )
      ENDIF
   NEXT

RETURN ( nNr )


*-- FUNCTION -----------------------------------------------------------------
* Name........: IsDivisible
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION IsDivisible( nNr, nDivisor )

   LOCAL lReturn := .F.

   IF nNr / nDivisor = INT( nNr / nDivisor )
      lReturn := .T.
   ENDIF

RETURN ( lReturn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: ADelete( <aArray>, <nIndex> )

* Beschreibung: ADelete() löscht das Array-Element an der Stelle <nIndex> und
*               verkleinert das Array um eins.
* Rückgabewert: Das geänderte Array
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ADelete( aArray, nIndex )

   LOCAL i
   LOCAL aNewArray := {}

   ADEL( aArray, nIndex )

   FOR i := 1 TO LEN( aArray ) - 1
      AADD( aNewArray, aArray[i] )
   NEXT

RETURN ( aNewArray )


*-- FUNCTION -----------------------------------------------------------------
* Name........: StrAtNum( <cSearch>, <cString>, <nCount> )
* Beschreibung: n-tes Auftreten einer Zeichenfolge in Strings ermitteln
*               StrAtNum() sucht das <nCount>-te Auftreten von <cSearch>
*               in <cString>. War die Suche erfolgreich, wird die Position
*               innerhalb <cString> zurückgegeben, andernfalls 0.
* Rückgabewert: die Position des <nCount>-ten Auftretens von <cSearch>.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION StrAtNum( cSearch, cString, nNr )

   cString := STRTRAN( cString, cSearch, REPLICATE( "@", LEN( cSearch ) ),, nNr - 1 )

RETURN AT( cSearch, cString )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GoBottom
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GoBottom()

  GO BOTTOM

RETURN ! Eof()


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetFile
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetFile( cFileMask, cTitle, nDefaultMask, cInitDir, lSave, nFlags )

   LOCAL cTmpPath := CheckPath( GetPvProfString( "General", "DefaultPath", "", cGeneralIni ) )

   IF .NOT. EMPTY( cTmpPath )
      cInitDir := cTmpPath
   ENDIF

   DEFAULT cInitDir := cFilePath( GetModuleFileName( GetInstance() ) )

RETURN cGetFile32( cFileMask, cTitle, nDefaultMask, cInitDir, lSave, nFlags )


*-- FUNCTION -----------------------------------------------------------------
* Name........: IsIntersectRect
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION IsIntersectRect( aRect1, aBoxRect )

   LOCAL aSect
   LOCAL lReturn := .F.

   IF aBoxRect[1] > aBoxRect[3]
      aBoxRect := { aBoxRect[3], aBoxRect[2], aBoxRect[1], aBoxRect[4] }
   ENDIF
   IF aBoxRect[2] > aBoxRect[4]
      aBoxRect := { aBoxRect[1], aBoxRect[4], aBoxRect[3], aBoxRect[2] }
   ENDIF

   aSect := { MAX( aRect1[1], aBoxRect[1] ), ;
              MAX( aRect1[2], aBoxRect[2] ), ;
              MIN( aRect1[3], aBoxRect[3] ), ;
              MIN( aRect1[4], aBoxRect[4] ) }

   IF IsPointInRect( { aSect[1], aSect[2] }, aRect1 ) .AND. ;
      IsPointInRect( { aSect[1], aSect[2] }, aBoxRect ) .OR. ;
      IsPointInRect( { aSect[3], aSect[4] }, aRect1 ) .AND. ;
      IsPointInRect( { aSect[3], aSect[4] }, aBoxRect )
      lReturn := .T.
   ENDIF

RETURN ( lReturn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: IsPointInRect
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION IsPointInRect( aPoint, aRect )

   LOCAL lReturn := .F.

   IF aRect[1] <= aPoint[1] .AND. aRect[3] >= aPoint[1] .AND. ;
      aRect[2] <= aPoint[2] .AND. aRect[4] >= aPoint[2]
      lReturn := .T.
   ENDIF

RETURN ( lReturn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetSourceToolTip
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetSourceToolTip( cSourceCode )

   LOCAL cText := GL("Formula")

   IF EMPTY( cSourceCode ) = .F.
      cText += ":" + CRLF
      IF LEN( cSourceCode ) >= 200
         cText += SUBSTR( cSourceCode,   1, 100 ) + CRLF + ;
                  SUBSTR( cSourceCode, 100, 100 ) + CRLF + ;
                  SUBSTR( cSourceCode, 200 )
      ELSEIF LEN( cSourceCode ) >= 100
         cText += SUBSTR( cSourceCode,   1, 100 ) + CRLF + ;
                  SUBSTR( cSourceCode, 100 )
      ELSE
         cText += cSourceCode
      ENDIF
   ENDIF

RETURN ( cText )


*-- FUNCTION -----------------------------------------------------------------
* Name........: AddToRecentDocs
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION AddToRecentDocs( cFullPathFile )

   LOCAL hDLL, uResult, cFarProc

   hDLL := LoadLib32( "Shell32.dll" )

   IF ABS( hDLL ) <= 32

      MsgAlert( "Error code: " + LTrim( Str( hDLL ) ) + ;
      " loading " + "Shell32.dll" )

   ELSE

      cFarProc := GetProcAdd( hDLL, "SHAddToRecentDocs", .T., 7, 7, 8 )
      uResult  := FWCallDLL( cFarProc, 2, cFullPathFile + Chr(0) )
      FreeLibrary( hDLL )

   ENDIF

RETURN uResult


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetBarCodes
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetBarCodes()

   LOCAL aBarcodes := { "Code 39", ;
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

RETURN ( aBarcodes )


*-- FUNCTION -----------------------------------------------------------------
* Name........: MainCaption
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION MainCaption()

   LOCAL cReturn    := ""
   LOCAL cVersion   := ""
   LOCAL cMainTitle := ""
   LOCAL cUserApp   := ALLTRIM( GetPvProfString( "General", "MainAppTitle", "", cGeneralIni ) )

   IF lBeta = .T.
      cVersion := " - Beta Version"
   ELSEIF lDemo = .T.
      cVersion := " - Full version" // " - Unregistered Demo Version" FiveTech
   ENDIF

   IF .NOT. EMPTY( cDefIni )
      cMainTitle := ALLTRIM( GetPvProfString( "General", "Title", "", cDefIni ) )
   ENDIF

   cReturn := IIF( EMPTY( cUserApp ), "EasyReport", cUserApp ) + ;
              cVersion + ;
              IIF( EMPTY(cMainTitle), "", " - " + cMainTitle )

RETURN ( cReturn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: Expressions
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION Expressions( lTake, cAltText )

   LOCAL i, oDlg, oFld, oBrw, oBrw2, oBrw3, oFont, cReturn, oSay1, nTyp, oGet1
   LOCAL oBtn1, aBtn[3], aGet[5], cName
   LOCAL nAltSel    := SELECT()
   LOCAL nShowExpr  := VAL( GetPvProfString( "General", "Expressions", "0", cDefIni ) )
   LOCAL cGenExpr   := ALLTRIM( cDefaultPath + GetPvProfString( "General", "GeneralExpressions", "", cDefIni ) )
   LOCAL cUserExpr  := ALLTRIM( cDefaultPath + GetPvProfString( "General", "UserExpressions", "", cDefIni ) )
   LOCAL aUndo      := {}
   LOCAL cErrorFile := ""
   //LOCAL aRDD      := { "DBFNTX", "COMIX", "DBFCDX" }

   DEFAULT cAltText := ""
   DEFAULT lTake    := .F.

   IF FILE( VRD_LF2SF( cGenExpr ) ) = .F.
      cErrorFile += cGenExpr + CRLF
   ENDIF
   IF FILE( VRD_LF2SF( cUserExpr ) ) = .F.
      cErrorFile += cUserExpr + CRLF
   ENDIF

   IF .NOT. EMPTY( cErrorFile )
      MsgStop( GL("This file(s) could no be found:") + CRLF + CRLF + cErrorFile, GL("Stop!") )
      RETURN( cAltText )
   ENDIF

   DEFINE FONT oFont NAME "Arial" SIZE 0, -12

   DEFINE DIALOG oDlg NAME "EXPRESSIONS" TITLE GL("Expressions")

   REDEFINE SAY oSay1 ID 170 OF oDlg ;
      PROMPT GL("Please doubleclick an expression to take it over.")

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION oDlg:End()

   IF nShowExpr = 2
      REDEFINE FOLDER oFld ID 110 OF oDlg ;
         PROMPT " " + GL("General") + " " ;
         DIALOGS "EXPRESS_FOLDER1"
   ELSE
      REDEFINE FOLDER oFld ID 110 OF oDlg ;
         PROMPT " " + GL("General") + " ", ;
                " " + GL("User defined") + " " ;
         DIALOGS "EXPRESS_FOLDER1", ;
                 "EXPRESS_FOLDER2"
   ENDIF

   SELECT 0
   USE ( VRD_LF2SF( cGenExpr ) ) ALIAS "GENEXPR"

   REDEFINE LISTBOX oBrw ;
      FIELDS GENEXPR->NAME, GENEXPR->INFO ;
      FIELDSIZES 180, 400 ;
      HEADERS " " + GL("Name"), " " + GL("Description") ;
      ID 301 OF oFld:aDialogs[1] FONT oFont ;
      ON LEFT DBLCLICK ( cReturn := GENEXPR->NAME, nTyp := 1, oDlg:End() )

   oBrw:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, ;
                     EVAL( {|| cReturn := GENEXPR->NAME, nTyp := 1, oDlg:End() } ), .T. ) }

   IF nShowExpr = 1

   i := 2
   SELECT 0
   USE ( VRD_LF2SF( cUserExpr ) ) ALIAS "USEREXPR"

   REDEFINE LISTBOX oBrw2 ;
      FIELDS USEREXPR->NAME, USEREXPR->INFO ;
      FIELDSIZES 220, 400 ;
      HEADERS " " + GL("Name"), " " + GL("Description") ;
      ID 301 OF oFld:aDialogs[i] FONT oFont ;
      ON CHANGE ( oDlg:Update(), aUndo := {} ) ;
      ON LEFT DBLCLICK ( cReturn := USEREXPR->NAME, nTyp := 2, oDlg:End() )

   oBrw2:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, ;
                      EVAL( {|| cReturn := USEREXPR->NAME, nTyp := 2, oDlg:End() } ), .T. ) }

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

   ENDIF

   ACTIVATE DIALOG oDlg CENTER ;
      ON INIT IIF( lTake = .F., oSay1:Hide, .T. )

   IF .NOT. EMPTY( cReturn )
      cReturn := "[" + ALLTRIM(STR( nTyp , 1 )) + "]" + ALLTRIM( cReturn )
   ELSEIF .NOT. EMPTY( cAltText )
      cReturn := cAltText
   ENDIF

   GENEXPR->(DBCLOSEAREA())

   IF nShowExpr = 1
      USEREXPR->(DBCLOSEAREA())
   ENDIF

   SELECT( nAltSel )
   oFont:End()
   aUndo := {}

RETURN ( cReturn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: CheckExpression
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CheckExpression( cText )

   LOCAL lReturn, xReturn, oScript

   oScript := TScript():New( "FUNCTION TEST()" + CRLF + cText + CRLF + "RETURN" )

   oScript:Compile()

   IF EMPTY( oScript:cError )
      MsgWait( GL("Correct expression"), GL("Check"), 1.5 )
      lReturn := .T.
   ELSE
      MsgStop( GL("Incorrect expression"), GL("Check") )
      lReturn := .F.
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: DBPack
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DBPack()

   PACK

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: DBReplace
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DBReplace( cReplFeld, xAusdruck )

   REPLACE &cReplFeld with xAusdruck

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: CopyToExpress
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CopyToExpress( cText, oGet, aUndo )

   AADD( aUndo, oGet:cText )

   oGet:SetFocus()
   oGet:Paste( cText )
   oGet:SetPos( oGet:nPos + LEN( cText ) )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: UndoExpression
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION UnDoExpression( oGet, aUndo )

   IF Len( aUndo ) > 0
      IF .NOT. EMPTY( ATAIL( aUndo ) )
         oGet:cText( ATAIL( aUndo ) )
         oGet:Refresh()
         ASIZE( aUndo, Len( aUndo ) - 1 )
      ENDIF
   ENDIF

   oGet:SetFocus()

RETURN ( aUndo )


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRDLogo
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRDLogo()

   LOCAL oDlg, oSay
   LOCAL aFonts    := ARRAY(2)
   LOCAL nInterval := 1

   DEFINE FONT aFonts[1] NAME "Ms Sans Serif" SIZE 0, -14
   DEFINE FONT aFonts[2] NAME "Ms Sans Serif" SIZE 0, -6

   DEFINE TIMER oTimer INTERVAL 1000 OF oDlg ;
      ACTION IIF( CheckTimer( nInterval++, oSay ) = .T., EndMsgLogo( oDlg, aFonts ), )

   DEFINE DIALOG oDlg NAME "MSGLOGO" COLOR 0, RGB( 255, 255, 255 )

   REDEFINE SAY PROMPT GetLicLanguage() ID 201 OF oDlg FONT aFonts[1] COLOR 0, RGB( 255, 255, 255 )
   REDEFINE SAY PROMPT GetRegistInfos() ID 202 OF oDlg FONT aFonts[1] COLOR 0, RGB( 255, 255, 255 )

   REDEFINE BITMAP ID 301 OF oDlg RESOURCE "LOGO"

   REDEFINE SAY PROMPT "copyright Sodtalbers+Partner, " + oGenVar:cCopyright + " - www.reportdesigner.info " ;
      ID 203 OF oDlg FONT aFonts[2] COLOR 0, RGB( 255, 255, 255 )

   REDEFINE SAY oSay PROMPT ;
      IIF( lDemo = .T., "Please wait: 20 Sec.", "") ID 204 OF oDlg FONT aFonts[2] ;
      COLOR 0, RGB( 255, 255, 255 )

   ACTIVATE DIALOG oDlg CENTER ;
      ON INIT oTimer:Activate() ;
      VALID IF( GETKEYSTATE( VK_ESCAPE ) .AND. lDemo = .T. , .F., .T. )

   aFonts[1]:End()
   aFonts[2]:End()

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: EndMsgLogo
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EndMsgLogo( oDlg, aFonts )

   LOCAL nInterval := 0

   oDlg:End()
   AEVAL( aFonts, {| oFont| oFont:End() } )
   oTimer:End()
   SysRefresh()
   MEMORY(-1)

   //Demo mode: App läuft nur 3 Minuten
   IF lDemo = .T.
      DEFINE TIMER oTimer INTERVAL 1000 OF oMainWnd ;
         ACTION ( TimerRunOut( ++nInterval ) )
      ACTIVATE TIMER oTimer
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: TimerRunOut
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION TimerRunOut( nInterval )

   IF nInterval = 300
      MsgStop( "Demo version time run out (5 minutes)!" )
      oTimer:End()
      QUIT
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: CheckTimer
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CheckTimer( nInterval, oSay )

    LOCAL lReturn := .F.

    IF lDemo = .T.
       oSay:SetText( "Please wait: " + ALLTRIM(STR( 20 - nInterval, 3)) + " Sec." )
    ENDIF

    IF lDemo = .T. .AND. nInterval = 20 .OR. lDemo = .F. .AND. nInterval = 3
      lReturn := .T.
    ENDIF

RETURN ( lReturn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRDAbout
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRDAbout()

   LOCAL oDlg, oFont, cVersion := ""
   LOCAL nClrBack := RGB( 255, 255, 255 )

   IIF( lProfi   , cVersion := "Professional", )
   IIF( lPersonal, cVersion := "Personal"    , )
   IIF( lStandard, cVersion := "Standard"    , )

   DEFINE FONT oFont  NAME "Ms Sans Serif" SIZE 0, -14

   DEFINE DIALOG oDlg NAME "MSGINFO" TITLE GL("About") COLOR 0, nClrBack

   REDEFINE SAY PROMPT GL("Release") + " " + oGenVar:cRelease + " - " + cVersion ;
      ID 204 OF oDlg FONT oFont COLOR 0, nClrBack

   REDEFINE SAY PROMPT GetLicLanguage() ID 201 OF oDlg FONT oFont COLOR 0, nClrBack
   REDEFINE SAY PROMPT GetRegistInfos() ID 202 OF oDlg FONT oFont COLOR 0, nClrBack

   REDEFINE BITMAP ID 301 OF oDlg RESOURCE "LOGO"

   REDEFINE SAY PROMPT "copyright Timm Sodtalbers, " + oGenVar:cCopyright + + ;
                       "     Sodtalbers+Partner - Ihlow - Germany" ;
      ID 203 OF oDlg COLOR 0, nClrBack

   REDEFINE BUTTON ID 101 OF oDlg ACTION oDlg:End()
   REDEFINE BUTTON ID 102 OF oDlg ACTION ;
      ShellExecute( 0, "Open", "http://www.reportdesigner.info", Nil, Nil, 1 )

   ACTIVATE DIALOG oDlg CENTER

   oFont:End()

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRDBeta
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION BetaVersion()

   LOCAL oDlg, oFont
   LOCAL nClrBack := RGB( 255, 255, 255 )

   DEFINE FONT oFont  NAME "Ms Sans Serif" SIZE 0, -14

   DEFINE DIALOG oDlg NAME "MSGBETA" COLOR 0, nClrBack

   REDEFINE SAY PROMPT "- BETA VERSION -" ID 204 OF oDlg FONT oFont COLOR 0, nClrBack

   REDEFINE SAY PROMPT "This is a beta version of EasyReport. Please let me" ID 201 OF oDlg FONT oFont COLOR 0, nClrBack
   REDEFINE SAY PROMPT "know if you have any problems or suggestions."       ID 202 OF oDlg FONT oFont COLOR 0, nClrBack

   REDEFINE BITMAP ID 301 OF oDlg RESOURCE "LOGO"

   REDEFINE BUTTON ID 101 OF oDlg ACTION oDlg:End()

   ACTIVATE DIALOG oDlg CENTER

   oFont:End()

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: QuietRegCheck
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION QuietRegCheck()

   LOCAL nSerial := GetSerialHD()
   LOCAL cSerial := IIF( nSerial = 0, "8"+"2"+"2"+"7"+"3"+"6"+"5"+"1", ALLTRIM( STR( ABS( nSerial ), 20 ) ) )
   LOCAL cRegist := PADR( GetPvProfString( "General", "RegistKey", "", cGeneralIni ), 40 )

RETURN CheckRegist( cSerial, cRegist )


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRDMsgPersonal
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRDMsgPersonal()

   LOCAL oDlg, oFont, oFont2
   LOCAL lOK          := .T. // .F.
   LOCAL lTestVersion := .F.
   LOCAL nClr1        := RGB( 128, 128, 128 )
   LOCAL nClrBack     := RGB( 255, 255, 255 )
   LOCAL nSerial      := GetSerialHD()
   LOCAL cSerial      := IIF( nSerial = 0, "8"+"2"+"2"+"7"+"3"+"6"+"5"+"1", ALLTRIM( STR( ABS( nSerial ), 20 ) ) )
   LOCAL cRegist      := PADR( GetPvProfString( "General", "RegistKey", "", cGeneralIni ), 40 )
   LOCAL cCompany     := PADR( GetPvProfString( "General", "Company"  , "", cGeneralIni ), 100 )
   LOCAL cUser        := PADR( GetPvProfString( "General", "User"     , "", cGeneralIni ), 100 )
   LOCAL cVersion     := IIF( lStandard, "Standard", "Personal" )

   DEFINE FONT oFont  NAME "Ms Sans Serif" SIZE 0, -14
   DEFINE FONT oFont2 NAME "Ms Sans Serif" SIZE 0, -6

   DEFINE DIALOG oDlg NAME "MSGPERSONAL" ;
      TITLE "EasyReport " + cVersion COLOR 0, nClrBack

   REDEFINE BITMAP ID 301 OF oDlg RESOURCE "LOGO"

   REDEFINE GET cSerial  ID 401 OF oDlg READONLY MEMO COLOR 0, nClrBack FONT oFont
   REDEFINE GET cCompany ID 402 OF oDlg COLOR 0, nClrBack FONT oFont
   REDEFINE GET cUser    ID 403 OF oDlg COLOR 0, nClrBack FONT oFont
   REDEFINE GET cRegist  ID 404 OF oDlg COLOR 0, nClrBack FONT oFont

   REDEFINE SAY PROMPT "Please send us the serial number, company and" + CRLF + ;
                       "user name. We will give you the free registration" + CRLF + ;
                       "key as soon as possible." ;
      ID 201 OF oDlg COLOR RGB( 0, 0, 128 ), nClrBack //FONT oFont

   REDEFINE SAY PROMPT "Using EasyReport " + cVersion + " the Visual Report Designer will only work on one machine." + CRLF + ;
                       "With EasyReport Professional you have the possibility to pass the Visual Report" + CRLF + ;
                       "Designer to your customers without paying anything extra (royalty free)." ;
      ID 203 OF oDlg COLOR 0, nClrBack

   REDEFINE BUTTON ID 103 OF oDlg ACTION SendRegInfos( cSerial, cCompany, cUser, cVersion ) ;
      WHEN .NOT. EMPTY( cCompany ) .OR. .NOT. EMPTY( cUser )

   REDEFINE SAY PROMPT "Copyright"        + CRLF + ;
                       oGenVar:cCopyright + CRLF + ;
                       "Timm Sodtalbers"  + CRLF + ;
                       "Sodtalbers+Partner" ;
      ID 202 OF oDlg COLOR nClr1, nClrBack FONT oFont2

   REDEFINE SAY ID 171 OF oDlg COLOR 0, nClrBack FONT oFont
   REDEFINE SAY ID 172 OF oDlg COLOR 0, nClrBack FONT oFont
   REDEFINE SAY ID 173 OF oDlg COLOR 0, nClrBack FONT oFont
   REDEFINE SAY ID 174 OF oDlg COLOR 0, nClrBack FONT oFont

   REDEFINE BUTTON ID 101 OF oDlg ;
      ACTION ( lOK := .T. /* := CheckRegist( cSerial, cRegist ) */, oDlg:End() )
   REDEFINE BUTTON ID 104 OF oDlg ACTION ( lTestVersion := .T., oDlg:End() )
   REDEFINE BUTTON ID 102 OF oDlg ACTION ;
      ShellExecute( 0, "Open", "http://www.reportdesigner.info", Nil, Nil, 1 )

   ACTIVATE DIALOG oDlg CENTER

   WritePProString( "General", "Company", ALLTRIM( cCompany ), cGeneralIni )
   WritePProString( "General", "User"   , ALLTRIM( cUser )   , cGeneralIni )

   IF lOK = .F. .AND. lTestVersion = .F.
      MsgInfo( "The registration key is not valid!" + CRLF + CRLF + ;
               "EasyReport starts in demo mode." )
      WritePProString( "General", "RegistKey", "", cGeneralIni )
   ENDIF

   IF lOK = .F.
      lDemo  := .T.
      lProfi := .T.
      oBar:AEvalWhen()
      oMainWnd:cTitle := MainCaption()
      oMainWnd:SetMenu( BuildMenu() )
      VRDLogo()
   ENDIF

   oFont:End()
   oFont2:End()

RETURN ( lOK )


*-- FUNCTION -----------------------------------------------------------------
* Name........: CheckRegist
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CheckRegist( cSerial, cRegist )

   LOCAL lOK := .F.

   IF ALLTRIM( cRegist ) == GetRegistKey( cSerial )
      WritePProString( "General", "RegistKey", ALLTRIM( cRegist ) , cGeneralIni )
      lOK := .T.
   ENDIF

RETURN ( lOK )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetRegistKey
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetRegistKey( cSerial )

   LOCAL cReg := ALLTRIM( STR( INT( ( VAL( ALLTRIM( cSerial ) ) * 167 ) * 4.12344 ), 30 ) )

   cReg := SUBSTR( cReg + ALLTRIM( STR( 47348147489715610655, 30 ) ), 1, 12 )

   cReg := CHR( VAL( SUBSTR( cReg, 8, 1 ) ) + 74 ) + ;
           CHR( VAL( SUBSTR( cReg, 4, 1 ) ) + 68 ) + ;
           CHR( VAL( SUBSTR( cReg, 2, 1 ) ) + 70 ) + ;
           CHR( VAL( SUBSTR( cReg, 6, 1 ) ) + 66 ) + ;
           SUBSTR( cReg, 5 )

RETURN ( cReg )


*-- FUNCTION -----------------------------------------------------------------
* Name........: SendRegInfos
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SendRegInfos( cSerial, cCompany, cUser, cVersion )

   LOCAL i, oMail

   DEFINE MAIL oMail SUBJECT "EasyReport " + cVersion + " Registration" ;
                     TEXT "      Company: " + cCompany + CRLF + ;
                          "    User name: " + cUser    + CRLF + ;
                          "Serial number: " + cSerial  + CRLF ;
                     FROM USER ;
                     TO "regist@reportdesigner.info"

   oMail:Activate()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetSerialHD
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetSerialHD( cDrive )

   LOCAL cLabel      := Space(32)
   LOCAL cFileSystem := Space(32)
   LOCAL nSerial     := 0
   LOCAL nMaxComp    := 0
   LOCAL nFlags      := 0

   DEFAULT cDrive := "C:\"

   GetVolInfo( cDrive, @cLabel, Len( cLabel ), @nSerial, @nMaxComp, @nFlags, ;
               @cFileSystem, Len( cFileSystem ) )

RETURN nSerial

DLL32 Function GetVolInfo( sDrive          AS STRING, ;
                           sVolName        AS STRING, ;
                           lVolSize        AS LONG  , ;
                           @lVolSerial     AS PTR   , ;
                           @lMaxCompLength AS PTR   , ;
                           @lFileSystFlags AS PTR   , ;
                           @sFileSystName  AS STRING, ;
                           lFileSystSize   AS LONG ) ;
               AS LONG PASCAL ;
               FROM "GetVolumeInformationA" ;
               LIB  "kernel32.dll"


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetRegistInfos
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetRegistInfos()

   LOCAL cRegText := ""
   LOCAL cRegFile := IIF( FILE( ".\VRD.LIZ" ), ".\VRD.LIZ", ;
                          "..\VDESIGN.PRG\LICENCE\VRD.LIZ" )

   cRegText := DeCrypt( MEMOREAD( cRegFile ), "A"+"N"+"I"+"G"+"E"+"R" )

   IF lPersonal = .T. .OR. lStandard = .T.
      cRegText := "S" +"o"+"d"+"t"+"a"+"l"+"b"+"e"+"r"+"s" + "+Partner"
   ELSEIF SUBSTR( cRegText, 11, 3 ) <> "209" .AND. lBeta = .F.
      lDemo := .T.
      cRegText := "U"+"n"+"r"+"e"+"g"+"i"+"s"+"t"+"e"+"r"+"e"+"d "+"D"+"e"+"m"+"o "+"V"+"e"+"r"+"s"+"i"+"o"+"n"
   ELSEIF SUBSTR( cRegText, 11, 3 ) <> "209" .AND. lBeta = .T.
      lDemo := .T.
      cRegText := "beta version"
   ELSEIF lBeta = .F.
      IF SUBSTR( cRegText, 14, 7 ) = "Ghze646" .OR. SUBSTR( cRegText, 14, 7 ) = "fSDFh23"
         IF SUBSTR( cRegText, 14, 7 ) <> "Ghze646"
            lProfi := .F.
         ENDIF
         cRegText := ALLTRIM( SUBSTR( cRegText, 21, 10 ) + ;
                              SUBSTR( cRegText, 41, 10 ) + ;
                              SUBSTR( cRegText, 61, 10 ) + ;
                              SUBSTR( cRegText, 81, 10 ) + ;
                              SUBSTR( cRegText, 101, 10 ) )
      ENDIF
   ENDIF

   lDemo = .F. // FiveTech
   cRegText = "FiveTech Software full version" // FiveTech

RETURN ( cRegText )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetLicLanguage
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetLicLanguage()

   LOCAL cText     := ""
   LOCAL nLanguage := VAL( GetPvProfString( "General", "Language", "1", cGeneralIni ) )

   IF lBeta = .F.
      IF nLanguage = 2
         cText := "Lizensiert für: "
      ELSEIF nLanguage = 3
         cText := "In licenza a: "
      ELSEIF nLanguage = 4
         cText := "Licenciado a: "
      ELSE
         cText := "Licenced to: "
      ENDIF
   ENDIF

RETURN ( cText )


*-- FUNCTION -----------------------------------------------------------------
* Name........: EditLanguage
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EditLanguage()

   LOCAL oDlg, oBrw
   LOCAL aHeader    := ARRAY(20)
   LOCAL aCol       := ARRAY(20)
   LOCAL nVorColor  := RGB( 0, 0, 0 )
   LOCAL nHinColor  := RGB( 224, 239, 223 )
   LOCAL nHinColor2 := RGB( 223, 231, 224 )
   LOCAL nHinColor3 := RGB( 235, 234, 203 )
   LOCAL nHVorCol   := RGB( 0, 0, 0 )
   LOCAL nSelect    := SELECT()

   DBUSEAREA( .T.,, "LANGUAGE.DBF",, .F. )

   DEFINE DIALOG oDlg NAME "EDITLANGUAGE" TITLE GL("Language Database")

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION oDlg:End()

   REDEFINE SAY PROMPT GL("Please restart the programm to activate the changes.") ;
      ID 170 OF oDLg

   SELECT LANGUAGE
   SET ORDER TO 1
   GO TOP

   REDEFINE LISTBOX oBrw ;
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
         HEADERS " " + GetPvProfString( "Languages", "1", "Language 1", cGeneralIni ), ;
                 " " + GetPvProfString( "Languages", "2", "Language 2", cGeneralIni ), ;
                 " " + GetPvProfString( "Languages", "3", "Language 3", cGeneralIni ), ;
                 " " + GetPvProfString( "Languages", "4", "Language 4", cGeneralIni ), ;
                 " " + GetPvProfString( "Languages", "5", "Language 5", cGeneralIni ), ;
                 " " + GetPvProfString( "Languages", "6", "Language 6", cGeneralIni ), ;
                 " " + GetPvProfString( "Languages", "7", "Language 7", cGeneralIni ), ;
                 " " + GetPvProfString( "Languages", "8", "Language 8", cGeneralIni ), ;
                 " " + GetPvProfString( "Languages", "9", "Language 9", cGeneralIni ) ;
         ID 301 OF oDlg ;
         ON LEFT DBLCLICK GetLanguage()

   oBrw:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, GetLanguage(), .T. ) }

   ACTIVATE DIALOG oDlg CENTERED

   LANGUAGE->(DBCLOSEAREA())
   SELECT( nSelect )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetLanguage
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetLanguage()

   LOCAL oDlg

   LANGUAGE->(RLOCK())

   DEFINE DIALOG oDlg NAME "GETLANGUAGE"

   REDEFINE BUTTON ID 101 OF oDlg ACTION oDlg:End()

   REDEFINE SAY PROMPT GetPvProfString( "Languages", "1", "Language 1", cGeneralIni ) + ":" ID 151 OF oDlg
   REDEFINE SAY PROMPT GetPvProfString( "Languages", "2", "Language 2", cGeneralIni ) + ":" ID 152 OF oDlg
   REDEFINE SAY PROMPT GetPvProfString( "Languages", "3", "Language 3", cGeneralIni ) + ":" ID 153 OF oDlg
   REDEFINE SAY PROMPT GetPvProfString( "Languages", "4", "Language 4", cGeneralIni ) + ":" ID 154 OF oDlg
   REDEFINE SAY PROMPT GetPvProfString( "Languages", "5", "Language 5", cGeneralIni ) + ":" ID 155 OF oDlg
   REDEFINE SAY PROMPT GetPvProfString( "Languages", "6", "Language 6", cGeneralIni ) + ":" ID 156 OF oDlg
   REDEFINE SAY PROMPT GetPvProfString( "Languages", "7", "Language 7", cGeneralIni ) + ":" ID 157 OF oDlg
   REDEFINE SAY PROMPT GetPvProfString( "Languages", "8", "Language 8", cGeneralIni ) + ":" ID 158 OF oDlg
   REDEFINE SAY PROMPT GetPvProfString( "Languages", "9", "Language 9", cGeneralIni ) + ":" ID 159 OF oDlg

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

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetPixel
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetPixel( nValue )

   IF Upper( ValType( nMeasure ) ) = "L"
      nMeasure := 1
   ENDIF

   IF nMeasure = 1
      //mm
      nValue := nValue * 3
   ELSEIF nMeasure = 2
      //Inch
      nValue := nValue * 100
   ENDIF

RETURN ( nValue )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetCmInch
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetCmInch( nValue )

   IF nMeasure = 1
      //mm
      nValue := ROUND( nValue / 3, 0 )
   ELSEIF nMeasure = 2
      //Inch
      nValue := ROUND( nValue / 100, 2 )
   ENDIF

RETURN ( nValue )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetField
* Beschreibung:
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetField( cString, nNr, cSepChar )

   DEFAULT cSepChar := "|"

RETURN StrToken( cString, nNr, cSepChar )


*-- FUNCTION -----------------------------------------------------------------
* Name........: StrCount
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION StrCount( cText, cString )

   LOCAL i
   LOCAL nCount := 0

   FOR i := 1 TO LEN( ALLTRIM( cText ) )
      IF SUBSTR( cText, i, LEN( cString ) ) == cString
         ++nCount
      ENDIF
   NEXT

RETURN ( nCount )


* - FUNCTION ---------------------------------------------------------------
*  Function....: GetResDLL()
*  Beschreibung:
*  Argumente...: None
*  Rückgabewert:
*  Author......: Timm Sodtalbers
* --------------------------------------------------------------------------
FUNCTION GetResDLL()

   LOCAL cDLLName
   LOCAL nLanguage := VAL( GetPvProfString( "General", "Language", "1", cGeneralIni ) )

   IF nLanguage < 1
      nLanguage := 1
   ENDIF

   cDLLName := "VRD" + ALLTRIM(STR( nLanguage, 1, 3)) + ".DLL"

   IF FILE( cDLLName ) = .F.
      MsgInfo( GL("Language specific file") + " " + cDLLName + " " + GL("not found!") + CRLF + CRLF + ;
               GL("The english file will be used instead.") )
      cDLLName := "VRD1.DLL"
   ENDIF

RETURN ( cDLLName )


*-- FUNCTION -----------------------------------------------------------------
* Name........: OpenLanguage
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION OpenLanguage()

   USE LANGUAGE.DBF

   DO WHILE .NOT. LANGUAGE->(EOF())

      AADD( oGenVar:aLanguages, { LANGUAGE->LANGUAGE1, LANGUAGE->LANGUAGE2, ;
                                  LANGUAGE->LANGUAGE3, LANGUAGE->LANGUAGE4, ;
                                  LANGUAGE->LANGUAGE5, LANGUAGE->LANGUAGE6, ;
                                  LANGUAGE->LANGUAGE7, LANGUAGE->LANGUAGE8, ;
                                  LANGUAGE->LANGUAGE9 } )
      LANGUAGE->(DBSKIP())

   ENDDO

   LANGUAGE->(DBCLOSEAREA())

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: GL
* Beschreibung: Get Language
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GL( cOriginal )

   LOCAL cAltText := strtran( cOriginal, " ", "_" )
   LOCAL cText    := cAltText
   LOCAL nSelect  := Select()
   LOCAL nPos     := ASCAN( oGenVar:aLanguages, ;
                            { |aVal| ALLTRIM( aVal[1] ) == ALLTRIM( cAltText ) } )

   IF nPos = 0
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
      IF EMPTY( cText )
         cText := oGenVar:aLanguages[ nPos, 1 ]
      ENDIF
   ENDIF

RETURN ( STRTRAN(ALLTRIM( cText ), "_", " " ) )


*-- FUNCTION -----------------------------------------------------------------
* Name........: PrintReport
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION PrintReport( lPreview, lDeveloper, lPrintDlg )

   LOCAL i, oVRD, cCondition
   LOCAL lPrintIDs := IIF( GetPvProfString( "General", "PrintIDs", "0", cDefIni ) = "0", .F., .T. )

   DEFAULT lPreview   := .F.
   DEFAULT lDeveloper := .F.
   DEFAULT lPrintDlg  := .T.

   IF lDeveloper = .F.
      ShellExecute( 0, "Open", ;
         "ERSTART.EXE", ;
         "-File=" + ALLTRIM( cDefIni ) + ;
         IIF( lPreview, " -PREVIEW", " -PRINTDIALOG" ) + ;
         "-CHECK", ;
         NIL, 1 )
      RETURN (.T.)
   ELSE
      EASYREPORT oVRD NAME cDefIni OF oMainWnd PREVIEW lPreview ;
                 PRINTDIALOG IIF( lPreview, .F., lPrintDlg ) PRINTIDS NOEXPR
   ENDIF

   IF oVRD:lDialogCancel = .T.
      RETURN( .F. )
   ENDIF

   //erste Seite
   FOR i := 1 TO LEN( oVRD:aAreaInis )

      IF GetPvProfString( "General", "Condition", "0", oVRD:aAreaInis[i] ) <> "4"
         PRINTAREA i OF oVRD
      ENDIF

   NEXT

   //zweite Seite
   IF IsSecondPage( oVRD ) = .T.

      oVRD:PageBreak()

      FOR i := 1 TO LEN( oVRD:aAreaInis )
         cCondition := GetPvProfString( "General", "Condition", "0", oVRD:aAreaInis[i] )
         IF cCondition = "1" .OR. cCondition = "4"
            PRINTAREA i OF oVRD
         ENDIF
      NEXT

   ENDIF

   END EASYREPORT oVRD

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: PrintReport
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION AltPrintReport( lPreview, cPrinter )

   LOCAL i, oVRD, cCondition
   LOCAL lPrintIDs := IIF( GetPvProfString( "General", "PrintIDs", "0", cDefIni ) = "0", .F., .T. )

   oVRD := VRD():New( cDefIni, lPreview, cPrinter, oMainWnd,, lPrintIDs,, .T. )

   //erste Seite
   FOR i := 1 TO LEN( oVRD:aAreaInis )

      IF GetPvProfString( "General", "Condition", "0", oVRD:aAreaInis[i] ) <> "4"
         oVRD:PrintArea( i )
      ENDIF

   NEXT

   //zweite Seite
   IF IsSecondPage( oVRD ) = .T.

      oVRD:PageBreak()

      FOR i := 1 TO LEN( oVRD:aAreaInis )
         cCondition := GetPvProfString( "General", "Condition", "0", oVRD:aAreaInis[i] )
         IF cCondition = "1" .OR. cCondition = "4"
            oVRD:PrintArea( i )
         ENDIF
      NEXT

   ENDIF

   oVrd:End()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: IsSecondPage
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION IsSecondPage( oVRD )

   LOCAL i
   LOCAL lReturn := .F.

   FOR i := 1 TO LEN( oVRD:aAreaInis )

      IF GetPvProfString( "General", "Condition", "0", oVRD:aAreaInis[i] ) = "4"
         lReturn := .T.
         EXIT
      ENDIF

   NEXT

RETURN ( lReturn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: OpenUndo()
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION OpenUndo()

   LOCAL nSelect := SELECT()

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

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: CloseUndo()
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CloseUndo()

  DelFile( ".\" + oGenVar:cUndoFileName + ".dbf" )
  DelFile( ".\" + oGenVar:cUndoFileName + ".dbt" )
  DelFile( ".\" + oGenVar:cRedoFileName + ".dbf" )
  DelFile( ".\" + oGenVar:cRedoFileName + ".dbt" )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: Add2Undo()
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION Add2Undo( cEntryText, nEntryNr, nAreaNr, cAreaText )

   LOCAL nSelect := SELECT()

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

   oBar:AEvalWhen()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: Undo
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION Undo()

   LOCAL oIni, oItemInfo, nOldWidth, nOldHeight
   LOCAL nSelect   := SELECT()
   LOCAL aFirst    := { .F., 0, 0, 0, 0, 0 }
   LOCAL nElemente := 0

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

   IF TMPUNDO->ENTRYNR = 0

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

   ELSEIF EMPTY( TMPUNDO->ENTRYTEXT )

      //New item was build
      DeleteItem( TMPUNDO->ENTRYNR, TMPUNDO->AREANR, .T.,, .T. )
      DelIniEntry( "Items", ALLTRIM(STR(TMPUNDO->ENTRYNR,5)), aAreaIni[ TMPUNDO->AREANR ] )

   ELSE

      IF aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ] <> NIL
         DeleteItem( TMPUNDO->ENTRYNR, TMPUNDO->AREANR, .T.,, .T. )
      ENDIF

      INI oIni FILE aAreaIni[ TMPUNDO->AREANR ]
         SET SECTION "Items" ENTRY ALLTRIM(STR(TMPUNDO->ENTRYNR,5)) TO TMPUNDO->ENTRYTEXT OF oIni
      ENDINI

      oItemInfo := VRDItem():New( TMPUNDO->ENTRYTEXT )

      IF oItemInfo:nShow = 1
         aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ] := NIL
         ShowItem( TMPUNDO->ENTRYNR, TMPUNDO->AREANR, aAreaIni[ TMPUNDO->AREANR ], aFirst, nElemente )
         aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ]:lDrag := .T.
      ENDIF

   ENDIF

   DELETE
   PACK

   RefreshUndo()
   RefreshRedo()
   oBar:AEvalWhen()

   TMPUNDO->(DBCLOSEAREA())
   TMPREDO->(DBCLOSEAREA())
   SELECT( nSelect )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: Redo
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION Redo()

   LOCAL oIni, oItemInfo, nOldWidth, nOldHeight
   LOCAL nSelect   := SELECT()
   LOCAL aFirst    := { .F., 0, 0, 0, 0, 0 }
   LOCAL nElemente := 0

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

   IF TMPREDO->ENTRYNR = 0

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

   ELSEIF EMPTY( TMPREDO->ENTRYTEXT )

      //New item was build
      DeleteItem( TMPREDO->ENTRYNR, TMPREDO->AREANR, .T.,, .T. )
      DelIniEntry( "Items", ALLTRIM(STR(TMPREDO->ENTRYNR,5)), aAreaIni[ TMPREDO->AREANR ] )

   ELSE

      IF aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ] <> NIL
         DeleteItem( TMPREDO->ENTRYNR, TMPREDO->AREANR, .T.,, .T. )
      ENDIF

      INI oIni FILE aAreaIni[ TMPREDO->AREANR ]
         SET SECTION "Items" ENTRY ALLTRIM(STR(TMPREDO->ENTRYNR,5)) TO TMPREDO->ENTRYTEXT OF oIni
      ENDINI

      oItemInfo := VRDItem():New( TMPREDO->ENTRYTEXT )

      IF oItemInfo:nShow = 1
         aItems[ TMPREDO->AREANR, TMPREDO->ENTRYNR ] := NIL
         ShowItem( TMPREDO->ENTRYNR, TMPREDO->AREANR, aAreaIni[ TMPREDO->AREANR ], aFirst, nElemente )
         aItems[ TMPREDO->AREANR, TMPREDO->ENTRYNR ]:lDrag := .T.
      ENDIF

   ENDIF

   DELETE
   PACK

   RefreshUndo()
   RefreshRedo()
   oBar:AEvalWhen()

   TMPUNDO->(DBCLOSEAREA())
   TMPREDO->(DBCLOSEAREA())
   SELECT( nSelect )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: RefreshUndo()
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION RefreshUndo()

   nUndoCount := TMPUNDO->(LASTREC())

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: RefreshRedo()
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION RefreshRedo()

   nRedoCount := TMPREDO->(LASTREC())

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ClearUndoRedo
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ClearUndoRedo()

   LOCAL nSelect := SELECT()

   SELECT 0
   USE ( oGenVar:cUndoFileName + ".dbf" ) ALIAS TMPUNDO
   ZAP

   USE ( oGenVar:cRedoFileName + ".dbf" ) ALIAS TMPREDO
   ZAP

   TMPREDO->(DBCLOSEAREA())
   SELECT( nSelect )

   nUndoCount := 0
   nRedoCount := 0

   oBar:AEvalWhen()

RETURN (.T.)


* - FUNCTION ---------------------------------------------------------------
*  Function....: UndoRedoMenu
*  Beschreibung: Shell-Menu anzeigen
*  Argumente...: None
*  Rückgabewert: ( NIL )
*  Author......: Timm Sodtalbers
* --------------------------------------------------------------------------
FUNCTION UndoRedoMenu( nTyp, oBtn )

   LOCAL i, oMenu
   LOCAL cText1 := "" //IIF( nTyp = 1, GL("Undo"), GL("Redo") )
   LOCAL cText2 := IIF( nTyp = 1, GL("Undo all"), GL("Redo all") )
   LOCAL nCount := IIF( nTyp = 1, nUndoCount, nRedoCount )
   LOCAL aRect  := GetClientRect( oBtn:hWnd )

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

RETURN( oMenu )


*-- FUNCTION -----------------------------------------------------------------
* Name........: MultiUndoRedo
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION MultiUndoRedo( nTyp, nCount )

   LOCAL i

   FOR i := 1 TO nCount
      IIF( nTyp = 1, Undo(), Redo() )
   NEXT

RETURN (.T.)