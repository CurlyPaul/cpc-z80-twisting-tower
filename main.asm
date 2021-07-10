;****************************************
; Header
;****************************************
Palette_Background equ &FF
Palette_Black equ &3F

org &4000
;;run start

Start:
call Screen_Init
call Palette_Init
call InterruptHandler_Init

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
_waitFrame:                                
         ld b,#F5	;; PPI Rastor port
_waitFrameLoop:
         in a,(c)
         rra  		;; Right most bit indicates vSync is happening
         jr nc, _waitFrameLoop
	 call SwitchScreenBuffer
jr MainLoop
	
DrawBackground:
	call ClearScreen
ret

ClearScreen:
	ld hl,(BackBufferAddress)
	ld d,h
	ld e,l
	inc de
	ld bc,&3DFF		;; Number of bytes to clear
	ld (hl),Palette_Background
	ldir	
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
	ld e,(iy+RowOffset_BlockWidth) ;; Reset the width

	ld a,(iy+RowOffset_Hue)	 	;; Toggle the hue
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
	add (iy+RowOffset_LHWidth)				;; b{sqOne.xPos} + e{sqOne.W} 
	inc a
	ld b,a  			;; put the final X back into b
	ld e,(iy+RowOffset_BlockWidth)	;; this one is always the standard width
	call DrawSquare

	;; Another square the same as the last
	ld a,b
	add (iy+RowOffset_BlockWidth)
	inc a
	ld b,a
	ld e,(iy+RowOffset_BlockWidth)
	call DrawSquare
	
	;; For the final one, calculate the xPos as before
	ld a,b
	add (iy+RowOffset_BlockWidth)
	inc a
	ld b,a
	;; Now calculate it's width
	ld e,(iy+RowOffset_RHWidth)
	inc e

	;; Check if it's larger than the starting width
	ld a,e
	cp &0E	;; Width + 1
	jr c,SkipRightReset 
	;; Do right square reset
	ld e,&00
SkipRightReset:
	ld (iy+RowOffset_RHWidth),e
	call DrawSquare
	
ret

; todo the colours are out by one

DrawSquare:
	;; INPUTS
	;; IY Row struct
	;; BC (x,y)
	;; E Block Width

	;; return if the width is zero
	ld a,e
	cp 0
	jr z,_toggleHue

	;; Need to maintain this value, but DE is too useful to tie up
	ld ixl, e

	;; Calculate where the start of the heatmap is for this block and store it in de
	;; Xpos - RowStartXPos + Heatmap
	;; (B - (iy+RowOffset_XPos)) + HeatMap
	
	ld a,b
	sub (iy+RowOffset_XPos)
	ld de,HeatMap
	add e
	ld e,a

	push bc
		call GetScreenPos 	;; HL = screen position
		;; init some loop counters
		ld b,(iy+RowOffset_Height) ; Height in lines
		ld c,ixl ; Width in Bytes

		_squareNextLine:
			push de ;; Preserving pointer to heatmap
			push hl ;; Preserving point to the scr address
			push bc ;; Resetting loop counters for the next line
		
		_squareNextByte:		
				ld a,(de) 			;; Load a byte from the heatmap
				ld ix,&00:ColourMaskOffsetPlus2 ;; Apply the hue for this block block
				or a,ixl
				
				ld (hl),a	;; HL = Screen desintation
				inc hl
				inc de
				dec c
				jr nz,_squareNextByte
			
			pop bc
			pop hl
			call GetNextLine ;; Load HL wit the scr address for the next line		
			pop de
		djnz _squareNextLine	;; djnz - decreases b and jumps when it's not zero
	pop bc

	_toggleHue:
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
;; Not currently using but leaving this here so the palette keeps working

;;	exx
;;	ex af,af'
;;		ld b,&F5 	; The PPI (Programmable Peripheral Interface) is a device which gives us info about the screen
;;		in a,(c)	; read a from port (bc)
;;		rra 		; right most bit indicates vsync, so push it into the carry
;;		jp nc,InterruptHandlerReturn
;;
;;	InterruptHandlerReturn: 
;;	exx
;;	ex af,af'
	ei
ret

;****************************************
; Variables
;****************************************
ScreenStartAddressFlag:	db 48  		; 16 = &4000 32 = &8000 48 = &C000 ;; TODO Keiths example shows how to bitshift these
ScreenOverflowAddress: 	dw &BFFF
BackBufferAddress: 	dw &8000 

RowOffset_XPos equ 0
RowOffset_YPos equ 1
RowOffset_Height equ 2
RowOffset_BlockWidth equ 3
RowOffset_LHWidth equ 4
RowOffset_RHWidth equ 5
RowOffset_Hue equ 6

Row1Struct:
	db &0C 		;; X pos
	db &00 		;; Y pos
	db &30 		;; Height
	db &0D 		;; Block Width
	db &0D 		;; Current LH square width
	db &0  		;; Current RH square width
	db %00000000 	;; Starting hue

Row2Struct:
	db &0C 		;; X pos
	db &33 		;; Y pos
	db &30 		;; Height
	db &0D 		;; Block Width
	db &06 		;; Current LH square width
	db &07 		;; Current RH square width
	db %00000011 	;; Starting hue

Row3Struct:
	db &0C 		;; X pos
	db &66 		;; Y pos
	db &10 		;; Height
	db &0D 		;; Block Width
	db &03 		;; Current LH square width
	db &0A 		;; Current RH square width
	db %00000000 	;; Starting hue

Row4Struct:
	db &0C 		;; X pos
	db &79 		;; Y pos
	db &30 		;; Height
	db &0D 		;; Block Width
	db &0B 		;; Current LH square width
	db &02 		;; Current RH square width
	db %00000011 	;; Starting hue

Row5Struct:
	db &0C 		;; X pos
	db &AC 		;; Y pos
	db &18 		;; Height
	db &0D 		;; Block Width
	db &09 		;; Current LH square width
	db &04  	;; Current RH square width
	db %00000000 	;; Starting hue

read ".\libs\CPC_V2_SimpleScreenSetUp.asm"
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