// TreeView for FiveWin for Clipper / FiveWin for Harbour / FiveWin++

#ifndef _TREEVIEW_CH
#define _TREEVIEW_CH

#define WM_SETREDRAW    11

#define TVS_HASBUTTONS		   1
#define TVS_HASLINES		   2
#define TVS_LINESATROOT 	   4
#define TVS_EDITLABELS		   8
#define TVS_SHOWSELALWAYS	  32

#define TIS_NORMAL    0
#define TIS_FIRST     1
#define TIS_LAST      2
#define TIS_PARENT    4
#define TIS_OPEN      8

// insert styles
#define IS_FIRST	  1
#define IS_LAST 	  2
#define IS_AFTER	  3
#define IS_FIRSTCHILD	  4
#define IS_LASTCHILD	  5

// get styles
#define TVGN_ROOT	  0
#define TVGN_NEXT	  1
#define TVGN_PREVIOUS	  2
#define TVGN_PARENT	  3
#define TVGN_CHILD	  4
#define TVGN_CARET	  5

// expand styles
#define TVE_COLLAPSE	  0
#define TVE_EXPAND	  1
#define TVE_TOGGLE	  2

#xcommand @ <nRow>, <nCol> TREE <oTree> ;
	     [ SIZE <nWidth>, <nHeight> ] ;
	     [ ON CHANGE <uChange> ] ;
             [ ON [ LEFT ] DBLCLICK <uLDblClick> ] ;
	     [ <of: OF, WINDOW, DIALOG > <oWnd> ] ;
             [ VALID <uValid> ] ;
	     [ <color: COLOR,COLORS> <nClrFore> [,<nClrBack>] ] ;
	     [ FONT <oFont> ] ;
	     [ BITMAPS <aBitmaps> ] ;
	     [ MASKS <aMasks> ] ;
	     [ <help:HELP, HELPID, HELP ID> <nHelpId> ] ;
             [ MESSAGE <cMsg> ] ;
             [ WHEN <uWhen> ] ;
	     [ <pixel: PIXEL> ] ;
	     [ TREE STYLE <nTreeStyle> ] ;
             [ <lNoBorder: NO BORDER, NOBORDER> ] ;
             [ <lNoVScroll: NO VSCROLL, NOVSCROLL> ] ;
             [ <lNoHScroll: NO HSCROLL, NOHSCROLL> ] ;
	=> ;
           <oTree> := TTreeView():New( <nRow>, <nCol>, <nWidth>, <nHeight>, <oWnd>, ;
		      <aBitmaps>, <aMasks>, <{uChange}>, <{uLDblClick}>, <{uValid}>, <nHelpId>, ;
                      <nClrFore>, <nClrBack>, <oFont>, <cMsg>, <{uWhen}>, <.pixel.>, <nTreeStyle>,;
                      [<.lNoBorder.>], [<.lNoVScroll.>], [<.lNoHScroll.>] )
                       

#xcommand REDEFINE TREE <oTree> ID <nId> ;
	     [ ON CHANGE <uChange> ] ;
             [ ON [ LEFT ] DBLCLICK <uLDblClick> ] ;
	     [ <of: OF, WINDOW, DIALOG > <oWnd> ] ;
             [ VALID <uValid> ] ;
	     [ <color: COLOR,COLORS> <nClrFore> [,<nClrBack>] ] ;
	     [ FONT <oFont> ] ;
	     [ BITMAPS <aBitmaps> ] ;
	     [ MASKS <aMasks> ] ;
	     [ <help:HELP, HELPID, HELP ID> <nHelpId> ] ;
             [ MESSAGE <cMsg> ] ;
             [ WHEN <uWhen> ] ;
	     [ TREE STYLE <nTreeStyle> ] ;
	=> ;
           <oTree> := TTreeView():Redefine( <nId>, <oWnd>, <aBitmaps>, <aMasks>, ;
		      [\{|oLink|<uChange>\}], <{uLDblClick}>, <{uValid}>, <nHelpId>, ;
		      <nClrFore>, <nClrBack>, <oFont>, <cMsg>, <{uWhen}>, <nTreeStyle> )

#endif

#ifdef __XPP__
   #xtranslate TTreeView():New( <params,...> ) => ;
               TTreeView():New():_New( <params> )

   #xtranslate TTreeView():Redefine( <params,...> ) => ;
               TTreeView():New():Redefine( <params> )

   #xtranslate TVItem():New( <params,...> ) => ;
               TVItem():New():_New( <params> )

   #xtranslate TVItem():Redefine( <params,...> ) => ;
               TVItem():New():Redefine( <params> )

   #xtranslate TTreeLink():New( <params,...> ) => ;
               TTreeLink():New():_New( <params> )

   #xtranslate TTreeLink():Redefine( <params,...> ) => ;
               TTreeLink():New():Redefine( <params> )

   #xtranslate TTreeItem():New( <params,...> ) => ;
               TTreeItem():New():_New( <params> )

   #xtranslate TTreeItem():Redefine( <params,...> ) => ;
               TTreeItem():New():Redefine( <params> )

#endif

