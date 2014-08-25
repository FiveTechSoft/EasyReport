//
// OJO, no es el original
// Esta sacado de Davinci.h (http://www.herdsoft.com/ftp/downloads.html#davinci)
//

#define IPT_SELECT        0x000 // 
#define IPT_WMF           0x001 // Windows-Metafile
#define IPT_DXF           0x002 // AUTOCAD DXF-
#define IPT_EPS           0x004 // Encapsulated PostScript EPS
#define IPT_BMP           0x008 // Windows-Bitmapfile
#define IPT_TIF           0x010 // TIFF 5.0
#define IPT_GIF           0x020 // Compuserve GIF
#define IPT_PCX           0x040 // PCX
#define IPT_JPG           0x080 // JPEG-File
#define IPT_PNG           0x100 // PNG (Portable network Graphic)
#define IPT_EMF           0x200 // EMF (Enhanced Windows MetaFile)
#define IPT_JPC          0x1000 // JPEG-2000 Code Stream Syntax (ISO/IEC 15444-1)
#define IPT_JP2          0x2000 // JPEG-2000 JP2 File Format Syntax (ISO/IEC 15444-1)
#define IPT_PGX          0x4000 // JPEG-2000 VM Format
#define IPT_RAS          0x8000 // Sun Rasterfile (RAS)
#define IPT_PNM         0x10000 // Portable Anymap (Graymap/Pixmap/Bitmap) (PNM, PGM, PPM)

#define IPT_FLT           0x800 // 

#define IPE_OK             0    // 

#define IPE_ABORT          1    // 
#define IPE_WRONGTYPE      2    // 
#define IPE_CORRUPTED      3    // 

#define IPE_CLOSE          4    // 
#define IPE_OPEN           5    // 
#define IPE_WRITE          6    // 
#define IPE_EOF            7    // 
#define IPE_NOMEM          8    // 
#define IPE_UNSUPPORTED    9    // 

#define IPE_MAX256        10    // 
#define IPE_REENTERED     11    //

#define IPE_PARAM         12    // 
#define IPE_ERRINFLT      13    //
#define IPE_ERRNOFLT      14    // 
#define IPE_ERRTEXTFLT    15    //
#define IPE_NOLICENSE     16    // 

#define IPE_LAST          32    // 

#define IPF_MSGBOX                   0x1L // 
#define IPF_DIB                      0x8L // 
#define IPF_META                    0x10L // 
#define IPF_ENH                    0x800L // 
#define IPF_COMPRESS                 0x2L // 

#define IPF_TIFF_APPEND         0x200000L // TIFF-Write: Append Page to existing TIF file.

#define IPF_TIFF_COMPMETHOD     0x300000e0 // TIFF-Write Compression Modes
#define IPF_TIFF_NOCOMP         0x00000020 // TIFF-Write: Uncompressed
#define IPF_TIFF_LZW            0x00000040 // TIFF-Write: LZW
#define IPF_TIFF_CCITTRLE       0x00000060 // TIFF-Write: CCITT 
#define IPF_TIFF_CCITTFAX3      0x00000080 // TIFF-Write: CCITT G3 Fax Compression
#define IPF_TIFF_CCITTFAX4      0x000000a0 // TIFF-Write: CCITT G4 Fax Compression
#define IPF_TIFF_PACKBITS       0x000000c0 // TIFF-Write: PACKBITS
#define IPF_TIFF_JPEG           0x000000e0 // TIFF-Write: JPEG
#define IPF_TIFF_DEFLATE        0x10000000 // TIFF-Write: Deflate (zlib)

#define IPF_QUALITY               0xF000L // JPEG- 0x1000: 0x9000 
#define IPF_LOWQUALITY            0x3000L // JPEG
#define IPF_INTERLACED           0x10000L // PNG/GIF-Write: Write in interlaced Mode
#define IPF_PNG_INTERLACED       IPF_INTERLACED // Obsolete

#define IPF_FILEDIALOG               0x4L // 

#define IPF_NOPROGRESSBAR          0x100L // 
#define IPF_NOWAIT                 IPF_NOPROGRESSBAR // 
#define IPF_NOWARNINGS             0x200L // 
#define IPF_ALLOWLZW               0x400L // 

#define IPF_ZLIB_MASK              0xc0000000
#define IPF_ZLIB_DEFAULT_COMPRESSION 0x00000000  // Medium Speed, Medium compression rate for Deflate-Algorithm
#define IPF_ZLIB_BEST_SPEED        0x40000000  // High Speed, Low compression rate for Deflate-Algorithm
#define IPF_ZLIB_BEST_COMPRESSION  0xc0000000  // Low Speed, High compression rate for Deflate-Algorithm


#define IPF_UNUSED                 0x0fde0000  // IPF_xxxx Bits, 

//------------------- Flags for DXF-Import -----------------------
#define IPDXF_BLACKONLY            0x00000001L // Import all DXF-Elements as black
#define IPDXF_IGNOREEXTMINMAX      0x00000002L // 
#define IPDXF_EXTENDED             0x00000004L // 

//------------------- Flags for Import DIB-Type selection --------
#  define IPDIBF_IMPORT_32BIT       0x00020000L// 
#  define IPDIBF_ALLOW_IMPORT_CMYK  0x00080000L//
#  define IPDIBF_ALLOW_IMPORT_48BIT 0x00100000L// 
#  define IPDIBF_ALLOW_IMPORT_RGBA  0x00400000L// 
#define IPDIBF_NORMALIZE            0x00800000L// 

#define IPM_WARNING 1
#define IPM_ERROR   2

