#ifndef _C5GRID_CH
#define _C5GRID_CH

// Language constructs for Strings used in the class libraries.
#ifdef ESPANOL

   #define TITLE_LOCKED      "Registro bloqueado"
   #define MSG_LOCKED        "Por favor, pruebe de nuevo!"
   #define TITLE_UPDATED     "Actualizar?"
   #define MSG_UPDATED       "Seleccione, por favor"
   #define MSG_BMPSELECT     "Seleccione un fichero BMP"
   #define MSGCOPY           "&Copiar"
   #define MSGPASTE          "&Pegar:  "
   #define MSGPASTELOCK      "Accion cancelada Registro bloqueado!!"
   #define MSGDISTINCTYPE    "Diferente tipo de dato"
   #define MSGNOTFINDFILE    "No puedo encontrar el fichero:"
   #define MSGSETFILTER      "SetFilter () los tipos no equiparan con actuales claves de indices"
   #define MSGERRORWIDTH     "Error de anchura de datos No se actualiza el registro."
   #define MSGERRORIREC      "No se defini¢ el nombre del indice para calcular recno"


#else // English (Default)

   #define TITLE_LOCKED      "Record locked!"
   #define MSG_LOCKED        "Please, try again"
   #define TITLE_UPDATED     "Update?"
   #define MSG_UPDATED       "Please Please"
   #define MSG_BMPSELECT     "Select a Bmp File"
   #define MSGCOPY           "&Copy"
   #define MSGPASTE          "&Paste:  "
   #define MSGPASTELOCK      "Action Canceled - Record locked !"
   #define MSGDISTINCTYPE    "Unknown data type"
   #define MSGNOTFINDFILE    "Can't find file: "
   #define MSGSETFILTER      "TGrid SetFilter() types don't match with current Index Key type!"
   #define MSGERRORWIDTH     "Data Width Error Record Not Updated"
   #define MSGERRORIREC      "It was not defined the name of the index to calculate recno"


#endif


#xcommand @ <nRow>, <nCol> GRID <oGrid>          ;
               [ SIZE <nWidth>, <nHeight>      ] ;
               [ <dlg:OF,DIALOG> <oDlg>        ] ;
               [ <color: COLOR, COLORS> <nClrText> [,<nClrPane>] ] ;
               [ <colorfocus: COLORFOCUS> <nClrTFoc> [,<nClrPFoc>] ] ;
               [ COLORGRID <nClrGrid>          ] ;
               [ FONT  <oFont>                 ] ;
               [ ALIAS <cAlias>                ] ;
               [ HIGHTLINE <nHRow>             ] ;
               [ HDRLINES <nLinesHdr>          ] ;
               [ <lVScroll:    VSCROLL   >     ] ;
               [ <lHScroll:    HSCROLL   >     ] ;
               [ <lBorder:     NOBORDER  >     ] ;
               [ <lFoots:      FOOTS     >     ] ;
               [ <lVGrid:      VGRID     >     ] ;
               [ <lHGrid:      HGRID     >     ] ;
               [ <lFastDef:    FASTDEF   >     ] ;
               [ <lNoAutoSize: NOAUTOSIZE>     ] ;
               [ <lNoHilite:   NOHILITE  >     ] ;
               [ <lBar:        BAR       >     ] ;
               [ <lEditLine:   EDITLINE  >     ] ;
               [ ACTION <bAction>              ] ;
               [ ON CHANGE <uChange>           ] ;
               [ ON RIGHT CLICK <uRClick>      ] ;
      => ;
     [ <oGrid> := ] TGrid():New( <nRow>, <nCol>, <nWidth>, <nHeight>, <oDlg>,;
                 <nHRow>, <.lVGrid.>,<.lHGrid.>, <nClrTFoc>, <nClrPFoc>,;
                 <.lVScroll.>, <.lHScroll.>, <nClrText>, <nClrPane>, <oFont>,;
                 !<.lBorder.>, <nClrGrid>, <nLinesHdr>, <cAlias>,<.lBar.>,<.lNoHilite.> ,;
                 <.lFoots.>,<.lEditLine.> , <{bAction}>, <.lFastDef.>,[<{uChange}>],;
                 <.lNoAutoSize.> , [\{|nRow,nCol,nFlags|<uRClick>\}] )


#xcommand REDEFINE GRID [<oGrid>]  ;
               [ ID <nId>                      ] ;
               [ <dlg:OF,DIALOG> <oDlg>        ] ;
               [ <color: COLOR, COLORS> <nClrText> [,<nClrPane>] ] ;
               [ <colorfocus: COLORFOCUS> <nClrTFoc> [,<nClrPFoc>] ] ;
               [ COLORGRID <nClrGrid>          ] ;
               [ FONT <oFont>                  ] ;
               [ ALIAS  <cAlias>               ] ;
               [ HIGHTLINE <nHRow>             ];
               [ HDRLINES <nLinesHdr>          ] ;
               [ <lVScroll: VSCROLL>           ] ;
               [ <lHScroll: HSCROLL>           ] ;
               [ <lBorder:  NOBORDER >         ] ;
               [ <lFoots:   FOOTS>             ] ;
               [ <lVGrid:   VGRID>             ] ;
               [ <lHGrid:   HGRID>             ] ;
               [ <lFastDef: FASTDEF>           ] ;
               [ <lNoHilite:NOHILITE>          ] ;
               [ <lBar:     BAR>               ] ;
               [ <lEditLine:EDITLINE>          ] ;
               [ ACTION <bAction>              ] ;
               [ ON CHANGE <uChange>           ] ;
               [ ON RIGHT CLICK <uRClick>      ] ;
      => ;
        [ <oGrid> := ] TGrid():Redefine( <oDlg>,<nId>,;
                           <nHRow>, <.lVGrid.>,<.lHGrid.>,;
                           <nClrTFoc>, <nClrPFoc>, <.lVScroll.>, <.lHScroll.>,;
                           <nClrText>, <nClrPane>, <oFont>,;
                           !<.lBorder.>, <nClrGrid> ,;
                           <nLinesHdr>, <cAlias>, <.lBar.>, <.lNoHilite.>,;
                           <.lFoots.>, <.lEditLine.>, ;
                           <{bAction}>, <.lFastDef.>,[<{uChange}>] ,;
                           [\{|nRow,nCol,nFlags|<uRClick>\}] )

//------------------------------------------------------------------------//

#command DEFINE HEADER <oHdr> ;
            [ <tit: TITLE, TITLES> <cTitles,...>    ] ;
            [ ALIGN <cAlign: TOP_LEFT, TOP_CENTER, TOP_RIGHT, LEFT, CENTER, RIGHT, BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT, PLAIN, MULTILINE, MULTICENTER > ] ;
            [ <fon: FONT, FONTS> <oFont,...>        ] ;
            [ COLORPANE <nClrPane,...>              ] ;
            [ COLORTEXT <nClrText,...>              ] ;
            [ <bit: BITMAP, BITMAPS> <cBitmaps,...> ] ;
            [ ALIGNBMP <cAlignBmp: TOP_LEFT, TOP_CENTER, TOP_RIGHT, LEFT, CENTER, RIGHT, BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT  > ] ;
            [ <lVGrid: VGRID       > ] ;
            [ <lHGrid: HGRID       > ] ;
            [ <lSpand: SPAND       > ] ;
            [ <lBtnLook:BUTTONLOOK > ] ;
            [ DOUBLECLICK <uAction> ]        ;
            [ GRIDS <cSides,...>     ] ;
            => ;
    <oHdr> :=  THdrGrid():New( [ \{<cTitles>\}]                  ,;
                               [ \{<oFont>\}]                    ,;
                               [ \{<nClrPane>\}]                 ,;
                               [ \{<nClrText>\}]                 ,;
                               [ Upper(<(cAlign)>) ]             ,;
                               [ \{<cBitmaps>\}]                 ,;
                               <.lVGrid.>, <.lHGrid.>, <.lSpand.>,;
                               [ upper(<(cAlignBmp)>) ]          ,;
                               <{uAction}>, <.lBtnLook.>, [ \{<cSides>\}] )

#command DEFINE COLUMNA <oCol> ;
            [ OF     <oGrid>              ] ;
            [ DATA   <uDato>              ] ;
            [ <color: COLOR, COLORS> <nClrText> [,<nClrPane>] ] ;
            [ CLRBLOCK <nBClrText> [,<nBClrPane> ] ] ;
            [ BCOLOR <bColor> ] ;
            [ <fon: FONT, FONTS> <oFont>  ] ;
            [ WIDTH <nWidth>              ] ;
            [ ALIGN  <cAlign: TOP_LEFT, TOP_CENTER, TOP_RIGHT, LEFT, CENTER, RIGHT,;
                              BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT, PLAIN, MULTILINE, MULTICENTER > ] ;
            [ HEADER <oHeader>            ] ;
            [ FOOT   <oFoot>              ] ;
            [ <lNoEdit: NOEDITABLE      > ] ;
            [ <lNoPaintData:NOPAINTDATA > ] ;
            [ BBITMAP <bBitmap>           ] ;
            [ <bit: BITMAP, BITMAPS> <uBitmap>  ] ;
            [ ALIGNBMP   <cAlignBmp: TOP_LEFT, TOP_CENTER, TOP_RIGHT, LEFT, CENTER,  RIGHT,;
                              BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT >  ] ;
            [ VALID <uValid>   ] ;
            [ MESSAGEVALID <cMsgValid> ] ;
            [ WHEN <WhenFunc>  ] ;
            [ MESSAGEWHEN <cMsgWhen> ] ;
            [ PICTURE <cPicture> ] ;
            [ ACTION <bAction>             ] ;
            [ ASELDATO <aSelDato> ] ;
            [ <lOem:OEM> ] ;
            [ <lAutoViewBmp:AUTOVIEWBMP> ] ;
            [ EDPICTURE <cEdPicture>     ] ;
            [ BCVALID <bCValid> ] ;
            => ;
    <oCol> :=  TColGrid():New( <uDato>, <uBitmap>, <nWidth>, <oHeader> ,;
                               <oGrid>, <oFont>, <nClrPane>, <nClrText>,;
                               <bColor>,;
                               <nBClrPane>, <nBClrText>, ;
                               [ upper(<(cAlign)>) ] ,;
                               [<{bBitmap}>], <oFoot> , ;
                               [ upper(<(cAlignBmp)>) ], !<.lNoEdit.>,;
                               [ \{ |uVar| <WhenFunc> \} ], ;
                               [ \{ |uVar| <uValid> \} ] ,;
                               <cMsgWhen>, <cMsgValid>, <cPicture>,<{bAction}>,;
                               <.lNoPaintData.>, <aSelDato>, <.lOem.>,;
                               <.lAutoViewBmp.>, <cEdPicture>, <bCValid> )


#command DEFINE FOOT <oFoot> ;
            [ TITLE <cTitle> ] ;
            [ BDATA <bDato>  ] ;
            [ FONT <oFont>   ] ;
            [ COLOR <nClrText>  [,<nClrPane> ] ] ;
            [ ALIGN  <cAlign: TOP_LEFT,     TOP_CENTER ,     TOP_RIGHT ,;
                              LEFT ,        CENTER ,  RIGHT ,;
                              BOTTOM_LEFT , BOTTOM_CENTER ,  BOTTOM_RIGHT ,;
                              PLAIN, MULTILINE  >        ] ;
            [ <lSpand:SPAND> ]     ;
            [ PICTURE <cPicture> ] ;
            => ;
     <oFoot> := TFoot():New( <bDato>,<oFont>,<nClrPane>,<nClrText>,;
                               [ upper(<(cAlign)>) ] ,;
                               <cTitle> , <.lSpand.>, <cPicture> )


#command FILLCOLOR TO <oGrid>     ;
                [ <lRows: ROWS  >       ] ;
                [ <lCols:  COLUMNS >    ] ;
                [ COLORTEXT <nClrText>  ] ;
                [ COLORPANE <nClrPane>  ] ;
                [ FROM <nIni>           ] ;
                [ STEPS <nSteps>        ] ;
                [ INIT <nIni2>          ] ;
                [ EACH <nStep2>         ]  ;
                [ LESSCOLS <anLessCols,...> ] ;
                [ LESSROWS <anLessRows,...> ] ;
                => ;
       <oGrid>:FillStep( <nClrText>, <nClrPane>, ;
                 (.not.<.lCols.>) [.or. <.lRows.> ],;
                 <nIni>, <nSteps>, <nIni2>, <nStep2>, ;
                 [ \{<anLessRows>\}],;
                 [ \{<anLessCols>\}] )

#command FILLFONT TO <oGrid>         ;
                [ ROW <nRow>       ] ;
                [ COLUMN <nCol>    ] ;
                [ FONT <oFont>  ] ;
                => ;
       <oGrid>:FillFont( <nRow>,<nCol>, <oFont> )


#xcommand @ <nRow>, <nCol> FWGRID  <oBrw>  ;
               [ [ FIELDS ] <Flds,...>] ;
               [ ALIAS <cAlias> ] ;
               [ <sizes:FIELDSIZES, SIZES, COLSIZES> <aColSizes,...> ] ;
               [ <head:HEAD,HEADER,HEADERS> <aHeaders,...> ] ;
               [ SELECT <cField> FOR <uValue1> [ TO <uValue2> ] ] ;
               [ SIZE <nWidth>, <nHeigth> ] ;
               [ <dlg:OF,DIALOG> <oDlg> ] ;
               [ <change: ON CHANGE, ON CLICK> <uChange> ] ;
               [ ON [ LEFT ] DBLCLICK <uLDblClick> ] ;
               [ ON RIGHT CLICK <uRClick> ] ;
               [ FONT <oFont> ] ;
               [ CURSOR <oCursor> ] ;
               [ <color: COLOR, COLORS> <nClrFore> [,<nClrBack>] ] ;
               [ MESSAGE <cMsg> ] ;
               [ <update: UPDATE> ] ;
               [ WHEN <uWhen> ] ;
               [ VALID <uValid> ] ;
               [ TABLA <aTabla> ] ;
               [ <lCompatible:COMPATIBLE> ] ;
               => ;
<oBrw> := CCmpTWBr( <nRow>, <nCol>, <nWidth>, <nHeigth>,;
                    [\{|| \{<(Flds)> \} \}], ;
                    [\{<aHeaders>\}], [\{<aColSizes>\}], ;
                    <cField>, <uValue1>, <uValue2>, ;
                    <oDlg>, [<{uChange}>],;
                    [\{|nRow,nCol,nFlags|<uLDblClick>\}],;
                    [\{|nRow,nCol,nFlags|<uRClick>\}],;
                    <oFont>, <oCursor>, <nClrFore>, <nClrBack>, <cMsg>,;
                    <(cAlias)>,  <{uWhen}>,;
                    <{uValid}>, <aTabla>, <.lCompatible.>)


#xcommand REDEFINE FWGRID  <oBrw>  ;
             [ FIELDS <Flds,...>] ;
             [ ALIAS <cAlias> ] ;
             [ ID <nId> ] ;
             [ <dlg:OF,DIALOG> <oDlg> ] ;
             [ <sizes:FIELDSIZES, SIZES, COLSIZES> <aColSizes,...> ] ;
             [ <head:HEAD,HEADER,HEADERS> <aHeaders,...> ] ;
             [ SELECT <cField> FOR <uValue1> [ TO <uValue2> ] ] ;
             [ <change: ON CHANGE, ON CLICK> <uChange> ] ;
             [ ON [ LEFT ] DBLCLICK <uLDblClick> ] ;
             [ ON RIGHT CLICK <uRClick> ] ;
             [ FONT <oFont> ] ;
             [ CURSOR <oCursor> ] ;
             [ <color: COLOR, COLORS> <nClrFore> [,<nClrBack>] ] ;
             [ MESSAGE <cMsg> ] ;
             [ <update: UPDATE> ] ;
             [ WHEN <uWhen> ] ;
             [ VALID <uValid> ] ;
             [ TABLA <aTabla> ] ;
               => ;
<oBrw> := RCmpTWBr( <nId>, <oDlg>,;
                    [\{|| \{<(Flds)> \} \}], ;
                    [\{<aHeaders>\}], [\{<aColSizes>\}], ;
                    <(cField)>, <uValue1>, <uValue2>,;
                    [<{uChange}>],;
                    [\{|nRow,nCol,nFlags|<uLDblClick>\}],;
                    [\{|nRow,nCol,nFlags|<uRClick>\}],;
                    <oFont>, <oCursor>, <nClrFore>, <nClrBack>, <cMsg>,;
                    <.update.>, <(cAlias)>,  <{uWhen}>,;
                    <{uValid}>, <aTabla> )


#command ADD FWCOLUMN TO BROWSE <oBrw> ;
            [ <dat: DATA, SHOWBLOCK> <uData> ] ;
            [ <tit: TITLE, HEADER> <cHead> [ <oem: OEM, ANSI, CONVERT>] ];
            [ <clr: COLORS, COLOURS> <uClrFore> [,<uClrBack>] ] ;
            [ ALIGN ] [ <align: LEFT, CENTERED, RIGHT> ] ;
            [ <wid: WIDTH, SIZE> <nWidth> [ PIXELS ] ] ;
            [ PICTURE <cPicture> ] ;
            [ <bit: BITMAP> ] ;
            [ <edit: EDITABLE> ] ;
            [ MESSAGE <cMsg> ] ;
            [ VALID <uValid> ] ;
            [ ERROR [MSG] [MESSAGE] <cErr> ] ;
            [ <lite: NOBAR, NOHILITE> ] ;
            [ <idx: ORDER, INDEX, TAG> <cOrder> ] ;
            => ;
     cmpTCCol( <oBrw>, ;
    If(<.oem.>, OemToAnsi(<cHead>), <cHead>), ;
    [ If( ValType(<uData>)=="B", <uData>, <{uData}> ) ], <cPicture>, ;
    [ If( ValType(<uClrFore>)=="B", <uClrFore>, <{uClrFore}> ) ], ;
    [ If( ValType(<uClrBack>)=="B", <uClrBack>, <{uClrBack}> ) ], ;
    If(!<.align.>,"LEFT", Upper(<(align)>)), <nWidth>, <.bit.>, ;
    <.edit.>, <cMsg>, <{uValid}>, <cErr>, <.lite.>, <(cOrder)> )

#endif
