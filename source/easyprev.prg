 /*
    ==================================================================
    EasyPreview 1.4.8
    ------------------------------------------------------------------
    Authors: Jürgen Bäz
             Timm Sodtalbers
    ==================================================================
*/

#IFDEF __XPP__
   #INCLUDE "VRDXPP.ch"
#ELSE
   #INCLUDE "FiveWin.ch"
#ENDIF

#INCLUDE "STRUCT.CH"

STATIC cSetupFile   := NIL
STATIC cEP_Path     := ""
STATIC cEPIniPath   := ""
STATIC cEPIniFile   := "EPREVIEW.INI"
STATIC cEPLangFile  := "EPREVIEW.DBF"
STATIC lLinkedToApp := .T.
STATIC lWaitRun     := .F.

*-- FUNCTION -----------------------------------------------------------------
* Name........: RPreview
* Description.: Calls EPreview to display the preview EMF based
* Parameters..: oPrn - the print object
* Return value: none
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION RPreview( oPrn )

   LOCAL aSize, cAppPath
   LOCAL cIni := cSetupFile

   DEFAULT cIni := oPrn:cDir + "\EPREVIEW.TMP"

   IF oPrn:lMeta .AND. LEN( oPrn:aMeta ) > 0 .and. oPrn:hDC <> 0

      WritePProString( "General", "Printer"    , oPrn:GetModel(), cIni )
      WritePProString( "General", "Path"       , oPrn:cDir      , cIni )
      WritePProString( "General", "Document"   , oPrn:cDocument , cIni )
      WritePProString( "General", "Orientation", ALLTRIM( STR( PrnGetOrientation() )), cIni )
      WritePProString( "General", "ParentWnd"  , "", cIni )
      //WritePProString( "General", "ParentWnd"  , ALLTRIM( STR( WndMain():hWnd, 20 )), cIni )
      WritePProString( "General", "Copies"     , ALLTRIM( STR( PrnGetCopies(), 20 )), cIni )
      WritePProString( "General", "Bin"        , ALLTRIM( STR( PrnBinSource(), 20 )), cIni )

      WritePProString( "General", "HorzRes", ALLTRIM( STR( oPrn:nHorzRes(), 10 )), cIni )
      WritePProString( "General", "VertRes", ALLTRIM( STR( oPrn:nVertRes(), 10 )), cIni )

      aSize := oPrn:GetPhySize()
      WritePProString( "General", "Width"    , ALLTRIM( STR( aSize[1], 10, 2 )), cIni )
      WritePProString( "General", "Height"   , ALLTRIM( STR( aSize[2], 10, 2 )), cIni )
      WritePProString( "General", "PaperType", "0", cIni )

      WritePProString( "General", "IniFilePath" , cEPIniPath , cIni )
      WritePProString( "General", "IniFileName" , cEPIniFile , cIni )
      WritePProString( "General", "LanguageFile", cEPLangFile, cIni )

      IF lLinkedToApp = .T.

         //IIF( EMPTY( cEP_Path ),, lChDir( cEP_Path + "\" ) )
         EasyPreview( oPrn,, cIni )
         //IIF( EMPTY( cEP_Path ),, lChDir( cFilePath( GetModuleFileName( GetInstance() ) ) ) )

      ELSE

         #IFDEF __HARBOUR__

            ShellExecute( 0, "OPEN", "EPREVIEW", cIni, cEP_Path, 1 )

         #ELSE

            IF FILE( cEP_Path + IIF( EMPTY( cEP_Path ), "", "\" ) + "EPREVIEW.EXE" ) = .F.

               MsgStop( UPPER( cEP_Path ) + IIF( EMPTY( cEP_Path ), "", "\" ) + ;
                  "EPREVIEW.EXE not found!" )

            ELSE

               CursorWait()

               IIF( EMPTY( cEP_Path ),, lChDir( EP_LF2SF( cEP_Path + "\" ) ) )

               IF lWaitRun = .T.
                  WaitRun( ALLTRIM( "EPREVIEW.EXE " + cIni ) )
               ELSE
                  EP_WinExec( ALLTRIM( "EPREVIEW.EXE " + cIni ) )
               ENDIF

               IIF( EMPTY( cEP_Path ),, ;
                  lChDir( EP_LF2SF( cFilePath( GetModuleFileName( GetInstance() ) ) ) ) )

               CursorArrow()

            ENDIF

         #ENDIF

      ENDIF

   ENDIF

   oPrn:lMeta  := .F.
   oPrn:hDCOut := 0
   oPrn:End()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_UseWaitRun
* Description.:
* Parameters..:
* Return value: none
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_UseWaitRun( lUseWait )

  lWaitRun := lUseWait

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_SetSaveAtStart
* Description.:
* Parameters..:
* Return value: none
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_SetSaveAtStart( lValue )

   DEFAULT lValue := .F.

   WritePProString( "General", "SaveAtStart", IIF( lValue, "1", "0" ), EP_GetIniFile() )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_SetMailAtStart
* Description.:
* Parameters..:
* Return value: none
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_SetMailAtStart( lValue )

   DEFAULT lValue := .F.

   WritePProString( "General", "MailAtStart", IIF( lValue, "1", "0" ), EP_GetIniFile() )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_TidyUp
* Description.:
* Parameters..:
* Return value: none
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_TidyUp()

   LOCAL cTempDir  := EP_GetTempPath() + "\epreview"
   LOCAL aTmpFiles := DIRECTORY( cTempDir + "\*.*" )

   IF LEN( aTmpFiles ) > 0
      AEVAL( aTmpFiles, {|x,i| FERASE( cTempDir + "\" + aTmpFiles[i,1] ) } )
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_GetTempPath
* Description.:
* Parameters..:
* Return value: the windows temp directory
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_GetTempPath()

   LOCAL cDir := GetEnv("TEMP")

   IF EMPTY( cDir )
      cDir := GetEnv("TMP")
   ENDIF

   IF RIGHT( cDir, 1 ) == "\"
      cDir = SUBSTR( cDir, 1, LEN( cDir ) - 1 )
   ENDIF

   IF !EMPTY( cDir )
      IF !lIsDir( cDir )
         cDir := GetWinDir()
      ENDIF
   ELSE
      cDir := GetWinDir()
   ENDIF

RETURN ( cDir )


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_SetPath
* Description.:
* Parameters..:
* Return value: none
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_SetPath( cPath )

  cEP_Path := ALLTRIM( cPath )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_SetIniPath
* Description.:
* Parameters..:
* Return value: none
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_SetIniPath( cPath )

  cEPIniPath := ALLTRIM( cPath )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_SetIniName
* Description.:
* Parameters..:
* Return value: none
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_SetIniFile( cName )

  cEPIniFile := ALLTRIM( cName )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_SetTempFile
* Description.:
* Parameters..:
* Return value: none
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_SetTempFile( cName )

  cSetupFile := ALLTRIM( cName )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_SetLanguageName
* Description.:
* Parameters..:
* Return value: none
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_SetLanguageFile( cName )

  cEPLangFile := ALLTRIM( cName )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_WasPrinted
* Description.:
* Parameters..:
* Return value: .T. if the last preview was send to the printer
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_WasPrinted()

RETURN IIF( GetPvProfString( "Broadcast", "WasPrinted", "0", EP_GetIniFile() ) = "1", .T., .F. )


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_SetDemoMode
* Description.: The next preview runs in demo mode when you call this function
* Parameters..:
* Return value:
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_SetDemoMode( cMessage )

   DEFAULT cMessage := "The preview runs in demo mode!"

   WritePProString( "General", "DemoMessage", cMessage, EP_GetIniFile() )

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_LinkedToApp
* Description.:
* Parameters..:
* Return value:
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_LinkedToApp()

   lLinkedToApp := .T.

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_DirectPrint
* Description.: Directly prints all pages
* Parameters..:
* Return value:
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_DirectPrint( nFromPage, nToPage )

   LOCAL cIni := EP_GetIniFile()

   DEFAULT nFromPage := 1
   DEFAULT nToPage   := 0

   WritePProString( "General", "Direct", "1", cIni )
   WritePProString( "General", "DirectFrom", ALLTRIM(STR( nFromPage, 6 )), cIni )
   WritePProString( "General", "DirectTo"  , ALLTRIM(STR( nToPage  , 6 )), cIni )

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_DirectSave
* Description.: Directly saves the printout to file
* Parameters..:
* Return value:
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_DirectSave( nFromPage, nToPage )

   LOCAL cIni := EP_GetIniFile()

   DEFAULT nFromPage := 1
   DEFAULT nToPage   := 0

   WritePProString( "General", "Direct", "2", cIni )
   WritePProString( "General", "DirectFrom", ALLTRIM(STR( nFromPage, 6 )), cIni )
   WritePProString( "General", "DirectTo"  , ALLTRIM(STR( nToPage  , 6 )), cIni )

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_DirectMail
* Description.: Directly sends the printout
* Parameters..:
* Return value:
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_DirectMail( nFromPage, nToPage )

   LOCAL cIni := EP_GetIniFile()

   DEFAULT nFromPage := 1
   DEFAULT nToPage   := 0

   WritePProString( "General", "Direct", "3", cIni )
   WritePProString( "General", "DirectFrom", ALLTRIM(STR( nFromPage, 6 )), cIni )
   WritePProString( "General", "DirectTo"  , ALLTRIM(STR( nToPage  , 6 )), cIni )

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_SetSendTo
* Description.: Sets the email options
* Parameters..:
* Return value:
* Author......: Juergen Baez / Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_SetSendTo( cTo, cCc, cBcc, cSubject, cAddFiles )

   LOCAL cIni := EP_GetIniFile()

   IIF( cTo       <> NIL, WritePProString( "SendTo", "To"      , cTo      , cIni ), )
   IIF( cCc       <> NIL, WritePProString( "SendTo", "Cc"      , cCc      , cIni ), )
   IIF( cBcc      <> NIL, WritePProString( "SendTo", "Bcc"     , cBcc     , cIni ), )
   IIF( cSubject  <> NIL, WritePProString( "SendTo", "Subject" , cSubject , cIni ), )
   IIF( cAddFiles <> NIL, WritePProString( "SendTo", "AddFiles", cAddFiles, cIni ), )

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_GetIniFile
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_GetIniFile()

   LOCAL cIni := ".\" + cEPIniFile

   IF .NOT. EMPTY( cEP_Path )
      cIni := cEP_Path + ;
              IIF( SUBSTR( cEP_Path, LEN( cEP_Path ), 1 ) = "\", "", "\" ) + cEPIniFile
   ENDIF

   IF .NOT. EMPTY( cEPIniPath )
      cIni := cEPIniPath + ;
              IIF( SUBSTR( cEPIniPath, LEN( cEPIniPath ), 1 ) = "\", "", "\" ) + cEPIniFile
   ENDIF

RETURN ( cIni )


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_LF2SF
* Beschreibung: Long file to short file with path
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_LF2SF( cFile )

   #IFDEF __HARBOUR__
      RETURN( CFILE )
   #ELSE
      #IFDEF __XPP__
         RETURN( CFILE )
      #ELSE
         RETURN IIF( EMPTY( cFile ), "", EP_LPN2SPN( EP_GetFullPath( ALLTRIM( cFile ) ) ) )
      #ENDIF
   #ENDIF

RETURN NIL

#IFNDEF __HARBOUR__
#IFNDEF __XPP__

*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_LPN2SPN
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_LPN2SPN( cLPN )

   LOCAL cSPN:="", I, II := 1
   LOCAL lIsLastBackSlash := .T.

   IF RAT( "\", cLPN ) < LEN( ALLTRIM( cLPN ) )
      cLPN = ALLTRIM( cLPN ) + "\"
      lIsLastBackSlash := .F.
   ENDIF

   IF SUBSTR( cLPN, 2, 1 ) = ":"
      cSPN += SUBSTR( cLPN, 1, AT( "\", cLPN ) )
      ii := 2
   ENDIF

   FOR I := 4 TO LEN( cLPN )
      IF SUBSTR( cLPN, I, 1 ) = "\"
         cSPN += EP_LFN2SFN( cSPN + STRTOKEN( cLPN, ii, "\" ) )
         cSPN += "\"
         ii++
      ENDIF
   NEXT

   IF !lIsLastBackSlash
      cSPN := SUBSTR( cSPN, 1, LEN( cSPN ) -1 )
   ENDIF

RETURN cSPN


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_LFN2SFN
* Beschreibung: Long File Name to Short File Name (works with short too)
*               Guarantee a short file name (path not expanded)
*-----------------------------------------------------------------------------
FUNCTION EP_LFN2SFN( cSpec )

   LOCAL oWin32, c, h

   STRUCT oWin32
      MEMBER nFileAttributes  AS DWORD
      MEMBER nCreation        AS STRING LEN 8
      MEMBER nLastRead        AS STRING LEN 8
      MEMBER nLastWrite       AS STRING LEN 8
      MEMBER nSizeHight       AS DWORD
      MEMBER nSizeLow         AS DWORD
      MEMBER nReserved0       AS DWORD
      MEMBER nReserved1       AS DWORD
      MEMBER cFileName        AS STRING LEN 260
      MEMBER cAltName         AS STRING LEN  14
   ENDSTRUCT

   c := oWin32:cBuffer
   h := EP_FindFst(cSpec,@c)
   oWin32:cBuffer := c

   EP_FindCls(h)

RETURN if(empty(EP_PSZ(oWin32:cAltName)),EP_PSZ(oWin32:cFileName),EP_PSZ(oWin32:cAltName))


*-- FUNCTION -----------------------------------------------------------------
*         Name: EP_PSZ
*  Description: Truncate a zero-terminated string to a proper size
*    Arguments: cZString - string containing zeroes
* Return Value: cString  - string without zeroes
*-----------------------------------------------------------------------------
FUNCTION EP_PSZ( c )
RETURN substr( c, 1, AT( CHR( 0 ), c ) - 1 )


*-- FUNCTION -----------------------------------------------------------------
* Name........: EP_GetFullPath
* Beschreibung: Short File Name to Long Path Name (works with long too)
*               Returns a complete, LONG pathname and LONG filename.
*-----------------------------------------------------------------------------
Function EP_GetFullPath( cSpec )

   LOCAL cLongName := Space(261)
   LOCAL nNamePos  := 0

   EP_FullPathName( cSpec, Len( cLongName ), @cLongName, @nNamePos )

RETURN ALLTRIM( cLongName )

#ENDIF
#ENDIF


*-- FUNCTION -----------------------------------------------------------------
*         Name: EP_WinExec
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EP_WinExec( cCommand )

   IF GetVersion()[3] = 5
      TempWinExec( cCommand, 7 )
   ELSE
      TempWinExec( cCommand )
   ENDIF

RETURN (.T.)


DLL32 Function EP_FindFst( lpFilename AS LPSTR, @cWin32DataInfo AS LPSTR ) AS LONG PASCAL ;
   FROM "FindFirstFileA" LIB "KERNEL32.DLL"

DLL32 Function EP_FindCls( nHandle AS LONG ) AS BOOL PASCAL ;
   FROM "FindClose" LIB "KERNEL32.DLL"

DLL32 Function EP_FullPathName( lpszFile AS LPSTR, cchPath AS DWORD,;
               lpszPath AS LPSTR, @nFilePos AS PTR ) AS DWORD ;
               PASCAL FROM "GetFullPathNameA" LIB "kernel32.dll"

DLL32 Function TempWinExec( lpCmdLine AS LPSTR, nCmdShow AS LONG ) AS BOOL PASCAL ;
               FROM "WinExec" LIB "KERNEL32.DLL"