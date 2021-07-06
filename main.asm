;****************************************
; Header
;****************************************
ScreenSize equ &4000
Palette_Background equ &FF
Palette_Black equ &3F

org &8000

call Screen_Init
call Palette_Init
call InterruptHandler_Init
call MainLoop

;****************************************
; Main Program
;****************************************
MainLoop:
	call DrawBackground

	ld iy,Row1Struct
	call DrawRow
	ld iy,Row2Struct
	call DrawRow
	ld iy,Row3Struct
	call DrawRow
	ld iy,Row4Struct
	call DrawRow
	ld iy,Row5Struct
	call DrawRow
	
	ld ix,FrameSemaphor
	ld (ix),1
WaitFrame:
	ld a,0
	cp (ix)
	jr z,MainLoop
	halt
jr WaitFrame
	
DrawBackground:
	call ClearScreen
ret

ClearScreen:
	push de
		ld hl,(BackBufferAddress)
		ld de,(BackBufferAddress)
		inc de
		ld bc,ScreenSize-1
		ld (hl),Palette_Background
		ldir
	pop de
ret

DrawRow:
	;; INPUTS
	;; IY Row struct
	call DrawBlock
	
	ld b,(iy+RowOffset_XPos)
	ld c,(iy+RowOffset_YPos)
	ld d,(iy+RowOffset_Height)
	ld e,(iy+RowOffset_LHWidth)

	;; Get the starting colour
	ld h,0
	ld l,(iy+RowOffset_Hue)
	ld (ColourMaskOffsetPlus2-2),hl

	;; Decrease the width
	dec e
	bit 7,e ;; If the left most bit is set, we've gone past zero	
	jr z,SkipLeftReset
	;; Do left hand square reset
	ld e,(iy+RowOffset_BlockWidth)

	ld a,(iy+RowOffset_Hue)
	xor 3
	ld l,a
	ld (iy+RowOffset_Hue),l
	ld h,0
	ld (ColourMaskOffsetPlus2-2),hl
SkipLeftReset:
	ld (iy+RowOffset_LHWidth),e
	call DrawSquare

	;; Increment some of the values and draw another square
	ld a,b
	add e				;; b{sqOne.xPos} + e{sqOne.W} 
	inc a
	ld b,a  			;; put the final X back into b
	ld e,(iy+RowOffset_BlockWidth)	;; this one is always the standard width
	call DrawSquare

	;; Another square the same as the last
	ld a,b
	add e
	inc a
	ld b,a
	ld e,(iy+RowOffset_BlockWidth)
	call DrawSquare
	
	;; For the final one, calculate the xPos as before
	ld a,b
	add e
	inc a
	ld b,a
	;; Now calculate it's width
	ld e,(iy+RowOffset_RHWidth)
	inc e

	;; Check if it's larger than the starting width
	ld a,e
	cp &0E	;; Width + 1, can't find a nice way to not hard code this
	jr c,SkipRightReset 
	;; Do right square reset
	ld e,&00
SkipRightReset:
	ld (iy+RowOffset_RHWidth),e
	call DrawSquare
	
ret

DrawSquare:
	;; INPUTS
	;; bc (x,y)
	;; de Height, Width
	;; l Row start xpos
	;; return if the width is zero
	ld a,e
	cp 0
	jr z,ToggleHue

	;; return if the width wrapped
	bit 7,e
	ret nz

	;; Xpos - RowStartXPos + Heatmap
	;; (B - (iy+RowOffset_XPos)) + HeatMap
	
	ld a,b
	sub (iy+RowOffset_XPos)
	ld hl,HeatMap
	add l
	ld l,a
	ld (HeatMapOffsetPlus2-2),hl

	push bc
	push de
		call GetScreenPos 	;; HL = screen position
		;; init some loop counters
		ld b,d ; Height in lines
		ld c,e ; Width in Bytes
		;;dec c
		SquareNextLine:
			push hl
			push bc

		SquareNextByte:
			push hl
			push de
				;; TODO Can I do this outside of this loop and increment de?
				ld hl,&00:HeatMapOffsetPlus2
				ld a,e ;; e == width
				sub c  ;; c == width - index
				ld b,0
				ld d,0
				add l  ;; 
				ld l,a				;;ld de,a ;; put it back in e
				ld a,(hl)
				;; A now contains the pixel data to write to the screen
				ld hl,&00:ColourMaskOffsetPlus2
				or a,l
			pop de
			pop hl
			ld (hl),a	;; HL = Screen desintation
			inc hl
			dec c
			jr nz,SquareNextByte
			pop bc
			pop hl
	
		call GetNextLine 		
		djnz SquareNextLine	;; djnz - decreases b and jumps when it's not zero
	pop de
	pop bc

	ToggleHue:
	ld hl,(ColourMaskOffsetPlus2-2)
	ld a,l
	xor 3
	ld l,a
	ld (ColourMaskOffsetPlus2-2),hl
ret

DrawBlock:
	;; INPUTS 
	;; IY Row struct
	;; De
	ld b,(iy+RowOffset_XPos)
	ld c,(iy+RowOffset_YPos)

	call GetScreenPos 	;; HL = screen position
	;; init the loop counters
	
	;; for the width we use 3(block width+1)
	ld e,(iy+RowOffset_BlockWidth)	
	inc e 	;; here's the +1
	ld a,e 	;; then add it to itself 3 times
	add e
	add e
	ld c,a  ;; C == Width in Bytes
	
	ld a,(iy+RowOffset_Height) ; Height in lines
	add 3  	;; to make them the same as the vertical ones	
	ld b,a 	;; B == Height in lines
	
	BlockNextLine:
		push hl
		push bc

		BlockNextByte:
			ld a,Palette_Black
			ld (hl),a	;; HL = Screen desintation
			inc hl
			dec c
			jr nz,BlockNextByte
		pop bc
		pop hl
		call GetNextLine 		
		djnz BlockNextLine	;; djnz - decreases b and jumps when it's not zero
ret

GetScreenPos:
	;; Inputs: BC - X Y
	;; Returns HL : screen memory locations

	;; Calculate the ypos first
	push bc				; push bc because we need to preserve the value of b (xpos)
		ld b,0			; which we must zero out because bc needs to be the y coordinate
		ld hl,scr_addr_table	; load the address of the label into h1
		add hl,bc		; as each element in the look up table is 2 bytes(&XXXX) long, so add the value of c (ypos) to hl twice
		add hl,bc		; ...to convert h into an offset from the start of the lookup table
		
		;; Now read two bytes from the address held in hl. We have to do this one at a time

		ld a,(hl)		; stash one byte from the address in hl into a
		inc l			; increment the address we are pointing at
		ld h,(hl)		; load the next byte into the address at h into h
		ld l,a			; now put the first byte we read back into l

	;; Now calculate the xpos, this is much easier as these are linear in screen
	pop bc				; reset to BC to the original XY values
					
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

	push hl
	push de
		ld d,h
		ld e,l
		ld hl,(ScreenOverflowAddress)
		sbc hl,de 	; (OverflowAddress - CurrentAddress)
	pop de
	pop hl
	ret p			; if top bit is set we've wrapped and ran out memory			
	push bc		
		ld bc,&C050	; if we've wrapped add this magic number nudge back to the right place
		add hl,bc
	pop bc	
ret

SwitchScreenBuffer:
	; Flips all the screen buffer variables and moves the back buffer onto the screen
	ld a,(ScreenStartAddressFlag)
	sub 16
	jp nz, SetScreenBufferTwo
SetScreenBufferOne:
	ld de,48
	ld (ScreenStartAddressFlag),de
	ld de,&4000
	ld (BackBufferAddress),de
	ld de,&7FFF
	ld (ScreenOverflowAddress),de
	jp DoSwitchScreen
SetScreenBufferTwo:
	ld de,16
	ld (ScreenStartAddressFlag),de
	ld de,&C000
	ld (BackBufferAddress),de 
	ld de,&FFFF
	ld (ScreenOverflowAddress),de
DoSwitchScreen:
	ld bc,&BC0C 	; CRTC Register to change the start address of the screen
	out (c),c
	inc b
	ld a,(ScreenStartAddressFlag)
	out (c),a
ret

InterruptHandler_Init:
	; Sets the rastor interrupt to our interrupt handler
	di
		ld a,&C3		; jp op code
		ld (&0038),a		; &0038 is executed when the rastor interrupt fires
		ld hl,InterruptHandler
		ld (&0039),hl		; write jp InterruptHandler into the target address
	ei
ret

InterruptHandler:
	exx
	ex af,af'
		ld b,&F5 	; The PPI (Programmable Peripheral Interface) is a device which gives us info about the screen
		in a,(c)	; read a from port (bc)
		rra 		; right most bit indicates vsync, so push it into the carry
		jp nc,InterruptHandlerReturn
		ld ix,FrameSemaphor
		ld a,0
		cp (ix)
		jp z,InterruptHandlerReturn ;; Frame not ready 
		call SwitchScreenBuffer
		ld (ix),0
	InterruptHandlerReturn: 
	exx
	ex af,af'
	ei
ret

;****************************************
; Variables
;****************************************
ScreenStartAddressFlag:	db 48  		; 16 = &4000 48 = &C000 
ScreenOverflowAddress: 	dw &7FFF
BackBufferAddress: 	dw &4000 
FrameCounter: 		db 0
FrameSemaphor:		db 0

RowOffset_XPos equ 0
RowOffset_YPos equ 1
RowOffset_Height equ 2
RowOffset_BlockWidth equ 3
RowOffset_LHWidth equ 4
RowOffset_RHWidth equ 5
RowOffset_Hue equ 6

Row1Struct:
	db &0F 		;; X pos
	db &00 		;; Y pos
	db &30 		;; Height
	db &0D 		;; Block Width
	db &0D 		;; Current LH square width
	db &0  		;; Current RH square width
	db %00000000 	;; Starting hue

Row2Struct:
	db &0F 		;; X pos
	db &33 		;; Y pos
	db &30 		;; Height
	db &0D 		;; Block Width
	db &06 		;; Current LH square width
	db &07 		;; Current RH square width
	db %00000011 	;; Starting hue

Row3Struct:
	db &0F 		;; X pos
	db &66 		;; Y pos
	db &10 		;; Height
	db &0D 		;; Block Width
	db &03 		;; Current LH square width
	db &0A 		;; Current RH square width
	db %00000000 	;; Starting hue

Row4Struct:
	db &0F 		;; X pos
	db &79 		;; Y pos
	db &30 		;; Height
	db &0D 		;; Block Width
	db &0B 		;; Current LH square width
	db &02 		;; Current RH square width
	db %00000011 	;; Starting hue

Row5Struct:
	db &0F 		;; X pos
	db &AC 		;; Y pos
	db &18 		;; Height
	db &0D 		;; Block Width
	db &09 		;; Current LH square width
	db &04  	;; Current RH square width
	db %00000000 	;; Starting hue

read ".\libs\CPC_V1_SimpleScreenSetUp.asm"
read ".\libs\CPC_V1_SimplePalette.asm"

;****************************************
; Resources
;****************************************

;; Pixel layout: A0 B0 A2 B2 A1 B1 A3 B3

		  ;; pixel A 	B
HeatMap_0 equ %00000000 ;; 0	0
HeatMap_1 equ %11000000 ;; 1	1
HeatMap_2 equ %10000100	;; 1    2  
HeatMap_3 equ %00001100 ;; 2    2
HeatMap_4 equ %11001100 ;; 3    3

HeatMap:
	db HeatMap_0
	db %10000000
	db HeatMap_1
	db HeatMap_1
	db HeatMap_1
	db HeatMap_2
	db HeatMap_2 
	db HeatMap_2 
	db %10011000 
	db HeatMap_3 
	db HeatMap_3
	db HeatMap_3
	db HeatMap_4

	db HeatMap_4
	db HeatMap_3
	db HeatMap_3
	db HeatMap_3
	db HeatMap_3
	db HeatMap_3
	db HeatMap_3
	db HeatMap_3
	db HeatMap_3
	db HeatMap_3
	db HeatMap_3
	db HeatMap_3
	db HeatMap_3
	db HeatMap_3
	db HeatMap_3

	db HeatMap_4
	db HeatMap_3  
	db HeatMap_3  
	db HeatMap_3  
	db HeatMap_3 
	db HeatMap_2  
	db HeatMap_2  
	db HeatMap_2  
	db HeatMap_1  
	db HeatMap_1  
	db HeatMap_1  
	db HeatMap_1 
	db HeatMap_0
	db HeatMap_0