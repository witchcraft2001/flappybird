@echo off
mkdir resources 2>nul
cd resources
python ..\..\tools\resources.py ..\res.txt
copy bird0.bin /B + bird1.bin /B + bird2.bin /B + bird3.bin /B birds.bin /B
copy tube0dn.bin /B + tube0up.bin /B + tube0md.bin /B + tube1dn.bin /B + tube1up.bin /B + tube1md.bin /B tubes.bin /B
copy big_digit0.bin /B + big_digit1.bin /B + big_digit2.bin /B + big_digit3.bin /B + big_digit4.bin /B + big_digit5.bin /B + big_digit6.bin /B + big_digit7.bin /B + big_digit8.bin /B + big_digit9.bin /B + small_digit0.bin /B + small_digit1.bin /B + small_digit2.bin /B + small_digit3.bin /B + small_digit4.bin /B + small_digit5.bin /B + small_digit6.bin /B + small_digit7.bin /B + small_digit8.bin /B + small_digit9.bin /B + coin0.bin /B + coin1.bin /B + coin2.bin /B + coin3.bin /B + ui_hand.bin /B + title_get_ready.bin /B + title_game_over.bin /B + title_flappybird.bin /B ui.bin /B
cd ..
pause 0
