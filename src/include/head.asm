		org 8100h-512
start_addr:
code_start:
		; display "start_addr=",$

		db "EXE"
		db 0
		dw 200h
		dw 0
		dw 0
		dw 0
		dw 0
		dw 0
		dw begin
		dw begin
		dw 0bfffh
		ds 490
		
;		.PHASE 8100h
		
