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
RestoreBackground:
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
	ld b,255
.cls1:	ld c,4
.cls:	ld (hl),a
	inc hl
	dec c
	jr nz,.cls
	djnz .cls1
	pop hl
	ld de,#ff00
	xor a
	call SetPalette
	ret

;HL - current pallette
;DE - buffer
;B - Colors count
;C - Start color number
UnfadePallete:
	ei
	push hl
	push de
	push bc
	xor a
.cls1:	ld c,4
.cls:	ld (de),a
	inc de
	dec c
	jr nz,.cls
	djnz .cls1
	pop de
	pop hl
	push de
	xor a
	call SetPalette
	halt
	pop bc
	ex de,hl
	pop hl
	ld a,64	
.unfadeloop:
	push af
	push hl
	push de
	push bc
	push bc
	push de
.loop1:	ld c,3
.loop:	ld a,(de)
	add 4
	cp (hl)
	jr c,.next
	ld a,(hl)
.next:	ld (de),a
	inc hl
	inc de
	dec c
	jr nz,.loop
	inc hl
	inc de
	djnz .loop1
	pop hl
	pop de
	halt
	xor a
	call SetPalette
	pop bc
	pop de
	pop hl
	pop af
	dec a
	jr nz,.unfadeloop
	push bc
	pop de
	xor a
	call SetPalette
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
        sub a
	call SetPalette
	pop af
	dec a
	jr nz,.fadeloop
	ret

ADDR:	EQU	#C000
OldVideoMode:
	DB	0
OldVideoPage:
	DB	0