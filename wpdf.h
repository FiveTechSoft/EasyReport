// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Type and Procedure Definition
// library wPDFControl and wRTF2PDF
// written by Julian Ziersch
// -----------------------------------------------------------------------
// Copyright (C) 2002-2014 by wpcubed GmbH
// http://www.pdfcontrol.com
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Last change: 16.4.2014
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// USE TCHAR instead of char*
// This requires #include <windows.h>

/* This file includes
   -   struct WPDFInfoRecord - the PDF Engine initialisation parameter
   -   typedefs for callbacks and engine functions
   -   macro DEF_WPDF_ENGINE_PTR to define the pointers
   -   macro LOAD_WPDF_ENGINE_PTR( DLLVAR, DLLNAME ) to initialize the pointers
   -   ERROR, MESSAGE and COMMAND constants
*/

#ifndef WPCONTROLDEF

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Tag to identify the PDF enviroment
typedef void *WPDFEnviroment; // Pointer 32/64 bit
typedef TCHAR* pchar; // was char

// Function definition for callbacks
typedef void (__stdcall TWPDF_Callback)(WPDFEnviroment PdfEnv, int number, TCHAR *buffer, int bufsize); // CHAR BUFFER, ANSI or UNICODE
typedef void (__stdcall TWPDF_StreamCallback)(WPDFEnviroment PdfEnv, int number, char *buffer, int bufsize); // ANSI BUFFER, BYTES


// Structur to set up the PDF Engine with WPDF_InitializeEx
typedef struct
  {
     int SizeOfStruct;
     // Encoding
     int Encoding; // 0 = none, 1=ASCII85, 2=Hex
     // Compression 0=none, deflate, runlength
     int Compression;
     // BitmapCompression
     int BitCompression; // 0=auto, 1=deflat, 2=jpeg
     // Thumbnailes
     int ThumbNails; // 0=none, 1=color, 2=monchrome
     // UseFonts
     int FontMode;
     // PageMode
     int PageMode;
     // InputFileMode
     int InputFileMode;
     // JPEGCompress 0=off, - = value, 1..5 for 10, 25, 50, 75, 100
     int JPEGCompress;
     int EnhancedOptions;
     // PDF Resolution
     int PDFXRes, PDFYRes; // 0->72
     // Default PDF Size (for StartPageA)
     int PDFWidth, PDFHeight; // Default DINa4
     // Read PDF Filename
     char InputPDFFile[128];  // ANSI, not TCHAR!
     // Several Callback functions
     // For Stream Output. We can use this callbacks to write to STDIO.
     // this is useful for CGI applications which rely to send to the PDF output
     // to stdout
     TWPDF_Callback* OnStreamOpen;
     TWPDF_StreamCallback* OnStreamWrite; // was TWPDF_Callback
     TWPDF_Callback* OnStreamClose;
     // Message callbacks
     TWPDF_Callback* OnError;
     TWPDF_Callback* OnMessage;
     // The mailmerge string is used to detect mailmerge fields
     // it is possible to the text such as @@NAME be using the callback function OnGetText
     char MailMergeStart[8]; // ANSI, not TCHAR!
     TWPDF_Callback* OnGetText;
     // Encryption of the PDF file
     int Permission;
     char UserPassword[20], OwnerPassword[20]; // ANSI, not TCHAR!
	 // actually only 5 chars long (40 bits)
     // Info record of the PDF file
     char Date[256],
          ModDate[256],
          Author[256],
          Producer[256],
          Title[256],
          Subject[256],
          Keywords[256]; // ANSI, not TCHAR!
     // Reserved, must be 0
     int Reserved;
} WPDFInfoRecord;

// uses this with
//     WPDF_ExecCommand( pdf, WPCOM_AUTOLINK, 0, &WPDFAutoLink, sizeof(WPDFAutoLink));
// Structur to set up a link bitmap which printed on every page (for Demo versions)
typedef struct
  {
     int BitmapCloneNr; // has priority  (or 0)
     int BitmapHandle;  // HBITMAP handle (or 0)
     TCHAR *VarBuf;      // extra pointer parameter
     int VarBufLen;     // Len of buffer
     // Options:
     //    1: Under Text (but over watermark!)
     //    2: Interpret VarP as pointer to a filename
     int Options;
     // Destination Rectangle (in PDF resolution, not "HDC" Resolution!)
     int DrawX;
     int DrawY;
     int DrawW;
     int DrawH;
     // Destination URL and relative link rectangle
     char LinkURL[100]; // only used in wPDFControl 4 if pLinkURL=null!
     int  LinkX; // added to DrawX
     int  LinkY; // added to DrawY
     int  LinkW; // if 0 then = DrawW
     int  LinkH; // if 0 then = DrawH
	 // Used instead of LinkURL in wPDFControl V4
	 TCHAR *pLinkURL;  // replaces LinkURL!
     TCHAR *pLinkParam;
} WPDFAutoLink;

// used for WPCOM_OUTLINE
typedef struct
{
      char caption[256];    // (currently!) not used for links
      char destname[256];   // (currently!) not used for outlines
      int x,y,w,h;
      int destmode;
      int destzoom;
      int charset, levelmode, level;         // only used for outlines
      int Mode;                              // If Bit 1 then read the custom action
                                             // If Bit 2 then custom_action is actually a Caption as PWideChar
      int custom_action_type;
      TCHAR *custom_action;
      TCHAR *embedded_file;
      int embedded_file_len;
      int reserved;
} WPPDF_LinkDef;

// used for WPCOM_FIELD
typedef struct
{
   int x,y,w,h;
   int typ; // 1: checkbox, 0 = edit
   int mode; // for edits: 1:Multiline, 2:Right aligned, 4:Centered
   int value; // checkbos: 1=checked
   TCHAR *init_text; // reserved 
   TCHAR *default_text; // resereved
   TCHAR *hint_text; // hints for edits and checks
   TCHAR *text_text; // text for edits 
} WPCOM_FIELD_ARG;



// Methods defined in the DLL
typedef WPDFEnviroment (__stdcall WPDF_InitializeEx)(WPDFInfoRecord *Info); // WPDFInfoRecord
typedef WPDFEnviroment (__stdcall WPDF_Initialize)(void);
typedef void (__stdcall WPDF_Finalize)(WPDFEnviroment PdfEnv);
typedef void (__stdcall WPDF_FinalizeAll)(void);
typedef void (__stdcall WPDF_SetResult)(WPDFEnviroment PdfEnv, int buffertype, TCHAR *buffer, int bufsize);
typedef int  (__stdcall WPDF_BeginDoc)(WPDFEnviroment PdfEnv, TCHAR *FileName, int UseStream);
typedef void (__stdcall WPDF_EndDoc)(WPDFEnviroment PdfEnv);
typedef int  (__stdcall WPDF_BeginDocStream)(WPDFEnviroment PdfEnv, void* Stream);
typedef void (__stdcall WPDF_StartPage)(WPDFEnviroment PdfEnv);
typedef void (__stdcall WPDF_StartPageEx)(WPDFEnviroment PdfEnv, int Width, int Height, int Rotation);
typedef void (__stdcall WPDF_EndPage)(WPDFEnviroment PdfEnv);
typedef void (__stdcall WPDF_StartWatermark)(WPDFEnviroment PdfEnv, TCHAR *Name);
typedef void (__stdcall WPDF_StartWatermarkEx)(WPDFEnviroment PdfEnv, TCHAR *Name, int Width, int Height);
typedef void (__stdcall WPDF_EndWatermark)(WPDFEnviroment PdfEnv);
typedef void (__stdcall WPDF_DrawWatermark)(WPDFEnviroment PdfEnv, TCHAR *Name, int Rotation);
// Property and command
typedef void (__stdcall WPDF_SetSProp)(WPDFEnviroment PdfEnv, int id, TCHAR *Value);
typedef void (__stdcall WPDF_SetIProp)(WPDFEnviroment PdfEnv, int id, intptr_t Value);
typedef void (__stdcall WPDF_SetCallbackFKT)(WPDFEnviroment PdfEnv, int id, void *value);
typedef int (__stdcall WPDF_ExecCommand)(WPDFEnviroment PdfEnv, int id, int Value, TCHAR *buffer, int buflen);
typedef int (__stdcall WPDF_ExecCommandEx)(WPDFEnviroment PdfEnv, int id, int Value, void *buffer, int buflen);



// PDF Output Functions
typedef void (__stdcall WPDF_DrawMetafile)(WPDFEnviroment PdfEnv, intptr_t meta, int x, int y, int w, int h);
typedef void (__stdcall WPDF_DrawMetafileEx)(WPDFEnviroment PdfEnv, intptr_t meta, int x, int y, int w, int h, int xres, int yres);
typedef void (__stdcall WPDF_DrawMetafileBuf)(WPDFEnviroment PdfEnv,  \
	    void* data, int buflen, int x, int y, int w, int h, int xres, int yres);
typedef int (__stdcall WPDF_DrawDIB)(WPDFEnviroment PdfEnv, int x, int y, int w, int h, void *BitmapInfo, void *BitmapBits);
typedef int (__stdcall WPDF_DrawBMP)(WPDFEnviroment PdfEnv, int x, int y, int w, int h, HBITMAP Bitmap);
typedef int (__stdcall WPDF_DrawJPEG)(WPDFEnviroment PdfEnv, int x, int y, int w, int h, int jpeg_w, int jpeg_h, void *buffer, int buflen);
typedef int (__stdcall WPDF_DrawBitmapFile)(WPDFEnviroment PdfEnv, int x, int y, int w, int h, TCHAR *FileName);
typedef int (__stdcall WPDF_DrawBitmapClone)(WPDFEnviroment PdfEnv, int x, int y, int w, int h, int BitmapID);
// HDC Output function
typedef HDC (__stdcall WPDF_DC)(WPDFEnviroment PdfEnv); //** Get the DC of the PDF Canvas! **
typedef void* (__stdcall WPDF_GetPointer)(WPDFEnviroment PdfEnv);
typedef void (__stdcall WPDF_SetPointer)(WPDFEnviroment PdfEnv, void *ptr);
typedef void (__stdcall WPDF_TextOut)(WPDFEnviroment PdfEnv, int x, int y, TCHAR * Text);
typedef char* (__stdcall WPDF_TextRect)(WPDFEnviroment PdfEnv, int x, int y, int w, int h, TCHAR *Text, int Alignment);
typedef void (__stdcall WPDF_MoveTo)(WPDFEnviroment PdfEnv, int x, int y);
typedef void (__stdcall WPDF_LineTo)(WPDFEnviroment PdfEnv, int x, int y);
typedef void (__stdcall WPDF_Rectangle)(WPDFEnviroment PdfEnv, int x, int y, int w, int h);
typedef void (__stdcall WPDF_Hyperlink)(WPDFEnviroment PdfEnv, int x, int y, int w, int h, TCHAR *Name);
typedef void (__stdcall WPDF_Bookmark)(WPDFEnviroment PdfEnv, int x, int y, TCHAR *Name);
typedef void (__stdcall WPDF_Outline)(WPDFEnviroment PdfEnv, int level,  int x, int y,TCHAR *Name, TCHAR *Caption);
typedef void (__stdcall WPDF_RichEditPrint)(WPDFEnviroment PdfEnv, 
	   intptr_t RichEditHandle,\
	   float PageWidth, float PageHeight, \
	   float LeftMargin, float TopMargin, \
	   float RightMargin, float BottomMargin, int UseCM);
// Attribute funtions
typedef void (__stdcall WPDF_SetTextDefaultAttr)(WPDFEnviroment PdfEnv, TCHAR *FontName, int Size);
typedef void (__stdcall WPDF_SetTextAttr)(WPDFEnviroment PdfEnv, TCHAR *FontName, int Size, int Bold, int Italic,int Underline);
typedef void (__stdcall WPDF_SetTextAttrEx)(WPDFEnviroment PdfEnv, TCHAR *FontName, int Charset,
         int Size, int Bold, int Italic,int Underline, unsigned int Color);
typedef void (__stdcall WPDF_SetPenAttr)(WPDFEnviroment PdfEnv, int Style, int Width, int Color);
typedef void (__stdcall WPDF_SetBrushAttr)(WPDFEnviroment PdfEnv, int Style, int Color);
// Set License Key. This function only exists in the registered DLL, not in the demo!
typedef void (__stdcall WPDF_SetLicenseKey)(unsigned long number, TCHAR *Name, TCHAR *Code);

// Returns 1 in unicode version or is null
typedef int (__stdcall WPDF_IsUnicodeDLL)();




// -----------------------------------------------------------------------------
// Macro to define the function pointers used for the PDF engine DLL
// Usage:    DEF_WPDF_ENGINE_PTR;
// -----------------------------------------------------------------------------
// added: WPDF_SetCallback - WPDF_RichEditPrint for wPDFControl 4

#define DEF_WPDF_ENGINE_PTR                  \
WPDF_InitializeEx* wpdfInitializeEx;         \
WPDF_Initialize*  wpdfInitialize;            \
WPDF_Finalize*    wpdfFinalize;              \
WPDF_FinalizeAll* wpdfFinalizeAll;           \
WPDF_SetResult*    wpdfSetResult;            \
WPDF_BeginDoc*    wpdfBeginDoc;              \
WPDF_EndDoc*      wpdfEndDoc;                \
WPDF_StartPage*   wpdfStartPage;             \
WPDF_StartPageEx* wpdfStartPageEx;           \
WPDF_EndPage*     wpdfEndPage;               \
WPDF_StartWatermark* wpdfStartWatermark;     \
WPDF_StartWatermarkEx* wpdfStartWatermarkEx; \
WPDF_EndWatermark* wpdfEndWatermark;         \
WPDF_DrawWatermark* wpdfDrawWatermark;       \
WPDF_SetSProp*    wpdfSetSProp;              \
WPDF_SetIProp*    wpdfSetIProp;              \
WPDF_ExecCommand* wpdfExecCommand;           \
WPDF_ExecCommandEx* wpdfExecCommandEx;           \
WPDF_DrawMetafile* wpdfDrawMetafile;         \
WPDF_DrawDIB* wpdfDrawDIB;                   \
WPDF_DrawBMP* wpdfDrawBMP;                   \
WPDF_DrawJPEG* wpdfDrawJPEG;                 \
WPDF_DrawBitmapFile* wpdfDrawBitmapFile;     \
WPDF_DrawBitmapClone* wpdfDrawBitmapClone;   \
WPDF_DC*           wpdfDC;                   \
WPDF_TextOut*      wpdfTextOut;              \
WPDF_TextRect*     wpdfTextRect;             \
WPDF_MoveTo*       wpdfMoveTo;               \
WPDF_LineTo*       wpdfLineTo;               \
WPDF_Rectangle*    wpdfRectangle;            \
WPDF_Hyperlink*    wpdfHyperlink;            \
WPDF_Bookmark*     wpdfBookmark;             \
WPDF_Outline*      wpdfOutline;              \
WPDF_SetTextDefaultAttr* wpdfSetTextDefaultAttr; \
WPDF_SetTextAttr*   wpdfSetTextAttr;         \
WPDF_SetTextAttrEx* wpdfSetTextAttrEx;       \
WPDF_SetPenAttr*    wpdfSetPenAttr;          \
WPDF_SetBrushAttr*  wpdfSetBrushAttr;        \
WPDF_DrawMetafileEx* wpdfDrawMetafileEx;	 \
WPDF_DrawMetafileBuf* wpdfDrawMetafileBuf;   \
WPDF_GetPointer* wpdfGetPointer;			 \
WPDF_SetPointer* wpdfSetPointer;             \
WPDF_RichEditPrint* wpdfRichEditPrint;       \
WPDF_SetCallbackFKT* wpdfSetCallback;        \
WPDF_IsUnicodeDLL* wpdfIsUnicodeDLL;         \
WPDF_SetLicenseKey* wpdfSetLicenseKey        // no ';'



// -----------------------------------------------------------------------------
// Macro to load the DLL and initialize the function pointers defined above
// Usage:    LOAD_WPDF_ENGINE( PDFEngine,       - variable used as DLL handle
//                                 dllname          - PDF engine name
//                               ) == 0 if loaded OK
//                                 == 1 if not found
//                                 == 2 if wrong version (function is missing)
// -----------------------------------------------------------------------------

#define LOAD_WPDF_ENGINE( PDFEngine, dllname ) \
(                                              \
 PdfEngine = LoadLibrary(dllname),             \
 ((PdfEngine==0)?1:                            \
  ( wpdfInitializeEx=(WPDF_InitializeEx*)GetProcAddress(PdfEngine, "WPDF_InitializeEx"),   \
    wpdfInitialize=(WPDF_Initialize*)GetProcAddress(PdfEngine, "WPDF_Initialize"),   \
    wpdfFinalize=(WPDF_Finalize*)GetProcAddress(PdfEngine, "WPDF_Finalize"),   \
    wpdfFinalizeAll=(WPDF_FinalizeAll*)GetProcAddress(PdfEngine, "WPDF_FinalizeAll"),   \
    wpdfSetResult= (WPDF_SetResult*)GetProcAddress(PdfEngine, "WPDF_SetResult"),   \
    wpdfBeginDoc=(WPDF_BeginDoc*)GetProcAddress(PdfEngine, "WPDF_BeginDoc"),   \
    wpdfEndDoc=(WPDF_EndDoc*)GetProcAddress(PdfEngine, "WPDF_EndDoc"),   \
    wpdfStartPage=(WPDF_StartPage*)GetProcAddress(PdfEngine, "WPDF_StartPage"),   \
    wpdfStartPageEx=(WPDF_StartPageEx*)GetProcAddress(PdfEngine, "WPDF_StartPageEx"),   \
    wpdfEndPage=(WPDF_EndPage*)GetProcAddress(PdfEngine, "WPDF_EndPage"),   \
    wpdfStartWatermark=(WPDF_StartWatermark*)GetProcAddress(PdfEngine, "WPDF_StartWatermark"),   \
    wpdfStartWatermarkEx=(WPDF_StartWatermarkEx*)GetProcAddress(PdfEngine, "WPDF_StartWatermarkEx"),   \
    wpdfEndWatermark=(WPDF_EndWatermark*)GetProcAddress(PdfEngine, "WPDF_EndWatermark"),   \
    wpdfDrawWatermark=(WPDF_DrawWatermark*)GetProcAddress(PdfEngine, "WPDF_DrawWatermark"),   \
    wpdfSetSProp=(WPDF_SetSProp*)GetProcAddress(PdfEngine, "WPDF_SetSProp"),   \
    wpdfSetIProp=(WPDF_SetIProp*)GetProcAddress(PdfEngine, "WPDF_SetIProp"),   \
    wpdfExecCommand=(WPDF_ExecCommand*)GetProcAddress(PdfEngine, "WPDF_ExecCommand"),   \
	wpdfExecCommandEx=(WPDF_ExecCommandEx*)GetProcAddress(PdfEngine, "WPDF_ExecCommand"),   \
    wpdfDrawMetafile=(WPDF_DrawMetafile*)GetProcAddress(PdfEngine, "WPDF_DrawMetafile"),   \
    wpdfDrawDIB=(WPDF_DrawDIB*)GetProcAddress(PdfEngine, "WPDF_DrawDIB"),   \
    wpdfDrawBMP=(WPDF_DrawBMP*)GetProcAddress(PdfEngine, "WPDF_DrawBMP"),   \
    wpdfDrawJPEG=(WPDF_DrawJPEG*)GetProcAddress(PdfEngine, "WPDF_DrawJPEG"),   \
    wpdfDrawBitmapFile=(WPDF_DrawBitmapFile*)GetProcAddress(PdfEngine, "WPDF_DrawBitmapFile"),   \
    wpdfDrawBitmapClone=(WPDF_DrawBitmapClone*)GetProcAddress(PdfEngine, "WPDF_DrawBitmapClone"),   \
    wpdfDC=(WPDF_DC*)GetProcAddress(PdfEngine, "WPDF_DC"),   \
    wpdfTextOut=(WPDF_TextOut*)GetProcAddress(PdfEngine, "WPDF_TextOut"),   \
    wpdfTextRect=(WPDF_TextRect*)GetProcAddress(PdfEngine, "WPDF_TextRect"),   \
    wpdfMoveTo=(WPDF_MoveTo*)GetProcAddress(PdfEngine, "WPDF_MoveTo"),   \
    wpdfLineTo=(WPDF_LineTo*)GetProcAddress(PdfEngine, "WPDF_LineTo"),   \
    wpdfRectangle=(WPDF_Rectangle*)GetProcAddress(PdfEngine, "WPDF_Rectangle"),   \
    wpdfHyperlink=(WPDF_Hyperlink*)GetProcAddress(PdfEngine, "WPDF_Hyperlink"),   \
    wpdfBookmark=(WPDF_Bookmark*)GetProcAddress(PdfEngine, "WPDF_Bookmark"),   \
    wpdfOutline=(WPDF_Outline*)GetProcAddress(PdfEngine, "WPDF_Outline"),   \
    wpdfSetTextDefaultAttr=(WPDF_SetTextDefaultAttr*)GetProcAddress(PdfEngine, "WPDF_SetTextDefaultAttr"),   \
    wpdfSetTextAttr=(WPDF_SetTextAttr*)GetProcAddress(PdfEngine, "WPDF_SetTextAttr"),   \
    wpdfSetTextAttrEx=(WPDF_SetTextAttrEx*)GetProcAddress(PdfEngine, "WPDF_SetTextAttrEx"),   \
	wpdfSetPenAttr=(WPDF_SetPenAttr*)GetProcAddress(PdfEngine, "WPDF_SetPenAttr"),   \
	wpdfSetBrushAttr=(WPDF_SetBrushAttr*)GetProcAddress(PdfEngine, "WPDF_SetBrushAttr"),   \
	wpdfSetLicenseKey=(WPDF_SetLicenseKey*)GetProcAddress(PdfEngine, "WPDF_SetLicenseKey"),   \
	wpdfSetCallback=(WPDF_SetCallbackFKT*)GetProcAddress(PdfEngine, "WPDF_SetCallback"),   \
	wpdfDrawMetafileEx=(WPDF_DrawMetafileEx*)GetProcAddress(PdfEngine, "WPDF_DrawMetafileEx"),   \
	wpdfDrawMetafileBuf=(WPDF_DrawMetafileBuf*)GetProcAddress(PdfEngine, "WPDF_DrawMetafileBuf"),   \
	wpdfGetPointer=(WPDF_GetPointer*)GetProcAddress(PdfEngine, "WPDF_GetPointer"),   \
	wpdfSetPointer=(WPDF_SetPointer*)GetProcAddress(PdfEngine, "WPDF_SetPointer"),   \
    wpdfIsUnicodeDLL=(WPDF_IsUnicodeDLL*)GetProcAddress(PdfEngine, "WPDF_IsUnicodeDLL"),   \
	wpdfRichEditPrint=(WPDF_RichEditPrint*)GetProcAddress(PdfEngine, "WPDF_RichEditPrint"),   \
	( (                                                          \
	     (wpdfInitialize==NULL)||(wpdfInitializeEx==NULL)||      \
         (wpdfFinalize==NULL)||(wpdfFinalizeAll==NULL)||         \
         (wpdfSetResult==NULL)||                                 \
         (wpdfBeginDoc==NULL)||(wpdfEndDoc==NULL)||              \
         (wpdfStartPage==NULL)||(wpdfStartPageEx==NULL)|| (wpdfEndPage==NULL)|| \
         (wpdfStartWatermark==NULL)||(wpdfStartWatermarkEx==NULL)||     \
         (wpdfDrawWatermark==NULL)||(wpdfEndWatermark==NULL)||          \
         (wpdfSetSProp==NULL)||(wpdfSetIProp==NULL)||(wpdfExecCommand==NULL)|| \
         (wpdfDrawMetafile==NULL)||                                         \
         (wpdfDrawDIB==NULL)||(wpdfDrawBMP==NULL)||(wpdfDrawJPEG==NULL)||   \
         (wpdfDrawBitmapFile==NULL)||(wpdfDrawBitmapClone==NULL)||          \
         (wpdfDC==NULL)||                                                   \
         (wpdfTextOut==NULL)||(wpdfTextRect==NULL)||(wpdfMoveTo==NULL)||    \
         (wpdfLineTo==NULL)||(wpdfRectangle==NULL)||                        \
         (wpdfRectangle==NULL)||(wpdfMoveTo==NULL)||                        \
         (wpdfHyperlink==NULL)||(wpdfBookmark==NULL)||(wpdfOutline==NULL)|| \
         (wpdfSetTextDefaultAttr==NULL)||(wpdfSetTextAttr==NULL)||   \
         (wpdfSetTextAttrEx==NULL)||(wpdfSetPenAttr==NULL)||   \
		 ((wpdfIsUnicodeDLL&&wpdfIsUnicodeDLL())!=(sizeof(TCHAR)==2))|| \
         (wpdfSetBrushAttr==NULL)    \
      )?  \
      ( FreeLibrary(PdfEngine),   \
        wpdfInitialize=NULL,      \
		wpdfInitializeEx=NULL,    \
        wpdfFinalize=NULL,        \
        wpdfFinalizeAll=NULL,     \
		wpdfIsUnicodeDLL=NULL,    \
        2 ) : 0                   \
      )                           \
    )                             \
  ) \
) \

// The code 
//  ((wpdfIsUnicodeDLL&&wpdfIsUnicodeDLL())!=(sizeof(TCHAR)==2))|| \
// checks wether the engine is a unicode DLL


// note: wpdfSetLicenseKey *may* be NULL in Demo version
// -----------------------------------------------------------------------------
// This constants are used to modify certain properties of the PDF engine
// SetSProp
  #define WPPDF_Author   1
  #define WPPDF_Date     2
  #define WPPDF_ModDate  3
  #define WPPDF_Producer 4
  #define WPPDF_Title    5
  #define WPPDF_Subject  6
  #define WPPDF_Keywords 7
  #define WPPDF_Creator  8
  #define WPPDF_IncludedFonts  9
  #define WPPDF_ExcludedFonts  10
  #define WPPDF_OwnerPassword  11
  #define WPPDF_UserPassword   12
  #define WPPDF_InputFile      13
  #define WPPDF_MergeStart 14
  #define WPPDF_MergeFieldContents 15 
  #define WPPDF_DebugPath 16
  #define WPPDF_BackgroundImage 17
  #define WPPDF_XMPInfoExtension  18
  #define WPPDF_XMPInfoSchemaExtension 19
  #define WPPDF_LICName  1000
  #define WPPDF_LICCode 1001
//SetIProp
  #define WPPDF_ENCODE  1
  #define WPPDF_COMPRESSION  2
  #define WPPDF_PAGEMODE  3
  #define WPPDF_USEFONTMODE  4
  #define WPPDF_Encryption  5
  #define WPPDF_InputFileMode   6
  #define WPPDF_MonochromeThumbnail  7
  #define WPPDF_JPEGCompress  8
  #define WPPDF_EnhancedOptions  9
  #define WPPDF_DevModes 10
  #define WPPDF_PDFOptions 11
  #define WPPDF_Thumbnails 12 // None, Mono, Color
  #define WPPDF_Security 13 // 40, 128 bit
  #define WPPDF_OutlineCharset 14
  #define WPPDF_LICNumber 15
  #define WPPDF_UseForAllSubsequent 20
  #define WPPDF_MetaIsDOTNETEMF 21
  #define WPPDF_CIDFONTMODE 22
  #define WPPDF_PDFAMODE 23
  #define WPPDF_MEMLEAKTEST 24 // -->ReportMemoryLeaksOnShutdown := true;
  #define WPPDF_ABORTTASK 25  // // Set 1 to abort current EMF conversion (Makes only sense in callback, i.e. when font was missing)
  #define WPPDF_ReferenceDC 26 // Assign ReferenceDC
  #define WPPDF_UsePrinterDC 27 // Assign ReferenceDC
  #define WPPDF_ZoomLevelDefault 28 //  set the multiplicator, default = 1, use 20 for .NET
  #define WPPDF_CJK_PRESELECT 29 //Sets charset for CJK unicode ranges
  #define WPPDF_USE_GLYPHS 30 // Use glyphs (= outline vectors) for the text
  #define WPPDF_GlobalBrightness 31 // Sets the brighness for all colors. may be negative or positive
  #define WPPDF_NoOffsetEMF 32 // Activates an experimental switch which can help to remove unwanted X a,d Y offsets
  
 // WPDF_SetCallback
  #define WPPDF_OnStreamOpen 1
  #define WPPDF_OnStreamWrite 2
  #define WPPDF_OnStreamClose 3
  #define WPPDF_OnError 4
  #define WPPDF_OnMessage 5
  #define WPPDF_OnGetText 6

// Message IDs for OnError
 #define WPERR_Bookmark  1 // Bookmark not found
 #define WPERR_Bitmap    2   // Bitmap Errpr
 #define WPERR_FileOpen  3 // Fileopen errr
 #define WPERR_Meta      4 // Metafile error
 #define WPERR_Font      5 // Font embedding error
 #define WPERR_InputPDF  6 // Not able to load PDF file (don't find it, wrong format)
 #define WPERR_BeginDocRequired 10 // Not inside of BeginDoc/EndDoc
 #define WPERR_StartPageRequired 11 // Not inside of StartPage/EndPage or StartWatermark/EndWatermark
 #define WPERR_StreamMissing    12 // On OnStreamWrite method was specified
 #define WPERR_ErrLoadLinkBitmap        13 // the file was not found (param=name)
 #define WPERR_ErrCannotDrawLinkBitmap  14 // cannot draw bitmap (each page!). Buf = &WPDFAutoLink
 #define WPERR_UnknownFormat 15
// This codes are used in the Message callback

 #define WPMSG_BeforeBeginDoc  1
 #define WPMSG_AfterEndDoc     2
 #define WPMSG_EmbedFont       3
 #define WPMSG_InputPDFFile    4
 #define WPMSG_AfterBeginDoc   24
 #define WPMSG_BeforeEndDoc    25
 #define WPMSG_AfterStartPage  26
 #define WPMSG_BeforeEndPage   27

// Codes for the wpdfCommand API
 #define WPCOM_xxxx 0
 #define WPCOM_Version  1  // Result = version * 100
 #define WPCOM_AUTOLINK 2  
 #define WPCOM_FIELD 5     
 #define WPCOM_OUTLINE 6
 #define  WPPDF_AddAction 7 // uses buf=sting
 #define  WPPDF_UseAction  8
 #define  WPPDF_PrintRichEdit 9
 #define  WPPDF_GetInputFilePageCount 10 // read FInputFilePageCount
 #define  WPPDF_GetInputFilePageSize 11 // val=number 0..FInputFilePageCount-1, Result := w*10000+h
 #define   WPPDF_PrintRichEditColumns 12 // val = number of columns
 #define   WPPDF_PrintEMFData 13 // Buf, BufSize
 #define   WPPDF_PrintEMFDataHGlobal 14 // Buf=HGlobal, BufSize  
 #define   WPPDF_InitDC 15 
 #define   WPPDF_CloseDC 16
 #define   WPPDF_ExportMetaAsBMP 17 // val=hmetafile
 #define   WPPDF_GENERATE_EMF_PROTOKOLL 18 // Aktivete the debug protokoll in c:\temp\wpdftest
 #define   WPSYS_SETOCXEVENTS 20
 #define   WPSYS_GETResultBufferLen 21 // Length of Result
 #define   WPSYS_GETResultBuffer 22 // Ptr to Result. If Ptr provided copy there
 #define   WPSYS_ResultBufferClear 23 // Clears the buffer
 #define   WPPDF_EmbedData 24 // data is TEmDataRec
 
 //Codes only used by wRTF2PDF
 #define WPCOM_RTFINIT       1000
 #define WPCOM_RTFVersion    1001
 #define WPCOM_RTFLOAD       1002
 #define WPCOM_RTFAPPEND     1003
 #define WPCOM_RTFMAKEFIELDS 1004
 #define WPCOM_RTFMERGE      1005
 #define WPCOM_RTFSAVE       1006
 #define WPCOM_RTFBACKUP     1007
 #define WPCOM_RTFRESTORE    1008

 #define WPCOM_RTF_PAGEWIDTH     1010
 #define WPCOM_RTF_PAGEHEIGHT    1011
 #define WPCOM_RTF_MARGINLEFT    1012
 #define WPCOM_RTF_MARGINRIGHT   1013
 #define WPCOM_RTF_MARGINTOP     1014
 #define WPCOM_RTF_MARGINBOTTOM  1015

 #define  WPCOM_RTF_DECIMALTABCHAR 1016
 #define  WPCOM_RTF_ConvertRTFEmbededMeta 1017
 #define  WPCOM_RTF_HEADERTEXT 1018
 #define  WPCOM_RTF_FOOTERTEXT 1019

 #define WPCOM_RTF_PAGECOLUMNS   1020
 #define WPCOM_RTF_PAGEROTATION  1021
 #define WPCOM_RTF_PAGEZOOM      1022
 #define WPCOM_RTF_READEROPTIONS 1023 // Bit1: Border=0->no Border, Bit2: Load Landscape, Bit3: Flip w/h
 #define WPCOM_RTF_USE_PRINTER   1024 // Uses printer driver canvas for better measuring (0=off, 1=on)

 #define WPCOM_RTF_PAGESMALLCOLUMNS 1025 // Print multiple columns (decreses Page width)

 // Result = old setting, -1 if error
 #define  WPCOM_RTF_SUPPORTKEEPN 1026 // 1 switches KeepN support on (default), 0 switches it off
 #define  WPCOM_RTF_DONTBREAKTABLES 1027 // 1: don't break tables, 0: Break tables (default);
 #define  WPCOM_RTF_NOWIDOWORPHANPARS 1028 // Switch on orphan/widow control
 #define  WPCOM_RTF_DisableAutosizeTables 1029 // Activate/Deactivate auto table width (default OFF)

 #define  WPCOM_RTFLOADFROMBUFFER 1030 // load from buffer, bufsize
 #define  WPCOM_RTFAPPENDFROMBUFFER 1031 // append from buffer/bufsize
 #define  WPCOM_RTFAPPENDANSI 1032 // Append String
 #define  WPCOM_RTFAPPENDANSICODE 1033 // Append just one ASCII char

// Set Font and Size
 #define  WPCOM_RTF_SETFONTNAME 1040 // Set FontName  buffer
 #define  WPCOM_RTF_SETFONTSIZE 1041 // Set FontSize  buffer
 #define  WPCOM_RTF_NORMALIZEALINDENTS 1042 // Set all indents to 0

 #define  WPCOM_RTF_SET_DEFAULT_CHARSET 1043
 #define  WPCOM_RTF_REMOVE_KEEP 1044
 #define  WPCOM_RTF_REMOVE_KEEPN 1045
// SET FoldLine <0=auto, 0=off, >0 = y in twips
 #define  WPCOM_RTF_NEEDFOLDLINE 1050
//------------------------------------
 #define  WPCOM_RTFPRINT    1100  // Exports PDF
 #define  WPCOM_RTFREFORMAT 1200  // Initializes the formatting, page breaks ect
//------------------------------------
 #define  WPCOM_ISADVANCED 1300 // Check if this is an advanced RTF engine with Memo and TextCursor
 #define  WPCOM_GETMEMO 1301 // Get Memo 1 Interface (IWPEditor interface!)
 #define  WPCOM_GETMEMO2 1302 // Get Memo 2 Interface (IWPEditor interface!)
 #define  WPCOM_GETPDFCreator 1303 // Get PDFCreator
 #define  WPCOM_GETReport 1304 // Get Report - if possible (license!)
 #define  WPCOM_PrintOne 1305 // Result = PageCount
 #define  WPCOM_PDFCreatorPrint 1313 // The same as PDFCreator.Print
 #define  WPCOM_PrintSecond 1306 // Result = PageCount
 #define  WPCOM_GetAttrHelper 1307 // Get AttrHelper
 #define  WPCOM_GetTextCursor 1308 // Get TextCursor
 #define  WPCOM_GetTextAttr 1309 // Get TextAttr
 #define  WPCOM_GetCurrAttr 1310 // Get CurrAttr
  //  WPCOM_GetPrintParameter 1326 // Get PrintParameter

 #define WPCOM_SAVE_PAGE_METAFILE 1311

 // New - Select the special HTML mode
 #define WPCOM_SELECT_HTML_MODE 1312

 //WPCOM_PDFCreatorPrint
 // Set various properties (See Memo.SetBProp) - intparam:group, strparam: id=val
 #define WPCOM_SETBPROP 1314
 #define WPCOM_TOKENCONVERSION 1315 // Convert <<..>> tokens
 #define WPCOM_TOKENHIGHLIGHTING 1316 // use param=4 to higlight bands and fields !
 #define WPCOM_CREATEREPORT 1317 // Convert <<..>> tokens. Use PDFCreator.PRINT2 !
 #define WPCOM_SELECT_PRINTER 1320 // param = printer name
 #define WPCOM_PRINT 1321 // param = page list
 #define WPCOM_PRINT2 1322 // print memo 2, param = page list
 #define  WPCOM_BEGIN_PRINT 1323 // when printing multiple documents into one printing cue
 #define WPCOM_END_PRINT 1324 // use beginprint/endprint
 #define WPCOM_SET_PRINTFILE 1325 // set print file for subsequent printing
 // ---------------------------------------------------------------------------
 #define WPCOM_RTFWPFBACK 1201 // WPF Filename = param, pageno = x
 #define WPCOM_RTFWPF_XPOS 1202 // Move X Coordinate
 #define WPCOM_RTFWPF_YPOS 1203 // Move Y Coordinate 
 // ---------------------------------------------------------------------------
 #define WPMSG_RTFLOAD           1001
 #define WPMSG_RTFPRINTPAGECOUNT 1002
 #define WPMSG_RTFPRINTPAGE      1003
 #define WPMSG_CANNOTLOADWMF     1202

// --------------------------------------------------------------------------- 
 #define WPCONTROLDEF



// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#endif

