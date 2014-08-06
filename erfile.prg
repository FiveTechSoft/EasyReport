
#INCLUDE "Folder.ch"
#INCLUDE "FiveWin.ch"
#INCLUDE "Treeview.ch"

MEMVAR aItems, aFonts, oAppFont, aAreaIni, aWnd, aWndTitle, oBar, oMru
MEMVAR oCbxArea, aCbxItems, nAktuellItem, aRuler, cLongDefIni, cDefaultPath
MEMVAR nAktItem, nAktArea, nSelArea, cAktIni, aSelection, nTotalHeight, nTotalWidth
MEMVAR nHinCol1, nHinCol2, nHinCol3, oMsgInfo, oGenVar
MEMVAR aVRDSave, lVRDSave, lFillWindow, nDeveloper, oRulerBmp1, oRulerBmp2
MEMVAR lBoxDraw, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight
MEMVAR cItemCopy, nCopyEntryNr, nCopyAreaNr, aSelectCopy, aItemCopy, nXMove, nYMove
MEMVAR cInfoWidth, cInfoHeight, nInfoRow, nInfoCol, aItemPosition, aItemPixelPos
MEMVAR oClpGeneral, cDefIni, cDefIniPath, cGeneralIni, nMeasure, cMeasure, lDemo, lBeta, oTimer
MEMVAR oMainWnd, lProfi, nUndoCount, nRedoCount, nDlgTextCol, nDlgBackCol

*-- FUNCTION -----------------------------------------------------------------
* Name........: OpenFile
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION OpenFile( cFile )

   LOCAL i
   LOCAL cLongFile  := cFile
   LOCAL cMainTitle := ""

   IF cFile = NIL
      cLongFile   := GetFile( GL("Designer Files") + " (*.vrd)|*.vrd|" + ;
                              GL("All Files") + " (*.*)|*.*", GL("Open"), 1 )
   ENDIF

   cLongDefIni := cLongFile
   cFile       := VRD_LF2SF( cLongFile )

   IF AT( "[AREAS]", UPPER( MEMOREAD( cFile ) ) ) = 0 .AND. .NOT. EMPTY( cFile )
      MsgStop( ALLTRIM( cLongFile ) + CRLF + CRLF + GL("is not a valid file."), GL("Stop!") )
      RETURN( .F. )
   ENDIF

   // Neustart des Programmes
   IF .NOT. EMPTY( cFile ) .AND. oGenVar:lFirstFile = .F.
      oGenVar:cLoadFile := cFile
      oMainWnd:End()
      RETURN (.T.)
   ENDIF

   // Aufruf des neuen Reports im gleichen Frame gibt optische Probleme
   IF .NOT. EMPTY( cFile )

      oGenVar:lFirstFile := .F.

      oMainWnd:CloseAll()

      aItems    := NIL
      aAreaIni  := NIL
      aWnd      := NIL
      aWndTitle := NIL
      aRuler    := NIL
      MEMORY(-1)
      SYSREFRESH()

      aItems    := Array( 100, 1000 )
      aAreaIni  := Array( 100 )
      aWnd      := Array( 100 )
      aWndTitle := Array( 100 )
      aRuler    := Array( 100, 2 )

      //Fontobjekte beenden
      FOR i := 1 TO 20
         IF aFonts[i] <> NIL
            aFonts[i]:End()
         ENDIF
      NEXT
      aFonts := Array( 20 )

      SysRefresh()

      cDefIni := cFile
      IF AT( "\", cDefIni ) = 0
         cDefIni := ".\" + cDefIni
      ENDIF

      cDefIniPath := CheckPath( cFilePath( cDefIni ) )

      SetGeneralSettings()

      //Fonts definieren
      DefineFonts()
      //Areas initieren
      IF oCbxArea = NIL
      ELSE
         oCbxArea:End()
      ENDIF

      IniAreasOnBar()
      //Designwindows öffnen
      ClientWindows()
      //Areas anzeigen
      ShowAreasOnBar()

      SysRefresh()

      ClearUndoRedo() // and refresh the bar

      cMainTitle      := ALLTRIM( GetPvProfString( "General", "Title", "", cDefIni ) )
      oMainWnd:cTitle := MainCaption()

      SetScrollBar()

      oMainWnd:SetMenu( BuildMenu() )

      SetSave( .T. )

      IF VAL( GetPvProfString( "General", "MruList"  , "4", cGeneralIni ) ) > 0
         oMru:Save( cLongDefIni )
      ENDIF

      CreateBackup()

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: CreateBackup
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CreateBackup()

   LOCAL nArea

   IF VAL( GetPvProfString( "General", "CreateBackup", "0", cGeneralIni ) ) = 1

      CopyFile( cDefIni, STUFF( cDefIni, RAT( ".", cDefIni ), 1, "_backup." ) )

      FOR nArea := 1 TO LEN( aAreaIni )

         IF .NOT. EMPTY( aAreaIni[nArea] )
            CopyFile( aAreaIni[nArea], ;
               STUFF( aAreaIni[nArea], RAT( ".", aAreaIni[nArea] ), 1, "_backup." ) )
         ENDIF

      NEXT

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: SaveFile
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SaveFile()

   LOCAL nArea

   aVRDSave := ARRAY( 102, 2 )

   aVRDSave[101,1] := cDefIni
   aVRDSave[101,2] := MEMOREAD( cDefIni )
   aVRDSave[102,1] := cGeneralIni
   aVRDSave[102,2] := MEMOREAD( cGeneralIni )

   FOR nArea := 1 TO LEN( aAreaIni )

      aVRDSave[nArea,1] := aAreaIni[nArea]
      aVRDSave[nArea,2] := MEMOREAD( aAreaIni[nArea] )

   NEXT

   SetSave( .T. )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: SaveAsFile
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SaveAsFile()

   LOCAL cFile := GetFile( GL("Designer Files") + " (*.vrd)|*.vrd|" + ;
                           GL("All Files") + " (*.*)|*.*", GL("Save as"), 1,, .T. )

   IF .NOT. EMPTY( cFile )
      VRD_MsgRun( GL("Please wait..."), ;
         STRTRAN( GL("Save &as"), "&", "" ), {|| SaveAs( cFile ) } )
   ENDIF

RETURN NIL


*-- FUNCTION -----------------------------------------------------------------
* Name........: SaveAs
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SaveAs( cFile )

   LOCAL i, nArea, cAreaFile, cAltDefIni

   cLongDefIni := cFile

   IF EMPTY( cFileExt( cFile ) )
      cFile += ".vrd"
   ELSEIF UPPER( cFileExt( cFile ) ) <> "VRD"
      cFile := ALLTRIM( cFile )
      cFile := SUBSTR( cFile, 1, RAT( UPPER(ALLTRIM(cFileExt( cFile ))), UPPER( cFile ) ) - 1 ) + "vrd"
   ENDIF

   IF FILE( VRD_LF2SF( cFile ) ) = .T.
      IF MsgNoYes( GL("The file already exists.") + CRLF + CRLF + ;
                   GL("Overwrite?"), GL("Save as") ) = .F.
         RETURN( .F. )
      ELSE
         cAltDefIni := VRD_LF2SF( ALLTRIM( cFile ) )
         IIF( AT( "\", cAltDefIni ) = 0, cAltDefIni := ".\" + cAltDefIni, )
         FOR i := 1 TO 100
            DelFile( VRD_LF2SF( ALLTRIM( GetPvProfString( "Areas", ALLTRIM(STR(i,5)) , "", cAltDefIni ) ) ) )
         NEXT
         DelFile( cAltDefIni )
      ENDIF
   ENDIF

   CreateNewFile( cFile )

   IF .NOT. EMPTY( cFile )

      cDefIni := VRD_LF2SF( ALLTRIM( cFile ) )

      IF AT( "\", cDefIni ) = 0
         cDefIni := ".\" + cDefIni
      ENDIF

      aVRDSave[101,1] := cDefIni
      MEMOWRIT( aVRDSave[101,1], aVRDSave[101,2] )
      MEMOWRIT( aVRDSave[102,1], aVRDSave[102,2] )

      //Alte Areas löschen
      DelIniSection( "Areas", cDefIni )

      //Areas abspeichern
      FOR nArea := 1 TO LEN( aAreaIni )

         IF .NOT. EMPTY( aVRDSave[nArea,1] )

            cAreaFile := SUBSTR( cFile, 1, LEN( cFile )-2 ) + PADL( ALLTRIM( STR( nArea, 2) ), 2, "0" )
            CreateNewFile( cAreaFile )

            aVRDSave[nArea,1] := VRD_LF2SF( cAreaFile )
            //aVRDSave[nArea,1] := SUBSTR( cDefIni, 1, LEN( cDefIni )-2 ) + ;
            //                  PADL( ALLTRIM( STR( nArea, 2) ), 2, "0" )
            MEMOWRIT( aVRDSave[nArea,1], aVRDSave[nArea,2] )

            aAreaIni[nArea] := aVRDSave[nArea,1]

            //Areas in General Ini File ablegen
            WritePProString( "Areas", ALLTRIM(STR( nArea, 3)), cFileName( cAreaFile ), cDefIni )

         ENDIF

         //Areapfad speichern
         WritePProString( "General", "AreaFilesDir", cFilePath( cDefIni ), cDefIni )

      NEXT

      SetSave( .T. )

      IF VAL( GetPvProfString( "General", "MruList"  , "4", cGeneralIni ) ) > 0
         oMru:Save( cLongDefIni )
      ENDIF

   ENDIF


RETURN (.T.)

*-- FUNCTION -----------------------------------------------------------------
* Name........: NoSaveFiles
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION AskSaveFiles()

   LOCAL nArea, nSave
   LOCAL lReturn := .T.

   IF lVRDSave = .F.

      nSave := MessageBox( oMainWnd:hWnd, ;
                           GL("Your changes are not saved.") + CRLF + CRLF + ;
                           GL("Save the current report?"), GL("Save"), 35 )

      IF nSave = 7
         MEMOWRIT( aVRDSave[101,1], aVRDSave[101,2] )
         MEMOWRIT( aVRDSave[102,1], aVRDSave[102,2] )
         FOR nArea := 1 TO LEN( aAreaIni )
            MEMOWRIT( aVRDSave[nArea,1], aVRDSave[nArea,2] )
         NEXT
      ELSEIF nSave = 6
         SetSaveInfos()
      ELSE
         oGenVar:cLoadFile := ""
         lReturn := .F.
      ENDIF

   ENDIF

   IF .NOT. EMPTY( oGenVar:cLoadFile )
      ShellExecute( 0, "Open", GetModuleFileName( GetInstance() ), oGenVar:cLoadFile, NIL, 1 )
   ENDIF

RETURN ( lReturn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: FileInfos
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION FileInfos()

   LOCAL i, oDlg, oBrw, cAreaDef, aFileInfo, oFld, nWnd, oIni, cLastSave
   LOCAL lSave        := .F.
   LOCAL aFiles       := { { GL("General"), ALLTRIM( cLongDefIni ) } }
   LOCAL cTitle       := PADR( GetPvProfString( "General", "Title", "", cDefIni ), 80 )
   LOCAL cGroup       := PADR( GetPvProfString( "General", "Group", "", cDefIni ), 80 )
   LOCAL aIniEntries  := GetIniSection( "Infos", cDefIni )
   LOCAL cAuthor      := PADR( GetIniEntry( aIniEntries, "Author" ), 100 )
   LOCAL cCompany     := PADR( GetIniEntry( aIniEntries, "Company" ), 100 )
   LOCAL cComment     := PADR( GetIniEntry( aIniEntries, "Comment" ), 200 )
   LOCAL cSaveDate    := GetIniEntry( aIniEntries, "SaveDate" )
   LOCAL cSaveTime    := GetIniEntry( aIniEntries, "SaveTime" )
   LOCAL cRevision    := GetIniEntry( aIniEntries, "Revision", "0" )
   LOCAL nNrItems     := 0
   LOCAL nNrAreas     := 0
   LOCAL aAreaEntries := GetIniSection( "Areas", cDefIni )

   IF EMPTY( cSaveDate )
      cLastSave := "-"
   ELSE
      cLastSave := cSaveDate + "  " + cSaveTime
   ENDIF

   FOR i := 1 TO LEN( aAreaEntries )
      IF VAL( aAreaEntries[i] ) <> 0
         nWnd := EntryNr( aAreaEntries[i] )
         cAreaDef := GetIniEntry( aAreaEntries,, "",, i )
         IF .NOT. EMPTY( cAreaDef )
            AADD( aFiles, { aWndTitle[nWnd], cAreaDef } )
         ENDIF
      ENDIF
   NEXT

   AEVAL( aWnd, {|x| IIF( x <> NIL, ++nNrAreas, ) } )
   FOR i := 1 TO 100
      IF aItems[i] <> NIL
         AEVAL( aItems[i], {|x| IIF( x <> NIL, ++nNrItems, ) } )
      ENDIF
   NEXT

   DEFINE DIALOG oDlg NAME "FILEINFOS" TITLE GL("File Informations")

   REDEFINE FOLDER oFld ID 301 OF oDlg ;
      PROMPT " " + GL("General") + " ", ;
             " " + GL("File List") + " " ;
      DIALOGS "FILEINFOS1", ;
              "FILEINFOS2"

   i := 1
   REDEFINE GET cTitle   ID 201 OF oFld:aDialogs[i]
   REDEFINE GET cGroup   ID 202 OF oFld:aDialogs[i]

   REDEFINE GET cAuthor  ID 203 OF oFld:aDialogs[i]
   REDEFINE GET cCompany ID 204 OF oFld:aDialogs[i]
   REDEFINE GET cComment ID 205 OF oFld:aDialogs[i]

   REDEFINE SAY PROMPT cLastSave                   ID 301 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT cRevision                   ID 302 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT ALLTRIM(STR( nNrAreas, 5 )) ID 303 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT ALLTRIM(STR( nNrItems, 5 )) ID 304 OF oFld:aDialogs[i]

   REDEFINE SAY PROMPT GL("Name") +":"         ID 181 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Group") +":"        ID 182 OF oFld:aDialogs[i]

   REDEFINE SAY PROMPT GL("Author") +":"       ID 183 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Company") +":"      ID 184 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Comment") +":"      ID 185 OF oFld:aDialogs[i]

   REDEFINE SAY PROMPT GL("Last saved") +":"   ID 171 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Revision") +":"     ID 172 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("No. of areas") +":" ID 173 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("No. of items") +":" ID 174 OF oFld:aDialogs[i]

   REDEFINE LISTBOX oBrw ;
      FIELDS "", "" ;
      FIELDSIZES 180, 180 ;
      HEADERS " " + GL("Area"), " " + GL("File name") ;
      ID 301 OF oFld:aDialogs[2]

   oBrw:nAt       = 1
   oBrw:bLine     = { || { aFiles[oBrw:nAt][1], aFiles[oBrw:nAt][2] } }
   oBrw:bGoTop    = { || oBrw:nAt := 1 }
   oBrw:bGoBottom = { || oBrw:nAt := Eval( oBrw:bLogicLen ) }
   oBrw:bSkip     = { | nWant, nOld | nOld := oBrw:nAt, oBrw:nAt += nWant,;
                        oBrw:nAt := Max( 1, Min( oBrw:nAt, Eval( oBrw:bLogicLen ) ) ),;
                        oBrw:nAt - nOld }
   oBrw:bLogicLen = { || Len( aFiles ) }
   oBrw:cAlias    = "Array"

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   ACTIVATE DIALOG oDlg CENTER

   IF lSave = .T.

      INI oIni FILE cDefIni
         SET SECTION "General" ENTRY "Title"   TO ALLTRIM( cTitle ) OF oIni
         SET SECTION "General" ENTRY "Group"   TO ALLTRIM( cGroup ) OF oIni
         SET SECTION "Infos"   ENTRY "Author"  TO RTRIM( cAuthor )  OF oIni
         SET SECTION "Infos"   ENTRY "Company" TO RTRIM( cCompany ) OF oIni
         SET SECTION "Infos"   ENTRY "Comment" TO RTRIM( cComment ) OF oIni
      ENDINI

      oMainWnd:cTitle := MainCaption()

      SetSave( .F. )

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: SetSave
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetSave( lSave )

   IF lSave = .T.
      lVRDSave := .T.
      SetSaveInfos()
   ELSE
      lVRDSave := .F.
   ENDIF

   oBar:AEvalWhen()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: SetSaveInfos
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetSaveInfos()

   LOCAL oIni

   INI oIni FILE cDefIni
      SET SECTION "Infos" ENTRY "Revision" TO ;
         ALLTRIM(STR( VAL( GetPvProfString( "Infos", "Revision", "0", cDefIni ) ) + 1, 5 )) OF oIni
      SET SECTION "Infos" ENTRY "SaveDate" TO ALLTRIM( DTOC( DATE() ) ) OF oIni
      SET SECTION "Infos" ENTRY "SaveTime" TO TIME() OF oIni
   ENDINI

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: NewReport
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION NewReport()

   LOCAL i, y, oDlg, oFld, oFont, oBrw, cTmpFile, oRad1, oRad2
   LOCAL aGet[3], aBtn[2], aGet2[1], aCbx1[1], aCbx2[1], aCbx3[8], aCheck[9]
   LOCAL nAltSel      := SELECT()
   LOCAL lCreate      := .F.
   LOCAL aMeasure     := { "mm", "inch", "pixel" }
   LOCAL cMeasure     := aMeasure[1]
   LOCAL cGeneralName := SPACE(100)
   LOCAL cSourceCode  := SPACE(100)
   LOCAL cReportName  := SPACE(100)
   LOCAL lMakeSource  := .F.
   LOCAL nTop         := 20
   LOCAL nLeft        := 20
   LOCAL nPageBreak   := 270
   LOCAL nOrient      := 1

   //Defaults
   AFILL( aCheck, .T. )

   DEFINE FONT oFont NAME "Arial" SIZE 0, -12

   DEFINE DIALOG oDlg NAME "NEWREPORT" TITLE GL("New Report")

   REDEFINE BUTTON PROMPT GL("Create &Report") ID 101 OF oDlg ;
      ACTION IIF( CheckFileName( @cGeneralName, cSourceCode, lMakeSource ) = .T., ;
                  EVAL( {|| lCreate := .T., oDlg:End() } ), )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE FOLDER oFld ID 110 OF oDlg ;
      PROMPT " " + GL("General") + " ", ;
             " " + GL("Areas") + " " ;
      DIALOGS "NEWFOLDER1", ;
              "NEWFOLDER2"

   i := 1
   REDEFINE SAY PROMPT " " + GL("General report file name") ID 171 OF oFld:aDialogs[i] COLOR nDlgTextCol, nDlgBackCol FONT oFont
   REDEFINE SAY PROMPT " " + GL("Source code file name")    ID 172 OF oFld:aDialogs[i] COLOR nDlgTextCol, nDlgBackCol FONT oFont
   REDEFINE SAY PROMPT " " + GL("Report name")              ID 173 OF oFld:aDialogs[i] COLOR nDlgTextCol, nDlgBackCol FONT oFont
   REDEFINE SAY PROMPT " " + GL("Measure")                  ID 175 OF oFld:aDialogs[i] COLOR nDlgTextCol, nDlgBackCol FONT oFont
   REDEFINE SAY PROMPT " " + GL("Paper size")               ID 176 OF oFld:aDialogs[i] COLOR nDlgTextCol, nDlgBackCol FONT oFont
   REDEFINE SAY PROMPT " " + GL("Orientation")              ID 177 OF oFld:aDialogs[i] COLOR nDlgTextCol, nDlgBackCol FONT oFont
   REDEFINE SAY PROMPT " " + GL("General settings")         ID 178 OF oFld:aDialogs[i] COLOR nDlgTextCol, nDlgBackCol FONT oFont

   REDEFINE SAY PROMPT GL("Top:")         ID 181 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Left:")        ID 182 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Page break:")  ID 183 OF oFld:aDialogs[i]

   REDEFINE GET aGet[1] VAR cGeneralName ID 201 OF oFld:aDialogs[i] UPDATE
   REDEFINE GET aGet[2] VAR cSourceCode  ID 202 OF oFld:aDialogs[i] UPDATE
   REDEFINE GET aGet[3] VAR cReportName  ID 203 OF oFld:aDialogs[i] UPDATE

   REDEFINE BTNBMP aBtn[1] ID 151 OF oFld:aDialogs[i] RESOURCE "B_OPEN" UPDATE ;
      TOOLTIP GL("Open") ;
      ACTION ( cTmpFile := GetFile( GL("Designer Files") + " (*.vrd)|*.vrd|" + ;
                                    GL("All Files") + " (*.*)|*.*", ;
                                    GL("General report file name"), 1 ), ;
               IIF( EMPTY( cTmpFile ),, cGeneralName := cTmpFile ), ;
               aGet[1]:Refresh() )

   REDEFINE BTNBMP aBtn[2] ID 152 OF oFld:aDialogs[i] RESOURCE "B_OPEN" UPDATE ;
      TOOLTIP GL("Open") ;
      ACTION ( cTmpFile := GetFile( GL("All Files") + " (*.*)|*.*", ;
                                    GL("Source code file name"), 1 ), ;
               IIF( EMPTY( cTmpFile ),, cSourceCode := cTmpFile ), ;
               aGet[2]:Refresh() )

   REDEFINE CHECKBOX aCbx1[1] VAR lMakeSource ID 301 OF oFld:aDialogs[i]
   REDEFINE COMBOBOX cMeasure  ITEMS aMeasure  ID 303 OF oFld:aDialogs[i]

   REDEFINE GET nTop       ID 401 OF oFld:aDialogs[i] PICTURE "9999.99" SPINNER MIN 0
   REDEFINE GET nLeft      ID 402 OF oFld:aDialogs[i] PICTURE "9999.99" SPINNER MIN 0
   REDEFINE GET nPageBreak ID 403 OF oFld:aDialogs[i] PICTURE "9999.99" SPINNER MIN 0

   REDEFINE RADIO oRad1 VAR nOrient ID 601, 602 OF oFld:aDialogs[i]

   REDEFINE CHECKBOX aCbx3[1] VAR aCheck[1] ID 501 OF oFld:aDialogs[i]
   REDEFINE CHECKBOX aCbx3[2] VAR aCheck[2] ID 502 OF oFld:aDialogs[i]
   REDEFINE CHECKBOX aCbx3[3] VAR aCheck[3] ID 503 OF oFld:aDialogs[i]
   REDEFINE CHECKBOX aCbx3[4] VAR aCheck[4] ID 504 OF oFld:aDialogs[i]
   REDEFINE CHECKBOX aCbx3[5] VAR aCheck[5] ID 505 OF oFld:aDialogs[i]
   REDEFINE CHECKBOX aCbx3[6] VAR aCheck[6] ID 506 OF oFld:aDialogs[i]
   REDEFINE CHECKBOX aCbx3[7] VAR aCheck[7] ID 507 OF oFld:aDialogs[i]
   REDEFINE CHECKBOX aCbx3[8] VAR aCheck[8] ID 508 OF oFld:aDialogs[i]

   i := 2
   SELECT 0
   CREATE VRDTMPST

   APPEND BLANK
   REPLACE FIELD_NAME WITH "NAME"   , FIELD_TYPE WITH "C", FIELD_LEN WITH 120, FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "TEXTNR" , FIELD_TYPE WITH "N", FIELD_LEN WITH 4  , FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "IMAGENR", FIELD_TYPE WITH "N", FIELD_LEN WITH 4  , FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "GRAPHNR", FIELD_TYPE WITH "N", FIELD_LEN WITH 4  , FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "BCODENR", FIELD_TYPE WITH "N", FIELD_LEN WITH 4  , FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "TOP1"   , FIELD_TYPE WITH "N", FIELD_LEN WITH 6  , FIELD_DEC WITH 2
   APPEND BLANK
   REPLACE FIELD_NAME WITH "TOP2"   , FIELD_TYPE WITH "N", FIELD_LEN WITH 6  , FIELD_DEC WITH 2
   APPEND BLANK
   REPLACE FIELD_NAME WITH "LTOP"   , FIELD_TYPE WITH "L", FIELD_LEN WITH 0  , FIELD_DEC WITH 0
   APPEND BLANK
   REPLACE FIELD_NAME WITH "WIDTH"  , FIELD_TYPE WITH "N", FIELD_LEN WITH 6  , FIELD_DEC WITH 2
   APPEND BLANK
   REPLACE FIELD_NAME WITH "HEIGHT" , FIELD_TYPE WITH "N", FIELD_LEN WITH 6  , FIELD_DEC WITH 2
   APPEND BLANK
   REPLACE FIELD_NAME WITH "CONDITION" , FIELD_TYPE WITH "N", FIELD_LEN WITH 1  , FIELD_DEC WITH 0

   CREATE VRDTMP FROM VRDTMPST

   USE VRDTMP.DBF ALIAS "AREAS"
   APPEND BLANK
   REPLACE AREAS->NAME WITH "1. " + GL("Area")
   SetNewReportDefaults()

   REDEFINE LISTBOX oBrw ;
      FIELDS AREAS->NAME ;
      HEADERS " " + GL("Name") ;
      ID 301 OF oFld:aDialogs[i] FONT oFont ;
      ON CHANGE ( oDlg:Update(), aGet2[1]:SetFocus() )

   REDEFINE BUTTON PROMPT GL("&New") ID 101 OF oFld:aDialogs[i] UPDATE ;
      ACTION ( AREAS->(DBAPPEND()), SetNewReportDefaults(), ;
               oBrw:Refresh(), oBrw:GoBottom(), oDlg:Update() )
   REDEFINE BUTTON PROMPT GL("&Delete") ID 102 OF oFld:aDialogs[i] UPDATE ;
      ACTION ( AREAS->(DBDELETE()), AREAS->(DBPACK()), ;
               oBrw:GoTop(), oBrw:Refresh(), oDlg:Update() ) ;
      WHEN AREAS->(LASTREC()) > 1
   REDEFINE BUTTON PROMPT GL("Move &up") ID 103 OF oFld:aDialogs[i] UPDATE ;
      ACTION ( MoveRecord( .T., oBrw ), oBrw:Refresh(), oDlg:Update() ) ;
      WHEN AREAS->(RECNO()) <> 1
   REDEFINE BUTTON PROMPT GL("Move &down") ID 104 OF oFld:aDialogs[i] UPDATE ;
      ACTION ( MoveRecord( .F., oBrw ), oBrw:Refresh(), oDlg:Update() ) ;
      WHEN AREAS->(RECNO()) <> AREAS->(LASTREC())

   REDEFINE SAY PROMPT " " + GL("Name")            ID 191 OF oFld:aDialogs[i] COLOR nDlgTextCol, nDlgBackCol FONT oFont
   REDEFINE SAY PROMPT " " + GL("Number of Items") ID 192 OF oFld:aDialogs[i] COLOR nDlgTextCol, nDlgBackCol FONT oFont
   REDEFINE SAY PROMPT " " + GL("Position")        ID 193 OF oFld:aDialogs[i] COLOR nDlgTextCol, nDlgBackCol FONT oFont
   REDEFINE SAY PROMPT " " + GL("Size")            ID 194 OF oFld:aDialogs[i] COLOR nDlgTextCol, nDlgBackCol FONT oFont
   REDEFINE SAY PROMPT " " + GL("Print Condition") ID 195 OF oFld:aDialogs[i] COLOR nDlgTextCol, nDlgBackCol FONT oFont

   REDEFINE SAY PROMPT GL("Page = 1:")     ID 170 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Page > 1:")     ID 171 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Top:")          ID 172 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Top:")          ID 173 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("previous area") ID 174 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Width:")        ID 175 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Height:")       ID 176 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Text") + ":"    ID 177 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Image") + ":"   ID 178 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Graphic") + ":" ID 179 OF oFld:aDialogs[i]
   REDEFINE SAY PROMPT GL("Barcode") + ":" ID 180 OF oFld:aDialogs[i]

   REDEFINE GET aGet2[1] VAR AREAS->NAME ID 201 OF oFld:aDialogs[i] UPDATE ;
      VALID ( oBrw:Refresh(), !EMPTY( AREAS->NAME ) )
   REDEFINE GET AREAS->TEXTNR  ID 202 OF oFld:aDialogs[i] UPDATE SPINNER MIN 0 MAX 99
   REDEFINE GET AREAS->IMAGENR ID 203 OF oFld:aDialogs[i] UPDATE SPINNER MIN 0 MAX 99
   REDEFINE GET AREAS->GRAPHNR ID 204 OF oFld:aDialogs[i] UPDATE SPINNER MIN 0 MAX 99
   REDEFINE GET AREAS->BCODENR ID 205 OF oFld:aDialogs[i] UPDATE SPINNER MIN 0 MAX 99

   REDEFINE GET AREAS->TOP1 ID 401 OF oFld:aDialogs[i] PICTURE "9999.99" SPINNER MIN 0 UPDATE WHEN AREAS->LTOP = .F.
   REDEFINE GET AREAS->TOP2 ID 402 OF oFld:aDialogs[i] PICTURE "9999.99" SPINNER MIN 0 UPDATE WHEN AREAS->LTOP = .F.
   REDEFINE CHECKBOX aCbx2[1] VAR AREAS->LTOP ID 303 OF oFld:aDialogs[i] UPDATE

   REDEFINE GET AREAS->WIDTH  ID 601 OF oFld:aDialogs[i] UPDATE PICTURE "9999.99" SPINNER MIN 0
   REDEFINE GET AREAS->HEIGHT ID 602 OF oFld:aDialogs[i] UPDATE PICTURE "9999.99" SPINNER MIN 0

   REDEFINE RADIO oRad2 VAR AREAS->CONDITION ID 501, 502, 503, 504 OF oFld:aDialogs[i] UPDATE

   ACTIVATE DIALOG oDlg CENTER ;
      ON INIT ( aCbx1[1]:SetText( GL("Create source code") ), ;
                aCbx3[1]:SetText( GL("Edit font and colors properties") ), ;
                aCbx3[2]:SetText( GL("Edit area properties") ), ;
                aCbx3[3]:SetText( GL("Use expressions") ), ;
                aCbx3[4]:SetText( GL("Developer mode") ), ;
                aCbx3[5]:SetText( GL("Insert items mode") ), ;
                aCbx3[6]:SetText( GL("Edit language") ), ;
                aCbx3[7]:SetText( GL("Show info message during printout") ), ;
                aCbx3[8]:SetText( GL("Print item ids from the designer") ), ;
                oRad1:aItems[1]:SetText( GL("Portrait") ), ;
                oRad1:aItems[2]:SetText( GL("Landscape") ), ;
                oRad2:aItems[1]:SetText( GL("always") ), ;
                oRad2:aItems[2]:SetText( GL("never") ), ;
                oRad2:aItems[3]:SetText( GL("page = 1") ), ;
                oRad2:aItems[4]:SetText( GL("page > 1") ), ;
                aCbx2[1]:SetText( GL("Top depends on") ) )

   oFont:End()

   IF lCreate = .T.
      VRD_MsgRun( GL("Please wait..."), GL("New Report"), ;
         {|| CreateNewReport( aCheck, cGeneralName, cSourceCode, cReportName, lMakeSource, ;
                              nTop, nLeft, nPageBreak, nOrient, aMeasure, cMeasure ) } )
   ENDIF

   AREAS->(DBCLOSEAREA())
   SELECT( nAltSel )

   ERASE VRDTMPST.DBF
   ERASE VRDTMP.DBF

   IF lCreate = .T.
      OpenFile( cGeneralName )
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: CreateNewReport
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CreateNewReport( aCheck, cGeneralName, cSourceCode, cReportName, lMakeSource, ;
                          nTop, nLeft, nPageBreak, nOrient, aMeasure, cMeasure )

   LOCAL i, nCol, nRow, nXCol, nXRow, nColStart, oIni, cSource
   LOCAL cAreaTmpFile, cDefTmpIni

   //General ini file
   CreateNewFile( cGeneralName )
   cLongDefIni := ALLTRIM( cGeneralName )
   cDefTmpIni  := ALLTRIM( cGeneralName )

   IF AT( "\", cDefTmpIni ) = 0
      cDefTmpIni := ".\" + cDefTmpIni
   ENDIF

   nMeasure := ASCAN( aMeasure, cMeasure )

   INI oIni FILE cDefTmpIni
      SET SECTION "General" ENTRY "Title"              TO cReportName OF oIni
      SET SECTION "General" ENTRY "TopMargin"          TO nTop OF oIni
      SET SECTION "General" ENTRY "LeftMargin"         TO nLeft OF oIni
      SET SECTION "General" ENTRY "PageBreak"          TO nPageBreak OF oIni
      SET SECTION "General" ENTRY "Measure"            TO nMeasure OF oIni
      SET SECTION "General" ENTRY "Orientation"        TO nOrient OF oIni
      SET SECTION "General" ENTRY "EditProperties"     TO IIF( aCheck[1], "1", "0" ) OF oIni
      SET SECTION "General" ENTRY "EditAreaProperties" TO IIF( aCheck[2], "1", "0" ) OF oIni
      SET SECTION "General" ENTRY "DeveloperMode"      TO IIF( aCheck[4], "1", "0" ) OF oIni
      SET SECTION "General" ENTRY "InsertMode"         TO IIF( aCheck[5], "1", "0" ) OF oIni
      SET SECTION "General" ENTRY "EditLanguage"       TO IIF( aCheck[6], "1", "0" ) OF oIni
      SET SECTION "General" ENTRY "ShowInfoMsg"        TO IIF( aCheck[7], "1", "0" ) OF oIni
      SET SECTION "General" ENTRY "PrintIDs"           TO IIF( aCheck[8], "1", "0" ) OF oIni
      SET SECTION "General" ENTRY "GridWidth"          TO 1 OF oIni
      SET SECTION "General" ENTRY "GridHeight"         TO 1 OF oIni
      SET SECTION "General" ENTRY "ShowGrid"           TO 0 OF oIni
      SET SECTION "General" ENTRY "Expressions"        TO IIF( aCheck[3], "1", "0" ) OF oIni
      SET SECTION "General" ENTRY "GeneralExpressions" TO "General.dbf" OF oIni
      SET SECTION "General" ENTRY "UserExpressions"    TO "User.dbf" OF oIni
      SET SECTION "General" ENTRY "DataExpressions"    TO "Database.dbf" OF oIni
      SET SECTION "General" ENTRY "AreaFilesDir"       TO cFilePath( cLongDefIni ) OF oIni

      SET SECTION "Fonts"   ENTRY "1" TO "Arial| 0| -11| 0| 0| 0| 0| 0" OF oIni
      SET SECTION "Colors"  ENTRY "1" TO "0" OF oIni
      SET SECTION "Colors"  ENTRY "2" TO "16777215" OF oIni

      AREAS->(DBGOTOP())

      DO WHILE .NOT. AREAS->(EOF())
         SET SECTION "Areas" ENTRY ALLTRIM(STR( AREAS->(RECNO()), 5)) ;
            TO cFileNoPath( SUBSTR( cLongDefIni, 1, LEN( cLongDefIni ) - 2 ) + ;
               PADL( ALLTRIM( STR( AREAS->(RECNO()), 2 ) ), 2, "0" ) ) OF oIni
         AREAS->(DBSKIP())
      ENDDO

   ENDINI

   //Area files
   AREAS->(DBGOTOP())

   DO WHILE .NOT. AREAS->(EOF())

      cAreaTmpFile := SUBSTR( cLongDefIni, 1, LEN( cLongDefIni ) - 2 ) + ;
         PADL( ALLTRIM( STR( AREAS->(RECNO()), 2 ) ), 2, "0" )
      CreateNewFile( cAreaTmpFile )
      cAreaTmpFile := VRD_LF2SF( ALLTRIM( cAreaTmpFile ) )

      INI oIni FILE cAreaTmpFile

         SET SECTION "General" ENTRY "Title"       TO AREAS->NAME  OF oIni
         SET SECTION "General" ENTRY "Width"       TO ALLTRIM(STR( AREAS->WIDTH, 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "Height"      TO ALLTRIM(STR( AREAS->HEIGHT, 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "Top1"        TO ALLTRIM(STR( AREAS->TOP1, 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "Top2"        TO ALLTRIM(STR( AREAS->TOP2, 5, IIF( nMeasure = 2, 2, 0 ) )) OF oIni
         SET SECTION "General" ENTRY "TopVariable" TO IIF( AREAS->LTOP, "1", "0") OF oIni
         SET SECTION "General" ENTRY "Condition"   TO STR( AREAS->CONDITION, 1 ) OF oIni

         nRow := 1
         nCol := 1
         nXRow := 0
         nXCol := 0

         FOR i := 1 TO AREAS->TEXTNR
            nXRow := 5 + ( nRow - 1 ) * 24
            nXCol := 5 + ( nCol - 1 ) * 55
            IF GetCmInch( nXRow + 48 ) > AREAS->HEIGHT
               nRow := 1
               nCol += 1
            ELSE
               nRow += 1
            ENDIF
            IF GetCmInch( nXCol + 55 ) > AREAS->WIDTH
               EXIT
            ENDIF
            SET SECTION "Items" ENTRY ALLTRIM(STR(i,3)) ;
               TO "Text|" + ALLTRIM(STR(i,3)) + "| " + ALLTRIM(STR(i,3)) + "|1|1|1|" + ;
               ALLTRIM(STR( GetCmInch( nXRow ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( GetCmInch( nXCol ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 50 ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 20 ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               "1|1|2|0|0|0|" OF oIni
         NEXT

         IF AREAS->TEXTNR > 0
            nColStart := nXCol + 55
         ELSE
            nColStart := 5
         ENDIF
         nCol := 1
         nRow := 1

         FOR i := 1 TO AREAS->IMAGENR
            nXRow := 5 + ( nRow - 1 ) * 24
            nXCol := nColStart + ( nCol - 1 ) * 55
            IF GetCmInch( nXRow + 48 ) > AREAS->HEIGHT
               nRow := 1
               nCol += 1
            ELSE
               nRow += 1
            ENDIF
            IF GetCmInch( nXCol + 55 ) > AREAS->WIDTH
               EXIT
            ENDIF
            SET SECTION "Items" ENTRY ALLTRIM(STR(100+i,3)) ;
               TO "Image|| " + ALLTRIM(STR(100+i,3)) + "|1|1|1|" + ;
               ALLTRIM(STR( GetCmInch( nXRow ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( GetCmInch( nXCol ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 50 ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 20 ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               "|0" OF oIni
         NEXT

         IF AREAS->TEXTNR > 0 .OR. AREAS->IMAGENR > 0
            nColStart := nXCol + 55
         ELSE
            nColStart := 5
         ENDIF
         nCol := 1
         nRow := 1

         FOR i := 1 TO AREAS->GRAPHNR
            nXRow := 5 + ( nRow - 1 ) * 24
            nXCol := nColStart + ( nCol - 1 ) * 55
            IF GetCmInch( nXRow + 48 ) > AREAS->HEIGHT
               nRow := 1
               nCol += 1
            ELSE
               nRow += 1
            ENDIF
            IF GetCmInch( nXCol + 55 ) > AREAS->WIDTH
               EXIT
            ENDIF
            SET SECTION "Items" ENTRY ALLTRIM(STR(200+i,3)) ;
               TO "LineHorizontal|" + GL("Line horizontal") + "| " + ALLTRIM(STR(200+i,3)) + "|1|1|1|" + ;
               ALLTRIM(STR( GetCmInch( nXRow ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( GetCmInch( nXCol ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 50 ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 20 ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               "1|2|1|1|0|0" OF oIni
         NEXT

         IF AREAS->TEXTNR > 0 .OR. AREAS->IMAGENR > 0 .OR. AREAS->GRAPHNR > 0
            nColStart := nXCol + 55
         ELSE
            nColStart := 5
         ENDIF
         nCol := 1
         nRow := 1

         FOR i := 1 TO AREAS->BCODENR
            nXRow := 5 + ( nRow - 1 ) * 24
            nXCol := nColStart + ( nCol - 1 ) * 175
            IF GetCmInch( nXRow + 48 ) > AREAS->HEIGHT
               nRow := 1
               nCol += 1
            ELSE
               nRow += 1
            ENDIF
            IF GetCmInch( nXCol + 175 ) > AREAS->WIDTH
               EXIT
            ENDIF
            SET SECTION "Items" ENTRY ALLTRIM(STR(300+i,3)) ;
               TO "Barcode|12345678| " + ALLTRIM(STR(300+i,3)) + "|1|1|1|" + ;
               ALLTRIM(STR( GetCmInch( nXRow ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( GetCmInch( nXCol ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 170 ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 20 ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               "1|1|2|1|1|0.3|" OF oIni
         NEXT

      ENDINI

      AREAS->(DBSKIP())

   ENDDO

   //Create source code
   IF lMakeSource = .T.

      cSource := CRLF
      cSource += SPACE(3) + 'oVRD := VRD():New( "' + ALLTRIM(cGeneralName) + '", lPreview, cPrinter, oWnd )'
      cSource += CRLF + CRLF

      AREAS->(DBGOTOP())

      DO WHILE .NOT. AREAS->(EOF())

         IF .NOT. EMPTY( AREAS->NAME )
            cSource += SPACE(3) + "//--- Area: " + ALLTRIM( AREAS->NAME ) + " ---"
         ENDIF

         IF AREAS->TEXTNR > 0
            cSource += CRLF + SPACE(3) + "//Text items" + CRLF
         ENDIF
         FOR i := 1 TO AREAS->TEXTNR
            cSource += SPACE(3) + "oVRD:PrintItem( " + ALLTRIM(STR(AREAS->(RECNO()),3)) + ;
                       ", " + ALLTRIM(STR( i, 5)) + ", )" + CRLF
         NEXT

         IF AREAS->IMAGENR > 0
            cSource += CRLF + SPACE(3) + "//Image items" + CRLF
         ENDIF
         FOR i := 1 TO AREAS->IMAGENR
            cSource += SPACE(3) + "oVRD:PrintItem( " + ALLTRIM(STR(AREAS->(RECNO()),3)) + ;
                       ", " + ALLTRIM(STR( 100+i, 5)) + ", )" + CRLF
         NEXT

         IF AREAS->GRAPHNR > 0
            cSource += CRLF + SPACE(3) + "//Graphic items" + CRLF
         ENDIF
         FOR i := 1 TO AREAS->GRAPHNR
            cSource += SPACE(3) + "oVRD:PrintItem( " + ALLTRIM(STR(AREAS->(RECNO()),3)) + ;
                       ", " + ALLTRIM(STR( 200+i, 5)) + ", )" + CRLF
         NEXT

         IF AREAS->BCODENR > 0
            cSource += CRLF + SPACE(3) + "//Barcode items" + CRLF
         ENDIF
         FOR i := 1 TO AREAS->BCODENR
            cSource += SPACE(3) + "oVRD:PrintItem( " + ALLTRIM(STR(AREAS->(RECNO()),3)) + ;
                       ", " + ALLTRIM(STR( 300+i, 5)) + ", )" + CRLF
         NEXT

         cSource += CRLF + SPACE(3) + ;
                    "oVRD:PrintRest( " + ALLTRIM(STR(AREAS->(RECNO()),3)) + " )" + ;
                    CRLF + CRLF

         AREAS->(DBSKIP())

      ENDDO

      cSource += SPACE(3) + "oVRD:End()" + CRLF

      CreateNewFile( cSourceCode )
      MEMOWRIT( VRD_LF2SF( cSourceCode ), cSource )

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: CheckFileName
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION CheckFileName( cGeneralName, cSourceCode, lMakeSource )

   LOCAL lReturn := .T.

   DEFAULT lMakeSource := .F.

   IF EMPTY( cGeneralName ) .OR. AT( "\\", cGeneralName ) <> 0
      lReturn := .F.
      MsgStop( GL("Please insert a valid file name."), GL("Stop!") )
   ELSEIF AT( ".", cGeneralName ) = 0
      cGeneralName := ALLTRIM( cGeneralName ) + ".vrd"
      //lReturn := .F.
      //MsgStop( GL("Please add the file extension."), GL("Stop!") )
   ELSEIF lMakeSource = .T.
      IF EMPTY( cSourceCode ) .OR. AT( "\\", cSourceCode ) <> 0
         lReturn := .F.
         MsgStop( GL("Please insert a valid source code file name."), GL("Stop!") )
      ENDIF
   ENDIF

RETURN ( lReturn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: SetNewReportDefaults
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetNewReportDefaults()

   REPLACE AREAS->NAME      WITH ALLTRIM(STR( AREAS->(RECNO()) )) + ". " + GL("Area")
   REPLACE AREAS->LTOP      WITH .T.
   REPLACE AREAS->WIDTH     WITH 200
   REPLACE AREAS->HEIGHT    WITH 40
   REPLACE AREAS->CONDITION WITH 1

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: MoveRecord
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION MoveRecord( lUp, oBrw )

   LOCAL i, xFeld
   LOCAL aFields1 := {}
   LOCAL aFields2 := {}

   //alte Werte einlesen
   FOR i := 1 to FCOUNT()
      xFeld = FIELDNAME(i)
      aadd( aFields1, &xFeld)
   NEXT

   DBSKIP( IIF( lUp, -1, 1) )

   FOR i := 1 to FCOUNT()
      xFeld = FIELDNAME(i)
      aadd( aFields2, &xFeld)
   NEXT

   //neue Werte wegschreiben
   FOR i := 1 to FCOUNT()
      xFeld = FIELDNAME(i)
      REPLACE &xFeld WITH aFields1[i]
   NEXT

   DBSKIP( IIF( lUp, 1, -1) )

   FOR i := 1 to FCOUNT()
      xFeld = FIELDNAME(i)
      REPLACE &xFeld WITH aFields2[i]
   NEXT

   IF lUp
      oBrw:GoUp()
   ELSE
      oBrw:GoDown()
   ENDIF

RETURN (.T.)