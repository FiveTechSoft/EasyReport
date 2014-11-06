/*
    ==================================================================
    EasyReport - The Visual Report Designer                VRDITEM.PRG
                                                         Version 2.1.1
    ------------------------------------------------------------------
                           (c) copyright: Timm Sodtalbers, 2000 - 2004
                                                    Sodtalbers+Partner
                                              info@reportdesigner.info
                                               www.reportdesigner.info
    ==================================================================
*/

#IFDEF __XPP__
   #INCLUDE "VRDXPP.ch"
#ELSE
   #INCLUDE "FiveWin.ch"
#ENDIF

*-- CLASS DEFINITION ---------------------------------------------------------
*         Name: VRDItem
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
CLASS VRDItem

   DATA cType         // Item type
   DATA cText         // Item text
   DATA nItemID       // Item ID
   DATA nShow         // Visible (1) or not visible (0)
   DATA lVisible
   DATA nDelete       // Item removable (1) or not (0)
   DATA nEdit         // Edit items (1) or not (0)
   DATA nTop
   DATA nLeft
   DATA nWidth
   DATA nHeight
   DATA nBorder       // Draw a border around the item (1) or not (0)
   DATA lBorder
   DATA lGraphic      // if lineup, linedown, linehorizontal, linevertical, rectangle or ellipse

   //Only for type: Text
   DATA nFont         // Font number
   DATA lMultiLine    // For printing memo fields
   DATA lVariHeight   // For printing memo fields
   DATA nInterLine INIT 0.2 // for interlines

   //Only for type: Text, Image and barcode
   DATA cSource       // Source code which will be interpreted during run time

   //Only for type: Text, graphic and barcode
   DATA nColText INIT 1   // Text color
   DATA nColPane INIT 2   // Background color
   DATA nOrient           // Orientation
   DATA nTrans            // Transparent numeric
   DATA lTrans            // Transparent logical

   //Only for type: Image
   DATA cFile         // Image file

   //Only for type: LineUp, LineDown, LineHorizontal, LineVertical, Rectangle or Ellipse
   DATA nColor   INIT 1   // Color
   DATA nColFill INIT 2   // Fill color
   DATA nStyle            // line style
   DATA nPenWidth         // Pen width
   DATA nRndWidth         // width of the rounded corner
   DATA nRndHeight        // height of the rounded corner

   //Only for type: Barcode
   DATA nBCodeType    // Barcode type (EAN 13, Code 13 etc.)
   DATA nPinWidth     // Barcode pin width
   DATA lHorizontal   // Horizontal (.T.) or vertical (.F.)

   //Formulas
   DATA cSTop, cSLeft, cSWidth, cSHeight, cSFont, cSTextClr, cSBackClr, cSPenSize
   DATA cSAlignment, cSVisible, cSMultiline, cSPrBorder, cSTransparent, cSPenStyle
   DATA cSVariHeight

   DATA cArea
   DATA nArea
   DATA oVRD

   METHOD New( cItemDef, oVRD, nArea, nItemID ) CONSTRUCTOR
   METHOD Set()

ENDCLASS


*-- METHOD -------------------------------------------------------------------
*         Name: New
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD New( cItemDef, oVRD, nArea, nItemID ) CLASS VRDItem

   IF cItemDef = NIL
      ::oVRD    := oVRD
      ::cArea   := oVRD:aAreaInis[ nArea ]
      ::nArea   := nArea
      ::nItemID := nItemID
      cItemDef  := ALLTRIM( VRD_GetDataArea( "Items", oVRD:GetEntryNr( nArea, nItemID ), ;
                                             "", ::cArea ,oVRD ) )
   ENDIF

   ::cType    := UPPER(ALLTRIM( VRD_GetField( cItemDef, 1 ) ))
   ::cText    := VRD_GetField( cItemDef, 2 )
   ::nItemID  := VAL( VRD_GetField( cItemDef, 3 ) )
   ::nShow    := VAL( VRD_GetField( cItemDef, 4 ) )
   ::lVisible := ( ::nShow <> 0 )
   ::nDelete  := VAL( VRD_GetField( cItemDef, 5 ) )
   ::nEdit    := VAL( VRD_GetField( cItemDef, 6 ) )
   ::nTop     := VAL( VRD_GetField( cItemDef, 7 ) )
   ::nLeft    := VAL( VRD_GetField( cItemDef, 8 ) )
   ::nWidth   := VAL( VRD_GetField( cItemDef, 9 ) )
   ::nHeight  := VAL( VRD_GetField( cItemDef, 10 ) )
   ::lGraphic := .F.
   ::nOrient  := 1
   ::lTrans   := .F.
   ::nTrans   := 0

   IF ::cType == "LINEUP"         .OR. ;
      ::cType == "LINEDOWN"       .OR. ;
      ::cType == "LINEHORIZONTAL" .OR. ;
      ::cType == "LINEVERTICAL"   .OR. ;
      ::cType == "RECTANGLE"      .OR. ;
      ::cType == "ELLIPSE"
      ::lGraphic := .T.
   ENDIF

   IF ::cType = "TEXT"

      ::nFont         := VAL( VRD_GetField( cItemDef, 11 ) )
      ::nColText      := VAL( VRD_GetField( cItemDef, 12 ) )
      ::nColPane      := VAL( VRD_GetField( cItemDef, 13 ) )
      ::nOrient       := VAL( VRD_GetField( cItemDef, 14 ) )
      ::nBorder       := VAL( VRD_GetField( cItemDef, 15 ) )
      ::lBorder       := ( ::nBorder <> 0 )
      ::nTrans        := VAL( VRD_GetField( cItemDef, 16 ) )
      ::lTrans        := ( ::nTrans <> 0 )
      ::cSource       := ALLTRIM( VRD_GetField( cItemDef, 17 ) )
      ::lMultiLine    := ( VAL( VRD_GetField( cItemDef, 18 ) ) = 1 )
      ::cSTop         := ALLTRIM( VRD_GetField( cItemDef, 19 ) )
      ::cSLeft        := ALLTRIM( VRD_GetField( cItemDef, 20 ) )
      ::cSWidth       := ALLTRIM( VRD_GetField( cItemDef, 21 ) )
      ::cSHeight      := ALLTRIM( VRD_GetField( cItemDef, 22 ) )
      ::cSFont        := ALLTRIM( VRD_GetField( cItemDef, 23 ) )
      ::cSTextClr     := ALLTRIM( VRD_GetField( cItemDef, 24 ) )
      ::cSBackClr     := ALLTRIM( VRD_GetField( cItemDef, 25 ) )
      ::cSAlignment   := ALLTRIM( VRD_GetField( cItemDef, 26 ) )
      ::cSVisible     := ALLTRIM( VRD_GetField( cItemDef, 27 ) )
      ::cSMultiline   := ALLTRIM( VRD_GetField( cItemDef, 28 ) )
      ::cSPrBorder    := ALLTRIM( VRD_GetField( cItemDef, 29 ) )
      ::cSTransparent := ALLTRIM( VRD_GetField( cItemDef, 30 ) )
      ::cSVariHeight  := ALLTRIM( VRD_GetField( cItemDef, 31 ) )
      ::lVariHeight   := ( VAL( VRD_GetField( cItemDef, 32 ) ) = 1 )
      ::nInterLine    :=  VAL( VRD_GetField( cItemDef, 33 ) )
   ELSEIF ::cType = "IMAGE"

      ::cFile         := ALLTRIM( VRD_GetField( cItemDef, 11 ) )
      ::nBorder       := VAL( VRD_GetField( cItemDef, 12 ) )
      ::lBorder       := ( ::nBorder <> 0 )
      ::cSource       := ALLTRIM( VRD_GetField( cItemDef, 13 ) )
      ::cSTop         := ALLTRIM( VRD_GetField( cItemDef, 14 ) )
      ::cSLeft        := ALLTRIM( VRD_GetField( cItemDef, 15 ) )
      ::cSWidth       := ALLTRIM( VRD_GetField( cItemDef, 16 ) )
      ::cSHeight      := ALLTRIM( VRD_GetField( cItemDef, 17 ) )
      ::cSVisible     := ALLTRIM( VRD_GetField( cItemDef, 18 ) )
      ::cSPrBorder    := ALLTRIM( VRD_GetField( cItemDef, 19 ) )

   ELSEIF ::lGraphic

      ::nColor        := VAL( VRD_GetField( cItemDef, 11 ) )
      ::nColFill      := VAL( VRD_GetField( cItemDef, 12 ) )
      ::nStyle        := VAL( VRD_GetField( cItemDef, 13 ) )
      ::nPenWidth     := VAL( VRD_GetField( cItemDef, 14 ) )
      ::nRndWidth     := VAL( VRD_GetField( cItemDef, 15 ) )
      ::nRndHeight    := VAL( VRD_GetField( cItemDef, 16 ) )
      ::nTrans        := VAL( VRD_GetField( cItemDef, 17 ) )
      ::lTrans        := ( ::nTrans <> 0 )
      ::cSTop         := ALLTRIM( VRD_GetField( cItemDef, 18 ) )
      ::cSLeft        := ALLTRIM( VRD_GetField( cItemDef, 19 ) )
      ::cSWidth       := ALLTRIM( VRD_GetField( cItemDef, 20 ) )
      ::cSHeight      := ALLTRIM( VRD_GetField( cItemDef, 21 ) )
      ::cSTextClr     := ALLTRIM( VRD_GetField( cItemDef, 22 ) )
      ::cSBackClr     := ALLTRIM( VRD_GetField( cItemDef, 23 ) )
      ::cSVisible     := ALLTRIM( VRD_GetField( cItemDef, 24 ) )
      ::cSTransparent := ALLTRIM( VRD_GetField( cItemDef, 25 ) )
      ::cSPenSize     := ALLTRIM( VRD_GetField( cItemDef, 26 ) )
      ::cSPenStyle    := ALLTRIM( VRD_GetField( cItemDef, 27 ) )

   ELSEIF ::cType = "BARCODE"

      ::nBCodeType    := VAL( VRD_GetField( cItemDef, 11 ) )
      ::nColText      := VAL( VRD_GetField( cItemDef, 12 ) )
      ::nColPane      := VAL( VRD_GetField( cItemDef, 13 ) )
      ::nOrient       := VAL( VRD_GetField( cItemDef, 14 ) )
      ::nTrans        := VAL( VRD_GetField( cItemDef, 15 ) )
      ::lTrans        := ( ::nTrans <> 0 )
      ::nPinWidth     := VAL( VRD_GetField( cItemDef, 16 ) )
      ::lHorizontal   := IIF( ::nOrient = 1, .T., .F. )
      ::cSource       := ALLTRIM( VRD_GetField( cItemDef, 17 ) )
      ::cSTop         := ALLTRIM( VRD_GetField( cItemDef, 18 ) )
      ::cSLeft        := ALLTRIM( VRD_GetField( cItemDef, 19 ) )
      ::cSWidth       := ALLTRIM( VRD_GetField( cItemDef, 20 ) )
      ::cSHeight      := ALLTRIM( VRD_GetField( cItemDef, 21 ) )
      ::cSTextClr     := ALLTRIM( VRD_GetField( cItemDef, 22 ) )
      ::cSBackClr     := ALLTRIM( VRD_GetField( cItemDef, 23 ) )
      ::cSAlignment   := ALLTRIM( VRD_GetField( cItemDef, 24 ) )
      ::cSVisible     := ALLTRIM( VRD_GetField( cItemDef, 25 ) )
      ::cSTransparent := ALLTRIM( VRD_GetField( cItemDef, 26 ) )
      ::cSPenSize     := ALLTRIM( VRD_GetField( cItemDef, 27 ) )

   ENDIF

RETURN ( Self )


*-- METHOD -------------------------------------------------------------------
*         Name: Set
*  Description:
*       Author: Timm Sodtalbers
*-----------------------------------------------------------------------------
METHOD Set( lSaveItem, nMeasure ) CLASS VRDItem

   LOCAL cItemDef

   DEFAULT lSaveItem := .T.

   IF nMeasure = NIL
      nMeasure := ::oVRD:nMeasure
   ENDIF

   cItemDef := ALLTRIM( ::cType )           + "|" + ;
               ::cText                      + "|" + ;
               ALLTRIM(STR( ::nItemID, 5 )) + "|" + ;
               ALLTRIM(STR( ::nShow, 1 ))   + "|" + ;
               ALLTRIM(STR( ::nDelete, 1 )) + "|" + ;
               ALLTRIM(STR( ::nEdit, 1 ))   + "|" + ;
               ALLTRIM(STR( ::nTop, 5,    IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( ::nLeft, 5,   IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( ::nWidth, 5,  IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
               ALLTRIM(STR( ::nHeight, 5, IIF( nMeasure = 2, 2, 0 ) )) + "|"

   IF ::cType = "TEXT"

      cItemDef += ALLTRIM(STR( ::nFont, 4 ))    + "|" + ;
                  ALLTRIM(STR( ::nColText, 4 )) + "|" + ;
                  ALLTRIM(STR( ::nColPane, 4 )) + "|" + ;
                  ALLTRIM(STR( ::nOrient, 2 ))  + "|" + ;
                  ALLTRIM(STR( ::nBorder, 1 ))  + "|" + ;
                  ALLTRIM(STR( ::nTrans, 1 ))   + "|" + ;
                  ALLTRIM( ::cSource )          + "|" + ;
                  IIF( ::lMultiLine, "1", "0" ) + "|" + ;
                  ALLTRIM( ::cSTop         )    + "|" + ;
                  ALLTRIM( ::cSLeft        )    + "|" + ;
                  ALLTRIM( ::cSWidth       )    + "|" + ;
                  ALLTRIM( ::cSHeight      )    + "|" + ;
                  ALLTRIM( ::cSFont        )    + "|" + ;
                  ALLTRIM( ::cSTextClr     )    + "|" + ;
                  ALLTRIM( ::cSBackClr     )    + "|" + ;
                  ALLTRIM( ::cSAlignment   )    + "|" + ;
                  ALLTRIM( ::cSVisible     )    + "|" + ;
                  ALLTRIM( ::cSMultiline   )    + "|" + ;
                  ALLTRIM( ::cSPrBorder    )    + "|" + ;
                  ALLTRIM( ::cSTransparent )    + "|" + ;
                  ALLTRIM( ::cSVariHeight  )    + "|" + ;
                  IIF( ::lVariHeight, "1", "0" ) + "|" + ;
                  AllTrim(Str( ::nInterLine ,4,2 ))

   ELSEIF ::cType = "IMAGE"

      cItemDef += ALLTRIM( ::cFile )           + "|" + ;
                  ALLTRIM(STR( ::nBorder, 1 )) + "|" + ;
                  ALLTRIM( ::cSource )         + "|" + ;
                  ALLTRIM( ::cSTop         )   + "|" + ;
                  ALLTRIM( ::cSLeft        )   + "|" + ;
                  ALLTRIM( ::cSWidth       )   + "|" + ;
                  ALLTRIM( ::cSHeight      )   + "|" + ;
                  ALLTRIM( ::cSVisible     )   + "|" + ;
                  ALLTRIM( ::cSPrBorder    )

   ELSEIF ::lGraphic

      cItemDef += ALLTRIM(STR( ::nColor, 4 ))    + "|" + ;
                  ALLTRIM(STR( ::nColFill, 4 ))  + "|" + ;
                  ALLTRIM(STR( ::nStyle, 1 ))    + "|" + ;
                  ALLTRIM(STR( ::nPenWidth, 2 )) + "|" + ;
                  ALLTRIM(STR( ::nRndWidth, 5,  IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
                  ALLTRIM(STR( ::nRndHeight, 5, IIF( nMeasure = 2, 2, 0 ) )) + "|" + ;
                  ALLTRIM(STR( ::nTrans, 1 ))   + "|" + ;
                  ALLTRIM( ::cSTop         )    + "|" + ;
                  ALLTRIM( ::cSLeft        )    + "|" + ;
                  ALLTRIM( ::cSWidth       )    + "|" + ;
                  ALLTRIM( ::cSHeight      )    + "|" + ;
                  ALLTRIM( ::cSTextClr     )    + "|" + ;
                  ALLTRIM( ::cSBackClr     )    + "|" + ;
                  ALLTRIM( ::cSVisible     )    + "|" + ;
                  ALLTRIM( ::cSTransparent )    + "|" + ;
                  ALLTRIM( ::cSPenSize     )    + "|" + ;
                  ALLTRIM( ::cSPenStyle    )

   ELSEIF ::cType = "BARCODE"

      cItemDef += ALLTRIM(STR( ::nBCodeType, 2 ))   + "|" + ;
                  ALLTRIM(STR( ::nColText, 4 ))     + "|" + ;
                  ALLTRIM(STR( ::nColPane, 4 ))     + "|" + ;
                  ALLTRIM(STR( ::nOrient, 2 ))      + "|" + ;
                  ALLTRIM(STR( ::nTrans, 1 ))       + "|" + ;
                  ALLTRIM(STR( ::nPinWidth, 5, 2 )) + "|" + ;
                  ALLTRIM( ::cSource )              + "|" + ;
                  ALLTRIM( ::cSTop         )        + "|" + ;
                  ALLTRIM( ::cSLeft        )        + "|" + ;
                  ALLTRIM( ::cSWidth       )        + "|" + ;
                  ALLTRIM( ::cSHeight      )        + "|" + ;
                  ALLTRIM( ::cSTextClr     )        + "|" + ;
                  ALLTRIM( ::cSBackClr     )        + "|" + ;
                  ALLTRIM( ::cSAlignment   )        + "|" + ;
                  ALLTRIM( ::cSVisible     )        + "|" + ;
                  ALLTRIM( ::cSPenSize     )        + "|" + ;
                  ALLTRIM( ::cSTransparent )

   ENDIF

   IF lSaveItem                                                                 // cAreaIni
      VRD_SetDataArea( "Items", ::oVRD:GetEntryNr( ::nArea, ::nItemID ), cItemDef, ::cArea, ::oVrd )
    //  WritePProString( "Items", ::oVRD:GetEntryNr( ::nArea, ::nItemID ), cItemDef, ::cArea )
   ENDIF

RETURN ( cItemDef )