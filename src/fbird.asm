                device zxspectrum128
                include "include\head.asm"
                include "include\dss_equ.asm"
                include "include\bios_equ.asm"
                include "include\sp_equ.asm"

begin:		jp main

main:	        di
;                ld (DOSLine+1),ix
                call SavePages
                ld hl,AppDir
                ld bc,256 + Dss.AppInfo
                rst #10
                ld hl,AppDir
                ld de,AssetsDir
                ld bc,128
                ldir
                ld hl,AssetsDir
                push hl
                call FindNextName
                dec hl
                ex de,hl
                ld hl,AssetsDirName
                ld bc,city-AssetsDirName
                ldir
                pop hl
                push hl
                ld c,Dss.ChDir
                rst #10
                jr nc,.next
                ld hl,OpenDirErrorMessage
                ld c,Dss.PChars
                rst #10
                pop hl
                jp PrintError

.next:          pop hl
                ld hl,ResourcesLoadingMessage
                ld c,Dss.PChars
                rst #10
                ld a,(assetsBlocks)
                push af
                ld b,a
                ld c,Dss.GetMem
                rst #10
                jp c,NotEnoughtMemory
                ld (MemoryDescriptor),a
                ld hl,MemoryBuffer
                ld c,Bios.Emm_Fn5
                rst #08
                pop bc
                ld de,MemoryBuffer
                ld hl,city
.loadLoop:      push de
                push bc
                push hl
                call LoadResource
                jp c,.error                
                pop hl
                call FindNextName
                pop bc
                pop de
                inc de
                djnz .loadLoop                
                call ChangeVideoMode
                ld hl,Palette+1
                ld a,(Palette)
                ld d,a
                ld e,0
                ld a,1
                call SetPalette
                ld hl,Palette+1
                ld a,(Palette)
                ld d,a
                ld e,0
                ld a,0
                call SetPalette

                ; ld hl,TempPal
                ; call ResetPallete
                ; call ShowBackground
                ; call CopyBackground
                ld de,Im2Handler
                call set_im2
                call PlayerInit
                ; ld hl,Palette+1
                ; ld de,TempPal
                ; ld a,(Palette)
                ; ld b,a
                ; ld c,0
                ; call UnfadePallete
                call FillShadowScreen
                call DrawCity
                call DrawWay
                in a,(RGMOD)
                xor 1
                out (RGMOD),a
                call FillShadowScreen
                call DrawCity
                call DrawWay
                in a,(RGMOD)
                and a
                ld a,1
                jr nz,.loop
                ld (Im2Handler.needChangePage),a        ;Переключаем основной экран на 1
.loop:          ei
                halt
                call UpdateBirdState
                call UpdateCityPos
                call UpdateWayPos
                call RestoreBirdBackground
                call DrawCity
                call DrawWay
                call RestoreTubes
                call UpdateTubes
                call DrawTubes                
                call DrawBird
                ld a,1
                ld (Im2Handler.needChangePage),a
                call UpdateBirdCoord

                ; call Update0Screen
                ; call UpdateScreenFlag
                call CheckKeys
                jp nc,.loop

.exit:
                in a,(RGMOD)
                and 1                
                call nz,ChangeVideoPage
                ; ld hl,Palette+1
                ; ld de,TempPal
                ; push de
                ; ld bc,256*4
                ; ldir
                ; pop hl
                ; ld a,(Palette)
                ; ld d,a
                ; ld e,0                
                ; call FadePallete
                call PlayerMute
                call set_im1
                call RestoreVideoMode
                call RestorePages
                ld bc,Dss.Exit
	        rst #10
	        ret

.error:         pop hl
                pop de
                pop bc
                jp  FileReadError

;Обновляем флаг необходимости смены основного экрана
UpdateScreenFlag:
                ld a,1
                ld (Im2Handler.needChangePage),a
                ret

LoadResource:   ld  a,(de)
                out (EmmWin.P3),a
                push hl
                ld c,Dss.PChars
                rst #10
                ld hl,CrLf
                ld c,Dss.PChars
                rst #10
                pop hl
                xor a
	        ld c,Dss.Open
	        rst #10
	        ret c
	        ld (fHandler),A
                LD	HL,ADDR
	        LD	DE,#4000
	        LD	A,(fHandler)
	        LD	C,Dss.Read
	        RST	#10
                push af
                LD	A,(fHandler)
                ld c,Dss.Close
                rst #10
                pop af
                ret
FillShadowScreen:
                in a,(EmmWin.P3)
                push af
                ld a,#50
                out (EmmWin.P3),a
                ld bc,320
                in a,(RGMOD)
                ld hl,#c000
                and 1
                jr nz,FillScreen.firstScreen
                ld hl,#c140
                jr FillScreen.firstScreen

FillScreen:     in a,(EmmWin.P3)
                push af
                ld a,#50
                out (EmmWin.P3),a
                ld bc,320
                in a,(RGMOD)
                ld hl,#c000
                and 1
                jr z,.firstScreen
                ld hl,#c140
.firstScreen:   
                ld b,150
                xor a
.loop1:         out (Y_PORT),a
                ld (hl),0
                inc a
                djnz .loop1
                ld b,70
.loop2:         out (Y_PORT),a
                ld (hl),1
                inc a
                djnz .loop2
                ld b,36
.loop3:         out (Y_PORT),a
                ld (hl),2
                inc a
                djnz .loop3
;TODO: check on real this example                
                ; ld d,d
                ; ld a,100        ;sky height
                ; ld e,e
                ; ld (hl),0
                ; ld b,b
                ; ld a,99
                ; out (Y_PORT),a
                ; ld d,d
                ; ld a,100        ;grass height
                ; ld e,e
                ; ld (hl),1
                ; ld b,b

                ; ld a,199        ;grass Y pos
                ; out (Y_PORT),a
                ; ld d,d
                ; ld a,56         ;wall height
                ; ld e,e
                ; ld (hl),2
                ; ld b,b
                di
                xor a
                out (Y_PORT),a
                ld d,h
                ld e,l
                inc de
                ld bc,#140-1
                ld d,d         ;copy vertical lines
                ld a,0
                ld a,a
                ldir
                ld b,b
                pop af
                out (EmmWin.P3),a
                ret

RestoreBirdBackground:
                in a,(RGMOD)
                ld de,BirdFirstY
                and 1
                jr nz,.first
                ld de,BirdSecondY
.first:         ld a,(de)
                cp #ff
                ret z
                ld hl,#c000+16
                ld bc,#0c11
                jp RestoreRect

UpdateBirdCoord:
                ; ld a,(BirdY)
                ; ld b,a
                ; ld a,(PressedKey)
                ; and a
                call CheckSpace
                jr nz,.down
                xor a
                ld (.state),a
                ld a,6
                ld (.count),a
                ld a,(BirdY)
                and a
                ret z
                sub 5
                jr nc,.less
                xor a
.less:          ld (BirdY),a
                ret
.down:          ld a,6
.count:         equ $-1
                and a
                jr z,.skip
                dec a
                ld (.count),a
                ret
.skip:          ld a,0
.state:         equ $-1
                ld e,a
                inc a
                ld (.state),a
                ld a,(BirdY)
                ld b,a
                ld d,0
                ld hl,DownTable
                add hl,de
                ld a,(hl)
                add a,b
                cp 208
                jr nc,.over
                ld (BirdY),a
                ret
.over:          ld a,208
                ld (BirdY),a
                xor a
                ld (.state),a
                inc a
                ld (GemeOver),a
                ret

UpdateBirdState:
                in a,(RGMOD)
                and 1
                ret z
                ld a,0
.state:         equ $-1
                inc a
                cp 3
                jr c,.less
                xor a
.less:          ld (UpdateBirdState.state),a
                ret

UpdateCityPos:  in a,(RGMOD)
                and 1
                ret z
                ld a,(DrawCity.pos)
                inc a
                cp 138
                jr c,.less
                xor a
.less:          ld (DrawCity.pos),a
                ret

DrawBird:       
                IN A,(EmmWin.P1)
                push af
                IN A,(EmmWin.P3)
                push af
                LD A,#5C
                OUT (EmmWin.P1),A
                ld a,(MemoryBuffer.memBirds)
                out (EmmWin.P3),a
                ld hl,#c000
                ld bc,204
                ld a,(UpdateBirdState.state)
                and a
                jr z,.null
.addAdr:        add hl,bc
                dec a
                jr nz,.addAdr
.null:          push hl                
                ld hl,#4000 + 16
                ld de,BirdFirstY
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld de,BirdSecondY
                ld hl,#4140 + 16
.firstpg:       ld b,12         ;hgt
                ld a,(BirdY)
                ld (de),a
                pop de
                ex hl,de
.loop:          out (Y_PORT),a
                push bc
                push de
                ld bc,17
                ldir
                pop de
                pop bc
                inc a
                djnz .loop
                pop af
                OUT (EmmWin.P3),A
                pop af
                OUT (EmmWin.P1),A
                ret

DrawCity:       
                IN A,(EmmWin.P1)
                push af
                IN A,(EmmWin.P3)
                push af
                LD A,#50
                OUT (EmmWin.P1),A
                ld a,(MemoryBuffer.memCity)
                out (EmmWin.P3),a
                ld hl,#4000
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld hl,#4140
.firstpg:       ld de,138
                ld (.adr1),hl
                add hl,de
                ld (.adr2),hl
                add hl,de
                ld (.adr3),hl
                ld hl,#c000     ;city sprite
                ld a,0
.pos:           equ $-1
                ld c,a
                ld b,0
                add hl,bc
                ld b,39         ;city hgt
                ld a,150        ;city Y pos
.loop:	        PUSH BC
                push af
                OUT (#89),A
                di
                ld de,0
.adr1:          equ $-2                
                ld d,d		;enable accel, set buffer size
                ld a,138        ;pattern lenght
                ld l,l
                ld a,(hl)
                ld (de),a
                ld b,b

                ld de,0
.adr2:          equ $-2
                ld l,l
                ld a,(hl)
                ld (de),a
                ld b,b

                ld de,0
.adr3:          equ $-2
                ld d,d
                ld a,44
                ld l,l
                ld a,(hl)
                ld (de),a
                ld b,b
                ei
                ld bc,276
                add hl,bc
                pop af
                POP BC
                INC A
                DJNZ .loop
                pop af
                OUT (EmmWin.P3),A
                pop af
                OUT (EmmWin.P1),A
                RET
UpdateWayPos:   ld a,(DrawWay.pos)
                ; add a,2
                inc a
                cp 12
                jr c,.less
                xor a
.less:          ld (DrawWay.pos),a
                ret
DrawWay:
                IN A,(EmmWin.P1)
                push af
                IN A,(EmmWin.P3)
                push af
                LD A,#50
                OUT (EmmWin.P1),A
                ld a,(MemoryBuffer.memWay)
                out (EmmWin.P3),a
                ld hl,#4000
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld hl,#4140
.firstpg:       
                ld de,120
                ld (.adr1),hl
                add hl,de
                ld (.adr2),hl
                add hl,de
                ld (.adr3),hl
                ld hl,#c000     ;sprite
                ld a,0
.pos:           equ $-1
                ld c,a
                ld b,0
                add hl,bc
                ld b,11        ;way hgt
                ld a,220        ;way Y pos
.loop:	        PUSH BC
                push af
                OUT (#89),A
                di
                ld de,0
.adr1:          equ $-2                
                ld d,d		;enable accel, set buffer size
                ld a,120        ;pattern lenght
                ld l,l
                ld a,(hl)
                ld (de),a
                ld b,b

                ld de,0
.adr2:          equ $-2
                ld l,l
                ld a,(hl)
                ld (de),a
                ld b,b

                ld de,0
.adr3:          equ $-2
                ld d,d
                ld a,80
                ld l,l
                ld a,(hl)
                ld (de),a
                ld b,b
                ei
                ld bc,140       ;sprite width
                add hl,bc
                pop af
                POP BC
                INC A
                DJNZ .loop
                pop af
                OUT (EmmWin.P3),A
                pop af
                OUT (EmmWin.P1),A
                RET

CoordToAddrP3:  push de
                ld de,#c000
                add hl,de
                pop de
                ret

CoordToAddrP1:  push de
                ld de,#4000
                add hl,de
                pop de
                ret

FindNextName:   ld a,(hl)
                inc hl
                and a
                ret z
                jr FindNextName

;Сохранение номеров страниц при запуске
SavePages:      ld hl,Pages
                ld a,EmmWin.P0
                call SavePage
                inc hl
                ld a,EmmWin.P1
                call SavePage
                inc hl
                ld a,EmmWin.P2
                call SavePage
                inc hl
                ld a,EmmWin.P3
                jp SavePage

;Восстановление номеров страниц при завершении
RestorePages:
                ld hl, Pages
                ld a,EmmWin.P0
                call RestorePage
                inc hl
                ld a,EmmWin.P1
                call RestorePage
                inc hl
            ;ld a,cpu_w2
            ;call SavePage
                inc hl
                ld a,EmmWin.P3
                jp RestorePage

NotEnoughtMemory:	
                ld hl,NotEnoughtMemoryMessage
    	        jp PrintError

FileReadError:
                call RestorePages
                ld hl,FileReadErrorMessage
                jp PrintError

PrintError:	    
                ld c,Dss.PChars			;печатаем
                rst #10
                call RestorePages
                ld a,(MemoryDescriptor)
                and a
                jr z,.next
                ld c,Dss.FreeMem
                rst #10
.next:          ld bc,#FF41
                rst #10
                jp $				; привычка...

PlayerInit:
                in a,(EmmWin.P3)
                push af
                ld a,1
                ld (Im2Handler.musicEnabled),a
                ld a,(MemoryBuffer.memMusic)
                out (EmmWin.P3),a
                call PlayerStart
.exit:          pop af
                out (EmmWin.P3),a
                ret

Player:         ld a,(MemoryBuffer.memMusic)
                out (EmmWin.P3),a
                jp PlayerStart+5
PlayerMute:
                in a,(EmmWin.P3)
                push af
                ld a,(Im2Handler.musicEnabled)
                xor 1
                ld (Im2Handler.musicEnabled),a
                ld a,(MemoryBuffer.memMusic)
                out (EmmWin.P3),a
                call PlayerStart+8
                jr PlayerInit.exit

DrawTubes:      ld ix,Tubes
                ld iy,Tubes1
                in a,(RGMOD)
                and 1
                jr z,.firstpg
                ld iy,Tubes0
.firstpg:       ld b,TUBES_COUNT
                ld de,3
.loop:          ld l,(ix+0)
                ld h,(ix+1)
                ld (iy+0),l
                ld (iy+1),h
                ld a,(ix+2)
                ld (iy+2),a
                call DrawTube
                add ix,de
                add iy,de
                djnz .loop
                ret

RestoreTubes:   in a,(RGMOD)
                ld ix,Tubes1
                and 1
                jr z,.firstpg
                ld ix,Tubes0
.firstpg:       ld b,TUBES_COUNT
                ld de,3
.loop:          ld l,(ix+0)
                ld h,(ix+1)
                ld a,(ix+2)
                and a
                call nz,RestoreTube
                add ix,de
                djnz .loop
                ret

UpdateTubes:    ld ix,Tubes
                ld b,TUBES_COUNT
                ld de,3
.loop:          call UpdateTube
                add ix,de
                djnz .loop
                ret

UpdateTube:     push de
                ld l,(ix+0)
                ld h,(ix+1)
                dec hl
                ld (ix+0),l
                ld (ix+1),h
                bit 7,h
                jr z,.end
                ld de,TubeWidth
                and a
                add hl,de
                ld a,h
                or l
                jr nz,.end
                ld hl,319
                ld (ix+0),l
                ld (ix+1),h
.end:           pop de
                ret

;HL - X position
RestoreTube:    push bc
                push de
                in a,(EmmWin.P3)
                push af
                ld a,#50
                out (EmmWin.P3),a
                push hl
                ld a,h          ;check for left hided size (if x is negative)
                and 254
                jr z,.positive
                pop de
                and a
                ld hl,TubeWidth
                add hl,de
                ld b,l
                ld hl,0
                jr .restore

.positive:      ld bc,TubeWidth
                push bc
                add hl,bc
                ld de,320
                and a
                sbc hl,de
                jr c,.full
                push hl
                pop bc
                pop hl
                and a
                sbc hl,bc       ; visible width of sprite
                jr .sizeSet
.full:          pop hl
.sizeSet:       ld b,l                
                pop hl
.restore:       in a,(RGMOD)
                ld de,#c000
                and 1
                jr nz,.firstpg
                ld de,#c140
.firstpg:       add hl,de
                di
                ld d,d
                ld a,220
                ld b,b
                xor a
                push hl
                pop de
.loop:          out (Y_PORT),a
                ld a,a
                ld c,(hl)
                ld b,b
                out (Y_PORT),a
                ld a,a
                ld (hl),c
                ld b,b
                inc hl
                djnz .loop
                pop af
                out (EmmWin.P3),a
                pop de
                pop bc
                ei
                ret

;HL - X position
;A - Y of head
DrawTube:       push bc
                push de
                ex af,af'
                in a,(EmmWin.P3)
                push af
                in a,(EmmWin.P0)
                push af
                ld a,(MemoryBuffer.memTubes)
                out (EmmWin.P3),a
                ld a,#5c
                out (EmmWin.P1),a
                ; ld hl,0         ;X
                push hl
                ld a,h          ;check for left hided size (if x is negative)
                and 254
                jr z,.positive
                ;todo: handle negative case
                pop de
                push de
                and a
                ld hl,TubeWidth
                add hl,de
                ld a,l
                ld (DrawTubeHead.len),a
                pop de
                ld hl,0
                and a
                sbc hl,de
                in a,(RGMOD)
                ld de,#4000
                and 1
                jr nz,.firstpg1
                ld de,#4140
.firstpg1:      push hl
                push de
                ld bc,RedTubeMiddle
                add hl,bc
                ld (.middle),hl
                ex af,af'
                push af
                ld b,a
                ld a,(DrawTubeHead.len)
                ld c,a
                xor a
                call DrawTubeBody
                pop af
                pop de
                pop hl
                push hl
                push de
                push af

                ld bc,RedTubeDn
                add hl,bc
                call DrawTubeHead

                pop af
                pop de
                pop hl
                add a,80
                ld bc,RedTubeUp
                add hl,bc
                push de
                push af
                call DrawTubeHead
                pop af
                ld hl,0
.middle:        equ $-2
                pop de
                add a,TubeHeadHeight
                ex af,af'
                ld b,a
                ld a,220
                sub b
                ld b,a
                ex af,af'
                call DrawTubeBody
                jr .exit
.positive:      ld bc,TubeWidth
                push bc
                add hl,bc
                ld de,320
                and a
                sbc hl,de
                jr c,.full
                push hl
                pop bc
                pop hl
                and a
                sbc hl,bc       ; visible width of sprite
                jr .sizeSet
.full:          pop hl
.sizeSet:       ld a,l
                ld (DrawTubeHead.len),a
                pop hl
                in a,(RGMOD)
                ld de,#4000
                and 1
                jr nz,.firstpg
                ld de,#4140
.firstpg:       add hl,de
                ex hl,de
                ld hl,RedTubeDn
                ex af,af'
                push af
                push de
                push de
                push af
                call DrawTubeHead
                pop af
                ; sub TubeHeadHeight
                ld b,a
                ld a,(DrawTubeHead.len)
                ld c,a
                xor a
                ld hl,RedTubeMiddle
                pop de
                push bc
                call DrawTubeBody
                pop bc
                pop de
                pop af

                push de
                push af
                add a,80+TubeHeadHeight
                push af
                ld b,a
                ld a,220
                sub b
                ld b,a
                pop af
                ld hl,RedTubeMiddle
                call DrawTubeBody

                pop af
                pop de
                add a,80
                ld hl,RedTubeUp
                ; push af
                ; push de
                call DrawTubeHead
                ; pop de
                ; pop af
                ; add a,TubeHeadHeight
                ; ld hl,RedTubeMiddle
                ; call DrawTubeBody
.exit:          pop af
                out (EmmWin.P0),a
                pop af
                out (EmmWin.P3),a
                pop de
                pop bc
                ret
;HL - Sprite
;DE - Address
;A - Y
;B - Hgt
;C - Len
DrawTubeBody:   
                ; and a
                ; sbc a,b
                ex af,af'
                ld a,b
                ld (.hgt),a
                di
                ld d,d
                ld b,0
.hgt:           equ $-1
                ld b,b
                ex af,af'
                ld b,a
.loop:          ld a,b
                out (Y_PORT),a
                ld a,(hl)
                ld e,e
                ld (de),a
                ld b,b
                inc hl
                inc de
                dec c
                jr nz,.loop
                ei
                ret

;Draw Tube Head
;HL - Sprite
;DE - Address
;A' - Y
DrawTubeHead:   ex af,af'
                ld a,TubeHeadHeight
                ld b,0
                ld c,0                
.len:           equ $-1
.loop:          ex af,af'
                out (Y_PORT),a
                inc a
                push de
                push hl
                push bc
                ldir
                pop bc
                pop hl
                ld de,TubeWidth
                add hl,de
                pop de
                ex af,af'
                dec a
                jr nz,.loop
                ret

Im2Handler:     di
                push af
                push hl
                push bc
                push de
                push ix
                push iy
                exx
                ex af,af'
                push af
                push hl
                push bc
                push de
                push ix
                push iy
	        ld a,0
.needChangePage: equ $-1
	        and a
	        jr z,.skip
                call ChangeVideoPage
                xor a
                ld (.needChangePage),a
.skip:          in a,(EmmWin.P3)
                push af
                ld hl,Counter
                inc (hl)
                ld a,0
.musicEnabled:  equ $-1
                and a
                call nz,Player
                pop af
                out (EmmWin.P3),a
                pop iy
                pop ix
                pop de
                pop bc
                pop hl
                pop af
                ex af,af'
                exx
                pop iy
                pop ix
                pop de
                pop bc
                pop hl
                pop af
                ei
                jp #38

NotEnoughtMemoryMessage:
                db cr,lf,"Error: Not enought memory!",cr,lf
		db cr,lf,0

FileReadErrorMessage:
                db cr,lf,"Error: Can't read file!",cr,lf
		db cr,lf,0
OpenDirErrorMessage:
                db cr,lf,"Error: Can't open ASSETS dir!"
		db cr,lf,0

ResourcesLoadingMessage:
                db cr,lf,"Loading resources, please wait ...",cr,lf
CrLf:		db cr,lf,0

Counter:        db 0
fHandler        db 0

MemoryBuffer:
.memCity        db 0
.memWay         db 0
.memBirds       db 0
.memTubes       db 0
.memMusic       db 0
                db 0
assetsBlocks    db 5

AssetsDirName   db "ASSETS",0
city            db "city.bin",0
way             db "way.bin",0
birds           db "birds.bin",0
tubes           db "tubes.bin",0
music           db "music.bin",0
MemoryDescriptor:
                db 0

;Страницы, которые были открыты при запуске программы
Pages:
Page0:          db 0
Page1:          db 0
Page2:          db 0
Page3:          db 0

; CardCoord0:      
; .y:             db 0
; .x:             dw 0

; CardCoord1:
; .y:             db 0
; .x:             dw 0

GemeOver:       db 0
BirdY:          db 100
BirdFirstY:     db #ff
BirdSecondY:    db #ff

Tubes:
                dw 100
                db 70

                dw 220
                db 30

                dw 319
                db 110

TUBES_COUNT     equ 2
Tubes0          ds TUBES_COUNT*3,0
Tubes1          ds TUBES_COUNT*3,0

                include "grx_utils.asm"
                include "sys_utils.asm"
                include "im2_utils.asm"
                include "bird_tab.asm"
       
Palette:
                include "res_pal.asm"
PaletteEnd:
                
RedTubeDn:      equ #C000
RedTubeUp:      equ RedTubeDn+338
RedTubeMiddle:  equ RedTubeUp+338
GreenTubeDn:    equ RedTubeMiddle+194
GreenTubeUp:    equ GreenTubeDn+338
GreenTubeMiddle: equ GreenTubeUp+338

TubeWidth:      equ 26
TubeHeadHeight: equ 13

AppDir:	        equ ($/80h)*80h+80h
AssetsDir:	equ AppDir + 128
code_end:


                org 0xC000
PlayerStart:
                include "pt3play.asm"
MusicModule:
                incbin "music\mus2.pt3"
PlayerEnd:
                savebin "assets\music.bin",PlayerStart,PlayerEnd-PlayerStart
                savebin "FBIRD.EXE",start_addr,code_end-start_addr