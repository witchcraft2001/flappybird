mkdir resources
cd resources
..\..\tools\res_man\resources\bin\Debug\netcoreapp3.1\resources.exe ..\res.txt
copy bird0.bin /B + bird1.bin /B + bird2.bin /B birds.bin /B
rem copy digit0.bin /B + digit1.bin /B + digit2.bin /B + digit3.bin /B + digit4.bin /B + digit5.bin /B + digit6.bin /B + digit7.bin /B + digit8.bin /B + digit9.bin /B digits.bin /B
cd ..
pause 0
