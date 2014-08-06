#include <WinTen.h>
#include <Windows.h>
#include <ClipApi.h>

//----------------------------------------------------------------------------//

#ifdef __HARBOUR__
   HARBOUR HB_FUN_DPTOLP( PARAMS ) // ( hDC, aPoint ) --> lSuccess
#else
   CLIPPER DPTOLP( PARAMS ) // ( hDC, aPoint ) --> lSuccess
#endif
{
   POINT pt;                             // just one point
   BOOL  bOk;

   #ifdef __FLAT__
      #ifndef __HARBOUR__
         #define _parnl( x, y ) PARNL( x, params, y )
      #endif
   #endif

   pt.y = _parnl( 2, 2 );
   pt.x = _parnl( 2, 1 );

   #ifdef __FLAT__
      #ifndef __HARBOUR__
         #define _parnl( x ) PARNL( x, params )
      #endif
   #endif

   bOk = DPtoLP( ( HDC ) _parnl( 1 ), ( LPPOINT ) &pt, 1 );
   _retl( bOk );

   if( bOk )
   {
      #ifdef __FLAT__
         #ifndef __HARBOUR__
            #define _stornl( x, y, z ) STORNL( x, params, y, z )
         #endif
      #endif

      _stornl( pt.y, 2, 2 );
      _stornl( pt.x, 2, 1 );
   }
}

//----------------------------------------------------------------------------//

#ifdef __HARBOUR__
   HARBOUR HB_FUN_LPTODP( PARAMS )
#else
   CLIPPER LPTODP( PARAMS )
#endif  
{
   POINT pt;                             // just one point
   BOOL  bOk;

   #ifdef __FLAT__
      #ifndef __HARBOUR__
         #define _parnl( x, y ) PARNL( x, params, y )
      #endif
   #endif

   pt.y = _parnl( 2, 2 );
   pt.x = _parnl( 2, 1 );

   #ifdef __FLAT__
      #ifndef __HARBOUR__
         #define _parnl( x ) PARNL( x, params )
      #endif
   #endif

   bOk = LPtoDP( ( HDC ) _parnl( 1 ), ( LPPOINT ) &pt, 1 );
   _retl( bOk );

   if( bOk )
   {
      _stornl( pt.y, 2, 2 );
      _stornl( pt.x, 2, 1 );
   }
}

//----------------------------------------------------------------------------//
