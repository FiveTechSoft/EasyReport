/*
 * Archivo treeview.prg
 * Clase TTreeView
 * Copyright 1998 Goran Savckic (Version Original)
 * Modificaciones: dd/mm/1999 Jorge Mason Salinas <htcsoft@iname.com>
 *                            - Correccion en muestra de BitMaps
 *                 22/04/2000 Hernan Diego Ceccarelli <checanet@tutopia.com>
 *                            - Funcionamiento en Dialogos
 *                            - Manejo de Fuentes predeterminadas
 *                 03/09/2000 Hernan Diego Ceccarelli <checanet@tutopia.com>
 *                            - Windows 9x/2000/NT/ME Look y Colors
 *                            - Mejoras en calculos de altura de items para
 *                              fuentes grandes.
 *                            - Teclas Left y Right se comportan como Tree
 *                              Win9x/2000/NT/ME nativo.
 *                 21/10/2000 Hernan Diego Ceccarelli <checanet@tutopia.com>
 *                            - Se incorporaron las clausulas opcionales:
 *                                NOBORDER o NO BORDER  ->Idea de Jose Lalin
 *                                NO VSCROLL o NOVSCROLL
 *                                NO HSCROLL o HOVSCROLL
 *                              utilizables unicamente cuando se define el
 *                              tree desde codigo. Para ello se modifico el
 *                              metodo New() constructor de la clase.
 *                            - Se incorporo en la clase TTreeLink en los
 *                              metodos AddXXXX, como 4to. parametro la opcion
 *                              de si se quiere crear abierto el item.
 *                 27/10/2000 Hernan Diego Ceccarelli <checanet@tutopia.com>
 *                            - Bug arreglado. Si el recurso bmp no existia
 *                              el sistema se colgaba. Era un problema de la
 *                              clase original. Gracias Jose Lalin !!!
 *                            - New: Los BMP ahora tambien soporta indistinta-
 *                              mente archivos .BMP de disco o de recursos.
 *                 30/10/2000 Hernan Diego Ceccarelli <checanet@tutopia.com>
 *                            - New: Se incorporo a la clase TTreeLink la
 *                              variable de instancia ::Cargo para que pueda
 *                              ser utilizada por el usuario.
 *                            - New: Nuevos Metodos ::OpenAll() y ::CloseAll().
 *                              Despues de muchisimo esfuerzo, he podido desa-
 *                              rrollar estos metodos que habian sido muy pe-
 *                              didos por los usuarios de clase, dado que son
 *                              bastante complejos de desarrollar, a consecuen-
 *                              cia de la rebuscada arquitectura de la clase, y
 *                              por ello hubo que dedicarle bastante el tiempo y
 *                              abstraerse demasiado. Que los disfruten. !!!
 *                 08/07/2001 Hernan Diego Ceccarelli <checanet@tutopia.com>
 *                            - Bug en API de Windows2000 arreglado. Bajo Win2k
 *                              y en dialogos unicamente, se producia un error,
 *                              dado que se pintaba el DrawFocusRect, sin
 *                              permiso, dejando un efecto desagradable.
 *                              Se corrigio usando una peque¤a trampa (Bill Cry)
 *                              que evita que el problema se produzca.
 *                            - New: Soporte para 32 Bits FWH y FW++. Confieso
 *                              que me costo muchisimo trabajo hacer esto,
 *                              convertir funciones, etc, etc. Pero al fin
 *                              este codigo es reutilizable por los tres
 *                              compiladores. Sepan disfrutarlo. :-)
 *                 15/10/2001 Jorge Mason Salinas <htcsoft@iname.com>
 *                            - Bug arreglado en la visualizacion de los Bitmaps
 *                              bajo sistemas operativos NT (nt,Win2k,WinXP).
 *                              Jorge reescribio totalmente el archivo setmask.c
 *                              solucionando definitivamente el problema.
 *
 */

#include "FiveWin.ch"
#include "Constant.ch"
#include "TreeView.ch"


#ifdef __CLIPPER__
   #define LISTBOX_BASE    WM_USER
#else
   #define LISTBOX_BASE        383
#endif

#define LBS_NOREDRAW                  4
#define LBS_OWNERDRAWVARIABLE        32

#define LB_ADDSTRING         ( LISTBOX_BASE +  1 )
#define LB_INSERTSTRING      ( LISTBOX_BASE +  2 )
#define LB_DELETESTRING      ( LISTBOX_BASE +  3 )
#define LB_RESETCONTENT      ( LISTBOX_BASE +  5 )
#define LB_SETSEL            ( LISTBOX_BASE +  6 )
#define LB_SETCURSEL         ( LISTBOX_BASE +  7 )
#define LB_GETSEL            ( LISTBOX_BASE +  8 )
#define LB_GETCURSEL         ( LISTBOX_BASE +  9 )
#define LB_GETCOUNT          ( LISTBOX_BASE + 12 )
#define LB_DIR               ( LISTBOX_BASE + 14 )
#define LB_GETTOPINDEX       ( LISTBOX_BASE + 15 )
#define LB_FINDSTRING        ( LISTBOX_BASE + 16 )
#define LB_GETSELCOUNT       ( LISTBOX_BASE + 17 )
#define LB_GETSELITEMS       ( LISTBOX_BASE + 18 )
#define LB_GETHORIZONTALEXTENT ( LISTBOX_BASE + 20 )
#define LB_SETHORIZONTALEXTENT ( LISTBOX_BASE + 21 )
#define LB_SETTOPINDEX         ( LISTBOX_BASE + 24 )
#define LB_SETCARETINDEX       ( LISTBOX_BASE + 31 )
#define LB_GETCARETINDEX       ( LISTBOX_BASE + 32 )

#define LB_ERR              (-1)
#define LBS_MULTIPLESEL      8 // 0x0008L
#define GWL_STYLE           (-16)

#define COLOR_WINDOW       5
#define COLOR_WINDOWTEXT   8

#define WM_DRAWITEM           43    // 0x2B
#define WM_MEASUREITEM        44    // 0x2C


#ifdef __XPP__
   #define Super ::TControl
   #define New _New
#endif


STATIC oTreeTip, lTreeTip := .f.
      

//----------------------------------------------------------------------------//

CLASS TTreeView FROM TControl

   CLASSDATA lRegistered AS LOGICAL

   DATA RootLink, nIndent, aBitmaps, aMasks, oItem
   DATA oEditTimer, lEdit, oTipTimer
   DATA nTreeStyle
   DATA lProcessInit  INIT .f.  // [ByHernanCeccarelli]
   DATA aDataLinks              // [ByHernanCeccarelli]
   DATA lDrawFocusRect INIT .F. // [ByHernanCeccarelli] Fix on Win2k Dialog

   METHOD New( nRow, nCol, nWidth, nHeight, oWnd, acBitmaps, acMasks, ;
               bChange, bLDblClick, bValid, nHelpID, ;
               nClrFore, nClrBack, oFont, cMsg, bWhen, lPixel, nTreeStyle, ;
               lNoBorder, lNoVScroll, lNoHScroll ) CONSTRUCTOR

   METHOD Redefine( nId, oWnd, acBitmaps, acMasks, ;
                    bChange, bLDblClick, bValid, nHelpID, ;
                    nClrFore, nClrBack, oFont, cMsg, bWhen, nTreeStyle ) CONSTRUCTOR

   /////////////////////////////
   /// [ByHernanCeccarelli]  ///
   METHOD Init( hDlg ) INLINE  ::lProcessInit:= .t.,;
                               Super:Init( hDlg ), ;
			       ::UpdateTV()

   /////////////////////////////
   /// [ByHernanCeccarelli]  ///
   METHOD Display() INLINE If( !::lProcessInit,;
                               ( ::lProcessInit:= .t., ::Init( ::oWnd:hWnd ) ), ),;
                           Super:Display()

   METHOD cToChar() INLINE Super:cToChar( "LISTBOX" )

   METHOD GetDlgCode( nLastKey )

   METHOD Destroy()

   METHOD Del( index )
   METHOD Modify( index, cPrompt, iBmpOpen, iBmpClose )

   METHOD IndexFromPoint( nRow, nCol )

   METHOD AddLinks( oLink, nIndentLevel, nInsAfter )
   METHOD OpenLink( oLink, nIndex )
   METHOD CloseLink( oLink, nIndex )

   METHOD Default()

   METHOD Change()

   METHOD VScroll( nWParam, nLParam ) VIRTUAL  // We request default behaviors
   METHOD HScroll( nWParam, nLParam ) VIRTUAL  // We request default behaviors

   METHOD GetRoot() INLINE ::RootLink
   METHOD GetLinkAt( nPos )

   METHOD ClearList()

   METHOD GetCurSel()         INLINE ::SendMsg( LB_GETCURSEL, 0, 0 )
   METHOD SetCurSel( nPos )   INLINE ::SendMsg( LB_SETCURSEL, nPos, "" )

   METHOD GetTopIndex()       INLINE ::SendMsg( LB_GETTOPINDEX, 0, 0 )
   METHOD SetTopIndex( nPos ) INLINE ::SendMsg( LB_SETTOPINDEX, nPos, 0 )

   METHOD SetHorExt()
   METHOD GetHorExt() INLINE ::SendMsg( LB_GETHORIZONTALEXTENT, 0, 0 )

   METHOD InsertString( oLink, nPos )
   METHOD DeleteString( nPos )

   METHOD GetRect( nIndex ) INLINE if( nIndex == nil, nIndex := ::GetCurSel(), ), ;
				   LBGetRect( ::hWnd, nIndex )

   METHOD nCount() INLINE ::SendMsg( LB_GETCOUNT, 0, 0 )

   METHOD FillMeasure( nPInfo )  INLINE ;
                       TreeMeasure( nPInfo, GetFontInfo( ::oFont:hFont )[1] + 3 )
                    // [ByHernanCeccarelli]
                    // TreeMeasure( nPInfo, GetFontInfo( ::oFont )[1] )

   METHOD DrawItem( nIdCtl, nPStruct )

   METHOD KeyDown( nKey, nFlags )
   METHOD LDblClick( nRow, nCol, nFlags )
   METHOD LButtonDown( nRow, nCol, nFlags )
   METHOD MouseMove( nRow, nCol, nFlags )

   METHOD EditLabel()
   METHOD GetStyle( oLink )

   METHOD UpdateTV()

   METHOD SetBitmaps( acBitmaps )

   METHOD InsertChild( cPrompt, iBmpOpen, iBmpClose, nFlag, index )
   METHOD GetNext( index, nFlag )
   METHOD Expand( index, nFlag )

   METHOD GetLongest()
   METHOD GetExtent( nPos )

   METHOD ShowTreeTip()
   METHOD CheckTreeTip( nIndex )
   METHOD IsVisible( nIndex )
   METHOD IsOverLabel( nIndex, nRow, nCol )

   METHOD SetColor( nClrText, nClrPane )

   METHOD OpenAll()      // [ByHernanCeccarelli]
   METHOD CloseAll()     // [ByHernanCeccarelli]

   // C to PRG conversion !!!
   METHOD LBSetData( hWnd, nIndex, oLink )       // [ByHernanCeccarelli]
   METHOD LBGetData( hWnd, nIndex, lDelete )     // [ByHernanCeccarelli]

   METHOD GotFocus()                             // [ByHernanCeccarelli]
   METHOD LostFocus()                            // [ByHernanCeccarelli]

   METHOD HandleEvent( nMsg, nWParam, nLParam )  // [ByHernanCeccarelli]

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( nRow, nCol, nWidth, nHeight, oWnd, acBitmaps, acMasks, ;
	    bChange, bLDblClick, bValid, nHelpID, ;
            nClrFore, nClrBack, oFont, cMsg, bWhen, lPixel, nTreeStyle, ;
            lNoBorder, lNoVScroll, lNoHScroll ) CLASS TTreeView

   #ifdef __XPP__
      #undef New
   #endif

   ::aDataLinks:= {}
   if nClrFore == nil
      nClrBack := GetSysColor( COLOR_WINDOW )
   endif

   DEFAULT nWidth   := 40, nHeight := 40, ;
	   nClrFore := GetSysColor( COLOR_WINDOWTEXT ), ;
	   nHelpID  := 100, ;
	   lPixel   := .f., oWnd := GetWndDefault(), ;
	   nTreeStyle := nOr( TVS_HASLINES, TVS_HASBUTTONS, TVS_EDITLABELS ), ;
           oWnd     := GetWndDefault(),;
           oFont    := TFont():New( "MS Sans Serif", 0, -8 ),; // [ByHernanCeccarelli]
           lNoBorder := .f.,;                                  // [ByHernanCeccarelli]
           lNoVScroll:= .f.,;                                  // [ByHernanCeccarelli]
           lNoHScroll:= .f.                                    // [ByHernanCeccarelli]

   if acBitmaps != nil
      ::SetBitmaps( acBitmaps )
   endif
   ::cCaption	= ""
   ::nTop	= nRow * If( lPixel, 1, LST_CHARPIX_H )
   ::nLeft	= nCol * If( lPixel, 1, LST_CHARPIX_W )
   ::nBottom    = ::nTop  + nHeight - 1
   ::nRight     = ::nLeft + nWidth - 1
   ::oWnd	= oWnd
   ::oFont	= oFont
   ::nHelpID	= nHelpID

   ::nStyle     = nOr( WS_CHILD, WS_VISIBLE, ;
                       If( lNoBorder, 0, WS_BORDER ),;    // [ByHernanCeccarelli]
                       WS_TABSTOP, ;
                       If( lNoVScroll, 0, WS_VSCROLL ), ; // [ByHernanCeccarelli]
                       If( lNoHScroll, 0, WS_HSCROLL ), ; // [ByHernanCeccarelli]
                       LBS_NOTIFY, LBS_OWNERDRAWVARIABLE, ;
                       LBS_NOINTEGRALHEIGHT, LBS_NOREDRAW )

   ::nTreeStyle = nTreeStyle
   ::lEdit	= .f.

   ::nId	= ::GetNewId()
   ::lUpdate    = .t.
   ::bChange	= bChange
   ::bValid	= bValid
   ::bWhen	= bWhen
   ::cMsg	= cMsg
   ::bLDblClick = bLDblClick

   ::SetColor( nClrFore, nClrBack )

   #ifdef __XPP__
      DEFAULT ::lRegistered := .f.
   #endif

   ::Register( nOR( CS_VREDRAW, CS_HREDRAW ) )

   if !Empty( oWnd:hWnd )
      ::Create( "LISTBOX" )
      ::Default()
      ::lVisible := .t.
      oWnd:AddControl( Self )
   else
      oWnd:DefControl( Self )
      ::lVisible := .f.
   endif

   ::nIndent = 20
   ::RootLink := TTreeLink():New( Self )

return Self

//----------------------------------------------------------------------------//

METHOD Redefine( nId, oWnd, acBitmaps, acMasks, ;
		 bChange, bLDblClick, bValid, nHelpID, ;
                 nClrFore, nClrBack, oFont, cMsg, bWhen, nTreeStyle ) CLASS TTreeView

   ::aDataLinks:= {}

   if nClrFore == nil
      nClrBack := GetSysColor( COLOR_WINDOW )
   endif

   DEFAULT nClrFore   := GetSysColor( COLOR_WINDOWTEXT ), ;
	   nTreeStyle := nOr( 0, TVS_HASLINES, TVS_HASBUTTONS, TVS_EDITLABELS ), ;
           nHelpId    := 100,;
           oFont      := TFont():New( "MS Sans Serif", 0, -8 ) // [ByHernanCeccarelli]

   ::nId	= nId
   ::oWnd	= oWnd

// [ByHernanCeccarelli]  ::oFont      = TFont():New( "MS Sans Serif", 0, -9 ) //
   ::oFont      = oFont // [ByHernanCeccarelli]

   if acBitmaps != nil
      ::SetBitmaps( acBitmaps )
   endif

   ::nTreeStyle = nTreeStyle
   ::lEdit	= .f.

   ::lUpdate    = .t.
   ::bChange	= bChange
   ::bValid	= bValid
   ::bWhen	= bWhen
   ::cMsg	= cMsg
   ::bLDblClick = bLDblClick

   ::SetColor( nClrFore, nClrBack )

   oWnd:DefControl( Self )

   ::nIndent = 20
   ::RootLink := TTreeLink():New( Self )

return Self

//----------------------------------------------------------------------------//

METHOD SetColor( nClrText, nClrPane ) CLASS TTreeView

   LOCAL n

   DEFAULT nClrText := ::nClrText,;
           nClrPane := ::nClrPane

   FOR n = 1 TO LEN( ::aBitmaps )
       // [ByHernanCeccarelli]  SetMasked( ::aBitmaps[n], nClrPane )
       If ::aBitMaps[n] > 0
          SetMasked( ::aBitMaps[n], nClrPane )
       EndIf
       // [ByHernanCeccarelli]
   NEXT

RETURN Super:SetColor( nClrText, nClrPane )

//----------------------------------------------------------------------------//

METHOD Change() CLASS TTreeView

   if !Empty( ::bChange )
      Eval( ::bChange, ::GetLinkAt( ::GetCurSel() ) )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD Destroy() CLASS TTreeView

 Local n

   for n := 0 to ::nCount - 1
       ::LBGetData( ::hWnd, n, .t. )
   next

   if ::oEditTimer != nil
      ::oEditTimer:End()
   endif

   if ::oFont != nil
      ::oFont:End()
   endif

   if ::oTipTimer != nil
      ::oTipTimer:End()
      ::oTipTimer := nil
   endif

   if oTreeTip != nil
      oTreeTip:End()
      oTreeTip := nil
   endif

   if ::aBitmaps != nil
      for n = 1 to Len( ::aBitmaps )
	  DeleteObject( ::aBitmaps[n] )
      next
   endif

return Super:Destroy()

//----------------------------------------------------------------------------//

METHOD IndexFromPoint( nRow, nCol ) CLASS TTreeView

   local aPoint    := { nRow, nCol }, ;
	 iTopIndex := ::GetTopIndex(), ;
	 index

   LPtoDP( ::hdc, aPoint )

   index = iTopIndex + Int( aPoint[1] / 16 )

   if ( index + 1 ) >= ::nCount()
      index := ::nCount() - 1
   endif

return index

//----------------------------------------------------------------------------//

METHOD SetHorExt() CLASS TTreeView

 Local nLongest := ::GetLongest()

   if ::GetHorExt() != nLongest
      ::SendMsg( LB_SETHORIZONTALEXTENT, nLongest + 4, 0 )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD AddLinks( oLink, nIndentLevel, nInsAfter ) CLASS TTreeView

 Local chase

    if oLink == nil
       return nInsAfter
    endif

    if ! oLink:IsRoot()
       nInsAfter := ::InsertString( oLink, nInsAfter )
    else
       nInsAfter := -1
       nIndentLevel := 0
    endif

    if ( oLink:IsParent() .and. oLink:IsOpened() ) .or. oLink:IsRoot()
       chase := oLink:LastChild

       while chase != nil
	  ::AddLinks( chase, nIndentLevel + 1, nInsAfter + 1 )
	  chase := chase:PrevSibling
       end
    endif

   oLink:SetIndent( nIndentLevel )

return nil

//----------------------------------------------------------------------------//

METHOD OpenLink( oLink, nIndex ) CLASS TTreeView

 Local chase   

   if oLink == nil
      return nil
   endif

   if ::hWnd > 0
      ::SendMsg( WM_SETREDRAW, 0, 0 )
   endif

   oLink:ToggleOpened()
   chase := oLink:LastChild
   while chase != nil
      ::AddLinks( chase, oLink:GetIndent() + 1, nIndex + 1 )
      chase := chase:PrevSibling
   end

   if ::hWnd > 0
      ::SendMsg( WM_SETREDRAW, 1, 0 )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD CloseLink( oLink, nIndex ) CLASS TTreeView

 Local nTargDelLevel := 0, ;
       chase, ;
       chaseLevel := 0, ;
       cnt := 0

   if oLink == nil
      return nil
   endif

   oLink:ToggleOpened()
   ++nIndex

   if nIndex >= ::nCount()
      return nil
   endif

   nTargDelLevel := oLink:GetIndent() + 1
   chase	 := ::GetLinkAt( nIndex )
   chaseLevel	 := chase:GetIndent()

   // When closing a parent, remove all of the children with indent level
   // grater than the parent
   //
   while nTargDelLevel <= chaseLevel

      if chase:IsOpened()
	 ::CloseLink( chase, nIndex )
      endif

      cnt := ::DeleteString( nIndex )

      if nIndex >= cnt
	 exit
      endif

      chase := ::GetLinkAt( nIndex )
      chaseLevel := chase:GetIndent()

   end

return nil

//----------------------------------------------------------------------------//

METHOD ClearList() CLASS TTreeView

 Local nPos, nTot := ::nCount() - 1

   for nPos = 0 to nTot
       ::LBGetData( ::hWnd, nPos, .t. )
   next

   ::SendMsg( LB_RESETCONTENT, 0, 0 )

return nil

//----------------------------------------------------------------------------//

METHOD Default() CLASS TTreeView

   if ::oFont != nil
      ::SetFont( ::oFont )
   else
      ::SetFont( TFont():New( "MS Sans Serif", 0, -9 ) )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD InsertString( oLink, nPos ) CLASS TTreeView

 DEFAULT nPos := iif( nPos == nil, ::GetCurSel(), nPos )

   nPos := ::SendMsg( LB_INSERTSTRING, nPos, oLink:TreeItem:cPrompt )

   if nPos != LB_ERR
      ::LBSetData( ::hWnd, nPos, oLink )
   endif

return nPos

//----------------------------------------------------------------------------//

METHOD DeleteString( nPos ) CLASS TTreeView

 Local nCount := 0

 DEFAULT nPos := iif( nPos == nil, ::GetCurSel(), nPos )

   ::LBGetData( ::hWnd, nPos, .t. )
   nCount := ::SendMsg( LB_DELETESTRING, nPos, 0 )

RETURN nCount

//----------------------------------------------------------------------------//

METHOD GetLinkAt( nPos ) CLASS TTreeView

   If ::nCount() <= 0  // [ByHernanCeccarelli]
      return Nil
   EndIf

   if ( nPos < 0 ) .and. ( ( nPos + 1 ) >= ::nCount() )
      return nil
   endif


return ::LBGetData( ::hWnd, nPos, .f. )

//----------------------------------------------------------------------------//

METHOD KeyDown( nKey, nFlags ) CLASS TTreeView

 Local index, ;
       oLink

      index := ::GetCurSel()
      oLink := ::GetLinkAt( index )

      do case

         case nKey == VK_RIGHT // [ByHernanCeccarelli]
	      if oLink:IsParent() .and. !oLink:IsOpened()
		 ::OpenLink( oLink, index )
                 ::SetHorExt()
                 return 0
	      endif
              ::SetHorExt()


         case nKey == VK_LEFT // [ByHernanCeccarelli]
	      if oLink:IsParent() .and. oLink:IsOpened()
		 ::CloseLink( oLink, index )
                 ::SetHorExt()
                 return 0
	      endif
	      ::SetHorExt()


         case nKey == VK_ADD
	      if oLink:IsParent() .and. !oLink:IsOpened()
		 ::OpenLink( oLink, index )
	      endif
	      ::SetHorExt()


         case nKey == VK_SUBTRACT
	      if oLink:IsParent() .and. oLink:IsOpened()
		 ::CloseLink( oLink, index )
	      endif
	      ::SetHorExt()

      endcase

return Super:KeyDown( nKey, nFlags )

//----------------------------------------------------------------------------//

METHOD LButtonDown( nRow, nCol, nFlags ) CLASS TTreeView

   // ::CheckTreeTip()

   if lAnd( ::nTreeStyle, TVS_EDITLABELS )

      if ::IndexFromPoint( nRow, nCol ) == ::GetCurSel() .and. ! ::lEdit
         if ::oEditTimer == nil
	    DEFINE TIMER ::oEditTimer ;
		  INTERVAL 800 ;
		  ACTION ( ::oEditTimer:End(), ::oEditTimer := nil, ::EditLabel() )
	    ACTIVATE TIMER ::oEditTimer
         endif
      else
	 if ::oEditTimer != nil
	    ::oEditTimer:End()
	    ::oEditTimer := nil
	 endif
      endif

   endif

return Super:LButtonDown( nRow, nCol, nFlags )

//----------------------------------------------------------------------------//

METHOD LDblClick( nRow, nCol, nFlags ) CLASS TTreeView

 Local index, ;
       oLink

   if lAnd( ::nTreeStyle, TVS_EDITLABELS )

      if ::oEditTimer != nil
	 ::oEditTimer:End()
	 ::oEditTimer := nil
      endif

   endif

   index := ::GetCurSel()
   oLink := ::GetLinkAt( index )

   if ( oLink != nil ) .and. oLink:IsParent()
      if oLink:IsOpened()
	 ::CloseLink( oLink, index )
      else
	 ::OpenLink( oLink, index )
      endif
      ::SetHorExt()
   endif

return Super:LDblClick( nRow, nCol, nFlags )

//----------------------------------------------------------------------------//

METHOD GetStyle( oLink ) CLASS TTreeView

 Local aRet, i, nHow

   nHow := oLink:IndentLevel
   aRet := Array( nHow )

   for i = nHow TO 1 step -1

       aRet[i] := 0

       if oLink:IsFirstChild()
	  aRet[i] := nOr( aRet[i], TIS_FIRST )
       endif

       if oLink:IsLastChild()
	  aRet[i] := nOr( aRet[i], TIS_LAST )
       endif

       if oLink:IsParent()
	  aRet[i] := nOr( aRet[i], TIS_PARENT )
       endif

       if oLink:IsOpened()
	  aRet[i] := nOr( aRet[i], TIS_OPEN )
       endif

       oLink := oLink:ParentLink

   next

return aRet

//----------------------------------------------------------------------------//

METHOD UpdateTV() CLASS TTreeView

 Local nTopIndex := ::GetTopIndex(), ;
       nSelIndex := ::GetCurSel()

   if ::hWnd > 0
      ::SendMsg( WM_SETREDRAW, 0, 0 )
   endif

   ::ClearList()

   ::AddLinks( ::RootLink, 0, 0 )

   ::SetHorExt()

   ::SetTopIndex( nTopIndex )
   if nSelIndex != LB_ERR
      ::SetCurSel( nSelIndex )
   else
      ::SetCurSel( 0 )
   endif

   if ::hWnd > 0
      ::SendMsg( WM_SETREDRAW, 1, 0 )
   endif

return Nil

//----------------------------------------------------------------------------//

METHOD SetBitmaps( acBitmaps ) CLASS TTreeView

 Local n
 LOCAL cBmp, hDC:= 0 // [ByHernanCeccarelli]

   ::aBitmaps = Array( Len( acBitmaps ) )

   // [ByHernanCeccarelli]   //! Soporte adicional de archivos .BMP !//
   If ::oWnd != Nil          //! y recursos, por supuesto.          !//
      hDC:= ::oWnd:GetDC()
   EndIf

   for n = 1 to Len( acBitmaps )
      // ::aBitmaps[n] = LoadBitmap( GetResources(), acBitmaps[n] )
      // [ByHernanCeccarelli]
      cBmp:= acBitMaps[n]
      If !Empty( cBmp ) .and. File( cBmp )
         ::aBitMaps[n]:= ReadBitMap( hDC, cBmp )
      Else
         ::aBitMaps[n]:= LoadBitMap( GetResources(), cBmp )
      EndIf
      // [ByHernanCeccarelli]
   next

   // [ByHernanCeccarelli]
   If ::oWnd != Nil
      ::oWnd:ReleaseDC()
   EndIf

return nil

//----------------------------------------------------------------------------//

METHOD Del( index ) CLASS TTreeView

 Local Link

 DEFAULT index := ::GetCurSel()

   if ( index < 0 ) .and. ( index > ::nCount() )
      return nil
   endif

   Link := ::GetLinkAt( index )

   if Link:Kill()
      ::UpdateTV()
   endif

return nil

//----------------------------------------------------------------------------//

METHOD Modify( index, cPrompt, iBmpOpen, iBmpClose ) CLASS TTreeView

 Local oLink

 DEFAULT index := ::GetCurSel()

   oLink := ::GetLinkAt( index )

   if oLink == nil
      return .f.
   endif

   oLink:TreeItem:SetText( cPrompt )

   if iBmpOpen != nil
      oLink:TreeItem:iBmpOpen := iBmpOpen
   endif

   if iBmpClose != nil
      oLink:TreeItem:iBmpClose := iBmpClose
   endif

   ::UpdateTV()

return .f.

//----------------------------------------------------------------------------//

METHOD InsertChild( cPrompt, iBmpOpen, iBmpClose, nFlag, index ) CLASS TTreeView

 Local Link, oItem

 DEFAULT nFlag := nOr( 0, IS_AFTER ), index := ::GetCurSel()

   if ( index < 0 ) .and. ( index > ::nCount() )
      return nil
   endif

   oItem := ::GetLinkAt( index )

   do case

      case nFlag == IS_FIRST
	   Link = oItem:AddAtHead( cPrompt, iBmpOpen, iBmpClose )

      case nFlag == IS_LAST
	   Link = oItem:AddAtTail( cPrompt, iBmpOpen, iBmpClose )

      case nFlag == IS_AFTER
	   Link = oItem:AddAfter( cPrompt, iBmpOpen, iBmpClose )

      case nFlag == IS_FIRSTCHILD
	   Link = oItem:AddFirstChild( cPrompt, iBmpOpen, iBmpClose )

      case nFlag == IS_LASTCHILD
	   Link = oItem:AddLastChild( cPrompt, iBmpOpen, iBmpClose )

   endcase

   ::UpdateTV()

return Link

//----------------------------------------------------------------------------//

METHOD GetNext( index, nFlag ) CLASS TTreeView

 Local Link, oItem

 DEFAULT index := ::GetCurSel(), nFlag := TVGN_NEXT

   if ( index < 0 ) .and. ( index > ::nCount() )
      return nil
   endif

   oItem := ::GetLinkAt( index )

   DO CASE

      CASE nFlag == TVGN_ROOT
	   Link := ::GetRoot()

      CASE nFlag == TVGN_NEXT
	   Link := oItem:NextSibling

      CASE nFlag == TVGN_PREVIOUS
	   Link := oItem:PrevSibling

      CASE nFlag == TVGN_PARENT
	   Link := oItem:ParentLink

      CASE nFlag == TVGN_CHILD
	   if oItem:IsParent()
	      Link := oItem:FirstChild
	   endif

      CASE nFlag == TVGN_CARET
	   Link := oItem

   ENDCASE

return Link

//----------------------------------------------------------------------------//

METHOD Expand( index, nFlag ) CLASS TTreeView

 Local Link

 DEFAULT index := ::GetCurSel(), nFlag := TVE_EXPAND

   if ( index < 0 ) .and. ( index > ::nCount() )
      return nil
   endif

   Link := ::GetLinkAt( index )

   if ! Link:IsParent()
      return .f.
   endif

   DO CASE

      CASE nFlag == TVE_COLLAPSE
	   if Link:IsOpened()
	      ::CloseLink( Link, index )
	   endif
	   return .t.

      CASE nFlag == TVE_EXPAND
	   if ! Link:IsOpened()
	      ::OpenLink( Link, index )
	   endif
	   return .t.

      CASE nFlag == TVE_TOGGLE
	   if Link:IsOpened()
	      ::CloseLink( Link, index )
	   else
	      ::OpenLink( Link, index )
	   endif
	   return .t.

   ENDCASE

return .f.

//----------------------------------------------------------------------------//

METHOD GetLongest() CLASS TTreeView

 Local nTot := ::nCount() - 1, ;
       i, ;
       nLongest := 0

   for i = 0 TO nTot
       nLongest := Max( nLongest, ::GetExtent( i ) )
   next

return nLongest

//----------------------------------------------------------------------------//

METHOD EditLabel() CLASS TTreeView

 Local oLink := ::GetLinkAt( ::GetCurSel() ), ;
       aRect := ::GetRect(), ;
       oGet, ;
       cText, ;
       nSaveWid

   aRect[2] += ::GetExtent() - GetTextWidth( nil, AllTrim( oLink:TreeItem:cPrompt ), ::oFont:hFont )

   if lAnd( GetWindowLong( ::hWnd, GWL_STYLE ), WS_HSCROLL )
      if ::GetExtent() > aRect[4]
	 ::SendMsg( WM_HSCROLL, SB_RIGHT, GetScrollPos( ::hWnd, 0 ) )
      else
	 ::SendMsg( WM_HSCROLL, SB_LEFT, GetScrollPos( ::hWnd, 0 ) )
      endif
      aRect[2] -= GetScrollPos( ::hWnd, 0 )
   endif

   cText := padr( oLink:TreeItem:cPrompt, 64, " " )

   nSaveWid := GetTextWidth( nil, AllTrim( cText ), ::oFont:hFont ) + 8

   @ aRect[1], aRect[2] GET oGet VAR cText ;
			FONT ::oFont ;
			SIZE nSaveWid, aRect[3] - aRect[1] PIXEL ;
			COLOR ::nClrText, ::nClrPane ;
			UPDATE ;
			OF Self

   ::nLastKey := 0

   oGet:bGotFocus  := { || oGet:SetSel( , Len( AllTrim( cText ) ) + 1 ) }
   oGet:bLostFocus := { || Eval( oGet:bKeyDown, Self:nLastKey ), oGet:End(), ::lEdit := .f. }
   oGet:bKeyDown   := { | nKey, nFlags | iif( nKey == VK_ESCAPE, oGet:End(), ;
					 iif( nKey == VK_RETURN, ( ::Modify( nil, oGet:oGet:buffer ), oGet:End() ),) ) }
   oGet:bChange    := { || oGet:Move( oGet:nTop, ;
			   aRect[2], ;
			   Min( ::GetRect()[4] - aRect[2], Max( nSaveWid, GetTextWidth( nil, AllTrim( oGet:oGet:buffer ), ::oFont:hFont ) + 20 ) ), ;
			   oGet:nHeight, .t. ) }

   oGet:SetFocus()
   ::lEdit := .t.

return nil

//----------------------------------------------------------------------------//

METHOD GetExtent( nPos ) CLASS TTreeView

 Local oLink, ;
       nExtent := 77

 DEFAULT nPos := ::GetCurSel()

   //////////////////////////////////
   /// If-> [ByHernanCeccarelli]  ///
   If 'O' $ Valtype( oLink := ::GetLinkAt( nPos ) )

      nExtent := ( oLink:GetIndent * ::nIndent ) + ;
                 GetTextWidth( nil, oLink:TreeItem:GetText(), ::oFont:hFont ) + ;
                 iif( oLink:IsOpened(), iif( oLink:TreeItem:iBmpOpen  > 0, 18, 0 ), ;
                                        iif( oLink:TreeItem:iBmpClose > 0, 18, 0 ) )
    EndIf
   //////////////////////////////////

return nExtent

//----------------------------------------------------------------------------//

METHOD ShowTreeTip( nIndex ) CLASS TTreeView

 Local oFont, hOldFont, aPos, ;
       aRect := ::GetRect( nIndex ), ;
       oLink := ::GetLinkAt( nIndex )

   DEFINE FONT oFont NAME "Ms Sans Serif" SIZE 0, -8

   SetCapture( ::hWnd )

   ::Disable()

   DEFINE WINDOW oTreeTip FROM 0, 0 TO 1, 5 ;
	  STYLE nOr( WS_POPUP, WS_BORDER ) ;
	  COLOR 0, RGB( 255, 255, 225 )

   aRect[2] := ::GetExtent( nIndex ) - GetTextWidth( nil, oLink:TreeItem:cPrompt, ::oFont:hFont )
   aRect[2] -= GetScrollPos( ::hWnd, 0 )

   aPos = { aRect[1], aRect[2] }

   ClientToScreen( ::hWnd, aPos )

   oTreeTip:Move( aPos[1], aPos[2] - 1, GetTextWidth( nil, oLink:TreeItem:cPrompt, ::oFont:hFont ) + 7, 16 )

   oTreeTip:Show()

   SetBkMode( oTreeTip:GetDC(), 1 )
   SetTextColor( oTreeTip:hDC, 0 )
   hOldFont = SelectObject( oTreeTip:hDC, oFont:hFont )
   TextOut( oTreeTip:hDC, 0, 2, oLink:TreeItem:cPrompt )
   SelectObject( oTreeTip:hDC, hOldFont )
   oTreeTip:ReleaseDC()
   oFont:End()

   lTreeTip := .t.

   ::Enable()

   SetCapture( ::hWnd )

return nil

//----------------------------------------------------------------------------//

METHOD MouseMove( nRow, nCol, nFlags ) CLASS TTreeView

 Local aPoint := { nRow, nCol }, ;
       nIndex := ::IndexFromPoint( nRow, nCol )

   Super:MouseMove( nRow, nCol, nFlags )

   if lTreeTip
      ClientToScreen( ::hWnd, aPoint )
      ScreenToClient( oTreeTip:hWnd, aPoint )
      if !IsOverWnd( oTreeTip:hWnd, aPoint[1], aPoint[2] )
	 lTreeTip := .f.
	 oTreeTip:End()
	 oTreeTip := nil
	 ReleaseCapture()
	 ::SetFocus()
      endif
   elseif ! ::IsVisible( nIndex )
      if ::IsOverLabel( nIndex, nRow, nCol )
	 ::CheckTreeTip( nIndex )
      endif
   elseif ::IsVisible( nIndex ) .and. ::oTipTimer != nil
      ::oTipTimer:End()
      ::oTipTimer := nil
   endif

return 0

//----------------------------------------------------------------------------//

METHOD CheckTreeTip( nIndex ) CLASS TTreeView

   lTreeTip := .f.
   if ::oTipTimer != nil
      ::oTipTimer:End()
      ::oTipTimer := nil
   endif
   if lTreeTip
      ::ShowTreeTip( nIndex )
   else
      DEFINE TIMER ::oTipTimer INTERVAL 900 ;
	  ACTION ( if( !::IsVisible( nIndex ), ::ShowTreeTip( nIndex ),), ::oTipTimer:End(), ::oTipTimer := nil )
      ACTIVATE TIMER ::oTipTimer
   endif

return nil

//----------------------------------------------------------------------------//

METHOD IsVisible( nIndex ) CLASS TTreeView

 DEFAULT nIndex := ::GetCurSel()

return ::GetExtent( nIndex ) <= ::GetRect( nIndex )[4]

//----------------------------------------------------------------------------//

METHOD IsOverLabel( nIndex, nRow, nCol ) CLASS TTreeView

 Local aPoint := { nRow, nCol }, ;
       oLink, ;
       nAllIndent := 0, ;
       lRet := .f.

 DEFAULT nIndex := ::GetCurSel()

   oLink  := ::GetLinkAt( nIndex )

   ScreenToClient( ::hWnd, aPoint )
   ClientToScreen( ::hWnd, aPoint )

   nAllIndent := ( oLink:IndentLevel * ::nIndent )

   if oLink:IsOpened
      if oLink:TreeItem:iBmpOpen != 0
	 nAllIndent += 18
      endif
   else
      if oLink:TreeItem:iBmpClose != 0
	 nAllIndent += 18
      endif
   endif

   lRet := aPoint[2] >= nAllIndent

return lRet

//----------------------------------------------------------------------------//

METHOD GetDlgCode( nLastKey ) CLASS TTreeView

   if .not. ::oWnd:lValidating
      if nLastKey == VK_UP .or. nLastKey == VK_DOWN ;
         .or. nLastKey == VK_RETURN .or. nLastKey == VK_TAB
         ::oWnd:nLastKey = nLastKey
      else
         ::oWnd:nLastKey = 0
      endif
   endif

return DLGC_WANTALLKEYS

//----------------------------------------------------------------------------//

METHOD CloseAll() CLASS TTreeView // [ByHernanCeccarelli]
 LOCAL oLink

    ::Init()  // Seteo inicializacion por si no la hubo !!!
    oLink:= ::GetLinkAt( 0 ) // Primer Link (No es GetRoot())
    If oLink == Nil
       return Nil
    EndIf

    ::SetCurSel( 0 )
    If oLink:IsOpened()
       ::CloseLink( oLink, 0 )
       ::SetHorExt()
       ::Refresh()
    EndIf

return Nil

//----------------------------------------------------------------------------//

METHOD OpenAll() CLASS TTreeView // [ByHernanCeccarelli]
 LOCAL oLink, oLinkChild, nId:= 0, nIdOld, oLinkOld, uCargoOld

    ::Init()  // Seteo inicializacion por si no la hubo !!!

    oLink:= ::GetLinkAt( 0 ) // El primer Link ( NO el GetRoot() )

    If oLink == Nil
       return Nil
    EndIf

    oLinkChild:= oLink:FirstChild
    nIdOld   := ::GetCurSel()          // Posicion Actual
    oLinkOld := ::GetLinkAt( nIdOld )  // Link Actual
    uCargoOld:= oLinkOld:Cargo         // Guardo Info.de Usuario


    oLinkOld:Cargo:= 2545.2545 // Pongo banderita rara en el objeto activo !!!

    If !oLink:IsOpened() .and. oLink:IsParent()
       ::OpenLink( oLink, nId )
       ::SetHorExt()
    EndIf

    // Verifico la banderita, por si cambio de posicion, debido a aperturas
    // dado que el mismo item, ocupa quiza, una posicion logica diferente !!!
    If "N"$ValType( ::GetLinkAt( nId ):Cargo ) .and. ;
       ::GetLinkAt( nId ):Cargo == 2545.2545
       nIdOld:= nId
    EndIf

    While .t.
       If oLinkChild != Nil
          nId++
          OpenLinks( oLinkChild, Self, @nId, @nIdOld )
       Else
          Exit
       EndIf
       oLinkChild:= oLinkChild:NextSibling
    EndDo

    oLinkOld:Cargo:= uCargoOld // Restauro Info de usuario anterior !!!
    ::SetCurSel( nIdOld )      // Seteo posicion anterior a la apertura total

    ::Refresh()

return Nil

//----------------------------------------------------------------------------//

STATIC Function OpenLinks( oLink, Self, nId, nIdOld )
 LOCAL oLinkChild:= oLink:FirstChild

    If !oLink:IsOpened() .and. oLink:IsParent()
       ::OpenLink( oLink, nId )
       ::SetHorExt()
    EndIf

    // Verifico la banderita, por si cambio de posicion, debido a aperturas
    // dado que el mismo item, ocupa quiza, una posicion logica diferente !!!
    If "N"$ValType( ::GetLinkAt( nId ):Cargo ) .and. ;
       ::GetLinkAt( nId ):Cargo == 2545.2545

       nIdOld:= nId
    EndIf

    While .t.
       If oLinkChild != Nil
          nId++
          OpenLinks( oLinkChild, Self, @nId, @nIdOld )
       Else
          Exit
       EndIf
       oLinkChild:= oLinkChild:NextSibling
    EndDo
return Nil

//----------------------------------------------------------------------------//

METHOD LBSetData( hWnd, nIndex, oLink ) CLASS TTreeview // [ByHernanCeccarelli]
 LOCAL nPos

     nIndex++

     ASize( ::aDataLinks, Len( ::aDataLinks ) + 1 )
     AIns( ::aDataLinks, nIndex )
     ::aDataLinks[ nIndex ]:= oLink

return Nil

//----------------------------------------------------------------------------//

METHOD LBGetData( hWnd, nIndex, lDelete ) CLASS TTreeview // [ByHernanCeccarelli]
 LOCAL nPos, oObj, nLen

    nIndex++

    if (nLen:= Len( ::aDataLinks )) > 0 .and. nIndex <= nLen
       oObj:= ::aDataLinks[ nIndex ]
       If lDelete
          ADel( ::aDataLinks, nIndex )
          ASize( ::aDataLinks, Len( ::aDataLinks ) - 1 )
       EndIf
       return oObj
    EndIf
return Self


//----------------------------------------------------------------------------//

METHOD DrawItem( nIdCtl, nPStruct ) CLASS TTreeview // [ByHernanCeccarelli]

    ::oItem := ::GetLinkAt( LbxGetID( nPStruct ) )

    TreeDrawItem( nPStruct, ::oItem:TreeItem:cPrompt, ;
                  ::oItem:IndentLevel, ::nIndent, ::nTreeStyle, ;
                  ::GetStyle( ::oItem ), ::oItem:GetBitmap(), ;
                  ::aBitmaps, ::lDrawFocusRect )

return 1

//----------------------------------------------------------------------------//

METHOD GotFocus() CLASS TTreeview

    if "DIALOG" $ ::oWnd:ClassName
       ::lDrawFocusRect:= .T.
       ::Refresh( .f. )
    endif

return Super:GotFocus()

//----------------------------------------------------------------------------//

METHOD LostFocus() CLASS TTreeview

    if "DIALOG" $ ::oWnd:ClassName
       ::lDrawFocusRect:= .F.
       ::Refresh( .f. )
    endif

return Super:GotFocus()

//----------------------------------------------------------------------------//

METHOD HandleEvent( nMsg, nWParam, nLParam ) CLASS TTreeView

   do case

      case nMsg == FM_DRAW
           return ::DrawItem( nWParam, nLParam )

      otherwise
           return Super:HandleEvent( nMsg, nWParam, nLParam )

   endcase

return nil

//----------------------------------------------------------------------------//


