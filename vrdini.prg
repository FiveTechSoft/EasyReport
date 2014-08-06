
#include "FiveWin.ch"

/*----------------------------------------------------------------------------//
   This class is based on the Fivewin ini class. It reads the entries
   faster then the original because it only opens the ini file once.

   Many thanks to José Lalín for the idea.

   Timm Sodtalbers
//----------------------------------------------------------------------------*/

CLASS TIni

   DATA cIniFile
   DATA aSections
   DATA aEntries

   METHOD Get( cSection, cEntry, uDefault, uVar )

   METHOD Set( cSection, cEntry, uValue )

   METHOD Sections()

   METHOD DelSection( cSection ) INLINE DelIniSection( cSection, ::cIniFile )

   METHOD DelEntry( cSection, cEntry ) INLINE ;
                       DelIniEntry( cSection, cEntry, ::cIniFile )

   METHOD GetIniSection( cSection )

   METHOD New( cIniFile ) CONSTRUCTOR

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( cIniFile ) CLASS TIni

   LOCAL i

   DEFAULT cIniFile := ""

   if ! Empty( cIniFile ) .and. At( ".", cIniFile ) == 0
      cIniFile += ".ini"
   endif

   ::cIniFile  = cIniFile
   ::aSections = {}
   ::aEntries  = {}

   ::aSections = ::Sections()

   FOR i := 1 TO LEN( ::aSections )
      AADD( ::aEntries, ::GetIniSection( ::aSections[i] ) )
   NEXT

return Self

//----------------------------------------------------------------------------//

METHOD Get( cSection, cEntry, uDefault, uVar ) CLASS TIni

   LOCAL aCurEntries, nEntry
   LOCAL cType    := ValType( If( uDefault != nil, uDefault, uVar ) )
   LOCAL nSection := ASCAN( ::aSections, cSection )

   IF nSection = 0
      MsgStop( 'Section "' + cSection + '" not found in ' + ::cIniFile )
      RETURN( NIL )
   ELSE
      aCurEntries := ::aEntries[ nSection ]
   ENDIF

   nEntry := ASCAN( aCurEntries, {|x| SUBSTR( x, 1, AT( "=", x ) - 1 ) == cEntry } )

   IF nEntry = 0

      IF uDefault = nil
         uVar := ""
      ELSE
         uVar := uDefault
      ENDIF

   ELSE

      uVar := aCurEntries[ nEntry ]
      uVar := SUBSTR( uVar, AT( "=", uVar ) + 1 )

      DO CASE
      CASE cType == "N"
         uVar = VAL( uVar )
      CASE cType == "D"
         uVar = CToD( uVar )
      CASE cType == "L"
         uVar = ( Upper( uVar ) == ".T." )
      endcase

   ENDIF

return uVar

//----------------------------------------------------------------------------//

METHOD Set( cSection, cEntry, uValue ) CLASS TIni

   LOCAL aCurEntries, nEntry, cOldValue
   LOCAL nSection := ASCAN( ::aSections, cSection )

   IF nSection = 0

      MsgStop( 'Section "' + cSection + '" not found in ' + ::cIniFile )
      RETURN( NIL )

   ELSE

      aCurEntries := ::aEntries[ nSection ]
      nEntry      := ASCAN( aCurEntries, {|x| SUBSTR( x, 1, AT( "=", x ) ) = cEntry } )
      cOldValue   := aCurEntries[ nEntry ]

      ::aEntries[ nSection, nEntry ] := ;
         SUBSTR( cOldValue, 1, AT( "=", cOldValue ) ) + uValue

   ENDIF

   if Empty( ::cIniFile )
      WriteProfString( cSection, cEntry, cValToChar( uValue ) )
   else
      WritePProString( cSection, cEntry, cValToChar( uValue ), ::cIniFile )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD Sections() CLASS TIni

   local cBuffer := Space( 4096 ), p, aSec:={}

   cBuffer := Left( cBuffer, GetPvPrfSe( @cBuffer, 4095, ::cIniFile ) )

   while ( p := At( Chr( 0 ), cBuffer ) ) > 1
      AAdd( aSec, Left( cBuffer, p - 1 ) )
      cBuffer = SubStr( cBuffer, p + 1 )
   enddo

return aSec

//----------------------------------------------------------------------------//

METHOD GetIniSection( cSection ) CLASS TIni

   LOCAL p
   LOCAL aEntries := {}
   LOCAL nBuffer := 8192
   LOCAL cBuffer := Space( nBuffer )

   IF Empty( ::cIniFile )
      GetProfSect( cSection, @cBuffer, nBuffer )
   ELSE
      GetPPSection( cSection, @cBuffer, nBuffer, ::cIniFile )
   ENDIF

   WHILE ( p := At( Chr( 0 ), cBuffer ) ) > 1
      AAdd( aEntries, Left( cBuffer, p - 1 ) )
      cBuffer = SubStr( cBuffer, p + 1 )
   ENDDO

RETURN aEntries

//----------------------------------------------------------------------------//

DLL32 FUNCTION GetPvPrfSe(cBuffer AS LPSTR, nSize AS DWORD, cIni AS LPSTR) AS DWORD PASCAL ;
               FROM "GetPrivateProfileSectionNamesA" LIB "Kernel32.dll"

DLL32 FUNCTION GetProfSect( cSection AS LPSTR, @cData AS LPSTR, ;
                            nSize AS DWORD ) ;
   AS DWORD PASCAL ;
   FROM "GetProfileSectionA" ;
   LIB "Kernel32.dll"

DLL32 FUNCTION GetPPSection( cSection AS LPSTR, @cData AS LPSTR, ;
                             nSize AS DWORD, cFile AS LPSTR ) ;
   AS DWORD PASCAL ;
   FROM "GetPrivateProfileSectionA" ;
   LIB "Kernel32.dll"