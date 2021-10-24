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
	defb 21	 	; R1 - Horizontal Displayed  (chars wide)
	defb 36		; R2 - Horizontal Sync Position (centralises screen)
	defb &86	; R3 - Horizontal and Vertical Sync Widths
	defb 38		; R4 - Vertical Total
	defb 0		; R5 - Vertical Adjust
	defb 34		; R6 - Vertical Displayed (chars tall)
	defb 35		; R7 - Vertical Sync Position (centralises screen)
	defb 0		; R8 - Interlace
	defb 7		; R9 - Max Raster 
	defb 0		; R10 - Cursor (not used)
	defb 0		; R11 - Cursor (not used)
	defb &30	; R12 - Screen start (start at &c000)
	defb &00 	; R13 - Screen start

Screen_Init:
	;; Sets the screen to 16 colour/160 wide mode
	ld bc,&7F00+128+4+8+0
	out (c),c
	
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
	ld de,&C02a 	;; x40  bytes 
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
	defw &002A,&082A,&102A,&182A,&202A,&282A,&302A,&382A
	defw &0054,&0854,&1054,&1854,&2054,&2854,&3054,&3854
	defw &007E,&087E,&107E,&187E,&207E,&287E,&307E,&387E
	defw &00A8,&08A8,&10A8,&18A8,&20A8,&28A8,&30A8,&38A8
	defw &00D2,&08D2,&10D2,&18D2,&20D2,&28D2,&30D2,&38D2
	defw &00FC,&08FC,&10FC,&18FC,&20FC,&28FC,&30FC,&38FC
	defw &0126,&0926,&1126,&1926,&2126,&2926,&3126,&3926
	defw &0150,&0950,&1150,&1950,&2150,&2950,&3150,&3950
	defw &017A,&097A,&117A,&197A,&217A,&297A,&317A,&397A
	defw &01A4,&09A4,&11A4,&19A4,&21A4,&29A4,&31A4,&39A4
	defw &01CE,&09CE,&11CE,&19CE,&21CE,&29CE,&31CE,&39CE
	defw &01F8,&09F8,&11F8,&19F8,&21F8,&29F8,&31F8,&39F8
	defw &0222,&0A22,&1222,&1A22,&2222,&2A22,&3222,&3A22
	defw &024C,&0A4C,&124C,&1A4C,&224C,&2A4C,&324C,&3A4C
	defw &0276,&0A76,&1276,&1A76,&2276,&2A76,&3276,&3A76
	defw &02A0,&0AA0,&12A0,&1AA0,&22A0,&2AA0,&32A0,&3AA0
	defw &02CA,&0ACA,&12CA,&1ACA,&22CA,&2ACA,&32CA,&3ACA
	defw &02F4,&0AF4,&12F4,&1AF4,&22F4,&2AF4,&32F4,&3AF4
	defw &031E,&0B1E,&131E,&1B1E,&231E,&2B1E,&331E,&3B1E
	defw &0348,&0B48,&1348,&1B48,&2348,&2B48,&3348,&3B48
	defw &0372,&0B72,&1372,&1B72,&2372,&2B72,&3372,&3B72
	defw &039C,&0B9C,&139C,&1B9C,&239C,&2B9C,&339C,&3B9C
	defw &03C6,&0BC6,&13C6,&1BC6,&23C6,&2BC6,&33C6,&3BC6
	defw &03F0,&0BF0,&13F0,&1BF0,&23F0,&2BF0,&33F0,&3BF0
	defw &041A,&0C1A,&141A,&1C1A,&241A,&2C1A,&341A,&3C1A
	defw &0444,&0C44,&1444,&1C44,&2444,&2C44,&3444,&3C44
	defw &046E,&0C6E,&146E,&1C6E,&246E,&2C6E,&346E,&3C6E
	defw &0498,&0C98,&1498,&1C98,&2498,&2C98,&3498,&3C98
	defw &04C2,&0CC2,&14C2,&1CC2,&24C2,&2CC2,&34C2,&3CC2
	defw &04EC,&0CEC,&14EC,&1CEC,&24EC,&2CEC,&34EC,&3CEC
	defw &0516,&0D16,&1516,&1D16,&2516,&2D16,&3516,&3D16
	defw &0540,&0D40,&1540,&1D40,&2540,&2D40,&3540,&3D40
	defw &056A,&0D6A,&156A,&1D6A,&256A,&2D6A,&356A,&3D6A

