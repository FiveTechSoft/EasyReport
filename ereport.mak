#Borland make sample, (c) FiveTech Software 2014

HBDIR=c:\harbour
BCDIR=c:\bcc582
FWDIR=c:\fwteam

#change these paths as needed
.path.OBJ = .\obj
.path.PRG = .\
.path.CH  = $(FWDIR)\include;$(HBDIR)\include
.path.C   = .\
.path.rc  = .\

#important: Use Uppercase for filenames extensions, in the next two rules!

PRG =        \
ereport.prg  \ 
vrdini.prg   \
control.prg  \
dialog.prg   \
easyprev.prg \
erfile.prg   \
eritems.prg  \
eritems2.prg \
erstart.prg  \
ertools.prg  \
example.prg  \
fileedit.prg \
mget.prg     \
tget.prg     \
vrd.prg      \
vrdbcode.prg \
vrditem.prg  

C =          \
cfunc.c                 

PROJECT    : ereport.exe

ereport.exe  : $(PRG:.prg=.obj) $(C:.c=.obj) ereport.res
   echo off
   echo $(BCDIR)\lib\c0w32.obj + > b32.bc
   echo $(PRG:.prg=.obj), + >> b32.bc
   echo ereport.exe, + >> b32.bc
   echo ereport.map, + >> b32.bc
   echo $(FWDIR)\lib\FiveH.lib $(FWDIR)\lib\FiveHC.lib + >> b32.bc
   echo $(HBDIR)\lib\hbrtl.lib + >> b32.bc
   echo $(HBDIR)\lib\hbvm.lib + >> b32.bc
   echo $(HBDIR)\lib\gtgui.lib + >> b32.bc
   echo $(HBDIR)\lib\hblang.lib + >> b32.bc
   echo $(HBDIR)\lib\hbmacro.lib + >> b32.bc
   echo $(HBDIR)\lib\hbrdd.lib + >> b32.bc
   echo $(HBDIR)\lib\rddntx.lib + >> b32.bc
   echo $(HBDIR)\lib\rddcdx.lib + >> b32.bc
   echo $(HBDIR)\lib\rddfpt.lib + >> b32.bc
   echo $(HBDIR)\lib\hbsix.lib + >> b32.bc
   echo $(HBDIR)\lib\hbdebug.lib + >> b32.bc
   echo $(HBDIR)\lib\hbcommon.lib + >> b32.bc
   echo $(HBDIR)\lib\hbpp.lib + >> b32.bc
   echo $(HBDIR)\lib\hbwin.lib + >> b32.bc
   echo $(HBDIR)\lib\hbcpage.lib + >> b32.bc
   echo $(HBDIR)\lib\hbct.lib + >> b32.bc

   echo $(BCDIR)\lib\cw32.lib + >> b32.bc
   echo $(BCDIR)\lib\import32.lib + >> b32.bc
   echo $(BCDIR)\lib\psdk\odbc32.lib + >> b32.bc
   echo $(BCDIR)\lib\psdk\nddeapi.lib + >> b32.bc
   echo $(BCDIR)\lib\psdk\iphlpapi.lib + >> b32.bc
   echo $(BCDIR)\lib\psdk\msimg32.lib + >> b32.bc
   echo $(BCDIR)\lib\psdk\rasapi32.lib, >> b32.bc

   IF EXIST ereport.res echo ereport.res >> b32.bc
   $(BCDIR)\bin\ilink32 -Gn -aa -Tpe -s @b32.bc
   del b32.bc

.PRG.OBJ:
  $(HBDIR)\bin\harbour $< /L /N /W /Oobj\ /I$(FWDIR)\include;$(HBDIR)\include
  $(BCDIR)\bin\bcc32 -c -tWM -I$(HBDIR)\include -oobj\$& obj\$&.c

.C.OBJ:
  echo -c -tWM -D__HARBOUR__ -DHB_API_MACROS > tmp
  echo -I$(HBDIR)\include;$(FWDIR)\include >> tmp
  $(BCDIR)\bin\bcc32 -oobj\$& @tmp $&.c
  del tmp

ereport.res : ereport.rc
  $(BCDIR)\bin\brc32.exe -r ereport.rc