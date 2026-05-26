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
                ei
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
                ei
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
                ld de,3
.loop:          ld l,(ix+0)
                ld h,(ix+1)
                ld (iy+0),l
                ld (iy+1),h
                ld a,(ix+2)
                ld (iy+2),a
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
                ld de,3
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
                ld de,3
.loop:          call CacheUpdateTube
                add ix,de
                djnz .loop
                ret

CacheUpdateTube:
                push de
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

CacheRestoreTube:
                push bc
                push de
                ld de,TubeWidth-TubeWidthRestored
                add hl,de
                in a,(EmmWin.P3)
                push af
                ld a,#50
                out (EmmWin.P3),a
                push hl
                ld a,h
                and 254
                jr z,.positive
                pop de
                and a
                ld hl,TubeWidthRestored
                add hl,de
                ld b,l
                ld hl,0
                jr .restore
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
                ei
                ret
.skip:          pop de
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
                ld a,h
                and 254
                jr z,.positive
                pop de
                push de
                and a
                ld hl,TubeWidth
                add hl,de
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
                sbc hl,bc
                jr .sizeSet
.full:          pop hl
.sizeSet:       ld a,l
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
                ei
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
                ei
                ret

CacheRenderCodeEnd:
                ASSERT CacheRenderCodeEnd <= #4000

                ENT
