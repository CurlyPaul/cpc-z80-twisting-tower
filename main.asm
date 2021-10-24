;****************************************
; Header
;****************************************
Palette_Background equ &FF
Palette_Black equ &3F

org &4000
run start
;write ".\artifacts\tower.bin"

Start:
di
im 1
ld hl,&C9FB			;; C9 FB are the bytes for the Z80 opcodes EI:RET
ld (&0038),hl			;; setup interrupt handler

ld sp,&7fff			;; Using 8000-BFFF for video, so move this out of the way

call Palette_AllBackground	;; Clear the screen
call Screen_Init
ei
call ClearScreen
call SwitchScreenBuffer
call ClearScreen
call WaitFrame

call Palette_Init		;; Now set the correct colours and start drawing to the screen

ld b,&FF	;; 50 * 2 vsyncs == 2seconds
WaitFirstPauseLoop:	
	push bc
		call WaitFrame
	pop bc
	djnz WaitFirstPauseLoop

ld b,50*2
PhaseOneIntroLoop:
	push bc
		call SwitchScreenBuffer

		ld iy,Row1Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		call WaitFrame
	pop bc
	djnz PhaseOneIntroLoop

ld b,15
PhaseTwoIntroLoop:
	push bc
		call SwitchScreenBuffer

		ld iy,Row1Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row7Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		call WaitFrame
	pop bc
	djnz PhaseTwoIntroLoop


ld b,10
PhaseThreeIntroLoop:
	push bc
		call SwitchScreenBuffer

		ld iy,Row1Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row5Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row7Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		call WaitFrame
	pop bc
	djnz PhaseThreeIntroLoop

ld b,20
PhaseFourIntroLoop:
	push bc
		call SwitchScreenBuffer

		ld iy,Row1Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row4Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row5Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row7Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row10Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		call WaitFrame
	pop bc
	djnz PhaseFourIntroLoop

ld b,15
PhaseFiveIntroLoop:
	push bc
		call SwitchScreenBuffer

		ld iy,Row1Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row2Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider


		ld iy,Row4Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row5Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row7Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row10Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		call WaitFrame
	pop bc
	djnz PhaseFiveIntroLoop


ld b,12
PhaseSixIntroLoop:
	push bc
		call SwitchScreenBuffer

		ld iy,Row1Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row2Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row3Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row4Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row5Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row7Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row10Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		call WaitFrame
	pop bc
	djnz PhaseSixIntroLoop

ld b,4
PhaseSevenIntroLoop:
	push bc
		call SwitchScreenBuffer

		ld iy,Row1Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row2Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row3Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row4Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row5Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row6Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row7Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row10Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		call WaitFrame
	pop bc
	djnz PhaseSevenIntroLoop

ld b,4
PhaseEightIntroLoop:
	push bc
		call SwitchScreenBuffer

		ld iy,Row1Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row2Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row3Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row4Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row5Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row6Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row7Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row9Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		ld iy,Row10Struct
		call DrawRow
		call CopyRow
		call DrawRowDivider

		call WaitFrame
	pop bc
	djnz PhaseEightIntroLoop


ld b,30
PauseBeforeSpinning
	push bc
		call SwitchScreenBuffer
		call DrawRows
		call WaitFrame
	pop bc
	djnz PauseBeforeSpinning

ld iy,Row10Struct
ld (iy+RowOffset_Velocity),1
ld b,50
VelocityOneWait
	push bc
		call SwitchScreenBuffer
		call DrawRows
		call WaitFrame
	pop bc
	djnz VelocityOneWait

ld iy,Row9Struct
ld (iy+RowOffset_Velocity),1
ld b,20
VelocityTwoWait
	push bc
		call SwitchScreenBuffer
		call DrawRows
		call WaitFrame
	pop bc
	djnz VelocityTwoWait

ld iy,Row8Struct
ld (iy+RowOffset_Velocity),1
ld b,10
VelocityThreeWait
	push bc
		call SwitchScreenBuffer
		call DrawRows
		call WaitFrame
	pop bc
	djnz VelocityThreeWait


ld iy,Row7Struct
ld (iy+RowOffset_Velocity),1
ld b,10
VelocityFourWait
	push bc
		call SwitchScreenBuffer
		call DrawRows
		call WaitFrame
	pop bc
	djnz VelocityFourWait


ld hl,RowSpinArray
ld a,(hl)
SpinNextRow:
	ld iyl,a
	inc hl
	ld a,(hl)
	ld iyh,a
	ld (iy+RowOffset_Velocity),1
	push hl
		ld b,5
		VelocityFiveWait
			push bc
				call SwitchScreenBuffer
				call DrawRows
				call WaitFrame
			pop bc
		djnz VelocityFiveWait
	pop hl
	inc hl
	ld a,(hl)
	cp 0
	jr nz,SpinNextRow	

ld b,40
PauseAfterSpinning
	push bc
		call SwitchScreenBuffer
		call DrawRows
		call WaitFrame
	pop bc
	djnz PauseAfterSpinning

ld iy,Row2Struct
ld (iy+RowOffset_Velocity),2
ld iy,Row6Struct
ld (iy+RowOffset_Velocity),2
ld iy,Row9Struct
ld (iy+RowOffset_Velocity),2

;****************************************
; Main Program
;****************************************
MainLoop:
	call SwitchScreenBuffer
	call DrawRows
	call WaitFrame
jr MainLoop

WaitFrame:                                
         ld b,#F5	;; PPI Rastor port
_waitFrameLoop:
         in a,(c)
         rra  		;; Right most bit indicates vSync is happening
         jr nc, _waitFrameLoop
ret

DrawRows:
	ld iy,Row1Struct
	call DrawRow
	call CopyRow
	call DrawRowDivider

	ld iy,Row2Struct
	call DrawRow
	call CopyRow
	call DrawRowDivider

	ld iy,Row3Struct
	call DrawRow
	call CopyRow
	call DrawRowDivider

	ld iy,Row4Struct
	call DrawRow
	call CopyRow
	call DrawRowDivider

	ld iy,Row5Struct
	call DrawRow
	call CopyRow
	call DrawRowDivider	

	ld iy,Row6Struct
	call DrawRow
	call CopyRow
	call DrawRowDivider

	ld iy,Row7Struct
	call DrawRow
	call CopyRow
	call DrawRowDivider

	ld iy,Row8Struct
	call DrawRow
	call CopyRow
	call DrawRowDivider

	ld iy,Row9Struct
	call DrawRow
	call CopyRow
	call DrawRowDivider

	ld iy,Row10Struct
	call DrawRow
	call CopyRow
	call DrawRowDivider
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
	;; RETURNS
	;; HL scr pos of the first pixel in the row we just drew
	;; DESTROYS
	;; BC, DE

	;; Read the starting colour from the row's struct, and write it into the self mod location
	ld h,0
	ld l,(iy+RowOffset_Hue)
	ld (ColourMaskOffsetPlus2-2),hl
	
	;; Start to calculate how big the first square should be

	;; Load the last width and dec it by one
	ld a,(iy+RowOffset_LHWidth)
	sub (iy+RowOffset_Velocity)
	ld e,a
	 
	bit 7,e ;; e >= 0
	jr z,_drawFirstSquare
		;; Reset to the full block width for the row
		ld e,(iy+RowOffset_BlockWidth) 
		ld a,(iy+RowOffset_Hue)	 	;; Toggle the hue
		xor 3
		ld (iy+RowOffset_Hue),a
		ld (ColourMaskOffsetPlus2-2),a
_drawFirstSquare:
	ld ix,Heatmap			;; Initialise the heatmap to the start
	ld (iy+RowOffset_LHWidth),e	;; Save the width for the next time

	;; Calculate the screen position  from the xypos
	ld b,(iy+RowOffset_XPos)
	ld c,(iy+RowOffset_YPos)
	call GetScreenPos 	;; HL == scr position of the fisrt pixel in the first line
	push hl			;; Which we must preserve so that CopyRow can continue

		call DrawSquareFirstLine

		ld (hl),Palette_Black
		inc hl
		inc ix

		;; The second square is always the same width
		ld e,(iy+RowOffset_BlockWidth)	;; this one is always the standard width
		call DrawSquareFirstLine

		ld (hl),Palette_Black
		inc hl
		inc ix
		
		;; So is the third
		ld e,(iy+RowOffset_BlockWidth)
		call DrawSquareFirstLine
	
		ld (hl),Palette_Black
		inc hl
		inc ix
	
		;; Calculate the width of the last square, that starts at zero and get's wider each frame
		ld a,(iy+RowOffset_RHWidth)
		add (iy+RowOffset_Velocity)
		ld e,a

		;; Check if it's larger than the starting width
		ld a,e
		cp &0E	;; Width + 1
		jr c,_drawLastSquare 
			;; Reset the last square to zero width
			ld e,&00
	_drawLastSquare:
		ld (iy+RowOffset_RHWidth),e
		call DrawSquareFirstLine

	pop hl	
ret

DrawSquareFirstLine:
	;; INPUTS
	;; IX Heatmap address
	;; E Block Width
	;; HL screen pos
	;; RETURNS
	;; HL screen pos of last pixel drawn
	;; DESTROYS
	;; B, DE

	;; return if the width is zero
	ld a,e
	cp 0
	jr z,_drawFirstLineDone
		;; TODO Change GetScreenPos to take DE = xypos and use B to pass around the width
		
		ld b,e ;; init c as a loop counter for the width
		ld de,&00:ColourMaskOffsetPlus2 
		_squareNextByte:
			ld a,(ix) 	;; Load a byte from the heatmap
			or a,e		;; Apply the hue for this block 

			ld (hl),a	;; Draw the byte into the address in HL
			inc hl
			inc ix
			djnz _squareNextByte

_drawFirstLineDone:
	Call ToggleHue
ret

CopyRow:
	;; INPUTS 
	;; HL = scr pos of first byte of last row 
	;; IY = Row struct
	;; RETURNS 
	;; HL = scr pos of the first byte of the last row drawn
	ld b,(iy+RowOffset_Height)

	;; Combinding GetNextLine's dependency on HL and LDIR's use of HL means for some furious registry swapping
	;; but it's probably still faster than doing it manually

	ld d,h
	ld e,l

_copyNextLine:
	push bc
		
		;; de has the value that hl needs to have, but we need hl to use GetNextLine
		;; and to do that hl needs the values that de currently has
		ld b,d
		ld c,e

		ld h,d
		ld l,e

		call GetNextLine		
		;; Now hl has the value that de needs to have
		ld d,h
		ld e,l
		;; Now put the last line pos back into hl
		ld h,b
		ld l,c	
	
		push de	
			ld b,0
			ld c,&2A ;; Todo calculate this from the row struct
			ldir ;; HL first pixel of last line, de first pixel of this line, bc bytes to copy
		pop de


	pop bc
	djnz _copyNextLine

	ld h,d
	ld l,e
ret

DrawRowDivider
	;; INPUTS
	;; HL = scr pos of the first byte of the previous row
	;; RETURNS
	;; HL = scr pos of the first byte of the last row drawn
	
	call GetNextLine
	push hl
		ld b,&2A 		;; Row width, might eventually be dynamic
	_rowDividerLoopOne:
		ld (hl),Palette_Black
		inc hl
		djnz _rowDividerLoopOne
	pop hl

	;; Draw another black line
	call GetNextLine
	push hl
		ld b,&2A 		
	_rowDividerLoopTwo:
		ld (hl),Palette_Black
		inc hl
		djnz _rowDividerLoopTwo
	pop hl
ret

ToggleHue:
	;; Flips the bits the controls if the blocks are colour one or colour two
	;; RETURNS
	;; A - current value
	ld a,(ColourMaskOffsetPlus2-2)
	xor 3
	ld (ColourMaskOffsetPlus2-2),a
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
RowOffset_Velocity equ 7

Row1Struct:
	db &00 		;; X pos
	db &00 		;; Y pos
	db &19 		;; Height
	db &0D 		;; Block Width
	db &0D 		;; Current LH square width
	db &0  		;; Current RH square width
	db %00000000 	;; Starting hue
	db 0		;; Velocity

Row2Struct:
	db &00 		;; X pos
	db &1c 		;; Y pos
	db &10 		;; Height
	db &0D 		;; Block Width
	db &06 		;; Current LH square width
	db &07 		;; Current RH square width
	db %00000011 	;; Starting hue
	db 0		;; Velocity

Row3Struct:
	db &00 		;; X pos
	db &2F 		;; Y pos
	db &1B		;; Height
	db &0D 		;; Block Width
	db &03 		;; Current LH square width
	db &0A 		;; Current RH square width
	db %00000000 	;; Starting hue
	db 0		;; Velocity

Row4Struct:
	db &00 		;; X pos
	db &4D 		;; Y pos
	db &1B 		;; Height
	db &0D 		;; Block Width
	db &09 		;; Current LH square width
	db &04  		;; Current RH square width
	db %00000011 	;; Starting hue
	db 0		;; Velocity

Row5Struct:
	db &00 		;; X pos
	db &6B 		;; Y pos
	db &1D		;; Height
	db &0D 		;; Block Width
	db &02 		;; Current LH square width
	db &0B 		;; Current RH square width
	db %00000000 	;; Starting hue
	db 0		;; Velocity

Row6Struct:
	db &00 		;; X pos
	db &8B 		;; Y pos
	db &10 		;; Height
	db &0D 		;; Block Width
	db &0B 		;; Current LH square width
	db &02 		;; Current RH square width
	db %00000011 	;; Starting hue
	db 0		;; Velocity

Row7Struct:
	db &00 		;; X pos
	db &9e 		;; Y pos
	db &18 		;; Height
	db &0D 		;; Block Width
	db &08 		;; Current LH square width
	db &05  	;; Current RH square width
	db %00000000 	;; Starting hue
	db 0		;; Velocity

Row8Struct:
	db &00 		;; X pos
	db &B9 		;; Y pos
	db &1F 		;; Height	
	db &0D 		;; Block Width
	db &07 		;; Current LH square width
	db &06  	;; Current RH square width
	db %00000000 	;; Starting hue
	db 0		;; Velocity

Row9Struct:
	db &00 		;; X pos
	db &DB 		;; Y pos
	db &10 		;; Height
	db &0D 		;; Block Width
	db &0A 		;; Current LH square width
	db &03  	;; Current RH square width
	db %00000011 	;; Starting hue
	db 0		;; Velocity
	
Row10Struct:
	db &00 		;; X pos
	db &EE 		;; Y pos
	db &1C 		;; Height
	db &0D 		;; Block Width
	db &07 		;; Current LH square width
	db &06  	;; Current RH square width
	db %00000000 	;; Starting hue
	db 0		;; Velocity

;; Used during start up to save some repitition
RowSpinArray:
	dw Row6Struct
	dw Row5Struct
	dw Row4Struct
	dw Row3Struct
	dw Row2Struct
	dw Row1Struct
	db 0

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