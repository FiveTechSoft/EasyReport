#include <Windows.h>
#include <hbapi.h>

#define TVS_HASBUTTONS	     1
#define TVS_HASLINES	     2

#define TIS_NORMAL    0
#define TIS_FIRST     1
#define TIS_LAST      2
#define TIS_PARENT    4
#define TIS_OPEN      8

void LineToDot( HDC hDC, int xEnd, int yEnd ); // [ByHernanCeccarelli]
void FrameDot( HDC hDC, RECT * pRect );        // [ByHernanCeccarelli]

void DrawBitmap( HDC, HBITMAP, WORD, WORD, WORD, WORD, LONG );


#ifdef __FLAT__
   DWORD MoveTo( HDC hdc, int x, int y );
#endif

#ifdef __XPP__
   #define _parni( x, y ) PARNI( x, params, y )
   #define _storni( x, y, z ) STORNI( x, params, y, z )
#endif


//----------------------------------------------------------------------------//

HB_FUNC( TREEMEASURE )
{
   LPMEASUREITEMSTRUCT pMeasure = ( LPMEASUREITEMSTRUCT ) hb_parnl( 1 );

   pMeasure->itemHeight = hb_parni( 2 );

   hb_retl( TRUE );
}

//----------------------------------------------------------------------------//

HB_FUNC( TREEDRAWITEM )
{
   LPDRAWITEMSTRUCT lp = ( LPDRAWITEMSTRUCT ) hb_parnl( 1 );
   RECT tempRct;
   HPEN hDotPen, hOldPen;
   BOOL firstDraw = TRUE;
   int centerX, centerY, x, y;
   COLORREF rgbFore, rgbBack;
   BYTE szName[ 30 ];
   int nLevel = hb_parni( 3 );
   int nLevel1 = nLevel;
   int nIndent = hb_parni( 4 );
   int nIndent1 = nIndent;
   DWORD nStyle = (DWORD) hb_parnl( 5 );
   WORD wItemStyle = hb_parvni( 6, nLevel1 );
   HBRUSH hBrush, hOldBrush;
   int iItemID = (int) lp->itemID ;

   RECT rect;    // [HernanCeccarelli]
   DWORD dwSize; // [HernanCeccarelli]
   SIZE sz;      // [HernanCeccarelli]

   ////////////////////////////////////

   if( nStyle & TVS_HASLINES )
   {
       tempRct.top    = lp->rcItem.top;
       tempRct.left   = lp->rcItem.left;
       tempRct.bottom = lp->rcItem.bottom;
       tempRct.right  = lp->rcItem.right;

       tempRct.right = nIndent * nLevel;
       tempRct.left  = tempRct.right - nIndent;

       while( nIndent1 > 0 )
       {
          centerX = tempRct.left + ( tempRct.right - tempRct.left ) / 2;
          centerY = tempRct.top  + ( tempRct.bottom - tempRct.top ) / 2;

          if( firstDraw )
          {
             firstDraw = FALSE;
             if( (wItemStyle & TIS_FIRST) && (nLevel == 1) )
             {
                  MoveTo( lp->hDC, centerX, tempRct.bottom );
                  LineToDot( lp->hDC, centerX, centerY );
                  LineToDot( lp->hDC, tempRct.right, centerY );
             }
             else if( wItemStyle & TIS_LAST )
             {
                 MoveTo( lp->hDC, centerX, tempRct.top );
                 LineToDot( lp->hDC, centerX, centerY );
                 LineToDot( lp->hDC, tempRct.right, centerY );
             }
             else
             {
                 MoveTo( lp->hDC, centerX, tempRct.top );
                 LineToDot( lp->hDC, centerX, tempRct.bottom );
                 MoveTo( lp->hDC, centerX, centerY );
                 LineToDot( lp->hDC, tempRct.right, centerY );
             }
          }
          else
          {
             if( !(wItemStyle & TIS_LAST ) )
             {
                MoveTo( lp->hDC, centerX, tempRct.top );
                LineToDot( lp->hDC, centerX, tempRct.bottom );
                MoveTo( lp->hDC, centerX, centerY );
             }
          }
          tempRct.left  -= nIndent;
          tempRct.right -= nIndent;
          nIndent1--;
          --nLevel1;
          wItemStyle = hb_parvni( 6, nLevel1 );
       }
   }

   ////////////////////////////////////

   if( nStyle & TVS_HASBUTTONS )
   {
       hBrush = CreateSolidBrush( GetSysColor( COLOR_WINDOW ) );
       hOldBrush = SelectObject( lp->hDC, hBrush );

       tempRct.top    = lp->rcItem.top;
       tempRct.left   = lp->rcItem.left;
       tempRct.bottom = lp->rcItem.bottom;
       tempRct.right  = lp->rcItem.right;

       tempRct.right = nIndent * nLevel;
       tempRct.left  = tempRct.right - nIndent;

       centerX = tempRct.left + ( tempRct.right - tempRct.left ) / 2;
       centerY = tempRct.top  + ( tempRct.bottom - tempRct.top ) / 2;

       tempRct.left   = centerX - 4;
       tempRct.right  = centerX + 5;

       tempRct.top    = centerY - 4;
       tempRct.bottom = centerY + 5;

       wItemStyle = hb_parvni( 6, nLevel );

       if ( wItemStyle & TIS_PARENT ) {

          /// [ByHernanCeccarelli]
          hDotPen = CreatePen( PS_SOLID, 0, GetSysColor(COLOR_GRAYTEXT)) ;
          hOldPen = SelectObject( lp->hDC, hDotPen );
          /// [ByHernanCeccarelli]

          Rectangle( lp->hDC, tempRct.left, tempRct.top, tempRct.right, tempRct.bottom );

          /// [ByHernanCeccarelli]
          SelectObject( lp->hDC, hOldPen );
          DeleteObject( hDotPen );
          /// [ByHernanCeccarelli]

          /// [ByHernanCeccarelli]
          hDotPen = CreatePen( PS_SOLID, 0, GetSysColor(COLOR_BTNTEXT)) ;
          hOldPen = SelectObject( lp->hDC, hDotPen );
          /// [ByHernanCeccarelli]

          // -
          y = tempRct.top + ( tempRct.bottom - tempRct.top ) / 2;
          MoveTo( lp->hDC, tempRct.left + 2, y );
          LineTo( lp->hDC, tempRct.right - 2, y );

          if( !(wItemStyle & TIS_OPEN) ) {
              x = tempRct.left + ( tempRct.right - tempRct.left ) / 2;
              MoveTo( lp->hDC, x, tempRct.top + 2 );
              LineTo( lp->hDC, x, tempRct.bottom - 2 );
          }

          /// [ByHernanCeccarelli]
          SelectObject( lp->hDC, hOldPen );
          DeleteObject( hDotPen );
          /// [ByHernanCeccarelli]

       }

       SelectObject( lp->hDC, hOldBrush );
       DeleteObject( hBrush );
   }

   ////////////////////////////////////

   lp->rcItem.left += nLevel * nIndent;

   if( wItemStyle & TIS_OPEN ) {
       if( hb_parvni( 7, 1 ) != 0 ) {
         DrawBitmap( lp->hDC, (HBITMAP) hb_parvnl( 8, hb_parvni( 7, 1 ) ), lp->rcItem.top, lp->rcItem.left, 0, 0, 0 );
         lp->rcItem.left += 18;
       }
   }
   else {
       if( hb_parvni( 7, 2 ) != 0 ) {
         DrawBitmap( lp->hDC, (HBITMAP) hb_parvnl( 8, hb_parvni( 7, 2 ) ), lp->rcItem.top, lp->rcItem.left, 0, 0, 0 );
         lp->rcItem.left += 18;
       }
   }

   #ifndef __FLAT__
       dwSize = GetTextExtent( lp->hDC, hb_parc( 2 ), hb_parclen( 2 ) ) ;
   #else
       GetTextExtentPoint32( lp->hDC, hb_parc( 2 ), hb_parclen( 2 ), &sz ) ;
       dwSize = sz.cx;
   #endif
   lp->rcItem.right = lp->rcItem.left + LOWORD( dwSize ) + 4;

   if( iItemID == -1 )
   {
      DrawFocusRect( lp->hDC, &lp->rcItem );
      hb_retl( TRUE );
      return;
   }
   else
   {
      switch( lp->itemAction )
      {
         case ODA_DRAWENTIRE:
         case ODA_SELECT:

              if( lp->itemState & ODS_FOCUS )
                 DrawFocusRect( lp->hDC, &lp->rcItem );

              if( lp->itemState & ODS_SELECTED )
              {
                  rgbFore = SetTextColor( lp->hDC, GetSysColor( COLOR_HIGHLIGHTTEXT ) );
                  rgbBack = SetBkColor( lp->hDC, GetSysColor( COLOR_HIGHLIGHT ) );
              }

              ExtTextOut( lp->hDC, lp->rcItem.left + 2, lp->rcItem.top + 1,
                          ETO_CLIPPED | ETO_OPAQUE, &lp->rcItem, hb_parc( 2 ),
                          hb_parclen( 2 ), 0 );

              if( lp->itemState & ODS_FOCUS )
                 DrawFocusRect( lp->hDC, &lp->rcItem );

              if( lp->itemState & ODS_SELECTED )
              {
                  if( hb_parl( 9 ) )  // Fix for Win2K Dialog
                    DrawFocusRect( lp->hDC, &lp->rcItem );

                  SetTextColor( lp->hDC, rgbFore );
                  SetBkColor( lp->hDC, rgbBack );
              }
              break;

         case ODA_FOCUS:
              GetClassName( GetParent( lp->hwndItem ), szName, 30 );
              if( lp->CtlType == ODT_COMBOBOX || szName[ 5 ] != '0' )
                 DrawFocusRect( lp->hDC, &lp->rcItem );
              break;
      }
   }
   hb_retl( TRUE );

}

//----------------------------------------------------------------------------//

HB_FUNC( LBXGETID ) // ( LPDRAWITEMSTRUCT lp )
{
   LPDRAWITEMSTRUCT lp = ( LPDRAWITEMSTRUCT ) hb_parnl( 1 );
   
   hb_retni( lp->itemID );
}

//----------------------------------------------------------------------------//

HB_FUNC( LBGETRECT ) // ( hwnd, nIndex )
{
   RECT rect;

   hb_retni( SendMessage( (HWND) hb_parnl( 1 ), LB_GETITEMRECT, hb_parni( 2 ),
		(LPARAM) (LPRECT) &rect ) );

   hb_reta( 4 );

   hb_storvni( rect.top,	 -1, 1 );
   hb_storvni( rect.left,	 -1, 2 );
   hb_storvni( rect.bottom, -1, 3 );
   hb_storvni( rect.right,  -1, 4 );
}

//----------------------------------------------------------------------------//

static void LineToDot( HDC hDC, int xEnd, int yEnd ) // [ByHernanCeccarelli]
{
 POINT pInicial ;
 RECT rect ;

     GetCurrentPositionEx( hDC, &pInicial );
     rect.top    = pInicial.y ;
     rect.left   = pInicial.x ;
     rect.bottom = yEnd ;
     rect.right  = xEnd ;
     FrameDot( hDC, &rect );
     MoveTo( hDC, xEnd, yEnd );

}

//----------------------------------------------------------------------------//

static void FrameDot( HDC hDC, RECT * pRect )
{
   HBITMAP hbmp;
   HBRUSH hbr, hbrPrevious ;
   unsigned short aChecker[] = { 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 };
   RECT rct;

   rct.top    = pRect->top;
   rct.left   = pRect->left;
   rct.bottom = pRect->bottom + 1;
   rct.right  = pRect->right + 1;

   hbmp = CreateBitmap( 8, 8, 1, 1, aChecker );
   hbr  = CreatePatternBrush( hbmp );

   UnrealizeObject( hbr );
   hbrPrevious = ( HBRUSH ) SelectObject( hDC, hbr );

   FrameRect( hDC, &rct, hbr );

   SelectObject( hDC, hbrPrevious );
   DeleteObject( hbr );
   DeleteObject( hbmp );
}

//----------------------------------------------------------------------------//