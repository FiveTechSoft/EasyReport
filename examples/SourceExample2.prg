
// EasyReport: Order form 2 - controlling the flow

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

   IF oVRD:lDialogCancel = .T.
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
      if lLastPosition = .T. .AND. oVRD:nNextRow > oVRD:nPageBreak - oVRD:aAreaHeight[4] .OR. ;
         lLastPosition = .F. .AND. oVRD:nNextRow > oVRD:nPageBreak

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