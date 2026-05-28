ChangeVideoMode:
	LD	C,Dss.GetVMod
	RST	#10
	LD	(OldVideoMode),a
	ld	a,b
	ld	(OldVideoPage),a
	LD	A,#81
	LD	B,1
	call	SetVideoMode
	LD	A,#81
	LD	B,0

SetVideoMode:
	LD	C,Dss.SetVMod
	RST	#10
	RET
RestoreVideoMode:
	ld	a,(OldVideoPage)
	LD	B,a
	LD	a,(OldVideoMode)
	JR	SetVideoMode

ChangeVideoPage:
	in	a,(RGMOD)
	xor	1
	out	(RGMOD),a
	ret

;BC - откуда
;HL - ширина
;DE - куда
;A - Y координата
;A' - Высота

ShowBitmap:
	LD	(.len), HL
	LD	H,B
	LD	L,C
;	LD	HL,ADDR+#76
;	LD	DE,#4000
	EX	AF,AF'
	LD	B,A
	IN	A,(EmmWin.P1)
	PUSH	AF
	LD	A,#50
	OUT	(EmmWin.P1),A
	in a,(RGMOD)
	and 1
	jr z,.firstpg
	ex de,hl
	push de
	ld de,#0140
	add hl,de
	pop de
	ex de,hl
.firstpg:
	EX	AF,AF'
;	LD	A,0
;	LD	B,100
.loop	PUSH	BC
	PUSH	DE
	OUT	(#89),A
	LD	BC,0
.len:	EQU	$-2
	LDIR
	POP	DE
	POP	BC
	INC	A
	DJNZ	.loop
	POP	AF
	OUT	(EmmWin.P1),A
	RET

;BC - откуда
;HL - ширина
;DE - куда
;A - Y координата
;A' - Высота

ShowBitmapShadow:
	LD	(.len), HL
	LD	H,B
	LD	L,C
;	LD	HL,ADDR+#76
;	LD	DE,#4000
	EX	AF,AF'
	LD	B,A
	IN	A,(EmmWin.P1)
	PUSH	AF
	LD	A,#50
	OUT	(EmmWin.P1),A
	in a,(RGMOD)
	and 1
	jr nz,.firstpg
	ex de,hl
	push de
	ld de,#0140
	add hl,de
	pop de
	ex de,hl
.firstpg:
	EX	AF,AF'
;	LD	A,0
;	LD	B,100
.loop	PUSH	BC
	PUSH	DE
	OUT	(#89),A
	LD	BC,0
.len:	EQU	$-2
	LDIR
	POP	DE
	POP	BC
	INC	A
	DJNZ	.loop
	POP	AF
	OUT	(EmmWin.P1),A
	RET
;BC - высота/ширина
;HL - откуда
;DE - куда
;A - Y координата
ShowBitmapAcc:
;	LD	HL,ADDR+#76
;	LD	DE,#4000
	ex af,af'
	ld a,c
	ld (.len),a
	IN A,(EmmWin.P1)
	push af
	LD A,#50
	OUT (EmmWin.P1),A
	in a,(RGMOD)
	and 1
	jr nz,.firstpg
	ex de,hl
	push de
	ld de,#0140
	add hl,de
	pop de
	ex de,hl
.firstpg:
	ex af,af'
;	LD	A,0
;	LD	B,100
.loop:	PUSH BC
	push af
	OUT (#89),A
	di
	ld d,d		;enable accel, set buffer size
	ld a,0
.len:	equ $-1
	ld l,l
	ld a,(hl)
	ld (de),a
	ld b,b
	ei
	ld b,0
	add hl,bc
	pop af
	POP BC
	INC A
	DJNZ .loop
	pop af
	OUT (EmmWin.P1),A
	RET

;BC - высота/ширина
;HL - откуда
;DE - куда
;A - Y координата
ShowMaskBitmapShadowAcc:
;	LD	HL,ADDR+#76
;	LD	DE,#4000
	ex af,af'
	ld a,c
	ld (.len),a
	IN A,(EmmWin.P1)
	push af
	LD A,#5C
	OUT (EmmWin.P1),A
	in a,(RGMOD)
	and 1
	jr nz,.firstpg
	ex de,hl
	push de
	ld de,#0140
	add hl,de
	pop de
	ex de,hl
.firstpg:
	ex af,af'
;	LD	A,0
;	LD	B,100
.loop	PUSH BC
	push af
	OUT (#89),A
	di
	ld d,d		;enable accel, set buffer size
	ld a,0
.len:	equ $-1
	ld l,l
	ld a,(hl)
	ld (de),a
	ld b,b
	ei
	ld b,0
	add hl,bc
	pop af
	POP BC
	INC A
	DJNZ .loop
	pop af
	OUT (EmmWin.P1),A
	RET

;HL - Palette
;D - Colors count
;E - Start color number
;A - Palette number
SetPalette:
	di
	push	hl
	push	de
	push	bc	
	LD	B,0xff
	LD	C,Bios.SetPalette
	RST	0x08
	pop	bc
	pop	de
	pop	hl
	ei
	RET

SetPaletteBoth:
	di
	push	af
	push	bc
	push	de
	push	hl
	in	a,(EmmWin.P3)
	ld	(.savedWin3),a
	ld	a,#50
	out	(EmmWin.P3),a
	ld	a,e
	out	(Y_PORT),a
	ld	b,d
.loop:
	ld	a,(hl)		; B
	ld	(#C3E2),a
	ld	(#C3E6),a
	inc	hl
	ld	a,(hl)		; G
	ld	(#C3E1),a
	ld	(#C3E5),a
	inc	hl
	ld	a,(hl)		; R
	ld	(#C3E0),a
	ld	(#C3E4),a
	inc	hl
	ld	a,(hl)		; Y
	ld	(#C3E3),a
	ld	(#C3E7),a
	inc	hl
	inc	e
	ld	a,e
	out	(Y_PORT),a
	djnz	.loop
	ld	a,#C0
	out	(Y_PORT),a
	ld	a,0
.savedWin3:	equ	$-1
	out	(EmmWin.P3),a
	pop	hl
	pop	de
	pop	bc
	pop	af
	ei
	ret

;Копирует весь основ экран в теневой
CopyBackground:	
        di
        IN A,(EmmWin.P3)
	PUSH AF
	LD A,#50
	OUT (EmmWin.P3),A
	ld hl,#c000
        ld de,#c140
        ld bc,#140
        ld d,d
        ld a,0
.loop:  ld a,a
        ld a,(hl)
	ld (de),a
        ld b,b
	inc hl
	inc de
	dec bc
	ld a,b
	or c
	jr nz,.loop
	pop af
	OUT (EmmWin.P3),A
        ei
        ret
;Восстанавливает из основного ОЗУ в Видео ОЗУ прямоугольник (при использовании режима записи только в VRAM bit 2)
;HL - Addr
;B - Len
;C - Height
;A - Y
RestoreRect:
	ex af,af'
	IN A,(EmmWin.P3)
	push af
	LD A,#50
	OUT (EmmWin.P3),A
	in a,(RGMOD)
	and 1
	jr nz,.firstpg
	ld de,#0140
	add hl,de
.firstpg:
	ld a,c
	ld (.hgt),a
	di
	ex af,af'
.loop:	
	out (Y_PORT),a
	inc a
	ld d,d
	ld c,0
.hgt:	equ $-1
	ld l,l
	ld c,(hl)
	ld (hl),c
	ld b,b
	djnz .loop
	pop af
	out (EmmWin.P3),a
	ei
	ret	

;Восстанавливает из теневого экрана прямоугольник
;HL - Addr
;B - Len
;C - Height
;A - Y
RestoreBackgroundShadow:
	ex af,af'
	IN A,(EmmWin.P3)
	push af
	LD A,#50
	OUT (EmmWin.P3),A
	ld a,c
	ld (.hgt),a
	push hl
	ld de,#140
	add hl,de
	pop de
	di
.loop:	ex af,af'
	out (Y_PORT),a
	ex af,af'
	ld d,d
	ld a,0
.hgt:	equ $-1
	ld a,a
	ld a,(hl)
	ld (de),a
	ld b,b
	inc hl
	inc de
	djnz .loop
	pop af
	out (EmmWin.P3),a
	ei
	ret

;HL - buffer
ResetPallete:
	push hl
	xor a
	ld b,0
.cls1:	ld c,4
.cls:	ld (hl),a
	inc hl
	dec c
	jr nz,.cls
	djnz .cls1
	pop hl
	ld de,#0000
	call SetPaletteBoth
	ret

;HL - target pallette
;DE - buffer
;B - Colors count
;C - Start color number
UnfadePallete:
	ei
	ld (UnfadeTargetPtr),hl
	ld (UnfadeBufferPtr),de
	ld a,b
	ld (UnfadeColorCount),a
	ld a,c
	ld (UnfadeStartColor),a
	ld hl,(UnfadeBufferPtr)
	push hl
	xor a
	ld bc,1024
.clearLoop:
	xor a
	ld (hl),a
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,.clearLoop
	pop hl
	ld d,0
	ld a,(UnfadeStartColor)
	ld e,a
	call SetPaletteBoth
	halt
	ld a,1
.unfadeloop:
	push af
	call BuildFadeLut
	call BuildUnfadePalette
	halt
	ld hl,(UnfadeBufferPtr)
	ld a,(UnfadeColorCount)
	ld d,a
	ld a,(UnfadeStartColor)
	ld e,a
	call SetPaletteBoth
	pop af
	inc a
	cp 33
	jr nz,.unfadeloop
	ld hl,(UnfadeTargetPtr)
	ld a,(UnfadeColorCount)
	ld d,a
	ld a,(UnfadeStartColor)
	ld e,a
	call SetPaletteBoth
	ret

BuildUnfadePalette:
	ld hl,(UnfadeTargetPtr)
	ld de,(UnfadeBufferPtr)
	ld a,(UnfadeColorCount)
	ld b,a
.entryLoop:
	ld c,3
.rgbLoop:
	ld a,(hl)
	srl a
	srl a
	push bc
	push hl
	ld l,a
	ld h,0
	ld bc,FadeLut
	add hl,bc
	ld a,(hl)
	pop hl
	pop bc
	ld (de),a
	inc hl
	inc de
	dec c
	jr nz,.rgbLoop
	xor a
	ld (de),a
	inc hl
	inc de
	djnz .entryLoop
	ret

BuildFadeLut:
	ld (FadeStep),a
	ld hl,FadeLut
	ld c,0
.loop:
	ld a,c
	push bc
	push hl
	call ScaleFadeComponent
	pop hl
	pop bc
	ld (hl),a
	inc hl
	inc c
	ld a,c
	cp 64
	jr nz,.loop
	ret

ScaleFadeComponent:
	ld d,0
	ld e,a
	ld hl,0
	ld a,(FadeStep)
	ld b,8
.mulLoop:
	srl a
	jr nc,.skipAdd
	add hl,de
.skipAdd:
	sla e
	rl d
	djnz .mulLoop
	ld b,5
.shiftLoop:
	srl h
	rr l
	djnz .shiftLoop
	ld a,l
	add a,a
	add a,a
	ret

;HL - temp buffer with current pallette
;D - Colors count
;E - Start color number
FadePallete:
	ei
	ld a,64
.fadeloop:
	push af
	push hl
	ld b,d
.loop1:	ld c,3
.loop:	ld a,(hl)
	sub 4
	jr nc,.next
	xor a
.next:	ld (hl),a
	inc hl
	dec c
	jr nz,.loop
	inc hl
	djnz .loop1
	pop hl
	halt
	call SetPaletteBoth
	pop af
	dec a
	jr nz,.fadeloop
	ret

ADDR:	EQU	#C000
OldVideoMode:
	DB	0
OldVideoPage:
	DB	0
UnfadeTargetPtr:
	DW	0
UnfadeBufferPtr:
	DW	0
UnfadeColorCount:
	DB	0
UnfadeStartColor:
	DB	0
FadeStep:
	DB	0
FadeLut:
	DS	64,0
