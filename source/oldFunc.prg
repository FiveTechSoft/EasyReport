#include "FiveWin.ch"
#INCLUDE "Mail.ch"

MEMVAR aItems, aFonts, aAreaIni, aWnd, oBar
MEMVAR cDefaultPath
MEMVAR nAktArea
MEMVAR aVRDSave
MEMVAR oClpGeneral, cDefIni, cGeneralIni, nMeasure, lDemo, lBeta, oTimer
MEMVAR oMainWnd, lProfi, nUndoCount, nRedoCount, lPersonal, lStandard, oGenVar
MEMVAR oER

//------------------------------------------------------------------------------

function BetaVersion()

   local oDlg, oFont
   local nClrBack := RGB( 255, 255, 255 )

   DEFINE FONT oFont  NAME "Ms Sans Serif" SIZE 0, -14

   DEFINE DIALOG oDlg NAME "MSGBETA" COLOR 0, nClrBack

   REDEFINE SAY PROMPT "- BETA VERSION -" ID 204 OF oDlg FONT oFont COLOR 0, nClrBack

   REDEFINE SAY PROMPT "This is a beta version of EasyReport. Please let me" ID 201 OF oDlg FONT oFont COLOR 0, nClrBack
   REDEFINE SAY PROMPT "know if you have any problems or suggestions."       ID 202 OF oDlg FONT oFont COLOR 0, nClrBack

   REDEFINE BITMAP ID 301 OF oDlg RESOURCE "LOGO"

   REDEFINE BUTTON ID 101 OF oDlg ACTION oDlg:End()

   ACTIVATE DIALOG oDlg CENTER

   oFont:End()

return NIL

//------------------------------------------------------------------------------

function QuietRegCheck()

   local nSerial := GetSerialHD()
   local cSerial := IIF( nSerial = 0, "8"+"2"+"2"+"7"+"3"+"6"+"5"+"1", ALLTRIM( STR( ABS( nSerial ), 20 ) ) )
   local cRegist := PADR( GetPvProfString( "General", "RegistKey", "", cGeneralIni ), 40 )

   return CheckRegist( cSerial, cRegist )

//------------------------------------------------------------------------------

function CheckRegist( cSerial, cRegist )

   local lOK := .F.

   if ALLTRIM( cRegist ) == GetRegistKey( cSerial )
      WritePProString( "General", "RegistKey", ALLTRIM( cRegist ) , cGeneralIni )
      lOK := .T.
   endif

return ( lOK )

//------------------------------------------------------------------------------

function GetRegistKey( cSerial )

   local cReg := ALLTRIM( STR( INT( ( VAL( ALLTRIM( cSerial ) ) * 167 ) * 4.12344 ), 30 ) )

   cReg := SUBSTR( cReg + ALLTRIM( STR( 47348147489715610655, 30 ) ), 1, 12 )

   cReg := CHR( VAL( SUBSTR( cReg, 8, 1 ) ) + 74 ) + ;
           CHR( VAL( SUBSTR( cReg, 4, 1 ) ) + 68 ) + ;
           CHR( VAL( SUBSTR( cReg, 2, 1 ) ) + 70 ) + ;
           CHR( VAL( SUBSTR( cReg, 6, 1 ) ) + 66 ) + ;
           SUBSTR( cReg, 5 )

return ( cReg )

//------------------------------------------------------------------------------

function SendRegInfos( cSerial, cCompany, cUser, cVersion )

   local i, oMail

   DEFINE MAIL oMail SUBJECT "EasyReport " + cVersion + " Registration" ;
                     TEXT "      Company: " + cCompany + CRLF + ;
                          "    User name: " + cUser    + CRLF + ;
                          "Serial number: " + cSerial  + CRLF ;
                     FROM USER ;
                     TO "regist@reportdesigner.info"

   oMail:Activate()

 return .T.

//------------------------------------------------------------------------------

function GetSerialHD( cDrive )

   local cLabel      := Space(32)
   local cFileSystem := Space(32)
   local nSerial     := 0
   local nMaxComp    := 0
   local nFlags      := 0

   DEFAULT cDrive := "C:\"

   GetVolInfo( cDrive, @cLabel, Len( cLabel ), @nSerial, @nMaxComp, @nFlags, ;
               @cFileSystem, Len( cFileSystem ) )

return nSerial

DLL32 function GetVolInfo( sDrive          AS STRING, ;
                           sVolName        AS STRING, ;
                           lVolSize        AS LONG  , ;
                           @lVolSerial     AS PTR   , ;
                           @lMaxCompLength AS PTR   , ;
                           @lFileSystFlags AS PTR   , ;
                           @sFileSystName  AS STRING, ;
                           lFileSystSize   AS LONG ) ;
               AS LONG PASCAL ;
               FROM "GetVolumeInformationA" ;
               LIB  "kernel32.dll"


//------------------------------------------------------------------------------

function GetRegistInfos()

   local cRegText := ""
   local cRegFile := IIF( FILE( ".\VRD.LIZ" ), ".\VRD.LIZ", ;
                          "..\VDESIGN.PRG\LICENCE\VRD.LIZ" )

   cRegText := DeCrypt( MEMOREAD( cRegFile ), "A"+"N"+"I"+"G"+"E"+"R" )

   if lPersonal = .T. .OR. lStandard = .T.
      cRegText := "S" +"o"+"d"+"t"+"a"+"l"+"b"+"e"+"r"+"s" + "+Partner"
   ELSEif SUBSTR( cRegText, 11, 3 ) <> "209" .AND. lBeta = .F.
      lDemo := .T.
      cRegText := "U"+"n"+"r"+"e"+"g"+"i"+"s"+"t"+"e"+"r"+"e"+"d "+"D"+"e"+"m"+"o "+"V"+"e"+"r"+"s"+"i"+"o"+"n"
   ELSEif SUBSTR( cRegText, 11, 3 ) <> "209" .AND. lBeta = .T.
      lDemo := .T.
      cRegText := "beta version"
   ELSEif lBeta = .F.
      if SUBSTR( cRegText, 14, 7 ) = "Ghze646" .OR. SUBSTR( cRegText, 14, 7 ) = "fSDFh23"
         if SUBSTR( cRegText, 14, 7 ) <> "Ghze646"
            lProfi := .F.
         endif
         cRegText := ALLTRIM( SUBSTR( cRegText, 21, 10 ) + ;
                              SUBSTR( cRegText, 41, 10 ) + ;
                              SUBSTR( cRegText, 61, 10 ) + ;
                              SUBSTR( cRegText, 81, 10 ) + ;
                              SUBSTR( cRegText, 101, 10 ) )
      endif
   endif

   lDemo = .F. // FiveTech
   cRegText = "(c) FiveTech Software 2014" // FiveTech

return ( cRegText )

//------------------------------------------------------------------------------

function VRDLogo()

   local oDlg, oSay
   local aFonts    := ARRAY(2)
   local nInterval := 1

   DEFINE FONT aFonts[1] NAME "Ms Sans Serif" SIZE 0, -14
   DEFINE FONT aFonts[2] NAME "Ms Sans Serif" SIZE 0, -6

   DEFINE TIMER oTimer INTERVAL 1000 OF oDlg ;
      ACTION IIF( CheckTimer( nInterval++, oSay ) = .T., EndMsgLogo( oDlg, aFonts ), )

   DEFINE DIALOG oDlg NAME "MSGLOGO" COLOR 0, RGB( 255, 255, 255 )

   REDEFINE SAY PROMPT GetLicLanguage() ID 201 OF oDlg FONT aFonts[1] COLOR 0, RGB( 255, 255, 255 )
   REDEFINE SAY PROMPT GetRegistInfos() ID 202 OF oDlg FONT aFonts[1] COLOR 0, RGB( 255, 255, 255 )

   REDEFINE BITMAP ID 301 OF oDlg RESOURCE "LOGO"

   REDEFINE SAY PROMPT "copyright Sodtalbers+Partner, " + oGenVar:cCopyright + " - www.reportdesigner.info " ;
      ID 203 OF oDlg FONT aFonts[2] COLOR 0, RGB( 255, 255, 255 )

   REDEFINE SAY oSay PROMPT ;
      IIF( lDemo = .T., "Please wait: 20 Sec.", "") ID 204 OF oDlg FONT aFonts[2] ;
      COLOR 0, RGB( 255, 255, 255 )

   ACTIVATE DIALOG oDlg CENTER ;
      ON INIT oTimer:Activate() ;
      VALID IF( GETKEYSTATE( VK_ESCAPE ) .AND. lDemo = .T. , .F., .T. )

   aFonts[1]:End()
   aFonts[2]:End()

return NIL

//------------------------------------------------------------------------------

function GetLicLanguage()

   local cText     := ""
   local nLanguage := VAL( GetPvProfString( "General", "Language", "1", cGeneralIni ) )

   if lBeta = .F.
      if nLanguage = 2
         cText := "Lizensiert f�r: "
      ELSEif nLanguage = 3
         cText := "In licenza a: "
      ELSEif nLanguage = 4
         cText := "Licenciado a: "
      ELSE
         cText := "Licenced to: "
      endif
   endif

return ( cText )

//------------------------------------------------------------------------------

function VRDAbout()

   local oDlg, oFont, cVersion := ""
   local nClrBack := RGB( 255, 255, 255 )

   oGenVar:cRelease = "3.0"

   IIF( lProfi   , cVersion := "Professional", )
   IIF( lPersonal, cVersion := "Personal"    , )
   IIF( lStandard, cVersion := "Standard"    , )

   DEFINE FONT oFont  NAME "Ms Sans Serif" SIZE 0, -14

   DEFINE DIALOG oDlg NAME "MSGINFO" TITLE GL("About") COLOR 0, nClrBack

   REDEFINE SAY PROMPT GL("Release") + " " + oGenVar:cRelease + " - " + cVersion ;
      ID 204 OF oDlg FONT oFont COLOR 0, nClrBack

   REDEFINE SAY PROMPT GetLicLanguage() ID 201 OF oDlg FONT oFont COLOR 0, nClrBack
   REDEFINE SAY PROMPT GetRegistInfos() ID 202 OF oDlg FONT oFont COLOR 0, nClrBack

   REDEFINE BITMAP ID 301 OF oDlg RESOURCE "LOGO"

   REDEFINE SAY PROMPT "copyright Timm Sodtalbers, " + oGenVar:cCopyright + + ;
                       "     Sodtalbers+Partner - Ihlow - Germany" ;
      ID 203 OF oDlg COLOR 0, nClrBack

   REDEFINE BUTTON ID 101 OF oDlg ACTION oDlg:End()
   REDEFINE BUTTON ID 102 OF oDlg ACTION ;
      ShellExecute( 0, "Open", "http://www.reportdesigner.info", Nil, Nil, 1 )

   ACTIVATE DIALOG oDlg CENTER

   oFont:End()

return NIL

//------------------------------------------------------------------------------

