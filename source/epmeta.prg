/** @package

        mymeta.prg

        Copyright() Formglas Neon GmbH 2000

        Author: JUERGEN BAEZ
        Created: JB  03.11.2001 16:15:15
   Last change: JB 07.03.2006 18:40:43
*/
#include "FiveWin.ch"
#include "Struct.ch"

#define MM_ANISOTROPIC         8
#define MM_ISOTROPIC           7

#define SW_HIDE                0
#define SW_SHOWNA              8
#define META_PIXEL             1
#define META_010MM             2


//----------------------------------------------------------------------------//
CLASS EPMetaFile FROM TControl

   DATA   hMeta
   DATA   oPen
   DATA   nWidth, nHeight, nXorig, nYorig, nXZoom, nYZoom
   DATA   lZoom, lShadow
   DATA   nyfactor
   DATA   blDblClicked
   DATA   lBorder as LOGIC INIT .T.
   DATA   nPageBorColor
   DATA   nPrnXOffset as NUMERIC INIT 0
   DATA   nPrnYOffset as NUMERIC INIT 0
   DATA   nShadow_Deep  as NUMERIC INIT 5
   DATA   nShadow_Width as NUMERIC INIT 5
   DATA   nShadow_Color
   DATA   nPageHeight
   DATA   nPageWidth
   DATA   oPrev
   DATA   cMetaFormat as CHARACTER INIT "EMF"
   DATA   oPenborder
   DATA   nMWidth as NUMERIC INIT 0
   DATA   nMHeight as NUMERIC INIT 0


   CLASSDATA lRegistered AS LOGICAL

   METHOD New( nTop, nLeft, nWidth, nHeight, cMetaFile, oWnd,;
               nClrFore, nClrBack, oPrev ) CONSTRUCTOR

   METHOD Redefine( nId, cMetaFile, oWnd, nClrFore, nClrBack ) CONSTRUCTOR

   METHOD Display() INLINE ::BeginPaint(), ::Paint(), ::EndPaint(), 0
   METHOD Paint()
   METHOD SetFile(cFile)

   METHOD Shadow()
   METHOD epShadow()
   METHOD End()

   METHOD ZoomIn()  INLINE IIF(!::lZoom, (::nWidth  /= ::nXZoom ,;
                                          ::nHeight /= ::nYZoom ,;
                                          ::lZoom   :=      .T. ,;
                                          ::Refresh()), )
   METHOD ZoomOut() INLINE IIF(::lZoom , (::nWidth  *= ::nXZoom ,;
                                          ::nHeight *= ::nYZoom ,;
                                          ::lZoom   := .F.      ,;
                                          ::nXorig  := 0        ,;
                                          ::nYorig  := 0        ,;
                                          ::Refresh()), )

   METHOD SetZoomFactor(nXFactor, nYFactor)

   METHOD SetOrg(nX,nY)    INLINE iif(nX != NIL, ::nXorig := nX ,) ,;
                                  iif(nY != NIL, ::nYorig := nY ,)

   METHOD HandleEvent( nMsg, nWParam, nLParam )  // for mouse wheel support

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( nTop, nLeft, nWidth, nHeight, cMetaFile, oWnd,;
            nClrFore, nClrBack, oPrev )  CLASS EPMetaFile

   #ifdef __XPP__
      #undef New
   #endif

   DEFAULT nWidth := 100, nHeight := 100, oWnd := GetWndDefault()

   ::nTop     := nTop
   ::nLeft    := nLeft
   ::nBottom  := nTop + nHeight - 1
   ::nRight   := nLeft + nWidth - 1
   ::cCaption := cMetaFile
   ::oWnd     := oWnd
   ::nStyle   := nOr( WS_CHILD, WS_VISIBLE )
   //Timm Ende
   ::oPrev    := oPrev
   ::nWidth   := oPrev:nHorzRes
   ::nHeight  := oPrev:nVertRes

   *::nWidth   := oPrev:oDevice:nHorzRes()
   *::nHeight  := oPrev:oDevice:nVertRes()
   //Timm Ende

   ::lZoom    := .F.
   ::lShadow  := .T.
   ::nXorig   := 0
   ::nYorig   := 0
   ::hMeta    := 0
   ::nXZoom   := 2
   ::nYZoom   := 4
   ::nyfactor := 1
   ::nPrnXOffset   := oPrev:oDevice:nXOffset
   ::nPrnYOffset   := oPrev:oDevice:nYOffset
   ::nShadow_Deep  := oPrev:nShadow_Deep
   ::nShadow_Width := oPrev:nShadow_Width
   ::nShadow_Color := oPrev:nShadow_Color

   //Timm Start
   ::nPageWidth  := oPrev:nHorzRes
   ::nPageHeight := oPrev:nVertRes

   //::nPageWidth  := oPrev:oDevice:nHorzRes()
   //::nPageHeight := oPrev:oDevice:nVertRes()
   //Timm Ende

   ::lBorder       := oPrev:lPageBorder
   ::nPageBorColor := oPrev:nPageBorColor

   ::cMetaformat   := oPrev:cMetaFormat
    #ifdef __XPP__
       DEFAULT ::lRegistered := .f.
   #endif

   ::Register()

   ::SetColor(nClrFore, ::nPageBorColor)

   if ::lShadow
     DEFINE PEN ::oPen WIDTH ::nShadow_Width  COLOR ::nShadow_Color
   endif

   DEFINE PEN ::oPenborder WIDTH 0 COLOR ::nPageBorColor //STYLE oPrev:nPageBorStyle

   if oWnd:lVisible
      ::Create()
      ::Default()
      ::lVisible = .t.
      oWnd:AddControl( Self )
   else
      oWnd:DefControl( Self )
      ::lVisible  = .f.
   endif

return Self

//----------------------------------------------------------------------------//

METHOD Redefine( nId, cMetaFile, oWnd, nClrFore, nClrBack ) CLASS EPMetaFile

   DEFAULT oWnd := GetWndDefault()

   ::nId      := nId
   ::cCaption := cMetaFile
   ::oWnd     := oWnd
   ::nWidth   := 100
   ::nHeight  := 100
   ::hMeta    := 0
   ::lShadow  := .t.
   ::nyfactor := 1
   #ifdef __XPP__
      DEFAULT ::lRegistered := .f.
   #endif

   ::Register()

   ::SetColor( nClrFore, ::nPageBorColor) //nClrBack )
*   ::SetColor(::nPageBorColor , ::nPageBorColor) //nClrBack )
   oWnd:DefControl( Self )

return Self

//----------------------------------------------------------------------//

METHOD Paint() CLASS EPMetaFile

   local oRect     := ::GetRect()
   local arect     := array(4)
   local nWidth
   local nHeight
   local nyfactor
   local hOldMeta

   IF ::hMeta == 0

        IF file(::cCaption)
          if ::cMetaFormat = "WMF"
             hOldMeta   := getMetaFile(::cCaption)
             ::hMeta    := wmf2emf(::hdc,hOldMeta)
             DeleteMetafile(hOldMeta)
          else
             ::hMeta    := GetEnhMetaFile( ::cCaption )
          endif
        ELSEIF !empty(::cCaption)
            Alert("Could not find the Metafile,"+CRLF+;
                 "please check your TEMP environment variable")
        ENDIF
   ENDIF

   IF ::hMeta != 0

        arect      := enhmetasize(::hMeta,META_PIXEL)

        ::nMWidth  :=arect[3]
        ::nMHeight :=arect[4]

        arect[1] := 0
        arect[2] := 0

        // Neu nötig, da printer.prg geändert wurde//
        arect[3] := ::nPageWidth
        arect[4] := ::nPageHeight
        // Ende neu

        arect[3]  -=  2* ::nPrnXOffset
        arect[4]  -=  2* ::nPrnYOffset

        nyfactor  := if(::lzoom,::nyfactor,1)

        SetMapMode( ::hdc, MM_ANISOTROPIC )
        SetWindowOrg(::hdc, ::nXorig-::nPrnXOffset, ::nYorig-::nPrnYOffset)
        SetWindowExt( ::hdc, ::nWidth, ::nHeight )
        SetViewportExt( ::hdc, oRect:nRight - oRect:nLeft,;
                       nyfactor* (oRect:nBottom - oRect:nTop) )

        CursorWait()
        Rectangle( ::hDC, -::nPrnYOffset ,-::nPrnXOffset,::nPageHeight- ::nPrnYOffset,;
                           ::nPageWidth - ::nPrnXOffset)//, ::openborder:hpen)

        if ::lborder
             Rectangle(::hDC, -2 ,-2,::nPageHeight-2* ::nPrnYOffset,;
                       ::nPageWidth - 2*::nPrnXOffset, ::openborder:hpen)
        endif

        EP_PlayEnhMetaFile( ::hdc, ::hMeta ,arect )

        CursorArrow()
        ::Shadow()
        ::epShadow()
   ENDIF

return nil

//----------------------------------------------------------------------------//

METHOD SetFile(cFile) CLASS EPMetaFile

     IF file(cFile)
          ::cCaption := cFile
     ELSE
          ::cCaption := ""
     ENDIF

     IF ::hMeta != 0
          #ifdef __HARBOUR__
             DeleteEnhMetafile(::hMeta)
          #else
             DeleteMetafile(::hMeta)
          #endif
          ::hMeta := 0
     ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD Shadow() CLASS EPMetaFile

     IF ! ::lShadow
          RETURN NIL
     ENDIF

     ::oWnd:GetDC()
     MoveTo( ::oWnd:hDC              ,;
          ::nLeft + ::nShadow_Deep   ,;
          ::nBottom )
     LineTo( ::oWnd:hDC              ,;
          ::nRight                   ,;
          ::nBottom                  ,;
          ::oPen:hPen )
     MoveTo( ::oWnd:hDC              ,;
          ::nRight                   ,;
          ::nTop + ::nShadow_Deep )
     LineTo( ::oWnd:hDC              ,;
          ::nRight                ,;
          ::nBottom               ,;
          ::oPen:hPen )
     ::oWnd:ReleaseDC()

RETURN NIL
//------------------  ------------------------//

METHOD epShadow() CLASS EPMetaFile

LOCAL nleft,ntop,nbottom,nright

     nleft   :=-::nPrnXOffset
     ntop    :=-::nPrnYOffset
     nRight  := ::nPageWidth - ::nPrnXOffset
     nBottom := ::nPageHeight- ::nPrnYOffset
    * ::oPen:nWidth*=2 //*::nXZoom

     MoveTo( ::hDC              ,;
          nLeft + ::nShadow_Deep   ,;
          nBottom )
     LineTo( ::hDC              ,;
          nRight                   ,;
          nBottom                 ,;
          ::oPen:hPen )
     MoveTo( ::hDC              ,;
          nRight                   ,;
          nTop + ::nShadow_Deep )   // JB //
     LineTo( ::hDC              ,;
          nRight                ,;
          nBottom               ,;
          ::oPen:hPen )

RETURN NIL

//----------------------------------------------------------------------------//
METHOD End() CLASS EPMetaFile

     IF ::hMeta != 0
        #ifdef __HARBOUR__
             DeleteEnhMetafile(::hMeta)
          #else
             DeleteMetafile(::hMeta)
          #endif
          ::hMeta := 0
     ENDIF

     IF ::lShadow
          ::oPen:End()
     ENDIF
     ::oPenborder:End()
     ::Super:End()

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SetZoomFactor(nX, nY) CLASS EPMetaFile

     IF ::lZoom
          ::nWidth  *= ::nXZoom
          ::nHeight *= ::nYZoom
     ENDIF
     ::nXZoom := nX
     ::nYZoom := nY //* 1.5

     IF ::lZoom
          ::nWidth  /= ::nXZoom
          ::nHeight /= ::nYZoom
          ::Refresh()
     ENDIF

RETURN NIL

//----------------------------------------------------------------------------//
// for mouse wheel support

METHOD HandleEvent( nMsg, nWParam, nLParam ) CLASS EPMetafile

   Local nDelta, nRow, nCol, aCoors

   If nMsg == 522 .AND. ::oPrev:lZoom = .T.  //Timm

      nCol := nLoWord( nLParam )
      nRow := nHiWord( nLParam )
      aCoors := ClientToScreen( ::hWnd, aCoors )

      If nRow >= aCoors[ 1 ] .and. nCol >= aCoors[ 2 ] .and. ;
         nRow <= ( aCoors[ 1 ] + ::nHeight() )  .and. ;
         nCol <= ( aCoors[ 2 ] + ::nWidth() )

         nDelta := Bin2I( I2Bin( nHiWord( nWParam ) ) ) / 120

         If ( nDelta ) > 0
            nWParam := SB_PAGEUP
         Else
            nWParam := SB_PAGEDOWN
            nDelta := -nDelta
         EndIf

         While nDelta > 1
            ::oWnd:VScroll( nWParam, 0 )
            nDelta--
         EndDo

         Return ::oWnd:VScroll( nWParam, 0 )

      EndIf

   Endif

Return ::Super:HandleEvent( nMsg, nWParam, nLParam )

//------------------  ------------------------//
// Eigenen Metafilefuctionen //
//------------------ c inline------------------------//


#pragma BEGINDUMP

#include <windows.h>
#include "hbapi.h"

HB_FUNC(EP_PLAYENHMETAFILE)

{
 RECT rect;
 HENHMETAFILE  hemf =(HENHMETAFILE) hb_parnl( 2 );
 HDC           hDC  = ( HDC ) hb_parnl( 1 );

// GetEnhMetaFileHeader( hemf, sizeof( mh ), &mh ) ;

   if( hb_parl( 4 ) )
   {
      rect.left = 0;
      rect.top  = 0;
      rect.right  = GetDeviceCaps( ( HDC ) hb_parnl( 1 ), HORZRES );
      rect.bottom = GetDeviceCaps( ( HDC ) hb_parnl( 1 ), VERTRES );
   }
   else
   if (HB_IS_ARRAY(3))
     {
       rect.left   = hb_parvni( 3, 1 );
       rect.top    = hb_parvni( 3, 2 );
       rect.right  = hb_parvni( 3, 3 );
       rect.bottom = hb_parvni( 3, 4 );
     }
   else
 //     GetClientRect( WindowFromDC( hDC ), &rc );
      GetClientRect ( (HWND)hb_parnl( 3 ), &rect );
 hb_retl( PlayEnhMetaFile( hDC, hemf, ( LPRECT ) &rect ) );
}
//------------------  ------------------------//
HB_FUNC(ENHMETASIZE)
{
   HENHMETAFILE hemf = (HENHMETAFILE) hb_parnl( 1 );
   INT  sizetyp      =  hb_parni( 2 );
   ENHMETAHEADER mh ;
   RECTL rect ;

   GetEnhMetaFileHeader( hemf, sizeof( mh ), &mh ) ;

   if (sizetyp == 1 )     // Size in Pixel
      rect = mh.rclBounds ;
   else
      rect = mh.rclFrame ;  //Size in 0.1 mm

   hb_reta( 4 );
   hb_storvni(rect.left  , -1, 1 );
   hb_storvni(rect.top   , -1, 2 );
   hb_storvni(rect.right , -1, 3 );
   hb_storvni(rect.bottom, -1, 4 );
}
//------------------  ------------------------//
HB_FUNC(WMF2EMF)

{
  HENHMETAFILE hmf   ;
  HMETAFILE    hmfold  =(HMETAFILE) hb_parnl( 2 ) ;
  UINT         nSize     = GetMetaFileBitsEx( hmfold, 0, NULL ) ;

  HGLOBAL hGlobal = GlobalAlloc( GPTR, nSize );
  LPVOID lpvData = ( LPVOID ) GlobalLock( hGlobal );

  GetMetaFileBitsEx( hmfold, nSize, lpvData ) ;
  hmf       = SetWinMetaFileBits( nSize, lpvData, ( HDC ) hb_parnl( 1 ), NULL ) ;

  GlobalUnlock( hGlobal );
  GlobalFree( hGlobal );

  hb_retnl( (LONG)hmf  );
}

//--------------------------------------------------------------------//
/*
HB_FUNC(CREATEENHMETAFILE) // ()  hDC, hMetaFile  --> lSuccess
{

LPCTSTR cFile = NULL ;
RECT  rect           ;
HDC   hDC  = ( HDC ) hb_parnl( 1 );
SetRect( &rect, 0, 0, GetDeviceCaps(hDC, HORZSIZE ) * 100, GetDeviceCaps( hDC, VERTSIZE ) * 100 );

if( ISCHAR( 2 ) ) cFile= hb_parc( 2 );

// geht nicht bei 2 Seite
//hb_retnl( ( LONG ) CreateEnhMetaFile( hDC ,cFile ,&rect, NULL ) );

hb_retnl( ( LONG ) CreateEnhMetaFile(hDC,cFile , NULL, NULL ));

}
*/


#pragma STOPDUMP




