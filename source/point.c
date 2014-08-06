#include <Windows.h>
#include <hbapi.h>

//----------------------------------------------------------------------------//

HB_FUNC( ER_DPTOLP ) // ( hDC, aPoint ) --> lSuccess
{
   POINT pt;                             // just one point
   BOOL  bOk;

   #ifdef __FLAT__
      #ifndef __HARBOUR__
         #define hb_parnl( x, y ) PARNL( x, params, y )
      #endif
   #endif

   pt.y = hb_parvnl( 2, 2 );
   pt.x = hb_parvnl( 2, 1 );

   #ifdef __FLAT__
      #ifndef __HARBOUR__
         #define hb_parnl( x ) PARNL( x, params )
      #endif
   #endif

   bOk = DPtoLP( ( HDC ) hb_parnl( 1 ), ( LPPOINT ) &pt, 1 );
   hb_retl( bOk );

   if( bOk )
   {
      #ifdef __FLAT__
         #ifndef __HARBOUR__
            #define hb_stornl( x, y, z ) STORNL( x, params, y, z )
         #endif
      #endif

      hb_storvnl( pt.y, 2, 2 );
      hb_storvnl( pt.x, 2, 1 );
   }
}

//----------------------------------------------------------------------------//

HB_FUNC( ER_LPTODP )
{
   POINT pt;                             // just one point
   BOOL  bOk;

   #ifdef __FLAT__
      #ifndef __HARBOUR__
         #define hb_parnl( x, y ) PARNL( x, params, y )
      #endif
   #endif

   pt.y = hb_parvnl( 2, 2 );
   pt.x = hb_parvnl( 2, 1 );

   #ifdef __FLAT__
      #ifndef __HARBOUR__
         #define hb_parnl( x ) PARNL( x, params )
      #endif
   #endif

   bOk = LPtoDP( ( HDC ) hb_parnl( 1 ), ( LPPOINT ) &pt, 1 );
   hb_retl( bOk );

   if( bOk )
   {
      hb_storvnl( pt.y, 2, 2 );
      hb_storvnl( pt.x, 2, 1 );
   }
}

//----------------------------------------------------------------------------//
