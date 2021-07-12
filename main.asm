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
call DrawBackground
call SwitchScreenBuffer
call DrawBackground

;****************************************
; Main Program
;****************************************
MainLoop:
	ld iy,Row1Struct
	call DrawRow
	call CopyRow
	ld iy,Row2Struct
	call DrawRow
	call CopyRow
	ld iy,Row3Struct
	call DrawRow
	call CopyRow
	ld iy,Row4Struct
	call DrawRow
	call CopyRow
	ld iy,Row5Struct
	call DrawRow
	call CopyRow
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

DrawRowV2:
	;; Set the starting colour

	;; In this context, draw only draws one line to the screen	
	;; Draw the RH square, including the black line if needed

	;; Given IY contains a row width 
	;; create a loop that draws squares until we run out of width

	;; Draw the LH square, including the black line if needed

	;; Copy the above row down the screen
CopyRow:
	;; INPUTS 
	;; HL = scr pos of first byte of last row 
	;; IY = Row struct
	ld b,(iy+RowOffset_Height)
_copyNextLine:
	push bc	
		push hl
		push hl 
			call GetNextLine
			ld d,h
			ld e,l
		pop hl
		ld b,0
		ld c,&30 ;; Todo calculate this from the row struct
		ldir ;; HL first pixel of last line, de first pixel of this line, bc bytes to copy

		;; HL now needs to be reset to the start of the previous row
		pop hl
		;; and incremented to the next row
		call GetNextLine 
		;; TODO I end up calling GetNextLine twice per line when I already have one of the values 
	pop bc
	djnz _copyNextLine
ret

DrawRow:
	;; INPUTS
	;; IY Row struct
	;; RETURNS
	;; HL scr pos of the first pixel in the row

	;; Get the starting colour
	ld h,0
	ld l,(iy+RowOffset_Hue)
	ld (ColourMaskOffsetPlus2-2),hl
	
	ld b,(iy+RowOffset_XPos)
	ld c,(iy+RowOffset_YPos)
	call GetScreenPos 	;; HL == scr position of the fisrt pixel in the first line
	push hl

	ld ix,Heatmap
	;; Draw the LH square

	ld e,(iy+RowOffset_LHWidth)
	dec e
	bit 7,e ;; If the left most bit is set, we've gone past zero	
	jr z,SkipLeftReset
	;; Do left hand square reset
	ld e,(iy+RowOffset_BlockWidth) ;; Reset the width

	ld a,(iy+RowOffset_Hue)	 	;; Toggle the hue
	xor 3
	;;ld l,a
	ld (iy+RowOffset_Hue),a
	;;ld h,0
	ld (ColourMaskOffsetPlus2-2),a
SkipLeftReset:
	ld (iy+RowOffset_LHWidth),e
	call DrawSquareFirstLine

	inc hl
	ld (hl),Palette_Black
	inc hl
	inc ix
	;; Increment some of the values and draw another square
	;;ld a,b
	;;add (iy+RowOffset_LHWidth)	;; b{sqOne.xPos} + e{sqOne.W} 
	;;inc a
	;;ld b,a  			;; put the final X back into b
	ld e,(iy+RowOffset_BlockWidth)	;; this one is always the standard width
	call DrawSquareFirstLine

	inc hl
	ld (hl),Palette_Black
	inc hl
	inc ix
	;; Another square the same as the last
	;ld a,b
	;add (iy+RowOffset_BlockWidth)
	;inc a
	;ld b,a
	ld e,(iy+RowOffset_BlockWidth)
	call DrawSquareFirstLine
	
	inc hl
	ld (hl),Palette_Black
	inc hl
	inc ix
	;; For the final one, calculate the xPos as before
	;ld a,b
	;add (iy+RowOffset_BlockWidth)
	;inc a
	;ld b,a
	;; Now calculate it's new width
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
	call DrawSquareFirstLine

	pop hl	
ret

DrawSquareFirstLine:
	;; INPUTS
	;; IX Heatmap address
	;; BC (x,y) ?????????? don't think this is true anymore
	;; E Block Width
	;; HL screen pos
	;; RETURNS
	;; HL screen pos of last pixel drawn
	;; DESTROYS
	;; DE

	;; return if the width is zero
	ld a,e
	cp 0
	jr z,_toggleHue

	;; Need to maintain this value, but DE is too useful to tie up
	;ld ixl, e

	;; Calculate where the start of the heatmap is for this block and store it in de
	;; Xpos - RowStartXPos + Heatmap
	;; (B - (iy+RowOffset_XPos)) + HeatMap
	
;this was failing because GetScreenPos destroys bc, but can I maintain de == heatmap instead

	;ld a,b,
	;sub (iy+RowOffset_XPos)
	;ld ix,HeatMap
	;add ixl
	;ld e,a

	;; TODO don't think this push is needed
	push bc 	 ;; Preserving XYPos for the calling fuction
		ld c,e ;; init c as a loop counter for the width
		_squareNextByte:
			;; Can I self mod to get rid of this push
			push ix		
				ld a,(ix) 			;; Load a byte from the heatmap
				ld ix,&00:ColourMaskOffsetPlus2 ;; Apply the hue for this block block
				or a,ixl
			pop ix

			ld (hl),a	;; HL = Screen desintation
			inc hl
			inc ix
			dec c
			jr nz,_squareNextByte
	pop bc

	_toggleHue:
	ld de,(ColourMaskOffsetPlus2-2)
	ld a,e
	xor 3
	ld e,a
	ld (ColourMaskOffsetPlus2-2),de
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
	add 2  	;; to make them the same as the vertical ones	
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
	db &32 		;; Y pos
	db &30 		;; Height
	db &0D 		;; Block Width
	db &06 		;; Current LH square width
	db &07 		;; Current RH square width
	db %00000011 	;; Starting hue

Row3Struct:
	db &0C 		;; X pos
	db &64 		;; Y pos
	db &10 		;; Height
	db &0D 		;; Block Width
	db &03 		;; Current LH square width
	db &0A 		;; Current RH square width
	db %00000000 	;; Starting hue

Row4Struct:
	db &0C 		;; X pos
	db &76 		;; Y pos
	db &30 		;; Height
	db &0D 		;; Block Width
	db &0B 		;; Current LH square width
	db &02 		;; Current RH square width
	db %00000011 	;; Starting hue

Row5Struct:
	db &0C 		;; X pos
	db &A8 		;; Y pos
	db &16 		;; Height
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


org &6000
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