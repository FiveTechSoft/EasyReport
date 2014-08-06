#include "WinTen.h"
#include "Windows.h"
#include "ClipApi.h"


void MaskRegion(HDC hdc, RECT * rct,
                       COLORREF cTransparentColor,
                       COLORREF cBackgroundColor);

//----------------------------------------------------------------------------//

void SetMasked( HBITMAP hbm , DWORD lMaskColor)
{
   HDC     hdc;
   BITMAP  bm;
   RECT    rct;

   hdc      = CreateCompatibleDC( NULL );
   GetObject( hbm, sizeof( BITMAP ), ( LPSTR ) &bm );
   SelectObject( hdc, ( HGDIOBJ ) LOWORD( hbm ) );

   rct.top = 0;
   rct.left = 0;
   rct.right = bm.bmWidth - 1;
   rct.bottom = bm.bmHeight -1;
   MaskRegion( hdc, &rct, GetPixel( hdc, 0, 0 ),
               lMaskColor);
   DeleteDC( hdc );
}

//----------------------------------------------------------------------------//

void ChangeCol( HBITMAP hbm , DWORD lMaskColor, DWORD lOldMask)
{
   HDC     hdc;
   BITMAP  bm;
   RECT    rct;

   hdc      = CreateCompatibleDC( NULL );
   GetObject( hbm, sizeof( BITMAP ), ( LPSTR ) &bm );
   SelectObject( hdc, ( HGDIOBJ ) LOWORD( hbm ) );

   rct.top = 0;
   rct.left = 0;
   rct.right = bm.bmWidth - 1;
   rct.bottom = bm.bmHeight -1;
   MaskRegion( hdc, &rct, lOldMask,lMaskColor);
   DeleteDC( hdc );
}

//----------------------------------------------------------------------------//

void SetGrayMasked( HBITMAP hbm )
{
   HDC      hdc;
   BITMAP   bm;
   DWORD    lHigh,lShadow,lMask;
   RECT     rct;

   lHigh      = GetSysColor(COLOR_BTNHIGHLIGHT);
   lShadow    = GetSysColor(COLOR_BTNSHADOW);
   lMask      = GetSysColor(COLOR_BTNFACE);
   hdc        = CreateCompatibleDC( NULL );
   GetObject( hbm, sizeof( BITMAP ), ( LPSTR ) &bm );
   SelectObject( hdc, ( HGDIOBJ ) LOWORD( hbm ) );
   rct.top = 0;
   rct.left = 0;
   rct.right = bm.bmWidth - 1;
   rct.bottom = bm.bmHeight -1;
   MaskRegion( hdc, &rct, GetPixel( hdc, 0, 0 ), lMask );
   MaskRegion( hdc, &rct, 0 , lShadow );
   MaskRegion( hdc, &rct, 255, lHigh );
   DeleteDC( hdc );
}
  
//----------------------------------------------------------------------------//

#ifdef __HARBOUR__
   HARBOUR HB_FUN_SETMASKED( PARAMS ) // ( hBitmap , lMaskColor) --> nil
#else
   CLIPPER SETMASKED( PARAMS ) // ( hBitmap , lMaskColor) --> nil
#endif
{
   SetMasked( ( HBITMAP ) _parnl( 1 ) , _parnl( 2 )  );
}

//----------------------------------------------------------------------------//

#ifdef __HARBOUR__
   HARBOUR HB_FUN_CHANGECOL( PARAMS ) // ( hBitmap, lMaskColor, lOldMask) --> nil
#else
   CLIPPER CHANGECOL( PARAMS ) // ( hBitmap, lMaskColor, lOldMask) --> nil
#endif
{
   ChangeCol( ( HBITMAP ) _parnl( 1 ) , _parnl( 2 ), _parnl( 3 )  );
}

//----------------------------------------------------------------------------//

#ifdef __HARBOUR__
   HARBOUR HB_FUN_SETGRAYMASED( PARAMS ) // ( hBitmap , lMaskColor, lMaskColor) --> nil
#else
   CLIPPER SETGRAYMAS( PARAMS ) //KED ( hBitmap , lMaskColor, lMaskColor) --> nil
#endif
{
   SetGrayMasked( ( HBITMAP ) _parnl( 1 ) );
}

//----------------------------------------------------------------------------//

