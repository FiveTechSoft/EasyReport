
STATIC cEP_Path     := ""
STATIC cEPIniPath   := ""
STATIC lLinkedToApp := .T.

//----------------------------------------------------------------------

FUNCTION EP_LinkedToApp()

   lLinkedToApp := .T.

RETURN NIL

//----------------------------------------------------------------------

FUNCTION EP_SetPath( cPath )

  cEP_Path := ALLTRIM( cPath )

RETURN (.T.)

//--------------------------------------------------------------------

FUNCTION EP_TidyUp()

   LOCAL cTempDir  := EP_GetTempPath() + "\epreview"
   LOCAL aTmpFiles := DIRECTORY( cTempDir + "\*.*" )

   IF LEN( aTmpFiles ) > 0
      AEVAL( aTmpFiles, {|x,i| FERASE( cTempDir + "\" + aTmpFiles[i,1] ) } )
   ENDIF

RETURN (.T.)

//--------------------------------------------------------------------

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

