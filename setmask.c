#include <Windows.h>
#include <hbapi.h>

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

HB_FUNC( SETMASKED ) // ( hBitmap , lMaskColor) --> nil
{
   SetMasked( ( HBITMAP ) hb_parnl( 1 ) , hb_parnl( 2 )  );
}

//----------------------------------------------------------------------------//

HB_FUNC( CHANGECOL ) // ( hBitmap, lMaskColor, lOldMask) --> nil
{
   ChangeCol( ( HBITMAP ) hb_parnl( 1 ) , hb_parnl( 2 ), hb_parnl( 3 )  );
}

//----------------------------------------------------------------------------//

HB_FUNC( SETGRAYMASED ) // ( hBitmap , lMaskColor, lMaskColor) --> nil
{
   SetGrayMasked( ( HBITMAP ) hb_parnl( 1 ) );
}

//----------------------------------------------------------------------------//

