/*
    ==================================================================
    EasyReport                                             ERSTART.PRG
                                                         Version 2.0.5
    ------------------------------------------------------------------
                           (c) copyright: Timm Sodtalbers, 2000 - 2004
                                                    Sodtalbers+Partner
                                              info@reportdesigner.info
                                               www.reportdesigner.info
    ==================================================================
*/

#INCLUDE "FiveWin.ch"
#INCLUDE "VRD.ch"

*-- FUNCTION -----------------------------------------------------------------
*         Name: Start
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION Start( P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, P11, P12, P13, P14, P15 )

   LOCAL oReport
   LOCAL cParameter := ""

   IF P1  <> NIL ; cParameter += P1  ; ENDIF
   IF P2  <> NIL ; cParameter += P2  ; ENDIF
   IF P3  <> NIL ; cParameter += P3  ; ENDIF
   IF P4  <> NIL ; cParameter += P4  ; ENDIF
   IF P5  <> NIL ; cParameter += P5  ; ENDIF
   IF P6  <> NIL ; cParameter += P6  ; ENDIF
   IF P7  <> NIL ; cParameter += P7  ; ENDIF
   IF P8  <> NIL ; cParameter += P8  ; ENDIF
   IF P9  <> NIL ; cParameter += P9  ; ENDIF
   IF P10 <> NIL ; cParameter += P10 ; ENDIF
   IF P11 <> NIL ; cParameter += P11 ; ENDIF
   IF P12 <> NIL ; cParameter += P12 ; ENDIF
   IF P13 <> NIL ; cParameter += P13 ; ENDIF
   IF P14 <> NIL ; cParameter += P14 ; ENDIF
   IF P15 <> NIL ; cParameter += P15 ; ENDIF

   oReport := ERStart():New( ALLTRIM( cParameter ) )

RETURN (.T.)


*-- CLASS DEFINITION ---------------------------------------------------------
*         Name: ERStart
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
CLASS ERStart

   DATA cRptFile, cMode, cPrinter, cScript, cRDD

   DATA cIni    INIT ".\VRD.INI"

   DATA nCopies

   DATA lCheck  INIT .F.

   DATA oVRD

   METHOD New( cParameter ) CONSTRUCTOR

   METHOD PrintReport()
   METHOD RunScript()
   METHOD PrintAreas()

   METHOD CheckFullVersion()
   METHOD FreewareMessage()

ENDCLASS


*-- METHOD -------------------------------------------------------------------
*         Name: New
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD New( cParameter ) CLASS ERStart

   LOCAL i, cDateFormat, cTemp, nScan
   LOCAL aParameter  := {}
   LOCAL aParaValues := {}
   LOCAL cParaSep    := IIF( AT( "/", cParameter ) = 0, "-", "/" )

   IF AT( cParaSep + "PRINTDIALOG", UPPER(ALLTRIM( cParameter )) ) <> 0
      ::cMode := "PRINTDIALOG"
   ELSEIF AT( cParaSep + "PREVIEW", UPPER(ALLTRIM( cParameter )) ) <> 0
      ::cMode := "PREVIEW"
   ELSE
      ::cMode := "PRINT"
   ENDIF

   ::lCheck := ( AT( cParaSep + "CHECK", UPPER(ALLTRIM( cParameter )) ) <> 0 )
   ::cRDD   := ALLTRIM( GetPvProfString( "General", "RDD", "COMIX", ::cIni ) )

   FOR i := 1 TO 10
      cTemp := ALLTRIM( StrToken( cParameter, i, cParaSep ) )
      IF AT( "=", cTemp ) <> 0
         AADD( aParameter , UPPER( SUBSTR( StrToken( cTemp, 1, "=" ), 1, 1 ) ) )
         AADD( aParaValues, StrToken( cTemp, 2, "=" ) )
      ENDIF
   NEXT

   // Reportfile
   nScan := ASCAN( aParameter, "F" )
   IF nScan <> 0
      ::cRptFile := aParaValues[ nScan ]
   ENDIF

   // Printer name
   nScan := ASCAN( aParameter, "P" )
   IF nScan <> 0
      ::cPrinter := aParaValues[ nScan ]
   ENDIF

   // Script
   nScan := ASCAN( aParameter, "S" )
   IF nScan <> 0
      ::cScript := aParaValues[ nScan ]
   ENDIF

   // Copies
   nScan := ASCAN( aParameter, "C" )
   IF nScan <> 0
      ::nCopies := MAX( 1, VAL( aParaValues[ nScan ] ) )
   ENDIF

   IF EMPTY( ::cRptFile )
      MsgInfo( "Wrong start parameter.", "EasyReport" )
      QUIT
   ENDIF

   IF .NOT. EMPTY( ::cScript ) .AND. FILE( ::cScript ) = .F.
      MsgStop( "Script not found:" + CRLF + CRLF + ::cScript )
      QUIT
   ENDIF

   // setup EasyPreview
   EP_TidyUp()
   EP_LinkedToApp()
   EP_SetPath( ".\EPFILES" )

   cDateFormat := LOWER(ALLTRIM( GetPvProfString( "General", "DateFormat", "", ::cIni )))

   IF .NOT. EMPTY( cDateFormat )
      SET DATE FORMAT cDateFormat
   ENDIF

   IF ::CheckFullVersion() = .F.
      ::FreewareMessage()
   ENDIF

   ::PrintReport()

RETURN SELF


*-- METHOD -------------------------------------------------------------------
*         Name: PrintReport
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrintReport() CLASS ERStart

   LOCAL i, oInfo

   IF ::lCheck = .T.

      EASYREPORT ::oVRD NAME ::cRptFile CHECK .T. AUTOPAGEBREAK .T.

      ::PrintAreas()

      oInfo := ::oVRD:End()

   ENDIF

   EASYREPORT ::oVRD         ;
      NAME          ::cRptFile ;
      TO            ::cPrinter ;
      COPIES        ::nCopies  ;
      PREVIEW       ( ::cMode == "PREVIEW" ) ;
      PRINTDIALOG   ( ::cMode == "PRINTDIALOG" ) ;
      AUTOPAGEBREAK .T.

   IF ::oVRD:lDialogCancel = .T.
      RETURN .F.
   ENDIF

   ::oVRD:oInfo := oInfo

   ::PrintAreas()

   ::oVRD:End()

RETURN .T.


*-- METHOD -------------------------------------------------------------------
*         Name: PrintAreas
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD PrintAreas() CLASS ERStart

   LOCAL i

   IF EMPTY( ::cScript )
      FOR i := 1 TO LEN( ::oVRD:aAreaInis )
         IF i = LEN( ::oVRD:aAreaInis )
            ::oVRD:lAutoPageBreak = .F.
         ENDIF
         PRINTAREA i OF ::oVRD
      NEXT
   ELSE
      ::RunScript()
   ENDIF

RETURN .T.


*-- METHOD -------------------------------------------------------------------
*         Name: RunScript
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD RunScript() CLASS ERStart

   LOCAL oScript := TScript():New( MEMOREAD( ::cScript ) )

   oScript:lPreProcess := .T.

   oScript:Compile()

   IF EMPTY( oScript:cError ) = .F.
      MsgStop( "Error in script:" + CRLF + CRLF + ALLTRIM( oScript:cError ), "Error" )
   ELSE
      oScript:Run( "Script", ::oVRD )
   ENDIF

RETURN .T.


*-- METHOD -------------------------------------------------------------------
*         Name: CheckFullVersion
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD CheckFullVersion() CLASS ERStart

   LOCAL lReturn   := .F.
   LOCAL cRegText  := DeCrypt( MEMOREAD( ".\ERSTART.LIZ" ), "A"+"N"+"I"+"G"+"E"+"R" )
   LOCAL cRegText2 := DeCrypt( MEMOREAD( ".\VRD.LIZ" )    , "A"+"N"+"I"+"G"+"E"+"R" )

   IF SUBSTR( cRegText , 11, 3 ) = "287" .OR. SUBSTR( cRegText2, 11, 3 ) = "209"
      lReturn := .T.
   ENDIF

RETURN ( lReturn )


*-- METHOD -------------------------------------------------------------------
*         Name: FreewareMessage
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD FreewareMessage() CLASS ERStart

   LOCAL oDlg, aFonts[2], aSay[3]

   DEFINE FONT aFonts[1] NAME "MS SANS SERIF" SIZE 0,-14
   DEFINE FONT aFonts[2] NAME "MS SANS SERIF" SIZE 0,-8

   DEFINE DIALOG oDlg NAME "MSGLOGO" COLOR 0, RGB( 255, 255, 255 )

   REDEFINE SAY PROMPT "EasyReport Starter  -  Freeware Version" ID 202 OF oDlg FONT aFonts[1] COLOR 0, RGB( 255, 255, 255 )

   REDEFINE BITMAP ID 301 OF oDlg RESOURCE "LOGO"

   REDEFINE SAY PROMPT "Copyright 2004 Sodtalbers+Partner - www.reportdesigner.info " ;
      ID 203 OF oDlg FONT aFonts[2] COLOR 0, RGB( 255, 255, 255 )

   ACTIVATE DIALOG oDlg CENTER NOMODAL

   SysWait(4)

   oDlg:End()

   AEVAL( aFonts, {|x| x:End() } )

RETURN .T.