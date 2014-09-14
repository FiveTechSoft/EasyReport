
#INCLUDE "FiveWin.ch"
#INCLUDE "VRD.ch"
#INCLUDE "TSButton.ch"

STATIC cIni    := ".\EXAMPLE.INI"
STATIC nReport := 1

STATIC oWnd, aOutFiles, aFont[3]

*-- FUNCTION -----------------------------------------------------------------
* Name........: Start
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION Start()

   LOCAL oBmp, oBrush

   SET DELETED ON
   SET CONFIRM ON
   SET 3DLOOK ON
   SET MULTIPLE OFF
   SET DATE FORMAT TO "dd.mm.yyyy"
   SET EPOCH TO 1960

   SetHandleCount(100)

   EP_TidyUp()
   EP_SetPath( ".\" )

   SET HELPFILE TO ".\HELP\DEVELOP.HLP"

   DEFINE BRUSH oBrush RESOURCE "BRUSH"

   DEFINE WINDOW oWnd FROM 2, 3 TO 28, 85 ;
      TITLE "EasyReport - The Visual Report Designer - Example application" ;
      BRUSH oBrush

   @ 20, 20 BITMAP oBmp RESOURCE "Logo" OF oWnd PIXEL

   SET MESSAGE OF oWnd TO "Sodtalbers+Partner - www.reportdesigner.info" CENTERED KEYBOARD DATE

   ACTIVATE WINDOW oWnd MAXIMIZED ON INIT StartDialog()

   oBrush:End()
   oBmp:End()
   AEVAL( aFont, {|x| x:End() } )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: StartDialog
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION StartDialog()

   LOCAL oDlg, oRad1, aBtn[4], aSay[1]
   LOCAL cText1 := CRLF + ;
                   "   Welcome!" + CRLF
   LOCAL cText2 := "    With this example application you get an idea of how EasyReport"    + CRLF + ;
                   "    works. Please let us know if you have any questions or suggestions."
   LOCAL cText3 := CHR(9) + CHR(9) + CHR(9) + CHR(9) + CHR(9) + CHR(9) + "Timm Sodtalbers" + CRLF + ;
                   CHR(9) + CHR(9) + CHR(9) + CHR(9) + CHR(9) + CHR(9) + "Sodtalbers+Partner"

   DEFINE FONT aFont[1] NAME "ARIAL" SIZE 0,-12
   DEFINE FONT aFont[2] NAME "ARIAL" SIZE 0,-14
   DEFINE FONT aFont[3] NAME "ARIAL" SIZE 0,-18 BOLD ITALIC

   DEFINE DIALOG oDlg NAME "EXAMPLE"

   REDEFINE SBUTTON ID 101 OF oDlg ACTION ( oDlg:End(), oWnd:End() )

   REDEFINE SAY PROMPT cText1 ID 201 OF oDlg FONT aFont[3] COLOR RGB( 255, 255, 255 ), RGB( 94, 129, 165 )
   REDEFINE SAY PROMPT cText2 ID 202 OF oDlg FONT aFont[2] COLOR RGB( 255, 255, 255 ), RGB( 94, 129, 165 )
   REDEFINE SAY PROMPT cText3 ID 203 OF oDlg FONT aFont[2] COLOR RGB( 255, 255, 255 ), RGB( 94, 129, 165 )

   REDEFINE RADIO oRad1 VAR nReport ID 401, 402, 403, 404, 405, 406, 407 OF oDlg

   REDEFINE SBUTTON aBtn[3] RESOURCE "B_OPEN"    PROMPT "&Design"     FONT aFont[1] ID 104 OF oDlg ACTION ReportExec( 1 )
   REDEFINE SBUTTON aBtn[4] RESOURCE "B_EDIT"    PROMPT "&Sourcecode" FONT aFont[1] ID 105 OF oDlg ACTION ReportExec( 2 )
   REDEFINE SBUTTON aBtn[2] RESOURCE "B_PREVIEW" PROMPT "Pre&view"    FONT aFont[1] ID 103 OF oDlg ACTION PrintChoice(oDlg, .T. )
   REDEFINE SBUTTON aBtn[1] RESOURCE "B_PRINT"   PROMPT "&Print"      FONT aFont[1] ID 102 OF oDlg ACTION PrintChoice(oDlg )

   REDEFINE SBUTTON ID 111 OF oDlg ACTION OpenHtmlHelp()

   REDEFINE SAY ID 171 OF oDlg COLOR 0, oDlg:nClrPane
   REDEFINE SAY ID 172 OF oDlg COLOR 0, oDlg:nClrPane

   AEVAL( aBtn, { | oBtn | oBtn:SetFont( aFont[1] ) } )

   ACTIVATE DIALOG oDlg CENTERED NOMODAL

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ReportExec
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ReportExec( nTyp )

   LOCAL cReportName

   DO CASE
   CASE nReport = 1
      cReportName := ".\examples\StandaloneExample1.vrd"
   CASE nReport = 2
      cReportName := ".\examples\StandaloneExample2.vrd"
   CASE nReport = 3
      cReportName := ".\examples\StandaloneExample3.vrd"
   CASE nReport = 4
      cReportName := "1"
   CASE nReport = 5
      cReportName := "2"
   CASE nReport = 6
      cReportName := "3"
   CASE nReport = 7
      cReportName := "4"
   ENDCASE

   IF nReport = 1 .OR. nReport = 2
      IIF( nTyp = 1, WinExec( "VRD.EXE " + cReportName ), OpenHtmlHelp( NIL, 100 ) )
   ELSEIF nReport = 3
      IIF( nTyp = 1, WinExec( "VRD.EXE " + cReportName ), ;
                     WinExec( "Notepad .\examples\ERStartScript1.prg" ) )
   ELSEIF nTyp = 1
      WinExec( 'VRD.EXE ".\examples\EasyReportExample' + cReportName + '.vrd"' )
   ELSEIF nTyp = 2
      WinExec( "Notepad .\examples\SourceExample" + cReportName + ".prg" )
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: PrintChoice
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION PrintChoice( oDlg, lPreview )

   DEFAULT lPreview := .F.

   EnableWindow( oDlg:hWnd, .F. )

   DO CASE
   CASE nReport = 1
      ShellExecute( 0, "Open", "ERSTART.EXE", ;
         "/File=.\examples\StandaloneExample1.vrd" + ;
         IIF( lPreview, "/PREVIEW", "/PRINTDIALOG" ), ;
         NIL, 1 )
   CASE nReport = 2
      ShellExecute( 0, "Open", "ERSTART.EXE", ;
         "-File=.\examples\StandaloneExample2.vrd" + ;
         IIF( lPreview, " -PREVIEW", " -PRINTDIALOG" ) + ;
         " -CHECK", ;
         NIL, 1 )
   CASE nReport = 3
      ShellExecute( 0, "Open", ;
         "ERSTART.EXE", ;
         "-File=.\examples\StandaloneExample3.vrd -Script=.\examples\ERStartScript1.prg" + ;
         IIF( lPreview, " -PREVIEW", " -PRINTDIALOG" ), ;
         NIL, 1 )
   CASE nReport = 4
      PrintOrder( lPreview )
   CASE nReport = 5
      PrOrderControlled( lPreview )
   CASE nReport = 6
      PrintReport( lPreview )
   CASE nReport = 7
      PrintRep2( lPreview, .T. )
   ENDCASE

   EnableWindow( oDlg:hWnd, .T. )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*        Name: PrintOrder
* Description: EasyReport example
*       Autor: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION PrintOrder( lPreview )

   LOCAL i, nTotal, nVAT, oVRD, lLastPosition

   //Open report
   EASYREPORT oVRD NAME ".\examples\EasyReportExample1.vrd" ;
              PREVIEW lPreview OF oWnd PRINTDIALOG IIF( lPreview, .F., .T. )

   IF oVRD:lDialogCancel
      RETURN( .F. )
   ENDIF

   // Set data
   oVRD:Cargo := { "Nr. 12345  Date: 5.9.2004", ;                      // 1 order number
                   "Testclient"               , ;                      // 2 Address string 1
                   "z.H.: Timm Sodtalbers"    , ;                      // 3 Address string 2
                   "Plaggefelder Str. 42"     , ;                      // 4 Address string 3
                   "26632 Ihlow"              , ;                      // 5 Address string 4
                   "257001"                   , ;                      // 6 Barcode value
                   "Sodtalbers+Partner" + CRLF + ;                     // 7 Company
                      "Plaggefelder Str. 42" + CRLF + "26632 Ihlow", ;
                   MEMOREAD( ".\examples\EasyReportExample.txt" ) }    // 8 Memo

   oVRD:Cargo2 := { "", "", "", ;
                    "Memo row 1" + CRLF + ;
                    "Memo row 2" + CRLF + ;
                    "Memo row 3" + CRLF + ;
                    "Memo row 4" + CRLF + ;
                    "Memo row 5", "" }

   //Open database and print order positions
   USE .\EXAMPLES\EXAMPLE
   nTotal := 0

   DO WHILE .NOT. EOF()

      PRINTAREA 3 OF oVRD ;
         ITEMIDS    { 104, 105, 106, 107 } ;
         ITEMVALUES { EXAMPLE->UNIT                               , ;
                      ALLTRIM(STR( EXAMPLE->PRICE, 10, 2 ))       , ;
                      ALLTRIM(STR( EXAMPLE->TOTALPRICE, 11, 2 ))  , ;
                      ALLTRIM( ".\EXAMPLES\" + EXAMPLE->IMAGE ) }

      EXAMPLE->(DBSKIP())
      lLastPosition := EXAMPLE->(EOF())
      EXAMPLE->(DBSKIP(-1))

      nTotal += EXAMPLE->TOTALPRICE

      FOR i := 1 TO MLCOUNT( oVRD:Cargo2[ EXAMPLE->(RECNO()) ], 240 )

         if lLastPosition .AND. oVRD:nNextRow > oVRD:nPageBreak - oVRD:aAreaHeight[5] .OR. ;
            !lLastPosition .AND. oVRD:nNextRow > oVRD:nPageBreak
            PAGEBREAK oVRD
         ENDIF

         PRINTAREA 4 OF oVRD ;
            ITEMIDS { 301 } ;
            ITEMVALUES { RTRIM( MEMOLINE( oVRD:Cargo2[ EXAMPLE->(RECNO()) ], 240, i ) ) }

      NEXT

      //New Page
      if lLastPosition .AND. oVRD:nNextRow > oVRD:nPageBreak - oVRD:aAreaHeight[5] .OR. ;
         !lLastPosition .AND. oVRD:nNextRow > oVRD:nPageBreak
         PAGEBREAK oVRD
      ENDIF

      EXAMPLE->(DBSKIP())

   ENDDO

   EXAMPLE->(DBCLOSEAREA())

   //Print position footer
   nVAT := nTotal * 0.16
   AADD( oVRD:Cargo, ALLTRIM(STR( nTotal       , 12, 2 )) )  //  9
   AADD( oVRD:Cargo, ALLTRIM(STR( nVAT         , 12, 2 )) )  // 10
   AADD( oVRD:Cargo, ALLTRIM(STR( nTotal + nVAT, 12, 2 )) )  // 11

   PRINTAREA 5 OF oVRD

   END EASYREPORT oVRD

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*        Name: PrOrderControlled
* Description: EasyReport example
*       Autor: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION PrOrderControlled( lPreview )

   LOCAL nTotal, nVAT, oVRD, oItem, nOldCol, nOldWidth, nOldHeight, aAlias[1], lLastPosition
   LOCAL cOrderNr   := "Nr. 54321  Date: 1.9.2003"
   LOCAL cAddress1  := "Sodtalbers+Partner"
   LOCAL cAddress2  := "z.H.: Timm Sodtalbers"
   LOCAL cAddress3  := "Plaggefelder Str. 42"
   LOCAL cAddress4  := "26632 Ihlow"
   LOCAL cCompany   := "Sodtalbers+Partner" + CRLF + "Plaggefelder Str. 42" + CRLF + "26632 Ihlow"

   //Open report
   EASYREPORT oVRD NAME ".\examples\EasyReportExample2.vrd" ;
              PREVIEW lPreview OF oWnd PRINTDIALOG IIF( lPreview, .F., .T. ) //;
              //AREAPATH "c:\fivewin\vdesign\test\"

   IF oVRD:lDialogCancel
      RETURN( .F. )
   ENDIF

   //Set and delete expressions
   oVRD:SetExpression( "Page number", "'page: ' + ALLTRIM(STR( oPrn:nPage, 3 ))", ;
                       "Print the current page number" )
   oVRD:SetExpression( "Report name", "oVRD:cReportName", "The Report title" )
   oVRD:DelExpression( "Test" )

   //Change item color
   oItem          := VRDItem():New( NIL, oVRD, 1, 102 )
   nOldCol        := oItem:nColText
   oItem:nColText := 1
   oItem:Set()

   //Print order title
   PRINTAREA 1 OF oVRD ;
      ITEMIDS    { 451, 102, 103, 104, 105, 202, 301, 150 } ;
      ITEMVALUES { NIL, cAddress1, cAddress2, cAddress3, cAddress4, cOrderNr, NIL, "257001" }

   //Set old item color
   oItem:nColText := nOldCol
   oItem:Set()

   //Change size of an item
   oItem := VRDItem():New( NIL, oVRD, 1, 452 )
   nOldWidth  := oItem:nWidth
   nOldHeight := oItem:nHeight
   oItem:nWidth  := 36
   oItem:nHeight := 10
   oItem:Set()

   //Print item
   oVRD:PrintItem( 1, 452, "RES:LOGO" )

   //Set old sizes
   oItem:nWidth  := nOldWidth
   oItem:nHeight := nOldHeight
   oItem:Set()

   //Print position header
   PRINTAREA 2 OF oVRD

   //Print order positions
   USE .\EXAMPLES\EXAMPLE
   nTotal := 0

   //aAlias[1] := "EXAMPLE"
   //
   //oVRD:bTransExpr := {| oVrd, cSource | ;
   //     cSource := STRTRAN( UPPER( cSource ), "TEST->", aAlias[1] + "->" ), ;
   //     EVAL( &( "{ | oPrn, oVRD, oInfo |" + ALLTRIM( cSource ) + " }" ), oVRD:oPrn, oVRD, oVRD:oInfo ) }

   oVRD:aAlias := { "EXAMPLE", "EXAMPLE" }

   DO WHILE .NOT. EOF()

      //Change item color
      oItem := VRDItem():New( NIL, oVRD, 3, 110 )
      nOldCol        := oItem:nColFill
      oItem:nColFill := 1
      oItem:Set()

      PRINTAREA 3 OF oVRD ;
         ITEMIDS    { 104, 105, 106, 107 } ;
         ITEMVALUES { EXAMPLE->UNIT                               , ;
                      ALLTRIM(STR( EXAMPLE->PRICE, 10, 2 ))       , ;
                      ALLTRIM(STR( EXAMPLE->TOTALPRICE, 11, 2 ))  , ;
                      ALLTRIM( ".\EXAMPLES\" + EXAMPLE->IMAGE ) }

      //Set old item color
      oItem:nColFill := nOldCol
      oItem:Set()

      EXAMPLE->(DBSKIP())
      lLastPosition := EXAMPLE->(EOF())
      EXAMPLE->(DBSKIP(-1))

      nTotal += EXAMPLE->TOTALPRICE

      //New Page
      if lLastPosition .AND. oVRD:nNextRow > oVRD:nPageBreak - oVRD:aAreaHeight[4] .OR. ;
         !lLastPosition .AND. oVRD:nNextRow > oVRD:nPageBreak

         //Print order footer
         PRINTAREA 5 OF oVRD ;
            ITEMIDS    { 101, 102 } ;
            ITEMVALUES { cCompany, ;
                         MEMOREAD( ".\examples\EasyReportExample.txt" ) }

         PAGEBREAK oVRD

         //Print position header
         PRINTAREA 2 OF oVRD

      ENDIF

      EXAMPLE->(DBSKIP())

   ENDDO

   EXAMPLE->(DBCLOSEAREA())

   //Print position footer
   nVAT := nTotal * 0.16
   PRINTAREA 4 OF oVRD ;
      ITEMIDS    { 104, 105, 106 } ;
      ITEMVALUES { ALLTRIM(STR( nTotal, 12, 2 ))        , ;
                   ALLTRIM(STR( nVAT, 12, 2 ))          , ;
                   ALLTRIM(STR( nTotal + nVAT , 12, 2 )) }

   //Print order footer on last page
   PRINTAREA 5 OF oVRD ;
      ITEMIDS    { 101, 102 } ;
      ITEMVALUES { cCompany, ;
                   MEMOREAD( ".\examples\EasyReportExample.txt" ) }

   //Ends the printout
   END EASYREPORT oVRD

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*        Name: PrintTextFeatures
* Description: EasyReport example
*       Autor: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION PrintTextFeatures( lPreview )

   LOCAL oVRD
   LOCAL cText1 := "Very flexible and easy to built in:" + CRLF + ;
                   "You do not need to learn a new programming or database language. " + ;
                   "The page and print control and the data delivery take place " + ;
                   "directly from your Clipper/Fivewin source code." + CRLF + ;
                   "Instead of oPrn:Say() you will use for example "+ ;
                   "oVrd:PrintItem( oPrn, 1, 101, adress->name ) to print items and " + ;
                   "areas which can be designed by your end users. Already existing " + ;
                   "source code only need some little changes." + CRLF + ;
                   "You don`t get problems with database drivers or runtime moduls." + ;
                   "The classes for the access to the EasyReport data files are delivered " + ;
                   "with source code."

   EASYREPORT oVRD NAME ".\examples\EasyReportExample2.vrd" ;
              PREVIEW lPreview OF oWnd PRINTDIALOG IIF( lPreview, .F., .T. )

   IF oVRD:lDialogCancel
      RETURN( .F. )
   ENDIF

   USE .\EXAMPLES\EXAMPLE2 VIA "DBFNTX"

   PRINTAREA 1 OF oVRD ;
      ITEMIDS    { 101, 102 } ;
      ITEMVALUES { cText1, EXAMPLE2->MEMOFIELD }

   EXAMPLE2->(DBCLOSEAREA())

   END EASYREPORT oVRD

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*        Name: PrintReport
* Description: EasyReport example
*       Autor: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION PrintReport( lPreview )

   LOCAL oVRD, oItem, nOldCol

   //Open report
   oVRD := VRD():New( ".\examples\EasyReportExample3.vrd", lPreview,, oWnd, ;
                      ,,,,, IIF( lPreview, .F., .T. ) )

   IF oVRD:lDialogCancel
      RETURN( .F. )
   ENDIF

   USE .\EXAMPLES\EXAMPLE3

   oVRD:AreaStart( 1 )
   oVRD:PrintArea( 1 )

   DO WHILE .NOT. EOF()

      //Change item color
      oItem := VRDItem():New( NIL, oVRD, 2, 110 )
      nOldCol        := oItem:nColFill
      oItem:nColFill := 1
      oItem:Set()

      oVRD:AreaStart( 2 )
      oVRD:PrintArea( 2 )

      //Set old item color
      oItem:nColFill := nOldCol
      oItem:Set()

      EXAMPLE3->(DBSKIP())

      //New Page
      IF oVRD:nNextRow > oVRD:nPageBreak

         oVRD:PageBreak()

         //Print header
         oVRD:AreaStart( 1 )
         oVRD:PrintArea( 1 )

      ENDIF

   ENDDO

   //Print footer
   oVRD:AreaStart( 3 )
   oVRD:PrintArea( 3 )

   EXAMPLE3->(DBCLOSEAREA())

   //End the printout
   oVRD:End()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*        Name: PrintRep2
* Description: Report with groups
*       Autor: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION PrintRep2( lPreview, lBreakAfterGroup )

   LOCAL oVRD, oInfo
   LOCAL nTotalPages := 0

   // This example shows the possibilities of the command ER QUICK and
   // the check clause. With the check clause you get the total number of
   // pages. The End() method of the VRD class returns an object (oInfo).

   IF lBreakAfterGroup

      ER QUICK oVRD NAME ".\examples\EasyReportExample4.vrd" ;
                    PREVIEW lPreview                          ;
                    OF oWnd                                   ;
                    PRINTDIALOG IIF( lPreview, .F., .T. )     ;
                    CHECK .T.                                 ;
                    ACTION ReportIt( oVRD, lBreakAfterGroup )

   ELSE

      EASYREPORT oVRD NAME ".\examples\EasyReportExample4.vrd" CHECK .T. OF oWnd

      ReportIt( oVRD, lBreakAfterGroup )

      IF oVRD:lDialogCancel
         RETURN( .F. )
      ENDIF

      oInfo := oVRD:End()

      EASYREPORT oVRD NAME ".\examples\EasyReportExample4.vrd" ;
         PREVIEW lPreview OF oWnd PRINTDIALOG IIF( lPreview, .F., .T. )

      IF oVRD:lDialogCancel
         RETURN( .F. )
      ENDIF

      oVRD:Cargo := ALLTRIM(STR( oInfo:nPages ))
      oVRD:oInfo := oInfo

      ReportIt( oVRD, lBreakAfterGroup )

      END EASYREPORT oVRD

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ReportIt
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ReportIt( oVRD, lBreakAfterGroup )

   LOCAL cCurState
   LOCAL nGroupTotal := 0
   LOCAL nTotal      := 0

   DELETE FILE "EXAMPLE4.NTX"
   USE .\EXAMPLES\EXAMPLE4
   INDEX ON EXAMPLE4->STATE TO EXAMPLE4.NTX
   SET INDEX TO EXAMPLE4
   DBGOTOP()

   cCurState := EXAMPLE4->STATE
   PRINTAREA 1 OF oVRD

   DO WHILE .NOT. EOF()

      oVRD:AreaStart( 2, .T. )

      nGroupTotal += EXAMPLE4->SALARY
      nTotal      += EXAMPLE4->SALARY

      EXAMPLE4->(DBSKIP())

      //Group
      IF EXAMPLE4->STATE <> cCurState

         PRINTAREA 3 OF oVRD ;
            ITEMIDS    { 101, 102 } ;
            ITEMVALUES { "Total for state " + ALLTRIM( cCurState ) + ":", ;
                         ALLTRIM(STR( nGroupTotal, 12, 2 )) }

         cCurState   := EXAMPLE4->STATE
         nGroupTotal := 0

         //Total
         PRINTAREA 4 OF oVRD ;
            ITEMIDS    { 101 } ;
            ITEMVALUES { ALLTRIM(STR( nTotal, 12, 2 )) }

         IF lBreakAfterGroup
            PRINTAREA 1 OF oVRD PAGEBREAK
         ENDIF

      ENDIF

      //Page break if necessary
      IF oVRD:nNextRow > oVRD:nPageBreak
         PRINTAREA 1 OF oVRD PAGEBREAK
      ENDIF

   ENDDO

   EXAMPLE4->(DBCLOSEAREA())
   DELETE FILE "EXAMPLE4.NTX"

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: OpenHtmlHelp
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION OpenHtmlHelp( cTopicID, nTopicNr, cHelpFile )

   LOCAL cPara := ""

   DEFAULT cHelpFile := ".\HELP\DEVELOP.CHM"

   IF nTopicNr <> NIL
      cPara := "-mapid " + ALLTRIM(STR( nTopicNr, 10 )) + " " + ALLTRIM( cHelpFile )
   ELSEIF cTopicID <> NIL
      cPara := '"' + ALLTRIM( cHelpFile ) + "::/" + ALLTRIM( cTopicID ) + '"'
   ELSE
      cPara := '"' + ALLTRIM( cHelpFile ) + '"'
   ENDIF

   ShellExecute( 0, "Open", "HH.exe", ALLTRIM( cPara ), NIL, 1 )

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
*        Name: PrTest
* Description: EasyReport example
*       Autor: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION PrTest()

   LOCAL oVRD

   EASYREPORT oVRD NAME ".\examples\test.vrd" PREVIEW .T. OF oWnd PRINTDIALOG .F.

   IF oVRD:lDialogCancel
      RETURN( .F. )
   ENDIF

   PRINTAREA 1 OF oVRD

   END EASYREPORT oVRD

RETURN (.T.)