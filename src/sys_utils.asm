WaitSpaceKey:
.loop
	ld	c,Dss.ScanKey
	rst	#10
	jr	z,.loop
	cp	#20
	ret	z
	cp	#1B
	jr	nz,.loop
	scf
        ret

CheckKeys:
	xor	a
	ld	(PressedKey),a
	ld	c,Dss.ScanKey
	rst	#10
	ret	z
	cp	#1B
	jr	z,.esc
	ld	(PressedKey),a
	ret
.esc:	scf
        ret
PressedKey:	db	0
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