@echo off

if EXIST fbird.exe (
	del fbird.exe
)
tools\sjasmplus\sjasmplus.exe fbird.asm --lst=fbird.lst
if errorlevel 1 goto ERR
echo Ok!
goto END

:ERR
del fbird.exe
pause
echo Something was happened...
pause
goto END

:END
