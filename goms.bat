@set oldpath=%path%
@set oldinclude=%include%
@set oldlib=%lib%
@set oldlibpath=%libpath%
if exist "%ProgramFiles%\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" call "%ProgramFiles%\Microsoft Visual Studio 12.0\VC\vcvarsall.bat"
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" call "%ProgramFiles(x86)%\Microsoft Visual Studio 12.0\VC\vcvarsall.bat"
c:\"Program Files (x86)\Microsoft Visual Studio 12.0"\VC\bin\nmake -ferepoms.mak
@set path=%oldpath%
@set include=%oldinclude%
@set lib=%oldlib%
@set libpath=%oldlibpath%
@set oldpath=""
@set oldinclude=""
@set oldlib=
@set oldlibpath=
if errorlevel==0 ereport.exe