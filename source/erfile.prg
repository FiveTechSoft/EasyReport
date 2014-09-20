#include "FiveWin.ch"

MEMVAR aItems, aFonts, aAreaIni, aWnd, aWndTitle, oMru
MEMVAR oCbxArea, aRuler, cLongDefIni, cDefaultPath
MEMVAR oGenVar
MEMVAR aVRDSave, lVRDSave
MEMVAR cDefIniPath
MEMVAR nDlgTextCol, nDlgBackCol
MEMVAr oEr


//------------------------------------------------------------------------------

function OpenFile( cFile, lChange, lAddDelNew )

   local i
   local cLongFile     := cFile
   local cMainTitle    := ""

   DEFAULT lChange     := .F.
   DEFAULT lAddDelNew  := .F.

   if cFile = NIL
      cLongFile   := GetFile( GL("Designer Files") + " (*.vrd)|*.vrd|" + ;
                              GL("All Files") + " (*.*)|*.*", GL("Open"), 1 )
   endif

   cLongDefIni := cLongFile
   cFile       := VRD_LF2SF( cLongFile )

   if AT( "[AREAS]", UPPER( MEMOREAD( cFile ) ) ) = 0 .AND. !EMPTY( cFile )
      MsgStop( ALLTRIM( cLongFile ) + CRLF + CRLF + GL("is not a valid file."), GL("Stop!") )
      return( .F. )
   endif

   // Neustart des Programmes
   if !EMPTY( cFile ) .AND. !oGenVar:lFirstFile
      oGenVar:cLoadFile := cFile
      //oEr:oMainWnd:End()
      //return .T.
   endif

   // Aufruf des neuen Reports im gleichen Frame gibt optische Probleme
   if !EMPTY( cFile )

      oGenVar:lFirstFile := .F.

      //oEr:oMainWnd:CloseAll()
      /*
      For i = 1 to Len( aWnd )
          if !empty( aWnd[ i ] )
             aWnd[ i ]:End()
          endif
      Next i
      */

      aItems    := NIL
      aAreaIni  := NIL
      if !lChange
      aWnd      := NIL
      aWndTitle := NIL
      aRuler    := NIL
      endif
      //MEMORY(-1)
      //SYSREFRESH()

      if !lChange
      aWnd      := Array( oER:nTotAreas )
      aWndTitle := Array( Len( aWnd ) )
      aRuler    := Array( Len( aWnd ), 2 )
      endif
      aItems    := Array( Len( aWnd ), 1000 )
      aAreaIni  := Array( Len( aWnd ) )

      //Fontobjekte beenden
      for i := 1 TO 20
         if aFonts[i] <> NIL
            aFonts[i]:End()
         endif
      next
      aFonts := Array( 20 )

      //SysRefresh()

      oER:cDefIni := cFile
      if AT( "\", oER:cDefIni ) = 0
         oER:cDefIni := ".\" + oER:cDefIni
      endif

      cDefIniPath := CheckPath( cFilePath( oER:cDefIni ) )

      SetGeneralSettings()

      //Fonts definieren
      DefineFonts()
      //Areas initieren
      //if oCbxArea = NIL
      //else
      //   oCbxArea:End()
      //endif

      //Designwindows öffnen
      if !lChange
      ClientWindows()
      else
      For i = 1 to Len( aWnd )
          if !empty( aWnd[ i ] )
             aWnd[ i ]:Refresh()
          endif
      Next i
      endif
      //Areas anzeigen
      ShowAreasOnBar()

      //SysRefresh()

      ClearUndoRedo() // and refresh the bar

      cMainTitle      := ALLTRIM( oer:GetDefIni( "General", "Title", "" ) )
      oEr:oMainWnd:cTitle := MainCaption()

      oER:SetScrollBar()

      oEr:oMainWnd:SetMenu( BuildMenu() )

      //dlg_colors()

      SetSave( .T. )

      if VAL( GetPvProfString( "General", "MruList"  , "4", oER:cGeneralIni ) ) > 0
         oMru:Save( cLongDefIni )
      endif

      CreateBackup()

   endif

return .T.

//-----------------------------------------------------------------------------

function CreateBackup()

   local nArea

   if VAL( oEr:GetGeneralIni( "General", "CreateBackup", "0" ) ) == 1

      CopyFile( oER:cDefIni, STUFF( oER:cDefIni, RAT( ".", oER:cDefIni ), 1, "_backup." ) )

      for nArea := 1 TO LEN( aAreaIni )

         if .NOT. EMPTY( aAreaIni[nArea] )
            CopyFile( aAreaIni[nArea], ;
               STUFF( aAreaIni[nArea], RAT( ".", aAreaIni[nArea] ), 1, "_backup." ) )
         endif

      next

   endif

return .T.

//-----------------------------------------------------------------------------

function SaveFile()

   local nArea

   aVRDSave := ARRAY( 102, 2 )

   aVRDSave[101,1] := oER:cDefIni
   aVRDSave[101,2] := MEMOREAD( oER:cDefIni )
   aVRDSave[102,1] := oER:cGeneralIni
   aVRDSave[102,2] := MEMOREAD( oER:cGeneralIni )

   for nArea := 1 TO LEN( aAreaIni )

      aVRDSave[nArea,1] := aAreaIni[nArea]
      aVRDSave[nArea,2] := MEMOREAD( aAreaIni[nArea] )

   next

   SetSave( .T. )

return .T.

//-----------------------------------------------------------------------------

function SaveAsFile()

   local cFile := GetFile( GL("Designer Files") + " (*.vrd)|*.vrd|" + ;
                           GL("All Files") + " (*.*)|*.*", GL("Save as"), 1,, .T. )

   if !EMPTY( cFile )
      MsgRun( GL("Please wait..."), ;
         STRTRAN( GL("Save &as"), "&", "" ), {|| SaveAs( cFile ) } )
   endif

return NIL

//-----------------------------------------------------------------------------

function SaveAs( cFile )

   local i, nArea, cAreaFile, cAltDefIni

   cLongDefIni := cFile

   if EMPTY( cFileExt( cFile ) )
      cFile += ".vrd"
   elseif UPPER( cFileExt( cFile ) ) <> "VRD"
      cFile := ALLTRIM( cFile )
      cFile := SUBSTR( cFile, 1, RAT( UPPER(ALLTRIM(cFileExt( cFile ))), UPPER( cFile ) ) - 1 ) + "vrd"
   endif

   if FILE( VRD_LF2SF( cFile ) )
      if MsgNoYes( GL("The file already exists.") + CRLF + CRLF + ;
                   GL("Overwrite?"), GL("Save as") ) = .F.
         return( .F. )
      else
         cAltDefIni := VRD_LF2SF( ALLTRIM( cFile ) )
         IIF( AT( "\", cAltDefIni ) = 0, cAltDefIni := ".\" + cAltDefIni, )
         for i := 1 TO Len( aWnd )
            DelFile( VRD_LF2SF( ALLTRIM( GetPvProfString( "Areas", ALLTRIM(STR(i,5)) , "", cAltDefIni ) ) ) )
         next
         DelFile( cAltDefIni )
      endif
   endif

   CreateNewFile( cFile )

   if ! EMPTY( cFile )

      oER:cDefIni := VRD_LF2SF( ALLTRIM( cFile ) )

      if AT( "\", oER:cDefIni ) = 0
         oER:cDefIni := ".\" + oER:cDefIni
      endif

      aVRDSave[101,1] := oER:cDefIni
      MEMOWRIT( aVRDSave[101,1], aVRDSave[101,2] )
      MEMOWRIT( aVRDSave[102,1], aVRDSave[102,2] )

      //Alte Areas löschen
      DelIniSection( "Areas", oER:cDefIni )

      //Areas abspeichern
      for nArea := 1 TO LEN( aAreaIni )

         if ! EMPTY( aVRDSave[nArea,1] )

            cAreaFile := SUBSTR( cFile, 1, LEN( cFile )-2 ) + PADL( ALLTRIM( STR( nArea, 2) ), 2, "0" )
            CreateNewFile( cAreaFile )

            aVRDSave[nArea,1] := VRD_LF2SF( cAreaFile )
            //aVRDSave[nArea,1] := SUBSTR( oER:cDefIni, 1, LEN( oER:cDefIni )-2 ) + ;
            //                  PADL( ALLTRIM( STR( nArea, 2) ), 2, "0" )
            MEMOWRIT( aVRDSave[nArea,1], aVRDSave[nArea,2] )

            aAreaIni[nArea] := aVRDSave[nArea,1]

            //Areas in General Ini File ablegen
            WritePProString( "Areas", ALLTRIM(STR( nArea, 3)), cFileName( cAreaFile ), oER:cDefIni )

         endif

         //Areapfad speichern
         WritePProString( "General", "AreaFilesDir", cFilePath( oER:cDefIni ), oER:cDefIni )

      next

      SetSave( .T. )

      if VAL( GetPvProfString( "General", "MruList"  , "4", oER:cGeneralIni ) ) > 0
         oMru:Save( cLongDefIni )
      endif

   endif


return .T.

*-----------------------------------------------------------------------------

function AskSaveFiles()

   local nArea, nSave
   local lreturn := .T.

   if ! lVRDSave

      nSave := MessageBox( oEr:oMainWnd:hWnd, ;
                           GL("Your changes are not saved.") + CRLF + CRLF + ;
                           GL("Save the current report?"), GL("Save"), 35 )

      if nSave = 7
         MEMOWRIT( aVRDSave[101,1], aVRDSave[101,2] )
         MEMOWRIT( aVRDSave[102,1], aVRDSave[102,2] )
         for nArea := 1 TO LEN( aAreaIni )
            MEMOWRIT( aVRDSave[nArea,1], aVRDSave[nArea,2] )
         next
      elseif nSave = 6
         SetSaveInfos()
      else
         oGenVar:cLoadFile := ""
         lreturn := .F.
      endif

   endif

   /*
   if ! EMPTY( oGenVar:cLoadFile )
      ShellExecute( 0, "Open", GetModuleFileName( GetInstance() ), oGenVar:cLoadFile, NIL, 1 )
   endif
   */

return ( lreturn )

*-----------------------------------------------------------------------------

function FileInfos()

   local i, oDlg, oBrw, cAreaDef, aFileInfo, oFld, nWnd, oIni, cLastSave
   local lSave        := .F.
   local aFiles       := { { GL("General"), ALLTRIM( cLongDefIni ) } }
   local cTitle       := PADR( oEr:GetDefIni( "General", "Title", "" ), 80 )
   local cGroup       := PADR( oEr:GetDefIni( "General", "Group", "" ), 80 )
   local aIniEntries  := GetIniSection( "Infos", oER:cDefIni )
   local cAuthor      := PADR( GetIniEntry( aIniEntries, "Author" ), 100 )
   local cCompany     := PADR( GetIniEntry( aIniEntries, "Company" ), 100 )
   local cComment     := PADR( GetIniEntry( aIniEntries, "Comment" ), 200 )
   local cSaveDate    := GetIniEntry( aIniEntries, "SaveDate" )
   local cSaveTime    := GetIniEntry( aIniEntries, "SaveTime" )
   local cRevision    := GetIniEntry( aIniEntries, "Revision", "0" )
   local nNrItems     := 0
   local nNrAreas     := 0
   local aAreaEntries := GetIniSection( "Areas", oER:cDefIni )

   if EMPTY( cSaveDate )
      cLastSave := "-"
   else
      cLastSave := cSaveDate + "  " + cSaveTime
   endif

   for i := 1 TO LEN( aAreaEntries )
      if VAL( aAreaEntries[i] ) <> 0
         nWnd := EntryNr( aAreaEntries[i] )
         cAreaDef := GetIniEntry( aAreaEntries,, "",, i )
         if .NOT. EMPTY( cAreaDef )
            AADD( aFiles, { aWndTitle[nWnd], cAreaDef } )
         endif
      endif
   next

   AEval( aWnd, {|x| IIF( x <> NIL, ++nNrAreas, ) } )
   for i := 1 TO Len( aWnd )
      if aItems[i] <> NIL
         AEval( aItems[i], {|x| IIF( x <> NIL, ++nNrItems, ) } )
      endif
   next

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

   if lSave

      INI oIni FILE oER:cDefIni
         SET SECTION "General" ENTRY "Title"   TO ALLTRIM( cTitle ) OF oIni
         SET SECTION "General" ENTRY "Group"   TO ALLTRIM( cGroup ) OF oIni
         SET SECTION "Infos"   ENTRY "Author"  TO RTRIM( cAuthor )  OF oIni
         SET SECTION "Infos"   ENTRY "Company" TO RTRIM( cCompany ) OF oIni
         SET SECTION "Infos"   ENTRY "Comment" TO RTRIM( cComment ) OF oIni
      ENDINI

      oEr:oMainWnd:cTitle := MainCaption()

      SetSave( .F. )

   endif

return .T.

*-----------------------------------------------------------------------------

function SetSave( lSave )

   if lSave
      lVRDSave := .T.
      SetSaveInfos()
   else
      lVRDSave := .F.
   endif

   if !empty( oEr:oMainWnd:oBar )
      oEr:oMainWnd:oBar:AEvalWhen()
   endif

return .T.

*-----------------------------------------------------------------------------

function SetSaveInfos()

   local oIni

   INI oIni FILE oER:cDefIni
      SET SECTION "Infos" ENTRY "Revision" TO ;
         ALLTRIM(STR( VAL( oEr:GetDefIni( "Infos", "Revision", "0" ) ) + 1, 5 )) OF oIni
      SET SECTION "Infos" ENTRY "SaveDate" TO ALLTRIM( DTOC( DATE() ) ) OF oIni
      SET SECTION "Infos" ENTRY "SaveTime" TO TIME() OF oIni
   ENDINI

return .T.

*-----------------------------------------------------------------------------

function NewReport()

   local i, y, oDlg, oFld, oFont, oBrw, cTmpFile, oRad1, oRad2
   local aGet[3], aBtn[2], aGet2[1], aCbx1[1], aCbx2[1], aCbx3[8], aCheck[9]
   local nAltSel      := SELECT()
   local lCreate      := .F.
   local aMeasure     := { "mm", "inch", "pixel" }
   local cMeasure     := aMeasure[1]
   local cGeneralName := SPACE(100)
   local cSourceCode  := SPACE(100)
   local cReportName  := SPACE(100)
   local lMakeSource  := .F.
   local nTop         := 20
   local nLeft        := 20
   local nPageBreak   := 270
   local nOrient      := 1
   local oCombo

   //Defaults
   AFill( aCheck, .T. )

   DEFINE FONT oFont NAME "Arial" SIZE 0, -12

   nDlgTextCol = CLR_BLACK

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

   REDEFINE BTNBMP aBtn[1] ID 151 OF oFld:aDialogs[i] RESOURCE "B_OPEN_16" TRANSPARENT UPDATE ;
      TOOLTIP GL("Open") ;
      ACTION ( cTmpFile := GetFile( GL("Designer Files") + " (*.vrd)|*.vrd|" + ;
                                    GL("All Files") + " (*.*)|*.*", ;
                                    GL("General report file name"), 1 ), ;
               IIF( EMPTY( cTmpFile ),, cGeneralName := cTmpFile ), ;
               aGet[1]:Refresh() )

   REDEFINE BTNBMP aBtn[2] ID 152 OF oFld:aDialogs[i] RESOURCE "B_OPEN_16" TRANSPARENT UPDATE ;
      TOOLTIP GL("Open") ;
      ACTION ( cTmpFile := GetFile( GL("All Files") + " (*.*)|*.*", ;
                                    GL("Source code file name"), 1 ), ;
               IIF( EMPTY( cTmpFile ),, cSourceCode := cTmpFile ), ;
               aGet[2]:Refresh() )

   REDEFINE CHECKBOX aCbx1[1] VAR lMakeSource ID 301 OF oFld:aDialogs[i]
   REDEFINE COMBOBOX oCombo VAR cMeasure  ITEMS aMeasure  ID 303 OF oFld:aDialogs[i]

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

   if lCreate
      MsgRun( GL("Please wait..."), GL("New Report"), ;
         {|| CreateNewReport( aCheck, cGeneralName, cSourceCode, cReportName, lMakeSource, ;
                              nTop, nLeft, nPageBreak, nOrient, aMeasure, cMeasure ) } )
   endif

   AREAS->(DBCLOSEAREA())
   SELECT( nAltSel )

   ERASE VRDTMPST.DBF
   ERASE VRDTMP.DBF

   if lCreate
      OpenFile( cGeneralName,, .T. )
   endif

return .T.

*-----------------------------------------------------------------------------

function CreateNewReport( aCheck, cGeneralName, cSourceCode, cReportName, lMakeSource, ;
                          nTop, nLeft, nPageBreak, nOrient, aMeasure, cMeasure )

   Local i
   Local nCol
   Local nRow
   Local nXCol
   Local nXRow
   Local nColStart
   Local oIni
   Local cSource
   Local cAreaTmpFile
   Local cDefTmpIni
   LOCAL nDecimals

   //General ini file
   CreateNewFile( cGeneralName )
   cLongDefIni := ALLTRIM( cGeneralName )
   cDefTmpIni  := ALLTRIM( cGeneralName )

   if AT( "\", cDefTmpIni ) = 0
      cDefTmpIni := ".\" + cDefTmpIni
   endif

   oER:nMeasure := ASCAN( aMeasure, cMeasure )
   oER:nMeasure := Max( 1, oER:nMeasure )

   INI oIni FILE cDefTmpIni
      SET SECTION "General" ENTRY "Title"              TO cReportName OF oIni
      SET SECTION "General" ENTRY "TopMargin"          TO nTop OF oIni
      SET SECTION "General" ENTRY "LeftMargin"         TO nLeft OF oIni
      SET SECTION "General" ENTRY "PageBreak"          TO nPageBreak OF oIni
      SET SECTION "General" ENTRY "Measure"            TO oER:nMeasure OF oIni
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

   nDecimals := IIF( oER:nMeasure == 2, 2, 0 )

   //Area files
   AREAS->(DBGOTOP())

   DO WHILE .NOT. AREAS->(EOF())

      cAreaTmpFile := SUBSTR( cLongDefIni, 1, LEN( cLongDefIni ) - 2 ) + ;
         PADL( ALLTRIM( STR( AREAS->(RECNO()), 2 ) ), 2, "0" )
      CreateNewFile( cAreaTmpFile )
      cAreaTmpFile := VRD_LF2SF( ALLTRIM( cAreaTmpFile ) )

      INI oIni FILE cAreaTmpFile

         SET SECTION "General" ENTRY "Title"       TO AREAS->NAME  OF oIni
         SET SECTION "General" ENTRY "Width"       TO ALLTRIM(STR( AREAS->WIDTH, 5, nDecimals )) OF oIni
         SET SECTION "General" ENTRY "Height"      TO ALLTRIM(STR( AREAS->HEIGHT, 5, nDecimals )) OF oIni
         SET SECTION "General" ENTRY "Top1"        TO ALLTRIM(STR( AREAS->TOP1, 5, nDecimals )) OF oIni
         SET SECTION "General" ENTRY "Top2"        TO ALLTRIM(STR( AREAS->TOP2, 5, nDecimals )) OF oIni
         SET SECTION "General" ENTRY "TopVariable" TO IIF( AREAS->LTOP, "1", "0") OF oIni
         SET SECTION "General" ENTRY "Condition"   TO STR( AREAS->CONDITION, 1 ) OF oIni

         nRow := 1
         nCol := 1
         nXRow := 0
         nXCol := 0

         for i := 1 TO AREAS->TEXTNR
            nXRow := 5 + ( nRow - 1 ) * 24
            nXCol := 5 + ( nCol - 1 ) * 55
            if GetCmInch( nXRow + 48 ) > AREAS->HEIGHT
               nRow := 1
               nCol += 1
            else
               nRow += 1
            endif
            if GetCmInch( nXCol + 55 ) > AREAS->WIDTH
               EXIT
            endif
            SET SECTION "Items" ENTRY ALLTRIM(STR(i,3)) ;
               TO "Text|" + ALLTRIM(STR(i,3)) + "| " + ALLTRIM(STR(i,3)) + "|1|1|1|" + ;
               ALLTRIM(STR( GetCmInch( nXRow ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( nXCol ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 50 ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 20 ), 5, nDecimals )) + "|" + ;
               "1|1|2|0|0|0|" OF oIni
         next

         if AREAS->TEXTNR > 0
            nColStart := nXCol + 55
         else
            nColStart := 5
         endif
         nCol := 1
         nRow := 1

         for i := 1 TO AREAS->IMAGENR
            nXRow := 5 + ( nRow - 1 ) * 24
            nXCol := nColStart + ( nCol - 1 ) * 55
            if GetCmInch( nXRow + 48 ) > AREAS->HEIGHT
               nRow := 1
               nCol += 1
            else
               nRow += 1
            endif
            if GetCmInch( nXCol + 55 ) > AREAS->WIDTH
               EXIT
            endif
            SET SECTION "Items" ENTRY ALLTRIM(STR(100+i,3)) ;
               TO "Image|| " + ALLTRIM(STR(100+i,3)) + "|1|1|1|" + ;
               ALLTRIM(STR( GetCmInch( nXRow ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( nXCol ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 50 ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 20 ), 5, nDecimals )) + "|" + ;
               "|0" OF oIni
         next

         if AREAS->TEXTNR > 0 .OR. AREAS->IMAGENR > 0
            nColStart := nXCol + 55
         else
            nColStart := 5
         endif
         nCol := 1
         nRow := 1

         for i := 1 TO AREAS->GRAPHNR
            nXRow := 5 + ( nRow - 1 ) * 24
            nXCol := nColStart + ( nCol - 1 ) * 55
            if GetCmInch( nXRow + 48 ) > AREAS->HEIGHT
               nRow := 1
               nCol += 1
            else
               nRow += 1
            endif
            if GetCmInch( nXCol + 55 ) > AREAS->WIDTH
               EXIT
            endif
            SET SECTION "Items" ENTRY ALLTRIM(STR(200+i,3)) ;
               TO "LineHorizontal|" + GL("Line horizontal") + "| " + ALLTRIM(STR(200+i,3)) + "|1|1|1|" + ;
               ALLTRIM(STR( GetCmInch( nXRow ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( nXCol ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 50 ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 20 ), 5, nDecimals )) + "|" + ;
               "1|2|1|1|0|0" OF oIni
         next

         if AREAS->TEXTNR > 0 .OR. AREAS->IMAGENR > 0 .OR. AREAS->GRAPHNR > 0
            nColStart := nXCol + 55
         else
            nColStart := 5
         endif
         nCol := 1
         nRow := 1

         for i := 1 TO AREAS->BCODENR
            nXRow := 5 + ( nRow - 1 ) * 24
            nXCol := nColStart + ( nCol - 1 ) * 175
            if GetCmInch( nXRow + 48 ) > AREAS->HEIGHT
               nRow := 1
               nCol += 1
            else
               nRow += 1
            endif
            if GetCmInch( nXCol + 175 ) > AREAS->WIDTH
               EXIT
            endif
            SET SECTION "Items" ENTRY ALLTRIM(STR(300+i,3)) ;
               TO "Barcode|12345678| " + ALLTRIM(STR(300+i,3)) + "|1|1|1|" + ;
               ALLTRIM(STR( GetCmInch( nXRow ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( nXCol ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 170 ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 20 ), 5, nDecimals )) + "|" + ;
               "1|1|2|1|1|0.3|" OF oIni
         next

      ENDINI

      AREAS->(DBSKIP())

   ENDDO

   //Create source code
   if lMakeSource = .T.

      cSource := CRLF
      cSource += SPACE(3) + 'oVRD := VRD():New( "' + ALLTRIM(cGeneralName) + '", lPreview, cPrinter, oWnd )'
      cSource += CRLF + CRLF

      AREAS->(DBGOTOP())

      DO WHILE .NOT. AREAS->(EOF())

         if .NOT. EMPTY( AREAS->NAME )
            cSource += SPACE(3) + "//--- Area: " + ALLTRIM( AREAS->NAME ) + " ---"
         endif

         if AREAS->TEXTNR > 0
            cSource += CRLF + SPACE(3) + "//Text items" + CRLF
         endif
         for i := 1 TO AREAS->TEXTNR
            cSource += SPACE(3) + "oVRD:PrintItem( " + ALLTRIM(STR(AREAS->(RECNO()),3)) + ;
                       ", " + ALLTRIM(STR( i, 5)) + ", )" + CRLF
         next

         if AREAS->IMAGENR > 0
            cSource += CRLF + SPACE(3) + "//Image items" + CRLF
         endif
         for i := 1 TO AREAS->IMAGENR
            cSource += SPACE(3) + "oVRD:PrintItem( " + ALLTRIM(STR(AREAS->(RECNO()),3)) + ;
                       ", " + ALLTRIM(STR( 100+i, 5)) + ", )" + CRLF
         next

         if AREAS->GRAPHNR > 0
            cSource += CRLF + SPACE(3) + "//Graphic items" + CRLF
         endif
         for i := 1 TO AREAS->GRAPHNR
            cSource += SPACE(3) + "oVRD:PrintItem( " + ALLTRIM(STR(AREAS->(RECNO()),3)) + ;
                       ", " + ALLTRIM(STR( 200+i, 5)) + ", )" + CRLF
         next

         if AREAS->BCODENR > 0
            cSource += CRLF + SPACE(3) + "//Barcode items" + CRLF
         endif
         for i := 1 TO AREAS->BCODENR
            cSource += SPACE(3) + "oVRD:PrintItem( " + ALLTRIM(STR(AREAS->(RECNO()),3)) + ;
                       ", " + ALLTRIM(STR( 300+i, 5)) + ", )" + CRLF
         next

         cSource += CRLF + SPACE(3) + ;
                    "oVRD:PrintRest( " + ALLTRIM(STR(AREAS->(RECNO()),3)) + " )" + ;
                    CRLF + CRLF

         AREAS->(DBSKIP())

      ENDDO

      cSource += SPACE(3) + "oVRD:End()" + CRLF

      CreateNewFile( cSourceCode )
      MEMOWRIT( VRD_LF2SF( cSourceCode ), cSource )

   endif

return .T.

*-----------------------------------------------------------------------------

function CheckFileName( cGeneralName, cSourceCode, lMakeSource )

   local lreturn := .T.

   DEFAULT lMakeSource := .F.

   if EMPTY( cGeneralName ) .OR. AT( "\\", cGeneralName ) <> 0
      lreturn := .F.
      MsgStop( GL("Please insert a valid file name."), GL("Stop!") )
   elseif AT( ".", cGeneralName ) = 0
      cGeneralName := ALLTRIM( cGeneralName ) + ".vrd"
      //lreturn := .F.
      //MsgStop( GL("Please add the file extension."), GL("Stop!") )
   elseif lMakeSource = .T.
      if EMPTY( cSourceCode ) .OR. AT( "\\", cSourceCode ) <> 0
         lreturn := .F.
         MsgStop( GL("Please insert a valid source code file name."), GL("Stop!") )
      endif
   endif

return ( lreturn )

*-----------------------------------------------------------------------------

function SetNewReportDefaults()

   REPLACE AREAS->NAME      WITH ALLTRIM(STR( AREAS->(RECNO()) )) + ". " + GL("Area")
   REPLACE AREAS->LTOP      WITH .T.
   REPLACE AREAS->WIDTH     WITH 200
   REPLACE AREAS->HEIGHT    WITH 40
   REPLACE AREAS->CONDITION WITH 1

return .T.

*-----------------------------------------------------------------------------

function MoveRecord( lUp, oBrw )

   local i, xFeld
   local aFields1 := {}
   local aFields2 := {}

   //alte Werte einlesen
   for i := 1 to FCOUNT()
      xFeld = FIELDNAME(i)
      aadd( aFields1, &xFeld)
   next

   DBSKIP( IIF( lUp, -1, 1) )

   for i := 1 to FCOUNT()
      xFeld = FIELDNAME(i)
      aadd( aFields2, &xFeld)
   next

   //neue Werte wegschreiben
   for i := 1 to FCOUNT()
      xFeld = FIELDNAME(i)
      REPLACE &xFeld WITH aFields1[i]
   next

   DBSKIP( IIF( lUp, 1, -1) )

   for i := 1 to FCOUNT()
      xFeld = FIELDNAME(i)
      REPLACE &xFeld WITH aFields2[i]
   next

   if lUp
      oBrw:GoUp()
   else
      oBrw:GoDown()
   endif

return .T.