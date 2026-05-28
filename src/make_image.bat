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
copy /Y assets\city.bin /B X:\%PROG%\ASSETS\ /B
copy /Y assets\way.bin /B X:\%PROG%\ASSETS\ /B
copy /Y assets\birds.bin /B X:\%PROG%\ASSETS\ /B
copy /Y assets\tubes.bin /B X:\%PROG%\ASSETS\ /B
copy /Y assets\ui.bin /B X:\%PROG%\ASSETS\ /B
copy /Y assets\gopanel.bin /B X:\%PROG%\ASSETS\ /B
copy /Y assets\font.bin /B X:\%PROG%\ASSETS\ /B
copy /Y assets\title.bin /B X:\%PROG%\ASSETS\ /B
copy /Y assets\title.b00 /B X:\%PROG%\ASSETS\ /B
copy /Y assets\title.b01 /B X:\%PROG%\ASSETS\ /B
copy /Y assets\title.b02 /B X:\%PROG%\ASSETS\ /B
copy /Y assets\title.b03 /B X:\%PROG%\ASSETS\ /B
copy /Y assets\title.b04 /B X:\%PROG%\ASSETS\ /B
copy /Y assets\music.bin /B X:\%PROG%\ASSETS\ /B
copy /Y assets\hit.raw /B X:\%PROG%\ASSETS\ /B
copy /Y assets\die.raw /B X:\%PROG%\ASSETS\ /B
copy /Y assets\point.raw /B X:\%PROG%\ASSETS\ /B

mkdir build\%PROG%
mkdir build\%PROG%\ASSETS

copy /Y %PROG%.EXE /B X:\%PROG%\ /B
copy /Y assets\city.bin /B X:\%PROG%\ASSETS /B
copy /Y assets\way.bin /B X:\%PROG%\ASSETS /B
copy /Y assets\birds.bin /B X:\%PROG%\ASSETS /B
copy /Y assets\tubes.bin /B X:\%PROG%\ASSETS /B
copy /Y assets\ui.bin /B X:\%PROG%\ASSETS /B
copy /Y assets\gopanel.bin /B X:\%PROG%\ASSETS /B
copy /Y assets\font.bin /B X:\%PROG%\ASSETS /B
copy /Y assets\title.bin /B X:\%PROG%\ASSETS /B
copy /Y assets\title.b00 /B X:\%PROG%\ASSETS /B
copy /Y assets\title.b01 /B X:\%PROG%\ASSETS /B
copy /Y assets\title.b02 /B X:\%PROG%\ASSETS /B
copy /Y assets\title.b03 /B X:\%PROG%\ASSETS /B
copy /Y assets\title.b04 /B X:\%PROG%\ASSETS /B
copy /Y assets\music.bin /B X:\%PROG%\ASSETS /B
copy /Y assets\hit.raw /B X:\%PROG%\ASSETS /B
copy /Y assets\die.raw /B X:\%PROG%\ASSETS /B
copy /Y assets\point.raw /B X:\%PROG%\ASSETS /B
copy /Y %PROG%.EXE /B build\%PROG%\ /B
copy /Y assets\city.bin /B build\%PROG%\ASSETS /B
copy /Y assets\way.bin /B build\%PROG%\ASSETS /B
copy /Y assets\birds.bin /B build\%PROG%\ASSETS /B
copy /Y assets\tubes.bin /B build\%PROG%\ASSETS /B
copy /Y assets\ui.bin /B build\%PROG%\ASSETS /B
copy /Y assets\gopanel.bin /B build\%PROG%\ASSETS /B
copy /Y assets\font.bin /B build\%PROG%\ASSETS /B
copy /Y assets\title.bin /B build\%PROG%\ASSETS /B
copy /Y assets\title.b00 /B build\%PROG%\ASSETS /B
copy /Y assets\title.b01 /B build\%PROG%\ASSETS /B
copy /Y assets\title.b02 /B build\%PROG%\ASSETS /B
copy /Y assets\title.b03 /B build\%PROG%\ASSETS /B
copy /Y assets\title.b04 /B build\%PROG%\ASSETS /B
copy /Y assets\music.bin /B build\%PROG%\ASSETS /B
copy /Y assets\hit.raw /B build\%PROG%\ASSETS /B
copy /Y assets\die.raw /B build\%PROG%\ASSETS /B
copy /Y assets\point.raw /B build\%PROG%\ASSETS /B

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
