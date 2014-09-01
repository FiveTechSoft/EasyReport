#include "FiveWin.ch"
#INCLUDE "Mail.ch"

MEMVAR aItems, aFonts, aAreaIni, aWnd, oBar
MEMVAR cDefaultPath
MEMVAR nAktArea
MEMVAR aVRDSave
MEMVAR oClpGeneral, cDefIni, nMeasure, lDemo, lBeta, oTimer
MEMVAR oMainWnd, lProfi, nUndoCount, nRedoCount, lPersonal, lStandard, oGenVar
MEMVAR oER


//------------------------------------------------------------------------------

function QuietRegCheck()

   local nSerial := GetSerialHD()
   local cSerial := IIF( nSerial = 0, "8"+"2"+"2"+"7"+"3"+"6"+"5"+"1", ALLTRIM( STR( ABS( nSerial ), 20 ) ) )
   local cRegist := PADR( GetPvProfString( "General", "RegistKey", "", oER:cGeneralIni ), 40 )

   return CheckRegist( cSerial, cRegist )

//------------------------------------------------------------------------------

function CheckRegist( cSerial, cRegist )

   local lOK := .F.

   if ALLTRIM( cRegist ) == GetRegistKey( cSerial )
      WritePProString( "General", "RegistKey", ALLTRIM( cRegist ) , oER:cGeneralIni )
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
   local nLanguage := VAL( GetPvProfString( "General", "Language", "1", oER:cGeneralIni ) )

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


*-- function -----------------------------------------------------------------
* Name........: EndMsgLogo
* Beschreibung:
* Argumente...: None
* R�ckgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
function EndMsgLogo( oDlg, aFonts )

   local nInterval := 0

   oDlg:End()
   AEVAL( aFonts, {| oFont| oFont:End() } )
   oTimer:End()
   SysRefresh()
   MEMORY(-1)

   //Demo mode: App l�uft nur 3 Minuten
   if lDemo
      DEFINE TIMER oTimer INTERVAL 1000 OF oEr:oMainWnd ;
         ACTION ( TimerRunOut( ++nInterval ) )
      ACTIVATE TIMER oTimer
   endif

return .T.


//------------------------------------------------------------------------------

function TimerRunOut( nInterval )

   if nInterval = 300
      MsgStop( "Demo version time run out (5 minutes)!" )
      oTimer:End()
      QUIT
   endif

return .T.

//------------------------------------------------------------------------------

function CheckTimer( nInterval, oSay )

    local lreturn := .F.

    if lDemo
       oSay:SetText( "Please wait: " + ALLTRIM(STR( 20 - nInterval, 3)) + " Sec." )
    endif

    if lDemo .AND. nInterval = 20 .OR. lDemo = .F. .AND. nInterval = 3
      lreturn := .T.
    endif

return ( lreturn )

//------------------------------------------------------------------------------

function VRDMsgPersonal()

   local oDlg, oFont, oFont2
   local lOK          := .T. // .F.
   local lTestVersion := .F.
   local nClr1        := RGB( 128, 128, 128 )
   local nClrBack     := RGB( 255, 255, 255 )
   local nSerial      := GetSerialHD()
   local cSerial      := IIF( nSerial = 0, "8"+"2"+"2"+"7"+"3"+"6"+"5"+"1", ALLTRIM( STR( ABS( nSerial ), 20 ) ) )
   local cRegist      := PADR( GetPvProfString( "General", "RegistKey", "", oER:cGeneralIni ), 40 )
   local cCompany     := PADR( GetPvProfString( "General", "Company"  , "", oER:cGeneralIni ), 100 )
   local cUser        := PADR( GetPvProfString( "General", "User"     , "", oER:cGeneralIni ), 100 )
   local cVersion     := IIF( lStandard, "Standard", "Personal" )

   DEFINE FONT oFont  NAME "Ms Sans Serif" SIZE 0, -14
   DEFINE FONT oFont2 NAME "Ms Sans Serif" SIZE 0, -6

   DEFINE DIALOG oDlg NAME "MSGPERSONAL" ;
      TITLE "EasyReport " + cVersion COLOR 0, nClrBack

   REDEFINE BITMAP ID 301 OF oDlg RESOURCE "LOGO"

   REDEFINE GET cSerial  ID 401 OF oDlg READONLY MEMO COLOR 0, nClrBack FONT oFont
   REDEFINE GET cCompany ID 402 OF oDlg COLOR 0, nClrBack FONT oFont
   REDEFINE GET cUser    ID 403 OF oDlg COLOR 0, nClrBack FONT oFont
   REDEFINE GET cRegist  ID 404 OF oDlg COLOR 0, nClrBack FONT oFont

   REDEFINE SAY PROMPT "Please send us the serial number, company and" + CRLF + ;
                       "user name. We will give you the free registration" + CRLF + ;
                       "key as soon as possible." ;
      ID 201 OF oDlg COLOR RGB( 0, 0, 128 ), nClrBack //FONT oFont

   REDEFINE SAY PROMPT "Using EasyReport " + cVersion + " the Visual Report Designer will only work on one machine." + CRLF + ;
                       "With EasyReport Professional you have the possibility to pass the Visual Report" + CRLF + ;
                       "Designer to your customers without paying anything extra (royalty free)." ;
      ID 203 OF oDlg COLOR 0, nClrBack

   REDEFINE BUTTON ID 103 OF oDlg ACTION SendRegInfos( cSerial, cCompany, cUser, cVersion ) ;
      WHEN .NOT. EMPTY( cCompany ) .OR. .NOT. EMPTY( cUser )

   REDEFINE SAY PROMPT "Copyright"        + CRLF + ;
                       oGenVar:cCopyright + CRLF + ;
                       "Timm Sodtalbers"  + CRLF + ;
                       "Sodtalbers+Partner" ;
      ID 202 OF oDlg COLOR nClr1, nClrBack FONT oFont2

   REDEFINE SAY ID 171 OF oDlg COLOR 0, nClrBack FONT oFont
   REDEFINE SAY ID 172 OF oDlg COLOR 0, nClrBack FONT oFont
   REDEFINE SAY ID 173 OF oDlg COLOR 0, nClrBack FONT oFont
   REDEFINE SAY ID 174 OF oDlg COLOR 0, nClrBack FONT oFont

   REDEFINE BUTTON ID 101 OF oDlg ;
      ACTION ( lOK := .T. /* := CheckRegist( cSerial, cRegist ) */, oDlg:End() )
   REDEFINE BUTTON ID 104 OF oDlg ACTION ( lTestVersion := .T., oDlg:End() )
   REDEFINE BUTTON ID 102 OF oDlg ACTION ;
      ShellExecute( 0, "Open", "http://www.reportdesigner.info", Nil, Nil, 1 )

   ACTIVATE DIALOG oDlg CENTER

   WritePProString( "General", "Company", ALLTRIM( cCompany ), oER:cGeneralIni )
   WritePProString( "General", "User"   , ALLTRIM( cUser )   , oER:cGeneralIni )

   if lOK = .F. .AND. lTestVersion = .F.
      MsgInfo( "The registration key is not valid!" + CRLF + CRLF + ;
               "EasyReport starts in demo mode." )
      WritePProString( "General", "RegistKey", "", oER:cGeneralIni )
   endif

   if lOK = .F.
      lDemo  := .T.
      lProfi := .T.
      oEr:oMainWnd:oBar:AEvalWhen()
      oEr:oMainWnd:cTitle := MainCaption()
      oEr:oMainWnd:SetMenu( BuildMenu() )
      VRDLogo()
   endif

   oFont:End()
   oFont2:End()

return ( lOK )

//------------------------------------------------------------------------------