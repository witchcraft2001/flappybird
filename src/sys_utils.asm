CheckSpace:
		call CheckControlKey
		cp KEY_SPACE
		jr z,.pressed
		ld a,1
		ret
.pressed:	xor a
		ret

; KeyFrame (bit0 Space, bit1 Esc) is sampled once per frame in WaitVsync from the
; live PS/2 state (KeysHandler); this replaces the ZX-matrix #FE read, deprecated
; in Sprinter mode.
CheckControlKey:
		ld a,(KeyFrame)
		bit 1,a
		jr nz,.esc
		bit 0,a
		jr nz,.space
		ld a,(JoyStart)         ; no key -> joystick (polled once/frame in WaitVsync)
		and a
		jr nz,.esc              ; Start -> Esc
		ld a,(JoyFire)
		and a
		ret z                   ; nothing -> 0
.space:		ld a,KEY_SPACE          ; Space, or fire/up -> Space
		ret
.esc:		ld a,KEY_ESC
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

; PS/2 scan-code decoder (as in zx-sprinter-sdk sdk/src/sprinter/lib_input.asm, PS2Scan/
; KeyHandler): tracks Space/Esc as live level state (KeyState) plus a one-frame "was
; pressed" latch (KeyLatch), so a tap shorter than a frame still registers for the frame
; it falls in. Called from every IM2 path (Im2Handler, SfxCblIrqHandler, Im2OtherHandler,
; set_im2.sync) and once more from WaitVsync, so a byte is never left in the SIO FIFO
; across a frame. WaitVsync folds KeyState|KeyLatch into KeyFrame once per frame;
; CheckControlKey/CacheCheckSpace read KeyFrame, not the #FE ZX matrix (deprecated in
; Sprinter mode). KeyPressed keeps its old meaning: the last make code, used by the
; title screen as "any PS/2 key". As in the SDK, an #E0-prefixed key is its own code
; (#80|code, so it never matches Space #29 or Esc #76), and any other byte with bit 7
; set (#AA self-test, #FA ack, #E1 Pause prefix...) is keyboard status, not a key: it
; only resets the prefix flags.
; Trashes AF, B, D, E.
KeysHandler:
.loop:          in a,(SIO_CONTROL_A)
                bit 0,a                 ; 0-bit, байт пришел ?
                ret z           	; нет
                in a,(SIO_DATA_REG_A)
                ld e,a
                ld a,(.flags)
                ld d,a                  ; D = prefix flags: bit7 #E0, bit6 #F0
                ld a,e
                cp #E0
                jr z,.ext
                cp #F0
                jr z,.brk
                xor a
                ld (.flags),a           ; a code or a status byte ends the sequence
                bit 7,e
                jr nz,.loop             ; status byte, not a key
                ld a,d
                and #80
                or e                    ; A = key code, #80|code for an extended key
                ld b,1
                cp KEY_SPACE
                jr z,.known
                ld b,2
                cp KEY_ESC
                jr z,.known
                ld b,0                  ; B = KeyState/KeyLatch bit of this key
.known:         bit 6,d
                jr nz,.release
                ld (KeyPressed),a       ; any key -> "press any key" on the title
                ld a,(KeyLatch)
                or b
                ld (KeyLatch),a
                ld a,(KeyState)
                or b
                ld (KeyState),a
                jr .loop
.release:       ld a,b
                cpl
                ld b,a
                ld a,(KeyState)
                and b
                ld (KeyState),a
                jr .loop
.ext:           ld a,d
                or #80
                jr .setFlags
.brk:           ld a,d
                or #40
.setFlags:      ld (.flags),a
                jr .loop
.flags:         db 0

KeyState:	db	0		; bit0 Space held, bit1 Esc held (live PS/2 level)
KeyLatch:	db	0		; bit0/1 set on make, OR'd into KeyFrame once per frame
KeyFrame:	db	0		; snapshot formed in WaitVsync: KeyState | KeyLatch
KeyPressed:	db	0		; last make code (#80|code if extended), 0 = none
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
