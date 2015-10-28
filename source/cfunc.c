// #include "C:\Entwicklung\FiveWin\FWH2007-12\include\fwharb.h"
#include <windows.h>
#include <hbapi.h>

#define _FWH_1408_

// Controls mouse-resizing types in design mode
#define RES_NW             1
#define RES_N              2
#define RES_NE             3
#define RES_E              4
#define RES_SE             5
#define RES_S              6
#define RES_SW             7
#define RES_W              8

//----------------------------------------------------------------------------//

HB_FUNC( SHOWGRID ) // hDC, @cPS, wGridWidth, wGridHeight, wWidth, wHeight, wTopRuler, wRuler
{
   WORD wRow, wCol;
   HDC hDC = ( HDC ) hb_parnl( 1 );
   // PAINTSTRUCT * ps = ( PAINTSTRUCT * ) hb_parc( 2 );
   WORD wGridWidth  = hb_parni( 3 );
   WORD wGridHeight = hb_parni( 4 );
   WORD wWidth      = hb_parni( 5 );
   WORD wHeight     = hb_parni( 6 );
   WORD wTopRuler   = hb_parni( 7 );
   WORD wRuler      = hb_parni( 8 );

   for( wRow = wTopRuler; wRow <= wTopRuler + wHeight - 2; wRow += wGridHeight )
      for( wCol = wRuler; wCol <= wRuler + wWidth - 2; wCol += wGridWidth )
         SetPixel( hDC, wCol, wRow, 0 );
}

#if ! defined( _FWH_1408_ )
//----------------------------------------------------------------------------//

HB_FUNC( CTRLDRAWFOCUS )  // ( hWnd, nOriginRow, nOriginCol, nMRow, nMCol, nMResize )
{
   HWND hWnd = ( HWND ) hb_parnl( 1 );
   int wRow  = hb_parnl( 2 );
   int wCol  = hb_parnl( 3 );
   int wMRow = hb_parnl( 4 );
   int wMCol = hb_parnl( 5 );
   WORD wMResize = hb_parnl( 6 );
   HWND hWndParent = GetParent( hWnd );
   HDC hDC;
   RECT rct;
   POINT pt;
   HRGN hReg;
   HBRUSH hBr = CreateSolidBrush( RGB( 127, 127, 127 ) );
   int iRop;
   int iParentsWithCaption = 0;

   if( ( GetWindowLong( hWndParent, GWL_STYLE ) & WS_CAPTION ) == WS_CAPTION )
      iParentsWithCaption++;

   while( GetParent( hWndParent ) )
   {
      #ifndef UNICODE
   	     char ClassName[ 100 ];
   	  
   	     GetClassName( hWndParent, ClassName, 99 );

      	 if( strcmp( ClassName, "#32770" ) == 0 ) // a Modal Dialog
   	        break;

   	     if( lstrcmp( ClassName, "MDIClient" ) == 0 ) // MDIClient
   	        iParentsWithCaption++;	  

   	  #else   
   	     WCHAR ClassName[ 100 ];
   	  
   	     GetClassName( hWndParent, ClassName, 99 * sizeof( WCHAR ) );

   	     if( lstrcmp( ClassName, L"#32770" ) == 0 ) // a Modal Dialog
   	        break;

   	     if( lstrcmp( ClassName, L"MDIClient" ) == 0 ) // MDIClient
   	        iParentsWithCaption++;	  

      #endif
         	  
      hWndParent = GetParent( hWndParent );
      
      if( ( GetWindowLong( hWndParent, GWL_STYLE ) & WS_CAPTION ) == WS_CAPTION )
   	     iParentsWithCaption++;
   }   

   GetWindowRect( hWnd, &rct );

   if( ! wMResize || ( ! wRow && ! wCol ) )
   {
      rct.bottom += wRow;
      rct.right  += wCol;
      rct.top    += wRow;
      rct.left   += wCol;
   }
   else
   {
      pt.x = wMCol;
      pt.y = wMRow;
      ClientToScreen( hWnd, &pt );
      wMRow = pt.y;
      wMCol = pt.x;

      switch( wMResize )
      {
         case RES_NW:
              rct.top  = wMRow;
              rct.left = wMCol;
              break;

         case RES_N:
              rct.top = wMRow;
              break;

         case RES_NE:
              rct.top   = wMRow;
              rct.right = wMCol;
              break;

         case RES_E:
              rct.right = wMCol;
              break;

         case RES_SE:
              rct.bottom = wMRow;
              rct.right  = wMCol;
              break;

         case RES_S:
              rct.bottom = wMRow;
              break;

         case RES_SW:
              rct.bottom = wMRow;
              rct.left   = wMCol;
              break;

         case RES_W:
              rct.left = wMCol;
              break;
      }
   }

   pt.x = rct.left;
   pt.y = rct.top;
   ScreenToClient( hWndParent, &pt );
   rct.left = pt.x + ( iParentsWithCaption * GetSystemMetrics( SM_CXFRAME ) );
   rct.top  = pt.y + ( iParentsWithCaption * ( GetSystemMetrics( SM_CYCAPTION	) + GetSystemMetrics( SM_CYFRAME ) ) );
   
   pt.x     = rct.right;
   pt.y     = rct.bottom;
   ScreenToClient( hWndParent, &pt );
   rct.right  = pt.x + ( iParentsWithCaption * GetSystemMetrics( SM_CXFRAME ) );
   rct.bottom = pt.y + ( iParentsWithCaption * ( GetSystemMetrics( SM_CYCAPTION	) + GetSystemMetrics( SM_CYFRAME ) ) );

   if( ( GetWindowLong( hWndParent, GWL_STYLE ) & DS_MODALFRAME ) == DS_MODALFRAME ) 
   {
      rct.left   -= 4;
      rct.top    -= 4;
      rct.right  -= 4;
      rct.bottom -= 4;		
   } 
 
   if( iParentsWithCaption > 1 )
   {
      rct.left   -=  8;
      rct.top    -= 10;
      rct.right  -=  7;
      rct.bottom -=  9;		
   } 
 
   hReg = CreateRectRgn( rct.left, rct.top, rct.right, rct.bottom );

   hDC = GetWindowDC( hWndParent ); 
   iRop = SetROP2( hDC, R2_XORPEN );
   FrameRgn( hDC, hReg, hBr, 2, 2 );
   SetROP2( hDC, iRop );
   ReleaseDC( hWndParent, hDC );
   DeleteObject( hReg );
   DeleteObject( hBr );
}
#endif

//----------------------------------------------------------------------------//

HB_FUNC( DOTSADJUST ) // ( hWndParent, hDot1, hDot2, ... ) --> nil
{
   HWND hWndParent = ( HWND ) hb_parnl( 1 );
   HWND hWndDot1   = ( HWND ) hb_parnl( 2 );
   HWND hWndDot2   = ( HWND ) hb_parnl( 3 );
   HWND hWndDot3   = ( HWND ) hb_parnl( 4 );
   HWND hWndDot4   = ( HWND ) hb_parnl( 5 );
   HWND hWndDot5   = ( HWND ) hb_parnl( 6 );
   HWND hWndDot6   = ( HWND ) hb_parnl( 7 );
   HWND hWndDot7   = ( HWND ) hb_parnl( 8 );
   HWND hWndDot8   = ( HWND ) hb_parnl( 9 );
   HWND hWndDialog = GetParent( hWndParent );
   RECT rct;
   POINT pt;

   GetWindowRect( hWndParent, &rct );

   // top left
   pt.y = -5;
   pt.x = -5;
   ClientToScreen( hWndParent, &pt );
   ScreenToClient( hWndDialog, &pt );
   SetWindowPos( hWndDot1, HWND_TOP, pt.x, pt.y, 5, 5, SWP_NOACTIVATE );
   InvalidateRect( hWndDot1, 0, TRUE );

   // top middle
   pt.y = -5;
   pt.x = ( ( rct.right - rct.left ) / 2 ) - 2;
   ClientToScreen( hWndParent, &pt );
   ScreenToClient( hWndDialog, &pt );
   SetWindowPos( hWndDot2, HWND_TOP, pt.x, pt.y, 5, 5, SWP_NOACTIVATE );
   InvalidateRect( hWndDot2, 0, TRUE );

   // top right
   pt.y = -5;
   pt.x = rct.right - rct.left - 2;
   ClientToScreen( hWndParent, &pt );
   ScreenToClient( hWndDialog, &pt );
   SetWindowPos( hWndDot3, HWND_TOP, pt.x, pt.y, 5, 5, SWP_NOACTIVATE );
   InvalidateRect( hWndDot3, 0, TRUE );

   // middle left
   pt.y = ( ( rct.bottom - rct.top ) / 2 ) - 3;
   pt.x = rct.right - rct.left - 2;
   ClientToScreen( hWndParent, &pt );
   ScreenToClient( hWndDialog, &pt );
   SetWindowPos( hWndDot4, HWND_TOP, pt.x, pt.y, 5, 5, SWP_NOACTIVATE );
   InvalidateRect( hWndDot4, 0, TRUE );

   // bottom right
   pt.y = rct.bottom - rct.top - 2;
   pt.x = rct.right - rct.left - 2;
   ClientToScreen( hWndParent, &pt );
   ScreenToClient( hWndDialog, &pt );
   SetWindowPos( hWndDot5, HWND_TOP, pt.x, pt.y, 5, 5, SWP_NOACTIVATE );
   InvalidateRect( hWndDot5, 0, TRUE );

   // bottom middle
   pt.y = rct.bottom - rct.top - 2;
   pt.x = ( ( rct.right - rct.left ) / 2 ) - 2;
   ClientToScreen( hWndParent, &pt );
   ScreenToClient( hWndDialog, &pt );
   SetWindowPos( hWndDot6, HWND_TOP, pt.x, pt.y, 5, 5, SWP_NOACTIVATE );
   InvalidateRect( hWndDot6, 0, TRUE );

   // bottom middle
   pt.y = rct.bottom - rct.top - 2;
   pt.x = -5;
   ClientToScreen( hWndParent, &pt );
   ScreenToClient( hWndDialog, &pt );
   SetWindowPos( hWndDot7, HWND_TOP, pt.x, pt.y, 5, 5, SWP_NOACTIVATE );
   InvalidateRect( hWndDot7, 0, TRUE );

   // middle left
   pt.y = ( ( rct.bottom - rct.top ) / 2 ) - 3;
   pt.x = -5;
   ClientToScreen( hWndParent, &pt );
   ScreenToClient( hWndDialog, &pt );
   SetWindowPos( hWndDot8, HWND_TOP, pt.x, pt.y, 5, 5, SWP_NOACTIVATE );
   InvalidateRect( hWndDot8, 0, TRUE );
}

//----------------------------------------------------------------------------//