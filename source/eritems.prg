
#INCLUDE "Folder.ch"
#INCLUDE "FiveWin.ch"


MEMVAR nAktItem, nSelArea //, aSelection, nAktArea,
MEMVAR nRuler, nRulerTop
MEMVAR cItemCopy, aSelectCopy, aItemCopy, nXMove, nYMove

MEMVAR lProfi, oGenVar,oER

STATIC aItemPosition
STATIC nCopyEntryNr, nCopyAreaNr
STATIC oCurDlg
STATIC nInfoRow, nInfoCol
STATIC cInfoWidth, cInfoHeight

STATIC aItemPixelPos := {}

//----------------------------------------------------------------------------//

function ElementActions( oItem, i, cName, nArea, cAreaIni, cTyp )

   oItem:bLDblClick = { || If( GetKeyState( VK_SHIFT ), MultiItemProperties(), ;
                             ( ItemProperties( i, nArea ), oCurDlg:SetFocus() ) ) }

   //oItems:bGotFocus  := {|| SelectItem( i, nArea, cAreaIni ), MsgBarInfos( i, cAreaIni ) }


   oItem:bGotFocus  := {||  SelectItem( i, nArea, cAreaIni ),;
                          IF( Empty(oItem:aDots),oItem:checkDots(), ) ,;
                          AEval(  oItem:aDots, { | o | o:SetColor( CLR_WHITE, CLR_WHITE ),;
                                    o:bPainted := { | hdc |  Ellipse( hDC , 1, 1,7,7 )  } } ) ,;
                          RefreshBrwProp( i, cAreaIni ) ,;
                          SetSelectItemTree( oER:oTree, nArea, i ) }

   //                       oItem:refresh(),;
   //                       RefreshBrwProp( i, cAreaIni )  }


  // oItem:bGotFocus  := {||  SelectItem( i, nArea, cAreaIni ), ;
  //                        RefreshBrwProp( i, cAreaIni )  }



   oItem:bLClicked = { | nRow, nCol, nFlags | ;
                           If( oGenVar:lItemDlg, ( If( GetKeyState( VK_SHIFT ), MultiItemProperties(), ;
                            ( ItemProperties( i, nArea ), oCurDlg:SetFocus() ) ) ), ;
                            ( SelectItem( i, nArea, cAreaIni ), ;
                              nInfoRow := nRow, nInfoCol := nCol, ;
                              MsgBarItem( i, nArea, cAreaIni, nRow, nCol ) ;
                              ) ) }

   oItem:bMoved   = { || SetItemSize( i, nArea, cAreaIni ), ;
                         RefreshBrwProp( i, cAreaIni ), ;
                         MsgBarItem( i, nArea, cAreaIni,,, .T. ) }

   oItem:bResized = { |nrow,ncol| SetItemSize( i, nArea, cAreaIni ),;
                         RefreshBrwProp( i, cAreaIni ), ;
                         MsgBarItem( i, nArea, cAreaIni,,, .T. ) }

   oItem:bMMoved  = { | nRow, nCol, nFlags, aPoint | ;
                        oER:SetReticule( nRow, nCol, nArea ),;
                        RefreshBrwProp( i, cAreaIni ) ,;
                        MsgBarItem( i, nArea, cAreaIni, nRow, nCol ) }

   /*
   oItem:bMMoved  = { | nRow, nCol, nFlags, aPoint | ;
                        aPoint := { nRow, nCol },;
                        aPoint := ClientToScreen( oItem:hWnd, aPoint ),;
                        aPoint := ScreenToClient( oER:aWnd[ nArea ]:hWnd, aPoint ),;
                        nRow := aPoint[ 1 ], nCol := aPoint[ 2 ],;
                        oER:SetReticule( nRow, nCol, nArea ),;
                        RefreshBrwProp( i, cAreaIni ) ,;
                        MsgBarItem( i, nArea, cAreaIni, nRow, nCol ) }
   */

   oItem:bDrag = { |nrow,ncol | oER:SetReticule( nRow, nCol, nArea )  }

   oItem:bRClicked = { | nRow, nCol, nFlags | oItem:SetFocus(),;
                         ItemPopupMenu( oItem, i, nArea, nRow, nCol ) }

   oItem:nDlgCode = DLGC_WANTALLKEYS

   oItem:bKeyDown   = { | nKey | KeyDownAction( nKey, i, nArea, cAreaIni ) }

   oItem:bPostDelcontrol:= { || DelItemWithKey( i , nArea ) }

    oItem:bLostFocus = { | nRow, nCol, nFlags |  ;
                              nInfoRow := nRow, nInfoCol := nCol, ;
                              MsgBarItem( i, nArea, cAreaIni, nRow, nCol ) }

return .T.

//----------------------------------------------------------------------------//

function KeyDownAction( nKey, nItem, nArea, cAreaIni )

   local aWerte   := GetCoors( oER:aItems[nArea,nItem]:hWnd )
   local nTop     := aWerte[1]
   local nLeft    := aWerte[2]
   local nHeight  := aWerte[3] - aWerte[1]
   local nWidth   := aWerte[4] - aWerte[2]
   local lMove    := .T.
   local nY       := 0
   local nX       := 0
   local nRight   := 0
   local nBottom  := 0

   if LEN( oER:aSelection ) <> 0
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
      oER:aItems[nArea,nItem]:Move( nTop + nY, nLeft + nX, nWidth + nRight, nHeight + nBottom, .T. )
      oER:aItems[nArea,nItem]:ShowDots( .T. )
   endif

return .T.

//----------------------------------------------------------------------------//

function DeleteItem( i, nArea, lFromList, lRemove, lFromUndoRedo )

   local cItemDef, cOldDef, cWert
   local aFirst    := { .F., 0, 0, 0, 0, 0 }
   local nElemente := 0
   local cAreaIni  := oER:aAreaIni[nArea]

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

   cItemDef := GetItemDef( i, cAreaIni )
   cOldDef  := cItemDef

   cWert:= IIf( lRemove , " 0", " 1" )

   cItemDef := SUBSTR( cItemDef, 1, StrAtNum( "|", cItemDef, 3 ) ) + " " + ;
               cWert + ;
               SUBSTR( cItemDef, StrAtNum( "|", cItemDef, 4 ) )

   SetDataArea( "Items", AllTrim(STR(i,5)), cItemDef, cAreaIni )

   if lRemove
      oER:aItems[nArea,i]:lDrag := .F.
      oER:aItems[nArea,i]:HideDots()
      oER:aItems[nArea,i]:End()
   ELSE
      ShowItem( i, nArea, cAreaIni, @aFirst, @nElemente )
      oER:aItems[nArea,i]:lDrag := .T.
   endif

   if !lFromUndoRedo
      Add2Undo( cOldDef, i, nArea )
   endif

   SetSave( .F. )

return .T.

//------------------------------------------------------------------------------

function CopyAllItemsToArea( nOldArea, nNewArea )

   local i, cDef
   local nLen := LEN( oER:aItems[nOldArea] )
   LOCAL cOldArea := GetNameArea(nOldArea)
   LOCAL cNewArea := GetNameArea(nNewArea)

   if !MsgYesNo( GL("Copy items?"), GL("Select an option") )
      return (.F.)
   endif
   FOR i := 1 TO nLen
      cDef :=  GetItemDef( i, cOldArea  )
      if !EMPTY( cDef )
         SetDataArea( "Items",  AllTrim(Str(i,5)), cDef, cNewArea )
      endif
   NEXT

return .T.

//----------------------------------------------------------------------------//

FUNCTION GetItemDef( nItem, cAreaIni )
 RETURN  GetDataArea( "Items", AllTrim(STR(nItem,5)),"", cAreaIni )

//------------------------------------------------------------------------------

FUNCTION GetDataArea( cSection, cData,cDefault, cAreaIni )
LOCAL cText

IF oER:lNewFormat
     cText:= AllTrim( GetPvProfString(  cAreaIni+cSection , cData , cDefault,  oER:cDefIni ) )
   ELSE
     cText:= AllTrim( GetPvProfString( cSection , cData , cDefault,  cAreaIni ) )
   ENDIF

RETURN cText

//------------------------------------------------------------------------------

FUNCTION SetDataArea( cSection, cItem, cItemDef, cAreaIni )
   Local oIni


   IF oEr:lNewFormat
       INI oIni FILE oEr:cDefIni
           SET SECTION cAreaIni+cSection ENTRY cItem TO cItemDef OF oIni
       ENDINI
   else

      INI oIni FILE cAreaIni
          SET SECTION cSection ENTRY cItem TO cItemDef OF oIni
      ENDINI
   endif

RETURN nil

//------------------------------------------------------------------------------

FUNCTION DelEntryArea( cSection, cItem, cAreaIni )

   IF oEr:lNewFormat
      DelIniEntry( cAreaIni + cSection , cItem,  oEr:cDefIni )
   ELSE
      DelIniEntry( cSection, cItem, cAreaIni )
   endif



Return nil

//------------------------------------------------------------------------------

FUNCTION GetaItemProp( nItem, cAreaIni )
RETURN hb_atokens( GetItemDef( nItem, cAreaIni ) , "|" )

//------------------------------------------------------------------------------

function DeleteAllItems( nTyp )

   local i, cTyp, cDef, oItem
   local nLen := LEN( oER:aItems[oER:nAktArea] )

   if MsgYesNo( GL("Remove items?"), GL("Select an option") ) = .F.
      return (.F.)
   endif

   FOR i := 1 TO nLen

      cDef :=  GetItemDef( i, oER:aItems[oER:nAktArea]  )

      if !EMPTY( cDef )

         cTyp := UPPER(AllTrim( GetField( cDef, 1 ) ))

        if nTyp = 1 .AND. cTyp = "TEXT"     .OR. ;
           nTyp = 2 .AND. cTyp = "IMAGE"    .OR. ;
           nTyp = 3 .AND. IsGraphic( cTyp ) .OR. ;
           nTyp = 4 .AND. cTyp = "BARCODE"

            IF VAL( GetField( cDef, 4 ) ) != 0
               DeleteItem( i, oER:nAktArea, .T., .T. )
            endif

         endif

      endif

   NEXT

return .T.

//----------------------------------------------------------------------------//

function DelItemWithKey( nItem, nArea )
   LOCAL cAreaIni := GetNameArea(nArea)
   local cItemDef

   cItemDef  :=  GetItemDef( nItem, cAreaIni )
   DeleteItem( nItem, nArea, .T. )
   IF VAL( GetField( cItemDef, 3 ) ) < 0
      DelEntryArea( "Items",  AllTrim(STR(nItem,5) ), cAreaIni )
   endif
   nAktItem := 0
   RefreshPanelTree()

return .T.

//----------------------------------------------------------------------------//

function swichItemsArea( nArea, lDisable )
   LOCAL nLen:= Len(oER:aItems[nArea])
   LOCAL  i
   DEFAULT lDisable:= .t.

   IF nLen>0

      FOR i=1 TO nLen
          IF  !Empty(oER:aItems[nArea, i ])
            IF ldisable
                  oER:aItems[nArea, i ]:disable()
                 else
                 oER:aItems[nArea, i ]:enable()
               ENDIF
         endif
      next
    endif

RETURN nil

//----------------------------------------------------------------------------//

function ItemPopupMenu( oItem, nItem, nArea, nRow, nCol )

   local oMenu
   LOCAL cItemDef  := AllTrim( GetDataArea(  "Items",  AllTrim(STR(nItem,5)),, oER:aAreaIni[nArea] ))
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
      WHEN !EMPTY( cItemCopy )

   ENDMENU

   nRow += oItem:nTop
   nCol += oItem:nLeft

   ACTIVATE POPUP oMenu OF oER:aWnd[nArea] AT nRow, nCol

return .T.

//----------------------------------------------------------------------------//

function ItemProperties( i, nArea, lFromList, lNew )

   local cOldDef, cItemDef, cTyp, cName
   local cAreaIni := oER:aAreaIni[nArea]

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

   cOldDef := GetItemDef( i, cAreaIni  )
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

   cItemDef := GetItemDef( i, cAreaIni  )

   cName := AllTrim( GetField( cItemDef, 2 ) )

   if UPPER( cTyp ) == "IMAGE" .AND. EMPTY( cName )
      cName := AllTrim( GetField( cItemDef, 11 ) )
   ENDIF
   cName := AllTrim(STR(i,5)) + ". " + cName


   Memory(-1)
   SysRefresh()


return ( cName )

//----------------------------------------------------------------------------//

function MultiItemProperties()

   local oDlg, aCbx[1], aGrp[1]
   local cItemDef  := AllTrim( GetDataArea( "Items", AllTrim(STR( oER:aSelection[1,2], 5 )), ;
                      "", oER:aAreaIni[ oER:aSelection[1,1] ] ) )
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

   if nValue == aOldValue[ nTyp ]
       RETURN .T.
   endif

   /*

   do case
   case nTyp = 1 .AND. nValue = aOldValue[1] ; lStop := .T.
   case nTyp = 2 .AND. nValue = aOldValue[2] ; lStop := .T.
   case nTyp = 3 .AND. nValue = aOldValue[3] ; lStop := .T.
   case nTyp = 4 .AND. nValue = aOldValue[4] ; lStop := .T.
   endcase

   if lStop
      return( .T. )
   endif

    */

   UnSelectAll( .F. )

   FOR i := 1 TO LEN( oER:aSelection )

      aWerte  := GetCoors( oER:aItems[ oER:aSelection[i,1], oER:aSelection[i,2] ]:hWnd )
      nTop    := aWerte[1]
      nLeft   := aWerte[2]
      nHeight := aWerte[3] - aWerte[1]
      nWidth  := aWerte[4] - aWerte[2]

      do case
      case nTyp = 1 ; IIF( lAddValue, nTop    += nPixValue, nTop    := oEr:nRulerTop + nPixValue )
      case nTyp = 2 ; IIF( lAddValue, nLeft   += nPixValue, nLeft   := oER:nRuler    + nPixValue )
      case nTyp = 3 ; IIF( lAddValue, nWidth  += nPixValue, nWidth  := nPixValue )
      case nTyp = 4 ; IIF( lAddValue, nHeight += nPixValue, nHeight := nPixValue )
      endcase

      aOldValue[nTyp] := nValue

      oER:aItems[ oER:aSelection[i,1], oER:aSelection[i,2]] :Move( nTop, nLeft, nWidth, nHeight, .T. ) //, .T. )

      oER:aItems[ oER:aSelection[i,1], oER:aSelection[i,2] ]:Refresh()

   NEXT

   UnSelectAll( .F. )

   return .T.

//------------------------------------------------------------------------------

 function MultiItemsAligh( nTyp )
    LOCAL cItemDef
    LOCAL nTop, nLeft, nWidth, nHeight
    local aOldValue

    IF Len( oER:aSelection ) == 0
       RETURN nil
    ENDIF

    cItemDef  := AllTrim( GetDataArea( "Items", AllTrim(STR( oER:aSelection[1,2], 5 )), ;
                      "", oER:aAreaIni[ oER:aSelection[1,1] ] ) )
    nTop      := VAL( GetField( cItemDef, 7 ) )
    nLeft     := VAL( GetField( cItemDef, 8 ) )
    nWidth    := VAL( GetField( cItemDef, 9 ) )
    nHeight   := VAL( GetField( cItemDef, 10 ) )
    aOldValue := { 0, 0, 0, 0 }

   IF nTyp == 1
      nValue:= nTop
   ELSEIF nTyp == 2
      nValue:= nLeft
   ELSEIF nTyp == 3
      nValue:= nWidth
   ELSEIF nTyp == 4
       nValue:= nHeight
    ENDIF


   UpdateItems( nValue , nTyp, .f., @aOldValue )

return .T.


//------------------------------------------------------------------------------

FUNCTION GetItemProperties( nItem, cAreaIni )

   LOCAL aItemProp := Array(7)
   local oItem := VRDItem():New( GetItemDef( nItem, cAreaIni ) )

   LOCAL cType   := UPPER(ALLTRIM( oItem:cType ))

    aItemProp[1] := { GL( "Title" ) , oItem:cText }
    aItemProp[2] := { GL( "ItemID" ), oItem:nItemID }
    aItemProp[3] := { GL( "Show" )  , oItem:nShow }
    aItemProp[4] := { GL( "Top" )   , oItem:nTop }
    aItemProp[5] := { GL( "Left" )  , oItem:nLeft }
    aItemProp[6] := { GL( "Width" ) , oItem:nWidth }
    aItemProp[7] := { GL( "Height" ), oItem:nHeight }

 RETURN aItemProp

//------------------------------------------------------------------------------

FUNCTION SetPropItem( nItem, cAreaIni, cNewValue )
   LOCAL cItemDef
   local oItem := VRDItem():New( GetItemDef( nItem, cAreaIni ) )
   LOCAL nReg:= oER:oBrwProp:nArrayAt
   LOCAL nArea := getNumArea( cAreaIni )

    DO CASE
        CASE nReg == 1
           oItem:cText := cNewValue
        CASE nReg == 2
           oItem:nItemID := cNewValue
        CASE nReg == 3
           oItem:nShow := cNewValue
        CASE nReg == 4
           oItem:nTop := cNewValue
        CASE nReg == 5
            oItem:nLeft := cNewValue
        CASE nReg == 6
            oItem:nWidth := cNewValue
        CASE nReg == 7
            oItem:nHeight := cNewValue
    ENDCASE

    cItemDef := oItem:Set( .f., oER:nMeasure )
    SetDataArea( "Items", AllTrim(Str(nItem,5)), cItemDef, cAreaIni )

   IF oItem:cType == "TEXT"
      SetTextObj( oItem, nArea, nItem )
   ELSEIF  oItem:cType == "IMAGE"
      SetImgObj( oItem, nArea, nItem )
   ELSEIF  oItem:lGraphic
      SetGraObj( oItem, nArea, nItem )
   ELSEIF oItem:cType = "BARCODE"
      SetBarcodeItem( oItem, nArea, nItem )
   endif

RETURN nil

//------------------------------------------------------------------------------

FUNCTION RefreshBrwProp( i , cAreaIni )
   LOCAL aProps:=GetItemProperties( i, cAreaIni )
   oER:oBrwProp:Cargo:= {"item",cAreaIni, i }
   oER:oBrwProp:setArray(aProps)
   oER:oBrwProp:refresh(.t.)
   oER:oSaySelectedItem:setText( aProps[1,2] )
Return nil

//----------------------------------------------------------------------------//

function TextProperties( i, nArea, cAreaIni, lFromList, lNew )

   local nColor
   local aCbx[5], aGrp[3], aGet[5], aSay[4]
   local nDefClr, oBtn, oBtn2, oBtn3
 //  local oVar  := GetoVar( i, nArea, cAreaIni, lNew )
   LOCAL hVar  := GetohVar( i, nArea, cAreaIni, lNew )

   local oItem := VRDItem():New( hVar["cItemDef"] )

   /*
  local oItem := VRDItem():New( oVar:cItemDef )
  */

   hVar[ "aOrient" ] := { GL("Left"), GL("Center"), GL("Right"), GL("Flush justified"), GL("Line-makeup") }
   hVar[ "cOrient" ]:=  hVar["aOrient"][ IIF( oItem:nOrient = 0, 1, oItem:nOrient ) ]
   hVar[ "aColors" ]:= GetAllColors()
   hVar[ "aBitmaps"]:= { "ALIGN_LEFT", "ALIGN_CENTER", "ALIGN_RIGHT", "ALIGN_BLOCK", "ALIGN_WRAP" }

 /*
   oVar:AddMember( "aOrient"    ,, { GL("Left"), GL("Center"), GL("Right"), ;
                                     GL("Flush justified"), GL("Line-makeup") } )
   oVar:AddMember( "cOrient"    ,, oVar:aOrient[ IIF( oItem:nOrient = 0, 1, oItem:nOrient ) ]                )
   oVar:AddMember( "aColors"    ,, GetAllColors()                                                          )
   oVar:AddMember( "aBitmaps"   ,, { "ALIGN_LEFT", "ALIGN_CENTER", "ALIGN_RIGHT", ;
                                   "ALIGN_BLOCK", "ALIGN_WRAP" } )
  */

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


   REDEFINE GET oItem:nTop      ID 301 OF oCurDlg PICTURE hVar["cPicture"] ;
      SPINNER MIN 0 MAX hVar["nGesHeight"] - oItem:nHeight ;
      VALID oItem:nTop >= 0 .AND. oItem:nTop + oItem:nHeight <= hVar["nGesHeight"]

   REDEFINE GET oItem:nLeft     ID 302 OF oCurDlg PICTURE hVar["cPicture"] ;
      SPINNER MIN 0 MAX hVar["nGesWidth"] - oItem:nWidth ;
      VALID oItem:nLeft >= 0 .AND. oItem:nLeft + oItem:nWidth <= hVar["nGesWidth"]

   REDEFINE GET oItem:nWidth    ID 303 OF oCurDlg PICTURE hVar["cPicture"] ;
      SPINNER MIN 0.01 MAX hVar["nGesWidth"] - oItem:nLeft ;
      VALID oItem:nWidth > 0 .AND. oItem:nLeft + oItem:nWidth <= hVar["nGesWidth"]

   REDEFINE GET oItem:nHeight   ID 304 OF oCurDlg PICTURE hVar["cPicture"] ;
      SPINNER MIN 0.01 MAX hVar["nGesHeight"] - oItem:nTop ;
      VALID oItem:nHeight > 0 .AND. oItem:nTop + oItem:nHeight <= hVar["nGesHeight"]

   REDEFINE COMBOBOX hVar["cOrient"] ITEMS hVar["aOrient"] BITMAPS hVar["aBitmaps"] ID 305 OF oCurDlg

   REDEFINE CHECKBOX aCbx[3] VAR oItem:lVisible    ID 306 OF oCurDlg WHEN oItem:nDelete <> 0
   REDEFINE CHECKBOX aCbx[4] VAR oItem:lMultiLine  ID 307 OF oCurDlg
   REDEFINE CHECKBOX aCbx[5] VAR oItem:lVariHeight ID 308 OF oCurDlg

   REDEFINE GET aGet[1] VAR oItem:nColText ID 501 OF oCurDlg PICTURE "9999" SPINNER MIN 1 MAX 30 ;
      ON CHANGE Set2Color( aSay[1], IIF( oItem:nColText > 0, hVar["aColors"][oItem:nColText], ""), nDefClr ) ;
      VALID     Set2Color( aSay[1], IIF( oItem:nColText > 0, hVar["aColors"][oItem:nColText], ""), nDefClr )

   REDEFINE GET aGet[2] VAR oItem:nColPane ID 502 OF oCurDlg PICTURE "9999" SPINNER MIN 1 MAX 30 ;
      ON CHANGE Set2Color( aSay[2], IIF( oItem:nColPane > 0,  hVar["aColors"][oItem:nColPane], ""), nDefClr ) ;
      VALID     Set2Color( aSay[2], IIF( oItem:nColPane > 0,  hVar["aColors"][oItem:nColPane], ""), nDefClr ) ;
      WHEN oItem:lTrans = .F.

   REDEFINE GET aGet[3] VAR oItem:nFont    ID 503 OF oCurDlg PICTURE "9999" SPINNER MIN 1 MAX 20 ;
      ON CHANGE aSay[3]:Refresh() ;
      VALID     ( aSay[3]:Refresh(), .T. )

   REDEFINE CHECKBOX aCbx[1] VAR oItem:lBorder ID 601 OF oCurDlg
   REDEFINE CHECKBOX aCbx[2] VAR oItem:lTrans  ID 602 OF oCurDlg

   REDEFINE BTNBMP aSay[1] PROMPT "" ID 401 OF oCurDlg NOBORDER ;
   ACTION GetHColorBtn( @oItem:nColText , aSay[1], aGet[1], hVar, nDefClr )
   aSay[1]:lBoxSelect := .f.
   aSay[1]:SetColor( oER:GetColor( oItem:nColText ), oER:GetColor( oItem:nColText ) )

   REDEFINE BTNBMP aSay[2] PROMPT "" ID 402 OF oCurDlg NOBORDER ;
     ACTION GetHColorBtn( @oItem:nColPane , aSay[2], aGet[2], hVar, nDefClr )
     aSay[2]:SetColor(  oER:GetColor( oItem:nColPane ), oER:GetColor( oItem:nColPane ) )
     aSay[2]:lBoxSelect := .f.

   REDEFINE SAY aSay[3] PROMPT ;
      IIF( oItem:nFont > 0, " " + GetCurrentFont( oItem:nFont, GetFonts(), 1 ), "" ) ;
      ID 403 OF oCurDlg

   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 151 OF oCurDlg ;
      ACTION GetHColorBtn(  @oItem:nColText, aSay[1], aGet[1], hVar, nDefClr )

   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 152 OF oCurDlg ;
      ACTION GetHColorBtn( @oItem:nColPane, aSay[2], aGet[2], hVar, nDefClr )

   REDEFINE BTNBMP RESOURCE "SELECT" TRANSPARENT NOBORDER ID 153 OF oCurDlg ;
      ACTION ( oItem:nFont := ShowFontChoice( oItem:nFont ), aGet[3]:Refresh(), aSay[3]:Refresh() )

   REDEFINE BUTTON PROMPT GL("&OK")     ID 101 OF oCurDlg ;
      ACTION ( oGenVar:lDlgSave := .T., oGenVar:lItemDlg := .F., oCurDlg:End() )

   REDEFINE BUTTON PROMPT GL("&Cancel") ID 102 OF oCurDlg ;
      ACTION ( oGenVar:lItemDlg := .F., oCurDlg:End() )

   REDEFINE BUTTON oBtn PROMPT GL("&Remove Item") ID 103 OF oCurDlg ;
      ACTION ( hVar["lRemoveItem"] := .T., oItem:lVisible := .F., ;
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

   REDEFINE BUTTON PROMPT GL("&Set") ID 104 OF oCurDlg ACTION SaveHTextItem( hVar, oItem )

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

   REDEFINE SAY PROMPT oER:cMeasure ID 181 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 182 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 183 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 184 OF oCurDlg

   ACTIVATE DIALOG oCurDlg CENTERED ; // NOMODAL ;
      ON INIT ( GetItemDlgPos(), ;
                IIF( oER:nDeveloper = 0, ( aGet[5]:Hide(), aSay[4]:Hide(), aGet[4]:nWidth( 329 ), oBtn2:nLeft := 352, oBtn3:nLeft := 374 ), ), ;
                IIF( hVar["cShowExpr"] = "0" .OR. lProfi = .F., oBtn3:Hide(), ), ;
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
      VALID ( IIF( oGenVar:lDlgSave, SaveHTextItem( hVar, oItem ), oGenVar:lItemDlg := .F. ), ;
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

Function GethColorBtn( cColorItem , oSay, oGet, hVar, nDefClr )
local nColor := ShowColorChoice( cColorItem )
      IF  nColor <> 0
         cColorItem := nColor
         oGet:Refresh()
         Set2Color( oSay, IIF( cColorItem > 0, hVar["aColors"][cColorItem], ""), nDefClr )
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

   oVar:AddMember( "cItemDef"   ,, AllTrim( GetDataArea( "Items", AllTrim(STR(i,5)) , "", cAreaIni ) ) )
   oVar:AddMember( "i"          ,, i                                                                       )
   oVar:AddMember( "nArea"      ,, nArea                                                                   )
   oVar:AddMember( "cAreaIni"   ,, cAreaIni                                                                )
   oVar:AddMember( "cOldDef"    ,, oVar:cItemDef                                                           )
   oVar:AddMember( "lNew"       ,, lNew                                                                    )
   oVar:AddMember( "lRemoveItem",, .F.                                                                     )
   oVar:AddMember( "cShowExpr"  ,, AllTrim( oER:GetDefIni( "General", "Expressions", "0" ) )    )
   oVar:AddMember( "nGesWidth"  ,, VAL( GetDataArea( "General", "Width", "600", cAreaIni ) )           )
   oVar:AddMember( "nGesHeight" ,, VAL( GetDataArea( "General", "Height", "300", cAreaIni ) )          )
   oVar:AddMember( "cPicture"   ,, IIF( oER:nMeasure = 2, "999.99", "99999" )                                  )

return ( oVar )

//----------------------------------------------------------------------------//

function GetohVar( i, nArea, cAreaIni, lNew )

   local hVar :=  { => }

   hVar[ "cItemDef" ]:= GetItemDef( i, cAreaIni )
   hVar[ "i" ]       := i
   hVar[ "nArea" ]   := nArea
   hVar[ "cAreaIni" ]:= cAreaIni
   hVar[ "cOldDef" ] := hVar["cItemDef"]
   hVar[ "lNew" ]    := lNew
   hVar[ "lRemoveItem" ] := .F.
   hVar[ "cShowExpr" ] := AllTrim( oER:GetDefIni( "General", "Expressions", "0" ) )
   hVar[ "nGesWidth" ] := VAL( GetDataArea( "General", "Width", "600", cAreaIni ) )
   hVar[ "nGesHeight"] := VAL( GetDataArea( "General", "Height", "300", cAreaIni ) )
   hVar[ "cPicture" ] := IIF( oER:nMeasure = 2, "999.99", "99999" )

return ( hVar )


//----------------------------------------------------------------------------//

function SaveHTextItem( hVar, oItem )

   local lRight, lCenter, nColor, oFont
   LOCAL nArea := hVar["nArea"]
   LOCAL i :=  hVar["i"]

   oItem:nOrient := ASCAN( hVar["aOrient"], hVar["cOrient"] )
   oItem:nBorder := IIF( oItem:lBorder , 1, 0 )
   oItem:nTrans  := IIF( oItem:lTrans  , 1, 0 )
   oItem:nShow   := IIF( oItem:lVisible, 1, 0 )

   hVar["cItemDef"] := oItem:Set( .F., oER:nMeasure )

   SetDataArea( "Items", AllTrim(STR(i,5)), hVar["cItemDef"],  hVar["cAreaIni"] )

   SetTextObj( oItem, nArea, i )

   if hVar["lRemoveItem"]
      DelEntryArea( "Items", AllTrim(STR(i,5)), hVar["cAreaIni"] )
   endif

   SetSave( .F. )

   if hVar["lNew"]
      Add2Undo( "", i, nArea )
   ELSEif hVar["cOldDef"] != hVar["cItemDef"]
      Add2Undo( hVar["cOldDef"], i, nArea )
   endif

   oCurDlg:SetFocus()

   return ( .T. )

//------------------------------------------------------------------------------

FUNCTION SetTextObj( oItem, nArea, i )

   LOCAL oFont := IIF( oItem:nFont = 0, oEr:oAppFont, oER:aFonts[oItem:nFont] )
   LOCAL lCenter := IIF( oItem:nOrient = 2, .T., .F. )
   LOCAL lRight  := IIF( oItem:nOrient = 3,  .T., .F. )

   if oItem:lVisible

      if !Empty(  oER:aItems[nArea,i])
         // añadido por si es nil
         oER:aItems[nArea,i]:HideDots()
         oER:aItems[nArea,i]:End()
         sysrefresh()
         oER:aItems[nArea,i] := ;
         TSay():New( oEr:nRulerTop + ER_GetPixel( oItem:nTop ), oER:nRuler + ER_GetPixel( oItem:nLeft ), ;
                     {|| oItem:cText }, oER:aWnd[ nArea ],, ;
                     oFont, lCenter, lRight, ( oItem:lBorder .OR. oGenVar:lShowBorder ), ;
                     .T., oER:GetColor( oItem:nColText ), oER:GetColor( oItem:nColPane ), ;
                     ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ), ;
                     .F., .T., .F., .F., .F. )

         oER:aItems[nArea,i]:lDrag := .T.

        ElementActions( oER:aItems[nArea,i], i, oItem:cText, nArea , GetNameArea(nArea) )

        oER:aItems[nArea,i]:SetFocus()

     endif
   endif


   if !oItem:lVisible .AND. oER:aItems[nArea,i] <> NIL
      oER:aItems[nArea,i]:lDrag := .F.
      oER:aItems[nArea,i]:HideDots()
      oER:aItems[nArea,i]:End()
   endif

 RETURN nil

//------------------------------------------------------------------------------
/*
function SaveTextItem( oVar, oItem )

   local lRight, lCenter, nColor, oFont, oIni
   LOCAL nArea := oVar:nArea
   LOCAL i :=  oVar:i

   oItem:nOrient := ASCAN( oVar:aOrient, oVar:cOrient )
   oItem:nBorder := IIF( oItem:lBorder , 1, 0 )
   oItem:nTrans  := IIF( oItem:lTrans  , 1, 0 )
   oItem:nShow   := IIF( oItem:lVisible, 1, 0 )

   oVar:cItemDef := oItem:Set( .F., oER:nMeasure )

   INI oIni FILE oVar:cAreaIni
      SET SECTION "Items" ENTRY AllTrim(STR(oVar:i,5)) TO oVar:cItemDef OF oIni
   ENDINI

   oFont := IIF( oItem:nFont = 0, oEr:oAppFont, oER:aFonts[oItem:nFont] )
   lCenter := IIF( oItem:nOrient = 2, .T., .F. )
   lRight  := IIF( oItem:nOrient = 3,  .T., .F. )

   if oItem:lVisible

      oER:aItems[oVar:nArea,oVar:i]:End()
      oER:aItems[oVar:nArea,oVar:i] := ;
         TSay():New( oEr:nRulerTop + ER_GetPixel( oItem:nTop ), oER:nRuler + ER_GetPixel( oItem:nLeft ), ;
                     {|| oItem:cText }, oER:aWnd[oVar:nArea],, ;
                     oFont, lCenter, lRight, ( oItem:lBorder .OR. oGenVar:lShowBorder ), ;
                     .T., oER:GetColor( oItem:nColText ), oER:GetColor( oItem:nColPane ), ;
                     ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ), ;
                     .F., .T., .F., .F., .F. )

      oER:aItems[oVar:nArea,oVar:i]:lDrag := .T.
      ElementActions( oER:aItems[oVar:nArea,oVar:i], oVar:i, oItem:cText, oVar:nArea, oVar:cAreaIni )
      oER:aItems[oVar:nArea,oVar:i]:SetFocus()

   endif

   // Diese Funktion darf nicht aufgerufen werden, weil beim Sprung von einem
   // Textelement zu einem Bildelement ein Fehler generiert wird.
   // Der Funktionsinhalt muß direkt angehängt werden.
   //SaveItemGeneral( oVar, oItem )

   if !oItem:lVisible .AND. oER:aItems[oVar:nArea,oVar:i] <> NIL
      oER:aItems[oVar:nArea,oVar:i]:lDrag := .F.
      oER:aItems[oVar:nArea,oVar:i]:HideDots()
      oER:aItems[oVar:nArea,oVar:i]:End()
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
*/
//----------------------------------------------------------------------------//

function SaveItemGeneral( oVar, oItem )

   LOCAL xItem := oER:aItems[oVar:nArea,oVar:i]

   if !oItem:lVisible .AND. !Empty( xItem )
      xItem:lDrag := .F.
      xItem:HideDots()
      xItem:End()
   endif

  /*
   if !oItem:lVisible .AND. aItems[oVar:nArea,oVar:i] <> NIL
      aItems[oVar:nArea,oVar:i]:lDrag := .F.
      aItems[oVar:nArea,oVar:i]:HideDots()
      aItems[oVar:nArea,oVar:i]:End()
   endif
  */

   if oVar:lRemoveItem
      DelEntryArea("Items", AllTrim(STR(oVar:i,5)), oVar:cAreaIni )
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

   local aBtn[3], oCbx1, oCbx2, aGet[3], aSay[1], aGrp[2], aSizeSay[2]
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

   REDEFINE SAY PROMPT oER:cMeasure ID 120 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 121 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 122 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 123 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 125 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 126 OF oCurDlg

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
                IIF( oER:nDeveloper = 0, ( aGet[3]:Hide(), aSay[1]:Hide(), aGet[2]:nWidth( 328 ) ), ), ;
                IIF( lFromList .OR. oItem:nItemID > 0, aBtn[1]:Hide(), ), ;
                IIF( oVar:cShowExpr = "0" .OR. !lProfi, aBtn[3]:Hide(), ), ;
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

   oItem:nBorder := IIF( oItem:lBorder , 1, 0 )
   oItem:nShow   := IIF( oItem:lVisible, 1, 0 )

   oVar:cItemDef := oItem:Set( .F., oER:nMeasure )

   SetDataArea( "Items", AllTrim(STR(oVar:i,5)), oVar:cItemDef, oVar:cAreaIni )

   SetImgObj( oItem, oVar:nArea, oVar:i )
 /*
   if oItem:nShow = 1

      oER:aItems[oVar:nArea,oVar:i]:End()
      oER:aItems[oVar:nArea,oVar:i] := TImage():New( oEr:nRulerTop + ER_GetPixel( oItem:nTop ), ;
         oER:nRuler + ER_GetPixel( oItem:nLeft ), ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ),,, ;
         IIF( oItem:lBorder, .F., .T. ), oER:aWnd[oVar:nArea],,, .F., .T.,,, .T.,, .T. )
      oER:aItems[oVar:nArea,oVar:i]:Progress(.F.)
      oER:aItems[oVar:nArea,oVar:i]:LoadBmp( VRD_LF2SF( oItem:cFile ) )

      oER:aItems[oVar:nArea,oVar:i]:lDrag := .T.
      ElementActions( oER:aItems[oVar:nArea,oVar:i], oVar:i, oItem:cText, oVar:nArea, oVar:cAreaIni )
      oER:aItems[oVar:nArea,oVar:i]:SetFocus()

   endif
   */

   SaveItemGeneral( oVar, oItem )

return .T.

//------------------------------------------------------------------------------

FUNCTION SetImgObj( oItem, nArea, i )

   if oItem:nShow = 1
      if !Empty(  oER:aItems[nArea,i])
         oER:aItems[nArea,i]:End()
      ENDIF


      oER:aItems[nArea,i] := TImage():New( oEr:nRulerTop + ER_GetPixel( oItem:nTop ), ;
         oER:nRuler + ER_GetPixel( oItem:nLeft ), ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ),,, ;
         IIF( oItem:lBorder, .F., .T. ), oER:aWnd[nArea],,, .F., .T.,,, .T.,, .T. )
      oER:aItems[nArea,i]:Progress(.F.)
      oER:aItems[nArea,i]:LoadBmp( VRD_LF2SF( oItem:cFile ) )

      oER:aItems[nArea,i]:lDrag := .T.


      ElementActions( oER:aItems[nArea,i], i, oItem:cText, nArea, GetNameArea(nArea) )
      oER:aItems[nArea,i]:SetFocus()

   endif

RETURN nil

//----------------------------------------------------------------------------//

function GraphicProperties( i, nArea, cAreaIni, lFromList, lNew )

   local oBtn, oCmb1, aCbx[2], nColor, nDefClr
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

   REDEFINE SAY PROMPT oER:cMeasure ID 120 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 121 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 122 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 123 OF oCurDlg

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

   REDEFINE SAY aSay[1] PROMPT "" ID 401 OF oCurDlg COLORS oER:GetColor( oItem:nColText ), oER:GetColor( oItem:nColText )
   REDEFINE SAY aSay[2] PROMPT "" ID 402 OF oCurDlg COLORS oER:GetColor( oItem:nColPane ), oER:GetColor( oItem:nColPane )

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
   REDEFINE SAY PROMPT oER:cMeasure ID 180 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 181 OF oCurDlg
   REDEFINE SAY PROMPT GL("Width:")      ID 182 OF oCurDlg
   REDEFINE SAY PROMPT GL("Height:")     ID 183 OF oCurDlg
   REDEFINE SAY PROMPT GL("Rounded Corners") + ":" ID 184 OF oCurDlg

   ACTIVATE DIALOG oCurDlg CENTERED ; // NOMODAL ;
      ON INIT ( GetItemDlgPos(), ;
                IIF( oER:nDeveloper = 0, EVAL( {|| aGet[3]:Hide(), aSay[3]:Hide() }), ), ;
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

   oItem:cType  := GetGraphName( ASCAN( oVar:aGraphic, oVar:cGraphic ) )
   oItem:cText  := oVar:cGraphic
   oItem:nStyle := VAL( oVar:cStyle )
   oItem:nTrans := IIF( oItem:lTrans, 1, 0 )

   oVar:cItemDef := oItem:Set( .F., oER:nMeasure )

   SetDataArea( "Items", AllTrim(STR(oVar:i,5)), oVar:cItemDef, oVar:cAreaIni )

   SetGraObj( oItem, oVar:nArea, oVar:i )

   SaveItemGeneral( oVar, oItem )

return .T.


//------------------------------------------------------------------------------

FUNCTION SetGraObj( oItem, nArea, i )

  if oItem:nShow = 1

          IF !Empty(  oER:aItems[nArea,i])
         oER:aItems[nArea,i]:End()
      endif

      oER:aItems[nArea,i] := TBitmap():New( oEr:nRulerTop + ER_GetPixel( oItem:nTop ), ;
          oER:nRuler + ER_GetPixel( oItem:nLeft ), ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ), ;
          "GRAPHIC",, .T., oER:aWnd[nArea],,, .F., .T.,,, .T.,, .T. )
      oER:aItems[nArea,i]:lTransparent := .T.

      oER:aItems[nArea,i]:bPainted = {| hDC, cPS | ;
         DrawGraphic( hDC, AllTrim(UPPER( oItem:cType )), ;
                      ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ), ;
                      oER:GetColor( oItem:nColor ), oER:GetColor( oItem:nColFill ), ;
                      oItem:nStyle, oItem:nPenWidth, ;
                      ER_GetPixel( oItem:nRndWidth ), ER_GetPixel( oItem:nRndHeight ) ) }

      oER:aItems[nArea,i]:lDrag := .T.
      ElementActions( oER:aItems[nArea,i], i, "", nArea, GetNameArea(nArea) )
      oER:aItems[nArea,i]:SetFocus()

  endif


RETURN nil

//----------------------------------------------------------------------------/

function BarcodeProperties( i, nArea, cAreaIni, lFromList, lNew )

   local oFont, lRight, lCenter, nColor
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

   REDEFINE SAY aSay[1] PROMPT "" ID 401 OF oCurDlg COLORS oER:GetColor( oItem:nColText ), oER:GetColor( oItem:nColText )
   REDEFINE SAY aSay[2] PROMPT "" ID 402 OF oCurDlg COLORS oER:GetColor( oItem:nColPane ), oER:GetColor( oItem:nColPane )

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

   REDEFINE SAY PROMPT oER:cMeasure ID 181 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 182 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 183 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 184 OF oCurDlg
   REDEFINE SAY PROMPT oER:cMeasure ID 185 OF oCurDlg

   ACTIVATE DIALOG oCurDlg CENTERED ; // NOMODAL ;
      ON INIT ( GetItemDlgPos(), ;
                IIF( oER:nDeveloper == 0, ( aGet[5]:Hide(), aSay[4]:Hide() ), ), ;
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

   local lRight, lCenter, nColor

   oItem:nBCodeType := ASCAN( oVar:aBarcode, oVar:cBarcode )
   oItem:nOrient    := ASCAN( oVar:aOrient, oVar:cOrient )

   oVar:cItemDef := oItem:Set( .F., oER:nMeasure )

   SetDataArea( "Items", AllTrim(STR(oVar:i,5)), oVar:cItemDef, oVar:cAreaIni )

   lCenter := IIF( oItem:nOrient == 2, .T., .F. )
   lRight  := IIF( oItem:nOrient == 3, .T., .F. )

   SetBarcodeItem( oItem, oVar:nArea, oVar:i )

   SaveItemGeneral( oVar, oItem )

   return .T.

//------------------------------------------------------------------------------

FUNCTION SetBarcodeItem( oItem, nArea, i )

     if oItem:nShow = 1

      oER:aItems[nArea,i]:End()

         oER:aItems[nArea,i] := TBitmap():New( oEr:nRulerTop + ER_GetPixel( oItem:nTop ), ;
             oER:nRuler + ER_GetPixel( oItem:nLeft ), ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ), ;
             "GRAPHIC",, .T., oER:aWnd[nArea],,, .F., .T.,,, .T.,, .T. )
         oER:aItems[nArea,i]:lTransparent := .T.

         oER:aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawBarcode( hDC, AllTrim( oItem:cText ), 0, 0, ;
                         ER_GetPixel( oItem:nWidth ), ER_GetPixel( oItem:nHeight ), ;
                         oItem:nBCodeType, oER:GetColor( oItem:nColText ), oER:GetColor( oItem:nColPane ), ;
                         oItem:nOrient, oItem:lTrans, ER_GetPixel( oItem:nPinWidth ) ) }

      oER:aItems[nArea,i]:lDrag := .T.
      ElementActions( oER:aItems[nArea,i], i, "", nArea, GetNameArea(nArea) )
      oER:aItems[nArea,i]:SetFocus()

   endif


RETURN nil

//----------------------------------------------------------------------------//

function SetItemSize( i, nArea, cAreaIni )

   local nColor, nColFill, nStyle, nPenWidth, nRndWidth, nRndHeight, oItem
   local cItemDef   := AllTrim( GetDataArea( "Items", AllTrim(STR(i,5)) , "", cAreaIni ) )
   local cOldDef    := cItemDef
   local aWerte     := GetCoors( oER:aItems[nArea,i]:hWnd )
   local nTop       := GetCmInch( aWerte[1] - oEr:nRulerTop )
   local nLeft      := GetCmInch( aWerte[2] - oER:nRuler )
   local nHeight    := GetCmInch( aWerte[3] - aWerte[1] )
   local nWidth     := GetCmInch( aWerte[4] - aWerte[2] )
   local nGesWidth  := VAL( GetDataArea( "General", "Width", "600", cAreaIni ) )
   local nGesHeight := VAL( GetDataArea( "General", "Height", "300", cAreaIni ) )
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

      if IsGraphic( cTyp )

         nColor     := VAL( GetField( cItemDef, 11 ) )
         nColFill   := VAL( GetField( cItemDef, 12 ) )
         nStyle     := VAL( GetField( cItemDef, 13 ) )
         nPenWidth  := VAL( GetField( cItemDef, 14 ) )
         nRndWidth  := VAL( GetField( cItemDef, 15 ) )
         nRndHeight := VAL( GetField( cItemDef, 16 ) )

         oER:aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawGraphic( hDC, cTyp, ;
            ER_GetPixel( nWidth ), ER_GetPixel( nHeight ), ;
            oER:GetColor( nColor ), oER:GetColor( nColFill ), ;
            nStyle, nPenWidth, ER_GetPixel( nRndWidth ), ER_GetPixel( nRndHeight ) ) }

      ELSEif UPPER( cTyp ) = "BARCODE"

         oItem := VRDItem():New( cItemDef )

         oER:aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawBarcode( hDC, oItem:cText, 0, 0, ;
            ER_GetPixel( nWidth ), ER_GetPixel( nHeight ), ;
            oItem:nBCodeType, ;
            oER:GetColor( oItem:nColText ), oER:GetColor( oItem:nColPane ), ;
            oItem:nOrient, IIF( oItem:nTrans = 1, .T., .F. ), ;
            ER_GetPixel( oItem:nPinWidth ) ) }

      endif

      SetDataArea( "Items", AllTrim(STR(i,5)), cItemDef, cAreaIni )

      if VAL( GetField( cItemDef, 7  ) ) <> VAL( GetField( cOldDef, 7  ) ) .OR. ;
         VAL( GetField( cItemDef, 8  ) ) <> VAL( GetField( cOldDef, 8  ) ) .OR. ;
         VAL( GetField( cItemDef, 9  ) ) <> VAL( GetField( cOldDef, 9  ) ) .OR. ;
         VAL( GetField( cItemDef, 10 ) ) <> VAL( GetField( cOldDef, 10 ) )

         if !oER:lFillWindow
            Add2Undo( cOldDef, i, nArea )
            SetSave( .F. )
         endif

      endif

   endif

   oER:lFillWindow := .T.
   oER:aItems[nArea,i]:Move( oEr:nRulerTop + ER_GetPixel( VAL( GetField( cItemDef, 7 ) ) ), ;
      oER:nRuler + ER_GetPixel( VAL( GetField( cItemDef, 8 ) ) ), ;
      ER_GetPixel( VAL( GetField( cItemDef, 9 ) ) ), ;
      ER_GetPixel( VAL( GetField( cItemDef, 10 ) ) ), .T. )
   oER:lFillWindow := .F.

   aItemPosition := { GetField( cItemDef, 7 ), GetField( cItemDef, 8 ), ;
                      GetField( cItemDef, 9 ), GetField( cItemDef, 10 ) }

 //  aItemPixelPos := { ER_GetPixel( VAL( GetField( cItemDef, 7 ) ) ), ;
 //                     ER_GetPixel( VAL( GetField( cItemDef, 8 ) ) ), ;
 //                     ER_GetPixel( VAL( GetField( cItemDef, 9 ) ) ), ;
 //                     ER_GetPixel( VAL( GetField( cItemDef, 10 ) ) ) }

   oER:aItems[nArea,i]:Refresh()

return .T.

//----------------------------------------------------------------------------//

function MsgBarItem( nItem, nArea, cAreaIni, nRow, nCol, lResize )

   local nTop, nLeft
   local cItemDef := AllTrim( GetDataArea( "Items", AllTrim(STR(nItem,5)) , "", cAreaIni ) )
   local cItemID  := AllTrim(  GetField( cItemDef, 3 ) )

   DEFAULT lResize := .F.


   if lResize .AND. LEN( aItemPosition ) <> 0

      oER:oMsgInfo:SetText( GL("ID") + ": " + cItemID + "  " + ;
                        GL("Top:")    + " " + AllTrim( aItemPosition[1] ) + "  " + ;
                        GL("Left:")   + " " + AllTrim( aItemPosition[2] ) + "  " + ;
                        GL("Width:")  + " " + AllTrim( aItemPosition[3] ) + "  " + ;
                        GL("Height:") + " " + AllTrim( aItemPosition[4] ) )

   ELSE
      nInfoRow := 0; nInfoCol := 0 // oEr:nRulerTop := 0; oER:nRuler := 0 // FiveTech

      nTop  := oER:aItems[nArea,nItem]:nTop  + ;
                  ( nLoWord( oER:aItems[nArea,nItem]:nPoint ) - nInfoRow ) - oEr:nRulerTop
      nLeft := oER:aItems[nArea,nItem]:nLeft + ;
                  ( nHiWord( oER:aItems[nArea,nItem]:nPoint ) - nInfoCol ) - oER:nRuler

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
   local cAreaIni := oER:aAreaIni[oER:nAktArea]

   DEFAULT lCut := .F.

   if nAktItem = 0 .AND. LEN( oER:aSelection ) = 0
      MsgStop( GL("Please select an item first."), GL("Stop!") )
      return (.F.)
   endif

   aSelectCopy  := {}
   nCopyEntryNr := 0
   nCopyAreaNr  := 0

   if LEN( oER:aSelection ) <> 0

      //Multiselection
      aSelectCopy := oER:aSelection
      aItemCopy   := {}

      FOR i := 1 TO LEN( oER:aSelection )

         cItemCopy := AllTrim( GetDataArea( "Items", ;
                      AllTrim(STR( oER:aSelection[i,2], 5 )) , "", oER:aAreaIni[ oER:aSelection[i,1] ] ) )
         AADD( aItemCopy, cItemCopy )

         oItemInfo := VRDItem():New( cItemCopy )

         if lCut
            DeleteItem( oER:aSelection[i,2], oER:aSelection[i,1], .T. )
            if oItemInfo:nItemID < 0
               DelEntryArea( "Items", AllTrim(STR(oER:aSelection[i,2],5)), ;
                            oER:aAreaIni[ oER:aSelection[i,1] ] )
            endif
         endif

      NEXT

   ELSE

      cItemCopy    := AllTrim( GetDataArea( "Items", AllTrim(STR(nAktItem,5)), "", cAreaIni ) )
      nCopyEntryNr := nAktItem
      nCopyAreaNr  := oER:nAktArea

      oItemInfo := VRDItem():New( cItemCopy )

      if lCut
         DeleteItem( nAktItem, oER:nAktArea, .T. )
         if oItemInfo:nItemID < 0
            DelEntryArea( "Items", AllTrim(STR(nAktItem,5)), oER:aAreaIni[oER:nAktArea] )
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
         NewItem( "COPY", oER:nAktArea, aSelectCopy[i,1], aSelectCopy[i,2], aItemCopy[i] )
      NEXT
   ELSE
      NewItem( "COPY", oER:nAktArea )
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
   local cAreaIni   := oER:aAreaIni[nArea]
   local nGesWidth  := VAL( GetDataArea( "General", "Width", "600", cAreaIni ) )
   local nGesHeight := VAL( GetDataArea( "General", "Height", "300", cAreaIni ) )
   local cTop       := IIF( oER:nMeasure = 2, "0.10", "2" )
   local cLeft      := cTop

   FOR i := 400 TO 1000
      if oER:aItems[ nArea, i ] = NIL
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
         if oER:aItems[ nArea, i ] = NIL
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

      cDefault := oER:GetDefIni( "General", "Default" + cTyp, "" )

      if !EMPTY( cDefault )
         cItemDef := SUBSTR( cDefault, 1, StrAtNum( "|", cDefault, 2 ) ) + ;
                     SUBSTR( cItemDef, StrAtNum( "|", cItemDef, 2 ) + 1, StrAtNum( "|", cItemDef, 8 ) - StrAtNum( "|", cItemDef, 2 ) ) + ;
                     SUBSTR( cDefault, StrAtNum( "|", cDefault, 8 ) + 1 )
      endif

   endif

   IF oER:lNewFormat
      INI oIni FILE oER:cDefIni
         SET SECTION cAreaIni+"Items" ENTRY AllTrim(STR(nFree,5)) TO cItemDef OF oIni
      ENDINI
   else
      INI oIni FILE cAreaIni
          SET SECTION "Items" ENTRY AllTrim(STR(nFree,5)) TO cItemDef OF oIni
      ENDINI
   endif

   // movemos esto aqui y lo comentamos abajo
   if cTyp <> "COPY"
      ItemProperties( i, nArea,, .T. )
   ELSE
      Add2Undo( "", nFree, nArea )
   ENDIF

   ShowItem( nFree, nArea, cAreaIni, @aFirst, @nElemente )
   oER:aItems[nArea,nFree]:lDrag := .T.

   nInfoRow := 0
   nInfoCol := 0
   SelectItem( i, nArea, cAreaIni )

   SetSave( .F. )

 //  if cTyp <> "COPY"
 //     ItemProperties( i, nArea,, .T. )
 //  ELSE
 //     Add2Undo( "", nFree, nArea )
 //  endif

    RefreshPanelTree()

return .T.

//----------------------------------------------------------------------------//

function ShowItem( i, nArea, cAreaIni, aFirst, nElemente, aIniEntries, nIndex )

   local cTyp, cName, nTop, nLeft, nWidth, nHeight, nFont, oFont, hDC, nTrans, lTrans
   local nColText, nColPane, nOrient, cFile, nBorder, nColor, nColFill, nStyle, nPenWidth
   local nRndWidth, nRndHeight, nBarcode, nPinWidth, cItemDef
   local lRight  := .F.
   local lCenter := .F.
   local cTool   := ""

/*
// Text   : say| name| ID| show| deleteable| editable| top| left| width| height| font| text color| background color| orientation | border | transparent
// Image  : say| name| ID| show| deleteable| editable| top| left| width| height| filename| border
// Graphic: say| style| ID| show| deleteable| editable| top| left| width| height| color | fill color | Style | Pen Size
// Barcode: say| value| ID| show| deleteable| editable| top| left| width| height| barcode font | color | fill color | orientation | transparent | Pin width
*/

   if aIniEntries = NIL
      cItemDef := GetItemDef( i, cAreaIni )
   ELSE
      cItemDef := GetIniEntry( aIniEntries,, "",, nIndex )
   endif


   if !EMPTY( cItemDef ) .AND. VAL( GetField( cItemDef, 4 ) ) <> 0

      cTyp      := UPPER(AllTrim( GetField( cItemDef, 1 ) ))
      cName     := GetField( cItemDef, 2 )
      nTop      := oER:nRulerTop + ER_GetPixel( VAL( GetField( cItemDef, 7 ) ) )
      nLeft     := oER:nRuler    + ER_GetPixel( VAL( GetField( cItemDef, 8 ) ) )
      nWidth    := ER_GetPixel( VAL( GetField( cItemDef, 9 ) ) )
      nHeight   := ER_GetPixel( VAL( GetField( cItemDef, 10 ) ) )

      if !aFirst[1]
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

         oFont:= IIF( nFont = 0, oEr:oAppFont, oER:aFonts[nFont] )
         lCenter := IIF( nOrient = 2, .T. , .F. )
         lRight := IIF( nOrient = 3, .T. , .F. )

         SetBKMode( oEr:oMainWnd:hDC, 1 )

         /*
         oER:aItems[nArea,i] := TSSay():New( nTop, nLeft, ;
            {|| cName }, oER:aWnd[nArea],, oFont,,, ;
            lCenter, lRight,, .T., .T., nColText, nColPane,, ;
            nWidth, nHeight, .F., .T., .F., .F., .F., IIF( nTrans = 1, .T., .F. ) )
         */

         oER:aItems[nArea,i] := TSay():New( nTop, nLeft, ;
            {|| cName }, oER:aWnd[nArea], , oFont, ;
            lCenter, lRight, ( nBorder = 1 .OR. oGenVar:lShowBorder ), .T., ;
            oER:GetColor( nColText ), oER:GetColor( nColPane ), nWidth, nHeight, .F., .T., .F., .F., .F. )

         SetBKMode( oEr:oMainWnd:hDC, 0 )

         cTool := " Tipo:        " + Chr( 9 ) + "TSAY" + CRLF + ;
                  " Top:         " + Chr( 9 ) + Str( nTop, 10 ) + CRLF + ;
                  " Left:        " + Chr( 9 ) + Str( nLeft, 10 ) + CRLF + ;
                  " Width:       " + Chr( 9 ) + Str( nWidth, 10 ) + CRLF + ;
                  " Height:      " + Chr( 9 ) + Str( nHeight, 10 ) + CRLF + ;
                  " Contenido    " + Chr( 9 ) + cName  + CRLF + ;
                  " Font:        " + Chr( 9 ) + oFont:cFaceName + CRLF + ;
                  " Font:        " + Chr( 9 ) + Str( oFont:nHeight, 10 ) + CRLF + ;
                  " Color Texto: " + Chr( 9 ) + Str( oER:GetColor( nColText ), 10 ) + CRLF + ;
                  " Color Fondo: " + Chr( 9 ) + Str( oER:GetColor( nColPane ), 10 ) + CRLF + ;
                  " Alineacion:  " + Chr( 9 ) + if( nOrient = 1, "LEFT",if( nOrient = 2, "CENTER", "RIGHT") ) + CRLF + ;
                  " Border:      " + Chr( 9 ) + if( ( nBorder = 1 .OR. oGenVar:lShowBorder ), " SI ", " NO ") + CRLF + ;
                  " Transparente:" + Chr( 9 ) + iif( nTrans = 1, " SI ", " NO " ) + CRLF

         /*
         [ <oSay> := ] TSay():New( <nRow>, <nCol>, <{cText}>,;
            [<oWnd>], [<cPict>], <oFont>, <.lCenter.>, <.lRight.>, <.lBorder.>,;
            <.lPixel.>, <nClrText>, <nClrBack>, <nWidth>, <nHeight>,;
            <.design.>, <.update.>, <.lShaded.>, <.lBox.>, <.lRaised.> )
         */

      ELSEif cTyp = "IMAGE"

         cFile   := AllTrim( GetField( cItemDef, 11 ) )
         nBorder := VAL( GetField( cItemDef, 12 ) )

         oER:aItems[nArea,i] := TImage():New( nTop, nLeft, nWidth, nHeight,,, ;
            IIF( nBorder = 1, .F., .T.), oER:aWnd[nArea],,, .F., .T.,,, .T.,, .T. )
         oER:aItems[nArea,i]:Progress(.F.)
         oER:aItems[nArea,i]:LoadBmp( VRD_LF2SF( cFile ) )

         cTool := " Tipo:        " + Chr( 9 ) + "TIMAGE" + CRLF + ;
                  " Top:         " + Chr( 9 ) + Str( nTop, 10 ) + CRLF + ;
                  " Left:        " + Chr( 9 ) + Str( nLeft, 10 ) + CRLF + ;
                  " Width:       " + Chr( 9 ) + Str( nWidth, 10 ) + CRLF + ;
                  " Height:      " + Chr( 9 ) + Str( nHeight, 10 ) + CRLF + ;
                  " Contenido    " + Chr( 9 ) + cFile  + CRLF + ;
                  " Border:      " + Chr( 9 ) + if( ( nBorder = 1 .OR. oGenVar:lShowBorder ), " SI ", " NO ") + CRLF


         /*
         [ <oBmp> := ] TImage():New( <nRow>, <nCol>, <nWidth>, <nHeight>,;
            <cResName>, <cBmpFile>, <.NoBorder.>, <oWnd>,;
            [\{ |nRow,nCol,nKeyFlags| <uLClick> \} ],;
            [\{ |nRow,nCol,nKeyFlags| <uRClick> \} ], <.scroll.>,;
            <.adjust.>, <oCursor>, <cMsg>, <.update.>,;
            <{uWhen}>, <.pixel.>, <{uValid}>, <.lDesign.> )
         */

      ELSEif IsGraphic( cTyp )

         nColor     := VAL( GetField( cItemDef, 11 ) )
         nColFill   := VAL( GetField( cItemDef, 12 ) )
         nStyle     := VAL( GetField( cItemDef, 13 ) )
         nPenWidth  := VAL( GetField( cItemDef, 14 ) )
         nRndWidth  := ER_GetPixel( VAL( GetField( cItemDef, 15 ) ) )
         nRndHeight := ER_GetPixel( VAL( GetField( cItemDef, 16 ) ) )

         oER:aItems[nArea,i] := TBitmap():New( nTop, nLeft, nWidth, nHeight, "GRAPHIC",, ;
             .T., oER:aWnd[nArea],,, .F., .T.,,, .T.,, .T. )
         oER:aItems[nArea,i]:lTransparent := .T.

         oER:aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawGraphic( hDC, cTyp, nWidth, nHeight, oER:GetColor( nColor ), oER:GetColor( nColFill ), ;
                         nStyle, nPenWidth, nRndWidth, nRndHeight ) }

         cTool := " Tipo:        " + Chr( 9 ) + "GRAPHIC" + CRLF + ;
                  " Top:         " + Chr( 9 ) + Str( nTop, 10 ) + CRLF + ;
                  " Left:        " + Chr( 9 ) + Str( nLeft, 10 ) + CRLF + ;
                  " Width:       " + Chr( 9 ) + Str( nWidth, 10 ) + CRLF + ;
                  " Height:      " + Chr( 9 ) + Str( nHeight, 10 ) + CRLF + ;
                  " Contenido    " + Chr( 9 ) + "    " + CRLF + ;
                  " Color:       " + Chr( 9 ) + Str( oER:GetColor( nColor ), 10 ) + CRLF + ;
                  " Color Fondo: " + Chr( 9 ) + Str( oER:GetColor( nColFill ), 10 ) + CRLF + ;
                  " Border:      " + Chr( 9 ) + if( ( nBorder = 1 .OR. oGenVar:lShowBorder ), " SI ", " NO ") + CRLF + ;
                  " Transparente:" + Chr( 9 ) + if( oER:aItems[nArea,i]:lTransparent, " SI ", " NO " ) + CRLF

      ELSEif cTyp = "BARCODE" .AND. lProfi

         nBarcode    := VAL( GetField( cItemDef, 11 ) )
         nColText    := VAL( GetField( cItemDef, 12 ) )
         nColPane    := VAL( GetField( cItemDef, 13 ) )
         nOrient     := VAL( GetField( cItemDef, 14 ) )
         lTrans      := IIF( VAL( GetField( cItemDef, 15 ) ) = 1, .T., .F. )
         nPinWidth   := ER_GetPixel( VAL( GetField( cItemDef, 16 ) ) )

         oER:aItems[nArea,i] := TBitmap():New( nTop, nLeft, nWidth, nHeight, "GRAPHIC",, ;
             .T., oER:aWnd[nArea],,, .F., .T.,,, .T.,, .T. )
         oER:aItems[nArea,i]:lTransparent := .T.

         oER:aItems[nArea,i]:bPainted = {| hDC, cPS | ;
            DrawBarcode( hDC, cName, 0, 0, nWidth, nHeight, nBarCode, oER:GetColor( nColText ), ;
                         oER:GetColor( nColPane ), nOrient, lTrans, nPinWidth ) }

         cTool := " Tipo:        " + Chr( 9 ) + "BARCODE" + CRLF + ;
                  " Top:         " + Chr( 9 ) + Str( nTop, 10 ) + CRLF + ;
                  " Left:        " + Chr( 9 ) + Str( nLeft, 10 ) + CRLF + ;
                  " Width:       " + Chr( 9 ) + Str( nWidth, 10 ) + CRLF + ;
                  " Height:      " + Chr( 9 ) + Str( nHeight, 10 ) + CRLF + ;
                  " Contenido    " + Chr( 9 ) + cName  + CRLF + ;
                  " Color:       " + Chr( 9 ) + Str( oER:GetColor( nColText ), 10 ) + CRLF + ;
                  " Color Fondo: " + Chr( 9 ) + Str( oER:GetColor( nColPane ), 10 ) + CRLF + ;
                  " Border:      " + Chr( 9 ) + if( ( nBorder = 1 .OR. oGenVar:lShowBorder ), " SI ", " NO ") + CRLF + ;
                  " Transparente:" + Chr( 9 ) + if( lTrans, " SI ", " NO " ) + CRLF

      endif

      if cTyp = "BARCODE" .AND. lProfi = .F.
         //Dummy
      ELSE
         oER:aItems[nArea,i]:lDrag := .T.
         ElementActions( oER:aItems[nArea,i], i, cName, nArea, cAreaIni, cTyp )
      endif

      ++nElemente

   endif

   if Valtype( oER:aItems[nArea,i] ) = "O"
      if oER:lShowToolTip
         oER:aItems[nArea,i]:cToolTip := cTool
      endif
   endif

return .T.

//----------------------------------------------------------------------------//

function DeactivateItem()

   if nAktItem <> 0
      oER:aItems[nSelArea,nAktItem]:HideDots()
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