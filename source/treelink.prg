
#include "FiveWin.ch"
#include "TreeView.ch"

#ifdef __XPP__
   #define New _New
#endif

//----------------------------------------------------------------------------//

CLASS TTreeLink

   DATA   TreeWnd
   DATA   ParentLink
   DATA   FirstChild, LastChild
   DATA   NextSibling, PrevSibling
   DATA   lOpened, IndentLevel
   DATA   TreeItem
   DATA   Cargo

   METHOD New( oTreeWnd, lOpened ) CONSTRUCTOR

   METHOD AddAtHead( cPrompt, iBmpClose, iBmpOpen, lOpened )
   METHOD AddAtTail( cPrompt, iBmpClose, iBmpOpen, lOpened )
   METHOD AddAfter( cPrompt, iBmpClose, iBmpOpen, lOpened )
   METHOD AddFirstChild( cPrompt, iBmpClose, iBmpOpen, lOpened )
   METHOD AddLastChild( cPrompt, iBmpClose, iBmpOpen, lOpened )

   METHOD GetBitmap() INLINE { ::TreeItem:iBmpOpen, ::TreeItem:iBmpClose }

   METHOD Kill()

   METHOD SetIndent( nIndentLevel ) INLINE ::IndentLevel := nIndentLevel
   METHOD GetIndent() INLINE ::IndentLevel

   METHOD IsRoot()	 INLINE ::ParentLink == nil
   METHOD IsParent()	 INLINE ::FirstChild != nil .and. ::LastChild != nil
   METHOD IsLastChild()
   METHOD IsFirstChild()
   METHOD IsOpened()	 INLINE ::lOpened
   METHOD ToggleOpened() INLINE ::lOpened := iif( ::lOpened, .f., .t. )

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( oTreeWnd, lOpened ) CLASS TTreeLink

 DEFAULT lOpened := .f.

   #ifdef __XPP__
      #undef New
   #endif

   ::TreeWnd := oTreeWnd
   ::lOpened  := lOpened
   ::ParentLink := nil
   ::FirstChild := nil
   ::LastChild	:= nil
   ::PrevSibling := nil
   ::NextSibling := nil
   ::IndentLevel := 0

return Self

//----------------------------------------------------------------------------//

METHOD AddAtHead( cPrompt, iBmpClose, iBmpOpen, lOpened ) CLASS TTreeLink

 Local NewItem, NewLink, head

   NewItem := TVItem():New( cPrompt, iBmpClose, iBmpOpen )
   NewLink := TTreeLink():New( ::TreeWnd, lOpened )

   NewLink:TreeItem   := NewItem
   NewLink:ParentLink := ::ParentLink

   if ::ParentLink != nil
      head = ::ParentLink:FirstChild
   else
      head = Self
      while head:PrevSibling != nil
	 head = head:PrevSibling
      end
   endif

   NewLink:NextSibling = head
   head:PrevSibling    = NewLink

   if ::ParentLink != nil
      ::ParentLink:FirstChild = NewLink
   endif

return NewLink

//----------------------------------------------------------------------------//

METHOD AddAtTail( cPrompt, iBmpClose, iBmpOpen, lOpened ) CLASS TTreeLink

 Local NewItem, NewLink, tail

   NewItem := TVItem():New( cPrompt, iBmpClose, iBmpOpen )
   NewLink := TTreeLink():New( ::TreeWnd, lOpened )

   NewLink:TreeItem   := NewItem
   NewLink:ParentLink := ::ParentLink

   if ::ParentLink != nil
      tail = ::ParentLink:LastChild
   else
      tail = Self
      while tail:NextSibling != nil
	 tail = tail:NextSibling
      end
   endif

   NewLink:PrevSibling = tail
   tail:NextSibling    = NewLink

   if ::ParentLink != nil
      ::ParentLink:LastChild = NewLink
   endif

return NewLink

//----------------------------------------------------------------------------//

METHOD AddAfter( cPrompt, iBmpClose, iBmpOpen, lOpened ) CLASS TTreeLink

 Local NewItem, NewLink

   NewItem := TVItem():New( cPrompt, iBmpClose, iBmpOpen )
   NewLink := TTreeLink():New( ::TreeWnd, lOpened )

   NewLink:TreeItem   := NewItem
   NewLink:ParentLink := ::ParentLink

   if ( ::ParentLink != nil ) .and. ( ::ParentLink:LastChild == Self )
      ::ParentLink:LastChild := NewLink
   endif

   NewLink:PrevSibling := Self
   NewLink:NextSibling := ::NextSibling
   if ::NextSibling != nil
      ::NextSibling:PrevSibling := NewLink
   endif
   ::NextSibling := NewLink

return NewLink

//----------------------------------------------------------------------------//

METHOD AddFirstChild( cPrompt, iBmpClose, iBmpOpen, lOpened ) CLASS TTreeLink

 Local NewItem, NewLink

   NewItem := TVItem():New( cPrompt, iBmpClose, iBmpOpen )
   NewLink := TTreeLink():New( ::TreeWnd, lOpened )

   NewLink:TreeItem   := NewItem
   NewLink:ParentLink := Self

   if ::FirstChild != nil
      ::FirstChild:PrevSibling := NewLink
   endif

   NewLink:NextSibling := ::FirstChild

   ::FirstChild := NewLink
   if ::LastChild == nil
      ::LastChild := NewLink
   endif

return NewLink

//----------------------------------------------------------------------------//

METHOD AddLastChild( cPrompt, iBmpClose, iBmpOpen, lOpened ) CLASS TTreeLink

 Local NewItem, NewLink

   NewItem := TVItem():New( cPrompt, iBmpClose, iBmpOpen )
   NewLink := TTreeLink():New( ::TreeWnd, lOpened )

   NewLink:TreeItem   := NewItem
   NewLink:ParentLink := Self

   if ::LastChild != nil
      ::LastChild:NextSibling := NewLink
   endif

   NewLink:PrevSibling := ::LastChild

   ::LastChild := NewLink
   if ::FirstChild == nil
      ::FirstChild := NewLink
   endif

return NewLink

//----------------------------------------------------------------------------//

METHOD IsLastChild() CLASS TTreeLink

   if ::ParentLink == nil
      return .f.
   endif

   if ::ParentLink:LastChild == Self
      return .t.
   endif

return .f.

//----------------------------------------------------------------------------//

METHOD IsFirstChild() CLASS TTreeLink

   if ::ParentLink == nil
      return .f.
   endif

   if ::ParentLink:FirstChild == Self
      return .t.
   endif

return .f.

//----------------------------------------------------------------------------//

METHOD Kill() CLASS TTreeLink

   // Cannot delete root
   if ::IsRoot()
      return .f.
   endif

   // deleting only child
   if ::PrevSibling == nil .and. ::NextSibling == nil
      ::ParentLink:FirstChild := ::ParentLink:LastChild := nil
      return .t.
   endif

   // deleting tail
   if ::PrevSibling != nil .and. ::NextSibling == nil
      ::ParentLink:LastChild := ::PrevSibling
      ::PrevSibling:NextSibling := nil
      return .t.
   endif

   // deleting head
   if ::PrevSibling == nil .and. ::NextSibling != nil
      ::ParentLink:FirstChild := ::NextSibling
      ::NextSibling:PrevSibling := nil
      return .t.
   endif

   // deleting middle of list
   ::NextSibling:PrevSibling := ::PrevSibling
   ::PrevSibling:NextSibling := ::NextSibling

return .t.

//----------------------------------------------------------------------------//

