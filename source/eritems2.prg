
#INCLUDE "Folder.ch"
#INCLUDE "FiveWin.ch"

STATIC  nBoxTop, nBoxLeft, nBoxRight, nBoxBottom

MEMVAR cDefaultPath
MEMVAR nAktItem, nAktArea, nSelArea //, aSelection //, nTotalHeight, nTotalWidth
MEMVAR oGenVar
//MEMVAR lBoxDraw
MEMVAR cInfoWidth, cInfoHeight
MEMVAR oEr

STATIC lBoxDraw  := .F.

//------------------------------------------------------------------------------

FUNCTION SelectItem( nItem, nArea, cAreaIni )

   LOCAL cItemDef := ALLTRIM( GetPvProfString( "Items", ALLTRIM(STR(nItem,5)) , "", cAreaIni ) )

   cInfoWidth  := GetField( cItemDef, 9 )
   cInfoHeight := GetField( cItemDef, 10 )

   nAktItem := nItem
   nSelArea := nArea
   nAktArea := nArea

   IF GetKeyState( VK_SHIFT )
      ToggleItemSelection( nItem, nArea )
   ELSE
      UnSelectAll()
   ENDIF

RETURN (.T.)

//------------------------------------------------------------------------------

FUNCTION ToggleItemSelection( nItem, nArea )

   LOCAL nSelSearch := ASCAN( oER:aSelection, {| aVal | aVal[1] = nArea .AND. aVal[2] = nItem } )

   IF nSelSearch = 0
      AADD( oER:aSelection, { nArea, nItem } )
   ELSE
      oER:aSelection := ADel( oER:aSelection, nSelSearch, .T. )
   ENDIF

   MarkItem( oER:aItems[nArea,nItem]:hWnd )
   nAktItem := 0

RETURN (.T.)

//------------------------------------------------------------------------------

FUNCTION RefreshSelection()

   LOCAL i

   FOR i := 1 TO LEN( oER:aSelection )
      MarkItem( oER:aItems[ oER:aSelection[i,1], oER:aSelection[i,2] ]:hWnd )
      oER:aItems[ oER:aSelection[i,1], oER:aSelection[i,2] ]:Refresh()
      MarkItem( oER:aItems[ oER:aSelection[i,1], oER:aSelection[i,2] ]:hWnd )
   NEXT

   //UnSelectAll( .F. )
   //UnSelectAll( .F. )

RETURN (.T.)

//------------------------------------------------------------------------------

FUNCTION UnSelectAll( lDelSelection )

   LOCAL i

   DEFAULT lDelSelection := .T.

   FOR i := 1 TO LEN( oER:aSelection )
      IF oER:aItems[ oER:aSelection[i,1], oER:aSelection[i,2] ] <> NIL
         MarkItem( oER:aItems[ oER:aSelection[i,1], oER:aSelection[i,2] ]:hWnd )
      ENDIF
   NEXT

   IF lDelSelection
      oER:aSelection := {}
   ENDIF

   RETURN (.T.)

//------------------------------------------------------------------------------

FUNCTION SelectAllItems( lCurArea )

   LOCAL i, y, nCurArea

   DEFAULT lCurArea := .F.

   UnSelectAll()

   FOR y := 1 TO IIF( lCurArea, 1, Len( oER:aWnd ) )

      IF oER:aWnd[y] <> NIL

         nCurArea := IIF( lCurArea, nAktArea, y )

         FOR i := 1 TO LEN( oER:aItems[ nCurArea ] )

            IF oER:aItems[ nCurArea, i ] <> NIL

               MarkItem( oER:aItems[ nCurArea, i ]:hWnd )

               AADD( oER:aSelection, { nCurArea, i } )

            ENDIF

         NEXT

      ENDIF

   NEXT

   nAktItem := 0

RETURN (.T.)

//------------------------------------------------------------------------------

FUNCTION InvertSelection( lCurArea )

   LOCAL i, y, nCurArea

   DEFAULT lCurArea := .F.

   FOR y := 1 TO IIF( lCurArea, 1, Len( oER:aWnd ) )

      IF oER:aWnd[y] <> NIL

         nCurArea := IIF( lCurArea, nAktArea, y )

         FOR i := 1 TO LEN( oER:aItems[ nCurArea ] )

            IF oER:aItems[ nCurArea, i ] <> NIL

               ToggleItemSelection( i, nCurArea )

            ENDIF

         NEXT

      ENDIF

   NEXT

RETURN (.T.)

//------------------------------------------------------------------------------

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

//------------------------------------------------------------------------------

FUNCTION MoveSelection( nRow, nCol, oAktWnd )

   IF lBoxDraw
      RectDotted( oAktWnd:hWnd, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight )
      nBoxBottom = nRow
      nBoxRight  = nCol
      RectDotted( oAktWnd:hWnd, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight )
   ENDIF

RETURN (.T.)

//------------------------------------------------------------------------------

FUNCTION StopSelection( nRow, nCol, oAktWnd )

   LOCAL i, aBoxRect, aItemRect
   LOCAL aSelSearch := {}

   IF lBoxDraw

      nBoxBottom = nRow
      nBoxRight  = nCol
      RectDotted( oAktWnd:hWnd, nBoxTop, nBoxLeft, nBoxBottom, nBoxRight )
      lBoxDraw = .F.
      ReleaseCapture()

      FOR i := 1 TO LEN( oER:aItems[ nAktArea ] )

         IF oER:aItems[nAktArea,i] <> NIL

            aBoxRect  := { nBoxTop, nBoxLeft, nBoxBottom, nBoxRight }
            aItemRect := { oER:aItems[nAktArea,i]:nTop, oER:aItems[nAktArea,i]:nLeft, ;
                           oER:aItems[nAktArea,i]:nBottom, oER:aItems[nAktArea,i]:nRight }

            IF IsIntersectRect( aItemRect, aBoxRect )

               ToggleItemSelection( i, nAktArea )

            ENDIF

         ENDIF

      NEXT

   ENDIF

   oGenVar:lSelectItems := .F.

RETURN (.T.)

//------------------------------------------------------------------------------

FUNCTION MsgSelected()

   LOCAL i, cSel := ""

   FOR i := 1 TO LEN( oER:aSelection )
      cSel += STR( oER:aSelection[i,1] ) + "  " + STR( oER:aSelection[i,2] ) + CRLF
   NEXT

   Msginfo( cSel )

RETURN (.T.)

//------------------------------------------------------------------------------

FUNCTION MarkItem( hWnd )

   CtrlDrawFocus( hWnd )

RETURN (.T.)