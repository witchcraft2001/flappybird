                device zxspectrum128
                include "include/head.asm"
                include "include/keyboard.asm"
                include "include/dss_equ.asm"
                include "include/bios_equ.asm"
                include "include/sp_equ.asm"
                include "sfx_len.asm"

begin:		jp main

                org #8181
Im2DefaultVector:
                jp Im2OtherHandler

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
                pop af
                ld de,MemoryBuffer.memTitle0
                ld hl,title0
                ld b,6
                call LoadResourceList
                jp c,.error
                call ChangeVideoMode
                ld hl,TempPal
                call ResetPallete
                call DrawTitleScreen
                ld hl,TitlePalette+1
                ld de,TempPal
                ld a,(TitlePalette)
                ld b,a
                ld c,0
                call UnfadePallete
                ld hl,TitlePalette+1
                ld a,(TitlePalette)
                ld d,a
                ld e,0
                ld a,1
                call SetPalette
                ld de,MemoryBuffer
                ld hl,city
                ld b,7
                call LoadResourceList
                jp c,.error
                ld de,MemoryBuffer.memMusic
                ld hl,music
                ld b,1
                call LoadResourceList
                jp c,.error
                ld de,MemoryBuffer.memSfxHit
                ld hl,sfxHit
                ld b,3
                call LoadResourceList
                jp c,.error
                call DrawPressToPlay
                call WaitTitlePress
                ld hl,TitlePalette+1
                ld de,TempPal
                ld a,(TitlePalette)
                call CopyPaletteToTemp
                ld hl,TempPal
                ld a,(TitlePalette)
                ld d,a
                ld e,0
                call FadePallete
                ld hl,TempPal
                call ResetPallete
                ld de,Im2Handler
                call set_im2
                call PlayerInit
                call SfxInit
                call InitRenderCache
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
                jr nz,.paletteReady
                ld (Im2Handler.needChangePage),a        ;Переключаем основной экран на 1
.paletteReady:
                call RunRenderCache
                call WaitVsync
                ld hl,Palette+1
                ld de,TempPal
                ld a,(Palette)
                ld b,a
                ld c,0
                call UnfadePallete
                ld hl,Palette+1
                ld a,(Palette)
                ld d,a
                ld e,0
                ld a,1
                call SetPalette
.loop:
                call WaitVsync
                call CheckControlKey
                cp KEY_ESC
                jp nz,.render
                ld a,(GemeOver)
                and a
                jp nz,.render
                ld a,(ReadyCounter)
                and a
                jp nz,.render
                call PauseGame
                ld a,(PauseExitRequested)
                and a
                jp nz,.exit
                jp .loop
.render:
                ld a,2
                out (#fe),a
                call RunRenderCache
                xor a
                out (#fe),a
                ld a,(RestartTransitionRequest)
                and a
                call nz,RestartGameWithFade
                ; call Update0Screen
                ; call UpdateScreenFlag
                jp .loop

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
                call SfxShutdown
                call PlayerMute
                call set_im1
                call RestoreVideoMode
                call RestorePages
                ld bc,Dss.Exit
	        rst #10
	        ret

.error:         jp  FileReadError

RestartGameWithFade:
                xor a
                ld (RestartTransitionRequest),a
                ld hl,Palette+1
                ld de,TempPal
                ld a,(Palette)
                call CopyPaletteToTemp
                ld hl,TempPal
                ld a,(Palette)
                ld d,a
                ld e,0
                call FadePallete
                ld hl,TempPal
                call ResetPallete
                call RestartGameStateInCache
                call RunRenderCache
                call WaitVsync
                call RunRenderCache
                call WaitVsync
                ld hl,Palette+1
                ld de,TempPal
                ld a,(Palette)
                ld b,a
                ld c,0
                call UnfadePallete
                ld hl,Palette+1
                ld a,(Palette)
                ld d,a
                ld e,0
                ld a,1
                jp SetPalette

RestartGameStateInCache:
                call OpenCacheWindow
                ei
                call CacheRestartGame
                call CloseCacheWindow
                ei
                ret

;Обновляем флаг необходимости смены основного экрана
UpdateScreenFlag:
                ld a,1
                ld (Im2Handler.needChangePage),a
                ret

WaitVsync:      di
                xor a
                ld (Im2Handler.vsyncFlag),a
.loop:          ei
                halt
                di
                ld a,(Im2Handler.vsyncFlag)
                and a
                jr z,.loop
                ei
                ret

PauseGame:
                xor a
                ld (PauseExitRequested),a
                call DrawPauseMessage
                xor a
                ld (KeyPressed),a
.debounce:      ld b,12
.debounceLoop:  push bc
                call WaitVsync
                xor a
                ld (KeyPressed),a
                pop bc
                djnz .debounceLoop
.waitRelease:   call WaitVsync
                call CheckControlKey
                and a
                jr nz,.waitRelease
.loop:          call WaitVsync
                call CheckControlKey
                cp KEY_ESC
                jr z,.exit
                cp KEY_SPACE
                jr z,.continue
                jr .loop
.continue:      call ClearPauseMessage
                xor a
                ld (KeyPressed),a
                ld (PauseExitRequested),a
                and a
                ret
.exit:          ld a,1
                ld (PauseExitRequested),a
                ret

LoadResourceList:
.loop:          push de
                push bc
                push hl
                call LoadResourceSilent
                jr c,.error
                pop hl
                call FindNextName
                pop bc
                pop de
                inc de
                djnz .loop
                and a
                ret
.error:         pop hl
                pop bc
                pop de
                scf
                ret

LoadResourceSilent:
                ld  a,(de)
                out (EmmWin.P3),a
                jr LoadResource.open

LoadResource:   ld  a,(de)
                out (EmmWin.P3),a
                push hl
                ld c,Dss.PChars
                rst #10
                ld hl,CrLf
                ld c,Dss.PChars
                rst #10
                pop hl
.open:
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

CopyPaletteToTemp:
                ld c,a
                ld b,0
                sla c
                rl b
                sla c
                rl b
                ldir
                ret

DrawTitleScreen:
                ld a,(MemoryBuffer.memTitle0)
                ld b,51
                ld c,0
                call DrawTitleChunk
                ld a,(MemoryBuffer.memTitle1)
                ld b,51
                ld c,51
                call DrawTitleChunk
                ld a,(MemoryBuffer.memTitle2)
                ld b,51
                ld c,102
                call DrawTitleChunk
                ld a,(MemoryBuffer.memTitle3)
                ld b,51
                ld c,153
                call DrawTitleChunk
                ld a,(MemoryBuffer.memTitle4)
                ld b,51
                ld c,204
                call DrawTitleChunk
                ld a,(MemoryBuffer.memTitle5)
                ld b,1
                ld c,255
                jp DrawTitleChunk

DrawTitleChunk:
                ex af,af'
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                ld a,#50
                out (EmmWin.P1),a
                ex af,af'
                out (EmmWin.P3),a
                ld hl,TitleScreen
.rowLoop:       ld a,c
                out (Y_PORT),a
                inc c
                push bc
                push hl
                ld de,#4000
                ld bc,320
                ldir
                pop hl
                push hl
                ld de,#4140
                ld bc,320
                ldir
                pop hl
                ld de,320
                add hl,de
                pop bc
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
                pop af
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

DrawPressToPlay:
                ld hl,PressToPlayText
                ld a,108
                ld b,180
                jp DrawText

DrawPauseMessage:
                ld hl,PauseContinueText
                ld a,PAUSE_TEXT_X
                ld b,PAUSE_TEXT_Y
                call DrawText
                ld hl,PauseExitText
                ld a,PAUSE_EXIT_TEXT_X
                ld b,PAUSE_EXIT_TEXT_Y
                jp DrawText

ClearPauseMessage:
                in a,(EmmWin.P1)
                push af
                ld a,#50
                out (EmmWin.P1),a
                ld hl,#4000+PAUSE_TEXT_X
                ld de,#4140+PAUSE_TEXT_X
                ld a,PAUSE_TEXT_Y
                ld b,PAUSE_TEXT_H
.rowLoop:       push af
                out (Y_PORT),a
                di
                push bc
                push de
                push hl
                ld d,d
                ld a,PAUSE_TEXT_W
                ld c,c
                xor a
                ld (hl),a
                ld b,b
                pop hl
                pop de
                push de
                push hl
                push de
                pop hl
                ld d,d
                ld a,PAUSE_TEXT_W
                ld c,c
                xor a
                ld (hl),a
                ld b,b
                pop hl
                pop de
                pop bc
                pop af
                inc a
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
                ei
                pop af
                out (EmmWin.P1),a
                ret

DrawText:
                ld (DrawTextX),a
                ld a,b
                ld (DrawTextY),a
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                ld a,#50
                out (EmmWin.P1),a
                ld a,(MemoryBuffer.memFont)
                out (EmmWin.P3),a
.loop:          ld a,(hl)
                and a
                jr z,.done
                cp 32
                jr c,.advance
                cp 96
                jr nc,.advance
                push hl
                call DrawFontGlyph
                pop hl
.advance:       ld a,(DrawTextX)
                add a,8
                ld (DrawTextX),a
                inc hl
                jr .loop
.done:          ld a,#c0
                out (Y_PORT),a
                pop af
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

DrawFontGlyph:
                sub 32
                ld (.tile),a
                and #0f
                add a,a
                add a,a
                add a,a
                ld e,a
                ld d,0
                ld hl,Font8x8
                add hl,de
                ld a,0
.tile:          equ $-1
                rrca
                rrca
                rrca
                rrca
                and #0f
                add a,a
                add a,a
                add a,h
                ld h,a
                push hl
                pop ix
                ld b,8
                ld a,(DrawTextY)
.rowLoop:       out (Y_PORT),a
                inc a
                push af
                push bc
                ld a,(DrawTextX)
                ld de,#4000
                add a,e
                ld e,a
                jr nc,.dst1Ready
                inc d
.dst1Ready:     ld a,(DrawTextX)
                ld hl,#4140
                add a,l
                ld l,a
                jr nc,.dst2Ready
                inc h
.dst2Ready:     ld c,8
.pixelLoop:     ld a,(ix+0)
                cp FONT_BACKGROUND_INDEX
                jr z,.skipPixel
                ld (de),a
                ld (hl),a
.skipPixel:     inc ix
                inc de
                inc hl
                dec c
                jr nz,.pixelLoop
                push ix
                pop hl
                ld de,120
                add hl,de
                push hl
                pop ix
                pop bc
                pop af
                djnz .rowLoop
                ret

WaitTitlePress:
                xor a
                ld (KeyPressed),a
.loop:          call KeysHandler
                call CheckSpace
                ret z
                ld a,(KeyPressed)
                and a
                jr z,.loop
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

SFX_ID_NONE     equ 0
SFX_ID_HIT      equ 1
SFX_ID_DIE      equ 2
SFX_ID_POINT    equ 3
SFX_SILENCE_TAIL_BLOCKS equ 3

SfxInit:
                xor a
                ld (SfxCurrentId),a
                ld (SfxQueue0),a
                ld (SfxQueue1),a
                ld (SfxServiceChunkCounter),a
                ld (SfxSilenceBlocks),a
                ld (SfxCblEnabled),a
                ld bc,CBL_CTRL
                out (c),a
                jp SfxFlushCblBuffer

SfxShutdown:
                xor a
                ld (SfxCurrentId),a
                ld (SfxQueue0),a
                ld (SfxQueue1),a
                ld (SfxSilenceBlocks),a
                ld (SfxCblEnabled),a
                jp SfxHardQuenchCbl

SfxFlushCblBuffer:
                ld bc,CBL_CTRL
                ld a,CBL_CTRL_RUN_11K_MONO
                out (c),a
                ld bc,CBL_DATA
                ld hl,512
.flush:         ld a,CBL_SILENCE
                out (c),a
                dec hl
                ld a,h
                or l
                jr nz,.flush
                ld bc,CBL_CTRL
                xor a
                out (c),a
                ret

SfxQueueHitDie:
                ld a,(SfxCurrentId)
                cp SFX_ID_HIT
                ret z
                cp SFX_ID_DIE
                ret z
                call SfxAbortCblPlayback
                ld a,SFX_ID_HIT
                ld (SfxQueue0),a
                ld a,SFX_ID_DIE
                ld (SfxQueue1),a
                xor a
                ld (SfxCurrentId),a
                call SfxStartNext
                jp SfxPrimePlayback

SfxQueuePoint:
                ld a,(SfxCurrentId)
                and a
                ret nz
                ld a,(SfxQueue0)
                and a
                ret nz
                ld a,(SfxCblEnabled)
                and a
                call nz,SfxAbortCblPlayback
                ld a,SFX_ID_POINT
                ld (SfxQueue0),a
                call SfxStartNext
                jp SfxPrimePlayback

SfxStartNext:
                ld a,(SfxCurrentId)
                and a
                ret nz
                ld a,(SfxQueue0)
                and a
                ret z
                ld (SfxCurrentId),a
                push af
                ld a,(SfxQueue1)
                ld (SfxQueue0),a
                xor a
                ld (SfxQueue1),a
                pop af
                cp SFX_ID_HIT
                jr z,.hit
                cp SFX_ID_DIE
                jr z,.die
                cp SFX_ID_POINT
                jr z,.point
                xor a
                ld (SfxCurrentId),a
                ret
.hit:           ld a,(MemoryBuffer.memSfxHit)
                ld de,SFX_HIT_LEN
                jr .store
.die:           ld a,(MemoryBuffer.memSfxDie)
                ld de,SFX_DIE_LEN
                jr .store
.point:         ld a,(MemoryBuffer.memSfxPoint)
                ld de,SFX_POINT_LEN
.store:         ld (SfxCurrentPage),a
                ld hl,#C000
                ld (SfxCurrentPtr),hl
                ld (SfxRemaining),de
                ret

SfxPrimePlayback:
                ld a,(SfxCurrentId)
                and a
                ret z
                xor a
                ld (SfxSilenceBlocks),a
                ld bc,CBL_CTRL
                ld a,CBL_CTRL_RUN_11K_MONO
                out (c),a
                ld b,2
.primeLoop:     push bc
                call SfxWriteCblBlock
                pop bc
                djnz .primeLoop
.bitReady:
                ld a,(SfxCurrentId)
                and a
                jr nz,.enable
                ld a,(SfxSilenceBlocks)
                and a
                ret z
.enable:
                ld bc,CBL_CTRL
                ld a,CBL_CTRL_RUN_11K_MONO_INT
                out (c),a
                ld a,1
                ld (SfxCblEnabled),a
                ret

SfxHandleCblInterrupt:
                ld a,(SfxCurrentId)
                and a
                jr nz,.loop
                ld a,(SfxSilenceBlocks)
                and a
                jr nz,.loop
                ld a,(SfxCblEnabled)
                and a
                ret z
.loop:
                ld a,#ff
                in a,(#FE)
                bit 7,a
                jr z,.handled              ; FIFO no longer hungry -> full enough
                ld a,(SfxCurrentId)
                and a
                jr nz,.writeSample
                ld a,(SfxSilenceBlocks)
                and a
                jr nz,.writeSilence
                call SfxStopCbl
                jr .handled
.writeSample:
                call SfxWriteCblBlock
                jr .loop                   ; re-check flag, keep filling
.writeSilence:
                call SfxWriteSilenceBlock
                jr .loop
.handled:
                scf
                ret

SfxAbortCblPlayback:
                xor a
                ld (SfxCblEnabled),a
                ld (SfxCurrentId),a
                ld (SfxSilenceBlocks),a
                call SfxHardQuenchCbl
                ei
                ret

SfxStopCbl:
                xor a
                ld (SfxCblEnabled),a
                ld (SfxCurrentId),a
                ld (SfxSilenceBlocks),a
                call SfxHardQuenchCbl
                ret

SfxHardQuenchCbl:
                di
                ld bc,CBL_CTRL
                ld a,CBL_CTRL_RUN_11K_MONO_INT
                out (c),a
                ld bc,CBL_DATA
                ld hl,512
.flush:         ld a,CBL_SILENCE
                out (c),a
                dec hl
                ld a,h
                or l
                jr nz,.flush
                xor a
                ld bc,CBL_CTRL
                out (c),a
                ret

SfxWriteSilenceBlock:
                ld bc,CBL_DATA                  ; C = CBL data port low byte (#4F)
                ld b,SFX_CBL_CHUNK_BYTES
                ld hl,SfxSilenceBuf
.loop:          outi
                jr nz,.loop
                ld hl,SfxSilenceBlocks
                ld a,(hl)
                and a
                ret z
                dec (hl)
                ret

SfxWriteCblBlock:
                in a,(EmmWin.P3)
                push af
                ld bc,CBL_DATA                  ; C = CBL data port low byte (#4F)
                ld a,SFX_CBL_CHUNK_BYTES
                ld (SfxServiceChunkCounter),a   ; bytes still to emit in this block
.loadState:     ld a,(SfxCurrentPage)
                out (EmmWin.P3),a
                ld hl,(SfxCurrentPtr)
                ld de,(SfxRemaining)
.segment:       ld a,d
                or e
                jr z,.sampleEnded               ; current sample exhausted
                ld a,(SfxServiceChunkCounter)
                ld b,a                          ; n = bytes left in this block
                ld a,d
                or a
                jr nz,.haveCount                ; remaining >= 256 > block -> n = block
                ld a,e
                cp b
                jr nc,.haveCount                ; remaining >= block  -> n = block
                ld b,e                          ; remaining < block   -> n = remaining
.haveCount:     ld a,(SfxServiceChunkCounter)
                sub b
                ld (SfxServiceChunkCounter),a   ; block bytes left -= n
                ld a,e
                sub b
                ld e,a
                jr nc,.spanOk
                dec d                           ; sample remaining -= n (16-bit)
.spanOk:        ; B = n (1..128), C = #4F, HL -> sample page (#C000..), DE updated
.write:         outi
                jr nz,.write
                ld a,(SfxServiceChunkCounter)
                or a
                jr nz,.sampleEnded              ; block not full -> sample ran out, chain
                ld (SfxCurrentPtr),hl
                ld (SfxRemaining),de
                pop af
                out (EmmWin.P3),a
                ret
.sampleEnded:   xor a
                ld (SfxCurrentId),a
                call SfxStartNext
                ld a,(SfxCurrentId)
                and a
                jr nz,.loadState
                ld a,(SfxServiceChunkCounter)
                and a
                jr z,.tailSet
                ld b,a
                ld hl,SfxSilenceBuf
.tailFill:      outi
                jr nz,.tailFill
.tailSet:       ld a,SFX_SILENCE_TAIL_BLOCKS
                ld (SfxSilenceBlocks),a
                pop af
                out (EmmWin.P3),a
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
		call SfxHandleCblInterrupt
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
                ld a,1
                ld (.vsyncFlag),a
                jp .end
.end:           pop iy
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
                reti
.vsyncFlag:     db 0

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
DrawTextX:      db 0
DrawTextY:      db 0
PauseExitRequested:
                db 0
FONT_BACKGROUND_INDEX equ 38
PAUSE_TEXT_X    equ 72
PAUSE_TEXT_Y    equ 104
PAUSE_EXIT_TEXT_X equ 116
PAUSE_EXIT_TEXT_Y equ 116
PAUSE_TEXT_W    equ 176
PAUSE_TEXT_H    equ 20
FIELD_SCORE_X   equ 30
FIELD_MEDAL_X   equ 4
FIELD_MEDAL_TARGET_Y equ 231
SfxCurrentId:   db 0
SfxCurrentPage: db 0
SfxCurrentPtr:  dw 0
SfxRemaining:   dw 0
SfxQueue0:      db 0
SfxQueue1:      db 0
SfxServiceChunkCounter:
                db 0
SfxSilenceBlocks:
                db 0
SfxCblEnabled:  db 0
SfxSilenceBuf:  ds SFX_CBL_CHUNK_BYTES,CBL_SILENCE
FieldMedalId:   db #ff
FieldMedalAnim: db 0
FieldMedalFirstY:
                db #ff
FieldMedalSecondY:
                db #ff
FieldMedalCurrentY:
                db #ff

PressToPlayText:
                db "PRESS TO PLAY",0
PauseContinueText:
                db "PRESS FIRE TO CONTINUE",0
PauseExitText:
                db "ESC TO EXIT",0

MemoryBuffer:
.memCity        db 0
.memWay         db 0
.memBirds       db 0
.memTubes       db 0
.memUi          db 0
.memGameOverPanel:
                db 0
.memFont        db 0
.memTitle0      db 0
.memTitle1      db 0
.memTitle2      db 0
.memTitle3      db 0
.memTitle4      db 0
.memTitle5      db 0
.memMusic       db 0
.memSfxHit      db 0
.memSfxDie      db 0
.memSfxPoint    db 0
                db 0
assetsBlocks    db 17

AssetsDirName   db "ASSETS",0
city            db "city.bin",0
way             db "way.bin",0
birds           db "birds.bin",0
tubes           db "tubes.bin",0
ui              db "ui.bin",0
gameOverPanel   db "gopanel.bin",0
font            db "font.bin",0
title0          db "title.bin",0
title1          db "title.b00",0
title2          db "title.b01",0
title3          db "title.b02",0
title4          db "title.b03",0
title5          db "title.b04",0
music           db "music.bin",0
sfxHit          db "hit.raw",0
sfxDie          db "die.raw",0
sfxPoint        db "point.raw",0
MemoryDescriptor:
                db 0

UiBigDigits:    equ #C000
UiSmallDigits:  equ UiBigDigits+16*20*10
UiCoins:        equ UiSmallDigits+8*10*10
UiMedalPlaceholder: equ UiCoins+24*24*4
UiHand:         equ UiMedalPlaceholder+24*24
UiGetReady:     equ UiHand+16*18
UiGameOver:     equ UiGetReady+96*25
UiFlappyBird:   equ UiGameOver+96*25
GameOverPanel:  equ #C000
Font8x8:        equ #C000
TitleScreen:    equ #C000

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
GameOverWaitRelease:
                db 0
GameOverRestartDelay:
                db 0
ReadyCounter:   db 150
ReadyCleanupCounter:
                db 0
RestartTransitionRequest:
                db 0
BirdY:          db 100
BirdFirstY:     db #ff
BirdSecondY:    db #ff

BIOME_CITY_DAY      equ 0
BIOME_CITY_EVENING  equ 1
BIOME_CITY_NIGHT    equ 2
BIOME_VILLAGE_DAY   equ 3
BIOME_VILLAGE_NIGHT equ 4

Score:          dw 0
HighScore:      dw 0
CacheScoreValue:
                dw 0
CacheScoreX:    dw 0
CacheScoreY:    db 0
CacheScoreDigit:
                db 0
CacheScorePrinted:
                db 0
CacheScoreForceDraw:
                db 0
CurrentBiome:   db BIOME_CITY_DAY
CurrentTubeInterval:
                db 156
CurrentTubeGap:
                db 80
CacheDrawTubeGap:
                db 80
RandomSeed:     db #5a
TubeYIndex:     db 0

InitialTubes:
                dw 100
                db 70
                db 80

                dw 256
                db 30
                db 80

                dw 412
                db 110
                db 80

                dw 568
                db 90
                db 80

Tubes:
                dw 100
                db 70
                db 80

                dw 256
                db 30
                db 80

                dw 412
                db 110
                db 80

                dw 568
                db 90
                db 80

TUBE_ENTRY_SIZE equ 4
TUBES_COUNT     equ 4
Tubes0          ds TUBES_COUNT*TUBE_ENTRY_SIZE,0
Tubes1          ds TUBES_COUNT*TUBE_ENTRY_SIZE,0

TubeYCityDay:
                db 44,124,54,114,66,104,78,92
TubeYCityEvening:
                db 38,128,48,118,60,108,72,94
TubeYCityNight:
                db 34,132,44,122,56,112,70,96
TubeYVillageDay:
                db 40,130,50,120,62,110,76,96
TubeYVillageNight:
                db 32,134,42,124,54,114,72,98

TubeIntervalCityDay:
                db 164,156,152,148
TubeIntervalCityEvening:
                db 148,140,136,132
TubeIntervalCityNight:
                db 132,124,120,116
TubeIntervalVillageDay:
                db 116,108,104,100
TubeIntervalVillageNight:
                db 104,96,92,88

InitRenderCache:
                call OpenCacheWindow
                ld hl,CacheRenderCodeStored
                ld de,CACHE_RENDER_BASE
                ld bc,CacheRenderCodeStoredEnd-CacheRenderCodeStored
                ldir
                call CloseCacheWindow
                ld a,r
                xor #5a
                or 1
                ld (RandomSeed),a
                ei
                ret

RunRenderCache:
                call OpenCacheWindow
                ei
                call CacheRenderFrame
                call CloseCacheWindow
                ei
                ret

OpenCacheWindow:
                push bc
                di
                xor a
                ld bc,ISA_SYSTEM_PORT
                out (c),a
                ld a,SYS_MAP_CACHE
                out (SYS_PORT_OFF),a
                in a,(CACHE_ON_PORT)
                pop bc
                ret

CloseCacheWindow:
                push bc
                di
                in a,(CACHE_OFF_PORT)
                ld a,SYS_MAP_DSS
                out (SYS_PORT_OFF),a
                ld bc,ISA_SYSTEM_PORT
                ld a,ISA_SYSTEM_DSS
                out (c),a
                pop bc
                ret

CacheRenderCodeStored:
                include "cache_render.asm"
CacheRenderCodeStoredEnd:

                include "grx_utils.asm"
                include "sys_utils.asm"
                include "im2_utils.asm"
                include "bird_tab.asm"
       
Palette:
                include "res_pal.asm"
PaletteEnd:
TitlePalette:
                include "title_pal.asm"
TitlePaletteEnd:
TempPal:        ds 256*4,0
                
RedTubeDn:      equ #C000
RedTubeUp:      equ RedTubeDn+338
RedTubeMiddle:  equ RedTubeUp+338
GreenTubeDn:    equ RedTubeMiddle+194
GreenTubeUp:    equ GreenTubeDn+338
GreenTubeMiddle: equ GreenTubeUp+338

TubeWidth:      equ 26
TubeWidthRestored: equ TubeWidth-20
TubeHeadHeight: equ 13

AppDir:	        equ ($/80h)*80h+80h
AssetsDir:	equ AppDir + 128
code_end:


                org 0xC000
PlayerStart:
                include "pt3play.asm"
MusicModule:
                incbin "music/mus2.pt3"
PlayerEnd:
                savebin "assets/music.bin",PlayerStart,PlayerEnd-PlayerStart
                savebin "FBIRD.EXE",start_addr,code_end-start_addr
