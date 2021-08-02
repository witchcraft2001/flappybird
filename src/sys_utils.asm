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
	ld	c,Dss.ScanKey
	rst	#10
	ret	z
	cp	#1B
	ret	nz
	scf
        ret

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