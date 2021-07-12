;;*****************************************************************************************
;; Origially based on examples in the zip file found at https://www.chibiakumas.com/z80/
;;
;; Public entry points:
;;
;;	- Screen_Init
;;	- GetScreenPos
;;	- GetNextLine
;; 	- SwitchScreenBuffer
;;
;; Label expectations:
;; 	- ScreenStartAddressFlag
;;	- BackBufferAddress
;;
;;*****************************************************************************************
ScreenSize equ &4000
CRTC_4000 equ 16
CRTC_8000 equ 32
CRTC_C000 equ 48

CRTCOptions:
	defb &3f	; R0 - Horizontal Total
	defb 32	 	; R1 - Horizontal Displayed  (32 chars wide)
	defb 42		; R2 - Horizontal Sync Position (centralises screen)
	defb &86	; R3 - Horizontal and Vertical Sync Widths
	defb 38		; R4 - Vertical Total
	defb 0		; R5 - Vertical Adjust
	defb 24		; R6 - Vertical Displayed (24 chars tall)
	defb 31		; R7 - Vertical Sync Position (centralises screen)
	defb 0		; R8 - Interlace
	defb 7		; R9 - Max Raster 
	defb 0		; R10 - Cursor (not used)
	defb 0		; R11 - Cursor (not used)
	defb &30	; R12 - Screen start (start at &c000)
	defb &00 	; R13 - Screen start

Screen_Init:
	;; Sets the screen to 16 colour/160 wide mode
	ld a,0
	call &BC0E	; scr_set_mode 0 - 16 colors
	
	;; Set all of the CRTC options
	ld hl,CrtcOptions	
	ld bc,&BC00
	set_crtc_vals:
		out (c),c	;Choose a register
		inc b
		ld a,(hl)
		out (c),a	;Send the new value
		dec b
		inc hl
		inc c
		ld a,c
		cp 14		;When we get to 14, we've done all the registers
		jr nz,set_crtc_vals
ret


GetScreenPos:
	;; Inputs: BC - X Y
	;; Returns HL : screen memory locations
	;; Destroys BC

	;; Calculate the ypos first
	ld hl,scr_addr_table	; load the address of the label into h1

	;; Now read two bytes from the address held in hl. We have to do this one at a time
	ld a,c
	add   a, l    ; A = A+L
	ld    l, a    ; L = A+L	
   	adc   a, h    ; A = A+L+H+carry
    	sub   l       ; A = H+carry
    	ld    h, a    ; H = H+carry

	ld a,c
	add   a, l    ; A = A+L
   	ld    l, a    ; L = A+L	
    	adc   a, h    ; A = A+L+H+carry
    	sub   l       ; A = H+carry
    	ld    h, a    ; H = H+carry

	ld a,(hl)		; stash one byte from the address in hl into a
	inc l			; increment the address we are pointing at
	ld h,(hl)		; load the next byte into the address at h into h
	ld l,a			; now put the first byte we read back into l

	;; Now calculate the xpos, this is much easier as these are linear on the screen screen				
	ld a,b				; need to stash b as the next op insists on reading 16bit - we can't to ld c,(label)
	ld bc,(BackBufferAddress)	; bc now contains either &4000 or &C000, depending which cycle we are in
	ld c,a				; bc will now contain &40{x}
	add hl,bc			; hl = hl + bc, add the x and y values together
ret

GetNextLine:
	;; Inputs: HL Current screen memory location
	;; Returns: HL updated to the start of the next line
	ld a,h				; load the high byte of hl into a
	add &08				; it's just a fact that each line is + &0800 from the last one
	ld h,a				; put the value back in h

_screenBankMod_Minus1:
	bit 7,h		;Change this to bit 6,h if your screen is at &8000!
	jr nz,_getNextLineDone
	ld de,&C040
	add hl,de
_getNextLineDone:
ret



SwitchScreenBuffer:
	; Flips all the screen buffer variables and moves the back buffer onto the screen
	ld a,(ScreenStartAddressFlag)
	sub CRTC_8000
	jr nz, _setScreenBase8000
_setScreenBaseC000:
	ld de,CRTC_C000 
	ld (ScreenStartAddressFlag),de
	ld de,&8000
	ld (BackBufferAddress),de
	;; Remember this is the test for drawing to 8000, not C000
	ld hl,&2874		;; Byte code for: Bit 6,JR Z
	ld (_screenBankMod_Minus1+1),hl
	jr _doSwitchScreen
_setScreenBase8000:
	ld de,CRTC_8000
	ld (ScreenStartAddressFlag),de
	ld de,&C000 
	ld (BackBufferAddress),de 
	ld hl,&207C		;; Byte code for: Bit 7,JR NZ
	ld (_screenBankMod_Minus1+1),hl
_doSwitchScreen:
	ld bc,&BC0C 	; CRTC Register to change the start address of the screen
	out (c),c
	inc b
	ld a,(ScreenStartAddressFlag)
	out (c),a
ret

; Each word in the table is the memory address offest for the start of each screen line
; eg line 1 is at 0000 (scr_start_adr +C000 normally)
;    line 2 is at 0800
;    line 3 is at 1000
;    line 4 is at 1800
;    line 5 is at 2000 etc

;; This is the screen address table for a 256*256 screen
scr_addr_table
align2
	defw &0000,&0800,&1000,&1800,&2000,&2800,&3000,&3800
	defw &0040,&0840,&1040,&1840,&2040,&2840,&3040,&3840
	defw &0080,&0880,&1080,&1880,&2080,&2880,&3080,&3880
	defw &00C0,&08C0,&10C0,&18C0,&20C0,&28C0,&30C0,&38C0
	defw &0100,&0900,&1100,&1900,&2100,&2900,&3100,&3900
	defw &0140,&0940,&1140,&1940,&2140,&2940,&3140,&3940
	defw &0180,&0980,&1180,&1980,&2180,&2980,&3180,&3980
	defw &01C0,&09C0,&11C0,&19C0,&21C0,&29C0,&31C0,&39C0
	defw &0200,&0A00,&1200,&1A00,&2200,&2A00,&3200,&3A00
	defw &0240,&0A40,&1240,&1A40,&2240,&2A40,&3240,&3A40
	defw &0280,&0A80,&1280,&1A80,&2280,&2A80,&3280,&3A80
	defw &02C0,&0AC0,&12C0,&1AC0,&22C0,&2AC0,&32C0,&3AC0
	defw &0300,&0B00,&1300,&1B00,&2300,&2B00,&3300,&3B00
	defw &0340,&0B40,&1340,&1B40,&2340,&2B40,&3340,&3B40
	defw &0380,&0B80,&1380,&1B80,&2380,&2B80,&3380,&3B80
	defw &03C0,&0BC0,&13C0,&1BC0,&23C0,&2BC0,&33C0,&3BC0
	defw &0400,&0C00,&1400,&1C00,&2400,&2C00,&3400,&3C00
	defw &0440,&0C40,&1440,&1C40,&2440,&2C40,&3440,&3C40
	defw &0480,&0C80,&1480,&1C80,&2480,&2C80,&3480,&3C80
	defw &04C0,&0CC0,&14C0,&1CC0,&24C0,&2CC0,&34C0,&3CC0
	defw &0500,&0D00,&1500,&1D00,&2500,&2D00,&3500,&3D00
	defw &0540,&0D40,&1540,&1D40,&2540,&2D40,&3540,&3D40
	defw &0580,&0D80,&1580,&1D80,&2580,&2D80,&3580,&3D80
	defw &05C0,&0DC0,&15C0,&1DC0,&25C0,&2DC0,&35C0,&3DC0
