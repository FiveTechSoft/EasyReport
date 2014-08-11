
// EasyReport: Simple report

FUNCTION PrintReport( lPreview )

   LOCAL oVRD, oItem, nOldCol

   //Open report
   oVRD := VRD():New( ".\examples\EasyReportExample3.vrd", lPreview,, oWnd, ;
                      ,,,,, IIF( lPreview, .F., .T. ) )

   IF oVRD:lDialogCancel = .T.
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
