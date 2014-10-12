#include "FiveWin.ch"
#include "ttitle.ch"

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


#define MINVERSIONFW   10.08

//Areazugabe
STATIC nAreaZugabe  := 42
STATIC nAreaZugabe2 := 10

//Quelltext im Area-Bereich
STATIC aTmpSource

//Entscheidet ob die Graphikelemente neu gezeichnet werden sollen
STATIC lDraGraphic := .T.

MEMVAR cLongDefIni, cDefaultPath
MEMVAR nAktItem, nSelArea  //, aSelection, nAktArea
MEMVAR aVRDSave, lVRDSave
MEMVAR cItemCopy, aSelectCopy, aItemCopy, nXMove, nYMove
MEMVAR lProfi
MEMVAR oGenVar
MEMVAR oER

Static oBtnAreas, oMenuAreas, lScrollVert
STATIC lPersonal

//----------------------------------------------------------------------------//

function Main( P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, P14, P15 )

   local i, oBrush, oIni, aTest, nTime1, nTime2, cTest, oIcon, cDateFormat
   local cOldDir  := hb_CurDrive() + ":\" + GetCurDir()
   local cDefFile := ""
   local oSpl
   local nAltoSpl := 680
   local oSplit
   local oPanelI
   local aColorSay[30]
   local aColors

   IF !Empty(p1) .and. Left(p1,6) == "REEXEC"
      p1:= SubStr(p1,7)
      msginfo("Se reiniciará el programa con los cambios " )
   endif

   CheckRes()

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

   //  EP_TidyUp()
   //  EP_LinkedToApp()
   //  EP_SetPath( ".\" )

   ReadInsert( .F. )

   FWLoadStrings( )
   FwSetLanguage( 2 )

   PUBLIC oER    := TEasyReport():New()

   //Variables Publics declaration
   DeclarePublics( cDefFile )

   SET DELETED ON
   SET CONFIRM ON
   SET 3DLOOK ON
   SET MULTIPLE OFF
   SET DATE FORMAT to "dd.mm.yyyy"

   cDateFormat := LOWER(AllTrim( oEr:GetGeneralIni( "General", "DateFormat", "")) )

   SET DATE FORMAT IIF( Empty( cDateFormat ), "dd.mm.yyyy", cDateFormat )

   //Open Undo database
    OpenUndo()

   SET HELPFILE to "VRD.HLP"

   DEFINE ICON oIcon FILE ".\vrd.ico"

   //DEFINE BRUSH oBrush RESOURCE "background"

   SetDlgGradient( oER:aClrDialogs )

   DEFINE WINDOW oEr:oMainWnd VSCROLL ; //FROM 0, 0 to 50, 200 VSCROLL ;
      TITLE MainCaption() ;  //      BRUSH oBrush ;
      MDI ;
      ICON oIcon ;
      MENU BuildMenu() ;
      MENUINFO 4


   SET MESSAGE OF oEr:oMainWnd  CENTERED 2010

   DEFINE MSGITEM oER:oMsgInfo OF oEr:oMainWnd:oMsgBar SIZE 280

   oEr:oMainWnd:oMsgBar:KeybOn()
   oEr:oMainWnd:oWndClient:bMouseWheel = { | nKey, nDelta, nXPos, nYPos | ;
                           ER_MouseWheel( nKey, nDelta, nXPos, nYPos ) }

   BarMenu()



   IF oER:lShowPanel
      oER:oPanelI := TPanel():New( 0.1, 0, GetSysMetrics( 1 ) - 138, ;
                                   Int(GetSysMetrics( 0 )/4), ;          // 326
                                   oER:oMainWnd )

      oER:oPanelD := TPanel():New( 0.1, Int( ScreenWidth() - 2*Int(GetSysMetrics( 0 )/4) ) + 2, ;
                              GetSysMetrics( 1 ) - 138 , 3*Int(GetSysMetrics( 0 )/4), ;
                              oER:oMainWnd )

      if lValidFwh()

       @ 0.2, 1 CFOLDEREX oER:oFldI ;
       PROMPT GL("&Report Settings"), GL("&Items"), GL("Colors"), GL("Fonts") ;
       OF oEr:oPanelI ; //oEr:oMainWnd ;
       SIZE Int(GetSysMetrics( 0 )/4), GetSysMetrics( 1 ) - 138 ;    //326
       OPTION 2 ;
       TAB HEIGHT 34 ;
       BITMAPS { "B_EDIT16", "B_ITEMLIST16", "B_ITEMLIST16", "B_EDIT2" } ;
       PIXEL ;
       SEPARATOR 0

       @ 0.2, 1 CFOLDEREX oER:oFldD ;
       PROMPT GL("&Expressions"), GL("&Databases"), GL("&Inspector") ; //, GL("&Fields"), GL("Fil&ters") ;
       OF oEr:oPanelD ; //oEr:oMainWnd ;
       SIZE Int(GetSysMetrics( 0 )/4), GetSysMetrics( 1 ) - 138 ;
       OPTION 1 ;
       TAB HEIGHT 34 ;
       BITMAPS { "B_ITEMLIST16", "B_EDIT2" } ; //, "B_AREA", "B_AREA" } ;
       PIXEL ;
       SEPARATOR 0

      else

       @ 0.2, 1 FOLDER oER:oFldI ;
       PROMPT GL("&Report Settings"), GL("&Items"), , GL("Colors"), GL("Fonts") ;
       OF oEr:oPanelI ; //oEr:oMainWnd ;
       SIZE Int(GetSysMetrics( 0 )/4), GetSysMetrics( 1 ) - 138 ;
       OPTION 2 ;
       PIXEL

       @ 0.2, 1 FOLDER oER:oFldD ;
       PROMPT GL("&Expressions"), GL("&Databases") ; //, GL("&Fields"), GL("Fil&ters") ;
       OF oEr:oPanelD ;  //oEr:oMainWnd ;
       SIZE Int(GetSysMetrics( 0 )/4), GetSysMetrics( 1 ) - 138 ;
       OPTION 1 ;
       PIXEL

      endif

      oER:oPanelI:SetColor(  , oEr:nClrPaneTree )
      oER:oPanelD:SetColor(  , oEr:nClrPaneTree )

      oEr:oMainWnd:oLeft   :=  oEr:oPanelI   //oER:oFldI
      oEr:oMainWnd:oRight  :=  oEr:oPanelD   //oER:oFldD
      oER:oFldI:SetColor(  , oEr:nClrPaneTree )
      oER:oFldD:SetColor(  , oEr:nClrPaneTree )


      DlgTree( 2 )
      ER_Inspector( 3 )

      //oER:oInspector  = TInspector():New()

   ENDIF

   ACTIVATE WINDOW oEr:oMainWnd ;
      MAXIMIZED ;
      ON RESIZE if(!Empty(oER:oTree),oER:oTree:refresh( .T. ), ) ;
      ON INIT ( SetMainWnd(), IniMainWindow(), ;
                IIF( Empty( oER:cDefIni ), OpenFile(,,.T.), (  OpenFile(oER:cDefIni,,.T.), oER:SetScrollBar() ) ), ;
                StartMessage(), SetSave( .T. ), ClearUndoRedo(),;
                oEr:oMainWnd:SetFocus() ) ;
      VALID ( AEVal( oER:aWnd, { |o| if( o <> nil, o:End(), ) } ), AskSaveFiles() )

   oEr:oAppFont:End()
   if !empty( oBrush )
      oBrush:End()
   endif
   if !empty( oGenVar:oAreaBrush )
      oGenVar:oAreaBrush:End()
   endif
   if !empty( oGenVar:oBarBrush )
      oGenVar:oBarBrush:End()
   endif

   AEval( oGenVar:aAppFonts, {|x| x:End() } )
   AEval( oER:aFonts, {|x| IIF( x <> nil, x:End(), ) } )

  // CloseUndo()

   IF lisDir(oER:cTmpPath)
      DelTempFiles(oER:cTmpPath )
      dirRemove( oER:cTmpPath  )
   endif

   DbCloseAll()

   lChDir( cOldDir )

   IF oER:lReexec
      oER:lReexec := .F.
      ShellExecute( , "Open",  HB_ARGV( 0 ) , "REEXEC"+AllTrim(oER:cDefIni)  )
   endif

return nil
//------------------------------------------------------------------------------

Function SwichFldD( oWnd, oFld, lSetVisible  )

  Local   nWidth      := GetSysMetrics( 1 ) - 1
  DEFAULT lSetVisible := !ofld:isVisible()


  IF lSetVisible
     ofld:show()
     oWnd:oRight:= oFld
  ELSE
     ofld:hide()
     oWnd:oRight:= NIL
     SysRefresh()
  ENDIF

  oWnd:resize()
  oWnd:SetFocus()
  //oWnd:oWndClient:oVScroll:Refresh()

RETURN nil

//----------------------------------------------------------------------------//

Function DlgTree( nD, nD1 )
Local oFont
Local nItemH
Local oFoldnD

DEFAULT nD  := 2

   if empty( nD1 )
      DEFINE FONT oFont NAME "Verdana" SIZE 0, -10
      oER:oTree := TTreeView():New( 0, 2, oER:oFldI:aDialogs[ nD ] , 0, , .T., .F.,;
                                 Int(GetSysMetrics( 0 )/4) - 6 ,;
                                 Int(oER:oFldI:aDialogs[ nD ]:nHeight/2) ,"",, )

      // oEr:oMainWnd:oLeft  :=   oER:oTree
      oEr:oTree:SetColor( ,  oEr:nClrPaneTree )
      oEr:oTree:l3DLook := .F.
      oEr:oTree:SetFont( oFont )

      if lValidFwh( 14.08 )
         if !empty( oEr:oTree:oFont )
            nItemH := oEr:oTree:oFont:nHeight * 2
         else
            nItemH := 24
         endif
         oEr:oTree:SetItemHeight( nItemH )  // o  TvSetItemHeight( oER:oTree:hWnd, nItemH )
      endif
      oEr:oTree:bMouseWheel = { | nKey, nDelta, nXPos, nYPos | ;
                        ER_MouseWheelTree( nKey, nDelta, nXPos, nYPos ) }

      //oER:oFldI:aDialogs[ nD ]:SetControl( oEr:oTree )
      //oER:oFldI:Hide()
   endif

   @ Int(oER:oFldI:aDialogs[ nD ]:nHeight/2)+10, 1 CFOLDEREX oFoldnD ;
       PROMPT GL("&Areas"), GL("&Items") ;
       OF oER:oFldI:aDialogs[ nD ] ;
       SIZE Int(GetSysMetrics( 0 )/4), Int(oER:oFldI:aDialogs[ nD ]:nHeight/2) - 10 ;    //326
       OPTION 1 ;
       TAB HEIGHT 24 ;
       BITMAPS { "B_EDIT16", "B_ITEMLIST16" } ;
       PIXEL ;
       FONT oFont ;
       SEPARATOR 0

   ER_Inspector( , oFoldnD:aDialogs[ 1 ] )


Return oEr:oTree

//----------------------------------------------------------------------------//

Function Dlg_Colors( i )
   LOCAL obrush
   Local oFont
   Local n
   Local x
   LOCAL nDefClr
   Local nCol       := 78
   Local nFil       := 0
   Local aColors    := GetAllColors()
   Local aColorSay  := Array( Len( aColors ) )
   Local aColorGet  := Array( Len( aColors ) )

   //DEFINE BRUSH oBrush COLOR oEr:nClrPaneTree
   //oER:oFldI:aDialogs[i]:SetBrush( oBrush )

   //oER:oFldI:aDialogs[ i ]:SetColor( CLR_BLACK, oEr:nClrPaneTree )
   nDefClr := oER:oFldI:aDialogs[ i ]:nClrPane

   DEFINE FONT ofont NAME "Verdana" Size 0,-14

   @ 02,025 SAY "Color"     OF oER:oFldI:aDialogs[ i ] FONT oFont PIXEL TRANSPARENT
   @ 02,095 SAY "Valor"  OF oER:oFldI:aDialogs[ i ] FONT oFont PIXEL TRANSPARENT

   @ 02,180 SAY "Color"     OF oER:oFldI:aDialogs[ i ] FONT oFont PIXEL TRANSPARENT
   @ 02,250 SAY "Valor"  OF oER:oFldI:aDialogs[ i ] FONT oFont PIXEL TRANSPARENT

   For x = 1 to Len( aColors )
      if x > 15
         nCol := 234
         nFil := 25+(x-1-15)*30
      else
         nFil := 25+(x-1)*30
      endif
      aColorGet[ x ] := TGet():New( nFil, nCol, MiSetGet( aColors, x ), oER:oFldI:aDialogs[ i ], 70, 20, , ,;
                                 ,,,,, .T.,,,,,,,,,,,,,,,,,,, )
      aColorGet[ x ]:bValid := SetMi2Color( aColorSay, aColors,  nDefClr, x )

   Next x

   nCol       := 78
   For x = 1 to Len( aColors )
     if x > 15
        nCol := 234
        nFil := 25+(x-1-15)*30
     else
        nFil := 25+(x-1)*30
     endif

     aColorSay[ x ] := TBtnBmp():New( nFil, nCol - 65, 60, 20,;
                                    ,,,,;
                                    ,oER:oFldI:aDialogs[ i ],,,,,;
                                    ,,,, .F.,,;
                                    ,,,,,;
                                    ,,.T.,)

     aColorSay[ x ]:bAction := SetMi3Color( aColorSay, aColors,  nDefClr, aColorGet, x )


   Next x

   AEval( aColorSay, { | o, n | o:SetColor( 0,;
          If( Empty( aColors[ n ] ), CLR_WHITE, Val( aColors[ n ] ) ) ) } )

   @ nFil + 40 , oER:oFldI:aDialogs[ i ]:nWidth - 100 BTNBMP PROMPT "Grabar" ;
            OF oER:oFldI:aDialogs[ i ] SIZE 80, 20 pixel ;
            ACTION SaveDlgColors( aColors )

RETURN nil

//------------------------------------------------------------------------------

Function Dlg_Fonts( i )
   Local oBrush
   Local oFont
   Local n
   Local nCol       := 78
   Local nFil       := 0
   Local aColors    := GetAllColors()
   Local aColorSay  := Array( Len( aColors ) )
   Local aColorGet  := Array( Len( aColors ) )
   local oDlg
   local oFld
   local oLbx
   local oSay1
   local oGet1
   local nDefClr
   local oIni
   local x
   local aGetFonts  := GetFonts()
   local aShowFonts := GetFontText( aGetFonts )
   local cFont      := aGetFonts [ 1, 1 ]
   local cFontText  := ""
   local oBtn1
   Local oBtn2

   DEFAULT i := 5

   for n := 33 to 254
      cFontText += CHR( n )
   next

   //oER:oFldI:aDialogs[ i ]:SetColor( CLR_BLACK, oEr:nClrPaneTree )
   nDefClr := oER:oFldI:aDialogs[ i ]:nClrPane

   DEFINE FONT oFont NAME "Verdana" Size 0,-14

   /*
   @ 25, 8 LISTBOX oLbx VAR cFont ITEMS aShowFonts OF oER:oFldI:aDialogs[ i ] ;
      SIZE oER:oFldI:aDialogs[ i ]:nWidth - 15, Int( oER:oFldI:aDialogs[ i ]:nHeight / 2 ) ; //+ 80 ;
      FONT oFont PIXEL ;
      ON CHANGE PreviewRefresh( oSay1, oLbx, oGet1 ) ;
      ON DBLCLICK ( aShowFonts := SelectFont( oSay1, oLbx, oGet1 ), oBtn:Enable() )

   oLbx:nDlgCode = DLGC_WANTALLKEYS
   oLbx:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, ;
                                      aShowFonts := SelectFont( oSay1, oLbx ), ) }
   */

   @ 25, 8 XBROWSE oLbx ARRAY aShowFonts  OF oER:oFldI:aDialogs[ i ] ;
      SIZE oER:oFldI:aDialogs[ i ]:nWidth - 15, Int( oER:oFldI:aDialogs[ i ]:nHeight / 2 ) - 5 ;
      FONT oFont PIXEL NOBORDER ;
      ON CHANGE PreviewRefresh( oSay1, oLbx, oGet1 ) ;
      ON DBLCLICK ( aShowFonts := SelectFont( oSay1, oLbx, oGet1 ) )

   oLbx:lRecordSelector     := .F.
   oLbx:lHeader             := .F.

   oLbx:lHScroll            := .F.

   oLbx:CreateFromCode()

   @ 02, 008 SAY GL("Fonts") OF oER:oFldI:aDialogs[ i ] FONT oFont PIXEL TRANSPARENT

   @ 06, 120 SAY "[ "+GL("Doubleclick to edit the font properties")+" ]" OF oER:oFldI:aDialogs[ i ] ;
             SIZE 300, 16 PIXEL TRANSPARENT

   @ Int( oER:oFldI:aDialogs[ i ]:nHeight / 2 ) + 28, 8 SAY GL("Preview")+": " ;
         OF oER:oFldI:aDialogs[ i ] FONT oFont PIXEL TRANSPARENT

   @ Int( oER:oFldI:aDialogs[ i ]:nHeight / 2 ) + 26, 70 SAY oSay1 PROMPT "    " ;
         OF oER:oFldI:aDialogs[ i ] UPDATE FONT oER:aFonts[ 1 ] ;
         SIZE oER:oFldI:aDialogs[ i ]:nWidth - 76, 76 ;
         PIXEL BOX TRANSPARENT

   @ Int( oER:oFldI:aDialogs[ i ]:nHeight / 2 ) + 32, 72 SAY oSay1 PROMPT GL("Test 123") ;
         OF oER:oFldI:aDialogs[ i ] UPDATE FONT oER:aFonts[ 1 ] ;
         SIZE oER:oFldI:aDialogs[ i ]:nWidth - 84, 68 ;
         PIXEL TRANSPARENT CENTER

   @ Int( oER:oFldI:aDialogs[ i ]:nHeight / 2 ) + 110, 8 GET oGet1 VAR cFontText OF oER:oFldI:aDialogs[ i ] ;
            UPDATE FONT oER:aFonts[ 1 ] MEMO ;
            SIZE oER:oFldI:aDialogs[ i ]:nWidth - 15, 116 PIXEL

   @ oER:oFldI:aDialogs[ i ]:nHeight - 40 , oER:oFldI:aDialogs[ i ]:nWidth - 110 BTNBMP oBtn1 ;
            PROMPT GL("Borrar Font") ;
            OF oER:oFldI:aDialogs[ i ] SIZE 100, 20 PIXEL ;
            ACTION ( DelFont( oLbx, .T. ) )

   @ oER:oFldI:aDialogs[ i ]:nHeight - 40, 8  BTNBMP oBtn2 ;
            PROMPT GL("Borrar Todos Fonts") ;
            OF oER:oFldI:aDialogs[ i ] SIZE 100, 20 PIXEL ;
            ACTION ( DelFont( oLbx, .T. ) )

RETURN nil

//------------------------------------------------------------------------------


Function SetMi2Color( aColorSay, aColors,  nDefClr, nPos )
Local bVal
bVal  := { || Set2Color( aColorSay[ nPos ], aColors[ nPos ], nDefClr ) }
Return bVal

//------------------------------------------------------------------------------

Function MiSetGet( aBuffer , n )

Return bSETGET( aBuffer[ n ] )

//------------------------------------------------------------------------------

Function SetMi3Color( aColorSay, aColors,  nDefClr, aColorGet, nPos )
Local bVal
bVal  := { || aColors[ nPos ] := Set3Color( aColorSay[ nPos ], aColors[ nPos ], nDefClr ), aColorGet[ nPos ]:Refresh() }
Return bVal

//------------------------------------------------------------------------------

FUNCTION SaveDlgColors( aColors )
 LOCAL oIni, i

 RndMsg( FwString("Saving Colors ") )

  INI oIni FILE oER:cDefIni
   for i := 1 to Len( aColors )
      if !Empty( aColors[ i ] )
         SET SECTION "Colors" ENTRY AllTrim(STR(i,5)) to aColors[ i ] OF oIni
      endif
   next
   ENDINI

   SetSave( .F. )

   syswait(.3)
   RndMsg()


RETURN nil

//------------------------------------------------------------------------------

/*
Function Dlg_Fonts( i )
   local aGetFonts  := GetFonts()
   local aShowFonts := GetFontText( aGetFonts )
   local cFont      := aGetFonts [1, 1 ]

   local cFontText  := ""
   LOCAL olbx
   LOCAL oSay1, oGet1, oFont
   LOCAL oDlg := oER:oFldI:aDialogs[ i ]

    for i := 33 to 254
      cFontText += CHR( i )
   next

   DEFINE FONT oFont NAME "Verdana" Size 0,-14

   @ 10,010 SAY  GL("Font") OF oDlg FONT oFont PIXEL TRANSPARENT

   @ 032, 10 LISTBOX olbx VAR cFont ITEMS aShowFonts SIZE 300, 360 OF oDlg ;
      ON CHANGE PreviewRefresh( oSay1, oLbx, oGet1 ) ;
      ON DBLCLICK ( aShowFonts := SelectFont( oSay1, oLbx, oGet1 ) ) PIXEL FONT oFont

   oLbx:nDlgCode = DLGC_WANTALLKEYS
   oLbx:bKeyDown = { | nKey, nFlags | IIF( nKey == VK_RETURN, ;
                                          aShowFonts := SelectFont( oSay1, oLbx ), ) }


   @ 380,010 SAY GL("Doubleclick to edit the font properties") OF oDlg ;
             SIZE 300, 160 pixel TRANSPARENT


   @ 410,010 SAY GL("Preview")  OF oDlg FONT oFont PIXEL TRANSPARENT ;
              SIZE 300,30

  @ 430, 10 SAY oSay1 PROMPT "  " OF oDlg ;
                 SIZE 300,100 pixel UPDATE FONT oER:aFonts[ 1 ] TRANSPARENT box

  @ 440 ,20 SAY oSay1 PROMPT  GL("Test 123") OF oDlg ;
                 SIZE 280,80 pixel UPDATE FONT oER:aFonts[ 1 ] TRANSPARENT CENTER

   @ 540,10 GET oGet1 VAR cFontText OF oDlg UPDATE FONT oER:aFonts[ 1 ] MEMO  ;
            SIZE 300, 160 pixel


RETURN nil
*/

//------------------------------------------------------------------------------

function BarMenu()
   LOCAL oBar
   local aBtn[4]
   local lPrompt := ( GetSysMetrics( 0 ) > 800 )
   Local oFont

   DEFINE FONT oFont NAME "Tahoma" SIZE 0,-9

   DEFINE BUTTONBAR oBar OF oEr:oMainWnd SIZE 70, 70 2010
   oBar:SetFont( oFont )


   // oBar:bClrGrad :=  oER:bClrBar

 //  IF oER:nDeveloper == 1

   DEFINE BUTTON aBtn[ 4 ] RESOURCE "New" ;
      OF oBar ;
      PROMPT FWString( "New" ) ;
      TOOLTIP GL("New report") ;
      ACTION NewReport()

//  ENDIF

   DEFINE BUTTON RESOURCE "B_OPEN" ;
      OF oBar ;
      PROMPT FWString( "Open" ) ;
      TOOLTIP GL("Open") ;
      ACTION OpenFile(,,.T.)

   DEFINE BUTTON RESOURCE "B_SAVE", "B_SAVE", "B_SAVE1" ;
      OF oBar ;
      PROMPT FWString( "Save" ) ;
      TOOLTIP GL("Save") ;
      ACTION SaveFile() ;
      WHEN !Empty( oER:cDefIni ) .and. !lVRDSave

  //MENU oMenuPreview POPUP
  //ENDMENU

  DEFINE BUTTON aBtn[ 1 ] RESOURCE "B_PREVIEW", "B_PREVIEW", "B_PREVIEW1" ;
         OF oBar ;
         PROMPT FWString( "Preview" ) ;
         TOOLTIP GL("Preview") ;
         ACTION (  swichFldD( oEr:oMainWnd, oER:oFldD ), ;
                  if( !Print_erReport(,,2, oEr:oMainWnd ), swichFldD( oEr:oMainWnd, oER:oFldD ,.t.), ) );   //   PrintReport( .T., !oGenVar:lStandalone ) ;
         WHEN Empty( oER:cDefIni ) //;
         //MENU oMenuPreview

   DEFINE BUTTON RESOURCE "print", "print", "print1" ;
      OF oBar ;
      PROMPT FWString( "Print" ) ;
      TOOLTIP GL( "Print" ) ;
      ACTION ( swichFldD( oEr:oMainWnd, oER:oFldD ), PrintReport() ) ;
      WHEN !Empty( oER:cDefIni )

   DEFINE BUTTON aBtn[2] RESOURCE "B_UNDO", "B_UNDO", "B_UNDO1" ;
      OF oBar GROUP ;
      PROMPT FWString( "Undo" ) ;
      TOOLTIP STRTRAN( GL("&Undo"), "&" ) ;
      ACTION Undo() ;
      WHEN !Empty( oER:cDefIni ) .and. oER:nUndoCount > 0
      // MENU UndoRedoMenu( 1, aBtn[2] ) ;

   DEFINE BUTTON aBtn[3] RESOURCE "B_REDO", "B_REDO", "B_REDO1" ;
      OF oBar ;
      PROMPT FWString( "Redo" ) ;
      TOOLTIP STRTRAN( GL("&Redo"), "&" ) ;
      ACTION Redo() ;
      WHEN !Empty( oER:cDefIni ) .and. oER:nRedoCount > 0
      // MENU UndoRedoMenu( 2, aBtn[2] ) ;

   DEFINE BUTTON RESOURCE "B_ITEMLIST32", "B_ITEMLIST32", "B_ITEMLIST321"  ;
      OF oBar GROUP ;
      PROMPT FWSTring( "Items" ) ;
      TOOLTIP GL("Area and Item List") ;
      ACTION Itemlist() ;
      WHEN !Empty( oER:cDefIni )

   if Val( oEr:GetDefIni( "General", "EditSetting", "1" ) ) = 1
      DEFINE BUTTON RESOURCE "B_FONTCOLOR32", "B_FONTCOLOR32", "B_FONTCOLOR321"  ;
         OF oBar ;
         PROMPT FWString( "Fonts" ) ;
         TOOLTIP GL("Fonts and Colors") ;
         ACTION FontsAndColors() ;
         WHEN !Empty( oER:cDefIni )
   endif

   if Val( oEr:GetDefIni( "General", "EditAreaProperties", "1" ) ) = 1
      MENU oMenuAreas POPUP
      ENDMENU

      DEFINE BUTTON oBtnAreas RESOURCE "B_AREA32", "B_AREA32", "B_AREA321" ;
         OF oBar ;
         PROMPT FWSTring( "Areas" ) ;
         TOOLTIP GL("Area Properties") ;
         ACTION AreaProperties( oER:nAktArea ) ;
         WHEN !Empty( oER:cDefIni ) ;
         MENU oMenuAreas
   endif

   DEFINE BUTTON RESOURCE "B_EDIT32", "B_EDIT32", "B_EDIT321"  ;
      OF oBar ;
      PROMPT FWString( "Properties" ) ;
      TOOLTIP GL("Item Properties") ;
      ACTION IIF( LEN( oER:aSelection ) <> 0, MultiItemProperties(), ItemProperties( nAktItem, oER:nAktArea ) ) ;
      WHEN !Empty( oER:cDefIni )

   if Val( oEr:GetDefIni( "General", "InsertMode", "1" ) ) = 1
      DEFINE BUTTON RESOURCE "B_TEXT32", "B_TEXT32", "B_TEXT321" ;
         OF oBar GROUP ;
         PROMPT FWString( "&Text" ) ;
         TOOLTIP STRTRAN( GL("Insert &Text"), "&" ) ;
         ACTION NewItem( "TEXT", oER:nAktArea ) ;
         WHEN !Empty( oER:cDefIni )

      DEFINE BUTTON RESOURCE "B_IMAGE32", "B_IMAGE32", "B_IMAGE321";
         OF oBar ;
         PROMPT FWString( "Image" ) ;
         TOOLTIP STRTRAN( GL("&Image"), "&" ) ;
         ACTION NewItem( "IMAGE", oER:nAktArea ) ;
         WHEN !Empty( oER:cDefIni )

      DEFINE BUTTON RESOURCE "B_GRAPHIC32", "B_GRAPHIC32", "B_GRAPHIC321" ;
         OF oBar ;
         PROMPT FWString( "Graphic" ) ;
         TOOLTIP STRTRAN( GL("Insert &Graphic"), "&" ) ;
         ACTION NewItem( "GRAPHIC", oER:nAktArea ) ;
         WHEN !Empty( oER:cDefIni )

      DEFINE BUTTON RESOURCE "B_BARCODE32", "B_BARCODE32", "B_BARCODE321" ;
         OF oBar ;
         PROMPT FWString( "Barcode" ) ;
         TOOLTIP STRTRAN( GL("Insert &Barcode"), "&" ) ;
         ACTION NewItem( "BARCODE", oER:nAktArea ) ;
         WHEN !Empty( oER:cDefIni )
   endif

      DEFINE BUTTON RESOURCE "HIDE0", "HIDE1" ;
                 OF oBar GROUP ;
         PROMPT FWString( "Hide/Show" ) ;
         ACTION ( SwichFldD( oEr:oMainWnd, oEr:oPanelD, )) //oER:oFldD, ) )

   // if Val( GetPvProfString( "General", "ShowExitButton", "0", oER:cGeneralIni ) ) = 1

      DEFINE BUTTON RESOURCE "B_EXIT" ;
         PROMPT FWString( "Exit" ) ;
         OF oBar GROUP ;
         ACTION oEr:oMainWnd:End() TOOLTIP GL("Exit")

   // endif

   oBar:bLClicked := {|| nil }
   oBar:bRClicked := {|| nil }

return oBar

//----------------------------------------------------------------------------//
/*
Function ValidVersionFwh( nVersion1, nVersion2 )
Local lVersion   := .T.

if !empty( nVersion1 ) .and. !empty( nVersion2 )
   if GetFwVersion()[ 1 ] < nVersion1
      lVersion := .F.
   else
      if GetFwVersion()[ 1 ] = nVersion1
         if GetFwVersion()[ 2 ] < nVersion2
            lVersion := .F.
         endif
      endif
   endif
else
   if !empty( nVersion1 ) .and. empty( nVersion2 )
      lVersion := lValidFwh( nVersion1 )
   endif
endif
Return lVersion

//----------------------------------------------------------------------------//

Function GetFwVersion()
Local aVersion := Array( 2 )
      aVersion[ 1 ] := Val( Substr( FWVERSION, 5, 2 ) )
      aVersion[ 2 ] := Val( Right( FWVERSION, 2 ) )
Return aVersion
 */
//----------------------------------------------------------------------------//

Function lValidFwh( nVersion )
DEFAULT nVersion := MINVERSIONFW     //10.08
return IF(  nFwVersion() <  nVersion, .F., .T. )

//----------------------------------------------------------------------------//

FUNCTION nFwVersion()
return Val(Right(AllTrim(FWVERSION),5))

//----------------------------------------------------------------------------//

#define MK_MBUTTON          0x0010

function ER_MouseWheel( nKey, nDelta, nXPos, nYPos )

   local aPoint := { nYPos, nXPos }

   ScreenToClient( oEr:oMainWnd:oWndClient:hWnd, aPoint )
   lScrollVert  := .T.
   if IsOverWnd( oEr:oMainWnd:oWndClient:hWnd, aPoint[ 1 ], aPoint[ 2 ] )

      if lAnd( nKey, MK_MBUTTON )
         if nDelta > 0
            oER:ScrollV(-4, .T. )
         else
            oER:ScrollV(4,, .T.)
         endif
      else
         if nDelta > 0
            oER:ScrollV( - WheelScroll() , .T.,, .T. )
         else
            oER:ScrollV( WheelScroll() ,, .T., .T. )
         endif
      endif

   endif

return .T.

//----------------------------------------------------------------------------//

function ER_MouseWheelTree( nKey, nDelta, nXPos, nYPos )

   local aPoint := { nYPos, nXPos }
   local i      := 0
   local oTemp1
   local nElem  := 0

   ScreenToClient( oEr:oTree:hWnd, aPoint )
   if IsOverWnd( oEr:oTree:hWnd, aPoint[ 1 ], aPoint[ 2 ] )
      /*
      For i = 1 to Len( oER:oTree:aItems )
          // 2 -> hWnd   3 -> Object   4 -> Array   5 -> Caption
          oTemp1 := oER:oTree:aItems[ i ][ 3 ]
          if oTemp1 == oEr:oTree:GetSelected()
             nElem := i
             i := Len( oER:oTree:aItems ) + 1
          endif
      Next i
      */

      if lAnd( nKey, MK_MBUTTON )
         if nDelta > 0
            if !empty( nElem )
               if nElem > 1
                  nElem--

               else
                  nElem := Len( oER:oTree:aItems )
               endif
            endif
         else
            if !empty( nElem )
               if nElem < Len( oER:oTree:aItems )
                  nElem++

               else
                  nElem := 1
               endif
            endif
         endif
      else
         if nDelta > 0
            //if empty( oEr:oTree:oParent )

            //else

            //endif
            if !empty( nElem )
               if nElem > 1
                  nElem--

               else
                  nElem := Len( oER:oTree:aItems )
               endif
            endif
         else
            if !empty( nElem )
               if nElem < Len( oER:oTree:aItems )
                  nElem++

               else
                  nElem := 1
               endif
            endif
         endif
      endif

      if !empty( nElem )
         oEr:oTree:Select( oER:oTree:aItems[ nElem ][ 3 ] )
         //oEr:oTree:Refresh()
      endif

   endif

return .T.

//----------------------------------------------------------------------------//

/*
function ER_MouseWheel( nKey, nDelta, nXPos, nYPos )

   local aPoint := { nYPos, nXPos }

   ScreenToClient( oEr:oMainWnd:oWndClient:hWnd, aPoint )
   lScrollVert  := .T.
   if IsOverWnd( oEr:oMainWnd:oWndClient:hWnd, aPoint[ 1 ], aPoint[ 2 ] )
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
*/
//----------------------------------------------------------------------------//

function PreviewMenu( oBtn )

   local oMenu
   local aRect := GetClientRect( oBtn:hWnd )

   MENU oMenu POPUP

      MENUITEM GL("Pre&view") + chr(9) + GL("Ctrl+P") ;
         ACCELERATOR ACC_CONTROL, ASC( GL("P") ) ;
         ACTION PrintReport( .T. ) ;
         WHEN !Empty( oER:cDefIni )
      MENUITEM GL("&Developer Preview") ;
         ACTION PrintReport( .T., .T. ) ;
         WHEN !Empty( oER:cDefIni )

   ENDMENU

   ACTIVATE POPUP oMenu AT aRect[3], aRect[2] OF oBtn

return( oMenu )

//----------------------------------------------------------------------------//

function StartMessage()

   if oER:lBeta
      BetaVersion()
   else
      if lPersonal
         lProfi := .T.
      endif
  endif

return .T.

//------------------------------------------------------------------------------

function BetaVersion()

   local oDlg, oFont
   local nClrBack := RGB( 255, 255, 255 )

   DEFINE FONT oFont  NAME "Ms Sans Serif" SIZE 0, -14

   DEFINE DIALOG oDlg NAME "MSGBETA" COLOR 0, nClrBack

   REDEFINE SAY PROMPT "- BETA VERSION -" ID 204 OF oDlg FONT oFont COLOR 0, nClrBack

   REDEFINE SAY PROMPT "This is a beta version of EasyReport. Please let me" ID 201 OF oDlg FONT oFont COLOR 0, nClrBack
   REDEFINE SAY PROMPT "know if you have any problems or suggestions."       ID 202 OF oDlg FONT oFont COLOR 0, nClrBack

   REDEFINE BITMAP ID 301 OF oDlg RESOURCE "LOGO"

   REDEFINE BUTTON ID 101 OF oDlg ACTION oDlg:End()

   ACTIVATE DIALOG oDlg CENTER

   oFont:End()

return NIL


//----------------------------------------------------------------------------//

function DeclarePublics( cDefFile )
   local oIni

   PUBLIC lProfi := .T.

   oER:lBeta := .F.

   lPersonal := .F.
   if lPersonal
      lProfi := .T.
   endif

   PUBLIC oBar
   PUBLIC cLongDefIni, cDefaultPath

   //PUBLIC nTotalHeight := 0
   //PUBLIC nTotalWidth  := 0

   //
   PUBLIC nAktItem := 0
   //PUBLIC nAktArea := 1
   PUBLIC nSelArea := 0
   //PUBLIC aSelection := {}

   oER:nAktArea := 1

   //Sichern
   PUBLIC aVRDSave[102, 2 ]
   PUBLIC lVRDSave    := .T.
   //PUBLIC lFillWindow := .F.

   //cut, copy and paste
   PUBLIC cItemCopy    := ""

   PUBLIC aSelectCopy  := {}
   PUBLIC aItemCopy    := {}

   //developer mode
   oER:nDeveloper := 0

   //Items bewegen
   PUBLIC nXMove := 0
   PUBLIC nYMove := 0

   //Undo/Redo
   oEr:nUndoCount := 0
   oER:nRedoCount := 0

   //Structure-Variable
   PUBLIC oGenVar := TExStruct():New()

   oEr:nTotalHeight   := 0
   oEr:nTotalWidth    := 0

   //Ruler anzeigen
   oEr:nRuler         := 20
   oEr:nRulerTop      := 37

   //Voreinstellungen holen

   IF  Empty(oEr:GetGeneralIni(  "Languages", "1" ) )
       INI oIni FILE oER:cGeneralIni
         SET SECTION "Languages" ENTRY "1" TO "English" OF oIni
         SET SECTION "Languages" ENTRY "2" to "German"  OF oIni
         SET SECTION "Languages" ENTRY "3" to "Italian" OF oIni
         SET SECTION "Languages" ENTRY "4" to "Spanish" OF oIni
         SET SECTION "Languages" ENTRY "5" to "Portuguese" OF oIni
         SET SECTION "Languages" ENTRY "6" to "Portuguese Brazilian" OF oIni
         SET SECTION "Languages" ENTRY "7" to "French" OF oIni
       ENDINI
   endif

   oER:cDefIni      := VRD_LF2SF( cDefFile )
   cLongDefIni      := cDefFile
   cDefaultPath     := CheckPath(  oEr:GetGeneralIni( "General", "DefaultPath", "" ) )

   oEr:lShowPanel   := ( oEr:GetGeneralIni( "General", "ShowPanel", "1" ) == "1" )

   oEr:lShowToolTip := .T.

   oER:lDClkProperties := oEr:lShowPanel

  // oER:lDClkProperties := .f.

   if AT( "\", oER:cDefIni ) = 0 .and. !Empty( oER:cDefIni )
      oER:cDefIni   := ".\" + oER:cDefIni
   endif

   oER:cDefIniPath := CheckPath( cFilePath( oER:cDefIni ) )

   oGenVar:AddMember( "cRelease"  ,, "2.1.1" )
   oGenVar:AddMember( "cCopyright",, "2000-2014" )

   oGenVar:AddMember( "aLanguages",, {} )
   oGenVar:AddMember( "nLanguage" ,, Val( oEr:GetGeneralIni(  "General", "Language", "1" ) )  )


   //Sprachdatei
   OpenLanguage()

   oER:aWnd         := Array( oER:nTotAreas )
   oER:aWndTitle    := Array( Len( oER:aWnd ) )
   oEr:aItems       := Array( Len( oER:aWnd ), 1000 )
   oER:aAreaIni     := Array( Len( oER:aWnd ) )
   oER:aRuler       := Array( Len( oER:aWnd ), 2 )
   oER:aSelection   := {}   // Array( Len( aWnd ), 2 )
   oER:aFonts       := Array( 20 )

   oEr:nDeveloper := Val( oEr:GetGeneralIni( "General", "DeveloperMode", "0" ) )

   oGenVar:AddMember( "nClrReticule" ,, IniColor(  oEr:GetGeneralIni( "General", "ReticuleColor", " 50,  50,  50" ) ) )
   oGenVar:AddMember( "lShowReticule",, ( oEr:GetGeneralIni( "General", "ShowReticule", "1" ) = "1" ) )

   oGenVar:AddMember( "aDBFile",, {} )

   oGenVar:AddMember( "lStandalone",, .F. )
   oGenVar:AddMember( "lShowGrid"  ,, .F. )
   oGenVar:AddMember( "nGridWidth" ,, 1   )
   oGenVar:AddMember( "nGridHeight",, 1   )

   if !Empty( oER:cDefIni )

   endif

   oGenVar:AddMember( "nClrArea"  ,, IniColor( oEr:GetGeneralIni( "General", "AreaBackColor", "240, 247, 255" ) ) )

   oGenVar:AddMember( "cBrush"    ,, AllTrim( oEr:GetGeneralIni( "General", "BackgroundBrush", "" ) ) )
   oGenVar:AddMember( "cBarBrush" ,, AllTrim( oEr:GetGeneralIni( "General", "ButtonbarBrush" , "" ) ) )
   oGenVar:AddMember( "cBrushArea" ,,  oEr:GetGeneralIni( "General", "AreaBackBrush"     , "" ) )

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

   oGenVar:AddMember( "nBClrAreaTitle" ,, IniColor(  oEr:GetGeneralIni( "General", "AreaTitleBackColor" , "204, 214, 228" ) ) )
   oGenVar:AddMember( "nF1ClrAreaTitle",, IniColor(  oEr:GetGeneralIni( "General", "AreaTitleForeColor1", "111, 111, 111" ) ) )
   oGenVar:AddMember( "nF2ClrAreaTitle",, IniColor(  oEr:GetGeneralIni( "General", "AreaTitleForeColor2", " 50,  50,  50" ) ) )

   oGenVar:AddMember( "nFocusGetBackClr",, IniColor(  oEr:GetGeneralIni( "General", "FocusGetBackClr", "0" ) ) )

   oGenVar:AddMember( "lSelectItems"   ,, .F. )

   oGenVar:AddMember( "lFixedAreaWidth",, (  oEr:GetGeneralIni( "General", "AreaWidthFixed", "1" ) = "1" ) )

   oGenVar:AddMember( "aAreaTitle",, ARRAY( Len( oER:aWnd ) ) )
   oGenVar:AddMember( "aAreaHide" ,, ARRAY( Len( oER:aWnd ) ) )
   oGenVar:AddMember( "aAreaSizes",, ARRAY( Len( oER:aWnd ), 2 ) )
   AFILL( oGenVar:aAreaHide, .F. )

   oGenVar:AddMember( "aAppFonts",, ARRAY(2) )

   DEFINE FONT oGenVar:aAppFonts[ 1 ] NAME GetSysFont() SIZE 0,-11 BOLD
   DEFINE FONT oGenVar:aAppFonts[ 2 ] NAME GetSysFont() SIZE 0,-10 BOLD

   oGenVar:AddMember( "lItemDlg",, .F. )
   oGenVar:AddMember( "lDlgSave",, .F. )
   oGenVar:AddMember( "nDlgTop" ,, Val( oEr:GetGeneralIni( "ItemDialog", "Top" , "0") ) )
   oGenVar:AddMember( "nDlgLeft",, Val( oEr:GetGeneralIni( "ItemDialog", "Left", "0" ) ) )

   oGenVar:AddMember( "lShowBorder",, ( oEr:GetGeneralIni( "General", "ShowTextBorder", "1" ) = "1" ) )

   oGenVar:AddMember( "cLoadFile" ,, "" )
   oGenVar:AddMember( "lFirstFile",, .T. )

   lScrollVert  := .F.

return .T.

//----------------------------------------------------------------------------//

function SetGeneralSettings()

   LOCAL aMeasure := { GL("mm"), GL("inch") , GL("Pixel") }

   oER:nMeasure := Val( oEr:GetDefIni( "General", "Measure", "1" ) )

   oER:cMeasure := aMeasure [ oER:nMeasure ]

   oEr:nDeveloper := Val( oEr:GetDefIni( "General", "DeveloperMode", STR( oER:nDeveloper, 1 )  ) )

   oGenVar:lStandalone := ( oEr:GetDefIni( "General", "Standalone"   , "0" ) = "1" )
   oGenVar:lShowGrid   := ( oEr:GetDefIni( "General", "ShowGrid"     , "0" ) = "1" )
   oGenVar:nGridWidth  := Val( oEr:GetDefIni( "General", "GridWidth" , "1" ) )
   oGenVar:nGridHeight := Val( oEr:GetDefIni( "General", "GridHeight", "1" ) )
   nXMove := ER_GetPixel( oGenVar:nGridWidth )
   nYMove := ER_GetPixel( oGenVar:nGridHeight )

   OpenDatabases()

return .T.

//----------------------------------------------------------------------------//

function IniMainWindow()

   if !Empty( oER:cDefIni )

      oGenVar:lFirstFile := .F.

      DefineFonts()
      //Design windows
      ClientWindows()
      //Areas anzeigen
      ShowAreasOnBar()
      //Mru erstellen
      if Val( GetPvProfString( "General", "MruList"  , "4", oER:cGeneralIni ) ) > 0
         oER:oMru:Save( cLongDefIni )
      endif
      CreateBackup()
   endif

return .T.

//----------------------------------------------------------------------------//

function SetMainWnd()

   if Val( GetPvProfString( "General", "Maximize", "1", oER:cGeneralIni ) ) = 1
      oEr:oMainWnd:Maximize()
      //SysRefresh()
   endif

return .T.

//----------------------------------------------------------------------------//

function SetWinNull()

   local i
   local nAltPos := oER:aWnd[oER:nAktArea]:nTop

   for i := 1 to Len( oER:aWnd )
      if oER:aWnd[ i ] <> nil
         oER:aWnd[ i ]:Move( oER:aWnd[ i ]:nTop - nAltPos, oER:aWnd[ i ]:nLeft, 0, 0, .T. )
      endif
   next

return .T.

//----------------------------------------------------------------------------//

function ShowAreasOnBar()

   local n

   if oMenuAreas != nil
      oMenuAreas:End()
   endif

   MENU oMenuAreas POPUP
      for n = 1 to Len( oER:aWndTitle )
         if ! Empty( oER:aWndTitle[ n ] )
            MENUITEM oER:aWndTitle[ n ] ;
               ACTION ( oER:nAktArea:= AScan( oER:aWndTitle, oMenuItem:cPrompt ) , ;
                        oER:aWnd[ oER:nAktArea ]:SetFocus(), SetWinNull() )
         endif
      next
   ENDMENU

   oBtnAreas:oPopup := oMenuAreas

   oER:aWnd[ AScan( oER:aWnd, { |x| x != nil } ) ]:SetFocus()

return .T.

//----------------------------------------------------------------------------//

function BuildMenu()

   local oMenu
   local nMruList := Val( GetPvProfString( "General", "MruList"  , "4", oER:cGeneralIni ) )

   MENU oMenu 2007
   MENUITEM GL("&File")
   MENU
   if oER:nDeveloper = 1
      MENUITEM GL("&New") ;
         ACTION NewReport()
   endif
   MENUITEM GL("&Open") + chr(9) + GL("Ctrl+O") RESOURCE "B_OPEN_16" ;
      ACCELERATOR ACC_CONTROL, ASC( GL("O") ) ;
      ACTION OpenFile(,,.T.)
   SEPARATOR
   MENUITEM GL("&Save") + chr(9) + GL("Ctrl+S") RESOURCE "B_SAVE_16" ;
      ACCELERATOR ACC_CONTROL, ASC( GL("S") ) ;
      ACTION SaveFile() ;
      WHEN !Empty( oER:cDefIni ) .and. !lVRDSave
   MENUITEM GL("Save &as") ;
      ACTION SaveAsFile() ;
      WHEN !Empty( oER:cDefIni )
   //SEPARATOR
   SEPARATOR
      MENUITEM GL("&Preferences") ;
          ACTION oEr:SetGeneralPreferences()

   MENUITEM GL("&File Informations") ;
      ACTION FileInfos() ;
      WHEN !Empty( oER:cDefIni )

   SEPARATOR
   if Val( oEr:GetDefIni( "General", "Standalone", "0" ) ) == 1
      MENUITEM GL("Pre&view") + chr(9) + GL("Ctrl+P") RESOURCE "B_PREVIEW" ;
         ACCELERATOR ACC_CONTROL, ASC( GL("P") ) ;
         ACTION PrintReport( .T. ) ;
         WHEN !Empty( oER:cDefIni )
   endif
   if oER:nDeveloper = 1
      MENUITEM GL("&Developer Preview") ;
         ACTION PrintReport( .T., .T. ) ;
         WHEN !Empty( oER:cDefIni )
   endif

   MENUITEM GL("&Print") RESOURCE "print16" ;
         ACTION PrintReport() ;
         WHEN !Empty( oER:cDefIni )

   MRU oER:oMru FILENAME oER:cGeneralIni ;
            SECTION  "MRU" ;
            ACTION   OpenFile( cMruItem, , .T. ) ;
            SIZE     Val( oEr:GetGeneralIni( "General", "MruList"  , "4" ) )
   SEPARATOR
   MENUITEM GL("&Exit") RESOURCE "B_EXIT_16" ;
      ACTION oEr:oMainWnd:End()
   ENDMENU

   MENUITEM GL("&Edit")
   MENU
   MENUITEM GL("&Undo") + chr(9) + GL("Ctrl+Z") RESOURCE "B_UNDO_16" ;
      ACTION Undo() ;
      ACCELERATOR ACC_CONTROL, ASC( GL("Z") ) ;
      WHEN !Empty( oER:cDefIni ) .and. oER:nUndoCount > 0
   MENUITEM GL("&Redo") + chr(9) + GL("Ctrl+Y") RESOURCE "B_REDO_16" ;
      ACTION Redo() ;
      ACCELERATOR ACC_CONTROL, ASC( GL("Y") ) ;
      WHEN !Empty( oER:cDefIni ) .and. oER:nRedoCount > 0
   SEPARATOR

   MENUITEM GL("Cu&t") + chr(9) + GL("Ctrl+X") ;
      ACTION ( ItemCopy( .T. ), nAktItem := 0 ) ;
      ACCELERATOR ACC_CONTROL, ASC( GL("X") ) ;
      WHEN !Empty( oER:cDefIni )
   MENUITEM GL("&Copy") + chr(9) + GL("Ctrl+C") ;
      ACTION ItemCopy( .F. ) ;
      ACCELERATOR ACC_CONTROL, ASC( GL("C") ) ;
      WHEN !Empty( oER:cDefIni )
   MENUITEM GL("&Paste") + chr(9) + GL("Ctrl+V") ;
      ACTION ItemPaste()  ;
      ACCELERATOR ACC_CONTROL, ASC( GL("V") ) ;
      WHEN !Empty( oER:cDefIni ) .and. !Empty( cItemCopy )
   SEPARATOR

   if Val( oEr:GetDefIni( "General", "InsertAreas", "1" ) ) <> 1
      if Val( oEr:GetDefIni( "General", "EditAreaProperties", "1" ) ) = 1
         MENUITEM GL("&Area Properties") + chr(9) + GL("Ctrl+A") RESOURCE "B_AREA" ;
            ACTION AreaProperties( oER:nAktArea ) ;
            ACCELERATOR ACC_CONTROL, ASC( GL("A") ) ;
            WHEN !Empty( oER:cDefIni )
         SEPARATOR
      endif
   endif

   MENUITEM GL("Select all Items") ;
      ACTION SelectAllItems() WHEN !Empty( oER:cDefIni )
   MENUITEM GL("Select all Items in current Area") ;
      ACTION SelectAllItems( .T. ) WHEN !Empty( oER:cDefIni )
   MENUITEM GL("Invert Selection") ;
      ACTION InvertSelection() WHEN !Empty( oER:cDefIni )
   MENUITEM GL("Invert Selection in current Area") ;
      ACTION InvertSelection( .T. ) WHEN !Empty( oER:cDefIni )
   SEPARATOR
   MENUITEM GL("Delete in current Area") WHEN !Empty( oER:cDefIni )
      MENU
      MENUITEM GL("&Text")    ACTION DeleteAllItems( 1 )
      MENUITEM GL("I&mage")   ACTION DeleteAllItems( 2 )
      MENUITEM GL("&Graphic") ACTION DeleteAllItems( 3 )
      MENUITEM GL("&Barcode") ACTION DeleteAllItems( 4 )
      ENDMENU
   ENDMENU

   if Val( oEr:GetDefIni( "General", "InsertMode", "1" ) ) = 1

      MENUITEM GL("&Items")
      MENU
      MENUITEM GL("Insert &Text") + chr(9) + GL("Ctrl+T") RESOURCE "B_TEXT" ;
         ACCELERATOR ACC_CONTROL, ASC( GL("T") ) ;
         ACTION NewItem( "TEXT", oER:nAktArea ) ;
         WHEN !Empty( oER:cDefIni )
      MENUITEM GL("Insert &Image") + chr(9) + GL("Ctrl+M") RESOURCE "B_IMAGE" ;
         ACCELERATOR ACC_CONTROL, ASC( GL("M") ) ;
         ACTION NewItem( "IMAGE", oER:nAktArea ) ;
         WHEN !Empty( oER:cDefIni )
      MENUITEM GL("Insert &Graphic") + chr(9) + GL("Ctrl+G") RESOURCE "B_GRAPHIC" ;
         ACCELERATOR ACC_CONTROL, ASC( GL("G") ) ;
         ACTION NewItem( "GRAPHIC", oER:nAktArea ) ;
         WHEN !Empty( oER:cDefIni )
      MENUITEM GL("Insert &Barcode") + chr(9) + GL("Ctrl+B") RESOURCE "B_BARCODE" ;
         ACCELERATOR ACC_CONTROL, ASC( ("B") ) ;
         ACTION NewItem( "BARCODE", oER:nAktArea ) ;
         WHEN !Empty( oER:cDefIni )
      SEPARATOR
      MENUITEM GL("&Item Properties") + chr(9) + GL("Ctrl+I") RESOURCE "B_EDIT" ;
         ACTION IIF( LEN( oER:aSelection ) <> 0, MultiItemProperties(), ItemProperties( nAktItem, oER:nAktArea ) ) ;
         ACCELERATOR ACC_CONTROL, ASC( GL("I") ) ;
         WHEN !Empty( oER:cDefIni )
      ENDMENU


   if Val( oEr:GetDefIni( "General", "InsertAreas", "1" ) ) = 1
      MENUITEM GL("&Areas")
      MENU
      MENUITEM GL("Insert Area &before") ACTION InsertArea( .T., STRTRAN( GL("Insert Area &before"), "&" ) )
      MENUITEM GL("Insert Area &after" ) ACTION InsertArea( .F., STRTRAN( GL("Insert Area &after" ), "&" ) )
      SEPARATOR
      MENUITEM GL("&Delete current Area") ACTION DeleteArea()
      SEPARATOR
      if Val( oEr:GetDefIni( "General", "EditAreaProperties", "1" ) ) = 1
         MENUITEM GL("&Area Properties") + chr(9) + GL("Ctrl+A") RESOURCE "B_AREA" ;
            ACTION AreaProperties( oER:nAktArea ) ;
            ACCELERATOR ACC_CONTROL, ASC( GL("A") ) ;
            WHEN !Empty( oER:cDefIni )
      endif
      ENDMENU
      endif

   endif

   MENUITEM GL("&Extras")
   MENU
   MENUITEM GL("Area and Item &List") + chr(9) + GL("Ctrl+L") RESOURCE "B_ITEMLIST" ;
      ACTION Itemlist() ;
      ACCELERATOR ACC_CONTROL, ASC( GL("L") ) ;
      WHEN !Empty( oER:cDefIni )
   if Val( oEr:GetDefIni( "General", "EditProperties", "1" ) ) = 1
      MENUITEM GL("&Fonts and Colors") + chr(9) + GL("Ctrl+F") RESOURCE "B_FONTCOLOR" ;
         ACTION FontsAndColors() ;
         ACCELERATOR ACC_CONTROL, ASC( GL("F") ) ;
         WHEN !Empty( oER:cDefIni )
   endif
   SEPARATOR
   if Val( oEr:GetDefIni( "General", "Expressions", "0" ) ) > 0
      MENUITEM GL("&Expressions") ;
         ACTION Expressions() ;
         WHEN !Empty( oER:cDefIni )
   endif
   if Val( oEr:GetDefIni( "General", "EditDatabases", "1" ) ) > 0
      MENUITEM GL("&Databases") ;
         ACTION Databases() ;   //Er_Databases()
         WHEN !Empty( oER:cDefIni )
   endif
   MENUITEM GL("&Report Settings") ;
      ACTION ReportSettings() ;
      WHEN !Empty( oER:cDefIni )
   SEPARATOR
   if Val( oEr:GetDefIni( "General", "EditLanguage", "0" ) ) = 1
      MENUITEM GL("Edit &Language") ;
         ACTION EditLanguage()
   endif
   MENUITEM GL("&Grid Settings") ;
      ACTION SetGrid() ; // Options()  ;
      WHEN !Empty( oER:cDefIni )
   ENDMENU

   if Val( oEr:GetDefIni( "General", "Help", "1" ) ) = 1
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

   MENUITEM GL("&About") ;
      ACTION Msginfo( "easyreport for FW" )
   ENDMENU

   ENDMENU


return( oMenu )

//----------------------------------------------------------------------------//

function PopupMenu( nArea, oItem, nRow, nCol, lItem )

   local oMenu

   DEFAULT lItem := .F.

   MENU oMenu POPUP

   if LEN( oER:aSelection ) <> 0 .OR. nAktItem <> 0
      MENUITEM GL("&Item Properties") + chr(9) + GL("Ctrl+I") RESOURCE "B_EDIT" ;
      ACTION IIF( LEN( oER:aSelection ) <> 0, MultiItemProperties(), ItemProperties( nAktItem, oER:nAktArea ) )
   endif

   if LEN( oER:aSelection ) <> 0
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
      ACTION ( oER:aWnd[ nArea ]:SetFocus(), AreaProperties( oER:nAktArea ) )
   MENUITEM GL("Insert Area &before") ACTION InsertArea( .T., STRTRAN( GL("Insert Area &before"), "&" ) )

   MENUITEM GL("Insert Area &after" ) ACTION InsertArea( .F., STRTRAN( GL("Insert Area &after" ), "&" ) )

   MENUITEM GL("&Delete current Area") ACTION DeleteArea()

   SEPARATOR

   MENUITEM GL("&Report Settings") ACTION ReportSettings()
   MENUITEM GL("Grid Setting")         ACTION SetGrid()  //Options()
   MENUITEM GL("Preferences")         ACTION oEr:SetGeneralPreferences()

   if Val( oEr:GetGeneralIni( "General", "Help", "1" ) ) = 1
      SEPARATOR
      MENUITEM GL("&Help Topics") + CHR(9) + GL("F1") ACTION WinHelp( "VRD.HLP" )
   endif

   if oER:nDeveloper = 1
      SEPARATOR
      MENUITEM GL("&Generate Source Code") ACTION GenerateSource( nArea )
   endif

   SEPARATOR

   MENUITEM GL("&Paste") + chr(9) + GL("Ctrl+V") ;
      ACTION ItemPaste() ;
      WHEN !Empty( cItemCopy )

   ENDMENU

   ACTIVATE POPUP oMenu OF IIF( lItem = .T., oItem, oER:aWnd[ nArea ] ) AT nRow, nCol

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
               IIF( AT( "\", cFile ) = 0 .and. !Empty( cDir ), ;
                  cFile := cDir + "\" + cFile, ), ;
               oGet1:Refresh() )

   ACTIVATE DIALOG oDlg CENTER ;
      ON INIT( oRad1:aItems[ 1 ]:SetText( GL("Copy to clipboard") ), ;
               oRad1:aItems[2]:SetText( GL("Copy to file") + ":" ) )

   if lGenerate

      cAreaDef := oEr:GetDefIni( "Areas", AllTrim(STR(nArea,5)) , "" )
      cAreaDef := VRD_LF2SF( AllTrim( cAreaDef ) )

      cAreaTitle := AllTrim( GetPvProfString( "General", "Title" , "", oER:aAreaIni[ nArea ] ) )

      if !Empty( cAreaTitle )
         cSource += SPACE(3) + "//--- Area: " + cAreaTitle + " ---" + CRLF
      endif

      for i := 1 to 1000

         cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(i,5)) , "", oER:aAreaIni[ nArea ] ) )

         if !Empty( cItemDef )
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

         OpenClipboard( oEr:oMainWnd:hWnd )
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
   local aIniEntries   := GetIniSection( "Areas", oER:cDefIni )
   local cAreaFilesDir := CheckPath( oEr:GetDefIni( "General", "AreaFilesDir", "" ) )
   local lReticule

   nDemoWidth := 0



      aVRDSave := ARRAY( 102, 2 )

      aVRDSave[101, 1 ] := oER:cDefIni
      aVRDSave[101, 2 ] := MEMOREAD( oER:cDefIni )
      aVRDSave[102, 1 ] := oER:cGeneralIni
      aVRDSave[102, 2 ] := MEMOREAD( oER:cGeneralIni )


   IF oER:lNewFormat

        for i := 1 to LEN( aIniEntries )
           nWnd := EntryNr( aIniEntries[ i ] )
           cItemDef := GetIniEntry( aIniEntries,, "",, i )
           if nWnd != 0 .and. !Empty( cItemDef )
               if lFirstWnd = .F.
                   oER:nAktArea := nWnd
                   lFirstWnd := .T.
                endif

                  aVRDSave[nWnd, 1 ] := cItemDef
            //    aVRDSave[nWnd, 2 ] := MEMOREAD( cItemDef )
                  nWindowNr += 1
                  oER:aAreaIni[nWnd] :=  cItemDef


           cTitle  :=   AllTrim(GetDataArea( "General", "Title","", cItemDef ))

           oGenVar:aAreaSizes[nWnd] := ;
            { Val( GetPvProfString( cItemDef+"General", "Width", "600", oER:cDefIni ) ), ;
              Val( GetPvProfString( cItemDef+"General", "Height", "300", oER:cDefIni) ) }

             nWidth  := ER_GetPixel( oGenVar:aAreaSizes[nWnd, 1 ] )
             nHeight := ER_GetPixel( oGenVar:aAreaSizes[nWnd, 2 ] )


         IF oER:lShowPanel

            nWidth += oEr:nRuler + nAreaZugabe2
            nDemoWidth := Max( nDemoWidth, nWidth )

            oER:aWnd[ nWnd ] = ER_MdiChild():New( nTop, oEr:oMainWnd:oWndClient:nLeft + 1 , nHeight + nAreaZugabe,;
                            nDemoWidth, cTitle, nOr( WS_BORDER ),, oEr:oMainWnd,, .F.,,,,;
                            oGenVar:oAreaBrush, .T., .F. ,,, , , , , 1 )


         ELSE

            nDemoWidth := nWidth
            if oGenVar:lFixedAreaWidth
               nWidth := GetSysMetrics( 0 ) - 342  //1200
            else
               nWidth += oER:nRuler + nAreaZugabe2
            endif

            oER:aWnd[ nWnd ] = ER_MdiChild():New( nTop, 0, nHeight + nAreaZugabe,;
                            nWidth, cTitle, nOr( WS_BORDER ),, oEr:oMainWnd,, .T.,,,,;
                            oGenVar:oAreaBrush, .T. )

         ENDIF


         oER:aWnd[ nWnd ]:nArea = nWnd

         oER:aWndTitle[ nWnd ] = cTitle

         lReticule = oGenVar:lShowReticule
         oGenVar:lShowReticule = .F.

         oER:FillWindow( nWnd, oER:aAreaIni[nWnd] )

         ACTIVATE WINDOW oER:aWnd[ nWnd ] VALID !GETKEYSTATE( VK_ESCAPE )

         oGenVar:lShowReticule := lReticule

         nTop += nHeight + nAreaZugabe

       endif

        next

     else


     for i := 1 to LEN( aIniEntries )

      nWnd := EntryNr( aIniEntries[ i ] )
      cItemDef := GetIniEntry( aIniEntries,, "",, i )

      if nWnd <> 0 .and. !Empty( cItemDef )

         if lFirstWnd = .F.
            oER:nAktArea := nWnd
            lFirstWnd := .T.
         endif

         if Empty( cAreaFilesDir )
            cAreaFilesDir := cDefaultPath
         endif
         if Empty( cAreaFilesDir )
            cAreaFilesDir := oER:cDefIniPath
         endif


         cItemDef := VRD_LF2SF( AllTrim( cAreaFilesDir + cItemDef ) )

         aVRDSave[nWnd, 1 ] := cItemDef
         aVRDSave[nWnd, 2 ] := MEMOREAD( cItemDef )

         nWindowNr += 1
         oER:aAreaIni[nWnd] := IIF( AT( "\", cItemDef ) = 0, ".\", "" ) + cItemDef

         cTitle  := AllTrim( GetPvProfString( "General", "Title" , "", oER:aAreaIni[nWnd] ) )

         oGenVar:aAreaSizes[nWnd] := ;
            { Val( GetPvProfString( "General", "Width", "600", oER:aAreaIni[nWnd] ) ), ;
              Val( GetPvProfString( "General", "Height", "300", oER:aAreaIni[nWnd] ) ) }

         nWidth  := ER_GetPixel( oGenVar:aAreaSizes[nWnd, 1 ] )
         nHeight := ER_GetPixel( oGenVar:aAreaSizes[nWnd, 2 ] )

         IF oER:lShowPanel

            nWidth += oEr:nRuler + nAreaZugabe2
            nDemoWidth := Max( nDemoWidth, nWidth )

            oER:aWnd[ nWnd ] = ER_MdiChild():New( nTop, oEr:oMainWnd:oWndClient:nLeft + 1 , nHeight + nAreaZugabe,;
                            nDemoWidth, cTitle, nOr( WS_BORDER ),, oEr:oMainWnd,, .F.,,,,;
                            oGenVar:oAreaBrush, .T., .F. ,,, , , , , 1 )


         ELSE

            nDemoWidth := nWidth
            if oGenVar:lFixedAreaWidth
               nWidth := GetSysMetrics( 0 ) - 342  //1200
            else
               nWidth += oER:nRuler + nAreaZugabe2
            endif

            oER:aWnd[ nWnd ] = ER_MdiChild():New( nTop, 0, nHeight + nAreaZugabe,;
                            nWidth, cTitle, nOr( WS_BORDER ),, oEr:oMainWnd,, .T.,,,,;
                            oGenVar:oAreaBrush, .T. )

         ENDIF


         oER:aWnd[ nWnd ]:nArea = nWnd

         oER:aWndTitle[ nWnd ] = cTitle

         lReticule = oGenVar:lShowReticule
         oGenVar:lShowReticule = .F.

         oER:FillWindow( nWnd, oER:aAreaIni[nWnd] )

         ACTIVATE WINDOW oER:aWnd[ nWnd ] VALID !GETKEYSTATE( VK_ESCAPE )

         oGenVar:lShowReticule := lReticule

         nTop += nHeight + nAreaZugabe

      endif


   next
ENDIF

   oEr:nTotalHeight := nTop
   oEr:nTotalWidth  := nWidth

   IF oER:lShowPanel
      ItemList()
   ENDIF

return .T.


//----------------------------------------------------------------------------//
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

function SetTitleColor( lOff, nArea )
Local nColor := if( lOff, oGenVar:nF2ClrAreaTitle , oGenVar:nF1ClrAreaTitle )
Local nAr    := if( lOff, nArea, oER:nAktArea )

   oGenVar:aAreaTitle[ nAr ]:SetColor( nColor, oGenVar:nBClrAreaTitle )
   oGenVar:aAreaTitle[ nAr ]:Refresh()

return .T.

//----------------------------------------------------------------------------//

function ZeichneHintergrund( nArea )

   local nWidth  := ER_GetPixel( oGenVar:aAreaSizes[ nArea, 1 ] )
   local nHeight := ER_GetPixel( oGenVar:aAreaSizes[ nArea, 2 ] )

   SetGridSize( ER_GetPixel( oGenVar:nGridWidth ), ER_GetPixel( oGenVar:nGridHeight ) )

   //Hintergrund
   Rectangle( oER:aWnd[ nArea ]:hDC, ;
              oEr:nRulerTop, oEr:nRuler, oEr:nRulerTop + nHeight + 1, oEr:nRuler + nWidth + 1 )

   //Grid zeichnen
   if oGenVar:lShowGrid
      ShowGrid( oER:aWnd[ nArea ]:hDC, oER:aWnd[ nArea ]:cPS, ;
                ER_GetPixel( oGenVar:nGridWidth ), ER_GetPixel( oGenVar:nGridHeight ), ;
                nWidth, nHeight, oEr:nRulerTop, oEr:nRuler )
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

   if LEN( oER:aSelection ) = 0
      return(.F.)
   endif

   //Delete item
   if nKey == VK_DELETE
      DelselectItems()
   endif

   //return to edit properties
   if nKey == VK_RETURN .and. LEN( oER:aSelection ) <> 0
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

   if lMove

      UnSelectAll( .F. )

      for i := 1 to LEN( oER:aSelection )

         if oER:aItems[ oER:aSelection[i, 1 ], oER:aSelection[i, 2 ] ] <> nil

            aWerte   := GetCoors( oER:aItems[ oER:aSelection[i, 1 ], oER:aSelection[i, 2 ] ]:hWnd )
            nTop     := aWerte[ 1 ]
            nLeft    := aWerte[2]
            nHeight  := aWerte[3] - aWerte[ 1 ]
            nWidth   := aWerte[4] - aWerte[2]

            oER:aItems[ oER:aSelection[i, 1 ], oER:aSelection[i, 2 ] ]:Move( nTop + nY, nLeft + nX, nWidth + nRight, nHeight + nBottom, .T. )

         endif

      next

      UnSelectAll( .F. )

   endif

return .T.

//----------------------------------------------------------------------------//

function DelselectItems()

   local i

   if MsgNoYes( GL("Delete the selected items?"), GL("Select an option") )

      for i := 1 to LEN( oER:aSelection )

         if oER:aItems[ oER:aSelection[i, 1 ], oER:aSelection[i, 2 ] ] != nil

            MarkItem( oER:aItems[ oER:aSelection[i, 1 ], oER:aSelection[i, 2 ] ]:hWnd )
            DelItemWithKey( oER:aSelection[i, 2 ], oER:aSelection[i, 1 ] )

         endif

      next

   endif

return .T.

//----------------------------------------------------------------------------//

function MsgBarInfos( nRow, nCol, nArea )
   LOCAL nDecimals := IIF( oER:nMeasure == 2, 2, 0 )
   Local nTotRow   := -1
   Local x

   DEFAULT nRow := 0
   DEFAULT nCol := 0

   For x = 1 to nArea - 1
       if !empty( oER:aWnd[ x ] )
          nTotRow  += ( oER:aWnd[ x ]:nHeight - 1 )
       endif
   Next x

   nTotRow += ( nRow - ( oEr:nRulerTop ) * nArea )

   oER:oMsgInfo:SetText( GL("Row:")    + " [ " + AllTrim( Str( GetCmInch( nTotRow ), 5, nDecimals ) ) + " ] / " + ;
                     if( GetCmInch( nRow - oEr:nRulerTop ) < 0, AllTrim( Str( 0, 5, nDecimals ) ) ,;
                     AllTrim( Str( GetCmInch( nRow - oEr:nRulerTop ), 5, nDecimals ) ) ) + "    " + ;
                     GL("Column:") + " " + AllTrim( Str( GetCmInch( nCol - oEr:nRuler ), 5, nDecimals ) ) )

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
      ID 301 OF oDlg UPDATE FONT oER:aFonts[ 1 ]

   REDEFINE GET oGet1 VAR cFontText ID 311 OF oDlg UPDATE FONT oER:aFonts[ 1 ] MEMO

   ACTIVATE DIALOG oDlg CENTERED ON INIT PreviewRefresh( oSay1, oLbx, oGet1 )

   if lSave
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

   local oIni
   local oDlg
   local nDefClr
   local aColors := GetAllColors()
   local aSay    := ARRAY(30)
   local oSay
   local aBtn    := ARRAY(30)
   local nColor  := 0

   DEFINE DIALOG oDlg NAME "GETCOLOR" TITLE GL("Select Color")

   nDefClr := oDlg:nClrPane

   REDEFINE BUTTON PROMPT GL("&Cancel") ID 101 OF oDlg ACTION oDlg:End()

   REDEFINE SAY PROMPT GL("Current:") ID 170 OF oDlg

   REDEFINE SAY PROMPT AllTrim(STR( nCurrentClr )) + "." ID 401 OF oDlg

 //  REDEFINE SAY PROMPT "" ID 402 OF oDlg COLORS SetColor( aColors[nCurrentClr], nDefClr ), SetColor( aColors[nCurrentClr], nDefClr )
   REDEFINE BTNBMP oSay PROMPT "" ID 402 OF oDlg NOBORDER
   osay:SetColor( SetColor(aColors[nCurrentClr], nDefClr ), SetColor( aColors[nCurrentClr], nDefClr ) )

/*
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
*/

   REDEFINE BTNBMP aSay[1]  ID 301 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[2]  ID 302 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[3]  ID 303 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[4]  ID 304 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[5]  ID 305 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[6]  ID 306 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[7]  ID 307 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[8]  ID 308 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[9]  ID 309 OF oDlg NOBORDER

   REDEFINE BTNBMP aSay[10]  ID 310 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[11]  ID 311 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[12]  ID 312 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[13]  ID 313 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[14]  ID 314 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[15]  ID 315 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[16]  ID 316 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[17]  ID 317 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[18]  ID 318 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[19]  ID 319 OF oDlg NOBORDER


   REDEFINE BTNBMP aSay[20]  ID 320 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[21]  ID 321 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[22]  ID 322 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[23]  ID 323 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[24]  ID 324 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[25]  ID 325 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[26]  ID 326 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[27]  ID 327 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[28]  ID 328 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[29]  ID 329 OF oDlg NOBORDER
   REDEFINE BTNBMP aSay[30]  ID 330 OF oDlg NOBORDER



   AEval( aSay, { | o, n | o:SetColor( 0,;
      If( Empty( aColors[ n ] ), CLR_WHITE, Val( aColors[ n ] ) ) ) } )

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

   oER:aFonts := nil
   oER:aFonts := Array( 50 )

   for i := 1 to 20
      oER:aFonts[ i ] := TFont():New( aGetFonts[i, 1], ;   // cFaceName
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

Function DelFont( oLbx, lAll )
Local nID
Local aGetFonts
Local aShowFonts
Local x
Local nFonts

   DEFAULT lAll   := .F.

   if !lAll
      if oLbx:ClassName() = "LISTBOX"
         nID := Val(SUBSTR( oLbx:GetItem(oLbx:GetPos()), 1, 2))
      else
          if oLbx:ClassName() = "TXBROWSE"
             nID  := oLbx:nArrayAt
          endif
      endif

      RndMsg( FwString("Deleting Font ") )

      DelIniEntry(  "Fonts", AllTrim(STR(nID,3)) ,oER:cDefIni  )
      oER:aFonts[nID]:= nil
   else
      RndMsg( FwString("Deleting Font ") )
      For x = 1 to Len( oER:aFonts )
          nID  := x
          DelIniEntry(  "Fonts", AllTrim(STR(nID,3)) ,oER:cDefIni  )
          oER:aFonts[nID]:= nil
      Next x
   endif
   aGetFonts  := GetFonts()
   aShowFonts := GetFontText( aGetFonts )
   if oLbx:ClassName() = "LISTBOX"
      oLbx:SetItems( aShowFonts )
   else
      if oLbx:ClassName() = "TXBROWSE"
         oLbx:SetArray( aShowFonts )
      endif
   endif
   oLbx:Refresh()

   SysWait(.3)
   RndMsg()

Return nil

//----------------------------------------------------------------------------//
/*
function GetColor( nNr )

return Val( oEr:GetDefIni( "Colors", AllTrim(STR( nNr, 5 )) , "" ) )
*/
//----------------------------------------------------------------------------//

function GetAllColors()

   local i
   local aColors := {}

   for i := 1 to 30
      AADD( aColors, PADR( oEr:GetDefIni( "Colors", AllTrim(STR( i, 5 )) , "" ), 15 ) )
   next

return ( aColors )

//----------------------------------------------------------------------------//

function FontsAndColors()

   local i
   local oDlg
   local oFld
   local oLbx
   local oSay1
   local oGet1
   local nDefClr
   local oIni
   local x
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
      ID 301 OF oFld:aDialogs[ i ] UPDATE FONT oER:aFonts[ 1 ]

   REDEFINE GET oGet1 VAR cFontText ID 311 OF oFld:aDialogs[ i ] UPDATE FONT oER:aFonts[ 1 ] MEMO

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
   INI oIni FILE oER:cDefIni
   for i := 1 to 30
      if !Empty( aColors[ i ] )
         SET SECTION "Colors" ENTRY AllTrim(STR(i,5)) to aColors[ i ] OF oIni
      endif
   next
   ENDINI

   SetSave( .F. )

return .T.

//----------------------------------------------------------------------------//

function Set2Color( oColorSay, cColor, nDefClr )
  LOCAL nColor := IF( Empty( cColor ), nDefClr, Val( cColor ) )

   oColorSay:SetColor( nColor, nColor )
   oColorSay:Refresh()

return .T.

//----------------------------------------------------------------------------//

function Set3Color( oColorSay, cColor, nDefClr )

   cColor := PADR( AllTrim( STR( ChooseColor( Val( cColor ) ), 20 ) ), 40 )
   Set2Color( oColorSay, cColor, nDefClr )

return ( cColor )

//----------------------------------------------------------------------------//

function SetColor( cColor, nDefClr )
RETURN IF( Empty( cColor ), nDefClr, Val( cColor ) )

//----------------------------------------------------------------------------//

function GetFontText( aGetFonts, lShowEmpty )

   local i, cText
   local aShowFonts := {}

   DEFAULT lShowEmpty := .T.

   for i := 1 to 20
      if !Empty(aGetFonts[i, 1 ])
         cText :=  Right("0"+AllTrim(STR( i, 3)),2) + ". " + ;
                   aGetFonts[i, 1 ] + ;
                   " " + AllTrim(STR( aGetFonts[i,3], 5 )) + ;
                   IIF( aGetFonts[i,4], " " + GL("bold"), "") + ;
                   IIF( aGetFonts[i,5], " " + GL("italic"), "") + ;
                   IIF( aGetFonts[i,6], " " + GL("underline"), "") + ;
                   IIF( aGetFonts[i,7], " " + GL("strickout"), "") + ;
                   IIF( aGetFonts[i,8] <> 0, " " + GL("Rotation:") + " " + AllTrim(STR( aGetFonts[i,8], 6)), "")
         AADD( aShowFonts, cText )
      else
         if lShowEmpty
            AADD( aShowFonts, Right("0"+AllTrim(STR( i, 3)), 2) + ". " )
         endif
      endif
   next

return ( aShowFonts )

//----------------------------------------------------------------------------//

function PreviewRefresh( oSay, oLbx, oGet )

   local nID

   if oLbx:ClassName() = "LISTBOX"

      nID := Val(SUBSTR( oLbx:GetItem(oLbx:GetPos()), 1, 2))

   else
       if oLbx:ClassName() = "TXBROWSE"
          nID  := oLbx:nArrayAt
       endif
   endif

   if !empty( oER:aFonts[nID] ) .and. Valtype( oER:aFonts[nID] ) = "O"
      oSay:Default()
      oSay:SetFont( oER:aFonts[nID] )
      oSay:Refresh()

      oGet:SetFont( oER:aFonts[nID] )
      oGet:Refresh()
   endif

return .T.

//----------------------------------------------------------------------------//

function SelectFont( oSay, oLbx, oGet )

   local oDlg
   local cFontDef
   local oFontGet
   local oIni
   local oNewFont
   local aShowFonts
   local nPos
   local aFontNames
   local i
   local y
   local cItemDef
   local aIniEntries
   local nEntry
   local lSave       := .F.
   local aCbx        := ARRAY(4)
   local nID
   local aGetFonts   := GetFonts()
   local cFontGet
   local nWidth
   local nHeight
   local lBold
   local lItalic
   local lUnderline
   local lStrikeOut
   local nEscapement
   local nOrient
   local nCharSet
   local hDC         := oEr:oMainWnd:GetDC()

   if oLbx:ClassName() = "LISTBOX"
      nID := Val(SUBSTR( oLbx:GetItem(oLbx:GetPos()), 1, 2))
   else
       if oLbx:ClassName() = "TXBROWSE"
          nID  := oLbx:nArrayAt
       endif
   endif

   cFontGet    := aGetFonts[nID, 1 ]
   nWidth      := aGetFonts[nID, 2 ]
   nHeight     := aGetFonts[nID, 3 ] * -1
   lBold       := aGetFonts[nID, 4 ]
   lItalic     := aGetFonts[nID, 5 ]
   lUnderline  := aGetFonts[nID, 6 ]
   lStrikeOut  := aGetFonts[nID, 7 ]
   nEscapement := aGetFonts[nID, 8 ]
   nOrient     := aGetFonts[nID, 10 ]
   nCharSet    := aGetFonts[nID, 9 ]

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

      INI oIni FILE oER:cDefIni
         SET SECTION "Fonts" ENTRY AllTrim(STR(nID,5)) to cFontDef OF oIni
      ENDINI

      oER:aFonts[nID] := TFont():New( AllTrim( cFontGet ), nWidth, -1 * nHeight,, lBold, ;
                                  nEscapement, nOrient,, lItalic, lUnderline, lStrikeOut, ;
                                  nCharSet )

      if oLbx:ClassName() = "LISTBOX"
         nPos := oLbx:GetPos()
         aShowFonts := GetFontText( GetFonts() )
         oLbx:SetItems( aShowFonts )
         oLbx:Select( nPos )
      else
         if oLbx:ClassName() = "TXBROWSE"
            nPos  := oLbx:nArrayAt
            aShowFonts := GetFontText( GetFonts() )
            oLbx:SetArray( aShowFonts )
            oLbx:Select( nPos )
         endif
      endif


      PreviewRefresh( oSay, oLbx, oGet )

      //Alle Elemente aktualisieren
      for i := 1 to Len( oER:aWnd )

         if oER:aWnd[ i ] <> nil

            aIniEntries := GetIniSection( "Items", oER:aAreaIni[ i ] )

            for y := 1 to LEN( aIniEntries )

               nEntry := EntryNr( aIniEntries[y] )

               if nEntry <> 0 .and. oER:aItems[i,nEntry] <> nil

                  cItemDef := GetIniEntry( aIniEntries, AllTrim(STR(nEntry,5)) , "" )

                  if UPPER(AllTrim( GetField( cItemDef, 1 ) )) = "TEXT" .and. ;
                        Val( GetField( cItemDef, 11 ) ) = nID

                     oER:aItems[i,nEntry]:SetFont( oER:aFonts[nID] )
                     oER:aItems[i,nEntry]:Refresh()

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

      cFontDef := AllTrim( oEr:GetDefIni( "Fonts", AllTrim(STR(i,3)) , "" ) )

      if !Empty( cFontDef )

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

   Local i
   Local oDlg
   Local oIni
   Local aGrp[ 2 ]
   Local oRad1
   Local aGet[ 1 ]
   local lSave       := .F.
   local nWidth      := Val( oEr:GetDefIni( "General", "PaperWidth" , "" ) )
   local nHeight     := Val( oEr:GetDefIni( "General", "PaperHeight", "" ) )
   local nTop        := Val( oEr:GetDefIni( "General", "TopMargin" , "20" ) )
   local nLeft       := Val( oEr:GetDefIni( "General", "LeftMargin", "20" ) )
   local nPageBreak  := Val( oEr:GetDefIni( "General", "PageBreak", "240" ) )
   local nOrient     := Val( oEr:GetDefIni( "General", "Orientation", "1" ) )
   local cTitle      := PADR( oEr:GetDefIni( "General", "Title", "" ), 80 )
   local cGroup      := PADR( oEr:GetDefIni( "General", "Group", "" ), 80 )
   local cPicture    := IIF( oER:nMeasure = 2, "999.99", "99999" )
   local aFormat     := GetPaperSizes()
   local nFormat     := Val( oEr:GetDefIni( "General", "PaperSize", "9" ) )
   local cFormat     := aFormat[ IIF( nFormat = 0, 9, nFormat ) ]
   Local nDecimals   := IIF( oER:nMeasure = 2, 2, 0 )

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

   REDEFINE SAY PROMPT oER:cMeasure ID 151 OF oDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 152 OF oDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 153 OF oDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 154 OF oDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 155 OF oDlg

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
   REDEFINE GROUP aGrp[ 2 ] ID 191 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( aGrp[ 1 ]:SetText( GL("Paper Size") ), ;
                aGrp[ 2 ]:SetText( GL("Report") ), ;
                oRad1:aItems[ 1 ]:SetText( GL("Portrait") ), ;
                oRad1:aItems[ 2 ]:SetText( GL("Landscape") ) )

   if lSave = .T.

      INI oIni FILE oER:cDefIni
         SET SECTION "General" ENTRY "PaperSize"    to AllTrim(STR( ASCAN( aFormat, AllTrim( cFormat ) ), 3 )) OF oIni
         SET SECTION "General" ENTRY "PaperWidth"   to AllTrim(STR( nWidth    , 5, nDecimals ) ) OF oIni
         SET SECTION "General" ENTRY "PaperHeight"  to AllTrim(STR( nHeight   , 5, nDecimals ) ) OF oIni
         SET SECTION "General" ENTRY "TopMargin"    to AllTrim(STR( nTop      , 5, nDecimals ) ) OF oIni
         SET SECTION "General" ENTRY "LeftMargin"   to AllTrim(STR( nLeft     , 5, nDecimals ) ) OF oIni
         SET SECTION "General" ENTRY "PageBreak"    to AllTrim(STR( nPageBreak, 5, nDecimals ) ) OF oIni
         SET SECTION "General" ENTRY "Orientation"  to AllTrim(STR( nOrient, 1 )) OF oIni
         SET SECTION "General" ENTRY "Title"        to AllTrim( cTitle ) OF oIni
         SET SECTION "General" ENTRY "Group"        to AllTrim( cGroup ) OF oIni
      ENDINI

      oEr:oMainWnd:cTitle := MainCaption()

      SetSave( .F. )

   endif

return .T.

//----------------------------------------------------------------------------//

function ER_ReportSettings( nD )

   Local i
   Local oDlg
   Local aGrp[ 3 ]
   Local oRad1
   Local aGet[ 10 ]
   Local lSave       := .F.
   Local nWidth      := Val( oEr:GetDefIni( "General", "PaperWidth" , "" ) )
   Local nHeight     := Val( oEr:GetDefIni( "General", "PaperHeight", "" ) )
   Local nTop        := Val( oEr:GetDefIni( "General", "TopMargin" , "20" ) )
   Local nLeft       := Val( oEr:GetDefIni( "General", "LeftMargin", "20" ) )
   Local nPageBreak  := Val( oEr:GetDefIni( "General", "PageBreak", "240" ) )
   Local nOrient     := Val( oEr:GetDefIni( "General", "Orientation", "1" ) )
   Local cTitle      := PADR( oEr:GetDefIni( "General", "Title", "" ), 80 )
   Local cGroup      := PADR( oEr:GetDefIni( "General", "Group", "" ), 80 )
   Local cPicture    := IIF( oER:nMeasure = 2, "999.99", "99999" )
   Local aFormat     := GetPaperSizes()
   Local nFormat     := Val( oEr:GetDefIni( "General", "PaperSize", "9" ) )
   Local cFormat     := aFormat[ IIF( nFormat = 0, 9, nFormat ) ]
   Local nDecimals   := IIF( oER:nMeasure = 2, 2, 0 )
   Local oBtn1
   Local oBtn2
   Local nFil        := 0
   Local oCbx
   Local lInfo       := .F.
   Local aLanguage   := {}
   Local nGridWidth  := oGenVar:nGridWidth
   Local nGridHeight := oGenVar:nGridHeight
   Local lShowGrid   := oGenVar:lShowGrid
   Local oFont

   DEFAULT nD := 1
   //DEFINE FONT oFont NAME "Verdana" SIZE 0, -10
   oFont := oER:oMainWnd:oFont

   oDlg := oER:oFldI:aDialogs[ nD ]
   oDlg:SetColor( CLR_BLACK, oEr:nClrPaneTree )

   @ oDlg:nHeight - 40, oDlg:nWidth - 110 BUTTON oBtn1 PROMPT GL("&OK") ;
     OF oDlg FONT oFont SIZE 80, 20 ;
     PIXEL ACTION  GrabaReportSetting( .T., aFormat,;
                             cFormat, nDecimals, nWidth, nHeight, nTop,   ;
                             nLeft, nPageBreak, nOrient, cTitle, cGroup,  ;
                             nGridWidth, nGridHeight, lShowGrid )

   //@ oDlg:nHeight - 50, oDlg:nWidth - 200 BUTTON oBtn2 PROMPT GL("&Cancel") ;
   //  OF oDlg SIZE 80, 20 PIXEL //ACTION oDlg:End()

   nFil  := 4

   //@ nFil, oDlg:nWidth - 80 SAY GL("Paper Size:") OF oDlg ;
   //  SIZE 60, 20 PIXEL TRANSPARENT
   @ nFil,  05 GROUP aGrp[ 1 ] TO nFil + 250, oDlg:nWidth - 5 OF oDlg ;
                    LABEL "  " + GL("Paper Size") + ": " ;
                    FONT oFont ;
                    PIXEL COLOR CLR_BLACK, oEr:nClrPaneTree

   nFil += 20
   @ nFil, 10 COMBOBOX cFormat ITEMS aFormat OF oDlg ;
      SIZE oDlg:nWidth - 20, 324 FONT oFont PIXEL ;
      ON CHANGE aGet[ 1 ]:Setfocus()

   nFil += 40
   @ nFil + 4, 10  SAY GL("Width:") OF oDlg FONT oFont SIZE 60, 24 ;
     COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil + 4, 150 SAY oER:cMeasure OF oDlg FONT oFont SIZE 40, 24 ;
     COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil, 70 GET aGet[ 2 ] VAR nWidth OF oDlg FONT oFont ;
      PICTURE cPicture SPINNER MIN 0 ;
      SIZE 50, 24 PIXEL ;
      WHEN AllTrim( cFormat ) = GL("user-defined")

   @ nFil+4,  200 SAY " " + GL("Orientation") + ":"  OF oDlg FONT oFont SIZE 60, 24 ;
     COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil + 44, 200 RADIO oRad1 VAR nOrient PROMPT GL("Portrait") OF oDlg SIZE 80, 24 ;
     COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL
   @ nFil + 84, 200 RADIOITEM GL("Landscape") RADIOMENU oRad1 OF oDlg ;
     SIZE 80, 24 COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL

   nFil += 40
   @ nFil + 4, 10  SAY GL("Height:") OF oDlg SIZE 60, 24 ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil + 4, 150 SAY oER:cMeasure OF oDlg SIZE 40, 24 ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil, 70 GET aGet[ 3 ] VAR nHeight OF oDlg PICTURE cPicture ;
      SPINNER MIN 0 ;
      SIZE 50, 24 FONT oFont PIXEL ;
      WHEN AllTrim( cFormat ) = GL("user-defined")
   nFil += 40
   @ nFil + 4, 10  SAY GL("Top margin")  +":" OF oDlg SIZE 60, 24 ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil + 4, 150 SAY oER:cMeasure OF oDlg SIZE 40, 24 ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil, 70 GET aGet[ 1 ] VAR nTop OF oDlg PICTURE cPicture SPINNER MIN 0 ;
      SIZE 50, 24 FONT oFont PIXEL
   nFil += 40
   @ nFil + 4, 10  SAY GL("Left margin") +":" OF oDlg SIZE 60, 24 ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil + 4, 150 SAY oER:cMeasure OF oDlg SIZE 40, 24 ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil, 70 GET aGet[ 4 ] VAR nLeft  OF oDlg PICTURE cPicture SPINNER MIN 0 ;
      FONT oFont SIZE 50, 24 PIXEL
   nFil += 40
   @ nFil + 4, 10  SAY GL("Page break:") OF oDlg SIZE 60, 24  ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil + 4, 150 SAY oER:cMeasure OF oDlg SIZE 40, 24 ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil, 70 GET aGet[ 5 ] VAR nPageBreak OF oDlg PICTURE cPicture SPINNER MIN 0 ;
      FONT oFont SIZE 50, 24 PIXEL


   nFil += 40
   //@ nFil, oDlg:nWidth - 80 SAY GL("Report") OF oDlg ;
   //  SIZE 60, 20 PIXEL TRANSPARENT
   @ nFil,  05 GROUP aGrp[ 2 ] TO nFil + 100, oDlg:nWidth - 5 OF oDlg ;
                    LABEL "  " + GL("Report") + ": " ;
                    FONT oFont PIXEL COLOR CLR_BLACK, oEr:nClrPaneTree

   nFil += 20
   @ nFil + 4, 10  SAY GL("Name")+":" OF oDlg SIZE 60, 24 ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil, 50 GET cTitle OF oDlg SIZE 260, 24 PIXEL
   nFil += 40
   @ nFil + 4, 10  SAY GL("Group")+":" OF oDlg SIZE 60, 24 ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil, 50 GET cGroup OF oDlg SIZE 260, 24 FONT oFont PIXEL

   nFil += 60
   @ nFil,  05 GROUP aGrp[ 3 ] TO nFil + 100, oDlg:nWidth - 5 OF oDlg ;
                    LABEL "  " + GL("Grid Setup") + ": " ;
                    FONT oFont PIXEL COLOR CLR_BLACK, oEr:nClrPaneTree

   nFil += 20
   @ nFil + 4, 10  SAY GL("Width:") OF oDlg SIZE 60, 24 ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil + 4, 150 SAY oER:cMeasure OF oDlg SIZE 40, 24 ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil, 70 GET aGet[ 6 ] VAR nGridWidth OF oDlg PICTURE cPicture SPINNER MIN 0.01 ;
      FONT oFont SIZE 50, 24 PIXEL VALID nGridWidth  > 0

   nFil += 40
   @ nFil + 4, 10  SAY GL("Height:") OF oDlg SIZE 60, 24 ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil + 4, 150 SAY oER:cMeasure OF oDlg SIZE 40, 24  ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL TRANSPARENT
   @ nFil, 70 GET aGet[ 7 ] VAR nGridHeight OF oDlg PICTURE cPicture SPINNER MIN 0.01 ;
      FONT oFont SIZE 50, 24 PIXEL VALID nGridHeight  > 0

   @ nFil, 220 CHECKBOX oCbx VAR lShowGrid ;
     PROMPT GL("Show grid") OF oDlg SIZE 80, 24  ;
     FONT oFont COLOR CLR_BLACK, oEr:nClrPaneTree PIXEL


return .T.

//----------------------------------------------------------------------------//

Function GrabaReportSetting( lSave, aFormat, cFormat, nDecimals, nWidth, nHeight, ;
                             nTop, nLeft, nPageBreak, nOrient, cTitle, cGroup, ;
                             nGridWidth, nGridHeight, lShowGrid )
Local oIni
Local i
Local nXMove
Local nYMove

DEFAULT lSave := .F.

   if lSave
      IF !Empty( oER:cDefIni )

      INI oIni FILE oER:cDefIni
         SET SECTION "General" ENTRY "PaperSize"    to AllTrim(STR( ASCAN( aFormat, AllTrim( cFormat ) ), 3 )) OF oIni
         SET SECTION "General" ENTRY "PaperWidth"   to AllTrim(STR( nWidth    , 5, nDecimals ) ) OF oIni
         SET SECTION "General" ENTRY "PaperHeight"  to AllTrim(STR( nHeight   , 5, nDecimals ) ) OF oIni
         SET SECTION "General" ENTRY "TopMargin"    to AllTrim(STR( nTop      , 5, nDecimals ) ) OF oIni
         SET SECTION "General" ENTRY "LeftMargin"   to AllTrim(STR( nLeft     , 5, nDecimals ) ) OF oIni
         SET SECTION "General" ENTRY "PageBreak"    to AllTrim(STR( nPageBreak, 5, nDecimals ) ) OF oIni
         SET SECTION "General" ENTRY "Orientation"  to AllTrim(STR( nOrient, 1 )) OF oIni
         SET SECTION "General" ENTRY "Title"        to AllTrim( cTitle ) OF oIni
         SET SECTION "General" ENTRY "Group"        to AllTrim( cGroup ) OF oIni
      ENDINI

      oEr:oMainWnd:cTitle := MainCaption()

      SetSave( .F. )

      oGenVar:nGridWidth    := nGridWidth
      oGenVar:nGridHeight   := nGridHeight
      oGenVar:lShowGrid     := lShowGrid


         INI oIni FILE oER:cDefIni
            SET SECTION "General" ENTRY "GridWidth"  to AllTrim(STR( nGridWidth , 5, nDecimals )) OF oIni
            SET SECTION "General" ENTRY "GridHeight" to AllTrim(STR( nGridHeight, 5, nDecimals )) OF oIni
            SET SECTION "General" ENTRY "ShowGrid"   to IIF( lShowGrid, "1", "0") OF oIni
         ENDINI

      endif

      for i := 1 to Len( oER:aWnd )
         if oER:aWnd[ i ] <> nil
            oER:aWnd[ i ]:Refresh()
         endif
      next

      SetGridSize( ER_GetPixel( nGridWidth ), ER_GetPixel( nGridHeight ) )
      nXMove := ER_GetPixel( nGridWidth )
      nYMove := ER_GetPixel( nGridHeight )

      oGenVar:nGridWidth  := nGridWidth
      oGenVar:nGridHeight := nGridHeight

      SetSave( .T. )

   endif

Return nil

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

/*
function Options()

   local i, oDlg, oIni, cLanguage, cOldLanguage, cWert, aCbx[5], aGrp[2], oRad1
   local lSave         := .F.
   local lInfo         := .F.
   local nLanguage     := Val( GetPvProfString( "General", "Language"  , "1", oER:cGeneralIni ) )
   local nMaximize     := Val( GetPvProfString( "General", "Maximize"  , "1", oER:cGeneralIni ) )
   local lMaximize     := IIF( nMaximize = 1, .T., .F. )
   local nMruList      := Val( GetPvProfString( "General", "MruList"  , "4", oER:cGeneralIni ) )
   local aLanguage     := {}
   local cPicture      := IIF( oER:nMeasure = 2, "999.99", "99999" )
   local nGridWidth    := oGenVar:nGridWidth
   local nGridHeight   := oGenVar:nGridHeight
   local lShowGrid     := oGenVar:lShowGrid
   local lShowReticule := oGenVar:lShowReticule
   local lShowBorder   := oGenVar:lShowBorder
   LOCAL lShowPanel  := ( oEr:GetGeneralIni( "General", "ShowPanel", "1" ) = "1" )
   LOCAL nDecimals     :=   IIF( oER:nMeasure = 2, 2, 0 )

   for i := 1 to 99
      cWert := GetPvProfString( "Languages", AllTrim(STR(i,2)), "", oER:cGeneralIni )
      if !Empty( cWert )
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
   REDEFINE BUTTON PROMPT GL("Clear list") ID 204 OF oDlg ACTION oER:oMru:Clear()

   REDEFINE CHECKBOX aCbx[3] VAR lShowBorder ID 205 OF oDlg ;
      ON CHANGE IIF( lInfo = .F., ;
                     ( MsgInfo( GL("Please restart the programm to activate the changes."), ;
                                GL("Information") ), lInfo := .T. ), )

   REDEFINE CHECKBOX aCbx[4] VAR lShowReticule ID 206 OF oDlg

   REDEFINE GET nGridWidth  ID 301 OF oDlg PICTURE cPicture SPINNER MIN 0.01 VALID nGridWidth > 0   WHEN !Empty( oER:cDefIni )
   REDEFINE GET nGridHeight ID 302 OF oDlg PICTURE cPicture SPINNER MIN 0.01 VALID nGridHeight > 0  WHEN !Empty( oER:cDefIni )


   REDEFINE CHECKBOX aCbx[2] VAR lShowGrid ID 303 OF oDlg  WHEN !Empty( oER:cDefIni )

   REDEFINE CHECKBOX aCbx[5] VAR lShowPanel ID 308 OF oDlg

   REDEFINE SAY PROMPT oER:cMeasure ID 120 OF oDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 121 OF oDlg

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

   if lSave

      oGenVar:nGridWidth    := nGridWidth
      oGenVar:nGridHeight   := nGridHeight
      oGenVar:lShowGrid     := lShowGrid
      oGenVar:lShowReticule := lShowReticule
      oGenVar:lShowBorder   := lShowBorder

      IF !Empty( oER:cDefIni )

      INI oIni FILE oER:cDefIni
         SET SECTION "General" ENTRY "GridWidth"  to AllTrim(STR( nGridWidth , 5, nDecimals )) OF oIni
         SET SECTION "General" ENTRY "GridHeight" to AllTrim(STR( nGridHeight, 5, nDecimals )) OF oIni
         SET SECTION "General" ENTRY "ShowGrid"   to IIF( lShowGrid, "1", "0") OF oIni
      ENDINI

      endif

      INI oIni FILE oER:cGeneralIni
         SET SECTION "General" ENTRY "MruList"        to AllTrim(STR( nMruList ))       OF oIni
         SET SECTION "General" ENTRY "Maximize"       to IIF( lMaximize    , "1", "0")  OF oIni
         SET SECTION "General" ENTRY "ShowTextBorder" to IIF( lShowBorder  , "1", "0" ) OF oIni
         SET SECTION "General" ENTRY "ShowReticule"   to IIF( lShowReticule, "1", "0" ) OF oIni
         SET SECTION "General" ENTRY "ShowPanel"      to IIF( lShowPanel, "1", "0" ) OF oIni

         if cLanguage <> cOldLanguage
            SET SECTION "General" ENTRY "Language" to ;
               AllTrim(STR(ASCAN( aLanguage, cLanguage ), 2)) OF oIni
         endif

      ENDINI

      for i := 1 to Len( oER:aWnd )
         if oER:aWnd[ i ] <> nil
            oER:aWnd[ i ]:Refresh()
         endif
      next

      SetGridSize( ER_GetPixel( nGridWidth ), ER_GetPixel( nGridHeight ) )
      nXMove := ER_GetPixel( nGridWidth )
      nYMove := ER_GetPixel( nGridHeight )

      oGenVar:nGridWidth  := nGridWidth
      oGenVar:nGridHeight := nGridHeight

      oEr:oMainWnd:SetMenu( BuildMenu() )

    //  SetSave( .F. )


      SetSave( .T. )
      msgInfo("el programa se reiniciara para que los cambios tengan efecto")
      oEr:oMainWnd:END()
      oER:lReexec  := .t.


   endif

return .T.
*/

//------------------------------------------------------------------------------

function SetGrid()

   local i, oDlg, oIni, oCbx, oRad1
   local lSave         := .F.
   local lInfo         := .F.
   local aLanguage     := {}
   local cPicture      := IIF( oER:nMeasure = 2, "999.99", "99999" )
   local nGridWidth    := oGenVar:nGridWidth
   local nGridHeight   := oGenVar:nGridHeight
   local lShowGrid     := oGenVar:lShowGrid
   LOCAL nDecimals     := IIF( oER:nMeasure = 2, 2, 0 )


   DEFINE DIALOG oDlg NAME "GRIDSETUP" TITLE GL("Grid Setup")

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()


   REDEFINE GET nGridWidth  ID 301 OF oDlg PICTURE cPicture SPINNER MIN 0.01 VALID nGridWidth  > 0
   REDEFINE GET nGridHeight ID 302 OF oDlg PICTURE cPicture SPINNER MIN 0.01 VALID nGridHeight > 0


   REDEFINE CHECKBOX oCbx VAR lShowGrid ID 303 OF oDlg

   REDEFINE SAY PROMPT oER:cMeasure ID 120 OF oDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 121 OF oDlg

   REDEFINE SAY PROMPT GL("Width:")           ID 171 OF oDlg
   REDEFINE SAY PROMPT GL("Height:")          ID 172 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( oCbx:SetText( GL("Show grid") )  ,;
                DlgBarTitle( oDlg, GL("Grid Setup"), "B_EDIT32",44 ) ) ;
      ON PAINT  DlgStatusBar(oDlg, 68,, .t. )


   if lSave

      oGenVar:nGridWidth    := nGridWidth
      oGenVar:nGridHeight   := nGridHeight
      oGenVar:lShowGrid     := lShowGrid

      IF !Empty( oER:cDefIni )

         INI oIni FILE oER:cDefIni
            SET SECTION "General" ENTRY "GridWidth"  to AllTrim(STR( nGridWidth , 5, nDecimals )) OF oIni
            SET SECTION "General" ENTRY "GridHeight" to AllTrim(STR( nGridHeight, 5, nDecimals )) OF oIni
            SET SECTION "General" ENTRY "ShowGrid"   to IIF( lShowGrid, "1", "0") OF oIni
         ENDINI

      endif

      for i := 1 to Len( oER:aWnd )
         if oER:aWnd[ i ] <> nil
            oER:aWnd[ i ]:Refresh()
         endif
      next

      SetGridSize( ER_GetPixel( nGridWidth ), ER_GetPixel( nGridHeight ) )
      nXMove := ER_GetPixel( nGridWidth )
      nYMove := ER_GetPixel( nGridHeight )

      oGenVar:nGridWidth  := nGridWidth
      oGenVar:nGridHeight := nGridHeight

      //  SetSave( .F. )
      SetSave( .T. )

   endif

return .T.


//------------------------------------------------------------------------------

function ItemList()

   local oTree
   local oImageList, oBmp1, oBmp2
   local lDlg   := .T.
   LOCAL oDlg

    IF !oEr:lShowPanel

      DEFINE DIALOG oDlg RESOURCE "Itemlist" TITLE GL("Item List")

      oTree := TTreeView():ReDefine( 201, oDlg, 0, , .F. ,"" )

      oTree:bLDblClick  = { | nRow, nCol, nKeyFlags | ClickListTree( oTree ) }
      oTree:bEraseBkGnd = { || nil }  // to properly erase the tree background


      REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION oDlg:End()

      ACTIVATE DIALOG oDlg CENTERED ON INIT FillTree( oTree, oDlg )  //ListTrees( oTree )

   else

     if !empty( oER:oTree )
        if empty( oER:oTree:aItems )
           oEr:oTree:bLDblClick  = { | nRow, nCol, nKeyFlags | ClickListTree( oEr:oTree ) }
           FillTree( oEr:oTree, oEr:oMainWnd )
           //  oEr:oTree:show()
           oER:oPanelI:Show()   //oFldI:Show()
        else
           // Recargar oTree ?
        endif
     endif


   endif

return nil

//------------------------------------------------------------------------------

FUNCTION RefreshPanelTree()

  IF oEr:lShowPanel
     oER:oTree:DeleteAll()
     //msginfo(1)
     FillTree( oEr:oTree, oEr:oMainWnd )
  ENDIF

RETURN nil

//------------------------------------------------------------------------------

STATIC Function FillTree( oTree, oDlg )

   local lFirstArea    := .T.
   local aIniEntries   := GetIniSection( "Areas", oER:cDefIni )
   local cAreaFilesDir := CheckPath( oEr:GetDefIni( "General", "AreaFilesDir", "" ) )
   local oTr1
   local aTr:= {}
   local i
   local y
   local oTr2
   local cItemDef
   local aElemente
   local nEntry
   local cTitle
   local ele

   CreateTreeImageList( oDlg, oTree )

   for i := 1 to LEN( aIniEntries )
      nEntry := EntryNr( aIniEntries[ i ] )
      if nEntry != 0
           cTitle := oER:aWndTitle[nEntry] //+ " - [ " + GL("Area" ) + " ]"
           oTr1 := oTree:Add( AllTrim(STR(nEntry,5)) + ". " + cTitle , 0 )
           oTr1:Set( , IF( oTr1:IsExpanded() , 1  , 0   )    )

           if Empty( cAreaFilesDir )
              cAreaFilesDir := cDefaultPath
           endif
           if Empty( cAreaFilesDir )
               cAreaFilesDir := oER:cDefIniPath
           endif
           cItemDef := VRD_LF2SF( cAreaFilesDir + ;
            AllTrim( GetIniEntry( aIniEntries, AllTrim(STR(nEntry,5)) , "" ) ) )
            if !Empty( cItemDef )

            cItemDef := IIF( AT( "\", cItemDef ) = 0, ".\", "" ) + cItemDef

            aElemente := GetAllItems( cItemDef )
            IF !oER:lDClkProperties
                oTr1:Add( GL("Area Properties"),2 )
            endif
            for y := 1 to LEN( aElemente )

               //oTr2 := oTr1:Add( aElemente[y, 2 ] + " - [ " + GL("Item") + " ]", aElemente[y,3], aElemente[y,3] )
               oTr2 := oTr1:Add( aElemente[y, 2 ], aElemente[y,3], aElemente[y,3] )
               if aElemente[y,6] <> 0
                  ele:= oTr2:Add( GL("Visible"), aElemente[y,5], aElemente[y,4] )
                  ele:Set( , IF( !GetItemVisible( ele ) , 4  , 3   )    )

               endif
               IF !oER:lDClkProperties
                  oTr2:Add( GL("Item Properties"),5 )
               endif

            next

         endif


      endif
   next

   oTree:Expand()
   oTree:GoTop()
   oTree:SetFocus()

Return .T.

//------------------------------------------------------------------------------

static function CreateTreeImageList( oDlg, oTree )

   local aBmps := { "FoldOpen", "FoldClose", "B_itemList", "Checkon", "Unchecked", "b_edit", ;
               "Typ_Text", "Typ_Image", "Typ_Graphic", "Typ_Barcode", ;
               "TreeGraph1", "TreeGraph2", "TreeGraph3", "TreeGraph4", ;
               "TreeGraph5", "TreeGraph6" }
   local n, oBmp
   local oImageList := TImageList():New()

   for n = 1 TO Len( aBmps )

     oBmp = TBitmap():Define( aBmps[ n ], oDlg )
     oImageList:Add( oBmp, SetMasked( oBmp:hBitmap, oTree:nClrPane ) )
     oBmp:End()

   next

   oTree:SetImageList( oImageList )

RETURN nil

//------------------------------------------------------------------------------

STATIC function GetItemVisible( oItem )

local  oLinkArea := oItem:GetParent()
local  nItem     := Val( oLinkArea:cPrompt )
local  nArea     := Val( oLinkArea:GetParent():cPrompt )
local  cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", oER:aAreaIni[ nArea ] ) )
local  lWert

      if Val( GetField( cItemDef, 4 ) ) = 0
         lWert := .F.
      else
         lWert := .T.
      endif

RETURN lWert

//------------------------------------------------------------------------------
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
   local aIniEntries   := GetIniSection( "Areas", oER:cDefIni )
   local cAreaFilesDir := CheckPath( oEr:GetDefIni( "General", "AreaFilesDir", "" ) )

   oTr1 := oTree:GetRoot()

   for i := 1 to LEN( aIniEntries )

      nEntry := EntryNr( aIniEntries[ i ] )

      if nEntry <> 0 //.and. !Empty( oER:aWndTitle[nEntry] )

         cTitle := oER:aWndTitle[nEntry]

         if lFirstArea
            oTr1 := oTr1:AddLastChild( AllTrim(STR(nEntry,5)) + ". " + cTitle, nClose, nOpen )
            lFirstArea := .F.
         else
            oTr1 := oTr1:AddAfter( AllTrim(STR(nEntry,5)) + ". " + cTitle, nClose, nOpen )
         endif

         if Empty( cAreaFilesDir )
            cAreaFilesDir := cDefaultPath
         endif
         if Empty( cAreaFilesDir )
            cAreaFilesDir := oER:cDefIniPath
         endif

         cItemDef := VRD_LF2SF( cAreaFilesDir + ;
            AllTrim( GetIniEntry( aIniEntries, AllTrim(STR(nEntry,5)) , "" ) ) )

         if !Empty( cItemDef )

            cItemDef := IIF( AT( "\", cItemDef ) = 0, ".\", "" ) + cItemDef

            aElemente := GetAllItems( cItemDef )
            IF !oER:lDClkProperties
               oTr1:AddLastChild( GL("Area Properties") )
            ENDIF

            for y := 1 to LEN( aElemente )

               oTr2 := oTr1:AddLastChild( aElemente[y, 2 ], aElemente[y,3], aElemente[y,3] )
               if nEntry = 1 .and. y = 1
                  oTr2:lOpened := .T.
               endif
               if aElemente[y,6] <> 0
                  oTr2:AddLastChild( GL("Visible"), aElemente[y,5], aElemente[y,4] )
               endif
               IF !oER:lDClkProperties
                  oTr2:AddLastChild( GL("Item Properties") )
               ENDIF

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

      if !Empty( cItemDef )

         cTyp    := UPPER(AllTrim( GetField( cItemDef, 1 ) ))
         cName   := AllTrim( GetField( cItemDef, 2 ) )
         nShow   := Val( GetField( cItemDef, 4 ) )
         nDelete := Val( GetField( cItemDef, 5 ) )

         if UPPER( cTyp ) = "IMAGE" .and. Empty( cName )
            cName := AllTrim(STR(nEntry,5)) + ". " + AllTrim( GetField( cItemDef, 11 ) )
         else
            cName := AllTrim(STR(nEntry,5)) + ". " + cName
         endif

         if UPPER( cTyp ) = "TEXT"
            nTyp := 6
         elseif UPPER( cTyp ) = "IMAGE"
            nTyp := 7
         elseif IsGraphic( cTyp )
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
   local nArea , nItem, oLinkArea, cItemDef,  lWert
   local nLevel  := 0
   local cPrompt := oTree:GetSelText()
   local oItem   := oTree:GetSelected()

   if cPrompt = GL("Visible") .OR. cPrompt = GL("Item Properties") //.or. !empty( At( ("[ " + GL("Item") + " ]"), cPrompt ) )

      oLinkArea := oItem:GetParent()
      nItem     := Val( oLinkArea:cPrompt )
      nArea     := Val( oLinkArea:GetParent():cPrompt )

   endif

   Do Case
       Case cPrompt = GL("Area Properties")

           nArea     := Val( oItem:GetParent():cPrompt )
           //oER:nAktArea  := nArea
           AreaProperties( nArea )

      Case cPrompt = GL("Item Properties")
           oLinkArea:SetText( ItemProperties( nItem, nArea, .T. ) )
           cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", oER:aAreaIni[ nArea ] ) )
           if IsGraphic( UPPER(AllTrim( GetField( cItemDef, 1 ) )) )
              oLinkArea:set( ,  SetGraphTreeBmp( nItem, oER:aAreaIni[ nArea ] ) )
           endif

      Case cPrompt = GL("Visible")
           cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", oER:aAreaIni[ nArea ] ) )
           lWert    := if( Val( GetField( cItemDef, 4 ) ) = 0, .F., .T. )
           oItem:Set( , IF( lWert , 4  , 3   )    )
           DeleteItem( nItem, nArea, .T., lWert )

      Otherwise
         if oEr:lDClkProperties

              nLevel  := oItem:ItemLevel()
              //? oItem:Cargo, oItem:cPrompt, oItem:oParent
              Do Case
                 Case nLevel = 0
                    if !empty( oItem:oParent )
                       nArea     := Val( oItem:GetParent():cPrompt )
                    else
                       nArea     := Val( oItem:cPrompt )
                    endif
                    //oER:nAktArea  := nArea
                    RefreshBrwAreaProp(nArea)
                    oItem:setText( AreaProperties( nArea ) )

                 Case nLevel = 1
                    oLinkArea  := oItem
                    if !empty( oItem:oParent )
                       nArea     := Val( oItem:GetParent():cPrompt )
                       nItem     := Val( oItem:cPrompt )
                    endif
                    //oER:nAktArea  := nArea
                    oLinkArea:SetText( ItemProperties( nItem, nArea, .T. ) )

                    cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", oER:aAreaIni[ nArea ] ) )
                    if IsGraphic( UPPER(AllTrim( GetField( cItemDef, 1 ) )) )
                       oLinkArea:set( ,  SetGraphTreeBmp( nItem, oER:aAreaIni[ nArea ] ) )
                    endif

                 Otherwise
              EndCase

           endif
   EndCase

/*
   if cPrompt = GL("Area Properties") //.or. !empty( At( ("[ " + GL("Area") + " ]"), cPrompt ) )

      nArea     := Val( oItem:GetParent():cPrompt )
      //oER:nAktArea  := nArea
      AreaProperties( nArea )

   endif

   if cPrompt = GL("Visible")

     cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", oER:aAreaIni[ nArea ] ) )

      if Val( GetField( cItemDef, 4 ) ) = 0
         lWert := .F.
      else
         lWert := .T.
      endif
      oItem:Set( , IF( lWert , 4  , 3   )    )

      DeleteItem( nItem, nArea, .T., lWert )

   elseif cPrompt = GL("Item Properties") //.or. !empty( At( ("[ " + GL("Item") + " ]"), cPrompt ) )

     oLinkArea:SetText( ItemProperties( nItem, nArea, .T. ) )

     cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", oER:aAreaIni[ nArea ] ) )

     if IsGraphic( UPPER(AllTrim( GetField( cItemDef, 1 ) )) )
         oLinkArea:set( ,  SetGraphTreeBmp( nItem, oER:aAreaIni[ nArea ] ) )

     endif

   endif
*/

return .T.

//----------------------------------------------------------------------------//

function SetGraphTreeBmp( nItem, cAreaIni )

   local cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", cAreaIni ) )
   local cTyp     := UPPER(AllTrim( GetField( cItemDef, 1 ) ))
   local nIndex   := GetGraphIndex( cTyp )

return ( nIndex + 9 )

//------------------------------------------------------------------------------

FUNCTION GetAreaProperties( nArea )
   LOCAL aAreaProp := Array(13)
   local cAreaTitle     := oER:aWndTitle[ nArea ]

   aAreaProp[1] := { GL( "Title" ),;
                     cAreaTitle }

   aAreaProp[2] := { GL( "Top1" ),;
                     Val( GetPvProfString( "General", "Top1", "0", oER:aAreaIni[ nArea ] ) ) }

   aAreaProp[3] := { GL( "Top2" ),;
                     Val( GetPvProfString( "General", "Top2", "0", oER:aAreaIni[ nArea ] ) ) }

   aAreaProp[4] := { GL( "TopVariable" ),;
                     ( GetPvProfString( "General", "TopVariable", "1", oER:aAreaIni[ nArea ] ) = "1" ) }

   aAreaProp[5] := { GL( "Width" ) ,;
                     Val( GetPvProfString( "General", "Width", "600", oER:aAreaIni[ nArea ] ) ) }

   aAreaProp[6] := { GL( "Height" ) ,;
                    Val( GetPvProfString( "General", "Height", "300", oER:aAreaIni[ nArea ] ) ) }

   aAreaProp[7] := { GL( "Condition" ) ,;
                    Val( GetPvProfString( "General", "Condition", "1", oER:aAreaIni[ nArea ] ) ) }

   aAreaProp[8] := { GL( "DelEmptySpace" ) ,;
                    ( GetPvProfString( "General", "DelEmptySpace", "0", oER:aAreaIni[ nArea ] ) = "1" ) }

   aAreaProp[9] := { GL( "BreakBefore" ) ,;
                     ( GetPvProfString( "General", "BreakBefore"  , "0", oER:aAreaIni[ nArea ] ) = "1" ) }

   aAreaProp[10] := { GL( "BreakAfter" ) ,;
                     ( GetPvProfString( "General", "BreakAfter"   , "0", oER:aAreaIni[ nArea ] ) = "1" ) }

   aAreaProp[11] := { GL( "PrintBeforeBreak") ,;
                     ( GetPvProfString( "General", "PrintBeforeBreak", "0", oER:aAreaIni[ nArea ] ) = "1" ) }

   aAreaProp[12] := { GL ("PrintAfterBreak") ,;
                     ( GetPvProfString( "General", "PrintAfterBreak" , "0", oER:aAreaIni[ nArea ] ) = "1" ) }

   aAreaProp[13] := { GL("ControlDBF") ,;
                     AllTrim( GetPvProfString( "General", "ControlDBF", GL("none"), oER:aAreaIni[ nArea ] ) ) }

RETURN aAreaProp

//------------------------------------------------------------------------------

FUNCTION SetAreaProperties( nArea, aAreaProp, aTmpSource, cOldAreaText )
   LOCAL oIni
   LOCAL nDecimals    := IIF( oER:nMeasure = 2, 2, 0 )
   LOCAL i
   local nOldWidth      := Val( GetPvProfString( "General", "Width", "600", oER:aAreaIni[ nArea ] ) )
   local nOldHeight     := Val( GetPvProfString( "General", "Height", "300", oER:aAreaIni[ nArea ] ) )

   INI oIni FILE oER:aAreaIni[ nArea ]
         SET SECTION "General" ENTRY "Title"            to AllTrim( aAreaProp[1,2] ) OF oIni
         SET SECTION "General" ENTRY "Top1"             to AllTrim(STR( aAreaProp[2,2], 5, nDecimals )) OF oIni
         SET SECTION "General" ENTRY "Top2"             to AllTrim(STR( aAreaProp[3,2], 5, nDecimals )) OF oIni
         SET SECTION "General" ENTRY "TopVariable"      to IIF( !aAreaProp[4,2] , "0", "1") OF oIni
         SET SECTION "General" ENTRY "Condition"        to AllTrim(STR( aAreaProp[7,2], 1 )) OF oIni
         SET SECTION "General" ENTRY "Width"            to AllTrim(STR( aAreaProp[5,2], 5, nDecimals )) OF oIni
         SET SECTION "General" ENTRY "Height"           to AllTrim(STR( aAreaProp[6,2], 5 ,nDecimals )) OF oIni
         SET SECTION "General" ENTRY "DelEmptySpace"    to IIF( !aAreaProp[8,2] , "0", "1") OF oIni
         SET SECTION "General" ENTRY "BreakBefore"      to IIF( !aAreaProp[9,2] , "0", "1") OF oIni
         SET SECTION "General" ENTRY "BreakAfter"       to IIF( !aAreaProp[10,2] , "0", "1") OF oIni
         SET SECTION "General" ENTRY "PrintBeforeBreak" to IIF( !aAreaProp[11,2] , "0", "1") OF oIni
         SET SECTION "General" ENTRY "PrintAfterBreak"  to IIF( !aAreaProp[12,2] , "0", "1") OF oIni
         SET SECTION "General" ENTRY "ControlDBF"       to AllTrim( aAreaProp[13,2] ) OF oIni

         for i := 1 to 12
            SET SECTION "General" ENTRY "Formula" + AllTrim(STR(i,2)) to AllTrim( aTmpSource[ i ] ) OF oIni
         next

      ENDINI

      oGenVar:aAreaSizes[ nArea, 1 ] := aAreaProp[5,2]
      oGenVar:aAreaSizes[ nArea, 2 ] := aAreaProp[6,2]

      AreaChange( nArea,  aAreaProp[1,2], nOldWidth, aAreaProp[5,2], nOldHeight,  aAreaProp[6,2] )

      SetSave( .T. )   // .F.

      if cOldAreaText <> MEMOREAD( oER:aAreaIni[ nArea ] )
         Add2Undo( "", 0, nArea, cOldAreaText )
      endif

 RETURN NIL

//------------------------------------------------------------------------------

  function AreaProperties( nArea )

   local i, oDlg, oIni, oBtn, oRad1, aCbx[6], aGrp[5], oSay1
   local aDbase  := { GL("none") }
   local lSave   := .F.
   LOCAL aAreaProp := GetAreaProperties( nArea )
   local cPicture       := IIF( oER:nMeasure = 2, "999.99", "99999" )
   local cAreaTitle     := oER:aWndTitle[ nArea ]
   local cOldAreaText   := MEMOREAD( oER:aAreaIni[ nArea ] )
   LOCAL nDecimals    := IIF( oER:nMeasure = 2, 2, 0 )

   aTmpSource := {}

   for i := 1 to 13
      AADD( aTmpSource, ;
         AllTrim( GetPvProfString( "General", "Formula" + AllTrim(STR(i,2)), "", oER:aAreaIni[ nArea ] ) ) )
   next

   AEval( oGenVar:aDBFile, {|x| IIF( Empty( x[2] ),, AADD( aDbase, AllTrim( x[2] ) ) ) } )

   DEFINE DIALOG oDlg RESOURCE "AREAPROPERTY" TITLE GL("Area Properties")

   REDEFINE GET aAreaProp[1,2] ID 201 OF oDlg MEMO
   REDEFINE GET aAreaProp[2,2] ID 301 OF oDlg PICTURE cPicture SPINNER MIN 0 UPDATE
   REDEFINE GET aAreaProp[3,2] ID 302 OF oDlg PICTURE cPicture SPINNER MIN 0 UPDATE

   REDEFINE CHECKBOX aCbx[4] VAR aAreaProp[4,2] ID 303 OF oDlg ;
      ON CHANGE oSay1:SetText( IIF( aAreaProp[4,2], GL("Minimum top") + ":", GL("Top:") ) )

   REDEFINE GET aAreaProp[5,2] ID 401 OF oDlg PICTURE cPicture SPINNER MIN 0
   REDEFINE GET aAreaProp[6,2] ID 402 OF oDlg PICTURE cPicture SPINNER MIN 0

   REDEFINE RADIO oRad1 VAR aAreaProp[7,2] ID 501, 502, 503, 504 OF oDlg

   REDEFINE COMBOBOX aAreaProp[13,2] ITEMS aDbase ID 511 OF oDlg

   REDEFINE CHECKBOX aCbx[1] VAR aAreaProp[8,2]  ID 601 OF oDlg
   REDEFINE CHECKBOX aCbx[2] VAR aAreaProp[9,2]  ID 602 OF oDlg
   REDEFINE CHECKBOX aCbx[3] VAR aAreaProp[10,2] ID 603 OF oDlg
   REDEFINE CHECKBOX aCbx[5] VAR aAreaProp[11,2] ID 604 OF oDlg
   REDEFINE CHECKBOX aCbx[6] VAR aAreaProp[12,2] ID 605 OF oDlg

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

   REDEFINE SAY PROMPT oER:cMeasure ID 121 OF oDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 122 OF oDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 123 OF oDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 124 OF oDlg

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE SAY oSay1 PROMPT IIF( aAreaProp[4,2] , GL("Minimum top") + ":", GL("Top:") ) ID 172 OF oDlg

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
      ON INIT ( oRad1:aItems[ 1 ]:SetText( GL("always") ), ;
                oRad1:aItems[2]:SetText( GL("never") ), ;
                oRad1:aItems[3]:SetText( GL("page = 1") ), ;
                oRad1:aItems[4]:SetText( GL("page > 1") ), ;
                aGrp[1]:SetText( GL("Title") ), ;
                aGrp[2]:SetText( GL("Position") ), ;
                aGrp[3]:SetText( GL("Size") ), ;
                aGrp[4]:SetText( GL("Print Condition") ), ;
                aGrp[5]:SetText( GL("Options") ), ;
                aCbx[1]:SetText( GL("Delete Empty space after last row") ), ;
                aCbx[2]:SetText( GL("New page before printing this area") ), ;
                aCbx[3]:SetText( GL("New page after printing this area") ), ;
                aCbx[5]:SetText( GL("Print this area before every page break") ), ;
                aCbx[6]:SetText( GL("Print this area after every page break") ), ;
                aCbx[4]:SetText( GL("Top depends on previous area") ) )

   if lSave
      SetAreaProperties( nArea, aAreaProp, aTmpSource, cOldAreaText )
      RefreshBrwAreaProp( nArea )
   endif

RETURN cAreaTitle

//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
 /*
function AreaProperties( nArea )

   local i, oDlg, oIni, oBtn, oRad1, aCbx[6], aGrp[5], oSay1
   local aDbase  := { GL("none") }
   local lSave   := .F.
   local nTop1   := Val( GetPvProfString( "General", "Top1", "0", oER:aAreaIni[ nArea ] ) )
   local nTop2   := Val( GetPvProfString( "General", "Top2", "0", oER:aAreaIni[ nArea ] ) )
   local lTop    := ( GetPvProfString( "General", "TopVariable", "1", oER:aAreaIni[ nArea ] ) = "1" )
   local nWidth  := Val( GetPvProfString( "General", "Width", "600", oER:aAreaIni[ nArea ] ) )
   local nHeight := Val( GetPvProfString( "General", "Height", "300", oER:aAreaIni[ nArea ] ) )
   local nCondition     := Val( GetPvProfString( "General", "Condition", "1", oER:aAreaIni[ nArea ] ) )
   local lDelSpace      := ( GetPvProfString( "General", "DelEmptySpace", "0", oER:aAreaIni[ nArea ] ) = "1" )
   local lBreakBefore   := ( GetPvProfString( "General", "BreakBefore"  , "0", oER:aAreaIni[ nArea ] ) = "1" )
   local lBreakAfter    := ( GetPvProfString( "General", "BreakAfter"   , "0", oER:aAreaIni[ nArea ] ) = "1" )
   local lPrBeforeBreak := ( GetPvProfString( "General", "PrintBeforeBreak", "0", oER:aAreaIni[ nArea ] ) = "1" )
   local lPrAfterBreak  := ( GetPvProfString( "General", "PrintAfterBreak" , "0", oER:aAreaIni[ nArea ] ) = "1" )
   local cDatabase      := AllTrim( GetPvProfString( "General", "ControlDBF", GL("none"), oER:aAreaIni[ nArea ] ) )

   local nOldWidth      := nWidth
   local nOldHeight     := nHeight
   local cPicture       := IIF( oER:nMeasure = 2, "999.99", "99999" )
   local cAreaTitle     := oER:aWndTitle[ nArea ]
   local cOldAreaText   := MEMOREAD( oER:aAreaIni[ nArea ] )
   LOCAL nDecimals    := IIF( oER:nMeasure = 2, 2, 0 )

   aTmpSource := {}

 //  msginfo(aItems[nArea,nItem])

   for i := 1 to 13
      AADD( aTmpSource, ;
         AllTrim( GetPvProfString( "General", "Formula" + AllTrim(STR(i,2)), "", oER:aAreaIni[ nArea ] ) ) )
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

   REDEFINE SAY PROMPT oER:cMeasure ID 121 OF oDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 122 OF oDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 123 OF oDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 124 OF oDlg

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

   if lSave

      INI oIni FILE oER:aAreaIni[ nArea ]
         SET SECTION "General" ENTRY "Title"            to AllTrim( cAreaTitle ) OF oIni
         SET SECTION "General" ENTRY "Top1"             to AllTrim(STR( nTop1  , 5, nDecimals )) OF oIni
         SET SECTION "General" ENTRY "Top2"             to AllTrim(STR( nTop2  , 5, nDecimals )) OF oIni
         SET SECTION "General" ENTRY "TopVariable"      to IIF( !lTop , "0", "1") OF oIni
         SET SECTION "General" ENTRY "Condition"        to AllTrim(STR( nCondition, 1 )) OF oIni
         SET SECTION "General" ENTRY "Width"            to AllTrim(STR( nWidth , 5, nDecimals )) OF oIni
         SET SECTION "General" ENTRY "Height"           to AllTrim(STR( nHeight, 5,nDecimals )) OF oIni
         SET SECTION "General" ENTRY "DelEmptySpace"    to IIF( !lDelSpace , "0", "1") OF oIni
         SET SECTION "General" ENTRY "BreakBefore"      to IIF( !lBreakBefore , "0", "1") OF oIni
         SET SECTION "General" ENTRY "BreakAfter"       to IIF( !lBreakAfter , "0", "1") OF oIni
         SET SECTION "General" ENTRY "PrintBeforeBreak" to IIF( !lPrBeforeBreak , "0", "1") OF oIni
         SET SECTION "General" ENTRY "PrintAfterBreak"  to IIF( !lPrAfterBreak , "0", "1") OF oIni
         SET SECTION "General" ENTRY "ControlDBF"       to AllTrim( cDatabase ) OF oIni

         for i := 1 to 12
            SET SECTION "General" ENTRY "Formula" + AllTrim(STR(i,2)) to AllTrim( aTmpSource[ i ] ) OF oIni
         next

      ENDINI

      oGenVar:aAreaSizes[ nArea, 1 ] := nWidth
      oGenVar:aAreaSizes[ nArea, 2 ] := nHeight

      AreaChange( nArea, cAreaTitle, nOldWidth, nWidth, nOldHeight, nHeight )

      SetSave( .T. )   // .F.

      if cOldAreaText <> MEMOREAD( oER:aAreaIni[ nArea ] )
         Add2Undo( "", 0, nArea, cOldAreaText )
      endif

    //  OpenFile( oER:cDefIni, .T., )

   endif

RETURN cAreaTitle
 */

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
   local n
   local oMenuItem
   local cOldTitle   := oER:aWndTitle[ nArea ]    // aWnd[ nArea ]:cTitle  // da igual
   local cTemp1
   local cTemp2
   local nElem
   local oItem


   oER:aWndTitle[ nArea ]   := cAreaTitle
   oER:aWnd[ nArea ]:cTitle := cAreaTitle
   oGenVar:aAreaTitle[ oER:nAktArea ]:Refresh()

  oMenuAreas:DelItems()
   for n = 1 to Len( oER:aWndTitle )
      if ! Empty( oER:aWndTitle[ n ] )
         oMenuAreas:Add( oMenuitem:=TmenuItem():New( oER:aWndTitle[ n ],,,,;
         {|| oER:nAktArea:= AScan( oER:aWndTitle, oMenuItem:cPrompt ), oER:aWnd[ oER:nAktArea ]:SetFocus(), SetWinNull() }  )  )

      endif
   next

   if nOldWidth <> nWidth

      for i := 1 to Len( oER:aWnd )
         if oER:aWnd[ i ] <> nil
            oER:aWnd[ i ]:Refresh()
         endif
      next

   endif

   if nOldHeight <> nHeight

      oER:aWnd[ nArea ]:Move( oER:aWnd[ nArea ]:nTop, oER:aWnd[ nArea ]:nLeft, ;
         IIF( oGenVar:lFixedAreaWidth, ER_GetPixel(MaxWidthAreas( nArea ))+ oER:nRuler + nAreaZugabe2 , ER_GetPixel( nWidth ) + oER:nRuler + nAreaZugabe2 ), ;
         IIF( oGenVar:aAreaHide[ nArea ], oEr:nRulerTop, ER_GetPixel( nHeight ) + nAreaZugabe ), .T. )

      for i := nArea+1 to Len( oER:aWnd )
         if oER:aWnd[ i ] <> nil
            oER:aWnd[ i ]:Move( oER:aWnd[ i ]:nTop + ER_GetPixel( nHeight - nOldHeight ), ;
               oER:aWnd[ i ]:nLeft,,, .T. )
         endif
      next

      oEr:nTotalHeight += ER_GetPixel( nHeight - nOldHeight )

   endif

   nElem := 0
   if !empty( oER:oTree )
      For i = 1 to Len( oER:oTree:aItems )
          cTemp1 := Left( oER:oTree:aItems[ i ][ 5 ], At( ".", oER:oTree:aItems[ i ][ 5 ] ) )
          cTemp2 := Right( oER:oTree:aItems[ i ][ 5 ], Len( oER:oTree:aItems[ i ][ 5 ] ) - At( ".", oER:oTree:aItems[ i ][ 5 ] ) - 1 )
          if RTrim( cTemp2 ) == RTrim( cOldTitle )
             nElem := i
             i := Len( oER:oTree:aItems ) + 1
          endif
      Next i
      // Sustituir Caption del elemento
      if !empty( nElem )
         // 2 -> hWnd   3 -> Object   4 -> Array   5 -> Caption
         //? TVGetText( oER:oTree:hWnd, oER:oTree:aItems[ nElem ][ 2 ] )

         TVSetItemText( oER:oTree:hWnd, oER:oTree:aItems[ nElem ][ 2 ], cTemp1 + " " + cAreaTitle )
      endif
   ENDIF

return .T.

//----------------------------------------------------------------------------//

function AreaHide( nArea )

   local i, nDifferenz
   local nHideHeight := GetCmInch( 18 )
   local nAreaHeight := Val( GetPvProfString( "General", "Height", "300", oER:aAreaIni[ nArea ] ) )
   local nWidth      := Val( GetPvProfString( "General", "Width", "600", oER:aAreaIni[ nArea ] ) )

   oGenVar:aAreaHide[oER:nAktArea] := !oGenVar:aAreaHide[oER:nAktArea]

   nDifferenz := ( ER_GetPixel( nAreaHeight ) + nAreaZugabe - 18 ) * ;
                 IIF( oGenVar:aAreaHide[oER:nAktArea], -1, 1 )

   oER:aWnd[ nArea ]:Move( oER:aWnd[ nArea ]:nTop, oER:aWnd[ nArea ]:nLeft, ;
      IIF( oGenVar:lFixedAreaWidth, ER_GetPixel(MaxWidthAreas( nArea ))+ oER:nRuler + nAreaZugabe2 , ER_GetPixel( nWidth ) + oER:nRuler + nAreaZugabe2 ), ;
      IIF( oGenVar:aAreaHide[oER:nAktArea], 18, ER_GetPixel( nAreaHeight ) + nAreaZugabe ), .T. )

   for i := nArea+1 to Len( oER:aWnd )
      if oER:aWnd[ i ] <> nil
         oER:aWnd[ i ]:Move( oER:aWnd[ i ]:nTop + nDifferenz, oER:aWnd[ i ]:nLeft,,, .T. )
      endif
   next

   oEr:nTotalHeight += nDifferenz

return .T.

//----------------------------------------------------------------------------//

Function MaxWidthAreas( nArea )
Local nMax   := 0
Local i
For i = 1 to Len( oER:aWnd )
    if !empty( oER:aWnd[ i ] )
       nMax := Max( nMax, oGenVar:aAreaSizes[ i, 1 ] )
    endif
Next i
/*
For i = 1 to Len( oER:aWnd )
    if !empty( oER:aWnd[ i ] )
    oGenVar:aAreaSizes[ i, 1 ] := nMax
    endif
Next i
*/
Return nMax

//------------------------------------------------------------------------------
Function DlgStatusBar(oDlg, nHeight, nCorrec , lColor )
Local nDlgHeight := oDlg:nHeight
Local aColor     := { { 0.40, nRGB( 200, 200, 200 ), nRGB( 184, 184, 184 ) },;
                    { 0.60, nRGB( 184, 184, 184 ), nRGB( 150, 150, 150 ) } }

DEFAULT nHeight  := 72
DEFAULT nCorrec  := 0
DEFAULT lColor   := .F.

nDlgHeight:= nDlgHeight+ncorrec
IF lColor
   GradienTfill(oDlg:hDC,nDlgHeight-( nHeight-2 ),0,nDlgHeight-20,oDlg:nWidth, aColor ,.t.)
   WndBoxIn( oDlg:hDc,nDlgHeight-( nHeight-1 ),0,nDlgHeight-( nHeight ),oDlg:nWidth )
ELSE
   WndBoxIn( oDlg:hDc,nDlgHeight -( nHeight-1 ),4,nDlgHeight-( nHeight ),oDlg:nWidth - 10 )
endif

Return Nil

//------------------------------------------------------------------------------

FUNCTION DlgBarTitle( oWnd, cTitle, cBmp ,nHeight )
   LOCAL oFont
   LOCAL oTitle
   LOCAL nColText := 180
   LOCAL nRowImg  := 16

   DEFAULT cTitle  := ""
   DEFAULT nHeight := 48

   IF nHeight < 48
      nColText := 60
      nRowImg  := 12
      DEFINE FONT oFont NAME "Arial" size 10, 30
   ELSE
      DEFINE FONT oFont NAME "Arial" size 12, 30
   endif

    @ -1, -1  TITLE oTitle size oWnd:nWidth+1, nHeight+1 of oWnd SHADOWSIZE 0

    @  nRowImg,  10  TITLEIMG  OF oTitle BITMAP cBmp  SIZE 30, 30 REFLEX ;
       TRANSPARENT

    @  nRowImg-2 ,  nColText TITLETEXT OF oTitle TEXT cTitle COLOR CLR_BLACK FONT oFont

    oTitle:aGrdBack := { { 1, RGB( 255, 255, 255 ), RGB( 229, 233, 238 )  } }
    oTitle:nShadowIntensity = 0
    oTitle:nShadow = 0
    oTitle:nClrLine1 := nrgb(0,0,0)
    oTitle:nClrLine2 := RGB( 229, 233, 238 )
    oWnd:oTop:= oTitle

RETURN oTitle

//------------------------------------------------------------------------------

static function DoBreak( oError )

   local cInfo := oError:operation, n

   if ValType( oError:Args ) == "A"
      cInfo += "   Args:" + CRLF
      for n = 1 to Len( oError:Args )
         MsgInfo( oError:Args[ n ] )
         cInfo += "[" + Str( n, 4 ) + "] = " + ValType( oError:Args[ n ] ) + ;
                   "   " + cValToChar( oError:Args[ n ] ) + CRLF
         close all
         exit
      next
   endif

   MsgStop( oError:Description + CRLF + cInfo,;
            "Script error at line: " + AllTrim( Str( ProcLine( 2 ) ) ) )

   BREAK

return nil

//----------------------------------------------------------------//

#pragma BEGINDUMP

#include <stdio.h>
#include <hbapi.h>

HB_FUNC( FREOPEN_STDERR )
{
   hb_retnl( ( HB_LONG ) freopen( hb_parc( 1 ), hb_parc( 2 ), stderr ) );
}

#pragma ENDDUMP

//----------------------------------------------------------------------------//

// TScript

CLASS TErScript

   DATA cCode
   DATA cError
   DATA lPreProcess INIT .f.
   DATA oHrb
   DATA cFwHPath, cHarbourPath

   METHOD New( cCode ) CONSTRUCTOR
   METHOD Compile()
   METHOD Run(p1,p2,p3,p4)

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( cCode, cFwHPath, cHarbourPath  ) CLASS TErScript
   DEFAULT cFwHPath := "c:\fwh"
   DEFAULT cHarbourPath := "c:\harbour"

   ::cCode := cCode
   ::cFwHPath := cFwHPath
   ::cHarbourPath := cHarbourPath

   IF Empty ( ::cCode )
      Msginfo("no ha definido texto a compilar")
   endif

return Self

//----------------------------------------------------------------------------//

METHOD Compile() CLASS TErScript

   IF ::lPreProcess
      ::oHrb := HB_CompileFromBuf( ::cCode , "-n", "-I"+::cFwHPath+"\include", "-I"+::cHarbourPath+"\include","-o" )
   ELSE
      ::oHrb := HB_CompileFromBuf( ::cCode , "-n", "-I"+::cFwHPath+"\include", "-I"+::cHarbourPath+"\include" )
   ENDIF

RETURN nil

//----------------------------------------------------------------------------//

METHOD Run(p1,p2,p3,p4) CLASS TErScript
   local cResult, bOldError

  //  MemoEdit( cCode, "PRG code" )
  //  MemoWrit( "_temp.prg", (Scripts)->Code )

   FReOpen_Stderr( "comp.log", "w" )

   ::compile()

   ::cError := MemoRead( "comp.log" )

   //::oHrb = HB_CompileFromBuf( ::cCode , "-n", "-Ic:\fwh\include", "-Ic:\harbour\include" )
   //  oResult:SetText( If( Empty( cResult := MemoRead( "comp.log" ) ), "ok", cResult ) )

   if ! Empty( ::oHrb )
      BEGIN SEQUENCE
      bOldError = ErrorBlock( { | o | DoBreak( o ) } )
      hb_HrbRun( ::oHrb, p1,p2,p3,p4 )
      END SEQUENCE
      ErrorBlock( bOldError )
   endif

RETURN nil


//----------------------------------------------------------------------------//



//----------------------------------------------------------------------------//
// TEasyReport -> oER

CLASS TEasyReport

   DATA oMainWnd
   DATA aWnd, aWndTitle
   DATA cGeneralIni, cDefIni
   DATA cDataPath, cPath, cTmpPath, cDefIniPath
   DATA bClrBar
   DATA aClrDialogs, nDlgTextCol, nDlgBackCol
   DATA nClrPaneTree
   DATA nMeasure, cMeasure
   DATA oAppFont
   DATA lShowPanel
   DATA nRuler
   DATA nRulerTop
   DATA nTotalHeight, nTotalWidth
   DATA oTree
   DATA oFldI, oFldD
   DATA oPanelD, oPanelI
   DATA lReexec INIT .F.
   DATA nTotAreas
   DATA lFillWindow
   DATA nRedoCount, nUndoCount
   DATA lBeta, nDeveloper
   DATA oMru
   DATA lDClkProperties
   DATA oMsgInfo
   DATA aFonts
   DATA aAreaIni
   DATA aRuler
   DATA lShowToolTip
   DATA oBrwProp,oSaySelectedItem
   DATA aSelection
   DATA aItems
   DATA nAktArea
   DATA lNewFormat

   METHOD New() CONSTRUCTOR
   METHOD GetGeneralIni( cSection , cKey, cDefault ) INLINE GetPvProfString( cSection, cKey, cDefault, ::cGeneralIni )
   METHOD GetDefIni( cSection , cKey, cDefault ) INLINE GetPvProfString( cSection, cKey, cDefault, ::cDefIni )
   METHOD GetColor( nNr ) INLINE  Val( GetPvProfString(  "Colors", AllTrim(STR( nNr, 5 )), "", ::cDefIni ) )
   METHOD SetGeneralPreferences()
   METHOD SetScrollBar()
   METHOD ScrollV( nPosZugabe, lUp, lDown, lPos )
   METHOD ScrollH( lLeft, lRight, lPageLeft, lPageRight, lPos, nPosZugabe )
   METHOD FillWindow( nArea, cAreaIni )
   METHOD SetReticule( nRow, nCol, nArea )

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New() CLASS TEasyReport

   ::cGeneralIni  := ".\vrd.ini"
   ::cPath:=  cFilePath( GetModuleFileName( GetInstance() ) )
   ::cDataPath    := ::cPath + "Datas\"
   ::cTmpPath:= GetEnv("TMP")+'\ERTMP\'

   //msginfo(::cTmpPath)
   IF lisDir(::cTmpPath)
      DelTempFiles(::cTmpPath )
      dirRemove( ::cTmpPath  )
   endif

   MakeDir(::cTmpPath )

   //::lShowPanel   := .T.
   //::lShowToolTip := .T.

   ::nTotAreas    := 100

   ::lFillWindow  := .F.

   ::nClrPaneTree := RGB( 229, 233, 238)
   ::nDlgTextCol  := RGB( 255, 255, 255 )
   ::nDlgBackCol  := RGB( 150, 150, 150 )

   ::bClrBar =  { | lInvert | If( ! lInvert,;
                                  { { 1, RGB( 255, 255, 255 ), RGB( 229, 233, 238 ) } },;
                                  { { 2/5, RGB( 255, 253, 222 ), RGB( 255, 231, 147 ) },;
                                    { 3/5, RGB( 255, 215,  86 ), RGB( 255, 231, 153 ) } } ) }

   //  ::bClrBar := { | lInvert | If( ! lInvert,;
   //                                 { { 0.50, nRGB( 254, 254, 254 ), nRGB( 225, 225, 225 ) },;
   //                                   { 0.50, nRGB( 225, 225, 225 ), nRGB( 185, 185, 185 ) } },;
   //                                 { { 0.40, nRGB( 68, 68, 68 ), nRGB( 109, 109, 109 ) }, ;
   //                                   { 0.60, nRGB( 109, 109, 109 ), nRGB( 116, 116, 116 ) } } ) }

   ::aClrDialogs = { { 1, RGB( 199, 216, 237 ), RGB( 237, 242, 248 ) } }

  //  ::aColorDlg :=  { { 1, RGB( 199, 216, 237 ), RGB( 237, 242, 248 ) } }

  //   ::aColorDlg :=  { { 0.60,  nRGB( 221, 227, 233) ,  nRGB( 221, 227, 233 ) }, ;
  //                        { 0.40,nRGB( 221, 227, 233), nRGB( 221, 227, 233) } }

  ::lDClkProperties   := .t.    // Seleccionar edicion de propiedades Areas o Items

   DEFINE FONT ::oAppFont NAME "Arial" SIZE 0, -12


 return Self

//------------------------------------------------------------------------------

METHOD SetGeneralPreferences() CLASS TEasyReport
   local i, oDlg, oIni, cLanguage, cOldLanguage, cWert, aCbx[5], oRad1
   local lSave         := .F.
   local lInfo         := .F.
   local nLanguage     := Val( ::GetGeneralIni( "General", "Language"  , "1" ) )
   local lMaximize     := IIf ( Val( ::GetGeneralIni( "General", "Maximize"  , "1" ) ) == 1 , .T., .F. )
   local nMruList      := Val( ::GetGeneralIni( "General", "MruList"  , "4" ) )
   local aLanguage     := {}
   local lShowReticule := oGenVar:lShowReticule
   local lShowBorder   := oGenVar:lShowBorder
   LOCAL lShowPanel  := ( ::GetGeneralIni( "General", "ShowPanel", "1" ) = "1" )
   local cPicture      := IIF( ::nMeasure = 2, "999.99", "99999" )
   local nDecimals     := IIF( ::nMeasure = 2, 2, 0 )

   for i := 1 to 99
      cWert := ::GetGeneralIni( "Languages", AllTrim(STR(i,2)), "" )
      if !Empty( cWert )
         AADD( aLanguage, cWert )
      endif
   next

   if Len( aLanguage ) > 0
      cLanguage    := aLanguage[IIF( nLanguage < 1, 1, nLanguage)]
      cOldLanguage := cLanguage
   endif

   DEFINE DIALOG oDlg NAME "GENERALPREFERENCES" TITLE GL("Preferences")

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE COMBOBOX cLanguage ITEMS aLanguage ID 201 OF oDlg
   REDEFINE CHECKBOX aCbx[ 1 ] VAR lMaximize ID 202 OF oDlg
   REDEFINE GET nMruList  ID 203 OF oDlg PICTURE "99" SPINNER MIN 0 VALID nMruList >= 0
   REDEFINE BUTTON PROMPT GL("Clear list") ID 204 OF oDlg ACTION oER:oMru:Clear()

   REDEFINE CHECKBOX aCbx[3] VAR lShowBorder ID 205 OF oDlg ;
      ON CHANGE IIF( lInfo = .F., ;
                     ( MsgInfo( GL("Please restart the programm to activate the changes."), ;
                                GL("Information") ), lInfo := .T. ), )

   REDEFINE CHECKBOX aCbx[4] VAR lShowReticule ID 206 OF oDlg

   REDEFINE CHECKBOX aCbx[5] VAR lShowPanel ID 308 OF oDlg

   REDEFINE SAY PROMPT GL("Language:")        ID 170 OF oDlg
   REDEFINE SAY PROMPT GL("Entries")          ID 180 OF oDlg

   REDEFINE SAY PROMPT " " + GL("List of most recently used files") + ":" ID 179 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( aCbx[ 1 ]:SetText( GL("Maximize window at start") ), ;
                aCbx[3]:SetText( GL("Show always text border") ), ;
                aCbx[4]:SetText( GL("Show reticule")  ) ,;
                DlgBarTitle( oDlg, GL("Preferences"), "B_EDIT32",44 ) ) ;
      ON PAINT  DlgStatusBar(oDlg, 68,, .t. )

   if lSave

      oGenVar:lShowReticule := lShowReticule
      oGenVar:lShowBorder   := lShowBorder

      INI oIni FILE oER:cGeneralIni
         SET SECTION "General" ENTRY "MruList"        to AllTrim(STR( nMruList ))       OF oIni
         SET SECTION "General" ENTRY "Maximize"       to IIF( lMaximize    , "1", "0")  OF oIni
         SET SECTION "General" ENTRY "ShowTextBorder" to IIF( lShowBorder  , "1", "0" ) OF oIni
         SET SECTION "General" ENTRY "ShowReticule"   to IIF( lShowReticule, "1", "0" ) OF oIni
         SET SECTION "General" ENTRY "ShowPanel"      to IIF( lShowPanel, "1", "0" ) OF oIni

         if cLanguage <> cOldLanguage
            SET SECTION "General" ENTRY "Language" to ;
               AllTrim(STR(ASCAN( aLanguage, cLanguage ), 2)) OF oIni
         endif

      ENDINI

      for i := 1 to Len( ::aWnd )
         if ::aWnd[ i ] <> nil
            ::aWnd[ i ]:Refresh()
         endif
      next

      ::oMainWnd:SetMenu( BuildMenu() )

    //  SetSave( .F. )

      SetSave( .T. )
      msgInfo("el programa se reiniciara para que los cambios tengan efecto")
      ::oMainWnd:END()
      ::lReexec  := .t.

   endif

return .T.

//------------------------------------------------------------------------------

METHOD SetScrollBar() CLASS TEasyReport

   //local oVScroll
   local nPageZugabe //:= 392/100
   local oWnd        := ::oMainWnd:oWndClient

   if !Empty( oWnd:oVScroll )

      oWnd:oVScroll := ER_ScrollBar():WinNew(0,100,10,.T., oWnd )

      oWnd:oVScroll:bGoUp     = { || ::ScrollV( -1 )  }
      oWnd:oVScroll:bGoDown   = { || ::ScrollV( 1 )   }
      oWnd:oVScroll:bPageUp   = { || ::ScrollV( -4 )  }
      oWnd:oVScroll:bPageDown = { || ::ScrollV( 4 )   }
      oWnd:oVScroll:bPos      = { | nWert | ::ScrollV( nWert )  }
      oWnd:oVScroll:nPgStep   = 10

      oWnd:oVScroll:SetPos( 0 )

 ENDIF

   if ! Empty( oWnd:oHScroll )
      nPageZugabe := 602/100
      oWnd:oHScroll:SetRange( 0, oEr:nTotalWidth / 100 )

      oWnd:oHScroll:bGoUp     = {|| ::ScrollH( .T. ) }
      oWnd:oHScroll:bGoDown   = {|| ::ScrollH( , .T. ) }
      oWnd:oHScroll:bPageUp   = {|| ::ScrollH( ,, .T. ) }
      oWnd:oHScroll:bPageDown = {|| ::ScrollH( ,,, .T. ) }
      oWnd:oHScroll:bPos      = {| nWert | ::ScrollH( ,,,, .T., nWert/100 ) }
      oWnd:oHScroll:nPgStep   = nPageZugabe  //602

      oWnd:oHScroll:SetPos( 0 )
   endif


return .T.

//----------------------------------------------------------------------------//

METHOD ScrollV( nPosZugabe, lUp, lDown, lPos ) CLASS TEasyReport
   Local i
   Local aFirstWndCoors
   Local nAltWert
   Local nZugabe     := 14
   Local nPageZugabe := 392
   Local aCliRect    := ::oMainWnd:GetCliRect()
   Local lReticule
   Local oVScroll    := ::oMainWnd:oWndClient:oVScroll

   DEFAULT lUp       := .F.
   DEFAULT lDown     := .F.
   DEFAULT lPos      := .F.

   UnSelectAll()

    for i := 1 to Len( ::aWnd )
      if ::aWnd[ i ] <> nil
         aFirstWndCoors := GetCoors( ::aWnd[ i ]:hWnd )
         EXIT
      endif
   next

   if lUp
      if aFirstWndCoors[ 1 ] = 0
         nZugabe := 0
      elseif aFirstWndCoors[ 1 ] + IIF( lUp, nZugabe, nPageZugabe ) >= 0
         nZugabe     := -1 * aFirstWndCoors[ 1 ]
         nPageZugabe := -1 * aFirstWndCoors[ 1 ]
      endif
   endif

   if lDown
      if aFirstWndCoors[ 1 ] + (oEr:nTotalHeight) <= aCliRect[3] - 80
         nZugabe     := 0
         nPageZugabe := 0
      endif
   endif


   lReticule = oGenVar:lShowReticule
   oGenVar:lShowReticule = .F.
   ::SetReticule( 0, 0 ) // turn off the rulers lines


   nAltWert := IF ( lPos, oVScroll:GetPos(), oVScroll:nPrevPos )

   oVScroll:SetPos( nPosZugabe )
   nZugabe := ::nTotalHeight * ( oVScroll:GetPos() - nAltWert ) / ( (::nTotalHeight) / 100 )

   for i := 1 to Len( ::aWnd )
      if ::aWnd[ i ] <> nil
         ::aWnd[ i ]:Move( ::aWnd[ i ]:nTop - Int(nZugabe/10), ::aWnd[ i ]:nLeft, 0, 0, .T. )
      endif
   next

   oGenVar:lShowReticule = lReticule

return .T.

//----------------------------------------------------------------------------//

METHOD ScrollH( lLeft, lRight, lPageLeft, lPageRight, lPos, nPosZugabe ) CLASS TEasyReport

   local i
   local aFirstWndCoors
   local nAltWert
   local nZugabe     := 14
   local nPageZugabe := 602
   local aCliRect    := ::oMainWnd:GetCliRect()

   DEFAULT lLeft      := .F.
   DEFAULT lRight     := .F.
   DEFAULT lPageLeft  := .F.
   DEFAULT lPageRight := .F.
   DEFAULT lPos       := .F.

   UnSelectAll()

   for i := 1 to Len( ::aWnd )
      if ::aWnd[ i ] <> nil
         aFirstWndCoors := GetCoors( ::aWnd[ i ]:hWnd )
         EXIT
      endif
   next

   if lLeft  .OR. lPageLeft
      if aFirstWndCoors[2] = 0
         nZugabe := 0
      elseif aFirstWndCoors[2] + IIF( lLeft, nZugabe, nPageZugabe ) >= 0
         nZugabe     := -1 * aFirstWndCoors[2]
         nPageZugabe := -1 * aFirstWndCoors[2]
      endif
   endif

   if lRight .OR. lPageRight
      if aFirstWndCoors[2] + ::nTotalWidth <= aCliRect[4] - 40
         nZugabe     := 0
         nPageZugabe := 0
      endif
   endif

   if lPos
      nAltWert := ::oMainWnd:oWndClient:oHScroll:GetPos()
      ::oMainWnd:oWndClient:oHScroll:SetPos( nPosZugabe )
      nZugabe := -1 * ::nTotalWidth * ( ::oMainWnd:oWndClient:oHScroll:GetPos() - nAltWert ) / 100
   endif


   for i := 1 to Len( oER:aWnd )
      if oER:aWnd[ i ] <> nil
         if lLeft .OR. lPos
            oER:aWnd[ i ]:Move( oER:aWnd[ i ]:nTop, oER:aWnd[ i ]:nLeft + nZugabe , 0, 0, .T. )
         elseif lRight
            oER:aWnd[ i ]:Move( oER:aWnd[ i ]:nTop, oER:aWnd[ i ]:nLeft - nZugabe , 0, 0, .T. )
         elseif lPageLeft
            oER:aWnd[ i ]:Move( oER:aWnd[ i ]:nTop, oER:aWnd[ i ]:nLeft + nPageZugabe, 0, 0, .T. )
         elseif lPageRight
            oER:aWnd[ i ]:Move( oER:aWnd[ i ]:nTop, oER:aWnd[ i ]:nLeft - nPageZugabe, 0, 0, .T. )
         endif
      endif
   next

return .T.

//----------------------------------------------------------------------------//

METHOD FillWindow( nArea, cAreaIni ) CLASS TEasyReport

   local i
   local cRuler1
   local cRuler2
   local aWerte
   local nEntry
   local nTmpCol
   local nFirstTop
   local nFirstLeft
   local nFirstWidth
   local nFirstHeight
   local nFirstItem
   local aFirst      := { .F., 0, 0, 0, 0, 0 }
   local nElemente   := 0
   local aIniEntries
   local oRulerBmp1
   local oRulerBmp2
   local oRulerBmp3
   LOCAL  cTitle

   msginfo(cAreaIni)

   IF ::lNewFormat
      aIniEntries := GetIniSection( cAreaIni+"Items", oER:cDefIni )
   ELSE
      aIniEntries := GetIniSection( "Items", cAreaIni )
   ENDIF

// cTool  := if( nRow < 34, "Propiedades Area: " + Str( aWnd[ nArea ]:nArea, 10 ), "" ), ;

   ::nMeasure  := if( empty( ::nMeasure ), 1, ::nMeasure )
   //Ruler anzeigen
   if ::nMeasure = 1 ; cRuler1 := "RULER1_MM" ; cRuler2 := "RULER2_MM" ; endif
   if ::nMeasure = 2 ; cRuler1 := "RULER1_IN" ; cRuler2 := "RULER2_IN" ; endif
   if ::nMeasure = 3 ; cRuler1 := "RULER1_PI" ; cRuler2 := "RULER2_PI" ; endif

   @ 0, 0 SAY " " SIZE 1200, ::nRulerTop - ::nRuler PIXEL ;
      COLORS 0, oGenVar:nBClrAreaTitle OF oER:aWnd[ nArea ]

   @ 2,  3 BTNBMP RESOURCE "AREAMINMAX" SIZE 12,12 ACTION  oEr:nAktArea:= nArea, AreaHide( oEr:nAktArea )
   @ 2, 17 BTNBMP RESOURCE "AREAPROP"   SIZE 12,12 ACTION  oEr:nAktArea:= nArea, AreaProperties( oEr:nAktArea )

   @ 2, 29 SAY oGenVar:aAreaTitle[ nArea ] ;
      PROMPT " " + AllTrim( GetDataArea( "General", "Title","", cAreaIni ) ) + Space( 14 ) + ;
      "Ancho: " + Str( oGenVar:aAreaSizes[ nArea, 1 ] ) + "    " + ;
      "Alto: " + Str( oGenVar:aAreaSizes[ nArea, 2 ] ) ;
      SIZE 400, ::nRulerTop - ::nRuler - 2 PIXEL FONT oGenVar:aAppFonts[ 1 ] ;
      COLORS oGenVar:nF2ClrAreaTitle, oGenVar:nBClrAreaTitle OF oER:aWnd[ nArea ]

   @ ::nRulerTop - ::nRuler,  0 BITMAP oRulerBmp2 RESOURCE cRuler2 ;
      OF oER:aWnd[ nArea ] PIXEL NOBORDER

   //@ ::nRulerTop - ::nRuler, 20 BITMAP oRulerBmp3 RESOURCE cRuler2 ;
   //   OF aWnd[ nArea ] PIXEL NOBORDER

   @ ::nRulerTop - ::nRuler, 20 BITMAP oRulerBmp1 RESOURCE cRuler1 ;
      OF oER:aWnd[ nArea ] PIXEL NOBORDER

   oRulerBmp1:bLClicked := { |nRow,nCol,nFlags| oEr:nAktArea := oER:aWnd[ nArea ]:nArea, ::oMainWnd:SetFocus() }
   oRulerBmp2:bLClicked := oRulerBmp1:bLClicked

   oER:aWnd[ nArea ]:bPainted   = {| hDC, cPS | ZeichneHintergrund( nArea ) }

   oER:aWnd[ nArea ]:bGotFocus  = { || SetTitleColor( .F., nArea ), RefreshBrwAreaProp(nArea) }
   oER:aWnd[ nArea ]:bLostFocus = { || SetTitleColor( .T., nArea ) }

   oER:aWnd[ nArea ]:bMMoved = {|nRow,nCol,nFlags| ;
                           MsgBarInfos( nRow, nCol, nArea ), ;
                           MoveSelection( nRow, nCol, oER:aWnd[ nArea ] ) ,;
                           if(!lScrollVert, ::SetReticule( nRow, nCol, nArea ), ::SetReticule( 0, 0, nArea )),;
                           lScrollVert :=  .F. }

   oER:aWnd[ nArea ]:bRClicked = {|nRow,nCol,nFlags| oEr:nAktArea := oER:aWnd[ nArea ]:nArea, ::oMainWnd:SetFocus(),;
                                                 PopupMenu( nArea,, nRow, nCol ) }


    oER:aWnd[ nArea ]:bLClicked = {|nRow,nCol,nFlags| DeactivateItem(), ;
                              IIF( GetKeyState( VK_SHIFT ),, UnSelectAll() ), ;
                              StartSelection( nRow, nCol, oER:aWnd[ nArea ] ), ;
                              oEr:nAktArea := oER:aWnd[ nArea ]:nArea,;
                              swichItemsArea( nArea, .t. ) ,;
                              ::oMainWnd:SetFocus() ,;
                              swichItemsArea( nArea, .f. )  }


   oER:aWnd[ nArea ]:bLButtonUp = {|nRow,nCol,nFlags| StopSelection( nRow, nCol, oER:aWnd[ nArea ] ) }

   oER:aWnd[ nArea ]:bKeyDown   = {|nKey| WndKeyDownAction( nKey, nArea, cAreaIni ) }

   oRulerBmp1:bRClicked    := oER:aWnd[ nArea ]:bRClicked
   oRulerBmp2:bRClicked    := oER:aWnd[ nArea ]:bRClicked

   ::aRuler[ nArea , 1 ]     := oRulerBmp1
   ::aRuler[ nArea , 2 ]     := oRulerBmp2

   for i := 1 to LEN( aIniEntries )
      nEntry := EntryNr( aIniEntries[ i ] )
      if nEntry <> 0
         ShowItem( nEntry, nArea, cAreaIni, @aFirst, @nElemente, aIniEntries, i )
      endif
   next

   //Durch diese Anweisung werden alle Controls resizable
   if nElemente <> 0
      ::lFillWindow := .T.
      ::aItems[ nArea,aFirst[6]]:CheckDots()
      ::aItems[ nArea,aFirst[6]]:Move( aFirst[2], aFirst[3], aFirst[4], aFirst[5], .T. )
      ::lFillWindow := .F.
   endif

   //oER:aWnd[ nArea ]:oToolTip := ER_TooltipAr( nArea, cRuler1 )
   /*
   oER:aWnd[ nArea ]:cToolTip := "Titulo:           " + Chr( 9 ) + Left( oGenVar:aAreaTitle[ nArea ]:cCaption, 28 ) + CRLF + ;
                  "Unidad Medida:    " + Chr( 9 ) + Right( RTrim( cRuler1 ), 2 ) + CRLF + ;
                  "Top:              " + Chr( 9 ) + Str( oER:aWnd[ nArea ]:nTop, 10 ) + CRLF
   */

   //Memory(-1)
   //SysRefresh()

return .T.

//----------------------------------------------------------------------------//

METHOD SetReticule( nRow, nCol, nArea ) CLASS TEasyReport

   local nRowPos := nRow
   local nColPos := nCol
   local lShow   := ( oGenVar:lShowReticule .and. !oGenVar:lSelectItems )

   if nRow <= ::nRulerTop
      nRowPos := ::nRulerTop
   elseif nRow >= ER_GetPixel( oGenVar:aAreaSizes[ nArea, 2 ] ) + ::nRulerTop
      nRowPos := ER_GetPixel( oGenVar:aAreaSizes[ nArea, 2 ] ) + ::nRulerTop
   endif

   if nCol <= ::nRuler
      nColPos := ::nRuler
   elseif nCol >= ER_GetPixel( oGenVar:aAreaSizes[ nArea, 1 ] ) + ::nRuler
      nColPos := ER_GetPixel( oGenVar:aAreaSizes[ nArea, 1 ] ) + ::nRuler
   endif

   if lShow
      DrawRulerHorzLine( oER:aWnd[ nArea ], nRowPos )

      AEval( oER:aWnd, { | oWnd | If( oWnd != nil, DrawRulerVertLine( oWnd, nColPos ),) } )
   endif

return .T.

//----------------------------------------------------------------------------//


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

   oER:SetReticule( nRow, nCol, ::nArea )

return nil


//----------------------------------------------------------------------------//

#define SB_HORZ         0
#define SB_VERT         1
#define SB_CTL          2

CLASS ER_ScrollBar FROM TScrollBar

   DATA   nPrevPos

   METHOD SetPos( nPos ) INLINE ;
                 ::nPrevPos:= ::GetPos() ,;
                 SetScrollPos( if( ::lIsChild, ::oWnd:hWnd, ::hWnd ),;
                 If( ::lIsChild, If( ::lVertical, SB_VERT, SB_HORZ ), SB_CTL ),;
                 nPos, ::lReDraw )

ENDCLASS

//----------------------------------------------------------------------------//

Function ER_TooltipAr( nArea, cRuler1 )
   local cTool  := ""
   local oTT

   oTT    := TC5Tooltip():New( 100, 100, 250, 150, oER:aWnd[ nArea ] , .T., CLR_CYAN, CLR_WHITE )

   cTool       := "Titulo:           " + Chr( 9 ) + Left( oGenVar:aAreaTitle[ nArea ]:cCaption, 28 ) + CRLF + ;
                  "Unidad Medida:    " + Chr( 9 ) + Right( RTrim( cRuler1 ), 2 ) + CRLF + ;
                  "Top:              " + Chr( 9 ) + Str( oER:aWnd[ nArea ]:nTop, 10 ) + CRLF

   oTT:cHeader  := "Propiedades Area: " + Chr( 9 ) + Str( oER:aWnd[ nArea ]:nArea, 10 ) //+ CRLF + ;
   oTT:cBody    := cTool
   oTT:cFoot    := " "
   //oTT:cBmpFoot := "..\bitmaps\16x16\help.bmp"
   //oTT:cBmpLeft := "..\bitmaps\32x32\calendar.bmp"

   oTT:lLineHeader = .T.
   oTT:lBtnClose   = .T.
   oTT:lSplitHdr   = .T.
   oTT:lBorder     = .T.

Return oTT

//----------------------------------------------------------------------------//

