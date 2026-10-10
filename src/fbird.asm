                device zxspectrum128
                IFDEF AUTOTEST
                OUTPUT "../build/autotest/FBIRD.EXE"
                ELSE
                OUTPUT "FBIRD.EXE"
                ENDIF
                include "include/head.asm"
                include "include/keyboard.asm"
                include "include/dss_equ.asm"
                include "include/bios_equ.asm"
                include "include/sp_equ.asm"
                include "sfx_len.asm"

begin:		jp main

                ds #8181-$,0
Im2DefaultVector:
                jp Im2OtherHandler

main:	        di
                ld a,(ix-3)             ; DSS loader mode: handle of the open EXE file
                ld (fHandler),a
                ld hl,BannerMessage
                ld c,Dss.PChars
                rst #10
                call SavePages
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
                ld de,MemoryBuffer.memTitle0    ; the logo goes into the title pages first
                ld b,SPRINTER_LOGO_PAGES
                call LoadResourceList
                jp c,.error
                call ChangeVideoMode
                ld hl,TempPal
                call ResetPallete
                call DrawSprinterLogo
                ld hl,LogoPalette+1
                ld de,TempPal
                ld a,(LogoPalette)
                ld b,a
                ld c,0
                call UnfadePallete
                ld de,MemoryBuffer.memTitle0    ; the logo is on screen, its pages are free
                ld b,6
                call LoadResourceList
                jp c,.error
                ei
                ld b,SPRINTER_LOGO_PAUSE
.logoPause:     halt
                djnz .logoPause
                ld hl,LogoPalette+1
                ld de,TempPal
                ld a,(LogoPalette)
                call CopyPaletteToTemp
                ld hl,TempPal
                ld a,(LogoPalette)
                ld d,a
                ld e,0
                call FadePallete
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
                ld b,7
                call LoadResourceList
                jp c,.error
                ld de,MemoryBuffer.memMusic
                ld b,1
                call LoadResourceList
                jp c,.error
                ld de,MemoryBuffer.memSfxHit
                ld b,3
                call LoadResourceList
                jp c,.error
                ld de,MemoryBuffer.memCityNight
                ld b,1
                call LoadResourceList
                jp c,.error
                call CloseExeFile
                ld a,(MemoryBuffer.memCity)
                ld (CurrentCityPage),a
                call DrawPressToStart
                ld de,Im2Handler
                call set_im2            ; start 50Hz IM2 early so the joystick is polled
                                        ; on the title too (music stays off until PlayerInit)
                IFDEF AUTOTEST
                ld a,1
                ld (DbgTitleReady),a
                ENDIF
                call WaitTitlePress
                xor a
                ld (JoyFire),a          ; do not carry the title Fire edge into gameplay
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
                ld a,(ThemeTransitionRequest)
                and a
                call nz,ThemeTransitionWithFade
                ; call Update0Screen
                ; call UpdateScreenFlag
                jp .loop

.exit:
                di
                ld a,#03                ; stop CTC timers (sw reset + INT off) so the
                out (CTC_CH2),a         ; extra 50Hz IM2 source doesn't derail the next
                out (CTC_CH3),a         ; program after returning to DSS
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

;Короткий fade out/in при смене темы день/ночь
ThemeTransitionWithFade:
                ld a,(GemeOver)
                and a
                jr z,.start
                xor a                   ; restart returns to day anyway
                ld (ThemeTransitionRequest),a
                ret
.start:         ld a,THEME_FADE_STEP
.fadeOut:       push af
                call SetPaletteDarkened
                pop af
                add a,THEME_FADE_STEP
                jr nc,.fadeOut
                ld a,255                ; black
                call SetPaletteDarkened
                call OpenCacheWindow
                ei
                call CacheSwitchTheme
                call CloseCacheWindow
                ei
                call RunRedrawCache
                call WaitVsync
                call RunRedrawCache
                call WaitVsync
                ld a,256-THEME_FADE_STEP
.fadeIn:        push af
                call SetPaletteDarkened
                pop af
                sub THEME_FADE_STEP
                jr nz,.fadeIn
                call WaitVsync
                ld hl,Palette+1
                ld a,(Palette)
                ld d,a
                ld e,0
                call SetPaletteBoth
                ld hl,Palette+1
                ld a,(Palette)
                ld d,a
                ld e,0
                ld a,1
                jp SetPalette

;A - value subtracted from every colour component of the game palette (0 - as is, 255 - black).
;One pass without multiplications, so a fade step always fits into a frame.
SetPaletteDarkened:
                ld c,a
                ld hl,Palette+1
                ld de,TempPal
                ld a,(Palette)
                ld b,a
.entryLoop:     push bc
                ld b,3
.rgbLoop:       ld a,(hl)
                sub c
                jr nc,.store
                xor a
.store:         ld (de),a
                inc hl
                inc de
                djnz .rgbLoop
                xor a
                ld (de),a
                inc hl
                inc de
                pop bc
                djnz .entryLoop
                call WaitVsync
                ld hl,TempPal
                ld a,(Palette)
                ld d,a
                ld e,0
                jp SetPaletteBoth

RunRedrawCache:
                call OpenCacheWindow
                ei
                call CacheRedrawFrame
                call CloseCacheWindow
                ei
                ret

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
                ; SDK-style: flip the rendered page here, right at the frame boundary,
                ; so a slow (DI) render cannot defer the flip into the visible area.
                ld a,(Im2Handler.needChangePage)
                and a
                jr z,.noflip
                call ChangeVideoPage
                xor a
                ld (Im2Handler.needChangePage),a
.noflip:        ; Only AF changes here: WaitFrame stands in for a bare halt inside the
                ; palette fades, whose callers keep HL/D/E live across it.
                push bc
                push de
                call KeysHandler        ; drain the SIO FIFO here too, so a byte stuck
                                        ; behind a swallowed IM2 ack never survives a frame
                ld a,(KeyLatch)
                ld e,a
                ld a,(KeyState)
                or e
                ld (KeyFrame),a         ; frame snapshot: level-held or pressed-since-last-frame
                xor a
                ld (KeyLatch),a
                pop de
                pop bc
                ; Poll from the main DRAM code path. Kempston/Sega is #1F here;
                ; #07 is only for code executed from WIN0/SRAM cache.
                call PollJoystick       ; keeps BC/DE/HL
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
.continue:      call ClearPauseMessageBack      ; hidden page: remove the text, redraw the
                call RunRedrawCache             ; sprites it covered, show the page
                call WaitVsync
                call ClearPauseMessageBack      ; the same for the other page
                call RunRedrawCache
                call WaitVsync
                xor a
                ld (KeyPressed),a
                ld (PauseExitRequested),a
                and a
                ret
.exit:          ld a,1
                ld (PauseExitRequested),a
                ret

; Reads the resources that follow the resident part of the EXE, one per page.
; Each record is: dw length, data (see the end of this file).
;DE - list of page numbers
;B - count
LoadResourceList:
.loop:          push de
                push bc
                ld a,(de)
                out (EmmWin.P3),a
                ld hl,ResLength
                ld de,2
                call ReadExe
                jr c,.error
                ld de,(ResLength)
                ld hl,ADDR
                call ReadExe
                jr c,.error
                pop bc
                pop de
                inc de
                djnz .loop
                and a
                ret
.error:         pop bc
                pop de
                scf
                ret

;HL - buffer
;DE - size
;CF set on a DSS error or a short read
ReadExe:        push de
                ld a,(fHandler)
                ld c,Dss.Read
                rst #10
                pop hl
                ret c
                and a
                sbc hl,de               ; requested - actually read
                ret z
                scf
                ret

; Called exactly once per run (either after the last LoadResourceList on the success path,
; or from PrintError on a load failure) -- no "already closed" guard needed. DSS handles are
; small numbers starting at 0 (sprinter_dss/DOS_FM.ASM GET_FM), so 0 is a valid handle and
; cannot be used as an "unset/closed" sentinel.
CloseExeFile:   ld a,(fHandler)
                ld c,Dss.Close
                rst #10
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

SPRINTER_LOGO_H equ 200
SPRINTER_LOGO_Y equ (256-SPRINTER_LOGO_H)/2
SPRINTER_LOGO_PAGE_ROWS equ 16384/320   ; rows per file, as tools/resources.py splits images
SPRINTER_LOGO_PAGES equ 4
SPRINTER_LOGO_PAUSE equ 150             ; frames at full brightness: 3 s at 50 Hz

; The 320x200 logo in the middle of both video pages; its first row is black, repeated it
; fills the bands above and below.
DrawSprinterLogo:
                ld a,(MemoryBuffer.memTitle0)
                ld b,SPRINTER_LOGO_Y
                ld c,0
                ld hl,0
                call DrawImageRows
                ld a,(MemoryBuffer.memTitle0)
                ld b,SPRINTER_LOGO_PAGE_ROWS
                ld c,SPRINTER_LOGO_Y
                call DrawTitleChunk
                ld a,(MemoryBuffer.memTitle1)
                ld b,SPRINTER_LOGO_PAGE_ROWS
                ld c,SPRINTER_LOGO_Y+SPRINTER_LOGO_PAGE_ROWS
                call DrawTitleChunk
                ld a,(MemoryBuffer.memTitle2)
                ld b,SPRINTER_LOGO_PAGE_ROWS
                ld c,SPRINTER_LOGO_Y+SPRINTER_LOGO_PAGE_ROWS*2
                call DrawTitleChunk
                ld a,(MemoryBuffer.memTitle3)
                ld b,SPRINTER_LOGO_H-SPRINTER_LOGO_PAGE_ROWS*3
                ld c,SPRINTER_LOGO_Y+SPRINTER_LOGO_PAGE_ROWS*3
                call DrawTitleChunk
                ld a,(MemoryBuffer.memTitle0)
                ld b,256-SPRINTER_LOGO_Y-SPRINTER_LOGO_H
                ld c,SPRINTER_LOGO_Y+SPRINTER_LOGO_H
                ld hl,0
                jp DrawImageRows

;A - page, B - rows, C - first screen row
DrawTitleChunk:
                ld hl,320
;HL - source step per row (0 repeats the first row of the page)
DrawImageRows:
                ld (.step),hl
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
                ld de,0
.step:          equ $-2
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

DrawPressToStart:
                ld hl,PressToStartText
                ld a,(320-PRESS_TO_START_LEN*8)/2
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

; Стирает сообщение паузы на невидимой странице (спрайты поверх дорисует RunRedrawCache)
ClearPauseMessageBack:
                in a,(EmmWin.P1)
                push af
                ld a,#50
                out (EmmWin.P1),a
                ld hl,#4000+PAUSE_TEXT_X
                in a,(RGMOD)
                and 1
                jr nz,.pageReady
                ld hl,#4140+PAUSE_TEXT_X
.pageReady:     ld a,PAUSE_TEXT_Y
                ld b,PAUSE_TEXT_H
.rowLoop:       push af
                out (Y_PORT),a
                cp PLAYFIELD_GRASS_Y    ; the background of the row, as CacheClearPlayfieldPages fills it
                ld a,(ThemeSkyColor)
                jr c,.colorReady
                ld a,(ThemeGrassColor)
.colorReady:    ld c,a
                di
                push bc
                push hl
                ld d,d
                ld a,PAUSE_TEXT_W
                ld c,c
                ld a,c
                ld (hl),a
                ld b,b
                ei
                pop hl
                pop bc
                pop af
                inc a
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
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
                ld a,#5C
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
.dst2Ready:     ld a,(ix+0)
                ld (de),a
                ld (hl),a
                inc ix
                inc de
                inc hl
                ld a,(ix+0)
                ld (de),a
                ld (hl),a
                inc ix
                inc de
                inc hl
                ld a,(ix+0)
                ld (de),a
                ld (hl),a
                inc ix
                inc de
                inc hl
                ld a,(ix+0)
                ld (de),a
                ld (hl),a
                inc ix
                inc de
                inc hl
                ld a,(ix+0)
                ld (de),a
                ld (hl),a
                inc ix
                inc de
                inc hl
                ld a,(ix+0)
                ld (de),a
                ld (hl),a
                inc ix
                inc de
                inc hl
                ld a,(ix+0)
                ld (de),a
                ld (hl),a
                inc ix
                inc de
                inc hl
                ld a,(ix+0)
                ld (de),a
                ld (hl),a
                inc ix
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
.loop:          call WaitVsync          ; frame-sync; polls joystick after the halt.
                                        ; Keyboard is serviced by the IM2 handler now.
                call CheckSpace          ; PS/2 Space (KeyFrame) + cached joystick fire
                ret z
                ld a,(KeyPressed)        ; any PS/2 key (set by the keyboard IRQ)
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
                ei
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
                call CloseExeFile
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
                ld a,(MemoryBuffer.memMusic)
                out (EmmWin.P3),a
                call PlayerStart
                ld a,1                  ; only after the init: a CTC tick inside it would
                ld (Im2Handler.musicEnabled),a  ; run Player on half-initialised state
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
                ld a,CBL_CTRL_RUN_11K_MONO_INT
                out (c),a
                ld a,1
                ld (SfxCblEnabled),a
                ret

; Vector #FF is shared by VSync (FPGA), every PS/2 byte and this CBL half-FIFO-empty
; signal, so a plain "feed on every call" (the previous code) fed 128 bytes on VSync
; and keyboard interrupts too, draining the sample in well under its real duration
; (observed: hit+die played in ~57% of their real time in MAME). #FE bit 7 (CBL_IND,
; valid while the CBL is running) is the actual request: only feed when it is set, and
; check again after feeding in case one half-empty event was already missed while this
; vector was busy with something else -- catch up by at most one extra block per call
; (modplay's CBL_ISR, sources/modplay/src/lib/cbl.asm, re-reads bit 7 the same way but
; only counts the overrun).
; Writing a block clears the request (MAME: bit 7 = (play ^ write half) & #80), so the
; second pass only feeds on a real miss. Both passes re-check SfxCblEnabled first: once
; a pass has finished the sample (SfxFinishCbl, CBL idle) bit 7 is no longer CBL_IND.
SfxHandleCblInterrupt:
                call .service           ; first pass, then fall through for the second
.service:       ld a,(SfxCblEnabled)
                and a
                ret z
                in a,(#FE)
                and #80
                ret z
                ld a,(SfxCurrentId)
                and a
                jr nz,.writeSample
                ld a,(SfxSilenceBlocks)
                and a
                jr nz,.writeSilence
                call SfxFinishCbl
                scf
                ret
.writeSample:
                call SfxWriteCblBlock
                scf
                ret
.writeSilence:
                call SfxWriteSilenceBlock
                scf
                ret

; Vector #FF is shared by VSync (FPGA), every PS/2 byte and the CBL half-FIFO-empty
; signal (see #FE bit 7 in SfxHandleCblInterrupt). Never touches Y_PORT/WIN1/VRAM.
SfxCblIrqHandler:
                di
                push af
                push hl
                push bc
                push de
                call SfxHandleCblInterrupt
                call KeysHandler        ; drain the SIO byte here too, or the keyboard
                                        ; stalls whenever this vector fires without one
                pop de
                pop bc
                pop hl
                pop af
                ei
                reti

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

SfxFinishCbl:
                xor a
                ld (SfxCblEnabled),a
                ld (SfxCurrentId),a
                ld (SfxSilenceBlocks),a
                ld bc,CBL_CTRL
                ld a,CBL_CTRL_IDLE
                out (c),a
                ret

; Both callers clear SfxCblEnabled before calling this, so SfxHandleCblInterrupt already
; ignores the CBL vector for the whole flush -- no di needed, and the caller's IFF is
; left untouched.
SfxHardQuenchCbl:
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
.spanOk:        ; B = n (1..128), C = #4F, HL -> sample page (#C000..), DE updated.
                ; Groups of 8 OUTIs (as in modplay's StreamScratchToFIFO, sources/modplay
                ; /src/lib/cbl.asm): back-to-back OUTIs are fine on real CBL hardware
                ; within a group of 8, but a fully unrolled run (128 in a row) measurably
                ; distorted the sample; pace only between groups, and finish any remainder
                ; below 8 one byte at a time.
.write:         ld a,b
                cp 8
                jr c,.tail
                outi
                outi
                outi
                outi
                outi
                outi
                outi
                outi
                jr .write
.tail:          and a
                jr z,.written
.tailStep:      outi
                jr nz,.tailStep
.written:
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

; CTC ch3 tick (~50 Hz, synchronized to VSync in set_im2): the frame clock for the main
; loop and the music. One IM2 ack clears every pending FPGA request (VSync, keyboard,
; CBL; MAME: irqack_cb -> in_clear<0..2>), so this handler also drains the SIO FIFO and
; serves a CBL half-empty request whose own #FF interrupt this CTC ack swallowed;
; otherwise that block is lost and the sample stalls for one block. The CBL check comes
; after Player: #FE bit 7 stays set until the block is written, so it still sees a
; request swallowed by the ack, and also one raised while Player ran (in MAME the CTC's
; RETI drops the shared INT line under such a request, so it would never be taken).
; Writes only EmmWin.P3 (saved/restored) for the player; never touches Y_PORT, WIN1 or
; VRAM, so it needs no coordination with the accelerator di/ei windows in the renderer.
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
                call KeysHandler
		ld a,0
.needChangePage: equ $-1
		and a
		jr z,.skip
.skip:          in a,(EmmWin.P3)                ;flip done in main loop after WaitVsync
                push af
                ld hl,Counter
                inc (hl)
                ld a,0
.musicEnabled:  equ $-1
                and a
                call nz,Player
                call SfxHandleCblInterrupt      ; after Player: see above
                pop af
                out (EmmWin.P3),a
                ld a,1
                ld (.vsyncFlag),a
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

BannerMessage:
                db "FlappyBird by Dmitry Mikhalchenkov v.0.2.1",cr,lf,0

ResourcesLoadingMessage:
                db cr,lf,"Loading resources, please wait ...",cr,lf
CrLf:		db cr,lf,0

Counter:        db 0
fHandler        db 0
ResLength:      dw 0
DrawTextX:      db 0
DrawTextY:      db 0
PauseExitRequested:
                db 0
PAUSE_TEXT_W    equ PAUSE_CONTINUE_LEN*8  ; the wider line; both are cleared as one box
PAUSE_TEXT_X    equ (320-PAUSE_TEXT_W)/2
PAUSE_TEXT_Y    equ 174                ; below the Get Ready banner and digit (rows 112..163)
PAUSE_EXIT_TEXT_X equ (320-PAUSE_EXIT_LEN*8)/2
PAUSE_EXIT_TEXT_Y equ PAUSE_TEXT_Y+12
PAUSE_TEXT_H    equ 20
PLAYFIELD_GRASS_Y equ 150               ; sky above, grass from here to the road (the city is drawn over it)
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

PressToStartText:
                db "PRESS FIRE TO START"
PRESS_TO_START_LEN equ $-PressToStartText
                db 0
                IFDEF AUTOTEST
DbgTitleReady:  db 0                    ; set when the title waits for Fire (tools/mame_fbird.lua)
                ENDIF
PauseContinueText:
                db "PRESS FIRE TO CONTINUE"
PAUSE_CONTINUE_LEN equ $-PauseContinueText
                db 0
PauseExitText:
                db "START/ESC TO EXIT"
PAUSE_EXIT_LEN  equ $-PauseExitText
                db 0
                ASSERT PAUSE_EXIT_LEN <= PAUSE_CONTINUE_LEN   ; ClearPauseMessageBack clears PAUSE_TEXT_W

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
.memCityNight   db 0
                db 0
assetsBlocks    db 18
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
GameOverStage:  db 0                    ; CacheRenderGameOver: settled scene frames, then panel, then static
GAME_OVER_PANEL equ 2
GAME_OVER_STATIC equ 4
ReadyCounter:   db 150
ReadyCleanupCounter:
                db 0
RestartTransitionRequest:
                db 0
JoyFire:        db 0            ; Sega/Kempston fire|up edge, polled once per frame
JoyStart:       db 0            ; Sega Start button (-> Esc/pause)
JoyFirePrev:    db 0            ; previous raw fire|up level for edge detection
BirdY:          db 100
BirdFirstY:     db #ff
BirdSecondY:    db #ff

THEME_DAY       equ 0
THEME_NIGHT     equ 1
DAY_SKY_COLOR   equ 0
DAY_GRASS_COLOR equ 1
NIGHT_SKY_COLOR equ 193         ; reserved in assets/res.txt
NIGHT_GRASS_COLOR equ 194       ; reserved in assets/res.txt
THEME_FADE_STEP equ 32          ; darkening per frame of the day/night fade (256/8 steps)

CurrentTheme:   db THEME_DAY
PendingTheme:   db THEME_DAY
ThemeTransitionRequest:
                db 0
CurrentCityPage:
                db 0
ThemeSkyColor:  db DAY_SKY_COLOR
ThemeGrassColor:
                db DAY_GRASS_COLOR

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
CacheHudDirtyFirst:
                db 1
CacheHudDirtySecond:
                db 1
CurrentLevel:   db 0
CurrentLevelParams:
                dw LevelParams          ; -> 8-byte row in LevelParams for CurrentLevel
ScoreInTheme:   db 0                    ; 0..49, counts up to the next day/night switch
ThemeParity:    db 0                    ; 0 = day, 1 = night; toggles every 50 points
CurrentTubeGap: db 80
CacheDrawTubeGap:
                db 80
RandomSeed:     db #5a
TubeYIndex:     db 0

InitialTubes:
                dw 100
                db 70
                db 80
                db 0
                db #ff

                dw 256
                db 50
                db 80
                db 0
                db #ff

                dw 412
                db 80
                db 80
                db 0
                db #ff

                dw 568
                db 56
                db 80
                db 0
                db #ff

Tubes:
                dw 100
                db 70
                db 80
                db 0
                db #ff

                dw 256
                db 50
                db 80
                db 0
                db #ff

                dw 412
                db 80
                db 80
                db 0
                db #ff

                dw 568
                db 56
                db 80
                db 0
                db #ff

TUBE_ENTRY_SIZE equ 6
TUBES_COUNT     equ 4
Tubes0          ds TUBES_COUNT*TUBE_ENTRY_SIZE,0
Tubes1          ds TUBES_COUNT*TUBE_ENTRY_SIZE,0

; Tube Y tables, two levels per set. Even entries < TUBE_Y_SPLIT <= odd ones (CacheSelectTubeY
; relies on it); the spread sets the height jumps: about 27, 37, 53, 68, 82 px on average.
TUBE_Y_SPLIT    equ 72
TubeYSet0:
                db 50,80,56,74,46,86,60,78
TubeYSet1:
                db 44,86,50,80,40,92,56,74
TubeYSet2:
                db 36,96,44,88,30,102,50,82
TubeYSet3:
                db 28,104,36,96,22,112,44,88
TubeYSet4:
                db 20,112,30,104,14,120,38,96

; Score at which each level 1..LEVEL_MAX begins (level 0 covers score 0..LevelScores[0]-1).
; All entries must stay below 256: CacheUpdateLevel compares the low byte of Score only.
LevelScores:    db 10,25,50,75,100,125,150,175,200
LEVEL_MAX       equ $-LevelScores       ; top level; LevelParams has LEVEL_MAX+1 rows

; LEVEL_PARAMS_SIZE bytes per level: gap, moving-tube threshold (0..127, CacheRandom range),
; 4 spawn intervals in px (one is picked at random), dw pointer to the tube-Y table.
; Mirrored in tools/mame_fbird.lua (LEVEL_GAP, LEVEL_INTERVALS, TUBE_Y_SETS).
LevelParams:
                db 80,0,  164,156,152,148
                dw TubeYSet0
                db 80,13, 156,148,144,140
                dw TubeYSet0
                db 78,19, 148,140,136,132
                dw TubeYSet1
                db 76,26, 140,132,128,124
                dw TubeYSet1
                db 74,32, 132,124,120,116
                dw TubeYSet2
                db 72,38, 124,116,112,108
                dw TubeYSet2
                db 70,45, 120,112,108,104
                dw TubeYSet3
                db 68,51, 116,108,104,100
                dw TubeYSet3
                db 66,58, 108,100,96,92
                dw TubeYSet4
                db 64,64, 104,96,92,88
                dw TubeYSet4
LEVEL_PARAMS_SIZE equ 8                 ; CacheUpdateLevel multiplies by it with 3 x add hl,hl

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
LogoPalette:
                include "logo_pal.asm"
TempPal:        ds 256*4,0
                
RedTubeDn:      equ #C000
RedTubeUp:      equ RedTubeDn+338
RedTubeMiddle:  equ RedTubeUp+338
GreenTubeDn:    equ RedTubeMiddle+26
GreenTubeUp:    equ GreenTubeDn+338
GreenTubeMiddle: equ GreenTubeUp+338

TubeWidth:      equ 26
TubeWidthRestored: equ TubeWidth-20
TubeMinY:       equ 8
TubeRightMinVisible: equ 4
TubeHeadHeight: equ 13

code_end:
                ds (((code_end-#8100)+511)/512)*512-(code_end-#8100)
resident_end:
                ASSERT resident_end <= #BE00        ; the stack lives below #BFFF

; Resources: the DSS loader reads only the part above, the rest is read by LoadResourceList.
; Records go in the order of the load calls in main; the data of each is assembled at
; #C000 (the page window it will be read into).
                MACRO RESOURCE endLabel, file
                org #BFFE
                dw endLabel-#C000
                incbin file
endLabel:
                ASSERT endLabel <= #10000
                ENDM

                RESOURCE ResLogo0, "assets/sprinter_logo.bin"
                RESOURCE ResLogo1, "assets/sprinter_logo.b00"
                RESOURCE ResLogo2, "assets/sprinter_logo.b01"
                RESOURCE ResLogo3, "assets/sprinter_logo.b02"
                RESOURCE ResEnd0, "assets/title.bin"
                RESOURCE ResEnd1, "assets/title.b00"
                RESOURCE ResEnd2, "assets/title.b01"
                RESOURCE ResEnd3, "assets/title.b02"
                RESOURCE ResEnd4, "assets/title.b03"
                RESOURCE ResEnd5, "assets/title.b04"
                RESOURCE ResEnd6, "assets/city.bin"
                RESOURCE ResEnd7, "assets/way.bin"
                RESOURCE ResEnd8, "assets/birds.bin"
                RESOURCE ResEnd9, "assets/tubes.bin"
                RESOURCE ResEnd10, "assets/ui.bin"
                RESOURCE ResEnd11, "assets/gopanel.bin"
                RESOURCE ResEnd12, "assets/font.bin"

                org #BFFE
                dw PlayerEnd-PlayerStart
PlayerStart:
                include "pt3play.asm"
MusicModule:
                incbin "music/mus2.pt3"
PlayerEnd:

                RESOURCE ResEnd13, "assets/hit.raw"
                RESOURCE ResEnd14, "assets/die.raw"
                RESOURCE ResEnd15, "assets/point.raw"
                RESOURCE ResEnd16, "assets/cityn.bin"
