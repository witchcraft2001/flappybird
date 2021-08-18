WaitSpaceKey:
.skip:		xor a
		ld (KeyPressed),a
.loop:		ld a,(KeyPressed)
		and a
		jr z,.loop
		cp KEY_SPACE		;Space
		ret z
		cp KEY_ESC
		jr nz,.loop
		scf
		ret

CheckKeys:
		ld a,(KeyPressed)
		and a
		ret z
		cp KEY_ESC
		jr z,.esc
		and a
		ret 
.esc:		xor a
		scf
		ret

CheckSpace:
		ld a,127
		in a,(#FE)
		and 1
		ret

KeysHandler:
.loop:          in a,(SIO_CONTROL_A)
                bit 0,a                 ; 0-bit, байт пришел ?
                ret z           	; нет
                in a,(SIO_DATA_REG_A)
                cp #F0
                jr nz,.key
                ld a,1
                ld (.needskipkey),a
                jr .loop
.key: 
                cp #E0
                jr z,.skipkey
                ld c,0
.needskipkey:   equ $-1
                bit 0,c
                jr nz,.skipkey
                ld (KeyPressed),a
.skipkey:       xor a
                ld (.needskipkey),a
                jr .loop


KeyPressed:	db	0
; процедура сохранения страницы в указнном окне.
; C = окно (порт)
; HL = куда сохранять.
SavePage:	in a,(c)
		ld (hl),a
		ret

; процедура восстановления страницы в указнном окне.
; C = окно (порт)
; HL = от куда восстановить.
RestorePage:	ld a,(hl)
		out (c),a
		ret