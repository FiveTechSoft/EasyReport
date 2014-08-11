
// EasyReport: Report with groups

FUNCTION PrintRep2( lPreview, lBreakAfterGroup )

   LOCAL oVRD, oInfo
   LOCAL nTotalPages := 0

   // This example shows the possibilities of the command ER QUICK and
   // the check clause. With the check clause you get the total number of
   // pages. The End() method of the VRD class returns an object (oInfo).

   IF lBreakAfterGroup = .T.

      ER QUICK oVRD NAME ".\examples\EasyReportExample4.vrd" ;
                    PREVIEW lPreview                          ;
                    OF oWnd                                   ;
                    PRINTDIALOG IIF( lPreview, .F., .T. )     ;
                    CHECK .T.                                 ;
                    ACTION ReportIt( oVRD, lBreakAfterGroup )

   ELSE

      EASYREPORT oVRD NAME ".\examples\EasyReportExample4.vrd" CHECK .T. OF oWnd

      ReportIt( oVRD, lBreakAfterGroup )

      IF oVRD:lDialogCancel = .T.
         RETURN( .F. )
      ENDIF

      oInfo := oVRD:End()

      EASYREPORT oVRD NAME ".\examples\EasyReportExample4.vrd" ;
         PREVIEW lPreview OF oWnd PRINTDIALOG IIF( lPreview, .F., .T. )

      IF oVRD:lDialogCancel = .T.
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

         IF lBreakAfterGroup = .T.
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
