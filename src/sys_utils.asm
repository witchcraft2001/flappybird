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
		call CheckControlKey
		cp KEY_SPACE
		jr z,.pressed
		ld a,1
		ret
.pressed:	xor a
		ret

CheckControlKey:
		ld a,127
		in a,(#FE)
		bit 0,a
		jr nz,.none
		ld a,#FE
		in a,(#FE)
		bit 0,a
		jr z,.esc
		ld a,KEY_SPACE
		ret
.esc:		ld a,KEY_ESC
		ret
.none:		ld a,(JoyStart)         ; no key -> joystick (polled once/frame in WaitVsync)
		and a
		jr nz,.esc              ; Start -> Esc
		ld a,(JoyFire)
		and a
		ret z                   ; nothing -> 0
		ld a,KEY_SPACE          ; fire/up -> Space
		ret

; Poll the Sega/Kempston joystick ONCE and cache a one-frame JoyFire edge
; (fire|up) plus JoyStart level. This routine is executed from main DRAM, so read #1F.
; Code copied to WIN0/SRAM cache must use the #07 alias instead.
; Polarity is ACTIVE HIGH (Sprinter inverts the pad: pressed = 1; see spevosdk).
; Use the full SJTEST/TMNT 9-half-cycle sequence so 6-button-compatible pads are
; returned to normal mode every frame. Cycle 2 gives Start/A + connected bits,
; cycle 3 gives directions/B/C. Guard: disconnected or impossible directions
; = floating/absent port -> idle.
PollJoystick:
		push bc
		push de
		push hl
		call .selHigh           ; cycle 1 (stale on some pads)
		in a,(KEMP_PORT_DRAM)   ; #1F: throwaway read of cycle 1 (as in SDK/TMNT)
		call .selLow            ; cycle 2 -> Start/A on SEL low
		in a,(KEMP_PORT_DRAM)   ; A=#60 -> #601F; Start,A,Down,Up,1,1
		and %00111111
		ld h,a
		call .selHigh           ; cycle 3 -> directions/B on SEL high
		in a,(KEMP_PORT_DRAM)   ; A=#E0 -> #E01F; R,L,D,U,B,C (pressed = 1)
		and %00111111
		ld l,a
		call .selLow            ; cycle 4
		call .selHigh           ; cycle 5
		call .selLow            ; cycle 6, 6-button marker
		in a,(KEMP_PORT_DRAM)
		call .selHigh           ; cycle 7, extra buttons
		in a,(KEMP_PORT_DRAM)
		call .selLow            ; cycle 8, extra buttons
		in a,(KEMP_PORT_DRAM)
		call .selHigh           ; cycle 9, back to normal mode
		ld a,h
		and %00000001           ; connected bit from cycle 2
		jr z,.dead
		ld a,l
		and %00000011           ; Right|Left both set -> floating -> dead
		cp %00000011
		jr z,.dead
		ld a,l
		and %00001100           ; Down|Up both set -> floating -> dead
		cp %00001100
		jr z,.dead
		ld a,h
		and JOY_SEGA_START      ; bit5 = Start (pressed = 1)
		ld (JoyStart),a         ; nonzero = Start held
		ld a,l
		and JOY_FLAP_MASK       ; FIRE(B) | UP raw level
		ld e,a
		ld a,(JoyFirePrev)
		cpl
		and e                   ; edge: current & ~previous
		ld (JoyFire),a          ; nonzero for one frame only
		ld a,e
		ld (JoyFirePrev),a
		pop hl
		pop de
		pop bc
		ret
.dead:		xor a
		ld (JoyFire),a
		ld (JoyStart),a
		ld (JoyFirePrev),a
		pop hl
		pop de
		pop bc
		ret
.selHigh:	ld a,5
		out (SIO_CMD_B),a
		ld a,SEGA_SEL_HIGH
		out (SIO_CMD_B),a
		jr .settle
.selLow:	ld a,5
		out (SIO_CMD_B),a
		ld a,SEGA_SEL_LOW
		out (SIO_CMD_B),a
.settle:	ld b,SEGA_SETTLE_DRAM
.sloop:		djnz .sloop
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
