@if not exist obj md obj
c:\bcc582\bin\make -fereport.mak
if errorlevel 0 ereport.exe
