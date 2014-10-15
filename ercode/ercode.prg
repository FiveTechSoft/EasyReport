#include "FiveWin.ch"

function Main()

   local cGeneralIni:= "c:\vrd.ini" +space(20)
   local oDlg, oBtn,oGet
 
   DEFINE DIALOG oDlg TiTle "Registrar EReport"

   @ 2,  2 GET oget VAR cGeneralIni ACTION SetinGet( oGet )

   @ 3,  4 BUTTON oBtn PROMPT "Registrar" ACTION Registrar( alltrim( cGeneralIni ) )

   @ 3, 15 BUTTON "Salir" ACTION oDlg:End() CANCEL

   ACTIVATE DIALOG oDlg CENTERED 
     
return  nil

//-----------------------------------------------------------------------------

Function Registrar( cGeneralIni )
local cSerial, cRegist, lOk
local cDrive := hb_CurDrive( cGeneralIni )+":\"


 cSerial := alltrim(str(GetSerialHD( cDrive ) ))
 cRegist := GetRegistKey( cSerial )
 lok := CheckRegist( cSerial, cRegist, cGeneralIni )

if lok 
   msginfo("registro realizado") 
else
   msginfo("registro no realizado")
endif

Return nil

//-----------------------------------------------------------------------------

Function SetinGet( oget )
local cfile:= cGetFile( oget:cText )
  if !empty(cFile)
     oget:cText(cFile)
  endif

Return nil

//-----------------------------------------------------------------------------

FUNCTION GetSerialHD( cDrive )

   LOCAL cLabel      := Space(32)
   LOCAL cFileSystem := Space(32)
   LOCAL nSerial     := 0
   LOCAL nMaxComp    := 0
   LOCAL nFlags      := 0

   DEFAULT cDrive := "C:\"

   GetVolInfo( cDrive, @cLabel, Len( cLabel ), @nSerial, @nMaxComp, @nFlags, ;
               @cFileSystem, Len( cFileSystem ) )

RETURN nSerial

DLL32 Function GetVolInfo( sDrive          AS STRING, ;
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
               

//-----------------------------------------------------------------------------         

FUNCTION CheckRegist( cSerial, cRegist, cGeneralIni )

   LOCAL lOK := .F.
   
   if !file( cGeneralIni )
       msginfo("archivo ini no encontrado")
       return .f.
   endif

   IF ALLTRIM( cRegist ) == GetRegistKey( cSerial )
      WritePProString( "General", "RegistKey", ALLTRIM( cRegist ) , cGeneralIni )
      lOK := .T.
   ENDIF

RETURN ( lOK )


//-----------------------------------------------------------------------------        

FUNCTION GetRegistKey( cSerial )

   LOCAL cReg := ALLTRIM( STR( INT( ( VAL( ALLTRIM( cSerial ) ) * 167 ) * 4.12344 ), 30 ) )

   cReg := SUBSTR( cReg + ALLTRIM( STR( 47348147489715610655, 30 ) ), 1, 12 )

   cReg := CHR( VAL( SUBSTR( cReg, 8, 1 ) ) + 74 ) + ;
           CHR( VAL( SUBSTR( cReg, 4, 1 ) ) + 68 ) + ;
           CHR( VAL( SUBSTR( cReg, 2, 1 ) ) + 70 ) + ;
           CHR( VAL( SUBSTR( cReg, 6, 1 ) ) + 66 ) + ;
           SUBSTR( cReg, 5 )

RETURN ( cReg )      
