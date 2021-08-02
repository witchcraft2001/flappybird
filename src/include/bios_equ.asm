BiosRst			EQU	#08

;Функции работы с памятью
Bios.Emm_Fn0		EQU	#C0
Bios.Emm_Fn1		EQU	#C1
Bios.Emm_Fn2		EQU	#C2
Bios.Emm_Fn3		EQU	#C3
Bios.Emm_Fn4		EQU	#C4
Bios.Emm_Fn5		EQU	#C5
Bios.Emm_Fn6		EQU	#C6
Bios.Emm_Fn7		EQU	#C7
Bios.Emm_Fn8		EQU	#C8
Bios.Emm_Fn9		EQU	#C9

Bios.SetPalette         EQU     #A4		; установка палитры

;Функции управления окнами и режимами экрана
Bios.Win_Open		EQU	#B0
Bios.Win_Close		EQU	#B1
Bios.Win_Copy_Win	EQU	#B2
Bios.Win_Restore_Win	EQU	#B3
Bios.Win_Get_Sym	EQU	#B4
Bios.Win_Put_Sym	EQU	#B5
Bios.Win_Set_ZG		EQU	#B6
Bios.Win_Move_Win	EQU	#B7
Bios.Win_Get_ZG		EQU	#B8



;Функции вывода текста на экран
Bios.Lp_Print_All	EQU	#81
Bios.Lp_Print_Sym	EQU	#82
Bios.Lp_Print_Atr	EQU	#83
Bios.Lp_Set_Place	EQU	#84
Bios.Lp_Print_Ln	EQU	#85
Bios.Lp_Print_Ln2	EQU	#86
Bios.Lp_Print_Ln3	EQU	#87
Bios.Lp_Print_Ln4	EQU	#88
Bios.Lp_Cls_Win		EQU	#89
Bios.Lp_Scroll_Up	EQU	#8A
Bios.Lp_Print_Ln5	EQU	#8B
Bios.Lp_Print_Ln6	EQU	#8C
Bios.Lp_Cls_Win2	EQU	#8D
Bios.Lp_Get_Place	EQU	#8E

;Функции работы с жесткими дисками и дисководами
Bios.Drv_Reset		EQU	#51
Bios.Drv_Verify		EQU	#54
Bios.Drv_Read		EQU	#55
Bios.Drv_Write		EQU	#56
Bios.Drv_Detect		EQU	#57
Bios.Drv_Get_Par	EQU	#58
Bios.Drv_Set_Par	EQU	#59
Bios.Ext_Version	EQU	#5A
Bios.Drv_List		EQU	#5F





