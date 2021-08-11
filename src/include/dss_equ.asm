DssRst		EQU	#10

Dss.Version	EQU	#00
Dss.ChDisk	EQU	#01
Dss.CurDisk	EQU	#02
Dss.DskInfo	EQU	#03
;Dss.G_ENTRY	EQU	#04
;		EQU	#05
;		EQU	#06
;		EQU	#07
;		EQU	#08
Dss.BOOTDSK	EQU	#09
;File io
Dss.Create	EQU	#0A
Dss.Creat_N	EQU	#0B
;		EQU	#0C
;Dss.ERASE	EQU	#0D
Dss.Delete	EQU	#0E
;Dss.Move	EQU	#0F
Dss.Rename	EQU	#10
Dss.Open	EQU	#11
Dss.Close	EQU	#12
Dss.Read	EQU	#13
Dss.Write	EQU	#14
Dss.Move_FP	EQU	#15
Dss.Attrib	EQU	#16
Dss.Get_D_T	EQU	#17
Dss.Put_D_T	EQU	#18
Dss.F_First	EQU	#19
Dss.F_Next	EQU	#1A
Dss.MkDir	EQU	#1B
Dss.RmDir	EQU	#1C
Dss.ChDir	EQU	#1D
Dss.CurDir	EQU	#1E
;		EQU	#1F
;		EQU	#20
Dss.SysTime	EQU	#21
Dss.SetTime	EQU	#22
;		EQU	#23
;		EQU	#24
;		EQU	#25
;		EQU	#26
;		EQU	#27
;		EQU	#28
;		EQU	#29
;		EQU	#2A
;		EQU	#2B
;		EQU	#2C
;		EQU	#2D
;		EQU	#2E
;		EQU	#2F
;Keyboard
Dss.WaitKey	EQU	#30
Dss.ScanKey	EQU	#31
Dss.EchoKey	EQU	#32
Dss.CTRLKey	EQU	#33
;Dss.EDIT	EQU	#34
Dss.K_CLEAR	EQU	#35
Dss.K_SETUP	EQU	#36
Dss.TestKey	EQU	#37
;Memory
Dss.SetWin	EQU	#38
Dss.SetWin1	EQU	#39
Dss.SetWin2	EQU	#3A
Dss.SetWin3	EQU	#3B
Dss.INFOMEM	EQU	#3C
Dss.GetMem	EQU	#3D
Dss.FreeMem	EQU	#3E
Dss.SetMem	EQU	#3F
;Execution
Dss.Exec	EQU	#40
Dss.Exit	EQU	#41
Dss.Wait	EQU	#42

Dss.GSwitch	EQU	#43
Dss.DosName	EQU	#44
Dss.EX_Path	EQU	#45
Dss.Environ	EQU	#46
Dss.AppInfo	EQU	#47
;		EQU	#48
;		EQU	#49
;		EQU	#4A
;		EQU	#4B
;		EQU	#4C
;		EQU	#4D
;		EQU	#4E
;		EQU	#4F

Dss.SetVMod	EQU	#50
Dss.GetVMod	EQU	#51
Dss.Locate	EQU	#52
Dss.Cursor	EQU	#53
Dss.SelPage	EQU	#54
Dss.Scroll	EQU	#55
Dss.Clear	EQU	#56
Dss.RdChar	EQU	#57
Dss.WrChar	EQU	#58
Dss.WinCopy	EQU	#59
Dss.WinRest	EQU	#5A
Dss.PutChar	EQU	#5B
Dss.PChars	EQU	#5C
;Dss.RES_PRN	EQU	#5D
;Dss.CTRLPRN	EQU	#5E
Dss.Print	EQU	#5F
;
FileMode.RW:    EQU     #00
FileMode.Read:  EQU     #01
FileMode.Write: EQU     #02
FileAttrib.Normal equ   #00	; Normal file, no attributes 
FileAttrib.RDOnly equ   #01	; Read only attribute 
FileAttrib.Hidden equ   #02	; Hidden file 
FileAttrib.System equ   #04	; System file 
FileAttrib.Label  equ   #08	; Volume label
FileAttrib.Direc  equ   #10	; Directory
FileAttrib.Arch   equ   #20     ; Archive

;-------------------------
;characters
cr		equ 0dh		;возврат коретки
lf		equ 0ah		;новая строка
tab		equ 9		;символ табуляции
space		equ 20h		;символ пробела