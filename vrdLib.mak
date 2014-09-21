#Borland makefile for EasyReport, (c) FiveTech Software 2014

HBDIR=c:\harbour
BCDIR=c:\bcc582
FWDIR=c:\fwH
#FWDIR=c:\fwTeam

#change these paths as needed
.path.obj = .\obj
.path.prg = .\source
.path.ch  = $(FWDIR)\include;$(HBDIR)\include
.path.c   = .\source
.path.rc  = .\
.path.res = .\

PRG =        \
.\vrd.prg      \
.\ermain.prg \
.\vrdbcode.prg \
.\vrditem.prg   

OBJ=$(PRG:.prg=.obj)
OBJS=$(OBJ:.\=.\obj\)


PROJECT    : vrd.lib

vrd.lib  : $(OBJS)

 $(BCDIR)\bin\tlib vrd.lib -+.\obj\vrd -+.\obj\ermain -+.\obj\vrdbcode -+.\obj\vrditem ,vrd.lst


.PRG.OBJ:
  $(HBDIR)\bin\harbour $< /N /W /Oobj\ /I$(FWDIR)\include;$(HBDIR)\include;.\source
  $(BCDIR)\bin\bcc32 -c -tWM -I$(HBDIR)\include -oobj\$& obj\$&.c
     
  
   

