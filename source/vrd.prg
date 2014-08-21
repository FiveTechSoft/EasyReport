/*
    ==================================================================
    EasyReport - The Visual Report Designer                    VRD.PRG
                                                         Version 2.1.1
    ------------------------------------------------------------------
                           (c) copyright: Timm Sodtalbers, 2000 - 2004
                                                    Sodtalbers+Partner
                                              info@reportdesigner.info
                                               www.reportdesigner.info
    ==================================================================
*/

#IFDEF __XPP__
   #INCLUDE "VRDXPP.ch"
   #INCLUDE "VRD.ch"
#ELSE
   #INCLUDE "FiveWin.ch"
   #INCLUDE "Struct.ch"
   #INCLUDE "VRD.ch"
   REQUEST DBFNTX
   //REQUEST DBFCDX
#ENDIF

#DEFINE AREASOURCE_TOP1            1
#DEFINE AREASOURCE_TOP2            2
#DEFINE AREASOURCE_TOPVARIABLE     3
#DEFINE AREASOURCE_WIDTH           4
#DEFINE AREASOURCE_HEIGHT          5
#DEFINE AREASOURCE_CONDITION       6
#DEFINE AREASOURCE_CONTROLDBF      7
#DEFINE AREASOURCE_DELETESPACE     8
#DEFINE AREASOURCE_BREAKBEFORE     9
#DEFINE AREASOURCE_BREAKAFTER     10
#DEFINE AREASOURCE_PRBEFOREBREAK  11
#DEFINE AREASOURCE_PRAFTERBREAK   12

STATIC nLanguage := 1
STATIC aLanguages := ;
   { { "Preview"       , "Vorschau"       , "Anteprima"         , "Previsualizar"      , "Ver antes"           , "Visualizar"          , "Prévisualiser"      }, ;
     { "Print"         , "Drucken"        , "Stampa"            , "Imprimir"           , "Imprimir"            , "Imprimir"            , "Imprimer"           }, ;
     { "Please wait...", "Bitte warten...", "Prego attendere...", "Por favor espere...", "Por favor aguarde...", "Por_favor_aguarde...", "Veuillez patienter" }, ;
     { "&Cancel"       , "&Abbrechen"     , "&Annulla"          , "&Cancelar"          , "&Cancelar"           , "&Cancelar"           , "&Annuler"           }, ;
     { "to Printer"    , "an Ducker"      , "alla Stampante"    , "a Impresora"        , "para a impressora"   , "para a impressora"   , "Vers Imprimante"    }, ;
     { "Copies"        , "Kopien"         , "Copie"             , "Copias"             , "Nº de cópias"        , "Nro de cópias"       , "Copies"             }, ;
     { "Preparing Print", "Der Ausdruck wird vorbereitet.", "Stampa in fase di costruzione.", "Preparando Impresión", "Preparando impressÆo", "Preparando impressão", "Impression en préparation" }, ;
     { "Preparing Page:", "Erstelle Seite:"               , "Pagina in fase di costruzione:", "Preparando página:"  , "Preparando pagina:"  , "Preparando página"   , "Page en Préparation"       } ;
   }

STATIC hTmpWnd, oTmpWnd, Cargo

MEMVAR cRec

*-- CLASS DEFINITION ---------------------------------------------------------
*         Name: VRD
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
CLASS VRD

   DATA cTitle          // Report title
   DATA cDefIni         // Main ini file
   DATA cRDD            // name of the replacable database driver
   DATA cReportName, cDefaultPath, cAreaFilesDir, cInfoSay, cInfoSay2, cPrinter
   DATA cDefIniPath
   DATA cDataPath

   DATA nTopMargin      // Top paper margin
   DATA nLeftMargin     // Left paper margin
   DATA nPageBreak      // Page break position
   DATA nOrientation    // 1 = Portrait, 2 = Landscape
   DATA nMeasure, nLastPrintedRow, nLastRow, nNextRow, nLastArea, nLastIniArea
   DATA nOldSelect, nPaperSize, nPaperWidth, nPaperHeight
   DATA nCurArea   INIT 1
   DATA nDBFRecord

   DATA lShowInfo                 // Show the info messagebox on/off
   DATA lFirstAreaOnPage INIT .T.
   DATA lPrintIDs, lNoExpr, lAreaStartUsed, lBreak, lPreview, nResize, nCopies
   DATA lDialogCancel, lCheck, loPrnExist, lDelQuotations, lAutoPageBreak
   DATA lUnix2Windows

   DATA aAreaInis       // All area ini files
   DATA aFonts          // All fonts with properties
   DATA aColors         // All colors
   DATA aAreaTop        // All area top positions
   DATA aAreaHeight     // All area height
   DATA aItemsPrinted   // stores all already printed items of the current area
   DATA aErrors         // stores errors
   DATA aLastItems, aDelEmptySpace, aBreakBefore, aBreakAfter, aAlias
   DATA aAreaSource, aPrBeforeBreak, aPrAfterBreak
   DATA aDBAlias, aDBContent, aDBType, aDBRecords, aControlDBF, aDBPrevRecord
   DATA aDBFilter, aDBFieldNames, aDBFieldPos

   DATA oPrn, oTmpWnd, oInfoDlg, oInfoSay, oInfo

   DATA bTransExpr
   DATA Cargo, Cargo2, Cargo3, Cargo4, Cargo5

   METHOD New( cReportName, lPreview, cPrinter, oWnd, lModal, lPrintIDs, lNoPrint, ;
               lNoExpr, cFilePath, lPrintDialog, nCopies, lCheck, oPrint, aSize, ;
               cTitle, cPreviewDir, lAutoBreak, lShowInfo ) CONSTRUCTOR
   METHOD End( lPrintArea )
   METHOD SetPaperSize( aSize )
   METHOD AreaTitle( nArea )
   METHOD AreaWidth( nArea )
   METHOD AreaHeight( nArea )
   METHOD DefineFonts()
   METHOD GetItem( nAera, nItemID )
   METHOD AreaStart( nArea, lPrintArea, aIDs, aStrings, lPageBreak )
   METHOD AreaStart2( nArea, lPrintArea, aIDs, aStrings, lPageBreak )
   METHOD PrintItem( nAera, nItemID, cTextORImage, nAddtoTop, lMemo, nEntry )
   METHOD PrintUserFields( nArea, nAddtoTop )
   METHOD PrintArea( nArea, nAddtoTop, lPageBreak )
   METHOD PrintRest( nArea, nAddtoTop, lPageBreak )
   METHOD PrintItemList( nArea, aIDs, aStrings, nAddToTop )
   METHOD PrMultiAreas( aAreas, lPrintArea )
   METHOD DrawBox( nTop, nLeft, nBottom, nRight )
   METHOD Say( nRow, nCol, cText, oFont, nWidth, nClrText, nBkMode, nPad )
   METHOD SayMemo( nTop, nLeft, nWidth, nHeight, cValue, oFont, nColor, nPad )
   METHOD GetEntryNr( nArea, nItemID )
   METHOD ToPix( nValue, lHeight )
   METHOD ToMmInch( nValue, lHeight )
   METHOD SetExpression( cName, cExpression, cInfo )
   METHOD GetExpression( cName )
   METHOD DelExpression( cName )
   METHOD EvalAreaSource( xValue, cSource )
   METHOD EvalSourceCode( cSource )
   METHOD EvalExpression( cText )
   METHOD PageBreak( lPrintArea )
   METHOD MsgError()
   METHOD CountItems( nArea, lUser )
   METHOD GetAllItemIDs( nArea )
   METHOD GetIniItems( nArea )
   METHOD GetTextWidth( cText, oFont )
   METHOD PrintDialog()
   METHOD CheckPath( cPath )

   //For memo justification
   METHOD SayMemoJust( nTop, nLeft, nWidth, nHeight, cText, oFont, nColor, nOrient )
   METHOD MemoText( cText, nLength, oFont )
   METHOD MemoTextPLeft( cText, nPixels, oFont )
   METHOD MemoTextSpaces( cText )

   //for databases
   METHOD OpenDatabases()
   METHOD GetDBContent( cDatabase, cDBAlias, cDBType, cSeparator, nIndex )
   METHOD CloseDatabases()
   METHOD EvalDBFields( cSource )
   METHOD EvalFormula( oItem )
   METHOD DelQuotations( cOriginal )

   METHOD DBSum( cDatabase, cField, nLen, nDec, cFor, lPrevious, lCount )
   METHOD DBCount( cDatabase, cFor )
   METHOD DBValue( cField, cDatabase )
   METHOD DBPrevValue( cField, cDatabase )
   METHOD SetPrevRecord( cDatabase )
   METHOD StrUnix2Win( cString )
   METHOD GetText( cTextFile, nRow, nCol, nColLast, nRowLast )

ENDCLASS


*-- METHOD -------------------------------------------------------------------
*         Name: New
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD New( cReportName, lPreview, cPrinter, oWnd, lModal, lPrintIDs, lNoPrint, ;
            lNoExpr, cAreaPath, lPrintDialog, nCopies, lCheck, oPrint, aSize, ;
            cTitle, cPreviewDir, lAutoBreak, lShowInfo ) CLASS VRD

   LOCAL i, y, cDef, oInfoFont, oInfo2Font, cFile, aIniEntries, cDlgTitle
   LOCAL aSay[3], aPrompt[3], aTmpSource, lTmpValue, nTmpValue, cTmpValue
   LOCAL nValue := 0

   DEFAULT lPreview     := .F.
   DEFAULT cPrinter     := ""
   DEFAULT lModal       := .F.
   DEFAULT lPrintIDs    := .F.
   DEFAULT lNoPrint     := .F.
   DEFAULT lNoExpr      := .F.
   DEFAULT cAreaPath    := ""
   DEFAULT nCopies      := 1
   DEFAULT lCheck       := .F.
   DEFAULT lPrintDialog := .F.
   DEFAULT cPreviewDir  := ""
   DEFAULT lAutoBreak   := .F.

   ::lPreview         := lPreview
   ::cPrinter         := cPrinter
   ::aFonts           := ARRAY( 20, 10 )
   ::aItemsPrinted    := {}
   ::aErrors          := {}
   ::lPrintIDs        := lPrintIDs
   ::nLastPrintedRow  := 0
   ::nLastRow         := 0
   ::nNextRow         := 0
   ::nLastArea        := 0
   ::lNoExpr          := lNoExpr
   ::nLastIniArea     := 0
   ::aLastItems       := {}
   ::aDelEmptySpace   := {}
   ::aBreakBefore     := {}
   ::aBreakAfter      := {}
   ::aPrBeforeBreak   := {}
   ::aPrAfterBreak    := {}
   ::lAreaStartUsed   := .F.
   ::lBreak           := .F.
   ::cDefaultPath     := ::CheckPath( GetPvProfString( "General", "DefaultPath", "", ".\VRD.INI" ) )
   ::cDataPath        :=  GetCurDir()+"\Datas\"
   ::lDialogCancel    := .F.
   ::nCopies          := nCopies
   ::Cargo            := ""
   ::lCheck           := lCheck
   ::loPrnExist       := IIF( oPrint = NIL, .F., .T. )
   ::cTitle           := cTitle
   ::aAlias           := {}
   ::nOldSelect       := SELECT()
   ::aAreaSource      := {}
   ::aControlDBF      := {}
   ::lAutoPageBreak   := lAutoBreak
   ::nDBFRecord       := 0
   ::aDBAlias         := {}
   ::aDBContent       := {}
   ::aDBType          := {}
   ::aDBRecords       := {}
   ::aDBPrevRecord    := {}

   ::cReportName = cReportName
   ::oTmpWnd     = oWnd
   ::cDefIni     = VRD_LF2SF( ALLTRIM( cReportName ) )

   ::oInfo := VRD_NewStructure()
   ::oInfo:AddMember( "nPages",, 0 )

   nLanguage  := VAL( GetPvProfString( "General", "Language", "1", ".\VRD.INI" ) )
   cDlgTitle  := IIF( ::lPreview, VRD_GL("Preview"), VRD_GL("Print") )

   IF ::loPrnExist = .T.
      ::oPrn := oPrint
   ENDIF

   //No printout. Useful if you want to get for example the total pages.
   IF ::lCheck = .T.
      ::lPreview := .T.
   ENDIF

   #IFDEF __XPP__
      hTmpWnd := ::oTmpWnd:getHWND()
      //Otherwise pictures can not be printed under Xbase++
      ::oTmpWnd := NIL
      DEFINE WINDOW oTmpWnd
      SetWndApp( oTmpWnd:hWnd )
      SetForegroundWindow( oTmpWnd:hWnd )
      EnableWindow( hTmpWnd, 0 )
      oTmpWnd:Hide()
   #ENDIF

   IF lPrintDialog = .T.
      IF ::PrintDialog() = .F.
         ::lDialogCancel := .T.
         ::CloseDatabases()
         RETURN( Self )
      ENDIF
   ENDIF

   IF FILE( ::cDefIni ) = .F.
      AADD( ::aErrors, "1" + CHR(9) + "General ini file not found: " + ALLTRIM( cReportName ) )
      ::MsgError( .T. )
   ENDIF

   aIniEntries := GetIniSection( "General", ::cDefIni, .F. )

   DEFAULT ::cTitle := ALLTRIM( GetIniEntry( aIniEntries, "Title", "" ) )

   ::nTopMargin   := VAL( GetIniEntry( aIniEntries, "TopMargin"  , "20"  ) )
   ::nLeftMargin  := VAL( GetIniEntry( aIniEntries, "LeftMargin" , "20"  ) )
   ::nPageBreak   := VAL( GetIniEntry( aIniEntries, "PageBreak"  , "240" ) )
   ::nMeasure     := VAL( GetIniEntry( aIniEntries, "Measure"    , "1"   ) )
   ::nOrientation := VAL( GetIniEntry( aIniEntries, "Orientation", "1"   ) )
   ::nPaperSize   := VAL( GetIniEntry( aIniEntries, "PaperSize"  , "9"   ) )
   ::nPaperWidth  := VAL( GetIniEntry( aIniEntries, "PaperWidth" , "0"   ) )
   ::nPaperHeight := VAL( GetIniEntry( aIniEntries, "PaperHeight", "0"   ) )
   ::lShowInfo    := ( GetIniEntry( aIniEntries, "ShowInfoMsg", "1" ) = "1" )
   ::cRDD         := GetIniEntry( aIniEntries, "RDD", "COMIX" )

   IF lShowInfo <> NIL
      ::lShowInfo := lShowInfo
   ENDIF

   IF .NOT. EMPTY( cAreaPath )
      ::cAreaFilesDir := ALLTRIM( cAreaPath )
   ELSE
      ::cAreaFilesDir := ALLTRIM( GetIniEntry( aIniEntries, "AreaFilesDir", "" ) )
   ENDIF

   IF EMPTY( ::cAreaFilesDir )
      ::cAreaFilesDir := ::cDefaultPath
   ENDIF
   IF EMPTY( ::cAreaFilesDir )
      ::cAreaFilesDir := cFilePath( ::cDefIni )
   ENDIF

   ::cAreaFilesDir := ::CheckPath( ::cAreaFilesDir )

   IF ::lShowInfo = .T. .AND. lNoPrint = .F. .AND. ::loPrnExist = .F.

      aPrompt[1]     := REPLICATE("_", 100 )
      aPrompt[2]     := ALLTRIM( ::cTitle )
      aPrompt[3]     := VRD_GL( "Please wait..." )
      ::cInfoSay  := VRD_GL( "Preparing Print" )
      ::cInfoSay2 := VRD_GL( "Preparing Page:" )

      DEFINE FONT oInfoFont  NAME "MS SANS SERIF" SIZE 0,-14 BOLD
      DEFINE FONT oInfo2Font NAME "MS SANS SERIF" SIZE 0,-8

      #IFDEF __XPP__
         DEFINE DIALOG ::oInfoDlg FROM 0,0 TO 104, 300 PIXEL TITLE cDlgTitle ;
            STYLE nOr( DS_MODALFRAME, WS_POPUP )
      #ELSE
         DEFINE DIALOG ::oInfoDlg FROM 0,0 TO 86, 300 PIXEL ;
            STYLE nOr( DS_MODALFRAME, WS_POPUP )
      #ENDIF

      @ 10, 0 SAY aSay[1] PROMPT aPrompt[1] OF ::oInfoDlg SIZE 300, 20 PIXEL //FONT oInfo2Font
      @  4, 8 SAY aSay[2] PROMPT aPrompt[2] OF ::oInfoDlg SIZE 300, 10 PIXEL //FONT oInfoFont
      @ 21, 8 SAY aSay[3] PROMPT aPrompt[3] OF ::oInfoDlg SIZE 300, 20 PIXEL //FONT oInfo2Font
      IF ::lCheck = .F.
         @ 31, 8 SAY ::oInfoSay PROMPT ::cInfoSay ;
            OF ::oInfoDlg SIZE 94, 20 PIXEL FONT oInfo2Font
      ENDIF

      //IF ::lPreview = .T.
         @ 30, 105 BUTTON VRD_GL( "&Cancel" ) ;
            OF ::oInfoDlg SIZE 40, 10 PIXEL FONT oInfo2Font ;
            ACTION ( ::oInfoDlg:End(), IIF( ::lCheck, ::lDialogCancel := .T., ), ;
                     ::lBreak := .T. )
      //ENDIF

      #IFDEF __XPP__
         ACTIVATE DIALOG ::oInfoDlg CENTER NOMODAL
         SetForegroundWindow( ::oInfoDlg:hWnd )
         EnableWindow( hTmpWnd, 0 )
      #ELSE
         ACTIVATE DIALOG ::oInfoDlg CENTER NOMODAL ;
            ON INIT ( aSay[1]:SetFont( oInfo2Font ), ;
                      aSay[2]:SetFont( oInfoFont ) , ;
                      aSay[3]:SetFont( oInfo2Font ) )
      #ENDIF

      oInfoFont:End()
      oInfo2Font:End()

   ENDIF

   IF lNoPrint = .F. .AND. ::loPrnExist = .F.

      ::oPrn := PrintBegin( ::cTitle,, ::lPreview, ;
                            IIF( EMPTY( ::cPrinter ), NIL, ::cPrinter ), ;
                            IIF( ::lPreview, lModal, .F. ) )

      IF ::nPaperWidth > 0
         ::nPaperWidth  := ::ToPix( ::nPaperWidth , .F. )
      ENDIF
      IF ::nPaperHeight > 0
         ::nPaperHeight := ::ToPix( ::nPaperHeight, .T. )
      ENDIF

      ::SetPaperSize( aSize )

      ::oPrn:SetCopies( ::nCopies )

      IF aSize <> NIL
      ELSEIF ::nOrientation = 2
         #IFDEF __HARBOUR__
            ::oPrn:SetLandscape()
         #ELSE
            ::oPrn:SetLandsca()
         #ENDIF
      ELSE
         #IFDEF __HARBOUR__
            ::oPrn:SetPortrait()
         #ELSE
            ::oPrn:SetPortrai()
         #ENDIF
      ENDIF

   ENDIF

   IF .NOT. EMPTY( cPreviewDir )
      ::oPrn:cDir := cPreviewDir
   ENDIF

   //Open the databases
   ::OpenDatabases()

   //Fonts
   aIniEntries := GetIniSection( "Fonts", ::cDefIni )

   FOR i := 1 TO 20
      cDef := ALLTRIM( GetIniEntry( aIniEntries, ALLTRIM(STR( i, 5)) , "" ) )
      IF .NOT. EMPTY( cDef )
         ::aFonts[i, 1] := ALLTRIM( VRD_GetField( cDef, 1 ) )                  //Name
         ::aFonts[i, 2] := VAL( VRD_GetField( cDef, 2 ) )                      //Width
         ::aFonts[i, 3] := VAL( VRD_GetField( cDef, 3 ) )                      //Height
         ::aFonts[i, 4] := IIF( VAL( VRD_GetField( cDef, 4 ) ) = 1, .T., .F. ) //Bold
         ::aFonts[i, 5] := IIF( VAL( VRD_GetField( cDef, 5 ) ) = 1, .T., .F. ) //Italic
         ::aFonts[i, 6] := IIF( VAL( VRD_GetField( cDef, 6 ) ) = 1, .T., .F. ) //Underline
         ::aFonts[i, 7] := IIF( VAL( VRD_GetField( cDef, 7 ) ) = 1, .T., .F. ) //Strikeout
         ::aFonts[i, 8] := VAL( VRD_GetField( cDef, 8 ) )                      //Escapement
         ::aFonts[i, 9] := VAL( VRD_GetField( cDef, 9 ) )                      //Character Set
         ::aFonts[i,10] := VAL( VRD_GetField( cDef, 10 ) )                     //Orientation
      ENDIF
   NEXT

   //Colors
   ::aColors := {}
   aIniEntries := GetIniSection( "Colors", ::cDefIni )

   FOR i := 1 TO 30
      AADD( ::aColors, VAL( GetIniEntry( aIniEntries, ALLTRIM(STR( i, 5)) , "" ) ) )
   NEXT

   //Areas
   ::aAreaInis := {}
   aIniEntries := GetIniSection( "Areas", ::cDefIni )

   FOR i := 1 TO 100

      cDef := ALLTRIM( GetIniEntry( aIniEntries, ALLTRIM(STR( i, 5)) , "" ) )

      IF .NOT. EMPTY( cDef )

         cFile := VRD_LF2SF( ::cAreaFilesDir + cDef )

         IF FILE( cFile ) = .F.
            AADD( ::aErrors, "2" + CHR(9) + "Area ini file not found: " + cDef )
         ENDIF

         AADD( ::aAreaInis, cFile )

      ENDIF

   NEXT

   //Area settings
   ::aAreaTop    := {}
   ::aAreaHeight := {}

   FOR i := 1 TO LEN( ::aAreaInis )

      aIniEntries := GetIniSection( "General", ::aAreaInis[i] )

      aTmpSource := {}

      FOR y := 1 TO 12
         AADD( aTmpSource, ALLTRIM( GetIniEntry( aIniEntries, "Formula" + ALLTRIM(STR(y,2)), "" ) ) )
      NEXT

      AADD( ::aAreaSource, aTmpSource )

      lTmpValue := ( GetIniEntry( aIniEntries, "DelEmptySpace", "0" ) = "1" )
      ::EvalAreaSource( @lTmpValue, ::aAreaSource[i,AREASOURCE_DELETESPACE] )
      AADD( ::aDelEmptySpace, lTmpValue )

      lTmpValue := ( GetIniEntry( aIniEntries, "BreakBefore", "0" ) = "1" )
      ::EvalAreaSource( @lTmpValue, ::aAreaSource[i,AREASOURCE_BREAKBEFORE] )
      AADD( ::aBreakBefore, lTmpValue )

      lTmpValue := ( GetIniEntry( aIniEntries, "BreakAfter", "0" ) = "1" )
      ::EvalAreaSource( @lTmpValue, ::aAreaSource[i,AREASOURCE_BREAKAFTER] )
      AADD( ::aBreakAfter, lTmpValue )

      lTmpValue := ( GetIniEntry( aIniEntries, "PrintBeforeBreak", "0" ) = "1" )
      ::EvalAreaSource( @lTmpValue, ::aAreaSource[i,AREASOURCE_PRBEFOREBREAK] )
      IF lTmpValue = .T.
         AADD( ::aPrBeforeBreak, i )
      ENDIF

      lTmpValue := ( GetIniEntry( aIniEntries, "PrintAfterBreak", "0" ) = "1" )
      ::EvalAreaSource( @lTmpValue, ::aAreaSource[i,AREASOURCE_PRAFTERBREAK] )
      IF lTmpValue = .T.
         AADD( ::aPrAfterBreak, i )
      ENDIF

      cTmpValue := ALLTRIM( GetIniEntry( aIniEntries, "ControlDBF", "" ) )
      ::EvalAreaSource( @cTmpValue, ::aAreaSource[i,AREASOURCE_CONTROLDBF] )
      AADD( ::aControlDBF, ASCAN( ::aDBAlias, cTmpValue ) )

      nTmpValue := VAL( GetIniEntry( aIniEntries, "Height", "0" ) )
      ::EvalAreaSource( @nTmpValue, ::aAreaSource[i,AREASOURCE_HEIGHT] )
      AADD( ::aAreaHeight, nTmpValue )

      AADD( ::aAreaTop, nValue )
      nValue += ::aAreaHeight[i]

   NEXT

   IF lNoPrint = .F. .AND. ::loPrnExist = .F.

      ::oPrn:StartPage()

      IF ::lShowInfo = .T. .AND. ::lCheck = .F.
         ::oInfoSay:SetText( ::cInfoSay2 + " 1" )
      ENDIF

   ENDIF

RETURN ( Self )


*-- METHOD -------------------------------------------------------------------
*         Name: End
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD End( lPrintArea ) CLASS VRD

   LOCAL i
   LOCAL oInfo := VRD_NewStructure()

   DEFAULT lPrintArea := .T.

   IF ::loPrnExist = .T.
      ::CloseDatabases()
      RETURN( NIL )
   ENDIF

   oInfo:AddMember( "nPages",, ::oPrn:nPage )

   IF ::lBreak = .F.

      IF LEN( ::aPrBeforeBreak ) > 0
         FOR i := 1 TO LEN( ::aPrBeforeBreak )
            ::AreaStart2( ::aPrBeforeBreak[i], lPrintArea )
         NEXT
      ENDIF

      ::oPrn:EndPage()

      //Preview
      IF ::oPrn:lMeta = .T.

         IF ::lCheck = .T.

            ::oPrn:End()
            SYSREFRESH()

         ELSE

            IF ::lShowInfo = .T.
               ::oInfoDlg:End()
               ::lShowInfo := .F.
               SYSREFRESH()
            ENDIF

            #IFDEF __HARBOUR__
               RPreview( ::oPrn )
            #ELSE
               ::oPrn:Preview()
            #ENDIF

         ENDIF

      ELSE

         ::oPrn:End()

      ENDIF

      ::oPrn := nil

      //End the info dialog
      IF ::lShowInfo = .T.
         ::oInfoDlg:End()
      ENDIF

      ::MsgError()

   ELSE

      ::oPrn:End()

   ENDIF

   ::CloseDatabases()

   SYSREFRESH()

   #IFDEF __XPP__
      EnableWindow( hTmpWnd, 1 )
      SetForegroundWindow( hTmpWnd )
   #ENDIF

RETURN ( oInfo )


*-- METHOD -------------------------------------------------------------------
*         Name: SetPaperSize
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SetPaperSize( aSize ) CLASS VRD

   LOCAL aSizes

   IF aSize <> NIL
      ::oPrn:SetSize( aSize[1], aSize[2] )
   ELSE

      IF ::nPaperSize = 42
         ::oPrn:SetSize( ::nPaperWidth, ::nPaperHeight )
      ELSE
         ::oPrn:SetPage( ::nPaperSize )
      ENDIF

   ENDIF

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: AreaStart
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD AreaStart( nArea, lPrintArea, aIDs, aStrings, lPageBreak ) CLASS VRD

   LOCAL i
   LOCAL nRecords   := IIF( ::aControlDBF[nArea] = 0, 1, ::aDBRecords[ ::aControlDBF[nArea] ] )
   LOCAL nCondition := VAL( GetPvProfString( "General", "Condition", "1", ::aAreaInis[nArea] ) )
   LOCAL nPrBefore  := VAL( GetPvProfString( "General", "PrintBeforeBreak", "0", ::aAreaInis[nArea] ) )
   LOCAL nPrAfter   := VAL( GetPvProfString( "General", "PrintAfterBreak" , "0", ::aAreaInis[nArea] ) )

   DEFAULT lPageBreak := .F.

   ::nCurArea   := nArea
   ::nDBFRecord := 0

   ::EvalAreaSource( @nCondition, ::aAreaSource[nArea,AREASOURCE_CONDITION] )

   IF nCondition = 2 .OR. ;
      nCondition = 3 .AND. ::oPrn:nPage > 1 .OR. ;
      nCondition = 4 .AND. ::oPrn:nPage = 1 .OR. ;
      nPrBefore = 1 .OR. nPrAfter = 1
      RETURN ( NIL )
   ENDIF

   FOR i := 1 TO nRecords

      ::nDBFRecord += 1

      ::SetPrevRecord( ::aControlDBF[nArea] )

      ::aBreakBefore[nArea] := ;
         ::EvalAreaSource( ::aBreakBefore[nArea], ::aAreaSource[nArea,AREASOURCE_BREAKBEFORE] )

      IF lPageBreak = .T. .OR. ::aBreakBefore[ nArea ] = .T.
         ::PageBreak( lPrintArea )
      ENDIF

      ::AreaStart2( nArea, lPrintArea, aIDs, aStrings, lPageBreak )

      ::aBreakAfter[nArea] := ;
         ::EvalAreaSource( ::aBreakAfter[nArea], ::aAreaSource[nArea,AREASOURCE_BREAKAFTER] )

      IF ::lAutoPageBreak = .T. .AND. ::nNextRow > ::nPageBreak .OR. ::aBreakAfter[ nArea ] = .T.
         //IF nArea <> LEN( ::aAreaInis )
            ::PageBreak( lPrintArea )
         //ENDIF
      ENDIF

   NEXT

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: SetPrevRecord
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SetPrevRecord( nAlias ) CLASS VRD

   LOCAL i, nOldSel
   LOCAL aCurRec := {}

   IF nAlias <> 0 .AND. ::aDBType[ nAlias ] = "DBF"

      //from DBF file
      nOldSel := SELECT()
      SELECT( ::aDBAlias[ nAlias ] )

      IF ::nDBFRecord > 1
         GOTO ::nDBFRecord - 1
         FOR i := 1 TO FCOUNT()
            AADD( aCurRec, FIELDGET( i ) )
         NEXT
         ::aDBPrevRecord[ nAlias ] := aCurRec
         GOTO ::nDBFRecord
      ELSE
         ::aDBPrevRecord[ nAlias ] := {}
      ENDIF

      SELECT( nOldSel )

   ELSEIF nAlias <> 0

      IF ::nDBFRecord > 1
         ::aDBPrevRecord[ nAlias ] := ::aDBContent[nAlias,::nDBFRecord]
      ELSE
         ::aDBPrevRecord[ nAlias ] := {}
      ENDIF

   ENDIF

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: AreaStart2
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD AreaStart2( nArea, lPrintArea, aIDs, aStrings, lPageBreak ) CLASS VRD

   LOCAL i, nAreaTop1, nAreaTop2
   LOCAL lAreaTop := IIF( VAL( GetPvProfString( "General", "TopVariable", "1", ::aAreaInis[nArea] ) ) = 1, .T., .F. )

   DEFAULT lPrintArea := .T.
   DEFAULT aIDs       := {}
   DEFAULT aStrings   := {}
   DEFAULT lPageBreak := .F.

   ::EvalAreaSource( @lAreaTop, ::aAreaSource[nArea,AREASOURCE_TOPVARIABLE] )

   nAreaTop1 := VAL( GetPvProfString( "General", "Top1", "0", ::aAreaInis[nArea] ) )
   nAreaTop2 := VAL( GetPvProfString( "General", "Top2", "0", ::aAreaInis[nArea] ) )

   ::EvalAreaSource( @nAreaTop1, ::aAreaSource[nArea,AREASOURCE_TOP1] )
   ::EvalAreaSource( @nAreaTop2, ::aAreaSource[nArea,AREASOURCE_TOP2] )

   IF lAreaTop = .T.

      //Top depends on previous area
      IF ::lFirstAreaOnPage = .T.
         ::nLastRow := ::nTopMargin
      ELSE
         ::nLastRow := IIF( ::nLastPrintedRow <> 0, ::nLastPrintedRow, ::nNextRow )
      ENDIF

      IF nAreaTop1 <> 0 .AND. ::oPrn:nPage = 1
         ::nLastRow := MAX( ::nLastRow, nAreaTop1 )
      ELSEIF nAreaTop2 <> 0 .AND. ::oPrn:nPage <> 1
         ::nLastRow := MAX( ::nLastRow, nAreaTop2 )
      ENDIF

   ELSE

      //Fix area position
      IF ::nLastArea = nArea
         ::nLastRow := IIF( ::nLastPrintedRow <> 0, ::nLastPrintedRow, ::nNextRow )
      ELSE
         ::nLastRow := IIF( ::oPrn:nPage = 1, nAreaTop1, nAreaTop2 )
      ENDIF

   ENDIF

   ::nNextRow         := ::nLastRow + ::aAreaHeight[nArea]
   ::lAreaStartUsed   := .T.
   ::nLastArea        := nArea
   ::nLastPrintedRow  := 0
   ::lFirstAreaOnPage := .F.

   IF lPrintArea = .T.
      IF LEN( aIDs ) = 0 .AND. LEN( aStrings ) = 0
         ::PrintArea( nArea,, .F. )
      ELSE
         ::PrintItemList( nArea, aIDs, aStrings )
         ::PrintRest( nArea,, .F. )
      ENDIF
   ENDIF

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: EvalAreaSource
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EvalAreaSource( xValue, cSource ) CLASS VRD

   IF .NOT. EMPTY( cSource )
      IF VALTYPE( xValue ) = "L"
         xValue := ( ::EvalSourceCode( cSource, "N" ) = 1 )
      ELSEIF VALTYPE( xValue ) = "N"
         xValue := ::EvalSourceCode( cSource, "N" )
      ELSEIF VALTYPE( xValue ) = "C"
         xValue := ::EvalSourceCode( cSource, "C" )
      ENDIF
   ENDIF

RETURN ( xValue )


*-- METHOD -------------------------------------------------------------------
*         Name: PrintItem
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrintItem( nArea, nItemID, cValue, nAddToTop, lMemo, nEntry ) CLASS VRD

   LOCAL nPad, oFont, oBrush, oPen, nTextLeft, oImg, nItemTop, nRndWidth, nRndHeight
   LOCAL nTop, nLeft, nBottom, nRight, hPen, hOldPen, hBrush, hOldBrush, cText, oBC
   LOCAL nMemoHeight, aMemo
   LOCAL lNewArea       := .F.
   LOCAL lMemoPageBreak := .F.
   LOCAL cEntryNr    := IIF( nEntry = NIL, ::GetEntryNr( nArea, nItemID ), ALLTRIM(STR(nEntry,5)) )
   LOCAL cItemDef    := ALLTRIM( GetPvProfString( "Items", cEntryNr, "", ::aAreaInis[ nArea ] ) )
   LOCAL oItem       := VRDItem():New( cItemDef )
   LOCAL nAreaTop1   := VAL( GetPvProfString( "General", "Top1"  , "0", ::aAreaInis[nArea] ) )
   LOCAL nAreaTop2   := VAL( GetPvProfString( "General", "Top2"  , "0", ::aAreaInis[nArea] ) )
   LOCAL lAreaTop    := IIF( VAL( GetPvProfString( "General", "TopVariable", "1", ::aAreaInis[nArea] ) ) = 1, .T., .F. )
   LOCAL nCondition  := VAL( GetPvProfString( "General", "Condition", "1", ::aAreaInis[nArea] ) )

   DEFAULT nAddToTop := 0
   DEFAULT lMemo     := oItem:lMultiLine
   DEFAULT nEntry    := 0

   ::EvalAreaSource( @lAreaTop   , ::aAreaSource[nArea,AREASOURCE_TOPVARIABLE] )
   ::EvalAreaSource( @nAreaTop1  , ::aAreaSource[nArea,AREASOURCE_TOP1] )
   ::EvalAreaSource( @nAreaTop2  , ::aAreaSource[nArea,AREASOURCE_TOP2] )
   ::EvalAreaSource( @nCondition , ::aAreaSource[nArea,AREASOURCE_CONDITION] )

   oItem := ::EvalFormula( oItem )

   IF ::lBreak = .T.
      RETURN ( NIL )
   ENDIF

   //Fill already printed item array
   IF LEN( ::aItemsPrinted ) <> 0
      IF nArea <> ::aItemsPrinted[1,1]
         //New Area
         ::aItemsPrinted := {}
         lNewArea := .T.
      ENDIF
   ENDIF

   AADD( ::aItemsPrinted, { nArea, cEntryNr } )

   nItemTop := oItem:nTop + nAddToTop

   IF ::lAreaStartUsed = .T.

      nItemTop := ::nLastRow + oItem:nTop

   ELSEIF lAreaTop = .T. .AND. ::lAreaStartUsed = .F.

      //Top depends on previous area
      IF ::nLastArea <> nArea

         nItemTop    += ::nNextRow
         ::nLastRow  := ::nNextRow
         ::nNextRow  += ::aAreaHeight[nArea] + nAddToTop
         ::nLastArea := nArea

      ELSE
         nItemTop    += ::nLastRow
      ENDIF

   ELSEIF ::lAreaStartUsed = .F.

      //Fix area position
      nItemTop    += IIF( ::oPrn:nPage = 1, nAreaTop1, nAreaTop2 )
      ::nNextRow  := IIF( ::oPrn:nPage = 1, nAreaTop1, nAreaTop2 ) + ;
                     ::aAreaHeight[nArea] + nAddToTop
      ::nLastArea := nArea

   ENDIF

   IF lAreaTop = .T.
      IF nAreaTop1 <> 0 .AND. ::oPrn:nPage = 1
         nItemTop := MAX( nItemTop, nAreaTop1 )
      ELSEIF nAreaTop2 <> 0 .AND. ::oPrn:nPage <> 1
         nItemTop := MAX( nItemTop, nAreaTop2 )
      ENDIF
   ENDIF

   //Condition
   IF nCondition = 2
      RETURN ( NIL )
   ELSEIF nCondition = 3 .AND. ::oPrn:nPage > 1
      RETURN ( NIL )
   ELSEIF nCondition = 4 .AND. ::oPrn:nPage = 1
      RETURN ( NIL )
   ENDIF

   //Orientation
   nPad := 0
   IIF( oItem:nOrient = 1 .OR. oItem:nOrient = 0, nPad := 0, )
   IIF( oItem:nOrient = 2, nPad := 2, )
   IIF( oItem:nOrient = 3, nPad := 1, )

   nTextLeft := ::nLeftMargin + oItem:nLeft
   IF nPad = 1
      nTextLeft += oItem:nWidth
   ELSEIF nPad = 2
      nTextLeft += oItem:nWidth / 2
   ENDIF

   IF oItem:cType = "TEXT" .AND. oItem:nShow = 1

      cText := ::EvalExpression( oItem:cText )
      IF .NOT. EMPTY( oItem:cSource ) .AND. ::lNoExpr = .F.
         cText := ::EvalSourceCode( oItem:cSource )
      ENDIF

      oFont := TFont():New( ::aFonts[oItem:nFont, 1], ;   // cFaceName
                            ::aFonts[oItem:nFont, 2], ;   // nWidth
                            ::aFonts[oItem:nFont, 3], ;   // nHeight
                            , ;                           // lFromUser
                            ::aFonts[oItem:nFont, 4], ;   // lBold
                            ::aFonts[oItem:nFont, 8], ;   // nEscapement
                            ::aFonts[oItem:nFont,10], ;   // nOrientation
                            , ;                           // nWeight
                            ::aFonts[oItem:nFont, 5], ;   // lItalic
                            ::aFonts[oItem:nFont, 6], ;   // lUnderline
                            ::aFonts[oItem:nFont, 7], ;   // lStrikeOut
                            ::aFonts[oItem:nFont, 9], ;   // nCharSet
                            , ;                           // nOutPrecision
                            , ;                           // nClipPrecision
                            , ;                           // nQuality
                            ::oPrn )                      // oDevice

      //Paint background
      IF ::aColors[ oItem:nColPane ] <> RGB( 255, 255, 255 ) .AND. oItem:nTrans = 0
         DEFINE BRUSH oBrush COLOR ::aColors[ oItem:nColPane ]
         ::oPrn:FillRect( { ::ToPix( nItemTop, .T. ), ;
                          ::ToPix( ::nLeftMargin + oItem:nLeft, .F. ), ;
                          ::ToPix( nItemTop + oItem:nHeight, .T. ), ;
                          ::ToPix( ::nLeftMargin + oItem:nLeft + oItem:nWidth, .F. ) }, ;
                        oBrush )
         oBrush:End()
      ENDIF

      IF lMemo = .T.
         IF oItem:nOrient < 4
            aMemo := ::SayMemo( ::ToPix( nItemTop, .T. ), ;
                     ::ToPix( nTextLeft, .F. ), ;
                     ::ToPix( oItem:nWidth, .F. ), ;
                     ::ToPix( oItem:nHeight, .T. ), ;
                     IIF( cValue = NIL, cText, cValue ), ;
                     oFont, ;
                     ::aColors[ oItem:nColText ], ;
                     nPad, ;
                     oItem:lVariHeight )
         ELSE
            aMemo := ::SayMemoJust( ::ToPix( nItemTop, .T. ), ;
                                    ::ToPix( nTextLeft, .F. ), ;
                                    ::ToPix( oItem:nWidth, .F. ), ;
                                    ::ToPix( oItem:nHeight, .T. ), ;
                                    IIF( cValue = NIL, cText, cValue ), ;
                                    oFont, ;
                                    ::aColors[ oItem:nColText ], ;
                                    oItem:nOrient, ;
                                    oItem:lVariHeight )
         ENDIF
         nMemoHeight    := aMemo[1]
         lMemoPageBreak := aMemo[2]
      ELSE
         ::Say( ::ToPix( nItemTop, .T. ) , ;
                ::ToPix( nTextLeft, .F. ), ;
                IIF( cValue = NIL, cText, cValue ), oFont, ;
                ::ToPix( oItem:nWidth, .F. ), ;
                ::aColors[ oItem:nColText ], , nPad )
      ENDIF

      oFont:End()

   ELSEIF oItem:cType = "IMAGE" .AND. oItem:nShow = 1

      oImg := TImage():New( 0, 0, 0, 0,,, IIF( oItem:nBorder = 1, .F., .T. ), ::oTmpWnd )
      oImg:Progress(.F.)

      IF cValue = NIL
         cText := ::EvalExpression( oItem:cFile )
         IF .NOT. EMPTY( oItem:cSource ) .AND. ::lNoExpr = .F.
            cText := ::EvalSourceCode( oItem:cSource )
         ENDIF
      ELSE
         cText := cValue
      ENDIF

      oImg:LoadImage( IIF( AT( "RES:", UPPER( cText ) ) <> 0, ;
                           SUBSTR( ALLTRIM( cText ), 5 ), NIL ), ;
                      VRD_LF2SF( cText ) )

      //oImg:LoadBmp( VRD_LF2SF( IIF( cValue = NIL, cText, ALLTRIM( cValue ) ) ) )

      ::oPrn:SayImage( ::ToPix( nItemTop, .T. ), ;
                     ::ToPix( ::nLeftMargin + oItem:nLeft, .F. ), ;
                     oImg, ;
                     ::ToPix( oItem:nWidth, .F. ), ;
                     ::ToPix( oItem:nHeight, .T. ) )
      oImg:End()

   ELSEIF oItem:lGraphic = .T. .AND. oItem:nShow = 1

      nTop       := ::ToPix( nItemTop, .T. )
      nLeft      := ::ToPix( ::nLeftMargin + oItem:nLeft, .F. )
      nBottom    := ::ToPix( nItemTop + oItem:nHeight, .T. )
      nRight     := ::ToPix( ::nLeftMargin + oItem:nLeft + oItem:nWidth, .F. )
      nRndWidth  := ::ToPix( oItem:nRndWidth*2, .F. )
      nRndHeight := ::ToPix( oItem:nRndHeight*2, .T. )

      hPen       := CreatePen( oItem:nStyle - 1, oItem:nPenWidth, ::aColors[ oItem:nColor ] )
      hOldPen    := SelectObject( ::oPrn:hDCOut, hPen )
      hBrush     := CreateSolidBrush( ::aColors[ oItem:nColFill ] )
      IF oItem:lTrans = .T.
         hOldBrush := SelectObject( ::oPrn:hDCOut, GetStockObject( 5 ) )
      ELSE
         hOldBrush := SelectObject( ::oPrn:hDCOut, hBrush )
      ENDIF

      DO CASE
      CASE oItem:cType == "LINEUP"
         MOVETO( ::oPrn:hDCOut, nLeft , nBottom )
         LINETO( ::oPrn:hDCOut, nRight, nTop )
      CASE oItem:cType == "LINEDOWN"
         MOVETO( ::oPrn:hDCOut, nLeft , nTop )
         LINETO( ::oPrn:hDCOut, nRight, nBottom )
      CASE oItem:cType == "LINEHORIZONTAL"
         MOVETO( ::oPrn:hDCOut, nLeft , nTop + IIF( oItem:nHeight > 1, (nBottom-nTop)/2, 0 ) )
         LINETO( ::oPrn:hDCOut, nRight, nTop + IIF( oItem:nHeight > 1, (nBottom-nTop)/2, 0 ) )
      CASE oItem:cType == "LINEVERTICAL"
         MOVETO( ::oPrn:hDCOut, nLeft + IIF( oItem:nWidth > 1, (nRight-nLeft)/2, 0 ), nTop    )
         LINETO( ::oPrn:hDCOut, nLeft + IIF( oItem:nWidth > 1, (nRight-nLeft)/2, 0 ), nBottom )
      CASE oItem:cType == "RECTANGLE"
         RoundRect( ::oPrn:hDCOut, nLeft, nTop, nRight, nBottom, nRndWidth, nRndHeight )
      CASE oItem:cType == "ELLIPSE"
         Ellipse( ::oPrn:hDCOut, nLeft, nTop, nRight, nBottom )
      ENDCASE

      SelectObject( ::oPrn:hDCOut, hOldPen )
      DeleteObject( hPen )
      SelectObject( ::oPrn:hDCOut, hOldBrush )
      DeleteObject( hBrush )

   ELSEIF oItem:cType = "BARCODE" .AND. oItem:nShow = 1

      nTop       := ::ToPix( nItemTop, .T. )
      nLeft      := ::ToPix( ::nLeftMargin + oItem:nLeft, .F. )
      nBottom    := ::ToPix( oItem:nHeight, .T. )
      nRight     := ::ToPix( oItem:nWidth, .F. )

      cText := ::EvalExpression( oItem:cText )
      IF .NOT. EMPTY( oItem:cSource ) .AND. ::lNoExpr = .F.
         cText := ::EvalSourceCode( oItem:cSource )
      ENDIF

      oBC := VRDBarcode():New( ::oPrn:hDCOut, IIF( cValue = NIL, cText, cValue ), ;
                               nTop, nLeft, nRight, nBottom, ;
                               oItem:nBCodeType, ;
                               ::aColors[ oItem:nColText ], ;
                               ::aColors[ oItem:nColPane ], ;
                               oItem:lHorizontal, oItem:lTrans, ;
                               ::ToPix( oItem:nPinWidth, IIF( oItem:lHorizontal, .F., .T.) ) )
      oBC:ShowBarcode()

   ENDIF

   //Draw border
   IF oItem:lGraphic = .F. .AND. oItem:cType <> "BARCODE" .AND. ;
      oItem:nBorder = 1 .AND. oItem:nShow = 1
      ::DrawBox( ::ToPix( nItemTop, .T. ), ;
                 ::ToPix( ::nLeftMargin + oItem:nLeft, .F. ), ;
                 ::ToPix( nItemTop + ;
                    IIF( lMemo = .T., ::ToMmInch( nMemoHeight, .T. ), oItem:nHeight ), .T. ), ;
                 ::ToPix( ::nLeftMargin + oItem:nLeft + oItem:nWidth, .F. ) )
   ENDIF

   //Print the item ID
   IF ::lPrintIDs = .T. .AND. oItem:nShow = 1

      DEFINE FONT oFont NAME "Arial" SIZE 0,-8 OF ::oPrn

      ::Say( ::ToPix( nItemTop - IIF( ::nMeasure = 1, 3, 0.1 ), .T. ), ;
             ::ToPix( nTextLeft, .F. ), ;
             ALLTRIM(STR( nArea, 3 )) + "/" + ALLTRIM(STR( oItem:nItemID, 10 )), ;
             oFont, ::ToPix( oItem:nWidth, .F. ), 0,, nPad )

      oFont:End()

   ENDIF

   //Last printed row
   IF oItem:nShow = 1 .AND. ::aDelEmptySpace[nArea] = .T.
      IF lMemoPageBreak = .T.
         ::nLastPrintedRow := ::ToMmInch( nMemoHeight, .T. )
      ELSE
         ::nLastPrintedRow := MAX( ::nLastPrintedRow, nItemTop + ;
                              IIF( lMemo = .T., ::ToMmInch( nMemoHeight, .T. ), oItem:nHeight ) )
      ENDIF
      ::nNextRow := ::nLastPrintedRow
   ENDIF

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: EvalFormula
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EvalFormula( oItem ) CLASS VRD

   IF !EMPTY( oItem:cSTop     ) ; oItem:nTop     := ::EvalSourceCode( oItem:cSTop    , "N" ) ; ENDIF
   IF !EMPTY( oItem:cSLeft    ) ; oItem:nLeft    := ::EvalSourceCode( oItem:cSLeft   , "N" ) ; ENDIF
   IF !EMPTY( oItem:cSWidth   ) ; oItem:nWidth   := ::EvalSourceCode( oItem:cSWidth  , "N" ) ; ENDIF
   IF !EMPTY( oItem:cSHeight  ) ; oItem:nHeight  := ::EvalSourceCode( oItem:cSHeight , "N" ) ; ENDIF
   IF !EMPTY( oItem:cSVisible ) ; oItem:nShow    := ::EvalSourceCode( oItem:cSVisible, "N" ) ; oItem:lVisible := ( oItem:nShow <> 0 ) ; ENDIF

   IF oItem:cType = "TEXT"

      IF !EMPTY( oItem:cSFont        ) ; oItem:nFont      := ::EvalSourceCode( oItem:cSFont       , "N" ) ; ENDIF
      IF !EMPTY( oItem:cSTextClr     ) ; oItem:nColText   := ::EvalSourceCode( oItem:cSTextClr    , "N" ) ; ENDIF
      IF !EMPTY( oItem:cSBackClr     ) ; oItem:nColPane   := ::EvalSourceCode( oItem:cSBackClr    , "N" ) ; ENDIF
      IF !EMPTY( oItem:cSAlignment   ) ; oItem:nOrient    := ::EvalSourceCode( oItem:cSAlignment  , "N" ) ; ENDIF
      IF !EMPTY( oItem:cSTransparent ) ; oItem:nTrans     := ::EvalSourceCode( oItem:cSTransparent, "N" ) ; oItem:lTrans   := ( oItem:nTrans  <> 0 ) ; ENDIF
      IF !EMPTY( oItem:cSPrBorder    ) ; oItem:nBorder    := ::EvalSourceCode( oItem:cSPrBorder   , "N" ) ; oItem:lBorder  := ( oItem:nBorder <> 0 ) ; ENDIF
      IF !EMPTY( oItem:cSMultiline   ) ; oItem:lMultiline := ( ::EvalSourceCode( oItem:cSMultiline, "N" ) = 1 ) ; ENDIF

   ELSEIF oItem:cType = "IMAGE"

      IF !EMPTY( oItem:cSPrBorder    ) ; oItem:nBorder    := ::EvalSourceCode( oItem:cSPrBorder   , "N" ) ; oItem:lBorder  := ( oItem:nBorder <> 0 ) ; ENDIF

   ELSEIF oItem:lGraphic = .T.

      IF !EMPTY( oItem:cSTextClr     ) ; oItem:nColor     := ::EvalSourceCode( oItem:cSTextClr    , "N" ) ; ENDIF
      IF !EMPTY( oItem:cSBackClr     ) ; oItem:nColFill   := ::EvalSourceCode( oItem:cSBackClr    , "N" ) ; ENDIF
      IF !EMPTY( oItem:cSTransparent ) ; oItem:nTrans     := ::EvalSourceCode( oItem:cSTransparent, "N" ) ; oItem:lTrans   := ( oItem:nTrans  <> 0 ) ; ENDIF
      IF !EMPTY( oItem:cSPenSize     ) ; oItem:nPenWidth  := ::EvalSourceCode( oItem:cSPenSize    , "N" ) ; ENDIF
      IF !EMPTY( oItem:cSPenStyle    ) ; oItem:nStyle     := ::EvalSourceCode( oItem:cSPenStyle   , "N" ) ; ENDIF

   ELSEIF oItem:cType = "BARCODE"

      IF !EMPTY( oItem:cSTextClr     ) ; oItem:nColText   := ::EvalSourceCode( oItem:cSTextClr    , "N" ) ; ENDIF
      IF !EMPTY( oItem:cSBackClr     ) ; oItem:nColPane   := ::EvalSourceCode( oItem:cSBackClr    , "N" ) ; ENDIF
      IF !EMPTY( oItem:cSAlignment   ) ; oItem:nOrient    := ::EvalSourceCode( oItem:cSAlignment  , "N" ) ; oItem:lHorizontal := ( oItem:nOrient <> 0 ) ; ENDIF
      IF !EMPTY( oItem:cSTransparent ) ; oItem:nTrans     := ::EvalSourceCode( oItem:cSTransparent, "N" ) ; oItem:lTrans      := ( oItem:nTrans  <> 0 ) ; ENDIF
      IF !EMPTY( oItem:cSPenSize     ) ; oItem:nPenWidth  := ::EvalSourceCode( oItem:cSPenSize    , "N" ) ; ENDIF

   ENDIF

RETURN oItem


*-- METHOD -------------------------------------------------------------------
*         Name: EvalSourceCode
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EvalSourceCode( cSource, cValType ) CLASS VRD

   LOCAL xValue := ""

   DEFAULT cValType := "C"

   IF LEN( ::aAlias ) > 0
      AEVAL( ::aAlias, {|x,y| ;
         cSource := STRTRAN( UPPER( cSource ), "ALIAS" + ALLTRIM(STR(y,3)) + "->", ;
                                               ::aAlias[y] + "->" ) } )
   ENDIF

   cSource := ::EvalDBFields( cSource )

   IF Empty( ::bTransExpr )
      xValue := EVAL( &( "{ | oPrn, oVRD, oInfo |" + ALLTRIM( cSource ) + " }" ), ::oPrn, SELF, ::oInfo )
   ELSE
      xValue := EVAL( ::bTransExpr, SELF, ALLTRIM( cSource ) )
   ENDIF

   IF cValType = "C" .AND. VALTYPE( xValue ) = "N"
      xValue := ALLTRIM(STR( xValue ))
   ELSEIF cValType = "N" .AND. VALTYPE( xValue ) = "C"
      xValue := VAL( xValue )
   ELSEIF VALTYPE( xValue ) <> "C" .AND. VALTYPE( xValue ) <> "N"
      IF cValType = "N"
         xValue := 0
      ELSE
         xValue := ""
      ENDIF
   ENDIF

RETURN xValue


*-- METHOD -------------------------------------------------------------------
*         Name: EvalExpression
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EvalExpression( cText ) CLASS VRD

   cText := ::EvalDBFields( cText, .T. )

   IF ALLTRIM(SUBSTR( cText, 1, 3 )) = "[1]" .OR. ;
      ALLTRIM(SUBSTR( cText, 1, 3 )) = "[2]"
      IF ::lNoExpr = .F.
         IF Empty( ::bTransExpr )
            cText := EVAL( &( "{ | oPrn, oVRD, oInfo |" + ::GetExpression( cText ) + " }" ), ::oPrn, SELF, ::oInfo )
         ELSE
            cText := EVAL( ::bTransExpr, SELF, ALLTRIM( ::GetExpression( cText ) ) )
         ENDIF
      ENDIF
   ELSEIF ALLTRIM(SUBSTR( cText, 1, 3 )) = "[3]"
      cText := ::GetExpression( cText )
   ENDIF

RETURN cText


*-- METHOD -------------------------------------------------------------------
*         Name: PrintUserFields
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrintUserFields( nArea, nAddToTop ) CLASS VRD

   LOCAL i, cItemDef, oIni, nEntry
   LOCAL cAreaIni    := ::aAreaInis[ nArea ]
   LOCAL aIniEntries := ::GetIniItems( nArea )

   DEFAULT nAddToTop := 0

   FOR i := 1 TO LEN( aIniEntries )

      nEntry := VAL( SUBSTR( aIniEntries[i], 1, AT( "=", aIniEntries[i] ) - 1 ) )

      IF nEntry <> 0 .AND. nEntry > 399
         cItemDef := GetIniEntry( aIniEntries,, "",, i )
         ::PrintItem( nArea,,, nAddToTop,, nEntry )
      ENDIF

      SYSREFRESH()

   NEXT

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: PrintArea
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrintArea( nArea, nAddToTop, lPageBreak ) CLASS VRD

   LOCAL i, cItemDef, oIni, nEntry
   LOCAL cAreaIni    := ::aAreaInis[ nArea ]
   LOCAL aIniEntries := ::GetIniItems( nArea )

   DEFAULT nAddToTop  := 0
   DEFAULT lPageBreak := .T.

   FOR i := LEN( aIniEntries ) TO 1 STEP -1

      nEntry := VAL( SUBSTR( aIniEntries[i], 1, AT( "=", aIniEntries[i] ) - 1 ) )

      IF nEntry <> 0
         cItemDef := GetIniEntry( aIniEntries,, "",, i )
         ::PrintItem( nArea,,, nAddToTop,, nEntry )
      ENDIF

      SYSREFRESH()

   NEXT

   IF ::aBreakAfter[ nArea ] = .T. .AND. lPageBreak = .T.
      ::PageBreak()
   ENDIF

   ::aItemsPrinted := {}

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: PrintRest
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrintRest( nArea, nAddToTop, lPageBreak ) CLASS VRD

   LOCAL i, cItemDef, oIni, nEntry
   LOCAL cAreaIni    := ::aAreaInis[ nArea ]
   LOCAL aIniEntries := ::GetIniItems( nArea )

   DEFAULT nAddToTop  := 0
   DEFAULT lPageBreak := .T.

   FOR i := LEN( aIniEntries ) TO 1 STEP -1

      nEntry := VAL( SUBSTR( aIniEntries[i], 1, AT( "=", aIniEntries[i] ) - 1 ) )

      IF ASCAN( ::aItemsPrinted, {|aVal| aVal[2] == ALLTRIM(STR(nEntry,5)) } ) = 0

         IF nEntry <> 0
            cItemDef := GetIniEntry( aIniEntries,, "",, i )
            ::PrintItem( nArea,,, nAddToTop,, nEntry )
         ENDIF

         SYSREFRESH()

      ENDIF

   NEXT

   IF ::aBreakAfter[ nArea ] = .T. .AND. lPageBreak = .T.
      ::PageBreak()
   ENDIF

   ::aItemsPrinted := {}

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: PrintItemList
*  Description:
*       Author: José Lalin / Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrintItemList( nArea, aIDs, aStrings, nAddToTop ) CLASS VRD

   IF LEN( aIDs ) <> LEN( aStrings )
      MsgStop( "Area: " + ALLTRIM(STR( nArea, 3 )) + CRLF + ;
               "The lengths of the ID array and the string array are no the same!" )
   ENDIF

   AEVAL( aIDs, {|cID, nCount| ::PrintItem( nArea, cID, aStrings[nCount], nAddToTop ) } )

   IF nAddToTop <> NIL
      nAddToTop += ::aAreaHeight[ nArea ]
   ENDIF

RETURN (NIL)


*-- METHOD -------------------------------------------------------------------
*         Name: PrMultiAreas
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrMultiAreas( aArea, lPrintArea ) CLASS VRD

   AEVAL( aArea, {|x| ::AreaStart( x, lPrintArea ) } )

RETURN (NIL)


*-- METHOD -------------------------------------------------------------------
*         Name: DrawBox
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD DrawBox( nTop, nLeft, nBottom, nRight ) CLASS VRD

   IF ::lBreak = .T.
      RETURN ( NIL )
   ENDIF

   ::oPrn:Line( nTop, nLeft, nTop, nRight )
   ::oPrn:Line( nTop, nRight, nBottom, nRight )
   ::oPrn:Line( nBottom, nLeft, nBottom, nRight )
   ::oPrn:Line( nTop, nLeft, nBottom, nLeft )

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: Say
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD Say( nRow, nCol, cText, oFont, nWidth, nClrText, nBkMode, nPad ) CLASS VRD

   IF ::oPrn:hDC = 0
      RETURN NIL
   ENDIF

   DEFAULT oFont   := ::oPrn:oFont
   DEFAULT nBkMode := 1
   DEFAULT nPad    := 0

   IF oFont != nil
      oFont:Activate( ::oPrn:hDCOut )
   ENDIF

   // 1,2 transparent or Opaque
   SetbkMode( ::oPrn:hDCOut, nBkMode )

   IF nClrText != NIL
      #IFDEF __HARBOUR__
         SetTextColor( ::oPrn:hDCOut, nClrText )
      #ELSE
         SetTextCol( ::oPrn:hDCOut, nClrText )
      #ENDIF
   ENDIF

   DO CASE
   CASE nPad == 1  // right
      nCol := Max( 0, nCol - ::GetTextWidth( cText, oFont ) )
   CASE nPad == 2  // center
      nCol := Max( 0, nCol - ( ::GetTextWidth( cText, oFont ) / 2 ) )
   ENDCASE

   TextOut( ::oPrn:hDCOut, nRow, nCol, cText )

   IF oFont != nil
      oFont:DeActivate( ::oPrn:hDCOut )
   ENDIF

   IF nClrText != NIL
      #IFDEF __HARBOUR__
         SetTextColor( ::oPrn:hDCOut, 0 )
      #ELSE
         SetTextCol( ::oPrn:hDCOut, 0 )
      #ENDIF
   ENDIF

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: SayMemo
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SayMemo( nTop, nLeft, nWidth, nHeight, cText, oFont, nColor, nPad, lVariHeight ) CLASS VRD

   LOCAL i
   LOCAL nTmpHeight     := 0
   LOCAL lMemoPageBreak := .F.
   LOCAL nLines         := MlCount( cText, 240 )
   LOCAL aAbstand       := ::oPrn:Cmtr2Pix( 0.2, 0.2 )

   FOR i := 1 TO nLines

      ::Say( nTop, nLeft, RTRIM(MemoLine( cText, 240, i )), oFont, nWidth, nColor,, nPad )

      nTop       += oFont:nHeight + aAbstand[1]
      nTmpHeight += oFont:nHeight + aAbstand[1]

      IF nTmpHeight > nHeight .AND. lVariHeight = .F.
         EXIT
      ELSEIF nTop >= ::nPageBreak
         //::PageBreak()
         //lMemoPageBreak := .T.
         //nTop           := ::nNextRow
         //nTmpHeight     := nTop
      ENDIF

   NEXT

RETURN { nTmpHeight, lMemoPageBreak }


*-- METHOD -------------------------------------------------------------------
*         Name: SayMemoJust
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SayMemoJust( nTop, nLeft, nWidth, nHeight, cText, oFont, nColor, nOrient, lVariHeight ) CLASS VRD

   LOCAL i, nSpaces
   LOCAL nTmpHeight     := 0
   LOCAL lMemoPageBreak := .F.
   LOCAL aText          := ::MemoText( cText, nWidth, oFont )
   LOCAL nLines         := LEN( aText )
   LOCAL aAbstand       := ::oPrn:Cmtr2Pix( 0.2, 0.2 )

   FOR i := 1 TO nLines

      aText[i] := RTRIM( aText[i] )
      nSpaces  := ::MemoTextSpaces( aText[i] )

      IF .NOT. EMPTY( aText[i] )
         IF RIGHT( aText[i], 1 ) <> CHR( 127 )
            IF nSpaces > 0 .AND. nOrient = 4
               SETTEXTJUSTIFICATION( ::oPrn:hDCOut, ;
                  nWidth - ::GetTextWidth( aText[i], oFont ), nSpaces )
            ENDIF
         ELSE
            aText[i] = LEFT( aText[i], LEN( aText[i] ) - 1 )
         ENDIF
      ENDIF

      ::Say( nTop, nLeft, aText[i], oFont,, nColor )

      SETTEXTJUSTIFICATION( ::oPrn:hDCOut, 0, 0 )

      nTop       += oFont:nHeight + aAbstand[1]
      nTmpHeight += oFont:nHeight + aAbstand[1]

      IF nTmpHeight > nHeight .AND. lVariHeight = .F.
         EXIT
      ELSEIF nTop >= ::nPageBreak
         //::PageBreak()
         //lMemoPageBreak := .T.
         //nTop           := ::nNextRow
         //nTmpHeight     := nTop
      ENDIF

   NEXT

RETURN { nTmpHeight, lMemoPageBreak }


*-- METHOD -------------------------------------------------------------------
*         Name: MemoText
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD MemoText( cText, nLength, oFont ) CLASS VRD

    LOCAL aLines := {}

    LOCAL nLen := LEN( cText )
    LOCAL nPos := 1

    LOCAL cLine, nTPos

    IF ISOEM( cText )
       cText = OEMTOANSI( cText )
    ENDIF

    DO WHILE nPos <= nLen

        cLine = ::MemoTextPLeft( SUBSTR( cText, nPos ), nLength, oFont )

        nTPos = AT( CRLF, cLine )

        IF nTPos > 0
            cLine = LEFT( cLine, nTPos - 1 )
            nPos += nTPos + 1
            AADD( aLines, cLine + CHR( 127 ) )
            LOOP
        ENDIF

        nPos += LEN( cLine )

        IF nPos > nLen .OR. SUBSTR( cText, nPos, 1 ) = " "
            AADD( aLines, cLine )
            nPos++
            LOOP
        ENDIF

        IF ::MemoTextSpaces( cLine ) > 0
            nTPos = LEN( cLine )
            DO WHILE SUBSTR( cLine, nTPos, 1 ) != " "
               nTPos--
               nPos--
            ENDDO
            AADD( aLines, LEFT( cLine, nTPos - 1 ) )
        ELSE
            AADD( aLines, cLine )
        ENDIF

    ENDDO

    IF LEN( aLines ) > 0
       aLines[ LEN( aLines ) ] += CHR( 127 )
    ENDIF

RETURN aLines


*-- METHOD -------------------------------------------------------------------
*         Name: MemoTextPLeft
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD MemoTextPLeft( cText, nPixels, oFont ) CLASS VRD

   LOCAL cTText  := RTRIM( cText )

   IF ::GetTextWidth( cTText, oFont ) <= nPixels
       RETURN cTText
   ENDIF

   WHILE ::GetTextWidth( cTText, oFont ) > nPixels
       cTText = LEFT( cTText, LEN( cTText ) - 10 )
   ENDDO

   WHILE ::GetTextWidth( cTText, oFont ) <= nPixels
       cTText += SUBSTR( cText, LEN( cTText ) + 1, 1 )
   ENDDO

RETURN LEFT( cTText, LEN( cTText ) - 1 )


*-- METHOD -------------------------------------------------------------------
*         Name: MemoTextSpaces
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD MemoTextSpaces( cText ) CLASS VRD

   LOCAL i, nSpaces := 0

   FOR i = 1 TO LEN( cText )
      IF SUBSTR( cText, i, 1 ) = " "
         nSpaces++
      ENDIF
   NEXT

RETURN nSpaces


*-- METHOD -------------------------------------------------------------------
*         Name: GetIniItems
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GetIniItems( nArea ) CLASS VRD

   LOCAL aIniEntries

   IF nArea = ::nLastIniArea
      aIniEntries := ::aLastItems
   ELSE
      aIniEntries    := GetIniSection( "Items", ::aAreaInis[ nArea ] )
      ::nLastIniArea := nArea
      ::aLastItems   := aIniEntries
   ENDIF

RETURN aIniEntries


*-- METHOD -------------------------------------------------------------------
*         Name: GetItem
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GetItem( nArea, nItemID ) CLASS VRD

   LOCAL cItemDef := ALLTRIM( GetPvProfString( "Items", ::GetEntryNr( nArea, nItemID ), ;
                                               "", ::aAreaInis[ nArea ] ) )
   LOCAL oItem    := VRDItem():New( cItemDef )

RETURN oItem


*-- METHOD -------------------------------------------------------------------
*         Name: GetEntryNr
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GetEntryNr( nArea, nItemID ) CLASS VRD

   LOCAL nIndex
   LOCAL cEntry      := ""
   LOCAL aIniEntries := ::GetIniItems( nArea )

   IF ::aAreaInis[ nArea ] <> NIL

      nIndex := ASCAN( aIniEntries, {|x| VAL( VRD_GetField( x, 3 ) ) == nItemID } )

      IF nIndex <> 0
         //0 = Entry not defined
         cEntry := ALLTRIM(SUBSTR( aIniEntries[nIndex], 1, AT( "=", aIniEntries[nIndex] ) - 1 ))
      ENDIF

   ENDIF

RETURN ( cEntry )


*-- METHOD -------------------------------------------------------------------
*         Name: DefineFonts
*  Description: Defines all fonts
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD DefineFonts() CLASS VRD

   LOCAL i
   LOCAL aAllFonts := ARRAY( 20 )

   FOR i := 1 TO 20
      aAllFonts[i] := TFont():New( ::aFonts[i, 1], ;   // cFaceName
                                   ::aFonts[i, 2], ;   // nWidth
                                   ::aFonts[i, 3], ;   // nHeight
                                   , ;                 // lFromUser
                                   ::aFonts[i, 4], ;   // lBold
                                   ::aFonts[i, 8], ;   // nEscapement
                                   ::aFonts[i,10], ;   // nOrientation
                                   , ;                 // nWeight
                                   ::aFonts[i, 5], ;   // lItalic
                                   ::aFonts[i, 6], ;   // lUnderline
                                   ::aFonts[i, 7], ;   // lStrikeOut
                                   ::aFonts[i, 9] )    // nCharSet
   NEXT

RETURN aAllFonts


*-- METHOD -------------------------------------------------------------------
*         Name: AreaTitle
*  Description: Returns the title of a certain area
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD AreaTitle( nArea ) CLASS VRD

RETURN ALLTRIM( GetPvProfString( "General", "Title" , "", ::aAreaInis[ nArea ] ) )


*-- METHOD -------------------------------------------------------------------
*         Name: AreaWidth
*  Description: Returns the width of a certain area
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD AreaWidth( nArea ) CLASS VRD

RETURN VAL( GetPvProfString( "General", "Width", "600", ::aAreaInis[ nArea ] ) )


*-- METHOD -------------------------------------------------------------------
*         Name: AreaHeight
*  Description: Returns the height of a certain area
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD AreaHeight( nArea ) CLASS VRD

RETURN VAL( GetPvProfString( "General", "Height", "300", ::aAreaInis[ nArea ] ) )


*-- METHOD -------------------------------------------------------------------
*         Name: ToPix
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD ToPix( nValue, lHeight ) CLASS VRD

   LOCAL aWerte[2], aWerte1[2], aWerte2[2]

   IF ::nMeasure = 1

      IF nValue < 5
         aWerte1 := ::oPrn:Cmtr2Pix( 1, 1 )
         aWerte2 := ::oPrn:Cmtr2Pix( 1 + nValue/10, 1 + nValue/10 )
         aWerte  := { aWerte2[1] - aWerte1[1], aWerte2[2] - aWerte1[2] }
      ELSE
         aWerte  := ::oPrn:Cmtr2Pix( nValue/10, nValue/10 )
      ENDIF

   ELSEIF ::nMeasure = 2
      aWerte := ::oPrn:Inch2Pix( nValue, nValue )
   ELSE
      aWerte := { nValue, nValue }
   ENDIF

RETURN aWerte[ IIF( lHeight = .T. , 1, 2 ) ]


*-- METHOD -------------------------------------------------------------------
*         Name: ToMmInch
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD ToMmInch( nValue, lHeight ) CLASS VRD

   LOCAL aWerte

   IF ::nMeasure = 1
      aWerte := ::oPrn:Pix2Mmtr( nValue, nValue )
   ELSEIF ::nMeasure = 2
      aWerte := ::oPrn:Pix2Inch( nValue, nValue )
   ELSE
      aWerte := { nValue, nValue }
   ENDIF

RETURN aWerte[ IIF( lHeight = .T. , 1, 2 ) ]


*-- METHOD -------------------------------------------------------------------
*         Name: SetExpression
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD SetExpression( cName, cExpression, cInfo ) CLASS VRD

   LOCAL nAltSel
   LOCAL cGenExpr := ::cDataPath + ;
                     GetPvProfString( "General", "GeneralExpressions", "", ::cDefIni )
                     
  //  LOCAL cGenExpr := ::cDefaultPath + ;
  //                   GetPvProfString( "General", "GeneralExpressions", "", ::cDefIni )                  

   DEFAULT cName       := ""
   DEFAULT cExpression := ""
   DEFAULT cInfo       := ""

   IF EMPTY( cGenExpr ) .OR. EMPTY( cName )
      RETURN ( .F. )
   ENDIF

   nAltSel := SELECT()
   SELECT 0
   USE ( VRD_LF2SF( cGenExpr ) ) ALIAS "GENEXPR" EXCLUSIVE

   LOCATE FOR GENEXPR->NAME = cName

   IF .NOT. FOUND()
      APPEND BLANK
   ENDIF

   REPLACE GENEXPR->NAME       WITH cName
   REPLACE GENEXPR->EXPRESSION WITH cExpression
   REPLACE GENEXPR->INFO       WITH cInfo

   GENEXPR->(DBCLOSEAREA())
   SELECT( nAltSel )

RETURN ( .T. )


*-- METHOD -------------------------------------------------------------------
*         Name: GetExpression
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GetExpression( cName ) CLASS VRD

   LOCAL nAltSel, cExprDBF
   LOCAL lDatabase   := .F.
   LOCAL cExpression := "substr(' ', 1)"
   LOCAL cGenExpr    := ::cDataPath + GetPvProfString( "General", "GeneralExpressions", "", ::cDefIni )
   LOCAL cUserExpr   := ::cDataPath + GetPvProfString( "General", "UserExpressions"   , "", ::cDefIni )
   LOCAL cDataExpr   := ::cDataPath + GetPvProfString( "General", "DataExpressions"   , "", ::cDefIni )
   
  // LOCAL cGenExpr    := ::cDefaultPath + GetPvProfString( "General", "GeneralExpressions", "", ::cDefIni )
  // LOCAL cUserExpr   := ::cDefaultPath + GetPvProfString( "General", "UserExpressions"   , "", ::cDefIni )
  // LOCAL cDataExpr   := ::cDefaultPath + GetPvProfString( "General", "DataExpressions"   , "", ::cDefIni )

   DEFAULT cName := ""

   IF ALLTRIM(SUBSTR( cName, 1, 3 )) = "[1]"
      cExprDBF := cGenExpr
   ELSEIF ALLTRIM(SUBSTR( cName, 1, 3 )) = "[2]"
      cExprDBF := cUserExpr
   ELSE
      cExprDBF  := cDataExpr
      lDatabase := .T.
   ENDIF

   IF EMPTY( cExprDBF ) .OR. EMPTY( cName )
      RETURN ( "" )
   ENDIF

   nAltSel := SELECT()
   SELECT 0
   USE ( VRD_LF2SF( cExprDBF ) ) ALIAS "EXPRDBF"

   LOCATE FOR EXPRDBF->NAME = SUBSTR( cName, 4 )

   IF FOUND()

      IF lDatabase = .F.

         cExpression := EXPRDBF->EXPRESSION

      ELSE

         cExpression := ""

         IF .NOT. EMPTY( EXPRDBF->DATABASE ) .AND. ;
               FILE( VRD_LF2SF( ALLTRIM( EXPRDBF->DATABASE ) ) ) = .T.

            SELECT 0
            USE ( VRD_LF2SF( ALLTRIM( EXPRDBF->DATABASE ) ) ) ALIAS "ZIELDBF" VIA ::cRDD
            GO EXPRDBF->RECORD

            IF .NOT. EMPTY( EXPRDBF->FIELD )

               IF EXPRDBF->TYPE = "N"
                  cExpression := ALLTRIM( STR( ZIELDBF->&(ALLTRIM(EXPRDBF->FIELD)), 20, EXPRDBF->DECIMALS ) )
               ELSE
                  cExpression := ZIELDBF->&(ALLTRIM(EXPRDBF->FIELD))
               ENDIF

            ENDIF

            ZIELDBF->(DBCLOSEAREA())

         ENDIF

      ENDIF

   ENDIF

   EXPRDBF->(DBCLOSEAREA())
   SELECT( nAltSel )

RETURN ( cExpression )


*-- METHOD -------------------------------------------------------------------
*         Name: DelExpression
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD DelExpression( cName ) CLASS VRD

   LOCAL nAltSel
   LOCAL cGenExpr := ::cDataPath + GetPvProfString( "General", "GeneralExpressions", "", ::cDefIni )
 //  LOCAL cGenExpr := ::cDefaultPath + GetPvProfString( "General", "GeneralExpressions", "", ::cDefIni )

   DEFAULT cName := ""

   IF EMPTY( cGenExpr ) .OR. EMPTY( cName )
      RETURN ( .F. )
   ENDIF

   nAltSel := SELECT()
   SELECT 0
   USE ( VRD_LF2SF( cGenExpr ) ) ALIAS "GENEXPR" EXCLUSIVE

   LOCATE FOR GENEXPR->NAME = cName

   IF FOUND()
      DELETE
      PACK
   ENDIF

   GENEXPR->(DBCLOSEAREA())
   SELECT( nAltSel )

RETURN ( .T. )


*-- METHOD -------------------------------------------------------------------
*         Name: PageBreak
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PageBreak( lPrintArea ) CLASS VRD

   LOCAL i

   DEFAULT lPrintArea := .T.

   IF ::lBreak = .F. .AND. ::loPrnExist = .F.

      IF LEN( ::aPrBeforeBreak ) > 0
         FOR i := 1 TO LEN( ::aPrBeforeBreak )
            ::AreaStart2( ::aPrBeforeBreak[i], lPrintArea )
         NEXT
      ENDIF

      ::oPrn:EndPage()
      ::oPrn:StartPage()

      ::nLastRow := 0
      ::nNextRow := 0

      IF LEN( ::aPrAfterBreak ) > 0
         FOR i := 1 TO LEN( ::aPrAfterBreak )
            ::AreaStart2( ::aPrAfterBreak[i], lPrintArea )
         NEXT
      ENDIF

      IF ::lShowInfo = .T. .AND. ::lCheck = .F.
         ::oInfoSay:SetText( ::cInfoSay2 + " " + ALLTRIM(STR( ::oPrn:nPage, 3 )) )
      ENDIF

      ::lFirstAreaOnPage := .T.

   ENDIF

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: MsgError
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD MsgError( lQuit ) CLASS VRD

   LOCAL i
   LOCAL cErrorText := ""

   DEFAULT lQuit := .F.

   IF LEN( ::aErrors ) <> 0
      cErrorText := "EasyReport has detected the following errors:" + CRLF + ;
                    REPLICATE( "-", 100 ) + CRLF + ;
                    "Code" + CHR(9) + "Description" + CRLF + ;
                    REPLICATE( "-", 100 ) + CRLF
      FOR i := 1 TO LEN( ::aErrors )
         cErrorText += ::aErrors[i] + CRLF
      NEXT
      cErrorText += REPLICATE( "-", 100 )
      IF lQuit = .T.
         MsgStop( cErrorText )
         QUIT
      ELSE
         MsgInfo( cErrorText )
      ENDIF
   ENDIF

RETURN (.T.)


*-- METHOD -------------------------------------------------------------------
*         Name: CountItems
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD CountItems( nArea, nMode ) CLASS VRD

   LOCAL i, cItemDef
   LOCAL cAreaIni    := ::aAreaInis[ nArea ]
   LOCAL aIniEntries := ::GetIniItems( nArea )
   LOCAL nCount   := 0

   DEFAULT nMode := 1

   // nMode = 1 all items               (Entry 1 - 1000)
   // nMode = 2 developer defined items (Entry 1 - 399)
   // nMode = 3 user defined items      (Entry 400 - 1000)

   FOR i := IIF( nMode = 3, 400, 1 ) TO IIF( nMode = 2, 399, 1000 )

      cItemDef := GetIniEntry( aIniEntries, ALLTRIM(STR(i,5)) , "" )

      IF .NOT. EMPTY( cItemDef )
         ++nCount
      ENDIF

   NEXT

RETURN ( nCount )


*-- METHOD -------------------------------------------------------------------
*         Name: GetAllItemIDs
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GetAllItemIDs( nArea ) CLASS VRD

   LOCAL i, cItemDef
   LOCAL cAreaIni    := ::aAreaInis[ nArea ]
   LOCAL aIniEntries := ::GetIniItems( nArea )
   LOCAL aText       := {}

   FOR i := 1 TO 1000

      cItemDef := GetIniEntry( aIniEntries, ALLTRIM(STR(i,5)) , "" )

      IF .NOT. EMPTY( cItemDef )
         AADD( aText, { VAL( VRD_GetField( cItemDef, 3 ) ), VRD_GetField( cItemDef, 2 ) } )
      ENDIF

   NEXT

RETURN ( aText )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetTextWidth
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GetTextWidth( cText, oFont ) CLASS VRD

   LOCAL nWidth

   #IFDEF __HARBOUR__
      nWidth := ::oPrn:GetTextWidth( cText, oFont )
   #ELSE
      nWidth := ::oPrn:GetTextWid( cText, oFont )
   #ENDIF

RETURN ( nWidth )


*-- METHOD -------------------------------------------------------------------
*         Name: PrintDialog
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrintDialog() CLASS VRD

   LOCAL oDlg, oTitleFont, cTmpFile, oIni
   LOCAL lPrint      := .F.
   LOCAL aPrinters   := VRD_GetPrinters()
   LOCAL cPrinter    := IIF( EMPTY( ::cPrinter ), VRD_DefaultPrinter(), ::cPrinter )
   LOCAL nDlgTextCol := RGB( 255, 255, 255 )
   LOCAL nDlgBackCol := RGB( 150, 150, 150 )
   LOCAL cIni        := ".\VRD.INI"

   DEFINE FONT oTitleFont NAME "Arial" SIZE 0,-12

   DEFINE DIALOG oDlg FROM 0, 0 TO 220, 384 PIXEL TITLE VRD_GL("Print")

   @ 2, 4 GROUP TO 106, 132 PROMPT " " + VRD_GL("to Printer") OF oDlg PIXEL

   @ 10, 8 LISTBOX cPrinter SIZE 120, 100 OF oDlg PIXEL ITEMS aPrinters

   @ 98, 136 SAY VRD_GL("Copies") + ":" OF oDlg SIZE 35, 10 PIXEL RIGHT

   @ 96, 172 GET ::nCopies SIZE 16, 10 PIXEL OF oDlg VALID ::nCopies > 0 PICTURE "999" RIGHT //SPINNER MIN 1

   @  4, 138 BUTTON "&" + VRD_GL("Print") OF oDlg SIZE 50, 11 PIXEL ACTION ( ::lPreview := .F., oDlg:End(), lPrint := .T. )
   @ 17, 138 BUTTON VRD_GL("Preview")     OF oDlg SIZE 50, 11 PIXEL ACTION ( ::lPreview := .T., oDlg:End(), lPrint := .T. )
   @ 34, 138 BUTTON VRD_GL("&Cancel")     OF oDlg SIZE 50, 11 PIXEL ACTION oDlg:End()

   ACTIVATE DIALOG oDlg CENTERED

   #IFDEF __XPP__
      EnableWindow( hTmpWnd, 1 )
      SetForegroundWindow( hTmpWnd )
   #ENDIF

   IF lPrint = .T.
      ::cPrinter := cPrinter
   ENDIF

   oTitleFont:End()

RETURN ( lPrint )


*-- METHOD -------------------------------------------------------------------
*         Name: OpenDatabases
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD OpenDatabases() CLASS VRD

   LOCAL i, cDatabase, cDBName, cDBAlias, cDBType, cDBFilter, cFieldNames, cFieldPos
   LOCAL aIniEntries := GetIniSection( "Databases", ::cDefIni )
   LOCAL cSeparator  := ALLTRIM( GetIniEntry( aIniEntries, "Separator" , ";" ) )
   LOCAL nIndex      := 0

   ::aDBAlias       := {}
   ::aDBContent     := {}
   ::aDBType        := {}
   ::aDBRecords     := {}
   ::aDBPrevRecord  := {}
   ::aDBFilter      := {}
   ::aDBFieldNames  := {}
   ::aDBFieldPos    := {}
   ::lDelQuotations := ( GetIniEntry( aIniEntries, "DelQuotations", "0" ) = "1" )
   ::lUnix2Windows  := ( GetIniEntry( aIniEntries, "Unix2Windows" , "0" ) = "1" )

   FOR i := 1 TO 12

      cDatabase  := ALLTRIM( GetIniEntry( aIniEntries, ALLTRIM(STR( i, 5 )) , "" ) )

      cDBName     := ALLTRIM( VRD_GetField( cDatabase, 1 ) )
      cDBAlias    := ALLTRIM( VRD_GetField( cDatabase, 2 ) )
      cDBFilter   := ALLTRIM( VRD_GetField( cDatabase, 3 ) )
      cFieldNames := ALLTRIM( VRD_GetField( cDatabase, 4 ) )
      cFieldPos   := ALLTRIM( VRD_GetField( cDatabase, 5 ) )
      cDBType     := UPPER( cFileExt( cDatabase ) )

      IF FILE( VRD_LF2SF( cDBName ) )
         AADD( ::aDBAlias     , cDBAlias )
         AADD( ::aDBType      , cFileExt( cDatabase ) )
         AADD( ::aDBPrevRecord, NIL )
         AADD( ::aDBFilter    , cDBFilter )
         AADD( ::aDBFieldNames, cFieldNames )
         AADD( ::aDBFieldPos  , cFieldPos )
         AADD( ::aDBContent   , ::GetDBContent( cDBName, cDBAlias, cDBType, cSeparator, ++nIndex ) )
      ENDIF

   NEXT

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: GetDBContent
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GetDBContent( cDatabase, cDBAlias, cDBType, cSeparator, nIndex ) CLASS VRD

   LOCAL cLine, aFields, oText, aTemp
   LOCAL aContent   := {}
   LOCAL nFirstLine := .T.

   PRIVATE cRec

   IF cDBType = "DBF"

      DBUSEAREA( .T.,, cDatabase, cDBAlias )
      AADD( ::aDBRecords, LASTREC() )

   ELSE

      oText    := TTxtFile():New( cDatabase, 0 )
      aContent := {}

      oText:nMaxLineLength := 10000

      IF .NOT. EMPTY( ::aDBFieldNames[ nIndex ] )
         aFields := VRD_aToken( ::aDBFieldNames[ nIndex ], ";" )
         AEVAL( aFields, {|x,y| aFields[y] := ALLTRIM( x ) } )
         AADD( aContent, aFields )
      ENDIF

      WHILE !oText:lEof()

         cLine := oText:ReadLine()
         IF ::lUnix2Windows
            cLine := ::StrUnix2Win( cLine )
         ENDIF
         cRec  := cLine

         IF nFirstLine = .T. .AND. EMPTY( ::aDBFieldNames[ nIndex ] )

            aFields := VRD_aToken( cLine, cSeparator )
            AEVAL( aFields, {|x,y| aFields[y] := ALLTRIM( x ) } )
            AADD( aContent, aFields )
            nFirstLine := .F.

         ELSE

            IF .NOT. EMPTY( ::aDBFilter[ nIndex ] ) .AND. &( ::aDBFilter[ nIndex ] ) = .F.

            ELSEIF EMPTY( ::aDBFieldPos[ nIndex ] )

               AADD( aContent, VRD_aToken( cLine, cSeparator ) )

            ELSE

               aFields := VRD_aToken( ::aDBFieldPos[ nIndex ], ";" )
               aTemp   := {}
               AEVAL( aFields, {|x,y,n1,n2| ;
                                 n1 := VAL( VRD_GetField( x, 1, "-" ) ), ;
                                 n2 := VAL( VRD_GetField( x, 2, "-" ) ), ;
                                 AADD( aTemp, SUBSTR( cLine, n1, n2 - n1 ) ) } )
               AADD( aContent, aTemp )

            ENDIF

         ENDIF

         oText:Skip()

      END

      AADD( ::aDBRecords, LEN( aContent ) - 1 )

      oText:Close()

   ENDIF

RETURN ( aContent )


*-- METHOD -------------------------------------------------------------------
*         Name: StrUnix2Win
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD StrUnix2Win( cString ) CLASS VRD

RETURN STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN( ;
          cString, ;
          CHR(124),"ö"),CHR(126),"ß"),CHR(10)," "),CHR(123),"ä"),CHR(125),"ü"),CHR(93),"Ü")


*-- METHOD -------------------------------------------------------------------
*         Name: GetText
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD GetText( cTextFile, nRow, nCol, nColLast, nRowLast ) CLASS VRD

   LOCAL i, oText
   LOCAL cLine := ""

   DEFAULT nRow     := 1
   DEFAULT nRowLast := nRow
   DEFAULT nCol     := 1
   DEFAULT nColLast := 1

   nRowLast := MAX( nRowLast, nRow )
   nColLast := MAX( nColLast, nCol )

   IF FILE( cTextFile )

      oText := TTxtFile():New( cTextFile, 0 )

      oText:nMaxLineLength := 10000
      oText:Goto( nRow )

      FOR i := 1 TO nRowLast - nRow + 1

         cLine := ALLTRIM( SUBSTR( oText:ReadLine(), nCol, nColLast - nCol ) )
         IF ::lUnix2Windows
            cLine := ::StrUnix2Win( cLine )
         ENDIF

         oText:Goto( nRow + i )

      NEXT

      oText:Close()

   ENDIF

RETURN ( cLine )


*-- METHOD -------------------------------------------------------------------
*         Name: CloseDatabases
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD CloseDatabases() CLASS VRD

   AEVAL( ::aDBAlias, {|x,y| IIF( ::aDBType[y] = "DBF", ( x )->(DBCLOSEAREA()), ) } )
   SELECT( ::nOldSelect )

RETURN ( NIL )


*-- METHOD -------------------------------------------------------------------
*         Name: EvalDBFields
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD EvalDBFields( cSource, lGetString ) CLASS VRD

   LOCAL i, nPos1, nPos2, cValue, nValue, cDatabase, cField, nAlias, nFieldPos
   LOCAL nCount := VRD_StrCount( cSource, "[" )

   DEFAULT lGetString := .F.

   FOR i := 1 TO nCount

      nPos1 := AT( "[", cSource )
      nPos2 := AT( "]", cSource )

      cValue := ALLTRIM(SUBSTR( cSource, nPos1+1, nPos2-nPos1-1 ))

      IF cValue <> "[1]" .AND. cValue <> "[2]"

         nValue := AT( ":", cValue )

         IF nValue <> 0

            cDatabase := SUBSTR( cValue, 1, nValue - 1 )
            cField    := SUBSTR( cValue, nValue + 1, LEN( cValue ) - nValue )
            nAlias    := ASCAN( ::aDBAlias, cDatabase )

            IF nAlias <> 0 .AND. ::aDBType[ nAlias ] = "DBF"

               //from DBF file
               SELECT( ::aDBAlias[ nAlias ] )
               GOTO ::nDBFRecord

               nFieldPos := FIELDPOS( cField )

               IF nFieldPos <> 0
                  IF lGetString = .T.
                     cSource := VRD_XTOC( FIELDGET( nFieldPos ) )
                  ELSE
                     cSource := SUBSTR( cSource, 1, nPos1-1 ) + ;
                                '"' + VRD_XTOC( FIELDGET( nFieldPos ) ) + '"' + ;
                                SUBSTR( cSource, nPos2+1 )
                  ENDIF
               ENDIF

            ELSEIF nAlias <> 0

               //from text file
               nFieldPos := ASCAN( ::aDBContent[nAlias,1], cField )

               IF nFieldPos <> 0
                  IF lGetString = .T.
                     //msginfo( ::aDBContent[nAlias,2][2] )
                     //msginfo( ::nDBFRecord )
                     //::nDBFRecord := 1
                     cSource := ::DelQuotations( ::aDBContent[nAlias,::nDBFRecord+1][nFieldPos] )
                  ELSE
                     cSource := SUBSTR( cSource, 1, nPos1-1 ) + ;
                                '"' + ::DelQuotations( ::aDBContent[nAlias,::nDBFRecord+1][nFieldPos] ) + '"' + ;
                                SUBSTR( cSource, nPos2+1 )
                  ENDIF
               ENDIF

            ENDIF

         ENDIF

      ENDIF

   NEXT

RETURN ( cSource )


*-- METHOD -------------------------------------------------------------------
*         Name: DelQuotations
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD DelQuotations( cOriginal ) CLASS VRD

   LOCAL nPos
   LOCAL cText := ALLTRIM( cOriginal )

   IF ::lDelQuotations = .F.
      RETURN ( cOriginal )
   ENDIF

   IF SUBSTR( cText, 1, 1 ) = "'" .OR. SUBSTR( cText, 1, 1 ) = '"'
      cText := SUBSTR( cText, 2 )
   ENDIF
   IF SUBSTR( cText, LEN( cText ) ) = "'" .OR. SUBSTR( cText, LEN( cText ) ) = '"'
      cText := SUBSTR( cText, 1, LEN( cText ) - 1 )
   ENDIF

RETURN ( cText )


*-- METHOD -------------------------------------------------------------------
*         Name: DBSum
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD DBSum( cDatabase, cField, nLen, nDec, cFor, lPrevious, lCount ) CLASS VRD

   LOCAL i, nOldRec, nFieldPos, cForValue
   LOCAL nAlias := ASCAN( ::aDBAlias, cDatabase )
   LOCAL nSum   := 0

   DEFAULT nLen      := 20
   DEFAULT nDec      := 2
   DEFAULT cFor      := ""
   DEFAULT lPrevious := .F.
   DEFAULT lCount    := .F.

   IF nAlias <> 0 .AND. ::aDBType[ nAlias ] = "DBF"

      //from DBF
      SELECT( ::aDBAlias[ nAlias ] )

      IF lCount = .F.

         IF .NOT. EMPTY( cFor )
            IF lPrevious = .T. .AND. RECNO() > 1
               DBSKIP(-1)
            ENDIF
            cForValue := &( cFor )
         ENDIF

         nOldRec := RECNO()
         GO TOP
         nFieldPos := FIELDPOS( cField )

         DO WHILE .NOT. EOF()
            IF EMPTY( cFor ) .OR. &( cFor ) = cForValue
               nSum += VAL( VRD_XTOC( FIELDGET( nFieldPos ) ) )
            ENDIF
            DBSKIP()
         ENDDO

         GOTO nOldRec

      ELSE
         nSum := LASTREC()
      ENDIF

   ELSEIF nAlias <> 0

      //from text file
      IF lCount = .F.

         nFieldPos := ASCAN( ::aDBContent[nAlias,1], cField )

         IF .NOT. EMPTY( cFor )
            cForValue := EVAL( &( "{ | oPrn, oVRD, oInfo, nCurRecNo |" + ALLTRIM( cFor ) + " }" ), ;
               ::oPrn, SELF, ::oInfo, ::nDBFRecord - IIF( lPrevious = .T. .AND. ::nDBFRecord > 1, 1, 0 ) )
         ENDIF

         FOR i := 1 TO Len( ::aDBContent[nAlias] )
            IF EMPTY( cFor ) .OR. ;
               EVAL( &( "{ | oPrn, oVRD, oInfo, nCurRecNo |" + ALLTRIM( cFor ) + " }" ), ::oPrn, SELF, ::oInfo, i ) = cForValue
               nSum += VAL( ::DelQuotations( ::aDBContent[nAlias][i,nFieldPos] ) )
            ENDIF
         NEXT

         //FOR i := 1 TO Len( ::aDBContent[nAlias] )
         //   IF EMPTY( cFor ) .OR. ;
         //      EVAL( &( "{ | oPrn, oVRD, oInfo, nCurRecNo |" + ALLTRIM( cFor ) + " }" ), ::oPrn, SELF, ::oInfo, i ) = cForValue
         //      nSum += VAL( ::DelQuotations( ::aDBContent[nAlias][i,nFieldPos] ) )
         //   ENDIF
         //NEXT

      ELSE
         nSum := LEN( ::aDBContent[nAlias] )
      ENDIF

   ENDIF


RETURN ( ALLTRIM( STR( nSum, nLen, nDec ) ) )


*-- METHOD -------------------------------------------------------------------
*         Name: DBCount
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD DBCount( cDatabase, cFor ) CLASS VRD

RETURN ::DBSum( cDatabase, "", 20, 0, cFor, .T. )


*-- METHOD -------------------------------------------------------------------
*         Name: DBValue
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD DBValue( cField, cDatabase, lPrevious ) CLASS VRD

   LOCAL nFieldPos, nOldRec, nField, nOldSel, nAlias
   LOCAL cReturn := ""

   DEFAULT cDatabase := ""
   DEFAULT lPrevious := .F.

   IF EMPTY( cDatabase )
      nAlias := ::aControlDBF[ ::nCurArea ]
   ELSE
      nAlias := ASCAN( ::aDBAlias, cDatabase )
   ENDIF

   IF nAlias <> 0

      IF ::aDBType[ nAlias ] = "DBF"

         nOldSel := SELECT()
         SELECT( ::aDBAlias[ nAlias ] )

         nOldRec := RECNO()
         GOTO ::nDBFRecord

         nFieldPos := FIELDPOS( cField )

         IF nFieldPos <> 0
            IF lPrevious = .F.
               cReturn := VRD_XTOC( FIELDGET( nFieldPos ) )
            ELSEIF EMPTY( ::aDBPrevRecord[ nAlias ] ) = .F.
               cReturn := VRD_XTOC( ::aDBPrevRecord[ nAlias, nFieldPos ] )
            ENDIF
         ENDIF

         GOTO nOldRec
         SELECT( nOldSel )

      ELSE

         nFieldPos := ASCAN( ::aDBContent[nAlias,1], cField )
         IF nFieldPos <> 0
            IF lPrevious = .F.
               cReturn := ::aDBContent[nAlias,::nDBFRecord+1][nFieldPos]
            ELSE
               cReturn := ::aDBPrevRecord[ nAlias, nFieldPos ]
            ENDIF
         ENDIF

      ENDIF

   ENDIF

RETURN IIF( EMPTY( cReturn ), IIF( lPrevious, "NOPREVIOUS", "NOCURRENT" ), cReturn )


*-- METHOD -------------------------------------------------------------------
*         Name: DBPrevValue
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD DBPrevValue( cField, cDatabase ) CLASS VRD

RETURN ::DBValue( cField, cDatabase, .T. )


*-- METHOD -------------------------------------------------------------------
*         Name: CheckPath
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD CheckPath( cPath ) CLASS VRD

   cPath := ALLTRIM( cPath )

   IF .NOT. EMPTY( cPath ) .AND. SUBSTR( cPath, LEN( cPath ) ) <> "\"
      cPath += "\"
   ENDIF

RETURN cPath


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_GL
* Beschreibung: Get Language
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_GL( cOriginal )

   LOCAL nPos
   LOCAL cText := cOriginal

   IF nLanguage > 1
      nPos  := ASCAN( aLanguages, { |aVal| ALLTRIM( aVal[1] ) == ALLTRIM( cOriginal ) } )
      cText := IIF( nPos <> 0, STRTRAN( ALLTRIM( aLanguages[nPos,nLanguage] ), "_", " " ), ;
                               cOriginal )
   ENDIF

RETURN ( cText )


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_GetField
* Beschreibung:
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_GetField( cString, nNr, cSepChar )

   DEFAULT cSepChar := "|"

RETURN StrToken( cString, nNr, cSepChar )


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_SetField
* Beschreibung:
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_SetField( cString, cSetStr, nNr )

   LOCAL cSepChar := "|"
   LOCAL cOldStr  := StrToken( cString, nNr, cSepChar )

RETURN StrToken( cString, nNr, cSepChar )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetIniSection
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetIniSection( cSection, cIniFile, lSort )

   LOCAL p
   LOCAL aEntries := {}
   LOCAL nBuffer :=  32000 //8192
   LOCAL cBuffer := Space( nBuffer )

   DEFAULT lSort := .T.

   if At( ".", cIniFile ) == 0
      cIniFile += ".ini"
   endif

   GetPPSection( cSection, @cBuffer, nBuffer, cIniFile )

   WHILE ( p := At( Chr( 0 ), cBuffer ) ) > 1
      AAdd( aEntries, Left( cBuffer, p - 1 ) )
      cBuffer = SubStr( cBuffer, p + 1 )
   ENDDO

   IF lSort = .T.
      ASORT( aEntries,,, {|x,y| VAL( SUBSTR( x, 1, AT( "=", x ) - 1 ) ) < ;
                                VAL( SUBSTR( y, 1, AT( "=", y ) - 1 ) ) } )
   ENDIF

RETURN aEntries


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetIniEntry
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetIniEntry( aEntries, cEntry, uDefault, uVar, nIndex )

   LOCAL cType  := ValType( If( uDefault != nil, uDefault, uVar ) )

   IF nIndex = NIL
      nIndex := ASCAN( aEntries, {|x| SUBSTR( x, 1, AT( "=", x ) - 1 ) == cEntry } )
   ENDIF

   IF nIndex = 0

      IF uDefault = nil
         uVar := ""
      ELSE
         uVar := uDefault
      ENDIF

   ELSE

      uVar := aEntries[ nIndex ]
      uVar := SUBSTR( uVar, AT( "=", uVar ) + 1 )

      DO CASE
      CASE cType == "N"
         uVar = VAL( uVar )
      CASE cType == "D"
         uVar = CToD( uVar )
      CASE cType == "L"
         uVar = ( Upper( uVar ) == ".T." )
      endcase

   ENDIF

RETURN uVar


*-- FUNCTION -----------------------------------------------------------------
* Name........: EntryNr
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EntryNr( cString )

RETURN VAL( SUBSTR( cString, 1, AT( "=", cString ) - 1 ) )


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_PrintReport
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_PrReport( cReportName, lPreview, cPrinter, oWnd, lModal, lPrintIDs, lNoPrint, ;
                       lNoExpr, cFilePath, lPrintDialog, nCopies, lCheck, bReportSource, ;
                       cTitle, cPreviewDir, lAutoBreak )

   LOCAL oVRD
   LOCAL oInfo := VRD_NewStructure()

   DEFAULT lCheck := .F.

   oInfo:AddMember( "nPages",, 0 )

   IF lCheck = .T.

      oVRD := VRD():New( cReportName,,, oWnd,,,,,,,, lCheck,,, cTitle, cPreviewDir, lAutoBreak )

      EVAL( bReportSource, oVRD )

      IF oVRD:lDialogCancel = .T.
         RETURN( .F. )
      ENDIF

      oInfo := oVRD:End()

   ENDIF

   oVRD := VRD():New( cReportName, lPreview, cPrinter, oWnd, lModal, lPrintIDs, lNoPrint, ;
                      lNoExpr, cFilePath, lPrintDialog, nCopies,,,,, cPreviewDir, lAutoBreak )

   IF oVRD:lDialogCancel = .T.
      RETURN( .F. )
   ENDIF

   oVRD:oInfo := oInfo

   EVAL( bReportSource, oVRD )

   oVRD:End()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_GetGroup
* Description.: get all report titles and/or report files of a certain report group
* Parameters..: cGroup  the name of the group (if empty or NIL = all reports)
*               nMode   determines the return value (optional, default: 0)
*                       0 = two demensional array ({ report title, report file })
*                       1 = an array with all report titles
*                       2 = an array with all report file names
*               cPath   path where the reports lie (optional, default: current path)
*               cExt    extension of the general report files (optional, default: vrd)
* Return value: array
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_GetGroup( cGroup, nMode, cPath, cExt )

   LOCAL i, aFiles, cCurGroup, cCurFile, cTitle
   LOCAL aReturn := {}

   DEFAULT cGroup := ""
   DEFAULT nMode  := 0
   DEFAULT cExt   := "VRD"

   IF cPath = NIL .OR. EMPTY( cPath )
      cPath := ".\"
   ELSE
      cPath := cPath + "\"
   ENDIF

   aFiles := DIRECTORY( VRD_LF2SF( cPath ) + "*." + cExt, "D" )

   FOR i := 1 TO LEN( aFiles )

      cCurFile  := cPath + aFiles[i,1]
      cCurGroup := GetPvProfString( "General", "Group", "", cCurFile )
      cTitle    := GetPvProfString( "General", "Title", "", cCurFile )

      IF EMPTY( cGroup ) .OR. UPPER( cGroup ) == UPPER( cCurGroup )

         IF nMode = 1
            //Titles
            AADD( aReturn, cTitle )
         ELSEIF nMode = 2
            //File names
            AADD( aReturn, cCurFile )
         ELSE
            //both
            AADD( aReturn, { cTitle, cCurFile } )
         ENDIF

      ENDIF

   NEXT

RETURN ( aReturn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_LF2SF
* Beschreibung: Long file to short file with path
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_LF2SF( cFile )

   #IFDEF __HARBOUR__
      RETURN( VRD_GetFullPath( AllTrim( cFile ) ) )
      //RETURN( cFile )
   #ELSE
      #IFDEF __XPP__
         RETURN( VRD_GetFullPath( AllTrim( cFile ) ) )
         //RETURN( cFile )
      #ELSE
         RETURN IIF( EMPTY( cFile ), "", VRD_LPN2SPN( VRD_GetFullPath( ALLTRIM( cFile ) ) ) )
      #ENDIF
   #ENDIF

RETURN NIL

#IFNDEF __HARBOUR__
#IFNDEF __XPP__


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_LPN2SPN
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_LPN2SPN( cLPN )

   LOCAL cSPN:="", I, II := 1
   LOCAL lIsLastBackSlash := .T.

   IF RAT( "\", cLPN ) < LEN( ALLTRIM( cLPN ) )
      cLPN = ALLTRIM( cLPN ) + "\"
      lIsLastBackSlash := .F.
   ENDIF

   IF SUBSTR( cLPN, 2, 1 ) = ":"
      cSPN += SUBSTR( cLPN, 1, AT( "\", cLPN ) )
      ii := 2
   ENDIF

   FOR I := 4 TO LEN( cLPN )
      IF SUBSTR( cLPN, I, 1 ) = "\"
         cSPN += VRD_LFN2SFN( cSPN + STRTOKEN( cLPN, ii, "\" ) )
         cSPN += "\"
         ii++
      ENDIF
   NEXT

   IF !lIsLastBackSlash
      cSPN := SUBSTR( cSPN, 1, LEN( cSPN ) -1 )
   ENDIF

RETURN cSPN


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_LFN2SFN
* Beschreibung: Long File Name to Short File Name (works with short too)
*               Guarantee a short file name (path not expanded)
*-----------------------------------------------------------------------------
FUNCTION VRD_LFN2SFN( cSpec )

   LOCAL oWin32, c, h

   STRUCT oWin32
      MEMBER nFileAttributes  AS DWORD
      MEMBER nCreation        AS STRING LEN 8
      MEMBER nLastRead        AS STRING LEN 8
      MEMBER nLastWrite       AS STRING LEN 8
      MEMBER nSizeHight       AS DWORD
      MEMBER nSizeLow         AS DWORD
      MEMBER nReserved0       AS DWORD
      MEMBER nReserved1       AS DWORD
      MEMBER cFileName        AS STRING LEN 260
      MEMBER cAltName         AS STRING LEN  14
   ENDSTRUCT

   c := oWin32:cBuffer
   h := apiFindFst(cSpec,@c)
   oWin32:cBuffer := c

   apiFindCls(h)

RETURN if(empty(psz(oWin32:cAltName)),psz(oWin32:cFileName),psz(oWin32:cAltName))


*-- FUNCTION -----------------------------------------------------------------
*         Name: psz
*  Description: Truncate a zero-terminated string to a proper size
*    Arguments: cZString - string containing zeroes
* Return Value: cString  - string without zeroes
*-----------------------------------------------------------------------------
FUNCTION psz(c)
RETURN substr(c,1,at(chr(0),c)-1)


#ENDIF
#ENDIF

*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_GetFullPath
* Beschreibung: Short File Name to Long Path Name (works with long too)
*               Returns a complete, LONG pathname and LONG filename.
*-----------------------------------------------------------------------------
Function VRD_GetFullPath( cSpec )

   LOCAL cLongName := Space(261)
   LOCAL nNamePos  := 0

   FullPathName( cSpec, Len( cLongName ), @cLongName, @nNamePos )

RETURN ALLTRIM( cLongName )


//for access to the windows registry
#DEFINE HKEY_CLASSES_ROOT           2147483648
#DEFINE HKEY_CURRENT_USER           2147483649
#DEFINE HKEY_LOCAL_MACHINE          2147483650
#DEFINE HKEY_USERS                  2147483651
#DEFINE HKEY_PERFORMANCE_DATA       2147483652
#DEFINE HKEY_CURRENT_CONFIG         2147483653
#DEFINE HKEY_DYN_DATA               2147483654
#DEFINE KEY_QUERY_VALUE              1
#DEFINE KEY_SET_VALUE                2
#DEFINE KEY_CREATE_SUB_KEY           4
#DEFINE KEY_ENUMERATE_SUB_KEYS       8
#DEFINE KEY_NOTIFY                  16
#DEFINE KEY_CREATE_LINK             32
#DEFINE KEY_ALL_ACCESS              63


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_GetPrinters
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Juan Gálvez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_GetPrinters()

   LOCAL cName, nWert
   LOCAL nPos      := 0
   LOCAL aPrinters := {}
   LOCAL cEntries  := GetProfString( "Devices" )

   WHILE !Empty( cName := VRD_TakeOut( cEntries, ++nPos, Chr(0) ) )
      nWert := AT( "=", cName )
      AAdd( aPrinters, IIF( nWert = 0, cName, SUBSTR( cName, 1, nWert - 1 ) ) )
   END

RETURN aPrinters


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_TakeOut
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Juan Gálvez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_TakeOut( cString, nPos, cChar )

   LOCAL nLen
   LOCAL cReturn := ''
   DEFAULT cChar := ' '

   IF nPos > 0
      nLen    := Len( cChar )
      cString += Replicate( cChar, nPos )
      WHILE --nPos > 0
         cString := SubStr( cString, At( cChar, cString ) + nLen )
      END
      cReturn := Left( cString, At( cChar, cString ) - 1 )
   ENDIF

RETURN cReturn


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_DefaultPrinter
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_DefaultPrinter()

#IFDEF __XPP__
/// !!! Antonio muß PrnGetName in FW++ einbauen
RETURN VRD_GetRegistry( HKEY_CURRENT_CONFIG, ;
                        "System\CurrentControlSet\Control\Print\Printers", ;
                        "Default" )
#ELSE

RETURN PrnGetName()

#ENDIF


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_GetRegistry
* Beschreibung: Read values from the Windows Registry database
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_GetRegistry( nHKEY, cKey, cEntry )

   LOCAL cName   := ""            // All parameters passed to
   LOCAL nSize   := 0             // API functions must have
   LOCAL nHandle := 0             // a value not equal to NIL
   LOCAL nType   := 0
   LOCAL nRet

   // Open Registry key
   nRet := RegOpenKeyExA( nHKEY, cKey, 0, KEY_ALL_ACCESS, @nHandle )

   IF nRet <> 0
      RETURN cName
   ENDIF

   // Determine size and type of the entry
   RegQueryValueExA( nHandle, cEntry, 0, @nType , @cName, @nSize  )

   IF nSize > 0

      // Prepare empty string. It is passed by reference to the
      // API and contains the result afterwards
      cName := Space( nSize-1 )

      RegQueryValueExA( nHandle, cEntry, 0, nType, @cName, @nSize )

   ENDIF

   // Close Registry key
   RegCloseKey( nHandle )

RETURN cName


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_StrCount
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_StrCount( cText, cString )

   LOCAL i
   LOCAL nCount := 0

   FOR i := 1 TO LEN( ALLTRIM( cText ) )
      IF SUBSTR( cText, i, LEN( cString ) ) == cString
         ++nCount
      ENDIF
   NEXT

RETURN ( nCount )


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_aToken
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_aToken( cString, cSeparator )

   LOCAL nPos
   LOCAL aString := {}

   DEFAULT cSeparator := ";"

   cString := ALLTRIM( cString ) + cSeparator

   DO WHILE .T.

      nPos := AT( cSeparator, cString )

      IF nPos = 0
         EXIT
      ENDIF

      AADD( aString, SUBSTR( cString, 1, nPos-1 ) )
      cString := SUBSTR( cString, nPos+1 )

   ENDDO

RETURN ( aString )


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_NewStructure
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_NewStructure()

   LOCAL oStruct

   #IFDEF __XPP__
      oStruct := TStruct():New() // !!! Hier muß TExStruct einbaut werden
   #ELSE
      #IFDEF USE_TEXSTRUC
         oStruct := TExStruc():New()
      #ELSE
         oStruct := TExStruct():New()
      #ENDIF
   #ENDIF

RETURN oStruct


*-- FUNCTION -----------------------------------------------------------------
* Name........: VRD_XTOC
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION VRD_XTOC( cValue )

   LOCAL cReturn  := ""
   LOCAL cValType := VALTYPE( cValue )

   IF cValType $ "CM"
      cReturn := ALLTRIM( cValue )
   ELSEIF cValType = "N"
      cReturn := ALLTRIM(STR( cValue ))
   ELSEIF cValType = "D"
      cReturn := DTOC( cValue )
   ELSEIF cValType = "L"
      cReturn := IIF( cValue, ".T.", ".F." )
   ENDIF

RETURN ( cReturn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: ERStart
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION vrd_ERStart( cRptFile, lPreview ) // FiveTech

   DEFAULT lPreview := .F.

   ShellExecute( 0, "Open", "ERSTART.EXE", ;
      cRptFile + IIF( lPreview, " PREVIEW", " PRINTDIALOG" ), NIL, 1 )

RETURN ( NIL )


#IFDEF __XPP__

#define  DLL_STDCALL             32

// DLLFUNCTION command
#command  DLLFUNCTION <Func>([<x,...>]) ;
                USING <sys:CDECL,OSAPI,STDCALL,SYSTEM> ;
                 FROM <(Dll)> ;
       => ;
             FUNCTION <Func>([<x>]);;
                LOCAL nDll:=DllLoad(<(Dll)>);;
                LOCAL xRet:=DllCall(nDll,__Sys(<sys>),<(Func)>[,<x>]);;
                      DllUnLoad(nDll);;
               RETURN xRet

#xtrans __Sys( CDECL )     =>   DLL_CDECL
#xtrans __Sys( OSAPI )     =>   DLL_OSAPI
#xtrans __Sys( STDCALL )   =>   DLL_STDCALL
#xtrans __Sys( SYSTEM )    =>   DLL_SYSTEM

#xcommand FUNCTION <Func>([<x1,...>] @ [<x2,...>]) ;
       => FUNCTION <Func>([<x1>][<x2>])

FUNCTION ApiFindFst( lpFilename, cWin32DataInfo )
RETURN   FindFirstFileA( lpFilename, @cWin32DataInfo )

DLLFUNCTION FindFirstFileA( lpFilename, @cWin32DataInfo ) USING STDCALL FROM KERNEL32.DLL

FUNCTION apiFindCls( nHandle )
RETURN   FindClose( nHandle )

DLLFUNCTION FindClose( nHandle ) USING STDCALL FROM KERNEL32.DLL

// FUNCTION GetPPSection( cSection, cData, nSize, cFile )
// RETURN   GetPrivateProfileSectionA( cSection, @cData, nSize, cFile )

DLLFUNCTION GetPrivateProfileSectionA( cSection, @cData, nSize, cFile ) ;
            USING STDCALL FROM KERNEL32.DLL

FUNCTION GetPvProfString( cSection, cData, cDefault, cFile )
RETURN   GETPVPROFS( cSection, cData, cDefault, cFile )

FUNCTION FullPathName( lpszFile, cchPath, lpszPath, nFilePos )
RETURN   GetFullPathNameA( lpszFile, cchPath, lpszPath, @nFilePos )

DLLFUNCTION GetFullPathNameA( lpszFile, cchPath, lpszPath, @nFilePos ) ;
            USING STDCALL FROM KERNEL32.DLL

FUNCTION DelFile( cFileName )
RETURN   DeleteFileA( cFileName )

DLLFUNCTION DeleteFileA( cFileName ) USING STDCALL FROM KERNEL32.DLL

FUNCTION GetProfString( cSection )

   LOCAL nBuffer :=  32000
   LOCAL cBuffer := Space( nBuffer )
   GetProfileSectionA( cSection, @cBuffer, nBuffer )

RETURN cBuffer

DLLFUNCTION GetProfileSectionA( cSection, @cBuffer, nSize ) USING STDCALL FROM KERNEL32.DLL

FUNCTION WritePProString( cSection, cEntry, cValue, cFile )
RETURN   WritePrivateProfileStringA( cSection, cEntry, cValue, cFile )

DLLFUNCTION WritePrivateProfileStringA( cSection, cEntry, cValue, cFile ) USING STDCALL FROM KERNEL32.DLL

DLLFUNCTION RoundRect( hDC, nLeft, nTop, nRight, nBottom, nWidth, nHeight ) ;
            USING STDCALL FROM GDI32.DLL

DLLFUNCTION SetTextJustification( hDC, nExtraSpace, nBreakChars ) USING STDCALL FROM GDI32.DLL

DLLFUNCTION CreateSolidBrush( nColor ) USING STDCALL FROM GDI32.DLL

DLLFUNCTION CreatePen( nPenStyle, nWidth, nColor ) USING STDCALL FROM GDI32.DLL

DLLFUNCTION SelectObject( hDC, hObject ) USING STDCALL FROM GDI32.DLL

DLLFUNCTION DeleteObject( hObject ) USING STDCALL FROM GDI32.DLL

DLLFUNCTION RegOpenKeyExA( nHkeyClass, cKeyName, nReserved, nAccess, @nKeyHandle ) ;
            USING STDCALL FROM ADVAPI32.DLL

DLLFUNCTION RegQueryValueExA( nKeyHandle, cEntry, nReserved, @nType, @cName, @nSize ) ;
            USING STDCALL FROM ADVAPI32.DLL

DLLFUNCTION RegCloseKey( nKeyHandle ) USING STDCALL FROM ADVAPI32.DLL

DLLFUNCTION BringWindowToTop( hWnd )    USING STDCALL FROM USER32.DLL
DLLFUNCTION SetFocus( hWnd )            USING STDCALL FROM USER32.DLL
DLLFUNCTION SetForegroundWindow( hWnd ) USING STDCALL FROM USER32.DLL
DLLFUNCTION SetCapture( hWnd )          USING STDCALL FROM USER32.DLL
DLLFUNCTION ReleaseCapture()            USING STDCALL FROM USER32.DLL
DLLFUNCTION EnableWindow( hWnd, cEnable )         USING STDCALL FROM USER32.DLL
DLLFUNCTION SetParent( hWndChild, hWndNewParent ) USING STDCALL FROM USER32.DLL

DLLFUNCTION GetStockObject( nIndex )    USING STDCALL FROM GDI32.DLL

EXIT PROCEDURE CloseTmpWnd()

   IF oTmpWnd <> nil
     oTmpWnd:End()
   ENDIF

RETURN

#ELSE

DLL32 Function apiFindFst(lpFilename AS LPSTR, @cWin32DataInfo AS LPSTR) AS LONG PASCAL ;
   FROM "FindFirstFileA" LIB "KERNEL32.DLL"

DLL32 Function apiFindCls(nHandle AS LONG) AS BOOL PASCAL ;
   FROM "FindClose" LIB "KERNEL32.DLL"

DLL32 FUNCTION GetPPSection( cSection AS LPSTR, @cData AS LPSTR, ;
                             nSize AS DWORD, cFile AS LPSTR ) ;
   AS DWORD PASCAL ;
   FROM "GetPrivateProfileSectionA" ;
   LIB "Kernel32.dll"

DLL32 Function FullPathName( lpszFile AS LPSTR, cchPath AS DWORD,;
               lpszPath AS LPSTR, @nFilePos AS PTR ) AS DWORD ;
               PASCAL FROM "GetFullPathNameA" LIB "kernel32.dll"

DLL32 FUNCTION MoveFile( Source_file AS LPSTR, Target_file AS LPSTR ) ;
   AS BOOL FROM "MoveFileA" LIB "Kernel32.dll"

DLL32 FUNCTION DelFile( cFileName AS LPSTR ) ;
   AS BOOL PASCAL FROM "DeleteFileA" LIB "kernel32.dll"

//DLL32 FUNCTION RoundRect( hDC AS LONG, nLeft AS LONG, nTop AS LONG, nRight AS LONG, ;
//                          nBottom AS LONG, nWidth AS LONG, nHeight AS LONG ) ;
//   AS LONG PASCAL LIB "GDI32"

DLL32 FUNCTION RegOpenKeyExA( nhKey     AS LONG   , ;
                              cAddress  AS LPSTR  , ;
                              nReserved AS LONG   , ;
                              nSecMask  AS LONG   , ;
                              @nphKey   AS PTR    ) ;
         AS LONG PASCAL LIB "ADVAPI32.DLL"

DLL32 FUNCTION RegQueryValueExA( nhKey      AS LONG   , ;
                                 cAddress   AS LPSTR  , ;
                                 nReserved  AS LONG   , ;
                                 @nType     AS PTR    , ;
                                 @cResult   AS LPSTR  , ;
                                 @nResSize  AS PTR    ) ;
         AS LONG PASCAL LIB "ADVAPI32.DLL"

DLL32 FUNCTION RegCloseKey( nhKey AS LONG ) AS LONG PASCAL LIB "ADVAPI32.DLL"

#ENDIF