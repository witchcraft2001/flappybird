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
        ld      hl,SfxCblIrqHandler
        ld      (#80ff),hl
        ld      a,#80
        ld      i,a
        im      2
.sync:  ei
        halt
        di
        in      a,(SIO_CONTROL_A)
        bit     0,a
        jr      z,.synced
        call    KeysHandler
        jr      .sync
.synced:
        pop     hl
        ld      (#8006),hl
        call    StartFrameTimer
        ld      hl,Im2OtherHandler
        ld      (Im2DefaultVector+1),hl
        ei
        ret
;Восстановление режима IM1 и предыдущего значения вектора прерываний
set_im1:
        di
        call    StopFrameTimer
        ld      a,0
.save_i: equ    $-1
        ld      i,a
        im      1
        ei
        ret

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

Im2OtherHandler:
        di
        push    af
        push    bc
        push    de
        push    hl
        call    KeysHandler
        pop     hl
        pop     de
        pop     bc
        pop     af
        ei
        reti
