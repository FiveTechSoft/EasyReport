/*
    ==================================================================
    EasyReport - The Visual Report Designer                Header File
                                                         Version 2.0.6
    ------------------------------------------------------------------
                           (c) copyright: Timm Sodtalbers, 2000 - 2004
                                                    Sodtalbers+Partner
                                              info@reportdesigner.info
                                               www.reportdesigner.info
    ==================================================================
*/

// In FiveWin 2.2 FiveTech renamed the class TExStruc to TExStruct.
// If you use FW 2.1 or lower uncomment the next line.
//#DEFINE USE_TEXSTRUC

//------------------------------------------------------------------------------

#DEFINE CODE39          1
#DEFINE CODE39CHECK     2
#DEFINE CODE128AUTO     3
#DEFINE CODE128A        4
#DEFINE CODE128B        5
#DEFINE CODE128C        6
#DEFINE EAN8            7
#DEFINE EAN13           8
#DEFINE UPCA            9
#DEFINE CODABAR         10
#DEFINE SUPLEMENTO5     11
#DEFINE INDUST25        12
#DEFINE INDUST25CHECK   13
#DEFINE INTER25         14
#DEFINE INTER25CHECK    15
#DEFINE MATRIX25        16
#DEFINE MATRIX25CHECK   17

//------------------------------------------------------------------------------
#xcommand EASYREPORT <oVRD>                         ;
                     NAME <cRptFile>                ;
                     [ PREVIEW <lPreview>         ] ;
                     [ TO <cPrinter>              ] ;
                     [ OF <oWnd>                  ] ;
                     [ <lModal: MODAL>            ] ;
                     [ <lPrintIDs: PRINTIDS>      ] ;
                     [ <lNoPrint: NOPRINT>        ] ;
                     [ <lNoExpr: NOEXPR>          ] ;
                     [ CHECK <lCheck>             ] ;
                     [ AREAPATH <cAreaPath>       ] ;
                     [ PRINTDIALOG <lPrDialog>    ] ;
                     [ COPIES <nCopies>           ] ;
                     [ PRINTOBJECT <oPrn>         ] ;
                     [ PAPERSIZE <aSize>          ] ;
                     [ TITLE <cTitle>             ] ;
                     [ PREVIEWDIR <cPrevDir>      ] ;
                     [ AUTOPAGEBREAK <lAutoBreak> ] ;
                     [ SHOWINFO <lShowInfo>       ] ;
   => ;
      <oVRD> := VRD():New( <cRptFile>       , ;
                           [ <lPreview>    ], ;
                           [ <cPrinter>    ], ;
                           [ <oWnd>        ], ;
                           [ <.lModal.>    ], ;
                           [ <.lPrintIDs.> ], ;
                           [ <.lNoPrint.>  ], ;
                           [ <.lNoExpr.>   ], ;
                           [ <cAreaPath>   ], ;
                           [ <lPrDialog>   ], ;
                           [ <nCopies>     ], ;
                           [ <lCheck>      ], ;
                           [ <oPrn>        ], ;
                           [ <aSize>       ], ;
                           [ <cTitle>      ], ;
                           [ <cPrevDir>    ], ;
                           [ <lAutoBreak>  ], ;
                           [ <lShowInfo>   ] )

//------------------------------------------------------------------------------
#xcommand ER QUICK <oVRD>                         ;
                   NAME <cRptFile>                ;
                   [ PREVIEW <lPreview>         ] ;
                   [ TO <cPrinter>              ] ;
                   [ OF <oWnd>                  ] ;
                   [ <lModal: MODAL>            ] ;
                   [ <lPrintIDs: PRINTIDS>      ] ;
                   [ <lNoPrint: NOPRINT>        ] ;
                   [ <lNoExpr: NOEXPR>          ] ;
                   [ CHECK <lCheck>             ] ;
                   [ AREAPATH <cAreaPath>       ] ;
                   [ PRINTDIALOG <lPrDialog>    ] ;
                   [ COPIES <nCopies>           ] ;
                   [ TITLE <cTitle>             ] ;
                   [ ACTION <uAction>           ] ;
                   [ PREVIEWDIR <cPrevDir>      ] ;
                   [ AUTOPAGEBREAK <lAutoBreak> ] ;
   => ;
         VRD_PrReport( <cRptFile>         , ;
                     [ <lPreview>        ], ;
                     [ <cPrinter>        ], ;
                     [ <oWnd>            ], ;
                     [ <.lModal.>        ], ;
                     [ <.lPrintIDs.>     ], ;
                     [ <.lNoPrint.>      ], ;
                     [ <.lNoExpr.>       ], ;
                     [ <cAreaPath>       ], ;
                     [ <lPrDialog>       ], ;
                     [ <nCopies>         ], ;
                     [ <lCheck>          ], ;
                     [ {|oVRD|<uAction>} ], ;
                     [ <cTitle>          ], ;
                     [ <cPrevDir>        ], ;
                     [ <lAutoBreak>      ] )

//------------------------------------------------------------------------------
#xcommand PRINTAREA <nArea>                     ;
                    OF <oVRD>                   ;
                    [ <lOnlyInit: ONLYINIT>   ] ;
                    [ ITEMIDS <aIDs>          ] ;
                    [ ITEMVALUES <aStrings>   ] ;
                    [ <lPageBreak: PAGEBREAK> ] ;
   => ;
      <oVRD>:AreaStart( <nArea>           , ;
                        [ !<.lOnlyInit.> ], ;
                        [ <aIDs>         ], ;
                        [ <aStrings>     ], ;
                        [ <.lPageBreak.> ] )

//------------------------------------------------------------------------------
#xcommand PRINTAREAS <aArea>                     ;
                     OF <oVRD>                   ;
                     [ <lOnlyInit: ONLYINIT>   ] ;
   => ;
      <oVRD>:PrMultiAreas( <aArea>           , ;
                           [ !<.lOnlyInit.> ] )

//------------------------------------------------------------------------------
#xcommand PRINTITEM <nItemID>                ;
                    AREA <nArea>             ;
                    [ VALUE <cTextORImage> ] ;
                    OF <oVRD>                ;
                    [ ENTRY <nEntry>       ] ;
   => ;
      <oVRD>:PrintItem( <nArea>            , ;
                        <nItemID>          , ;
                        [ <cTextORImage> ] ,,, ;
                        [ <nEntry>       ] )

//------------------------------------------------------------------------------
#xcommand PRITEMLIST AREA <nArea>          ;
                     OF <oVRD>             ;
                     ITEMIDS <aIDs>        ;
                     ITEMVALUES <aStrings> ;
   => ;
      <oVRD>:PrintItemList( <nArea>    , ;
                            <aIDs>     , ;
                            <aStrings> )

//------------------------------------------------------------------------------
#xcommand PRINTREST AREA <nArea> OF <oVRD> => <oVRD>:PrintRest( <nArea> )

//------------------------------------------------------------------------------
#xcommand PAGEBREAK <oVRD> => <oVRD>:PageBreak()

//------------------------------------------------------------------------------
#xcommand END EASYREPORT <oVRD> => <oVRD>:End()

//------------------------------------------------------------------------------
#xcommand ENDEASYREPORT <oVRD> => <oVRD>:End()

//------------------------------------------------------------------------------
#xcommand @ <nTop>, <nLeft> BARCODE <oBC>   ;
             DEVICE <hDC>                   ;
             <label: PROMPT, VAR> <cText>   ;
             TYPE <nBCodeType>              ;
             [ SIZE <nWidth>, <nHeight>   ] ;
             [ COLORTEXT <nColText>       ] ;
             [ COLORPANE <nColPane>       ] ;
             [ PINWIDTH <nPinWidth>       ] ;
             [ VERTICAL <lVert>           ] ;
             [ TRANSPARENT <lTransparent> ] ;
   => ;
      <oBC> := VRDBarcode():New( hDC, <cText>, <nTop>, <nLeft>, ;
                           [ <nWidth>       ], [ <nHeight>   ], [ <nBCodeType> ], ;
                           [ <nColText>     ], [ <nColPane>  ], [ !<lVert>     ], ;
                           [ <lTransparent> ], [ <nPinWidth> ] )

//------------------------------------------------------------------------------
#xcommand SHOWBARCODE <oBC> => <oBC>:ShowBarcode()