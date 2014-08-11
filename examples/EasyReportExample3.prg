
*-- FUNCTION -----------------------------------------------------------------
*        Name: PrintReport
* Description: EasyReport example
*       Autor: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION PrintReport( lPreview )

   LOCAL oVRD

   //Open report
   oVRD := VRD():New( ".\examples\EasyReport Example3.vrd", lPreview,, oWnd, ;
                      ,,,,, IIF( lPreview, .F., .T. ) )

   IF oVRD:lDialogCancel = .T.
      RETURN( .F. )
   ENDIF

   USE .\EXAMPLES\EXAMPLE3

   oVRD:AreaStart( 1 )
   oVRD:PrintArea( 1 )

   DO WHILE .NOT. EOF()

      oVRD:AreaStart( 2 )
      oVRD:PrintArea( 2 )

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
