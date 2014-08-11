
// EasyReport: Order form

FUNCTION PrintOrder( lPreview )

   LOCAL i, nTotal, nVAT, oVRD, lLastPosition

   //Open report
   EASYREPORT oVRD NAME ".\examples\EasyReportExample1.vrd" ;
              PREVIEW lPreview OF oWnd PRINTDIALOG IIF( lPreview, .F., .T. )

   IF oVRD:lDialogCancel = .T.
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

         if lLastPosition = .T. .AND. oVRD:nNextRow > oVRD:nPageBreak - oVRD:aAreaHeight[5] .OR. ;
            lLastPosition = .F. .AND. oVRD:nNextRow > oVRD:nPageBreak
            PAGEBREAK oVRD
         ENDIF

         PRINTAREA 4 OF oVRD ;
            ITEMIDS { 301 } ;
            ITEMVALUES { RTRIM( MEMOLINE( oVRD:Cargo2[ EXAMPLE->(RECNO()) ], 240, i ) ) }

      NEXT

      //New Page
      if lLastPosition = .T. .AND. oVRD:nNextRow > oVRD:nPageBreak - oVRD:aAreaHeight[5] .OR. ;
         lLastPosition = .F. .AND. oVRD:nNextRow > oVRD:nPageBreak
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