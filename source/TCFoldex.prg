#include "FiveWin.ch"
#include "constant.ch"

//
// TCFolderEx -> Cristobal Navarro:   - 28/09/2014 -  Primera implementacion
//

#define CLRTEXT           RGB(  21,  66, 139 )
#define DEFAULT_GUI_FONT  17
#define COLOR_GRAYTEXT    17
#define LAYOUT_TOP        1
#define LAYOUT_LEFT       2
#define LAYOUT_BOTTOM     3
#define LAYOUT_RIGHT      4

/*
#define CLRTEXT             RGB(  21,  66, 139 )
#define WM_MOUSELEAVE       0x2A3 //675
#define TME_LEAVE           0x2   //2
#define DEFAULT_GUI_FONT    17

#define TXTLPAD              15
#define TXTRPAD               5
#define COLOR_GRAYTEXT       17
#define DT_VCENTER            4
#define DT_SINGLELINE        32
#define DT_CENTER             1
#define VTA_BASELINE         24
#define VTA_CENTER            6


#define LAYOUT_TOP     1
#define LAYOUT_LEFT    2
#define LAYOUT_BOTTOM  3
#define LAYOUT_RIGHT   4
/*
#define AL_LEFT   0
#defiNE AL_RIGHT  1
#define AL_CENTER 2
*/
/*
#define BMP_HANDLE 1
#define BMP_WIDTH  2
#define BMP_HEIGHT 3
*/

static aLayouts := { "TOP", "LEFT", "BOTTOM", "RIGHT" }


CLASS TCFolderEx FROM TFolderEx

   CLASSDATA lRegistered AS LOGICAL

   METHOD New( nTop, nLeft, nWidth, nHeight, oWnd, aBitmaps, lPixel,;
               lDesign, aPrompts, nFolderHeight, ;
               aHelps, nRound, bAction, bClrTabs, bClrText, aAlign, ;
               lAdjust, nSeparator, nOption, bPopUp, lStretch, ;
               cLayOut, bBmpAction, nBright, lAnimate, nSpeed, oFont,;
               lTransparent, aDialogs ) CONSTRUCTOR 

ENDCLASS


//----------------------------------------------------------------------------//

METHOD New( nTop, nLeft, nWidth, nHeight, oWnd, aBitmaps, lPixel,;
            lDesign, aPrompts, nFolderHeight, ;
            aHelps, nRound, bAction, bClrTabs, bClrText, aAlign, ;
            lAdjust, nSeparator, nOption, bPopUp, lStretch, ;
            cLayOut, bBmpAction, nBright, lAnimate, nSpeed, oFont,;
            lTransparent, aDialogs  ) CLASS TCFolderEx 

   LOCAL n, oDlg, nLastRow, nLen, aRect, hRgn, aFontINfo

   DEFAULT nTop     := 0, nLeft := 0,;
           oWnd     := GetWndDefault(),;
           lPixel   := .F.,;
           lDesign  := .f.,;
           nWidth   := 300, nHeight := 200,;
           aPrompts := { { "One", "Two", "Three" } },;
           nFolderHeight := 25,;
           nRound   := 3,;
           bClrTabs := {| o, n | ::SetFldColors( o, n ) },;
           bClrText := {| o, n | If( ::aEnable[ n ], CLRTEXT, GetSysColor( COLOR_GRAYTEXT ) ) },;
           lAdjust  := .F.,;
           nSeparator := 3,;
           nOption  := 1,;
           lStretch := .F.,;
           cLayout  := "TOP",;
           nBright  := 0,;
           lAnimate := .F.,;
           nSpeed   := round( 30 / ( GetCPUSpeed() / 3000 ), 0 ),;
           oFont    := NIL,;      //-->> byte-one 2010
           lTransparent := .F.,;
           aDialogs := {}

   ::nStyle    = nOR( WS_CHILD, WS_VISIBLE, WS_CLIPCHILDREN, WS_TABSTOP )
   ::nId       = ::GetNewId()
   ::oWnd      = oWnd
   ::nTop      = If( lPixel, nTop, nTop * SAY_CHARPIX_H )
   ::nLeft     = If( lPixel, nLeft, nLeft * SAY_CHARPIX_W )
   ::nBottom   = ::nTop + nHeight - 1
   ::nRight    = ::nLeft + nWidth - 1
   ::lDrag     = lDesign
   ::lCaptured = .f.
   ::nSeparator = nSeparator
   ::nLastOver = 0
   ::nOption   = nOption
   ::nOver     = 0
   ::nFolderHeight = nFolderHeight
   ::nRound   = nRound
   ::lWorking = .F.
   ::lAdjust  = lAdjust
   ::lStretch = lStretch
   ::nBright  = nBright
   ::lAnimation = lAnimate
   ::nSpeed     = nSpeed
   ::nBmpTopMargin = 0
   ::nOverBmp = 0
   ::bAction  = bAction
   ::bBmpAction = bBmpAction
//   ::oFont = oFont      //-->> byte-one 2010
   ::nLayOut = AScan( aLayouts, cLayout )
   ::lTransparent = lTransparent

   ::SetDefColors()

   ::Register()

   if ! Empty( oWnd:hWnd )
      ::Create()
      oWnd:AddControl( Self )
   else
      oWnd:DefControl( Self )
   endif

   if lDesign
      ::CheckDots()
   endif

   ::aDialogs    = {}
   ::aEnable     = {}
   ::aPos        = {}
   ::aVisible    = {}
   ::aPrompts    = CheckArr( aPrompts )
   ::aOrder      = {}
   ::aLines      = {}

   nLen = Max( Len( ::aPrompts ), Len( aDialogs ) )

   if aAlign == NIL
      aAlign = Array( nLen )
   endif

   if aHelps == NIL
      aHelps = Array( nLen )
   endif

   if aBitmaps == NIL
      aHelps = Array( nLen )
   endif

   ::aVisible   = Array( nLen )
   ::aEnable    = Array( nLen )

   AFill( ::aVisible, .T. )
   AFill( ::aEnable, .T. )


//#ifdef OLDCODE   // upto FWH 14.06 : Modified on 2014-07-25
   if !OldCode( 14, 6 )

      // verify font by user
      if oFont == nil
         // verify font by parent
         if ::oWnd:oFont == nil
            oFont := TFont():New()
            oFont:hFont := GetStockObject( DEFAULT_GUI_FONT )
            aFontInfo = GetFontInfo( oFont:hFont )
          else
            aFontInfo := GetFontInfo( ::oWnd:oFont:hFont )
          endif
      else
          aFontInfo := GetFontInfo( oFont:hFont )
      endif

      if ::nLayOut == LAYOUT_RIGHT .OR. ::nLayOut == LAYOUT_LEFT
         if hb_isObject( oFont ) // oFont is external and user provided
            oFont:end()          // This font should not :End() here  2014-07-25
         endif
         DEFINE FONT oFont NAME aFontInfo[ 4 ] ;
             SIZE aFontInfo[ 2 ], aFontInfo[ 1 ] NESCAPEMENT 900 * If( ::nLayOut == LAYOUT_RIGHT, -1, 1 )
      else
         DEFINE FONT oFont NAME aFontInfo[ 4 ] ;
             SIZE aFontInfo[ 2 ], aFontInfo[ 1 ]
      endif

      ::SetFont( oFont )
      oFont:End()
   else
//#else

      if oFont == nil
         ::GetFont()
      else
         ::SetFont( oFont )
      endif
      if ::nLayOut == LAYOUT_RIGHT .OR. ::nLayOut == LAYOUT_LEFT
         oFont    := ::oFont:Escapement( If( ::nLayOut == LAYOUT_RIGHT, 2700, 900 ) )
         ::SetFont( oFont )
         oFont:End()
      endif

   endif
//#endif

   if ::lTransparent
      if ::oWnd:oBrush != NIL
         ::SetBrush( ::oWnd:oBrush )
      else
         ::oBrush = TBrush():New( , ::oWnd:nClrPane )
      endif
   else
      ::oBrush = TBrush():New( , CLR_WHITE )
   endif

   ::nFolderHeight := max( ::nFolderHeight, ::oFont:nHeight * 1.2 )

   ::bClrTabs  = bClrTabs
   ::bClrText  = bClrText
   ::aAlign    = CheckArr( aAlign )
   ::aHelps    = CheckArr( aHelps )
   ::bPopUp    = bPopUp

   ::aDialogs = Array( nLen )
   ::aBitmaps = {}
   ::aBrightBmp = {}
   ::LoadBitmaps( aBitmaps )

   if empty( aDialogs )

      for n = 1 to nLen

         DEFINE DIALOG oDlg OF Self ;
         STYLE nOR( WS_CHILD, ;
         If( (!::oWnd:IsKindOf( "TDIALOG") .and. !::oWnd:IsKindOf( "TPANEL")),;
         WS_CLIPCHILDREN, 0 ) );
         FROM 0, 1 TO ::nHeight(), ::nWidth() PIXEL ;
         FONT ::oWnd:oFont ;
         HELPID If( Len( ::aHelps ) >= n , ::aHelps[ n ] , NIL )

         oDlg:SetBrush( ::oBrush )
         ::aDialogs[ n ] := oDlg

         oDlg:cVarName := "Page" + AllTrim( Str( n ) )
         oDlg:Hide()
         oDlg:lTransparent := .T.

      next n
      
   else
      // Usar Dialogos en RC en un Folder creado por código
      // En pruebas

      ::aDialogs  = CheckArr( aDialogs )

      for n = 1 to len( ::aDialogs )
         DEFINE DIALOG oDlg OF Self RESOURCE ::aDialogs[ n ] PIXEL;
            FONT ::oWnd:oFont ;
            HELPID If( Len( ::aHelps ) >= n , ::aHelps[ n ] , NIL ) ;
            BRUSH ::oBrush // STYLE WS_CHILD
    
         ::aDialogs[ n ] := oDlg

         oDlg:cVarName := "Page" + AllTrim( Str( n ) )
         oDlg:Hide()
         oDlg:lTransparent := .T.

      next n

   endif

   if ::hWnd != 0
      ::UpdateRegion()
   endif

   if ! Empty( oWnd:hWnd )
     ::Default()
   endif

   if lDesign
      ::CheckDots()
   endif

   SetWndDefault( oWnd )

return Self

//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//

Static Function OldCode( nVersion1, nVersion2 )  //ValidVersionFwh( nVersion1, nVersion2 )
Local lVersion   := .T.

   if GetFwVersion()[ 1 ] < nVersion1
      lVersion := .F.
   else
      if GetFwVersion()[ 1 ] = nVersion1
         if GetFwVersion()[ 2 ] < nVersion2
            lVersion := .F.
         endif
      endif
   endif

Return lVersion

//----------------------------------------------------------------------------//

static function CheckArr( aArray )

   if ValType( aArray ) == 'A' .and. ;
      Len( aArray ) == 1 .and. ;
      ValType( aArray[ 1 ] ) == 'A'

      aArray   := aArray[ 1 ]
   endif

return aArray

//----------------------------------------------------------------------------//
