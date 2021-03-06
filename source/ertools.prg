#INCLUDE "FiveWin.ch"
#INCLUDE "VRD.ch"
#INCLUDE "Mail.ch"

#xcommand @ <nRow>, <nCol> CFOLDEREX [<oFolder>] ;
             [ <of: OF, WINDOW, DIALOG> <oWnd> ] ;
             [ <prm: PROMPT, PROMPTS, ITEMS> <cPrompt,...> ] ;
             [ <bm: BITMAPS, IMAGES, BMPS> <cbmps,...> ] ;
             [ <lPixel: PIXEL> ] ;
             [ <lDesign: DESIGN> ] ;
             [ TAB HEIGHT <ntabheight> ];
             [ SEPARATOR <nSep> ];
             [ OPTION <nOption> ] ;
             [ ROUND <nRound> ];
             [ SIZE <nWidth>, <nHeight> ] ;
             [ <lAdjust: ADJUST> ] ;
             [ <lStretch: STRETCH> ] ;
             [ POPUP <upop>];
             [ ALIGN <nAlign,...> ] ;
             [ ACTION <uAction> ];
             [ BRIGHT <nBright> ] ;
             [ ON CHANGE <uChange> ] ;
             [ ON PAINT TAB <uPaint> ];
             [ ON PAINT TEXT <uPaintxt> ];
             [ HELPTOPICS <cnHelpids,...> ] ;
             [ <layout: TOP, LEFT, BOTTOM, RIGHT> ] ;
             [ <lAnimate: ANIMATE> [ SPEED <nSpeed> ] ] ;
              [ FONT <oFont> ] ; //-->> byte-one 2010
             [ <lTransparent: TRANSPARENT> ] ;
            [ <dlg: DIALOG, DIALOGS, PAGE, PAGES> <cDlgsName,...> ] ;
       => ;
             [<oFolder> := ] TCFoldereX():New( <nRow>, <nCol>, <nWidth>, <nHeight>,;
             <oWnd>, [\{<cbmps>\}], <.lPixel.>, <.lDesign.>, [\{<cPrompt>\}], ;
             <ntabheight>, [\{<cnHelpids>\}], <nRound>, [{|nOption, nOldOption, Self | <uChange>}],;
             [{|Self,nOption| <uPaint>}], [{|Self,nOption| <uPaintxt>}], ;
             [\{<nAlign>\}], <.lAdjust.>, <nSep>, <nOption>, [{|Self,nOption| <upop>}],;
             <.lStretch.>, [ Upper(<(layout)>) ], [{|Self,nOption| <uAction>}], <nBright>,;
             <.lAnimate.>, [<nSpeed>], <oFont>, <.lTransparent.>, [\{<cDlgsName>\}] )



MEMVAR cDefaultPath
//MEMVAR nAktArea
MEMVAR aVRDSave
MEMVAR lProfi, oGenVar
MEMVAR oER

//-----------------------------------------------------------------------------//

function GetFreeSystemResources()
return 0


//-----------------------------------------------------------------------------//

function CheckPath( cPath )

   cPath := ALLTRIM( cPath )

   if !EMPTY( cPath ) .AND. SUBSTR( cPath, LEN( cPath ) ) != "\"
      cPath += "\"
   endif

return ( cPath )

//-----------------------------------------------------------------------------//

FUNCTION GetNameArea(nArea)
RETURN oEr:aAreaIni[nArea]

//------------------------------------------------------------------------------

FUNCTION getNumArea( cAreaIni )
RETURN AScan( oEr:aAreaIni,cAreaIni )

//------------------------------------------------------------------------------

FUNCTION GetAreaInis()

LOCAL i
local aIniEntries := GetIniSection( "Areas", oER:cDefIni )
LOCAL aAreaInis := {}

   FOR i := 1 TO Len( oER:aWnd )
      AADD( aAreaInis, ALLTRIM( GetIniEntry( aIniEntries, ALLTRIM(STR( i, 5 )) , "" ) ) )
   NEXT

RETURN aAreaInis

//------------------------------------------------------------------------------


function InsertArea( lBefore, cTitle )

   local i, oGet, oDlg, cTmpFile
   local aAreaInis   := GetAreaInis()
   local lreturn     := .F.
   local cFile       := SPACE( 200 )
   local nNewArea    := oER:nAktArea + IIF( lBefore, 0, 1 )
   local cDir        := CheckPath( oER:GetDefIni( "General", "AreaFilesDir", "" ) )
   LOCAL nDecimals   := IIF( oER:nMeasure = 2, 2, 0 )

   if EMPTY( cDir )
      cDir := cDefaultPath
   endif

   DEFINE DIALOG oDlg NAME "NEWFILENAME" TITLE cTitle

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION ( lReturn :=  ActionDlgInsertArea( cFile, oDlg, cDir ) )

   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE SAY PROMPT GL("Name of the new area file") + ":" ID 171 OF oDlg

   REDEFINE GET oGet VAR cFile ID 201 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED

   if lreturn

      nNewArea := IIF( nNewArea < 1, 1, nNewArea )
      AINS( aAreaInis, nNewArea )
      aAreaInis[nNewArea] := RTrim( cFile )

      DelIniSection( "Areas", oER:cDefIni )

      for i := 1 TO LEN( aAreaInis )
         if !EMPTY( aAreaInis[i] )
            WritePProString( "Areas", ALLTRIM(STR( i, 3 )), ALLTRIM( aAreaInis[i] ), oER:cDefIni )
         endif
      NEXT

      IF oER:lNewFormat

         SetDataArea( "General", "Title", "New Area",  ALLTRIM( aAreaInis[nNewArea] ) )
         SetDataArea( "General", "Width",  ALLTRIM(STR( oGenVar:aAreaSizes[oER:nAktArea,1], 5, nDecimals )) , ALLTRIM( aAreaInis[nNewArea] ) )
         SetDataArea( "General", "Height", ALLTRIM(STR( oGenVar:aAreaSizes[oER:nAktArea,2], 5, nDecimals )) , ALLTRIM( aAreaInis[nNewArea] ) )

      ELSE

         MEMOWRIT( cDir + cFile, ;
                  "[General]" + CRLF + ;
                  "Title=New Area" + CRLF + ;
                  "Width="  + ALLTRIM(STR( oGenVar:aAreaSizes[oER:nAktArea,1], 5, nDecimals )) + CRLF + ;
                  "Height=" + ALLTRIM(STR( oGenVar:aAreaSizes[oER:nAktArea,2], 5, nDecimals )) )

      ENDIF

      OpenFile( oER:cDefIni,, .T. )

      oER:aWnd[ nNewArea ]:SetFocus()

    //  AreaProperties( oER:nAktArea )

       AreaProperties( nNewArea )

   endif

return .T.

//-----------------------------------------------------------------------------//

FUNCTION ActionDlgInsertArea( cFile, oDlg ,cDir )
   LOCAL lreturn := .f.
   LOCAL aIniEnTries,cArea
   local i
   IF oEr:lNewFormat

         FOR i= 1 TO Len( oER:aWnd )
            cArea:= AllTrim( GetPvProfString( "Areas", AllTrim(STR(i,2)), "", oER:cDefIni ) )
            IF cArea == AllTrim(cFile)
               MsgStop( GL("The file already exists."), GL("Stop!") )
               RETURN .f.
            endif
         NEXT
         lreturn := .T.
         oDlg:End()
   ELSE

      IF FILE( cDir + cFile )
         MsgStop( GL("The file already exists."), GL("Stop!") )
       ELSE
         lreturn := .T.
         oDlg:End()
      endif
   endif
return lreturn

//------------------------------------------------------------------------------


function DeleteArea()
 LOCAL cAreaIni
 if MsgNoYes( GL("Do you really want to delete this area?"), GL("Select an option") ) = .T.

    IF oER:lNewFormat
         cAreaIni := AllTrim( GetPvProfString( "Areas", AllTrim(STR(oER:nAktArea,2)), "", oER:cDefIni ) )
         DelIniSection( cAreaIni+"General", oER:cDefIni )
         DelIniSection( cAreaIni+"Items", oER:cDefIni )
      ELSE
         FErase( aVRDSave[oER:nAktArea,1] )
      endif

      DelIniEntry( "Areas", ALLTRIM(STR( oER:nAktArea, 5 )), oER:cDefIni )

      DelallChildWnd()

      OpenFile( oER:cDefIni,, .T. )

   endif

   return .T.

//-----------------------------------------------------------------------------//

function DuplicateArea( cTitle )

   local i, oGet, oDlg, cTmpFile
   local aAreaInis   := GetAreaInis()
   local lreturn     := .F.
   local cFile       := SPACE( 200 )
   local nNewArea    := oER:nAktArea + 1
   LOCAL nOldArea    := oER:nAktArea
   local cDir        := CheckPath( oER:GetDefIni( "General", "AreaFilesDir", "" ) )
   LOCAL nDecimals   := IIF( oER:nMeasure = 2, 2, 0 )
   LOCAL aAreaProp:=  GetAreaProperties( oER:nAktArea )

   if EMPTY( cDir )
      cDir := cDefaultPath
   endif

   DEFINE DIALOG oDlg NAME "NEWFILENAME" TITLE cTitle

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION ( lReturn :=  ActionDlgInsertArea( cFile, oDlg, cDir ) )

   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE SAY PROMPT GL("Name of the new area file") + ":" ID 171 OF oDlg

   REDEFINE GET oGet VAR cFile ID 201 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED

   if lreturn

      nNewArea := IIF( nNewArea < 1, 1, nNewArea )
      AINS( aAreaInis, nNewArea )
      aAreaInis[nNewArea] := RTrim( cFile )

      DelIniSection( "Areas", oER:cDefIni )

      for i := 1 TO LEN( aAreaInis )
         if !EMPTY( aAreaInis[i] )
            WritePProString( "Areas", ALLTRIM(STR( i, 3 )), ALLTRIM( aAreaInis[i] ), oER:cDefIni )
         endif
      NEXT

      IF oER:lNewFormat

         SetDataArea( "General", "Title", "New Area",  ALLTRIM( aAreaInis[nNewArea] ) )
         SetDataArea( "General", "Width",  ALLTRIM(STR( oGenVar:aAreaSizes[oER:nAktArea,1], 5, nDecimals )) , ALLTRIM( aAreaInis[nNewArea] ) )
         SetDataArea( "General", "Height", ALLTRIM(STR( oGenVar:aAreaSizes[oER:nAktArea,2], 5, nDecimals )) , ALLTRIM( aAreaInis[nNewArea] ) )

      ELSE

         MEMOWRIT( cDir + cFile, ;
                  "[General]" + CRLF + ;
                  "Title=New Area" + CRLF + ;
                  "Width="  + ALLTRIM(STR( oGenVar:aAreaSizes[oER:nAktArea,1], 5, nDecimals )) + CRLF + ;
                  "Height=" + ALLTRIM(STR( oGenVar:aAreaSizes[oER:nAktArea,2], 5, nDecimals )) )

      ENDIF

     OpenFile( oER:cDefIni,, .T. )
     oER:aWnd[ nNewArea ]:SetFocus()

      SetAreaProperties( nNewArea, aAreaProp )
      CopyAllItemsToArea( nOldArea,nNewArea )
      oER:FillWindow( nNewArea, oER:aAreaIni[nNewArea] )

   endif

return .T.

//------------------------------------------------------------------------------

FUNCTION DelallChildWnd()
   LOCAL i

   FOR i=1 TO Len( oER:aWnd )
      IF !Empty( oER:aWnd[ i ]  )
         oER:aWnd[ i ]:END()
         oER:aWnd[ i ]:= nil
      endif
   next

RETURN nil

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

   local nLen       := LEN( oGenVar:aDBFile )
   local aDbase     := {}
   local lOK        := .T.
   local lreturn    := .F.
   local aFields    := {}

   DEFAULT lInsert := .F.

   if nShowDbase > 0

      for i := 1 TO nLen
         if !EMPTY( oGenVar:aDBFile[i,2] )
            AADD( aDbase , ALLTRIM( oGenVar:aDBFile[i,2] ) )
            AADD( aFields, oGenVar:aDBFile[i,3] )
         endif
      NEXT

   endif

   if nShowExpr > 0 .AND. !lInsert
      AADD( aDbase, GL("Expressions") + ": " + GL("General") )
      AADD( aFields, GetExprFields( cGenExpr ) )
      cGeneral := aDbase[ LEN( aDbase ) ]
   endif

   if nShowExpr <> 2 .AND. !lInsert
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

   if lreturn .AND. !EMPTY( cField ) .AND. lInsert
      oGet:Paste( "[" + ALLTRIM( cDbase ) + ":" + ALLTRIM( cField ) + "]" )
   ELSEif lreturn .AND. !EMPTY( cField )
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
//------------------------------------------------------------------------------

Function OpenDbf( cFile, cAlias, cVia )
DEFAULT cVia :=  "DBFNTX"
DEFAULT cAlias := cfileNoext(cFileNopath(cfile ))
    cAlias:= cGetNewAlias(cAlias)
    USE (cfile) VIA (cVia) ALIAS (cAlias) NEW SHARED
Return cAlias

//-----------------------------------------------------------------------------//

function GetExprFields( cDatabase )

   local nSelect := SELECT()
   local aTemp   := {}
   LOCAL nReg

   LOCAL cAlias:= OpenDbf( cDatabase )

    DO WHILE !EOF()
      if !EMPTY( (calias)->NAME )
         AADD( aTemp, ALLTRIM( (cAlias)->NAME ) )
      endif
      (cAlias)->(DBSKIP())
   ENDDO

   close( cAlias )

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

  close all

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

      if FILE( cDbase )

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

function Er_Databases( lTake, nD )

   Local oDlg
   Local aDBGet1    := Array( 12 )
   Local aDBGet2    := Array( 12 )
   Local oFont
   Local nDefClr
   Local x
   Local nCol
   Local nFil
   Local aBmps1     := Array( 12 )
   Local aBmps2     := Array( 12 )
   Local cRdds
   Local aRdds      := {"DbfNtx", "DbfCdx", "RddAds", "ADO" }

   DEFAULT nD := 1
   oDlg       := oER:oFldD:aDialogs[ nD ]
   oDlg:SetColor( CLR_BLACK, oEr:nClrPaneTree )

   nDefClr := oDlg:nClrPane

   DEFINE FONT oFont NAME "Verdana" Size 0,-12

   /*
   @ 24, 10 SAY GL("Rdds")      OF oDlg FONT oFont PIXEL //TRANSPARENT
   nFil  := 52
   @ nFil, 10 COMBOBOX cRdds ITEMS aRdds OF oDlg ;
      SIZE oDlg:nWidth - 20, 324 FONT oFont PIXEL //  ON CHANGE
   */

   nFil  := 2   //155

   //@ 2, 008 SAY GL("Nr.")      OF oDlg FONT oFont PIXEL TRANSPARENT

   @ nFil, 084 SAY GL("Database") OF oDlg FONT oFont ;
     COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT

   @ nFil, 228 SAY GL("Alias")    OF oDlg FONT oFont ;
     COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT

   For x = 1 to Len( aDBGet1 )
       nCol := 8
       nFil := (x-1)*30 + 25 //175
       aDBGet1[ x ] := TGet():New( nFil, nCol, MiSetGetDb( oGenVar:aDBFile, x, 1 ), oDlg, 200, 20, , ,;
                                  ,,,,, .T.,,,,,,,,,,,,,,,,,,, )

       nCol := 212
       aDBGet2[ x ] := TGet():New( nFil, nCol, MiSetGetDb( oGenVar:aDBFile, x, 2 ), oDlg, 60, 20, , ,;
                                  ,,,,, .T.,,,,,,,,,,,,,,,,,,, )

       nCol := 278
       aBmps1[ x ] := TBtnBmp():New( nFil, nCol, 16, 16,;
                                    "B_OPEN_16",,,,;
                                    ,oDlg,,,,,;
                                    ,,,, .F.,,;
                                    ,,,.T.,GL("Open"),;
                                    ,,.T.,)

       aBmps1[ x ]:bAction := SetMi2File( aDBGet1, aDBGet2, x )

       nCol := 300
       aBmps2[ x ] := TBtnBmp():New( nFil, nCol, 16, 16,;
                                    "B_DEL",,,,;
                                    ,oDlg,,,,,;
                                    ,,,, .F.,,;
                                    ,,,.T.,GL("Delete"),;
                                    ,,.T.,)

       aBmps2[ x ]:bAction := SetMi3File( aDBGet1, aDBGet2, x )

   Next x

   @ nFil + 35 , oDlg:nWidth - 110 BTNBMP PROMPT GL("Save") ;
            OF oDlg SIZE 100, 20 PIXEL ;
            ACTION ( SaveDatabases(), OpenDatabases() )

   //ACTIVATE DIALOG oDlg CENTER


   //SaveDatabases()
   //OpenDatabases()

return ( NIL )

//-----------------------------------------------------------------------------//

Function SetMi2File( aDBGet1, aDBGet2, nPos )
Return { || GetDBase( oGenVar:aDBFile[ nPos, 1 ], aDBGet1[ nPos ], aDBGet2[ nPos ] ) }

//-----------------------------------------------------------------------------//

Function SetMi3File( aDBGet1, aDBGet2, nPos )
Return { || DelDBase( aDBGet1[ nPos ], aDBGet2[ nPos ] ) }

//-----------------------------------------------------------------------------//

Function MiSetGetDb( aBuffer , n , m )
Return bSETGET( aBuffer[ n ][ m ] )

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
   FErase( cTmpFile )

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
/*
function ADelete( aArray, nIndex )

   local i
   local aNewArray := {}

   ADEL( aArray, nIndex )

   for i := 1 TO LEN( aArray ) - 1
      AADD( aNewArray, aArray[i] )
   NEXT

return ( aNewArray )
*/

//-----------------------------------------------------------------------------

function StrAtNum( cSearch, cString, nNr )

   cString := STRTRAN( cString, cSearch, REPLICATE( "@", LEN( cSearch ) ),, nNr - 1 )

return AT( cSearch, cString )


//-----------------------------------------------------------------------------

function GoBottom()

  GO BOTTOM

return !Eof()

//-----------------------------------------------------------------------------

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

//-----------------------------------------------------------------------------

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

//-----------------------------------------------------------------------------

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

//-----------------------------------------------------------------------------

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
   LOCAL cVersion := IIF ( oEr:lBeta , " - Beta Version" , " - Full version" )
   LOCAL cMainTitle := IIf(  !EMPTY( oER:cDefIni ), ALLTRIM( oER:GetDefIni( "General", "Title", "" ) ), "" )

   LOCAL cReturn := IIF( EMPTY( cUserApp ), "EasyReport", cUserApp ) + ;
              cVersion + ;
              IIF( EMPTY(cMainTitle), "", " - " + cMainTitle )

return ( cReturn )

//-----------------------------------------------------------------------------

function Expressions( lTake, cAltText )

   local i, oDlg, oFld, oBrw, oBrw2, oBrw3, oFont, creturn, oSay1, nTyp
   local oBtn1, aBtn[3], aGet[5], cName
   local nAltSel    := SELECT()
   local nShowExpr  := VAL( oER:GetDefIni( "General", "Expressions", "0" ) )
   local cGenExpr   := ALLTRIM( oEr:cDataPath + oER:GetDefIni( "General", "GeneralExpressions", "General.dbf" ) )
   local cUserExpr  := ALLTRIM( oEr:cDataPath + oER:GetDefIni( "General", "UserExpressions", "User.dbf") )
   LOCAL cAliasGen, cAliasUser
   LOCAL aVar:= Array(3)
   LOCAL oGet1, oGet2, oGet3

   local aUndo      := {}
   local cErrorFile := ""
   //local aRDD      := { "DBFNTX", "COMIX", "DBFCDX" }

   DEFAULT cAltText := ""
   DEFAULT lTake    := .F.

   aUndo      := {}

   if FILE( VRD_LF2SF( cGenExpr ) ) = .F.
      cErrorFile += cGenExpr + CRLF
   endif
   if FILE( VRD_LF2SF( cUserExpr ) ) = .F.
      cErrorFile += cUserExpr + CRLF
   endif

   if !EMPTY( cErrorFile )
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

   cAliasGen := OpenDbf( VRD_LF2SF( cGenExpr ) )


  //  IF Select(  "GENEXPR" ) == 0
  //      SELECT 0
  //      USE ( VRD_LF2SF( cGenExpr ) ) ALIAS "GENEXPR" SHARED
  //   endif


   REDEFINE LISTBOX oBrw ;
      FIELDS ( cAliasGen )->NAME, ( cAliasGen )->INFO ;
      FIELDSIZES 180, 400 ;
      HEADERS " " + GL("Name"), " " + GL("Description") ;
      ID 301 OF oFld:aDialogs[1] FONT oFont ;
      ON LEFT DBLCLICK ( creturn := ( cAliasGen )->NAME, nTyp := 1, oDlg:End() )

   oBrw:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, ;
                     EVAL( {|| creturn := ( cAliasGen )->NAME, nTyp := 1, oDlg:End() } ), .T. ) }

   if nShowExpr = 1

      i := 2

    cAliasUser := OpenDbf( VRD_LF2SF( cUserExpr ) )

//IF Select(  "USEREXPR" ) ==0
//   SELECT 0
//   USE ( VRD_LF2SF( cUserExpr ) ) ALIAS "USEREXPR" SHARED
//ENDIF

    aVar[1]:= ( cAliasUser )->NAME
    aVar[2] := ( cAliasUser )->EXPRESSION
    aVar[3]:= ( cAliasUser )->INFO

   REDEFINE LISTBOX oBrw2 ;
      FIELDS ( cAliasUser )->NAME, ( cAliasUser )->INFO ;
      FIELDSIZES 220, 400 ;
      HEADERS " " + GL("Name"), " " + GL("Description") ;
      ID 301 OF oFld:aDialogs[i] FONT oFont ;
      ON CHANGE ( cargaUserGet(aVar,cAliasUser ) ,;
                  oDlg:Update(), aUndo := {} ) ;
      ON LEFT DBLCLICK ( creturn := ( cAliasUser )->NAME, nTyp := 2, oDlg:End() )

   oBrw2:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, ;
                      EVAL( {|| creturn := ( cAliasUser )->NAME, nTyp := 2, oDlg:End() } ), .T. ) }

   REDEFINE BUTTON PROMPT GL("&New")    ID 101 OF oFld:aDialogs[i] ;
      ACTION ( ( cAliasUser )->(DBAPPEND()), oBrw2:Refresh(), oBrw2:GoBottom(), oDlg:Update() )
   REDEFINE BUTTON PROMPT GL("&Delete") ID 102 OF oFld:aDialogs[i] ;
      ACTION (  ( cAliasUser )->(rlock()), ( cAliasUser )->(DBDELETE()),( cAliasUser )->(DBUnlock()), ;
               ( cAliasUser )->(DBGoTop()), oBrw2:gotop(),oBrw2:Refresh(), oDlg:Update() )

   REDEFINE GET  oGet1 VAR  aVar[1]   ID 201 OF oFld:aDialogs[i] UPDATE ;
      VALID ( GrabaUserGet(aVar,cAliasUser ), oBrw2:Refresh(), .T. )

   REDEFINE GET oGet2 VAR  aVar[2]   ID 202 OF oFld:aDialogs[i] UPDATE ;
      VALID ( GrabaUserGet(aVar,cAliasUser ), oBrw2:Refresh(), .T. )
   REDEFINE GET oGet3 VAR   aVar[3]  ID 203 OF oFld:aDialogs[i] UPDATE ;
      VALID ( GrabaUserGet(aVar,cAliasUser ), oBrw2:Refresh(), .T. )

   REDEFINE BUTTON ID 401 OF oFld:aDialogs[i] ACTION CopyToExpress( "="   , oGet2, @aUndo )
   REDEFINE BUTTON ID 402 OF oFld:aDialogs[i] ACTION CopyToExpress( "<>"  , oGet2, @aUndo )
   REDEFINE BUTTON ID 403 OF oFld:aDialogs[i] ACTION CopyToExpress( "<"   , oGet2, @aUndo )
   REDEFINE BUTTON ID 404 OF oFld:aDialogs[i] ACTION CopyToExpress( ">"   , oGet2, @aUndo )
   REDEFINE BUTTON ID 405 OF oFld:aDialogs[i] ACTION CopyToExpress( "<="  , oGet2, @aUndo )
   REDEFINE BUTTON ID 406 OF oFld:aDialogs[i] ACTION CopyToExpress( ">="  , oGet2, @aUndo )
   REDEFINE BUTTON ID 407 OF oFld:aDialogs[i] ACTION CopyToExpress( "=="  , oGet2, @aUndo )
   REDEFINE BUTTON ID 408 OF oFld:aDialogs[i] ACTION CopyToExpress( "("   , oGet2, @aUndo )
   REDEFINE BUTTON ID 409 OF oFld:aDialogs[i] ACTION CopyToExpress( ")"   , oGet2, @aUndo )
   REDEFINE BUTTON ID 410 OF oFld:aDialogs[i] ACTION CopyToExpress( '"'   , oGet2, @aUndo )
   REDEFINE BUTTON ID 411 OF oFld:aDialogs[i] ACTION CopyToExpress( "!"   , oGet2, @aUndo )
   REDEFINE BUTTON ID 412 OF oFld:aDialogs[i] ACTION CopyToExpress( "$"   , oGet2, @aUndo )
   REDEFINE BUTTON ID 413 OF oFld:aDialogs[i] ACTION CopyToExpress( "+"   , oGet2, @aUndo )
   REDEFINE BUTTON ID 414 OF oFld:aDialogs[i] ACTION CopyToExpress( "-"   , oGet2, @aUndo )
   REDEFINE BUTTON ID 415 OF oFld:aDialogs[i] ACTION CopyToExpress( "*"   , oGet2, @aUndo )
   REDEFINE BUTTON ID 416 OF oFld:aDialogs[i] ACTION CopyToExpress( "/"   , oGet2, @aUndo )
   REDEFINE BUTTON ID 417 OF oFld:aDialogs[i] ACTION CopyToExpress( ".T." , oGet2, @aUndo )
   REDEFINE BUTTON ID 418 OF oFld:aDialogs[i] ACTION CopyToExpress( ".F." , oGet2, @aUndo )

   REDEFINE BUTTON ID 502 OF oFld:aDialogs[i] ACTION CopyToExpress( ".or." , oGet2, @aUndo )
   REDEFINE BUTTON ID 503 OF oFld:aDialogs[i] ACTION CopyToExpress( ".and.", oGet2, @aUndo )
   REDEFINE BUTTON ID 504 OF oFld:aDialogs[i] ACTION CopyToExpress( ".not.", oGet2, @aUndo )

   REDEFINE BUTTON ID 601 OF oFld:aDialogs[i] ACTION CopyToExpress( "If( , , )", oGet2, @aUndo )
   REDEFINE BUTTON ID 602 OF oFld:aDialogs[i] ACTION CopyToExpress( "Val(  )"  , oGet2, @aUndo )
   REDEFINE BUTTON ID 603 OF oFld:aDialogs[i] ACTION CopyToExpress( "Str(  )"  , oGet2, @aUndo )

   REDEFINE BUTTON  PROMPT GL("Check") ID 505 OF oFld:aDialogs[i] ;
      ACTION CheckExpression( ( cAliasUser )->EXPRESSION )
   REDEFINE BUTTON oBtn1 PROMPT GL("Undo") ID 506 OF oFld:aDialogs[i] WHEN LEN( aUndo ) > 0 ;
      ACTION aUndo := UnDoExpression( oGet2, aUndo )

   REDEFINE SAY ID 170 OF oFld:aDialogs[i] PROMPT GL("Name") + ":"
   REDEFINE SAY ID 171 OF oFld:aDialogs[i] PROMPT GL("Expression") + ":"
   REDEFINE SAY ID 172 OF oFld:aDialogs[i] PROMPT GL("Description") + ":"

   endif

   ACTIVATE DIALOG oDlg CENTER ;
      ON INIT IIF( lTake = .F., oSay1:Hide, .T. )

   if !EMPTY( creturn )
      creturn := "[" + ALLTRIM(STR( nTyp , 1 )) + "]" + ALLTRIM( creturn )
   ELSEif !EMPTY( cAltText )
      creturn := cAltText
   endif


   close( cAliasGen  )

   if nShowExpr = 1
       close( cAliasUser )
   endif

   SELECT( nAltSel )
   oFont:End()
   aUndo := {}

return ( creturn )

//------------------------------------------------------------------------------

FUNCTION cargaUserGet(aVar,cAliasUser )

   aVar[1]:= ( cAliasUser )->NAME
   aVar[2] := ( cAliasUser )->EXPRESSION
   aVar[3]:= ( cAliasUser )->INFO


RETURN

//------------------------------------------------------------------------------

FUNCTION GrabaUserGet(aVar,cAliasUser )
 IF ( cAliasUser )->( RLock() )
    ( cAliasUser )->NAME :=  aVar[1]
    ( cAliasUser )->EXPRESSION :=  aVar[2]
    ( cAliasUser )->INFO :=  aVar[3 ]
   (cAliasUser)->( dbUnlock() )
   RETURN .t.
ENDIF

RETURN .f.


//------------------------------------------------------------------------------

Function ER_Inspector( nD, oDlg )
//LOCAL oDlg   := oER:oFldD:aDialogs[ nD ]
LOCAL aProps := GetAreaProperties( oER:nAktArea )
Local oFont
Local lTr    := .T.
if oDlg == NIL
   lTr  := .F.
endif

DEFAULT oDlg   := oER:oFldD:aDialogs[ nD ]

DEFINE FONT oFont NAME "Verdana" SIZE 0, -11  //"Segoe UI BOLD"

if !empty( nD )
   @ 8, 3 SAY oER:oSaySelectedItem PROMPT "Area/Item" SIZE 140, 20 OF oDlg FONT oFont pixel //COLOR CLR_BLACK//TRANSPARENT //(+ aProps[1,2] FONT oFont
endif

@ if( !empty( nD ), 34.5, 2.5 ), 1 XBROWSE oER:oBrwProp ;
      SIZE oDlg:nWidth - 1, if( lTr, Int(oDlg:nHeight/2) - 25, oDlg:nHeight - 35) ;
      COLSIZES 95, 195 ;
      AUTOCOLS ;
      HEADERS " " + GL("Property"), " " + GL("Value") ;
      ARRAY aProps OF oDlg ;
      FONT oFont CELL PIXEL //NOBORDER
   // ON CHANGE SetEditType( oER:oBrw )

   oER:oBrwProp:nMarqueeStyle    = MARQSTYLE_HIGHLROW
   oER:oBrwProp:nColDividerStyle = LINESTYLE_DARKGRAY
   // oBrw:aCols[ 1 ]:bLDClickData = { || oER:oBrw:aCols[ 2 ]:Edit() }
   // oBrw:oCol( "Property" ):bLDClickData := { || oER:oBrw:Value:Edit() }
   oER:oBrwProp:lRecordSelector = .T.
   oER:oBrwProp:SetColor( 0, RGB( 224, 236, 255 ) )
   oER:oBrwProp:lHScroll            := .F.

   oER:oBrwProp:aCols[2]:nEditType   := EDIT_GET
   oER:oBrwProp:aCols[2]:bOnPostEdit := { | oCol, xVal, nKey | ActionPostEdit( nKey, xVal ) }

   oER:oBrwProp:Cargo:= Array(3)

   oER:oBrwProp:CreateFromCode()


RETURN oER:oBrwProp

//------------------------------------------------------------------------------

FUNCTION ActionPostEdit( nKey, xVal )
   LOCAL nReg := oER:oBrwProp:nArrayAt
   LOCAL nArea,cAreaIni, nItem
   local cOldAreaText

   IF nKey == VK_RETURN

      IF oER:oBrwProp:cargo[1] =="area"
         nArea:= oER:oBrwProp:Cargo[2]
         cOldAreaText  := MEMOREAD( oER:aAreaIni[ nArea ] )
         oER:oBrwProp:aArrayData[nReg,2] := xVal
         SetAreaProperties( nArea, oER:oBrwProp:aArrayData , , cOldAreaText )
         RefreshBrwAreaProp( nArea )

      ELSEIF oER:oBrwProp:cargo[1] == "item"

         cAreaIni:= oER:oBrwProp:Cargo[2]
         nItem:= oER:oBrwProp:Cargo[3]
        // oER:oBrwProp:aArrayData[nReg,2] := xVal
         SetPropItem( nItem , cAreaIni, xVal )
         RefreshBrwProp( nItem , cAreaIni )


      endif

   ENDIF

RETURN nil
//------------------------------------------------------------------------------

FUNCTION RefreshBrwAreaProp(nArea)
   /*
   LOCAL aProps:= getAreaProperties(nArea)
   oER:oBrwProp:Cargo[1]:=  "area"
   oER:oBrwProp:Cargo[2]:=  nArea
   oER:oBrwProp:setArray(aProps)
   oER:oBrwProp:refresh()

   oER:oSaySelectedItem:setText( aProps[1,2] )
   */
Return .T.

//------------------------------------------------------------------------------

Function CargaItems( aTree, aElem, aBmps )
   Local x
   Local n
   Local aTemp  := {}

  //? Len( aItems ), Len( aItems[ 1 ] )
  For x = 1 to Len( aElem )
      if !empty( aElem[ x ] )
         if Valtype( aElem[ x ] ) = "O"
            AAdd( aTemp, Space( aElem[ x ]:ItemLevel() * 5 ) + aElem[ x ]:cPrompt )
            AAdd( aTemp, aElem[ x ]:ItemLevel() )
            AAdd( aTree, aTemp )
            aTemp := {}
            if !empty( aElem[ x ]:aItems )
               CargaItems( aTree, aElem[ x ]:aItems, aBmps )
            endif
         endif
      endif
  Next x

Return aTree

//------------------------------------------------------------------------------

function ER_Expressions( lTake, cAltText, nD )

   local i
   local oDlg
   local oFld
   local oBrw
   local oBrw2
   local oBrw3
   local oFont
   local creturn
   local oSay1
   local nTyp
   local oGet1
   local oBtn1
   local aBtn[3]
   local aGet[5]
   local cName
   local nAltSel    := SELECT()
   local nShowExpr  := VAL( oER:GetDefIni( "General", "Expressions", "0" ) )
   local cGenExpr   := ALLTRIM( oEr:cDataPath + oER:GetDefIni( "General", "GeneralExpressions", "General.dbf" ) )
   local cUserExpr  := ALLTRIM( oEr:cDataPath + oER:GetDefIni( "General", "UserExpressions", "User.dbf") )
   local aUndo      := {}
   local cErrorFile := ""
   local nFil       := 0
   local oGet0
   local oGet2
   local x
   local cExpr      := ""
   local aBmps1     := {}
   local aBtts1     := {"="    , "<>"   , "<"    , ">"   , "<="  , ">="  , "=="  , "("   , ")"   ,;
                        '"'    , "!"    , "$"    , "+"   , "-"   , "*"   , "/"   , ".T." , ".F." ,;
                        ".or." , ".and.", ".not.", "If(,,)", "Val()"  , "Str()" }



   local nCol
   LOCAL cAliasGen, cAliasUsr

   //local aRDD      := { "DBFNTX", "COMIX", "DBFCDX" }

   DEFAULT cAltText := ""
   DEFAULT lTake    := .F.
   DEFAULT nD := 2
   oDlg       := oER:oFldD:aDialogs[ nD ]
   oDlg:SetColor( CLR_BLACK, oEr:nClrPaneTree )

   aUndo      := {}

   if FILE( VRD_LF2SF( cGenExpr ) ) = .F.
      cErrorFile += cGenExpr + CRLF
   endif
   if FILE( VRD_LF2SF( cUserExpr ) ) = .F.
      cErrorFile += cUserExpr + CRLF
   endif

   if !EMPTY( cErrorFile )
      MsgStop( GL("This file(s) could no be found:") + CRLF + CRLF + cErrorFile, GL("Stop!") )
      return( cAltText )
   endif

   DEFINE FONT oFont NAME "Verdana" SIZE 0, -10

   /*
   @ oDlg:nHeight - 30 , oDlg:nWidth - 110 BTNBMP PROMPT "&OK" ;
            OF oDlg SIZE 100, 20 PIXEL //;
            //ACTION ( oDlg:End() )
   */

   if nShowExpr = 2

       @ 4, 1 FOLDER oFld OF oDlg ;
         PROMPT " " + GL("General") + " ", ;
                " " + GL("User defined") + " " ;
         SIZE oDlg:nWidth - 2, oDlg:nHeight - 5 ;
         OPTION 1 ;
         PIXEL

   ELSE
      if  lValidFwh()

         @ 4, 1 CFOLDEREX oFld ;
           PROMPT " " + GL("General") + " ", " " + GL("User defined") + " " ;
           OF oDlg ;
           SIZE oDlg:nWidth - 2, oDlg:nHeight - 5 ;
           OPTION 1 ;
           TAB HEIGHT 24 ;  //           BITMAPS { "B_EDIT2", "B_EDIT1" } ;
           PIXEL ;
           SEPARATOR 0

      else

         @ 4, 1 FOLDER oFld ;
           PROMPT " " + GL("General") + " ", " " + GL("User defined") + " " ;
           OF oDlg ;
           SIZE oDlg:nWidth - 2, oDlg:nHeight - 5 ;
           OPTION 1 ;
           PIXEL

      endif

   endif

   oFld:aDialogs[1]:SetColor( CLR_BLACK, oEr:nClrPaneTree )
   oFld:aDialogs[2]:SetColor( CLR_BLACK, oEr:nClrPaneTree )


   cAliasGen := OpenDbf(  VRD_LF2SF( cGenExpr )  )

  // SELECT 0
  // USE ( VRD_LF2SF( cGenExpr ) ) ALIAS "GENEXPR" SHARED

   @ 6, 4 SAY oSay1 ;
      PROMPT GL("Please doubleclick an expression to take it over.") ;
      SIZE 280, 20 ;
      OF oFld:aDialogs[1] FONT oFont PIXEL TRANSPARENT


   @ 30, 1 XBROWSE oBrw ;
      OF oFld:aDialogs[1] ;
      SIZE oFld:aDialogs[1]:nWidth - 1, oFld:aDialogs[1]:nHeight - 70 ;
      FIELDS ( cAliasGen )->NAME, ( cAliasGen )->INFO ;
      COLSIZES 95, 195 ;
      HEADERS " " + GL("Name"), " " + GL("Description") ;
      FONT oFont PIXEL ; //NOBORDER  ;
      ON LEFT DBLCLICK ( creturn := ( cAliasGen )->NAME, nTyp := 1, oDlg:End() )

   oBrw:lRecordSelector   := .F.
   oBrw:lHScroll          := .F.
   //oBrw:lVScroll          := .F.

   oBrw:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, ;
                     EVAL( {|| creturn := ( cAliasGen )->NAME, nTyp := 1, oDlg:End() } ), .T. ) }

   oBrw:CreateFromCode()

   if nShowExpr = 1

   i := 2

   cAliasUsr := OpenDbf(  VRD_LF2SF( cUserExpr )  )

  // SELECT 0
  // USE ( VRD_LF2SF( cUserExpr ) ) ALIAS "USEREXPR" SHARED

   @ 4, oFld:aDialogs[i]:nWidth - 100 BTNBMP PROMPT GL("&New") ;
            OF oFld:aDialogs[i] SIZE 80, 20 PIXEL ;
            ACTION ( ( cAliasUsr )->(DBAPPEND()), oBrw2:Refresh(), oBrw2:GoBottom(), oDlg:Update() )

   @ 4, oFld:aDialogs[i]:nWidth - 190 BTNBMP PROMPT GL("&Delete") ;
            OF oFld:aDialogs[i] SIZE 80, 20 PIXEL ;
            ACTION ( ( cAliasUsr )->(DBDELETE()), ;
               ( cAliasUsr )->(DBSKIP(-1)), oBrw2:Refresh(), oDlg:Update() )

   @ 30, 1 XBROWSE oBrw2 ;
      OF oFld:aDialogs[i] ;
      SIZE oFld:aDialogs[i]:nWidth - 1, Int( ( oFld:aDialogs[i]:nHeight - 1 ) / 2 ) - 60 ;
      FIELDS ( cAliasUsr )->NAME, ( cAliasUsr )->INFO ;
      COLSIZES 95, 195 ;
      HEADERS " " + GL("Name"), " " + GL("Description") ;
      FONT oFont PIXEL NOBORDER ;
      ON CHANGE ( oDlg:Update(), aUndo := {} ) ;
      ON LEFT DBLCLICK ( creturn := ( cAliasUsr )->NAME, nTyp := 2, oDlg:End() )

   oBrw2:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, ;
                      EVAL( {|| creturn := ( cAliasUsr )->NAME, nTyp := 2, oDlg:End() } ), .T. ) }

   oBrw2:lRecordSelector   := .F.
   oBrw2:lHScroll          := .F.
   //oBrw2:lVScroll          := .F.
   //oBrw2:nRowHeight        := 48
   oBrw2:CreateFromCode()

   nFil   :=  Int( ( oFld:aDialogs[i]:nHeight - 1 ) / 2 ) - 20  // + 40
   @ nFil + 2, 1 SAY GL("Name") + ":" ;
      SIZE 80, 20 ;
      OF oFld:aDialogs[i] FONT oFont PIXEL TRANSPARENT

   //nFil += 20
   @ nFil, 71 GET oGet0 VAR ( cAliasUsr )->NAME OF oFld:aDialogs[i] UPDATE PIXEL ;
      SIZE oFld:aDialogs[i]:nWidth - 71, 16 ;
      FONT oFont ;
      VALID ( oBrw2:Refresh(), .T. )

   nFil += 20
   @ nFil + 2, 1 SAY GL("Expression") + ":" ;
      SIZE 200, 20 ;
      OF oFld:aDialogs[i] FONT oFont PIXEL TRANSPARENT

   nFil += 20
   @ nFil, 1 GET oGet1 VAR ( cAliasUsr )->EXPRESSION  OF oFld:aDialogs[i] UPDATE PIXEL ;
      SIZE oFld:aDialogs[i]:nWidth - 1, 48 ;
      FONT oFont ;
      VALID ( oBrw2:Refresh(), .T. )

   nFil += 50
   @ nFil + 2, 1 SAY GL("Description") + ":" ;
      SIZE 200, 20 ;
      OF oFld:aDialogs[i] FONT oFont PIXEL TRANSPARENT

   nFil += 20
   @ nFil, 1 GET oGet2 VAR ( cAliasUsr )->INFO OF oFld:aDialogs[i] UPDATE PIXEL ;
      SIZE oFld:aDialogs[i]:nWidth - 1, 48 ;
      FONT oFont ;
      VALID ( oBrw2:Refresh(), .T. )

   nFil += 55
   nCol := 1

   For x = 1 to Len( aBtts1 )
       AAdd( aBmps1, nil )
       aBmps1[ x ] := TBtnBmp():New( nFil, nCol, 30, 20,;
                                    ,,,,;
                                    ,oFld:aDialogs[i],,,,,;
                                    aBtts1[x],,,, .T.,,;
                                    ,,,.T.,,;
                                    ,,.T., )

       aBmps1[ x ]:bAction := SetMi2Expr( aBtts1, oGet1, aUndo, x )

       nCol += 40
       if Mod( x, 8 ) = 0
          nFil := nFil + 30
          nCol := 1
       endif

   Next x

   @ oFld:aDialogs[i]:nHeight - 24 , oFld:aDialogs[i]:nWidth - 110 BTNBMP PROMPT GL("Check") ;
            OF oFld:aDialogs[i] SIZE 100, 20 PIXEL ;
            ACTION CheckExpression( ( cAliasUsr )->EXPRESSION )

   @ oFld:aDialogs[i]:nHeight - 24 , 10 BTNBMP PROMPT GL("Undo") ;
            WHEN LEN( aUndo ) > 0 ;
            OF oFld:aDialogs[i] SIZE 100, 20 PIXEL ;
            ACTION aUndo := UnDoExpression( oGet1, aUndo )

   endif

 //  GENEXPR->(DBCLOSEAREA())

 //  if nShowExpr = 1
 //     USEREXPR->(DBCLOSEAREA())
 //  endif

   SELECT( nAltSel )
   oFont:End()
   aUndo := {}

return ( creturn )

//------------------------------------------------------------------------------

Function SetMi2Expr( aBtts1, oGet1, aUndo , x )
Return { || CopyToExpress( aBtts1[ x ], oGet1, @aUndo ) }

//------------------------------------------------------------------------------

function CheckExpression( cText )

   Local lReturn
   Local xReturn
   Local oScript

   //oScript := TScript():New( "function TEST()" + CRLF + cText + CRLF + "return" )
   if empty( AT( "FUNCTION", Upper( cText ) ) )
      oScript := TErScript():New( "function TEST()" + CRLF + cText + CRLF + "return" )
   else
      oScript := TErScript():New( cText )
   endif
   oScript:Compile()

   if EMPTY( oScript:cError )
      MsgWait( GL("Correct expression"), GL("Check"), 1.5 )
      lreturn := .T.
   ELSE
      MsgStop( GL("Incorrect expression"), GL("Check") )
      lreturn := .F.
   endif

return lReturn

//-----------------------------------------------------------------------------

function DBPack()
   PACK
return .T.

//-----------------------------------------------------------------------------

/*  no usado
function DBReplace( cReplFeld, xAusdruck )

   REPLACE &cReplFeld with xAusdruck

return .T.
*/

//-----------------------------------------------------------------------------

function CopyToExpress( cText, oGet, aUndo )
local uVar := ""

   AADD( aUndo, oGet:cText )
   if empty( oGet:Value )
      oGet:cText( " " )
   endif

   uVar := RTrim( oGet:Value ) + cText
   oGet:cText( uVar )
   oGet:SetFocus()
   oGet:Paste( cText )
   //oGet:Refresh()
   //oGet:SetPos( oGet:nPos + LEN( cText ) )
   oGet:SetPos( Len( uVar ) + 1 )

return .T.

//-----------------------------------------------------------------------------

function UnDoExpression( oGet, aUndo )

   if Len( aUndo ) > 0
      if !EMPTY( ATAIL( aUndo ) )
         oGet:cText( ATAIL( aUndo ) )
         oGet:Refresh()
         ASIZE( aUndo, Len( aUndo ) - 1 )
      endif
   endif

   oGet:SetFocus()

return ( aUndo )


//------------------------------------------------------------------------------

function EditLanguage()

  FWEditHStrings()

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

   if Upper( ValType( oER:nMeasure ) ) = "L" .or. ;
      Upper( ValType( oER:nMeasure ) ) = "O" .or. ;
      empty( oER:nMeasure )
      oER:nMeasure := 1
   endif

   Do Case
      Case oER:nMeasure = 1
           //mm
           nValue := nValue * 3
      Case oER:nMeasure = 2
           //Inch
           nValue := nValue * 100
      Otherwise
           nValue := nValue * 1
   EndCase

return ( nValue )

//-----------------------------------------------------------------------------

function GetCmInch( nValue )

   if oER:nMeasure = 1
      //mm
      nValue := ROUND( nValue / 3, 0 )
   ELSEif oER:nMeasure = 2
      //Inch
      nValue := ROUND( nValue / 100, 2 )
   elseif oER:nMeasure = 3
      // OJO
      nValue := Round( nValue, 0 )
   endif

return ( nValue )

//------------------------------------------------------------------------------

function GetField( cString, nNr, cSepChar )

   DEFAULT cSepChar := "|"

return StrToken( cString, nNr, cSepChar )

//------------------------------------------------------------------------------

function SetField( cString, cNewToken, nNr, cSepChar )
    LOCAL aTokens, cToken
    LOCAL cNewString:= ""
   DEFAULT cSepChar := "|"

IF hb_TokenCount(cString,cSepChar) < nNr
      aTokens:= hb_atokens( cString, cSepChar )
      aTokens[nNr]:= cNewToken
      FOR EACH cToken IN aTokens
           cNewString += cToken+cSepChar
      NEXT
      cNewString:=Left( cNewString, Len( cNewString ) - 1 )
endif
return cNewString



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


function OpenLanguage()
   LOCAL aStrings:= FWGetStrings()
   Local i, n, nLen
   LOCAL aNames:= {}
   LOCAL cName
   LOCAL aLanguages
   LOCAL hLanguages

    oGenVar:aLanguages  := {}

   FOR i = 1 TO Len(aStrings  )
        nLen:= Len(aStrings[i])


        AADD( oGenVar:aLanguages, { aStrings[i,1],;
                                    IF( nLen < 5 , aStrings[i,1] ,aStrings[i,5]) ,;
                                    IF( nLen < 6 , aStrings[i,1] ,aStrings[i,6]),;
                                    IF( nLen < 2 , aStrings[i,1] ,aStrings[i,2]),;
                                    IF( nLen < 4 , aStrings[i,1] ,aStrings[i,4]),;
                                    IF( nLen < 3 , aSTrings[i,1] ,aStrings[i,3]) } )
     next

     //aLanguages :=  ER_LoadStrings()

      hLanguages :=  ER_LoadStrings()



   FOR EACH aNames IN hLanguages
      nlen:= Len(aNames)
      AADD( oGenVar:aLanguages, { aNames[1],;
                                    IF( nLen < 5 , aNames[1] ,aNames[5]) ,;
                                    IF( nLen < 6 ,  aNames[1] ,aNames[6]) ,;
                                    IF( nLen < 2 , aNames[1] ,aNames[2]) ,;
                                    IF( nLen < 4 ,  aNames[1] ,aNames[4]) ,;
                                    IF( nLen < 3 ,  aNames[1] ,aNames[3] ) } )




   NEXT

  /*
     FOR i = 1 TO Len(aLanguages  )

        nLen:= Len(alanguages[i])


        AADD( oGenVar:aLanguages, { aLanguages[i,1],;
                                    IF( nLen < 5 , aLanguages[i,1] ,aLanguages[i,5]) ,;
                                    IF( nLen < 6 , aLanguages[i,1] ,aLanguages[i,6]),;
                                    IF( nLen < 2 , aLanguages[i,1] ,aLanguages[i,2]),;
                                    IF( nLen < 4 , aLanguages[i,1] ,aLanguages[i,4]),;
                                    IF( nLen < 3 , aLanguages[i,1] ,aLanguages[i,3]) } )


        next

      */


  //  msginfo(Len(  oGenVar:aLanguages   ))

return .T.

//------------------------------------------------------------------------------

function GL( cOriginal )

   local cAltText := cOriginal   //strtran( cOriginal, " ", "_" )
   local cText    := cAltText
   LOCAL aLanguage
   LOCAL hLanguage
   LOCAL npos
   LOCAL lshort := .f.
   LOCAL aNames := {}


     if '&' $ cAltText
            lshort := .t.
            cAltText  := StrTran( cAltText, '&', '' )
     ENDIF


   nPos  := ASCAN( oGenVar:aLanguages, ;
                            { |aVal| ALLTRIM( aVal[1] ) == ALLTRIM( cAltText ) } )

   if nPos = 0

      hLanguage :=  ER_LoadStrings()
      hlanguage[cAltText]:= { cAltText,,,,, }

      FWSaveHStrings( , hLanguage )
      OpenLanguage()

   ELSE

      cText := oGenVar:aLanguages[ nPos, oGenVar:nLanguage ]
      if EMPTY( cText )
         cText := oGenVar:aLanguages[ nPos, 1 ]
      endif

   endif


return  IF( lshort, '&',"") + ALLTRIM( cText )  //( STRTRAN(ALLTRIM( cText ), "_", " " ) )

//------------------------------------------------------------------------------

function ER_LoadStrings( cFileName )

   local cLine, n := 1
   local aLanguage := {}
   LOCAL hLanguage := {=>}
   LOCAL aNames:={}


   DEFAULT cFileName := cFilePath( GetModuleFileName( GetInstance() ) ) + ;
                        "fwstrings.ini"

      while ! Empty( cLine := GetPvProfString( "strings", AllTrim( Str( n++ ) ), "", cFileName ) )
         aNames:=  { AllTrim( StrToken( cLine, 1, "|" ) ),;
                        AllTrim( StrToken( cLine, 2, "|" ) ),;
                        AllTrim( StrToken( cLine, 3, "|" ) ),;
                        AllTrim( StrToken( cLine, 4, "|" ) ),;
                        AllTrim( StrToken( cLine, 5, "|" ) ),;
                        AllTrim( StrToken( cLine, 6, "|" ) ) }

         hLanguage[aNames[1]]:= aNames

   end

RETURN hLanguage

//------------------------------------------------------------------------------

function PrintReport( lPreview, lDeveloper, lPrintDlg, LPrintIDs, cScript )

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
   oVrd:lNoExpr = .F.

   if oVRD:lDialogCancel
      return( .F. )
   endif

  IF !EMPTY( cScript ) .AND. !FILE( cScript )
      MsgStop( "Script not found:" + CRLF + CRLF + cScript )
      QUIT
   ENDIF

   IF !Empty(cScript)

       RunScript( cScript, oVrd )

   else

   //erste Seite
   for i := 1 TO LEN( oVRD:aAreaInis )
      if GetDataArea( "General", "Condition", "0", oVRD:aAreaInis[i] ) <> "4"
         PRINTAREA i OF oVRD
      endif

   NEXT

   //zweite Seite
   if IsSecondPage( oVRD )

      oVRD:PageBreak()

      for i := 1 TO LEN( oVRD:aAreaInis )
         cCondition := GetDataArea( "General", "Condition", "0", oVRD:aAreaInis[i] )
         if cCondition = "1" .OR. cCondition = "4"
            PRINTAREA i OF oVRD
         endif
      NEXT

   endif
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

      if GetDataArea( "General", "Condition", "0", oVRD:aAreaInis[i] ) <> "4"
         oVRD:PrintArea( i )
      endif

   NEXT

   //zweite Seite
   if IsSecondPage( oVRD )

      oVRD:PageBreak()

      for i := 1 TO LEN( oVRD:aAreaInis )
         cCondition := GetDataArea( "General", "Condition", "0", oVRD:aAreaInis[i] )
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

      if GetDataArea( "General", "Condition", "0", oVRD:aAreaInis[i] ) = "4"
         lreturn := .T.
         EXIT
      endif

   NEXT

return ( lreturn )

//------------------------------------------------------------------------------

function OpenUndo()

   local nSelect := SELECT()
   LOCAL aDbf := {;
                 { "ENTRYTEXT" , "C",   250,    0 },;
                 { "ENTRYNR"   , "N",     5,    0 },;
                 { "AREANR"    , "N",     5,    0 },;
                 { "AREATEXT"  , "M",    10,    0 } }

  // LOCAL cPath :=

   oGenVar:AddMember( "cUndoFileName",, oER:cTmppath + cTempFile() )
   oGenVar:AddMember( "cRedoFileName",, oER:cTmpPath + cTempFile() )

   DBCreate( oGenVar:cUndoFileName + ".dbf" ,aDbf )
   DBCreate( oGenVar:cRedoFileName + ".dbf" ,aDbf )

 //  TMPREDO->(DBCLOSEAREA())

   SELECT( nSelect )

return .T.

//------------------------------------------------------------------------------

function CloseUndo()

  FErase( ".\" + oGenVar:cUndoFileName + ".dbf" )
  FErase( ".\" + oGenVar:cUndoFileName + ".dbt" )
  FErase( ".\" + oGenVar:cRedoFileName + ".dbf" )
  FErase( ".\" + oGenVar:cRedoFileName + ".dbt" )

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

   if !empty( oEr:oMainWnd:oBar )
      oEr:oMainWnd:oBar:AEvalWhen()
   endif

return .T.

//------------------------------------------------------------------------------


Function DelTempFiles(cPath)
Local aDirName := DIRECTORY ( cPath+"*.*"  , "D" )
   AEVAL ( aDirName, {| aFich |  FErase( cpath + aFich[1] ) } )
 //  SysRefresh()
Return nil


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
   REPLACE TMPREDO->ENTRYTEXT WITH ALLTRIM( GetDataArea( ;
      "Items", ALLTRIM(STR(TMPUNDO->ENTRYNR,5)) , "", oER:aAreaIni[ TMPUNDO->AREANR ] ) )
   REPLACE TMPREDO->ENTRYNR   WITH TMPUNDO->ENTRYNR
   REPLACE TMPREDO->AREANR    WITH TMPUNDO->AREANR
   REPLACE TMPREDO->AREATEXT  WITH MEMOREAD( oER:aAreaIni[ TMPUNDO->AREANR ] )

   SELECT TMPUNDO

   if TMPUNDO->ENTRYNR = 0

      //Area undo
      nOldWidth  := VAL( GetDataArea( "General", "Width", "600", oER:aAreaIni[ TMPUNDO->AREANR ] ) )
      nOldHeight := VAL( GetDataArea( "General", "Height", "300", oER:aAreaIni[ TMPUNDO->AREANR ] ) )

      MEMOWRIT( oER:aAreaIni[ TMPUNDO->AREANR ], TMPUNDO->AREATEXT )

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
      DelEntryArea( "Items", ALLTRIM(STR(TMPUNDO->ENTRYNR,5)), oER:aAreaIni[ TMPUNDO->AREANR ] )

   ELSE

      if oER:aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ] <> NIL
         DeleteItem( TMPUNDO->ENTRYNR, TMPUNDO->AREANR, .T.,, .T. )
      endif

      INI oIni FILE oER:aAreaIni[ TMPUNDO->AREANR ]
         SET SECTION "Items" ENTRY ALLTRIM(STR(TMPUNDO->ENTRYNR,5)) TO TMPUNDO->ENTRYTEXT OF oIni
      ENDINI

      oItemInfo := VRDItem():New( TMPUNDO->ENTRYTEXT )

      if oItemInfo:nShow = 1
         oER:aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ] := NIL
         ShowItem( TMPUNDO->ENTRYNR, TMPUNDO->AREANR, oER:aAreaIni[ TMPUNDO->AREANR ], aFirst, nElemente )
         if oER:aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ] != nil
            oER:aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ]:lDrag := .T.
         endif   
      endif

   endif

   DELETE
   PACK

   RefreshUndo()
   RefreshRedo()
   if !empty( oEr:oMainWnd:oBar )
      oEr:oMainWnd:oBar:AEvalWhen()
   endif

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
   REPLACE TMPUNDO->ENTRYTEXT WITH ALLTRIM( GetDataArea( ;
      "Items", ALLTRIM(STR(TMPREDO->ENTRYNR,5)) , "", oER:aAreaIni[ TMPREDO->AREANR ] ) )
   REPLACE TMPUNDO->ENTRYNR   WITH TMPREDO->ENTRYNR
   REPLACE TMPUNDO->AREANR    WITH TMPREDO->AREANR
   REPLACE TMPUNDO->AREATEXT  WITH MEMOREAD( oER:aAreaIni[ TMPREDO->AREANR ] )

   SELECT TMPREDO

   if TMPREDO->ENTRYNR = 0

      //Area redo
      nOldWidth  := VAL( GetDataArea( "General", "Width", "600", oER:aAreaIni[ TMPREDO->AREANR ] ) )
      nOldHeight := VAL( GetDataArea( "General", "Height", "300", oER:aAreaIni[ TMPREDO->AREANR ] ) )

      MEMOWRIT( oER:aAreaIni[ TMPREDO->AREANR ], TMPREDO->AREATEXT )
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
      DelIniEntry( "Items", ALLTRIM(STR(TMPREDO->ENTRYNR,5)), oER:aAreaIni[ TMPREDO->AREANR ] )

   ELSE

      if oER:aItems[ TMPUNDO->AREANR, TMPUNDO->ENTRYNR ] <> NIL
         DeleteItem( TMPREDO->ENTRYNR, TMPREDO->AREANR, .T.,, .T. )
      endif

      INI oIni FILE oER:aAreaIni[ TMPREDO->AREANR ]
         SET SECTION "Items" ENTRY ALLTRIM(STR(TMPREDO->ENTRYNR,5)) TO TMPREDO->ENTRYTEXT OF oIni
      ENDINI

      oItemInfo := VRDItem():New( TMPREDO->ENTRYTEXT )

      if oItemInfo:nShow = 1
         oER:aItems[ TMPREDO->AREANR, TMPREDO->ENTRYNR ] := NIL
         ShowItem( TMPREDO->ENTRYNR, TMPREDO->AREANR, oER:aAreaIni[ TMPREDO->AREANR ], aFirst, nElemente )
         oER:aItems[ TMPREDO->AREANR, TMPREDO->ENTRYNR ]:lDrag := .T.
      endif

   endif

   DELETE
   PACK

   RefreshUndo()
   RefreshRedo()
   if !empty( oEr:oMainWnd:oBar )
      oEr:oMainWnd:oBar:AEvalWhen()
   endif

   TMPUNDO->(DBCLOSEAREA())
   TMPREDO->(DBCLOSEAREA())
   SELECT( nSelect )

return .T.

//-----------------------------------------------------------------------------

function RefreshUndo()

   oER:nUndoCount := TMPUNDO->(LASTREC())

return .T.

//-----------------------------------------------------------------------------

function RefreshRedo()

   oER:nRedoCount := TMPREDO->(LASTREC())

return .T.

//-----------------------------------------------------------------------------

function ClearUndoRedo()

   local nSelect := SELECT()

   SELECT 0
   USE ( oGenVar:cUndoFileName + ".dbf" ) ALIAS TMPUNDO
   ZAP

   USE ( oGenVar:cRedoFileName + ".dbf" ) ALIAS TMPREDO
   ZAP

   TMPREDO->(DBCLOSEAREA())
   SELECT( nSelect )

   oER:nUndoCount := 0
   oER:nRedoCount := 0

   if !empty( oEr:oMainWnd:oBar )
      oEr:oMainWnd:oBar:AEvalWhen()
   endif

return .T.

//--------------------------------------------------------------------------

function UndoRedoMenu( nTyp, oBtn )

   local i, oMenu
   local cText1 := "" //IIF( nTyp = 1, GL("Undo"), GL("Redo") )
   local cText2 := IIF( nTyp = 1, GL("Undo all"), GL("Redo all") )
   local nCount := IIF( nTyp = 1, oEr:nUndoCount, oEr:nRedoCount )
   local aRect  := GetClientRect( oBtn:hWnd )

   MENU oMenu POPUP

      MENUITEM cText1 + "1 " + GL("action") ;
         WHEN IIF( nTyp = 1, oEr:nUndoCount, oEr:nRedoCount ) > 0 ;
         ACTION MultiUndoRedo( nTyp, 1 )
      MENUITEM cText1 + "2 " + GL("actions") ;
         WHEN IIF( nTyp = 1, oEr:nUndoCount, oEr:nRedoCount ) > 1 ;
         ACTION MultiUndoRedo( nTyp, 2 )
      MENUITEM cText1 + "3 " + GL("actions") ;
         WHEN IIF( nTyp = 1, oEr:nUndoCount, oEr:nRedoCount ) > 2 ;
         ACTION MultiUndoRedo( nTyp, 3 )
      MENUITEM cText1 + "4 " + GL("actions") ;
         WHEN IIF( nTyp = 1, oEr:nUndoCount, oEr:nRedoCount ) > 3 ;
         ACTION MultiUndoRedo( nTyp, 4 )
      MENUITEM cText1 + "5 " + GL("actions") ;
         WHEN IIF( nTyp = 1, oEr:nUndoCount, oEr:nRedoCount ) > 4 ;
         ACTION MultiUndoRedo( nTyp, 5 )
      MENUITEM cText1 + "6 " + GL("actions") ;
         WHEN IIF( nTyp = 1, oEr:nUndoCount, oEr:nRedoCount ) > 5 ;
         ACTION MultiUndoRedo( nTyp, 6 )
      MENUITEM cText1 + "7 " + GL("actions") ;
         WHEN IIF( nTyp = 1, oEr:nUndoCount, oEr:nRedoCount ) > 6 ;
         ACTION MultiUndoRedo( nTyp, 7 )
      MENUITEM cText1 + "8 " + GL("actions") ;
         WHEN IIF( nTyp = 1, oEr:nUndoCount, oEr:nRedoCount ) > 7 ;
         ACTION MultiUndoRedo( nTyp, 8 )
      MENUITEM cText1 + "9 " + GL("actions") ;
         WHEN IIF( nTyp = 1, oEr:nUndoCount, oEr:nRedoCount ) > 8 ;
         ACTION MultiUndoRedo( nTyp, 9 )
      MENUITEM cText1 + "10 " + GL("actions") ;
         WHEN IIF( nTyp = 1, oEr:nUndoCount, oEr:nRedoCount ) > 9 ;
         ACTION MultiUndoRedo( nTyp, 10 )

      MENUITEM cText2 ACTION MultiUndoRedo( nTyp, IIF( nTyp = 1, oEr:nUndoCount, oEr:nRedoCount ) )

   ENDMENU

   ACTIVATE POPUP oMenu AT aRect[3], aRect[2] OF oBtn

return( oMenu )

//------------------------------------------------------------------------------

function MultiUndoRedo( nTyp, nCount )

   local i

   for i := 1 TO nCount
      IIF( nTyp = 1, Undo(), Redo() )
   NEXT

   return .T.

//------------------------------------------------------------------------------

FUNCTION RunScript( cScript, oVrd )

   LOCAL oScript := TErScript():New( MEMOREAD( cScript ) )

   oScript:lPreProcess := .T.
   oScript:Compile()

   IF !EMPTY( oScript:cError )
      MsgStop( "Error in script:" + CRLF + CRLF + ALLTRIM( oScript:cError ), "Error" )
   ELSE
      oScript:Run( "Script", oVRD )
   ENDIF

RETURN .T.

//------------------------------------------------------------------------------

Function RndMsg( cCaption, cBmp ,nExpRow  )
   LOCAL nHeight := IF( Empty( cBmp ), 4, 11 )
   LOCAL nTextSize,nDlgSize,oSay

   STATIC lOn := .F.
   STATIC oRndDlg,oFont14

   DEFAULT nExpRow:= 50

   if Empty( cCaption )
      if !Empty( oRndDlg )
          lOn := .T.
      endif
   endif

   if lOn
        oRndDlg:End()
        oFont14:End()
        lOn := .F.
        sysrefresh()
        Return NIL
   endif

   IF cCaption == NIL; cCaption := FWString("Please, wait...") ; ENDIF

   cCaption := Alltrim(cCaption)

   DEFINE FONT oFont14 NAME "Verdana" SIZE 0,-14 BOLD

   SetDlgGradient()

   DEFINE DIALOG oRndDlg ;
      FROM 0,0 TO ( nHeight * 16 ) ,( Len( cCaption ) * 16 )  ;
      STYLE nOR( WS_POPUP, DS_SYSMODAL ) ;
      FONT oFont14  COLOR 0,CLR_BLACK PIXEL

     oRndDlg:nOpacity:= 200

      nTextSize := oRndDlg:GetWidth( cCaption, oFont14 )
      nDlgSize := IF( ( nTextsize ) < 150 , 150, nTextSize )


      @ ( oRndDlg:nHeight() /2 ) - IF( !Empty( cBmp ), 16, 20 ) , ( ( nDlgsize + nExpRow ) / 4 ) - ( nTextSize /4 ) ;
            SAY osay PROMPT cCaption OF oRndDlg ;
            FONT oFont14 COLOR CLR_WHITE PIXEL TRANSPARENT


      IF cBmp != NIL
         @  3 ,  ( nDlgsize + nExpRow -(84*1.5)  ) / 4  BITMAP RESNAME cBmp SIZE 84,84 OF oRndDlg NOBORDER PIXEL
      endif

      oRndDlg:cMsg := cCaption

      ACTIVATE DIALOG oRndDlg CENTERED NOWAIT  ;
          ON INIT ( lOn := .T., oRndDlg:nWidth( nDlgSize +  nExpRow  ), oRndDlg:center() ,RoundCorners( oRndDlg, 20 ) )

      oRndDlg:show()
      syswait(.1)
      ofont14:END()
      SetDlgGradient( oER:aClrDialogs )

 Return nil

//------------------------------------------------------------------------------

 function RoundCorners( oDlg, nRounder )

   local aRect, hRgn

   aRect       := GetClientRect( oDlg:hWnd )
   hRgn        := CreateRoundRectRgn( aRect, nRounder, nRounder )
   SetWindowRgn( oDlg:hWnd, hRgn )
   DeleteObject( hRgn )

return nil

//----------------------------------------------------------------------------//

Function GetbBmpData( oBrw )
Local nBmp  := 1

 If empty( oBrw:aCols[ 3 ]:Value() )
    nBmp := 1
 else
    If oBrw:aCols[ 3 ]:Value() = 1
       nBmp := 1
    else
       if !empty( At( Upper( GL("Visible") ), Upper( oBrw:aCols[ 2 ]:Value() ) ) )
          nBmp := 3
       else
       nBmp := 10
       endif
    endif
 endif

Return nBmp

//------------------------------------------------------------------------------
//aDatas := __objGetMsgList( tTest, .t. )
Function ER_Inspector1( nD )

   LOCAL oDlg   := oER:oFldD:aDialogs[ nD ]
   LOCAL aProps := GetAreaProperties( oER:nAktArea )
   Local oFont
   Local oBrw
   Local oCol
   Local oTree
   Local aTree := {}
   Local aT    := {}
   Local aBmps := { "FoldOpen", "FoldClose", "Checked", "Unchecked", "Property", ;
                    "Typ_Text", "Typ_Image", "Typ_Graphic", "Typ_Barcode", ;
                    "TreeGraph1", "TreeGraph2", "TreeGraph3", "TreeGraph4", ;
                    "TreeGraph5", "TreeGraph6" }

   DEFINE FONT oFont NAME "Verdana" SIZE 0, -11  //"Segoe UI BOLD"

   if !empty( oEr:oTree:aItems )
   aTree := CargaItems( aTree, oEr:oTree:aItems, aBmps )

   @ Int( oEr:oFldD:aDialogs[nD]:nHeight/2 ) + 15, 1 XBROWSE oBrw ;
     SIZE oER:oFldD:aDialogs[nD]:nWidth - 1, Int(oEr:oFldD:aDialogs[nD]:nHeight/2) - 20;
     ARRAY aT  ;  //     HEADERS " " + GL("Property"), " " + GL("Level") ;//     COLSIZES 195, 95 ;
     FONT oFont PIXEL OF oDlg CELL //NOBORDER

     oBrw:SetArray( aTree )

     oBrw:aCols[ 1 ]:nWidth   := 240
     oBrw:aCols[ 1 ]:cHeader  := GL("Property")
     oBrw:aCols[ 2 ]:nWidth   := 290
     oBrw:aCols[ 2 ]:cHeader  := GL("Level")

     oBrw:lHScroll            := .F.

     oCol  := oBrw:InsCol( 1 )
     //oCol:bEditValue   := { |x| If( x == nil, ::oTreeItem:cPrompt, ::oTreeItem:cPrompt := x ) }

     oCol:cHeader       := GL("Level")
     oCol:nWidth        := 50
     oCol:nDataStrAlign := AL_LEFT
     oCol:nDataBmpAlign := AL_LEFT
     //oCol:bLDClickData := { || If( ::oTreeItem:oTree != nil,( ::oTreeItem:Toggle(), ::Refresh() ),) }
     oCol:bIndent      := { || oBrw:aCols[ 3 ]:Value() * 20 } //nLevel * 20 - 20 }

   if ValType( aBmps ) == 'A'
      oCol:AddBitmap( aBmps )
   endif
   oCol:bBmpData   := { || GetbBmpData( oBrw ) }

   oBrw:nFreeze         := 1
   oBrw:aCols[3]:Hide()

   /*
   if !empty( oEr:oTree )
      if !empty( oEr:oTree:aItems )
         oBrw:SetTree( oEr:oTree, ;
             { "FoldOpen", "FoldClose", "Checked", "Unchecked", "Property", ;
               "Typ_Text", "Typ_Image", "Typ_Graphic", "Typ_Barcode", ;
               "TreeGraph1", "TreeGraph2", "TreeGraph3", "TreeGraph4", ;
               "TreeGraph5", "TreeGraph6" } )
      endif
   endif
   */

   else
   @ Int( oEr:oFldD:aDialogs[nD]:nHeight/2 ) + 15, 1 XBROWSE oBrw ;
     SIZE oER:oFldD:aDialogs[nD]:nWidth - 1, Int(oEr:oFldD:aDialogs[nD]:nHeight/2) - 20 ;
     ARRAY aT  ;
     HEADERS " " + GL("Property"), " " + GL("Level") ;//     COLSIZES 195, 95 ;
     FONT oFont PIXEL OF oDlg CELL //NOBORDER

     oBrw:lHScroll            := .F.

   endif
   oBrw:CreateFromCode()
   oBrw:SetColor( 0, RGB( 224, 236, 255 ) )


RETURN oBrw

//------------------------------------------------------------------------------

function OffsetRect( rc, x, y )

rc[1] := rc[1] + y
rc[2] := rc[2] + x
rc[3] := rc[3] + y
rc[4] := rc[4] + x

return rc

//------------------------------------------------------------------------------

FUNCTION DotsSelect( hDC , nTop, nleft, nbottom, nRight )

local aRect
local nClrBorder
local nClrPane
local lFocused := .f.
LOCAL aDots

  nClrBorder := 0
  nClrPane   := CLR_WHITE

  aRect:= { nTop, nleft, nbottom, nRight }
  DrawFocusRect( hDC,aRect[1]-4, aRect[2]-4, aRect[3]+4, aRect[4]+4 )

  aDots := array( 8 )
  aRect :=  {0,0,6,6}
  aRect := OffsetRect( aRect, nLeft-7, nTop-7 )
  aDots[1] := {aRect[1],aRect[2],aRect[3],aRect[4]}

     Ellipse( hDC, aRect[2], aRect[1],aRect[4], aRect[3])


  aRect := {0,0,6,6}
  aRect := OffsetRect( aRect, nLeft + int((nRight - nLeft)/2)-3, nTop-7 )
  aDots[2] := {aRect[1],aRect[2],aRect[3],aRect[4]}

     Ellipse( hDC, aRect[2], aRect[1],aRect[4], aRect[3])


  aRect := {0,0,6,6}
  aRect := OffsetRect( aRect, nRight+1, nTop-7 )
  aDots[3] := {aRect[1],aRect[2],aRect[3],aRect[4]}

     Ellipse( hDC, aRect[2], aRect[1],aRect[4], aRect[3])

  aRect := {0,0,6,6}
  aRect := OffsetRect( aRect, nRight+1 , nTop + int((nBottom - nTop)/2)-3)
  aDots[4] := {aRect[1],aRect[2],aRect[3],aRect[4]}

     Ellipse( hDC, aRect[2], aRect[1],aRect[4], aRect[3])

  aRect := {0,0,6,6}
  aRect := OffsetRect( aRect, nRight+1, nBottom+1 )
  aDots[5] := {aRect[1],aRect[2],aRect[3],aRect[4]}

     Ellipse( hDC, aRect[2], aRect[1],aRect[4], aRect[3])

  aRect := {0,0,6,6}
  aRect := OffsetRect( aRect, nLeft + int((nRight - nLeft)/2)-3, nBottom+1 )
  aDots[6] := {aRect[1],aRect[2],aRect[3],aRect[4]}

   Ellipse( hDC, aRect[2], aRect[1],aRect[4], aRect[3])


  aRect := {0,0,6,6}
  aRect := OffsetRect( aRect, nLeft-7, nBottom+1 )
  aDots[7] := {aRect[1],aRect[2],aRect[3],aRect[4]}

     Ellipse( hDC, aRect[2], aRect[1],aRect[4], aRect[3])


  aRect := {0,0,6,6}
  aRect := OffsetRect( aRect, nLeft-7, nTop + int((nBottom - nTop)/2)-3 )
  aDots[8] := {aRect[1],aRect[2],aRect[3],aRect[4]}

  Ellipse( hDC, aRect[2], aRect[1],aRect[4], aRect[3])

return nil
