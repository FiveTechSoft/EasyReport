

#INCLUDE "FiveWin.ch"
#INCLUDE "VRD.ch"


FUNCTION Print_erReport( cRptFile, cPrinter, nMode, oDlg )
LOCAL oReport

local aMode:= { "PRINT", "PREVIEW", "PRINTDIALOG" }
local cMode

   DEfault nMode :=  1

   if nMode >  3
      nMode:= 1
   endif
   cMode:= amode[nMode]

   if Empty( cRptFile )
      cRptFile:=  GetFile( GL("Designer Files") + " (*.vrd)|*.vrd|" + ;
                              GL("All Files") + " (*.*)|*.*", GL("Open"), 1 )

   endif

   oReport := ERStart():New(  cRptFile, cPrinter , oDlg )
   oReport:cMode := cMode

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
   DATA oDlg

   METHOD New( cRptFile, cPrinter ,oDlg ) CONSTRUCTOR

   METHOD PrintReport()
   METHOD RunScript()
   METHOD PrintAreas()


ENDCLASS


*-- METHOD -------------------------------------------------------------------
*         Name: New
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD New( cRptFile, cPrinter ,oDlg ) CLASS ERStart

   LOCAL i, cDateFormat, cTemp, nScan
   LOCAL aParameter  := {}
   LOCAL aParaValues := {}

    ::cRptFile := cRptFile
    ::cPrinter := cPrinter
    ::cRDD   := ALLTRIM( GetPvProfString( "General", "RDD", "COMIX", ::cIni ) )
    ::lCheck := .f.
    ::cScript := ""
    ::nCopies := 1
    ::oDlg:= oDlg

   IF EMPTY( ::cRptFile )
      MsgInfo( "No ha introducido el archivo a procesar","EasyReport" )
      QUIT
   ENDIF
   if !File ( ::cRptFile )
      MsgInfo( "No se ha encontrado el archivo a procesar","EasyReport" )
      QUIT
   ENDIF


   IF .NOT. EMPTY( ::cScript ) .AND. FILE( ::cScript ) = .F.
      MsgStop( "Script not found:" + CRLF + CRLF + ::cScript )
      QUIT
   ENDIF

   cDateFormat := LOWER(ALLTRIM( GetPvProfString( "General", "DateFormat", "", ::cIni )))

   IF .NOT. EMPTY( cDateFormat )
      SET DATE FORMAT cDateFormat
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

   LOCAL lPreview := .f.
   LOCAL lPrintDlg  := .T.
   LOCAL lPrintIDs := .F.

   IF ::lCheck

      EASYREPORT ::oVRD NAME ::cRptFile CHECK .T. AUTOPAGEBREAK .T.

      ::PrintAreas()

      oInfo := ::oVRD:End()

   ENDIF

   EASYREPORT ::oVRD  ;
     NAME ::cRptFile ;
     OF ::oDlg ;
     PREVIEW lPreview ;
     PRINTDIALOG IIF( lPreview, .F., lPrintDlg ) PRINTIDS NOEXPR


   ::oVRD:LPrintIDs :=  lPrintIDs
   ::oVrd:lAutoPageBreak := .T.


   /*

   EASYREPORT ::oVRD         ;
      NAME          ::cRptFile ;
      TO            ::cPrinter ;
      COPIES        ::nCopies  ;
      PREVIEW       ( ::cMode == "PREVIEW" ) ;
      PRINTDIALOG   ( ::cMode == "PRINTDIALOG" ) ;
      AUTOPAGEBREAK .T.

  */
   IF ::oVRD:lDialogCancel
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

