rem echo OFF
set PROG=FBIRD
mkdir build
echo Unmounting old image ...
osfmount.com -D -m X:

echo Assembling ...
tools\sjasmplus\sjasmplus.exe %PROG%.asm --lst=%PROG%.lst
if errorlevel 1 goto ERR

echo Preparing floppy disk image ...
copy /Y image\dss_image.img build\%PROG%.img
rem Delay before copy image
timeout 2 > nul
osfmount.com -a -t file -o rw -f build/%PROG%.img -m X:
if errorlevel 1 goto ERR
mkdir X:\%PROG%
mkdir X:\%PROG%\ASSETS
copy /Y %PROG%.EXE /B X:\%PROG%\ /B
copy /Y assets\*.b* /B X:\%PROG%\ASSETS\ /B

mkdir build\%PROG%
mkdir build\%PROG%\ASSETS

copy /Y %PROG%.EXE /B X:\%PROG%\ /B
copy /Y assets\*.b* /B X:\%PROG%\ASSETS /B
copy /Y %PROG%.EXE /B build\%PROG%\ /B
copy /Y assets\*.b* /B build\%PROG%\ASSETS /B

if errorlevel 1 goto ERR
rem Delay before unmounting image
timeout 2 > nul
echo Unmounting image ...
osfmount.com -d -m X:
goto SUCCESS
:ERR
rem pause
echo Some Building ERRORs!!!
pause 0
rem exit
goto END
:SUCCESS
echo Copying image to ZXMAK2 Emulator
copy /Y build\%PROG%.img /B %SPRINTER_EMULATOR% /B
echo Done!
:END
pause 0