#include "FiveWin.ch"
#include "TreeView.ch"

#ifdef __XPP__
   #define New _New
#endif

//----------------------------------------------------------------------------//

CLASS TVItem

   DATA   cPrompt
   DATA   iBmpOpen, iBmpClose
   DATA   Cargo

   METHOD New( cPrompt, iBmpOpen, iBmpClose ) CONSTRUCTOR

   METHOD SetText( cText ) INLINE ::cPrompt := AllTrim( cText )
   METHOD GetText()	   INLINE ::cPrompt

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( cPrompt, iBmpOpen, iBmpClose ) CLASS TVItem

 DEFAULT iBmpOpen := 0, iBmpClose := 0

   #ifdef __XPP__
      #undef New
   #endif

   ::cPrompt   = cPrompt
   ::iBmpOpen  = iBmpOpen
   ::iBmpClose = iBmpClose

return Self

//----------------------------------------------------------------------------//
