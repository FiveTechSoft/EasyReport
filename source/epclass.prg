/*
    ==================================================================
    EasyPreview 1.6.3
    ------------------------------------------------------------------
    Authors: Jürgen Bäz
             Timm Sodtalbers
    ------------------------------------------------------------------
    TODO:
      Spanish help file aktualisieren
      EP_SetPath muss immer gesetzt werden
      Marco: your preview know only the paper orientation on the first page,
             if I print the first page in Landscape and the second in Portrait
             all the pages will be printed as Landscape.

    Version 2.0:
      - [MenuBar]: BackgroundColor1 und BackgroundColor2
      - Briefpapier/Wasserzeichen einbinden
      - Save as DOC and HTML file (create a blank file and insert the image files)
      - Zoomen mit Lasso
      - Zoom/Unzoom und die 1/2/4/6/8-Seitenauswahl entfernen und nur
        eine Combobox mit: Seitenbreite, ganze Seite, zwei Seiten,
                           vier Seiten, ... , 100%, 120%, ...
      - Setup-Dialog: Hintergrundfarbe, Schatteneigenschaften,
                      PageBorder-Eigenschaften, Maximieren ja/nein,
                      Sprache, Zoomschritte, E-Mail-Optionen
      - Unterschiedliche "Skins" für Buttonbar ermöglichen
      - Lineal (Ruler) einbauen
      - nPageBorColor wirksam werden lassen
      - Thumbnails (wie beim Acrobat Reader)
    ==================================================================
*/

STATIC lEasyReport      := .F.
STATIC lShowSaveMessage := .F.

#INCLUDE "FiveWin.ch"
#INCLUDE "fileio.ch"
#INCLUDE "richedit.ch"

#IFDEF __HARBOUR__
//  #INCLUDE "davinci.ch"
#ENDIF

#DEFINE PAGE_NEXT    1
#DEFINE PAGE_PREV    2
#DEFINE PAGE_TOP     3
#DEFINE PAGE_BOTTOM  4
#DEFINE PAGE_GOTO    5

#DEFINE META_PIXEL   1
#DEFINE META_010MM   2

#DEFINE GO_POS       0
#DEFINE GO_UP        1
#DEFINE GO_DOWN      2
#DEFINE GO_LEFT      1
#DEFINE GO_RIGHT     2
#DEFINE GO_PAGE      .T.

STATIC oMenuUnZoom, nZFactor, nLanguage, aLanguages, hLib

*-- FUNCTION -----------------------------------------------------------------
* Name........: EasyPreview
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------

FUNCTION EasyPreview( oDevice, cPrinter, cPrevIni )

   LOCAL oPrev := EPREVIEW():NEW( oDevice, cPrinter, cPrevIni )

RETURN (.T.)


*-- CLASS DEFINITION ---------------------------------------------------------
*         Name: EPREVIEW
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
CLASS EPREVIEW

   DATA lDemo, lLandscape, lZoom, lNoBorder, lMaximize, lMultiPrev
   DATA lNoMenuIcons, lMenuBarExtern, lDelAfterMail, lSClickZoom
   DATA lSaveWindowPos, lSetParent, lShowSendTo, lShowInfoDlg, lUseDLL
   DATA lZoomAtStart, lSaveAtStart, lMailAtStart, lPDF, lShowSave
   DATA lSelectPrinter, lDelAfterMail, lOffice2007Look

   DATA lExtDemoMode AS LOGIC INIT .F.
   DATA lPageBorder  AS LOGIC INIT .T.

   DATA nTotalPages, nWidth, nHeight, nCopies, nOrientation, nPage, nxyfactor
   DATA nHorzRes, nVertRes, nVScrollSteps, nHScrollSteps, nBackClr, nSoftZoom
   DATA nPageBorColor, nPageBorStyle, nBarBackColor1, nBarBackColor2, nDirect
   DATA nMenuBarWidth, nMenuBarHeight, nShadow_Color, nPageOffset, nBin
   DATA nPaperType, nPrWidth, nPrHeight

   DATA nViewPages    AS NUMERIC INIT 1
   DATA nShadow_Deep  AS NUMERIC INIT 5
   DATA nShadow_Width AS NUMERIC INIT 5

   DATA cResFile INIT "EPreview.dll"
   DATA cIni, oDevice, cTmpPath, cMetaFormat, cPrinter, cDemoMessage
   DATA cAppName, cIcon, cMenuBarDir, cInfoSay, cBackBrush, cDocName
   DATA cTo, cCc, cBcc, cSubject, cLicenceFile, cSaveAsRTF

   DATA aFiles, aFilesSaved, aPageBtn, aMeta, aMenuPage, aFactor, aZoomFactor

   DATA oWnd, oBar, oPage, oTwoPages, oZoom, oMenuZoom, oFactor, oInfoDlg, oInfoSay
   DATA oSaveAsRTF

   DATA hEPWnd

   //wPDFControl license
   DATA cPDFLicName, cPDFLicCode, nPDFLicNr

   METHOD New( oDevice, cPrinter, cPrevIni ) CONSTRUCTOR
   METHOD End()

   METHOD ShowInfoDlg()
   METHOD EPShow()

   METHOD BarMenu()
   METHOD PageMenu()
   METHOD BuildMenu()

   METHOD PaintMeta()

   METHOD ChangePage( nTyp, lBarRefresh, nNewPage )
   METHOD ShowPages()
   METHOD SetPages( nPages, lMenu )
   METHOD GoToPage()

   METHOD Zoom( lMenu )
   METHOD SoftZoom( lPlus )

   METHOD RegInfos()
   METHOD Registration()

   METHOD PrintPage()
   METHOD PrintPrv( oDlg, nOption, nPageIni, nPageEnd, nCopies, aSelect, lPrinterSelect )
   METHOD PrintCurPage( oTempDevice, cPage )

   METHOD VScroll( nType, lPage, nSteps )
   METHOD HScroll( nType, lPage, nSteps )

   METHOD SetOrg1( nX, nY )
   METHOD SetOrg2( nX, nY, nPage )

   METHOD CheckKey( nKey, nFlags )

   METHOD SetFactor( nValue )

   METHOD PrViewSave( lFromSendTo, lDirectSave, nFromPage, nToPage )

   #IFDEF __HARBOUR__
      METHOD Img_Save( aSaveFiles, cFilename, cFormat, nCompress, lOverWrite, nOption, lZip, lFromSendTo )
      METHOD Img_Zip( aFiles, cFilename, lOverwrite )
      METHOD SavePreview( cFileName, aSaveFiles, aFileName, img_typ, img_option, oPDF, lOverWrite, aMeter, aVal, aText )
      METHOD SaveProcess( cFileName, aSaveFiles, aFileName, img_typ, img_option, oPDF, lOverWrite )
      METHOD SaveMessage( cFileName )
   #ENDIF

   METHOD Copy2Clipboard()

   METHOD Email( lDirectSave )
   METHOD EMailSend( oSay, cText )
   METHOD EMailFiles()
   METHOD EMailCc( cValue )
   METHOD EMailFileInfo()
   METHOD EMailTotalSize()
   METHOD TotalFileSize()
   METHOD CheckEMail( lZip, cFormat, nSaveFiles )
   METHOD EMailOptions()

   METHOD GetFactors( cFile )
   METHOD Watermark ( hDC )
   METHOD GetColor( cColor )
   METHOD TempFile()
   METHOD GetLanguages( cPrevIni )
   METHOD IsEven( nVal )
   METHOD GetWinCoords()
   METHOD SetWinCoords()

ENDCLASS


*-- METHOD -------------------------------------------------------------------
*         Name: New
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD New( oDevice, cPrinter, cPrevIni ) CLASS EPREVIEW

   LOCAL i, cBackClr, nZoom, cShadowClr, cExt, cNewFile, cPath, cIniFilePath
   LOCAL aTmpFiles, hDCOut, hOldMeta
   LOCAL aMeta     := {}

   IF !FILE( cPrevIni )
      MsgStop( EP_GL( "EPREVIEW.TMP not found"), EP_GL("Stop") )
      ::End()
      RETURN NIL
   ENDIF

   cIniFilePath := GetPvProfString( "General", "IniFilePath", "", cPrevIni )
   CursorWait()

   ::cPrinter       := cPrinter
   ::aMeta          := ARRAY( 8 )
   ::aMenuPage      := ARRAY( 5 )
   ::lDemo          := .F.
   ::aFilesSaved    := {}
   //::cIni           := GetPvProfString( "General", "IniFile", ".\EPREVIEW.INI", cPrevIni )
   ::cIni           := IIF( EMPTY( cIniFilePath ), ".", cIniFilePath ) + "\" + ;
                       GetPvProfString( "General", "IniFileName", "EPREVIEW.INI", cPrevIni )

   ::cLicenceFile   := GetPvProfString( "General", "LicenceFile", ".\EPREVIEW.LIZ", cPrevIni )

   ::lMaximize      := IIF( GetPvProfString( "General", "Maximize"       ,  "1", ::cIni ) = "1", .T., .F. )
   ::lMultiPrev     := IIF( GetPvProfString( "General", "MultiPreview"   ,  "0", ::cIni ) = "1", .T., .F. )
   ::lPageBorder    := IIF( GetPvProfString( "General", "PageBorder"     ,  "0", ::cIni ) = "1", .T., .F. )
   ::lZoomAtStart   := IIF( GetPvProfString( "General", "ZoomAtStart"    ,  "0", ::cIni ) = "1", .T., .F. )
   ::lSaveAtStart   := IIF( GetPvProfString( "General", "SaveAtStart"    ,  "0", ::cIni ) = "1", .T., .F. )
   ::lMailAtStart   := IIF( GetPvProfString( "General", "MailAtStart"    ,  "0", ::cIni ) = "1", .T., .F. )
   ::lSClickZoom    := IIF( GetPvProfString( "General", "SingleClickZoom",  "0", ::cIni ) = "1", .T., .F. )
   ::lSetParent     := IIF( GetPvProfString( "General", "SetParentWindow",  "0", ::cIni ) = "1", .T., .F. )
   ::lNoMenuIcons   := IIF( GetPvProfString( "General", "NoMenuIcons"    ,  "0", ::cIni ) = "1", .T., .F. )
   ::nPageBorStyle  := VAL( GetPvProfString( "General", "PageBorderStyle",  "2", ::cIni ) )
   ::nShadow_Deep   := VAL( GetPvProfString( "General", "ShadowDepth"    ,  "5", ::cIni ) )
   ::nShadow_Width  := VAL( GetPvProfString( "General", "ShadowWidth"    ,  "5", ::cIni ) )
   ::nVScrollSteps  := VAL( GetPvProfString( "General", "VScrollSteps"   , "20", ::cIni ) )
   ::nHScrollSteps  := VAL( GetPvProfString( "General", "HScrollSteps"   , "20", ::cIni ) )
   ::nPageOffset    := VAL( GetPvProfString( "General", "PageOffset"     , "12", ::cIni ) )
   ::nDirect        := VAL( GetPvProfString( "General", "Direct"         ,  "0", ::cIni ) )
   ::lSaveWindowPos := ( GetPvProfString( "General", "SaveWindowCoords"  ,  "0", ::cIni ) = "1" )
   ::lShowInfoDlg   := ( GetPvProfString( "General", "ShowMsgBoxAtStart" ,  "0", ::cIni ) = "1" )
   ::lNoBorder      := IIF( GetPvProfString( "MenuBar", "NoBorder"       ,  "0", ::cIni ) = "1", .T., .F. )
   ::nMenuBarWidth  := VAL( GetPvProfString( "MenuBar", "Width"          , "30", ::cIni ) )
   ::nMenuBarHeight := VAL( GetPvProfString( "MenuBar", "Height"         , "30", ::cIni ) )
   ::lMenuBarExtern := ( GetPvProfString( "MenuBar", "UserIcons"         ,  "0", ::cIni ) = "1" )
   ::lUseDLL        := ( GetPvProfString( "General", "UseDLL"            ,  "0", ::cIni ) = "1" )
   ::lShowSave      := ( GetPvProfString( "General", "ShowSaveAs"        ,  "1", ::cIni ) = "1" )
   ::cMenuBarDir    := GetPvProfString( "MenuBar", "UserIconsDir"        , ".\", ::cIni )
   ::cBackBrush     := ALLTRIM( GetPvProfString( "General", "BackgroundBrush", "", ::cIni ) )
   ::cAppName       := GetPvProfString( "General", "ApplicationName", "", ::cIni )
   ::cIcon          := GetPvProfString( "General", "Icon", "", ::cIni )
   ::lShowSendTo    := IIF( GetPvProfString( "SendTo", "ShowSendTo", "1", ::cIni ) = "1", .T., .F. )
   ::nSoftZoom      := VAL( GetPvProfString( "Zoom", "SoftZoom", "0.05", ::cIni ) )
   ::cDocName       := ALLTRIM( GetPvProfString( "General", "DocumentName", "", ::cIni ) )
   ::lSelectPrinter := ( GetPvProfString( "General", "SelectPrinterDlg", "1", ::cIni ) = "1" )

   ::cTo            := PADR( GetPvProfString( "Sendto", "To"     , "", ::cIni ), 200 )
   ::cCc            := PADR( GetPvProfString( "Sendto", "Cc"     , "", ::cIni ), 200 )
   ::cBcc           := PADR( GetPvProfString( "Sendto", "Bcc"    , "", ::cIni ), 200 )
   ::cSubject       := PADR( GetPvProfString( "Sendto", "Subject", "", ::cIni ), 200 )
   ::lDelAfterMail  := ( GetPvProfString( "Sendto", "DeleteFilesAfterMail", "1", ::cIni ) = "1" )

   ::aFiles         := oDevice:aMeta
   ::nTotalPages    := LEN( ::aFiles )
   ::cMetaformat    := IIF( UPPER( cFileExt( ::aFiles[1] ) ) = "WMF", "WMF", "EMF" )
   ::oDevice        := oDevice
   ::aPageBtn       := ARRAY(4)
   ::aZoomFactor    := { 1.0 }
   ::nBackClr       := ::GetColor( GetPvProfString( "General", "BackgroundColor", "", ::cIni ), ;
                                   RGB( 128, 128, 128 ) )
   ::nShadow_Color   := ::GetColor( GetPvProfString( "General", "ShadowColor", "", ::cIni ) )
   ::nPageBorColor   := ::GetColor( GetPvProfString( "General", "PageBorderColor", "", ::cIni ) )
   ::nBarBackColor1  := ::GetColor( GetPvProfString( "MenuBar", "BackgroundColor1", "-1", ::cIni ) )
   ::nBarBackColor2  := ::GetColor( GetPvProfString( "MenuBar", "BackgroundColor2", "-1", ::cIni ) )
   ::lOffice2007Look := ( GetPvProfString( "General", "Office2007Look", "1", ::cIni ) = "1" )

   ::cPDFLicName := AllTrim( GetPvProfString( "wPDFControl", "PDFLicName", "Sodtalbers+Partner" , ::cIni ) )
   ::cPDFLicCode := AllTrim( GetPvProfString( "wPDFControl", "PDFLicCode", "C1yPNce_earEr8deafka", ::cIni ) )
   ::nPDFLicNr   := Val(     GetPvProfString( "wPDFControl", "PDFLicNr"  , "686041"             , ::cIni ) )

   nLanguage := VAL( GetPvProfString( "General", "Language", "1", ::cIni ) )
   ::GetLanguages( cPrevIni )

   ::cDemoMessage  := GetPvProfString( "General", "DemoMessage", "", ::cIni )
   IF .NOT. EMPTY( ::cDemoMessage )
      ::lExtDemoMode := .T.
      WritePProString( "General", "DemoMessage", "", ::cIni )
   ENDIF

   WritePProString( "Broadcast", "WasPrinted", "0", ::cIni )

   cPath          := GetPvProfString( "General", "Path", "", cPrevIni )
   ::hEPWnd       := VAL( GetPvProfString( "General", "ParentWnd"  , "" , cPrevIni ) )
   ::nWidth       := VAL( GetPvProfString( "General", "Width"      , "" , cPrevIni ) ) * 10
   ::nHeight      := VAL( GetPvProfString( "General", "Height"     , "" , cPrevIni ) ) * 10
   ::nHorzRes     := VAL( GetPvProfString( "General", "HorzRes"    , "" , cPrevIni ) )
   ::nVertRes     := VAL( GetPvProfString( "General", "VertRes"    , "" , cPrevIni ) )
   ::nPaperType   := VAL( GetPvProfString( "General", "PaperType"  , "0", cPrevIni ) )
   ::nCopies      := VAL( GetPvProfString( "General", "Copies"     , "1", cPrevIni ) )
   ::nOrientation := VAL( GetPvProfString( "General", "Orientation", "1", cPrevIni ) )
   ::nBin         := VAL( GetPvProfString( "General", "Bin"        , "0", cPrevIni ) )
   FERASE( cPrevIni )

   ::nPrWidth  := ::nWidth
   ::nPrHeight := ::nHeight
   ::nWidth    := ::nHorzRes
   ::nHeight   := ::nVertRes

   //oDevice:SetSize( ::nWidth, ::nHeight )

   ::lLandscape := ( ::nHorzRes >= ::nVertRes )

    IF ::nOrientation = 2
      oDevice:SetLandscape()
    ELSE
      oDevice:SetPortrait()
    ENDIF

   ::cTmpPath := cPath + "\epreview"

   IF lIsDir( ::cTmpPath ) = .F.
      // temporäres Verzeichnis anlegen
      lMKDir( ::cTmpPath )
   ELSEIF ::lMultiPrev = .F.
      // Wenn nur eine Vorschau angezeigt werden soll
      aTmpFiles := DIRECTORY( ::cTmpPath + "\*.*" )
      IF LEN( aTmpFiles ) > 0
         MsgStop( EP_GL("A preview window is already open."), EP_GL("Stop") )
         ::End()
         RETURN NIL
      ENDIF
   ENDIF

   IF ::lShowInfoDlg = .T.
      ::ShowInfoDlg()
   ENDIF

   FOR i := 1 TO ::nTotalPages

      IF ::lShowInfoDlg = .T.
         ::oInfoSay:SetText( ::cInfoSay + " " + ;
            ALLTRIM(STR( i, 6 )) + " / " + ALLTRIM(STR( ::nTotalPages, 6 )) )
      ENDIF

      cExt     := IIF( UPPER( cFileExt( ::aFiles[i] ) ) = "EMF", ".emf", ".wmf" )
      // cNewFile darf nicht mehr als 8 Zeichen lang sein,
      // sonst funktioniert es nicht unter Win98
      cNewFile := "E" + ::TempFile() + PADL( ALLTRIM(STR(i,4)), 4, "0" ) + ".emf"

      IF cExt == ".wmf"

         hOldMeta := GetMetaFile( ::aFiles[i] )
         hDCOut   := CreateEnhMetaFile( ::oDevice:hDC, ::cTmpPath + "\" + cNewFile, 0 )
         PlayMetaFile( hDCOut, hOldMeta )
         DeleteMetafile( hOldMeta )
         DeleteEnhMetaFile( CloseEnhMetaFile( hDCOut ) )

         IF ( FERASE( ::aFiles[i] ) <> 0 )
            MsgStop( ::aFiles[i] + " " + EP_GL( "can not be deleted."), EP_GL("Stop") )
         ENDIF
         ::cMetaFormat := "EMF"
         cExt := ".emf"

      ELSE

         IF FRENAME( ::aFiles[i], ::cTmpPath + "\" + cNewFile ) < 0
            MsgStop( ::aFiles[i] + " " + EP_GL("could not be renamed."), EP_GL("Stop") )
         ENDIF

      ENDIF

      AADD( aMeta, ::cTmpPath + "\" + cFileNoExt( cNewFile ) + ".EMF" )

   NEXT

   ::oDevice:nOrient := ::nOrientation
   ::oDevice:aMeta   := aMeta
   ::aFiles          := aMeta

   FOR i := 1 TO 8
      nZoom := VAL( GetPvProfString( "Zoom", ALLTRIM(STR(i)), "", ::cIni ) )
      AADD( ::aZoomFactor, IIF( nZoom <> 0, nZoom, 1+i ) )
   NEXT

   IF ::lShowInfoDlg = .T.
      ::oInfoDlg:End()
   ENDIF

   ::EPShow()

RETURN ( Self )


*-- METHOD -------------------------------------------------------------------
*         Name: End
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD End() CLASS EPREVIEW

   AEVAL( ::oDevice:aMeta, {|val| FERASE( val ) } )

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: ShowInfoDlg
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD ShowInfoDlg() CLASS EPREVIEW

   LOCAL aFont[2], aSay[3]
   LOCAL aPrompt := { REPLICATE("_", 100 ), ;
                      ALLTRIM( IIF( EMPTY( ::cDocName ), ::oDevice:cDocument, ::cDocName ) ) }

   ::cInfoSay := EP_GL( "Please wait, preparing preview page" )

   DEFINE FONT aFont[1] NAME "MS SANS SERIF" SIZE 0,-14 BOLD
   DEFINE FONT aFont[2] NAME "MS SANS SERIF" SIZE 0,-8

   DEFINE DIALOG ::oInfoDlg FROM 0,0 TO 64, 300 PIXEL STYLE nOr( DS_MODALFRAME, WS_POPUP )

   @ 10, 0 SAY aSay[1] PROMPT aPrompt[1] OF ::oInfoDlg SIZE 300, 20 PIXEL FONT aFont[2]
   @  4, 8 SAY aSay[2] PROMPT aPrompt[2] OF ::oInfoDlg SIZE 300, 10 PIXEL FONT aFont[1]
   @ 21, 8 SAY ::oInfoSay PROMPT ::cInfoSay OF ::oInfoDlg SIZE 300, 20 PIXEL FONT aFont[2]

   ACTIVATE DIALOG ::oInfoDlg CENTER NOMODAL

   AEVAL( aFont, {|x| x:End() } )

   SysWait(.1)

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: EPShow
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EPShow() CLASS EPREVIEW

   LOCAL i, y, nFor, oHand, nLeft, nRight, nFromPage, nToPage, oBrush
   LOCAL oIcon, oCursor, oMenu, aFont[2]
   LOCAL hDLL        := LoadLibrary( "Riched20.dll" )
   LOCAL hOldRes     := GetResources()
   LOCAL oWndMain    := WndMain()
   LOCAL lExit       := .F.
   LOCAL lMaximize   := ::lMaximize
   LOCAL oPrev       := SELF
   LOCAL nZoomFactor := 1
   LOCAL aWinCoords  := ::GetWinCoords()

   ::nxyfactor := ( ::oDevice:nVertSize() / ::oDevice:nHorzSize() )

   IF ::lUseDLL = .T. .AND. SetResources(::cResFile) < 32
        MsgStop( ::cResFile + " not found, imposible to continue", "Preview Error" )
        RETURN NIL
   ENDIF

   IF ::oWnd != NIL
      MsgStop( EP_GL("A preview window is already running."), EP_GL("Stop") )
      SetResources(hOldRes)
      RETURN NIL
   ENDIF

   DEFINE ICON oIcon FILE ::cIcon

   IF ::oDevice:lPrvModal .and. oWndMain != NIL
        oWndMain:Hide()
   ELSE
        lExit := .T.
   ENDIF
   DEFINE FONT aFont[1] NAME GetSysFont() SIZE 0,-12
   DEFINE FONT aFont[2] NAME GetSysFont() SIZE 0,-12 //BOLD

   DEFINE CURSOR oCursor RESOURCE "Lupa"

   IF EMPTY( ::cBackBrush )
      DEFINE BRUSH oBrush COLOR ::nBackClr
   ELSE
      IF AT( ".BMP", ::cBackBrush ) <> 0
         DEFINE BRUSH oBrush FILE ::cBackBrush
      ELSE
         DEFINE BRUSH oBrush RESOURCE "EP_" + ::cBackBrush
      ENDIF
   ENDIF

   DEFINE WINDOW ::oWnd FROM aWinCoords[1], aWinCoords[2] TO aWinCoords[3], aWinCoords[4] ;
       PIXEL VSCROLL HSCROLL ;
       TITLE IIF( EMPTY( ::cAppName ), "", ::cAppName + " - " ) + ::oDevice:cDocument ;
       MENU  ::BuildMenu() ;
       BRUSH oBrush ;
       ICON  oIcon

   @  100, -10 RICHEDIT ::oSaveAsRTF VAR ::cSaveAsRTF OF ::oWnd PIXEL SIZE 2, 2

   ::nPage  := 1
   nZFactor := 1
   ::lZoom  := .F.

   ::oWnd:SetFont( aFont[1] )
   ::oWnd:oVScroll:SetRange(0,0)
   ::oWnd:oHScroll:SetRange(0,0)

   //SET MESSAGE OF ::oWnd TO ::RegInfos() CENTERED //NOINSET
   IF ::lOffice2007Look = .T.
      SET MESSAGE OF ::oWnd TO ::RegInfos() CENTERED 2007
   ELSE
      SET MESSAGE OF ::oWnd TO ::RegInfos() CENTERED
   ENDIF

   DEFINE MSGITEM ::oPage OF ::oWnd:oMsgBar SIZE 220 ;
      COLOR RGB( 0, 0, 128 ) ;
      FONT aFont[2] ;
      PROMPT EP_GL("Page number:") + " " + ;
             ALLTRIM(STR( ::nPage, 4 )) + " / " + ALLTRIM(STR( ::nTotalPages )) ;
      ACTION ::GotoPage()

   DEFINE CURSOR oHand HAND

   IF ::lOffice2007Look = .T.
      DEFINE BUTTONBAR ::oBar SIZE ::nMenuBarWidth, ::nMenuBarHeight OF ::oWnd 2007
   ELSE
      DEFINE BUTTONBAR ::oBar _3D SIZE ::nMenuBarWidth, ::nMenuBarHeight OF ::oWnd
   ENDIF

   ::oBar:bRClicked := {|| NIL }
   ::oBar:bLClicked := {|| NIL }

   ::BarMenu()

   AEval( ::oBar:aControls, { | o | o:oCursor := oHand } )

   ::aMeta[1] := EPMetaFile():New( 0, 0, 0, 0, ::aFiles[1], ::oWnd, CLR_BLACK, CLR_WHITE, oPrev )

   ::aMeta[1]:oCursor := oCursor

   IF ::lSClickZoom = .T.
      ::aMeta[1]:blClicked := { |nRow, nCol, nKeyFlags| ::SetOrg1( nCol*2, nRow ) }
   ELSE
      ::aMeta[1]:blDblClick := { |nRow, nCol, nKeyFlags| ::SetOrg1( nCol*2, nRow ) }
   ENDIF
   ::aMeta[1]:bKeyDown   := {|nKey,nFlags| ::CheckKey(nKey,nFlags)}

   FOR i := 2 TO 8
      ::aMeta[i] := EPMetaFile():New( 0, 0, 0, 0, "", ::oWnd, CLR_BLACK, CLR_WHITE, oPrev )
      ::aMeta[i]:oCursor := oCursor
      ::aMeta[i]:hide()
   NEXT

   IF ::lSClickZoom = .T.
      ::aMeta[2]:blClicked := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 2 ) }
      ::aMeta[3]:blClicked := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 3 ) }
      ::aMeta[4]:blClicked := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 4 ) }
      ::aMeta[5]:blClicked := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 5 ) }
      ::aMeta[6]:blClicked := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 6 ) }
      ::aMeta[7]:blClicked := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 7 ) }
      ::aMeta[8]:blClicked := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 8 ) }
   ELSE
      ::aMeta[2]:blDblClick := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 2 ) }
      ::aMeta[3]:blDblClick := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 3 ) }
      ::aMeta[4]:blDblClick := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 4 ) }
      ::aMeta[5]:blDblClick := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 5 ) }
      ::aMeta[6]:blDblClick := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 6 ) }
      ::aMeta[7]:blDblClick := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 7 ) }
      ::aMeta[8]:blDblClick := {|nRow, nCol, nKeyFlags| ::SetOrg2( nCol*2, nRow, 8 ) }
   ENDIF

   nLeft := ( 13 + IIF( ::lShowSendTo, 1, 0 ) + IIF( ::lShowSave, 1, 0 ) ) * ::nMenuBarWidth + 56
   //nLeft := IIF( ::lShowSendTo = .T., 446, 416 )
   nRight := ( ::nMenuBarHeight - 20 ) / 2

   //@ nRight+4, nLeft SAY EP_GL("Factor:") SIZE 46, 15 PIXEL OF ::oBar FONT aFont[1] RIGHT

   IF ::lOffice2007Look = .T.
      ::oBar:bPainted := {|| ::oBar:Say( nRight+4, nLeft + 46, EP_GL("Factor:"), 0, "B", aFont[1], .T., .T., 2 ) }
   ELSE
      @ nRight+4, nLeft SAY EP_GL("Factor:") SIZE 46, 15 PIXEL OF ::oBar FONT aFont[1] RIGHT
   ENDIF

   @ nRight, nLeft + 49 COMBOBOX ::oFactor VAR nZoomFactor ;
        ITEMS oPrev:GetFactors() ;
        OF ::oBar FONT aFont[1] PIXEL SIZE 60,200 ;
        ON CHANGE ( nZFactor := oPrev:aZoomFactor[nZoomFactor], oPrev:SetFactor( nZFactor ) )

   //@ nRight+4, nLeft + 149 SAY ::oPage PROMPT EP_GL("Page number:") + " " + ;
   //     alltrim(str(::nPage,4)) + " / " + alltrim(str( ::nTotalPages )) ;
   //     SIZE 160, 15 PIXEL OF ::oBar FONT aFont[1]

   ::oFactor:Set3dLook()

   IF ::lSaveWindowPos = .F.
      WndCenter( ::oWnd:hWnd )
   ENDIF

   SysRefresh()
   SetResources(hOldRes)

   ::oWnd:oHScroll:bPos := {|nPos| ::hScroll( GO_POS, .F., nPos ) }
   ::oWnd:oVScroll:bPos := {|nPos| ::vScroll( GO_POS, .F., nPos ) }

   oPrev:SetFactor()

   IF oPrev:hEPWnd <> 0 .AND. oPrev:lSetParent = .T.
      SetParent( oPrev:hEPWnd, ::oWnd:hWnd )
   ENDIF

   ::aMeta[1]:bRClicked = { | nKey, nFlags | ::SoftZoom( .T. ) }

   // direct printout / save to file / mailing
   // muss hier stehen, weil die Save-Funktion hWnd braucht
   IF ::nDirect > 0

      ::RegInfos()

      IF ::lDemo = .T. .AND. lEasyReport = .F.
         ::Registration()
      ENDIF

      WritePProString( "General", "Direct", "0", ::cIni )

      nFromPage := VAL( GetPvProfString( "General", "DirectFrom", "1", ::cIni ) )
      nToPage   := VAL( GetPvProfString( "General", "DirectTo"  , "0", ::cIni ) )

      IF ::nDirect = 1
         ::PrintPrv( NIL, 1, nFromPage, IIF( nToPage = 0, ::nTotalPages, nToPage ), ::nCopies )
      ELSEIF ::nDirect = 2
         ::PrViewSave( .F., .T., nFromPage, IIF( nToPage = 0, ::nTotalPages, nToPage ) )
      ELSEIF ::nDirect = 3
         ::PrViewSave( .F., .T., nFromPage, IIF( nToPage = 0, ::nTotalPages, nToPage ) )
         SysRefresh()
         ::EMail( .T. )
      ENDIF

      ::oWnd:End()
      ::oWnd:oIcon := NIL
      AEVAL( ::aMeta, {|x| x:End() } )
      ::oDevice:End()
      oBrush:End()
      oHand:End()
      AEVAL( aFont, {|x| x:End() } )
      oPrev:End()
      ::oWnd := NIL
      lExit := .T.

   ELSE

   ACTIVATE WINDOW ::oWnd ;
      ON INIT ( oMenuUnZoom:Disable(), ;
                IIF( lMaximize = .T.         , oPrev:oWnd:Maximize(), .T. ), ;
                IIF( oPrev:lZoomAtStart = .T., oPrev:Zoom(), .T. ), ;
                CursorArrow(), ;
                IIF( oPrev:lDemo = .T.       , oPrev:Registration(), .T. ), ;
                IIF( oPrev:lExtDemoMode = .T., MsgInfo( oPrev:cDemoMessage ), .T. ), ;
                IIF( oPrev:lSaveAtStart = .T., oPrev:PrViewSave(), .T. ), ;
                IIF( oPrev:lMailAtStart = .T. .AND. oPrev:lShowSendTo = .T., oPrev:EMail(), .T. ) ) ;
      ON RESIZE    ::PaintMeta()               ;
      ON UP        ::vScroll(GO_UP)            ;
      ON DOWN      ::vScroll(GO_DOWN)          ;
      ON PAGEUP    ::vScroll(GO_UP,GO_PAGE)    ;
      ON PAGEDOWN  ::vScroll(GO_DOWN,GO_PAGE)  ;
      ON LEFT      ::hScroll(GO_LEFT)          ;
      ON RIGHT     ::hScroll(GO_RIGHT)         ;
      ON PAGELEFT  ::hScroll(GO_LEFT,GO_PAGE)  ;
      ON PAGERIGHT ::hScroll(GO_RIGHT,GO_PAGE) ;
      VALID      ( IIF( ::lSaveWindowPos, ::SetWinCoords(), ), ;
                   ::oWnd:oIcon := NIL, ;
                   AEVAL( ::aMeta, {|x| x:End() } ), ;
                   ::oDevice:End(), ;
                   oHand:End(), ;
                   oBrush:End(), ;
                   AEVAL( aFont, {|x| x:End() } ), ;
                   oPrev:End(), ;
                   ::oWnd := NIL, ;
                   lExit := .T., ;
                   .T. )

   ENDIF

   #IFDEF __HARBOUR__
      StopUntil( {|| lExit } )
   #ELSE
      DO WHILE !lExit
         SysWait(.1)
      ENDDO
   #ENDIF

   IF ::oDevice:lPrvModal .and. oWndMain != NIL
        oWndMain:Show()
   ENDIF

   FreeLibrary( hDLL )

RETURN (NIL)


*-- METHOD -------------------------------------------------------------------
*         Name: BarMenu
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD BarMenu() CLASS EPREVIEW

   LOCAL aRestBar[8]
   LOCAl oPrev := SELF

   IF ::lMenuBarExtern = .T.

   DEFINE BUTTON ::aPageBtn[1] OF ::oBar NOBORDER ;
      FILE ::cMenuBarDir + "top.bmp", ::cMenuBarDir + "unabled_top.bmp" ;
      ACTION  oPrev:ChangePage( PAGE_TOP, .F. ) ;
      WHEN ::nPage > 1 ;
      TOOLTIP EP_GL("Go to first page")

   DEFINE BUTTON ::aPageBtn[2] OF ::oBar NOBORDER ;
      FILE ::cMenuBarDir + "previous.bmp", ::cMenuBarDir + "unabled_previous.bmp" ;
      ACTION oPrev:ChangePage( PAGE_PREV, .F. ) ;
      WHEN ::nPage > 1 ;
      TOOLTIP EP_GL("Go to previous page")

   DEFINE BUTTON ::aPageBtn[3] OF ::oBar NOBORDER ;
      FILE ::cMenuBarDir + "next.bmp", ::cMenuBarDir + "unabled_next.bmp"  ;
      ACTION oPrev:ChangePage( PAGE_NEXT, .F. ) ;
      WHEN ::nPage < ::nTotalPages ;
      TOOLTIP EP_GL("Go to next page")

   DEFINE BUTTON ::aPageBtn[4] OF ::oBar NOBORDER ;
      FILE ::cMenuBarDir + "bottom.bmp", ::cMenuBarDir + "unabled_bottom.bmp" ;
      ACTION oPrev:ChangePage( PAGE_BOTTOM, .F. ) ;
      WHEN ::nPage < ::nTotalPages ;
      TOOLTIP EP_GL("Go to last page")

   /*
   DEFINE SBUTTON ::aPageBtn[4] OF ::oBar NOBOX ;
      SIZE ::nMenuBarWidth, ::nMenuBarHeight ;
      FILE ::cMenuBarDir + "bottom.bmp",, ::cMenuBarDir + "unabled_bottom.bmp" ;
      COLOR 0, { ::nBarBackColor2, ::nBarBackColor1, 1 } ;
      ACTION oPrev:ChangePage( PAGE_BOTTOM, .F. ) ;
      WHEN ::nPage < ::nTotalPages ;
      TOOLTIP EP_GL("Go to last page")
   */

   DEFINE BUTTON ::oZoom FILE::cMenuBarDir + "zoom.bmp" OF ::oBar GROUP NOBORDER ;
        ACTION oPrev:Zoom() ;
        TOOLTIP EP_GL("Page zoom")

   DEFINE BUTTON ::oTwoPages OF ::oBar NOBORDER ;
      FILE ::cMenuBarDir + "pages2.bmp", ::cMenuBarDir + "unabled_pages2.bmp" ;
      ACTION oPrev:SetPages( IIF( ::nViewPages = 1, 2, 1 ) ) ;
      WHEN ::nTotalPages > 1 ;
      TOOLTIP EP_GL("Preview on two pages") ;
      MENU oPrev:PageMenu()

   DEFINE BUTTON aRestBar[1] OF ::oBar NOBORDER ;
      FILE ::cMenuBarDir + "minus.bmp", ::cMenuBarDir + "unabled_minus.bmp" ;
      ACTION oPrev:SoftZoom( .F. ) ;
      WHEN nZFactor > 1 ;
      TOOLTIP EP_GL("Reduce [-]")

   DEFINE BUTTON aRestBar[2] FILE ::cMenuBarDir + "plus.bmp" OF ::oBar NOBORDER ;
      ACTION oPrev:SoftZoom( .T. ) ;
      TOOLTIP EP_GL("Enlarge [+]")

   DEFINE BUTTON aRestBar[8] FILE ::cMenuBarDir + "copy.bmp" OF ::oBar GROUP NOBORDER ;
      ACTION oPrev:Copy2Clipboard( ) ;
      TOOLTIP Strtran( EP_GL("&Copy to Clipboard"), "&", "" )

   IF ::lShowSave = .T.
      DEFINE BUTTON aRestBar[3] FILE ::cMenuBarDir + "save.bmp" OF ::oBar NOBORDER ;
         ACTION oPrev:PrViewSave() ;
         TOOLTIP Strtran( EP_GL("&Save as"), "&", "" )
   ENDIF

   IF ::lShowSendTo = .T.
      DEFINE BUTTON aRestBar[4] FILE ::cMenuBarDir + "email.bmp" OF ::oBar NOBORDER ;
         ACTION oPrev:Email() ;
         TOOLTIP Strtran( EP_GL("Send &to"), "&", "" )
   ENDIF

   DEFINE BUTTON aRestBar[5] FILE ::cMenuBarDir + "print.bmp" OF ::oBar NOBORDER ;
      ACTION oPrev:PrintPage() ;
      TOOLTIP Strtran( EP_GL("&Print"), "&", "" )

   DEFINE BUTTON aRestBar[6] FILE ::cMenuBarDir + "print2.bmp" OF ::oBar NOBORDER ;
      ACTION oPrev:PrintPage(.T.) ;
      TOOLTIP EP_GL("Print and exit")

   DEFINE BUTTON aRestBar[7] FILE ::cMenuBarDir + "exit.bmp" OF ::oBar GROUP NOBORDER ;
      ACTION oPrev:oWnd:End() ;
      TOOLTIP EP_GL("Exit from preview")

   ELSE

   DEFINE BUTTON ::aPageBtn[1] RESOURCE "EP_Top", "EP_Top", "EP_Top2" OF ::oBar NOBORDER ;
        ACTION  ::ChangePage( PAGE_TOP, .F. ) ;
        WHEN ::nPage > 1 ;
        TOOLTIP EP_GL("Go to first page")

   DEFINE BUTTON ::aPageBtn[2] RESOURCE "EP_Previous", "EP_Previous", "EP_Previous2" OF ::oBar NOBORDER ;
        ACTION ::ChangePage( PAGE_PREV, .F. ) ;
        WHEN ::nPage > 1 ;
        TOOLTIP EP_GL("Go to previous page")

   DEFINE BUTTON ::aPageBtn[3] RESOURCE "EP_Next", "EP_Next", "EP_Next2" OF ::oBar NOBORDER ;
        ACTION ::ChangePage( PAGE_NEXT, .F. ) ;
        WHEN ::nPage < ::nTotalPages ;
        TOOLTIP EP_GL("Go to next page")

   DEFINE BUTTON ::aPageBtn[4] RESOURCE "EP_Bottom", "EP_Bottom", "EP_Bottom2" OF ::oBar NOBORDER ;
        ACTION ::ChangePage( PAGE_BOTTOM, .F. ) ;
        WHEN ::nPage < ::nTotalPages ;
        TOOLTIP EP_GL("Go to last page")

   DEFINE BUTTON ::oZoom RESOURCE "EP_Zoom" OF ::oBar GROUP NOBORDER ;
        ACTION ::Zoom() ;
        TOOLTIP EP_GL("Page zoom")

   DEFINE BUTTON ::oTwoPages RESOURCE "EP_Two_Pages", "EP_Two_Pages", "EP_Two_Pages2" OF ::oBar NOBORDER ;
        ACTION ::SetPages( IIF( ::nViewPages = 1, 2, 1 ) ) ;
        WHEN ::nTotalPages > 1 ;
        TOOLTIP EP_GL("Preview on two pages") ;
        MENU ::PageMenu()

   DEFINE BUTTON aRestBar[1] RESOURCE "EP_MINUS", "EP_MINUS", "EP_MINUS2" OF ::oBar NOBORDER ;
        ACTION ::SoftZoom( .F. ) ;
        WHEN nZFactor > 1 ;
        TOOLTIP EP_GL("Reduce [-]")

   DEFINE BUTTON aRestBar[2] RESOURCE "EP_PLUS" OF ::oBar NOBORDER ;
        ACTION ::SoftZoom( .T. ) ;
        TOOLTIP EP_GL("Enlarge [+]")

   DEFINE BUTTON aRestBar[8] RESOURCE "EP_COPY" OF ::oBar GROUP NOBORDER ;
        ACTION ::Copy2Clipboard( ) ;
        TOOLTIP Strtran( EP_GL("&Copy to Clipboard"), "&", "" )

   IF ::lShowSave = .T.
      DEFINE BUTTON aRestBar[3] RESOURCE "EP_SAVE" OF ::oBar NOBORDER ;
         ACTION ::PrViewSave() ;
         TOOLTIP Strtran( EP_GL("&Save as"), "&", "" )
   ENDIF

   IF ::lShowSendTo = .T.
      DEFINE BUTTON aRestBar[4] RESOURCE "EP_EMAIL" OF ::oBar NOBORDER ;
           ACTION ::Email() ;
           TOOLTIP Strtran( EP_GL("Send &to"), "&", "" )
   ENDIF

   DEFINE BUTTON aRestBar[5] RESOURCE "EP_PRINTER" OF ::oBar NOBORDER ;
        ACTION ::PrintPage() ;
        TOOLTIP Strtran( EP_GL("&Print"), "&", "" )

   DEFINE BUTTON aRestBar[6] RESOURCE "EP_PRINTEXIT" OF ::oBar NOBORDER ;
        ACTION ::PrintPage(.T.) ;
        TOOLTIP EP_GL("Print and exit")

   DEFINE BUTTON aRestBar[7] RESOURCE "EP_Exit" OF ::oBar GROUP NOBORDER ;
        ACTION ::oWnd:End() ;
        TOOLTIP EP_GL("Exit from preview")

   ENDIF

   IF ::lNoBorder = .F.
      AEVAL( ::aPageBtn, {|x| IIF( x <> NIL, ( x:lBorder := .T., x:l97Look := .F. ), ) } )
      AEVAL( aRestBar  , {|x| IIF( x <> NIL, ( x:lBorder := .T., x:l97Look := .F. ), ) } )
      ::oZoom:lBorder     := .T. ; ::oZoom:l97Look := .F.
      ::oTwoPages:lBorder := .T. ; ::oTwoPages:l97Look := .F.
   ENDIF

RETURN (.T.)


*-- METHOD -------------------------------------------------------------------
*         Name: PageMenu
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PageMenu() CLASS EPREVIEW

   LOCAL oMenu

   MENU oMenu POPUP

   MENUITEM STRTRAN( EP_GL("&1 Page") , "&", "" )  ACTION ::SetPages( 1 ) ;
      RESOURCE IIF( ::lMenuBarExtern, NIL, "EP_ONE_PAGE" ) ;
      FILE     IIF( ::lMenuBarExtern, ::cMenuBarDir + "small_pages1.bmp", NIL ) ;
      WHEN ::nTotalPages > 1 .AND. ::nViewPages <> 1
   MENUITEM STRTRAN( EP_GL("&2 Pages") , "&", "" )  ACTION ::SetPages( 2 ) ;
      RESOURCE IIF( ::lMenuBarExtern, NIL, "EP_TWO_PAGES" ) ;
      FILE     IIF( ::lMenuBarExtern, ::cMenuBarDir + "small_pages2.bmp", NIL ) ;
      WHEN ::nTotalPages > 1 .AND. ::nViewPages <> 2
   MENUITEM STRTRAN( EP_GL("&4 Pages") , "&", "" ) ACTION ::SetPages( 4 ) ;
      RESOURCE IIF( ::lMenuBarExtern, NIL, "EP_PAGES4" ) ;
      FILE     IIF( ::lMenuBarExtern, ::cMenuBarDir + "small_pages4.bmp", NIL ) ;
      WHEN ::nTotalPages > 3 .AND. ::nViewPages <> 4
   MENUITEM STRTRAN( EP_GL("&6 Pages") , "&", "" ) ACTION ::SetPages( 6 ) ;
      RESOURCE IIF( ::lMenuBarExtern, NIL, "EP_PAGES6" ) ;
      FILE     IIF( ::lMenuBarExtern, ::cMenuBarDir + "small_pages6.bmp", NIL ) ;
      WHEN ::nTotalPages > 5 .AND. ::nViewPages <> 6
   MENUITEM STRTRAN( EP_GL("&8 Pages") , "&", "" ) ACTION ::SetPages( 8 ) ;
      RESOURCE IIF( ::lMenuBarExtern, NIL, "EP_PAGES8" ) ;
      FILE     IIF( ::lMenuBarExtern, ::cMenuBarDir + "small_pages8.bmp", NIL ) ;
      WHEN ::nTotalPages > 7 .AND. ::nViewPages <> 8
   ENDMENU

RETURN( oMenu )


*-- METHOD -------------------------------------------------------------------
*         Name: BuildMenu
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD BuildMenu() CLASS EPREVIEW

   LOCAL nFor, oMenu
   LOCAL cPercent := EP_GL("%")

   ::aFactor := Array(9)

   IF ::lOffice2007Look = .T.
      MENU oMenu 2007
   ELSE
      MENU oMenu
   ENDIF

   MENUITEM EP_GL("&File")
   MENU

      MENUITEM EP_GL("&Copy to Clipboard") + chr(9) + EP_GL("Ctrl+C") ;
         ACTION ::Copy2Clipboard( ) ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_COPY" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_copy.bmp", NIL ) ;
         ACCELERATOR ACC_CONTROL, ASC( EP_GL("C") )

      IF ::lShowSave = .T.
         MENUITEM EP_GL("&Save as") + chr(9) + EP_GL("Ctrl+S") ;
            ACTION ::PrViewSave() ;
            RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_SAVE" ) ;
            FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_save.bmp", NIL ) ;
            ACCELERATOR ACC_CONTROL, ASC( EP_GL("S") )
      ENDIF

      IF ::lShowSendTo = .T.
         MENUITEM EP_GL("Send &to") + chr(9) + EP_GL("Ctrl+E") ;
            ACTION ::EMail() ;
            RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_EMAIL" ) ;
            FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_email.bmp", NIL ) ;
            ACCELERATOR ACC_CONTROL, ASC( EP_GL("E") )
      ENDIF

      MENUITEM EP_GL("&Print") + chr(9) + EP_GL("Ctrl+P") ;
         ACTION ::PrintPage() ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_PRINTER" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_print.bmp", NIL ) ;
         ACCELERATOR ACC_CONTROL, ASC( EP_GL("P") )

      SEPARATOR

      MENUITEM EP_GL("&Exit") ACTION ::oWnd:End() ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_EXIT" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_exit.bmp", NIL ) ;

   ENDMENU

   MENUITEM EP_GL("&Navigation")
   MENU

      MENUITEM EP_GL("&First") ACTION ( ::ChangePage( PAGE_TOP ), ::oBar:AEvalWhen() ) ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_TOP" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_top.bmp", NIL ) ;
         WHEN ::nPage > 1
      MENUITEM EP_GL("&Previous") ACTION ( ::ChangePage( PAGE_PREV ), ::oBar:AEvalWhen() ) ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_PREVIOUS" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_previous.bmp", NIL ) ;
         WHEN ::nPage > 1
      MENUITEM EP_GL("&Next") ACTION ( ::ChangePage( PAGE_NEXT ), ::oBar:AEvalWhen() ) ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_NEXT" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_next.bmp", NIL ) ;
         WHEN ::nPage < ::nTotalPages
      MENUITEM EP_GL("&Last") ACTION ( ::ChangePage( PAGE_BOTTOM ), ::oBar:AEvalWhen() ) ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_BOTTOM" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_bottom.bmp", NIL ) ;
         WHEN ::nPage < ::nTotalPages

      SEPARATOR

      MENUITEM EP_GL("&Go to") ACTION ( ::GoToPage(), ::oBar:AEvalWhen() ) ;
         WHEN ::nTotalPages > 1

   ENDMENU

   MENUITEM EP_GL("&View")
   MENU

      MENUITEM  ::oMenuZoom PROMPT EP_GL("&Zoom") ACTION ::Zoom(.T.) ENABLED ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_ZOOM" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_zoom.bmp", NIL )

      MENUITEM  oMenuUnZoom PROMPT EP_GL("Nor&mal") ACTION ::Zoom(.T.) ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_UNZOOM" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_unzoom.bmp", NIL )

      MENUITEM  EP_GL("Zoom &Factor")

         MENU
         MENUITEM ::aFactor[1] PROMPT "&" + ALLTRIM(STR(::aZoomFactor[1]*100,4)) + " " + cPercent ACTION ( ::oFactor:Set(1), ::oFactor:Change(), nZFactor := ::aZoomFactor[1], ::SetFactor(::aZoomFactor[1]) )
         MENUITEM ::aFactor[2] PROMPT "&" + ALLTRIM(STR(::aZoomFactor[2]*100,4)) + " " + cPercent ACTION ( ::oFactor:Set(2), ::oFactor:Change(), nZFactor := ::aZoomFactor[2], ::SetFactor(::aZoomFactor[2]) )
         MENUITEM ::aFactor[3] PROMPT "&" + ALLTRIM(STR(::aZoomFactor[3]*100,4)) + " " + cPercent ACTION ( ::oFactor:Set(3), ::oFactor:Change(), nZFactor := ::aZoomFactor[3], ::SetFactor(::aZoomFactor[3]) )
         MENUITEM ::aFactor[4] PROMPT "&" + ALLTRIM(STR(::aZoomFactor[4]*100,4)) + " " + cPercent ACTION ( ::oFactor:Set(4), ::oFactor:Change(), nZFactor := ::aZoomFactor[4], ::SetFactor(::aZoomFactor[4]) )
         MENUITEM ::aFactor[5] PROMPT "&" + ALLTRIM(STR(::aZoomFactor[5]*100,4)) + " " + cPercent ACTION ( ::oFactor:Set(5), ::oFactor:Change(), nZFactor := ::aZoomFactor[5], ::SetFactor(::aZoomFactor[5]) )
         MENUITEM ::aFactor[6] PROMPT "&" + ALLTRIM(STR(::aZoomFactor[6]*100,4)) + " " + cPercent ACTION ( ::oFactor:Set(6), ::oFactor:Change(), nZFactor := ::aZoomFactor[6], ::SetFactor(::aZoomFactor[6]) )
         MENUITEM ::aFactor[7] PROMPT "&" + ALLTRIM(STR(::aZoomFactor[7]*100,4)) + " " + cPercent ACTION ( ::oFactor:Set(7), ::oFactor:Change(), nZFactor := ::aZoomFactor[7], ::SetFactor(::aZoomFactor[7]) )
         MENUITEM ::aFactor[8] PROMPT "&" + ALLTRIM(STR(::aZoomFactor[8]*100,4)) + " " + cPercent ACTION ( ::oFactor:Set(8), ::oFactor:Change(), nZFactor := ::aZoomFactor[8], ::SetFactor(::aZoomFactor[8]) )
         MENUITEM ::aFactor[9] PROMPT "&" + ALLTRIM(STR(::aZoomFactor[9]*100,4)) + " " + cPercent ACTION ( ::oFactor:Set(9), ::oFactor:Change(), nZFactor := ::aZoomFactor[9], ::SetFactor(::aZoomFactor[9]) )
         ENDMENU

      SEPARATOR

      MENUITEM ::aMenuPage[1] PROMPT EP_GL("&1 Page") ACTION ::SetPages( 1, .T. ) ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_ONE_PAGE" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_pages1.bmp", NIL ) ;
         WHEN ::nTotalPages > 1 .AND. ::nViewPages <> 1

      MENUITEM ::aMenuPage[2] PROMPT EP_GL("&2 Pages") ACTION ::SetPages( 2, .T. ) ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_TWO_PAGES" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_pages2.bmp", NIL ) ;
         WHEN ::nTotalPages > 1 .AND. ::nViewPages <> 2

      MENUITEM ::aMenuPage[3] PROMPT EP_GL("&4 Pages") ACTION ::SetPages( 4, .T. ) ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_PAGES4" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_pages4.bmp", NIL ) ;
         WHEN ::nTotalPages > 3 .AND. ::nViewPages <> 4

      MENUITEM ::aMenuPage[4] PROMPT EP_GL("&6 Pages") ACTION ::SetPages( 6, .T. ) ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_PAGES6" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_pages6.bmp", NIL ) ;
         WHEN ::nTotalPages > 5 .AND. ::nViewPages <> 6

      MENUITEM ::aMenuPage[5] PROMPT EP_GL("&8 Pages") ACTION ::SetPages( 8, .T. ) ;
         RESOURCE IIF( ::lNoMenuIcons .OR. ::lMenuBarExtern, NIL, "EP_PAGES8" ) ;
         FILE     IIF( ::lNoMenuIcons = .F. .AND. ::lMenuBarExtern, ::cMenuBarDir + "small_pages8.bmp", NIL ) ;
         WHEN ::nTotalPages > 7 .AND. ::nViewPages <> 8

   ENDMENU

   IF ::lDemo = .T.
      MENUITEM "&Informations" ACTION ::Registration()
   ENDIF

   ENDMENU

RETURN oMenu


*-- METHOD -------------------------------------------------------------------
*         Name: PaintMeta
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PaintMeta() CLASS EPREVIEW

   LOCAL oCoors1, oCoors2, oCoors3, oCoors4, oCoors5, oCoors6, oCoors7, oCoors8
   LOCAL nWidth, nHeight, nFactor, nPageHeight, nPageWidth, nZuviel
   LOCAL nTop, nLeft, nRight, nBottom, nRectWidth, nRectHeight
   LOCAL nTop1, nLeft1, nBottom1, nRight1, nLeft2, nRight2, nTop3, nBottom3
   LOCAL nLeft3, nRight3, nTop4, nBottom4, nRight4, nLeft4, nTop5, nBottom5
   LOCAL nxoffset := 0

   IF IsIconic( ::oWnd:hWnd )
      RETURN NIL
   ENDIF

   DO CASE

   CASE ::nViewPages = 1

      nFactor  := IIF( ::lZoom, 0.47, 0.4 )

      nWidth     := ::oWnd:nRight  - ::oWnd:nLeft + 1 - IIF( ::lZoom, 20, 0 )
      nHeight    := ::oWnd:nBottom - ::oWnd:nTop + 1  - IIF( ::lZoom, 20, 0 )
      nTop       := ::nMenuBarHeight + ::nPageOffset
      nLeft      := nWidth/2-(nWidth*nFactor)
      nRight     := nWidth/2+(nWidth*nFactor)
      nRectWidth := nRight - nLeft

      IF !::lZoom
         nBottom := nRectWidth * ::nxyfactor + nTop
      else
         nbottom := nHeight - 70 - ::nPageOffset
         ::aMeta[1]:nyfactor := ( nWidth / nHeight ) * ;
                                IIF( ::nWidth >= ::nHeight, 0.43, 0.85 )
      endif

      if nBottom > ::oWnd:nBottom - 130 .and. !::lZoom
         nRectHeight := ( nHeight - 70 - ::nPageOffset ) - nTop
         nxoffset    := ( nRectWidth - ( nRectHeight / ::nxyfactor ) )
         nBottom     := ( nRectWidth - nxoffset ) * ::nxyfactor + nTop
      else
         nxoffset := 0
      endif

      IF ::lZoom = .F.

         nRectHeight := nHeight - 38 - ::oWnd:oBar:nHeight - ::oWnd:oMsgBar:nHeight - ;
                        2 * ::nPageOffset
         nRectWidth  := ::nWidth / ::nHeight * nRectHeight
         nLeft       := nWidth / 2 - nRectWidth / 2
         nRight      := nWidth / 2 + nRectWidth / 2

         IF nLeft < ::nPageOffset

            nZuviel := ::nPageOffset - nLeft
            nLeft   := ::nPageOffset
            nRight  -= nZuviel + ::nPageOffset

            nRectHeight := ( nRight - nLeft ) / nRectWidth * nRectHeight

            nTop    := ( nHeight - ::oWnd:oBar:nHeight - ::oWnd:oMsgBar:nHeight ) / 2 - ;
                       nRectHeight / 2
            nBottom := nTop + nRectHeight

         ENDIF

      ENDIF

      oCoors1 := TRect():New( nTop, nLeft, nBottom, nRight )

      AEVAL( ::aMeta, {|x,i| IIF( i <> 1, x:Hide(), ) } )

      ::aMeta[1]:SetCoors( oCoors1 )

   CASE ::nViewPages == 2

      nTop        := ::nMenuBarHeight
      nFactor     := .43
      nWidth      := ::oWnd:nRight-::oWnd:nLeft+1
      nHeight     := ::oWnd:nBottom-::oWnd:nTop+1 - 70 - ::nMenuBarHeight
      nTop1       := (nHeight/2)-((nHeight)*nFactor) + nTop
      nBottom1    := (nHeight/2)+((nHeight)*nFactor) + nTop
      nPageHeight := (nHeight)*nFactor*2         //nBottom1 - nTop1
      nPageWidth  := nPageHeight / ::nxyfactor

      if nWidth-20 < 2*nPageWidth
         nLeft1      := (nWidth/4)-((nWidth/2)*nFactor)
         nRight1     := (nWidth/4)+((nWidth/2)*nFactor)
         nPageWidth  := nRight1 - nLeft1
         nPageHeight := nPageWidth * ::nxyfactor
         nTop1       := nTop + 20
         nBottom1    := nTop1 + nPageHeight
         nLeft2      := nLeft1  + nWidth/2
         nRight2     := nRight1 + nWidth/2
      else
         nLeft1     := (nWidth - 2*nPageWidth) / 3
         nRight1    := nLeft1 + nPageWidth
         nLeft2     := nRight1 + nLeft1
         nRight2    := nLeft2 + nPageWidth
      endif

      oCoors1 := TRect():New( nTop1, nLeft1, nBottom1 ,nRight1)
      oCoors2 := TRect():New( nTop1, (nLeft2-9), nBottom1, nRight2-9)

      IF ::nPage == ::nTotalPages
         ::aMeta[2]:SetFile("")
      ELSE
         ::aMeta[2]:SetFile(::aFiles[::nPage+1])
      ENDIF

      ::aMeta[1]:SetCoors(oCoors1)
      ::aMeta[2]:SetCoors(oCoors2)

      AEVAL( ::aMeta, {|x,i| IIF( i > 2, x:Hide(), ) } )

      ::aMeta[2]:Show()

   CASE ::nViewPages == 4

      nFactor     := .43
      nWidth      := ::oWnd:nRight-::oWnd:nLeft+1
      nHeight     := ::oWnd:nBottom-::oWnd:nTop+1 - 70 - ::nMenuBarHeight
      nTop        := ::nMenuBarHeight
      nTop1       := (nHeight/4)-((nHeight/2)*nFactor)+ nTop
      nBottom1    := (nHeight/4)+((nHeight/2)*nFactor)+ nTop
      nPageHeight := nBottom1 - nTop1
      nPageWidth  := nPageHeight / ::nxyfactor
      nTop3       := nTop1 + nHeight/2
      nBottom3    := nBottom1 + nHeight/2

      if nWidth-20 < 2*nPageWidth
         nLeft1     := (nWidth/4)-((nWidth/2)*nFactor)
         nRight1    := (nWidth/4)+((nWidth/2)*nFactor)

         nPageWidth  := nRight1 - nLeft1
         nPageHeight := nPageWidth * ::nxyfactor
         nTop1       := nTop + 20
         nBottom1    := nTop1 + nPageHeight
         nLeft2      := nLeft1  + nWidth/2 -9
         nRight2     := nRight1 + nWidth/2 -9
         nTop3       := nTop1 + nHeight/2
         nBottom3    := nBottom1 + nHeight/2
      else
         nLeft1     := (nWidth - 2*(nPageWidth-9)) / 3 - 9
         nRight1    := nLeft1 + nPageWidth
         nLeft2     := nRight1 +  nLeft1
         nRight2    := nLeft2 + nPageWidth
      endif

      oCoors1 := TRect():New( nTop1, nLeft1, nBottom1 ,nRight1)
      oCoors2 := TRect():New( nTop1, (nLeft2), nBottom1, nRight2)
      oCoors3 := TRect():New( nTop3, nLeft1, nBottom3, nRight1)
      oCoors4 := TRect():New( nTop3, (nLeft2), nBottom3, nRight2)

      ::aMeta[1]:SetCoors(oCoors1)
      ::aMeta[2]:SetCoors(oCoors2)
      ::aMeta[3]:SetCoors(oCoors3)
      ::aMeta[4]:SetCoors(oCoors4)

      ::aMeta[2]:Show()
      ::aMeta[3]:Show()
      ::aMeta[4]:Show()

      ::ShowPages()

      AEVAL( ::aMeta, {|x,i| IIF( i > 4, x:Hide(), ) } )

   CASE ::nViewPages == 6

      nFactor     := .43
      nWidth      := ::oWnd:nRight-::oWnd:nLeft+1
      nHeight     := ::oWnd:nBottom-::oWnd:nTop+1 - 70 - ::nMenuBarHeight
      nTop        := ::nMenuBarHeight
      nTop1       := (nHeight/4)-((nHeight/2)*nFactor)+ nTop
      nBottom1    := (nHeight/4)+((nHeight/2)*nFactor)+ nTop
      nPageHeight := nBottom1 - nTop1
      nPageWidth  := nPageHeight / ::nxyfactor
      nTop4       := nTop1 + nHeight/2
      nBottom4    := nBottom1 + nHeight/2

      if nWidth-20 < 3*nPageWidth
         nLeft1      := (nWidth/6)-((nWidth/3)*nFactor)
         nRight1     := (nWidth/6)+((nWidth/3)*nFactor)
         nPageWidth  := nRight1 - nLeft1
         nPageHeight := nPageWidth * ::nxyfactor

         nTop1    := nTop + 20
         nBottom1 := nTop1 + nPageHeight

         nLeft2   := nLeft1  + nWidth/3 -9
         nRight2  := nRight1 + nWidth/3 -9

         nLeft3   := nLeft2  + nWidth/3 -9
         nRight3  := nRight2 + nWidth/3 -9

         nTop4    := nTop1 + nHeight/2
         nBottom4 := nBottom1 + nHeight/2
      else
         nLeft1   := (nWidth - 3*(nPageWidth-9))/4 - 9
         nRight1  := nLeft1 + nPageWidth

         nLeft2   := nRight1 + nLeft1
         nRight2  := nLeft2 + nPageWidth

         nLeft3   := nRight2 + nLeft1
         nRight3  := nLeft3 + nPageWidth
      endif

      oCoors1 := TRect():New( nTop1, nLeft1, nBottom1 ,nRight1)
      oCoors2 := TRect():New( nTop1, nLeft2, nBottom1, nRight2)
      oCoors3 := TRect():New( nTop1, nLeft3, nBottom1, nRight3)
      oCoors4 := TRect():New( nTop4, nLeft1, nBottom4, nRight1)
      oCoors5 := TRect():New( nTop4, nLeft2, nBottom4, nRight2)
      oCoors6 := TRect():New( nTop4, nLeft3, nBottom4, nRight3)

      ::aMeta[1]:SetCoors(oCoors1)
      ::aMeta[2]:SetCoors(oCoors2)
      ::aMeta[3]:SetCoors(oCoors3)
      ::aMeta[4]:SetCoors(oCoors4)
      ::aMeta[5]:SetCoors(oCoors5)
      ::aMeta[6]:SetCoors(oCoors6)

      AEVAL( ::aMeta, {|x,i| IIF( i > 1, x:Hide(), ) } )

      ::aMeta[2]:Show()
      ::aMeta[3]:Show()
      ::aMeta[4]:Show()
      ::aMeta[5]:Show()
      ::aMeta[6]:Show()

      ::ShowPages()

      AEVAL( ::aMeta, {|x,i| IIF( i > 6, x:Hide(), ) } )

   CASE ::nViewPages == 8

      nFactor     := .43
      nWidth      := ::oWnd:nRight-::oWnd:nLeft+1
      nHeight     := ::oWnd:nBottom-::oWnd:nTop+1 - 70 - ::nMenuBarHeight
      nTop        := ::nMenuBarHeight
      nTop1       := (nHeight/4)-((nHeight/2)*nFactor)+ nTop
      nBottom1    := (nHeight/4)+((nHeight/2)*nFactor)+ nTop
      nPageHeight := nBottom1 - nTop1
      nPageWidth  := nPageHeight / ::nxyfactor
      nTop5       := nTop1 + nHeight/2
      nBottom5    := nBottom1 + nHeight/2

      if nWidth-20 < 4*nPageWidth
         nLeft1      := (nWidth/8)-((nWidth/4)*nFactor)+9
         nRight1     := (nWidth/8)+((nWidth/4)*nFactor)+9
         nPageWidth  := nRight1 - nLeft1
         nPageHeight := nPageWidth * ::nxyfactor

         nTop1      := nTop + 20
         nBottom1   := nTop1 + nPageHeight

         nLeft2     := nLeft1  + nWidth/4 -9
         nRight2    := nRight1 + nWidth/4 -9

         nLeft3     := nLeft2  + nWidth/4 -9
         nRight3    := nRight2 + nWidth/4 -9

         nLeft4     := nLeft3  + nWidth/4 -9
         nRight4    := nRight3 + nWidth/4 -9

         nTop5      := nTop1    + nHeight/2
         nBottom5   := nBottom1 + nHeight/2


      else
         nLeft1     := (nWidth - 4*(nPageWidth-9))/5 - 9
         nRight1    := nLeft1 + nPageWidth

         nLeft2     := nRight1 + nLeft1
         nRight2    := nLeft2 + nPageWidth

         nLeft3     := nRight2 + nLeft1
         nRight3    := nLeft3 + nPageWidth

         nLeft4     := nRight3 + nLeft1
         nRight4    := nLeft4 + nPageWidth
      endif

      oCoors1 := TRect():New( nTop1, nLeft1, nBottom1 ,nRight1 )
      oCoors2 := TRect():New( nTop1, nLeft2, nBottom1, nRight2 )
      oCoors3 := TRect():New( nTop1, nLeft3, nBottom1, nRight3 )
      oCoors4 := TRect():New( nTop1, nLeft4, nBottom1, nRight4 )
      oCoors5 := TRect():New( nTop5, nLeft1, nBottom5, nRight1 )
      oCoors6 := TRect():New( nTop5, nLeft2, nBottom5, nRight2 )
      oCoors7 := TRect():New( nTop5, nLeft3, nBottom5, nRight3 )
      oCoors8 := TRect():New( nTop5, nLeft4, nBottom5, nRight4 )

      ::aMeta[1]:SetCoors(oCoors1)
      ::aMeta[2]:SetCoors(oCoors2)
      ::aMeta[3]:SetCoors(oCoors3)
      ::aMeta[4]:SetCoors(oCoors4)
      ::aMeta[5]:SetCoors(oCoors5)
      ::aMeta[6]:SetCoors(oCoors6)
      ::aMeta[7]:SetCoors(oCoors7)
      ::aMeta[8]:SetCoors(oCoors8)

      ::aMeta[2]:Show()
      ::aMeta[3]:Show()
      ::aMeta[4]:Show()
      ::aMeta[5]:Show()
      ::aMeta[6]:Show()
      ::aMeta[7]:Show()
      ::aMeta[8]:Show()

      ::ShowPages()

   ENDCASE

   ::aMeta[1]:SetFocus()

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: ChangePage
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD ChangePage( nTyp, lBarRefresh, nNewPage ) CLASS EPREVIEW

   LOCAL i

   DEFAULT lBarRefresh := .T.

   DO CASE
   CASE nTyp = PAGE_NEXT   ; IIF( ::nPage < ::nTotalPages, ::nPage++, )
   CASE nTyp = PAGE_PREV   ; IIF( ::nPage > 1, ::nPage--, )
   CASE nTyp = PAGE_TOP    ; ::nPage := 1
   CASE nTyp = PAGE_BOTTOM ; ::nPage := ::nTotalPages
   CASE nTyp = PAGE_GOTO   ; ::nPage := nNewPage
   ENDCASE

   ::oPage:SetText( EP_GL("Page number:") + " " + ;
      alltrim(str(::nPage,4,0)) + " / " + alltrim(str( ::nTotalPages )) )

   ::ShowPages()

   AEVAL( ::aPageBtn, {|x| x:Refresh() } )

   IF lBarRefresh
      ::oBar:AEvalWhen()
   ENDIF

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: ShowPages
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD ShowPages() CLASS EPREVIEW

   LOCAL i

   ::aMeta[1]:SetFile(::aFiles[::nPage])
   ::aMeta[1]:Refresh()

   FOR i := 2 TO ::nViewPages
      ::aMeta[i]:SetFile( IIF( ::nPage+i-1 > ::nTotalPages, "", ::aFiles[::nPage+i-1] ) )
      ::aMeta[i]:Refresh()
   NEXT

   ::aMeta[1]:SetFocus()

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: SetPages
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SetPages( nPages, lMenu ) CLASS EPREVIEW

   LOCAL hOldRes := GetResources()

   IF ::lUseDLL = .T.
      SET RESOURCES TO ::cResFile
   ENDIF

   DEFAULT lMenu := .F.

   IIF( ::nViewPages == nPages, ::nViewPages := 1, ::nViewPages := nPages )

   AEVAL( ::aMenuPage, {|x| x:Enable() } )

   IF ::lLandscape .OR. ::nTotalPages == 1
      ::nViewPages := 1
      MessageBeep()
      SetResources(hOldRes)
      RETU NIL
   ENDIF

   IF ::nViewPages > 1

      IF ::lZoom
         ::Zoom(.T.)
      ENDIF

      ::oTwoPages:FreeBitmaps()

      IF ::lMenuBarExtern = .T.
         ::oTwoPages:LoadBitmaps( ,, ::cMenuBarDir + "pages1.bmp",,, ::cMenuBarDir + "unabled_pages1.bmp" )
      ELSE
         ::oTwoPages:LoadBitmaps("EP_One_Page")
      ENDIF

      ::oTwoPages:cTooltip := Strtran( EP_GL("&One Page") , "&", "" )

      IF ::nViewPages = 2
         ::aMenuPage[2]:Disable()
      ELSEIF ::nViewPages = 4
         ::aMenuPage[3]:Disable()
      ELSEIF ::nViewPages = 6
         ::aMenuPage[4]:Disable()
      ELSEIF ::nViewPages = 8
         ::aMenuPage[5]:Disable()
      ENDIF

   ELSE

      ::oTwoPages:FreeBitmaps()

      IF ::lMenuBarExtern = .T.
         ::oTwoPages:LoadBitmaps( ,, ::cMenuBarDir + "pages2.bmp",,, ::cMenuBarDir + "unabled_pages2.bmp" )
      ELSE
         ::oTwoPages:LoadBitmaps("EP_Two_Pages")
      ENDIF

      ::oTwoPages:cTooltip := Strtran( EP_GL("&Two Pages") , "&", "" )
      ::aMenuPage[1]:disable()

   ENDIF

   IF lMenu
      ::oTwoPages:Refresh()
   ENDIF

   IIF( ::nTotalPages < 4, ::aMenuPage[3]:Disable(), )
   IIF( ::nTotalPages < 2, ::aMenuPage[2]:Disable(), )

   ::oBar:AEvalWhen()
   ::oWnd:Refresh()
   ::PaintMeta()
   SetResources(hOldRes)

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: GoToPage
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GoToPage() CLASS EPREVIEW

   LOCAL oDlg
   LOCAL oPrev   := SELF
   LOCAL lSave   := .F.
   LOCAL nPage   := 1
   LOCAL hOldRes := GetResources()

   IF ::lUseDLL = .T.
      SET RESOURCES TO ::cResFile
   ENDIF

   DEFINE DIALOG oDlg NAME "EP_GOTOPAGE" TITLE STRTRAN( EP_GL("&Go to") , "&", "" )

   REDEFINE BUTTON PROMPT EP_GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT EP_GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE GET nPage ID 201 OF oDlg SPINNER MIN 1 MAX oPrev:nTotalPages PICTURE "99999" ;
      VALID nPage > 0 .AND. nPage <= oPrev:nTotalPages

   REDEFINE SAY PROMPT EP_GL("Page") + ":" ID 171 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED

   IF lSave = .T. .AND. nPage > 0 .AND. nPage <= oPrev:nTotalPages
      ::ChangePage( PAGE_GOTO, .T., nPage )
   ENDIF

   SetResources(hOldRes)

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: Zoom
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD Zoom( lMenu ) CLASS EPREVIEW

   LOCAL nViewTmpPages := ::nViewPages
   LOCAL hOldRes := GetResources()

   IF ::lUseDLL = .T.
      SET RESOURCES TO ::cResFile
   ENDIF

   DEFAULT lMenu := .F.

   ::lZoom := !::lZoom

   IF ::lZoom

      IF ::nViewPages > 1
         ::SetPages( 1, .T. )
      ENDIF

      ::oZoom:FreeBitmaps()
      IF ::lMenuBarExtern = .T.
         ::oZoom:LoadBitmaps( ,, ::cMenuBarDir + "unzoom.bmp" )
      ELSE
         ::oZoom:LoadBitmaps("EP_Unzoom")
      ENDIF
      ::oZoom:cTooltip := Strtran( EP_GL("Nor&mal") , "&", "" )
      ::oMenuZoom:disable()
      oMenuUnZoom:enable()

      ::oWnd:oVScroll:SetRange( 1, ::nVScrollSteps )
      ::oWnd:oHScroll:SetRange( 1, ::nHScrollSteps )

      ::aMeta[1]:ZoomIn()

   ELSE

      ::oZoom:FreeBitmaps()
      IF ::lMenuBarExtern = .T.
         ::oZoom:LoadBitmaps( ,, ::cMenuBarDir + "zoom.bmp" )
      ELSE
         ::oZoom:LoadBitmaps("EP_Zoom")
      ENDIF
      ::oZoom:cTooltip := Strtran( EP_GL("&Zoom"), "&", "" )
      ::oMenuZoom:enable()
      oMenuUnZoom:disable()

      ::oWnd:oVScroll:SetRange(0,0)
      ::oWnd:oHScroll:SetRange(0,0)

      ::aMeta[1]:ZoomOut()

   ENDIF

   IF lMenu
      ::oZoom:Refresh()
   ENDIF

   ::PaintMeta()
   SetResources(hOldRes)

   ::nViewPages := nViewTmpPages

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: SoftZoom
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SoftZoom( lPlus ) CLASS EPREVIEW

   IF lPlus = .T.
      nZFactor += ::nSoftZoom
   ELSEIF nZFactor > 1
      nZFactor -= ::nSoftZoom
   ENDIF

   ::SetFactor( nZFactor )

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: VScroll
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD VScroll( nType, lPage, nSteps ) CLASS EPREVIEW

   LOCAL nYorig, nStep
   LOCAL nMetaSize := ::aMeta[1]:nHeight / ::aMeta[1]:nYFactor
   LOCAL nYfactor := Int( ( ::nVertRes - nMetaSize ) / ::oWnd:oVScroll:nMax )

   DEFAULT lPage := .F.

   IF nSteps != NIL
      nStep := nSteps
   ELSEIF lPage
      nStep := ::oWnd:oVScroll:nMax/10
   ELSE
      nStep := 1
   ENDIF

   IF nType == GO_UP
      nStep := -(nStep)
   ELSEIF nType == PAGE_BOTTOM
      ::oWnd:oVscroll:SetPos( ::nVScrollSteps )
   ENDIF

   nYorig := nYfactor * ( ::oWnd:oVScroll:GetPos() + nStep - 1 )

   IF nYorig > ::nVertRes - nMetaSize
      nYorig := ::nVertRes - nMetaSize
   ENDIF

   IF nYorig < 0
      nYorig := 0
   ENDIF

   ::aMeta[1]:SetOrg(NIL,nYorig)

   ::aMeta[1]:Refresh()

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: HScroll
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD HScroll( nType, lPage, nSteps ) CLASS EPREVIEW

   LOCAL nXorig, nStep
   LOCAL nMetaSize := ::aMeta[1]:nWidth
   LOCAL nXfactor  := Int( ( ::nHorzRes - nMetaSize ) / ::oWnd:oHScroll:nMax )

   DEFAULT lPage := .F.

   IF nSteps != NIL
      nStep := nSteps
   ELSEIF lPage
      nStep := ::oWnd:oHScroll:nMax/10
   ELSE
      nStep := 1
   ENDIF

   IF nType == GO_LEFT
      nStep := -(nStep)
   ENDIF

   nXorig := nXfactor * ( ::oWnd:oHScroll:GetPos() + nStep - 1 )

   IF nXorig > ::nHorzRes - nMetaSize
      nXorig := ::nHorzRes - nMetaSize
   ENDIF

   IF nXorig < 0
      nXorig := 0
   ENDIF

   ::aMeta[1]:SetOrg(nXorig,NIL)

   ::aMeta[1]:Refresh()

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: SetOrg1
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SetOrg1( nX, nY ) CLASS EPREVIEW

     LOCAL oCoors
     LOCAL nXStep, nYStep, nXFactor, nYFactor,;
           nWidth, nHeight, nXOrg

     IF ::lZoom
        ::Zoom(.T.)
        RETU NIL
     ENDIF

     oCoors   := ::aMeta[1]:GetRect()
     nWidth   := oCoors:nRight- oCoors:nLeft + 1
     nHeight  := oCoors:nBottom - oCoors:nTop + 1
     nXStep   := Max( Int( nX * ::nHScrollSteps / nWidth  ) + 1, 0 )
     nYStep   := Max( Int( nY * ::nVScrollSteps / nHeight ) + 1, 0 )
     //nXStep   := Max(Int(nX/nWidth*::nHScrollSteps) - 9, 0)
     //nYStep   := Max(Int(nY/nHeight*::nVScrollSteps) - 9, 0)
     //nXFactor := Int(::oDevice:nHorzRes()/::nHScrollSteps)
     //nYFactor := Int(::oDevice:nVertRes()/::nVScrollSteps)
     ::Zoom(.T.)

     IF !empty(nXStep)
          ::HScroll(2,,nxStep)
          ::oWnd:oHScroll:SetPos(nxStep)
     ENDIF

     IF !empty(nYStep)
          ::VScroll(2,,nyStep)
          ::oWnd:oVScroll:SetPos(nyStep)
     ENDIF

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: SetOrg2
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SetOrg2( nX, nY, nCurPage ) CLASS EPREVIEW

   LOCAL oCoors, nXStep, nYStep, nXFactor, nYFactor, nWidth, nHeight, nXOrg

   DEFAULT nCurPage := 2

   IF ::aMeta[nCurPage]:cCaption == ""
      RETU NIL
   ENDIF

   IF ::lZoom
      ::Zoom(.T.)
      RETU NIL
   ENDIF

   oCoors   := ::aMeta[nCurPage]:GetRect()
   nWidth   := oCoors:nRight - oCoors:nLeft + 1
   nHeight  := oCoors:nBottom - oCoors:nTop + 1
   nXStep   := Max(Int(nX/nWidth*::nHScrollSteps) - 9, 0)

   nXStep   := Max( Int( nX * ::nHScrollSteps / nWidth  ) + 1, 0 )
   nYStep   := Max( Int( nY * ::nVScrollSteps / nHeight ) + 1, 0 )

   //nXStep   := Max(Int(nX/nWidth*::nHScrollSteps) - 9, 0)
   //nYStep   := Max(Int(nY/nHeight*::nVScrollSteps) - 9, 0)
   //nXFactor := Int(::oDevice:nHorzRes()/::nHScrollSteps)
   //nYFactor := Int(::oDevice:nVertRes()/::nVScrollSteps)

   ::aMeta[1]:SetFile(::aMeta[nCurPage]:cCaption)

   IF ::nPage = ::nTotalPages
      ::aMeta[nCurPage]:SetFile("")
   ELSE
      ::nPage += nCurPage - 1
      ::aMeta[nCurPage]:SetFile(::aFiles[::nPage])
   ENDIF

   ::oPage:Refresh()

   ::Zoom(.T.)

   IF !empty(nXStep)
      ::HScroll(2,,nxStep)
      ::oWnd:oHScroll:SetPos(nxStep)
   ENDIF

   IF !empty(nYStep)
      ::VScroll(2,,nyStep)
      ::oWnd:oVScroll:SetPos(nyStep)
   ENDIF

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: CheckKey
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD CheckKey( nKey, nFlags ) CLASS EPREVIEW

   IF nKey == VK_SUBTRACT
      ::SoftZoom( .F. )
   ELSEIF nKey == VK_ADD
      ::SoftZoom( .T. )
   ELSEIF nKey == VK_PRIOR
      ::ChangePage( PAGE_PREV )
   ELSEIF nKey == VK_NEXT
      ::ChangePage( PAGE_NEXT )
   ELSEIF nKey == VK_RETURN
      ::Zoom( .T. )
   ELSEIF !::lZoom
      DO CASE
      CASE nKey == VK_HOME
         ::ChangePage( PAGE_TOP )
      CASE nKey == VK_UP .OR. nKey == VK_LEFT
         ::ChangePage( PAGE_PREV )
      CASE nKey == VK_END
         ::ChangePage( PAGE_BOTTOM )
      CASE nKey == VK_DOWN .OR. nKey == VK_RIGHT
         ::ChangePage( PAGE_NEXT )
      ENDCASE
   ELSE
      DO CASE
      CASE nKey == VK_UP
         ::oWnd:oVScroll:GoUp()
      CASE nKey == VK_DOWN
         ::oWnd:oVScroll:GoDown()
      CASE nKey == VK_LEFT
         ::oWnd:oHScroll:GoUp()
      CASE nKey == VK_RIGHT
         ::oWnd:oHScroll:GoDown()
      CASE nKey == VK_HOME
         ::oWnd:oVScroll:GoTop()
         ::oWnd:oHScroll:GoTop()
         ::aMeta[1]:SetOrg(0,0)
         ::aMeta[1]:Refresh()
      CASE nKey == VK_END
         ::oWnd:oVScroll:GoBottom()
         ::oWnd:oHScroll:GoBottom()
         //::aMeta[1]:SetOrg(.8*::oDevice:nHorzRes(),.8*::oDevice:nVertRes())
         ::VScroll( PAGE_BOTTOM )
         ::aMeta[1]:Refresh()
      ENDCASE
   ENDIF

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: SetFactor
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SetFactor( nValue ) CLASS EPREVIEW

   LOCAL lInit := .F.

   IF nValue == NIL
      Aeval(::aFactor, {|v,e| v:nHelpId := e})
      nValue := nZFactor
      lInit  := .T.
   ENDIF

   Aeval(::aFactor, {|val,elem| val:SetCheck( (elem == ASCAN( ::aZoomFactor, nZFactor ) ) ) })

   ::aMeta[1]:SetZoomFactor( nZFactor, nZFactor * 2 )

   IF !::lZoom .AND. !lInit
      ::Zoom(.T.)
   ENDIF

   IF ::lZoom
      ::oWnd:oVScroll:SetRange(1,::nVScrollSteps)
      ::oWnd:oHScroll:SetRange(1,::nHScrollSteps)
   ENDIF

   ::aMeta[1]:SetFocus()

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: PrintPage
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrintPage( lExit ) CLASS EPREVIEW

   LOCAL n, oDlg, oRad, oPageIni, oPageFin, oCopies, aGrp[2], oLbx
   LOCAL hOldRes    := GetResources()
   LOCAL hMeta      := ::aMeta[1]:hMeta
   LOCAL nTmpCopies := ::nCopies
   LOCAL nOption    := 1
   LOCAL nFirst     := 1
   LOCAL nLast      := ::nTotalPages
   LOCAL nSeite     := 1
   LOCAL aSeiten    := {}

   DEFAULT lExit := .F.

   IF lExit = .T.
      ::PrintPrv( NIL, nOption, nFirst, nLast, nTmpCopies )
      ::oWnd:End()
      RETURN NIL
   ENDIF

   IF ::lUseDLL = .T.
      SET RESOURCES TO ::cResFile
   ENDIF

   FOR n := 1 to ::nTotalPages
      AADD( aSeiten, Strtran( EP_GL("&Page"), "&", "" ) + " " + alltrim(str(n)) )
   NEXT

   DEFINE DIALOG oDlg RESOURCE "EP_PRINT" TITLE EP_GL("Printing")

   REDEFINE BUTTON PROMPT EP_GL("&Print") ID 101 OF oDlg ;
      ACTION ::PrintPrv( oDlg, nOption, nFirst, nLast, nTmpCopies, oLbx:GetSelItems(), .T. )

   REDEFINE BUTTON PROMPT EP_GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE RADIO oRad VAR nOption ID 301, 302, 303, 304, 305, 306 OF oDlg ;
      ON CHANGE ( IIF( nOption == 3, ;
                       ( oPageIni:Enable(), oPageFin:Enable() ), ;
                       ( oPageIni:Disable(),oPageFin:Disable() ) ), ;
                  IIF( nOption == 4, oLbx:Enable(), oLbx:Disable() ) )

   REDEFINE GET oPageIni VAR nFirst ID 311 PICTURE "@K 99999" OF oDlg ;
      VALID IIF( nFirst < 1 .OR. nFirst > nLast, ( MessageBeep(), .F. ), .T. ) ;
      SPINNER ON UP   IIF( nFirst >= nLast,, ( ++nFirst, oPageIni:Refresh() ) ) ;
              ON DOWN IIF( nFirst <= 1    ,, ( --nFirst, oPageIni:Refresh() ) )

   REDEFINE GET oPageFin VAR nLast ID 312 PICTURE "@K 99999" OF oDlg ;
      VALID IIF( nLast < nFirst .OR. nLast > ::nTotalPages, (MessageBeep(),.F.), .T. ) ;
      SPINNER ON UP   IIF( nLast >= ::nTotalPages,, ( ++nLast, oPageFin:Refresh() ) ) ;
              ON DOWN IIF( nLast <= nFirst       ,, ( --nLast, oPageFin:Refresh() ) )

   oPageIni:Disable()
   oPageFin:Disable()

   REDEFINE LISTBOX oLbx VAR nSeite ITEMS aSeiten ID 321 OF oDlg
   oLbx:Disable()

   REDEFINE GET oCopies VAR nTmpCopies ID 501 PICTURE "@K 99999" OF oDlg ;
      VALID IIF( nTmpCopies < 1, ( MessageBeep(), .F. ), .T. ) ;
      SPINNER ON UP   ( ++nTmpCopies, oCopies:Refresh() ) ;
              ON DOWN IIF( nTmpCopies = 1,, ( --nTmpCopies, oCopies:Refresh() ) )

   REDEFINE GROUP aGrp[1] ID 191 OF oDlg
   REDEFINE GROUP aGrp[2] ID 192 OF oDlg

   REDEFINE SAY PROMPT EP_GL("Number") + ":" ID 601 OF oDlg
   REDEFINE SAY PROMPT EP_GL("to")           ID 174 OF oDlg

   ACTIVATE DIALOG oDlg CENTER ;
      ON INIT ( aGrp[1]:SetText( Strtran( EP_GL("&Print"), "&", "" ) ), ;
                aGrp[2]:SetText( EP_GL("Copies") ), ;
                oRad:aItems[1]:SetText( EP_GL("All pages") ), ;
                oRad:aItems[2]:SetText( EP_GL("Current page") ), ;
                oRad:aItems[3]:SetText( EP_GL("From page") + ":" ), ;
                oRad:aItems[4]:SetText( EP_GL("Selected pages") + ":" ), ;
                oRad:aItems[5]:SetText( EP_GL("Odd pages") ), ;
                oRad:aItems[6]:SetText( EP_GL("Even pages") ) )

   SetResources(hOldRes )

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: PrintPrv
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrintPrv( oDlg, nOption, nPageIni, nPageEnd, nCopies, aSelect, lPrinterSelect ) CLASS EPREVIEW

   LOCAL nFor, nCopy, oTmpDevice
   LOCAL lEnd    := .T.
   LOCAL nWidth  := ::nPrWidth   //::nWidth
   LOCAL nHeight := ::nPrHeight  //::nHeight

   DEFAULT lPrinterSelect := .F.

   CursorWait()

   IF lPrinterSelect = .F. .OR. ::lSelectPrinter = .F.

      lEnd       := .F.
      oTmpDevice := ::oDevice

      IF ::nOrientation = 1
         oTmpDevice:SetPortrait()
         IF ::nPaperType = 0
            oTmpDevice:SetSize( nWidth, nHeight )
         ENDIF
      ELSE
         oTmpDevice:SetLandscape()
         IF ::nPaperType = 0
            oTmpDevice:SetSize( nHeight, nWidth )
         ENDIF
      ENDIF

      IF ::nPaperType <> 0
         oTmpDevice:SetPage( ::nPaperType )
      ENDIF

   ELSE

      IF ::nOrientation = 1
         PrnPortrait( ::oDevice:hDC )
         IF ::nPaperType = 0
            PrnSetSize( nWidth, nHeight )
         ENDIF
      ELSE
         PrnLandscape( ::oDevice:hDC )
         IF ::nPaperType = 0
            PrnSetSize( nHeight, nWidth )
         ENDIF
      ENDIF

      IF ::nPaperType <> 0
         PrnSetPage( ::nPaperType )
      ENDIF

      oTmpDevice := PrintBegin( ::oDevice:cDocument, .T. )

      IF oTmpDevice = NIL
      //IF oTmpDevice:lQuit = .T.
         RETURN NIL
      ENDIF

      IF ::nOrientation = 1
         oTmpDevice:SetPortrait()
         IF ::nPaperType = 0
            oTmpDevice:SetSize( nWidth, nHeight )
         ENDIF
      ELSE
         oTmpDevice:SetLandscape()
         IF ::nPaperType = 0
            oTmpDevice:SetSize( nHeight, nWidth )
         ENDIF
      ENDIF

      IF ::nPaperType <> 0
         oTmpDevice:SetPage( ::nPaperType )
      ENDIF

      oTmpDevice:aMeta   := ::oDevice:aMeta
      oTmpDevice:nOrient := ::nOrientation

   ENDIF

   IF ::nBin <> 0
      oTmpDevice:SetBin( ::nBin )
   ENDIF

   FOR nCopy := 1 to nCopies

      StartDoc( oTmpDevice:hDC, oTmpDevice:cDocument )

      DO CASE
      CASE nOption == 1
         FOR nFor := nPageIni TO nPageEnd
            ::PrintCurPage( oTmpDevice, ::aFiles[ nFor ] )
         NEXT
      CASE nOption == 2
         ::PrintCurPage( oTmpDevice, ::aFiles[ ::nPage ] )
      CASE nOption == 3
         FOR nFor := nPageIni TO nPageEnd
            ::PrintCurPage( oTmpDevice, ::aFiles[ nFor ] )
         NEXT
      CASE nOption == 4
         FOR nFor := 1 TO LEN( aSelect )
            ::PrintCurPage( oTmpDevice, ::aFiles[ aSelect[ nFor ] ] )
         NEXT
      CASE nOption = 5 .OR. nOption = 6
         FOR nFor := 1 TO ::nTotalPages
            IF nOption = 5 .AND. ::IsEven( nFor ) = .F. .OR. ;
               nOption = 6 .AND. ::IsEven( nFor ) = .T.
               ::PrintCurPage( oTmpDevice, ::aFiles[ nFor ] )
            ENDIF
         NEXT
      ENDCASE

      EndDoc( oTmpDevice:hDC )

   NEXT

   WritePProString( "Broadcast", "WasPrinted", "1", ::cIni )

   CursorArrow()

   IF oDlg != NIL
      oDlg:End()
   ENDIF

   IF lEnd = .T.
      oTmpDevice:End()
      PrinterInit()
   ENDIF

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: PrintCurPage
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrintCurPage( oTmpDevice, cPage ) CLASS EPREVIEW

   LOCAL hMeta, hOldMeta, aRect[4]
   LOCAL aData := PrnGetSize( oTmpDevice:hDC )

   StartPage( oTmpDevice:hDC )

   IF UPPER( cFileExt( cPage ) ) = "WMF"
      hOldMeta := GetMetaFile( cPage )
      hMeta    := wmf2emf( 0, hOldMeta )
      DeleteMetafile( hOldMeta )
   ELSE
      hMeta := GetEnhMetaFile( cPage )
   ENDIF

   aRect[1] := 0
   aRect[2] := 0
   aRect[3] := oTmpDevice:nHorzRes()
   aRect[4] := oTmpDevice:nVertRes()

   EP_PlayEnhMetaFile( oTmpDevice:hDC, hMeta, aRect )

   ::Watermark( oTmpDevice:hDC )
   DeleteEnhMetafile( hMeta )
   EndPage( oTmpDevice:hDC )

RETURN NIL

/*
*-- METHOD -------------------------------------------------------------------
*         Name: PrintCurPage
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrintCurPage( oTmpDevice, cPage ) CLASS EPREVIEW

   LOCAL hMeta, hOldMeta

   StartPage( oTmpDevice:hDC )

   IF UPPER( cFileExt( cPage ) ) = "WMF"
      hOldMeta := GetMetaFile( cPage )
      hMeta    := wmf2emf( 0, hOldMeta )
      DeleteMetafile( hOldMeta )
   ELSE
      hMeta := GetEnhMetaFile( cPage )
   ENDIF

   EP_PlayEnhMetaFile( oTmpDevice:hDCOut,hMeta,, .T. )

   ::Watermark( oTmpDevice:hDC )
   DeleteEnhMetafile( hMeta )
   EndPage( oTmpDevice:hDC )

RETURN NIL
*/

*-- METHOD -------------------------------------------------------------------
*         Name: EMail
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EMail( lDirectSave ) CLASS EPREVIEW

   LOCAL i, oDlg, oIni, aGet[4], oSay, oMail, cPara, aFiles
   LOCAL oPrev         := SELF
   LOCAL hOldRes       := GetResources()
   LOCAL cTo           := ::cTo
   LOCAL cCc           := ::cCc
   LOCAL cBcc          := ::cBcc
   LOCAL cSubject      := ::cSubject
   LOCAL lDelAfterMail := ::lDelAfterMail
   LOCAL cText         := ""
   LOCAL lExit         := .F.
   LOCAL cCurDir       := hb_CurDrive() + ":\" + CurDir()
   LOCAL cFiles        := ""

   DEFAULT lDirectSave := .F.

   IF lDirectSave = .F. .AND. ::PrViewSave( .T. ) = .F.
      RETURN NIL
   ENDIF

   IF EMPTY( GetPvProfString( "Sendto", "ServerIP", "", ::cIni ) )
      WritePProString( "Sendto", "ServerIP", EP_SMTPInfo()[1], ::cIni )
   ENDIF
   IF EMPTY( GetPvProfString( "Sendto", "Adress", "", ::cIni ) )
      WritePProString( "Sendto", "Adress", EP_SMTPInfo()[2], ::cIni )
   ENDIF

   IF GetPvProfString( "Sendto", "UseExternalClient", "0", ::cIni ) = "1"

      IF GetPvProfString( "Sendto", "UseExternalMAPI", "0", ::cIni ) = "1"

         AEVAL( oPrev:EMailFiles(), { |x,y| cFiles += IIF( y = 1, "", " ; " ) + ALLTRIM( x ) } )

         cPara := "/E /A " + ALLTRIM( cTo ) + ;
                  " /S " + ALLTRIM( PADR( cSubject, 23 ) ) + ;
                  " /F " + cFiles

         WaitRun( "MAPISend " + cPara, 0 )

         SysRefresh()

      ELSE

         oMail := TMail():New( AllTrim( cSubject ),,,,,,,,, ;
            IIF( Empty( AllTrim( cTo ) ), Nil, { { AllTrim( cTo ) } } ), ::EMailFiles() )

         //oMail := TMail():New( ALLTRIM( cSubject ),,,,,,,,, ;
         //   IIF( EMPTY( ALLTRIM( cTo ) ), NIL, { ALLTRIM( cTo ) } ), ::EMailFiles() )
         oMail:Activate()

      ENDIF

      //Pfad zurückstellen, wird von TMail oder MSOutlook geändert
      lChDir( cCurDir )

      IF lDelAfterMail = .T.
         FOR i := 1 TO LEN( ::aFilesSaved )
            FERASE( ::aFilesSaved[i] )
         NEXT
      ENDIF

      RETURN NIL

   ENDIF

   IF ::lUseDLL = .T.
      SET RESOURCES TO ::cResFile
   ENDIF

   DEFINE DIALOG oDlg NAME "EP_EMAIL" TITLE STRTRAN( EP_GL("Send &to") , "&", "" )

   REDEFINE BUTTON PROMPT EP_GL("&Cancel")        ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE BUTTON PROMPT EP_GL("&Send")          ID 101 OF oDlg ;
      ACTION ::EMailSend( oDlg, oSay, cText ) ;
      WHEN EMPTY( cTo ) = .F. .OR. EMPTY( cCc ) = .F. .OR. EMPTY( cBcc ) = .F.
   REDEFINE BUTTON PROMPT EP_GL("Send and &exit") ID 104 OF oDlg ;
      ACTION ( ::EMailSend( oDlg, oSay, cText ), lExit := .T., oDlg:End() ) ;
      WHEN EMPTY( cTo ) = .F. .OR. EMPTY( cCc ) = .F. .OR. EMPTY( cBcc ) = .F.

   REDEFINE BUTTON PROMPT EP_GL("&Options")  ID 103 OF oDlg ACTION oPrev:EMailOptions()

   REDEFINE GET aGet[1] VAR cTo      ID 201 OF oDlg
   REDEFINE GET aGet[2] VAR cCc      ID 202 OF oDlg
   REDEFINE GET aGet[3] VAR cBcc     ID 203 OF oDlg
   REDEFINE GET aGet[4] VAR cSubject ID 204 OF oDlg

   REDEFINE BTNBMP RESOURCE "EP_DEL" ID 121 OF oDlg NOBORDER ACTION ( cTo      := SPACE( 200 ), aGet[1]:Refresh() )
   REDEFINE BTNBMP RESOURCE "EP_DEL" ID 122 OF oDlg NOBORDER ACTION ( cCc      := SPACE( 200 ), aGet[2]:Refresh() )
   REDEFINE BTNBMP RESOURCE "EP_DEL" ID 123 OF oDlg NOBORDER ACTION ( cBcc     := SPACE( 200 ), aGet[3]:Refresh() )
   REDEFINE BTNBMP RESOURCE "EP_DEL" ID 124 OF oDlg NOBORDER ACTION ( cSubject := SPACE( 200 ), aGet[4]:Refresh() )

   REDEFINE GET cText ID 205 OF oDlg MEMO

   REDEFINE SAY oSay PROMPT oPrev:EMailFileInfo() ID 206 OF oDlg

   REDEFINE SAY oSay ID 151 OF oDlg

   REDEFINE SAY PROMPT EP_GL("To")         + ":" ID 171 OF oDlg
   REDEFINE SAY PROMPT EP_GL("Cc")         + ":" ID 172 OF oDlg
   REDEFINE SAY PROMPT EP_GL("Bcc")        + ":" ID 173 OF oDlg
   REDEFINE SAY PROMPT EP_GL("Subject")    + ":" ID 174 OF oDlg
   REDEFINE SAY PROMPT EP_GL("Attachment") + ":" ID 175 OF oDlg

   ACTIVATE DIALOG oDlg CENTER

   INI oIni FILE ::cIni
      SET SECTION "Sendto" ENTRY "To"      TO ALLTRIM( cTo )      OF oIni
      SET SECTION "Sendto" ENTRY "Cc"      TO ALLTRIM( cCc )      OF oIni
      SET SECTION "Sendto" ENTRY "Bcc"     TO ALLTRIM( cBcc )     OF oIni
      SET SECTION "Sendto" ENTRY "Subject" TO ALLTRIM( cSubject ) OF oIni
   ENDINI

   IF lDelAfterMail = .T.
      FOR i := 1 TO LEN( ::aFilesSaved )
         FERASE( ::aFilesSaved[i] )
      NEXT
   ENDIF

   SetResources( hOldRes )

   IF lExit = .T.
      ::oWnd:End()
   ENDIF

RETURN NIL


/*
*-- METHOD -------------------------------------------------------------------
*         Name: EMailSend
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EMailSend( cText ) CLASS EPREVIEW

   LOCAL oMail
   LOCAL cFiles := ""
   LOCAL cIP    := ALLTRIM( GetPvProfString( "Sendto", "ServerIP", "193.158.134.245", ::cIni ) )

   IF EMPTY( cIP )
      MsgStop( "Please insert your server IP in options dialog first." )
      RETURN (.F.)
   ENDIF

   AEVAL( ::EMailFiles(), {|x| cFiles += IIF( EMPTY( cFiles ), "", "," ) + ALLTRIM( x ) } )

   oMail  := tSendMail():New()

   oMail:cSmtp := cIP
   oMail:cFrom := ALLTRIM( GetPvProfString( "Sendto", "Adress"  , "", ::cIni ) )
   oMail:cTo   := ALLTRIM( GetPvProfString( "Sendto", "To"      , "", ::cIni ) )
   oMail:cCc   := ALLTRIM( GetPvProfString( "Sendto", "Cc"      , "", ::cIni ) )
   oMail:cSubject := ALLTRIM( GetPvProfString( "Sendto", "Subject" , "", ::cIni ) )
   oMail:cMsgBody := cText
   oMail:cBinfile := cFiles
   oMail:cComment := ""
   //oMail:lShowResult := .F.
   //oMail:nGmt      := +7
   //oMail:cPriority := 3

   oMail:Send()

RETURN NIL
*/

*-- METHOD -------------------------------------------------------------------
*         Name: EMailSend
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EMailSend( oDlg, oSay, cText ) CLASS EPREVIEW

   LOCAL oInit, oMail
   LOCAL cIP   := ALLTRIM( GetPvProfString( "Sendto", "ServerIP", "193.158.134.245", ::cIni ) )
   LOCAL oRect := oDlg:GetRect()

   oDlg:Move( oRect:nTop, oRect:nLeft, oRect:nRight - oRect:nLeft, oRect:nHeight + 24, .T. )
   SysRefresh()

   oInit := TSmtp():New( GetHostByName( cIP ) )
   oMail := TSmtp():New( cIP := GetHostByName( cIP ) )

   oMail:bConnecting := {|| oSay:SetText( " " + EP_GL("Connecting and waiting for response...") ) }
   oMail:bConnected  := {|| oSay:SetText( " " + EP_GL("Connected, sending mail and attachments...") ) }

   oMail:bDone    := {|| oSay:SetText( " " + EP_GL("Message successfully sent.") ) }

   // not possible with FWH 2.6 May
   //oMail:bFailure := {|| oSay:SetText( " " + EP_GL("Error during message sending:") + ;
   //                                                CRLF + CRLF + oMail:cError ) }

   // Cc and Bcc is not possible with FWH 2.6 May
   oMail:SendMail( ;
      ALLTRIM( GetPvProfString( "Sendto", "Adress"  , "", ::cIni ) ), ;
      { ALLTRIM( GetPvProfString( "Sendto", "To"      , "", ::cIni ) ) }, ;
      cText, ;
      ALLTRIM( GetPvProfString( "Sendto", "Subject" , "", ::cIni ) ), ;
      ::EMailFiles(), ;
      ::EMailCc( ALLTRIM( GetPvProfString( "Sendto", "Cc" , "", ::cIni ) ) ), ;
      ::EMailCc( ALLTRIM( GetPvProfString( "Sendto", "Bcc", "", ::cIni ) ) ) )

   oInit:end()

Return .T.


*-- METHOD -------------------------------------------------------------------
*         Name: EMailFiles
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EMailFiles() CLASS EPREVIEW

   LOCAL cFile     := ""
   LOCAL nFile     := 0
   LOCAL aFiles    := ACLONE( ::aFilesSaved )
   LOCAL cAddFiles := GetPvProfString( "Sendto", "AddFiles", "", ::cIni )

   DO WHILE .T.
      cFile := ALLTRIM( StrToken( cAddFiles, ++nFile, ";" ) )
      IF EMPTY( cFile )
         EXIT
      ELSE
         AADD( aFiles, cFile )
      ENDIF
   ENDDO

RETURN ( aFiles )


*-- METHOD -------------------------------------------------------------------
*         Name: EMailCc
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EMailCc( cValue ) CLASS EPREVIEW

   LOCAL cCc := ""
   LOCAL nCc := 0
   LOCAL aCc := {}

   DO WHILE .T.
      cCc := ALLTRIM( StrToken( cValue, ++nCc, ";" ) )
      IF EMPTY( cCc )
         EXIT
      ELSE
         AADD( aCc, cCc )
      ENDIF
   ENDDO

RETURN ( aCc )


*-- METHOD -------------------------------------------------------------------
*         Name: EMailFileInfo
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EMailFileInfo() CLASS EPREVIEW

   LOCAL cString   := " "
   LOCAL cFileName := GetPvProfString( "Save2File", "FileName", "", ::cIni )
   LOCAL lZip      := IIF( GetPvProfString( "Save2File", "ZipFiles", "0", ::cIni ) = "1", .T., .F. )
   LOCAL cFormat   := GetPvProfString( "Save2File", "Format", "BMP - Windows Bitmap", ::cIni )

   IF lZip = .T. .OR. ::nTotalPages = 1 .OR. SUBSTR( cFormat, 1, 3 ) = "PDF"
      cString += ALLTRIM( ::aFilesSaved[1] )
   ELSE
      cString += ALLTRIM(STR( ::nTotalPages )) + " " + EP_GL("files") + ", " + ;
                 ALLTRIM(STRTRAN( cFilename, ".", "0001." )) + " - " + ;
                 ALLTRIM(STRTRAN( cFilename, ".", ;
                                  PADL( ALLTRIM(STR( ::nTotalPages, 4 )), 4, "0" ) + "." ))

   ENDIF

   cString += CRLF + " " + EP_GL("Format") + ": " + ALLTRIM( cFormat ) + ", " + ;
              EP_GL("Total size:") + " " + ::EMailTotalSize()

RETURN ( cString )


*-- METHOD -------------------------------------------------------------------
*         Name: EMailTotalSize
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EMailTotalSize() CLASS EPREVIEW

   LOCAL nSize := ::TotalFileSize()
   LOCAL cUnit := EP_GL("Byte")

   IF nSize > 10000
      nSize /= 1024
      cUnit := EP_GL("KB")
   ENDIF

RETURN ALLTRIM(STR( nSize, 15 )) + " " + cUnit


*-- METHOD -------------------------------------------------------------------
*         Name: TotalFileSize
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD TotalFileSize() CLASS EPREVIEW

   LOCAL nSize := 0

   AEVAL( ::aFilesSaved, {|x| nSize += FSIZE( x ) } )

RETURN nSize


*-- METHOD -------------------------------------------------------------------
*         Name: CheckEMail
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD CheckEMail( lZip, cFormat, nSaveFiles ) CLASS EPREVIEW

   IF lZip = .F. .AND. UPPER(SUBSTR( cFormat, 1, 3 )) <> "PDF"

      IF ::TotalFileSize() / 1024 / 1024 > 5
         MsgInfo( EP_GL("The total file size is higher than 5 MB.") + CRLF + ;
                  EP_GL("The files will be zipped.")  )
         lZip := .T.
      ELSEIF nSaveFiles > 20
         MsgInfo( EP_GL("You want to send more than 20 files.") + CRLF + ;
                  EP_GL("The files will be zipped.")  )
         lZip := .T.
      ENDIF

   ENDIF

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: EMailOptions
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EMailOptions() CLASS EPREVIEW

   LOCAL oDlg, oIni, oFont, aGrp[2], aGet[2]
   LOCAL oPrev   := SELF
   LOCAL lSave   := .F.
   LOCAL cServerName := PADR( GetPvProfString( "Sendto", "ServerName", "T-Online", ::cIni ), 200 )
   LOCAL cServerIP   := PADR( GetPvProfString( "Sendto", "ServerIP  ", "194.25.134.90", ::cIni ), 200 )
   LOCAL cName       := PADR( GetPvProfString( "Sendto", "Name"      , "", ::cIni ), 200 )
   LOCAL cAdress     := PADR( GetPvProfString( "Sendto", "Adress"    , "", ::cIni ), 200 )

   DEFINE FONT oFont NAME "Arial" SIZE 0, -12

   DEFINE DIALOG oDlg NAME "EP_EMAILOPTIONS" TITLE STRTRAN( EP_GL("&Options") , "&", "" )

   REDEFINE BUTTON PROMPT EP_GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT EP_GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE GET cServerName           ID 201 OF oDlg
   REDEFINE GET aGet[1] VAR cServerIP ID 202 OF oDlg
   REDEFINE GET cName                 ID 203 OF oDlg
   REDEFINE GET aGet[2] VAR cAdress   ID 204 OF oDlg

   REDEFINE BTNBMP RESOURCE "EP_SEARCH" ID 111 OF oDlg NOBORDER ;
      ACTION ( cServerIP := EP_SMTPInfo()[1], aGet[1]:Refresh() )
   REDEFINE BTNBMP RESOURCE "EP_SEARCH" ID 112 OF oDlg NOBORDER ;
      ACTION ( cAdress   := EP_SMTPInfo()[2], aGet[2]:Refresh() )

   REDEFINE GROUP aGrp[1] ID 190 OF oDlg
   REDEFINE GROUP aGrp[2] ID 191 OF oDlg

   REDEFINE SAY PROMPT EP_GL("Name")         + ":" ID 171 OF oDlg
   REDEFINE SAY PROMPT EP_GL("Server-IP")    + ":" ID 172 OF oDlg
   REDEFINE SAY PROMPT EP_GL("Name")         + ":" ID 173 OF oDlg
   REDEFINE SAY PROMPT EP_GL("Email Adress") + ":" ID 174 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( aGrp[1]:SetText( EP_GL("Connection") ), ;
                aGrp[2]:SetText( EP_GL("Email Adress") ) )

   IF lSave = .T.
      INI oIni FILE ::cIni
         SET SECTION "Sendto" ENTRY "ServerName" TO ALLTRIM( cServerName ) OF oIni
         SET SECTION "Sendto" ENTRY "ServerIP"   TO ALLTRIM( cServerIP )   OF oIni
         SET SECTION "Sendto" ENTRY "Name"       TO ALLTRIM( cName )       OF oIni
         SET SECTION "Sendto" ENTRY "Adress"     TO ALLTRIM( cAdress )     OF oIni
      ENDINI
   ENDIF

   oFont:End()

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: EP_RegInfos
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD RegInfos() CLASS EPREVIEW

   LOCAL cKey
   LOCAL cRegText := ""

   SysWait( 0.1 )

   IF FILE( ::cLicenceFile )
      cRegText := DeCrypt( MEMOREAD( ::cLicenceFile ), "Z"+"Y"+"X"+"C"+"B"+"A" )
   ENDIF

   cKey := SUBSTR( cRegText, 8, 3 )

   IF cKey = "413" .OR. cKey = "654"
      cRegText := ALLTRIM( SUBSTR( cRegText, 11, 10 ) + ;
                           SUBSTR( cRegText, 31, 10 ) + ;
                           SUBSTR( cRegText, 51, 10 ) + ;
                           SUBSTR( cRegText, 71, 10 ) + ;
                           SUBSTR( cRegText, 91, 10 ) )
      IF cKey = "413"
         ::lPDF := .T.
         IF ::oWnd <> NIL
            ::oWnd:SetMenu( ::BuildMenu() )
         ENDIF
      ENDIF
   ELSE
      ::lDemo  := .T.
      cRegText := "U"+"n"+"r"+"e"+"g"+"i"+"s"+"t"+"e"+"r"+"e"+"d "+"D"+"e"+"m"+"o "+"V"+"e"+"r"+"s"+"i"+"o"+"n"
   ENDIF

   IF lEasyReport = .T.
      ::lDemo  := .F.
      cRegText := ""
   ENDIF

RETURN ( cRegText )


*-- METHOD -------------------------------------------------------------------
*         Name: Registration
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD Registration() CLASS EPREVIEW

   LOCAL oDlg, oFont
   LOCAL nClrBack := RGB( 255, 255, 255 )
   LOCAL hOldRes := GetResources()

   IF ::lUseDLL = .T.
      SET RESOURCES TO ::cResFile
   ENDIF

   DEFINE FONT oFont  NAME "Arial" SIZE 0, -14

   DEFINE DIALOG oDlg NAME "EP_ORDERINFOS" COLOR 0, nClrBack

   REDEFINE SAY PROMPT "EasyPreview costs 98 Euro." + CRLF + ;
                       "You will find an order form on www.reportdesigner.info." ;
      ID 201 OF oDlg FONT oFont COLOR 0, nClrBack

   REDEFINE BITMAP ID 301 OF oDlg RESOURCE "EP_LOGO"

   REDEFINE SAY PROMPT "by Jürgen Bäz + Timm Sodtalbers, 2001 - 2007" ;
      ID 202 OF oDlg COLOR 0, nClrBack

   REDEFINE BUTTON ID 101 OF oDlg ACTION oDlg:End()
   REDEFINE BUTTON ID 102 OF oDlg ACTION ;
    ShellExecute( 0, "Open", "http://www.reportdesigner.info", Nil, Nil, 1 )

   ACTIVATE DIALOG oDlg CENTER

   oFont:End()

   SetResources( hOldRes )

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: PrViewSave
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrViewSave( lFromSendTo, lDirectSave, nFromPage, nToPage ) CLASS EPREVIEW

   LOCAL oDlg, n, oImg, oPageIni, oPageFin, oLbx, oRad, aGrp[2], aSelect, oBtn
   LOCAL aSay[1], aGet[1], aCbx[3], oIni, cTmpFile
   LOCAL aSaveFiles  := {}
   LOCAL nDlgTextCol := RGB( 255, 255, 255 )
   LOCAL nDlgBackCol := RGB( 150, 150, 150 )
   LOCAL lSave       := .F.
   LOCAL lExit       := .F.
   LOCAL nSeite      := 1
   LOCAL nOption     := 1
   LOCAL nFirst      := 1
   LOCAL nLast       := ::nTotalPages
   LOCAL aSeiten     := {}
   LOCAL oPrev       := SELF
   LOCAL hOldRes     := GetResources()
   LOCAL cFileName   := PADR( GetPvProfString( "Save2File", "FileName", "", ::cIni ), 200 )
   LOCAL lOverWrite  := IIF( GetPvProfString( "Save2File", "Overwrite", "1", ::cIni ) = "1", .T., .F. )
   LOCAL lZip        := IIF( GetPvProfString( "Save2File", "ZipFiles", "0", ::cIni ) = "1", .T., .F. )
   LOCAL cFormat     := GetPvProfString( "Save2File", "Format", "BMP - Windows Bitmap", ::cIni )
   LOCAL aFormat     := { "BMP - Windows Bitmap", ;
                          "JPG - jpg, jpeg", ;
                          "EMF - Windows Enhanced Metafile", ;
                          "PCX - Zsoft Publisher's Paintbrush", ;
                          "TIF - TIFF Revision 6", ;
                          "PNG - Portable Network Graphic", ;
                          "WMF - Windows Metafile", ;
                          "RTF - Richtext", ;
                          "DOC - Word" }
   LOCAL nCompress   := 10
   LOCAL aOption     := GetOption( cFormat )
   LOCAL cOption     := IIF( LEN( aOption ) = 0, "", ;
                             GetPvProfString( "Save2File", "Option", aOption[1], ::cIni ) )

   DEFAULT lFromSendTo := .F.
   DEFAULT lDirectSave := .F.

   IF ::lPDF = .T.
      AADD( aFormat, "PDF - Portable Document Format" )
   ENDIF

   IF lDirectSave = .T.

      IF "PDF" $ cFormat .AND. ::lPDF = .F.
         MsgStop( "Saving to PDF is not available." )
      ELSE
         FOR n := nFromPage TO nToPage
            AADD( aSaveFiles, ::aFiles[n] )
         NEXT
         oPrev:Img_Save( aSaveFiles, ALLTRIM( cFileName ), cFormat, nCompress, ;
                         lOverwrite, ASCAN( aOption, cOption ), lZip, lFromSendTo )
         IF lShowSaveMessage = .T.
            oPrev:SaveMessage( cFileName )
         ENDIF
      ENDIF

      RETURN( .T. )

   ENDIF

   IF ::lUseDLL = .T.
      SET RESOURCES TO ::cResFile
   ENDIF

   FOR n := 1 to ::nTotalPages
      AADD( aSeiten, Strtran( EP_GL("&Page"), "&", "" ) + " " + alltrim(str(n)) )
   NEXT

   DEFINE DIALOG oDlg NAME "EP_SAVEPRINT" ;
      TITLE Strtran( IIF( lFromSendTo, EP_GL("Send &to"), EP_GL("&Save as") ) , "&", "" )

   REDEFINE BUTTON PROMPT IIF( lFromSendTo, EP_GL("&Send"), EP_GL("&Save") ) ID 101 OF oDlg ;
      ACTION IIF( EMPTY( cFileName ), MsgStop( EP_GL("Please insert a filename.") ), ;
         ( CheckFileExt( @cFileName, cFormat ), aGet[1]:Refresh(), ;
           lSave := .T., aSelect := oLbx:GetSelItems(), oDlg:End() ) )
   REDEFINE BUTTON PROMPT EP_GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE BUTTON oBtn PROMPT EP_GL("Save and &exit") ID 103 OF oDlg ;
      ACTION IIF( EMPTY( cFileName ), MsgStop( EP_GL("Please insert a filename.") ), ;
         ( lSave := .T., lExit := .T., aSelect := oLbx:GetSelItems(), oDlg:End() ) )

   REDEFINE GET aGet[1] VAR cFileName ID 201 OF oDlg

   REDEFINE BTNBMP RESOURCE "EP_OPEN" ID 110 OF oDlg NOBORDER ;
         ACTION ( cTmpFile := cGetFile( "*." + ALLTRIM(SUBSTR( cFormat, 1, 4 )), ;
                                 Strtran( EP_GL("&Save as") , "&", "" ), 1, ".\", .T. ), ;
                  IIF( EMPTY( cTmpFile ), .T., ;
                  EVAL( {|| cFileName := PADR( cTmpFile, 200 ), aGet[1]:Refresh() } ) ) )

   REDEFINE COMBOBOX cFormat ITEMS aFormat ID 202 OF oDlg ;
      ON CHANGE ( aOption := GetOption( cFormat ), ;
                  CheckFileExt( @cFileName, cFormat ), aGet[1]:Refresh(), ;
                  aCbx[1]:SetItems( aOption ), aCbx[1]:Select( 1 ), ;
                  cOption := IIF( LEN( aOption ) = 0, "", aOption[1] ), ;
                  IIF( LEN( aOption ) <> 0, ;
                       ( aCbx[1]:Show(), aSay[1]:Show() ), ( aCbx[1]:Hide(), aSay[1]:Hide() ) ) )

   REDEFINE CHECKBOX aCbx[2] VAR lOverwrite ID 203 OF oDlg
   REDEFINE CHECKBOX aCbx[3] VAR lZip       ID 205 OF oDlg
   REDEFINE COMBOBOX aCbx[1] VAR cOption ITEMS aOption ID 204 OF oDlg

   REDEFINE RADIO oRad VAR nOption ID 301, 302, 303, 304, 305, 306 OF oDlg ;
      ON CHANGE ( IIF( nOption == 3, ;
                       ( oPageIni:Enable(), oPageFin:Enable() ), ;
                       ( oPageIni:Disable(),oPageFin:Disable() ) ), ;
                  IIF( nOption == 4, oLbx:Enable(), oLbx:Disable() ) )

   REDEFINE GET oPageIni VAR nFirst ID 311 PICTURE "@K 99999" OF oDlg ;
      VALID IIF( nFirst < 1 .OR. nFirst > nLast, ( MessageBeep(), .F. ), .T. ) ;
      SPINNER ON UP   IIF( nFirst >= nLast,, ( ++nFirst, oPageIni:Refresh() ) ) ;
              ON DOWN IIF( nFirst <= 1    ,, ( --nFirst, oPageIni:Refresh() ) )

   REDEFINE GET oPageFin VAR nLast ID 312 PICTURE "@K 99999" OF oDlg ;
      VALID IIF( nLast < nFirst .OR. nLast > ::nTotalPages, (MessageBeep(),.F.), .T. ) ;
      SPINNER ON UP   IIF( nLast >= ::nTotalPages,, ( ++nLast, oPageFin:Refresh() ) ) ;
              ON DOWN IIF( nLast <= nFirst       ,, ( --nLast, oPageFin:Refresh() ) )

   oPageIni:Disable()
   oPageFin:Disable()

   REDEFINE LISTBOX oLbx VAR nSeite ITEMS aSeiten ID 321 OF oDlg
   oLbx:Disable()

   REDEFINE GROUP aGrp[1] ID 191 OF oDlg
   REDEFINE GROUP aGrp[2] ID 192 OF oDlg

   REDEFINE SAY PROMPT EP_GL("Name") + ":" ID 171 OF oDlg
   REDEFINE SAY PROMPT EP_GL("Format") + ":" ID 172 OF oDlg
   REDEFINE SAY aSay[1] PROMPT EP_GL("Option") + ":" ID 173 OF oDlg
   REDEFINE SAY PROMPT EP_GL("to") + ":" ID 174 OF oDlg

   ACTIVATE DIALOG oDlg CENTER ;
      ON INIT ( IIF( lFromSendTo, oBtn:Hide(), ), ;
                aGrp[1]:SetText( EP_GL("File") ), ;
                aGrp[2]:SetText( EP_GL("Pages") ), ;
                aCbx[1]:SetText( EP_GL("Option") ), ;
                aCbx[2]:SetText( EP_GL("overwrite existing files") ), ;
                aCbx[3]:SetText( EP_GL("zip files") ), ;
                oRad:aItems[1]:SetText( EP_GL("All pages") ), ;
                oRad:aItems[2]:SetText( EP_GL("Current page") ), ;
                oRad:aItems[3]:SetText( EP_GL("From page") + ":" ), ;
                oRad:aItems[4]:SetText( EP_GL("Selected pages") + ":" ), ;
                oRad:aItems[5]:SetText( EP_GL("Odd pages") ), ;
                oRad:aItems[6]:SetText( EP_GL("Even pages") ), ;
                IIF( LEN( aOption ) <> 0, ;
                     ( aCbx[1]:Show(), aSay[1]:Show() ), ( aCbx[1]:Hide(), aSay[1]:Hide() ) ) )

   SetResources( hOldRes )

   IF lSave = .T.

      DO CASE
      CASE nOption = 1
         FOR n := 1 TO ::nTotalPages
            AADD( aSaveFiles, ::aFiles[n] )
         NEXT
      CASE nOption = 2
         AADD( aSaveFiles, ::aFiles[::nPage] )
      CASE nOption = 3
         FOR n := nFirst TO nLast
            AADD( aSaveFiles, ::aFiles[n] )
         NEXT
      CASE nOption = 4
         FOR n := 1 TO LEN( aSelect )
            AADD( aSaveFiles, ::aFiles[ aSelect[n] ] )
         NEXT
      CASE nOption = 5 .OR. nOption = 6
         FOR n := 1 TO ::nTotalPages
            IF nOption = 5 .AND. ::IsEven( n ) = .F. .OR. ;
               nOption = 6 .AND. ::IsEven( n ) = .T.
               AADD( aSaveFiles, ::aFiles[n] )
            ENDIF
         NEXT
      ENDCASE

      INI oIni FILE ::cIni
         SET SECTION "Save2File" ENTRY "FileName"  TO ALLTRIM( cFileName )         OF oIni
         SET SECTION "Save2File" ENTRY "Format"    TO ALLTRIM( cFormat )           OF oIni
         SET SECTION "Save2File" ENTRY "Overwrite" TO IIF( lOverwrite, "1", "0" )  OF oIni
         SET SECTION "Save2File" ENTRY "ZipFiles"  TO IIF( lZip, "1", "0" )        OF oIni
         SET SECTION "Save2File" ENTRY "Option"    TO ALLTRIM( cOption )           OF oIni
      ENDINI

      #IFDEF __HARBOUR__
         oPrev:Img_Save( aSaveFiles, ALLTRIM( cFileName ), cFormat, nCompress, ;
                         lOverwrite, ASCAN( aOption, cOption ), lZip, lFromSendTo )
      #ELSE
         //Msginfo( ASCAN( aOption, cOption ) )
      #ENDIF

   ENDIF

   IF lExit = .T.
      ::oWnd:End()
   ENDIF

RETURN ( lSave )


*-- METHOD -------------------------------------------------------------------
*         Name: IsEven
*  Description: Checks if a number is even or odd
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD IsEven( nVal ) CLASS EPREVIEW

RETURN IIF( nVal = Round( nVal/2, 0 )*2, .T., .F. )


#IFDEF __HARBOUR__

*-- METHOD -------------------------------------------------------------------
*         Name: Img_Save
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD Img_Save( aSaveFiles, cFileName, cFormat, nCompress, lOverWrite, nOption, ;
                 lZip, lFromSendTo ) CLASS EPREVIEW

   LOCAL i, img_option, oPdf, img_typ, oWord, oSection, oImage
   LOCAL aFileName := {}
   LOCAL nActual   := 0
   LOCAL lOK       := .T.
   LOCAL cCommand  := GetPvProfString( "Save2File", "Command", "", ::cIni )
   LOCAL cCmdFor   := GetPvProfString( "Save2File", "CommandCondition", ".T.", ::cIni )

   ::aFilesSaved := {}

   cFileName := EP_GetFullPath( cFileName )

   // JPEG                   TIFF                      PNG
   // 1 = Quality            1 = Uncompressed          1 = None
   // 2 = Low Quality        2 = LZW Compression       2 = Write compressed
   // 3 = Comp. Factor 30%   3 = Packbits Compression  3 = Write in interlaced mode
   // to 9          to 90%                             4 = Write compressed in interlaced mode

   do case
   case "BMP" $ cFormat
      img_typ := IPT_BMP
   case "JP"  $ cFormat
      img_typ := IPT_JPG
      do case
      case nOption = 1  ; img_option  := IPF_QUALITY
      case nOption = 2  ; img_option  := IPF_LOWQUALITY
      case nOption = 3  ; img_option  := 530
      case nOption = 4  ; img_option  := 540
      case nOption = 5  ; img_option  := 550
      case nOption = 6  ; img_option  := 560
      case nOption = 7  ; img_option  := 570
      case nOption = 8  ; img_option  := 580
      case nOption = 9  ; img_option  := 590
      endcase
   case "EMF" $ cFormat
      img_typ := IPT_EMF
   case "PCX" $ cFormat
      img_typ := IPT_PCX
   case "TIF" $ cFormat
      img_typ := IPT_TIF
      do case
      case nOption = 1
         img_option  := IPF_TIFF_NOCOMP
      case nOption = 2
         img_option  := IPF_TIFF_LZW
      case nOption = 3
         img_option  := IPF_TIFF_PACKBITS
      endcase
   case "PNG" $ cFormat
      img_typ    := IPT_PNG
      do case
      case nOption = 2
         img_option := IPF_COMPRESS
      case nOption = 3
         img_option := IPF_INTERLACED
      case nOption = 4
         img_option := IPF_COMPRESS + IPF_INTERLACED
      endcase
   case "WMF" $ cFormat
      img_typ := IPT_WMF
    case  "PDF"  $ cFormat
      img_typ := 500
      IF FILE( cFileName ) .and. lOverwrite = .F.
         MsgStop( EP_GL( "This file already exists:" ) + CRLF + CRLF + ;
                  ALLTRIM( cFileName ), EP_GL("Stop") )
         return NIL
      ENDIF
   case "RTF" $ cFormat
      //CheckFileExt( @cFileName, "BMP" )
      //img_typ := IPT_BMP
      CheckFileExt( @cFileName, "JPG" )
      img_typ    := IPT_JPG
      img_option := 1
   case "DOC" $ cFormat
      CheckFileExt( @cFileName, IIF( nOption = 1, "WMF", "JPG" ) )
      img_typ := IIF( nOption = 1, IPT_WMF, IPT_JPG )
   endcase

   if img_typ = 500
     // comentado para quitar errores
    //  oPDF := TPDF():NEW( ::cIni, cFilename, ::oDevice, ::cPDFLicName, ::cPDFLicCode, ::nPDFLicNr )
    //  IF !oPDF:PDFInit()
    //     RETURN NIL
    //  ENDIF
    //  oPDF:RegCallBackMsg( .T. )
    //  oPDF:StartDoc()
   endif

   lOK := ::SaveProcess( cFileName, aSaveFiles, @aFileName, img_typ, img_option, oPDF, lOverWrite )

   IF img_typ = 500
     // comentado para quitar errores
   //   ::aFilesSaved := { ALLTRIM( cFilename ) }
   //   aFileName     := { ALLTRIM( cFilename ) }
   //   oPDF:EndDoc()
   //   oPDF:END()
   ENDIF

   IF lFromSendTo = .T.
      ::CheckEMail( @lZip, cFormat, LEN( aSaveFiles ) )
   ENDIF

   // Mit NConvert nachbearbeiten
   IF .NOT. EMPTY( cCommand ) .AND. EVAL( &( "{|cFormat|" + cCmdFor + "}" ), cFormat ) = .T.
      FOR i := 1 TO LEN( aFileName )
         WaitRun( STRTRAN( cCommand, "&&1", aFileName[i] ), 0 )
      NEXT
   ENDIF

   IF "RTF" $ cFormat

      CursorWait()

      ::oSaveAsRTF:SelectAll()
      ::oSaveAsRTF:Del()

      FOR i := 1 TO LEN( aFileName )
         //::oSaveAsRTF:InsertBitmap( ReadBitmap( 0, aFileName[i] ) )
         //::oSaveAsRTF:InsertBitmap( GetMetaFile( aFileName[i] ) )
         //::oSaveAsRTF:InsertPicture( aFileName[i] )

         oImage := TImage():Define( Nil, aFileName[i] )

         ::oSaveAsRTF:InsertPicture( oImage:hBitmap )

         oImage:End()

         ::oSaveAsRTF:PageBreak()
         FERASE( aFileName[i] )

      NEXT

      CheckFileExt( @cFileName, "RTF" )
      ::oSaveAsRTF:SaveToRTFFile( AllTrim( cFileName ) )

      ::aFilesSaved := { ALLTRIM( cFilename ) }
      aFileName     := { AllTrim( cFileName ) }

      CursorArrow()

   ENDIF

   IF "DOC" $ cFormat

      CursorWait()

      oWord = CreateObject( "Word.Application" )

      oWord:Documents:Add()

      FOR i := 1 TO LEN( aFileName )

         WITH OBJECT oWord:Selection

            :InlineShapes:AddPicture( aFileName[i], .F., .T. )

            IF i <> LEN( aFileName )
               :TypeParagraph()
               :InsertBreak()
            ENDIF

         END WITH

         FERASE( aFileName[i] )

      NEXT

      CheckFileExt( @cFileName, "DOC" )
      oWord:ActiveDocument:SaveAs( AllTrim( cFileName ) )

      IF lFromSendTo = .T.
         oWord:Quit()
      ELSE
         oWord:Visible = .T.
      ENDIF

      ::aFilesSaved := { ALLTRIM( cFilename ) }
      aFileName     := { AllTrim( cFileName ) }

      CursorArrow()

   ENDIF

   IF lZip = .T. .AND. lOK = .T.

      ::Img_Zip( aFileName, cFilename, lOverwrite )

   ENDIF

   IF lZip = .T. .OR. lOK = .F.

      FOR i := 1 TO LEN( aFileName )
         FERASE( aFileName[i] )
      NEXT

   ENDIF

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: SavePreview
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SavePreview( cFileName, aSaveFiles, aFileName, img_typ, img_option, ;
                    oPDF, lOverWrite, aMeter, aVal, aText ) CLASS EPREVIEW

   LOCAL i, cFile, cFileSave, holdMeta, henhmeta, aRect
   LOCAL lOK := .T.

   FOR i := 1 TO LEN( aSaveFiles )

      cFile := aSaveFiles[i]

      if ::nTotalPages == 1
         cFileSave := ALLTRIM( cFilename )
      else
         cFileSave := ALLTRIM(STRTRAN( cFilename, ".", ;
            PADL( ALLTRIM(STR( i, 4 )), 4, "0" ) + "." ))
      endif

      IF FILE( cFilesave ) .and. lOverwrite = .F. .AND. img_typ <> 500

         MsgStop( EP_GL( "This file already exists:" ) + CRLF + CRLF + ;
            ALLTRIM( cFileSave ), EP_GL("Stop") )

      ELSE

         AADD( aFileName, cFilesave )

         if ::cMetaFormat = "WMF"
            ::odevice:hDCOut := CreateEnhMetaFile(::odevice:hDC,,0)
            holdMeta         := getmetafile(cfile)
            PlayMetaFile( ::odevice:hDCOut,holdmeta)
         else
            ::odevice:hDCOut := CreateEnhMetaFile(::odevice:hDC,,0) // nötig
            holdMeta         := getenhmetafile(cfile)               // wegen Wasserzeichen
            EP_PlayEnhMetaFile( ::oDevice:hDCOut,hOldMeta,, .T. )
         endif
         textout(::odevice:hDCOut,0,0," ")      // Nullpunkt Seitenrand
         ::Watermark ( ::oDevice:hDCOut )
         DeleteEnhMetafile(hOldMeta)
         henhmeta := CloseEnhMetaFile(::odevice:hDCOut )

         aText[1]:SetText( EP_GL("Saving page") + " " + ;
            ALLTRIM(STR( i, 10 )) + " / " + ALLTRIM(STR( LEN( aSaveFiles ), 10 )) )

         IF img_typ = 500

            aMeter[1]:Set( 0 )
            aMeter[1]:Set( 25 )
            aMeter[1]:Set( 50 )
            oPDF:DrawMetaFile( hEnhMeta )
            aMeter[1]:Set( 75 )
            aMeter[1]:Set( 100 )

         ELSE
           // comentado para quitar errores
          //  ImagSaveAs( ::oWnd:hwnd, henhmeta, cFileSave, img_typ, img_option )
          //  AADD( ::aFilesSaved, ALLTRIM( cFileSave ) )

         ENDIF

         aMeter[2]:Set( i )

         DeleteEnhMetafile(henhmeta)

      ENDIF

   NEXT

RETURN ( aFileName )


*-- METHOD -------------------------------------------------------------------
*         Name: Copy2Clipboard
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD Copy2Clipboard() CLASS EPREVIEW

   LOCAL holdMeta, henhmeta
   LOCAL cFile := ::aFiles[::nPage]

   if ::cMetaFormat = "WMF"
      ::odevice:hDCOut := CreateEnhMetaFile(::odevice:hDC,,0)
      holdMeta         := getmetafile(cfile)
      PlayMetaFile( ::odevice:hDCOut,holdmeta )
   else
      ::odevice:hDCOut := CreateEnhMetaFile(::odevice:hDC,,0) // nötig
      holdMeta         := getenhmetafile(cfile)               // wegen Wasserzeichen
      EP_PlayEnhMetaFile( ::oDevice:hDCOut,hOldMeta,, .T. )
   endif

   textout(::odevice:hDCOut,0,0," ")         // Nullpunkt Seitenrand
   ::Watermark( ::oDevice:hDCOut )
   DeleteEnhMetafile( hOldMeta )
   henhmeta := CloseEnhMetaFile(::odevice:hDCOut )
  // comentado para quitar errores
 //  CopyClip( ::oWnd:hwnd, henhmeta )

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: SaveProcess
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SaveProcess( cFileName, aSaveFiles, aFileName, img_typ, img_option, ;
                    oPDF, lOverWrite ) CLASS EPREVIEW

   LOCAL i, oDlg, aMeter[2], aText[2], oBtn, oFont
   LOCAL lEnd    := .F.
   LOCAL lCancel := .F.
   LOCAL aVal    := { 0, 0 }

   DEFINE FONT oFont NAME "Ms Sans Serif" SIZE 0, -8

   DEFINE DIALOG oDlg FROM 5, 5 TO 13.7, 45 TITLE EP_GL("Please wait") FONT oFont

   @ 0.1, 0.5 SAY aText[1] VAR EP_GL("Saving page") SIZE 130, 9 OF oDlg

   @ 0.9, 0.5 METER aMeter[1] VAR aVal[1] TOTAL 100 SIZE 150, 10 OF oDlg

   @ 1.7, 0.5 SAY aText[2] VAR EP_GL("Total:") SIZE 130, 9 OF oDlg

   @ 2.5, 0.5 METER aMeter[2] VAR aVal[2] TOTAL LEN( aSaveFiles ) SIZE 150, 10 OF oDlg

   @ 2.9, 18.0 BUTTON oBtn PROMPT EP_GL("&Cancel") OF oDlg ;
      ACTION ( lEnd := .T., lCancel := .T. ) SIZE 46, 10

  // comentado para quitar errores
 //  oDlg:bStart = { ||  ImgCallbackMsg( {|nr| aMeter[1]:Set( nr ) } ), ;
 //     aFileName := ::SavePreview( cFileName, aSaveFiles, aFileName, img_typ, ;
  //                                img_option, oPDF, lOverWrite, aMeter, aVal, aText ), ;
  //    lEnd := .T., oDlg:End() }

   ACTIVATE DIALOG oDlg CENTERED VALID lEnd

   IF lCancel = .T.
      FOR i := 1 TO LEN( aFileName )
         FERASE( aFileName[i] )
      NEXT
   ENDIF

   oFont:End()

RETURN ( !lCancel )

//------------------------------------------------------------------------------

METHOD Img_Zip( aFiles, cFilename, lOverwrite ) CLASS EPREVIEW

   LOCAL i, lOK
   LOCAL nFactor := 5

   cFileName     := STRTRAN( UPPER( cFilename ), cFileExt( cFilename ), "ZIP" )
   ::aFilesSaved := { ALLTRIM( cFileName ) }

   IF FILE( cFileName ) .AND. lOverwrite = .F.

      MsgStop( EP_GL( "This file already exists:" ) + CRLF + CRLF + ;
               ALLTRIM( cFileName ), EP_GL("Stop") )

   ELSEIF LEN( aFiles ) > 0

      FERASE( cFilename )
     // lOK := Hb_ZipFile( cFilename, aFiles )  // comentado para quitar errores
       IF !lOk
          MsgStop( EP_GL( "Error Zipping" ) )
       ENDIF

    ENDIF

RETURN NIL

#ENDIF

//------------------------------------------------------------------------------

METHOD SaveMessage( cFileName ) CLASS EPREVIEW

   LOCAL oDlg, oFont

   DEFINE FONT oFont NAME "Arial" SIZE 0, -14

   DEFINE DIALOG oDlg FROM 0, 0 TO 99, 360 PIXEL TITLE EP_GL("Information")

   @ 6, 5 SAY EP_GL( "The printout was saved to the following file:" ) ;
      OF oDlg SIZE 156, 8 PIXEL

   @ 16, 4 SAY ALLTRIM( cFileName ) OF oDlg SIZE 173, 13 PIXEL CENTER FONT oFont

//   @ 26, 5 TO 29, 176 OF oDlg PIXEL   // comentada para quitar errores

   @ 38, 5 SAY ::RegInfos() OF oDlg SIZE 129, 10 PIXEL

   //@ 34, 136 BUTTON EP_GL("&OK") OF oDlg SIZE 40, 11 PIXEL ACTION oDlg:End()

   ACTIVATE DIALOG oDlg CENTER NOWAIT

   SYSWAIT(2)

   oDlg:End()
   oFont:End()

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: GetFactors
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GetFactors( cFile ) CLASS EPREVIEW

   LOCAL aFactors := { ALLTRIM(STR(::aZoomFactor[1]*100,4)), ;
                       ALLTRIM(STR(::aZoomFactor[2]*100,4)), ;
                       ALLTRIM(STR(::aZoomFactor[3]*100,4)), ;
                       ALLTRIM(STR(::aZoomFactor[4]*100,4)), ;
                       ALLTRIM(STR(::aZoomFactor[5]*100,4)), ;
                       ALLTRIM(STR(::aZoomFactor[6]*100,4)), ;
                       ALLTRIM(STR(::aZoomFactor[7]*100,4)), ;
                       ALLTRIM(STR(::aZoomFactor[8]*100,4)), ;
                       ALLTRIM(STR(::aZoomFactor[9]*100,4)) }
   LOCAL cPercent := EP_GL("%")

   AEVAL( aFactors, {| x, i| aFactors[i] += " " + cPercent } )

RETURN ( aFactors )


*-- METHOD -------------------------------------------------------------------
*         Name: GetFactors
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD Watermark( hDC ) CLASS EPREVIEW

   LOCAL i, cMark

   IF ::lDemo = .T. .OR. ::lExtDemoMode = .T.

      cMark := REPLICATE( IIF( ::lDemo, "EasyPreview Test Version - ", ;
                                        ::cDemoMessage + " - " ), 8 )

      FOR i := 1 to 8
         TextOut( hDC, 400 * i, 10, PADR( cMark, 160 ) )
      NEXT

   ENDIF

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: GetFactors
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GetColor( cColor, nDefColor ) CLASS EPREVIEW

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


*-- METHOD -------------------------------------------------------------------
*         Name: TempFile
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD TempFile() CLASS EPREVIEW

   LOCAL cFileName
   LOCAL cTime := ALLTRIM( StrTran( Time(), ":", "" ) )

   WHILE File( ::cTmpPath + "\" + ( cFileName := SUBSTR( cTime, 4 ) ) )
   END

RETURN cFileName


*-- METHOD -------------------------------------------------------------------
*         Name: GetLanguages
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GetLanguages( cPrevIni ) CLASS EPREVIEW

   LOCAL nOldSelect    := Select()
   LOCAL lCloseLangDBF := .T.

   IF nLanguage > 1

      IF SELECT( "EPREVIEW" ) = 0
         SELECT 0
         USE ( GetPvProfString( "General", "LanguageFile", "EPREVIEW.DBF", cPrevIni ) ) ;
            SHARED ALIAS "EPREVIEW"
         //USE EPREVIEW.DBF SHARED
      ELSE
         SELECT EPREVIEW
         lCloseLangDBF := .F.
      ENDIF

      EPREVIEW->(DBGOTOP())
      aLanguages := {}

      DO WHILE .NOT. EPREVIEW->(EOF())
         AADD( aLanguages, { EPREVIEW->LANGUAGE1, EPREVIEW->(FIELDGET( nLanguage )) } )
         EPREVIEW->(DBSKIP())
      ENDDO

      IF lCloseLangDBF = .T.
         EPREVIEW->(DBCLOSEAREA())
      ENDIF

      SELECT( nOldSelect )

   ENDIF

RETURN NIL


*-- METHOD -------------------------------------------------------------------
*         Name: GetWinCoords
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GetWinCoords() CLASS EPREVIEW

   LOCAL i
   LOCAL aPos    := {}
   LOCAL cWinPos := GetPvProfString( "General", "WindowCoordinates", "", ::cIni )

   IF .NOT. EMPTY( cWinPos ) .AND. ::lSaveWindowPos = .T.
      FOR i := 1 to 4
         AADD( aPos, VAL(STRTOKEN( cWinPos, i, "," )) )
      NEXT
   ELSE
      IF ::lLandscape = .T.
         aPos := { 0, 0, GetSysMetrics(1) * 0.8, GetSysMetrics(0) * 0.8 }
      ELSE
         aPos := { 0, 0, GetSysMetrics(1) * 0.8, GetSysMetrics(0) * 0.6 }
      ENDIF
   ENDIF

RETURN ( aPos )


*-- METHOD -------------------------------------------------------------------
*         Name: SetWinCoords
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SetWinCoords() CLASS EPREVIEW

   LOCAL aRect   := GetCoors( ::oWnd:hWnd )
   LOCAL cWinPos := LTRIM(STR( aRect[1] )) + "," + LTRIM(STR( aRect[2] )) + "," + ;
                    LTRIM(STR( aRect[3] )) + "," + LTRIM(STR( aRect[4] ))

   WritePProString( "General", "WindowCoordinates", cWinPos, ::cIni )

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_GL
* Beschreibung: Get Language
* Argumente...: English string
* Rückgabewert: translated string
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_GL( cOriginal )

   LOCAL nOldSelect, nPos
   LOCAL cText       := cOriginal
   LOCAL cSearchText := STRTRAN( ALLTRIM( cText ), " ", "_" )

   //fill the language file
   IF nLanguage = 0

      nOldSelect := Select()
      SELECT 0
      USE EPREVIEW.DBF SHARED

      GO TOP
      LOCATE FOR ALLTRIM( EPREVIEW->LANGUAGE1 ) == ALLTRIM( cSearchText )

      IF EPREVIEW->(EOF())
         FLOCK()
         APPEND BLANK
         REPLACE EPREVIEW->LANGUAGE1 WITH cSearchText
         UNLOCK
      ENDIF

      EPREVIEW->(DBCLOSEAREA())
      SELECT( nOldSelect )

   ENDIF

   IF nLanguage > 1
      nPos  := ASCAN( aLanguages, { |aVal| ALLTRIM( aVal[1] ) == ALLTRIM( cSearchText ) } )
      cText := IIF( nPos <> 0, STRTRAN( ALLTRIM( aLanguages[nPos,2] ), "_", " " ), ;
                               cOriginal )
   ENDIF

RETURN ( cText )


*-- FUNCTION -----------------------------------------------------------------
* Name........: HasOption
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
STATIC FUNCTION GetOption( cFormat )

   LOCAL i
   LOCAL aOption := {}

   IF SUBSTR( ALLTRIM( cFormat ), 1, 4 ) = "JPG"
      AADD( aOption, EP_GL("Quality") )
      AADD( aOption, EP_GL("Low Quality") )
      FOR i := 30 TO 90 STEP 10
         AADD( aOption, EP_GL("Compression Factor") + " " + ALLTRIM( STR( i, 4)) + "%" )
      NEXT
   ELSEIF SUBSTR( ALLTRIM( cFormat ), 1, 4 ) = "TIF"
      AADD( aOption, EP_GL("Uncompressed") )
      AADD( aOption, EP_GL("LZW Compression") )
      AADD( aOption, EP_GL("Packbits Compression") )
   ELSEIF SUBSTR( ALLTRIM( cFormat ), 1, 3 ) = "PNG"
      AADD( aOption, EP_GL("None") )
      AADD( aOption, EP_GL("Write compressed") )
      AADD( aOption, EP_GL("Write in interlaced mode") )
      AADD( aOption, EP_GL("Write compressed in interlaced mode") )
   ELSEIF SUBSTR( ALLTRIM( cFormat ), 1, 3 ) = "DOC"
      AADD( aOption, EP_GL("changeable (WMF based)") )
      AADD( aOption, EP_GL("read only (JPG based)") )
   ENDIF

RETURN ( aOption )


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_SMTPInfo
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: José Lalín / Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_SMTPInfo()

   LOCAL oReg
   LOCAL cAccount := ""
   LOCAL aData    := { "", "" }
   LOCAL nHKEY_CURRENT_USER := 2147483649

   oReg := TReg32():New( nHKEY_CURRENT_USER, "Software\Microsoft\Internet Account Manager" )

   cAccount := oReg:Get( "Default Mail Account" )

   oReg:Close()

   IF !Empty( cAccount )

      oReg := TReg32():New( nHKEY_CURRENT_USER, ;
         "Software\Microsoft\Internet Account Manager\Accounts\" + cAccount )

      aData := {  oReg:Get( "SMTP Server" ), ;
                  oReg:Get( "SMTP Email Address" ) }

      oReg:Close()

   ENDIF

RETURN ( aData )

*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_GetFullPath
* Beschreibung: Returns a complete, LONG pathname and LONG filename.
* Argumente...: None
* Rückgabewert: .T.
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
Function EP_GetFullPath( cSpec )

   LOCAL cLongName := Space(261)
   LOCAL nNamePos  := 0

   FullPathName( cSpec, Len( cLongName ), @cLongName, @nNamePos )

RETURN ALLTRIM( cLongName )

DLL32 Function FullPathName( lpszFile AS LPSTR, cchPath AS DWORD,;
               lpszPath AS LPSTR, @nFilePos AS PTR ) AS DWORD ;
               PASCAL FROM "GetFullPathNameA" LIB "kernel32.dll"

*-- FUNCTION -----------------------------------------------------------------
*         Name: CheckFileExt
*  Description:
*       Author: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CheckFileExt( cCurFileName, cFormat )

   LOCAL cPath, cFileName, cExtension
   LOCAL cExtention := ""

   HB_FNameSplit( AllTrim( cCurFileName ), @cPath, @cFileName, @cExtension )

   DO CASE
   CASE  "BMP"  $ cFormat .AND. Upper( cExtension ) <> ".BMP"  ; cExtention := ".bmp"
   CASE  "JPG"  $ cFormat .AND. Upper( cExtension ) <> ".JPG"  ; cExtention := ".jpg"
   CASE  "JPEG" $ cFormat .AND. Upper( cExtension ) <> ".JPEG" ; cExtention := ".jpeg"
   CASE  "EMF"  $ cFormat .AND. Upper( cExtension ) <> ".EMF"  ; cExtention := ".emf"
   CASE  "PCX"  $ cFormat .AND. Upper( cExtension ) <> ".PCX"  ; cExtention := ".pcx"
   CASE  "TIF"  $ cFormat .AND. Upper( cExtension ) <> ".TIF"  ; cExtention := ".tif"
   CASE  "PNG"  $ cFormat .AND. Upper( cExtension ) <> ".PNG"  ; cExtention := ".png"
   CASE  "WMF"  $ cFormat .AND. Upper( cExtension ) <> ".WMF"  ; cExtention := ".wmf"
   CASE  "PDF"  $ cFormat .AND. Upper( cExtension ) <> ".PDF"  ; cExtention := ".pdf"
   CASE  "RTF"  $ cFormat .AND. Upper( cExtension ) <> ".RTF"  ; cExtention := ".rtf"
   CASE  "DOC"  $ cFormat .AND. Upper( cExtension ) <> ".DOC"  ; cExtention := ".doc"
   ENDCASE

   IF .NOT. Empty( cExtention )
       cCurFileName := cPath + cFileName + cExtention
   ENDIF

RETURN .T.

// Hilfe unterdrücken
FUNCTION HELPINDEX()
RETURN ( NIL )
FUNCTION HELPTOPIC()
RETURN ( NIL )
FUNCTION HELPPOPUP()
RETURN ( NIL )