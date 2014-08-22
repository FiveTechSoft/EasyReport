#include "FiveWin.ch"
#include "Treeview.ch"

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
MEMVAR oER

static oBtnAreas, oMenuAreas

//----------------------------------------------------------------------------//

function Main( P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, P14, P15 )

   local i, oBrush, oIni, aTest, nTime1, nTime2, cTest, oIcon, cDateFormat
   local cOldDir  := hb_CurDrive() + ":\" + GetCurDir()
   local cDefFile := ""

   lChDir( cFilePath( GetModuleFileName( GetInstance() ) ) )

   if P1  <> nil ; cDefFile += P1  + " " ; endif
   if P2  <> nil ; cDefFile += P2  + " " ; endif
   if P3  <> nil ; cDefFile += P3  + " " ; endif
   if P4  <> nil ; cDefFile += P4  + " " ; endif
   if P5  <> nil ; cDefFile += P5  + " " ; endif
   if P6  <> nil ; cDefFile += P6  + " " ; endif
   if P7  <> nil ; cDefFile += P7  + " " ; endif
   if P8  <> nil ; cDefFile += P8  + " " ; endif
   if P9  <> nil ; cDefFile += P9  + " " ; endif
   if P10 <> nil ; cDefFile += P10 + " " ; endif
   if P11 <> nil ; cDefFile += P11 + " " ; endif
   if P12 <> nil ; cDefFile += P12 + " " ; endif
   if P13 <> nil ; cDefFile += P13 + " " ; endif
   if P14 <> nil ; cDefFile += P14 + " " ; endif
   if P15 <> nil ; cDefFile += P15 + " " ; endif

   cDefFile := STRTRAN( AllTrim( cDefFile ), '"' )

   EP_TidyUp()
   EP_LinkedToApp()
   EP_SetPath( ".\" )

   //Einf�ge-Modus einschalten
   ReadInsert( .T. )

   PUBLIC oER := TEasyReport():new()

   //Publics deklarieren
   DeclarePublics( cDefFile )

   SET DELETED ON
   SET CONFIRM ON
   SET 3DLOOK ON
   SET MULTIPLE OFF
   SET DATE FORMAT to "dd.mm.yyyy"

   cDateFormat := LOWER(AllTrim( GetPvProfString( "General", "DateFormat", "", cGeneralIni )))

   SET DATE FORMAT IIF( Empty( cDateFormat ), "dd.mm.yyyy", cDateFormat )

     //Open Undo database
   OpenUndo()

   SET HELPFILE to "VRD.HLP"

   //Fonts definieren
   DEFINE FONT oAppFont NAME "Arial" SIZE 0, -12
   DEFINE ICON oIcon FILE ".\vrd.ico"

   DEFINE BRUSH oBrush RESOURCE "background"

  // SetDlgGradient( oER:aClrDialogs )
      
   DEFINE WINDOW oMainWnd FROM 0, 0 to 50, 200 VSCROLL ;
      TITLE MainCaption() ;
      BRUSH oBrush MDI ;
      ICON oIcon ;
      MENU BuildMenu()
      
   DEFINE CLIPBOARD oClpGeneral OF oMainWnd

   SET MESSAGE OF oMainWnd to oGenVar:cRegistInfo CENTERED 2010

   DEFINE MSGITEM oMsgInfo OF oMainWnd:oMsgBar SIZE 280

   oMainWnd:oMsgBar:KeybOn()
   oMainWnd:oWndClient:bMouseWheel = { | nKey, nDelta, nXPos, nYPos | ;
                                  ER_MouseWheel( nKey, nDelta, nXPos, nYPos ) }

   BarMenu()

   ACTIVATE WINDOW oMainWnd ;
      ON INIT ( SetMainWnd(), IniMainWindow(), ;
                IIF( Empty( cDefIni ), OpenFile(), SetScrollBar() ), ;
                StartMessage(), SetSave( .T. ), ClearUndoRedo() ) ;
      VALID AskSaveFiles()

   oClpGeneral:End()
   oAppFont:End()
   oBrush:End()
   oGenVar:oAreaBrush:End()
   oGenVar:oBarBrush:End()

   AEval( oGenVar:aAppFonts, {|x| x:End() } )
   AEval( aFonts, {|x| IIF( x <> nil, x:End(), ) } )

   CloseUndo()

   lChDir( cOldDir )

return nil

//----------------------------------------------------------------------------//

function BarMenu()

   local aBtn[3]
   local lPrompt := ( GetSysMetrics( 0 ) > 800 )
   
   DEFINE BUTTONBAR oBar OF oMainWnd SIZE 70, 70 2010
   
   // oBar:bClrGrad :=  oER:bClrBar

   DEFINE BUTTON RESOURCE "New" ;
      OF oBar ;
      PROMPT FWString( "New" ) ;
      TOOLTIP GL("New report") ;
      ACTION NewReport()

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
      WHEN .NOT. Empty( cDefIni ) .and. lVRDSave = .F.

   if nDeveloper = 1 .OR. oGenVar:lStandalone = .T.
      DEFINE BUTTON aBtn[ 1 ] RESOURCE "B_PREVIEW" ;
         OF oBar ;
         PROMPT FWString( "Preview" ) ;
         TOOLTIP GL("Preview") ;
         ACTION PrintReport( .T., !oGenVar:lStandalone ) ;
         WHEN .NOT. Empty( cDefIni )
   endif

   DEFINE BUTTON RESOURCE "print" ;
      OF oBar ;
      PROMPT FWString( "Print" ) ;
      TOOLTIP GL( "Print" ) ;
      ACTION PrintReport() ;
      WHEN .NOT. Empty( cDefIni )
      
   DEFINE BUTTON aBtn[2] RESOURCE "B_UNDO" ;
      OF oBar GROUP ;
      PROMPT FWString( "Undo" ) ;
      TOOLTIP STRTRAN( GL("&Undo"), "&" ) ;
      ACTION Undo() ;
      WHEN .NOT. Empty( cDefIni ) .and. nUndoCount > 0 
      // MENU UndoRedoMenu( 1, aBtn[2] ) ;

   DEFINE BUTTON aBtn[3] RESOURCE "B_REDO" ;
      OF oBar ;
      PROMPT FWString( "Redo" ) ;
      TOOLTIP STRTRAN( GL("&Redo"), "&" ) ;
      ACTION Redo() ;
      WHEN .NOT. Empty( cDefIni ) .and. nRedoCount > 0
      // MENU UndoRedoMenu( 2, aBtn[2] ) ;

   DEFINE BUTTON RESOURCE "B_ITEMLIST32" ;
      OF oBar GROUP ;
      PROMPT FWSTring( "Items" ) ;
      TOOLTIP GL("Area and Item List") ;
      ACTION Itemlist() ;
      WHEN .NOT. Empty( cDefIni )

   if Val( GetPvProfString( "General", "EditSetting", "1", cDefIni ) ) = 1
      DEFINE BUTTON RESOURCE "B_FONTCOLOR32" ;
         OF oBar ;
         PROMPT FWString( "Fonts" ) ;
         TOOLTIP GL("Fonts and Colors") ;
         ACTION FontsAndColors() ;
         WHEN .NOT. Empty( cDefIni )
   endif

   if Val( GetPvProfString( "General", "EditAreaProperties", "1", cDefIni ) ) = 1
      MENU oMenuAreas POPUP
      ENDMENU
   
      DEFINE BUTTON oBtnAreas RESOURCE "B_AREA32" ;
         OF oBar ;
         PROMPT FWSTring( "Areas" ) ; 
         TOOLTIP GL("Area Properties") ;
         ACTION AreaProperties( nAktArea ) ;
         WHEN .NOT. Empty( cDefIni ) ;
         MENU oMenuAreas
   endif

   DEFINE BUTTON RESOURCE "B_EDIT32" ;
      OF oBar ;
      PROMPT FWString( "Properties" ) ;
      TOOLTIP GL("Item Properties") ;
      ACTION IIF( LEN( aSelection ) <> 0, MultiItemProperties(), ItemProperties( nAktItem, nAktArea ) ) ;
      WHEN .NOT. Empty( cDefIni )

   if Val( GetPvProfString( "General", "InsertMode", "1", cDefIni ) ) = 1
      DEFINE BUTTON RESOURCE "B_TEXT32" ;
         OF oBar GROUP ;
         PROMPT FWString( "&Text" ) ;
         TOOLTIP STRTRAN( GL("Insert &Text"), "&" ) ;
         ACTION NewItem( "TEXT", nAktArea ) ;
         WHEN .NOT. Empty( cDefIni )

      DEFINE BUTTON RESOURCE "B_IMAGE32" ;
         OF oBar ;
         PROMPT FWString( "Image" ) ;
         TOOLTIP STRTRAN( GL("&Image"), "&" ) ;
         ACTION NewItem( "IMAGE", nAktArea ) ;
         WHEN .NOT. Empty( cDefIni )

      DEFINE BUTTON RESOURCE "B_GRAPHIC32" ;
         OF oBar ;
         PROMPT FWString( "Graphic" ) ;
         TOOLTIP STRTRAN( GL("Insert &Graphic"), "&" ) ;
         ACTION NewItem( "GRAPHIC", nAktArea ) ;
         WHEN .NOT. Empty( cDefIni )

      DEFINE BUTTON RESOURCE "B_BARCODE32" ;
         OF oBar ;
         PROMPT FWString( "Barcode" ) ;
         TOOLTIP STRTRAN( GL("Insert &Barcode"), "&" ) ;
         ACTION NewItem( "BARCODE", nAktArea ) ;
         WHEN .NOT. Empty( cDefIni )
   endif

   // if Val( GetPvProfString( "General", "ShowExitButton", "0", cGeneralIni ) ) = 1

      DEFINE BUTTON RESOURCE "B_EXIT" ;
         PROMPT FWString( "Exit" ) ;
         OF oBar GROUP ;
         ACTION oMainWnd:End() TOOLTIP GL("Exit")

   // endif

   oBar:bLClicked := {|| nil }
   oBar:bRClicked := {|| nil }

return .T.

//----------------------------------------------------------------------------//

#define MK_MBUTTON          0x0010

function ER_MouseWheel( nKey, nDelta, nXPos, nYPos )
   
   local aPoint := { nYPos, nXPos }
   
   ScreenToClient( oMainWnd:oWndClient:hWnd, aPoint )

   if IsOverWnd( oMainWnd:oWndClient:hWnd, aPoint[ 1 ], aPoint[ 2 ] )
      if lAnd( nKey, MK_MBUTTON )
         if nDelta > 0
            ScrollVertical( ,,.T. )        
         else
            ScrollVertical( ,,,.T.,, )
         endif
      else
         if nDelta > 0
            ScrollVertical( .T.,,,, .T., -( WheelScroll() ) )
         else
            ScrollVertical( , .T.,,, .T., WheelScroll() )
         endif
      endif
   endif

return .T.

//----------------------------------------------------------------------------//

function PreviewMenu( oBtn )

   local oMenu
   local aRect := GetClientRect( oBtn:hWnd )

   MENU oMenu POPUP

      MENUITEM GL("Pre&view") + chr(9) + GL("Ctrl+P") ;
         ACCELERATOR ACC_CONTROL, ASC( GL("P") ) ;
         ACTION PrintReport( .T. ) ;
         WHEN .NOT. Empty( cDefIni )
      MENUITEM GL("&Developer Preview") ;
         ACTION PrintReport( .T., .T. ) ;
         WHEN .NOT. Empty( cDefIni )

   ENDMENU

   ACTIVATE POPUP oMenu AT aRect[3], aRect[2] OF oBtn

return( oMenu )

//----------------------------------------------------------------------------//

function StartMessage()

   if lBeta = .T.
      BetaVersion()
   else
      if lDemo = .T.
         VRDLogo()
      elseif lPersonal = .T. .OR. lStandard = .T.
         lProfi := .T.
         if QuietRegCheck() = .F.
            VRDMsgPersonal()
         endif
      endif
  endif

return .T.

//----------------------------------------------------------------------------//

function DeclarePublics( cDefFile )

   PUBLIC oMainWnd, oClpGeneral, oTimer
   PUBLIC cDefIni, cDefIniPath
   PUBLIC nMeasure, cMeasure
   PUBLIC cGeneralIni := ".\vrd.ini"
   PUBLIC lDemo       := .F.
   PUBLIC lBeta       := .F.
   PUBLIC lProfi      := .T.
   PUBLIC lPersonal   := .F.
   PUBLIC lStandard   := .F.

   if lPersonal = .T. .OR. lStandard = .T.
      lProfi := .T.
   endif

   PUBLIC aItems, aFonts, oAppFont, aAreaIni, aWnd, aWndTitle, oBar, oMru
   PUBLIC aCbxItems, nAktuellItem, aRuler, cLongDefIni, cDefaultPath
   PUBLIC oCbxArea := nil
   PUBLIC oCurDlg  := nil

   //Gesamth�he und Breite
   PUBLIC nTotalHeight, nTotalWidth

   //gerade gew�hlte(s) Element, Bereich, ini-Datei, multiple Selection
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
   PUBLIC aVRDSave[102, 2 ]
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

   //Msgbar mit Elementgr��e aktualisieren wenn ein Element bewegt wird
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

   if AT( "\", cDefIni ) = 0 .and. .NOT. Empty( cDefIni )
      cDefIni := ".\" + cDefIni
   endif

   cDefIniPath := CheckPath( cFilePath( cDefIni ) )

   oGenVar:AddMember( "cRelease"  ,, "2.1.1" )
   oGenVar:AddMember( "cCopyright",, "2000-2004" )

   oGenVar:AddMember( "aLanguages",, {} )
   oGenVar:AddMember( "nLanguage" ,, Val( GetPvProfString( "General", "Language", "1", cGeneralIni ) ) )

   //Sprachdatei f�llen
   OpenLanguage()

   nHinCol1 := IniColor( GetPvProfString( "General", "BackgroundColor", "0", cGeneralIni ) )
   if nHinCol1 = 0
      nHinCol1 := RGB( 255, 255, 225 )
   endif

   nHinCol2     := RGB( 0, 128, 255 )
   nHinCol3     := RGB( 255, 255, 255 )
   aItems       := Array( 100, 1000 )
   aAreaIni     := Array( 100 )
   aWnd         := Array( 100 )
   aWndTitle    := Array( 100 )
   aRuler       := Array( 100, 2 )
   aFonts       := Array( 20 )

   nDeveloper := Val( GetPvProfString( "General", "DeveloperMode", "0", cGeneralIni ) )

   oGenVar:AddMember( "nClrReticule" ,, IniColor( GetPvProfString( "General", "ReticuleColor"      , " 50,  50,  50", cGeneralIni ) ) )
   oGenVar:AddMember( "lShowReticule",, ( GetPvProfString( "General", "ShowReticule", "1", cGeneralIni ) = "1" ) )

   oGenVar:AddMember( "aDBFile",, {} )

   oGenVar:AddMember( "lStandalone",, .F. )
   oGenVar:AddMember( "lShowGrid"  ,, .F. )
   oGenVar:AddMember( "nGridWidth" ,, 1   )
   oGenVar:AddMember( "nGridHeight",, 1   )

   if .NOT. Empty( cDefIni )
      SetGeneralSettings()
   endif

   oGenVar:AddMember( "nClrArea"       ,, IniColor( GetPvProfString( "General", "AreaBackColor", "240, 247, 255", cGeneralIni ) ) )

   oGenVar:AddMember( "cBrush"   ,, AllTrim( GetPvProfString( "General", "BackgroundBrush", "", cGeneralIni ) ) )
   oGenVar:AddMember( "cBarBrush",, AllTrim( GetPvProfString( "General", "ButtonbarBrush" , "", cGeneralIni ) ) )
   oGenVar:AddMember( "cBrushArea"     ,, GetPvProfString( "General", "AreaBackBrush"     , "", cGeneralIni ) )

   oGenVar:AddMember( "oBarBrush",, nil )

   if Empty( oGenVar:cBarBrush )
      DEFINE BRUSH oGenVar:oBarBrush COLOR GetSysColor( 15 )  // COLOR_BTNFACE
   else
      if AT( ".BMP", oGenVar:cBrush ) <> 0
         DEFINE BRUSH oGenVar:oBarBrush FILE oGenVar:cBarBrush
      else
         DEFINE BRUSH oGenVar:oBarBrush RESOURCE oGenVar:cBarBrush
      endif
   endif

   oGenVar:AddMember( "oAreaBrush",, nil )

   if Empty( oGenVar:cBrushArea )
      DEFINE BRUSH oGenVar:oAreaBrush COLOR oGenVar:nClrArea
   else
     if AT( ".BMP", oGenVar:cBrushArea ) <> 0
        DEFINE BRUSH oGenVar:oAreaBrush FILE oGenVar:cBrushArea
     else
        DEFINE BRUSH oGenVar:oAreaBrush RESOURCE oGenVar:cBrushArea
     endif
   endif

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

   DEFINE FONT oGenVar:aAppFonts[ 1 ] NAME GetSysFont() SIZE 0,-11 BOLD
   DEFINE FONT oGenVar:aAppFonts[2] NAME GetSysFont() SIZE 0,-10 BOLD

   oGenVar:AddMember( "lItemDlg",, .F. )
   oGenVar:AddMember( "lDlgSave",, .F. )
   oGenVar:AddMember( "nDlgTop" ,, Val( GetPvProfString( "ItemDialog", "Top" , "0", cGeneralIni ) ) )
   oGenVar:AddMember( "nDlgLeft",, Val( GetPvProfString( "ItemDialog", "Left", "0", cGeneralIni ) ) )

   oGenVar:AddMember( "lShowBorder",, ( GetPvProfString( "General", "ShowTextBorder", "1", cGeneralIni ) = "1" ) )

   oGenVar:AddMember( "cLoadFile" ,, "" )
   oGenVar:AddMember( "lFirstFile",, .T. )

return .T.

//----------------------------------------------------------------------------//

function SetGeneralSettings()

   nMeasure := Val( GetPvProfString( "General", "Measure", "1", cDefIni ) )
   IIF( nMeasure = 1, cMeasure := GL("mm"), )
   IIF( nMeasure = 2, cMeasure := GL("inch"), )
   IIF( nMeasure = 3, cMeasure := GL("Pixel"), )

   nDeveloper := Val( GetPvProfString( "General", "DeveloperMode", STR( nDeveloper, 1 ), cDefIni ) )

   oGenVar:lStandalone := ( GetPvProfString( "General", "Standalone"   , "0", cDefIni ) = "1" )
   oGenVar:lShowGrid   := ( GetPvProfString( "General", "ShowGrid"     , "0", cDefIni ) = "1" )
   oGenVar:nGridWidth  := Val( GetPvProfString( "General", "GridWidth" , "1", cDefIni ) )
   oGenVar:nGridHeight := Val( GetPvProfString( "General", "GridHeight", "1", cDefIni ) )
   nXMove := ER_GetPixel( oGenVar:nGridWidth )
   nYMove := ER_GetPixel( oGenVar:nGridHeight )

   OpenDatabases()

return .T.

//----------------------------------------------------------------------------//

function IniMainWindow()

   if .NOT. Empty( cDefIni )

      oGenVar:lFirstFile := .F.

      //Fonts definieren
      DefineFonts()
      //Areas initieren
      // IniAreasOnBar()
      //Designwindows �ffnen
      ClientWindows()
      //Areas anzeigen
      ShowAreasOnBar()
      //Mru erstellen
      if Val( GetPvProfString( "General", "MruList"  , "4", cGeneralIni ) ) > 0
         oMru:Save( cLongDefIni )
      endif
      CreateBackup()
   endif

return .T.

//----------------------------------------------------------------------------//

function SetScrollBar()

   local oVScroll
   local nPageZugabe := 392

   if ! Empty( oMainWnd:oWndClient:oVScroll )
      oMainWnd:oWndClient:oVScroll:SetRange( 0, nTotalHeight / 100 )

      oMainWnd:oWndClient:oVScroll:bGoUp     = {|| ScrollVertical( .T. ) }
      oMainWnd:oWndClient:oVScroll:bGoDown   = {|| ScrollVertical( , .T. ) }
      oMainWnd:oWndClient:oVScroll:bPageUp   = {|| ScrollVertical( ,, .T. ) }
      oMainWnd:oWndClient:oVScroll:bPageDown = {|| ScrollVertical( ,,, .T. ) }
      oMainWnd:oWndClient:oVScroll:bPos      = {| nWert | ScrollVertical( ,,,, .T., nWert ) }
      oMainWnd:oWndClient:oVScroll:nPgStep   = nPageZugabe   //392

      oMainWnd:oWndClient:oVScroll:SetPos( 0 )
   endif

   if ! Empty( oMainWnd:oWndClient:oHScroll )
      oMainWnd:oWndClient:oHScroll:SetRange( 0, nTotalWidth / 100 )

      oMainWnd:oWndClient:oHScroll:bGoUp     = {|| ScrollHorizont( .T. ) }
      oMainWnd:oWndClient:oHScroll:bGoDown   = {|| ScrollHorizont( , .T. ) }
      oMainWnd:oWndClient:oHScroll:bPageUp   = {|| ScrollHorizont( ,, .T. ) }
      oMainWnd:oWndClient:oHScroll:bPageDown = {|| ScrollHorizont( ,,, .T. ) }
      oMainWnd:oWndClient:oHScroll:bPos      = {| nWert | ScrollHorizont( ,,,, .T., nWert ) }
      oMainWnd:oWndClient:oHScroll:nPgStep   = 602

      oMainWnd:oWndClient:oHScroll:SetPos( 0 )
   endif

return .T.

//----------------------------------------------------------------------------//

function ScrollVertical( lUp, lDown, lPageUp, lPageDown, lPos, nPosZugabe )

   local i, aFirstWndCoors, nAltWert
   local nZugabe     := 14
   local nPageZugabe := 392
   local aCliRect    := oMainWnd:GetCliRect()
   local lReticule

   DEFAULT lUp       := .F.
   DEFAULT lDown     := .F.
   DEFAULT lPageUp   := .F.
   DEFAULT lPageDown := .F.
   DEFAULT lPos      := .F.

   UnSelectAll()

   for i := 1 to 100
      if aWnd[ i ] <> nil
         aFirstWndCoors := GetCoors( aWnd[ i ]:hWnd )
         EXIT
      endif
   next

   if lUp = .T. .OR. lPageUp = .T.
      if aFirstWndCoors[ 1 ] = 0
         nZugabe := 0
      elseif aFirstWndCoors[ 1 ] + IIF( lUp, nZugabe, nPageZugabe ) >= 0
         nZugabe     := -1 * aFirstWndCoors[ 1 ]
         nPageZugabe := -1 * aFirstWndCoors[ 1 ]
      endif
   endif

   if lDown = .T. .OR. lPageDown = .T.
      if aFirstWndCoors[ 1 ] + nTotalHeight <= aCliRect[3] - 80
         nZugabe     := 0
         nPageZugabe := 0
      endif
   endif

   lReticule = oGenVar:lShowReticule
   oGenVar:lShowReticule = .F.
   SetReticule( 0, 0 ) // turn off the rulers lines

   if lPos = .T.
      nAltWert := oMainWnd:oWndClient:oVScroll:GetPos()
      oMainWnd:oWndClient:oVScroll:SetPos( nPosZugabe )
      nZugabe := -1 * nTotalHeight * ( oMainWnd:oWndClient:oVScroll:GetPos() - nAltWert ) / ( nTotalHeight / 100 )
   endif

   for i := 1 to 100
      if aWnd[ i ] <> nil
         if lUp = .T. .OR. lPos = .T.
            aWnd[ i ]:Move( aWnd[ i ]:nTop + nZugabe, aWnd[ i ]:nLeft, 0, 0, .T. )
         elseif lDown = .T.
            aWnd[ i ]:Move( aWnd[ i ]:nTop - nZugabe, aWnd[ i ]:nLeft, 0, 0, .T. )
         elseif lPageUp = .T.
            aWnd[ i ]:Move( aWnd[ i ]:nTop + nPageZugabe, aWnd[ i ]:nLeft, 0, 0, .T. )
         elseif lPageDown = .T.
            aWnd[ i ]:Move( aWnd[ i ]:nTop - nPageZugabe, aWnd[ i ]:nLeft, 0, 0, .T. )
         endif
      endif
   next

   oGenVar:lShowReticule = lReticule

return .T.

//----------------------------------------------------------------------------//

function ScrollHorizont( lLeft, lRight, lPageLeft, lPageRight, lPos, nPosZugabe )

   local i, aFirstWndCoors, nAltWert
   local nZugabe     := 14
   local nPageZugabe := 602
   local aCliRect    := oMainWnd:GetCliRect()

   DEFAULT lLeft      := .F.
   DEFAULT lRight     := .F.
   DEFAULT lPageLeft  := .F.
   DEFAULT lPageRight := .F.
   DEFAULT lPos       := .F.

   UnSelectAll()

   for i := 1 to 100
      if aWnd[ i ] <> nil
         aFirstWndCoors := GetCoors( aWnd[ i ]:hWnd )
         EXIT
      endif
   next

   if lLeft = .T. .OR. lPageLeft = .T.
      if aFirstWndCoors[2] = 0
         nZugabe := 0
      elseif aFirstWndCoors[2] + IIF( lLeft, nZugabe, nPageZugabe ) >= 0
         nZugabe     := -1 * aFirstWndCoors[2]
         nPageZugabe := -1 * aFirstWndCoors[2]
      endif
   endif

   if lRight = .T. .OR. lPageRight = .T.
      if aFirstWndCoors[2] + nTotalWidth <= aCliRect[4] - 40
         nZugabe     := 0
         nPageZugabe := 0
      endif
   endif

   if lPos = .T.
      nAltWert := oMainWnd:oWndClient:oHScroll:GetPos()
      oMainWnd:oWndClient:oHScroll:SetPos( nPosZugabe )
      nZugabe := -1 * nTotalWidth * ( oMainWnd:oWndClient:oHScroll:GetPos() - nAltWert ) / 100
   endif


   for i := 1 to 100
      if aWnd[ i ] <> nil
         if lLeft = .T. .OR. lPos = .T.
            aWnd[ i ]:Move( aWnd[ i ]:nTop, aWnd[ i ]:nLeft + nZugabe , 0, 0, .T. )
         elseif lRight = .T.
            aWnd[ i ]:Move( aWnd[ i ]:nTop, aWnd[ i ]:nLeft - nZugabe , 0, 0, .T. )
         elseif lPageLeft = .T.
            aWnd[ i ]:Move( aWnd[ i ]:nTop, aWnd[ i ]:nLeft + nPageZugabe, 0, 0, .T. )
         elseif lPageRight = .T.
            aWnd[ i ]:Move( aWnd[ i ]:nTop, aWnd[ i ]:nLeft - nPageZugabe, 0, 0, .T. )
         endif
      endif
   next

return .T.

//----------------------------------------------------------------------------//

function SetMainWnd()

   if Val( GetPvProfString( "General", "Maximize", "1", cGeneralIni ) ) = 1
      oMainWnd:Maximize()
      SysRefresh()
   endif

return .T.

//----------------------------------------------------------------------------//

function SetWinNull()

   local i
   local nAltPos := aWnd[nAktArea]:nTop

   for i := 1 to 100
      if aWnd[ i ] <> nil
         aWnd[ i ]:Move( aWnd[ i ]:nTop - nAltPos, aWnd[ i ]:nLeft, 0, 0, .T. )
      endif
   next

return .T.

//----------------------------------------------------------------------------//

function ShowAreasOnBar()

   local n
   // local cCbxItem  := aWndTitle[ 1 ]

   // aCbxItems := {}

   // for n := 1 to LEN( aWndTitle )
   //    if .NOT. Empty( aWndTitle[ n ] )
   //      AADD( aCbxItems, aWndTitle[ n ] )
   //    endif
   // next
   
   if oMenuAreas != nil
      oMenuAreas:End()
   endif
   
   MENU oMenuAreas POPUP
      for n = 1 to Len( aWndTitle )
         if ! Empty( aWndTitle[ n ] )
            MENUITEM aWndTitle[ n ] ;
               ACTION aWnd[ AScan( aWndTitle, oMenuItem:cPrompt ) ]:SetFocus(),;
                      SetWinNull()
         endif
      next
   ENDMENU
   
   oBtnAreas:oPopup = oMenuAreas            

   //Fokus auf das erste Fenster legen
   aWnd[ AScan( aWnd, { |x| x != nil } ) ]:SetFocus()

   // oCbxArea:SetItems( aCbxItems )
   // oCbxArea:Select( 1 )
   // oCbxArea:bChange = {|| aWnd[ASCAN( aWndTitle, oCbxArea:cTitle )]:SetFocus(), SetWinNull() }

return .T.

//----------------------------------------------------------------------------//

function BuildMenu()

   local oMenu
   local nMruList := Val( GetPvProfString( "General", "MruList"  , "4", cGeneralIni ) )

   MENU oMenu 2007

   MENUITEM GL("&File")
   MENU
   if nDeveloper = 1
      MENUITEM GL("&New") ;
         ACTION NewReport()
   endif
   MENUITEM GL("&Open") + chr(9) + GL("Ctrl+O") RESOURCE "B_OPEN_16" ;
      ACCELERATOR ACC_CONTROL, ASC( GL("O") ) ;
      ACTION OpenFile()
   SEPARATOR
   MENUITEM GL("&Save") + chr(9) + GL("Ctrl+S") RESOURCE "B_SAVE_16" ;
      ACCELERATOR ACC_CONTROL, ASC( GL("S") ) ;
      ACTION SaveFile() ;
      WHEN .NOT. Empty( cDefIni ) .and. lVRDSave = .F.
   MENUITEM GL("Save &as") ;
      ACTION SaveAsFile() ;
      WHEN .NOT. Empty( cDefIni )
   SEPARATOR
   MENUITEM GL("&File Informations") ;
      ACTION FileInfos() ;
      WHEN .NOT. Empty( cDefIni )

   SEPARATOR
   if Val( GetPvProfString( "General", "Standalone", "0", cDefIni ) ) = 1
      MENUITEM GL("Pre&view") + chr(9) + GL("Ctrl+P") RESOURCE "B_PREVIEW" ;
         ACCELERATOR ACC_CONTROL, ASC( GL("P") ) ;
         ACTION PrintReport( .T. ) ;
         WHEN .NOT. Empty( cDefIni )
   endif
   if nDeveloper = 1
      MENUITEM GL("&Developer Preview") ;
         ACTION PrintReport( .T., .T. ) ;
         WHEN .NOT. Empty( cDefIni )
   endif

   MENUITEM GL("&Print") RESOURCE "print16" ;
         ACTION PrintReport() ;
         WHEN .NOT. Empty( cDefIni )

   MRU oMru FILENAME cGeneralIni ;
            SECTION  "MRU" ;
            ACTION   OpenFile( cMruItem ) ;
            SIZE     Val( GetPvProfString( "General", "MruList"  , "4", cGeneralIni ) )
   SEPARATOR
   MENUITEM GL("&Exit") RESOURCE "B_EXIT_16" ;
      ACTION oMainWnd:End()
   ENDMENU

   MENUITEM GL("&Edit")
   MENU
   MENUITEM GL("&Undo") + chr(9) + GL("Ctrl+Z") RESOURCE "B_UNDO_16" ;
      ACTION Undo() ;
      ACCELERATOR ACC_CONTROL, ASC( GL("Z") ) ;
      WHEN .NOT. Empty( cDefIni ) .and. nUndoCount > 0
   MENUITEM GL("&Redo") + chr(9) + GL("Ctrl+Y") RESOURCE "B_REDO_16" ;
      ACTION Redo() ;
      ACCELERATOR ACC_CONTROL, ASC( GL("Y") ) ;
      WHEN .NOT. Empty( cDefIni ) .and. nRedoCount > 0
   SEPARATOR

   MENUITEM GL("Cu&t") + chr(9) + GL("Ctrl+X") ;
      ACTION ( ItemCopy( .T. ), nAktItem := 0 ) ;
      ACCELERATOR ACC_CONTROL, ASC( GL("X") ) ;
      WHEN .NOT. Empty( cDefIni )
   MENUITEM GL("&Copy") + chr(9) + GL("Ctrl+C") ;
      ACTION ItemCopy( .F. ) ;
      ACCELERATOR ACC_CONTROL, ASC( GL("C") ) ;
      WHEN .NOT. Empty( cDefIni )
   MENUITEM GL("&Paste") + chr(9) + GL("Ctrl+V") ;
      ACTION ItemPaste()  ;
      ACCELERATOR ACC_CONTROL, ASC( GL("V") ) ;
      WHEN .NOT. Empty( cDefIni ) .and. .NOT. Empty( cItemCopy )
   SEPARATOR

   if Val( GetPvProfString( "General", "InsertAreas", "1", cDefIni ) ) <> 1
      if Val( GetPvProfString( "General", "EditAreaProperties", "1", cDefIni ) ) = 1
         MENUITEM GL("&Area Properties") + chr(9) + GL("Ctrl+A") RESOURCE "B_AREA" ;
            ACTION AreaProperties( nAktArea ) ;
            ACCELERATOR ACC_CONTROL, ASC( GL("A") ) ;
            WHEN .NOT. Empty( cDefIni )
         SEPARATOR
      endif
   endif

   MENUITEM GL("Select all Items") ;
      ACTION SelectAllItems() WHEN .NOT. Empty( cDefIni )
   MENUITEM GL("Select all Items in current Area") ;
      ACTION SelectAllItems( .T. ) WHEN .NOT. Empty( cDefIni )
   MENUITEM GL("Invert Selection") ;
      ACTION InvertSelection() WHEN .NOT. Empty( cDefIni )
   MENUITEM GL("Invert Selection in current Area") ;
      ACTION InvertSelection( .T. ) WHEN .NOT. Empty( cDefIni )
   SEPARATOR
   MENUITEM GL("Delete in current Area") WHEN .NOT. Empty( cDefIni )
      MENU
      MENUITEM GL("&Text")    ACTION DeleteAllItems( 1 )
      MENUITEM GL("I&mage")   ACTION DeleteAllItems( 2 )
      MENUITEM GL("&Graphic") ACTION DeleteAllItems( 3 )
      MENUITEM GL("&Barcode") ACTION DeleteAllItems( 4 )
      ENDMENU
   ENDMENU

   if Val( GetPvProfString( "General", "InsertMode", "1", cDefIni ) ) = 1

      MENUITEM GL("&Items")
      MENU
      MENUITEM GL("Insert &Text") + chr(9) + GL("Ctrl+T") RESOURCE "B_TEXT" ;
         ACCELERATOR ACC_CONTROL, ASC( GL("T") ) ;
         ACTION NewItem( "TEXT", nAktArea ) ;
         WHEN .NOT. Empty( cDefIni )
      MENUITEM GL("Insert &Image") + chr(9) + GL("Ctrl+M") RESOURCE "B_IMAGE" ;
         ACCELERATOR ACC_CONTROL, ASC( GL("M") ) ;
         ACTION NewItem( "IMAGE", nAktArea ) ;
         WHEN .NOT. Empty( cDefIni )
      MENUITEM GL("Insert &Graphic") + chr(9) + GL("Ctrl+G") RESOURCE "B_GRAPHIC" ;
         ACCELERATOR ACC_CONTROL, ASC( GL("G") ) ;
         ACTION NewItem( "GRAPHIC", nAktArea ) ;
         WHEN .NOT. Empty( cDefIni )
      MENUITEM GL("Insert &Barcode") + chr(9) + GL("Ctrl+B") RESOURCE "B_BARCODE" ;
         ACCELERATOR ACC_CONTROL, ASC( ("B") ) ;
         ACTION NewItem( "BARCODE", nAktArea ) ;
         WHEN .NOT. Empty( cDefIni )
      SEPARATOR
      MENUITEM GL("&Item Properties") + chr(9) + GL("Ctrl+I") RESOURCE "B_EDIT" ;
         ACTION IIF( LEN( aSelection ) <> 0, MultiItemProperties(), ItemProperties( nAktItem, nAktArea ) ) ;
         ACCELERATOR ACC_CONTROL, ASC( GL("I") ) ;
         WHEN .NOT. Empty( cDefIni )
      ENDMENU

      if Val( GetPvProfString( "General", "InsertAreas", "1", cDefIni ) ) = 1
      MENUITEM GL("&Areas")
      MENU
      MENUITEM GL("Insert Area &before") ACTION InsertArea( .T., STRTRAN( GL("Insert Area &before"), "&" ) )
      MENUITEM GL("Insert Area &after" ) ACTION InsertArea( .F., STRTRAN( GL("Insert Area &after" ), "&" ) )
      SEPARATOR
      MENUITEM GL("&Delete current Area") ACTION DeleteArea()
      SEPARATOR
      if Val( GetPvProfString( "General", "EditAreaProperties", "1", cDefIni ) ) = 1
         MENUITEM GL("&Area Properties") + chr(9) + GL("Ctrl+A") RESOURCE "B_AREA" ;
            ACTION AreaProperties( nAktArea ) ;
            ACCELERATOR ACC_CONTROL, ASC( GL("A") ) ;
            WHEN .NOT. Empty( cDefIni )
      endif
      ENDMENU
      endif

   endif

   MENUITEM GL("&Extras")
   MENU
   MENUITEM GL("Area and Item &List") + chr(9) + GL("Ctrl+L") RESOURCE "B_ITEMLIST" ;
      ACTION Itemlist() ;
      ACCELERATOR ACC_CONTROL, ASC( GL("L") ) ;
      WHEN .NOT. Empty( cDefIni )
   if Val( GetPvProfString( "General", "EditProperties", "1", cDefIni ) ) = 1
      MENUITEM GL("&Fonts and Colors") + chr(9) + GL("Ctrl+F") RESOURCE "B_FONTCOLOR" ;
         ACTION FontsAndColors() ;
         ACCELERATOR ACC_CONTROL, ASC( GL("F") ) ;
         WHEN .NOT. Empty( cDefIni )
   endif
   SEPARATOR
   if Val( GetPvProfString( "General", "Expressions", "0", cDefIni ) ) > 0
      MENUITEM GL("&Expressions") ;
         ACTION Expressions() ;
         WHEN .NOT. Empty( cDefIni )
   endif
   if Val( GetPvProfString( "General", "EditDatabases", "1", cDefIni ) ) > 0
      MENUITEM GL("&Databases") ;
         ACTION Databases() ;
         WHEN .NOT. Empty( cDefIni )
   endif
   MENUITEM GL("&Report Settings") ;
      ACTION ReportSettings() ;
      WHEN .NOT. Empty( cDefIni )
   SEPARATOR
   if Val( GetPvProfString( "General", "EditLanguage", "0", cDefIni ) ) = 1
      MENUITEM GL("Edit &Language") ;
         ACTION EditLanguage()
   endif
   MENUITEM GL("&Options") ;
      ACTION Options() ;
      WHEN .NOT. Empty( cDefIni )
   ENDMENU

   if Val( GetPvProfString( "General", "Help", "1", cGeneralIni ) ) = 1
      MENUITEM GL("&Help")
      MENU
      MENUITEM GL("&Help Topics") + chr(9) + GL("F1") ;
         ACTION WinHelp( "VRD.HLP" ) ;
         ACCELERATOR ACC_NORMAL, VK_F1
      SEPARATOR
   else
      MENUITEM GL("&Info")
      MENU
   endif

   if lPersonal = .T. .OR. lStandard = .T.
      MENUITEM GL("&Registration") ;
         ACTION VRDMsgPersonal()
   endif
   MENUITEM GL("&About") ;
      ACTION VRDAbout()
   ENDMENU

   ENDMENU

return( oMenu )

//----------------------------------------------------------------------------//

function PopupMenu( nArea, oItem, nRow, nCol, lItem )

   local oMenu

   DEFAULT lItem := .F.

   MENU oMenu POPUP

   if LEN( aSelection ) <> 0 .OR. nAktItem <> 0
   MENUITEM GL("&Item Properties") + chr(9) + GL("Ctrl+I") RESOURCE "B_EDIT" ;
      ACTION IIF( LEN( aSelection ) <> 0, MultiItemProperties(), ItemProperties( nAktItem, nAktArea ) )
   endif
   if LEN( aSelection ) <> 0
   MENUITEM GL("&Delete selected Items") + CHR(9) + GL("Del") ;
      ACTION DelselectItems()
   SEPARATOR
   endif
   MENUITEM GL("Area and Item &List") + CHR(9) + GL("Ctrl+L") RESOURCE "B_ITEMLIST" ;
      ACTION Itemlist()
   MENUITEM GL("&Fonts and Colors") + CHR(9) + GL("Ctrl+F")   RESOURCE "B_FONTCOLOR" ;
      ACTION FontsAndColors()
   SEPARATOR
   MENUITEM GL("&Area Properties") + CHR(9) + GL("Ctrl+A")    RESOURCE "B_AREA" ;
      ACTION ( aWnd[ nArea ]:SetFocus(), AreaProperties( nAktArea ) )
   SEPARATOR
   MENUITEM GL("&Report Settings") ACTION ReportSettings()
   MENUITEM GL("&Options")         ACTION Options()
   if Val( GetPvProfString( "General", "Help", "1", cGeneralIni ) ) = 1
      SEPARATOR
      MENUITEM GL("&Help Topics") + CHR(9) + GL("F1") ACTION WinHelp( "VRD.HLP" )
   endif
   if nDeveloper = 1
      SEPARATOR
      MENUITEM GL("&Generate Source Code") ACTION GenerateSource( nArea )
   endif

   SEPARATOR
   MENUITEM GL("&Paste") + chr(9) + GL("Ctrl+V") ;
      ACTION ItemPaste() ;
      WHEN .NOT. Empty( cItemCopy )

   ENDMENU

   ACTIVATE POPUP oMenu OF IIF( lItem = .T., oItem, aWnd[ nArea ] ) AT nRow, nCol

return .T.

//----------------------------------------------------------------------------//

function GenerateSource( nArea )

   local i, oDlg, oGet1, cDir, cAreaDef, cAreaTitle, cItemDef, oRad1
   local cFile     := SPACE(120)
   local lGenerate := .F.
   local nCopyTo   := 1
   local nStyle    := 1
   local cSource   := CRLF
   local cIDs      := ""
   local cNames    := ""

   DEFINE DIALOG oDlg NAME "GENERATESOURCE" TITLE GL("Generate Source Code")

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ;
      ACTION IIF( nCopyTo = 2 .and. CheckFileName( cFile ) = .F.,, ;
                  EVAL( {|| lGenerate := .T., oDlg:End() } ) )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE RADIO oRad1 VAR nCopyTo ID 301, 302 OF oDlg
   REDEFINE RADIO nStyle  ID 401, 402 OF oDlg

   REDEFINE GET oGet1 VAR cFile ID 201 OF oDlg UPDATE WHEN nCopyTo = 2

   REDEFINE SAY PROMPT GL("Use method") + ":" ID 171 OF oDlg

   REDEFINE BTNBMP ID 151 OF oDlg RESOURCE "OPEN" TRANSPARENT UPDATE ;
      TOOLTIP GL("Directory") ;
      ACTION ( cDir := cGetDir32( GL("Select a directory") ), ;
               IIF( AT( "\", cFile ) = 0 .and. .NOT. Empty( cDir ), ;
                  cFile := cDir + "\" + cFile, ), ;
               oGet1:Refresh() )

   ACTIVATE DIALOG oDlg CENTER ;
      ON INIT( oRad1:aItems[ 1 ]:SetText( GL("Copy to clipboard") ), ;
               oRad1:aItems[2]:SetText( GL("Copy to file") + ":" ) )

   if lGenerate = .T.

      cAreaDef := GetPvProfString( "Areas", AllTrim(STR(nArea,5)) , "", cDefIni )
      cAreaDef := VRD_LF2SF( AllTrim( cAreaDef ) )

      cAreaTitle := AllTrim( GetPvProfString( "General", "Title" , "", aAreaIni[ nArea ] ) )

      if .NOT. Empty( cAreaTitle )
         cSource += SPACE(3) + "//--- Area: " + cAreaTitle + " ---" + CRLF
      endif

      for i := 1 to 1000

         cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(i,5)) , "", aAreaIni[ nArea ] ) )

         if .NOT. Empty( cItemDef )
            if nStyle = 1
               cSource += SPACE(3) + "oVRD:PrintItem( " + ;
                          AllTrim(STR( nArea,3 )) + ;
                          ", " + AllTrim(GetField( cItemDef, 3 )) + ;
                          ', "' + AllTrim(GetField( cItemDef, 2 )) + ;
                          '" )' + CRLF
            else
               cIDs   += IIF( Empty( cIDs ), "", ", ") + AllTrim(GetField( cItemDef, 3 ))
               cNames += IIF( Empty( cNames ), '"', ', "') + AllTrim(GetField( cItemDef, 2 )) + '"'
            endif
         endif

      next

      if nStyle = 2
         cSource += SPACE(3) + "oVRD:PrintItemList( " + AllTrim(STR( nArea,3 )) + ;
                    ", { " + cIDs + " }" + ", ;" + CRLF + ;
                    SPACE(6) + "{ " + cNames + " } )" + CRLF
      endif

      cSource += CRLF + SPACE(3) + ;
                 "oVRD:PrintRest( " + AllTrim(STR( nArea, 3 )) + " )" + CRLF

      if nCopyTo = 1

         OpenClipboard( oMainWnd:hWnd )
         SetClipboardData( 1, cSource )
         CloseClipboard()

      else

         CreateNewFile( cFile )

         MEMOWRIT( VRD_LF2SF( cFile ), cSource )

      endif

   endif

return (nil)

//----------------------------------------------------------------------------//

function ClientWindows()

   local i, nWnd, cItemDef, cTitle, nWidth, nHeight, nDemoWidth
   local lFirstWnd     := .F.
   local nTop          := 0
   local nWindowNr     := 0
   local aIniEntries   := GetIniSection( "Areas", cDefIni )
   local cAreaFilesDir := CheckPath( GetPvProfString( "General", "AreaFilesDir", "", cDefIni ) )
   local lReticule

   //Sichern
   aVRDSave := ARRAY( 102, 2 )
   aVRDSave[101, 1 ] := cDefIni
   aVRDSave[101, 2 ] := MEMOREAD( cDefIni )
   aVRDSave[102, 1 ] := cGeneralIni
   aVRDSave[102, 2 ] := MEMOREAD( cGeneralIni )

   for i := 1 to LEN( aIniEntries )

      nWnd := EntryNr( aIniEntries[ i ] )
      cItemDef := GetIniEntry( aIniEntries,, "",, i )

      if nWnd <> 0 .and. .NOT. Empty( cItemDef )

         if lFirstWnd = .F.
            nAktArea := nWnd
            lFirstWnd := .T.
         endif

         if Empty( cAreaFilesDir )
            cAreaFilesDir := cDefaultPath
         endif
         if Empty( cAreaFilesDir )
            cAreaFilesDir := cDefIniPath
         endif

         cItemDef := VRD_LF2SF( AllTrim( cAreaFilesDir + cItemDef ) )

         aVRDSave[nWnd, 1 ] := cItemDef
         aVRDSave[nWnd, 2 ] := MEMOREAD( cItemDef )

         nWindowNr += 1
         aAreaIni[nWnd] := IIF( AT( "\", cItemDef ) = 0, ".\", "" ) + cItemDef

         cTitle  := AllTrim( GetPvProfString( "General", "Title" , "", aAreaIni[nWnd] ) )

         oGenVar:aAreaSizes[nWnd] := ;
            { Val( GetPvProfString( "General", "Width", "600", aAreaIni[nWnd] ) ), ;
              Val( GetPvProfString( "General", "Height", "300", aAreaIni[nWnd] ) ) }

         nWidth  := ER_GetPixel( oGenVar:aAreaSizes[nWnd, 1 ] )
         nHeight := ER_GetPixel( oGenVar:aAreaSizes[nWnd, 2 ] )

         nDemoWidth := nWidth
         if oGenVar:lFixedAreaWidth = .T.
            nWidth := 1200
         else
            nWidth += nRuler + nAreaZugabe2
         endif

         /*  
         DEFINE WINDOW aWnd[nWnd] MDICHILD OF oMainWnd TITLE cTitle ;
            BRUSH oGenVar:oAreaBrush ;
            FROM nTop, 0 to nTop + nHeight + nAreaZugabe, nWidth PIXEL ;
            STYLE nOr( WS_BORDER )
         */   
            
         aWnd[ nWnd ] = ER_MdiChild():New( nTop, 0, nTop + nHeight + nAreaZugabe,;
                            nWidth, cTitle, nOr( WS_BORDER ),, oMainWnd,, .T.,,,,;
                            oGenVar:oAreaBrush, .T. )
         
         aWnd[ nWnd ]:nArea = nWnd   
            
         aWndTitle[ nWnd ] = cTitle

         /*
         if ( lDemo .OR. lBeta ) .and. nWindowNr = 1
            //Demo-Version
            @ 44, nDemoWidth - 200 ;
               SAY "Unregistered " + IIF( lBeta, "Beta", "Demo" ) + " Version" ;
               OF aWnd[nWnd] PIXEL COLOR RGB( 192, 192, 192 ), RGB( 255, 255, 255 ) ;
               SIZE 200, 16 RIGHT
         endif
         */

         lReticule = oGenVar:lShowReticule
         oGenVar:lShowReticule = .F.

         FillWindow( nWnd, aAreaIni[nWnd] )

         ACTIVATE WINDOW aWnd[nWnd] VALID .NOT. GETKEYSTATE( VK_ESCAPE )

         oGenVar:lShowReticule = lReticule          

         nTop += nHeight + nAreaZugabe

      endif

   next

   nTotalHeight := nTop
   nTotalWidth  := nWidth

return .T.

//----------------------------------------------------------------------------//

function FillWindow( nArea, cAreaIni )

   local i, cRuler1, cRuler2, aWerte, nEntry, nTmpCol
   local nFirstTop, nFirstLeft, nFirstWidth, nFirstHeight, nFirstItem
   local aFirst      := { .F., 0, 0, 0, 0, 0 }
   local nElemente   := 0
   local aIniEntries := GetIniSection( "Items", cAreaIni )

   //Ruler anzeigen
   if nMeasure = 1 ; cRuler1 := "RULER1_MM" ; cRuler2 := "RULER2_MM" ; endif
   if nMeasure = 2 ; cRuler1 := "RULER1_IN" ; cRuler2 := "RULER2_IN" ; endif
   if nMeasure = 3 ; cRuler1 := "RULER1_PI" ; cRuler2 := "RULER2_PI" ; endif

   @ 0, 0 SAY " " SIZE 1200, nRulerTop-nRuler PIXEL ;
      COLORS 0, oGenVar:nBClrAreaTitle OF aWnd[ nArea ]

   @ 2,  3 BTNBMP RESOURCE "AREAMINMAX" SIZE 12,12 ACTION AreaHide( nAktArea )
   @ 2, 17 BTNBMP RESOURCE "AREAPROP"   SIZE 12,12 ACTION AreaProperties( nAktArea )

   @ 2, 29 SAY oGenVar:aAreaTitle[ nArea ] ;
      PROMPT " " + AllTrim( GetPvProfString( "General", "Title" , "", cAreaIni ) ) ;
      SIZE 400, nRulerTop-nRuler-2 PIXEL FONT oGenVar:aAppFonts[ 1 ] ;
      COLORS oGenVar:nF1ClrAreaTitle, oGenVar:nBClrAreaTitle OF aWnd[ nArea ]

   @ nRulerTop - nRuler, 20 BITMAP oRulerBmp2 RESOURCE cRuler1 ;
      OF aWnd[ nArea ] PIXEL NOBORDER
   
   @ nRulerTop - nRuler, 0 BITMAP oRulerBmp2 RESOURCE cRuler2 ;
      OF aWnd[ nArea ] PIXEL NOBORDER

   // @ nRulerTop-nRuler, 20 SAY aRuler[ nArea, 1 ] PROMPT "" SIZE  1, 20 PIXEL ;
   //    COLORS oGenVar:nClrReticule, oGenVar:nClrReticule OF aWnd[ nArea ]
   
   // @ 20, 0 SAY aRuler[ nArea, 2 ] PROMPT "" SIZE 20,  1 PIXEL ;
   //    COLORS oGenVar:nClrReticule, oGenVar:nClrReticule OF aWnd[ nArea ]
   
   aWnd[ nArea ]:bPainted  = {| hDC, cPS | ZeichneHintergrund( nArea ) }

   aWnd[ nArea ]:bGotFocus = {|| SetTitleColor( .F. ), ;
                               nAktArea := nArea,; /* oCbxArea:Set( aWndTitle[ nArea ] ), ; */
                               SetTitleColor( .T. ) }

   aWnd[ nArea ]:bMMoved = {|nRow,nCol,nFlags| ;
                           SetReticule( nRow, nCol, nArea ), ;
                           MsgBarInfos( nRow, nCol ), ;
                           MoveSelection( nRow, nCol, aWnd[ nArea ] ) }

   aWnd[ nArea ]:bRClicked = {|nRow,nCol,nFlags| PopupMenu( nArea,, nRow, nCol ) }
   aWnd[ nArea ]:bLClicked = {|nRow,nCol,nFlags| DeactivateItem(), ;
                              IIF( GetKeyState( VK_SHIFT ),, UnSelectAll() ), ;
                              StartSelection( nRow, nCol, aWnd[ nArea ] ) }
   aWnd[ nArea ]:bLButtonUp = {|nRow,nCol,nFlags| StopSelection( nRow, nCol, aWnd[ nArea ] ) }

   aWnd[ nArea ]:bKeyDown   = {|nKey| WndKeyDownAction( nKey, nArea, cAreaIni ) }

   for i := 1 to LEN( aIniEntries )
      nEntry := EntryNr( aIniEntries[ i ] )
      if nEntry <> 0
         ShowItem( nEntry, nArea, cAreaIni, @aFirst, @nElemente, aIniEntries, i )
      endif
   next

   //Durch diese Anweisung werden alle Controls resizable
   if nElemente <> 0
      lFillWindow := .T.
      aItems[ nArea,aFirst[6]]:CheckDots()
      aItems[ nArea,aFirst[6]]:Move( aFirst[2], aFirst[3], aFirst[4], aFirst[5], .T. )
      lFillWindow := .F.
   endif

   Memory(-1)
   SysRefresh()

return .T.

//----------------------------------------------------------------------------//

function SetReticule( nRow, nCol, nArea )

   local nRowPos := nRow
   local nColPos := nCol
   local lShow   := ( oGenVar:lShowReticule == .T. .and. ;
                      oGenVar:lSelectItems == .F. )

   if nRow <= nRulerTop
      nRowPos := nRulerTop
   elseif nRow >= ER_GetPixel( oGenVar:aAreaSizes[ nArea, 2 ] ) + nRulerTop
      nRowPos := ER_GetPixel( oGenVar:aAreaSizes[ nArea, 2 ] ) + nRulerTop
   endif

   if nCol <= nRuler
      nColPos := nRuler
   elseif nCol >= ER_GetPixel( oGenVar:aAreaSizes[ nArea, 1 ] ) + nRuler
      nColPos := ER_GetPixel( oGenVar:aAreaSizes[ nArea, 1 ] ) + nRuler
   endif

   if lShow 
      DrawRulerHorzLine( aWnd[ nArea ], nRowPos )

      AEval( aWnd, { | oWnd | If( oWnd != nil, DrawRulerVertLine( oWnd, nColPos ),) } )
   endif   

return .T.

//----------------------------------------------------------------------------//

function DrawRulerHorzLine( oWnd, nRowPos )

   local hDC := oWnd:GetDC()

   if ! Empty( oWnd:aRulerLeftPos )   // Horizontal line position
      InvertRect( hDC, oWnd:aRulerLeftPos )
   endif   
   
   oWnd:aRulerLeftPos = { nRowPos, 0, nRowPos + 1, 20 }
   InvertRect( hDC, oWnd:aRulerLeftPos )

   oWnd:ReleaseDC()

return nil

//----------------------------------------------------------------------------//

function DrawRulerVertLine( oWnd, nColPos )

   local hDC := oWnd:GetDC()

   if ! Empty( oWnd:aRulerTopPos )  // vertical line position
      InvertRect( hDC, oWnd:aRulerTopPos )
   endif   
   
   oWnd:aRulerTopPos = { 17, nColPos, 37, nColPos + 1 }
   InvertRect( hDC, oWnd:aRulerTopPos )

   oWnd:ReleaseDC()

return nil

//----------------------------------------------------------------------------//

function SetTitleColor( lOff )

   if lOff = .T.
      oGenVar:aAreaTitle[nAktArea]:SetColor( oGenVar:nF2ClrAreaTitle, oGenVar:nBClrAreaTitle )
   else
      oGenVar:aAreaTitle[nAktArea]:SetColor( oGenVar:nF1ClrAreaTitle, oGenVar:nBClrAreaTitle )
   endif

   oGenVar:aAreaTitle[ nAktArea ]:Refresh()

return .T.

//----------------------------------------------------------------------------//

function ZeichneHintergrund( nArea )

   local nWidth  := ER_GetPixel( oGenVar:aAreaSizes[ nArea, 1 ] )
   local nHeight := ER_GetPixel( oGenVar:aAreaSizes[ nArea, 2 ] )

   SetGridSize( ER_GetPixel( oGenVar:nGridWidth ), ER_GetPixel( oGenVar:nGridHeight ) )

   //Hintergrund
   Rectangle( aWnd[ nArea ]:hDC, ;
              nRulerTop, nRuler, nRulerTop + nHeight + 1, nRuler + nWidth + 1 )

   //Grid zeichnen
   if oGenVar:lShowGrid = .T.
      ShowGrid( aWnd[ nArea ]:hDC, aWnd[ nArea ]:cPS, ;
                ER_GetPixel( oGenVar:nGridWidth ), ER_GetPixel( oGenVar:nGridHeight ), ;
                nWidth, nHeight, nRulerTop, nRuler )
   endif

return .T.

//----------------------------------------------------------------------------//

function WndKeyDownAction( nKey, nArea, cAreaIni )

   local i, aWerte, nTop, nLeft, nHeight, nWidth
   local lMove    := .T.
   local nY       := 0
   local nX       := 0
   local nRight   := 0
   local nBottom  := 0

   if LEN( aSelection ) = 0
      return(.F.)
   endif

   //Delete item
   if nKey == VK_DELETE
      DelselectItems()
   endif

   //return to edit properties
   if nKey == VK_RETURN .and. LEN( aSelection ) <> 0
      MultiItemProperties()
   endif

   //Move and resize items
   if GetKeyState( VK_SHIFT )
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
   else
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
   endif

   if lMove = .T.

      UnSelectAll( .F. )

      for i := 1 to LEN( aSelection )

         if aItems[ aSelection[i, 1 ], aSelection[i, 2 ] ] <> nil

            aWerte   := GetCoors( aItems[ aSelection[i, 1 ], aSelection[i, 2 ] ]:hWnd )
            nTop     := aWerte[ 1 ]
            nLeft    := aWerte[2]
            nHeight  := aWerte[3] - aWerte[ 1 ]
            nWidth   := aWerte[4] - aWerte[2]

            aItems[ aSelection[i, 1 ], aSelection[i, 2 ] ]:Move( nTop + nY, nLeft + nX, nWidth + nRight, nHeight + nBottom, .T. )

         endif

      next

      UnSelectAll( .F. )

   endif

return .T.

//----------------------------------------------------------------------------//

function DelselectItems()

   local i

   if MsgNoYes( GL("Delete the selected items?"), GL("Select an option") ) = .T.

      for i := 1 to LEN( aSelection )

         if aItems[ aSelection[i, 1 ], aSelection[i, 2 ] ] <> nil

            MarkItem( aItems[ aSelection[i, 1 ], aSelection[i, 2 ] ]:hWnd )
            DelItemWithKey( aSelection[i, 2 ], aSelection[i, 1 ] )

         endif

      next

   endif

return .T.

//----------------------------------------------------------------------------//

function MsgBarInfos( nRow, nCol )

   DEFAULT nRow := 0
   DEFAULT nCol := 0

   oMsgInfo:SetText( GL("Row:")    + " " + AllTrim(STR( GetCmInch( nRow - nRulerTop ), 5, IIF( nMeasure = 2, 2, 0 ) ) ) + "    " + ;
                     GL("Column:") + " " + AllTrim(STR( GetCmInch( nCol - nRuler ), 5, IIF( nMeasure = 2, 2, 0 ) ) ) )

return .T.

//----------------------------------------------------------------------------//

function CheckStyle( nPenSize, cStyle )

   if nPenSize > 1
      cStyle := "1"
   endif

return .T.

//----------------------------------------------------------------------------//

function ShowFontChoice( nCurrentFont )

   local i, oDlg, oLbx, oSay1, oGet1
   local nFont      := 0
   local aGetFonts  := GetFonts()
   local aShowFonts := GetFontText( aGetFonts, .F. )
   local cFont      := aShowFonts[IIF( nCurrentFont <= 0 .OR. nCurrentFont > LEN( aShowFonts), ;
                                       1, nCurrentFont )]
   local lSave      := .F.
   local cFontText  := ""

   for i := 33 to 254
      cFontText += CHR( i )
   next

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
      ID 301 OF oDlg UPDATE FONT aFonts[ 1 ]

   REDEFINE GET oGet1 VAR cFontText ID 311 OF oDlg UPDATE FONT aFonts[ 1 ] MEMO

   ACTIVATE DIALOG oDlg CENTERED ON INIT PreviewRefresh( oSay1, oLbx, oGet1 )

   if lSave = .T.
      nFont := Val(SUBSTR( AllTrim(cFont), 1, 2 ))
   endif

return ( IIF( nFont = 0, nCurrentFont, nFont ) )

//----------------------------------------------------------------------------//

function GetCurrentFont( nCurrentFont, aGetFonts, nTyp )

   local cCurFont := ""

   DEFAULT nTyp := 0

   if nTyp = 0
      cCurFont := GL("Current:") + " " + AllTrim(STR( nCurrentFont, 3)) + ". "
   endif

   if aGetFonts[nCurrentFont, 1 ] <> nil
      cCurFont += aGetFonts[nCurrentFont, 1 ] + ;
         " " + AllTrim(STR( aGetFonts[nCurrentFont,3], 5 )) + ;
         IIF( aGetFonts[nCurrentFont,4], " " + GL("bold"), "") + ;
         IIF( aGetFonts[nCurrentFont,5], " " + GL("italic"), "") + ;
         IIF( aGetFonts[nCurrentFont,6], " " + GL("underline"), "") + ;
         IIF( aGetFonts[nCurrentFont,7], " " + GL("strickout"), "") + ;
         IIF( aGetFonts[nCurrentFont,8] <> 0, " " + GL("Rotation:") + " " + AllTrim(STR( aGetFonts[nCurrentFont,8], 6)), "")
   else
      cCurFont := ""
   endif

return cCurFont

//----------------------------------------------------------------------------//

function ShowColorChoice( nCurrentClr )

   local oIni, oDlg, nDefClr
   local aColors := GetAllColors()
   local aSay    := ARRAY(30)
   local aBtn    := ARRAY(30)
   local nColor  := 0

   DEFINE DIALOG oDlg NAME "GETCOLOR" TITLE GL("Select Color")

   nDefClr := oDlg:nClrPane

   REDEFINE BUTTON PROMPT GL("&Cancel") ID 101 OF oDlg ACTION oDlg:End()

   REDEFINE SAY PROMPT GL("Current:") ID 170 OF oDlg

   REDEFINE SAY PROMPT AllTrim(STR( nCurrentClr )) + "." ID 401 OF oDlg
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
   aColors := nil
   aSay    := nil
   aBtn    := nil
   MEMORY(-1)
   SysRefresh()

return nColor

//----------------------------------------------------------------------------//

function DefineFonts()

   local i, cFontDef
   local aGetFonts := GetFonts()

   aFonts := nil
   aFonts := Array( 50 )

   for i := 1 to 20
      aFonts[ i ] := TFont():New( aGetFonts[i, 1], ;   // cFaceName
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
   next

return .T.

//----------------------------------------------------------------------------//

function GetColor( nNr )

return Val( GetPvProfString( "Colors", AllTrim(STR( nNr, 5 )) , "", cDefIni ) )

//----------------------------------------------------------------------------//

function GetAllColors()

   local i
   local aColors := {}

   for i := 1 to 30
      AADD( aColors, PADR( GetPvProfString( "Colors", AllTrim(STR( i, 5 )) , "", cDefIni ), 15 ) )
   next

return ( aColors )

//----------------------------------------------------------------------------//

function FontsAndColors()

   local i, oDlg, oFld, oLbx, oSay1, oGet1, nDefClr, oIni
   local aColorGet[30], aColorSay[30]
   local aGetFonts  := GetFonts()
   local aShowFonts := GetFontText( aGetFonts )
   local cFont      := aGetFonts [1, 1 ]
   local aColors    := GetAllColors()
   local cFontText  := ""

   for i := 33 to 254
      cFontText += CHR( i )
   next

   //System auffrischen
   SysRefresh()
   MEMORY(-1)

   DEFINE DIALOG oDlg NAME "FontsAndColors" TITLE GL( "Fonts and Colors" )

   REDEFINE BUTTON PROMPT GL( "&OK" ) ID 101 OF oDlg ACTION oDlg:End()

   nDefClr := oDlg:nClrPane

   REDEFINE FOLDER oFld ID 110 OF oDlg ;
      PROMPT " " + GL("Fonts")     + " ", ;
             " " + GL("Colors")    + " " ;
      DIALOGS "GENERALSET_1", "GENERALSET_2"

   i := 1
   REDEFINE LISTBOX oLbx VAR cFont ITEMS aShowFonts ID 201 OF oFld:aDialogs[ i ] ;
      ON CHANGE PreviewRefresh( oSay1, oLbx, oGet1 ) ;
      ON DBLCLICK ( aShowFonts := SelectFont( oSay1, oLbx, oGet1 ) )

   oLbx:nDlgCode = DLGC_WANTALLKEYS
   oLbx:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, ;
                                           aShowFonts := SelectFont( oSay1, oLbx ), ) }

   REDEFINE SAY PROMPT GL("Font")    ID 170 OF oFld:aDialogs[ i ]
   REDEFINE SAY PROMPT GL("Preview") ID 171 OF oFld:aDialogs[ i ]
   REDEFINE SAY PROMPT GL("Doubleclick to edit the font properties") ID 172 OF oFld:aDialogs[ i ]

   REDEFINE SAY oSay1 PROMPT CRLF + CRLF + GL("Test 123") ;
      ID 301 OF oFld:aDialogs[ i ] UPDATE FONT aFonts[ 1 ]

   REDEFINE GET oGet1 VAR cFontText ID 311 OF oFld:aDialogs[ i ] UPDATE FONT aFonts[ 1 ] MEMO

   i := 2
   REDEFINE SAY PROMPT GL("Nr.")   ID 170 OF oFld:aDialogs[ i ]
   REDEFINE SAY PROMPT GL("Color") ID 171 OF oFld:aDialogs[ i ]
   REDEFINE SAY PROMPT GL("Nr.")   ID 172 OF oFld:aDialogs[ i ]
   REDEFINE SAY PROMPT GL("Color") ID 173 OF oFld:aDialogs[ i ]
   REDEFINE SAY PROMPT GL("Nr.")   ID 174 OF oFld:aDialogs[ i ]
   REDEFINE SAY PROMPT GL("Color") ID 175 OF oFld:aDialogs[ i ]

   REDEFINE BTNBMP aColorSay[1 ]   ID 401 OF oFld:aDialogs[ i ] NOBORDER
   REDEFINE BTNBMP aColorSay[2 ]   ID 402 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[3 ]   ID 403 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[4 ]   ID 404 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[5 ]   ID 405 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[6 ]   ID 406 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[7 ]   ID 407 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[8 ]   ID 408 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[9 ]   ID 409 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[10]   ID 410 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[11]   ID 411 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[12]   ID 412 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[13]   ID 413 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[14]   ID 414 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[15]   ID 415 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[16]   ID 416 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[17]   ID 417 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[18]   ID 418 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[19]   ID 419 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[20]   ID 420 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[21]   ID 421 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[22]   ID 422 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[23]   ID 423 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[24]   ID 424 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[25]   ID 425 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[26]   ID 426 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[27]   ID 427 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[28]   ID 428 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[29]   ID 429 OF oFld:aDialogs[ i ] NOBORDER 
   REDEFINE BTNBMP aColorSay[30]   ID 430 OF oFld:aDialogs[ i ] NOBORDER 

   AEval( aColorSay, { | o, n | o:SetColor( 0,;
      If( Empty( aColors[ n ] ), CLR_WHITE, Val( aColors[ n ] ) ) ) } )

   REDEFINE GET aColorGet[1 ] VAR aColors[1 ] ID 201 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[1 ], aColors[1 ], nDefClr )
   REDEFINE GET aColorGet[2 ] VAR aColors[2 ] ID 202 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[2 ], aColors[2 ], nDefClr )
   REDEFINE GET aColorGet[3 ] VAR aColors[3 ] ID 203 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[3 ], aColors[3 ], nDefClr )
   REDEFINE GET aColorGet[4 ] VAR aColors[4 ] ID 204 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[4 ], aColors[4 ], nDefClr )
   REDEFINE GET aColorGet[5 ] VAR aColors[5 ] ID 205 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[5 ], aColors[5 ], nDefClr )
   REDEFINE GET aColorGet[6 ] VAR aColors[6 ] ID 206 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[6 ], aColors[6 ], nDefClr )
   REDEFINE GET aColorGet[7 ] VAR aColors[7 ] ID 207 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[7 ], aColors[7 ], nDefClr )
   REDEFINE GET aColorGet[8 ] VAR aColors[8 ] ID 208 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[8 ], aColors[8 ], nDefClr )
   REDEFINE GET aColorGet[9 ] VAR aColors[9 ] ID 209 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[9 ], aColors[9 ], nDefClr )
   REDEFINE GET aColorGet[10] VAR aColors[10] ID 210 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[10], aColors[10], nDefClr )
   REDEFINE GET aColorGet[11] VAR aColors[11] ID 211 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[11], aColors[11], nDefClr )
   REDEFINE GET aColorGet[12] VAR aColors[12] ID 212 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[12], aColors[12], nDefClr )
   REDEFINE GET aColorGet[13] VAR aColors[13] ID 213 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[13], aColors[13], nDefClr )
   REDEFINE GET aColorGet[14] VAR aColors[14] ID 214 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[14], aColors[14], nDefClr )
   REDEFINE GET aColorGet[15] VAR aColors[15] ID 215 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[15], aColors[15], nDefClr )
   REDEFINE GET aColorGet[16] VAR aColors[16] ID 216 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[16], aColors[16], nDefClr )
   REDEFINE GET aColorGet[17] VAR aColors[17] ID 217 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[17], aColors[17], nDefClr )
   REDEFINE GET aColorGet[18] VAR aColors[18] ID 218 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[18], aColors[18], nDefClr )
   REDEFINE GET aColorGet[19] VAR aColors[19] ID 219 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[19], aColors[19], nDefClr )
   REDEFINE GET aColorGet[20] VAR aColors[20] ID 220 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[20], aColors[20], nDefClr )
   REDEFINE GET aColorGet[21] VAR aColors[21] ID 221 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[21], aColors[21], nDefClr )
   REDEFINE GET aColorGet[22] VAR aColors[22] ID 222 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[22], aColors[22], nDefClr )
   REDEFINE GET aColorGet[23] VAR aColors[23] ID 223 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[23], aColors[23], nDefClr )
   REDEFINE GET aColorGet[24] VAR aColors[24] ID 224 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[24], aColors[24], nDefClr )
   REDEFINE GET aColorGet[25] VAR aColors[25] ID 225 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[25], aColors[25], nDefClr )
   REDEFINE GET aColorGet[26] VAR aColors[26] ID 226 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[26], aColors[26], nDefClr )
   REDEFINE GET aColorGet[27] VAR aColors[27] ID 227 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[27], aColors[27], nDefClr )
   REDEFINE GET aColorGet[28] VAR aColors[28] ID 228 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[28], aColors[28], nDefClr )
   REDEFINE GET aColorGet[29] VAR aColors[29] ID 229 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[29], aColors[29], nDefClr )
   REDEFINE GET aColorGet[30] VAR aColors[30] ID 230 OF oFld:aDialogs[ i ] VALID Set2Color( aColorSay[30], aColors[30], nDefClr )

   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 301 OF oFld:aDialogs[ i ] ACTION ( aColors[1 ] := Set3Color( aColorSay[1 ], aColors[1 ], nDefClr ), aColorGet[1 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 302 OF oFld:aDialogs[ i ] ACTION ( aColors[2 ] := Set3Color( aColorSay[2 ], aColors[2 ], nDefClr ), aColorGet[2 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 303 OF oFld:aDialogs[ i ] ACTION ( aColors[3 ] := Set3Color( aColorSay[3 ], aColors[3 ], nDefClr ), aColorGet[3 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 304 OF oFld:aDialogs[ i ] ACTION ( aColors[4 ] := Set3Color( aColorSay[4 ], aColors[4 ], nDefClr ), aColorGet[4 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 305 OF oFld:aDialogs[ i ] ACTION ( aColors[5 ] := Set3Color( aColorSay[5 ], aColors[5 ], nDefClr ), aColorGet[5 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 306 OF oFld:aDialogs[ i ] ACTION ( aColors[6 ] := Set3Color( aColorSay[6 ], aColors[6 ], nDefClr ), aColorGet[6 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 307 OF oFld:aDialogs[ i ] ACTION ( aColors[7 ] := Set3Color( aColorSay[7 ], aColors[7 ], nDefClr ), aColorGet[7 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 308 OF oFld:aDialogs[ i ] ACTION ( aColors[8 ] := Set3Color( aColorSay[8 ], aColors[8 ], nDefClr ), aColorGet[8 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 309 OF oFld:aDialogs[ i ] ACTION ( aColors[9 ] := Set3Color( aColorSay[9 ], aColors[9 ], nDefClr ), aColorGet[9 ]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 310 OF oFld:aDialogs[ i ] ACTION ( aColors[10] := Set3Color( aColorSay[10], aColors[10], nDefClr ), aColorGet[10]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 311 OF oFld:aDialogs[ i ] ACTION ( aColors[11] := Set3Color( aColorSay[11], aColors[11], nDefClr ), aColorGet[11]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 312 OF oFld:aDialogs[ i ] ACTION ( aColors[12] := Set3Color( aColorSay[12], aColors[12], nDefClr ), aColorGet[12]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 313 OF oFld:aDialogs[ i ] ACTION ( aColors[13] := Set3Color( aColorSay[13], aColors[13], nDefClr ), aColorGet[13]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 314 OF oFld:aDialogs[ i ] ACTION ( aColors[14] := Set3Color( aColorSay[14], aColors[14], nDefClr ), aColorGet[14]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 315 OF oFld:aDialogs[ i ] ACTION ( aColors[15] := Set3Color( aColorSay[15], aColors[15], nDefClr ), aColorGet[15]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 316 OF oFld:aDialogs[ i ] ACTION ( aColors[16] := Set3Color( aColorSay[16], aColors[16], nDefClr ), aColorGet[16]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 317 OF oFld:aDialogs[ i ] ACTION ( aColors[17] := Set3Color( aColorSay[17], aColors[17], nDefClr ), aColorGet[17]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 318 OF oFld:aDialogs[ i ] ACTION ( aColors[18] := Set3Color( aColorSay[18], aColors[18], nDefClr ), aColorGet[18]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 319 OF oFld:aDialogs[ i ] ACTION ( aColors[19] := Set3Color( aColorSay[19], aColors[19], nDefClr ), aColorGet[19]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 320 OF oFld:aDialogs[ i ] ACTION ( aColors[20] := Set3Color( aColorSay[20], aColors[20], nDefClr ), aColorGet[20]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 321 OF oFld:aDialogs[ i ] ACTION ( aColors[21] := Set3Color( aColorSay[21], aColors[21], nDefClr ), aColorGet[21]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 322 OF oFld:aDialogs[ i ] ACTION ( aColors[22] := Set3Color( aColorSay[22], aColors[22], nDefClr ), aColorGet[22]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 323 OF oFld:aDialogs[ i ] ACTION ( aColors[23] := Set3Color( aColorSay[23], aColors[23], nDefClr ), aColorGet[23]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 324 OF oFld:aDialogs[ i ] ACTION ( aColors[24] := Set3Color( aColorSay[24], aColors[24], nDefClr ), aColorGet[24]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 325 OF oFld:aDialogs[ i ] ACTION ( aColors[25] := Set3Color( aColorSay[25], aColors[25], nDefClr ), aColorGet[25]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 326 OF oFld:aDialogs[ i ] ACTION ( aColors[26] := Set3Color( aColorSay[26], aColors[26], nDefClr ), aColorGet[26]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 327 OF oFld:aDialogs[ i ] ACTION ( aColors[27] := Set3Color( aColorSay[27], aColors[27], nDefClr ), aColorGet[27]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 328 OF oFld:aDialogs[ i ] ACTION ( aColors[28] := Set3Color( aColorSay[28], aColors[28], nDefClr ), aColorGet[28]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 329 OF oFld:aDialogs[ i ] ACTION ( aColors[29] := Set3Color( aColorSay[29], aColors[29], nDefClr ), aColorGet[29]:Refresh() )
   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 330 OF oFld:aDialogs[ i ] ACTION ( aColors[30] := Set3Color( aColorSay[30], aColors[30], nDefClr ), aColorGet[30]:Refresh() )

   ACTIVATE DIALOG oDlg CENTERED

   //Colors speichern
   INI oIni FILE cDefIni
   for i := 1 to 30
      if .NOT. Empty( aColors[ i ] )
         SET SECTION "Colors" ENTRY AllTrim(STR(i,5)) to aColors[ i ] OF oIni
      endif
   next
   ENDINI

   SetSave( .F. )

return .T.

//----------------------------------------------------------------------------//

function Set2Color( oColorSay, cColor, nDefClr )

   oColorSay:SetColor( SetColor( cColor, nDefClr ), SetColor( cColor, nDefClr ) )
   oColorSay:Refresh()

return .T.

//----------------------------------------------------------------------------//

function Set3Color( oColorSay, cColor, nDefClr )

   cColor := PADR( AllTrim( STR( ChooseColor( Val( cColor ) ), 20 ) ), 40 )
   Set2Color( oColorSay, cColor, nDefClr )

return ( cColor )

//----------------------------------------------------------------------------//

function SetColor( cColor, nDefClr )

   local nColor

   if Empty( cColor ) = .T.
      nColor := nDefClr
   else
      nColor := Val( cColor )
   endif

return ( nColor )

//----------------------------------------------------------------------------//

function GetFontText( aGetFonts, lShowEmpty )

   local i, cText
   local aShowFonts := {}

   DEFAULT lShowEmpty := .T.

   for i := 1 to 20
      if .NOT. Empty(aGetFonts[i, 1 ])
         cText :=  AllTrim(STR( i, 3)) + ". " + ;
                   aGetFonts[i, 1 ] + ;
                   " " + AllTrim(STR( aGetFonts[i,3], 5 )) + ;
                   IIF( aGetFonts[i,4], " " + GL("bold"), "") + ;
                   IIF( aGetFonts[i,5], " " + GL("italic"), "") + ;
                   IIF( aGetFonts[i,6], " " + GL("underline"), "") + ;
                   IIF( aGetFonts[i,7], " " + GL("strickout"), "") + ;
                   IIF( aGetFonts[i,8] <> 0, " " + GL("Rotation:") + " " + AllTrim(STR( aGetFonts[i,8], 6)), "")
         AADD( aShowFonts, cText )
      else
         if lShowEmpty = .T.
            AADD( aShowFonts, AllTrim(STR( i, 3)) + ". " )
         endif
      endif
   next

return ( aShowFonts )

//----------------------------------------------------------------------------//

function PreviewRefresh( oSay, oLbx, oGet )

   local nID := Val(SUBSTR( oLbx:GetItem(oLbx:GetPos()), 1, 2))

   oSay:Default()
   oSay:SetFont( aFonts[nID] )
   oSay:Refresh()

   oGet:SetFont( aFonts[nID] )
   oGet:Refresh()

return .T.

//----------------------------------------------------------------------------//

function SelectFont( oSay, oLbx, oGet )

   local oDlg, cFontDef, oFontGet, oIni, oNewFont, aShowFonts, nPos, aFontNames
   local i, y, cItemDef, aIniEntries, nEntry
   local lSave       := .F.
   local aCbx        := ARRAY(4)
   local nID         := Val(SUBSTR( oLbx:GetItem(oLbx:GetPos()), 1, 2))
   local aGetFonts   := GetFonts()
   local cFontGet    := aGetFonts[nID, 1 ]
   local nWidth      := aGetFonts[nID, 2 ]
   local nHeight     := aGetFonts[nID,3] * -1
   local lBold       := aGetFonts[nID,4]
   local lItalic     := aGetFonts[nID,5]
   local lUnderline  := aGetFonts[nID,6]
   local lStrikeOut  := aGetFonts[nID,7]
   local nEscapement := aGetFonts[nID,8]
   local nOrient     := aGetFonts[nID,10]
   local nCharSet    := aGetFonts[nID,9]
   local hDC         := oMainWnd:GetDC()

   if Empty( aFontNames := GetFontNames( hDC ) )
      MsgStop( GL("Error getting font names."), GL("Stop!") )
      return( GetFontText( GetFonts() ) )
   else
      ASORT( aFontNames,,, { |x, y| UPPER( x ) < UPPER( y ) } )
   endif

   DEFINE DIALOG oDlg NAME "SETFONT" TITLE GL("Font")

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE COMBOBOX oFontGet VAR cFontGet ITEMS aFontNames ID 110 OF oDlg

   REDEFINE GET nWidth      ID 201 OF oDlg PICTURE "9999"   SPINNER
   REDEFINE GET nHeight     ID 202 OF oDlg PICTURE "9999"   SPINNER
   REDEFINE GET nEscapement ID 203 OF oDlg PICTURE "999999" SPINNER
   REDEFINE GET nOrient     ID 204 OF oDlg PICTURE "999999" SPINNER
   REDEFINE GET nCharSet    ID 205 OF oDlg PICTURE "99"     SPINNER

   REDEFINE CHECKBOX aCbx[ 1 ] VAR lBold      ID 301 OF oDlg
   REDEFINE CHECKBOX aCbx[2] VAR lItalic    ID 302 OF oDlg
   REDEFINE CHECKBOX aCbx[3] VAR lUnderline ID 303 OF oDlg
   REDEFINE CHECKBOX aCbx[4] VAR lStrikeOut ID 304 OF oDlg

   REDEFINE SAY PROMPT GL("Width:")              ID 170 OF oDlg
   REDEFINE SAY PROMPT GL("Height:")             ID 171 OF oDlg
   REDEFINE SAY PROMPT GL("Rotation:")           ID 172 OF oDlg
   REDEFINE SAY PROMPT GL("Orientation")   + ":" ID 173 OF oDlg
   REDEFINE SAY PROMPT GL("Character set") + ":" ID 174 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( aCbx[ 1 ]:SetText( GL("bold") ), ;
                aCbx[2]:SetText( GL("italic") ), ;
                aCbx[3]:SetText( GL("underline") ), ;
                aCbx[4]:SetText( GL("strikeout") ) )

   if lSave = .T.

      cFontDef := AllTrim( cFontGet )               + "| " + ;
                  AllTrim( STR( nWidth, 5 ) )       + "| " + ;
                  AllTrim( STR( -1 * nHeight, 5 ) ) + "| " + ;
                  IIF( lBold, "1", "0" )            + "| " + ;
                  IIF( lItalic, "1", "0" )          + "| " + ;
                  IIF( lUnderline, "1", "0" )       + "| " + ;
                  IIF( lStrikeOut, "1", "0" )       + "| " + ;
                  AllTrim( STR( nEscapement, 10 ) ) + "| " + ;
                  AllTrim( STR( nCharSet, 10 ) )    + "| " + ;
                  AllTrim( STR( nOrient, 10 ) )

      if Empty( cFontGet )
         cFontDef := ""
      endif

      INI oIni FILE cDefIni
         SET SECTION "Fonts" ENTRY AllTrim(STR(nID,5)) to cFontDef OF oIni
      ENDINI

      aFonts[nID] := TFont():New( AllTrim( cFontGet ), nWidth, -1 * nHeight,, lBold, ;
                                  nEscapement, nOrient,, lItalic, lUnderline, lStrikeOut, ;
                                  nCharSet )

      nPos := oLbx:GetPos()
      aShowFonts := GetFontText( GetFonts() )
      oLbx:SetItems( aShowFonts )
      oLbx:Select( nPos )
      PreviewRefresh( oSay, oLbx, oGet )

      //Alle Elemente aktualisieren
      for i := 1 to 100

         if aWnd[ i ] <> nil

            aIniEntries := GetIniSection( "Items", aAreaIni[ i ] )

            for y := 1 to LEN( aIniEntries )

               nEntry := EntryNr( aIniEntries[y] )

               if nEntry <> 0 .and. aItems[i,nEntry] <> nil

                  cItemDef := GetIniEntry( aIniEntries, AllTrim(STR(nEntry,5)) , "" )

                  if UPPER(AllTrim( GetField( cItemDef, 1 ) )) = "TEXT" .and. ;
                        Val( GetField( cItemDef, 11 ) ) = nID

                     aItems[i,nEntry]:SetFont( aFonts[nID] )
                     aItems[i,nEntry]:Refresh()

                  endif

               endif

            next

         endif

      next

   endif

return ( aShowFonts )

//----------------------------------------------------------------------------//

function GetFonts()

   local i, cFontDef
   local aWerte := ARRAY( 20, 10 )

   for i := 1 to 20

      cFontDef := AllTrim( GetPvProfString( "Fonts", AllTrim(STR(i,3)) , "", cDefIni ) )

      if .NOT. Empty( cFontDef )


         aWerte[i, 1] := AllTrim( GetField( cFontDef, 1 ) )                   // Name
         aWerte[i, 2] := Val( GetField( cFontDef, 2 ) )                       // Width
         aWerte[i, 3] := Val( GetField( cFontDef, 3 ) )                       // Height
         aWerte[i, 4] := IIF( Val( GetField( cFontDef, 4 ) ) = 1, .T., .F. )  // Bold
         aWerte[i, 5] := IIF( Val( GetField( cFontDef, 5 ) ) = 1, .T., .F. )  // Italic
         aWerte[i, 6] := IIF( Val( GetField( cFontDef, 6 ) ) = 1, .T., .F. )  // Underline
         aWerte[i, 7] := IIF( Val( GetField( cFontDef, 7 ) ) = 1, .T., .F. )  // Strikeout
         aWerte[i, 8] := Val( GetField( cFontDef, 8 ) )                       // Escapement
         aWerte[i, 9] := Val( GetField( cFontDef, 9 ) )                       // Character Set
         aWerte[i,10] := Val( GetField( cFontDef, 10 ) )                      // Orientation

      else

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

      endif

   next

return aWerte

//----------------------------------------------------------------------------//

function ReportSettings()

   local i, oDlg, oIni, aGrp[2], oRad1, aGet[ 1 ]
   local lSave       := .F.
   local nWidth      := Val( GetPvProfString( "General", "PaperWidth" , "", cDefIni ) )
   local nHeight     := Val( GetPvProfString( "General", "PaperHeight", "", cDefIni ) )
   local nTop        := Val( GetPvProfString( "General", "TopMargin" , "20", cDefIni ) )
   local nLeft       := Val( GetPvProfString( "General", "LeftMargin", "20", cDefIni ) )
   local nPageBreak  := Val( GetPvProfString( "General", "PageBreak", "240", cDefIni ) )
   local nOrient     := Val( GetPvProfString( "General", "Orientation", "1", cDefIni ) )
   local cTitle      := PADR( GetPvProfString( "General", "Title", "", cDefIni ), 80 )
   local cGroup      := PADR( GetPvProfString( "General", "Group", "", cDefIni ), 80 )
   local cPicture    := IIF( nMeasure = 2, "999.99", "99999" )
   local aFormat     := GetPaperSizes()
   local nFormat     := Val( GetPvProfString( "General", "PaperSize", "9", cDefIni ) )
   local cFormat     := aFormat[ IIF( nFormat = 0, 9, nFormat ) ]

   DEFINE DIALOG oDlg NAME "REPORTOPTIONS" TITLE GL("Report Settings")

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE COMBOBOX cFormat ITEMS aFormat ID 421 OF oDlg ;
      ON CHANGE aGet[ 1 ]:Setfocus()

   REDEFINE GET nWidth ID 411 OF oDlg PICTURE cPicture SPINNER MIN 0 ;
      WHEN AllTrim( cFormat ) = GL("user-defined")
   REDEFINE GET nHeight ID 412 OF oDlg PICTURE cPicture SPINNER MIN 0 ;
      WHEN AllTrim( cFormat ) = GL("user-defined")

   REDEFINE GET aGet[ 1 ] VAR nTop ID 401 OF oDlg PICTURE cPicture SPINNER MIN 0
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

   REDEFINE GROUP aGrp[ 1 ] ID 190 OF oDlg
   REDEFINE GROUP aGrp[2] ID 191 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( aGrp[ 1 ]:SetText( GL("Paper Size") ), ;
                aGrp[2]:SetText( GL("Report") ), ;
                oRad1:aItems[ 1 ]:SetText( GL("Portrait") ), ;
                oRad1:aItems[2]:SetText( GL("Landscape") ) )

   if lSave = .T.

      INI oIni FILE cDefIni
         SET SECTION "General" ENTRY "PaperSize"    to AllTrim(STR( ASCAN( aFormat, AllTrim( cFormat ) ), 3 )) OF oIni
         SET SECTION "General" ENTRY "PaperWidth"   to AllTrim(STR( nWidth , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "PaperHeight"  to AllTrim(STR( nHeight, 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "TopMargin"    to AllTrim(STR( nTop   , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "LeftMargin"   to AllTrim(STR( nLeft  , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "PageBreak"    to AllTrim(STR( nPageBreak, 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "Orientation"  to AllTrim(STR( nOrient, 1 )) OF oIni
         SET SECTION "General" ENTRY "Title"        to AllTrim( cTitle ) OF oIni
         SET SECTION "General" ENTRY "Group"        to AllTrim( cGroup ) OF oIni
      ENDINI

      oMainWnd:cTitle := MainCaption()

      SetSave( .F. )

   endif

return .T.

//----------------------------------------------------------------------------//

function GetPaperSizes()

   local aSizes := { "Letter 8 1/2 x 11 inch"        , ;
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

return ( aSizes )

//----------------------------------------------------------------------------//

function Options()

   local i, oDlg, oIni, cLanguage, cOldLanguage, cWert, aCbx[4], aGrp[2], oRad1
   local lSave         := .F.
   local lInfo         := .F.
   local nLanguage     := Val( GetPvProfString( "General", "Language"  , "1", cGeneralIni ) )
   local nMaximize     := Val( GetPvProfString( "General", "Maximize"  , "1", cGeneralIni ) )
   local lMaximize     := IIF( nMaximize = 1, .T., .F. )
   local nMruList      := Val( GetPvProfString( "General", "MruList"  , "4", cGeneralIni ) )
   local aLanguage     := {}
   local cPicture      := IIF( nMeasure = 2, "999.99", "99999" )
   local nGridWidth    := oGenVar:nGridWidth
   local nGridHeight   := oGenVar:nGridHeight
   local lShowGrid     := oGenVar:lShowGrid
   local lShowReticule := oGenVar:lShowReticule
   local lShowBorder   := oGenVar:lShowBorder

   for i := 1 to 99
      cWert := GetPvProfString( "Languages", AllTrim(STR(i,2)), "", cGeneralIni )
      if .NOT. Empty( cWert )
         AADD( aLanguage, cWert )
      endif
   next

   if Len( aLanguage ) > 0
      cLanguage    := aLanguage[IIF( nLanguage < 1, 1, nLanguage)]
      cOldLanguage := cLanguage
   endif   

   DEFINE DIALOG oDlg NAME "OPTIONS" TITLE GL("Options")

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE COMBOBOX cLanguage ITEMS aLanguage ID 201 OF oDlg
   REDEFINE CHECKBOX aCbx[ 1 ] VAR lMaximize ID 202 OF oDlg
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

   REDEFINE GROUP aGrp[ 1 ] ID 190 OF oDlg
   REDEFINE GROUP aGrp[2] ID 191 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( aCbx[ 1 ]:SetText( GL("Maximize window at start") ), ;
                aCbx[2]:SetText( GL("Show grid") ), ;
                aCbx[3]:SetText( GL("Show always text border") ), ;
                aCbx[4]:SetText( GL("Show reticule") ), ;
                aGrp[ 1 ]:SetText( GL("General") ), ;
                aGrp[2]:SetText( GL("Grid") ) )

   if lSave = .T.

      oGenVar:nGridWidth    := nGridWidth
      oGenVar:nGridHeight   := nGridHeight
      oGenVar:lShowGrid     := lShowGrid
      oGenVar:lShowReticule := lShowReticule
      oGenVar:lShowBorder   := lShowBorder

      INI oIni FILE cDefIni
         SET SECTION "General" ENTRY "GridWidth"  to AllTrim(STR( nGridWidth , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "GridHeight" to AllTrim(STR( nGridHeight, 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "ShowGrid"   to IIF( lShowGrid, "1", "0") OF oIni
      ENDINI

      INI oIni FILE cGeneralIni
         SET SECTION "General" ENTRY "MruList"        to AllTrim(STR( nMruList ))       OF oIni
         SET SECTION "General" ENTRY "Maximize"       to IIF( lMaximize    , "1", "0")  OF oIni
         SET SECTION "General" ENTRY "ShowTextBorder" to IIF( lShowBorder  , "1", "0" ) OF oIni
         SET SECTION "General" ENTRY "ShowReticule"   to IIF( lShowReticule, "1", "0" ) OF oIni

         if cLanguage <> cOldLanguage
            SET SECTION "General" ENTRY "Language" to ;
               AllTrim(STR(ASCAN( aLanguage, cLanguage ), 2)) OF oIni
         endif

      ENDINI

      for i := 1 to 100
         if aWnd[ i ] <> nil
            aWnd[ i ]:Refresh()
         endif
      next

      SetGridSize( ER_GetPixel( nGridWidth ), ER_GetPixel( nGridHeight ) )
      nXMove := ER_GetPixel( nGridWidth )
      nYMove := ER_GetPixel( nGridHeight )

      oGenVar:nGridWidth  := nGridWidth
      oGenVar:nGridHeight := nGridHeight

      oMainWnd:SetMenu( BuildMenu() )

      SetSave( .F. )

   endif

return .T.


 function ItemList()

   local oDlg
   local oTree
   LOCAL oImageList, oBmp1, oBmp2

   DEFINE DIALOG oDlg RESOURCE "Itemlist" TITLE GL("Item List")

   oTree := TTreeView():ReDefine( 201, oDlg, 0, , .F. ,"" )
   oTree:bLDblClick := { | nRow, nCol, nKeyFlags | ClickListTree( oTree ) }

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION oDlg:End()

   ACTIVATE DIALOG oDlg CENTERED ON INIT carga( oTree, oDlg )  //ListTrees( oTree )

return nil

STATIC Function Carga( oTree, oDlg )
   local lFirstArea    := .T.
   local aIniEntries   := GetIniSection( "Areas", cDefIni )
   local cAreaFilesDir := CheckPath( GetPvProfString( "General", "AreaFilesDir", "", cDefIni ) )
   LOCAL oTr1
   LOCAL aTr:= {}
   local i, y, oTr2, cItemDef, aElemente, nEntry, cTitle
   LOCAL oImageList, oBmp1
   LOCAL ele

      oImageList = TImageList():New()

      oBmp1 = TBitmap():Define( "FoldOpen",, oDlg )
      oImageList:Add( oBmp1,setMasked( oBmp1:hBitmap, oTree:nClrPane ) ) // 0

      oBmp1 = TBitmap():Define("FoldClose",, oDlg )
      oImageList:Add( oBmp1,setMasked( oBmp1:hBitmap, oTree:nClrPane )  ) //1

      oBmp1 = TBitmap():Define( "B_itemList",, oDlg )
      oImageList:Add( oBmp1,setMasked( oBmp1:hBitmap, oTree:nClrPane )  ) //2

      oBmp1 = TBitmap():Define( "Checkon",, oDlg )
      oImageList:Add( oBmp1,setMasked( oBmp1:hBitmap, oTree:nClrPane )  ) //3


      oBmp1 = TBitmap():Define("Unchecked" ,, oDlg )
      oImageList:Add( oBmp1,setMasked( oBmp1:hBitmap, oTree:nClrPane )  ) //4

       oBmp1 = TBitmap():Define("b_edit" ,, oDlg )
      oImageList:Add( oBmp1,setMasked( oBmp1:hBitmap, oTree:nClrPane )  ) //5

      oBmp1 = TBitmap():Define( "Typ_Text",, oDlg )
      oImageList:Add( oBmp1,setMasked( oBmp1:hBitmap, oTree:nClrPane )  ) //6


         oBmp1 = TBitmap():Define(  "Typ_Barcode",, oDlg )
         oImageList:Add( oBmp1, setMasked( oBmp1:hBitmap, oTree:nClrPane ) ) // 7

            oBmp1 = TBitmap():Define( "Typ_Image",, oDlg )
         oImageList:Add( oBmp1,setMasked( oBmp1:hBitmap, oTree:nClrPane )  ) //8


        oTree:SetImageList( oImageList )

   for i := 1 to LEN( aIniEntries )
      nEntry := EntryNr( aIniEntries[ i ] )
      if nEntry != 0
            cTitle := aWndTitle[nEntry]
            oTr1 := oTree:Add( AllTrim(STR(nEntry,5)) + ". " + cTitle,0 )
          
            if Empty( cAreaFilesDir )
                cAreaFilesDir := cDefaultPath
           endif
           if Empty( cAreaFilesDir )
               cAreaFilesDir := cDefIniPath
           endif
           cItemDef := VRD_LF2SF( cAreaFilesDir + ;
            AllTrim( GetIniEntry( aIniEntries, AllTrim(STR(nEntry,5)) , "" ) ) )
            if .NOT. Empty( cItemDef )

            cItemDef := IIF( AT( "\", cItemDef ) = 0, ".\", "" ) + cItemDef

            aElemente := GetAllItems( cItemDef )
            oTr1:Add( GL("Area Properties"),2 )

            for y := 1 to LEN( aElemente )

               oTr2 := oTr1:Add( aElemente[y, 2 ], aElemente[y,3], aElemente[y,3] )
               if aElemente[y,6] <> 0
                  ele:= oTr2:Add( GL("Visible"), aElemente[y,5], aElemente[y,4] )
                  ele:Set( , IF( !GetItemVisible( ele ) , 4  , 3   )    )
                    
               endif
               oTr2:Add( GL("Item Properties"),5 )

            next

         endif


      endif
  NEXT

   oTree:Expand()

Return NIL

//------------------------------------------------------------------------------

STATIC function GetItemVisible( oItem )

LOCAL  oLinkArea := oItem:GetParent()
LOCAL  nItem     := Val( oLinkArea:cPrompt )
LOCAL  nArea     := Val( oLinkArea:GetParent():cPrompt )
LOCAL  cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", aAreaIni[ nArea ] ) )
LOCAL  lWert

      if Val( GetField( cItemDef, 4 ) ) = 0
         lWert := .F.
      else
         lWert := .T.
      endif

RETURN lWert

//----------------------------------------------------------------------------//
/*
function ItemList()

   local oDlg
   local oTree

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

return nil
*/
//----------------------------------------------------------------------------//

function ListTrees( oTree )

   local i, y, oTr1, oTr2, cItemDef, aElemente, nEntry, cTitle
   local lFirstArea    := .T.
   local nClose        := 1
   local nOpen         := 2
   local aIniEntries   := GetIniSection( "Areas", cDefIni )
   local cAreaFilesDir := CheckPath( GetPvProfString( "General", "AreaFilesDir", "", cDefIni ) )

   oTr1 := oTree:GetRoot()

   for i := 1 to LEN( aIniEntries )

      nEntry := EntryNr( aIniEntries[ i ] )

      if nEntry <> 0 //.and. .NOT. Empty( aWndTitle[nEntry] )

         cTitle := aWndTitle[nEntry]

         if lFirstArea = .T.
            oTr1 := oTr1:AddLastChild( AllTrim(STR(nEntry,5)) + ". " + cTitle, nClose, nOpen )
            lFirstArea := .F.
         else
            oTr1 := oTr1:AddAfter( AllTrim(STR(nEntry,5)) + ". " + cTitle, nClose, nOpen )
         endif

         if Empty( cAreaFilesDir )
            cAreaFilesDir := cDefaultPath
         endif
         if Empty( cAreaFilesDir )
            cAreaFilesDir := cDefIniPath
         endif

         cItemDef := VRD_LF2SF( cAreaFilesDir + ;
            AllTrim( GetIniEntry( aIniEntries, AllTrim(STR(nEntry,5)) , "" ) ) )

         if .NOT. Empty( cItemDef )

            cItemDef := IIF( AT( "\", cItemDef ) = 0, ".\", "" ) + cItemDef

            aElemente := GetAllItems( cItemDef )
            oTr1:AddLastChild( GL("Area Properties") )

            for y := 1 to LEN( aElemente )

               oTr2 := oTr1:AddLastChild( aElemente[y, 2 ], aElemente[y,3], aElemente[y,3] )
               if nEntry = 1 .and. y = 1
                  oTr2:lOpened := .T.
               endif
               if aElemente[y,6] <> 0
                  oTr2:AddLastChild( GL("Visible"), aElemente[y,5], aElemente[y,4] )
               endif
               oTr2:AddLastChild( GL("Item Properties") )

            next

         endif

      endif

   next

   oTree:UpdateTV()
   oTree:SetFocus()
   oTree:Expand()

return oTree

//----------------------------------------------------------------------------//

function GetAllItems( cAktAreaIni )

   local i, cItemDef, cTyp, cName, nShow, nTyp, nDelete, nEntry
   local aWerte      := {}
   local aIniEntries := GetIniSection( "Items", cAktAreaIni )

   for i := 1 to LEN( aIniEntries )

      nEntry := EntryNr( aIniEntries[ i ] )
      cItemDef := GetIniEntry( aIniEntries, AllTrim(STR(nEntry,5)) , "" )

      if .NOT. Empty( cItemDef )

         cTyp    := UPPER(AllTrim( GetField( cItemDef, 1 ) ))
         cName   := AllTrim( GetField( cItemDef, 2 ) )
         nShow   := Val( GetField( cItemDef, 4 ) )
         nDelete := Val( GetField( cItemDef, 5 ) )

         if UPPER( cTyp ) = "IMAGE" .and. Empty( cName ) = .T.
            cName := AllTrim(STR(nEntry,5)) + ". " + AllTrim( GetField( cItemDef, 11 ) )
         else
            cName := AllTrim(STR(nEntry,5)) + ". " + cName
         endif

         if UPPER( cTyp ) = "TEXT"
            nTyp := 6
         elseif UPPER( cTyp ) = "IMAGE"
            nTyp := 7
         elseif IsGraphic( cTyp ) = .T.
            nTyp := GetGraphIndex( cTyp ) + 9
         elseif UPPER( cTyp ) = "BARCODE"
            nTyp := 9
         endif

         AADD( aWerte, { cTyp, cName, nTyp, ;
                         IIF( nShow = 0, 4, 3 ), IIF( nShow = 0, 3, 4 ), nDelete } )

      endif

   next

return aWerte

//----------------------------------------------------------------------------//

function ClickListTree( oTree )
   LOCAL nArea , nItem, oLinkArea, cItemDef,  lWert
   local cPrompt := oTree:GetSelText()
   LOCAL oItem   := oTree:GetSelected()

   if cPrompt = GL("Visible") .OR. cPrompt = GL("Item Properties")

      oLinkArea := oItem:GetParent()
      nItem     := Val( oLinkArea:cPrompt )
      nArea     := Val( oLinkArea:GetParent():cPrompt )

   endif

   if cPrompt = GL("Area Properties")

      nArea     := Val( oItem:GetParent():cPrompt )
      AreaProperties( nArea )

   endif

   if cPrompt = GL("Visible")

    //   nItem     := Val( oLinkArea:cPrompt )
    //   nArea     := Val( oLinkArea:GetParent():cPrompt )

      cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", aAreaIni[ nArea ] ) )

      if Val( GetField( cItemDef, 4 ) ) = 0
         lWert := .F.
      else
         lWert := .T.
      endif
      oItem:Set( , IF( lWert , 4  , 3   )    )
   //  oItem:SetCheck( !lWert )
     DeleteItem( nItem, nArea, .T., lWert )

   endif
   
return .T.

//----------------------------------------------------------------------------//

/*
function ClickListTree( oTree )

   local cItemDef ,nItem, oLinkArea, nArea, lWert
   local oLinkItem   := oTree:GetLinkAt( oTree:GetCursel() )
   local cPrompt     := oLinkItem:TreeItem:cPrompt

   if cPrompt = GL("Visible") .OR. cPrompt = GL("Item Properties")

      nItem     := Val( oLinkItem:ParentLink:TreeItem:cPrompt )
      oLinkArea := oLinkItem:ParentLink
      nArea     := Val( oLinkArea:ParentLink:TreeItem:cPrompt )

   endif

   if cPrompt = GL("Area Properties")

      nArea     := Val( oLinkItem:ParentLink:TreeItem:cPrompt )

   endif

   if cPrompt = GL("Visible")

      cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", aAreaIni[ nArea ] ) )

      oLinkItem:ToggleOpened()
      oTree:Refresh()

      if Val( GetField( cItemDef, 4 ) ) = 0
         lWert := .F.
      else
         lWert := .T.
      endif

      DeleteItem( nItem, nArea, .T., lWert )

   elseif cPrompt = GL("Area Properties")

      AreaProperties( nArea )

   elseif cPrompt = GL("Item Properties")

      oLinkItem:ParentLink:TreeItem:SetText( ItemProperties( nItem, nArea, .T. ) )

      cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", aAreaIni[ nArea ] ) )

      if IsGraphic( UPPER(AllTrim( GetField( cItemDef, 1 ) )) )
         oLinkItem:ParentLink:TreeItem:iBmpOpen  := SetGraphTreeBmp( nItem, aAreaIni[ nArea ] )
         oLinkItem:ParentLink:TreeItem:iBmpClose := SetGraphTreeBmp( nItem, aAreaIni[ nArea ] )
      endif

      oTree:UpdateTV()

   endif

return .T.
*/
//----------------------------------------------------------------------------//

function SetGraphTreeBmp( nItem, cAreaIni )

   local cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", cAreaIni ) )
   local cTyp     := UPPER(AllTrim( GetField( cItemDef, 1 ) ))
   local nIndex   := GetGraphIndex( cTyp )

return ( nIndex + 9 )

//----------------------------------------------------------------------------//

function AreaProperties( nArea )

   local i, oDlg, oIni, oBtn, oRad1, aCbx[6], aGrp[5], oSay1
   local aDbase  := { GL("none") }
   local lSave   := .F.
   local nTop1   := Val( GetPvProfString( "General", "Top1", "0", aAreaIni[ nArea ] ) )
   local nTop2   := Val( GetPvProfString( "General", "Top2", "0", aAreaIni[ nArea ] ) )
   local lTop    := ( GetPvProfString( "General", "TopVariable", "1", aAreaIni[ nArea ] ) = "1" )
   local nWidth  := Val( GetPvProfString( "General", "Width", "600", aAreaIni[ nArea ] ) )
   local nHeight := Val( GetPvProfString( "General", "Height", "300", aAreaIni[ nArea ] ) )
   local nCondition     := Val( GetPvProfString( "General", "Condition", "1", aAreaIni[ nArea ] ) )
   local lDelSpace      := ( GetPvProfString( "General", "DelEmptySpace", "0", aAreaIni[ nArea ] ) = "1" )
   local lBreakBefore   := ( GetPvProfString( "General", "BreakBefore"  , "0", aAreaIni[ nArea ] ) = "1" )
   local lBreakAfter    := ( GetPvProfString( "General", "BreakAfter"   , "0", aAreaIni[ nArea ] ) = "1" )
   local lPrBeforeBreak := ( GetPvProfString( "General", "PrintBeforeBreak", "0", aAreaIni[ nArea ] ) = "1" )
   local lPrAfterBreak  := ( GetPvProfString( "General", "PrintAfterBreak" , "0", aAreaIni[ nArea ] ) = "1" )
   local cDatabase      := AllTrim( GetPvProfString( "General", "ControlDBF", GL("none"), aAreaIni[ nArea ] ) )
   local nOldWidth      := nWidth
   local nOldHeight     := nHeight
   local cPicture       := IIF( nMeasure = 2, "999.99", "99999" )
   local cAreaTitle     := aWndTitle[ nArea ]
   local cOldAreaText   := MEMOREAD( aAreaIni[ nArea ] )

   aTmpSource := {}

   for i := 1 to 13
      AADD( aTmpSource, ;
         AllTrim( GetPvProfString( "General", "Formula" + AllTrim(STR(i,2)), "", aAreaIni[ nArea ] ) ) )
   next

   AEval( oGenVar:aDBFile, {|x| IIF( Empty( x[2] ),, AADD( aDbase, AllTrim( x[2] ) ) ) } )

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

   REDEFINE CHECKBOX aCbx[ 1 ] VAR lDelSpace      ID 601 OF oDlg
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

   REDEFINE GROUP aGrp[ 1 ] ID 190 OF oDlg
   REDEFINE GROUP aGrp[2] ID 191 OF oDlg
   REDEFINE GROUP aGrp[3] ID 192 OF oDlg
   REDEFINE GROUP aGrp[4] ID 193 OF oDlg
   REDEFINE GROUP aGrp[5] ID 194 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( oRad1:aItems[ 1 ]:SetText( GL("always") ), ;
                oRad1:aItems[2]:SetText( GL("never") ), ;
                oRad1:aItems[3]:SetText( GL("page = 1") ), ;
                oRad1:aItems[4]:SetText( GL("page > 1") ), ;
                aGrp[ 1 ]:SetText( GL("Title") ), ;
                aGrp[2]:SetText( GL("Position") ), ;
                aGrp[3]:SetText( GL("Size") ), ;
                aGrp[4]:SetText( GL("Print Condition") ), ;
                aGrp[5]:SetText( GL("Options") ), ;
                aCbx[ 1 ]:SetText( GL("Delete Empty space after last row") ), ;
                aCbx[2]:SetText( GL("New page before printing this area") ), ;
                aCbx[3]:SetText( GL("New page after printing this area") ), ;
                aCbx[5]:SetText( GL("Print this area before every page break") ), ;
                aCbx[6]:SetText( GL("Print this area after every page break") ), ;
                aCbx[4]:SetText( GL("Top depends on previous area") ) )

   if lSave = .T.

      INI oIni FILE aAreaIni[ nArea ]
         SET SECTION "General" ENTRY "Title"            to AllTrim( cAreaTitle ) OF oIni
         SET SECTION "General" ENTRY "Top1"             to AllTrim(STR( nTop1  , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "Top2"             to AllTrim(STR( nTop2  , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "TopVariable"      to IIF( lTop = .F., "0", "1") OF oIni
         SET SECTION "General" ENTRY "Condition"        to AllTrim(STR( nCondition, 1 )) OF oIni
         SET SECTION "General" ENTRY "Width"            to AllTrim(STR( nWidth , 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "Height"           to AllTrim(STR( nHeight, 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "DelEmptySpace"    to IIF( lDelSpace = .F., "0", "1") OF oIni
         SET SECTION "General" ENTRY "BreakBefore"      to IIF( lBreakBefore   = .F., "0", "1") OF oIni
         SET SECTION "General" ENTRY "BreakAfter"       to IIF( lBreakAfter    = .F., "0", "1") OF oIni
         SET SECTION "General" ENTRY "PrintBeforeBreak" to IIF( lPrBeforeBreak = .F., "0", "1") OF oIni
         SET SECTION "General" ENTRY "PrintAfterBreak"  to IIF( lPrAfterBreak  = .F., "0", "1") OF oIni
         SET SECTION "General" ENTRY "ControlDBF"       to AllTrim( cDatabase ) OF oIni

         for i := 1 to 12
            SET SECTION "General" ENTRY "Formula" + AllTrim(STR(i,2)) to AllTrim( aTmpSource[ i ] ) OF oIni
         next

      ENDINI

      oGenVar:aAreaSizes[ nArea, 1 ] := nWidth
      oGenVar:aAreaSizes[ nArea, 2 ] := nHeight

      AreaChange( nArea, cAreaTitle, nOldWidth, nWidth, nOldHeight, nHeight )

      SetSave( .F. )

      if cOldAreaText <> MEMOREAD( aAreaIni[ nArea ] )
         Add2Undo( "", 0, nArea, cOldAreaText )
      endif

   endif

return .T.

//----------------------------------------------------------------------------//

function SetAreaFormulaBtn( nID, nField, oDlg )

   local oBtn

   REDEFINE BTNBMP oBtn ID nID OF oDlg NOBORDER ;
      RESOURCE "B_SOURCE_" + IIF( Empty( aTmpSource[ nField ] ), "NO", "YES" ) TRANSPARENT ;
      TOOLTIP GetSourceToolTip( aTmpSource[ nField ] ) ;
      ACTION ( aTmpSource[ nField ] := EditSourceCode( 0, aTmpSource[ nField ] ), ;
               oBtn:LoadBitmaps( "B_SOURCE_" + IIF( Empty( aTmpSource[ nField ] ), "NO", "YES" ) ), ;
               oBtn:cToolTip := GetSourceToolTip( aTmpSource[ nField ] ), ;
               oBtn:Refresh() )

return oBtn

//----------------------------------------------------------------------------//

function AreaChange( nArea, cAreaTitle, nOldWidth, nWidth, nOldHeight, nHeight )

   local i

   aWndTitle[ nArea ]   := cAreaTitle
   aWnd[ nArea ]:cTitle := cAreaTitle
   oGenVar:aAreaTitle[ nAktArea ]:Refresh()

   aCbxItems[oCbxArea:nAt] := cAreaTitle
   oCbxArea:Modify( cAreaTitle, oCbxArea:nAt )
   oCbxArea:Set( AllTrim( cAreaTitle ) )

   if nOldWidth <> nWidth

      for i := 1 to 100
         if aWnd[ i ] <> nil
            aWnd[ i ]:Refresh()
         endif
      next

   endif

   if nOldHeight <> nHeight

      aWnd[ nArea ]:Move( aWnd[ nArea ]:nTop, aWnd[ nArea ]:nLeft, ;
         IIF( oGenVar:lFixedAreaWidth, 1200, ER_GetPixel( nWidth ) + nRuler + nAreaZugabe2 ), ;
         IIF( oGenVar:aAreaHide[ nArea ], nRulerTop, ER_GetPixel( nHeight ) + nAreaZugabe ), .T. )

      for i := nArea+1 to 100
         if aWnd[ i ] <> nil
            aWnd[ i ]:Move( aWnd[ i ]:nTop + ER_GetPixel( nHeight - nOldHeight ), ;
               aWnd[ i ]:nLeft,,, .T. )
         endif
      next

      nTotalHeight += ER_GetPixel( nHeight - nOldHeight )

   endif

return .T.

//----------------------------------------------------------------------------//

function AreaHide( nArea )

   local i, nDifferenz
   local nHideHeight := GetCmInch( 18 )
   local nAreaHeight := Val( GetPvProfString( "General", "Height", "300", aAreaIni[ nArea ] ) )
   local nWidth      := Val( GetPvProfString( "General", "Width", "600", aAreaIni[ nArea ] ) )

   oGenVar:aAreaHide[nAktArea] := !oGenVar:aAreaHide[nAktArea]

   nDifferenz := ( ER_GetPixel( nAreaHeight ) + nAreaZugabe - 18 ) * ;
                 IIF( oGenVar:aAreaHide[nAktArea], -1, 1 )

   aWnd[ nArea ]:Move( aWnd[ nArea ]:nTop, aWnd[ nArea ]:nLeft, ;
      IIF( oGenVar:lFixedAreaWidth, 1200, ER_GetPixel( nWidth ) + nRuler + nAreaZugabe2 ), ;
      IIF( oGenVar:aAreaHide[nAktArea], 18, ER_GetPixel( nAreaHeight ) + nAreaZugabe ), .T. )

   for i := nArea+1 to 100
      if aWnd[ i ] <> nil
         aWnd[ i ]:Move( aWnd[ i ]:nTop + nDifferenz, aWnd[ i ]:nLeft,,, .T. )
      endif
   next

   nTotalHeight += nDifferenz

return .T.

//----------------------------------------------------------------------------//

function EasyPreview()

   MsgInfo( "EasyPreview Not linked yet" )
   
return nil   

//----------------------------------------------------------------------------//

function TScript()

   MsgInfo( "TScript not linked yet" )
   
return nil   


//----------------------------------------------------------------------------//
// TEasyReport -> oER

CLASS TEasyReport

   DATA oMainWnd
   DATA cGeneralIni
   DATA cDataPath
   DATA bClrBar, aClrDialogs

   METHOD New() CONSTRUCTOR

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New() CLASS TEasyReport

   ::cGeneralIni = ".\vrd.ini"
   ::cDataPath   = GetCurDir() + "\Datas\"
   
   ::bClrBar =  { | lInvert | If( ! lInvert,;
                                  { { 1, RGB( 255, 255, 255 ), RGB( 229, 233, 238 ) } },;
                                  { { 2/5, RGB( 255, 253, 222 ), RGB( 255, 231, 147 ) },;
                                    { 3/5, RGB( 255, 215,  86 ), RGB( 255, 231, 153 ) } } ) }

   //  ::bClrBar := { | lInvert | If( ! lInvert,;
   //                                 { { 0.50, nRGB( 254, 254, 254 ), nRGB( 225, 225, 225 ) },;
   //                                   { 0.50, nRGB( 225, 225, 225 ), nRGB( 185, 185, 185 ) } },;
   //                                 { { 0.40, nRGB( 68, 68, 68 ), nRGB( 109, 109, 109 ) }, ;
   //                                   { 0.60, nRGB( 109, 109, 109 ), nRGB( 116, 116, 116 ) } } ) }

   ::aClrDialogs = { { 0.60,  nRGB( 221, 227, 233) ,  nRGB( 221, 227, 233 ) }, ;
                     { 0.40,nRGB( 221, 227, 233), nRGB( 221, 227, 233) } }  

  //  ::aColorDlg :=  { { 1, RGB( 199, 216, 237 ), RGB( 237, 242, 248 ) } } 

  //   ::aColorDlg :=  { { 0.60,  nRGB( 221, 227, 233) ,  nRGB( 221, 227, 233 ) }, ;
  //                        { 0.40,nRGB( 221, 227, 233), nRGB( 221, 227, 233) } }

return Self

//------------------------------------------------------------------------------

#define TME_LEAVE 2
#define WM_MOUSELEAVE 675

CLASS ER_MdiChild FROM TMdiChild

   DATA   aRulerTopPos
   DATA   aRulerLeftPos
   DATA   nArea
   
   METHOD HandleEvent( nMsg, nWParam, nLParam )
   METHOD MouseLeave( nRow, nCol, nFlags )
   METHOD MouseMove( nRow, nCol, nFlags )
   
ENDCLASS

//----------------------------------------------------------------------------//

METHOD MouseMove( nRow, nCol, nFlags ) CLASS ER_MdiChild

   local uResult := ::Super:MouseMove( nRow, nCol, nFlags )
   
   TrackMouseEvent( ::hWnd, TME_LEAVE )
   
return uResult   
   
//----------------------------------------------------------------------------//

METHOD HandleEvent( nMsg, nWParam, nLParam ) CLASS ER_MdiChild

   if nMsg == WM_MOUSELEAVE
      return ::MouseLeave( nHiWord( nLParam ), nLoWord( nLParam ), nWParam )
   endif 
   
return ::Super:HandleEvent( nMsg, nWParam, nLParam )

//----------------------------------------------------------------------------//

METHOD MouseLeave( nRow, nCol, nFlags ) CLASS ER_MdiChild

   SetReticule( nRow, nCol, ::nArea )

return nil

//----------------------------------------------------------------------------//