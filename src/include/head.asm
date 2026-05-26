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
		dw 8100h
		dw begin
		dw 0bfffh
		ds 490
		db 0            ; reserved for IM2 table byte at #8100
		
;		.PHASE 8100h
		
