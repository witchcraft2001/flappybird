                device zxspectrum128
                include "include\head.asm"
                include "include\dss_equ.asm"
                include "include\bios_equ.asm"
                include "include\sp_equ.asm"

begin:		    jp main

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
                call FillScreen
                call DrawCity
                ld a,1
                ld (Im2Handler.needChangePage),a        ;Переключаем основной экран на 1
                ei
                halt
                call FillScreen
                call DrawCity
                in a,(RGMOD)
                and a
                ld a,1
                jr nz,.loop
                ld (Im2Handler.needChangePage),a        ;Переключаем основной экран на 1
.loop:          ei
                halt
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
                ld de,138
                ld (.adr1),hl
                add hl,de
                ld (.adr2),hl
                add hl,de
                ld (.adr3),hl
.firstpg:       ld hl,#c000     ;city sprite
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
.memCity      db 0
.memWay       db 0
.memMusic       db 0
                db 0
assetsBlocks    db 3

AssetsDirName   db "ASSETS",0
city            db "city.bin",0
way             db "way.bin",0
music           db "music.bin",0
MemoryDescriptor:
                db 0

;Страницы, которые были открыты при запуске программы
Pages:
Page0:          db 0
Page1:          db 0
Page2:          db 0
Page3:          db 0

CardCoord0:      
.y:             db 0
.x:             dw 0

CardCoord1:
.y:             db 0
.x:             dw 0

                include "grx_utils.asm"
                include "sys_utils.asm"
                include "im2_utils.asm"
                
Palette:
                include "res_pal.asm"
PaletteEnd:
                

AppDir:	        equ ($/80h)*80h+80h
AssetsDir:	equ AppDir + 128
code_end:

                org 0xC000
PlayerStart:
                include "pt3play.asm"
MusicModule:
                incbin "music\mus1.pt3"
PlayerEnd:
                savebin "assets\music.bin",PlayerStart,PlayerEnd-PlayerStart
                savebin "FBIRD.EXE",start_addr,code_end-start_addr