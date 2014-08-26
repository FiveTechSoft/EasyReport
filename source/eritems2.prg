
#INCLUDE "Folder.ch"
#INCLUDE "FiveWin.ch"

MEMVAR aItems, aFonts, oAppFont, aAreaIni, aWnd, aWndTitle, oBar, oMru
MEMVAR oCbxArea, aCbxItems, nAktuellItem, aRuler, cLongDefIni, cDefaultPath
MEMVAR nAktItem, nAktArea, nSelArea, cAktIni, aSelection, nTotalHeight, nTotalWidth
MEMVAR nHinCol1, nHinCol2, nHinCol3, oMsgInfo, oGenVar
MEMVAR aVRDSave, lVRDSave, lFillWindow, nDeveloper, oRulerBmp1, oRulerBmp2
MEMVAR lBoxDraw, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight
MEMVAR cItemCopy, nCopyEntryNr, nCopyAreaNr, aSelectCopy, aItemCopy, nXMove, nYMove
MEMVAR cInfoWidth, cInfoHeight, nInfoRow, nInfoCol, aItemPosition, aItemPixelPos
MEMVAR oClpGeneral, cDefIni, cGeneralIni, nMeasure, cMeasure, lDemo, lBeta, oTimer
MEMVAR oMainWnd, lProfi, nUndoCount, nRedoCount

*-- FUNCTION -----------------------------------------------------------------
* Name........: SelectItem
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SelectItem( nItem, nArea, cAreaIni )

   LOCAL cItemDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(nItem,5)) , "", cAreaIni ) )

   cInfoWidth  := GetField( cItemDef, 9 )
   cInfoHeight := GetField( cItemDef, 10 )

   nAktItem := nItem
   nSelArea := nArea
   nAktArea := nArea
   cAktIni  := cAreaIni

   IF GetKeyState( VK_SHIFT )
      ToggleItemSelection( nItem, nArea )
   ELSE
      UnSelectAll()
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: ToggleItemSelection
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION ToggleItemSelection( nItem, nArea )

   LOCAL nSelSearch := ASCAN( aSelection, {| aVal | aVal[1] = nArea .AND. aVal[2] = nItem } )

   IF nSelSearch = 0
      AADD( aSelection, { nArea, nItem } )
   ELSE
      aSelection := ADELETE( aSelection, nSelSearch )
   ENDIF

   MarkItem( aItems[nArea,nItem]:hWnd )
   nAktItem := 0

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: RefreshSelection
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION RefreshSelection()

   LOCAL i

   FOR i := 1 TO LEN( aSelection )
      MarkItem( aItems[ aSelection[i,1], aSelection[i,2] ]:hWnd )
      aItems[ aSelection[i,1], aSelection[i,2] ]:Refresh()
      MarkItem( aItems[ aSelection[i,1], aSelection[i,2] ]:hWnd )
   NEXT

   //UnSelectAll( .F. )
   //UnSelectAll( .F. )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: UnSelectAll
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION UnSelectAll( lDelSelection )

   LOCAL i

   DEFAULT lDelSelection := .T.

   FOR i := 1 TO LEN( aSelection )
      IF aItems[ aSelection[i,1], aSelection[i,2] ] <> NIL
         MarkItem( aItems[ aSelection[i,1], aSelection[i,2] ]:hWnd )
      ENDIF
   NEXT

   IF lDelSelection = .T.
      aSelection := {}
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: SelectAllItems
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION SelectAllItems( lCurArea )

   LOCAL i, y, nCurArea

   DEFAULT lCurArea := .F.

   UnSelectAll()

   FOR y := 1 TO IIF( lCurArea, 1, 100 )

      IF aWnd[y] <> NIL

         nCurArea := IIF( lCurArea, nAktArea, y )

         FOR i := 1 TO LEN( aItems[ nCurArea ] )

            IF aItems[ nCurArea, i ] <> NIL

               MarkItem( aItems[ nCurArea, i ]:hWnd )

               AADD( aSelection, { nCurArea, i } )

            ENDIF

         NEXT

      ENDIF

   NEXT

   nAktItem := 0

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: InvertSelection
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION InvertSelection( lCurArea )

   LOCAL i, y, nCurArea

   DEFAULT lCurArea := .F.

   FOR y := 1 TO IIF( lCurArea, 1, 100 )

      IF aWnd[y] <> NIL

         nCurArea := IIF( lCurArea, nAktArea, y )

         FOR i := 1 TO LEN( aItems[ nCurArea ] )

            IF aItems[ nCurArea, i ] <> NIL

               ToggleItemSelection( i, nCurArea )

            ENDIF

         NEXT

      ENDIF

   NEXT

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: StartSelection
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION StartSelection( nRow, nCol, oAktWnd )

   lBoxDraw   = .T.
   nBoxTop    = nRow
   nBoxLeft   = nCol
   nBoxBottom = nRow
   nBoxRight  = nCol
   oAktWnd:Capture()

   oGenVar:lSelectItems := .T.

   RectDotted( oAktWnd:hWnd, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: MoveSelection
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION MoveSelection( nRow, nCol, oAktWnd )

   IF lBoxDraw = .T.
      RectDotted( oAktWnd:hWnd, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight )
      nBoxBottom = nRow
      nBoxRight  = nCol
      RectDotted( oAktWnd:hWnd, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight )
   ENDIF

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: StopSelection
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION StopSelection( nRow, nCol, oAktWnd )

   LOCAL i, aBoxRect, aItemRect
   LOCAL aSelSearch := {}

   IF lBoxDraw = .T.

      nBoxBottom = nRow
      nBoxRight  = nCol
      RectDotted( oAktWnd:hWnd, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight )
      lBoxDraw = .F.
      ReleaseCapture()

      FOR i := 1 TO LEN( aItems[ nAktArea ] )

         IF aItems[nAktArea,i] <> NIL

            aBoxRect  := { nBoxTop, nBoxLeft, nBoxBottom, nBoxRight }
            aItemRect := { aItems[nAktArea,i]:nTop, aItems[nAktArea,i]:nLeft, ;
                           aItems[nAktArea,i]:nBottom, aItems[nAktArea,i]:nRight }

            IF IsIntersectRect( aItemRect, aBoxRect )

               ToggleItemSelection( i, nAktArea )

            ENDIF

         ENDIF

      NEXT

   ENDIF

   oGenVar:lSelectItems := .F.

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........: MsgSelected
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION MsgSelected()

   LOCAL i, cSel := ""

   FOR i := 1 TO LEN( aSelection )
      cSel += STR( aSelection[i,1] ) + "  " + STR( aSelection[i,2] ) + CRLF
   NEXT

   Msginfo( cSel )

RETURN (.T.)


*-- FUNCTION -----------------------------------------------------------------
* Name........:
* Beschreibung:
* Argumente...: None
* Rückgabewert: .T.
* Author......: Timm Sodtalbers
*-----------------------------------------------------------------------------
FUNCTION MarkItem( hWnd )

   CtrlDrawFocus( hWnd )

RETURN (.T.)