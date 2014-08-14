
#INCLUDE "Folder.ch"
#INCLUDE "FiveWin.ch"
#INCLUDE "Treeview.ch"

MEMVAR aItems, aFonts, oAppFont, aAreaIni, aWnd, aWndTitle, oBar, oMru
MEMVAR oCbxArea, aCbxItems, nAktuellItem, aRuler, cLongDefIni, cDefaultPath
MEMVAR nAktItem, nAktArea, nSelArea, cAktIni, aSelection, nTotalHeight, nTotalWidth
MEMVAR nHinCol1, nHinCol2, nHinCol3, oMsgInfo
MEMVAR aVRDSave, lVRDSave, lFillWindow, nDeveloper, oRulerBmp1, oRulerBmp2
MEMVAR lBoxDraw, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight, nRuler, nRulerTop
MEMVAR cItemCopy, nCopyEntryNr, nCopyAreaNr, aSelectCopy, aItemCopy, nXMove, nYMove
MEMVAR cInfoWidth, cInfoHeight, nInfoRow, nInfoCol, aItemPosition, aItemPixelPos
MEMVAR oClpGeneral, cDefIni, cGeneralIni, nMeasure, cMeasure, lDemo, lBeta, oTimer
MEMVAR oMainWnd, lProfi, nUndoCount, nRedoCount, oCurDlg, oGenVar

*-- FUNCTION -----------------------------------------------------------------
* Name........: ElementActions
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ElementActions( oItems, i, cName, nArea, cAreaIni, cTyp )

   oItems:bLDblClick := {|| IIF( GetKeyState( VK_SHIFT ), MultiItemProperties(), ;
                                 ( ItemProperties( i, nArea ), oCurDlg:SetFocus() ) ) }

   //oItems:bGotFocus  := {|| SelectItem( i, nArea, cAreaIni ), MsgBarInfos( i, cAreaIni ) }
   oItems:bLClicked  := {| nRow, nCol, nFlags | ;
      IIF( oGenVar:lItemDlg, ( IIF( GetKeyState( VK_SHIFT ), MultiItemProperties(), ;
                               ( ItemProperties( i, nArea ), oCurDlg:SetFocus() ) ) ), ;
                             ( SelectItem( i, nArea, cAreaIni ), ;
                               nInfoRow := nRow, nInfoCol := nCol, ;
                               MsgBarItem( i, nArea, cAreaIni, nRow, nCol ) ) ) }
      //AEVAL( oItems:aDots, {|x| x:Show(), BringWindowToTop( x:hWnd ), x:Refresh() } ) }

   //oItems:bMoved     := {|| IIF( GetKeyState( VK_SHIFT ), .T., SetItemSize( i, nArea, cAreaIni ) ), ;
   //                         MsgBarItem( i, nArea, cAreaIni,,, .T. ) }

   //oItems:bResized   := {|| IIF( GetKeyState( VK_SHIFT ), .T., SetItemSize( i, nArea, cAreaIni ) ), ;
   //                         MsgBarItem( i, nArea, cAreaIni,,, .T. ) }

   oItems:bMoved     := {|| SetItemSize( i, nArea, cAreaIni ), MsgBarItem( i, nArea, cAreaIni,,, .T. ) }

   oItems:bResized   := {|| SetItemSize( i, nArea, cAreaIni ), MsgBarItem( i, nArea, cAreaIni,,, .T. ) }

   oItems:bMMoved    := {| nRow, nCol, nFlags | MsgBarItem( i, nArea, cAreaIni, nRow, nCol ) }

   oItems:bRClicked  := {| nRow, nCol, nFlags | oItems:SetFocus(), ;
                                                ItemPopupMenu( oItems, i, nArea, nRow, nCol ) }

   oItems:nDlgCode = DLGC_WANTALLKEYS
   oItems:bKeyDown   := {| nKey | KeyDownAction( nKey, i, nArea, cAreaIni ) }

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: KeyDownAction
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION KeyDownAction( nKey, nItem, nArea, cAreaIni )

   LOCAL aWerte   := GetCoors( aItems[nArea,nItem]:hWnd )
   LOCAL nTop     := aWerte[1]
   LOCAL nLeft    := aWerte[2]
   LOCAL nHeight  := aWerte[3] - aWerte[1]
   LOCAL nWidth   := aWerte[4] - aWerte[2]
   LOCAL lMove    := .T.
   LOCAL nY       := 0
   LOCAL nX       := 0
   LOCAL nRight   := 0
   LOCAL nBottom  := 0

   IF LEN( aSelection ) <> 0
      WndKeyDownAction( nKey, nArea, cAreaIni )
      RETURN (.T.)
   ENDIF

   //Delete item
   IF nKey == VK_DELETE
      DelItemWithKey( nItem, nArea )
   ENDIF

   //Return to edit properties
   IF nKey == VK_RETURN
      ItemProperties( nItem, nArea )
   ENDIF

   //Move and resize items
   IF GetKeyState( VK_SHIFT )
      DO CASE
      CASE nKey == VK_LEFT
         nRight := -1 * nXMove
      CASE nKey == VK_RIGHT
         nRight := 1 * nXMove
      CASE nKey == VK_UP
         nBottom := -1 * nYMove
      CASE nKey == VK_DOWN
         nBottom := 1 * nYMove
      OTHERWISE
         lMove := .F.
      ENDCASE
   ELSE
      DO CASE
      CASE nKey == VK_LEFT
         nX := -1 * nXMove
      CASE nKey == VK_RIGHT
         nX :=  1 * nXMove
      CASE nKey == VK_UP
         nY := -1 * nYMove
      CASE nKey == VK_DOWN
         nY :=  1 * nYMove
      OTHERWISE
         lMove := .F.
      ENDCASE
   ENDIF

   IF lMove = .T.
      aItems[nArea,nItem]:Move( nTop + nY, nLeft + nX, nWidth + nRight, nHeight + nBottom, .T. )
      aItems[nArea,nItem]:ShowDots( .T. )
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: DeleteItem
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DeleteItem( i, nArea, lFromList, lRemove, lFromUndoRedo )

   LOCAL cItemDef, cOldDef, oIni, cWert
   LOCAL aFirst    := { .F., 0, 0, 0, 0, 0 }
   LOCAL nElemente := 0
   LOCAL cAreaIni  := aAreaIni[nArea]

   DEFAULT lFromList := .F.
   DEFAULT lRemove   := .T.
   DEFAULT lFromUndoredo := .F.

   IF i = NIL
      MsgStop( GL("Please select an item first."), GL("Stop!") )
      RETURN (.F.)
   ENDIF

   IF lFromList = .F.
      IF MsgYesNo( GL("Remove the current item?"), GL("Select an option") ) = .F.
         RETURN (.F.)
      ENDIF
   ENDIF

   cItemDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(i,5)) , "", cAreaIni ) )
   cOldDef  := cItemDef

   IF lRemove = .T.
      cWert := " 0"
   ELSE
      cWert := " 1"
   ENDIF

   cItemDef := SUBSTR( cItemDef, 1, StrAtNum( "|", cItemDef, 3 ) ) + " " + ;
               cWert + ;
               SUBSTR( cItemDef, StrAtNum( "|", cItemDef, 4 ) )

   INI oIni FILE cAreaIni
      SET SECTION "Items" ENTRY ALLTRIM(STR(i,5)) TO cItemDef OF oIni
   ENDINI

   IF lRemove = .T.
      aItems[nArea,i]:lDrag := .F.
      aItems[nArea,i]:HideDots()
      aItems[nArea,i]:End()
   ELSE
      ShowItem( i, nArea, cAreaIni, @aFirst, @nElemente )
      aItems[nArea,i]:lDrag := .T.
   ENDIF

   IF lFromUndoRedo = .F.
      Add2Undo( cOldDef, i, nArea )
   ENDIF

   SetSave( .F. )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: DeleteAllItems
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DeleteAllItems( nTyp )

   LOCAL i, cTyp, cDef, oItem
   LOCAL nLen := LEN( aItems[nAktArea] )

   IF MsgYesNo( GL("Remove items?"), GL("Select an option") ) = .F.
      RETURN (.F.)
   ENDIF

   FOR i := 1 TO nLen

      cDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(i,5)) , "", aAreaIni[nAktArea] ) )

      IF .NOT. EMPTY( cDef )

         oItem := VRDItem():New( cDef )

         cTyp := UPPER(ALLTRIM( GetField( cDef, 1 ) ))

         IF nTyp = 1 .AND. oItem:cType = "TEXT"           .OR. ;
            nTyp = 2 .AND. oItem:cType = "IMAGE"          .OR. ;
            nTyp = 3 .AND. IsGraphic( oItem:cType ) = .T. .OR. ;
            nTyp = 4 .AND. oItem:cType = "BARCODE"

            IF oItem:lVisible = .T.
               DeleteItem( i, nAktArea, .T., .T. )
            ENDIF

         ENDIF

      ENDIF

   NEXT

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: DelItemWithKey
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DelItemWithKey( nItem, nArea )

   LOCAL cItemDef  := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR( nItem,5)), "", aAreaIni[nArea] ) )
   LOCAL oItemInfo := VRDItem():New( cItemDef )

   DeleteItem( nItem, nArea, .T. )

   IF oItemInfo:nItemID < 0
      DelIniEntry( "Items", ALLTRIM(STR(nItem,5)), aAreaIni[nArea] )
   ENDIF

   nAktItem := 0

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: ItemPopupMenu
* Beschreibung:
*    Argumente: None
* Rückgabewert: .T.                   Autor: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ItemPopupMenu( oItem, nItem, nArea, nRow, nCol )

   LOCAL oMenu
   LOCAL cItemDef  := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(nItem,5)), "", aAreaIni[nArea] ) )
   LOCAL oItemInfo := VRDItem():New( cItemDef )

   MENU oMenu POPUP

   MENUITEM GL("&Item Properties") RESOURCE "PROPERTY" ;
      ACTION ItemProperties( nItem, nArea )

   IF oItemInfo:nDelete = 1
      SEPARATOR
      MENUITEM GL("&Visible") CHECKED ACTION DeleteItem( nItem, nArea, .T. )
   ENDIF

   IF oItemInfo:nItemID < 0
      SEPARATOR
      MENUITEM GL("&Remove Item") RESOURCE "DEL" ACTION DelItemWithKey( nItem, nArea )
   ENDIF

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

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ItemProperties
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ItemProperties( i, nArea, lFromList, lNew )

   LOCAL cOldDef, cItemDef, cTyp, cName
   LOCAL cAreaIni := aAreaIni[nArea]

   DEFAULT lFromList := .F.
   DEFAULT lNew      := .F.

   IF i = NIL .OR. i = 0
      MsgStop( GL("Please select an item first."), GL("Stop!") )
      RETURN (.F.)
   ENDIF

   UnSelectAll()

   IF oCurDlg <> NIL
      oGenVar:lDlgSave := .T.
      oCurDlg:End()
      oCurDlg := NIL
   ENDIF

   cOldDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(i,5)) , "", cAreaIni ) )
   cTyp    := UPPER(ALLTRIM( GetField( cOldDef, 1 ) ))

   IF cTyp = "TEXT"
      TextProperties( i, nArea, cAreaIni, lFromList, lNew )
   ELSEIF cTyp = "IMAGE"
      ImageProperties( i, nArea, cAreaIni, lFromList, lNew )
   ELSEIF IsGraphic( cTyp ) = .T.
      GraphicProperties( i, nArea, cAreaIni, lFromList, lNew )
   ELSEIF cTyp = "BARCODE"
      BarcodeProperties( i, nArea, cAreaIni, lFromList, lNew )
   ENDIF

   cItemDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(i,5)) , "", cAreaIni ) )

   cName := ALLTRIM( GetField( cItemDef, 2 ) )

   IF UPPER( cTyp ) = "IMAGE" .AND. EMPTY( cName ) = .T.
      cName := ALLTRIM(STR(i,5)) + ". " + ALLTRIM( GetField( cItemDef, 11 ) )
   ELSE
      cName := ALLTRIM(STR(i,5)) + ". " + cName
   ENDIF

   Memory(-1)
   SysRefresh()

RETURN ( cName )


*-- FUNCTION -----------------------------------------------------------------
* Name........: MultiItemProperties
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION MultiItemProperties()

   LOCAL oDlg, aCbx[1], aGrp[1]
   LOCAL cItemDef  := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR( aSelection[1,2], 5 )), ;
                      "", aAreaIni[ aSelection[1,1] ] ) )
   LOCAL nTop      := VAL( GetField( cItemDef, 7 ) )
   LOCAL nLeft     := VAL( GetField( cItemDef, 8 ) )
   LOCAL nWidth    := VAL( GetField( cItemDef, 9 ) )
   LOCAL nHeight   := VAL( GetField( cItemDef, 10 ) )
   LOCAL aOldValue := { nTop, nLeft, nWidth, nHeight }
   LOCAL cPicture  := IIF( nMeasure = 2, "999.99", "99999" )
   LOCAL lAddValue := .F.

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
      ON INIT ( oDlg:Move( 120, oMainWnd:nRight - 240,,, .T. ), ;
                aGrp[1]:SetText( GL("Position / Size") ), ;
                aCbx[1]:SetText( GL("Add values") ) )

   //RefreshSelection()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: UpdateItems
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION UpdateItems( nValue, nTyp, lAddValue, aOldValue )

   LOCAL i, aWerte, nTop, nLeft, nWidth, nHeight
   LOCAL lStop     := .F.
   LOCAL nPixValue := GetPixel( nValue )

   DO CASE
   CASE nTyp = 1 .AND. nValue = aOldValue[1] ; lStop := .T.
   CASE nTyp = 2 .AND. nValue = aOldValue[2] ; lStop := .T.
   CASE nTyp = 3 .AND. nValue = aOldValue[3] ; lStop := .T.
   CASE nTyp = 4 .AND. nValue = aOldValue[4] ; lStop := .T.
   ENDCASE

   IF lStop = .T.
      RETURN( .T. )
   ENDIF

   UnSelectAll( .F. )

   FOR i := 1 TO LEN( aSelection )

      aWerte  := GetCoors( aItems[ aSelection[i,1], aSelection[i,2] ]:hWnd )
      nTop    := aWerte[1]
      nLeft   := aWerte[2]
      nHeight := aWerte[3] - aWerte[1]
      nWidth  := aWerte[4] - aWerte[2]

      DO CASE
      CASE nTyp = 1 ; IIF( lAddValue, nTop    += nPixValue, nTop    := nRulerTop + nPixValue )
      CASE nTyp = 2 ; IIF( lAddValue, nLeft   += nPixValue, nLeft   := nRuler    + nPixValue )
      CASE nTyp = 3 ; IIF( lAddValue, nWidth  += nPixValue, nWidth  := nPixValue )
      CASE nTyp = 4 ; IIF( lAddValue, nHeight += nPixValue, nHeight := nPixValue )
      ENDCASE

      aOldValue[nTyp] := nValue

      aItems[ aSelection[i,1], aSelection[i,2]] :Move( nTop, nLeft, nWidth, nHeight, .T. ) //, .T. )

      aItems[ aSelection[i,1], aSelection[i,2] ]:Refresh()

   NEXT

   UnSelectAll( .F. )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: TextProperties
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION TextProperties( i, nArea, cAreaIni, lFromList, lNew )

   LOCAL oIni, nColor
   LOCAL aCbx[5], aGrp[3], aGet[5], aSay[4]
   LOCAL nDefClr, oBtn, oBtn2, oBtn3
   LOCAL oVar  := GetoVar( i, nArea, cAreaIni, lNew )
   LOCAL oItem := VRDItem():New( oVar:cItemDef )

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

   REDEFINE BTNBMP oBtn2 ID 154 OF oCurDlg NOBORDER RESOURCE "SELECT" ;
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

   REDEFINE SAY aSay[1] PROMPT "" ID 401 OF oCurDlg COLORS GetColor( oItem:nColText ), GetColor( oItem:nColText )
   REDEFINE SAY aSay[2] PROMPT "" ID 402 OF oCurDlg COLORS GetColor( oItem:nColPane ), GetColor( oItem:nColPane )
   REDEFINE SAY aSay[3] PROMPT ;
      IIF( oItem:nFont > 0, " " + GetCurrentFont( oItem:nFont, GetFonts(), 1 ), "" ) ;
      ID 403 OF oCurDlg

   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 151 OF oCurDlg ;
      ACTION ( nColor := ShowColorChoice( oItem:nColText ), ;
               IIF( nColor <> 0, EVAL( {|| oItem:nColText := nColor, aGet[1]:Refresh(), ;
               Set2Color( aSay[1], IIF( oItem:nColText > 0, oVar:aColors[oItem:nColText], ""), nDefClr ) } ), ) )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 152 OF oCurDlg ;
      ACTION ( nColor := ShowColorChoice( oItem:nColPane ), ;
               IIF( nColor <> 0, EVAL( {|| oItem:nColPane := nColor, aGet[2]:Refresh(), ;
               Set2Color( aSay[2], IIF( oItem:nColPane > 0, oVar:aColors[oItem:nColPane], ""), nDefClr ) } ), ) )
   REDEFINE BTNBMP RESOURCE "SELECT" NOBORDER ID 153 OF oCurDlg ;
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

   REDEFINE BTNBMP ID 111 OF oCurDlg NOBORDER RESOURCE "B_SAVE3" ;
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

   ACTIVATE DIALOG oCurDlg CENTERED NOMODAL ;
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

RETURN ( .T. )


*-- FUNCTION -----------------------------------------------------------------
*         Name: SetItemDefault
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetItemDefault( oItem )

   WritePProString( "General", "Default" + IIF( oItem:lGraphic, "GRAPHIC", oItem:cType ), ;
                    oItem:Set( .F., nMeasure ), cDefIni )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: SetFormulaBtn
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetFormulaBtn( nID, oItem )

   LOCAL oBtn
   LOCAL cSource := ""

   DO CASE
   CASE nID =  9  ; cSource := oItem:cSource
   CASE nID = 10  ; cSource := oItem:cSTop
   CASE nID = 11  ; cSource := oItem:cSLeft
   CASE nID = 12  ; cSource := oItem:cSWidth
   CASE nID = 13  ; cSource := oItem:cSHeight
   CASE nID = 14  ; cSource := oItem:cSAlignment
   CASE nID = 15  ; cSource := oItem:cSVisible
   CASE nID = 16  ; cSource := oItem:cSMultiline
   CASE nID = 17  ; cSource := oItem:cSTextClr
   CASE nID = 18  ; cSource := oItem:cSBackClr
   CASE nID = 19  ; cSource := oItem:cSFont
   CASE nID = 20  ; cSource := oItem:cSPrBorder
   CASE nID = 21  ; cSource := oItem:cSTransparent
   CASE nID = 22  ; cSource := oItem:cSPenSize
   CASE nID = 23  ; cSource := oItem:cSPenStyle
   CASE nID = 24  ; cSource := oItem:cSVariHeight
   ENDCASE

   REDEFINE BTNBMP oBtn ID nID OF oCurDlg NOBORDER ;
      RESOURCE "B_SOURCE_" + IIF( EMPTY( cSource ), "NO", "YES" ) ;
      TOOLTIP GetSourceToolTip( cSource ) ;
      WHEN oItem:nEdit <> 0 ;
      ACTION ( cSource := EditSourceCode( nID, cSource, oItem ), ;
               oBtn:LoadBitmaps( "B_SOURCE_" + IIF( EMPTY( cSource ), "NO", "YES" ) ), ;
               oBtn:cToolTip := GetSourceToolTip( cSource ) )

RETURN ( oBtn )


*-- FUNCTION -----------------------------------------------------------------
* Name........: EditSourceCode
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION EditSourceCode( nID, cSourceCode, oItem )

   LOCAL oDlg, oGet1
   LOCAL cOldSource := cSourceCode
   LOCAL lSave      := .F.

   DEFINE DIALOG oDlg NAME "SOURCECODE" TITLE GL("Formula")

   REDEFINE GET oGet1 VAR cSourceCode ID 201 OF oDlg MEMO

   oGet1:bGotFocus:={|| oGet1:setpos(oGet1:nPos) }

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oDlg ACTION ( lSave := .T., oDlg:End() )
   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oDlg ACTION oDlg:End()

   REDEFINE BUTTON PROMPT GL("&Insert Database Field") ID 103 OF oDlg ;
      ACTION GetDBField( oGet1, .T. )

   ACTIVATE DIALOG oDlg CENTER

   IF lSave = .T. .AND. nID <> 0
      DO CASE
      CASE nID =  9  ; oItem:cSource       := cSourceCode
      CASE nID = 10  ; oItem:cSTop         := cSourceCode
      CASE nID = 11  ; oItem:cSLeft        := cSourceCode
      CASE nID = 12  ; oItem:cSWidth       := cSourceCode
      CASE nID = 13  ; oItem:cSHeight      := cSourceCode
      CASE nID = 14  ; oItem:cSAlignment   := cSourceCode
      CASE nID = 15  ; oItem:cSVisible     := cSourceCode
      CASE nID = 16  ; oItem:cSMultiline   := cSourceCode
      CASE nID = 17  ; oItem:cSTextClr     := cSourceCode
      CASE nID = 18  ; oItem:cSBackClr     := cSourceCode
      CASE nID = 19  ; oItem:cSFont        := cSourceCode
      CASE nID = 20  ; oItem:cSPrBorder    := cSourceCode
      CASE nID = 21  ; oItem:cSTransparent := cSourceCode
      CASE nID = 22  ; oItem:cSPenSize     := cSourceCode
      CASE nID = 23  ; oItem:cSPenStyle    := cSourceCode
      ENDCASE
   ENDIF

RETURN IIF( lSave, cSourceCode, cOldSource )


*-- FUNCTION -----------------------------------------------------------------
*         Name: GetItemDlgPos
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetItemDlgPos()

   IF oGenVar:nDlgTop  > 0 .AND. oGenVar:nDlgTop  <= GetSysMetrics( 1 ) - 80 .AND. ;
      oGenVar:nDlgLeft > 0 .AND. oGenVar:nDlgLeft <= GetSysMetrics( 0 ) - 80
      oCurDlg:Move( oGenVar:nDlgTop, oGenVar:nDlgLeft,,, .T. )
   ELSE
      WritePProString( "ItemDialog", "Top" , "0", cGeneralIni )
      WritePProString( "ItemDialog", "Left", "0", cGeneralIni )
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: SetItemDlg
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetItemDlg()

   LOCAL oRect := oCurDlg:GetRect()

   oGenVar:nDlgTop  := oRect:nTop
   oGenVar:nDlgLeft := oRect:nLeft

   WritePProString( "ItemDialog", "Top" , ALLTRIM(STR( oGenVar:nDlgTop , 10 )), cGeneralIni )
   WritePProString( "ItemDialog", "Left", ALLTRIM(STR( oGenVar:nDlgLeft, 10 )), cGeneralIni )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
*         Name: GetoVar
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetoVar( i, nArea, cAreaIni, lNew )

   LOCAL oVar := TExStruct():New()

   oVar:AddMember( "cItemDef"   ,, ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(i,5)) , "", cAreaIni ) ) )
   oVar:AddMember( "i"          ,, i                                                                       )
   oVar:AddMember( "nArea"      ,, nArea                                                                   )
   oVar:AddMember( "cAreaIni"   ,, cAreaIni                                                                )
   oVar:AddMember( "cOldDef"    ,, oVar:cItemDef                                                           )
   oVar:AddMember( "lNew"       ,, lNew                                                                    )
   oVar:AddMember( "lRemoveItem",, .F.                                                                     )
   oVar:AddMember( "cShowExpr"  ,, ALLTRIM( GetPvProfString( "General", "Expressions", "0", cDefIni ) )    )
   oVar:AddMember( "nGesWidth"  ,, VAL( GetPvProfString( "General", "Width", "600", cAreaIni ) )           )
   oVar:AddMember( "nGesHeight" ,, VAL( GetPvProfString( "General", "Height", "300", cAreaIni ) )          )
   oVar:AddMember( "cPicture"   ,, IIF( nMeasure = 2, "999.99", "99999" )                                  )

RETURN ( oVar )


*-- FUNCTION -----------------------------------------------------------------
*         Name: SaveTextItem
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SaveTextItem( oVar, oItem )

   LOCAL lRight, lCenter, nColor, oFont, oIni

   oItem:nOrient := ASCAN( oVar:aOrient, oVar:cOrient )
   oItem:nBorder := IIF( oItem:lBorder , 1, 0 )
   oItem:nTrans  := IIF( oItem:lTrans  , 1, 0 )
   oItem:nShow   := IIF( oItem:lVisible, 1, 0 )

   oVar:cItemDef := oItem:Set( .F., nMeasure )

   INI oIni FILE oVar:cAreaIni
      SET SECTION "Items" ENTRY ALLTRIM(STR(oVar:i,5)) TO oVar:cItemDef OF oIni
   ENDINI

   IIF( oItem:nFont = 0, oFont := oAppFont, oFont := aFonts[oItem:nFont] )
   IIF( oItem:nOrient = 2, lCenter := .T., lCenter := .F. )
   IIF( oItem:nOrient = 3, lRight  := .T., lRight  := .F. )

   IF oItem:lVisible = .T.

      aItems[oVar:nArea,oVar:i]:End()
      aItems[oVar:nArea,oVar:i] := ;
         TSay():New( nRulerTop + GetPixel( oItem:nTop ), nRuler + GetPixel( oItem:nLeft ), ;
                     {|| oItem:cText }, aWnd[oVar:nArea],, ;
                     oFont, lCenter, lRight, ( oItem:lBorder .OR. oGenVar:lShowBorder ), ;
                     .T., GetColor( oItem:nColText ), GetColor( oItem:nColPane ), ;
                     GetPixel( oItem:nWidth ), GetPixel( oItem:nHeight ), ;
                     .F., .T., .F., .F., .F. )

      aItems[oVar:nArea,oVar:i]:lDrag := .T.
      ElementActions( aItems[oVar:nArea,oVar:i], oVar:i, oItem:cText, oVar:nArea, oVar:cAreaIni )
      aItems[oVar:nArea,oVar:i]:SetFocus()

   ENDIF

   // Diese Funktion darf nicht aufgerufen werden, weil beim Sprung von einem
   // Textelement zu einem Bildelement ein Fehler generiert wird.
   // Der Funktionsinhalt muß direkt angehängt werden.
   //SaveItemGeneral( oVar, oItem )

   IF oItem:lVisible = .F. .AND. aItems[oVar:nArea,oVar:i] <> NIL
      aItems[oVar:nArea,oVar:i]:lDrag := .F.
      aItems[oVar:nArea,oVar:i]:HideDots()
      aItems[oVar:nArea,oVar:i]:End()
   ENDIF

   IF oVar:lRemoveItem = .T.
      DelIniEntry( "Items", ALLTRIM(STR(oVar:i,5)), oVar:cAreaIni )
   ENDIF

   SetSave( .F. )

   IF oVar:lNew = .T.
      Add2Undo( "", oVar:i, oVar:nArea )
   ELSEIF oVar:cOldDef <> oVar:cItemDef
      Add2Undo( oVar:cOldDef, oVar:i, oVar:nArea )
   ENDIF

   oCurDlg:SetFocus()

RETURN ( .T. )


*-- FUNCTION -----------------------------------------------------------------
*         Name: SaveItemGeneral
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SaveItemGeneral( oVar, oItem )

   // Immer auch SaveTextItem aktualisieren.
   // Der Funktionsinhalt muß dort direkt angehängt werden.

   IF oItem:lVisible = .F. .AND. aItems[oVar:nArea,oVar:i] <> NIL
      aItems[oVar:nArea,oVar:i]:lDrag := .F.
      aItems[oVar:nArea,oVar:i]:HideDots()
      aItems[oVar:nArea,oVar:i]:End()
   ENDIF

   IF oVar:lRemoveItem = .T.
      DelIniEntry( "Items", ALLTRIM(STR(oVar:i,5)), oVar:cAreaIni )
   ENDIF

   SetSave( .F. )

   IF oVar:lNew = .T.
      Add2Undo( "", oVar:i, oVar:nArea )
   ELSEIF oVar:cOldDef <> oVar:cItemDef
      Add2Undo( oVar:cOldDef, oVar:i, oVar:nArea )
   ENDIF

   oCurDlg:SetFocus()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ImageProperties
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ImageProperties( i, nArea, cAreaIni, lFromList, lNew )

   LOCAL oIni, aBtn[3], oCbx1, oCbx2, aGet[3], aSay[1], aGrp[2], aSizeSay[2]
   LOCAL oVar  := GetoVar( i, nArea, cAreaIni, lNew )
   LOCAL oItem := VRDItem():New( oVar:cItemDef )
   LOCAL aSize := GetImageSize( oItem:cFile )

   oGenVar:lItemDlg := .T.

   DEFINE DIALOG oCurDlg RESOURCE "IMAGEPROPERTY" TITLE GL("Image Properties")

   REDEFINE GET aGet[2] VAR oItem:cText ID 201 OF oCurDlg WHEN oItem:nEdit <> 0 MEMO
   REDEFINE GET aGet[1] VAR oItem:cFile ID 202 OF oCurDlg WHEN oItem:nEdit <> 0 ;
      VALID ( aSize := GetImageSize( oItem:cFile ), AEVAL( aSizeSay, {|x| x:Refresh() } ), .T. )
   REDEFINE BTNBMP ID 150 OF oCurDlg RESOURCE "B_OPEN" NOBORDER WHEN oItem:nEdit <> 0 ;
      TOOLTIP GL("Open") ACTION ( oItem:cFile := GetImage( oItem:cFile ), aGet[1]:Refresh() )

   REDEFINE BTNBMP aBtn[2] ID 152 OF oCurDlg RESOURCE "SELECT" NOBORDER ;
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

   REDEFINE BTNBMP ID 111 OF oCurDlg NOBORDER RESOURCE "B_SAVE3" ;
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

   ACTIVATE DIALOG oCurDlg CENTERED NOMODAL ;
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

RETURN ( .T. )


*-- FUNCTION -----------------------------------------------------------------
*         Name: GetImageSize
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetImageSize( cFile )

   LOCAL oImg
   LOCAL aSizes := { "--", "--" }

   IF FILE( cFile ) .OR. AT( "RES:", UPPER( cFile ) ) <> 0

      oImg := TImage():New( 0, 0, 0, 0,,,, oMainWnd )
      oImg:Progress(.F.)
      oImg:LoadImage( IIF( AT( "RES:", UPPER( cFile ) ) <> 0, ;
                           SUBSTR( ALLTRIM( cFile ), 5 ), NIL ), ;
                      VRD_LF2SF( cFile ) )
      aSizes := { ALLTRIM(STR( GetCmInch( oImg:nWidth()  ), 5, IIF( nMeasure = 2, 2, 0 ) )), ;
                  ALLTRIM(STR( GetCmInch( oImg:nHeight() ), 5, IIF( nMeasure = 2, 2, 0 ) )) }
      oImg:End()

   ENDIF

RETURN ( aSizes )


*-- FUNCTION -----------------------------------------------------------------
*         Name: SaveImgItem
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SaveImgItem( oVar, oItem )

   LOCAL oIni

   oItem:nBorder := IIF( oItem:lBorder , 1, 0 )
   oItem:nShow   := IIF( oItem:lVisible, 1, 0 )

   oVar:cItemDef := oItem:Set( .F., nMeasure )

   INI oIni FILE oVar:cAreaIni
      SET SECTION "Items" ENTRY ALLTRIM(STR(oVar:i,5)) TO oVar:cItemDef OF oIni
   ENDINI

   IF oItem:nShow = 1

      aItems[oVar:nArea,oVar:i]:End()
      aItems[oVar:nArea,oVar:i] := TImage():New( nRulerTop + GetPixel( oItem:nTop ), ;
         nRuler + GetPixel( oItem:nLeft ), GetPixel( oItem:nWidth ), GetPixel( oItem:nHeight ),,, ;
         IIF( oItem:lBorder, .F., .T. ), aWnd[oVar:nArea],,, .F., .T.,,, .T.,, .T. )
      aItems[oVar:nArea,oVar:i]:Progress(.F.)
      aItems[oVar:nArea,oVar:i]:LoadBmp( VRD_LF2SF( oItem:cFile ) )

      aItems[oVar:nArea,oVar:i]:lDrag := .T.
      ElementActions( aItems[oVar:nArea,oVar:i], oVar:i, oItem:cText, oVar:nArea, oVar:cAreaIni )
      aItems[oVar:nArea,oVar:i]:SetFocus()

   ENDIF

   SaveItemGeneral( oVar, oItem )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: GraphicProperties
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GraphicProperties( i, nArea, cAreaIni, lFromList, lNew )

   LOCAL oIni, oBtn, oCmb1, aCbx[2], nColor, nDefClr
   LOCAL aGet[4], aSay[3], aGrp[3]
   LOCAL oVar  := GetoVar( i, nArea, cAreaIni, lNew )
   LOCAL oItem := VRDItem():New( oVar:cItemDef )

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

   //Typ auswählen
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

   REDEFINE BTNBMP ID 151 OF oCurDlg NOBORDER RESOURCE "SELECT" ;
      ACTION ( nColor := ShowColorChoice( oItem:nColor ), ;
               IIF( nColor <> 0, EVAL( {|| oItem:nColor := nColor, aGet[1]:Refresh(), ;
               Set2Color( aSay[1], IIF( oItem:nColor > 0, oVar:aColors[oItem:nColor], ""), nDefClr ) } ), ) )
   REDEFINE BTNBMP ID 152 OF oCurDlg NOBORDER RESOURCE "SELECT" ;
      ACTION ( nColor := ShowColorChoice( oItem:nColFill ), ;
               IIF( nColor <> 0, EVAL( {|| oItem:nColFill := nColor, aGet[2]:Refresh(), ;
               Set2Color( aSay[2], IIF( oItem:nColFill > 0, oVar:aColors[oItem:nColFill], ""), nDefClr ) } ), ) )

   REDEFINE CHECKBOX aCbx[2] VAR oItem:lTrans ID 603 OF oCurDlg

   //Style auswählen
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

   REDEFINE BTNBMP ID 111 OF oCurDlg NOBORDER RESOURCE "B_SAVE3" ;
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

   ACTIVATE DIALOG oCurDlg CENTERED NOMODAL ;
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

RETURN ( .T. )


*-- FUNCTION -----------------------------------------------------------------
*         Name: SaveGraItem
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SaveGraItem( oVar, oItem )

   LOCAL oIni

   oItem:cType  := GetGraphName( ASCAN( oVar:aGraphic, oVar:cGraphic ) )
   oItem:cText  := oVar:cGraphic
   oItem:nStyle := VAL( oVar:cStyle )
   oItem:nTrans := IIF( oItem:lTrans, 1, 0 )

   oVar:cItemDef := oItem:Set( .F., nMeasure )

   INI oIni FILE oVar:cAreaIni
      SET SECTION "Items" ENTRY ALLTRIM(STR(oVar:i,5)) TO oVar:cItemDef OF oIni
   ENDINI

   IF oItem:nShow = 1

      aItems[oVar:nArea,oVar:i]:End()

      aItems[oVar:nArea,oVar:i] := TBitmap():New( nRulerTop + GetPixel( oItem:nTop ), ;
          nRuler + GetPixel( oItem:nLeft ), GetPixel( oItem:nWidth ), GetPixel( oItem:nHeight ), ;
          "GRAPHIC",, .T., aWnd[oVar:nArea],,, .F., .T.,,, .T.,, .T. )
      aItems[oVar:nArea,oVar:i]:lTransparent := .T.

      aItems[oVar:nArea,oVar:i]:bPainted = {| hDC, cPS | ;
         DrawGraphic( hDC, ALLTRIM(UPPER( oItem:cType )), ;
                      GetPixel( oItem:nWidth ), GetPixel( oItem:nHeight ), ;
                      GetColor( oItem:nColor ), GetColor( oItem:nColFill ), ;
                      oItem:nStyle, oItem:nPenWidth, ;
                      GetPixel( oItem:nRndWidth ), GetPixel( oItem:nRndHeight ) ) }

      aItems[oVar:nArea,oVar:i]:lDrag := .T.
      ElementActions( aItems[oVar:nArea,oVar:i], oVar:i, "", oVar:nArea, oVar:cAreaIni )
      aItems[oVar:nArea,oVar:i]:SetFocus()

   ENDIF

   SaveItemGeneral( oVar, oItem )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: BarcodeProperties
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION BarcodeProperties( i, nArea, cAreaIni, lFromList, lNew )

   LOCAL oFont, oIni, lRight, lCenter, nColor
   LOCAL nDefClr, aBtn[3], aGet[6], aSay[4], aGrp[3], aCbx[2]
   LOCAL oVar  := GetoVar( i, nArea, cAreaIni, lNew )
   LOCAL oItem := VRDItem():New( oVar:cItemDef )

   oVar:AddMember( "aBarcode"    ,, GetBarcodes()                                         )
   oVar:AddMember( "cBarcode"    ,, oVar:aBarcode[oItem:nBCodeType]                       )
   oVar:AddMember( "aOrient"     ,, { GL("Horizontal"), GL("Vertical") }                  )
   oVar:AddMember( "cOrient"     ,, oVar:aOrient[ IIF( oItem:nOrient = 0, 1, oItem:nOrient ) ] )
   oVar:AddMember( "aBitmaps"    ,, { "BCODE_HORI", "BCODE_VERT" }                        )
   oVar:AddMember( "aColors"     ,, GetAllColors()                                        )
   oVar:AddMember( "cPinPicture" ,, IIF( nMeasure = 2, "99.9999", "999.99" )              )

   oGenVar:lItemDlg := .T.

   DEFINE DIALOG oCurDlg RESOURCE "BARCODEPROPERTY" TITLE GL("Barcode Properties")

   nDefClr := oCurDlg:nClrPane

   REDEFINE COMBOBOX oVar:cBarcode ITEMS oVar:aBarcode ID 201 OF oCurDlg

   REDEFINE GET aGet[4] VAR oItem:cText ID 203 OF oCurDlg WHEN oItem:nEdit <> 0 MEMO

   REDEFINE BTNBMP aBtn[2] ID 153 OF oCurDlg RESOURCE "SELECT" NOBORDER ;
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

   REDEFINE BTNBMP ID 111 OF oCurDlg NOBORDER RESOURCE "B_SAVE3" ;
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

   ACTIVATE DIALOG oCurDlg CENTERED NOMODAL ;
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

RETURN ( .T. )


*-- FUNCTION -----------------------------------------------------------------
*         Name: SaveBarItem
*  Description:
*    Arguments: None
* Return Value: .T.
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SaveBarItem( oVar, oItem )

   LOCAL lRight, lCenter, nColor, oIni

   oItem:nBCodeType := ASCAN( oVar:aBarcode, oVar:cBarcode )
   oItem:nOrient    := ASCAN( oVar:aOrient, oVar:cOrient )

   oVar:cItemDef := oItem:Set( .F., nMeasure )

   INI oIni FILE oVar:cAreaIni
      SET SECTION "Items" ENTRY ALLTRIM(STR(oVar:i,5)) TO oVar:cItemDef OF oIni
   ENDINI

   IIF( oItem:nOrient = 2, lCenter := .T., lCenter := .F. )
   IIF( oItem:nOrient = 3, lRight  := .T., lRight  := .F. )

   IF oItem:nShow = 1

      aItems[oVar:nArea,oVar:i]:End()

         aItems[oVar:nArea,oVar:i] := TBitmap():New( nRulerTop + GetPixel( oItem:nTop ), ;
             nRuler + GetPixel( oItem:nLeft ), GetPixel( oItem:nWidth ), GetPixel( oItem:nHeight ), ;
             "GRAPHIC",, .T., aWnd[oVar:nArea],,, .F., .T.,,, .T.,, .T. )
         aItems[oVar:nArea,oVar:i]:lTransparent := .T.

         aItems[oVar:nArea,oVar:i]:bPainted = {| hDC, cPS | ;
            DrawBarcode( hDC, ALLTRIM( oItem:cText ), 0, 0, ;
                         GetPixel( oItem:nWidth ), GetPixel( oItem:nHeight ), ;
                         oItem:nBCodeType, GetColor( oItem:nColText ), GetColor( oItem:nColPane ), ;
                         oItem:nOrient, oItem:lTrans, GetPixel( oItem:nPinWidth ) ) }

      aItems[oVar:nArea,oVar:i]:lDrag := .T.
      ElementActions( aItems[oVar:nArea,oVar:i], oVar:i, "", oVar:nArea, oVar:cAreaIni )
      aItems[oVar:nArea,oVar:i]:SetFocus()

   ENDIF

   SaveItemGeneral( oVar, oItem )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: SetItemSize
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SetItemSize( i, nArea, cAreaIni )

   LOCAL oIni, nColor, nColFill, nStyle, nPenWidth, nRndWidth, nRndHeight, oItem
   LOCAL cItemDef   := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(i,5)) , "", cAreaIni ) )
   LOCAL cOldDef    := cItemDef
   LOCAL aWerte     := GetCoors( aItems[nArea,i]:hWnd )
   LOCAL nTop       := GetCmInch( aWerte[1] - nRulerTop )
   LOCAL nLeft      := GetCmInch( aWerte[2] - nRuler )
   LOCAL nHeight    := GetCmInch( aWerte[3] - aWerte[1] )
   LOCAL nWidth     := GetCmInch( aWerte[4] - aWerte[2] )
   LOCAL nGesWidth  := VAL( GetPvProfString( "General", "Width", "600", cAreaIni ) )
   LOCAL nGesHeight := VAL( GetPvProfString( "General", "Height", "300", cAreaIni ) )
   LOCAL cTyp       := UPPER(ALLTRIM( GetField( cItemDef, 1 ) ))

   IF nTop + nHeight <= nGesHeight .AND. nLeft + nWidth <= nGesWidth .AND. ;
         nTop >= 0 .AND. nLeft >= 0

      nTop    := GetDivisible( ROUND( nTop   , IIF( nMeasure = 2, 2, 0 ) ), GetCmInch( nYMove ) )
      nLeft   := GetDivisible( ROUND( nLeft  , IIF( nMeasure = 2, 2, 0 ) ), GetCmInch( nXMove ) )
      nWidth  := GetDivisible( ROUND( nWidth , IIF( nMeasure = 2, 2, 0 ) ), GetCmInch( nXMove ) )
      nHeight := GetDivisible( ROUND( nHeight, IIF( nMeasure = 2, 2, 0 ) ), GetCmInch( nYMove ) )

      cItemDef := SUBSTR( cItemDef, 1, StrAtNum( "|", cItemDef, 6 ) ) + ;
         ALLTRIM(STR( nTop, 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
         ALLTRIM(STR( nLeft, 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
         ALLTRIM(STR( nWidth, 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
         ALLTRIM(STR( nHeight, 5, IIF( nMeasure = 2, 2, 0 ) )) + ;
         SUBSTR( cItemDef, StrAtNum( "|", cItemDef, 10 ) )

      IF IsGraphic( cTyp ) = .T.

         nColor     := VAL( GetField( cItemDef, 11 ) )
         nColFill   := VAL( GetField( cItemDef, 12 ) )
         nStyle     := VAL( GetField( cItemDef, 13 ) )
         nPenWidth  := VAL( GetField( cItemDef, 14 ) )
         nRndWidth  := VAL( GetField( cItemDef, 15 ) )
         nRndHeight := VAL( GetField( cItemDef, 16 ) )

         aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawGraphic( hDC, cTyp, ;
            GetPixel( nWidth ), GetPixel( nHeight ), ;
            GetColor( nColor ), GetColor( nColFill ), ;
            nStyle, nPenWidth, GetPixel( nRndWidth ), GetPixel( nRndHeight ) ) }

      ELSEIF UPPER( cTyp ) = "BARCODE"

         oItem := VRDItem():New( cItemDef )

         aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawBarcode( hDC, oItem:cText, 0, 0, ;
            GetPixel( nWidth ), GetPixel( nHeight ), ;
            oItem:nBCodeType, ;
            GetColor( oItem:nColText ), GetColor( oItem:nColPane ), ;
            oItem:nOrient, IIF( oItem:nTrans = 1, .T., .F. ), ;
            GetPixel( oItem:nPinWidth ) ) }

      ENDIF

      INI oIni FILE cAreaIni
         SET SECTION "Items" ENTRY ALLTRIM(STR(i,5)) TO cItemDef OF oIni
      ENDINI

      IF VAL( GetField( cItemDef, 7  ) ) <> VAL( GetField( cOldDef, 7  ) ) .OR. ;
         VAL( GetField( cItemDef, 8  ) ) <> VAL( GetField( cOldDef, 8  ) ) .OR. ;
         VAL( GetField( cItemDef, 9  ) ) <> VAL( GetField( cOldDef, 9  ) ) .OR. ;
         VAL( GetField( cItemDef, 10 ) ) <> VAL( GetField( cOldDef, 10 ) )

         IF lFillWindow = .F.
            Add2Undo( cOldDef, i, nArea )
            SetSave( .F. )
         ENDIF

      ENDIF

   ENDIF

   lFillWindow := .T.
   aItems[nArea,i]:Move( nRulerTop + GetPixel( VAL( GetField( cItemDef, 7 ) ) ), ;
      nRuler + GetPixel( VAL( GetField( cItemDef, 8 ) ) ), ;
      GetPixel( VAL( GetField( cItemDef, 9 ) ) ), ;
      GetPixel( VAL( GetField( cItemDef, 10 ) ) ), .T. )
   lFillWindow := .F.

   aItemPosition := { GetField( cItemDef, 7 ), GetField( cItemDef, 8 ), ;
                      GetField( cItemDef, 9 ), GetField( cItemDef, 10 ) }
   aItemPixelPos := { GetPixel( VAL( GetField( cItemDef, 7 ) ) ), ;
                      GetPixel( VAL( GetField( cItemDef, 8 ) ) ), ;
                      GetPixel( VAL( GetField( cItemDef, 9 ) ) ), ;
                      GetPixel( VAL( GetField( cItemDef, 10 ) ) ) }

   aItems[nArea,i]:Refresh()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: MsgBarItem
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION MsgBarItem( nItem, nArea, cAreaIni, nRow, nCol, lResize )

   LOCAL nTop, nLeft
   LOCAL cItemDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(nItem,5)) , "", cAreaIni ) )
   LOCAL cItemID  := ALLTRIM(  GetField( cItemDef, 3 ) )

   DEFAULT lResize := .F.

   IF lResize = .T. .AND. LEN( aItemPosition ) <> 0

      oMsgInfo:SetText( GL("ID") + ": " + cItemID + "  " + ;
                        GL("Top:")    + " " + ALLTRIM( aItemPosition[1] ) + "  " + ;
                        GL("Left:")   + " " + ALLTRIM( aItemPosition[2] ) + "  " + ;
                        GL("Width:")  + " " + ALLTRIM( aItemPosition[3] ) + "  " + ;
                        GL("Height:") + " " + ALLTRIM( aItemPosition[4] ) )

      SetReticule( aItemPixelPos[2] + nRulerTop, aItemPixelPos[1] + nRuler, nArea )

   ELSE
      nInfoRow := 0; nInfoCol := 0 // nRulerTop := 0; nRuler := 0 // FiveTech
      
      nTop  := aItems[nArea,nItem]:nTop  + ;
                  ( nLoWord( aItems[nArea,nItem]:nPoint ) - nInfoRow ) - nRulerTop
      nLeft := aItems[nArea,nItem]:nLeft + ;
                  ( nHiWord( aItems[nArea,nItem]:nPoint ) - nInfoCol ) - nRuler

      SetReticule( nTop + nRulerTop, nLeft + nRuler, nArea )

      /* FiveTech
      oMsgInfo:SetText( GL("ID") + ": " + cItemID + "  " + ;
                        GL("Top:")    + " " + ALLTRIM(STR( GetCmInch( nTop ), 5, IIF( nMeasure = 2, 2, 0 ) )) + "  " + ;
                        GL("Left:")   + " " + ALLTRIM(STR( GetCmInch( nLeft), 5, IIF( nMeasure = 2, 2, 0 ) )) + "  " + ;
                        GL("Width:")  + " " + ALLTRIM( cInfoWidth ) + "  " + ;
                        GL("Height:") + " " + ALLTRIM( cInfoHeight ) )
      */                  

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetGraphName
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetGraphName( nIndex )

   LOCAL cName := ""

   DO CASE
   CASE nIndex = 1  ; cName := "LineUp"
   CASE nIndex = 2  ; cName := "LineDown"
   CASE nIndex = 3  ; cName := "LineHorizontal"
   CASE nIndex = 4  ; cName := "LineVertical"
   CASE nIndex = 5  ; cName := "Rectangle"
   CASE nIndex = 6  ; cName := "Ellipse"
   ENDCASE

RETURN ( cName )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetGraphIndex
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetGraphIndex( cTyp )

   LOCAL nIndex := 0

   DO CASE
   CASE UPPER( cTyp ) == "LINEUP"          ; nIndex := 1
   CASE UPPER( cTyp ) == "LINEDOWN"        ; nIndex := 2
   CASE UPPER( cTyp ) == "LINEHORIZONTAL"  ; nIndex := 3
   CASE UPPER( cTyp ) == "LINEVERTICAL"    ; nIndex := 4
   CASE UPPER( cTyp ) == "RECTANGLE"       ; nIndex := 5
   CASE UPPER( cTyp ) == "ELLIPSE"         ; nIndex := 6
   ENDCASE

RETURN ( nIndex )


*-- FUNCTION -----------------------------------------------------------------
* Name........: GetImage
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION GetImage( cOldFile )

   LOCAL cFile := GetFile( GL("Images") + "|*.BMP;*.DIB;*.JIF;*.JPG;*.PCX;*.RLE;*.TGA|" + ;
                           "Bitmap (*.bmp)| *.bmp|" + ;
                           "DIB (*.dib)| *.dib|"  + ;
                           "PCX (*.pcx)| *.pcx|"  + ;
                           "JPEG (*.jpg)| *.jpg|"  + ;
                           "TARGA (*.tga)| *.tga|"  + ;
                           "RLE (*.rle)| *.rle|"  + ;
                           "JIF (*.jif)| *.jif|"  + ;
                           GL("All Files") + "(*.*)| *.*", ;
                           GL("Open Image"), 1 )

RETURN IIF( EMPTY( cFile ), cOldFile, cFile )


*-- FUNCTION -----------------------------------------------------------------
* Name........: ItemCopy
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ItemCopy( lCut )

   LOCAL i, oItemInfo
   LOCAL cAreaIni := aAreaIni[nAktArea]

   DEFAULT lCut := .F.

   IF nAktItem = 0 .AND. LEN( aSelection ) = 0
      MsgStop( GL("Please select an item first."), GL("Stop!") )
      RETURN (.F.)
   ENDIF

   aSelectCopy  := {}
   nCopyEntryNr := 0
   nCopyAreaNr  := 0

   IF LEN( aSelection ) <> 0

      //Multiselection
      aSelectCopy := aSelection
      aItemCopy   := {}

      FOR i := 1 TO LEN( aSelection )

         cItemCopy := ALLTRIM( GetPvProfString( "Items", ;
                      ALLTRIM(STR( aSelection[i,2], 5 )) , "", aAreaIni[ aSelection[i,1] ] ) )
         AADD( aItemCopy, cItemCopy )

         oItemInfo := VRDItem():New( cItemCopy )

         IF lCut = .T.
            DeleteItem( aSelection[i,2], aSelection[i,1], .T. )
            IF oItemInfo:nItemID < 0
               DelIniEntry( "Items", ALLTRIM(STR(aSelection[i,2],5)), ;
                            aAreaIni[ aSelection[i,1] ] )
            ENDIF
         ENDIF

      NEXT

   ELSE

      cItemCopy    := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(nAktItem,5)), ;
                      "", cAreaIni ) )
      nCopyEntryNr := nAktItem
      nCopyAreaNr  := nAktArea

      oItemInfo := VRDItem():New( cItemCopy )

      IF lCut = .T.
         DeleteItem( nAktItem, nAktArea, .T. )
         IF oItemInfo:nItemID < 0
            DelIniEntry( "Items", ALLTRIM(STR(nAktItem,5)), aAreaIni[nAktArea] )
         ENDIF
      ENDIF

   ENDIF

RETURN ( .T. )


*-- FUNCTION -----------------------------------------------------------------
* Name........: ItemPaste
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ItemPaste( lCut )

   LOCAL i

   UnSelectAll()

   IF LEN( aSelectCopy ) <> 0
      FOR i := 1 TO LEN( aSelectCopy )
         NewItem( "COPY", nAktArea, aSelectCopy[i,1], aSelectCopy[i,2], aItemCopy[i] )
      NEXT
   ELSE
      NewItem( "COPY", nAktArea )
   ENDIF

RETURN ( .T. )


*-- FUNCTION -----------------------------------------------------------------
* Name........: NewItem
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION NewItem( cTyp, nArea, nTmpCopyArea, nTmpCopyEntry, cTmpItemCopy )

   LOCAL i, nFree, cItemDef, oIni, aBarcodes, oItemInfo, cDefault
   LOCAL nItemTop   := 0
   LOCAL nItemLeft  := 0
   LOCAL nPlusTop   := 0
   LOCAL nPlusLeft  := 0
   LOCAL aFirst     := { .F., 0, 0, 0, 0, 0 }
   LOCAL nElemente  := 0
   LOCAL cAreaIni   := aAreaIni[nArea]
   LOCAL nGesWidth  := VAL( GetPvProfString( "General", "Width", "600", cAreaIni ) )
   LOCAL nGesHeight := VAL( GetPvProfString( "General", "Height", "300", cAreaIni ) )
   LOCAL cTop       := IIF( nMeasure = 2, "0.10", "2" )
   LOCAL cLeft      := cTop

   FOR i := 400 TO 1000
      IF aItems[ nArea, i ] = NIL
         nFree := i
         EXIT
      ENDIF
   NEXT

   IF cTyp = "COPY"

      DEFAULT nTmpCopyEntry := nCopyEntryNr
      DEFAULT nTmpCopyArea  := nCopyAreaNr
      DEFAULT cTmpItemCopy  := cItemCopy

      IF nTmpCopyEntry < 400
         FOR i := 1 TO 399
         IF aItems[ nArea, i ] = NIL
            nFree := i
            EXIT
         ENDIF
         NEXT
      ENDIF

      oItemInfo := VRDItem():New( cTmpItemCopy )

      IF oItemInfo:nTop + oItemInfo:nHeight >= nGesHeight
         nItemTop  := GetCmInch( 10 )
      ENDIF
      IF oItemInfo:nLeft + oItemInfo:nWidth >= nGesWidth
         nItemLeft := GetCmInch( 10 )
      ENDIF

      IF nTmpCopyArea = nArea
         nPlusTop  := IIF( nMeasure = 2, 0.06, 2 )
         nPlusLeft := IIF( nMeasure = 2, 0.06, 2 )
      ENDIF

      cItemDef := SUBSTR( cTmpItemCopy, 1, StrAtNum( "|", cTmpItemCopy, 6 ) ) + ;
         ALLTRIM(STR( IIF( nItemTop = 0, oItemInfo:nTop, nItemTop ) + nPlusTop, 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
         ALLTRIM(STR( IIF( nItemLeft = 0, oItemInfo:nLeft, nItemLeft ) + nPlusLeft, 5, IIF( nMeasure = 2, 2, 0 ) )) + ;
         SUBSTR( cTmpItemCopy, StrAtNum( "|", cTmpItemCopy, 8 ) )

   ELSEIF cTyp = "TEXT"
      cItemDef := "Text||-1|1|1|1|" + cTop + "|" + cLeft + "|" + ;
                  IIF( nMeasure = 2, "1.00", "30" ) + "|" + ;
                  IIF( nMeasure = 2, "0.50",  "5" ) + "|" + ;
                  "1|1|2|0|0|0|"
   ELSEIF cTyp = "IMAGE"
      cItemDef := "Image||-1|1|1|1|" + cTop + "|" + cLeft + "|" + ;
                  IIF( nMeasure = 2, "0.60", "20" ) + "|" + ;
                  IIF( nMeasure = 2, "0.60", "20" ) + "|" + ;
                  "|0"
   ELSEIF cTyp = "GRAPHIC"
      cItemDef := "Rectangle|" + ;
                  GL("Rectangle") + ;
                  "|-1|1|1|1|" + cTop + "|" + cLeft + "|" + ;
                  IIF( nMeasure = 2, "0.60", "20" ) + "|" + ;
                  IIF( nMeasure = 2, "0.30", "10" ) + "|" + ;
                  "1|2|1|1|0|0"
   ELSEIF cTyp = "BARCODE"
      cItemDef := "Barcode|" + ;
                  "12345678" + ;
                  "|-1|1|1|1|" + cTop + "|" + cLeft + "|" + ;
                  IIF( nMeasure = 2, "1.70", "60" ) + "|" + ;
                  IIF( nMeasure = 2, "0.30", "10" ) + "|" + ;
                  "1|1|2|1|1|0.3|"
   ENDIF

   IF cTyp <> "COPY"

      cDefault := GetPvProfString( "General", "Default" + cTyp, "", cDefIni )

      IF .NOT. EMPTY( cDefault )
         cItemDef := SUBSTR( cDefault, 1, StrAtNum( "|", cDefault, 2 ) ) + ;
                     SUBSTR( cItemDef, StrAtNum( "|", cItemDef, 2 ) + 1, StrAtNum( "|", cItemDef, 8 ) - StrAtNum( "|", cItemDef, 2 ) ) + ;
                     SUBSTR( cDefault, StrAtNum( "|", cDefault, 8 ) + 1 )
      ENDIF

   ENDIF

   INI oIni FILE cAreaIni
      SET SECTION "Items" ENTRY ALLTRIM(STR(nFree,5)) TO cItemDef OF oIni
   ENDINI

   ShowItem( nFree, nArea, cAreaIni, @aFirst, @nElemente )
   aItems[nArea,nFree]:lDrag := .T.

   /*
   aItemPosition := { GetField( cItemDef, 7 ), GetField( cItemDef, 8 ), ;
                      GetField( cItemDef, 9 ), GetField( cItemDef, 10 ) }
   aItemPixelPos := { GetPixel( VAL( aItemPosition[1] ) ), ;
                      GetPixel( VAL( aItemPosition[2] ) ), ;
                      GetPixel( VAL( aItemPosition[3] ) ), ;
                      GetPixel( VAL( aItemPosition[4] ) ) }
   aItems[nArea,i]:CheckDots()
   aItems[nArea,i]:Move( nRulerTop + aItemPixelPos[1], nRuler + aItemPixelPos[2],,, .T. )
   */

   nInfoRow := 0
   nInfoCol := 0
   SelectItem( i, nArea, cAreaIni )

   SetSave( .F. )

   IF cTyp <> "COPY"
      ItemProperties( i, nArea,, .T. )
   ELSE
      Add2Undo( "", nFree, nArea )
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ShowItem
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ShowItem( i, nArea, cAreaIni, aFirst, nElemente, aIniEntries, nIndex )

   LOCAL cTyp, cName, nTop, nLeft, nWidth, nHeight, nFont, oFont, hDC, nTrans, lTrans
   LOCAL nColText, nColPane, nOrient, cFile, nBorder, nColor, nColFill, nStyle, nPenWidth
   LOCAL nRndWidth, nRndHeight, nBarcode, nPinWidth, cItemDef
   LOCAL lRight  := .F.
   LOCAL lCenter := .F.

   IF aIniEntries = NIL
      cItemDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(i,5)) , "", cAreaIni ) )
   ELSE
      cItemDef := GetIniEntry( aIniEntries,, "",, nIndex )
   ENDIF

   IF .NOT. EMPTY( cItemDef ) .AND. VAL( GetField( cItemDef, 4 ) ) <> 0

      cTyp      := UPPER(ALLTRIM( GetField( cItemDef, 1 ) ))
      cName     := GetField( cItemDef, 2 )
      nTop      := nRulerTop + GetPixel( VAL( GetField( cItemDef, 7 ) ) )
      nLeft     := nRuler    + GetPixel( VAL( GetField( cItemDef, 8 ) ) )
      nWidth    := GetPixel( VAL( GetField( cItemDef, 9 ) ) )
      nHeight   := GetPixel( VAL( GetField( cItemDef, 10 ) ) )

      IF aFirst[1] = .F.
         aFirst[2] := nTop
         aFirst[3] := nLeft
         aFirst[4] := nWidth
         aFirst[5] := nHeight
         aFirst[6] := i
         aFirst[1] := .T.
      ENDIF

      IF cTyp = "TEXT"

         nFont    := VAL( GetField( cItemDef, 11 ) )
         nColText := VAL( GetField( cItemDef, 12 ) )
         nColPane := VAL( GetField( cItemDef, 13 ) )
         nOrient  := VAL( GetField( cItemDef, 14 ) )
         nBorder  := VAL( GetField( cItemDef, 15 ) )
         nTrans   := VAL( GetField( cItemDef, 16 ) )

         IIF( nFont = 0, oFont := oAppFont, oFont := aFonts[nFont] )
         IIF( nOrient = 2, lCenter := .T., lCenter := .F. )
         IIF( nOrient = 3, lRight := .T. , lRight := .F. )

         SetBKMode( oMainWnd:hDC, 1 )

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

         SetBKMode( oMainWnd:hDC, 0 )

         /*
         [ <oSay> := ] TSay():New( <nRow>, <nCol>, <{cText}>,;
            [<oWnd>], [<cPict>], <oFont>, <.lCenter.>, <.lRight.>, <.lBorder.>,;
            <.lPixel.>, <nClrText>, <nClrBack>, <nWidth>, <nHeight>,;
            <.design.>, <.update.>, <.lShaded.>, <.lBox.>, <.lRaised.> )
         */

      ELSEIF cTyp = "IMAGE"

         cFile   := ALLTRIM( GetField( cItemDef, 11 ) )
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

      ELSEIF IsGraphic( cTyp ) = .T.

         nColor     := VAL( GetField( cItemDef, 11 ) )
         nColFill   := VAL( GetField( cItemDef, 12 ) )
         nStyle     := VAL( GetField( cItemDef, 13 ) )
         nPenWidth  := VAL( GetField( cItemDef, 14 ) )
         nRndWidth  := GetPixel( VAL( GetField( cItemDef, 15 ) ) )
         nRndHeight := GetPixel( VAL( GetField( cItemDef, 16 ) ) )

         aItems[nArea,i] := TBitmap():New( nTop, nLeft, nWidth, nHeight, "GRAPHIC",, ;
             .T., aWnd[nArea],,, .F., .T.,,, .T.,, .T. )
         aItems[nArea,i]:lTransparent := .T.

         aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawGraphic( hDC, cTyp, nWidth, nHeight, GetColor( nColor ), GetColor( nColFill ), ;
                         nStyle, nPenWidth, nRndWidth, nRndHeight ) }

      ELSEIF cTyp = "BARCODE" .AND. lProfi = .T.

         nBarcode    := VAL( GetField( cItemDef, 11 ) )
         nColText    := VAL( GetField( cItemDef, 12 ) )
         nColPane    := VAL( GetField( cItemDef, 13 ) )
         nOrient     := VAL( GetField( cItemDef, 14 ) )
         lTrans      := IIF( VAL( GetField( cItemDef, 15 ) ) = 1, .T., .F. )
         nPinWidth   := GetPixel( VAL( GetField( cItemDef, 16 ) ) )

         aItems[nArea,i] := TBitmap():New( nTop, nLeft, nWidth, nHeight, "GRAPHIC",, ;
             .T., aWnd[nArea],,, .F., .T.,,, .T.,, .T. )
         aItems[nArea,i]:lTransparent := .T.

         aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawBarcode( hDC, cName, 0, 0, nWidth, nHeight, nBarCode, GetColor( nColText ), ;
                         GetColor( nColPane ), nOrient, lTrans, nPinWidth ) }

      ENDIF

      IF cTyp = "BARCODE" .AND. lProfi = .F.
         //Dummy
      ELSE
         aItems[nArea,i]:lDrag := .T.
         ElementActions( aItems[nArea,i], i, cName, nArea, cAreaIni, cTyp )
      ENDIF

      ++nElemente

   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: DeactivateItem
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DeactivateItem()

   IF nAktItem <> 0
      aItems[nSelArea,nAktItem]:HideDots()
      naktItem := 0
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: DrawGraphic
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DrawGraphic( hDC, cType, nWidth, nHeight, nColor, nColFill, nStyle, nPenWidth, nRndWidth, nRndHeight )

   LOCAL nPlus      := IIF( nPenWidth < 1, 0, nPenWidth - 1 )
   LOCAL nBottom    := nHeight - nPlus
   LOCAL nRight     := nWidth  - nPlus
   LOCAL hPen       := CreatePen( nStyle - 1, nPenWidth, nColor )
   LOCAL hOldPen    := SelectObject( hDC, hPen )
   LOCAL hBrush     := CreateSolidBrush( nColFill )
   LOCAL hOldBrush  := SelectObject( hDC, hBrush )

   DO CASE
   CASE cType == "LINEUP"
      MOVETO( hDC, nPlus, nBottom )
      LINETO( hDC, nRight, nPlus )
   CASE cType == "LINEDOWN"
      MOVETO( hDC, nPlus, nPlus )
      LINETO( hDC, nRight, nBottom )
   CASE cType == "LINEHORIZONTAL"
      MOVETO( hDC, nPlus , IIF( nPenWidth > 1, nBottom/2, 0 ) )
      LINETO( hDC, nRight, IIF( nPenWidth > 1, nBottom/2, 0 ) )
   CASE cType == "LINEVERTICAL"
      MOVETO( hDC, IIF( nPenWidth > 1, nRight/2, 0 ), nPlus )
      LINETO( hDC, IIF( nPenWidth > 1, nRight/2, 0 ), nBottom )
   CASE cType == "RECTANGLE"
      RoundRect( hDC, nPlus, nPlus, nRight, nBottom, nRndWidth*2, nRndHeight*2 )
   CASE cType == "ELLIPSE"
      Ellipse( hDC, nPlus, nPlus, nRight, nBottom )
   ENDCASE

   SelectObject( hDC, hOldPen )
   DeleteObject( hPen )
   SelectObject( hDC, hOldBrush )
   DeleteObject( hBrush )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: DrawBarcode
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION DrawBarcode( hDC, cText, nTop, nLeft, nWidth, nHeight, nBCodeType, ;
                      nColText, nColPane, nOrient, lTransparent, nPinWidth )

   LOCAL oBC
   LOCAL lHorizontal := IIF( nOrient = 1, .T., .F. )

   //Bei Ausdrucken wird ein Dummy-Wert gezeigt
   IF ALLTRIM(SUBSTR( cText, 1, 1 )) = "["
      cText := "12345678"
   ENDIF

   oBC := VRDBarcode():New( hDC, cText, nTop, nLeft, nWidth, nHeight, nBCodeType, ;
                            nColText, nColPane, lHorizontal, lTransparent, nPinWidth )
   oBC:ShowBarcode()

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: IsGraphic
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION IsGraphic( cTyp )

   LOCAL lReturn := .F.

   IF cTyp == "LINEUP" .OR. ;
      cTyp == "LINEDOWN" .OR. ;
      cTyp == "LINEHORIZONTAL" .OR. ;
      cTyp == "LINEVERTICAL" .OR. ;
      cTyp == "RECTANGLE" .OR. ;
      cTyp == "ELLIPSE"
      lReturn := .T.
   ENDIF

RETURN ( lReturn )