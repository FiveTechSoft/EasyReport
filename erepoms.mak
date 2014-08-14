#Microsoft VS2013 make sample, (c) FiveTech Software 2014

HBDIR=c:\harbour
FWDIR=c:\fwteam
VCDIR="c:\Program Files (x86)\Microsoft Visual Studio 12.0\VC"
SDKDIR="c:\Program Files (x86)\Windows Kits\8.1"

.SUFFIXES: .prg .c .obj .rc .res

PRGS =       \
.\ereport.prg  \ 
.\vrdini.prg   \
.\easyprev.prg \
.\erfile.prg   \
.\eritems.prg  \
.\eritems2.prg \
.\erstart.prg  \
.\ertools.prg  \
.\treelink.prg \
.\treeview.prg \
.\tvitem.prg   \
.\vrd.prg      \
.\vrdbcode.prg \
.\vrditem.prg :

C =	         \
.\cfunc.c    \               
.\point.c    \
.\setmask.c  \
.\treedraw.c :

OBJ=$(PRG:.prg=.obj)
OBJS=$(OBJ:.\=.\obj\)

COBJ=$(C:.c=.obj)
COBJS=$(COBJ:.\=.\obj\)

ereport.exe : $(OBJS) $(COBJS) ereport.res
   echo $(OBJS) > msvc.tmp
   echo $(COBJS) > msvc.tmp

   echo $(FWDIR)\lib\FiveH32.lib $(FWDIR)\lib\FiveHC32.lib >> msvc.tmp

   echo $(HBDIR)\lib\vc32\hbrtl.lib    >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbvm.lib     >> msvc.tmp
   echo $(HBDIR)\lib\vc32\gtgui.lib    >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hblang.lib   >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbmacro.lib  >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbrdd.lib    >> msvc.tmp
   echo $(HBDIR)\lib\vc32\rddntx.lib   >> msvc.tmp
   echo $(HBDIR)\lib\vc32\rddcdx.lib   >> msvc.tmp
   echo $(HBDIR)\lib\vc32\rddfpt.lib   >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbsix.lib    >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbdebug.lib  >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbcommon.lib >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbpp.lib     >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbwin.lib    >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbcplr.lib   >> msvc.tmp
   echo $(HBDIR)\lib\vc32\xhb.lib      >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbpcre.lib   >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbct.lib     >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbcpage.lib  >> msvc.tmp
   echo $(HBDIR)\lib\vc32\hbzlib.lib   >> msvc.tmp
   echo $(HBDIR)\lib\vc32\png.lib      >> msvc.tmp

   echo kernel32.lib  >> msvc.tmp
   echo user32.lib    >> msvc.tmp
   echo gdi32.lib     >> msvc.tmp
   echo winspool.lib  >> msvc.tmp
   echo comctl32.lib  >> msvc.tmp
   echo comdlg32.lib  >> msvc.tmp
   echo advapi32.lib  >> msvc.tmp
   echo shell32.lib   >> msvc.tmp
   echo ole32.lib     >> msvc.tmp
   echo oleaut32.lib  >> msvc.tmp
   echo uuid.lib      >> msvc.tmp
   echo odbc32.lib    >> msvc.tmp
   echo odbccp32.lib  >> msvc.tmp
   echo iphlpapi.lib  >> msvc.tmp
   echo mpr.lib       >> msvc.tmp
   echo version.lib   >> msvc.tmp
   echo wsock32.lib   >> msvc.tmp
   echo msimg32.lib   >> msvc.tmp
   echo oledlg.lib    >> msvc.tmp
   echo psapi.lib     >> msvc.tmp
   echo gdiplus.lib   >> msvc.tmp
   echo winmm.lib     >> msvc.tmp

   echo ereport.res >> msvc.tmp
   
   link @msvc.tmp /nologo /subsystem:windows /NODEFAULTLIB:msvcrt > link.log
   @type link.log
   @del $(PRGS:.prg=.obj)

$(PRGS:.prg=.obj) : $(PRGS:.prg=.c)
$(PRGS:.prg=.c) : $(PRGS)

ereport.res : ereport.rc
   rc.exe -r -d__FLAT__ ereport.rc 
   
.prg.c:
   $(HBDIR)\bin\harbour $< /n /i$(FWDIR)\include;$(HBDIR)\include

.c.obj:
   cl.exe -c -TC -W3 -I$(HBDIR)\include -I$(SDKDIR)\include -I$(VCDIR)\include $<
 