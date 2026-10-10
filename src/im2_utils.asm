;Установка IM2 и нового вектора прерываний
;DE - обработчик прерываний
set_im2:
        ld      a,i
        ld      (set_im1.save_i),a
        di
        push    de
        ld      hl,#8000
        ld      de,#8001
        ld      bc,256
        ld      (hl),#81
        ldir
        ld      a,#C3
        ld      (Im2DefaultVector),a
        ld      hl,Im2EmptyHandler
        ld      (Im2DefaultVector+1),hl
        ld      a,#80
        ld      i,a
        im      2
        ; Sync the frame timer to VSync: wake on vector #FF (VSync, or a PS/2 byte). During
        ; the sync every vector still runs Im2EmptyHandler, which leaves the SIO byte in
        ; place, so a pending byte here means the wake-up was the keyboard, not VSync:
        ; drain it and wait again. SfxCblIrqHandler (which drains SIO itself) goes on #FF
        ; only after the sync, as the SDK installs its key handler (lib_startup.asm).
.sync:  ei
        halt
        di
        in      a,(SIO_CONTROL_A)
        bit     0,a
        jr      z,.synced
        call    KeysHandler
        jr      .sync
.synced:
        ld      hl,SfxCblIrqHandler
        ld      (#80ff),hl
        pop     hl
        ld      (#8006),hl
        call    StartFrameTimer
        ld      hl,Im2OtherHandler
        ld      (Im2DefaultVector+1),hl
        ld      a,1
        ld      (Im2Active),a           ; WaitFrame (grx_utils.asm): a real frame tick
        ei                              ; (CTC/WaitVsync) now exists, a bare halt no longer does
        ret
;Восстановление режима IM1 и предыдущего значения вектора прерываний
set_im1:
        di
        call    StopFrameTimer
        xor     a
        ld      (Im2Active),a
        ld      a,0
.save_i: equ    $-1
        ld      i,a
        im      1
        ei
        ret

Im2Active:      db      0

StartFrameTimer:
        ld      a,#57
        out     (CTC_CH2),a
        ld      a,112
        out     (CTC_CH2),a
        ld      a,#D7
        out     (CTC_CH3),a
        ld      a,160
        out     (CTC_CH3),a
        xor     a
        out     (CTC_CH0),a
        ret

StopFrameTimer:
        ld      a,#03
        out     (CTC_CH2),a
        out     (CTC_CH3),a
        ret

Im2EmptyHandler:
        ei
        reti

; Catch-all for every other IM2 vector (CTC channels not wired to a dedicated handler,
; and any vector fetch landing elsewhere in the #8000 table). Its ack may have swallowed
; a keyboard or CBL request too (see Im2Handler), so it serves both. Never touches
; Y_PORT, WIN1 or VRAM.
Im2OtherHandler:
        di
        push    af
        push    bc
        push    de
        push    hl
        call    SfxHandleCblInterrupt
        call    KeysHandler
        pop     hl
        pop     de
        pop     bc
        pop     af
        ei
        reti
