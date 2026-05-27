                DISP CACHE_RENDER_BASE

CacheRenderFrame:
                call CacheUpdateBirdState
                call CacheUpdateCityPos
                call CacheUpdateWayPos
                call CacheRestoreBirdBackground
                call CacheDrawCity
                call CacheDrawWay
                call CacheRestoreTubes
                call CacheUpdateTubes
                call CacheDrawTubes
                call CacheDrawBird
                ld a,1
                ld (Im2Handler.needChangePage),a
                call CacheUpdateBirdCoord
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
                inc a
                ld (GemeOver),a
                ret

CacheCheckSpace:
                ld a,127
                in a,(#FE)
                and 1
                ret

CacheUpdateBirdState:
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
                ld a,(CacheUpdateBirdState.state)
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
                call CacheUpdateBiomeParams
                pop hl
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
                ld a,96
                ld (CurrentTubeInterval),a
                ld a,64
                jr .setGap
.villageDay:    ld a,BIOME_VILLAGE_DAY
                ld (CurrentBiome),a
                ld a,104
                ld (CurrentTubeInterval),a
                ld a,68
                jr .setGap
.cityNight:     ld a,BIOME_CITY_NIGHT
                ld (CurrentBiome),a
                ld a,112
                ld (CurrentTubeInterval),a
                ld a,72
                jr .setGap
.cityEvening:   ld a,BIOME_CITY_EVENING
                ld (CurrentBiome),a
                ld a,120
                ld (CurrentTubeInterval),a
                ld a,76
                jr .setGap
.cityDay:       ld a,BIOME_CITY_DAY
                ld (CurrentBiome),a
                ld a,128
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
                ld a,(TubeYIndex)
                inc a
                and 7
                ld (TubeYIndex),a
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
                ld a,(RandomSeed)
                rrca
                jr nc,.store
                xor #b8
.store:         ld (RandomSeed),a
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
                add a,80
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
                add a,80+TubeHeadHeight
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
                add a,80
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
