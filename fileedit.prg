
#INCLUDE "FiveWin.ch"
#INCLUDE "Splitter.ch"
// #INCLUDE "C5GRID.CH"

STATIC oWnd, oSplit, oVRD, cText, oGet, oLbx, nMeasure, cArea
STATIC nAktText := 1
STATIC aAreas   := {}
STATIC aFiles   := {}

*-- FUNCTION -----------------------------------------------------------------
* Name........: Start
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION Start()

   LOCAL i, oBmp, oFont1, oFont2

   //Einfüge-Modus einschalten
   ReadInsert( .T. )

   OpenFile()

   AADD( aAreas, " Vrd.ini - Application ini file" )
   AADD( aFiles, "VRD.INI" )
   AADD( aAreas, " " + ALLTRIM( oVRD:cTitle ) + " - General ini file"  )
   AADD( aFiles, VRD_LF2SF( oVRD:cReportName ) )

   FOR i := 1 TO LEN( oVRD:aAreaInis )
      IF .NOT. EMPTY( oVRD:aAreaInis[i] )
         AADD( aAreas, " " + oVRD:AreaTitle( i ) )
         AADD( aFiles, VRD_LF2SF( oVRD:aAreaInis[ i ] ) )
      ENDIF
   NEXT
   cArea := aAreas[1]
   cText := MEMOREAD( aFiles[1] )

   nMeasure := VAL( GetPvProfString( "General", "Measure", "1", aFiles[2] ) )

   SET DELETED ON
   SET CONFIRM ON
   SET 3DLOOK ON
   SET MULTIPLE OFF
   SET DATE FORMAT TO "dd.mm.yyyy"
   SET EPOCH TO 1960

   //File-Handles erhöhen
   SetHandleCount(100)

   SET RESOURCES TO "FILEEDIT.DLL"

   DEFINE FONT oFont1 NAME "Ms Sans Serif" SIZE 0,-14
   DEFINE FONT oFont2 NAME "System" SIZE 0,-10

   DEFINE WINDOW oWnd FROM 1, 1 TO 400, 600 PIXEL ;
      TITLE "EasyReport - Report File Editor" ;
      MENU  BuildMenu()

   @ 0,0 LISTBOX oLbx VAR cArea ITEMS aAreas SIZE 160, 365 PIXEL OF oWnd ;
      COLOR RGB( 255, 255, 255 ), RGB( 128, 128, 128 ) FONT oFont1

   oLbx:bLDblClicked = { || BrowseItems() }
   oLbx:bChange := {|| MEMOWRIT( aFiles[ nAktText ], cText ), ;
                       cText := MEMOREAD( aFiles[ oLbx:GetPos() ] ), ;
                       oGet:Refresh(), nAktText := oLbx:GetPos() }

   @ 0,165 GET oGet VAR cText HSCROLL ;
      TEXT SIZE 300, 355 PIXEL OF oWnd COLOR 0, RGB( 255, 255, 255 ) FONT oFont2

   @ 0,160  SPLITTER oSplit ;
            VERTICAL ;
            PREVIOUS CONTROLS oLbx ;
            HINDS CONTROLS oGet ;
            TOP MARGIN 80 ;
            BOTTOM MARGIN 80 ;
            SIZE 4, 300  PIXEL ;
            OF oWnd ;
            _3DLOOK

   SET MESSAGE OF oWnd TO "Sodtalbers+Partner - www.reportdesigner.info" CENTERED KEYBOARD DATE

   oWnd:bLostFocus := {|| MEMOWRIT( aFiles[ nAktText ], oGet:cText() ) }
   oWnd:bGotFocus  := {|| cText := MEMOREAD( aFiles[ oLbx:GetPos() ] ), oGet:Refresh() }

   ACTIVATE WINDOW oWnd MAXIMIZED ;
      ON RESIZE oSplit:AdjClient() ;
      VALID ( MEMOWRIT( aFiles[ nAktText ], oGet:cText() ), .T. )

      //ON PAINT ( cText := MEMOREAD( aFiles[ oLbx:GetPos() ] ), oGet:Refresh() ) ;

   SET RESOURCES TO

RETURN (.T.)


* - FUNCTION ---------------------------------------------------------------
*  Function....: BuildMenu
*  Beschreibung: Shell-Menu anzeigen
*  Argumente...: None
*  Rückgabewert: ( NIL )
*  Author......: Timm Sodtalbers
* --------------------------------------------------------------------------
FUNCTION BuildMenu()

   LOCAL oMenu

   MENU oMenu

   MENUITEM "&Exit"  ACTION oWnd:End()
   MENUITEM "&Browse items" ACTION BrowseItems()
   MENUITEM "&About" ACTION FileEditAbout()

   ENDMENU

RETURN( oMenu )


*-- FUNCTION -----------------------------------------------------------------
* Name........: BrowseItems
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION BrowseItems()

   LOCAL i, cItemDef, cAreaIni, oItem, oDlg, oBrw, oIni, aHeader[20], aCol[20]
   LOCAL cField, aField1, aField2, cRange, aRange, nSatz
   LOCAL lSave      := .F.
   LOCAL aWerte     := {}
   LOCAL nOldSel    := Select()
   LOCAL cReplace   := SPACE( 200 )
   LOCAL nVorColor  := RGB( 0, 0, 0 )
   LOCAL nHinColor  := RGB( 224, 239, 223 )
   LOCAL nHinColor2 := RGB( 223, 231, 224 )
   LOCAL nHinColor3 := RGB( 235, 234, 203 )
   LOCAL nHVorCol   := RGB( 0, 0, 0 )
   LOCAL nColNoEdit := RGB( 128, 128, 128 )
   LOCAL aBmps      := { "CHECK", "UNCHECK" }
   LOCAL aTypeBmps  := { "TYP_TEXT", "TYP_IMAGE", "TYP_GRAPHIC", "TYP_BARCODE" }
   LOCAL aSelType   := { "Text", "Image", "Barcode", "Line up", "Line down", ;
                         "Line horizontal", "Line vertical", "Rectangle", "Ellipse" }

   MEMOWRIT( aFiles[ nAktText ], cText )

   IF AT( "[Items]", cText ) = 0
      MsgStop( 'There are no items defined in "' + ALLTRIM( aAreas[ nAktText ] ) + '".' )
      RETURN(.F.)
   ENDIF

   cAreaIni := oVRD:aAreaInis[ nAktText-2 ]

   FOR i := 1 TO 1000

      cItemDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(i,5)), "", cAreaIni ) )

      IF .NOT. EMPTY( cItemDef )
         oItem := VRDItem():New( cItemDef )
         AADD( aWerte, { i, oItem:cType, oItem:cText, oItem:nItemID, oItem:nShow, ;
                         oItem:nDelete, oItem:nEdit, oItem:nTop, oItem:nLeft, ;
                         oItem:nWidth, oItem:nHeight, ;
                         SUBSTR( cItemDef, StrAtNum( "|", cItemDef, 10 ) + 1 ) } )
      ENDIF

   NEXT

   IF AT( "[Items]", cText ) = 0 .OR. LEN( aWerte ) = 0
      MsgStop( 'There are no items defined in "' + ALLTRIM( aAreas[ nAktText ] ) + '".' )
      RETURN(.F.)
   ENDIF

   SELECT 0
   CREATE FEDITTMP

   APPEND BLANK
   REPLACE FIELD_NAME WITH "ENTRY" , FIELD_TYPE WITH "N", FIELD_LEN WITH   4, FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "TYPE"  , FIELD_TYPE WITH "C", FIELD_LEN WITH  30, FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "TEXT"  , FIELD_TYPE WITH "C", FIELD_LEN WITH 100, FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "ITEMID", FIELD_TYPE WITH "N", FIELD_LEN WITH   4, FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "TOP"   , FIELD_TYPE WITH "N", FIELD_LEN WITH   5, FIELD_DEC WITH IIF( nMeasure = 2, 2, 0 )
   APPEND BLANK
   REPLACE FIELD_NAME WITH "LEFT"  , FIELD_TYPE WITH "N", FIELD_LEN WITH   5, FIELD_DEC WITH IIF( nMeasure = 2, 2, 0 )
   APPEND BLANK
   REPLACE FIELD_NAME WITH "WIDTH" , FIELD_TYPE WITH "N", FIELD_LEN WITH   5, FIELD_DEC WITH IIF( nMeasure = 2, 2, 0 )
   APPEND BLANK
   REPLACE FIELD_NAME WITH "HEIGHT", FIELD_TYPE WITH "N", FIELD_LEN WITH   5, FIELD_DEC WITH IIF( nMeasure = 2, 2, 0 )
   APPEND BLANK
   REPLACE FIELD_NAME WITH "SHOW"  , FIELD_TYPE WITH "N", FIELD_LEN WITH   1, FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "DELETE", FIELD_TYPE WITH "N", FIELD_LEN WITH   1, FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "EDIT"  , FIELD_TYPE WITH "N", FIELD_LEN WITH   1, FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "REST"  , FIELD_TYPE WITH "C", FIELD_LEN WITH 200, FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "SELECT", FIELD_TYPE WITH "N", FIELD_LEN WITH   1, FIELD_DEC WITH 0

   CREATE FILEEDIT FROM FEDITTMP
   FILEEDIT->(DBGOTOP())
   INDEX ON FILEEDIT->ENTRY  TO ENTRY
   INDEX ON FILEEDIT->TYPE   TO TYPE
   INDEX ON FILEEDIT->TEXT   TO TEXT
   INDEX ON FILEEDIT->ITEMID TO ITEMID
   INDEX ON FILEEDIT->TOP    TO TOP
   INDEX ON FILEEDIT->LEFT   TO LEFT
   INDEX ON FILEEDIT->WIDTH  TO WIDTH
   INDEX ON FILEEDIT->HEIGHT TO HEIGHT
   USE FILEEDIT SHARED
   SET INDEX TO ENTRY, TYPE, TEXT, ITEMID, TOP, LEFT, WIDTH, HEIGHT
   SET ORDER TO 1
   FILEEDIT->(DBGOTOP())

   ERASE FEDITTMP.DBF

   FOR i := 1 TO LEN( aWerte )
      APPEND BLANK
      REPLACE FILEEDIT->ENTRY  WITH aWerte[i,1]
      REPLACE FILEEDIT->TYPE   WITH GetType( aWerte[i,2], .T. )
      REPLACE FILEEDIT->TEXT   WITH aWerte[i,3]
      REPLACE FILEEDIT->ITEMID WITH aWerte[i,4]
      REPLACE FILEEDIT->SHOW   WITH aWerte[i,5]
      REPLACE FILEEDIT->DELETE WITH aWerte[i,6]
      REPLACE FILEEDIT->EDIT   WITH aWerte[i,7]
      REPLACE FILEEDIT->TOP    WITH aWerte[i,8]
      REPLACE FILEEDIT->LEFT   WITH aWerte[i,9]
      REPLACE FILEEDIT->WIDTH  WITH aWerte[i,10]
      REPLACE FILEEDIT->HEIGHT WITH aWerte[i,11]
      REPLACE FILEEDIT->REST   WITH aWerte[i,12]
   NEXT
   FILEEDIT->(DBGOTOP())

   DEFINE DIALOG oDlg NAME "ITEMBROWSE" TITLE "Browse Items: " + ALLTRIM( cArea )

   REDEFINE BUTTON ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON ID 102 OF oDlg ACTION oDlg:End()
   REDEFINE BUTTON ID 103 OF oDlg ACTION Duplicate( oBrw )
   REDEFINE BUTTON ID 104 OF oDlg ;
      ACTION ( nSatz := FILEEDIT->(RECNO()), nSatz := nSatz - IIF( nSatz = 1, 0, 1), ;
               FILEEDIT->(FLOCK()), FILEEDIT->(DBDELETE()), ;
               FILEEDIT->(DBUNLOCK()), FILEEDIT->(DBGOTO(nSatz)), oBrw:Refresh(), ;
               oBrw:SetFocus() )

   aField1 := { "FILEEDIT->ENTRY", "FILEEDIT->TYPE", "FILEEDIT->TEXT", ;
                "FILEEDIT->ITEMID", "FILEEDIT->TOP", "FILEEDIT->LEFT", ;
                "FILEEDIT->WIDTH", "FILEEDIT->HEIGHT", "FILEEDIT->SHOW", ;
                "FILEEDIT->DELETE", "FILEEDIT->EDIT", "FILEEDIT->REST" }
   aField2 := { "Entry", "Type", "Text", "ID", "Top", "Left", "Width", ;
                "Height", "Show", "Delete", "Edit", "Rest" }
   cField := aField2[1]
   REDEFINE COMBOBOX cField ITEMS aField2 ID 201 OF oDlg

   REDEFINE GET cReplace ID 202 OF oDlg

   aRange := { "all", "selected", "current", "rest" }
   cRange := aRange[1]
   REDEFINE COMBOBOX cRange ITEMS aRange  ID 203 OF oDlg

   REDEFINE BUTTON ID 150 OF oDlg ;
      ACTION ReplaceItems( oBrw, cField, cReplace, cRange, aField1, aField2, aRange )

   REDEFINE GRID oBrw ID 301 ALIAS "FILEEDIT" OF oDlg ;
            HDRLINES 1 VGRID HGRID HIGHTLINE 17 VSCROLL HSCROLL ;
            COLOR nVorColor, nHinColor2

   DEFINE HEADER aHeader[1] TITLE " " ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ALIGN CENTER
   DEFINE COLUMNA aCol[1] OF oBrw WIDTH 16 ;
      HEADER aHeader[1] ALIGNBMP CENTER ;
      BITMAP aBmps BBITMAP IIF( FILEEDIT->SELECT = 1, 1, 2 ) ;
      ACTION ( FILEEDIT->(FLOCK()), ;
               DBREPLACE( "FILEEDIT->SELECT", IIF( FILEEDIT->SELECT = 1, 0, 1 ) ), ;
               FILEEDIT->(DBUNLOCK()), ;
               oBrw:RefreshLine() )

   DEFINE HEADER aHeader[2] TITLE "Entry " ALIGN LEFT BITMAP "INDEX" ALIGNBMP RIGHT ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ;
      DOUBLECLICK ( oBrw:Set2Order(1), oBrw:Refresh() )
   DEFINE COLUMNA aCol[2] OF oBrw WIDTH 44 DATA "FILEEDIT->ENTRY" ;
      HEADER aHeader[2] ALIGN TOP_RIGHT

   DEFINE HEADER aHeader[3] TITLE "Type" ALIGN LEFT BITMAP "INDEX" ALIGNBMP RIGHT ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ;
      DOUBLECLICK ( oBrw:Set2Order(2), oBrw:Refresh() )
   DEFINE COLUMNA aCol[3] OF oBrw WIDTH 88 DATA "FILEEDIT->TYPE" ;
      HEADER aHeader[3] ALIGN TOP_LEFT ;
      ASELDATO aSelType

   DEFINE HEADER aHeader[4] TITLE "Text" ALIGN LEFT BITMAP "INDEX" ALIGNBMP RIGHT ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ;
      DOUBLECLICK ( oBrw:Set2Order(3), oBrw:Refresh() )
   DEFINE COLUMNA aCol[4] OF oBrw WIDTH 188 DATA "FILEEDIT->TEXT" ;
      HEADER aHeader[4] ALIGN TOP_LEFT

   DEFINE HEADER aHeader[5] TITLE "ID " ALIGN LEFT BITMAP "INDEX" ALIGNBMP RIGHT ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ;
      DOUBLECLICK ( oBrw:Set2Order(4), oBrw:Refresh() )
   DEFINE COLUMNA aCol[5] OF oBrw WIDTH 30 DATA "FILEEDIT->ITEMID" ;
      HEADER aHeader[5] ALIGN TOP_RIGHT

   DEFINE HEADER aHeader[6] TITLE "Top " ALIGN LEFT BITMAP "INDEX" ALIGNBMP RIGHT ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ;
      DOUBLECLICK ( oBrw:Set2Order(5), oBrw:Refresh() )
   DEFINE COLUMNA aCol[6] OF oBrw WIDTH 50 DATA "FILEEDIT->TOP" ;
      HEADER aHeader[6] ALIGN TOP_RIGHT

   DEFINE HEADER aHeader[7] TITLE "Left " ALIGN LEFT BITMAP "INDEX" ALIGNBMP RIGHT ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ;
      DOUBLECLICK ( oBrw:Set2Order(6), oBrw:Refresh() )
   DEFINE COLUMNA aCol[7] OF oBrw WIDTH 50 DATA "FILEEDIT->LEFT" ;
      HEADER aHeader[7] ALIGN TOP_RIGHT

   DEFINE HEADER aHeader[8] TITLE "Width " ALIGN LEFT BITMAP "INDEX" ALIGNBMP RIGHT ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ;
      DOUBLECLICK ( oBrw:Set2Order(7), oBrw:Refresh() )
   DEFINE COLUMNA aCol[8] OF oBrw WIDTH 50 DATA "FILEEDIT->WIDTH" ;
      HEADER aHeader[8] ALIGN TOP_RIGHT

   DEFINE HEADER aHeader[9] TITLE "Height " ALIGN LEFT BITMAP "INDEX" ALIGNBMP RIGHT ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ;
      DOUBLECLICK ( oBrw:Set2Order(8), oBrw:Refresh() )
   DEFINE COLUMNA aCol[9] OF oBrw WIDTH 50 DATA "FILEEDIT->HEIGHT" ;
      HEADER aHeader[9] ALIGN TOP_RIGHT

   DEFINE HEADER aHeader[13] TITLE "Right " ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ALIGN RIGHT
   DEFINE COLUMNA aCol[13] OF oBrw WIDTH 50 ;
      DATA { || STR( FILEEDIT->LEFT + FILEEDIT->WIDTH, 5, IIF( nMeasure = 2, 2, 0 ) ) } ;
      HEADER aHeader[13] ALIGN TOP_RIGHT NOEDITABLE COLOR nColNoEdit

   DEFINE HEADER aHeader[14] TITLE "Bottom " ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ALIGN RIGHT
   DEFINE COLUMNA aCol[14] OF oBrw WIDTH 50 ;
      DATA { || STR( FILEEDIT->TOP + FILEEDIT->HEIGHT, 5, IIF( nMeasure = 2, 2, 0 ) ) } ;
      HEADER aHeader[14] ALIGN TOP_RIGHT NOEDITABLE COLOR nColNoEdit

   DEFINE HEADER aHeader[10] TITLE "Show" ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ALIGN CENTER
   DEFINE COLUMNA aCol[10] OF oBrw WIDTH 40 ;
      HEADER aHeader[10] ALIGNBMP CENTER ;
      BITMAP aBmps BBITMAP IIF( FILEEDIT->SHOW = 1, 1, 2 ) ;
      ACTION ( FILEEDIT->(FLOCK()), ;
               DBREPLACE( "FILEEDIT->SHOW", IIF( FILEEDIT->SHOW = 1, 0, 1 ) ), ;
               FILEEDIT->(DBUNLOCK()), ;
               oBrw:RefreshLine() )

   DEFINE HEADER aHeader[11] TITLE "Delete" ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ALIGN CENTER
   DEFINE COLUMNA aCol[11] OF oBrw WIDTH 40 ;
      HEADER aHeader[11] ALIGNBMP CENTER ;
      BITMAP aBmps BBITMAP IIF( FILEEDIT->DELETE = 1, 1, 2 ) ;
      ACTION ( FILEEDIT->(FLOCK()), ;
               DBREPLACE( "FILEEDIT->DELETE", IIF( FILEEDIT->DELETE = 1, 0, 1 ) ), ;
               FILEEDIT->(DBUNLOCK()), ;
               oBrw:RefreshLine() )

   DEFINE HEADER aHeader[12] TITLE "Edit" ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ALIGN CENTER
   DEFINE COLUMNA aCol[12] OF oBrw WIDTH 40 ;
      HEADER aHeader[12] ALIGNBMP CENTER ;
      BITMAP aBmps BBITMAP IIF( FILEEDIT->EDIT = 1, 1, 2 ) ;
      ACTION ( FILEEDIT->(FLOCK()), ;
               DBREPLACE( "FILEEDIT->EDIT", IIF( FILEEDIT->EDIT = 1, 0, 1 ) ), ;
               FILEEDIT->(DBUNLOCK()), ;
               oBrw:RefreshLine() )

   DEFINE HEADER aHeader[13] TITLE "Rest" ;
      BUTTONLOOK VGRID HGRID COLORTEXT nHVorCol COLORPANE oDlg:nClrPane ALIGN LEFT
   DEFINE COLUMNA aCol[13] OF oBrw WIDTH 400 DATA "FILEEDIT->REST" ;
      HEADER aHeader[13] ALIGN TOP_LEFT

   FILLCOLOR TO oBrw ROWS COLORPANE nHinColor STEPS 2

   oBrw:lUserMenu := .F.

   oDlg:bStart    = { || oBrw:SetFocus() }
   oDlg:bGotFocus = { || oBrw:SetFocus() }

   oBrw:bRClicked = { | nRow, nCol, nFlags | oBrw:LButtonDown(nRow, nCol, nFlags), ;
      FILEEDIT->(FLOCK()), ;
      DBREPLACE( "FILEEDIT->SELECT", IIF( FILEEDIT->SELECT = 1, 0, 1 ) ), ;
      FILEEDIT->(DBUNLOCK()), ;
      oBrw:RefreshLine() }

   ACTIVATE DIALOG oDlg CENTERED ;
      VALID IIF( lSave = .F., MsgYesNo( "Do you want to end without saving?" ), .T. )

   IF lSave = .T.

      FILEEDIT->(DBGOTOP())

      DelIniSection( "Items", cAreaIni )

      DO WHILE .NOT. EOF()

         INI oIni FILE cAreaIni
         SET SECTION "Items" ENTRY ALLTRIM(STR( FILEEDIT->ENTRY, 4 )) ;
            TO GetType( ALLTRIM( FILEEDIT->TYPE ) ) + "|" + ;
               RTRIM( FILEEDIT->TEXT ) + "|" + ;
               ALLTRIM(STR( FILEEDIT->ITEMID, 4 )) + "|" + ;
               ALLTRIM(STR( FILEEDIT->SHOW  , 1 )) + "|" + ;
               ALLTRIM(STR( FILEEDIT->DELETE, 1 )) + "|" + ;
               ALLTRIM(STR( FILEEDIT->EDIT  , 1 )) + "|" + ;
               ALLTRIM(STR( FILEEDIT->TOP   , 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( FILEEDIT->LEFT  , 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( FILEEDIT->WIDTH , 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( FILEEDIT->HEIGHT, 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM( FILEEDIT->REST ) ;
            OF oIni
         ENDINI

         FILEEDIT->(DBSKIP())

      ENDDO

      cText := MEMOREAD( aFiles[ oLbx:GetPos() ] )
      oGet:Refresh()

   ENDIF

   FILEEDIT->(DBCLOSEAREA())

   ERASE FILEEDIT.DBF
   ERASE ENTRY.NTX
   ERASE TYPE.NTX
   ERASE TEXT.NTX
   ERASE ITEMID.NTX
   ERASE LEFT.NTX
   ERASE TOP.NTX
   ERASE WIDTH.NTX
   ERASE HEIGHT.NTX

   Select( nOldSel )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ReplaceItems
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ReplaceItems( oBrw, cField, cReplace, cRange, aField1, aField2, aRange )

   LOCAL xReplace
   LOCAL cReplField := aField1[ ASCAN( aField2, cField ) ]
   LOCAL nRange     := ASCAN( aRange, cRange )
   LOCAL nSatz      := FILEEDIT->(RECNO())

   IF VALTYPE( &cReplField ) = "N"
      xReplace := VAL( cReplace )
   ELSE
      xReplace := ALLTRIM( cReplace )
   ENDIF

   FILEEDIT->(FLOCK())

   IF nRange = 1
      FILEEDIT->(DBGOTOP())
      REPLACE &(cReplField) WITH xReplace ALL
   ELSEIF nRange = 2
      FILEEDIT->(DBGOTOP())
      REPLACE &(cReplField) WITH xReplace FOR FILEEDIT->SELECT = 1
   ELSEIF nRange = 3
      REPLACE &(cReplField) WITH xReplace
   ELSEIF nRange = 4
      REPLACE &(cReplField) WITH xReplace REST
   ENDIF

   FILEEDIT->(DBUNLOCK())
   FILEEDIT->(DBGOTO( nSatz ))
   DBCommit()
   oBrw:Refresh()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetType
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetType( cTyp, lKlartext )

   LOCAL aTypen := { { "TEXT", "Text" }, ;
                     { "IMAGE", "Image" }, ;
                     { "BARCODE", "Barcode" }, ;
                     { "LINEUP", "Line up" }, ;
                     { "LINEDOWN", "Line down" }, ;
                     { "LINEHORIZONTAL", "Line horizontal" }, ;
                     { "LINEVERTICAL", "Line vertical" }, ;
                     { "RECTANGLE", "Rectangle" }, ;
                     { "ELLIPSE", "Ellipse" } }

   DEFAULT lKlartext := .F.

   IF lKlartext = .T.
      cTyp := aTypen[ ASCAN( aTypen, { |aVal| aVal[1] == cTyp } ), 2 ]
   ELSE
      cTyp := aTypen[ ASCAN( aTypen, { |aVal| aVal[2] == cTyp } ), 1 ]
   ENDIF

RETURN ( cTyp )


*-- FUNCTION -----------------------------------------------------------------
*         Name: Duplicate
* Beschreibung:
*    Argumente: None
* Return Value:                       Autor: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION Duplicate( oBrw )

   LOCAL i
   LOCAL aWerte := {}

   FOR i := 1 TO FCOUNT()
      AADD( aWerte, &(FIELDNAME(i)) )
   NEXT

   FILEEDIT->(FLOCK())
   APPEND BLANK

   FOR i := 1 TO FCOUNT()
      REPLACE &(FIELDNAME(i)) WITH aWerte[i]
   NEXT
   REPLACE FILEEDIT->ENTRY WITH LastEntryNr() + 1

   FILEEDIT->(DBUNLOCK())
   DBCommit()
   oBrw:Refresh()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: LastEntryNr
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION LastEntryNr()

   LOCAL nSatz  := FILEEDIT->(RECNO())
   LOCAl nEntry := 0

   FILEEDIT->(DBGOTOP())

   DO WHILE .NOT. FILEEDIT->(EOF())

      IF FILEEDIT->ENTRY > nEntry
         nEntry := FILEEDIT->ENTRY
      ENDIF

      FILEEDIT->(DBSKIP())

   ENDDO

   FILEEDIT->(DBGOTO( nSatz ))

RETURN ( nEntry )


*-- FUNCTION -----------------------------------------------------------------
*         Name: EditCell
* Beschreibung: Browser-Zelle editieren
*    Argumente: None
* Return Value:                       Autor: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EditCell( oLbx, nRow, nCol, aField )

   local nField, xVar, i
   local nColumn := oLbx:nAtCol( nCol )

   //Nicht editieren wenn aField-Wert = 0
   IF aField <> NIL .AND. aField[nColumn] = 0
      return nil
   ENDIF

   IF aField = NIL
      aField := {}
      FOR i := 1 TO 30
         AAdd( aField, i)
      NEXT
   ENDIF

   nField  := IIF( aField = NIL, nColumn, aField[nColumn] )
   xVar    := ( oLbx:cAlias )->( FieldGet( nField ) )

   oLbx:EditCol( nColumn, xVar, , {|v,k| CellVarPut( v, nField, oLbx ) } )

return nil


*-- FUNCTION -----------------------------------------------------------------
* Name........: CellVarPut
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CellVarPut( xVar, nField, oLbx )

   ( oLbx:cAlias )->( FieldPut( nField, xVar ) )

   ( oLbx:cAlias )->( DBunlock() )

   oLbx:DrawSelect()
   oLbx:Refresh()
   oLbx:UpStable()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: OpenFile
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION OpenFile()

   LOCAL cFile := VRD_LF2SF( GetFile( "Designer Files" + " (*.vrd)|*.vrd|" + ;
                                      "All Files" + " (*.*)|*.*", "Open", 1 ) )

   IF .NOT. EMPTY( cFile )
      oVRD := VRD():New( cFile,,,,,, .T. )
   ELSE
      QUIT
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetFile
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetFile( cFileMask, cTitle, nDefaultMask, cInitDir, lSave, nFlags )

   DEFAULT cInitDir := cFilePath( GetModuleFileName( GetInstance() ) )

RETURN cGetFile32( cFileMask, cTitle, nDefaultMask, cInitDir, lSave, nFlags )


*-- FUNCTION -----------------------------------------------------------------
* Name........: StrAtNum
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION StrAtNum( cTrennZeichen, cString, nNr )

   LOCAL cReplace := "-+#T2D#+-"

   cString := STRTRAN( cString, cTrennZeichen, cReplace, nNr, 1 )

RETURN AT( cReplace, cString )


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
* Name........: GetSysFont
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetSysFont()

RETURN "Ms Sans Serif"


*-- FUNCTION -----------------------------------------------------------------
* Name........: About
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION FileEditAbout()

   MsgInfo( "EasyReport - Report File Editor" + CRLF + CRLF + ;
            "Release 1.1.4" + CRLF + CRLF + ;
            "(c) copyright Timm Sodtalbers, 2000-2003" + CRLF + ;
            CHR(9) + CHR(9) + "Sodtalbers+Partner" + CRLF +;
            CHR(9) + CHR(9) + "info@reportdesigner.info     " + CRLF )

RETURN (.T.)

