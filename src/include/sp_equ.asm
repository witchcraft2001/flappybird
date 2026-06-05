EmmWin.P0	EQU	#82
EmmWin.P1	EQU	#A2
EmmWin.P2	EQU	#C2
EmmWin.P3	EQU	#E2
Y_PORT          EQU     #89
RGADR           EQU     Y_PORT
RGMOD           EQU     #C9
SIO_CONTROL_A   EQU     #19
SIO_DATA_REG_A  EQU     #18
CTC_CH0         EQU     #10
CTC_CH1         EQU     #11
CTC_CH2         EQU     #12
CTC_CH3         EQU     #13

CACHE_ON_PORT   EQU     #FB
CACHE_OFF_PORT  EQU     #7B
SYS_PORT_OFF    EQU     #3C
SYS_MAP_CACHE   EQU     #04
SYS_MAP_DSS     EQU     #03
ISA_SYSTEM_PORT EQU     #1FFD
ISA_SYSTEM_DSS  EQU     #01

CACHE_RENDER_BASE EQU   #0100

CBL_CTRL        EQU     #004E
CBL_DATA        EQU     #004F
CBL_CTRL_OFF    EQU     #00
CBL_CTRL_IDLE   EQU     #80
CBL_CTRL_RUN_11K_MONO EQU #88           ; 7.8125 kHz mono (CBL rate code #8)
CBL_CTRL_RUN_11K_MONO_INT EQU #98       ; 7.8125 kHz mono + INT
CBL_SILENCE     EQU     #80
SFX_CBL_CHUNK_BYTES EQU 128

; --- Sega/Kempston joystick (ported from spevosdk sprintersdk/lib_input.asm) ---
; The Kempston input is decoded without A3/A4, so #07 and #1F are the same
; external port. From SRAM cache (WIN0) #1F hits the Z84C15 internal PIO, so the
; joystick must be read via the #07 alias; from DRAM/SIMM it is read at #1F.
KEMP_PORT_CACHE EQU     #07             ; Kempston read port from SRAM cache (WIN0)
KEMP_PORT_DRAM  EQU     #1F             ; Kempston read port from DRAM/SIMM
SIO_CMD_B       EQU     #1B             ; SIO channel B command (Sega SEL = WR5 DTR)
SEGA_SEL_HIGH   EQU     #E0             ; WR5: DTR=1 -> SEL high (normal button set)
SEGA_SEL_LOW    EQU     #60             ; WR5: DTR=0 -> SEL low
SEGA_SETTLE     EQU     8               ; SEL settle djnz count, SRAM cache @21MHz (~5us)
SEGA_SETTLE_DRAM EQU    8               ; SEL settle from DRAM; wait-states lengthen each
                                        ; iteration, so 8 is a safe (>=window) upper bound
JOY_RIGHT       EQU     %00000001
JOY_LEFT        EQU     %00000010
JOY_DOWN        EQU     %00000100
JOY_UP          EQU     %00001000
JOY_FIRE        EQU     %00010000
JOY_FLAP_MASK   EQU     JOY_FIRE | JOY_UP   ; fire (B) or up triggers a flap (SEL high, cycle 3)
JOY_SEGA_START  EQU     %00100000           ; Start button, read on SEL low (cycle 2) -> Esc/pause
