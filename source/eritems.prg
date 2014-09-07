
#INCLUDE "Folder.ch"
#INCLUDE "FiveWin.ch"

MEMVAR aItems, aFonts, aAreaIni, aWnd, aWndTitle
MEMVAR oCbxArea, aCbxItems
MEMVAR nAktItem, nAktArea, nSelArea, aSelection
MEMVAR oMsgInfo
MEMVAR lFillWindow, nDeveloper
MEMVAR nRuler, nRulerTop
MEMVAR cItemCopy, nCopyEntryNr, nCopyAreaNr, aSelectCopy, aItemCopy, nXMove, nYMove
MEMVAR cInfoWidth, cInfoHeight, nInfoRow, nInfoCol, aItemPixelPos
MEMVAR cMeasure
MEMVAR lProfi, oCurDlg, oGenVar,oER

STATIC aItemPosition

//----------------------------------------------------------------------------//

function ElementActions( oItem, i, cName, nArea, cAreaIni, cTyp )

   oItem:bLDblClick = { || If( GetKeyState( VK_SHIFT ), MultiItemProperties(), ;
                             ( ItemProperties( i, nArea ), oCurDlg:SetFocus() ) ) }

   //oItems:bGotFocus  := {|| SelectItem( i, nArea, cAreaIni ), MsgBarInfos( i, cAreaIni ) }

   oItem:bLClicked = { | nRow, nCol, nFlags | ;
      If( oGenVar:lItemDlg, ( If( GetKeyState( VK_SHIFT ), MultiItemProperties(), ;
                            ( ItemProperties( i, nArea ), oCurDlg:SetFocus() ) ) ), ;
                            ( SelectItem( i, nArea, cAreaIni ), ;
                              nInfoRow := nRow, nInfoCol := nCol, ;
                              MsgBarItem( i, nArea, cAreaIni, nRow, nCol ) ) ) }

   // AEVAL( oItems:aDots, {|x| x:Show(), BringWindowToTop( x:hWnd ), x:Refresh() } ) }

   // oItems:bMoved     := {|| IIF( GetKeyState( VK_SHIFT ), .T., SetItemSize( i, nArea, cAreaIni ) ), ;
   //                         MsgBarItem( i, nArea, cAreaIni,,, .T. ) }

   // oItems:bResized   := {|| IIF( GetKeyState( VK_SHIFT ), .T., SetItemSize( i, nArea, cAreaIni ) ), ;
   //                         MsgBarItem( i, nArea, cAreaIni,,, .T. ) }

   oItem:bMoved   = { || SetItemSize( i, nArea, cAreaIni ),;
                         MsgBarItem( i, nArea, cAreaIni,,, .T. ) }

   oItem:bResized = { || SetItemSize( i, nArea, cAreaIni ),;
                         MsgBarItem( i, nArea, cAreaIni,,, .T. ) }

   oItem:bMMoved  = { | nRow, nCol, nFlags, aPoint | ;
                        aPoint := { nRow, nCol },;
                        aPoint := ClientToScreen( oItem:hWnd, aPoint ),;
                        aPoint := ScreenToClient( aWnd[ nArea ]:hWnd, aPoint ),;
                        nRow := aPoint[ 1 ], nCol := aPoint[ 2 ],;
                        SetReticule( nRow, nCol, nArea ),;
                        MsgBarItem( i, nArea, cAreaIni, nRow, nCol ) }

   oItem:bRClicked = { | nRow, nCol, nFlags | oItem:SetFocus(),;
                         ItemPopupMenu( oItem, i, nArea, nRow, nCol ) }

   oItem:nDlgCode = DLGC_WANTALLKEYS

   oItem:bKeyDown   = { | nKey | KeyDownAction( nKey, i, nArea, cAreaIni ) }

   oItem:bLostFocus = { | nRow, nCol, nFlags | ;
                        ( SelectItem( i, nArea, cAreaIni ), ;
                          nInfoRow := nRow, nInfoCol := nCol, ;
                          MsgBarItem( i, nArea, cAreaIni, nRow, nCol ) ) }

return .T.

//----------------------------------------------------------------------------//

function KeyDownAction( nKey, nItem, nArea, cAreaIni )

   local aWerte   := GetCoors( aItems[nArea,nItem]:hWnd )
   local nTop     := aWerte[1]
   local nLeft    := aWerte[2]
   local nHeight  := aWerte[3] - aWerte[1]
   local nWidth   := aWerte[4] - aWerte[2]
   local lMove    := .T.
   local nY       := 0
   local nX       := 0
   local nRight   := 0
   local nBottom  := 0

   if LEN( aSelection ) <> 0
      WndKeyDownAction( nKey, nArea, cAreaIni )
      return .T.
   endif

   //Delete item
   if nKey == VK_DELETE
      DelItemWithKey( nItem, nArea )
   endif

   //return to edit properties
   if nKey == VK_RETURN
      ItemProperties( nItem, nArea )
   endif

   //Move and resize items
   if GetKeyState( VK_SHIFT )
      do case
      case nKey == VK_LEFT
         nRight := -1 * nXMove
      case nKey == VK_RIGHT
         nRight := 1 * nXMove
      case nKey == VK_UP
         nBottom := -1 * nYMove
      case nKey == VK_DOWN
         nBottom := 1 * nYMove
      OTHERWISE
         lMove := .F.
      endcase
   ELSE
      do case
      case nKey == VK_LEFT
         nX := -1 * nXMove
      case nKey == VK_RIGHT
         nX :=  1 * nXMove
      case nKey == VK_UP
         nY := -1 * nYMove
      case nKey == VK_DOWN
         nY :=  1 * nYMove
      OTHERWISE
         lMove := .F.
      endcase
   endif

   if lMove
      aItems[nArea,nItem]:Move( nTop + nY, nLeft + nX, nWidth + nRight, nHeight + nBottom, .T. )
      aItems[nArea,nItem]:ShowDots( .T. )
   endif

return .T.

//----------------------------------------------------------------------------//

function DeleteItem( i, nArea, lFromList, lRemove, lFromUndoRedo )

   local cItemDef, cOldDef, oIni, cWert
   local aFirst    := { .F., 0, 0, 0, 0, 0 }
   local nElemente := 0
   local cAreaIni  := aAreaIni[nArea]

   DEFAULT lFromList := .F.
   DEFAULT lRemove   := .T.
   DEFAULT lFromUndoredo := .F.

   if i = NIL
      MsgStop( GL("Please select an item first."), GL("Stop!") )
      return (.F.)
   endif

   if !lFromList
      if MsgYesNo( GL("Remove the current item?"), GL("Select an option") ) = .F.
         return (.F.)
      endif
   endif

   cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(i,5)) , "", cAreaIni ) )
   cOldDef  := cItemDef

   if lRemove
      cWert := " 0"
   ELSE
      cWert := " 1"
   endif

   cItemDef := SUBSTR( cItemDef, 1, StrAtNum( "|", cItemDef, 3 ) ) + " " + ;
               cWert + ;
               SUBSTR( cItemDef, StrAtNum( "|", cItemDef, 4 ) )

   INI oIni FILE cAreaIni
      SET SECTION "Items" ENTRY AllTrim(STR(i,5)) TO cItemDef OF oIni
   ENDINI

   if lRemove
      aItems[nArea,i]:lDrag := .F.
      aItems[nArea,i]:HideDots()
      aItems[nArea,i]:End()
   ELSE
      ShowItem( i, nArea, cAreaIni, @aFirst, @nElemente )
      aItems[nArea,i]:lDrag := .T.
   endif

   if !lFromUndoRedo
      Add2Undo( cOldDef, i, nArea )
   endif

   SetSave( .F. )

return .T.

//----------------------------------------------------------------------------//

function DeleteAllItems( nTyp )

   local i, cTyp, cDef, oItem
   local nLen := LEN( aItems[nAktArea] )

   if MsgYesNo( GL("Remove items?"), GL("Select an option") ) = .F.
      return (.F.)
   endif

   FOR i := 1 TO nLen

      cDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(i,5)) , "", aAreaIni[nAktArea] ) )

      if !EMPTY( cDef )

         oItem := VRDItem():New( cDef )

         cTyp := UPPER(AllTrim( GetField( cDef, 1 ) ))

         if nTyp = 1 .AND. oItem:cType = "TEXT"           .OR. ;
            nTyp = 2 .AND. oItem:cType = "IMAGE"          .OR. ;
            nTyp = 3 .AND. IsGraphic( oItem:cType ) = .T. .OR. ;
            nTyp = 4 .AND. oItem:cType = "BARCODE"

            if oItem:lVisible
               DeleteItem( i, nAktArea, .T., .T. )
            endif

         endif

      endif

   NEXT

return .T.

//----------------------------------------------------------------------------//

function DelItemWithKey( nItem, nArea )

   local cItemDef  := AllTrim( GetPvProfString( "Items", AllTrim(STR( nItem,5)), "", aAreaIni[nArea] ) )
   local oItemInfo := VRDItem():New( cItemDef )

   DeleteItem( nItem, nArea, .T. )

   if oItemInfo:nItemID < 0
      DelIniEntry( "Items", AllTrim(STR(nItem,5)), aAreaIni[nArea] )
   endif

   nAktItem := 0

return .T.

//----------------------------------------------------------------------------//

function ItemPopupMenu( oItem, nItem, nArea, nRow, nCol )

   local oMenu
   local cItemDef  := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)), "", aAreaIni[nArea] ) )
   local oItemInfo := VRDItem():New( cItemDef )

   MENU oMenu POPUP

   MENUITEM GL("&Item Properties") RESOURCE "PROPERTY" ;
      ACTION ItemProperties( nItem, nArea )

   if oItemInfo:nDelete = 1
      SEPARATOR
      MENUITEM GL("&Visible") CHECKED ACTION DeleteItem( nItem, nArea, .T. )
   endif

   if oItemInfo:nItemID < 0
      SEPARATOR
      MENUITEM GL("&Remove Item") RESOURCE "DEL" ACTION DelItemWithKey( nItem, nArea )
   endif

   SEPARATOR
   MENUITEM GL("Cu&t") + chr(9) + GL("Ctrl+X") ;
      ACTION ( ItemCopy( .T. ), nAktItem := 0 )
   MENUITEM GL("&Copy") + chr(9) + GL("Ctrl+C") ;
      ACTION ItemCopy( .F. )
   MENUITEM GL("&Paste") + chr(9) + GL("Ctrl+V") ;
      ACTION ItemPaste() ;
      WHEN .NOT. EMPTY( cItemCopy )

   ENDMENU

   nRow += oItem:nTop
   nCol += oItem:nLeft

   ACTIVATE POPUP oMenu OF aWnd[nArea] AT nRow, nCol

return .T.

//----------------------------------------------------------------------------//

function ItemProperties( i, nArea, lFromList, lNew )

   local cOldDef, cItemDef, cTyp, cName
   local cAreaIni := aAreaIni[nArea]

   DEFAULT lFromList := .F.
   DEFAULT lNew      := .F.

   if i = NIL .OR. i = 0
      MsgStop( GL("Please select an item first."), GL("Stop!") )
      return (.F.)
   endif

   UnSelectAll()

   if oCurDlg <> NIL
    //  oGenVar:lDlgSave := .T.  // comentado fix bug
      oCurDlg:End()
      oCurDlg := NIL
   endif

   cOldDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(i,5)) , "", cAreaIni ) )
   cTyp    := UPPER(AllTrim( GetField( cOldDef, 1 ) ))

   if cTyp = "TEXT"
      TextProperties( i, nArea, cAreaIni, lFromList, lNew )
   ELSEif cTyp = "IMAGE"
      ImageProperties( i, nArea, cAreaIni, lFromList, lNew )
   ELSEif IsGraphic( cTyp ) = .T.
      GraphicProperties( i, nArea, cAreaIni, lFromList, lNew )
   ELSEif cTyp = "BARCODE"
      BarcodeProperties( i, nArea, cAreaIni, lFromList, lNew )
   endif

   cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(i,5)) , "", cAreaIni ) )

   cName := AllTrim( GetField( cItemDef, 2 ) )

   if UPPER( cTyp ) = "IMAGE" .AND. EMPTY( cName ) = .T.
      cName := AllTrim(STR(i,5)) + ". " + AllTrim( GetField( cItemDef, 11 ) )
   ELSE
      cName := AllTrim(STR(i,5)) + ". " + cName
   endif

   Memory(-1)
   SysRefresh()

return ( cName )

//----------------------------------------------------------------------------//

function MultiItemProperties()

   local oDlg, aCbx[1], aGrp[1]
   local cItemDef  := AllTrim( GetPvProfString( "Items", AllTrim(STR( aSelection[1,2], 5 )), ;
                      "", aAreaIni[ aSelection[1,1] ] ) )
   local nTop      := VAL( GetField( cItemDef, 7 ) )
   local nLeft     := VAL( GetField( cItemDef, 8 ) )
   local nWidth    := VAL( GetField( cItemDef, 9 ) )
   local nHeight   := VAL( GetField( cItemDef, 10 ) )
   local aOldValue := { nTop, nLeft, nWidth, nHeight }
   local cPicture  := IIF( oER:nMeasure = 2, "999.99", "99999" )
   local lAddValue := .F.

   DEFINE DIALOG oDlg RESOURCE "MULTISELECT" TITLE GL("Item Properties")

   REDEFINE GET nTop ID 301 OF oDlg PICTURE cPicture SPINNER ;
      VALID UpdateItems( nTop   , 1, lAddValue, @aOldValue )
   REDEFINE GET nLeft     ID 302 OF oDlg PICTURE cPicture SPINNER ;
      VALID UpdateItems( nLeft  , 2, lAddValue, @aOldValue )
   REDEFINE GET nWidth    ID 303 OF oDlg PICTURE cPicture SPINNER ;
      VALID UpdateItems( nWidth , 3, lAddValue, @aOldValue )
   REDEFINE GET nHeight   ID 304 OF oDlg PICTURE cPicture SPINNER ;
      VALID UpdateItems( nHeight, 4, lAddValue, @aOldValue )

   REDEFINE CHECKBOX aCbx[1] VAR lAddValue ID 305 OF oDlg

   REDEFINE BUTTON PROMPT GL("&OK") ID 101 OF oDlg ACTION oDlg:End()

   REDEFINE GROUP aGrp[1] ID 190 OF oDlg

   REDEFINE SAY PROMPT GL("Top:")    ID 170 OF oDlg
   REDEFINE SAY PROMPT GL("Left:")   ID 171 OF oDlg
   REDEFINE SAY PROMPT GL("Width:")  ID 172 OF oDlg
   REDEFINE SAY PROMPT GL("Height:") ID 173 OF oDlg

   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT ( oDlg:Move( 120, oEr:oMainWnd:nRight - 240,,, .T. ), ;
                aGrp[1]:SetText( GL("Position / Size") ), ;
                aCbx[1]:SetText( GL("Add values") ) )

   //RefreshSelection()

return .T.

//----------------------------------------------------------------------------//

function UpdateItems( nValue, nTyp, lAddValue, aOldValue )

   local i, aWerte, nTop, nLeft, nWidth, nHeight
   local lStop     := .F.
   local nPixValue := ER_GetPixel( nValue )

   do case
   case nTyp = 1 .AND. nValue = aOldValue[1] ; lStop := .T.
   case nTyp = 2 .AND. nValue = aOldValue[2] ; lStop := .T.
   case nTyp = 3 .AND. nValue = aOldValue[3] ; lStop := .T.
   case nTyp = 4 .AND. nValue = aOldValue[4] ; lStop := .T.
   endcase

   if lStop
      return( .T. )
   endif

   UnSelectAll( .F. )

   FOR i := 1 TO LEN( aSelection )

      aWerte  := GetCoors( aItems[ aSelection[i,1], aSelection[i,2] ]:hWnd )
      nTop    := aWerte[1]
      nLeft   := aWerte[2]
      nHeight := aWerte[3] - aWerte[1]
      nWidth  := aWerte[4] - aWerte[2]

      do case
      case nTyp = 1 ; IIF( lAddValue, nTop    += nPixValue, nTop    := nRulerTop + nPixValue )
      case nTyp = 2 ; IIF( lAddValue, nLeft   += nPixValue, nLeft   := nRuler    + nPixValue )
      case nTyp = 3 ; IIF( lAddValue, nWidth  += nPixValue, nWidth  := nPixValue )
      case nTyp = 4 ; IIF( lAddValue, nHeight += nPixValue, nHeight := nPixValue )
      endcase

      aOldValue[nTyp] := nValue

      aItems[ aSelection[i,1], aSelection[i,2]] :Move( nTop, nLeft, nWidth, nHeight, .T. ) //, .T. )

      aItems[ aSelection[i,1], aSelection[i,2] ]:Refresh()

   NEXT

   UnSelectAll( .F. )

return .T.

//----------------------------------------------------------------------------//

function TextProperties( i, nArea, cAreaIni, lFromList, lNew )

   local oIni, nColor
   local aCbx[5], aGrp[3], aGet[5], aSay[4]
   local nDefClr, oBtn, oBtn2, oBtn3
   local oVar  := GetoVar( i, nArea, cAreaIni, lNew )
   local oItem := VRDItem():New( oVar:cItemDef )

   oVar:AddMember( "aOrient"    ,, { GL("Left"), GL("Center"), GL("Right"), ;
                                     GL("Flush justified"), GL("Line-makeup") } )
   oVar:AddMember( "cOrient"    ,, oVar:aOrient[ IIF( oItem:nOrient = 0, 1, oItem:nOrient ) ]                )
   oVar:AddMember( "aColors"    ,, GetAllColors()                                                          )
   oVar:AddMember( "aBitmaps"   ,, { "ALIGN_LEFT", "ALIGN_CENTER", "ALIGN_RIGHT", ;
                                     "ALIGN_BLOCK", "ALIGN_WRAP" } )

   oGenVar:lItemDlg := .T.

   DEFINE DIALOG oCurDlg RESOURCE "TEXTPROPERTY" TITLE GL("Text Properties")

   nDefClr := oCurDlg:nClrPane

   REDEFINE GET aGet[4] VAR oItem:cText ID 201 OF oCurDlg WHEN oItem:nEdit <> 0 MEMO

   REDEFINE BTNBMP oBtn2 ID 154 OF oCurDlg NOBORDER RESOURCE "SELECT" TRANSPARENT ;
      TOOLTIP GL("Databases and Expressions") WHEN oItem:nEdit <> 0 ;
      ACTION GetDBField( aGet[4] )

   REDEFINE GET aGet[5] VAR oItem:nItemID ID 202 OF oCurDlg PICTURE "99999" SPINNER ;
      ON UP   ( oItem:nItemID := oItem:nItemID + 1, aGet[5]:Refresh(), IIF( oItem:nItemID < 0, oBtn:Show(), oBtn:Hide() ) ) ;
      ON DOWN ( oItem:nItemID := oItem:nItemID - 1, aGet[5]:Refresh(), IIF( oItem:nItemID < 0, oBtn:Show(), oBtn:Hide() ) ) ;
      VALID ( IIF( oItem:nItemID < 0, oBtn:Show(), oBtn:Hide() ), .T. )

   REDEFINE SAY aSay[4] ID 121 OF oCurDlg

   REDEFINE GET oItem:nTop      ID 301 OF oCurDlg PICTURE oVar:cPicture ;
      SPINNER MIN 0 MAX oVar:nGesHeight - oItem:nHeight ;
      VALID oItem:nTop >= 0 .AND. oItem:nTop + oItem:nHeight <= oVar:nGesHeight
   REDEFINE GET oItem:nLeft     ID 302 OF oCurDlg PICTURE oVar:cPicture ;
      SPINNER MIN 0 MAX oVar:nGesWidth - oItem:nWidth ;
      VALID oItem:nLeft >= 0 .AND. oItem:nLeft + oItem:nWidth <= oVar:nGesWidth
   REDEFINE GET oItem:nWidth    ID 303 OF oCurDlg PICTURE oVar:cPicture ;
      SPINNER MIN 0.01 MAX oVar:nGesWidth - oItem:nLeft ;
      VALID oItem:nWidth > 0 .AND. oItem:nLeft + oItem:nWidth <= oVar:nGesWidth
   REDEFINE GET oItem:nHeight   ID 304 OF oCurDlg PICTURE oVar:cPicture ;
      SPINNER MIN 0.01 MAX oVar:nGesHeight - oItem:nTop ;
      VALID oItem:nHeight > 0 .AND. oItem:nTop + oItem:nHeight <= oVar:nGesHeight

   REDEFINE COMBOBOX oVar:cOrient ITEMS oVar:aOrient BITMAPS oVar:aBitmaps ID 305 OF oCurDlg

   REDEFINE CHECKBOX aCbx[3] VAR oItem:lVisible    ID 306 OF oCurDlg WHEN oItem:nDelete <> 0
   REDEFINE CHECKBOX aCbx[4] VAR oItem:lMultiLine  ID 307 OF oCurDlg
   REDEFINE CHECKBOX aCbx[5] VAR oItem:lVariHeight ID 308 OF oCurDlg

   REDEFINE GET aGet[1] VAR oItem:nColText ID 501 OF oCurDlg PICTURE "9999" SPINNER MIN 1 MAX 30 ;
      ON CHANGE Set2Color( aSay[1], IIF( oItem:nColText > 0, oVar:aColors[oItem:nColText], ""), nDefClr ) ;
      VALID     Set2Color( aSay[1], IIF( oItem:nColText > 0, oVar:aColors[oItem:nColText], ""), nDefClr )
   REDEFINE GET aGet[2] VAR oItem:nColPane ID 502 OF oCurDlg PICTURE "9999" SPINNER MIN 1 MAX 30 ;
      ON CHANGE Set2Color( aSay[2], IIF( oItem:nColPane > 0, oVar:aColors[oItem:nColPane], ""), nDefClr ) ;
      VALID     Set2Color( aSay[2], IIF( oItem:nColPane > 0, oVar:aColors[oItem:nColPane], ""), nDefClr ) ;
      WHEN oItem:lTrans = .F.
   REDEFINE GET aGet[3] VAR oItem:nFont    ID 503 OF oCurDlg PICTURE "9999" SPINNER MIN 1 MAX 20 ;
      ON CHANGE aSay[3]:Refresh() ;
      VALID     ( aSay[3]:Refresh(), .T. )

   REDEFINE CHECKBOX aCbx[1] VAR oItem:lBorder ID 601 OF oCurDlg
   REDEFINE CHECKBOX aCbx[2] VAR oItem:lTrans  ID 602 OF oCurDlg

   REDEFINE BTNBMP aSay[1] PROMPT "" ID 401 OF oCurDlg NOBORDER ;
   ACTION GetColorBtn( @oItem:nColText , aSay[1], aGet[1], oVar, nDefClr )
   aSay[1]:lBoxSelect := .f.
   aSay[1]:SetColor( GetColor( oItem:nColText ), GetColor( oItem:nColText ) )

   REDEFINE BTNBMP aSay[2] PROMPT "" ID 402 OF oCurDlg NOBORDER ;
     ACTION GetColorBtn( @oItem:nColPane , aSay[2], aGet[2], oVar, nDefClr )
     aSay[2]:SetColor(  GetColor( oItem:nColPane ), GetColor( oItem:nColPane ) )
     aSay[2]:lBoxSelect := .f.

   REDEFINE SAY aSay[3] PROMPT ;
      IIF( oItem:nFont > 0, " " + GetCurrentFont( oItem:nFont, GetFonts(), 1 ), "" ) ;
      ID 403 OF oCurDlg

   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 151 OF oCurDlg ;
      ACTION GetColorBtn(  @oItem:nColText, aSay[1], aGet[1], oVar, nDefClr )

   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 152 OF oCurDlg ;
      ACTION GetColorBtn( @oItem:nColPane, aSay[2], aGet[2], oVar, nDefClr )

   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 153 OF oCurDlg ;
      ACTION ( oItem:nFont := ShowFontChoice( oItem:nFont ), aGet[3]:Refresh(), aSay[3]:Refresh() )

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oCurDlg ;
      ACTION ( oGenVar:lDlgSave := .T., oGenVar:lItemDlg := .F., oCurDlg:End() )

   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oCurDlg ;
      ACTION ( oGenVar:lItemDlg := .F., oCurDlg:End() )

   REDEFINE BUTTON oBtn PROMPT GL("&Remove Item") ID 103 OF oCurDlg ;
      ACTION ( oVar:lRemoveItem := .T., oItem:lVisible := .F., ;
               oGenVar:lDlgSave := .T., oGenVar:lItemDlg := .F., oCurDlg:End() )

   oBtn3 := SetFormulaBtn( 9, oItem )
   SetFormulaBtn( 10, oItem )
   SetFormulaBtn( 11, oItem )
   SetFormulaBtn( 12, oItem )
   SetFormulaBtn( 13, oItem )
   SetFormulaBtn( 14, oItem )
   SetFormulaBtn( 15, oItem )
   SetFormulaBtn( 16, oItem )
   SetFormulaBtn( 17, oItem )
   SetFormulaBtn( 18, oItem )
   SetFormulaBtn( 19, oItem )
   SetFormulaBtn( 20, oItem )
   SetFormulaBtn( 21, oItem )
   SetFormulaBtn( 24, oItem )

   REDEFINE BTNBMP ID 111 OF oCurDlg NOBORDER RESOURCE "B_SAVE3" TRANSPARENT ;
      TOOLTIP GL("Set these properties to default") ;
      ACTION SetItemDefault( oItem )

   REDEFINE BUTTON PROMPT GL("&Set") ID 104 OF oCurDlg ACTION SaveTextItem( oVar, oItem )

   REDEFINE GROUP aGrp[1] ID 190 OF oCurDlg
   REDEFINE GROUP aGrp[2] ID 191 OF oCurDlg
   REDEFINE GROUP aGrp[3] ID 192 OF oCurDlg

   REDEFINE SAY PROMPT GL("Top:")              ID 170 OF oCurDlg
   REDEFINE SAY PROMPT GL("Left:")             ID 171 OF oCurDlg
   REDEFINE SAY PROMPT GL("Width:")            ID 172 OF oCurDlg
   REDEFINE SAY PROMPT GL("Height:")           ID 173 OF oCurDlg
   REDEFINE SAY PROMPT GL("Alignment:")        ID 174 OF oCurDlg
   REDEFINE SAY PROMPT GL("Text color:")       ID 176 OF oCurDlg
   REDEFINE SAY PROMPT GL("Background color:") ID 177 OF oCurDlg
   REDEFINE SAY PROMPT GL("Font") +":"         ID 178 OF oCurDlg

   REDEFINE SAY PROMPT cMeasure ID 181 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 182 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 183 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 184 OF oCurDlg

   ACTIVATE DIALOG oCurDlg CENTERED ; // NOMODAL ;
      ON INIT ( GetItemDlgPos(), ;
                IIF( nDeveloper = 0, ( aGet[5]:Hide(), aSay[4]:Hide(), aGet[4]:nWidth( 329 ), oBtn2:nLeft := 352, oBtn3:nLeft := 374 ), ), ;
                IIF( oVar:cShowExpr = "0" .OR. lProfi = .F., oBtn3:Hide(), ), ;
                IIF( lFromList = .T. .OR. oItem:nItemID > 0, oBtn:Hide(), ), ;
                IIF( lFromList = .T., aCbx[3]:Hide(), ), ;
                aGrp[1]:SetText( GL("Text") ), ;
                aGrp[2]:SetText( GL("Position / Size") ), ;
                aGrp[3]:SetText( GL("Colors / Font") ), ;
                aCbx[1]:SetText( GL("Print border") ), ;
                aCbx[2]:SetText( GL("Transparent") ), ;
                aCbx[3]:SetText( GL("Visible") ), ;
                aCbx[4]:SetText( GL("Multiline") ), ;
                aCbx[5]:SetText( GL("Variable height") ) ) ;
      VALID ( IIF( oGenVar:lDlgSave, SaveTextItem( oVar, oItem ), oGenVar:lItemDlg := .F. ), ;
              oGenVar:lDlgSave := .F., SetItemDlg() )

   oCurDlg:bMoved := {|| SetItemDlg() }

return ( .T. )

//----------------------------------------------------------------------------//

Function GetColorBtn( cColorItem , oSay, oGet, oVar, nDefClr )
local nColor := ShowColorChoice( cColorItem )
      IF  nColor <> 0
         cColorItem := nColor
         oGet:Refresh()
         Set2Color( oSay, IIF( cColorItem > 0, oVar:aColors[cColorItem], ""), nDefClr )
      endif
Return nil

//----------------------------------------------------------------------------//

function SetItemDefault( oItem )

   WritePProString( "General", "Default" + IIF( oItem:lGraphic, "GRAPHIC", oItem:cType ), ;
                    oItem:Set( .F., oER:nMeasure ), oER:cDefIni )

return .T.

//----------------------------------------------------------------------------//

function SetFormulaBtn( nID, oItem )

   local oBtn
   local cSource := ""

   do case
   case nID =  9  ; cSource := oItem:cSource
   case nID = 10  ; cSource := oItem:cSTop
   case nID = 11  ; cSource := oItem:cSLeft
   case nID = 12  ; cSource := oItem:cSWidth
   case nID = 13  ; cSource := oItem:cSHeight
   case nID = 14  ; cSource := oItem:cSAlignment
   case nID = 15  ; cSource := oItem:cSVisible
   case nID = 16  ; cSource := oItem:cSMultiline
   case nID = 17  ; cSource := oItem:cSTextClr
   case nID = 18  ; cSource := oItem:cSBackClr
   case nID = 19  ; cSource := oItem:cSFont
   case nID = 20  ; cSource := oItem:cSPrBorder
   case nID = 21  ; cSource := oItem:cSTransparent
   case nID = 22  ; cSource := oItem:cSPenSize
   case nID = 23  ; cSource := oItem:cSPenStyle
   case nID = 24  ; cSource := oItem:cSVariHeight
   endcase

   REDEFINE BTNBMP oBtn ID nID OF oCurDlg NOBORDER ;
      RESOURCE "B_SOURCE_" + IIF( EMPTY( cSource ), "NO", "YES" ) TRANSPARENT ;
      TOOLTIP GetSourceToolTip( cSource ) ;
      WHEN oItem:nEdit <> 0 ;
      ACTION ( cSource := EditSourceCode( nID, cSource, oItem ), ;
               oBtn:LoadBitmaps( "B_SOURCE_" + IIF( EMPTY( cSource ), "NO", "YES" ) ), ;
               oBtn:cToolTip := GetSourceToolTip( cSource ) )

return ( oBtn )

//----------------------------------------------------------------------------//

function EditSourceCode( nID, cSourceCode, oItem )

   local oDlg, oGet1
   local cOldSource := cSourceCode
   local lSave      := .F.

   DEFINE DIALOG oDlg NAME "SOURCECODE" TITLE GL("Formula")

   REDEFINE GET oGet1 VAR cSourceCode ID 201 OF oDlg MEMO

   oGet1:bGotFocus:={|| oGet1:setpos(oGet1:nPos) }

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE BUTTON PROMPT GL("&Insert Database Field") ID 103 OF oDlg ;
      ACTION GetDBField( oGet1, .T. )

   ACTIVATE DIALOG oDlg CENTER

   if lSave .AND. nID <> 0
      do case
      case nID =  9  ; oItem:cSource       := cSourceCode
      case nID = 10  ; oItem:cSTop         := cSourceCode
      case nID = 11  ; oItem:cSLeft        := cSourceCode
      case nID = 12  ; oItem:cSWidth       := cSourceCode
      case nID = 13  ; oItem:cSHeight      := cSourceCode
      case nID = 14  ; oItem:cSAlignment   := cSourceCode
      case nID = 15  ; oItem:cSVisible     := cSourceCode
      case nID = 16  ; oItem:cSMultiline   := cSourceCode
      case nID = 17  ; oItem:cSTextClr     := cSourceCode
      case nID = 18  ; oItem:cSBackClr     := cSourceCode
      case nID = 19  ; oItem:cSFont        := cSourceCode
      case nID = 20  ; oItem:cSPrBorder    := cSourceCode
      case nID = 21  ; oItem:cSTransparent := cSourceCode
      case nID = 22  ; oItem:cSPenSize     := cSourceCode
      case nID = 23  ; oItem:cSPenStyle    := cSourceCode
      endcase
   endif

return IIF( lSave, cSourceCode, cOldSource )

//----------------------------------------------------------------------------//

function GetItemDlgPos()

   if oGenVar:nDlgTop  > 0 .AND. oGenVar:nDlgTop  <= GetSysMetrics( 1 ) - 80 .AND. ;
      oGenVar:nDlgLeft > 0 .AND. oGenVar:nDlgLeft <= GetSysMetrics( 0 ) - 80
      oCurDlg:Move( oGenVar:nDlgTop, oGenVar:nDlgLeft,,, .T. )
   ELSE
      WritePProString( "ItemDialog", "Top" , "0", oER:cGeneralIni )
      WritePProString( "ItemDialog", "Left", "0", oER:cGeneralIni )
   endif

return .T.

//----------------------------------------------------------------------------//

function SetItemDlg()

   local oRect := oCurDlg:GetRect()

   oGenVar:nDlgTop  := oRect:nTop
   oGenVar:nDlgLeft := oRect:nLeft

   WritePProString( "ItemDialog", "Top" , AllTrim(STR( oGenVar:nDlgTop , 10 )), oER:cGeneralIni )
   WritePProString( "ItemDialog", "Left", AllTrim(STR( oGenVar:nDlgLeft, 10 )), oER:cGeneralIni )

return .T.

//----------------------------------------------------------------------------//

function GetoVar( i, nArea, cAreaIni, lNew )

   local oVar := TExStruct():New()

   oVar:AddMember( "cItemDef"   ,, AllTrim( GetPvProfString( "Items", AllTrim(STR(i,5)) , "", cAreaIni ) ) )
   oVar:AddMember( "i"          ,, i                                                                       )
   oVar:AddMember( "nArea"      ,, nArea                                                                   )
   oVar:AddMember( "cAreaIni"   ,, cAreaIni                                                                )
   oVar:AddMember( "cOldDef"    ,, oVar:cItemDef                                                           )
   oVar:AddMember( "lNew"       ,, lNew                                                                    )
   oVar:AddMember( "lRemoveItem",, .F.                                                                     )
   oVar:AddMember( "cShowExpr"  ,, AllTrim( GetPvProfString( "General", "Expressions", "0", oER:cDefIni ) )    )
   oVar:AddMember( "nGesWidth"  ,, VAL( GetPvProfString( "General", "Width", "600", cAreaIni ) )           )
   oVar:AddMember( "nGesHeight" ,, VAL( GetPvProfString( "General", "Height", "300", cAreaIni ) )          )
   oVar:AddMember( "cPicture"   ,, IIF( oER:nMeasure = 2, "999.99", "99999" )                                  )

return ( oVar )

//----------------------------------------------------------------------------//

function SaveTextItem( oVar, oItem )

   local lRight, lCenter, nColor, oFont, oIni

   oItem:nOrient := ASCAN( oVar:aOrient, oVar:cOrient )
   oItem:nBorder := IIF( oItem:lBorder , 1, 0 )
   oItem:nTrans  := IIF( oItem:lTrans  , 1, 0 )
   oItem:nShow   := IIF( oItem:lVisible, 1, 0 )

   oVar:cItemDef := oItem:Set( .F., oER:nMeasure )

   INI oIni FILE oVar:cAreaIni
      SET SECTION "Items" ENTRY AllTrim(STR(oVar:i,5)) TO oVar:cItemDef OF oIni
   ENDINI

   oFont := IIF( oItem:nFont = 0, oEr:oAppFont, aFonts[oItem:nFont] )
   lCenter := IIF( oItem:nOrient = 2, .T., .F. )
   lRight  := IIF( oItem:nOrient = 3,  .T., .F. )

   if oItem:lVisible

      aItems[oVar:nArea,oVar:i]:End()
      aItems[oVar:nArea,oVar:i] := ;
         TSay():New( nRulerTop + ER_GetPixel( oItem:nTop ), nRuler + ER_GetPixel( oItem:nLeft ), ;
                     {|| oItem:cText }, aWnd[oVar:nArea],, ;
                     oFont, lCenter, lRight, ( oItem:lBorder .OR. oGenVar:lShowBorder ), ;
                     .T., GetColor( oItem:nColText ), GetColor( oItem:nColPane ), ;
                     ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ), ;
                     .F., .T., .F., .F., .F. )

      aItems[oVar:nArea,oVar:i]:lDrag := .T.
      ElementActions( aItems[oVar:nArea,oVar:i], oVar:i, oItem:cText, oVar:nArea, oVar:cAreaIni )
      aItems[oVar:nArea,oVar:i]:SetFocus()

   endif

   // Diese Funktion darf nicht aufgerufen werden, weil beim Sprung von einem
   // Textelement zu einem Bildelement ein Fehler generiert wird.
   // Der Funktionsinhalt mu� direkt angeh�ngt werden.
   //SaveItemGeneral( oVar, oItem )

   if !oItem:lVisible .AND. aItems[oVar:nArea,oVar:i] <> NIL
      aItems[oVar:nArea,oVar:i]:lDrag := .F.
      aItems[oVar:nArea,oVar:i]:HideDots()
      aItems[oVar:nArea,oVar:i]:End()
   endif

   if oVar:lRemoveItem
      DelIniEntry( "Items", AllTrim(STR(oVar:i,5)), oVar:cAreaIni )
   endif

   SetSave( .F. )

   if oVar:lNew
      Add2Undo( "", oVar:i, oVar:nArea )
   ELSEif oVar:cOldDef <> oVar:cItemDef
      Add2Undo( oVar:cOldDef, oVar:i, oVar:nArea )
   endif

   oCurDlg:SetFocus()

return ( .T. )

//----------------------------------------------------------------------------//

function SaveItemGeneral( oVar, oItem )

   // Immer auch SaveTextItem aktualisieren.
   // Der Funktionsinhalt mu� dort direkt angeh�ngt werden.

   if !oItem:lVisible .AND. aItems[oVar:nArea,oVar:i] <> NIL
      aItems[oVar:nArea,oVar:i]:lDrag := .F.
      aItems[oVar:nArea,oVar:i]:HideDots()
      aItems[oVar:nArea,oVar:i]:End()
   endif

   if oVar:lRemoveItem
      DelIniEntry( "Items", AllTrim(STR(oVar:i,5)), oVar:cAreaIni )
   endif

   SetSave( .F. )

   if oVar:lNew
      Add2Undo( "", oVar:i, oVar:nArea )
   ELSEif oVar:cOldDef <> oVar:cItemDef
      Add2Undo( oVar:cOldDef, oVar:i, oVar:nArea )
   endif

   oCurDlg:SetFocus()

return .T.

//----------------------------------------------------------------------------//

function ImageProperties( i, nArea, cAreaIni, lFromList, lNew )

   local oIni, aBtn[3], oCbx1, oCbx2, aGet[3], aSay[1], aGrp[2], aSizeSay[2]
   local oVar  := GetoVar( i, nArea, cAreaIni, lNew )
   local oItem := VRDItem():New( oVar:cItemDef )
   local aSize := GetImageSize( oItem:cFile )

   oGenVar:lItemDlg := .T.

   DEFINE DIALOG oCurDlg RESOURCE "IMAGEPROPERTY" TITLE GL("Image Properties")

   REDEFINE GET aGet[2] VAR oItem:cText ID 201 OF oCurDlg WHEN oItem:nEdit <> 0 MEMO
   REDEFINE GET aGet[1] VAR oItem:cFile ID 202 OF oCurDlg WHEN oItem:nEdit <> 0 ;
      VALID ( aSize := GetImageSize( oItem:cFile ), AEVAL( aSizeSay, {|x| x:Refresh() } ), .T. )
   REDEFINE BTNBMP ID 150 OF oCurDlg RESOURCE "B_OPEN_16" TRANSPARENT NOBORDER WHEN oItem:nEdit <> 0 ;
      TOOLTIP GL("Open") ACTION ( oItem:cFile := GetImage( oItem:cFile ), aGet[1]:Refresh() )

   REDEFINE BTNBMP aBtn[2] ID 152 OF oCurDlg RESOURCE "SELECT" TRANSPARENT NOBORDER ;
      TOOLTIP GL("Databases and Expressions") WHEN oItem:nEdit <> 0 ;
      ACTION GetDBField( aGet[1] )

   REDEFINE GET aGet[3] VAR oItem:nItemID ID 204 OF oCurDlg PICTURE "99999" SPINNER ;
      ON UP   ( oItem:nItemID := oItem:nItemID + 1, aGet[3]:Refresh(), IIF( oItem:nItemID < 0, aBtn[1]:Show(), aBtn[1]:Hide() ) ) ;
      ON DOWN ( oItem:nItemID := oItem:nItemID - 1, aGet[3]:Refresh(), IIF( oItem:nItemID < 0, aBtn[1]:Show(), aBtn[1]:Hide() ) ) ;
      VALID ( IIF( oItem:nItemID < 0, aBtn[1]:Show(), aBtn[1]:Hide() ), .T. )

   REDEFINE SAY aSay[1] ID 130 OF oCurDlg

   REDEFINE GET oItem:nTop      ID 301 OF oCurDlg PICTURE oVar:cPicture SPINNER MIN 0 MAX oVar:nGesHeight - oItem:nHeight ;
      VALID oItem:nTop >= 0 .AND. oItem:nTop + oItem:nHeight <= oVar:nGesHeight
   REDEFINE GET oItem:nLeft     ID 302 OF oCurDlg PICTURE oVar:cPicture SPINNER MIN 0 MAX oVar:nGesWidth - oItem:nWidth ;
      VALID oItem:nLeft >= 0 .AND. oItem:nLeft + oItem:nWidth <= oVar:nGesWidth
   REDEFINE GET oItem:nWidth    ID 303 OF oCurDlg PICTURE oVar:cPicture SPINNER MIN 0.01 MAX oVar:nGesWidth - oItem:nLeft ;
      VALID oItem:nWidth > 0 .AND. oItem:nLeft + oItem:nWidth <= oVar:nGesWidth
   REDEFINE GET oItem:nHeight   ID 304 OF oCurDlg PICTURE oVar:cPicture SPINNER MIN 0.01 MAX oVar:nGesHeight - oItem:nTop ;
      VALID oItem:nHeight > 0 .AND. oItem:nTop + oItem:nHeight <= oVar:nGesHeight

   REDEFINE CHECKBOX oCbx2 VAR oItem:lVisible ID 305 OF oCurDlg WHEN oItem:nDelete <> 0
   REDEFINE CHECKBOX oCbx1 VAR oItem:lBorder  ID 203 OF oCurDlg

   REDEFINE SAY PROMPT GL("Original width")  + ":" ID 311 OF oCurDlg
   REDEFINE SAY PROMPT GL("Original height") + ":" ID 312 OF oCurDlg

   REDEFINE SAY aSizeSay[1] PROMPT aSize[1] ID 321 OF oCurDlg
   REDEFINE SAY aSizeSay[2] PROMPT aSize[2] ID 322 OF oCurDlg

   REDEFINE SAY PROMPT cMeasure ID 120 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 121 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 122 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 123 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 125 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 126 OF oCurDlg

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oCurDlg ;
      ACTION ( oGenVar:lDlgSave := .T., oGenVar:lItemDlg := .F., oCurDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oCurDlg ;
      ACTION ( oGenVar:lItemDlg := .F., oCurDlg:End() )
   REDEFINE BUTTON aBtn[1] PROMPT GL("&Remove Item") ID 103 OF oCurDlg ;
      ACTION ( oVar:lRemoveItem := .T., oItem:lVisible := .F., ;
               oGenVar:lDlgSave := .T., oGenVar:lItemDlg := .F., oCurDlg:End() )

   aBtn[3] := SetFormulaBtn( 9, oItem )
   SetFormulaBtn( 10, oItem )
   SetFormulaBtn( 11, oItem )
   SetFormulaBtn( 12, oItem )
   SetFormulaBtn( 13, oItem )
   SetFormulaBtn( 15, oItem )
   SetFormulaBtn( 20, oItem )

   REDEFINE BTNBMP ID 111 OF oCurDlg NOBORDER RESOURCE "B_SAVE3" TRANSPARENT ;
      TOOLTIP GL("Set these properties to default") ;
      ACTION SetItemDefault( oItem )

   REDEFINE BUTTON PROMPT GL("&Set") ID 104 OF oCurDlg ACTION SaveImgItem( oVar, oItem )

   REDEFINE GROUP aGrp[1] ID 190 OF oCurDlg
   REDEFINE GROUP aGrp[2] ID 191 OF oCurDlg

   REDEFINE SAY PROMPT GL("Text") + ":" ID 170 OF oCurDlg
   REDEFINE SAY PROMPT GL("File:")   ID 171 OF oCurDlg
   REDEFINE SAY PROMPT GL("Top:")    ID 173 OF oCurDlg
   REDEFINE SAY PROMPT GL("Left:")   ID 174 OF oCurDlg
   REDEFINE SAY PROMPT GL("Width:")  ID 175 OF oCurDlg
   REDEFINE SAY PROMPT GL("Height:") ID 176 OF oCurDlg

   ACTIVATE DIALOG oCurDlg CENTERED ; //NOMODAL ;
      ON INIT ( GetItemDlgPos(), ;
                IIF( nDeveloper = 0, ( aGet[3]:Hide(), aSay[1]:Hide(), aGet[2]:nWidth( 328 ) ), ), ;
                IIF( lFromList = .T. .OR. oItem:nItemID > 0, aBtn[1]:Hide(), ), ;
                IIF( oVar:cShowExpr = "0" .OR. lProfi = .F., aBtn[3]:Hide(), ), ;
                aGrp[1]:SetText( GL("Image") ), ;
                aGrp[2]:SetText( GL("Position / Size") ), ;
                oCbx1:SetText( GL("Border") ), ;
                oCbx2:SetText( GL("Visible") ) ) ;
      VALID ( IIF( oGenVar:lDlgSave, SaveImgItem( oVar, oItem ), oGenVar:lItemDlg := .F. ), ;
              oGenVar:lDlgSave := .F., SetItemDlg() )

   oCurDlg:bMoved := {|| SetItemDlg() }

return ( .T. )

//----------------------------------------------------------------------------//

function GetImageSize( cFile )

   local oImg
   local aSizes := { "--", "--" }
   LOCAL nDecimals := IIF( oER:nMeasure == 2, 2, 0 )

   if FILE( cFile ) .OR. AT( "RES:", UPPER( cFile ) ) <> 0

      oImg := TImage():New( 0, 0, 0, 0,,,, oEr:oMainWnd )
      oImg:Progress(.F.)
      oImg:LoadImage( IIF( AT( "RES:", UPPER( cFile ) ) <> 0, ;
                           SUBSTR( AllTrim( cFile ), 5 ), NIL ), ;
                      VRD_LF2SF( cFile ) )
      aSizes := { AllTrim(STR( GetCmInch( oImg:nWidth()  ), 5, nDecimals )), ;
                  AllTrim(STR( GetCmInch( oImg:nHeight() ), 5, nDecimals )) }
      oImg:End()

   endif

return ( aSizes )

//----------------------------------------------------------------------------//

function SaveImgItem( oVar, oItem )

   local oIni

   oItem:nBorder := IIF( oItem:lBorder , 1, 0 )
   oItem:nShow   := IIF( oItem:lVisible, 1, 0 )

   oVar:cItemDef := oItem:Set( .F., oER:nMeasure )

   INI oIni FILE oVar:cAreaIni
      SET SECTION "Items" ENTRY AllTrim(STR(oVar:i,5)) TO oVar:cItemDef OF oIni
   ENDINI

   if oItem:nShow = 1

      aItems[oVar:nArea,oVar:i]:End()
      aItems[oVar:nArea,oVar:i] := TImage():New( nRulerTop + ER_GetPixel( oItem:nTop ), ;
         nRuler + ER_GetPixel( oItem:nLeft ), ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ),,, ;
         IIF( oItem:lBorder, .F., .T. ), aWnd[oVar:nArea],,, .F., .T.,,, .T.,, .T. )
      aItems[oVar:nArea,oVar:i]:Progress(.F.)
      aItems[oVar:nArea,oVar:i]:LoadBmp( VRD_LF2SF( oItem:cFile ) )

      aItems[oVar:nArea,oVar:i]:lDrag := .T.
      ElementActions( aItems[oVar:nArea,oVar:i], oVar:i, oItem:cText, oVar:nArea, oVar:cAreaIni )
      aItems[oVar:nArea,oVar:i]:SetFocus()

   endif

   SaveItemGeneral( oVar, oItem )

return .T.

//----------------------------------------------------------------------------//

function GraphicProperties( i, nArea, cAreaIni, lFromList, lNew )

   local oIni, oBtn, oCmb1, aCbx[2], nColor, nDefClr
   local aGet[4], aSay[3], aGrp[3]
   local oVar  := GetoVar( i, nArea, cAreaIni, lNew )
   local oItem := VRDItem():New( oVar:cItemDef )

   oVar:AddMember( "aColors" ,, GetAllColors()  )
   oVar:AddMember( "aGraphic",, { GL("Line up"), GL("Line down"), ;
                                  GL("Line horizontal"), GL("Line vertical"), ;
                                  GL("Rectangle"), GL("Ellipse") } )
   oVar:AddMember( "cGraphic",, oVar:aGraphic[ GetGraphIndex( oItem:cType ) ] )
   oVar:AddMember( "aBMPs"   ,, { "LINEUP","LINEDOWN","LINEHORI","LINEVERT","RECTANGLE","ELLIPSE" } )
   oVar:AddMember( "aStyles" ,, { "1", "2", "3", "4", "5" } )
   oVar:AddMember( "cStyle"  ,, oVar:aStyles[ oItem:nStyle ] )
   oVar:AddMember( "aBMP2s"  ,, { "STYLE1", "STYLE2", "STYLE3", "STYLE4", "STYLE5" } )

   oGenVar:lItemDlg := .T.

   DEFINE DIALOG oCurDlg RESOURCE "GRAPHICPROPERTY" TITLE GL("Graphic Properties")

   //Typ ausw�hlen
   REDEFINE COMBOBOX oVar:cGraphic ITEMS oVar:aGraphic ID 201 OF oCurDlg ;
      UPDATE BITMAPS oVar:aBMPs WHEN oItem:nEdit <> 0 ;
      ON CHANGE aGet[4]:SetFocus()

   REDEFINE GET aGet[3] VAR oItem:nItemID ID 202 OF oCurDlg PICTURE "99999" SPINNER ;
      ON UP   ( oItem:nItemID := oItem:nItemID + 1, aGet[3]:Refresh(), IIF( oItem:nItemID < 0, oBtn:Show(), oBtn:Hide() ) ) ;
      ON DOWN ( oItem:nItemID := oItem:nItemID - 1, aGet[3]:Refresh(), IIF( oItem:nItemID < 0, oBtn:Show(), oBtn:Hide() ) ) ;
      VALID ( IIF( oItem:nItemID < 0, oBtn:Show(), oBtn:Hide() ), .T. )

   REDEFINE SAY aSay[3] ID 124 OF oCurDlg

   REDEFINE GET aGet[4] VAR oItem:nTop ID 301 OF oCurDlg PICTURE oVar:cPicture ;
      SPINNER MIN 0 MAX oVar:nGesHeight - oItem:nHeight ;
      VALID oItem:nTop >= 0 .AND. oItem:nTop + oItem:nHeight <= oVar:nGesHeight
   REDEFINE GET oItem:nLeft     ID 302 OF oCurDlg PICTURE oVar:cPicture ;
      SPINNER MIN 0 MAX oVar:nGesWidth - oItem:nWidth ;
      VALID oItem:nLeft >= 0 .AND. oItem:nLeft + oItem:nWidth <= oVar:nGesWidth
   REDEFINE GET oItem:nWidth    ID 303 OF oCurDlg PICTURE oVar:cPicture ;
      SPINNER MIN 0.01 MAX oVar:nGesWidth - oItem:nLeft ;
      VALID oItem:nWidth > 0 .AND. oItem:nLeft + oItem:nWidth <= oVar:nGesWidth
   REDEFINE GET oItem:nHeight   ID 304 OF oCurDlg PICTURE oVar:cPicture ;
      SPINNER MIN 0.01 MAX oVar:nGesHeight - oItem:nTop ;
      VALID oItem:nHeight > 0 .AND. oItem:nTop + oItem:nHeight <= oVar:nGesHeight

   REDEFINE SAY PROMPT cMeasure ID 120 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 121 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 122 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 123 OF oCurDlg

   REDEFINE CHECKBOX aCbx[1] VAR oItem:lVisible ID 305 OF oCurDlg WHEN oItem:nDelete <> 0

   //Rounded Corners
   REDEFINE GET oItem:nRndWidth ID 701 OF oCurDlg UPDATE PICTURE oVar:cPicture ;
      SPINNER MIN 0 MAX oItem:nWidth/2 ;
      VALID oItem:nRndWidth >= 0 .AND. oItem:nRndWidth*2 <= oItem:nWidth ;
      WHEN ASCAN( oVar:aGraphic, oVar:cGraphic ) = 5
   REDEFINE GET oItem:nRndHeight ID 702 OF oCurDlg UPDATE PICTURE oVar:cPicture ;
      SPINNER MIN 0 MAX oItem:nHeight/2 ;
      VALID oItem:nRndHeight >= 0 .AND. oItem:nRndHeight*2 <= oItem:nHeight ;
      WHEN ASCAN( oVar:aGraphic, oVar:cGraphic ) = 5

   REDEFINE GET aGet[1] VAR oItem:nColor ID 501 OF oCurDlg PICTURE "9999" SPINNER MIN 1 MAX 30 ;
      ON CHANGE Set2Color( aSay[1], IIF( oItem:nColor > 0, oVar:aColors[oItem:nColor], ""), nDefClr ) ;
      VALID     Set2Color( aSay[1], IIF( oItem:nColor > 0, oVar:aColors[oItem:nColor], ""), nDefClr )

   REDEFINE GET aGet[2] VAR oItem:nColFill ID 502 OF oCurDlg PICTURE "9999" SPINNER MIN 1 MAX 30 ;
      ON CHANGE Set2Color( aSay[2], IIF( oItem:nColFill > 0, oVar:aColors[oItem:nColFill], ""), nDefClr ) ;
      VALID     Set2Color( aSay[2], IIF( oItem:nColFill > 0, oVar:aColors[oItem:nColFill], ""), nDefClr ) ;
      WHEN oItem:lTrans = .F.

   REDEFINE SAY aSay[1] PROMPT "" ID 401 OF oCurDlg COLORS GetColor( oItem:nColText ), GetColor( oItem:nColText )
   REDEFINE SAY aSay[2] PROMPT "" ID 402 OF oCurDlg COLORS GetColor( oItem:nColPane ), GetColor( oItem:nColPane )

   REDEFINE BTNBMP ID 151 OF oCurDlg NOBORDER RESOURCE "SELECT" TRANSPARENT ;
      ACTION GetColorBtn( @oItem:nColor , aSay[1], aGet[1], oVar, nDefClr )

    //  ACTION ( nColor := ShowColorChoice( oItem:nColor ), ;
    //           IIF( nColor <> 0, EVAL( {|| oItem:nColor := nColor, aGet[1]:Refresh(), ;
    //           Set2Color( aSay[1], IIF( oItem:nColor > 0, oVar:aColors[oItem:nColor], ""), nDefClr ) } ), ) )

   REDEFINE BTNBMP ID 152 OF oCurDlg NOBORDER RESOURCE "SELECT" TRANSPARENT ;
    ACTION GetColorBtn( @oItem:nColFill , aSay[2], aGet[2], oVar, nDefClr )

   //   ACTION ( nColor := ShowColorChoice( oItem:nColFill ), ;
   //            IIF( nColor <> 0, EVAL( {|| oItem:nColFill := nColor, aGet[2]:Refresh(), ;
   //            Set2Color( aSay[2], IIF( oItem:nColFill > 0, oVar:aColors[oItem:nColFill], ""), nDefClr ) } ), ) )

   REDEFINE CHECKBOX aCbx[2] VAR oItem:lTrans ID 603 OF oCurDlg

   //Style ausw�hlen
   REDEFINE COMBOBOX oCmb1 VAR oVar:cStyle ITEMS oVar:aStyles ID 601 OF oCurDlg UPDATE BITMAPS oVar:aBMP2s

   REDEFINE GET oItem:nPenWidth ID 602 OF oCurDlg PICTURE "99" SPINNER MIN 1

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oCurDlg ;
      ACTION ( oGenVar:lDlgSave := .T., oGenVar:lItemDlg := .F., oCurDlg:End() )

   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oCurDlg ;
      ACTION ( oGenVar:lItemDlg := .F., oCurDlg:End() )

   REDEFINE BUTTON oBtn PROMPT GL("&Remove Item") ID 103 OF oCurDlg ;
      ACTION ( oVar:lRemoveItem := .T., oItem:lVisible := .F., ;
               oGenVar:lDlgSave := .T., oGenVar:lItemDlg := .F., oCurDlg:End() )

   SetFormulaBtn( 10, oItem )
   SetFormulaBtn( 11, oItem )
   SetFormulaBtn( 12, oItem )
   SetFormulaBtn( 13, oItem )
   SetFormulaBtn( 15, oItem )
   SetFormulaBtn( 17, oItem )
   SetFormulaBtn( 18, oItem )
   SetFormulaBtn( 21, oItem )
   SetFormulaBtn( 22, oItem )
   SetFormulaBtn( 23, oItem )

   REDEFINE BTNBMP ID 111 OF oCurDlg NOBORDER RESOURCE "B_SAVE3" TRANSPARENT ;
      TOOLTIP GL("Set these properties to default") ;
      ACTION SetItemDefault( oItem )

   REDEFINE BUTTON PROMPT GL("&Set") ID 104 OF oCurDlg ACTION SaveGraItem( oVar, oItem )

   REDEFINE GROUP aGrp[1] ID 190 OF oCurDlg
   REDEFINE GROUP aGrp[2] ID 191 OF oCurDlg
   REDEFINE GROUP aGrp[3] ID 192 OF oCurDlg

   REDEFINE SAY PROMPT GL("Top:")        ID 170 OF oCurDlg
   REDEFINE SAY PROMPT GL("Left:")       ID 171 OF oCurDlg
   REDEFINE SAY PROMPT GL("Width:")      ID 172 OF oCurDlg
   REDEFINE SAY PROMPT GL("Height:")     ID 173 OF oCurDlg
   REDEFINE SAY PROMPT GL("Color") + ":" ID 174 OF oCurDlg
   REDEFINE SAY PROMPT GL("Fill color:") ID 175 OF oCurDlg
   REDEFINE SAY PROMPT GL("Pen size:")   ID 176 OF oCurDlg
   REDEFINE SAY PROMPT GL("Type:")       ID 177 OF oCurDlg
   REDEFINE SAY PROMPT ;
      GL("Please note: The special styles will only work with pen size 1.") ID 178 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 180 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 181 OF oCurDlg
   REDEFINE SAY PROMPT GL("Width:")      ID 182 OF oCurDlg
   REDEFINE SAY PROMPT GL("Height:")     ID 183 OF oCurDlg
   REDEFINE SAY PROMPT GL("Rounded Corners") + ":" ID 184 OF oCurDlg

   ACTIVATE DIALOG oCurDlg CENTERED ; // NOMODAL ;
      ON INIT ( GetItemDlgPos(), ;
                IIF( nDeveloper = 0, EVAL( {|| aGet[3]:Hide(), aSay[3]:Hide() }), ), ;
                IIF( lFromList = .T. .OR. oItem:nItemID > 0, oBtn:Hide(), ), ;
                aGrp[1]:SetText( GL("Graphic") ), ;
                aGrp[2]:SetText( GL("Position / Size") ), ;
                aGrp[3]:SetText( GL("Color / Style") ), ;
                aCbx[1]:SetText( GL("Visible") ), ;
                aCbx[2]:SetText( GL("Transparent") ) ) ;
      VALID ( IIF( oGenVar:lDlgSave, SaveGraItem( oVar, oItem ), oGenVar:lItemDlg := .F. ), ;
              oGenVar:lDlgSave := .F., SetItemDlg() )

   oCurDlg:bMoved := {|| SetItemDlg() }

return ( .T. )

//----------------------------------------------------------------------------//

function SaveGraItem( oVar, oItem )

   local oIni

   oItem:cType  := GetGraphName( ASCAN( oVar:aGraphic, oVar:cGraphic ) )
   oItem:cText  := oVar:cGraphic
   oItem:nStyle := VAL( oVar:cStyle )
   oItem:nTrans := IIF( oItem:lTrans, 1, 0 )

   oVar:cItemDef := oItem:Set( .F., oER:nMeasure )

   INI oIni FILE oVar:cAreaIni
      SET SECTION "Items" ENTRY AllTrim(STR(oVar:i,5)) TO oVar:cItemDef OF oIni
   ENDINI

   if oItem:nShow = 1

      aItems[oVar:nArea,oVar:i]:End()

      aItems[oVar:nArea,oVar:i] := TBitmap():New( nRulerTop + ER_GetPixel( oItem:nTop ), ;
          nRuler + ER_GetPixel( oItem:nLeft ), ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ), ;
          "GRAPHIC",, .T., aWnd[oVar:nArea],,, .F., .T.,,, .T.,, .T. )
      aItems[oVar:nArea,oVar:i]:lTransparent := .T.

      aItems[oVar:nArea,oVar:i]:bPainted = {| hDC, cPS | ;
         DrawGraphic( hDC, AllTrim(UPPER( oItem:cType )), ;
                      ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ), ;
                      GetColor( oItem:nColor ), GetColor( oItem:nColFill ), ;
                      oItem:nStyle, oItem:nPenWidth, ;
                      ER_GetPixel( oItem:nRndWidth ), ER_GetPixel( oItem:nRndHeight ) ) }

      aItems[oVar:nArea,oVar:i]:lDrag := .T.
      ElementActions( aItems[oVar:nArea,oVar:i], oVar:i, "", oVar:nArea, oVar:cAreaIni )
      aItems[oVar:nArea,oVar:i]:SetFocus()

   endif

   SaveItemGeneral( oVar, oItem )

return .T.

//----------------------------------------------------------------------------//

function BarcodeProperties( i, nArea, cAreaIni, lFromList, lNew )

   local oFont, oIni, lRight, lCenter, nColor
   local nDefClr, aBtn[3], aGet[6], aSay[4], aGrp[3], aCbx[2]
   local oVar  := GetoVar( i, nArea, cAreaIni, lNew )
   local oItem := VRDItem():New( oVar:cItemDef )

   oVar:AddMember( "aBarcode"    ,, GetBarcodes()                                         )
   oVar:AddMember( "cBarcode"    ,, oVar:aBarcode[oItem:nBCodeType]                       )
   oVar:AddMember( "aOrient"     ,, { GL("Horizontal"), GL("Vertical") }                  )
   oVar:AddMember( "cOrient"     ,, oVar:aOrient[ IIF( oItem:nOrient = 0, 1, oItem:nOrient ) ] )
   oVar:AddMember( "aBitmaps"    ,, { "BCODE_HORI", "BCODE_VERT" }                        )
   oVar:AddMember( "aColors"     ,, GetAllColors()                                        )
   oVar:AddMember( "cPinPicture" ,, IIF( oER:nMeasure = 2, "99.9999", "999.99" )              )

   oGenVar:lItemDlg := .T.

   DEFINE DIALOG oCurDlg RESOURCE "BARCODEPROPERTY" TITLE GL("Barcode Properties")

   nDefClr := oCurDlg:nClrPane

   REDEFINE COMBOBOX oVar:cBarcode ITEMS oVar:aBarcode ID 201 OF oCurDlg

   REDEFINE GET aGet[4] VAR oItem:cText ID 203 OF oCurDlg WHEN oItem:nEdit <> 0 MEMO

   REDEFINE BTNBMP aBtn[2] ID 153 OF oCurDlg RESOURCE "SELECT" TRANSPARENT NOBORDER ;
      TOOLTIP GL("Databases and Expressions") WHEN oItem:nEdit <> 0 ;
      ACTION GetDBField( aGet[4] )

   REDEFINE GET aGet[5] VAR oItem:nItemID ID 202 OF oCurDlg PICTURE "99999" SPINNER ;
      ON UP   ( oItem:nItemID := oItem:nItemID + 1, aGet[5]:Refresh(), IIF( oItem:nItemID < 0, aBtn[1]:Show(), aBtn[1]:Hide() ) ) ;
      ON DOWN ( oItem:nItemID := oItem:nItemID - 1, aGet[5]:Refresh(), IIF( oItem:nItemID < 0, aBtn[1]:Show(), aBtn[1]:Hide() ) ) ;
      VALID ( IIF( oItem:nItemID < 0, aBtn[1]:Show(), aBtn[1]:Hide() ), .T. )

   REDEFINE SAY aSay[4] ID 121 OF oCurDlg

   REDEFINE GET oItem:nTop      ID 301 OF oCurDlg PICTURE oVar:cPicture ;
      SPINNER MIN 0 MAX oVar:nGesHeight - oItem:nHeight ;
      VALID oItem:nTop >= 0 .AND. oItem:nTop + oItem:nHeight <= oVar:nGesHeight
   REDEFINE GET oItem:nLeft     ID 302 OF oCurDlg PICTURE oVar:cPicture ;
      SPINNER MIN 0 MAX oVar:nGesWidth - oItem:nWidth ;
      VALID oItem:nLeft >= 0 .AND. oItem:nLeft + oItem:nWidth <= oVar:nGesWidth
   REDEFINE GET oItem:nWidth    ID 303 OF oCurDlg PICTURE oVar:cPicture ;
      SPINNER MIN 0.01 MAX oVar:nGesWidth - oItem:nLeft ;
      VALID oItem:nWidth > 0 .AND. oItem:nLeft + oItem:nWidth <= oVar:nGesWidth
   REDEFINE GET oItem:nHeight   ID 304 OF oCurDlg PICTURE oVar:cPicture ;
      SPINNER MIN 0.01 MAX oVar:nGesHeight - oItem:nTop ;
      VALID oItem:nHeight > 0 .AND. oItem:nTop + oItem:nHeight <= oVar:nGesHeight
   REDEFINE GET aGet[6] VAR oItem:nPinWidth ID 307 OF oCurDlg PICTURE oVar:cPinPicture ;
      VALID oItem:nPinWidth > 0 ;
      SPINNER ;
      ON UP   ( oItem:nPinWidth += 0.1, aGet[6]:Refresh() ) ;
      ON DOWN ( IIF( oItem:nPinWidth - 0.1 < 0.01,, oItem:nPinWidth -= 0.1 ), aGet[6]:Refresh() )

   REDEFINE COMBOBOX oVar:cOrient ITEMS oVar:aOrient BITMAPS oVar:aBitmaps ID 305 OF oCurDlg

   REDEFINE CHECKBOX aCbx[1] VAR oItem:lVisible ID 306 OF oCurDlg WHEN oItem:nDelete <> 0

   REDEFINE GET aGet[1] VAR oItem:nColText ID 501 OF oCurDlg PICTURE "9999" SPINNER MIN 1 MAX 30 ;
      ON CHANGE Set2Color( aSay[1], IIF( oItem:nColText > 0, oVar:aColors[oItem:nColText], ""), nDefClr ) ;
      VALID     Set2Color( aSay[1], IIF( oItem:nColText > 0, oVar:aColors[oItem:nColText], ""), nDefClr )
   REDEFINE GET aGet[2] VAR oItem:nColPane ID 502 OF oCurDlg PICTURE "9999" SPINNER MIN 1 MAX 30 ;
      ON CHANGE Set2Color( aSay[2], IIF( oItem:nColPane > 0, oVar:aColors[oItem:nColPane], ""), nDefClr ) ;
      VALID     Set2Color( aSay[2], IIF( oItem:nColPane > 0, oVar:aColors[oItem:nColPane], ""), nDefClr ) ;
      WHEN oItem:lTrans = .F.

   REDEFINE SAY aSay[1] PROMPT "" ID 401 OF oCurDlg COLORS GetColor( oItem:nColText ), GetColor( oItem:nColText )
   REDEFINE SAY aSay[2] PROMPT "" ID 402 OF oCurDlg COLORS GetColor( oItem:nColPane ), GetColor( oItem:nColPane )

   REDEFINE BUTTON ID 151 OF oCurDlg ;
      ACTION ( nColor := ShowColorChoice( oItem:nColText ), ;
               IIF( nColor <> 0, EVAL( {|| oItem:nColText := nColor, aGet[1]:Refresh(), ;
               Set2Color( aSay[1], IIF( oItem:nColText > 0, oVar:aColors[oItem:nColText], ""), nDefClr ) } ), ) )
   REDEFINE BUTTON ID 152 OF oCurDlg ;
      ACTION ( nColor := ShowColorChoice( oItem:nColPane ), ;
               IIF( nColor <> 0, EVAL( {|| oItem:nColPane := nColor, aGet[2]:Refresh(), ;
               Set2Color( aSay[2], IIF( oItem:nColPane > 0, oVar:aColors[oItem:nColPane], ""), nDefClr ) } ), ) )

   REDEFINE CHECKBOX aCbx[2] VAR oItem:lTrans  ID 601 OF oCurDlg

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oCurDlg ;
      ACTION ( oGenVar:lDlgSave := .T., oGenVar:lItemDlg := .F., oCurDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oCurDlg ;
      ACTION ( oGenVar:lItemDlg := .F., oCurDlg:End() )
   REDEFINE BUTTON aBtn[1] PROMPT GL("&Remove Item") ID 103 OF oCurDlg ;
      ACTION ( oVar:lRemoveItem := .T., oItem:lVisible := .F., ;
               oGenVar:lDlgSave := .T., oGenVar:lItemDlg := .F., oCurDlg:End() )

   aBtn[3] := SetFormulaBtn( 9, oItem )
   SetFormulaBtn( 10, oItem )
   SetFormulaBtn( 11, oItem )
   SetFormulaBtn( 12, oItem )
   SetFormulaBtn( 13, oItem )
   SetFormulaBtn( 14, oItem )
   SetFormulaBtn( 15, oItem )
   SetFormulaBtn( 17, oItem )
   SetFormulaBtn( 18, oItem )
   SetFormulaBtn( 21, oItem )
   SetFormulaBtn( 22, oItem )

   REDEFINE BTNBMP ID 111 OF oCurDlg NOBORDER RESOURCE "B_SAVE3" TRANSPARENT ;
      TOOLTIP GL("Set these properties to default") ;
      ACTION SetItemDefault( oItem )

   REDEFINE BUTTON PROMPT GL("&Set") ID 104 OF oCurDlg ACTION SaveBarItem( oVar, oItem )

   REDEFINE GROUP aGrp[1] ID 190 OF oCurDlg
   REDEFINE GROUP aGrp[2] ID 191 OF oCurDlg
   REDEFINE GROUP aGrp[3] ID 192 OF oCurDlg

   REDEFINE SAY PROMPT GL("Top:")              ID 170 OF oCurDlg
   REDEFINE SAY PROMPT GL("Left:")             ID 171 OF oCurDlg
   REDEFINE SAY PROMPT GL("Width:")            ID 172 OF oCurDlg
   REDEFINE SAY PROMPT GL("Height:")           ID 173 OF oCurDlg
   REDEFINE SAY PROMPT GL("Type:")             ID 174 OF oCurDlg
   REDEFINE SAY PROMPT GL("Value:")            ID 175 OF oCurDlg
   REDEFINE SAY PROMPT GL("Text color:")       ID 176 OF oCurDlg
   REDEFINE SAY PROMPT GL("Background color:") ID 177 OF oCurDlg
   REDEFINE SAY PROMPT GL("Alignment:")        ID 178 OF oCurDlg
   REDEFINE SAY PROMPT GL("Pin width:")        ID 179 OF oCurDlg

   REDEFINE SAY PROMPT cMeasure ID 181 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 182 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 183 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 184 OF oCurDlg
   REDEFINE SAY PROMPT cMeasure ID 185 OF oCurDlg

   ACTIVATE DIALOG oCurDlg CENTERED ; // NOMODAL ;
      ON INIT ( GetItemDlgPos(), ;
                IIF( nDeveloper = 0, ( aGet[5]:Hide(), aSay[4]:Hide() ), ), ;
                IIF( oVar:cShowExpr = "0" .OR. lProfi = .F., aBtn[2]:Hide(), ), ;
                IIF( lFromList = .T. .OR. oItem:nItemID > 0, aBtn[1]:Hide(), ), ;
                IIF( lFromList = .T., aCbx[1]:Hide(), ), ;
                aGrp[1]:SetText( GL("Barcode") ), ;
                aGrp[2]:SetText( GL("Position / Size") ), ;
                aGrp[3]:SetText( GL("Colors") ), ;
                aCbx[1]:SetText( GL("Visible") ), ;
                aCbx[2]:SetText( GL("Transparent") ) ) ;
      VALID ( IIF( oGenVar:lDlgSave, SaveBarItem( oVar, oItem ), oGenVar:lItemDlg := .F. ), ;
              oGenVar:lDlgSave := .F., SetItemDlg() )

   oCurDlg:bMoved := {|| SetItemDlg() }

return ( .T. )

//----------------------------------------------------------------------------//

function SaveBarItem( oVar, oItem )

   local lRight, lCenter, nColor, oIni

   oItem:nBCodeType := ASCAN( oVar:aBarcode, oVar:cBarcode )
   oItem:nOrient    := ASCAN( oVar:aOrient, oVar:cOrient )

   oVar:cItemDef := oItem:Set( .F., oER:nMeasure )

   INI oIni FILE oVar:cAreaIni
      SET SECTION "Items" ENTRY AllTrim(STR(oVar:i,5)) TO oVar:cItemDef OF oIni
   ENDINI

   IIF( oItem:nOrient = 2, lCenter := .T., lCenter := .F. )
   IIF( oItem:nOrient = 3, lRight  := .T., lRight  := .F. )

   if oItem:nShow = 1

      aItems[oVar:nArea,oVar:i]:End()

         aItems[oVar:nArea,oVar:i] := TBitmap():New( nRulerTop + ER_GetPixel( oItem:nTop ), ;
             nRuler + ER_GetPixel( oItem:nLeft ), ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ), ;
             "GRAPHIC",, .T., aWnd[oVar:nArea],,, .F., .T.,,, .T.,, .T. )
         aItems[oVar:nArea,oVar:i]:lTransparent := .T.

         aItems[oVar:nArea,oVar:i]:bPainted = {| hDC, cPS | ;
            DrawBarcode( hDC, AllTrim( oItem:cText ), 0, 0, ;
                         ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ), ;
                         oItem:nBCodeType, GetColor( oItem:nColText ), GetColor( oItem:nColPane ), ;
                         oItem:nOrient, oItem:lTrans, ER_GetPixel( oItem:nPinWidth ) ) }

      aItems[oVar:nArea,oVar:i]:lDrag := .T.
      ElementActions( aItems[oVar:nArea,oVar:i], oVar:i, "", oVar:nArea, oVar:cAreaIni )
      aItems[oVar:nArea,oVar:i]:SetFocus()

   endif

   SaveItemGeneral( oVar, oItem )

return .T.

//----------------------------------------------------------------------------//

function SetItemSize( i, nArea, cAreaIni )

   local oIni, nColor, nColFill, nStyle, nPenWidth, nRndWidth, nRndHeight, oItem
   local cItemDef   := AllTrim( GetPvProfString( "Items", AllTrim(STR(i,5)) , "", cAreaIni ) )
   local cOldDef    := cItemDef
   local aWerte     := GetCoors( aItems[nArea,i]:hWnd )
   local nTop       := GetCmInch( aWerte[1] - nRulerTop )
   local nLeft      := GetCmInch( aWerte[2] - nRuler )
   local nHeight    := GetCmInch( aWerte[3] - aWerte[1] )
   local nWidth     := GetCmInch( aWerte[4] - aWerte[2] )
   local nGesWidth  := VAL( GetPvProfString( "General", "Width", "600", cAreaIni ) )
   local nGesHeight := VAL( GetPvProfString( "General", "Height", "300", cAreaIni ) )
   local cTyp       := UPPER(AllTrim( GetField( cItemDef, 1 ) ))
   LOCAL nDecimals := IIF( oER:nMeasure == 2, 2, 0 )

   if nTop + nHeight <= nGesHeight .AND. nLeft + nWidth <= nGesWidth .AND. ;
         nTop >= 0 .AND. nLeft >= 0

      nTop    := GetDivisible( ROUND( nTop   , nDecimals ), GetCmInch( nYMove ) )
      nLeft   := GetDivisible( ROUND( nLeft  , nDecimals ), GetCmInch( nXMove ) )
      nWidth  := GetDivisible( ROUND( nWidth , nDecimals ), GetCmInch( nXMove ) )
      nHeight := GetDivisible( ROUND( nHeight, nDecimals ), GetCmInch( nYMove ) )

      cItemDef := SUBSTR( cItemDef, 1, StrAtNum( "|", cItemDef, 6 ) ) + ;
         AllTrim(STR( nTop, 5, nDecimals )) + "|" + ;
         AllTrim(STR( nLeft, 5, nDecimals )) + "|" + ;
         AllTrim(STR( nWidth, 5, nDecimals )) + "|" + ;
         AllTrim(STR( nHeight, 5, nDecimals )) + ;
         SUBSTR( cItemDef, StrAtNum( "|", cItemDef, 10 ) )

      if IsGraphic( cTyp ) = .T.

         nColor     := VAL( GetField( cItemDef, 11 ) )
         nColFill   := VAL( GetField( cItemDef, 12 ) )
         nStyle     := VAL( GetField( cItemDef, 13 ) )
         nPenWidth  := VAL( GetField( cItemDef, 14 ) )
         nRndWidth  := VAL( GetField( cItemDef, 15 ) )
         nRndHeight := VAL( GetField( cItemDef, 16 ) )

         aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawGraphic( hDC, cTyp, ;
            ER_GetPixel( nWidth ), ER_GetPixel( nHeight ), ;
            GetColor( nColor ), GetColor( nColFill ), ;
            nStyle, nPenWidth, ER_GetPixel( nRndWidth ), ER_GetPixel( nRndHeight ) ) }

      ELSEif UPPER( cTyp ) = "BARCODE"

         oItem := VRDItem():New( cItemDef )

         aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawBarcode( hDC, oItem:cText, 0, 0, ;
            ER_GetPixel( nWidth ), ER_GetPixel( nHeight ), ;
            oItem:nBCodeType, ;
            GetColor( oItem:nColText ), GetColor( oItem:nColPane ), ;
            oItem:nOrient, IIF( oItem:nTrans = 1, .T., .F. ), ;
            ER_GetPixel( oItem:nPinWidth ) ) }

      endif

      INI oIni FILE cAreaIni
         SET SECTION "Items" ENTRY AllTrim(STR(i,5)) TO cItemDef OF oIni
      ENDINI

      if VAL( GetField( cItemDef, 7  ) ) <> VAL( GetField( cOldDef, 7  ) ) .OR. ;
         VAL( GetField( cItemDef, 8  ) ) <> VAL( GetField( cOldDef, 8  ) ) .OR. ;
         VAL( GetField( cItemDef, 9  ) ) <> VAL( GetField( cOldDef, 9  ) ) .OR. ;
         VAL( GetField( cItemDef, 10 ) ) <> VAL( GetField( cOldDef, 10 ) )

         if lFillWindow = .F.
            Add2Undo( cOldDef, i, nArea )
            SetSave( .F. )
         endif

      endif

   endif

   lFillWindow := .T.
   aItems[nArea,i]:Move( nRulerTop + ER_GetPixel( VAL( GetField( cItemDef, 7 ) ) ), ;
      nRuler + ER_GetPixel( VAL( GetField( cItemDef, 8 ) ) ), ;
      ER_GetPixel( VAL( GetField( cItemDef, 9 ) ) ), ;
      ER_GetPixel( VAL( GetField( cItemDef, 10 ) ) ), .T. )
   lFillWindow := .F.

   aItemPosition := { GetField( cItemDef, 7 ), GetField( cItemDef, 8 ), ;
                      GetField( cItemDef, 9 ), GetField( cItemDef, 10 ) }

   aItemPixelPos := { ER_GetPixel( VAL( GetField( cItemDef, 7 ) ) ), ;
                      ER_GetPixel( VAL( GetField( cItemDef, 8 ) ) ), ;
                      ER_GetPixel( VAL( GetField( cItemDef, 9 ) ) ), ;
                      ER_GetPixel( VAL( GetField( cItemDef, 10 ) ) ) }

   aItems[nArea,i]:Refresh()

return .T.

//----------------------------------------------------------------------------//

function MsgBarItem( nItem, nArea, cAreaIni, nRow, nCol, lResize )

   local nTop, nLeft
   local cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(nItem,5)) , "", cAreaIni ) )
   local cItemID  := AllTrim(  GetField( cItemDef, 3 ) )

   DEFAULT lResize := .F.

   if lResize .AND. LEN( aItemPosition ) <> 0

      oMsgInfo:SetText( GL("ID") + ": " + cItemID + "  " + ;
                        GL("Top:")    + " " + AllTrim( aItemPosition[1] ) + "  " + ;
                        GL("Left:")   + " " + AllTrim( aItemPosition[2] ) + "  " + ;
                        GL("Width:")  + " " + AllTrim( aItemPosition[3] ) + "  " + ;
                        GL("Height:") + " " + AllTrim( aItemPosition[4] ) )

   ELSE
      nInfoRow := 0; nInfoCol := 0 // nRulerTop := 0; nRuler := 0 // FiveTech

      nTop  := aItems[nArea,nItem]:nTop  + ;
                  ( nLoWord( aItems[nArea,nItem]:nPoint ) - nInfoRow ) - nRulerTop
      nLeft := aItems[nArea,nItem]:nLeft + ;
                  ( nHiWord( aItems[nArea,nItem]:nPoint ) - nInfoCol ) - nRuler

      /* FiveTech
      oMsgInfo:SetText( GL("ID") + ": " + cItemID + "  " + ;
                        GL("Top:")    + " " + AllTrim(STR( GetCmInch( nTop ), 5, IIF( oER:nMeasure = 2, 2, 0 ) )) + "  " + ;
                        GL("Left:")   + " " + AllTrim(STR( GetCmInch( nLeft), 5, IIF( oER:nMeasure = 2, 2, 0 ) )) + "  " + ;
                        GL("Width:")  + " " + AllTrim( cInfoWidth ) + "  " + ;
                        GL("Height:") + " " + AllTrim( cInfoHeight ) )
      */

   endif

return .T.

//----------------------------------------------------------------------------//

function GetGraphName( nIndex )

   local cName := ""

   do case
   case nIndex = 1  ; cName := "LineUp"
   case nIndex = 2  ; cName := "LineDown"
   case nIndex = 3  ; cName := "LineHorizontal"
   case nIndex = 4  ; cName := "LineVertical"
   case nIndex = 5  ; cName := "Rectangle"
   case nIndex = 6  ; cName := "Ellipse"
   endcase

return ( cName )

//----------------------------------------------------------------------------//

function GetGraphIndex( cTyp )

   local nIndex := 0

   do case
   case UPPER( cTyp ) == "LINEUP"          ; nIndex := 1
   case UPPER( cTyp ) == "LINEDOWN"        ; nIndex := 2
   case UPPER( cTyp ) == "LINEHORIZONTAL"  ; nIndex := 3
   case UPPER( cTyp ) == "LINEVERTICAL"    ; nIndex := 4
   case UPPER( cTyp ) == "RECTANGLE"       ; nIndex := 5
   case UPPER( cTyp ) == "ELLIPSE"         ; nIndex := 6
   endcase

return ( nIndex )

//----------------------------------------------------------------------------//

function GetImage( cOldFile )

   local cFile := GetFile( GL("Images") + "|*.BMP;*.DIB;*.JIF;*.JPG;*.PCX;*.RLE;*.TGA|" + ;
                           "Bitmap (*.bmp)| *.bmp|" + ;
                           "DIB (*.dib)| *.dib|"  + ;
                           "PCX (*.pcx)| *.pcx|"  + ;
                           "JPEG (*.jpg)| *.jpg|"  + ;
                           "TARGA (*.tga)| *.tga|"  + ;
                           "RLE (*.rle)| *.rle|"  + ;
                           "Jif (*.jif)| *.jif|"  + ;
                           GL("All Files") + "(*.*)| *.*", ;
                           GL("Open Image"), 1 )

return IIF( EMPTY( cFile ), cOldFile, cFile )

//----------------------------------------------------------------------------//

function ItemCopy( lCut )

   local i, oItemInfo
   local cAreaIni := aAreaIni[nAktArea]

   DEFAULT lCut := .F.

   if nAktItem = 0 .AND. LEN( aSelection ) = 0
      MsgStop( GL("Please select an item first."), GL("Stop!") )
      return (.F.)
   endif

   aSelectCopy  := {}
   nCopyEntryNr := 0
   nCopyAreaNr  := 0

   if LEN( aSelection ) <> 0

      //Multiselection
      aSelectCopy := aSelection
      aItemCopy   := {}

      FOR i := 1 TO LEN( aSelection )

         cItemCopy := AllTrim( GetPvProfString( "Items", ;
                      AllTrim(STR( aSelection[i,2], 5 )) , "", aAreaIni[ aSelection[i,1] ] ) )
         AADD( aItemCopy, cItemCopy )

         oItemInfo := VRDItem():New( cItemCopy )

         if lCut = .T.
            DeleteItem( aSelection[i,2], aSelection[i,1], .T. )
            if oItemInfo:nItemID < 0
               DelIniEntry( "Items", AllTrim(STR(aSelection[i,2],5)), ;
                            aAreaIni[ aSelection[i,1] ] )
            endif
         endif

      NEXT

   ELSE

      cItemCopy    := AllTrim( GetPvProfString( "Items", AllTrim(STR(nAktItem,5)), ;
                      "", cAreaIni ) )
      nCopyEntryNr := nAktItem
      nCopyAreaNr  := nAktArea

      oItemInfo := VRDItem():New( cItemCopy )

      if lCut
         DeleteItem( nAktItem, nAktArea, .T. )
         if oItemInfo:nItemID < 0
            DelIniEntry( "Items", AllTrim(STR(nAktItem,5)), aAreaIni[nAktArea] )
         endif
      endif

   endif

return ( .T. )

//----------------------------------------------------------------------------//

function ItemPaste( lCut )

   local i

   UnSelectAll()

   if LEN( aSelectCopy ) <> 0
      FOR i := 1 TO LEN( aSelectCopy )
         NewItem( "COPY", nAktArea, aSelectCopy[i,1], aSelectCopy[i,2], aItemCopy[i] )
      NEXT
   ELSE
      NewItem( "COPY", nAktArea )
   endif

return ( .T. )

//----------------------------------------------------------------------------//

function NewItem( cTyp, nArea, nTmpCopyArea, nTmpCopyEntry, cTmpItemCopy )

   local i, nFree, cItemDef, oIni, aBarcodes, oItemInfo, cDefault
   local nItemTop   := 0
   local nItemLeft  := 0
   local nPlusTop   := 0
   local nPlusLeft  := 0
   local aFirst     := { .F., 0, 0, 0, 0, 0 }
   local nElemente  := 0
   local cAreaIni   := aAreaIni[nArea]
   local nGesWidth  := VAL( GetPvProfString( "General", "Width", "600", cAreaIni ) )
   local nGesHeight := VAL( GetPvProfString( "General", "Height", "300", cAreaIni ) )
   local cTop       := IIF( oER:nMeasure = 2, "0.10", "2" )
   local cLeft      := cTop

   FOR i := 400 TO 1000
      if aItems[ nArea, i ] = NIL
         nFree := i
         EXIT
      endif
   NEXT

   if cTyp = "COPY"

      DEFAULT nTmpCopyEntry := nCopyEntryNr
      DEFAULT nTmpCopyArea  := nCopyAreaNr
      DEFAULT cTmpItemCopy  := cItemCopy

      if nTmpCopyEntry < 400
         FOR i := 1 TO 399
         if aItems[ nArea, i ] = NIL
            nFree := i
            EXIT
         endif
         NEXT
      endif

      oItemInfo := VRDItem():New( cTmpItemCopy )

      if oItemInfo:nTop + oItemInfo:nHeight >= nGesHeight
         nItemTop  := GetCmInch( 10 )
      endif
      if oItemInfo:nLeft + oItemInfo:nWidth >= nGesWidth
         nItemLeft := GetCmInch( 10 )
      endif

      if nTmpCopyArea = nArea
         nPlusTop  := IIF( oER:nMeasure = 2, 0.06, 2 )
         nPlusLeft := IIF( oER:nMeasure = 2, 0.06, 2 )
      endif

      cItemDef := SUBSTR( cTmpItemCopy, 1, StrAtNum( "|", cTmpItemCopy, 6 ) ) + ;
         AllTrim(STR( IIF( nItemTop = 0, oItemInfo:nTop, nItemTop ) + nPlusTop, 5, IIF( oER:nMeasure = 2, 2, 0 ) )) + "|" + ;
         AllTrim(STR( IIF( nItemLeft = 0, oItemInfo:nLeft, nItemLeft ) + nPlusLeft, 5, IIF( oER:nMeasure = 2, 2, 0 ) )) + ;
         SUBSTR( cTmpItemCopy, StrAtNum( "|", cTmpItemCopy, 8 ) )

   ELSEif cTyp = "TEXT"
      cItemDef := "Text||-1|1|1|1|" + cTop + "|" + cLeft + "|" + ;
                  IIF( oER:nMeasure = 2, "1.00", "30" ) + "|" + ;
                  IIF( oER:nMeasure = 2, "0.50",  "5" ) + "|" + ;
                  "1|1|2|0|0|0|"
   ELSEif cTyp = "IMAGE"
      cItemDef := "Image||-1|1|1|1|" + cTop + "|" + cLeft + "|" + ;
                  IIF( oER:nMeasure = 2, "0.60", "20" ) + "|" + ;
                  IIF( oER:nMeasure = 2, "0.60", "20" ) + "|" + ;
                  "|0"
   ELSEif cTyp = "GRAPHIC"
      cItemDef := "Rectangle|" + ;
                  GL("Rectangle") + ;
                  "|-1|1|1|1|" + cTop + "|" + cLeft + "|" + ;
                  IIF( oER:nMeasure = 2, "0.60", "20" ) + "|" + ;
                  IIF( oER:nMeasure = 2, "0.30", "10" ) + "|" + ;
                  "1|2|1|1|0|0"
   ELSEif cTyp = "BARCODE"
      cItemDef := "Barcode|" + ;
                  "12345678" + ;
                  "|-1|1|1|1|" + cTop + "|" + cLeft + "|" + ;
                  IIF( oER:nMeasure = 2, "1.70", "60" ) + "|" + ;
                  IIF( oER:nMeasure = 2, "0.30", "10" ) + "|" + ;
                  "1|1|2|1|1|0.3|"
   endif

   if cTyp <> "COPY"

      cDefault := GetPvProfString( "General", "Default" + cTyp, "", oER:cDefIni )

      if !EMPTY( cDefault )
         cItemDef := SUBSTR( cDefault, 1, StrAtNum( "|", cDefault, 2 ) ) + ;
                     SUBSTR( cItemDef, StrAtNum( "|", cItemDef, 2 ) + 1, StrAtNum( "|", cItemDef, 8 ) - StrAtNum( "|", cItemDef, 2 ) ) + ;
                     SUBSTR( cDefault, StrAtNum( "|", cDefault, 8 ) + 1 )
      endif

   endif

   INI oIni FILE cAreaIni
      SET SECTION "Items" ENTRY AllTrim(STR(nFree,5)) TO cItemDef OF oIni
   ENDINI

   ShowItem( nFree, nArea, cAreaIni, @aFirst, @nElemente )
   aItems[nArea,nFree]:lDrag := .T.

   /*
   aItemPosition := { GetField( cItemDef, 7 ), GetField( cItemDef, 8 ), ;
                      GetField( cItemDef, 9 ), GetField( cItemDef, 10 ) }
   aItemPixelPos := { ER_GetPixel( VAL( aItemPosition[1] ) ), ;
                      ER_GetPixel( VAL( aItemPosition[2] ) ), ;
                      ER_GetPixel( VAL( aItemPosition[3] ) ), ;
                      ER_GetPixel( VAL( aItemPosition[4] ) ) }
   aItems[nArea,i]:CheckDots()
   aItems[nArea,i]:Move( nRulerTop + aItemPixelPos[1], nRuler + aItemPixelPos[2],,, .T. )
   */

   nInfoRow := 0
   nInfoCol := 0
   SelectItem( i, nArea, cAreaIni )

   SetSave( .F. )

   if cTyp <> "COPY"
      ItemProperties( i, nArea,, .T. )
   ELSE
      Add2Undo( "", nFree, nArea )
   endif

return .T.

//----------------------------------------------------------------------------//

function ShowItem( i, nArea, cAreaIni, aFirst, nElemente, aIniEntries, nIndex )

   local cTyp, cName, nTop, nLeft, nWidth, nHeight, nFont, oFont, hDC, nTrans, lTrans
   local nColText, nColPane, nOrient, cFile, nBorder, nColor, nColFill, nStyle, nPenWidth
   local nRndWidth, nRndHeight, nBarcode, nPinWidth, cItemDef
   local lRight  := .F.
   local lCenter := .F.

   if aIniEntries = NIL
      cItemDef := AllTrim( GetPvProfString( "Items", AllTrim(STR(i,5)) , "", cAreaIni ) )
   ELSE
      cItemDef := GetIniEntry( aIniEntries,, "",, nIndex )
   endif

   if .NOT. EMPTY( cItemDef ) .AND. VAL( GetField( cItemDef, 4 ) ) <> 0

      cTyp      := UPPER(AllTrim( GetField( cItemDef, 1 ) ))
      cName     := GetField( cItemDef, 2 )
      nTop      := nRulerTop + ER_GetPixel( VAL( GetField( cItemDef, 7 ) ) )
      nLeft     := nRuler    + ER_GetPixel( VAL( GetField( cItemDef, 8 ) ) )
      nWidth    := ER_GetPixel( VAL( GetField( cItemDef, 9 ) ) )
      nHeight   := ER_GetPixel( VAL( GetField( cItemDef, 10 ) ) )

      if aFirst[1] = .F.
         aFirst[2] := nTop
         aFirst[3] := nLeft
         aFirst[4] := nWidth
         aFirst[5] := nHeight
         aFirst[6] := i
         aFirst[1] := .T.
      endif

      if cTyp = "TEXT"

         nFont    := VAL( GetField( cItemDef, 11 ) )
         nColText := VAL( GetField( cItemDef, 12 ) )
         nColPane := VAL( GetField( cItemDef, 13 ) )
         nOrient  := VAL( GetField( cItemDef, 14 ) )
         nBorder  := VAL( GetField( cItemDef, 15 ) )
         nTrans   := VAL( GetField( cItemDef, 16 ) )

         oFont:= IIF( nFont = 0, oEr:oAppFont, aFonts[nFont] )
         lCenter := IIF( nOrient = 2, .T. , .F. )
         lRight := IIF( nOrient = 3, .T. , .F. )

         SetBKMode( oEr:oMainWnd:hDC, 1 )

         /*
         aItems[nArea,i] := TSSay():New( nTop, nLeft, ;
            {|| cName }, aWnd[nArea],, oFont,,, ;
            lCenter, lRight,, .T., .T., nColText, nColPane,, ;
            nWidth, nHeight, .F., .T., .F., .F., .F., IIF( nTrans = 1, .T., .F. ) )
         */

         aItems[nArea,i] := TSay():New( nTop, nLeft, ;
            {|| cName }, aWnd[nArea], , oFont, ;
            lCenter, lRight, ( nBorder = 1 .OR. oGenVar:lShowBorder ), .T., ;
            GetColor( nColText ), GetColor( nColPane ), nWidth, nHeight, .F., .T., .F., .F., .F. )

         SetBKMode( oEr:oMainWnd:hDC, 0 )

         /*
         [ <oSay> := ] TSay():New( <nRow>, <nCol>, <{cText}>,;
            [<oWnd>], [<cPict>], <oFont>, <.lCenter.>, <.lRight.>, <.lBorder.>,;
            <.lPixel.>, <nClrText>, <nClrBack>, <nWidth>, <nHeight>,;
            <.design.>, <.update.>, <.lShaded.>, <.lBox.>, <.lRaised.> )
         */

      ELSEif cTyp = "IMAGE"

         cFile   := AllTrim( GetField( cItemDef, 11 ) )
         nBorder := VAL( GetField( cItemDef, 12 ) )

         aItems[nArea,i] := TImage():New( nTop, nLeft, nWidth, nHeight,,, ;
            IIF( nBorder = 1, .F., .T.), aWnd[nArea],,, .F., .T.,,, .T.,, .T. )
         aItems[nArea,i]:Progress(.F.)
         aItems[nArea,i]:LoadBmp( VRD_LF2SF( cFile ) )

         /*
         [ <oBmp> := ] TImage():New( <nRow>, <nCol>, <nWidth>, <nHeight>,;
            <cResName>, <cBmpFile>, <.NoBorder.>, <oWnd>,;
            [\{ |nRow,nCol,nKeyFlags| <uLClick> \} ],;
            [\{ |nRow,nCol,nKeyFlags| <uRClick> \} ], <.scroll.>,;
            <.adjust.>, <oCursor>, <cMsg>, <.update.>,;
            <{uWhen}>, <.pixel.>, <{uValid}>, <.lDesign.> )
         */

      ELSEif IsGraphic( cTyp ) = .T.

         nColor     := VAL( GetField( cItemDef, 11 ) )
         nColFill   := VAL( GetField( cItemDef, 12 ) )
         nStyle     := VAL( GetField( cItemDef, 13 ) )
         nPenWidth  := VAL( GetField( cItemDef, 14 ) )
         nRndWidth  := ER_GetPixel( VAL( GetField( cItemDef, 15 ) ) )
         nRndHeight := ER_GetPixel( VAL( GetField( cItemDef, 16 ) ) )

         aItems[nArea,i] := TBitmap():New( nTop, nLeft, nWidth, nHeight, "GRAPHIC",, ;
             .T., aWnd[nArea],,, .F., .T.,,, .T.,, .T. )
         aItems[nArea,i]:lTransparent := .T.

         aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawGraphic( hDC, cTyp, nWidth, nHeight, GetColor( nColor ), GetColor( nColFill ), ;
                         nStyle, nPenWidth, nRndWidth, nRndHeight ) }

      ELSEif cTyp = "BARCODE" .AND. lProfi = .T.

         nBarcode    := VAL( GetField( cItemDef, 11 ) )
         nColText    := VAL( GetField( cItemDef, 12 ) )
         nColPane    := VAL( GetField( cItemDef, 13 ) )
         nOrient     := VAL( GetField( cItemDef, 14 ) )
         lTrans      := IIF( VAL( GetField( cItemDef, 15 ) ) = 1, .T., .F. )
         nPinWidth   := ER_GetPixel( VAL( GetField( cItemDef, 16 ) ) )

         aItems[nArea,i] := TBitmap():New( nTop, nLeft, nWidth, nHeight, "GRAPHIC",, ;
             .T., aWnd[nArea],,, .F., .T.,,, .T.,, .T. )
         aItems[nArea,i]:lTransparent := .T.

         aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawBarcode( hDC, cName, 0, 0, nWidth, nHeight, nBarCode, GetColor( nColText ), ;
                         GetColor( nColPane ), nOrient, lTrans, nPinWidth ) }

      endif

      if cTyp = "BARCODE" .AND. lProfi = .F.
         //Dummy
      ELSE
         aItems[nArea,i]:lDrag := .T.
         ElementActions( aItems[nArea,i], i, cName, nArea, cAreaIni, cTyp )
      endif

      ++nElemente

   endif

return .T.

//----------------------------------------------------------------------------//

function DeactivateItem()

   if nAktItem <> 0
      aItems[nSelArea,nAktItem]:HideDots()
      naktItem := 0
   endif

return .T.

//----------------------------------------------------------------------------//

function DrawGraphic( hDC, cType, nWidth, nHeight, nColor, nColFill, nStyle, nPenWidth, nRndWidth, nRndHeight )

   local nPlus      := IIF( nPenWidth < 1, 0, nPenWidth - 1 )
   local nBottom    := nHeight - nPlus
   local nRight     := nWidth  - nPlus
   local hPen       := CreatePen( nStyle - 1, nPenWidth, nColor )
   local hOldPen    := SelectObject( hDC, hPen )
   local hBrush     := CreateSolidBrush( nColFill )
   local hOldBrush  := SelectObject( hDC, hBrush )

   do case
   case cType == "LINEUP"
      MoveTo( hDC, nPlus, nBottom )
      LineTo( hDC, nRight, nPlus )
   case cType == "LINEDOWN"
      MoveTo( hDC, nPlus, nPlus )
      LineTo( hDC, nRight, nBottom )
   case cType == "LINEHORIZONTAL"
      MoveTo( hDC, nPlus , IIF( nPenWidth > 1, nBottom/2, 0 ) )
      LineTo( hDC, nRight, IIF( nPenWidth > 1, nBottom/2, 0 ) )
   case cType == "LINEVERTICAL"
      MoveTo( hDC, IIF( nPenWidth > 1, nRight/2, 0 ), nPlus )
      LineTo( hDC, IIF( nPenWidth > 1, nRight/2, 0 ), nBottom )
   case cType == "RECTANGLE"
      RoundRect( hDC, nPlus, nPlus, nRight, nBottom, nRndWidth*2, nRndHeight*2 )
   case cType == "ELLIPSE"
      Ellipse( hDC, nPlus, nPlus, nRight, nBottom )
   endcase

   SelectObject( hDC, hOldPen )
   DeleteObject( hPen )
   SelectObject( hDC, hOldBrush )
   DeleteObject( hBrush )

return .T.

//----------------------------------------------------------------------------//

function DrawBarcode( hDC, cText, nTop, nLeft, nWidth, nHeight, nBCodeType, ;
                      nColText, nColPane, nOrient, lTransparent, nPinWidth )

   local oBC
   local lHorizontal := IIF( nOrient = 1, .T., .F. )

   //Bei Ausdrucken wird ein Dummy-Wert gezeigt
   if AllTrim(SUBSTR( cText, 1, 1 )) = "["
      cText := "12345678"
   endif

   oBC := VRDBarcode():New( hDC, cText, nTop, nLeft, nWidth, nHeight, nBCodeType, ;
                            nColText, nColPane, lHorizontal, lTransparent, nPinWidth )
   oBC:ShowBarcode()

return .T.

//----------------------------------------------------------------------------//

function IsGraphic( cTyp )

   local lreturn := .F.

   if cTyp == "LINEUP" .OR. ;
      cTyp == "LINEDOWN" .OR. ;
      cTyp == "LINEHORIZONTAL" .OR. ;
      cTyp == "LINEVERTICAL" .OR. ;
      cTyp == "RECTANGLE" .OR. ;
      cTyp == "ELLIPSE"
      lreturn := .T.
   endif

return ( lreturn )

//----------------------------------------------------------------------------//