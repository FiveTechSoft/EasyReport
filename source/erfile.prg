#include "FiveWin.ch"

MEMVAR cLongDefIni, cDefaultPath
MEMVAR oGenVar
MEMVAR aVRDSave, lVRDSave
MEMVAr oEr

//------------------------------------------------------------------------------

function OpenFile( cFile, lChange, lAddDelNew )
   local i
   local cLongFile     := cFile
   local cMainTitle    := ""
   LOCAL xExtension

   DEFAULT lChange     := .F.
   DEFAULT lAddDelNew  := .F.

   if cFile = NIL
      cLongFile   := GetFile( GL("Designer Files") + " (*.vrd)|*.vrd|" + ;
                              GL("New Designer Files")+ " (*.erd)|*.erd|"+ ;
                              GL("All Files") + " (*.*)|*.*", GL("Open"), 1 )
   ELSE
      cLongFile   := cFile
   endif

   cLongDefIni := cLongFile
   cFile       := VRD_LF2SF( cLongFile )

   xExtension := cFileExt( cLongFile )

   IF Len(xExtension) >3
      xExtension := Left(xExtension,3)
   endif

   IF  Upper(xExtension ) ==  "ERD"
      oER:lNewFormat := .T.
   ELSE
      oER:lNewFormat := .F.
   ENDIF

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

      oER:aItems    := NIL
      oER:aAreaIni  := NIL
      if !lChange
         oER:aWnd      := NIL
         oER:aWndTitle := NIL
         oER:aRuler    := NIL
      endif

      if !lChange
         oER:aWnd      := Array( oER:nTotAreas )
         oER:aWndTitle := Array( Len( oER:aWnd ) )
         oER:aRuler    := Array( Len( oER:aWnd ), 2 )
      endif
      oER:aItems    := Array( Len( oER:aWnd ), 1000 )
      oER:aAreaIni  := Array( Len( oER:aWnd ) )

      for i := 1 TO 20
         if oER:aFonts[i] <> NIL
            oER:aFonts[i]:End()
         endif
      next
      oER:aFonts := Array( 20 )

      oER:cDefIni := cFile
      if AT( "\", oER:cDefIni ) = 0
         oER:cDefIni := ".\" + oER:cDefIni
      endif

      oER:cDefIniPath := CheckPath( cFilePath( oER:cDefIni ) )

      SetGeneralSettings()

      DefineFonts()

          IF oER:lShowPanel
         //SwichFldD( oEr:oMainWnd, oEr:oPanelD, ) //oER:oFldD )
         ER_ReportSettings( 1 )
         //DlgTree( 2 )
         Dlg_Colors( 3 )
         Dlg_Fonts( 4 )
         Er_Databases(,2)
         ER_Expressions(,,1)

         ER_Inspector1(3 )
         SwichFldD( oEr:oMainWnd, oEr:oPanelD, ) //oER:oFldD )

      endif


      if !lChange
         ClientWindows()
      else
         For i = 1 to Len( oER:aWnd )
             if !empty( oER:aWnd[ i ] )
                oER:aWnd[ i ]:Refresh()
             endif
         Next i
      endif

      ShowAreasOnBar()

      ClearUndoRedo() // and refresh the bar

      oEr:oMainWnd:SetMenu( BuildMenu() )

      IF oER:lShowPanel
         //SwichFldD( oEr:oMainWnd, oEr:oPanelD, ) //oER:oFldD )
         ER_ReportSettings( 1 )
         //DlgTree( 2 )
         Dlg_Colors( 3 )
         Dlg_Fonts( 4 )
         Er_Databases(,2)
         ER_Expressions(,,1)

         ER_Inspector1(3 )
         SwichFldD( oEr:oMainWnd, oEr:oPanelD, ) //oER:oFldD )

          RefreshPanelTree()

      endif

      SetSave( .T. )

      if VAL( GetPvProfString( "General", "MruList"  , "4", oER:cGeneralIni ) ) > 0
         oER:oMru:Save( cLongDefIni )
      endif

      CreateBackup()

   endif

return .T.

//-----------------------------------------------------------------------------

function CreateBackup()

   local nArea

   if VAL( oEr:GetGeneralIni( "General", "CreateBackup", "0" ) ) == 1

      CopyFile( oER:cDefIni, STUFF( oER:cDefIni, RAT( ".", oER:cDefIni ), 1, "_backup." ) )

      for nArea := 1 TO LEN( oER:aAreaIni )

         if !empty( oER:aAreaIni[nArea] )
            CopyFile( oER:aAreaIni[nArea], ;
               STUFF( oER:aAreaIni[nArea], RAT( ".", oER:aAreaIni[nArea] ), 1, "_backup." ) )
         endif

      next

   endif

return .T.

//------------------------------------------------------------------------------

FUNCTION SaveAsNewFormat()
   LOCAL cFile:= oER:cDefIni
   LOCAL cExtension := Upper(cFileExt( cFile ))
   LOCAL cNewFile
   local aIniEntries := GetIniSection( "Areas", oER:cDefIni )
   LOCAL aDataAreas, n
   LOCAL aAreaInis:= {}
   LOCAL cTextfile
   LOCAL i,cData, oINI
   LOCAL cText, aValue, aValue2

   IF Len(cExtension) > 3
      cExtension := Left(cExtension,3)
   endif
   IF cExtension == "VRD"

      cNewFile:= cFileNoExt( cFile )+".erd"
      IF File(cNewFile)
         if msgYesNo("El fichero ya existe.Lo Borramos")
            FErase(cNewFile)
         ELSE
            msginfo("el proceso no se ha realizado")
            RETURN .f.
         endif
      ENDIF

      CopyFile( cFile, cNewFile )

      cNewFile:= VRD_LF2SF( cNewFile )

      INI oIni File cNewFile

      FOR i= 1 TO Len( aIniEntries )
         aValue:= hb_atokens(  aIniEntries[i] , "=" )
         cText := StrTran(aValue[2],".","")
         SET SECTION "Areas" ENTRY aValue[1] TO cText OF oIni
         aDataAreas := GetIniSection( "General", VRD_LF2SF(aValue[2]) )
         FOR n=1 TO Len(aDataAreas)
            aValue2:= hb_atokens(  aDataAreas[n] , "=" )
            SET SECTION cText+"General" ENTRY aValue2[1] TO aValue2[2] OF oIni
         NEXT
         aDataAreas := GetIniSection( "Items", VRD_LF2SF(aValue[2]) )
         FOR n=1 TO Len(aDataAreas)
            aValue2:= hb_atokens(  aDataAreas[n] , "=" )
            SET SECTION cText+"Items" ENTRY aValue2[1] TO aValue2[2] OF oIni
         NEXT

      next

      ENDINI

   ENDIF

   Msginfo( "Exportación Realizada")

RETURN nil

//-----------------------------------------------------------------------------

function SaveFile()

   local nArea

   aVRDSave := ARRAY( 102, 2 )

   aVRDSave[101,1] := oER:cDefIni
   aVRDSave[101,2] := MEMOREAD( oER:cDefIni )
   aVRDSave[102,1] := oER:cGeneralIni
   aVRDSave[102,2] := MEMOREAD( oER:cGeneralIni )

   for nArea := 1 TO LEN( oER:aAreaIni )

      aVRDSave[nArea,1] := oER:aAreaIni[nArea]
      aVRDSave[nArea,2] := MEMOREAD( oER:aAreaIni[nArea] )

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
         for i := 1 TO Len( oER:aWnd )
            FErase( VRD_LF2SF( ALLTRIM( GetPvProfString( "Areas", ALLTRIM(STR(i,5)) , "", cAltDefIni ) ) ) )
         next
         FErase( cAltDefIni )
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
      for nArea := 1 TO LEN( oER:aAreaIni )

         if ! EMPTY( aVRDSave[nArea,1] )

            cAreaFile := SUBSTR( cFile, 1, LEN( cFile )-2 ) + PADL( ALLTRIM( STR( nArea, 2) ), 2, "0" )
            CreateNewFile( cAreaFile )

            aVRDSave[nArea,1] := VRD_LF2SF( cAreaFile )
            //aVRDSave[nArea,1] := SUBSTR( oER:cDefIni, 1, LEN( oER:cDefIni )-2 ) + ;
            //                  PADL( ALLTRIM( STR( nArea, 2) ), 2, "0" )
            MEMOWRIT( aVRDSave[nArea,1], aVRDSave[nArea,2] )

            oER:aAreaIni[nArea] := aVRDSave[nArea,1]

            //Areas in General Ini File ablegen
            WritePProString( "Areas", ALLTRIM(STR( nArea, 3)), cFileName( cAreaFile ), oER:cDefIni )

         endif

         //Areapfad speichern
         WritePProString( "General", "AreaFilesDir", cFilePath( oER:cDefIni ), oER:cDefIni )

      next

      SetSave( .T. )

      if VAL( GetPvProfString( "General", "MruList"  , "4", oER:cGeneralIni ) ) > 0
         oER:oMru:Save( cLongDefIni )
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
         for nArea := 1 TO LEN( oER:aAreaIni )
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
         if !EMPTY( cAreaDef )
            AADD( aFiles, { oER:aWndTitle[nWnd], cAreaDef } )
         endif
      endif
   next

   AEval( oER:aWnd, {|x| IIF( x <> NIL, ++nNrAreas, ) } )
   for i := 1 TO Len( oER:aWnd )
      if oER:aItems[i] <> NIL
         AEval( oER:aItems[i], {|x| IIF( x <> NIL, ++nNrItems, ) } )
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
   local oGet
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
   LOCAL aNames:=  {}
   LOCAL aDataAreas:= {}
   LOCAL aDataItem := {}
   LOCAL nDlgTextCol := oEr:nDlgTextCol
   LOCAL nDlgBackCol := oEr:nDlgBackCol
   LOCAL nAt
   LOCAL nArea:= 1

   local hVar:= {=>}

   AFill( aCheck, .T. )

   DEFINE FONT oFont NAME "Arial" SIZE 0, -12


   DEFINE DIALOG oDlg NAME "NEWREPORT" TITLE GL("New Report")

   REDEFINE BUTTON PROMPT GL("Create &Report") ID 101 OF oDlg ;
      ACTION IIF( CheckFileName( @cGeneralName, cSourceCode, lMakeSource ) = .T., ;
                  (  RestoreNewDatas( aDataAreas[ obrw:nArrayAt ] , @Hvar )       ,;
                  EVAL( {|| lCreate := .T., oDlg:End() } ) ), )
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

   addNewDatas( @aDataAreas, @aNames, nArea++ )

   nAt := 1
   LoadNewDatas( aDataAreas[nAt], HVar )

   REDEFINE xBrowse oBrw  ;
      Array aNames ;
      ID 301 OF oFld:aDialogs[i] ;
      ON CHANGE (RestoreNewDatas( aDataAreas[ nAt ] , @Hvar ),;
                  nAt:= oBrw:nArrayAt ,;
                  LoadNewDatas(  aDataAreas[ nAt ], @HVar ),;
                  oDlg:Update(), aGet2[1]:SetFocus() )


   obrw:nMarqueeStyle := MARQSTYLE_HIGHLROW
   obrw:bClrSel := { || { CLR_WHITE ,{ { 0.60, nRGB( 108, 163, 217 ), nRGB( 64, 127, 194 ) }, ;
                         { 0.40, nRGB( 64, 127, 194 ), nRGB( 40, 106, 180 ) } } } }


   REDEFINE BUTTON PROMPT GL("&New") ID 101 OF oFld:aDialogs[i] UPDATE ;
      ACTION ( RestoreNewDatas( aDataAreas[ nAt ] , @Hvar ), ;
               addNewDatas( aDataAreas, oBrw:aArrayData , nArea++ ) ,;
               nAt:= RenewNewDatas(aDataAreas,oBrw,hVar) ,;
               oBrw:GoBottom(), oDlg:Update() )

   REDEFINE BUTTON PROMPT GL("&Delete") ID 102 OF oFld:aDialogs[i] UPDATE ;
      ACTION ( nAt:= DelNewDatas( aDataAreas, oBrw, hVar ) , oDlg:Update() ) ;
      WHEN Len(aDataAreas) > 1

   REDEFINE BUTTON PROMPT GL("Move &up") ID 103 OF oFld:aDialogs[i] UPDATE ;
      ACTION (  RestoreNewDatas( aDataAreas[ nAt ] , Hvar ),;
                nAt:= MoveItem ( .t., oBrw, aDataAreas , hVar ),;
                obrw:goup() ) ;
      WHEN nAt != 1

   REDEFINE BUTTON PROMPT GL("Move &down") ID 104 OF oFld:aDialogs[i] UPDATE ;
      ACTION ( RestoreNewDatas( aDataAreas[ nAt ] , Hvar ),;
               nAt:= MoveItem ( .f., oBrw, aDataAreas, hVar ),;
               obrw:godown() ) ;
      WHEN nAt != Len(  aDataAreas )

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

   REDEFINE GET aGet2[1] VAR hVar["NAME"] ID 201 OF oFld:aDialogs[i] UPDATE ;
      VALID ( oBrw:aArrayData[oBrw:nArrayAt]:= hVar["NAME"], oBrw:Refresh(), !EMPTY( hVar["NAME"] ) )

   REDEFINE GET oget VAR hVar["TEXTNR"]  ID 202 OF oFld:aDialogs[i] UPDATE SPINNER MIN 0 MAX 99
   REDEFINE GET oget VAR hVar["IMAGENR"] ID 203 OF oFld:aDialogs[i] UPDATE SPINNER MIN 0 MAX 99
   REDEFINE GET oget VAR hVar["GRAPHNR"] ID 204 OF oFld:aDialogs[i] UPDATE SPINNER MIN 0 MAX 99
   REDEFINE GET oget VAR hVar["BCODENR"] ID 205 OF oFld:aDialogs[i] UPDATE SPINNER MIN 0 MAX 99

   REDEFINE GET hVar["TOP1"] ID 401 OF oFld:aDialogs[i] PICTURE "9999.99" SPINNER MIN 0 UPDATE WHEN !hVar["LTOP"]
   REDEFINE GET hVar["TOP2"] ID 402 OF oFld:aDialogs[i] PICTURE "9999.99" SPINNER MIN 0 UPDATE WHEN !hVar["LTOP"]


   REDEFINE CHECKBOX aCbx2[1] VAR hVar["LTOP"] ID 303 OF oFld:aDialogs[i] UPDATE

   REDEFINE GET hVar["WIDTH"]  ID 601 OF oFld:aDialogs[i] UPDATE PICTURE "9999.99" SPINNER MIN 0
   REDEFINE GET hVar["HEIGHT"] ID 602 OF oFld:aDialogs[i] UPDATE PICTURE "9999.99" SPINNER MIN 0

   REDEFINE RADIO oRad2 VAR  hVar["CONDITION"] ID 501, 502, 503, 504 OF oFld:aDialogs[i] UPDATE

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
                aCbx2[1]:SetText( GL("Top depends on") ) ,;
                oBrw:acols[1]:nwidth:= 180 , ;
                oBrw:acols[1]:cHeader:= GL("Name") ;
                 )

   oFont:End()

   if lCreate

      MsgRun( GL("Please wait..."), GL("New Report"), ;
         {|| CreateNewReport( aCheck, cGeneralName, cSourceCode, cReportName, lMakeSource, ;
                              nTop, nLeft, nPageBreak, nOrient, aMeasure, cMeasure,aDataAreas  ) } )
   endif

   if lCreate
      OpenFile( cGeneralName,, .T. )
   endif

return .T.

*-----------------------------------------------------------------------------

function CreateNewReport( aCheck, cGeneralName, cSourceCode, cReportName, lMakeSource, ;
                          nTop, nLeft, nPageBreak, nOrient, aMeasure, cMeasure,aDataAreas  )

   Local i, n
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
   LOCAL aNewErArea:= {}
   LOCAL cText:= ""
   LOCAL xIni, xSection, xNameArea

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

      FOR i=1 TO Len( aDataAreas )

           IF oER:lNewFormat
              xNameArea :=  cFileNoPath( SUBSTR( cLongDefIni, 1, LEN( cLongDefIni ) - 4 ) + ;
                            PADL( ALLTRIM( STR( i, 2 ) ), 2, "0" ))
           ELSE
              xNameArea :=  cFileNoPath( SUBSTR( cLongDefIni, 1, LEN( cLongDefIni ) - 2 ) + ;
                            PADL( ALLTRIM( STR( i, 2 ) ), 2, "0" ))
           ENDIF

           SET SECTION "Areas" ENTRY ALLTRIM(STR( i, 5)) TO xNameArea OF oIni

      NEXT

   ENDINI

   nDecimals := IIF( oER:nMeasure == 2, 2, 0 )

   //Area files

    FOR i=1 TO Len( aDataAreas )

         IF oER:lNewFormat

             cAreaTmpFile := AllTrim(SUBSTR( cLongDefIni, 1, LEN( cLongDefIni ) - 4 ) + ;
                         PADL( ALLTRIM( STR( i, 2 ) ), 2, "0" ) )


             xIni:=  cDefTmpIni
             xSection :=   cAreaTmpFile+"General"

         ELSE

             cAreaTmpFile := AllTrim(SUBSTR( cLongDefIni, 1, LEN( cLongDefIni ) - 2 ) + ;
                         PADL( ALLTRIM( STR( i, 2 ) ), 2, "0" ) )

             xIni:=  cAreaTmpFile
             xSection := "General"

             CreateNewFile( cAreaTmpFile )
             cAreaTmpFile := VRD_LF2SF( ALLTRIM( cAreaTmpFile ) )

         ENDIF

         INI oIni File xIni

         SET SECTION  xSection ENTRY "Title"       TO aDataAreas[i,1]  OF oIni
         SET SECTION  xSection ENTRY "Width"       TO ALLTRIM(STR( aDataAreas[i,9], 5, nDecimals )) OF oIni
         SET SECTION  xSection ENTRY "Height"      TO ALLTRIM(STR(aDataAreas[i,10], 5, nDecimals )) OF oIni
         SET SECTION  xSection ENTRY "Top1"        TO ALLTRIM(STR( aDataAreas[i,6], 5, nDecimals )) OF oIni
         SET SECTION  xSection ENTRY "Top2"        TO ALLTRIM(STR(aDataAreas[i,7], 5, nDecimals ))  OF oIni
         SET SECTION  xSection ENTRY "TopVariable" TO IIF(aDataAreas[i,8], "1", "0") OF oIni
         SET SECTION  xSection ENTRY "Condition"   TO STR(aDataAreas[i,11], 1 ) OF oIni

         nRow := 1
         nCol := 1
         nXRow := 0
         nXCol := 0

         for n := 1 TO aDataAreas[i,2]
            nXRow := 5 + ( nRow - 1 ) * 24
            nXCol := 5 + ( nCol - 1 ) * 55
            if GetCmInch( nXRow + 48 ) > aDataAreas[i,10]
               nRow := 1
               nCol += 1
            else
               nRow += 1
            endif

            if GetCmInch( nXCol + 55 ) >aDataAreas[i,9]
               EXIT
            endif

            IF oER:lNewFormat
               xSection :=  cAreaTmpFile + "Items"
            ELSE
               xSection := "Items"
            ENDIF


             SET SECTION xSection ENTRY ALLTRIM(STR(n,3)) ;
               TO "Text|" + ALLTRIM(STR(n,3)) + "| " + ALLTRIM(STR(n,3)) + "|1|1|1|" + ;
               ALLTRIM(STR( GetCmInch( nXRow ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( nXCol ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 50 ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 20 ), 5, nDecimals )) + "|" + ;
               "1|1|2|0|0|0|" OF oIni

         next

         if aDataAreas[i,2] > 0
            nColStart := nXCol + 55
         else
            nColStart := 5
         endif
         nCol := 1
         nRow := 1

         for n := 1 TO aDataAreas[i,3]
            nXRow := 5 + ( nRow - 1 ) * 24
            nXCol := nColStart + ( nCol - 1 ) * 55
            if GetCmInch( nXRow + 48 ) > aDataAreas[i,10]
               nRow := 1
               nCol += 1
            else
               nRow += 1
            endif
            if GetCmInch( nXCol + 55 ) > aDataAreas[i,9]
               EXIT
            endif

            SET SECTION xSection ENTRY ALLTRIM(STR(100+n,3)) ;
               TO "Image|| " + ALLTRIM(STR(100+n,3)) + "|1|1|1|" + ;
               ALLTRIM(STR( GetCmInch( nXRow ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( nXCol ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 50 ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 20 ), 5, nDecimals )) + "|" + ;
               "|0" OF oIni
         next

         if aDataAreas[i,2] > 0 .OR. aDataAreas[i,3] > 0
            nColStart := nXCol + 55
         else
            nColStart := 5
         endif

         nCol := 1
         nRow := 1

         for n := 1 TO aDataAreas[i,4]
            nXRow := 5 + ( nRow - 1 ) * 24
            nXCol := nColStart + ( nCol - 1 ) * 55
            if GetCmInch( nXRow + 48 ) > aDataAreas[i,10]
               nRow := 1
               nCol += 1
            else
               nRow += 1
            endif
            if GetCmInch( nXCol + 55 ) > aDataAreas[i,9]
               EXIT
            endif

            SET SECTION xSection ENTRY ALLTRIM(STR(200+n,3)) ;
               TO "LineHorizontal|" + GL("Line horizontal") + "| " + ALLTRIM(STR(200+n,3)) + "|1|1|1|" + ;
               ALLTRIM(STR( GetCmInch( nXRow ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( nXCol ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 50 ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 20 ), 5, nDecimals )) + "|" + ;
               "1|2|1|1|0|0" OF oIni
         next

         if aDataAreas[i,2] > 0 .OR. aDataAreas[i,3] > 0 .OR. aDataAreas[i,4] > 0
            nColStart := nXCol + 55
         else
            nColStart := 5
         endif
         nCol := 1
         nRow := 1


        for n := 1 TO aDataAreas[i,5]
            nXRow := 5 + ( nRow - 1 ) * 24
            nXCol := nColStart + ( nCol - 1 ) * 175
            if GetCmInch( nXRow + 48 ) > aDataAreas[i,10]
               nRow := 1
               nCol += 1
            else
               nRow += 1
            endif
            if GetCmInch( nXCol + 175 ) > aDataAreas[i,9]
               EXIT
            endif



            SET SECTION xSection ENTRY ALLTRIM(STR(300+n,3)) ;
               TO "Barcode|12345678| " + ALLTRIM(STR(300+n,3)) + "|1|1|1|" + ;
               ALLTRIM(STR( GetCmInch( nXRow ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( nXCol ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 170 ), 5, nDecimals )) + "|" + ;
               ALLTRIM(STR( GetCmInch( 20 ), 5, nDecimals )) + "|" + ;
               "1|1|2|1|1|0.3|" OF oIni

         next


      ENDINI

    next

    // create source code
   if lMakeSource = .T.

      cSource := CRLF
      cSource += SPACE(3) + 'oVRD := VRD():New( "' + ALLTRIM(cGeneralName) + '", lPreview, cPrinter, oWnd )'
      cSource += CRLF + CRLF

     FOR i=1 TO Len( aDataAreas )

         cText:= SPACE(3)+"oVRD:PrintItem( " + ALLTRIM(STR(i,3))

         if !EMPTY( aDataAreas[i,1] )
            cSource += SPACE(3) + "//--- Area: " + ALLTRIM( aDataAreas[i,1] ) + " ---"
         endif
         IF aDataAreas[i,2] > 0
            cSource += CRLF + SPACE(3) + "//Text items" + CRLF
            for n := 1 TO aDataAreas[i,2]
              cSource += cText + ", " + ALLTRIM(STR( n, 5)) + ", )" + CRLF
            next
         ENDIF

         IF aDataAreas[i,3] > 0
             cSource += CRLF + SPACE(3) + "//Image items" + CRLF
            for n := 1 TO aDataAreas[i,3]
                cSource += cText  + ", " + ALLTRIM(STR( 100+n, 5)) + ", )" + CRLF
            next
         endif


         if aDataAreas[i,4] > 0
            cSource += CRLF + SPACE(3) + "//Graphic items" + CRLF
            for n := 1 TO aDataAreas[i,4]
              cSource += cText + ", " + ALLTRIM(STR( 200+n, 5)) + ", )" + CRLF
            next
         endif


         if aDataAreas[i,5] > 0
            cSource += CRLF + SPACE(3) + "//Barcode items" + CRLF
            for n := 1 TO aDataAreas[i,5]
                 cSource += cText + ", " + ALLTRIM(STR( 300+n, 5)) + ", )" + CRLF
            next
         endif

         cSource += CRLF + SPACE(3) + ;
                    "oVRD:PrintRest( " + ALLTRIM(STR(i,3)) + " )" + ;
                    CRLF + CRLF
      next

      cSource += SPACE(3) + "oVRD:End()" + CRLF

      IF oER:lNewFormat


      else
         CreateNewFile( cSourceCode )
         MEMOWRIT( VRD_LF2SF( cSourceCode ), cSource )
      endif
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
      IF msgYesNo("Quiere usar el nuevo Formato" )
         cGeneralName := ALLTRIM( cGeneralName ) + ".erd"
         oEr:lNewFormat:= .T.
      else
         cGeneralName := ALLTRIM( cGeneralName ) + ".vrd"
         oEr:lNewFormat:= .F.
      endif
   elseif lMakeSource
      if EMPTY( cSourceCode ) .OR. AT( "\\", cSourceCode ) <> 0
         lreturn := .F.
         MsgStop( GL("Please insert a valid source code file name."), GL("Stop!") )
      endif
   endif

return ( lreturn )

*-----------------------------------------------------------------------------

function SetNewReportDefaults( nAreas )

 LOCAL aNewErArea:= Array(11)

   aNewErArea[1] := ALLTRIM(STR( nAreas)) + ". " + GL("Area")
   aNewErArea[2] := 0
   aNewErArea[3] := 0
   aNewErArea[4] := 0
   aNewErArea[5] := 0
   aNewErArea[6] := 0
   aNewErArea[7] := 0
   aNewErArea[8] := .T.
   aNewErArea[9] := 200
   aNewErArea[10] := 40
   aNewErArea[11] := 1

return aNewErArea

//------------------------------------------------------------------------------

function MoveItem ( lUp, oBrw, aDataAreas , hVar )

   local aItemData2 := {}
   LOCAL cName2
   LOCAL nAt := obrw:nArrayAt
   LOCAL nBackPos := IF( lUp, nAt-1, nAt+1 )

   aItemData2 := aDataAreas[ nBackPos ]
   aDataAreas[ nBackPos ] :=  aDataAreas[ nAt ]
   aDataAreas[ nAt] :=  aItemData2

   cName2:= obrw:aArrayData[ nBackPos ]
   oBrw:aArrayData[ nBackPos ]:= obrw:aArrayData[ nAt ]
   oBrw:aArrayData[ nAt ]:= cName2

Return RenewNewDatas(aDataAreas,oBrw,hVar)

//------------------------------------------------------------------------------

function LoadNewDatas( aDataItem, HVar )
   LOCAL i,cName
    LOCAL aNames:= { "NAME", "TEXTNR", "IMAGENR", "GRAPHNR", "BCODENR" ,;
               "TOP1", "TOP2", "LTOP", "WIDTH", "HEIGHT", "CONDITION" }

    FOR i= 1 TO Len( aNames )
        cName:= aNames[i]
        HVar[ cName ]:= aDataItem[i]
    NEXT

 return .T.

//------------------------------------------------------------------------------

FUNCTION addNewDatas( aDataAreas, aNames, nArea )
   LOCAL aDataItem:= {}

   aDataItem:= SetNewReportDefaults(nArea)

   AAdd( aDataAreas, aDataItem )
   AAdd( aNames, aDataItem[1] )

RETURN .t.

//------------------------------------------------------------------------------

FUNCTION DelNewDatas( aDataAreas, oBrw, hVar  )
   LOCAL nAt:= oBrw:nArrayAt

   ADel( oBrw:aArrayData, nAt ,.t. )
   ADel( aDataAreas, nAt , .t. )

RETURN RenewNewDatas(aDataAreas,oBrw,hVar)

//------------------------------------------------------------------------------

FUNCTION RenewNewDatas(aDataAreas,oBrw,hVar)
   LOCAL nAt
   oBrw:Refresh()
   nAt:= oBrw:nArrayAt
   LoadNewDatas(  aDataAreas[ nAt ], hVar )

RETURN nAt
//------------------------------------------------------------------------------

FUNCTION RestoreNewDatas( aDataItem , Hvar )

    LOCAL i,cName
    LOCAL aNames:= { "NAME", "TEXTNR", "IMAGENR", "GRAPHNR", "BCODENR" ,;
               "TOP1", "TOP2", "LTOP", "WIDTH", "HEIGHT", "CONDITION" }

    FOR i= 1 TO Len( aNames )
        cName:= anames[i]
        aDataItem[i] := HVar[ cName ]
    NEXT

RETURN nil

//------------------------------------------------------------------------------

