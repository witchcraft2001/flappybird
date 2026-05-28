                DISP CACHE_RENDER_BASE

CacheRenderFrame:
                ld a,(GemeOver)
                and a
                jr z,.checkReady
                call CacheCheckGameOverRestart
                ld a,(GemeOver)
                and a
                jr z,.checkReady
                jp CacheRenderGameOver
.checkReady:    ld a,(ReadyCounter)
                and a
                jr z,.play
                jp CacheRenderReady
.play:
                call CacheUpdateBirdState
                call CacheUpdateCityPos
                call CacheUpdateWayPos
                call CacheRestoreBirdBackground
                call CacheRestoreFieldMedalBackground
                call CacheCleanupReadyOverlay
                call CacheDrawCity
                call CacheDrawWay
                call CacheRestoreTubes
                call CacheUpdateTubes
                call CacheUpdateBirdCoord
                call CacheCheckCollisions
                call CacheDrawTubes
                call CacheDrawBird
                call CacheDrawScore
                jp CacheFinishFrame

CacheRenderReady:
                call CacheRestoreBirdBackground
                call CacheRestoreFieldMedalBackground
                call CacheDrawCity
                call CacheDrawWay
                call CacheRestoreTubes
                call CacheRestoreReadyOverlay
                call CacheDrawTubes
                call CacheDrawBird
                call CacheDrawScore
                call CacheDrawGetReadyTitle
                call CacheDrawReadyCountdown
                call CacheUpdateReadyCounter
                jp CacheFinishFrame

CacheRenderGameOver:
                call CacheRestoreBirdBackground
                call CacheRestoreFieldMedalBackground
                call CacheDrawCity
                call CacheDrawWay
                call CacheRestoreTubes
                call CacheGameOverFall
                call CacheDrawTubes
                call CacheDrawBird
                call CacheDrawScore
                call CacheDrawGameOverTitle
                call CacheDrawGameOverPanel
CacheFinishFrame:
                ld a,1
                ld (Im2Handler.needChangePage),a
                ret

CacheRestoreBirdBackground:
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
                jp CacheRestoreRect

CacheUpdateBirdCoord:
                call CacheCheckSpace
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
                jp CacheSetGameOver

CacheGameOverFall:
                ld a,(BirdY)
                cp 208
                ret nc
                add a,4
                cp 208
                jr c,.store
                ld a,208
.store:         ld (BirdY),a
                ret

CacheCheckGameOverRestart:
                ld a,(GameOverRestartDelay)
                and a
                jr z,.canRestart
                dec a
                ld (GameOverRestartDelay),a
                call CacheCheckSpace
                ret z
                xor a
                ld (GameOverWaitRelease),a
                ret
.canRestart:
                call CacheCheckSpace
                jr z,.pressed
                xor a
                ld (GameOverWaitRelease),a
                ret
.pressed:       ld a,(GameOverWaitRelease)
                and a
                ret nz
                jp CacheRestartGame

CacheRestartGame:
                call CacheClearPlayfieldPages
                xor a
                ld (GemeOver),a
                ld (GameOverWaitRelease),a
                ld (GameOverRestartDelay),a
                ld (Score),a
                ld (Score+1),a
                ld (TubeYIndex),a
                ld (ReadyCleanupCounter),a
                ld (CacheUpdateBirdState.state),a
                ld (CacheUpdateBirdCoord.state),a
                ld (CacheDrawCity.pos),a
                ld (CacheDrawWay.pos),a
                ld a,6
                ld (CacheUpdateBirdCoord.count),a
                ld a,100
                ld (BirdY),a
                ld a,#ff
                ld (BirdFirstY),a
                ld (BirdSecondY),a
                ld (FieldMedalId),a
                ld (FieldMedalFirstY),a
                ld (FieldMedalSecondY),a
                xor a
                ld (FieldMedalAnim),a
                ld a,150
                ld (ReadyCounter),a
                xor a
                ld (CurrentBiome),a
                ld a,156
                ld (CurrentTubeInterval),a
                ld a,80
                ld (CurrentTubeGap),a
                ld (CacheDrawTubeGap),a
                ld a,r
                xor #5a
                or 1
                ld (RandomSeed),a
                ld hl,InitialTubes
                ld de,Tubes
                ld bc,TUBES_COUNT*TUBE_ENTRY_SIZE
                ldir
                xor a
                ld hl,Tubes0
                ld de,Tubes0+1
                ld bc,TUBES_COUNT*TUBE_ENTRY_SIZE-1
                ld (hl),a
                ldir
                ld hl,Tubes1
                ld de,Tubes1+1
                ld bc,TUBES_COUNT*TUBE_ENTRY_SIZE-1
                ld (hl),a
                ldir
                ret

CacheSetGameOver:
                ld a,(GemeOver)
                and a
                ret nz
                call SfxQueueHitDie
                ld a,1
                ld (GemeOver),a
                ld (GameOverWaitRelease),a
                ld a,75
                ld (GameOverRestartDelay),a
                ret

CacheUpdateReadyCounter:
                ld a,(ReadyCounter)
                and a
                ret z
                dec a
                ld (ReadyCounter),a
                ret nz
                ld a,2
                ld (ReadyCleanupCounter),a
                ret

CacheCleanupReadyOverlay:
                ld a,(ReadyCleanupCounter)
                and a
                ret z
                dec a
                ld (ReadyCleanupCounter),a
                jp CacheClearReadyOverlaySky

CacheResetRenderHistory:
                ld a,#ff
                ld (BirdFirstY),a
                ld (BirdSecondY),a
                xor a
                ld hl,Tubes0
                ld de,Tubes0+1
                ld bc,TUBES_COUNT*TUBE_ENTRY_SIZE-1
                ld (hl),a
                ldir
                ld hl,Tubes1
                ld de,Tubes1+1
                ld bc,TUBES_COUNT*TUBE_ENTRY_SIZE-1
                ld (hl),a
                ldir
                ret

CacheCheckCollisions:
                ld a,(BirdY)
                cp 208
                jp nc,CacheSetGameOver
                ld ix,Tubes
                ld b,TUBES_COUNT
                ld de,TUBE_ENTRY_SIZE
.loop:          push bc
                push de
                ld l,(ix+0)
                ld h,(ix+1)
                bit 7,h
                jr nz,.checkLeft
                push hl
                ld de,32
                and a
                sbc hl,de
                pop hl
                jr nc,.next
.checkLeft:     push hl
                ld de,TubeWidth
                add hl,de
                ld de,18
                and a
                sbc hl,de
                jr c,.offLeft
                ld a,h
                or l
                jr z,.offLeft
                pop hl
                ld a,(BirdY)
                add a,2
                ld c,a
                ld a,(ix+2)
                add a,TubeHeadHeight
                ld d,a
                ld a,c
                cp d
                jr c,.hit
                ld a,(BirdY)
                add a,10
                ld c,a
                ld a,(ix+2)
                ld d,a
                ld a,(ix+3)
                add a,d
                ld d,a
                ld a,c
                cp d
                jr nc,.hit
.next:          pop de
                pop bc
                add ix,de
                djnz .loop
                ret
.offLeft:       pop hl
                jr .next
.hit:           pop de
                pop bc
                jp CacheSetGameOver

CacheCheckSpace:
                ld a,127
                in a,(#FE)
                and 1
                ret

CacheUpdateBirdState:
                ld a,(GemeOver)
                and a
                ret nz
                in a,(RGMOD)
                and 1
                ret z
                ld a,0
.state:         equ $-1
                inc a
                cp 3
                jr c,.less
                xor a
.less:          ld (CacheUpdateBirdState.state),a
                ret

CacheUpdateCityPos:
                in a,(RGMOD)
                and 1
                ret z
                ld a,(CacheDrawCity.pos)
                inc a
                cp 138
                jr c,.less
                xor a
.less:          ld (CacheDrawCity.pos),a
                ret

CacheDrawBird:
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                ld a,#5C
                out (EmmWin.P1),a
                ld a,(MemoryBuffer.memBirds)
                out (EmmWin.P3),a
                ld hl,#c000
                ld bc,204
                ld a,(GemeOver)
                and a
                jr z,.normalState
                ld a,3
                jr .stateReady
.normalState:   ld a,(CacheUpdateBirdState.state)
.stateReady:
                and a
                jr z,.null
.addAdr:        add hl,bc
                dec a
                jr nz,.addAdr
.null:          push hl
                ld hl,#4000+16
                ld de,BirdFirstY
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld de,BirdSecondY
                ld hl,#4140+16
.firstpg:       ld b,12
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
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

CacheDrawCity:
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                ld a,#50
                out (EmmWin.P1),a
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
                ld hl,#c000
                ld a,0
.pos:           equ $-1
                ld c,a
                ld b,0
                add hl,bc
                ld b,39
                ld a,150
.loop:          push bc
                push af
                out (Y_PORT),a
                di
                ld de,0
.adr1:          equ $-2
                ld d,d
                ld a,138
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
                ; keep IRQs disabled while WIN1 is mapped to VRAM
                ld bc,276
                add hl,bc
                pop af
                pop bc
                inc a
                djnz .loop
                pop af
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

CacheUpdateWayPos:
                ld a,(CacheDrawWay.pos)
                inc a
                cp 12
                jr c,.less
                xor a
.less:          ld (CacheDrawWay.pos),a
                ret

CacheDrawWay:
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                ld a,#50
                out (EmmWin.P1),a
                ld a,(MemoryBuffer.memWay)
                out (EmmWin.P3),a
                ld hl,#4000
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld hl,#4140
.firstpg:       ld de,120
                ld (.adr1),hl
                add hl,de
                ld (.adr2),hl
                add hl,de
                ld (.adr3),hl
                ld hl,#c000
                ld a,0
.pos:           equ $-1
                ld c,a
                ld b,0
                add hl,bc
                ld b,11
                ld a,220
.loop:          push bc
                push af
                out (Y_PORT),a
                di
                ld de,0
.adr1:          equ $-2
                ld d,d
                ld a,120
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
                ; keep IRQs disabled while WIN1 is mapped to VRAM
                ld bc,140
                add hl,bc
                pop af
                pop bc
                inc a
                djnz .loop
                pop af
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

CacheDrawTubes:
                ld ix,Tubes
                ld iy,Tubes1
                in a,(RGMOD)
                and 1
                jr z,.firstpg
                ld iy,Tubes0
.firstpg:       ld b,TUBES_COUNT
                ld de,TUBE_ENTRY_SIZE
.loop:          ld l,(ix+0)
                ld h,(ix+1)
                ld (iy+0),l
                ld (iy+1),h
                ld a,(ix+2)
                ld (iy+2),a
                ld a,(ix+3)
                ld (iy+3),a
                ld (CacheDrawTubeGap),a
                ld a,(ix+2)
                call CacheDrawTube
                add ix,de
                add iy,de
                djnz .loop
                ret

CacheRestoreTubes:
                in a,(RGMOD)
                ld ix,Tubes1
                and 1
                jr z,.firstpg
                ld ix,Tubes0
.firstpg:       ld b,TUBES_COUNT
                ld de,TUBE_ENTRY_SIZE
.loop:          ld l,(ix+0)
                ld h,(ix+1)
                ld a,(ix+2)
                and a
                call nz,CacheRestoreTube
                add ix,de
                djnz .loop
                ret

CacheUpdateTubes:
                ld ix,Tubes
                ld b,TUBES_COUNT
                ld de,TUBE_ENTRY_SIZE
.loop:          call CacheUpdateTube
                add ix,de
                djnz .loop
                ret

CacheUpdateTube:
                push bc
                push de
                ld l,(ix+0)
                ld h,(ix+1)
                dec hl
                ld (ix+0),l
                ld (ix+1),h
                ld a,h
                cp #ff
                jr nz,.checkOffscreen
                ld a,l
                cp #f6
                call z,CacheAddScore
.checkOffscreen:
                bit 7,h
                jr z,.end
                ld de,TubeWidth
                and a
                add hl,de
                ld a,h
                or l
                jr z,.spawn
                bit 7,h
                jr z,.end
.spawn:
                call CacheSpawnTube
.end:           pop de
                pop bc
                ret

CacheAddScore:
                push af
                push hl
                ld hl,(Score)
                inc hl
                ld (Score),hl
                call CacheCheckMedalAward
                call CacheUpdateHighScore
                call CacheUpdateBiomeParams
                pop hl
                pop af
                ret

CacheCheckMedalAward:
                ld a,h
                and a
                ret nz
                ld a,l
                cp 10
                jr z,.bronze
                cp 25
                jr z,.silver
                cp 50
                jr z,.gold
                cp 100
                ret nz
.platinum:      ld a,3
                jr CacheStartFieldMedalAward
.gold:          ld a,2
                jr CacheStartFieldMedalAward
.silver:        ld a,1
                jr CacheStartFieldMedalAward
.bronze:        xor a

CacheStartFieldMedalAward:
                ld (FieldMedalId),a
                ld a,1
                ld (FieldMedalAnim),a
                ret

CacheUpdateHighScore:
                push af
                push de
                push hl
                ld hl,(Score)
                ld de,(HighScore)
                ld a,h
                cp d
                jr c,.end
                jr nz,.store
                ld a,l
                cp e
                jr c,.end
                jr z,.end
.store:         ld (HighScore),hl
.end:           pop hl
                pop de
                pop af
                ret

CacheUpdateBiomeParams:
                push af
                push hl
                ld hl,(Score)
                ld a,h
                and a
                jr nz,.villageNight
                ld a,l
                cp 10
                jr c,.cityDay
                cp 25
                jr c,.cityEvening
                cp 50
                jr c,.cityNight
                cp 80
                jr c,.villageDay
.villageNight:  ld a,BIOME_VILLAGE_NIGHT
                ld (CurrentBiome),a
                ld a,104
                ld (CurrentTubeInterval),a
                ld a,64
                jr .setGap
.villageDay:    ld a,BIOME_VILLAGE_DAY
                ld (CurrentBiome),a
                ld a,116
                ld (CurrentTubeInterval),a
                ld a,68
                jr .setGap
.cityNight:     ld a,BIOME_CITY_NIGHT
                ld (CurrentBiome),a
                ld a,132
                ld (CurrentTubeInterval),a
                ld a,72
                jr .setGap
.cityEvening:   ld a,BIOME_CITY_EVENING
                ld (CurrentBiome),a
                ld a,148
                ld (CurrentTubeInterval),a
                ld a,76
                jr .setGap
.cityDay:       ld a,BIOME_CITY_DAY
                ld (CurrentBiome),a
                ld a,156
                ld (CurrentTubeInterval),a
                ld a,80
.setGap:        ld (CurrentTubeGap),a
                pop hl
                pop af
                ret

CacheSpawnTube:
                push ix
                call CacheFindRightmostTube
                ld b,c
                push hl
                call CacheSelectTubeY
                ld c,a
                call CacheGetSpawnDistance
                pop hl
                add hl,de
                pop ix
                ld (ix+0),l
                ld (ix+1),h
                ld (ix+2),c
                ld a,(CurrentTubeGap)
                ld (ix+3),a
                ret

CacheFindRightmostTube:
                ld hl,319
                ld c,70
                ld ix,Tubes
                ld b,TUBES_COUNT
                ld de,TUBE_ENTRY_SIZE
.loop:          push de
                ld e,(ix+0)
                ld d,(ix+1)
                bit 7,d
                jr nz,.next
                push hl
                push de
                ex de,hl
                and a
                sbc hl,de
                pop de
                pop hl
                jr c,.next
                jr z,.next
                ex de,hl
                ld c,(ix+2)
.next:          pop de
                add ix,de
                djnz .loop
                ret

CacheGetSpawnDistance:
                push af
                ld a,c
                sub b
                jr nc,.absReady
                neg
.absReady:      cp 64
                jr nc,.extra24
                cp 48
                jr nc,.extra16
                cp 32
                jr nc,.extra8
                ld b,0
                jr .addBase
.extra8:        ld b,8
                jr .addBase
.extra16:       ld b,16
                jr .addBase
.extra24:       ld b,24
.addBase:       call CacheGetIntervalJitter
                add a,b
                cp 177
                jr c,.store
                ld a,176
.store:
                ld e,a
                ld d,0
                pop af
                ret

CacheGetIntervalJitter:
                call CacheRandom
                and 3
                ld e,a
                ld d,0
                ld a,(CurrentBiome)
                cp BIOME_CITY_EVENING
                jr z,.cityEvening
                cp BIOME_CITY_NIGHT
                jr z,.cityNight
                cp BIOME_VILLAGE_DAY
                jr z,.villageDay
                cp BIOME_VILLAGE_NIGHT
                jr z,.villageNight
                ld hl,TubeIntervalCityDay
                jr .pick
.cityEvening:   ld hl,TubeIntervalCityEvening
                jr .pick
.cityNight:     ld hl,TubeIntervalCityNight
                jr .pick
.villageDay:    ld hl,TubeIntervalVillageDay
                jr .pick
.villageNight:  ld hl,TubeIntervalVillageNight
.pick:          add hl,de
                ld a,(hl)
                ret

CacheSelectTubeY:
                push bc
                call CacheRandom
                and 7
                ld (TubeYIndex),a
                ld c,a
                call CacheSelectTubeYByIndex
                ld c,a
                ld a,c
                sub b
                jr nc,.absReady
                neg
.absReady:      cp 24
                jr nc,.useSelected
                ld a,(TubeYIndex)
                add a,4
                and 7
                ld (TubeYIndex),a
                call CacheSelectTubeYByIndex
.useSelected:   pop bc
                ret

CacheSelectTubeYByIndex:
                ld a,(TubeYIndex)
                ld e,a
                ld d,0
                ld a,(CurrentBiome)
                cp BIOME_CITY_EVENING
                jr z,.cityEvening
                cp BIOME_CITY_NIGHT
                jr z,.cityNight
                cp BIOME_VILLAGE_DAY
                jr z,.villageDay
                cp BIOME_VILLAGE_NIGHT
                jr z,.villageNight
                ld hl,TubeYCityDay
                jr .pick
.cityEvening:   ld hl,TubeYCityEvening
                jr .pick
.cityNight:     ld hl,TubeYCityNight
                jr .pick
.villageDay:    ld hl,TubeYVillageDay
                jr .pick
.villageNight:  ld hl,TubeYVillageNight
.pick:          add hl,de
                ld a,(hl)
                ret

CacheRandom:
                push bc
                ld a,r
                ld b,a
                ld a,(RandomSeed)
                rrca
                jr nc,.mix
                xor #b8
.mix:           xor b
                jr nz,.store
                ld a,#a7
.store:         ld (RandomSeed),a
                pop bc
                ret

CacheRestoreTube:
                push bc
                push de
                in a,(EmmWin.P3)
                push af
                ld a,#50
                out (EmmWin.P3),a
                push hl
                bit 7,h
                jr z,.notLeftClipped
                pop de
                and a
                ld hl,TubeWidth
                add hl,de
                ld a,h
                or l
                jp z,.exit
                bit 7,h
                jp nz,.exit
                ld b,l
                ld hl,0
                jr .restore
.notLeftClipped:
                pop hl
                ld de,TubeWidth-TubeWidthRestored
                add hl,de
                push hl
.positive:      ld bc,320
                push hl
                and a
                sbc hl,bc
                pop hl
                jr nc,.skip
                ld bc,TubeWidthRestored
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
                sbc hl,bc
                jr .sizeSet
.full:          pop hl
.sizeSet:       ld b,l
                ld a,b
                and a
                jp z,.skipRestoreVisible
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
.exit:          pop af
                out (EmmWin.P3),a
                pop de
                pop bc
                ret
.skip:          pop de
                jp .exit
.skipRestoreVisible:
                pop hl
                jp .exit

CacheDrawTube:
                push bc
                push de
                ex af,af'
                in a,(EmmWin.P3)
                push af
                ld a,(MemoryBuffer.memTubes)
                out (EmmWin.P3),a
                ld a,#5c
                out (EmmWin.P1),a
                push hl
                bit 7,h
                jr z,.positive
                pop de
                push de
                and a
                ld hl,TubeWidth
                add hl,de
                ld a,h
                or l
                jp z,.skipNegative
                bit 7,h
                jp nz,.skipNegative
                ld a,l
                ld (CacheDrawTubeHead.len),a
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
                ld a,(CacheDrawTubeHead.len)
                ld c,a
                xor a
                call CacheDrawTubeBody
                pop af
                pop de
                pop hl
                push hl
                push de
                push af
                ld bc,RedTubeDn
                add hl,bc
                call CacheDrawTubeHead
                pop af
                pop de
                pop hl
                ld b,a
                ld a,(CacheDrawTubeGap)
                add a,b
                ld bc,RedTubeUp
                add hl,bc
                push de
                push af
                call CacheDrawTubeHead
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
                call CacheDrawTubeBody
                jr .exit
.positive:      ld de,320
                push hl
                and a
                sbc hl,de
                pop hl
                jr c,.visible
                pop hl
                jr .exit
.visible:       ld bc,TubeWidth
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
                sbc hl,bc
                jr .sizeSet
.full:          pop hl
.sizeSet:       ld a,l
                and a
                jr z,.skipVisible
                ld (CacheDrawTubeHead.len),a
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
                call CacheDrawTubeHead
                pop af
                ld b,a
                ld a,(CacheDrawTubeHead.len)
                ld c,a
                xor a
                ld hl,RedTubeMiddle
                pop de
                push bc
                call CacheDrawTubeBody
                pop bc
                pop de
                pop af
                push de
                push af
                ld b,a
                ld a,(CacheDrawTubeGap)
                add a,b
                add a,TubeHeadHeight
                push af
                ld b,a
                ld a,220
                sub b
                ld b,a
                pop af
                ld hl,RedTubeMiddle
                call CacheDrawTubeBody
                pop af
                pop de
                ld b,a
                ld a,(CacheDrawTubeGap)
                add a,b
                ld hl,RedTubeUp
                call CacheDrawTubeHead
.exit:          pop af
                out (EmmWin.P3),a
                pop de
                pop bc
                ret
.skipVisible:   pop hl
                jr .exit
.skipNegative:  pop de
                jr .exit

CacheDrawTubeBody:
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
                ret

CacheDrawTubeHead:
                ex af,af'
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

CacheDrawScore:
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                call CacheClearScoreRect
                call CacheClearHighScoreRect
                ld a,#5c
                out (EmmWin.P1),a
                ld a,(MemoryBuffer.memUi)
                out (EmmWin.P3),a
                ld hl,(Score)
                ld (CacheScoreValue),hl
                ld hl,FIELD_SCORE_X
                ld (CacheScoreX),hl
                ld a,239
                ld (CacheScoreY),a
                xor a
                ld (CacheScorePrinted),a
                ld (CacheScoreForceDraw),a
                ld de,10000
                call CacheDrawScorePlace
                ld de,1000
                call CacheDrawScorePlace
                ld de,100
                call CacheDrawScorePlace
                ld de,10
                call CacheDrawScorePlace
                ld a,1
                ld (CacheScoreForceDraw),a
                ld de,1
                call CacheDrawScorePlace
                call CacheDrawFieldMedal
                ld hl,(HighScore)
                ld (CacheScoreValue),hl
                call CacheSetFieldHighScoreX
                ld a,239
                ld (CacheScoreY),a
                xor a
                ld (CacheScorePrinted),a
                ld (CacheScoreForceDraw),a
                ld de,10000
                call CacheDrawScorePlace
                ld de,1000
                call CacheDrawScorePlace
                ld de,100
                call CacheDrawScorePlace
                ld de,10
                call CacheDrawScorePlace
                ld a,1
                ld (CacheScoreForceDraw),a
                ld de,1
                call CacheDrawScorePlace
                call CacheDrawFlappyBirdFooter
                pop af
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

CacheClearScoreRect:
                ld a,#50
                out (EmmWin.P1),a
                ld hl,#4000+4
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld hl,#4140+4
.firstpg:       ld e,237
                ld b,12
.rowLoop:       ld a,e
                out (Y_PORT),a
                inc e
                di
                ld d,d
                ld a,72
                ld c,c
                ld a,2
                ld (hl),a
                ld b,b
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
                ret

CacheClearHighScoreRect:
                ld a,#50
                out (EmmWin.P1),a
                ld hl,#4000+272
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld hl,#4140+272
.firstpg:       ld e,237
                ld b,12
.rowLoop:       ld a,e
                out (Y_PORT),a
                inc e
                di
                ld d,d
                ld a,40
                ld c,c
                ld a,2
                ld (hl),a
                ld b,b
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
                ret

CacheRestoreFieldMedalBackground:
                in a,(RGMOD)
                ld de,FieldMedalFirstY
                and 1
                jr nz,.first
                ld de,FieldMedalSecondY
.first:         ld a,(de)
                cp #ff
                ret z
                ld hl,#c000+FIELD_MEDAL_X
                ld bc,#1818
                jp CacheRestoreRect

CacheDrawFieldMedal:
                ld a,(FieldMedalId)
                cp #ff
                jr z,.placeholder
                call CacheUpdateFieldMedalAnimation
                ld (FieldMedalCurrentY),a
                jr .draw
.placeholder:   ld a,FIELD_MEDAL_TARGET_Y
                ld (FieldMedalCurrentY),a
.draw:
                in a,(RGMOD)
                ld hl,FieldMedalFirstY
                and 1
                jr nz,.first
                ld hl,FieldMedalSecondY
.first:         ld a,(FieldMedalCurrentY)
                ld (hl),a
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                ld a,#5c
                out (EmmWin.P1),a
                ld a,(MemoryBuffer.memUi)
                out (EmmWin.P3),a
                ld a,(FieldMedalId)
                cp #ff
                jr z,.placeholderSource
                ld hl,UiCoins
                and a
                jr z,.sourceReady
                ld bc,24*24
.sourceLoop:    add hl,bc
                dec a
                jr nz,.sourceLoop
                jr .sourceReady
.placeholderSource:
                ld hl,UiMedalPlaceholder
.sourceReady:   ld de,#4000+FIELD_MEDAL_X
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld de,#4140+FIELD_MEDAL_X
.firstpg:       ld b,24
                ld a,(FieldMedalCurrentY)
.rowLoop:       out (Y_PORT),a
                inc a
                push af
                push bc
                push de
                push hl
                di
                ld d,d
                ld a,24
                ld l,l
                ld a,(hl)
                ld (de),a
                ld b,b
                pop hl
                ld bc,24
                add hl,bc
                pop de
                pop bc
                pop af
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
                pop af
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

CacheUpdateFieldMedalAnimation:
                ld a,(FieldMedalAnim)
                and a
                jr z,.static
                cp 9
                jr nz,.soundDone
                push af
                call SfxQueuePoint
                pop af
.soundDone:
                push af
                ld c,a
                ld b,0
                dec bc
                ld hl,FieldMedalYTable
                add hl,bc
                ld a,(hl)
                ld (FieldMedalCurrentY),a
                pop af
                inc a
                cp 13
                jr c,.store
                xor a
.store:         ld (FieldMedalAnim),a
                ld a,(FieldMedalCurrentY)
                ret
.static:        ld a,FIELD_MEDAL_TARGET_Y
                ret

FieldMedalYTable:
                db FIELD_MEDAL_TARGET_Y-32
                db FIELD_MEDAL_TARGET_Y-28
                db FIELD_MEDAL_TARGET_Y-24
                db FIELD_MEDAL_TARGET_Y-20
                db FIELD_MEDAL_TARGET_Y-16
                db FIELD_MEDAL_TARGET_Y-12
                db FIELD_MEDAL_TARGET_Y-8
                db FIELD_MEDAL_TARGET_Y-4
                db FIELD_MEDAL_TARGET_Y
                db FIELD_MEDAL_TARGET_Y-6
                db FIELD_MEDAL_TARGET_Y-2
                db FIELD_MEDAL_TARGET_Y

CacheSetFieldHighScoreX:
                ld bc,304
                push hl
                ld de,10
                and a
                sbc hl,de
                pop hl
                jr c,.store
                ld bc,296
                push hl
                ld de,100
                and a
                sbc hl,de
                pop hl
                jr c,.store
                ld bc,288
                push hl
                ld de,1000
                and a
                sbc hl,de
                pop hl
                jr c,.store
                ld bc,280
                push hl
                ld de,10000
                and a
                sbc hl,de
                pop hl
                jr c,.store
                ld bc,272
.store:         ld (CacheScoreX),bc
                ret

CacheDrawScorePlace:
                ld c,0
                ld hl,(CacheScoreValue)
.subLoop:       and a
                sbc hl,de
                jr c,.subDone
                inc c
                jr .subLoop
.subDone:       add hl,de
                ld (CacheScoreValue),hl
                ld a,(CacheScorePrinted)
                or c
                jr nz,.draw
                ld a,(CacheScoreForceDraw)
                and a
                ret z
.draw:          ld a,1
                ld (CacheScorePrinted),a
                ld a,c
                call CacheDrawSmallDigit
                ret

CacheDrawSmallDigit:
                ld (CacheScoreDigit),a
                ld hl,(CacheScoreX)
                in a,(RGMOD)
                and 1
                ld de,#4000
                jr nz,.firstpg
                ld de,#4140
.firstpg:       add hl,de
                ex de,hl
                ld a,(CacheScoreDigit)
                ld hl,UiSmallDigits
                and a
                jr z,.sourceReady
                ld bc,80
.sourceLoop:    add hl,bc
                dec a
                jr nz,.sourceLoop
.sourceReady:   ld a,(CacheScoreY)
                call CacheDrawSmallDigitSprite
                ld hl,(CacheScoreX)
                ld de,8
                add hl,de
                ld (CacheScoreX),hl
                ret

CacheDrawSmallDigitSprite:
                ld (.y),a
                ld b,10
.rowLoop:       ld a,0
.y:             equ $-1
                out (Y_PORT),a
                inc a
                ld (.y),a
                push bc
                push de
                ld c,8
.colLoop:       ld a,(hl)
                cp 255
                jr z,.skipPixel
                ld (de),a
.skipPixel:     inc hl
                inc de
                dec c
                jr nz,.colLoop
                pop de
                pop bc
                djnz .rowLoop
                ret

CacheDrawReadyCountdown:
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                ld a,#5c
                out (EmmWin.P1),a
                ld a,(MemoryBuffer.memUi)
                out (EmmWin.P3),a
                call CacheGetReadyDigit
                ld hl,UiBigDigits
                and a
                jr z,.sourceReady
                ld bc,320
.sourceLoop:    add hl,bc
                dec a
                jr nz,.sourceLoop
.sourceReady:   ld de,#4000+152
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld de,#4140+152
.firstpg:       ld a,144
                call CacheDrawBigDigitSprite
                pop af
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

CacheGetReadyDigit:
                ld a,(ReadyCounter)
                cp 113
                jr nc,.three
                cp 76
                jr nc,.two
                cp 39
                jr nc,.one
                xor a
                ret
.one:           ld a,1
                ret
.two:           ld a,2
                ret
.three:         ld a,3
                ret

CacheDrawBigDigitSprite:
                ld (.y),a
                ld b,20
.rowLoop:       ld a,0
.y:             equ $-1
                out (Y_PORT),a
                inc a
                ld (.y),a
                push bc
                push de
                push hl
                di
                ld d,d
                ld a,16
                ld l,l
                ld a,(hl)
                ld (de),a
                ld b,b
                pop hl
                ld bc,16
                add hl,bc
                pop de
                pop bc
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
                ret

CacheDrawGetReadyTitle:
                ld hl,UiGetReady
                ld a,112
                jr CacheDrawTitle

CacheDrawGameOverTitle:
                ld hl,UiGameOver
                ld a,80
CacheDrawTitle:
                ld (.titleY),a
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                ld a,#5c
                out (EmmWin.P1),a
                ld a,(MemoryBuffer.memUi)
                out (EmmWin.P3),a
                ld de,#4000+112
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld de,#4140+112
.firstpg:       ld b,25
                ld a,0
.titleY:        equ $-1
.rowLoop:       out (Y_PORT),a
                inc a
                push af
                push bc
                push de
                di
                ld d,d
                ld a,96
                ld l,l
                ld a,(hl)
                ld (de),a
                ld b,b
                pop de
                ld bc,96
                add hl,bc
                pop bc
                pop af
                djnz .rowLoop
                pop af
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

CacheDrawFlappyBirdFooter:
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                ld a,#5c
                out (EmmWin.P1),a
                ld a,(MemoryBuffer.memUi)
                out (EmmWin.P3),a
                ld hl,UiFlappyBird
                ld de,#4000+112
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld de,#4140+112
.firstpg:       ld b,25
                ld a,231
.rowLoop:       out (Y_PORT),a
                inc a
                push af
                push bc
                push de
                di
                ld d,d
                ld a,96
                ld l,l
                ld a,(hl)
                ld (de),a
                ld b,b
                pop de
                ld bc,96
                add hl,bc
                pop bc
                pop af
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
                pop af
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

CacheDrawGameOverPanel:
                call CacheDrawGameOverPanelFrame
                call CacheDrawGameOverMedal
                call CacheDrawGameOverNumbers
                ret

CacheDrawGameOverPanelFrame:
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                ld a,#5c
                out (EmmWin.P1),a
                ld a,(MemoryBuffer.memGameOverPanel)
                out (EmmWin.P3),a
                ld hl,GameOverPanel
                ld de,#4000+104
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld de,#4140+104
.firstpg:       ld b,57
                ld a,112
.rowLoop:       out (Y_PORT),a
                inc a
                push af
                push bc
                push de
                di
                ld d,d
                ld a,113
                ld l,l
                ld a,(hl)
                ld (de),a
                ld b,b
                pop de
                ld bc,113
                add hl,bc
                pop bc
                pop af
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
                pop af
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

CacheDrawGameOverMedal:
                call CacheSelectMedal
                cp #ff
                ret z
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                ld a,#5c
                out (EmmWin.P1),a
                ld a,(MemoryBuffer.memUi)
                out (EmmWin.P3),a
                call CacheSelectMedal
                ld hl,UiCoins
                and a
                jr z,.sourceReady
                ld bc,24*24
.sourceLoop:    add hl,bc
                dec a
                jr nz,.sourceLoop
.sourceReady:   ld de,#4000+116
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld de,#4140+116
.firstpg:       ld b,24
                ld a,132
.rowLoop:       out (Y_PORT),a
                inc a
                push af
                push bc
                push de
                push hl
                di
                ld d,d
                ld a,24
                ld l,l
                ld a,(hl)
                ld (de),a
                ld b,b
                pop hl
                ld bc,24
                add hl,bc
                pop de
                pop bc
                pop af
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
                pop af
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

CacheSelectMedal:
                ld hl,(Score)
                ld a,h
                and a
                jr nz,.platinum
                ld a,l
                cp 100
                jr nc,.platinum
                cp 50
                jr nc,.gold
                cp 25
                jr nc,.silver
                cp 10
                jr nc,.bronze
                ld a,#ff
                ret
.bronze:        xor a
                ret
.silver:        ld a,1
                ret
.gold:          ld a,2
                ret
.platinum:      ld a,3
                ret

CacheDrawGameOverNumbers:
                in a,(EmmWin.P1)
                push af
                in a,(EmmWin.P3)
                push af
                ld a,#5c
                out (EmmWin.P1),a
                ld a,(MemoryBuffer.memUi)
                out (EmmWin.P3),a
                ld hl,(Score)
                ld (CacheScoreValue),hl
                call CacheSetPanelScoreX
                ld a,130
                ld (CacheScoreY),a
                xor a
                ld (CacheScorePrinted),a
                ld (CacheScoreForceDraw),a
                ld de,10000
                call CacheDrawScorePlace
                ld de,1000
                call CacheDrawScorePlace
                ld de,100
                call CacheDrawScorePlace
                ld de,10
                call CacheDrawScorePlace
                ld a,1
                ld (CacheScoreForceDraw),a
                ld de,1
                call CacheDrawScorePlace
                ld hl,(HighScore)
                ld (CacheScoreValue),hl
                call CacheSetPanelScoreX
                ld a,151
                ld (CacheScoreY),a
                xor a
                ld (CacheScorePrinted),a
                ld (CacheScoreForceDraw),a
                ld de,10000
                call CacheDrawScorePlace
                ld de,1000
                call CacheDrawScorePlace
                ld de,100
                call CacheDrawScorePlace
                ld de,10
                call CacheDrawScorePlace
                ld a,1
                ld (CacheScoreForceDraw),a
                ld de,1
                call CacheDrawScorePlace
                pop af
                out (EmmWin.P3),a
                pop af
                out (EmmWin.P1),a
                ret

CacheSetPanelScoreX:
                ld bc,200
                push hl
                ld de,10
                and a
                sbc hl,de
                pop hl
                jr c,.store
                ld bc,192
                push hl
                ld de,100
                and a
                sbc hl,de
                pop hl
                jr c,.store
                ld bc,184
                push hl
                ld de,1000
                and a
                sbc hl,de
                pop hl
                jr c,.store
                ld bc,176
                push hl
                ld de,10000
                and a
                sbc hl,de
                pop hl
                jr c,.store
                ld bc,168
.store:         ld (CacheScoreX),bc
                ret

CacheRestoreReadyOverlay:
                in a,(EmmWin.P3)
                push af
                ld a,#50
                out (EmmWin.P3),a
                ld hl,#c000+112
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld hl,#c140+112
.firstpg:       ld a,112
                ld b,25
                ld c,96
                call CacheRestoreOverlayRect
                ld de,40
                add hl,de
                ld a,144
                ld b,20
                ld c,16
                call CacheRestoreOverlayRect
                pop af
                out (EmmWin.P3),a
                ret

CacheClearReadyOverlaySky:
                in a,(EmmWin.P1)
                push af
                ld a,#50
                out (EmmWin.P1),a
                in a,(RGMOD)
                ld hl,#4000+112
                and 1
                jr nz,.firstTitle
                ld hl,#4140+112
.firstTitle:    ld a,112
                ld b,25
                ld c,0
                ld e,96
                call CacheClearSkyRect
                in a,(RGMOD)
                ld hl,#4000+152
                and 1
                jr nz,.firstDigit
                ld hl,#4140+152
.firstDigit:    ld a,144
                ld b,20
                ld c,0
                ld e,16
                call CacheClearSkyRect
                pop af
                out (EmmWin.P1),a
                ret

CacheClearSkyRect:
                ex af,af'
                ld a,e
                ld (.width),a
                ex af,af'
.rowLoop:       out (Y_PORT),a
                inc a
                push af
                push bc
                push de
                push hl
                di
                ld d,d
                ld a,0
.width:         equ $-1
                ld c,c
                ld a,c
                ld (hl),a
                ld b,b
                pop hl
                pop de
                pop bc
                pop af
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
                ret

CacheRestoreTitlePages:
                in a,(EmmWin.P3)
                push af
                ld a,#50
                out (EmmWin.P3),a
                ld hl,#c000+112
                call .restorePage
                ld hl,#c140+112
                call .restorePage
                ld hl,#c000+152
                call .restoreDigit
                ld hl,#c140+152
                call .restoreDigit
                pop af
                out (EmmWin.P3),a
                ret
.restorePage:   ld b,25
                ld c,96
                ld a,112
.restoreRect:   jp CacheRestoreOverlayRect
.restoreDigit:  ld b,20
                ld c,16
                ld a,144
                jr .restoreRect

CacheRestoreOverlayRect:
.rowLoop:       out (Y_PORT),a
                inc a
                push af
                push bc
                push hl
                di
                ld d,d
                ld a,c
                ld l,l
                ld c,(hl)
                ld (hl),c
                ld b,b
                pop hl
                pop bc
                pop af
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
                ret

CacheClearPlayfieldPages:
                in a,(EmmWin.P1)
                push af
                ld a,#50
                out (EmmWin.P1),a
                ld hl,#4000
                call .clearPage
                ld hl,#4140
                call .clearPage
                pop af
                out (EmmWin.P1),a
                ret
.clearPage:     push hl
                ld b,150
                ld c,0
                ld e,0
                call .clearRows
                pop hl
                push hl
                ld b,70
                ld c,1
                ld e,150
                call .clearRows
                pop hl
                ld b,36
                ld c,2
                ld e,220
.clearRows:
.rowLoop:       ld a,e
                out (Y_PORT),a
                inc e
                push de
                push bc
                push hl
                di
                ld d,d
                ld a,120
                ld c,c
                ld a,c
                ld (hl),a
                ld b,b
                ld de,120
                add hl,de
                ld d,d
                ld a,120
                ld c,c
                ld a,c
                ld (hl),a
                ld b,b
                ld de,120
                add hl,de
                ld d,d
                ld a,80
                ld c,c
                ld a,c
                ld (hl),a
                ld b,b
                pop hl
                pop bc
                pop de
                djnz .rowLoop
                ld a,#c0
                out (Y_PORT),a
                ret

CacheRestoreRect:
                ex af,af'
                in a,(EmmWin.P3)
                push af
                ld a,#50
                out (EmmWin.P3),a
                in a,(RGMOD)
                and 1
                jr nz,.firstpg
                ld de,#0140
                add hl,de
.firstpg:       ld a,c
                ld (.hgt),a
                di
                ex af,af'
.loop:          out (Y_PORT),a
                inc a
                ld d,d
                ld c,0
.hgt:           equ $-1
                ld l,l
                ld c,(hl)
                ld (hl),c
                ld b,b
                djnz .loop
                pop af
                out (EmmWin.P3),a
                ret

CacheRenderCodeEnd:
                ASSERT CacheRenderCodeEnd <= #4000

                ENT
