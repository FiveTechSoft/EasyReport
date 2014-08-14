#INCLUDE "Folder.ch"
#INCLUDE "FiveWin.ch"
#INCLUDE "Treeview.ch"
//#INCLUDE "TSButton.ch"

//Areazugabe
STATIC nAreaZugabe  := 42
STATIC nAreaZugabe2 := 10

//Quelltext im Area-Bereich
STATIC aTmpSource

//Entscheidet ob die Graphikelemente neu gezeichnet werden sollen
STATIC lDraGraphic := .T.

MEMVAR aItems, aFonts, oAppFont, aAreaIni, aWnd, aWndTitle, oBar, oMru
MEMVAR oCbxArea, aCbxItems, nAktuellItem, aRuler, cLongDefIni, cDefaultPath
MEMVAR nAktItem, nAktArea, nSelArea, cAktIni, aSelection, nTotalHeight, nTotalWidth
MEMVAR nHinCol1, nHinCol2, nHinCol3, oMsgInfo
MEMVAR aVRDSave, lVRDSave, lFillWindow, nDeveloper, oRulerBmp1, oRulerBmp2
MEMVAR lBoxDraw, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight, nRuler, nRulerTop
MEMVAR cItemCopy, nCopyEntryNr, nCopyAreaNr, aSelectCopy, aItemCopy, nXMove, nYMove
MEMVAR cInfoWidth, cInfoHeight, nInfoRow, nInfoCol, aItemPosition, aItemPixelPos
MEMVAR oClpGeneral, cDefIni, cDefIniPath, cGeneralIni, nMeasure, cMeasure, lDemo, lBeta, oTimer
MEMVAR oMainWnd, lProfi, nUndoCount, nRedoCount, nDlgTextCol, nDlgBackCol
MEMVAR lPersonal, lStandard, oGenVar, oCurDlg

* - FUNCTION ---------------------------------------------------------------
*  Function....: Start()
*  Beschreibung:
*  Argumente...: None
*  Rückgabewert:
*  Author......: Timm Sodtalbers
* --------------------------------------------------------------------------
FUNCTION Main( P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, P14, P15 )

   LOCAL i, oBrush, oIni, aTest, nTime1, nTime2, cTest, oIcon, cDateFormat
   LOCAL cOldDir  := hb_CurDrive() + ":\" + GetCurDir()
   LOCAL cDefFile := ""

   lChDir( cFilePath( GetModuleFileName( GetInstance() ) ) )

   IF P1  <> NIL ; cDefFile += P1  + " " ; ENDIF
   IF P2  <> NIL ; cDefFile += P2  + " " ; ENDIF
   IF P3  <> NIL ; cDefFile += P3  + " " ; ENDIF
   IF P4  <> NIL ; cDefFile += P4  + " " ; ENDIF
   IF P5  <> NIL ; cDefFile += P5  + " " ; ENDIF
   IF P6  <> NIL ; cDefFile += P6  + " " ; ENDIF
   IF P7  <> NIL ; cDefFile += P7  + " " ; ENDIF
   IF P8  <> NIL ; cDefFile += P8  + " " ; ENDIF
   IF P9  <> NIL ; cDefFile += P9  + " " ; ENDIF
   IF P10 <> NIL ; cDefFile += P10 + " " ; ENDIF
   IF P11 <> NIL ; cDefFile += P11 + " " ; ENDIF
   IF P12 <> NIL ; cDefFile += P12 + " " ; ENDIF
   IF P13 <> NIL ; cDefFile += P13 + " " ; ENDIF
   IF P14 <> NIL ; cDefFile += P14 + " " ; ENDIF
   IF P15 <> NIL ; cDefFile += P15 + " " ; ENDIF

   cDefFile := STRTRAN( ALLTRIM( cDefFile ), '"' )

   EP_TidyUp()
   EP_LinkedToApp()
   EP_SetPath( ".\" )

   //Einfüge-Modus einschalten
   ReadInsert( .T. )

   //Publics deklarieren
   DeclarePublics( cDefFile )

   SET DELETED ON
   SET CONFIRM ON
   SET 3DLOOK ON
   SET MULTIPLE OFF
   SET DATE FORMAT TO "dd.mm.yyyy"

   cDateFormat := LOWER(ALLTRIM( GetPvProfString( "General", "DateFormat", "", cGeneralIni )))

   SET DATE FORMAT IIF( EMPTY( cDateFormat ), "dd.mm.yyyy", cDateFormat )

   //File-Handles erhöhen
   // SetHandleCount(100)    FiveTech

   //Open Undo database
   OpenUndo()

   SET HELPFILE TO "VRD.HLP"

   IF EMPTY( oGenVar:cBrush )
      DEFINE BRUSH oBrush COLOR nHinCol1
   ELSE
      IF AT( ".BMP", oGenVar:cBrush ) <> 0
         DEFINE BRUSH oBrush FILE oGenVar:cBrush
      ELSE
         DEFINE BRUSH oBrush RESOURCE oGenVar:cBrush
      ENDIF
   ENDIF

   //Fonts definieren
   DEFINE FONT oAppFont NAME "Arial" SIZE 0, -12
   DEFINE ICON oIcon FILE ".\vrd.ico"

   // SetBalloon( .T. )
   SetDlgGradient( { { 1, RGB( 199, 216, 237 ), RGB( 237, 242, 248 ) } } )
   
   DEFINE WINDOW oMainWnd FROM 2, 3 TO 28, 85 VSCROLL HSCROLL ;
      TITLE MainCaption() ;
      BRUSH oBrush MDI ;
      ICON oIcon ;
      MENU BuildMenu()

   //Clipboard
   DEFINE CLIPBOARD oClpGeneral OF oMainWnd

   SET MESSAGE OF oMainWnd TO oGenVar:cRegistInfo CENTERED 2010

   DEFINE MSGITEM oMsgInfo OF oMainWnd:oMsgBar SIZE 280

   oMainWnd:oMsgBar:KeybOn()

   BarMenu()

   ACTIVATE WINDOW oMainWnd ;
      ON INIT ( SetMainWnd(), IniMainWindow(), ;
                IIF( EMPTY( cDefIni ), OpenFile(), SetScrollBar() ), ;
                StartMessage(), SetSave( .T. ), ClearUndoRedo() ) ;
      VALID AskSaveFiles()

   oClpGeneral:End()
   oAppFont:End()
   oBrush:End()
   oGenVar:oAreaBrush:End()
   oGenVar:oBarBrush:End()

   AEVAL( oGenVar:aAppFonts, {|x| x:End() } )
   AEVAL( aFonts, {|x| IIF( x <> NIL, x:End(), ) } )

   CloseUndo()

   lChDir( cOldDir )

RETURN( NIL )


*-- FUNCTION -----------------------------------------------------------------
*         Name: BarMenu
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION BarMenu()

   LOCAL aBtn[3]
   LOCAL lPrompt := ( GetSysMetrics( 0 ) > 800 )

   DEFINE BUTTONBAR oBar OF oMainWnd SIZE 70, 70 2010

   DEFINE BUTTON RESOURCE "B_OPEN" ;
      OF oBar ;
      PROMPT FWString( "Open" ) ;
      TOOLTIP GL("Open") ;
      ACTION OpenFile()

   DEFINE BUTTON RESOURCE "B_SAVE" ;
      OF oBar ;
      PROMPT FWString( "Save" ) ;
      TOOLTIP GL("Save") ;
      ACTION SaveFile() ;
      WHEN .NOT. EMPTY( cDefIni ) .AND. lVRDSave = .F.

   IF nDeveloper = 1 .OR. oGenVar:lStandalone = .T.
      DEFINE BUTTON aBtn[1] RESOURCE "B_PREVIEW" ;
         OF oBar ;
         PROMPT FWString( "Preview" ) ;
         TOOLTIP GL("Preview") ;
         ACTION PrintReport( .T., !oGenVar:lStandalone ) ;
         WHEN .NOT. EMPTY( cDefIni )
   ENDIF

   DEFINE BUTTON aBtn[2] RESOURCE "B_UNDO" ;
      OF oBar GROUP ;
      PROMPT FWString( "Undo" ) ;
      TOOLTIP STRTRAN( GL("&Undo"), "&" ) ;
      ACTION Undo() ;
      WHEN .NOT. EMPTY( cDefIni ) .AND. nUndoCount > 0 
      // MENU UndoRedoMenu( 1, aBtn[2] ) ;

   DEFINE BUTTON aBtn[3] RESOURCE "B_REDO" ;
      OF oBar ;
      PROMPT FWString( "Redo" ) ;
      TOOLTIP STRTRAN( GL("&Redo"), "&" ) ;
      ACTION Redo() ;
      WHEN .NOT. EMPTY( cDefIni ) .AND. nRedoCount > 0
      // MENU UndoRedoMenu( 2, aBtn[2] ) ;

   DEFINE BUTTON RESOURCE "B_ITEMLIST", "B_ITEMLIST2", "B_ITEMLIST3", "B_ITEMLIST2" ;
      OF oBar GROUP ;
      PROMPT FWSTring( "Area and Item list" ) ;
      TOOLTIP GL("Area and Item List") ;
      ACTION Itemlist() ;
      WHEN .NOT. EMPTY( cDefIni )

   IF VAL( GetPvProfString( "General", "EditSetting", "1", cDefIni ) ) = 1
      DEFINE BUTTON RESOURCE "B_FONTCOLOR", "B_FONTCOLOR2", "B_FONTCOLOR3", "B_FONTCOLOR2" ;
         OF oBar ;
         PROMPT FWString( "Fonts and Colors" ) ;
         TOOLTIP GL("Fonts and Colors") ;
         ACTION GeneralSettings() ;
         WHEN .NOT. EMPTY( cDefIni )
   ENDIF

   IF VAL( GetPvProfString( "General", "EditAreaProperties", "1", cDefIni ) ) = 1
      DEFINE BUTTON RESOURCE "B_AREA", "B_AREA2", "B_AREA3", "B_AREA2" ;
         OF oBar ;
         PROMPT FWSTring( "Area properties" ) ; 
         TOOLTIP GL("Area Properties") ;
         ACTION AreaProperties( nAktArea ) ;
         WHEN .NOT. EMPTY( cDefIni )
   ENDIF

   DEFINE BUTTON RESOURCE "B_EDIT", "B_EDIT2", "B_EDIT3", "B_EDIT2" ;
      OF oBar ;
      PROMPT FWString( "Item Properties" ) ;
      TOOLTIP GL("Item Properties") ;
      ACTION IIF( LEN( aSelection ) <> 0, MultiItemProperties(), ItemProperties( nAktItem, nAktArea ) ) ;
      WHEN .NOT. EMPTY( cDefIni )

   IF VAL( GetPvProfString( "General", "InsertMode", "1", cDefIni ) ) = 1
      DEFINE BUTTON RESOURCE "B_TEXT", "B_TEXT2", "B_TEXT3", "B_TEXT2" ;
         OF oBar GROUP ;
         PROMPT FWString( "Insert &Text" ) ;
         TOOLTIP STRTRAN( GL("Insert &Text"), "&" ) ;
         ACTION NewItem( "TEXT", nAktArea ) ;
         WHEN .NOT. EMPTY( cDefIni )

      DEFINE BUTTON RESOURCE "B_IMAGE", "B_IMAGE2", "B_IMAGE3", "B_IMAGE2" ;
         OF oBar ;
         TOOLTIP STRTRAN( GL("Insert &Image"), "&" ) ;
         ACTION NewItem( "IMAGE", nAktArea ) ;
         WHEN .NOT. EMPTY( cDefIni )

      DEFINE BUTTON RESOURCE "B_GRAPHIC", "B_GRAPHIC2", "B_GRAPHIC3", "B_GRAPHIC2" ;
         OF oBar ;
         TOOLTIP STRTRAN( GL("Insert &Graphic"), "&" ) ;
         ACTION NewItem( "GRAPHIC", nAktArea ) ;
         WHEN .NOT. EMPTY( cDefIni )

      DEFINE BUTTON RESOURCE "B_BARCODE", "B_BARCODE2", "B_BARCODE3", "B_BARCODE2" ;
         OF oBar ;
         TOOLTIP STRTRAN( GL("Insert &Barcode"), "&" ) ;
         ACTION NewItem( "BARCODE", nAktArea ) ;
         WHEN .NOT. EMPTY( cDefIni )
   ENDIF

   IF VAL( GetPvProfString( "General", "ShowExitButton", "0", cGeneralIni ) ) = 1

      DEFINE BUTTON RESOURCE "B_EXIT" ;
         PROMPT FWString( "Exit" ) ;
         OF oBar GROUP ;
         ACTION oMainWnd:End() TOOLTIP GL("Exit")

   ENDIF

   oBar:bLClicked := {|| NIL }
   oBar:bRClicked := {|| NIL }

RETURN (.T.)


* - FUNCTION ---------------------------------------------------------------
*  Function....: PreviewMenu
*  Beschreibung:
*  Argumente...: None
*  Rückgabewert: ( NIL )
*  Author......: Timm Sodtalbers
* --------------------------------------------------------------------------
FUNCTION PreviewMenu( oBtn )

   LOCAL oMenu
   LOCAL aRect := GetClientRect( oBtn:hWnd )

   MENU oMenu POPUP

      MENUITEM GL("Pre&view") + chr(9) + GL("Ctrl+P") ;
         ACCELERATOR ACC_CONTROL, ASC( GL("P") ) ;
         ACTION PrintReport( .T. ) ;
         WHEN .NOT. EMPTY( cDefIni )
      MENUITEM GL("&Developer Preview") ;
         ACTION PrintReport( .T., .T. ) ;
         WHEN .NOT. EMPTY( cDefIni )

   ENDMENU

   ACTIVATE POPUP oMenu AT aRect[3], aRect[2] OF oBtn

RETURN( oMenu )


*-- FUNCTION -----------------------------------------------------------------
* Name........: StartMessage
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION StartMessage()

   IF lBeta = .T.
      BetaVersion()
   ELSE
      IF lDemo = .T.
         VRDLogo()
      ELSEIF lPersonal = .T. .OR. lStandard = .T.
         lProfi := .T.
         IF QuietRegCheck() = .F.
            VRDMsgPersonal()
         ENDIF
      ENDIF
  ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: DeclarePublics
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DeclarePublics( cDefFile )

   PUBLIC oMainWnd, oClpGeneral, oTimer
   PUBLIC cDefIni, cDefIniPath
   PUBLIC nMeasure, cMeasure
   PUBLIC cGeneralIni := ".\VRD.INI"
   PUBLIC lDemo       := .F.
   PUBLIC lBeta       := .F.
   PUBLIC lProfi      := .T.
   PUBLIC lPersonal   := .F.
   PUBLIC lStandard   := .F.

   IF lPersonal = .T. .OR. lStandard = .T.
      lProfi := .T.
   ENDIF

   PUBLIC aItems, aFonts, oAppFont, aAreaIni, aWnd, aWndTitle, oBar, oMru
   PUBLIC aCbxItems, nAktuellItem, aRuler, cLongDefIni, cDefaultPath
   PUBLIC oCbxArea := NIL
   PUBLIC oCurDlg  := NIL

   //Gesamthöhe und Breite
   PUBLIC nTotalHeight, nTotalWidth

   //gerade gewählte(s) Element, Bereich, ini-Datei, multiple Selection
   PUBLIC nAktItem := 0
   PUBLIC nAktArea := 1
   PUBLIC nSelArea := 0
   PUBLIC cAktIni
   PUBLIC aSelection := {}

   //Standardfarben
   PUBLIC nHinCol1  //Allgemeine Hintergrundfarbe
   PUBLIC nHinCol2  //Cursoranzeige auf dem Lineal
   PUBLIC nHinCol3  //Bedruckbarer Bereich

   //Selection box
   PUBLIC lBoxDraw := .F.
   PUBLIC nBoxTop, nBoxLeft, nBoxBottom, nBoxRight

   //Ruler anzeigen
   PUBLIC oRulerBmp1, oRulerBmp2
   PUBLIC nRuler    := 20
   PUBLIC nRulerTop := 37

   //Infos in MsgBar
   PUBLIC oMsgInfo

   //Sichern
   PUBLIC aVRDSave[102,2]
   PUBLIC lVRDSave    := .T.
   PUBLIC lFillWindow := .F.

   //cut, copy and paste
   PUBLIC cItemCopy    := ""
   PUBLIC nCopyEntryNr := 0
   PUBLIC nCopyAreaNr  := 0
   PUBLIC aSelectCopy  := {}
   PUBLIC aItemCopy    := {}

   //developer mode
   PUBLIC nDeveloper := 0

   //Items bewegen
   PUBLIC nXMove := 0
   PUBLIC nYMove := 0

   //Msgbar mit Elementgröße aktualisieren wenn ein Element bewegt wird
   PUBLIC cInfoWidth, cInfoHeight, nInfoRow, nInfoCol
   PUBLIC aItemPosition := {}
   PUBLIC aItemPixelPos := {}

   //Undo/Redo
   PUBLIC nUndoCount := 0
   PUBLIC nRedoCount := 0

   //Dialog say titles
   PUBLIC nDlgTextCol := RGB( 255, 255, 255 )
   PUBLIC nDlgBackCol := RGB( 150, 150, 150 )

   //Structure-Variable
   PUBLIC oGenVar := TExStruct():New()

   //Version einstellen
   oGenVar:AddMember( "cRegistInfo",, GetRegistInfos() )

   //Voreinstellungen holen
   cDefIni      := VRD_LF2SF( cDefFile )
   cLongDefIni  := cDefFile
   cDefaultPath := CheckPath( GetPvProfString( "General", "DefaultPath", "", cGeneralIni ) )

   IF AT( "\", cDefIni ) = 0 .AND. .NOT. EMPTY( cDefIni )
      cDefIni := ".\" + cDefIni
   ENDIF

   cDefIniPath := CheckPath( cFilePath( cDefIni ) )

   oGenVar:AddMember( "cRelease"  ,, "2.1.1" )
   oGenVar:AddMember( "cCopyright",, "2000-2004" )

   oGenVar:AddMember( "aLanguages",, {} )
   oGenVar:AddMember( "nLanguage" ,, VAL( GetPvProfString( "General", "Language", "1", cGeneralIni ) ) )

   //Sprachdatei füllen
   OpenLanguage()

   nHinCol1 := IniColor( GetPvProfString( "General", "BackgroundColor", "0", cGeneralIni ) )
   IF nHinCol1 = 0
      nHinCol1 := RGB( 255, 255, 225 )
   ENDIF

   nHinCol2     := RGB( 0, 128, 255 )
   nHinCol3     := RGB( 255, 255, 255 )
   aItems       := Array( 100, 1000 )
   aAreaIni     := Array( 100 )
   aWnd         := Array( 100 )
   aWndTitle    := Array( 100 )
   aRuler       := Array( 100, 2 )
   aFonts       := Array( 20 )

   nDeveloper := VAL( GetPvProfString( "General", "DeveloperMode", "0", cGeneralIni ) )

   oGenVar:AddMember( "nClrReticule" ,, IniColor( GetPvProfString( "General", "ReticuleColor"      , " 50,  50,  50", cGeneralIni ) ) )
   oGenVar:AddMember( "lShowReticule",, ( GetPvProfString( "General", "ShowReticule", "1", cGeneralIni ) = "1" ) )

   oGenVar:AddMember( "aDBFile",, {} )

   oGenVar:AddMember( "lStandalone",, .F. )
   oGenVar:AddMember( "lShowGrid"  ,, .F. )
   oGenVar:AddMember( "nGridWidth" ,, 1   )
   oGenVar:AddMember( "nGridHeight",, 1   )

   IF .NOT. EMPTY( cDefIni )
      SetGeneralSettings()
   ENDIF

   oGenVar:AddMember( "nClrArea"       ,, IniColor( GetPvProfString( "General", "AreaBackColor", "240, 247, 255", cGeneralIni ) ) )

   oGenVar:AddMember( "cBrush"   ,, ALLTRIM( GetPvProfString( "General", "BackgroundBrush", "", cGeneralIni ) ) )
   oGenVar:AddMember( "cBarBrush",, ALLTRIM( GetPvProfString( "General", "ButtonbarBrush" , "", cGeneralIni ) ) )
   oGenVar:AddMember( "cBrushArea"     ,, GetPvProfString( "General", "AreaBackBrush"     , "", cGeneralIni ) )

   oGenVar:AddMember( "oBarBrush",, NIL )

   IF EMPTY( oGenVar:cBarBrush )
      DEFINE BRUSH oGenVar:oBarBrush COLOR GetSysColor( 15 )  // COLOR_BTNFACE
   ELSE
      IF AT( ".BMP", oGenVar:cBrush ) <> 0
         DEFINE BRUSH oGenVar:oBarBrush FILE oGenVar:cBarBrush
      ELSE
         DEFINE BRUSH oGenVar:oBarBrush RESOURCE oGenVar:cBarBrush
      ENDIF
   ENDIF

   oGenVar:AddMember( "oAreaBrush",, NIL )

   IF EMPTY( oGenVar:cBrushArea )
      DEFINE BRUSH oGenVar:oAreaBrush COLOR oGenVar:nClrArea
   ELSE
     IF AT( ".BMP", oGenVar:cBrushArea ) <> 0
        DEFINE BRUSH oGenVar:oAreaBrush FILE oGenVar:cBrushArea
     ELSE
        DEFINE BRUSH oGenVar:oAreaBrush RESOURCE oGenVar:cBrushArea
     ENDIF
   ENDIF

   oGenVar:AddMember( "nBClrAreaTitle" ,, IniColor( GetPvProfString( "General", "AreaTitleBackColor" , "204, 214, 228", cGeneralIni ) ) )
   oGenVar:AddMember( "nF1ClrAreaTitle",, IniColor( GetPvProfString( "General", "AreaTitleForeColor1", "111, 111, 111", cGeneralIni ) ) )
   oGenVar:AddMember( "nF2ClrAreaTitle",, IniColor( GetPvProfString( "General", "AreaTitleForeColor2", " 50,  50,  50", cGeneralIni ) ) )

   oGenVar:AddMember( "nFocusGetBackClr",, IniColor( GetPvProfString( "General", "FocusGetBackClr", "0", cGeneralIni ) ) )

   oGenVar:AddMember( "lSelectItems"   ,, .F. )

   oGenVar:AddMember( "lFixedAreaWidth",, ( GetPvProfString( "General", "AreaWidthFixed", "1", cGeneralIni ) = "1" ) )

   oGenVar:AddMember( "aAreaTitle",, ARRAY( 100 ) )
   oGenVar:AddMember( "aAreaHide" ,, ARRAY( 100 ) )
   oGenVar:AddMember( "aAreaSizes",, ARRAY( 100, 2 ) )
   AFILL( oGenVar:aAreaHide, .F. )

   oGenVar:AddMember( "aAppFonts",, ARRAY(2) )

   DEFINE FONT oGenVar:aAppFonts[1] NAME GetSysFont() SIZE 0,-11 BOLD
   DEFINE FONT oGenVar:aAppFonts[2] NAME GetSysFont() SIZE 0,-10 BOLD

   oGenVar:AddMember( "lItemDlg",, .F. )
   oGenVar:AddMember( "lDlgSave",, .F. )
   oGenVar:AddMember( "nDlgTop" ,, VAL( GetPvProfString( "ItemDialog", "Top" , "0", cGeneralIni ) ) )
   oGenVar:AddMember( "nDlgLeft",, VAL( GetPvProfString( "ItemDialog", "Left", "0", cGeneralIni ) ) )

   oGenVar:AddMember( "lShowBorder",, ( GetPvProfString( "General", "ShowTextBorder", "1", cGeneralIni ) = "1" ) )

   oGenVar:AddMember( "cLoadFile" ,, "" )
   oGenVar:AddMember( "lFirstFile",, .T. )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: SetGeneralSettings
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetGeneralSettings()

   nMeasure := VAL( GetPvProfString( "General", "Measure", "1", cDefIni ) )
   IIF( nMeasure = 1, cMeasure := GL("mm"), )
   IIF( nMeasure = 2, cMeasure := GL("inch"), )
   IIF( nMeasure = 3, cMeasure := GL("Pixel"), )

   nDeveloper := VAL( GetPvProfString( "General", "DeveloperMode", STR( nDeveloper, 1 ), cDefIni ) )

   oGenVar:lStandalone := ( GetPvProfString( "General", "Standalone"   , "0", cDefIni ) = "1" )
   oGenVar:lShowGrid   := ( GetPvProfString( "General", "ShowGrid"     , "0", cDefIni ) = "1" )
   oGenVar:nGridWidth  := VAL( GetPvProfString( "General", "GridWidth" , "1", cDefIni ) )
   oGenVar:nGridHeight := VAL( GetPvProfString( "General", "GridHeight", "1", cDefIni ) )
   nXMove := ER_GetPixel( oGenVar:nGridWidth )
   nYMove := ER_GetPixel( oGenVar:nGridHeight )

   OpenDatabases()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: IniMainWindow
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION IniMainWindow()

   IF .NOT. EMPTY( cDefIni )

      oGenVar:lFirstFile := .F.

      //Fonts definieren
      DefineFonts()
      //Areas initieren
      IniAreasOnBar()
      //Designwindows öffnen
      ClientWindows()
      //Areas anzeigen
      ShowAreasOnBar()
      //Mru erstellen
      IF VAL( GetPvProfString( "General", "MruList"  , "4", cGeneralIni ) ) > 0
         oMru:Save( cLongDefIni )
      ENDIF
      CreateBackup()
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: SetScrollBar
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetScrollBar()

   LOCAL oVScroll

   oMainWnd:oWndClient:oVScroll:SetRange( 0, 100 )
   oMainWnd:oWndClient:oHScroll:SetRange( 0, 100 )
   //oMainWnd:oWndClient:oVScroll:SetRange( 0, nTotalHeight )
   //oMainWnd:oWndClient:oHScroll:SetRange( 0, nTotalWidth )

   oMainWnd:oWndClient:oVScroll:bGoUp     = {|| ScrollVertical( .T. ) }
   oMainWnd:oWndClient:oVScroll:bGoDown   = {|| ScrollVertical( , .T. ) }
   oMainWnd:oWndClient:oVScroll:bPageUp   = {|| ScrollVertical( ,, .T. ) }
   oMainWnd:oWndClient:oVScroll:bPageDown = {|| ScrollVertical( ,,, .T. ) }
   oMainWnd:oWndClient:oVScroll:bPos      = {| nWert | ScrollVertical( ,,,, .T., nWert ) }
   oMainWnd:oWndClient:oVScroll:nPgStep   = 392

   oMainWnd:oWndClient:oHScroll:bGoUp     = {|| ScrollHorizont( .T. ) }
   oMainWnd:oWndClient:oHScroll:bGoDown   = {|| ScrollHorizont( , .T. ) }
   oMainWnd:oWndClient:oHScroll:bPageUp   = {|| ScrollHorizont( ,, .T. ) }
   oMainWnd:oWndClient:oHScroll:bPageDown = {|| ScrollHorizont( ,,, .T. ) }
   oMainWnd:oWndClient:oHScroll:bPos      = {| nWert | ScrollHorizont( ,,,, .T., nWert ) }
   oMainWnd:oWndClient:oHScroll:nPgStep   = 602

   oMainWnd:oWndClient:oVScroll:SetPos(0)
   oMainWnd:oWndClient:oHScroll:SetPos(0)

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ScrollVertical
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ScrollVertical( lUp, lDown, lPageUp, lPageDown, lPos, nPosZugabe )

   LOCAL i, aFirstWndCoors, nAltWert
   LOCAL nZugabe     := 14
   LOCAL nPageZugabe := 392
   LOCAL aCliRect    := oMainWnd:GetCliRect()

   DEFAULT lUp       := .F.
   DEFAULT lDown     := .F.
   DEFAULT lPageUp   := .F.
   DEFAULT lPageDown := .F.
   DEFAULT lPos      := .F.

   UnSelectAll()

   FOR i := 1 TO 100
      IF aWnd[i] <> NIL
         aFirstWndCoors := GetCoors( aWnd[i]:hWnd )
         EXIT
      ENDIF
   NEXT

   IF lUp = .T. .OR. lPageUp = .T.
      IF aFirstWndCoors[1] = 0
         nZugabe := 0
      ELSEIF aFirstWndCoors[1] + IIF( lUp, nZugabe, nPageZugabe ) >= 0
         nZugabe     := -1 * aFirstWndCoors[1]
         nPageZugabe := -1 * aFirstWndCoors[1]
      ENDIF
   ENDIF

   IF lDown = .T. .OR. lPageDown = .T.
      IF aFirstWndCoors[1] + nTotalHeight <= aCliRect[3] - 80
         nZugabe     := 0
         nPageZugabe := 0
      ENDIF
   ENDIF

   IF lPos = .T.
      nAltWert := oMainWnd:oWndClient:oVScroll:GetPos()
      oMainWnd:oWndClient:oVScroll:SetPos( nPosZugabe )
      nZugabe := -1 * nTotalHeight * ( oMainWnd:oWndClient:oVScroll:GetPos() - nAltWert ) / 100
   ENDIF

   FOR i := 1 TO 100
      IF aWnd[i] <> NIL
         IF lUp = .T. .OR. lPos = .T.
            aWnd[i]:Move( aWnd[i]:nTop + nZugabe, aWnd[i]:nLeft, 0, 0, .T. )
         ELSEIF lDown = .T.
            aWnd[i]:Move( aWnd[i]:nTop - nZugabe, aWnd[i]:nLeft, 0, 0, .T. )
         ELSEIF lPageUp = .T.
            aWnd[i]:Move( aWnd[i]:nTop + nPageZugabe, aWnd[i]:nLeft, 0, 0, .T. )
         ELSEIF lPageDown = .T.
            aWnd[i]:Move( aWnd[i]:nTop - nPageZugabe, aWnd[i]:nLeft, 0, 0, .T. )
         ENDIF
      ENDIF
   NEXT

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ScrollHorizont
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ScrollHorizont( lLeft, lRight, lPageLeft, lPageRight, lPos, nPosZugabe )

   LOCAL i, aFirstWndCoors, nAltWert
   LOCAL nZugabe     := 14
   LOCAL nPageZugabe := 602
   LOCAL aCliRect    := oMainWnd:GetCliRect()

   DEFAULT lLeft      := .F.
   DEFAULT lRight     := .F.
   DEFAULT lPageLeft  := .F.
   DEFAULT lPageRight := .F.
   DEFAULT lPos       := .F.

   UnSelectAll()

   FOR i := 1 TO 100
      IF aWnd[i] <> NIL
         aFirstWndCoors := GetCoors( aWnd[i]:hWnd )
         EXIT
      ENDIF
   NEXT

   IF lLeft = .T. .OR. lPageLeft = .T.
      IF aFirstWndCoors[2] = 0
         nZugabe := 0
      ELSEIF aFirstWndCoors[2] + IIF( lLeft, nZugabe, nPageZugabe ) >= 0
         nZugabe     := -1 * aFirstWndCoors[2]
         nPageZugabe := -1 * aFirstWndCoors[2]
      ENDIF
   ENDIF

   IF lRight = .T. .OR. lPageRight = .T.
      IF aFirstWndCoors[2] + nTotalWidth <= aCliRect[4] - 40
         nZugabe     := 0
         nPageZugabe := 0
      ENDIF
   ENDIF

   IF lPos = .T.
      nAltWert := oMainWnd:oWndClient:oHScroll:GetPos()
      oMainWnd:oWndClient:oHScroll:SetPos( nPosZugabe )
      nZugabe := -1 * nTotalWidth * ( oMainWnd:oWndClient:oHScroll:GetPos() - nAltWert ) / 100
   ENDIF


   FOR i := 1 TO 100
      IF aWnd[i] <> NIL
         IF lLeft = .T. .OR. lPos = .T.
            aWnd[i]:Move( aWnd[i]:nTop, aWnd[i]:nLeft + nZugabe , 0, 0, .T. )
         ELSEIF lRight = .T.
            aWnd[i]:Move( aWnd[i]:nTop, aWnd[i]:nLeft - nZugabe , 0, 0, .T. )
         ELSEIF lPageLeft = .T.
            aWnd[i]:Move( aWnd[i]:nTop, aWnd[i]:nLeft + nPageZugabe, 0, 0, .T. )
         ELSEIF lPageRight = .T.
            aWnd[i]:Move( aWnd[i]:nTop, aWnd[i]:nLeft - nPageZugabe, 0, 0, .T. )
         ENDIF
      ENDIF
   NEXT

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: SetMainWnd
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetMainWnd()

   IF VAL( GetPvProfString( "General", "Maximize", "1", cGeneralIni ) ) = 1
      oMainWnd:Maximize()
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: IniAreasOnBar
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION IniAreasOnBar()

   LOCAL i, oFont1
   LOCAL cCbxItem   := ""
   LOCAL nAreaStart := oMainWnd:nRight - 208

   aCbxItems := {""}

   DEFINE FONT oFont1 NAME "Ms Sans Serif" SIZE 0,-10

   //@ 9, nAreaStart - 75 SAY GL("Area") + ":" OF oBar PIXEL SIZE 70, 16 FONT oFont1 RIGHT

   @ 5, nAreaStart COMBOBOX oCbxArea VAR cCbxItem ITEMS aCbxItems OF oBar ;
      PIXEL SIZE 200, 300 FONT oFont1 ;
      WHEN .NOT. EMPTY( cDefIni ) ;

   oFont1:End()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: SetWinNull
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetWinNull()

   LOCAL i
   LOCAL nAltPos := aWnd[nAktArea]:nTop

   FOR i := 1 TO 100
      IF aWnd[i] <> NIL
         aWnd[i]:Move( aWnd[i]:nTop - nAltPos, aWnd[i]:nLeft, 0, 0, .T. )
      ENDIF
   NEXT

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ShowAreasOnBar
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ShowAreasOnBar()

   LOCAL i, oFont1
   LOCAL cCbxItem  := aWndTitle[1]

   aCbxItems := {}

   FOR i := 1 TO LEN( aWndTitle )
      IF .NOT. EMPTY( aWndTitle[i] )
         AADD( aCbxItems, aWndTitle[i] )
      ENDIF
   NEXT

   //Fokus auf das erste Fenster legen
   aWnd[ ASCAN( aWnd, {|x| x <> NIL } ) ]:SetFocus()

   oCbxArea:SetItems( aCbxItems )
   oCbxArea:Select( 1 )
   oCbxArea:bChange = {|| aWnd[ASCAN( aWndTitle, oCbxArea:cTitle )]:SetFocus(), SetWinNull() }

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
   LOCAL nMruList := VAL( GetPvProfString( "General", "MruList"  , "4", cGeneralIni ) )

   MENU oMenu 2007

   MENUITEM GL("&File")
   MENU
   IF nDeveloper = 1
      MENUITEM GL("&New") ;
         ACTION NewReport()
   ENDIF
   MENUITEM GL("&Open") + chr(9) + GL("Ctrl+O") RESOURCE "B_OPEN_16" ;
      ACCELERATOR ACC_CONTROL, ASC( GL("O") ) ;
      ACTION OpenFile()
   SEPARATOR
   MENUITEM GL("&Save") + chr(9) + GL("Ctrl+S") RESOURCE "B_SAVE_16" ;
      ACCELERATOR ACC_CONTROL, ASC( GL("S") ) ;
      ACTION SaveFile() ;
      WHEN .NOT. EMPTY( cDefIni ) .AND. lVRDSave = .F.
   MENUITEM GL("Save &as") ;
      ACTION SaveAsFile() ;
      WHEN .NOT. EMPTY( cDefIni )
   SEPARATOR
   MENUITEM GL("&File Informations") ;
      ACTION FileInfos() ;
      WHEN .NOT. EMPTY( cDefIni )

   SEPARATOR
   IF VAL( GetPvProfString( "General", "Standalone", "0", cDefIni ) ) = 1
      MENUITEM GL("Pre&view") + chr(9) + GL("Ctrl+P") RESOURCE "B_PREVIEW" ;
         ACCELERATOR ACC_CONTROL, ASC( GL("P") ) ;
         ACTION PrintReport( .T. ) ;
         WHEN .NOT. EMPTY( cDefIni )
   ENDIF
   IF nDeveloper = 1
      MENUITEM GL("&Developer Preview") ;
         ACTION PrintReport( .T., .T. ) ;
         WHEN .NOT. EMPTY( cDefIni )
   ENDIF

   MENUITEM GL("&Print") /*RESOURCE "PRINTER"*/ ;
         ACTION PrintReport() ;
         WHEN .NOT. EMPTY( cDefIni )

   MRU oMru FILENAME cGeneralIni ;
            SECTION  "MRU" ;
            ACTION   OpenFile( cMruItem ) ;
            SIZE     VAL( GetPvProfString( "General", "MruList"  , "4", cGeneralIni ) )
   SEPARATOR
   MENUITEM GL("&Exit") RESOURCE "B_EXIT_16" ;
      ACTION oMainWnd:End()
   ENDMENU

   MENUITEM GL("&Edit")
   MENU
   MENUITEM GL("&Undo") + chr(9) + GL("Ctrl+Z") RESOURCE "B_UNDO_16" ;
      ACTION Undo() ;
      ACCELERATOR ACC_CONTROL, ASC( GL("Z") ) ;
      WHEN .NOT. EMPTY( cDefIni ) .AND. nUndoCount > 0
   MENUITEM GL("&Redo") + chr(9) + GL("Ctrl+Y") RESOURCE "B_REDO_16" ;
      ACTION Redo() ;
      ACCELERATOR ACC_CONTROL, ASC( GL("Y") ) ;
      WHEN .NOT. EMPTY( cDefIni ) .AND. nRedoCount > 0
   SEPARATOR

   MENUITEM GL("Cu&t") + chr(9) + GL("Ctrl+X") ;
      ACTION ( ItemCopy( .T. ), nAktItem := 0 ) ;
      ACCELERATOR ACC_CONTROL, ASC( GL("X") ) ;
      WHEN .NOT. EMPTY( cDefIni )
   MENUITEM GL("&Copy") + chr(9) + GL("Ctrl+C") ;
      ACTION ItemCopy( .F. ) ;
      ACCELERATOR ACC_CONTROL, ASC( GL("C") ) ;
      WHEN .NOT. EMPTY( cDefIni )
   MENUITEM GL("&Paste") + chr(9) + GL("Ctrl+V") ;
      ACTION ItemPaste()  ;
      ACCELERATOR ACC_CONTROL, ASC( GL("V") ) ;
      WHEN .NOT. EMPTY( cDefIni ) .AND. .NOT. EMPTY( cItemCopy )
   SEPARATOR

   IF VAL( GetPvProfString( "General", "InsertAreas", "1", cDefIni ) ) <> 1
      IF VAL( GetPvProfString( "General", "EditAreaProperties", "1", cDefIni ) ) = 1
         MENUITEM GL("&Area Properties") + chr(9) + GL("Ctrl+A") RESOURCE "B_AREA" ;
            ACTION AreaProperties( nAktArea ) ;
            ACCELERATOR ACC_CONTROL, ASC( GL("A") ) ;
            WHEN .NOT. EMPTY( cDefIni )
         SEPARATOR
      ENDIF
   ENDIF

   MENUITEM GL("Select all Items") ;
      ACTION SelectAllItems() WHEN .NOT. EMPTY( cDefIni )
   MENUITEM GL("Select all Items in current Area") ;
      ACTION SelectAllItems( .T. ) WHEN .NOT. EMPTY( cDefIni )
   MENUITEM GL("Invert Selection") ;
      ACTION InvertSelection() WHEN .NOT. EMPTY( cDefIni )
   MENUITEM GL("Invert Selection in current Area") ;
      ACTION InvertSelection( .T. ) WHEN .NOT. EMPTY( cDefIni )
   SEPARATOR
   MENUITEM GL("Delete in current Area") WHEN .NOT. EMPTY( cDefIni )
      MENU
      MENUITEM GL("&Text")    ACTION DeleteAllItems( 1 )
      MENUITEM GL("I&mage")   ACTION DeleteAllItems( 2 )
      MENUITEM GL("&Graphic") ACTION DeleteAllItems( 3 )
      MENUITEM GL("&Barcode") ACTION DeleteAllItems( 4 )
      ENDMENU
   ENDMENU

   IF VAL( GetPvProfString( "General", "InsertMode", "1", cDefIni ) ) = 1

      MENUITEM GL("&Items")
      MENU
      MENUITEM GL("Insert &Text") + chr(9) + GL("Ctrl+T") RESOURCE "B_TEXT" ;
         ACCELERATOR ACC_CONTROL, ASC( GL("T") ) ;
         ACTION NewItem( "TEXT", nAktArea ) ;
         WHEN .NOT. EMPTY( cDefIni )
      MENUITEM GL("Insert &Image") + chr(9) + GL("Ctrl+M") RESOURCE "B_IMAGE" ;
         ACCELERATOR ACC_CONTROL, ASC( GL("M") ) ;
         ACTION NewItem( "IMAGE", nAktArea ) ;
         WHEN .NOT. EMPTY( cDefIni )
      MENUITEM GL("Insert &Graphic") + chr(9) + GL("Ctrl+G") RESOURCE "B_GRAPHIC" ;
         ACCELERATOR ACC_CONTROL, ASC( GL("G") ) ;
         ACTION NewItem( "GRAPHIC", nAktArea ) ;
         WHEN .NOT. EMPTY( cDefIni )
      MENUITEM GL("Insert &Barcode") + chr(9) + GL("Ctrl+B") RESOURCE "B_BARCODE" ;
         ACCELERATOR ACC_CONTROL, ASC( ("B") ) ;
         ACTION NewItem( "BARCODE", nAktArea ) ;
         WHEN .NOT. EMPTY( cDefIni )
      SEPARATOR
      MENUITEM GL("&Item Properties") + chr(9) + GL("Ctrl+I") RESOURCE "B_EDIT" ;
         ACTION IIF( LEN( aSelection ) <> 0, MultiItemProperties(), ItemProperties( nAktItem, nAktArea ) ) ;
         ACCELERATOR ACC_CONTROL, ASC( GL("I") ) ;
         WHEN .NOT. EMPTY( cDefIni )
      ENDMENU

      IF VAL( GetPvProfString( "General", "InsertAreas", "1", cDefIni ) ) = 1
      MENUITEM GL("&Areas")
      MENU
      MENUITEM GL("Insert Area &before") ACTION InsertArea( .T., STRTRAN( GL("Insert Area &before"), "&" ) )
      MENUITEM GL("Insert Area &after" ) ACTION InsertArea( .F., STRTRAN( GL("Insert Area &after" ), "&" ) )
      SEPARATOR
      MENUITEM GL("&Delete current Area") ACTION DeleteArea()
      SEPARATOR
      IF VAL( GetPvProfString( "General", "EditAreaProperties", "1", cDefIni ) ) = 1
         MENUITEM GL("&Area Properties") + chr(9) + GL("Ctrl+A") RESOURCE "B_AREA" ;
            ACTION AreaProperties( nAktArea ) ;
            ACCELERATOR ACC_CONTROL, ASC( GL("A") ) ;
            WHEN .NOT. EMPTY( cDefIni )
      ENDIF
      ENDMENU
      ENDIF

   ENDIF

   MENUITEM GL("&Extras")
   MENU
   MENUITEM GL("Area and Item &List") + chr(9) + GL("Ctrl+L") RESOURCE "B_ITEMLIST" ;
      ACTION Itemlist() ;
      ACCELERATOR ACC_CONTROL, ASC( GL("L") ) ;
      WHEN .NOT. EMPTY( cDefIni )
   IF VAL( GetPvProfString( "General", "EditProperties", "1", cDefIni ) ) = 1
      MENUITEM GL("&Fonts and Colors") + chr(9) + GL("Ctrl+F") RESOURCE "B_FONTCOLOR" ;
         ACTION GeneralSettings() ;
         ACCELERATOR ACC_CONTROL, ASC( GL("F") ) ;
         WHEN .NOT. EMPTY( cDefIni )
   ENDIF
   SEPARATOR
   IF VAL( GetPvProfString( "General", "Expressions", "0", cDefIni ) ) > 0
      MENUITEM GL("&Expressions") ;
         ACTION Expressions() ;
         WHEN .NOT. EMPTY( cDefIni )
   ENDIF
   IF VAL( GetPvProfString( "General", "EditDatabases", "1", cDefIni ) ) > 0
      MENUITEM GL("&Databases") ;
         ACTION Databases() ;
         WHEN .NOT. EMPTY( cDefIni )
   ENDIF
   MENUITEM GL("&Report Settings") ;
      ACTION ReportSettings() ;
      WHEN .NOT. EMPTY( cDefIni )
   SEPARATOR
   IF VAL( GetPvProfString( "General", "EditLanguage", "0", cDefIni ) ) = 1
      MENUITEM GL("Edit &Language") ;
         ACTION EditLanguage()
   ENDIF
   MENUITEM GL("&Options") ;
      ACTION Options() ;
      WHEN .NOT. EMPTY( cDefIni )
   ENDMENU

   IF VAL( GetPvProfString( "General", "Help", "1", cGeneralIni ) ) = 1
      MENUITEM GL("&Help")
      MENU
      MENUITEM GL("&Help Topics") + chr(9) + GL("F1") ;
         ACTION WinHelp( "VRD.HLP" ) ;
         ACCELERATOR ACC_NORMAL, VK_F1
      SEPARATOR
   ELSE
      MENUITEM GL("&Info")
      MENU
   ENDIF

   IF lPersonal = .T. .OR. lStandard = .T.
      MENUITEM GL("&Registration") ;
         ACTION VRDMsgPersonal()
   ENDIF
   MENUITEM GL("&About") ;
      ACTION VRDAbout()
   ENDMENU

   ENDMENU

RETURN( oMenu )


*-- FUNCTION -----------------------------------------------------------------
*         Name: PopupMenu
* Beschreibung:
*    Argumente: None
* Rückgabewert: .T.                   Autor: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION PopupMenu( nArea, oItem, nRow, nCol, lItem )

   LOCAL oMenu

   DEFAULT lItem := .F.

   MENU oMenu POPUP

   IF LEN( aSelection ) <> 0 .OR. nAktItem <> 0
   MENUITEM GL("&Item Properties") + chr(9) + GL("Ctrl+I") RESOURCE "B_EDIT" ;
      ACTION IIF( LEN( aSelection ) <> 0, MultiItemProperties(), ItemProperties( nAktItem, nAktArea ) )
   ENDIF
   IF LEN( aSelection ) <> 0
   MENUITEM GL("&Delete selected Items") + CHR(9) + GL("Del") ;
      ACTION DelSelectItems()
   SEPARATOR
   ENDIF
   MENUITEM GL("Area and Item &List") + CHR(9) + GL("Ctrl+L") RESOURCE "B_ITEMLIST" ;
      ACTION Itemlist()
   MENUITEM GL("&Fonts and Colors") + CHR(9) + GL("Ctrl+F")   RESOURCE "B_FONTCOLOR" ;
      ACTION GeneralSettings()
   SEPARATOR
   MENUITEM GL("&Area Properties") + CHR(9) + GL("Ctrl+A")    RESOURCE "B_AREA" ;
      ACTION ( aWnd[nArea]:SetFocus(), AreaProperties( nAktArea ) )
   SEPARATOR
   MENUITEM GL("&Report Settings") ACTION ReportSettings()
   MENUITEM GL("&Options")         ACTION Options()
   IF VAL( GetPvProfString( "General", "Help", "1", cGeneralIni ) ) = 1
      SEPARATOR
      MENUITEM GL("&Help Topics") + CHR(9) + GL("F1") ACTION WinHelp( "VRD.HLP" )
   ENDIF
   IF nDeveloper = 1
      SEPARATOR
      MENUITEM GL("&Generate Source Code") ACTION GenerateSource( nArea )
   ENDIF

   SEPARATOR
   MENUITEM GL("&Paste") + chr(9) + GL("Ctrl+V") ;
      ACTION ItemPaste() ;
      WHEN .NOT. EMPTY( cItemCopy )

   ENDMENU

   ACTIVATE POPUP oMenu OF IIF( lItem = .T., oItem, aWnd[nArea] ) AT nRow, nCol

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: GenerateSource
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GenerateSource( nArea )

   LOCAL i, oDlg, oGet1, cDir, cAreaDef, cAreaTitle, cItemDef, oRad1
   LOCAL cFile     := SPACE(120)
   LOCAL lGenerate := .F.
   LOCAL nCopyTo   := 1
   LOCAL nStyle    := 1
   LOCAL cSource   := CRLF
   LOCAL cIDs      := ""
   LOCAL cNames    := ""

   DEFINE DIALOG oDlg NAME "GENERATESOURCE" TITLE GL("Generate Source Code")

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ;
      ACTION IIF( nCopyTo = 2 .AND. CheckFileName( cFile ) = .F.,, ;
                  EVAL( {|| lGenerate := .T., oDlg:End() } ) )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE RADIO oRad1 VAR nCopyTo ID 301, 302 OF oDlg
   REDEFINE RADIO nStyle  ID 401, 402 OF oDlg

   REDEFINE GET oGet1 VAR cFile ID 201 OF oDlg UPDATE WHEN nCopyTo = 2

   REDEFINE SAY PROMPT GL("Use method") + ":" ID 171 OF oDlg

   REDEFINE BTNBMP ID 151 OF oDlg RESOURCE "OPEN" UPDATE ;
      TOOLTIP GL("Directory") ;
      ACTION ( cDir := cGetDir32( GL("Select a directory") ), ;
               IIF( AT( "\", cFile ) = 0 .AND. .NOT. EMPTY( cDir ), ;
                  cFile := cDir + "\" + cFile, ), ;
               oGet1:Refresh() )

   ACTIVATE DIALOG oDlg CENTER ;
      ON INIT( oRad1:aItems[1]:SetText( GL("Copy to clipboard") ), ;
               oRad1:aItems[2]:SetText( GL("Copy to file") + ":" ) )

   IF lGenerate = .T.

      cAreaDef := GetPvProfString( "Areas", ALLTRIM(STR(nArea,5)) , "", cDefIni )
      cAreaDef := VRD_LF2SF( ALLTRIM( cAreaDef ) )

      cAreaTitle := ALLTRIM( GetPvProfString( "General", "Title" , "", aAreaIni[nArea] ) )

      IF .NOT. EMPTY( cAreaTitle )
         cSource += SPACE(3) + "//--- Area: " + cAreaTitle + " ---" + CRLF
      ENDIF

      FOR i := 1 TO 1000

         cItemDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(i,5)) , "", aAreaIni[nArea] ) )

         IF .NOT. EMPTY( cItemDef )
            IF nStyle = 1
               cSource += SPACE(3) + "oVRD:PrintItem( " + ;
                          ALLTRIM(STR( nArea,3 )) + ;
                          ", " + ALLTRIM(GetField( cItemDef, 3 )) + ;
                          ', "' + ALLTRIM(GetField( cItemDef, 2 )) + ;
                          '" )' + CRLF
            ELSE
               cIDs   += IIF( EMPTY( cIDs ), "", ", ") + ALLTRIM(GetField( cItemDef, 3 ))
               cNames += IIF( EMPTY( cNames ), '"', ', "') + ALLTRIM(GetField( cItemDef, 2 )) + '"'
            ENDIF
         ENDIF

      NEXT

      IF nStyle = 2
         cSource += SPACE(3) + "oVRD:PrintItemList( " + ALLTRIM(STR( nArea,3 )) + ;
                    ", { " + cIDs + " }" + ", ;" + CRLF + ;
                    SPACE(6) + "{ " + cNames + " } )" + CRLF
      ENDIF

      cSource += CRLF + SPACE(3) + ;
                 "oVRD:PrintRest( " + ALLTRIM(STR( nArea, 3 )) + " )" + CRLF

      IF nCopyTo = 1

         OpenClipboard( oMainWnd:hWnd )
         SetClipboardData( 1, cSource )
         CloseClipboard()

      ELSE

         CreateNewFile( cFile )

         MEMOWRIT( VRD_LF2SF( cFile ), cSource )

      ENDIF

   ENDIF

RETURN (NIL)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ClientWindow
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ClientWindows()

   LOCAL i, nWnd, cItemDef, cTitle, nWidth, nHeight, nDemoWidth
   LOCAL lFirstWnd     := .F.
   LOCAL nTop          := 0
   LOCAL nWindowNr     := 0
   LOCAL aIniEntries   := GetIniSection( "Areas", cDefIni )
   LOCAL cAreaFilesDir := CheckPath( GetPvProfString( "General", "AreaFilesDir", "", cDefIni ) )

   //Sichern
   aVRDSave := ARRAY( 102, 2 )
   aVRDSave[101,1] := cDefIni
   aVRDSave[101,2] := MEMOREAD( cDefIni )
   aVRDSave[102,1] := cGeneralIni
   aVRDSave[102,2] := MEMOREAD( cGeneralIni )

   FOR i := 1 TO LEN( aIniEntries )

      nWnd := EntryNr( aIniEntries[i] )
      cItemDef := GetIniEntry( aIniEntries,, "",, i )

      IF nWnd <> 0 .AND. .NOT. EMPTY( cItemDef )

         IF lFirstWnd = .F.
            nAktArea := nWnd
            lFirstWnd := .T.
         ENDIF

         IF EMPTY( cAreaFilesDir )
            cAreaFilesDir := cDefaultPath
         ENDIF
         IF EMPTY( cAreaFilesDir )
            cAreaFilesDir := cDefIniPath
         ENDIF

         cItemDef := VRD_LF2SF( ALLTRIM( cAreaFilesDir + cItemDef ) )

         aVRDSave[nWnd,1] := cItemDef
         aVRDSave[nWnd,2] := MEMOREAD( cItemDef )

         nWindowNr += 1
         aAreaIni[nWnd] := IIF( AT( "\", cItemDef ) = 0, ".\", "" ) + cItemDef

         cTitle  := ALLTRIM( GetPvProfString( "General", "Title" , "", aAreaIni[nWnd] ) )

         oGenVar:aAreaSizes[nWnd] := ;
            { VAL( GetPvProfString( "General", "Width", "600", aAreaIni[nWnd] ) ), ;
              VAL( GetPvProfString( "General", "Height", "300", aAreaIni[nWnd] ) ) }

         nWidth  := ER_GetPixel( oGenVar:aAreaSizes[nWnd,1] )
         nHeight := ER_GetPixel( oGenVar:aAreaSizes[nWnd,2] )

         nDemoWidth := nWidth
         IF oGenVar:lFixedAreaWidth = .T.
            nWidth := 1200
         ELSE
            nWidth += nRuler + nAreaZugabe2
         ENDIF

         DEFINE WINDOW aWnd[nWnd] MDICHILD OF oMainWnd TITLE cTitle ;
            BRUSH oGenVar:oAreaBrush ;
            FROM nTop, 0 TO nTop + nHeight + nAreaZugabe, nWidth PIXEL ;
            STYLE nOr( WS_BORDER )

         aWndTitle[nWnd] := cTitle

         /*
         IF ( lDemo .OR. lBeta ) .AND. nWindowNr = 1
            //Demo-Version
            @ 44, nDemoWidth - 200 ;
               SAY "Unregistered " + IIF( lBeta, "Beta", "Demo" ) + " Version" ;
               OF aWnd[nWnd] PIXEL COLOR RGB( 192, 192, 192 ), RGB( 255, 255, 255 ) ;
               SIZE 200, 16 RIGHT
         ENDIF
         */

         FillWindow( nWnd, aAreaIni[nWnd] )

         //aWnd[nWnd]:Move( aWnd[nWnd]:nTop, aWnd[nWnd]:nLeft, nWidth, nHeight + nAreaZugabe, .T. )

         ACTIVATE WINDOW aWnd[nWnd] VALID .NOT. GETKEYSTATE( VK_ESCAPE )

         nTop += nHeight + nAreaZugabe

      ENDIF

   NEXT

   nTotalHeight := nTop
   nTotalWidth  := nWidth

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: FillWindow
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION FillWindow( nArea, cAreaIni )

   LOCAL i, cRuler1, cRuler2, aWerte, nEntry, nTmpCol
   LOCAL nFirstTop, nFirstLeft, nFirstWidth, nFirstHeight, nFirstItem
   LOCAL aFirst      := { .F., 0, 0, 0, 0, 0 }
   LOCAL nElemente   := 0
   LOCAL aIniEntries := GetIniSection( "Items", cAreaIni )

   //Ruler anzeigen
   IF nMeasure = 1 ; cRuler1 := "RULER1_MM" ; cRuler2 := "RULER2_MM" ; ENDIF
   IF nMeasure = 2 ; cRuler1 := "RULER1_IN" ; cRuler2 := "RULER2_IN" ; ENDIF
   IF nMeasure = 3 ; cRuler1 := "RULER1_PI" ; cRuler2 := "RULER2_PI" ; ENDIF

   @ 0, 0 SAY " " SIZE 1200, nRulerTop-nRuler PIXEL ;
      COLORS 0, oGenVar:nBClrAreaTitle OF aWnd[nArea]

   @ 2,  3 BTNBMP RESOURCE "AREAMINMAX" SIZE 12,12 ACTION AreaHide( nAktArea )
   @ 2, 17 BTNBMP RESOURCE "AREAPROP"   SIZE 12,12 ACTION AreaProperties( nAktArea )

   @ 2, 29 SAY oGenVar:aAreaTitle[nArea] ;
      PROMPT " " + ALLTRIM( GetPvProfString( "General", "Title" , "", cAreaIni ) ) ;
      SIZE 400, nRulerTop-nRuler-2 PIXEL FONT oGenVar:aAppFonts[1] ;
      COLORS oGenVar:nF1ClrAreaTitle, oGenVar:nBClrAreaTitle OF aWnd[nArea]

   @ nRulerTop-nRuler, 20 BITMAP oRulerBmp2 RESOURCE cRuler1 OF aWnd[nArea] PIXEL NOBORDER
   @ nRulerTop-nRuler, 0 BITMAP oRulerBmp2 RESOURCE cRuler2 OF aWnd[nArea] PIXEL NOBORDER

   @ nRulerTop-nRuler, 20 SAY aRuler[nArea,1] PROMPT "" SIZE  1, 20 PIXEL ;
      COLORS oGenVar:nClrReticule, oGenVar:nClrReticule OF aWnd[nArea]
   @ 20, 0 SAY aRuler[nArea,2] PROMPT "" SIZE 20,  1 PIXEL ;
      COLORS oGenVar:nClrReticule, oGenVar:nClrReticule OF aWnd[nArea]

   aWnd[nArea]:bPainted  = {| hDC, cPS | ZeichneHintergrund( nArea ) }

   aWnd[nArea]:bGotFocus = {|| SetTitleColor( .F. ), ;
                               nAktArea := nArea, oCbxArea:Set( aWndTitle[nArea] ), ;
                               SetTitleColor( .T. ) }

   aWnd[nArea]:bMMoved = {|nRow,nCol,nFlags| ;
                           SetReticule( nRow, nCol, nArea ), ;
                           MsgBarInfos( nRow, nCol ), ;
                           MoveSelection( nRow, nCol, aWnd[nArea] ) }

   aWnd[nArea]:bRClicked = {|nRow,nCol,nFlags| PopupMenu( nArea,, nRow, nCol ) }
   aWnd[nArea]:bLClicked = {|nRow,nCol,nFlags| DeactivateItem(), ;
                              IIF( GetKeyState( VK_SHIFT ),, UnSelectAll() ), ;
                              StartSelection( nRow, nCol, aWnd[nArea] ) }
   aWnd[nArea]:bLButtonUp = {|nRow,nCol,nFlags| StopSelection( nRow, nCol, aWnd[nArea] ) }

   aWnd[nArea]:bKeyDown   = {|nKey| WndKeyDownAction( nKey, nArea, cAreaIni ) }

   FOR i := 1 TO LEN( aIniEntries )
      nEntry := EntryNr( aIniEntries[i] )
      IF nEntry <> 0
         ShowItem( nEntry, nArea, cAreaIni, @aFirst, @nElemente, aIniEntries, i )
      ENDIF
   NEXT

   //Durch diese Anweisung werden alle Controls resizable
   IF nElemente <> 0
      lFillWindow := .T.
      aItems[nArea,aFirst[6]]:CheckDots()
      aItems[nArea,aFirst[6]]:Move( aFirst[2], aFirst[3], aFirst[4], aFirst[5], .T. )
      lFillWindow := .F.
   ENDIF

   Memory(-1)
   SysRefresh()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: SetReticule
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetReticule( nRow, nCol, nArea )

   LOCAL nRowPos := nRow
   LOCAL nColPos := nCol
   LOCAL lShow   := ( oGenVar:lShowReticule = .T. .AND. oGenVar:lSelectItems = .F. )

   IF nRow <= nRulerTop
      nRowPos := nRulerTop
   ELSEIF nRow >= ER_GetPixel( oGenVar:aAreaSizes[nArea,2] ) + nRulerTop
      nRowPos := ER_GetPixel( oGenVar:aAreaSizes[nArea,2] ) + nRulerTop
   ENDIF

   IF nCol <= nRuler
      nColPos := nRuler
   ELSEIF nCol >= ER_GetPixel( oGenVar:aAreaSizes[nArea,1] ) + nRuler
      nColPos := ER_GetPixel( oGenVar:aAreaSizes[nArea,1] ) + nRuler
   ENDIF

   aRuler[nArea,2]:Move( nRowPos, 0, ;
      IIF( lShow, ER_GetPixel( oGenVar:aAreaSizes[nArea,1] ) + nRuler, nRuler ), 1, .T. )

   AEVAL( aRuler, {|x,y| IIF( x[1] <> NIL, ;
      ( x[1]:Move( nRulerTop-nRuler, nColPos, 1, ;
          IIF( lShow, ER_GetPixel( oGenVar:aAreaSizes[y,2] ) + nRuler, nRuler ), .T. ) ), ) } )

   //AEVAL( aRuler, {|x,y| IIF( x[1] <> NIL, ;
   //   ( x[1]:Move( nRulerTop-nRuler, nColPos, 1, ;
   //                IIF( lShow, ER_GetPixel( oGenVar:aAreaSizes[y,2] ) + nRuler, nRuler ), .T. ), ;
   //     x[1]:Refresh(), x[2]:Refresh() ), ) } )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: SetTitleColor
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetTitleColor( lOff )

   IF lOff = .T.
      oGenVar:aAreaTitle[nAktArea]:SetColor( oGenVar:nF2ClrAreaTitle, oGenVar:nBClrAreaTitle )
   ELSE
      oGenVar:aAreaTitle[nAktArea]:SetColor( oGenVar:nF1ClrAreaTitle, oGenVar:nBClrAreaTitle )
   ENDIF

   oGenVar:aAreaTitle[ nAktArea ]:Refresh()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ZeichneHintergrund
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ZeichneHintergrund( nArea )

   LOCAL nWidth  := ER_GetPixel( oGenVar:aAreaSizes[nArea,1] )
   LOCAL nHeight := ER_GetPixel( oGenVar:aAreaSizes[nArea,2] )

   SetGridSize( ER_GetPixel( oGenVar:nGridWidth ), ER_GetPixel( oGenVar:nGridHeight ) )

   //Hintergrund
   Rectangle( aWnd[nArea]:hDC, ;
              nRulerTop, nRuler, nRulerTop + nHeight + 1, nRuler + nWidth + 1 )

   //Grid zeichnen
   IF oGenVar:lShowGrid = .T.
      ShowGrid( aWnd[nArea]:hDC, aWnd[nArea]:cPS, ;
                ER_GetPixel( oGenVar:nGridWidth ), ER_GetPixel( oGenVar:nGridHeight ), ;
                nWidth, nHeight, nRulerTop, nRuler )
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: WndKeyDownAction
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION WndKeyDownAction( nKey, nArea, cAreaIni )

   LOCAL i, aWerte, nTop, nLeft, nHeight, nWidth
   LOCAL lMove    := .T.
   LOCAL nY       := 0
   LOCAL nX       := 0
   LOCAL nRight   := 0
   LOCAL nBottom  := 0

   IF LEN( aSelection ) = 0
      RETURN(.F.)
   ENDIF

   //Delete item
   IF nKey == VK_DELETE
      DelSelectItems()
   ENDIF

   //Return to edit properties
   IF nKey == VK_RETURN .AND. LEN( aSelection ) <> 0
      MultiItemProperties()
   ENDIF

   //Move and resize items
   IF GetKeyState( VK_SHIFT )
      DO CASE
      CASE nKey == VK_LEFT
         nRight := -1 * nXMove
      CASE nKey == VK_RIGHT
         nRight := 1 * nXMove
      CASE nKey == VK_UP
         nBottom := -1 * nYMove
      CASE nKey == VK_DOWN
         nBottom := 1 * nYMove
      OTHERWISE
         lMove := .F.
      ENDCASE
   ELSE
      DO CASE
      CASE nKey == VK_LEFT
         nX := -1 * nXMove
      CASE nKey == VK_RIGHT
         nX :=  1 * nXMove
      CASE nKey == VK_UP
         nY := -1 * nYMove
      CASE nKey == VK_DOWN
         nY :=  1 * nYMove
      OTHERWISE
         lMove := .F.
      ENDCASE
   ENDIF

   IF lMove = .T.

      UnSelectAll( .F. )

      FOR i := 1 TO LEN( aSelection )

         IF aItems[ aSelection[i,1], aSelection[i,2] ] <> NIL

            aWerte   := GetCoors( aItems[ aSelection[i,1], aSelection[i,2] ]:hWnd )
            nTop     := aWerte[1]
            nLeft    := aWerte[2]
            nHeight  := aWerte[3] - aWerte[1]
            nWidth   := aWerte[4] - aWerte[2]

            aItems[ aSelection[i,1], aSelection[i,2] ]:Move( nTop + nY, nLeft + nX, nWidth + nRight, nHeight + nBottom, .T. )

         ENDIF

      NEXT

      UnSelectAll( .F. )

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: DelSelectItems
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DelSelectItems()

   LOCAL i

   IF MsgNoYes( GL("Delete the selected items?"), GL("Select an option") ) = .T.

      FOR i := 1 TO LEN( aSelection )

         IF aItems[ aSelection[i,1], aSelection[i,2] ] <> NIL

            MarkItem( aItems[ aSelection[i,1], aSelection[i,2] ]:hWnd )
            DelItemWithKey( aSelection[i,2], aSelection[i,1] )

         ENDIF

      NEXT

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: MsgBarInfos
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION MsgBarInfos( nRow, nCol )

   DEFAULT nRow := 0
   DEFAULT nCol := 0

   oMsgInfo:SetText( GL("Row:")    + " " + ALLTRIM(STR( GetCmInch( nRow - nRulerTop ), 5, IIF( nMeasure = 2, 2, 0 ) ) ) + "    " + ;
                     GL("Column:") + " " + ALLTRIM(STR( GetCmInch( nCol - nRuler ), 5, IIF( nMeasure = 2, 2, 0 ) ) ) )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: CheckStyle
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CheckStyle( nPenSize, cStyle )

   IF nPenSize > 1
      cStyle := "1"
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ShowFontChoice
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ShowFontChoice( nCurrentFont )

   LOCAL i, oDlg, oLbx, oSay1, oGet1
   LOCAL nFont      := 0
   LOCAL aGetFonts  := GetFonts()
   LOCAL aShowFonts := GetFontText( aGetFonts, .F. )
   LOCAL cFont      := aShowFonts[IIF( nCurrentFont <= 0 .OR. nCurrentFont > LEN( aShowFonts), ;
                                       1, nCurrentFont )]
   LOCAL lSave      := .F.
   LOCAL cFontText  := ""

   FOR i := 33 TO 254
      cFontText += CHR( i )
   NEXT

   DEFINE DIALOG oDlg NAME "GETFONT" TITLE GL("Select Font")

   REDEFINE SAY PROMPT GL("Font")    ID 170 OF oDlg
   REDEFINE SAY PROMPT GL("Preview") ID 171 OF oDlg

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE SAY PROMPT ;
      IIF( nCurrentFont > 0, GetCurrentFont( nCurrentFont, aGetFonts ), "" ) ID 110 OF oDlg

   REDEFINE LISTBOX oLbx VAR cFont ITEMS aShowFonts ID 201 OF oDlg ;
      ON CHANGE PreviewRefresh( oSay1, oLbx, oGet1 ) ;
      ON DBLCLICK ( lSave := .T., oDlg:End() )

   oLbx:nDlgCode = DLGC_WANTALLKEYS

   REDEFINE SAY oSay1 PROMPT CRLF + CRLF + GL("Test 123") ;
      ID 301 OF oDlg UPDATE FONT aFonts[1]

   REDEFINE GET oGet1 VAR cFontText ID 311 OF oDlg UPDATE FONT aFonts[1] MEMO

   ACTIVATE DIALOG oDlg CENTERED ON INIT PreviewRefresh( oSay1, oLbx, oGet1 )

   IF lSave = .T.
      nFont := VAL(SUBSTR( ALLTRIM(cFont), 1, 2 ))
   ENDIF

RETURN ( IIF( nFont = 0, nCurrentFont, nFont ) )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetCurrentFont
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetCurrentFont( nCurrentFont, aGetFonts, nTyp )

   LOCAL cCurFont := ""

   DEFAULT nTyp := 0

   IF nTyp = 0
      cCurFont := GL("Current:") + " " + ALLTRIM(STR( nCurrentFont, 3)) + ". "
   ENDIF

   IF aGetFonts[nCurrentFont,1] <> NIL
      cCurFont += aGetFonts[nCurrentFont,1] + ;
         " " + ALLTRIM(STR( aGetFonts[nCurrentFont,3], 5 )) + ;
         IIF( aGetFonts[nCurrentFont,4], " " + GL("bold"), "") + ;
         IIF( aGetFonts[nCurrentFont,5], " " + GL("italic"), "") + ;
         IIF( aGetFonts[nCurrentFont,6], " " + GL("underline"), "") + ;
         IIF( aGetFonts[nCurrentFont,7], " " + GL("strickout"), "") + ;
         IIF( aGetFonts[nCurrentFont,8] <> 0, " " + GL("Rotation:") + " " + ALLTRIM(STR( aGetFonts[nCurrentFont,8], 6)), "")
   ELSE
      cCurFont := ""
   ENDIF

RETURN cCurFont


*-- FUNCTION -----------------------------------------------------------------
* Name........: ShowColorChoice
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ShowColorChoice( nCurrentClr )

   LOCAL oIni, oDlg, nDefClr
   LOCAL aColors := GetAllColors()
   LOCAL aSay    := ARRAY(30)
   LOCAL aBtn    := ARRAY(30)
   LOCAL nColor  := 0

   DEFINE DIALOG oDlg NAME "GETCOLOR" TITLE GL("Select Color")

   nDefClr := oDlg:nClrPane

   REDEFINE BUTTON PROMPT GL("&Cancel") ID 101 OF oDlg ACTION oDlg:End()

   REDEFINE SAY PROMPT GL("Current:") ID 170 OF oDlg

   REDEFINE SAY PROMPT ALLTRIM(STR( nCurrentClr )) + "." ID 401 OF oDlg
   REDEFINE SAY PROMPT "" ID 402 OF oDlg COLORS SetColor( aColors[nCurrentClr], nDefClr ), SetColor( aColors[nCurrentClr], nDefClr )

   REDEFINE SAY aSay[1 ] PROMPT "" ID 301 OF oDlg COLORS SetColor( aColors[1 ], nDefClr ), SetColor( aColors[1 ], nDefClr )
   REDEFINE SAY aSay[2 ] PROMPT "" ID 302 OF oDlg COLORS SetColor( aColors[2 ], nDefClr ), SetColor( aColors[2 ], nDefClr )
   REDEFINE SAY aSay[3 ] PROMPT "" ID 303 OF oDlg COLORS SetColor( aColors[3 ], nDefClr ), SetColor( aColors[3 ], nDefClr )
   REDEFINE SAY aSay[4 ] PROMPT "" ID 304 OF oDlg COLORS SetColor( aColors[4 ], nDefClr ), SetColor( aColors[4 ], nDefClr )
   REDEFINE SAY aSay[5 ] PROMPT "" ID 305 OF oDlg COLORS SetColor( aColors[5 ], nDefClr ), SetColor( aColors[5 ], nDefClr )
   REDEFINE SAY aSay[6 ] PROMPT "" ID 306 OF oDlg COLORS SetColor( aColors[6 ], nDefClr ), SetColor( aColors[6 ], nDefClr )
   REDEFINE SAY aSay[7 ] PROMPT "" ID 307 OF oDlg COLORS SetColor( aColors[7 ], nDefClr ), SetColor( aColors[7 ], nDefClr )
   REDEFINE SAY aSay[8 ] PROMPT "" ID 308 OF oDlg COLORS SetColor( aColors[8 ], nDefClr ), SetColor( aColors[8 ], nDefClr )
   REDEFINE SAY aSay[9 ] PROMPT "" ID 309 OF oDlg COLORS SetColor( aColors[9 ], nDefClr ), SetColor( aColors[9 ], nDefClr )
   REDEFINE SAY aSay[10] PROMPT "" ID 310 OF oDlg COLORS SetColor( aColors[10], nDefClr ), SetColor( aColors[10], nDefClr )
   REDEFINE SAY aSay[11] PROMPT "" ID 311 OF oDlg COLORS SetColor( aColors[11], nDefClr ), SetColor( aColors[11], nDefClr )
   REDEFINE SAY aSay[12] PROMPT "" ID 312 OF oDlg COLORS SetColor( aColors[12], nDefClr ), SetColor( aColors[12], nDefClr )
   REDEFINE SAY aSay[13] PROMPT "" ID 313 OF oDlg COLORS SetColor( aColors[13], nDefClr ), SetColor( aColors[13], nDefClr )
   REDEFINE SAY aSay[14] PROMPT "" ID 314 OF oDlg COLORS SetColor( aColors[14], nDefClr ), SetColor( aColors[14], nDefClr )
   REDEFINE SAY aSay[15] PROMPT "" ID 315 OF oDlg COLORS SetColor( aColors[15], nDefClr ), SetColor( aColors[15], nDefClr )
   REDEFINE SAY aSay[16] PROMPT "" ID 316 OF oDlg COLORS SetColor( aColors[16], nDefClr ), SetColor( aColors[16], nDefClr )
   REDEFINE SAY aSay[17] PROMPT "" ID 317 OF oDlg COLORS SetColor( aColors[17], nDefClr ), SetColor( aColors[17], nDefClr )
   REDEFINE SAY aSay[18] PROMPT "" ID 318 OF oDlg COLORS SetColor( aColors[18], nDefClr ), SetColor( aColors[18], nDefClr )
   REDEFINE SAY aSay[19] PROMPT "" ID 319 OF oDlg COLORS SetColor( aColors[19], nDefClr ), SetColor( aColors[19], nDefClr )
   REDEFINE SAY aSay[20] PROMPT "" ID 320 OF oDlg COLORS SetColor( aColors[20], nDefClr ), SetColor( aColors[20], nDefClr )
   REDEFINE SAY aSay[21] PROMPT "" ID 321 OF oDlg COLORS SetColor( aColors[21], nDefClr ), SetColor( aColors[21], nDefClr )
   REDEFINE SAY aSay[22] PROMPT "" ID 322 OF oDlg COLORS SetColor( aColors[22], nDefClr ), SetColor( aColors[22], nDefClr )
   REDEFINE SAY aSay[23] PROMPT "" ID 323 OF oDlg COLORS SetColor( aColors[23], nDefClr ), SetColor( aColors[23], nDefClr )
   REDEFINE SAY aSay[24] PROMPT "" ID 324 OF oDlg COLORS SetColor( aColors[24], nDefClr ), SetColor( aColors[24], nDefClr )
   REDEFINE SAY aSay[25] PROMPT "" ID 325 OF oDlg COLORS SetColor( aColors[25], nDefClr ), SetColor( aColors[25], nDefClr )
   REDEFINE SAY aSay[26] PROMPT "" ID 326 OF oDlg COLORS SetColor( aColors[26], nDefClr ), SetColor( aColors[26], nDefClr )
   REDEFINE SAY aSay[27] PROMPT "" ID 327 OF oDlg COLORS SetColor( aColors[27], nDefClr ), SetColor( aColors[27], nDefClr )
   REDEFINE SAY aSay[28] PROMPT "" ID 328 OF oDlg COLORS SetColor( aColors[28], nDefClr ), SetColor( aColors[28], nDefClr )
   REDEFINE SAY aSay[29] PROMPT "" ID 329 OF oDlg COLORS SetColor( aColors[29], nDefClr ), SetColor( aColors[29], nDefClr )
   REDEFINE SAY aSay[30] PROMPT "" ID 330 OF oDlg COLORS SetColor( aColors[30], nDefClr ), SetColor( aColors[30], nDefClr )

   REDEFINE BUTTON aBtn[1 ] ID 201 OF oDlg ACTION ( nColor := 1 , oDlg:End() )
   REDEFINE BUTTON aBtn[2 ] ID 202 OF oDlg ACTION ( nColor := 2 , oDlg:End() )
   REDEFINE BUTTON aBtn[3 ] ID 203 OF oDlg ACTION ( nColor := 3 , oDlg:End() )
   REDEFINE BUTTON aBtn[4 ] ID 204 OF oDlg ACTION ( nColor := 4 , oDlg:End() )
   REDEFINE BUTTON aBtn[5 ] ID 205 OF oDlg ACTION ( nColor := 5 , oDlg:End() )
   REDEFINE BUTTON aBtn[6 ] ID 206 OF oDlg ACTION ( nColor := 6 , oDlg:End() )
   REDEFINE BUTTON aBtn[7 ] ID 207 OF oDlg ACTION ( nColor := 7 , oDlg:End() )
   REDEFINE BUTTON aBtn[8 ] ID 208 OF oDlg ACTION ( nColor := 8 , oDlg:End() )
   REDEFINE BUTTON aBtn[9 ] ID 209 OF oDlg ACTION ( nColor := 9 , oDlg:End() )
   REDEFINE BUTTON aBtn[10] ID 210 OF oDlg ACTION ( nColor := 10, oDlg:End() )
   REDEFINE BUTTON aBtn[11] ID 211 OF oDlg ACTION ( nColor := 11, oDlg:End() )
   REDEFINE BUTTON aBtn[12] ID 212 OF oDlg ACTION ( nColor := 12, oDlg:End() )
   REDEFINE BUTTON aBtn[13] ID 213 OF oDlg ACTION ( nColor := 13, oDlg:End() )
   REDEFINE BUTTON aBtn[14] ID 214 OF oDlg ACTION ( nColor := 14, oDlg:End() )
   REDEFINE BUTTON aBtn[15] ID 215 OF oDlg ACTION ( nColor := 15, oDlg:End() )
   REDEFINE BUTTON aBtn[16] ID 216 OF oDlg ACTION ( nColor := 16, oDlg:End() )
   REDEFINE BUTTON aBtn[17] ID 217 OF oDlg ACTION ( nColor := 17, oDlg:End() )
   REDEFINE BUTTON aBtn[18] ID 218 OF oDlg ACTION ( nColor := 18, oDlg:End() )
   REDEFINE BUTTON aBtn[19] ID 219 OF oDlg ACTION ( nColor := 19, oDlg:End() )
   REDEFINE BUTTON aBtn[20] ID 220 OF oDlg ACTION ( nColor := 20, oDlg:End() )
   REDEFINE BUTTON aBtn[21] ID 221 OF oDlg ACTION ( nColor := 21, oDlg:End() )
   REDEFINE BUTTON aBtn[22] ID 222 OF oDlg ACTION ( nColor := 22, oDlg:End() )
   REDEFINE BUTTON aBtn[23] ID 223 OF oDlg ACTION ( nColor := 23, oDlg:End() )
   REDEFINE BUTTON aBtn[24] ID 224 OF oDlg ACTION ( nColor := 24, oDlg:End() )
   REDEFINE BUTTON aBtn[25] ID 225 OF oDlg ACTION ( nColor := 25, oDlg:End() )
   REDEFINE BUTTON aBtn[26] ID 226 OF oDlg ACTION ( nColor := 26, oDlg:End() )
   REDEFINE BUTTON aBtn[27] ID 227 OF oDlg ACTION ( nColor := 27, oDlg:End() )
   REDEFINE BUTTON aBtn[28] ID 228 OF oDlg ACTION ( nColor := 28, oDlg:End() )
   REDEFINE BUTTON aBtn[29] ID 229 OF oDlg ACTION ( nColor := 29, oDlg:End() )
   REDEFINE BUTTON aBtn[30] ID 230 OF oDlg ACTION ( nColor := 30, oDlg:End() )

   ACTIVATE DIALOG oDlg CENTERED

   //Speichervariablen freigeben
   aColors := NIL
   aSay    := NIL
   aBtn    := NIL
   MEMORY(-1)
   SYSREFRESH()

RETURN ( nColor )


*-- FUNCTION -----------------------------------------------------------------
* Name........: DefineFonts
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DefineFonts()

   LOCAL i, cFontDef
   LOCAL aGetFonts := GetFonts()

   aFonts := NIL
   aFonts := Array( 50 )

   FOR i := 1 TO 20
      aFonts[i] := TFont():New( aGetFonts[i, 1], ;   // cFaceName
                                aGetFonts[i, 2], ;   // nWidth
                                aGetFonts[i, 3], ;   // nHeight
                                , ;                  // lFromUser
                                aGetFonts[i, 4], ;   // lBold
                                aGetFonts[i, 8], ;   // nEscapement
                                aGetFonts[i,10], ;   // nOrientation
                                , ;                  // nWeight
                                aGetFonts[i, 5], ;   // lItalic
                                aGetFonts[i, 6], ;   // lUnderline
                                aGetFonts[i, 7], ;   // lStrikeOut
                                aGetFonts[i, 9] )    // nCharSet
   NEXT

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetColor
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetColor( nNr )

RETURN VAL( GetPvProfString( "Colors", ALLTRIM(STR( nNr, 5 )) , "", cDefIni ) )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetAllColors
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetAllColors()

   LOCAL i
   LOCAL aColors := {}

   FOR i := 1 TO 30
      AADD( aColors, PADR( GetPvProfString( "Colors", ALLTRIM(STR( i, 5 )) , "", cDefIni ), 15 ) )
   NEXT

RETURN ( aColors )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GeneralSettings
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GeneralSettings()

   LOCAL i, oDlg, oFld, oLbx, oSay1, oGet1, nDefClr, oIni
   LOCAL aColorGet[30], aColorSay[30]
   LOCAL aGetFonts  := GetFonts()
   LOCAL aShowFonts := GetFontText( aGetFonts )
   LOCAL cFont      := aGetFonts [1,1]
   LOCAL aColors    := GetAllColors()
   LOCAL cFontText  := ""

   FOR i := 33 TO 254
      cFontText += CHR( i )
   NEXT

   //System auffrischen
   SYSREFRESH()
   MEMORY(-1)

   DEFINE DIALOG oDlg NAME "GENERALSETTINGS" TITLE GL("Fonts, Colors and Databases")

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION oDlg:End()

   nDefClr := oDlg:nClrPane

   REDEFINE FOLDER oFld ID 110 OF oDlg ;
      PROMPT " " + GL("Fonts")     + " ", ;
             " " + GL("Colors")    + " " ;
      DIALOGS "GENERALSET_1", "GENERALSET_2"

   i := 1
   REDEFINE LISTBOX oLbx VAR cFont ITEMS aShowFonts ID 201 OF oFld:aDialogs[i] ;
      ON CHANGE PreviewRefresh( oSay1, oLbx, oGet1 ) ;
      ON DBLCLICK ( aShowFonts := SelectFont( oSay1, oLbx, oGet1 ) )

   oLbx:nDlgCode = DLGC_WANTALLKEYS
   oLbx:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, ;
                                           aShowFonts := SelectFont( oSay1, oLbx ), ) }

   REDEFINE SAY PROMPT GL("Font")    ID 170 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Preview") ID 171 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Doubleclick to edit the font properties") ID 172 OF oFld:aDialogs[i]

   REDEFINE SAY oSay1 PROMPT CRLF + CRLF + GL("Test 123") ;
      ID 301 OF oFld:aDialogs[i] UPDATE FONT aFonts[1]

   REDEFINE GET oGet1 VAR cFontText ID 311 OF oFld:aDialogs[i] UPDATE FONT aFonts[1] MEMO

   i := 2
   REDEFINE SAY PROMPT GL("Nr.")   ID 170 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Color") ID 171 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Nr.")   ID 172 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Color") ID 173 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Nr.")   ID 174 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Color") ID 175 OF oFld:aDialogs[i]

   REDEFINE SAY aColorSay[1 ] PROMPT "" ID 401 OF oFld:aDialogs[i] COLORS SetColor( aColors[1 ], nDefClr ), SetColor( aColors[1 ], nDefClr )
   REDEFINE SAY aColorSay[2 ] PROMPT "" ID 402 OF oFld:aDialogs[i] COLORS SetColor( aColors[2 ], nDefClr ), SetColor( aColors[2 ], nDefClr )
   REDEFINE SAY aColorSay[3 ] PROMPT "" ID 403 OF oFld:aDialogs[i] COLORS SetColor( aColors[3 ], nDefClr ), SetColor( aColors[3 ], nDefClr )
   REDEFINE SAY aColorSay[4 ] PROMPT "" ID 404 OF oFld:aDialogs[i] COLORS SetColor( aColors[4 ], nDefClr ), SetColor( aColors[4 ], nDefClr )
   REDEFINE SAY aColorSay[5 ] PROMPT "" ID 405 OF oFld:aDialogs[i] COLORS SetColor( aColors[5 ], nDefClr ), SetColor( aColors[5 ], nDefClr )
   REDEFINE SAY aColorSay[6 ] PROMPT "" ID 406 OF oFld:aDialogs[i] COLORS SetColor( aColors[6 ], nDefClr ), SetColor( aColors[6 ], nDefClr )
   REDEFINE SAY aColorSay[7 ] PROMPT "" ID 407 OF oFld:aDialogs[i] COLORS SetColor( aColors[7 ], nDefClr ), SetColor( aColors[7 ], nDefClr )
   REDEFINE SAY aColorSay[8 ] PROMPT "" ID 408 OF oFld:aDialogs[i] COLORS SetColor( aColors[8 ], nDefClr ), SetColor( aColors[8 ], nDefClr )
   REDEFINE SAY aColorSay[9 ] PROMPT "" ID 409 OF oFld:aDialogs[i] COLORS SetColor( aColors[9 ], nDefClr ), SetColor( aColors[9 ], nDefClr )
   REDEFINE SAY aColorSay[10] PROMPT "" ID 410 OF oFld:aDialogs[i] COLORS SetColor( aColors[10], nDefClr ), SetColor( aColors[10], nDefClr )
   REDEFINE SAY aColorSay[11] PROMPT "" ID 411 OF oFld:aDialogs[i] COLORS SetColor( aColors[11], nDefClr ), SetColor( aColors[11], nDefClr )
   REDEFINE SAY aColorSay[12] PROMPT "" ID 412 OF oFld:aDialogs[i] COLORS SetColor( aColors[12], nDefClr ), SetColor( aColors[12], nDefClr )
   REDEFINE SAY aColorSay[13] PROMPT "" ID 413 OF oFld:aDialogs[i] COLORS SetColor( aColors[13], nDefClr ), SetColor( aColors[13], nDefClr )
   REDEFINE SAY aColorSay[14] PROMPT "" ID 414 OF oFld:aDialogs[i] COLORS SetColor( aColors[14], nDefClr ), SetColor( aColors[14], nDefClr )
   REDEFINE SAY aColorSay[15] PROMPT "" ID 415 OF oFld:aDialogs[i] COLORS SetColor( aColors[15], nDefClr ), SetColor( aColors[15], nDefClr )
   REDEFINE SAY aColorSay[16] PROMPT "" ID 416 OF oFld:aDialogs[i] COLORS SetColor( aColors[16], nDefClr ), SetColor( aColors[16], nDefClr )
   REDEFINE SAY aColorSay[17] PROMPT "" ID 417 OF oFld:aDialogs[i] COLORS SetColor( aColors[17], nDefClr ), SetColor( aColors[17], nDefClr )
   REDEFINE SAY aColorSay[18] PROMPT "" ID 418 OF oFld:aDialogs[i] COLORS SetColor( aColors[18], nDefClr ), SetColor( aColors[18], nDefClr )
   REDEFINE SAY aColorSay[19] PROMPT "" ID 419 OF oFld:aDialogs[i] COLORS SetColor( aColors[19], nDefClr ), SetColor( aColors[19], nDefClr )
   REDEFINE SAY aColorSay[20] PROMPT "" ID 420 OF oFld:aDialogs[i] COLORS SetColor( aColors[20], nDefClr ), SetColor( aColors[20], nDefClr )
   REDEFINE SAY aColorSay[21] PROMPT "" ID 421 OF oFld:aDialogs[i] COLORS SetColor( aColors[21], nDefClr ), SetColor( aColors[21], nDefClr )
   REDEFINE SAY aColorSay[22] PROMPT "" ID 422 OF oFld:aDialogs[i] COLORS SetColor( aColors[22], nDefClr ), SetColor( aColors[22], nDefClr )
   REDEFINE SAY aColorSay[23] PROMPT "" ID 423 OF oFld:aDialogs[i] COLORS SetColor( aColors[23], nDefClr ), SetColor( aColors[23], nDefClr )
   REDEFINE SAY aColorSay[24] PROMPT "" ID 424 OF oFld:aDialogs[i] COLORS SetColor( aColors[24], nDefClr ), SetColor( aColors[24], nDefClr )
   REDEFINE SAY aColorSay[25] PROMPT "" ID 425 OF oFld:aDialogs[i] COLORS SetColor( aColors[25], nDefClr ), SetColor( aColors[25], nDefClr )
   REDEFINE SAY aColorSay[26] PROMPT "" ID 426 OF oFld:aDialogs[i] COLORS SetColor( aColors[26], nDefClr ), SetColor( aColors[26], nDefClr )
   REDEFINE SAY aColorSay[27] PROMPT "" ID 427 OF oFld:aDialogs[i] COLORS SetColor( aColors[27], nDefClr ), SetColor( aColors[27], nDefClr )
   REDEFINE SAY aColorSay[28] PROMPT "" ID 428 OF oFld:aDialogs[i] COLORS SetColor( aColors[28], nDefClr ), SetColor( aColors[28], nDefClr )
   REDEFINE SAY aColorSay[29] PROMPT "" ID 429 OF oFld:aDialogs[i] COLORS SetColor( aColors[29], nDefClr ), SetColor( aColors[29], nDefClr )
   REDEFINE SAY aColorSay[30] PROMPT "" ID 430 OF oFld:aDialogs[i] COLORS SetColor( aColors[30], nDefClr ), SetColor( aColors[30], nDefClr )

   REDEFINE GET aColorGet[1 ] VAR aColors[1 ] ID 201 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[1 ], aColors[1 ], nDefClr )
   REDEFINE GET aColorGet[2 ] VAR aColors[2 ] ID 202 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[2 ], aColors[2 ], nDefClr )
   REDEFINE GET aColorGet[3 ] VAR aColors[3 ] ID 203 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[3 ], aColors[3 ], nDefClr )
   REDEFINE GET aColorGet[4 ] VAR aColors[4 ] ID 204 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[4 ], aColors[4 ], nDefClr )
   REDEFINE GET aColorGet[5 ] VAR aColors[5 ] ID 205 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[5 ], aColors[5 ], nDefClr )
   REDEFINE GET aColorGet[6 ] VAR aColors[6 ] ID 206 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[6 ], aColors[6 ], nDefClr )
   REDEFINE GET aColorGet[7 ] VAR aColors[7 ] ID 207 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[7 ], aColors[7 ], nDefClr )
   REDEFINE GET aColorGet[8 ] VAR aColors[8 ] ID 208 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[8 ], aColors[8 ], nDefClr )
   REDEFINE GET aColorGet[9 ] VAR aColors[9 ] ID 209 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[9 ], aColors[9 ], nDefClr )
   REDEFINE GET aColorGet[10] VAR aColors[10] ID 210 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[10], aColors[10], nDefClr )
   REDEFINE GET aColorGet[11] VAR aColors[11] ID 211 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[11], aColors[11], nDefClr )
   REDEFINE GET aColorGet[12] VAR aColors[12] ID 212 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[12], aColors[12], nDefClr )
   REDEFINE GET aColorGet[13] VAR aColors[13] ID 213 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[13], aColors[13], nDefClr )
   REDEFINE GET aColorGet[14] VAR aColors[14] ID 214 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[14], aColors[14], nDefClr )
   REDEFINE GET aColorGet[15] VAR aColors[15] ID 215 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[15], aColors[15], nDefClr )
   REDEFINE GET aColorGet[16] VAR aColors[16] ID 216 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[16], aColors[16], nDefClr )
   REDEFINE GET aColorGet[17] VAR aColors[17] ID 217 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[17], aColors[17], nDefClr )
   REDEFINE GET aColorGet[18] VAR aColors[18] ID 218 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[18], aColors[18], nDefClr )
   REDEFINE GET aColorGet[19] VAR aColors[19] ID 219 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[19], aColors[19], nDefClr )
   REDEFINE GET aColorGet[20] VAR aColors[20] ID 220 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[20], aColors[20], nDefClr )
   REDEFINE GET aColorGet[21] VAR aColors[21] ID 221 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[21], aColors[21], nDefClr )
   REDEFINE GET aColorGet[22] VAR aColors[22] ID 222 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[22], aColors[22], nDefClr )
   REDEFINE GET aColorGet[23] VAR aColors[23] ID 223 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[23], aColors[23], nDefClr )
   REDEFINE GET aColorGet[24] VAR aColors[24] ID 224 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[24], aColors[24], nDefClr )
   REDEFINE GET aColorGet[25] VAR aColors[25] ID 225 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[25], aColors[25], nDefClr )
   REDEFINE GET aColorGet[26] VAR aColors[26] ID 226 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[26], aColors[26], nDefClr )
   REDEFINE GET aColorGet[27] VAR aColors[27] ID 227 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[27], aColors[27], nDefClr )
   REDEFINE GET aColorGet[28] VAR aColors[28] ID 228 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[28], aColors[28], nDefClr )
   REDEFINE GET aColorGet[29] VAR aColors[29] ID 229 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[29], aColors[29], nDefClr )
   REDEFINE GET aColorGet[30] VAR aColors[30] ID 230 OF oFld:aDialogs[i] VALID Set2Color( aColorSay[30], aColors[30], nDefClr )

   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 301 OF oFld:aDialogs[i] ACTION ( aColors[1 ] := Set3Color( aColorSay[1 ], aColors[1 ], nDefClr ), aColorGet[1 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 302 OF oFld:aDialogs[i] ACTION ( aColors[2 ] := Set3Color( aColorSay[2 ], aColors[2 ], nDefClr ), aColorGet[2 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 303 OF oFld:aDialogs[i] ACTION ( aColors[3 ] := Set3Color( aColorSay[3 ], aColors[3 ], nDefClr ), aColorGet[3 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 304 OF oFld:aDialogs[i] ACTION ( aColors[4 ] := Set3Color( aColorSay[4 ], aColors[4 ], nDefClr ), aColorGet[4 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 305 OF oFld:aDialogs[i] ACTION ( aColors[5 ] := Set3Color( aColorSay[5 ], aColors[5 ], nDefClr ), aColorGet[5 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 306 OF oFld:aDialogs[i] ACTION ( aColors[6 ] := Set3Color( aColorSay[6 ], aColors[6 ], nDefClr ), aColorGet[6 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 307 OF oFld:aDialogs[i] ACTION ( aColors[7 ] := Set3Color( aColorSay[7 ], aColors[7 ], nDefClr ), aColorGet[7 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 308 OF oFld:aDialogs[i] ACTION ( aColors[8 ] := Set3Color( aColorSay[8 ], aColors[8 ], nDefClr ), aColorGet[8 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 309 OF oFld:aDialogs[i] ACTION ( aColors[9 ] := Set3Color( aColorSay[9 ], aColors[9 ], nDefClr ), aColorGet[9 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 310 OF oFld:aDialogs[i] ACTION ( aColors[10] := Set3Color( aColorSay[10], aColors[10], nDefClr ), aColorGet[10]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 311 OF oFld:aDialogs[i] ACTION ( aColors[11] := Set3Color( aColorSay[11], aColors[11], nDefClr ), aColorGet[11]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 312 OF oFld:aDialogs[i] ACTION ( aColors[12] := Set3Color( aColorSay[12], aColors[12], nDefClr ), aColorGet[12]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 313 OF oFld:aDialogs[i] ACTION ( aColors[13] := Set3Color( aColorSay[13], aColors[13], nDefClr ), aColorGet[13]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 314 OF oFld:aDialogs[i] ACTION ( aColors[14] := Set3Color( aColorSay[14], aColors[14], nDefClr ), aColorGet[14]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 315 OF oFld:aDialogs[i] ACTION ( aColors[15] := Set3Color( aColorSay[15], aColors[15], nDefClr ), aColorGet[15]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 316 OF oFld:aDialogs[i] ACTION ( aColors[16] := Set3Color( aColorSay[16], aColors[16], nDefClr ), aColorGet[16]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 317 OF oFld:aDialogs[i] ACTION ( aColors[17] := Set3Color( aColorSay[17], aColors[17], nDefClr ), aColorGet[17]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 318 OF oFld:aDialogs[i] ACTION ( aColors[18] := Set3Color( aColorSay[18], aColors[18], nDefClr ), aColorGet[18]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 319 OF oFld:aDialogs[i] ACTION ( aColors[19] := Set3Color( aColorSay[19], aColors[19], nDefClr ), aColorGet[19]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 320 OF oFld:aDialogs[i] ACTION ( aColors[20] := Set3Color( aColorSay[20], aColors[20], nDefClr ), aColorGet[20]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 321 OF oFld:aDialogs[i] ACTION ( aColors[21] := Set3Color( aColorSay[21], aColors[21], nDefClr ), aColorGet[21]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 322 OF oFld:aDialogs[i] ACTION ( aColors[22] := Set3Color( aColorSay[22], aColors[22], nDefClr ), aColorGet[22]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 323 OF oFld:aDialogs[i] ACTION ( aColors[23] := Set3Color( aColorSay[23], aColors[23], nDefClr ), aColorGet[23]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 324 OF oFld:aDialogs[i] ACTION ( aColors[24] := Set3Color( aColorSay[24], aColors[24], nDefClr ), aColorGet[24]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 325 OF oFld:aDialogs[i] ACTION ( aColors[25] := Set3Color( aColorSay[25], aColors[25], nDefClr ), aColorGet[25]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 326 OF oFld:aDialogs[i] ACTION ( aColors[26] := Set3Color( aColorSay[26], aColors[26], nDefClr ), aColorGet[26]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 327 OF oFld:aDialogs[i] ACTION ( aColors[27] := Set3Color( aColorSay[27], aColors[27], nDefClr ), aColorGet[27]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 328 OF oFld:aDialogs[i] ACTION ( aColors[28] := Set3Color( aColorSay[28], aColors[28], nDefClr ), aColorGet[28]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 329 OF oFld:aDialogs[i] ACTION ( aColors[29] := Set3Color( aColorSay[29], aColors[29], nDefClr ), aColorGet[29]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 330 OF oFld:aDialogs[i] ACTION ( aColors[30] := Set3Color( aColorSay[30], aColors[30], nDefClr ), aColorGet[30]:Refresh() )

   ACTIVATE DIALOG oDlg CENTERED

   //Colors speichern
   INI oIni FILE cDefIni
   FOR i := 1 TO 30
      IF .NOT. EMPTY( aColors[i] )
         SET SECTION "Colors" ENTRY ALLTRIM(STR(i,5)) TO aColors[i] OF oIni
      ENDIF
   NEXT
   ENDINI

   SetSave( .F. )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: Set2Color
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION Set2Color( oColorSay, cColor, nDefClr )

   oColorSay:SetColor( SetColor( cColor, nDefClr ), SetColor( cColor, nDefClr ) )
   oColorSay:Refresh()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: Set3Color
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION Set3Color( oColorSay, cColor, nDefClr )

   cColor := PADR(ALLTRIM(STR( ChooseColor( VAL(cColor) ), 20 )), 40 )
   Set2Color( oColorSay, cColor, nDefClr )

RETURN ( cColor )


*-- FUNCTION -----------------------------------------------------------------
* Name........: SetColor
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetColor( cColor, nDefClr )

   LOCAL nColor

   IF EMPTY( cColor ) = .T.
      nColor := nDefClr
   ELSE
      nColor := VAL( cColor )
   ENDIF

RETURN ( nColor )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetFontText
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetFontText( aGetFonts, lShowEmpty )

   LOCAL i, cText
   LOCAL aShowFonts := {}

   DEFAULT lShowEmpty := .T.

   FOR i := 1 TO 20
      IF .NOT. EMPTY(aGetFonts[i,1])
         cText :=  ALLTRIM(STR( i, 3)) + ". " + ;
                   aGetFonts[i,1] + ;
                   " " + ALLTRIM(STR( aGetFonts[i,3], 5 )) + ;
                   IIF( aGetFonts[i,4], " " + GL("bold"), "") + ;
                   IIF( aGetFonts[i,5], " " + GL("italic"), "") + ;
                   IIF( aGetFonts[i,6], " " + GL("underline"), "") + ;
                   IIF( aGetFonts[i,7], " " + GL("strickout"), "") + ;
                   IIF( aGetFonts[i,8] <> 0, " " + GL("Rotation:") + " " + ALLTRIM(STR( aGetFonts[i,8], 6)), "")
         AADD( aShowFonts, cText )
      ELSE
         IF lShowEmpty = .T.
            AADD( aShowFonts, ALLTRIM(STR( i, 3)) + ". " )
         ENDIF
      ENDIF
   NEXT

RETURN ( aShowFonts )


*-- FUNCTION -----------------------------------------------------------------
* Name........: PreviewRefresh()
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION PreviewRefresh( oSay, oLbx, oGet )

   LOCAL nID := VAL(SUBSTR( oLbx:GetItem(oLbx:GetPos()), 1, 2))

   oSay:Default()
   oSay:SetFont( aFonts[nID] )
   oSay:Refresh()

   oGet:SetFont( aFonts[nID] )
   oGet:Refresh()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: SelectFont
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SelectFont( oSay, oLbx, oGet )

   LOCAL oDlg, cFontDef, oFontGet, oIni, oNewFont, aShowFonts, nPos, aFontNames
   LOCAL i, y, cItemDef, aIniEntries, nEntry
   LOCAL lSave       := .F.
   LOCAL aCbx        := ARRAY(4)
   LOCAL nID         := VAL(SUBSTR( oLbx:GetItem(oLbx:GetPos()), 1, 2))
   LOCAL aGetFonts   := GetFonts()
   LOCAL cFontGet    := aGetFonts[nID,1]
   LOCAL nWidth      := aGetFonts[nID,2]
   LOCAL nHeight     := aGetFonts[nID,3] * -1
   LOCAL lBold       := aGetFonts[nID,4]
   LOCAL lItalic     := aGetFonts[nID,5]
   LOCAL lUnderline  := aGetFonts[nID,6]
   LOCAL lStrikeOut  := aGetFonts[nID,7]
   LOCAL nEscapement := aGetFonts[nID,8]
   LOCAL nOrient     := aGetFonts[nID,10]
   LOCAL nCharSet    := aGetFonts[nID,9]
   LOCAL hDC         := oMainWnd:GetDC()

   IF EMPTY( aFontNames := GetFontNames( hDC ) )
      MsgStop( GL("Error getting font names."), GL("Stop!") )
      RETURN( GetFontText( GetFonts() ) )
   ELSE
      ASORT( aFontNames,,, { |x, y| UPPER( x ) < UPPER( y ) } )
   ENDIF

   DEFINE DIALOG oDlg NAME "SETFONT" TITLE GL("Font")

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE COMBOBOX oFontGet VAR cFontGet ITEMS aFontNames ID 110 OF oDlg

   REDEFINE GET nWidth      ID 201 OF oDlg PICTURE "9999"   SPINNER
   REDEFINE GET nHeight     ID 202 OF oDlg PICTURE "9999"   SPINNER
   REDEFINE GET nEscapement ID 203 OF oDlg PICTURE "999999" SPINNER
   REDEFINE GET nOrient     ID 204 OF oDlg PICTURE "999999" SPINNER
   REDEFINE GET nCharSet    ID 205 OF oDlg PICTURE "99"     SPINNER

   REDEFINE CHECKBOX aCbx[1] VAR lBold      ID 301 OF oDlg
   REDEFINE CHECKBOX aCbx[2] VAR lItalic    ID 302 OF oDlg
   REDEFINE CHECKBOX aCbx[3] VAR lUnderline ID 303 OF oDlg
   REDEFINE CHECKBOX aCbx[4] VAR lStrikeOut ID 304 OF oDlg

   REDEFINE SAY PROMPT GL("Width:")              ID 170 OF oDlg
   REDEFINE SAY PROMPT GL("Height:")             ID 171 OF oDlg
   REDEFINE SAY PROMPT GL("Rotation:")           ID 172 OF oDlg
   REDEFINE SAY PROMPT GL("Orientation")   + ":" ID 173 OF oDlg
   REDEFINE SAY PROMPT GL("Character set") + ":" ID 174 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( aCbx[1]:SetText( GL("bold") ), ;
                aCbx[2]:SetText( GL("italic") ), ;
                aCbx[3]:SetText( GL("underline") ), ;
                aCbx[4]:SetText( GL("strikeout") ) )

   IF lSave = .T.

      cFontDef := ALLTRIM( cFontGet )               + "| " + ;
                  ALLTRIM( STR( nWidth, 5 ) )       + "| " + ;
                  ALLTRIM( STR( -1 * nHeight, 5 ) ) + "| " + ;
                  IIF( lBold, "1", "0" )            + "| " + ;
                  IIF( lItalic, "1", "0" )          + "| " + ;
                  IIF( lUnderline, "1", "0" )       + "| " + ;
                  IIF( lStrikeOut, "1", "0" )       + "| " + ;
                  ALLTRIM( STR( nEscapement, 10 ) ) + "| " + ;
                  ALLTRIM( STR( nCharSet, 10 ) )    + "| " + ;
                  ALLTRIM( STR( nOrient, 10 ) )

      IF EMPTY( cFontGet )
         cFontDef := ""
      ENDIF

      INI oIni FILE cDefIni
         SET SECTION "Fonts" ENTRY ALLTRIM(STR(nID,5)) TO cFontDef OF oIni
      ENDINI

      aFonts[nID] := TFont():New( ALLTRIM( cFontGet ), nWidth, -1 * nHeight,, lBold, ;
                                  nEscapement, nOrient,, lItalic, lUnderline, lStrikeOut, ;
                                  nCharSet )

      nPos := oLbx:GetPos()
      aShowFonts := GetFontText( GetFonts() )
      oLbx:SetItems( aShowFonts )
      oLbx:Select( nPos )
      PreviewRefresh( oSay, oLbx, oGet )

      //Alle Elemente aktualisieren
      FOR i := 1 TO 100

         IF aWnd[i] <> NIL

            aIniEntries := GetIniSection( "Items", aAreaIni[i] )

            FOR y := 1 TO LEN( aIniEntries )

               nEntry := EntryNr( aIniEntries[y] )

               IF nEntry <> 0 .AND. aItems[i,nEntry] <> NIL

                  cItemDef := GetIniEntry( aIniEntries, ALLTRIM(STR(nEntry,5)) , "" )

                  IF UPPER(ALLTRIM( GetField( cItemDef, 1 ) )) = "TEXT" .AND. ;
                        VAL( GetField( cItemDef, 11 ) ) = nID

                     aItems[i,nEntry]:SetFont( aFonts[nID] )
                     aItems[i,nEntry]:Refresh()

                  ENDIF

               ENDIF

            NEXT

         ENDIF

      NEXT

   ENDIF

RETURN ( aShowFonts )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetFonts
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetFonts()

   LOCAL i, cFontDef
   LOCAL aWerte := ARRAY( 20, 10 )

   FOR i := 1 TO 20

      cFontDef := ALLTRIM( GetPvProfString( "Fonts", ALLTRIM(STR(i,3)) , "", cDefIni ) )

      IF .NOT. EMPTY( cFontDef )


         aWerte[i, 1] := ALLTRIM( GetField( cFontDef, 1 ) )                   // Name
         aWerte[i, 2] := VAL( GetField( cFontDef, 2 ) )                       // Width
         aWerte[i, 3] := VAL( GetField( cFontDef, 3 ) )                       // Height
         aWerte[i, 4] := IIF( VAL( GetField( cFontDef, 4 ) ) = 1, .T., .F. )  // Bold
         aWerte[i, 5] := IIF( VAL( GetField( cFontDef, 5 ) ) = 1, .T., .F. )  // Italic
         aWerte[i, 6] := IIF( VAL( GetField( cFontDef, 6 ) ) = 1, .T., .F. )  // Underline
         aWerte[i, 7] := IIF( VAL( GetField( cFontDef, 7 ) ) = 1, .T., .F. )  // Strikeout
         aWerte[i, 8] := VAL( GetField( cFontDef, 8 ) )                       // Escapement
         aWerte[i, 9] := VAL( GetField( cFontDef, 9 ) )                       // Character Set
         aWerte[i,10] := VAL( GetField( cFontDef, 10 ) )                      // Orientation

      ELSE

         //Leerer Font
         aWerte[i, 1] := ""
         aWerte[i, 2] := 0
         aWerte[i, 3] := -12
         aWerte[i, 4] := .F.
         aWerte[i, 5] := .F.
         aWerte[i, 6] := .F.
         aWerte[i, 7] := .F.
         aWerte[i, 8] :=0
         aWerte[i, 9] :=0
         aWerte[i,10] :=0

      ENDIF

   NEXT

RETURN ( aWerte )


*-- FUNCTION -----------------------------------------------------------------
* Name........: ReportSettings
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ReportSettings()

   LOCAL i, oDlg, oIni, aGrp[2], oRad1, aGet[1]
   LOCAL lSave       := .F.
   LOCAL nWidth      := VAL( GetPvProfString( "General", "PaperWidth" , "", cDefIni ) )
   LOCAL nHeight     := VAL( GetPvProfString( "General", "PaperHeight", "", cDefIni ) )
   LOCAL nTop        := VAL( GetPvProfString( "General", "TopMargin" , "20", cDefIni ) )
   LOCAL nLeft       := VAL( GetPvProfString( "General", "LeftMargin", "20", cDefIni ) )
   LOCAL nPageBreak  := VAL( GetPvProfString( "General", "PageBreak", "240", cDefIni ) )
   LOCAL nOrient     := VAL( GetPvProfString( "General", "Orientation", "1", cDefIni ) )
   LOCAL cTitle      := PADR( GetPvProfString( "General", "Title", "", cDefIni ), 80 )
   LOCAL cGroup      := PADR( GetPvProfString( "General", "Group", "", cDefIni ), 80 )
   LOCAL cPicture    := IIF( nMeasure = 2, "999.99", "99999" )
   LOCAL aFormat     := GetPaperSizes()
   LOCAL nFormat     := VAL( GetPvProfString( "General", "PaperSize", "9", cDefIni ) )
   LOCAL cFormat     := aFormat[ IIF( nFormat = 0, 9, nFormat ) ]

   DEFINE DIALOG oDlg NAME "REPORTOPTIONS" TITLE GL("Report Settings")

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE COMBOBOX cFormat ITEMS aFormat ID 421 OF oDlg ;
      ON CHANGE aGet[1]:Setfocus()

   REDEFINE GET nWidth ID 411 OF oDlg PICTURE cPicture SPINNER MIN 0 ;
      WHEN ALLTRIM( cFormat ) = GL("user-defined")
   REDEFINE GET nHeight ID 412 OF oDlg PICTURE cPicture SPINNER MIN 0 ;
      WHEN ALLTRIM( cFormat ) = GL("user-defined")

   REDEFINE GET aGet[1] VAR nTop ID 401 OF oDlg PICTURE cPicture SPINNER MIN 0
   REDEFINE GET nLeft      ID 402 OF oDlg PICTURE cPicture SPINNER MIN 0
   REDEFINE GET nPageBreak ID 403 OF oDlg PICTURE cPicture SPINNER MIN 0

   REDEFINE RADIO oRad1 VAR nOrient ID 601, 602 OF oDlg

   REDEFINE SAY PROMPT cMeasure ID 151 OF oDlg
   REDEFINE SAY PROMPT cMeasure ID 152 OF oDlg
   REDEFINE SAY PROMPT cMeasure ID 153 OF oDlg
   REDEFINE SAY PROMPT cMeasure ID 154 OF oDlg
   REDEFINE SAY PROMPT cMeasure ID 155 OF oDlg

   REDEFINE GET cTitle ID 501 OF oDlg
   REDEFINE GET cGroup ID 502 OF oDlg

   REDEFINE SAY PROMPT GL("Width:")           ID 171 OF oDlg
   REDEFINE SAY PROMPT GL("Height:")          ID 172 OF oDlg
   REDEFINE SAY PROMPT GL("Top margin")  +":" ID 173 OF oDlg
   REDEFINE SAY PROMPT GL("Left margin") +":" ID 174 OF oDlg
   REDEFINE SAY PROMPT GL("Page break:")      ID 175 OF oDlg
   REDEFINE SAY PROMPT GL("Name")        +":" ID 177 OF oDlg
   REDEFINE SAY PROMPT GL("Group")       +":" ID 178 OF oDlg

   REDEFINE SAY PROMPT " " + GL("Orientation") + ":" ID 176 OF oDlg

   REDEFINE GROUP aGrp[1] ID 190 OF oDlg
   REDEFINE GROUP aGrp[2] ID 191 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( aGrp[1]:SetText( GL("Paper Size") ), ;
                aGrp[2]:SetText( GL("Report") ), ;
                oRad1:aItems[1]:SetText( GL("Portrait") ), ;
                oRad1:aItems[2]:SetText( GL("Landscape") ) )

   IF lSave = .T.

      INI oIni FILE cDefIni
         SET SECTION "General" ENTRY "PaperSize"    TO ALLTRIM(STR( ASCAN( aFormat, ALLTRIM( cFormat ) ), 3 )) OF oIni
         SET SECTION "General" ENTRY "PaperWidth"   TO ALLTRIM(STR( nWidth , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "PaperHeight"  TO ALLTRIM(STR( nHeight, 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "TopMargin"    TO ALLTRIM(STR( nTop   , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "LeftMargin"   TO ALLTRIM(STR( nLeft  , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "PageBreak"    TO ALLTRIM(STR( nPageBreak, 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "Orientation"  TO ALLTRIM(STR( nOrient, 1 )) OF oIni
         SET SECTION "General" ENTRY "Title"        TO ALLTRIM( cTitle ) OF oIni
         SET SECTION "General" ENTRY "Group"        TO ALLTRIM( cGroup ) OF oIni
      ENDINI

      oMainWnd:cTitle := MainCaption()

      SetSave( .F. )

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: GetPaperSizes
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetPaperSizes()

   LOCAL aSizes := { "Letter 8 1/2 x 11 inch"        , ;
                     "Letter Small 8 1/2 x 11 inch"  , ;
                     "Tabloid 11 x 17 inch"          , ;
                     "Ledger 17 x 11 inch"           , ;
                     "Legal 8 1/2 x 14 inch"         , ;
                     "Statement 5 1/2 x 8 1/2 inch"  , ;
                     "Executive 7 1/4 x 10 1/2 inch" , ;
                     "A3 297 x 420 mm"               , ;
                     "A4 210 x 297 mm"               , ;
                     "A4 Small 210 x 297 mm"         , ;
                     "A5 148 x 210 mm"               , ;
                     "B4 250 x 354 mm"               , ;
                     "B5 182 x 257 mm"               , ;
                     "Folio 8 1/2 x 13 inch"         , ;
                     "Quarto 215 x 275 mm"           , ;
                     "10x14 inch"                    , ;
                     "11x17 inch"                    , ;
                     "Note 8 1/2 x 11 inch"          , ;
                     "Envelope #9 3 7/8 x 8 7/8"     , ;
                     "Envelope #10 4 1/8 x 9 1/2"    , ;
                     "Envelope #11 4 1/2 x 10 3/8"   , ;
                     "Envelope #12 4 \276 x 11"      , ;
                     "Envelope #14 5 x 11 1/2"       , ;
                     "C size sheet"                  , ;
                     "D size sheet"                  , ;
                     "E size sheet"                  , ;
                     "Envelope DL 110 x 220mm"       , ;
                     "Envelope C5 162 x 229 mm"      , ;
                     "Envelope C3  324 x 458 mm"     , ;
                     "Envelope C4  229 x 324 mm"     , ;
                     "Envelope C6  114 x 162 mm"     , ;
                     "Envelope C65 114 x 229 mm"     , ;
                     "Envelope B4  250 x 353 mm"     , ;
                     "Envelope B5  176 x 250 mm"     , ;
                     "Envelope B6  176 x 125 mm"     , ;
                     "Envelope 110 x 230 mm"         , ;
                     "Envelope Monarch 3.875 x 7.5 inch"   , ;
                     "6 3/4 Envelope 3 5/8 x 6 1/2 inch"   , ;
                     "US Std Fanfold 14 7/8 x 11 inch"     , ;
                     "German Std Fanfold 8 1/2 x 12 inch"  , ;
                     "German Legal Fanfold 8 1/2 x 13 inch", ;
                     GL("user-defined") }

RETURN ( aSizes )


*-- FUNCTION -----------------------------------------------------------------
* Name........: Options
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION Options()

   LOCAL i, oDlg, oIni, cLanguage, cOldLanguage, cWert, aCbx[4], aGrp[2], oRad1
   LOCAL lSave         := .F.
   LOCAL lInfo         := .F.
   LOCAL nLanguage     := VAL( GetPvProfString( "General", "Language"  , "1", cGeneralIni ) )
   LOCAL nMaximize     := VAL( GetPvProfString( "General", "Maximize"  , "1", cGeneralIni ) )
   LOCAL lMaximize     := IIF( nMaximize = 1, .T., .F. )
   LOCAL nMruList      := VAL( GetPvProfString( "General", "MruList"  , "4", cGeneralIni ) )
   LOCAL aLanguage     := {}
   LOCAL cPicture      := IIF( nMeasure = 2, "999.99", "99999" )
   LOCAL nGridWidth    := oGenVar:nGridWidth
   LOCAL nGridHeight   := oGenVar:nGridHeight
   LOCAL lShowGrid     := oGenVar:lShowGrid
   LOCAL lShowReticule := oGenVar:lShowReticule
   LOCAL lShowBorder   := oGenVar:lShowBorder

   FOR i := 1 TO 99
      cWert := GetPvProfString( "Languages", ALLTRIM(STR(i,2)), "", cGeneralIni )
      IF .NOT. EMPTY( cWert )
         AADD( aLanguage, cWert )
      ENDIF
   NEXT

   cLanguage    := aLanguage[IIF( nLanguage < 1, 1, nLanguage)]
   cOldLanguage := cLanguage

   DEFINE DIALOG oDlg NAME "OPTIONS" TITLE GL("Options")

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE COMBOBOX cLanguage ITEMS aLanguage ID 201 OF oDlg
   REDEFINE CHECKBOX aCbx[1] VAR lMaximize ID 202 OF oDlg
   REDEFINE GET nMruList  ID 203 OF oDlg PICTURE "99" SPINNER MIN 0 VALID nMruList >= 0
   REDEFINE BUTTON PROMPT GL("Clear list") ID 204 OF oDlg ACTION oMru:Clear()

   REDEFINE CHECKBOX aCbx[3] VAR lShowBorder ID 205 OF oDlg ;
      ON CHANGE IIF( lInfo = .F., ;
                     ( MsgInfo( GL("Please restart the programm to activate the changes."), ;
                                GL("Information") ), lInfo := .T. ), )

   REDEFINE CHECKBOX aCbx[4] VAR lShowReticule ID 206 OF oDlg

   REDEFINE GET nGridWidth  ID 301 OF oDlg PICTURE cPicture SPINNER MIN 0.01 VALID nGridWidth > 0
   REDEFINE GET nGridHeight ID 302 OF oDlg PICTURE cPicture SPINNER MIN 0.01 VALID nGridHeight > 0

   REDEFINE CHECKBOX aCbx[2] VAR lShowGrid ID 303 OF oDlg

   REDEFINE SAY PROMPT cMeasure ID 120 OF oDlg
   REDEFINE SAY PROMPT cMeasure ID 121 OF oDlg

   REDEFINE SAY PROMPT GL("Language:")        ID 170 OF oDlg
   REDEFINE SAY PROMPT GL("Width:")           ID 171 OF oDlg
   REDEFINE SAY PROMPT GL("Height:")          ID 172 OF oDlg
   REDEFINE SAY PROMPT GL("Entries")          ID 180 OF oDlg

   REDEFINE SAY PROMPT " " + GL("List of most recently used files") + ":" ID 179 OF oDlg

   REDEFINE GROUP aGrp[1] ID 190 OF oDlg
   REDEFINE GROUP aGrp[2] ID 191 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( aCbx[1]:SetText( GL("Maximize window at start") ), ;
                aCbx[2]:SetText( GL("Show grid") ), ;
                aCbx[3]:SetText( GL("Show always text border") ), ;
                aCbx[4]:SetText( GL("Show reticule") ), ;
                aGrp[1]:SetText( GL("General") ), ;
                aGrp[2]:SetText( GL("Grid") ) )

   IF lSave = .T.

      oGenVar:nGridWidth    := nGridWidth
      oGenVar:nGridHeight   := nGridHeight
      oGenVar:lShowGrid     := lShowGrid
      oGenVar:lShowReticule := lShowReticule
      oGenVar:lShowBorder   := lShowBorder

      INI oIni FILE cDefIni
         SET SECTION "General" ENTRY "GridWidth"  TO ALLTRIM(STR( nGridWidth , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "GridHeight" TO ALLTRIM(STR( nGridHeight, 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "ShowGrid"   TO IIF( lShowGrid, "1", "0") OF oIni
      ENDINI

      INI oIni FILE cGeneralIni
         SET SECTION "General" ENTRY "MruList"        TO ALLTRIM(STR( nMruList ))       OF oIni
         SET SECTION "General" ENTRY "Maximize"       TO IIF( lMaximize    , "1", "0")  OF oIni
         SET SECTION "General" ENTRY "ShowTextBorder" TO IIF( lShowBorder  , "1", "0" ) OF oIni
         SET SECTION "General" ENTRY "ShowReticule"   TO IIF( lShowReticule, "1", "0" ) OF oIni

         IF cLanguage <> cOldLanguage
            SET SECTION "General" ENTRY "Language" TO ;
               ALLTRIM(STR(ASCAN( aLanguage, cLanguage ), 2)) OF oIni
         ENDIF

      ENDINI

      FOR i := 1 TO 100
         IF aWnd[i] <> NIL
            aWnd[i]:Refresh()
         ENDIF
      NEXT

      SetGridSize( ER_GetPixel( nGridWidth ), ER_GetPixel( nGridHeight ) )
      nXMove := ER_GetPixel( nGridWidth )
      nYMove := ER_GetPixel( nGridHeight )

      oGenVar:nGridWidth  := nGridWidth
      oGenVar:nGridHeight := nGridHeight

      oMainWnd:SetMenu( BuildMenu() )

      SetSave( .F. )

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ItemList
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ItemList()

   LOCAL oDlg
   LOCAL oTree

   DEFINE DIALOG oDlg RESOURCE "Itemlist" TITLE GL("Item List")

   REDEFINE TREE oTree ID 201 OF oDlg ;
     BITMAPS { "FoldOpen", "FoldClose", "Checked", "Unchecked", "Property", ;
               "Typ_Text", "Typ_Image", "Typ_Graphic", "Typ_Barcode", ;
               "TreeGraph1", "TreeGraph2", "TreeGraph3", "TreeGraph4", ;
               "TreeGraph5", "TreeGraph6" } ;
     TREE STYLE nOr( TVS_HASLINES, TVS_HASBUTTONS ) ;
     ON DBLCLICK ClickListTree( oTree )

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION oDlg:End()

   ACTIVATE DIALOG oDlg CENTERED ON INIT ListTrees( oTree )

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: ListTrees
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ListTrees( oTree )

   LOCAL i, y, oTr1, oTr2, cItemDef, aElemente, nEntry, cTitle
   LOCAL lFirstArea    := .T.
   LOCAL nClose        := 1
   LOCAL nOpen         := 2
   LOCAL aIniEntries   := GetIniSection( "Areas", cDefIni )
   LOCAL cAreaFilesDir := CheckPath( GetPvProfString( "General", "AreaFilesDir", "", cDefIni ) )

   oTr1 := oTree:GetRoot()

   FOR i := 1 TO LEN( aIniEntries )

      nEntry := EntryNr( aIniEntries[i] )

      IF nEntry <> 0 //.AND. .NOT. EMPTY( aWndTitle[nEntry] )

         cTitle := aWndTitle[nEntry]

         IF lFirstArea = .T.
            oTr1 := oTr1:AddLastChild( ALLTRIM(STR(nEntry,5)) + ". " + cTitle, nClose, nOpen )
            lFirstArea := .F.
         ELSE
            oTr1 := oTr1:AddAfter( ALLTRIM(STR(nEntry,5)) + ". " + cTitle, nClose, nOpen )
         ENDIF

         IF EMPTY( cAreaFilesDir )
            cAreaFilesDir := cDefaultPath
         ENDIF
         IF EMPTY( cAreaFilesDir )
            cAreaFilesDir := cDefIniPath
         ENDIF

         cItemDef := VRD_LF2SF( cAreaFilesDir + ;
            ALLTRIM( GetIniEntry( aIniEntries, ALLTRIM(STR(nEntry,5)) , "" ) ) )

         IF .NOT. EMPTY( cItemDef )

            cItemDef := IIF( AT( "\", cItemDef ) = 0, ".\", "" ) + cItemDef

            aElemente := GetAllItems( cItemDef )
            oTr1:AddLastChild( GL("Area Properties") )

            FOR y := 1 TO LEN( aElemente )

               oTr2 := oTr1:AddLastChild( aElemente[y,2], aElemente[y,3], aElemente[y,3] )
               IF nEntry = 1 .AND. y = 1
                  oTr2:lOpened := .T.
               ENDIF
               IF aElemente[y,6] <> 0
                  oTr2:AddLastChild( GL("Visible"), aElemente[y,5], aElemente[y,4] )
               ENDIF
               oTr2:AddLastChild( GL("Item Properties") )

            NEXT

         ENDIF

      ENDIF

   NEXT

   oTree:UpdateTV()
   oTree:SetFocus()
   oTree:Expand()

RETURN oTree


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetAllItems
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetAllItems( cAktAreaIni )

   LOCAL i, cItemDef, cTyp, cName, nShow, nTyp, nDelete, nEntry
   LOCAL aWerte      := {}
   LOCAL aIniEntries := GetIniSection( "Items", cAktAreaIni )

   FOR i := 1 TO LEN( aIniEntries )

      nEntry := EntryNr( aIniEntries[i] )
      cItemDef := GetIniEntry( aIniEntries, ALLTRIM(STR(nEntry,5)) , "" )

      IF .NOT. EMPTY( cItemDef )

         cTyp    := UPPER(ALLTRIM( GetField( cItemDef, 1 ) ))
         cName   := ALLTRIM( GetField( cItemDef, 2 ) )
         nShow   := VAL( GetField( cItemDef, 4 ) )
         nDelete := VAL( GetField( cItemDef, 5 ) )

         IF UPPER( cTyp ) = "IMAGE" .AND. EMPTY( cName ) = .T.
            cName := ALLTRIM(STR(nEntry,5)) + ". " + ALLTRIM( GetField( cItemDef, 11 ) )
         ELSE
            cName := ALLTRIM(STR(nEntry,5)) + ". " + cName
         ENDIF

         IF UPPER( cTyp ) = "TEXT"
            nTyp := 6
         ELSEIF UPPER( cTyp ) = "IMAGE"
            nTyp := 7
         ELSEIF IsGraphic( cTyp ) = .T.
            nTyp := GetGraphIndex( cTyp ) + 9
         ELSEIF UPPER( cTyp ) = "BARCODE"
            nTyp := 9
         ENDIF

         AADD( aWerte, { cTyp, cName, nTyp, ;
                         IIF( nShow = 0, 4, 3 ), IIF( nShow = 0, 3, 4 ), nDelete } )

      ENDIF

   NEXT

RETURN ( aWerte )


*-- FUNCTION -----------------------------------------------------------------
* Name........: ClickListTree
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ClickListTree( oTree )

   LOCAL cItemDef ,nItem, oLinkArea, nArea, lWert
   LOCAL oLinkItem   := oTree:GetLinkAt( oTree:GetCursel() )
   LOCAL cPrompt     := oLinkItem:TreeItem:cPrompt

   IF cPrompt = GL("Visible") .OR. cPrompt = GL("Item Properties")

      nItem     := VAL( oLinkItem:ParentLink:TreeItem:cPrompt )
      oLinkArea := oLinkItem:ParentLink
      nArea     := VAL( oLinkArea:ParentLink:TreeItem:cPrompt )

   ENDIF

   IF cPrompt = GL("Area Properties")

      nArea     := VAL( oLinkItem:ParentLink:TreeItem:cPrompt )

   ENDIF

   IF cPrompt = GL("Visible")

      cItemDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(nItem,5)) , "", aAreaIni[nArea] ) )

      oLinkItem:ToggleOpened()
      oTree:Refresh()

      IF VAL( GetField( cItemDef, 4 ) ) = 0
         lWert := .F.
      ELSE
         lWert := .T.
      ENDIF

      DeleteItem( nItem, nArea, .T., lWert )

   ELSEIF cPrompt = GL("Area Properties")

      AreaProperties( nArea )

   ELSEIF cPrompt = GL("Item Properties")

      oLinkItem:ParentLink:TreeItem:SetText( ItemProperties( nItem, nArea, .T. ) )

      cItemDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(nItem,5)) , "", aAreaIni[nArea] ) )

      IF IsGraphic( UPPER(ALLTRIM( GetField( cItemDef, 1 ) )) )
         oLinkItem:ParentLink:TreeItem:iBmpOpen  := SetGraphTreeBmp( nItem, aAreaIni[nArea] )
         oLinkItem:ParentLink:TreeItem:iBmpClose := SetGraphTreeBmp( nItem, aAreaIni[nArea] )
      ENDIF

      oTree:UpdateTV()

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: SetGraphTreeBmp
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetGraphTreeBmp( nItem, cAreaIni )

   LOCAL cItemDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(nItem,5)) , "", cAreaIni ) )
   LOCAL cTyp     := UPPER(ALLTRIM( GetField( cItemDef, 1 ) ))
   LOCAL nIndex   := GetGraphIndex( cTyp )

RETURN ( nIndex + 9 )


*-- FUNCTION -----------------------------------------------------------------
* Name........: AreaProperties
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION AreaProperties( nArea )

   LOCAL i, oDlg, oIni, oBtn, oRad1, aCbx[6], aGrp[5], oSay1
   LOCAL aDbase  := { GL("none") }
   LOCAL lSave   := .F.
   LOCAL nTop1   := VAL( GetPvProfString( "General", "Top1", "0", aAreaIni[nArea] ) )
   LOCAL nTop2   := VAL( GetPvProfString( "General", "Top2", "0", aAreaIni[nArea] ) )
   LOCAL lTop    := ( GetPvProfString( "General", "TopVariable", "1", aAreaIni[nArea] ) = "1" )
   LOCAL nWidth  := VAL( GetPvProfString( "General", "Width", "600", aAreaIni[nArea] ) )
   LOCAL nHeight := VAL( GetPvProfString( "General", "Height", "300", aAreaIni[nArea] ) )
   LOCAL nCondition     := VAL( GetPvProfString( "General", "Condition", "1", aAreaIni[nArea] ) )
   LOCAL lDelSpace      := ( GetPvProfString( "General", "DelEmptySpace", "0", aAreaIni[nArea] ) = "1" )
   LOCAL lBreakBefore   := ( GetPvProfString( "General", "BreakBefore"  , "0", aAreaIni[nArea] ) = "1" )
   LOCAL lBreakAfter    := ( GetPvProfString( "General", "BreakAfter"   , "0", aAreaIni[nArea] ) = "1" )
   LOCAL lPrBeforeBreak := ( GetPvProfString( "General", "PrintBeforeBreak", "0", aAreaIni[nArea] ) = "1" )
   LOCAL lPrAfterBreak  := ( GetPvProfString( "General", "PrintAfterBreak" , "0", aAreaIni[nArea] ) = "1" )
   LOCAL cDatabase      := ALLTRIM( GetPvProfString( "General", "ControlDBF", GL("none"), aAreaIni[nArea] ) )
   LOCAL nOldWidth      := nWidth
   LOCAL nOldHeight     := nHeight
   LOCAL cPicture       := IIF( nMeasure = 2, "999.99", "99999" )
   LOCAL cAreaTitle     := aWndTitle[nArea]
   LOCAL cOldAreaText   := MEMOREAD( aAreaIni[nArea] )

   aTmpSource := {}

   FOR i := 1 TO 13
      AADD( aTmpSource, ;
         ALLTRIM( GetPvProfString( "General", "Formula" + ALLTRIM(STR(i,2)), "", aAreaIni[nArea] ) ) )
   NEXT

   AEVAL( oGenVar:aDBFile, {|x| IIF( EMPTY( x[2] ),, AADD( aDbase, ALLTRIM( x[2] ) ) ) } )

   DEFINE DIALOG oDlg RESOURCE "AREAPROPERTY" TITLE GL("Area Properties")

   REDEFINE GET cAreaTitle ID 201 OF oDlg MEMO

   REDEFINE GET nTop1   ID 301 OF oDlg PICTURE cPicture SPINNER MIN 0 UPDATE
   REDEFINE GET nTop2   ID 302 OF oDlg PICTURE cPicture SPINNER MIN 0 UPDATE
   REDEFINE CHECKBOX aCbx[4] VAR lTop ID 303 OF oDlg ;
      ON CHANGE oSay1:SetText( IIF( lTop, GL("Minimum top") + ":", GL("Top:") ) )

   REDEFINE GET nWidth  ID 401 OF oDlg PICTURE cPicture SPINNER MIN 0
   REDEFINE GET nHeight ID 402 OF oDlg PICTURE cPicture SPINNER MIN 0

   REDEFINE RADIO oRad1 VAR nCondition ID 501, 502, 503, 504 OF oDlg

   REDEFINE COMBOBOX cDatabase ITEMS aDbase ID 511 OF oDlg

   REDEFINE CHECKBOX aCbx[1] VAR lDelSpace      ID 601 OF oDlg
   REDEFINE CHECKBOX aCbx[2] VAR lBreakBefore   ID 602 OF oDlg
   REDEFINE CHECKBOX aCbx[3] VAR lBreakAfter    ID 603 OF oDlg
   REDEFINE CHECKBOX aCbx[5] VAR lPrBeforeBreak ID 604 OF oDlg
   REDEFINE CHECKBOX aCbx[6] VAR lPrAfterBreak  ID 605 OF oDlg

   SetAreaFormulaBtn( 10,  1, oDlg )
   SetAreaFormulaBtn( 11,  2, oDlg )
   SetAreaFormulaBtn( 12,  3, oDlg )
   SetAreaFormulaBtn( 13,  4, oDlg )
   SetAreaFormulaBtn( 14,  5, oDlg )
   SetAreaFormulaBtn( 15,  6, oDlg )
   SetAreaFormulaBtn( 16,  7, oDlg )
   SetAreaFormulaBtn( 17,  8, oDlg )
   SetAreaFormulaBtn( 18,  9, oDlg )
   SetAreaFormulaBtn( 19, 10, oDlg )
   SetAreaFormulaBtn( 20, 11, oDlg )
   SetAreaFormulaBtn( 21, 12, oDlg )

   REDEFINE SAY PROMPT cMeasure ID 121 OF oDlg
   REDEFINE SAY PROMPT cMeasure ID 122 OF oDlg
   REDEFINE SAY PROMPT cMeasure ID 123 OF oDlg
   REDEFINE SAY PROMPT cMeasure ID 124 OF oDlg

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE SAY oSay1 PROMPT IIF( lTop, GL("Minimum top") + ":", GL("Top:") ) ID 172 OF oDlg

   REDEFINE SAY PROMPT GL("Page = 1:")                     ID 170 OF oDlg
   REDEFINE SAY PROMPT GL("Page > 1:")                     ID 171 OF oDlg
   REDEFINE SAY PROMPT GL("Width:")                        ID 175 OF oDlg
   REDEFINE SAY PROMPT GL("Height:")                       ID 176 OF oDlg
   REDEFINE SAY PROMPT GL("Print area for each record of") ID 177 OF oDlg

   REDEFINE GROUP aGrp[1] ID 190 OF oDlg
   REDEFINE GROUP aGrp[2] ID 191 OF oDlg
   REDEFINE GROUP aGrp[3] ID 192 OF oDlg
   REDEFINE GROUP aGrp[4] ID 193 OF oDlg
   REDEFINE GROUP aGrp[5] ID 194 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( oRad1:aItems[1]:SetText( GL("always") ), ;
                oRad1:aItems[2]:SetText( GL("never") ), ;
                oRad1:aItems[3]:SetText( GL("page = 1") ), ;
                oRad1:aItems[4]:SetText( GL("page > 1") ), ;
                aGrp[1]:SetText( GL("Title") ), ;
                aGrp[2]:SetText( GL("Position") ), ;
                aGrp[3]:SetText( GL("Size") ), ;
                aGrp[4]:SetText( GL("Print Condition") ), ;
                aGrp[5]:SetText( GL("Options") ), ;
                aCbx[1]:SetText( GL("Delete empty space after last row") ), ;
                aCbx[2]:SetText( GL("New page before printing this area") ), ;
                aCbx[3]:SetText( GL("New page after printing this area") ), ;
                aCbx[5]:SetText( GL("Print this area before every page break") ), ;
                aCbx[6]:SetText( GL("Print this area after every page break") ), ;
                aCbx[4]:SetText( GL("Top depends on previous area") ) )

   IF lSave = .T.

      INI oIni FILE aAreaIni[nArea]
         SET SECTION "General" ENTRY "Title"            TO ALLTRIM( cAreaTitle ) OF oIni
         SET SECTION "General" ENTRY "Top1"             TO ALLTRIM(STR( nTop1  , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "Top2"             TO ALLTRIM(STR( nTop2  , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "TopVariable"      TO IIF( lTop = .F., "0", "1") OF oIni
         SET SECTION "General" ENTRY "Condition"        TO ALLTRIM(STR( nCondition, 1 )) OF oIni
         SET SECTION "General" ENTRY "Width"            TO ALLTRIM(STR( nWidth , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "Height"           TO ALLTRIM(STR( nHeight, 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "DelEmptySpace"    TO IIF( lDelSpace = .F., "0", "1") OF oIni
         SET SECTION "General" ENTRY "BreakBefore"      TO IIF( lBreakBefore   = .F., "0", "1") OF oIni
         SET SECTION "General" ENTRY "BreakAfter"       TO IIF( lBreakAfter    = .F., "0", "1") OF oIni
         SET SECTION "General" ENTRY "PrintBeforeBreak" TO IIF( lPrBeforeBreak = .F., "0", "1") OF oIni
         SET SECTION "General" ENTRY "PrintAfterBreak"  TO IIF( lPrAfterBreak  = .F., "0", "1") OF oIni
         SET SECTION "General" ENTRY "ControlDBF"       TO ALLTRIM( cDatabase ) OF oIni

         FOR i := 1 TO 12
            SET SECTION "General" ENTRY "Formula" + ALLTRIM(STR(i,2)) TO ALLTRIM( aTmpSource[i] ) OF oIni
         NEXT

      ENDINI

      oGenVar:aAreaSizes[nArea,1] := nWidth
      oGenVar:aAreaSizes[nArea,2] := nHeight

      AreaChange( nArea, cAreaTitle, nOldWidth, nWidth, nOldHeight, nHeight )

      SetSave( .F. )

      IF cOldAreaText <> MEMOREAD( aAreaIni[nArea] )
         Add2Undo( "", 0, nArea, cOldAreaText )
      ENDIF

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: SetAreaFormulaBtn
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetAreaFormulaBtn( nID, nField, oDlg )

   LOCAL oBtn

   REDEFINE BTNBMP oBtn ID nID OF oDlg NOBORDER ;
      RESOURCE "B_SOURCE_" + IIF( EMPTY( aTmpSource[ nField ] ), "NO", "YES" ) ;
      TOOLTIP GetSourceToolTip( aTmpSource[ nField ] ) ;
      ACTION ( aTmpSource[ nField ] := EditSourceCode( 0, aTmpSource[ nField ] ), ;
               oBtn:LoadBitmaps( "B_SOURCE_" + IIF( EMPTY( aTmpSource[ nField ] ), "NO", "YES" ) ), ;
               oBtn:cToolTip := GetSourceToolTip( aTmpSource[ nField ] ), ;
               oBtn:Refresh() )

RETURN ( oBtn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: AreaChange
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION AreaChange( nArea, cAreaTitle, nOldWidth, nWidth, nOldHeight, nHeight )

   LOCAL i

   aWndTitle[nArea]   := cAreaTitle
   aWnd[nArea]:cTitle := cAreaTitle
   oGenVar:aAreaTitle[ nAktArea ]:Refresh()

   aCbxItems[oCbxArea:nAt] := cAreaTitle
   oCbxArea:Modify( cAreaTitle, oCbxArea:nAt )
   oCbxArea:Set( ALLTRIM( cAreaTitle ) )

   IF nOldWidth <> nWidth

      FOR i := 1 TO 100
         IF aWnd[i] <> NIL
            aWnd[i]:Refresh()
         ENDIF
      NEXT

   ENDIF

   IF nOldHeight <> nHeight

      aWnd[nArea]:Move( aWnd[nArea]:nTop, aWnd[nArea]:nLeft, ;
         IIF( oGenVar:lFixedAreaWidth, 1200, ER_GetPixel( nWidth ) + nRuler + nAreaZugabe2 ), ;
         IIF( oGenVar:aAreaHide[nArea], nRulerTop, ER_GetPixel( nHeight ) + nAreaZugabe ), .T. )

      FOR i := nArea+1 TO 100
         IF aWnd[i] <> NIL
            aWnd[i]:Move( aWnd[i]:nTop + ER_GetPixel( nHeight - nOldHeight ), ;
               aWnd[i]:nLeft,,, .T. )
         ENDIF
      NEXT

      nTotalHeight += ER_GetPixel( nHeight - nOldHeight )

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: AreaHide
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION AreaHide( nArea )

   LOCAL i, nDifferenz
   LOCAL nHideHeight := GetCmInch( 18 )
   LOCAL nAreaHeight := VAL( GetPvProfString( "General", "Height", "300", aAreaIni[nArea] ) )
   LOCAL nWidth      := VAL( GetPvProfString( "General", "Width", "600", aAreaIni[nArea] ) )

   oGenVar:aAreaHide[nAktArea] := !oGenVar:aAreaHide[nAktArea]

   nDifferenz := ( ER_GetPixel( nAreaHeight ) + nAreaZugabe - 18 ) * ;
                 IIF( oGenVar:aAreaHide[nAktArea], -1, 1 )

   aWnd[nArea]:Move( aWnd[nArea]:nTop, aWnd[nArea]:nLeft, ;
      IIF( oGenVar:lFixedAreaWidth, 1200, ER_GetPixel( nWidth ) + nRuler + nAreaZugabe2 ), ;
      IIF( oGenVar:aAreaHide[nAktArea], 18, ER_GetPixel( nAreaHeight ) + nAreaZugabe ), .T. )

   FOR i := nArea+1 TO 100
      IF aWnd[i] <> NIL
         aWnd[i]:Move( aWnd[i]:nTop + nDifferenz, aWnd[i]:nLeft,,, .T. )
      ENDIF
   NEXT

   nTotalHeight += nDifferenz

RETURN (.T.)

// dummy for now

function EasyPreview()

   MsgInfo( "EasyPreview Not linked yet" )
   
return nil   

function TScript()

   MsgInfo( "TScript not linked yet" )
   
return nil   
