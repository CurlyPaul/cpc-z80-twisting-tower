;****************************************
; Header
;****************************************
ScreenSize equ &4000
MC_WAIT_FLYBACK equ &BD19

org &8000

call Screen_Init
call Palette_Init

;****************************************
; Main Program
;****************************************
MainLoop:
	call DrawBackground

	ld iy,Row1Template
	call DrawRow
	ld iy,Row2Template
	;;call DrawRow
	ld iy,Row3Template
	;;call DrawRow
	ld iy,Row4Template
	;;call DrawRow

	call MC_WAIT_FLYBACK
	call SwitchScreenBuffer
jp MainLoop
	
DrawBackground:
	; for now, just draw an empty background
	call ClearScreen
ret

ClearScreen:
	push de
		ld hl,(BackBufferAddress)
		ld de,(BackBufferAddress)
		inc de
		ld bc,ScreenSize-1
		ld (hl),0
		ldir
	pop de
ret

DrawRow:
	;; INPUTS
	;; IY Row struct
	ld b,(iy+0)	;; X
	ld c,(iy+1)	;; Y
	ld d,(iy+2)	;; H
	ld e,(iy+4)	;; W
	dec e
	bit 7,e
	jr z,SkipLeftReset
	ld e,(iy+3)	;; Starting width
SkipLeftReset:
	ld (iy+4),e
	call DrawSquare

	;; The X pos of this one needs to be sqOne.xPos + sqOne.W + Space
	ld a,b
	add e
	inc a
	ld b,a
	ld e,(iy+3)
	call DrawSquare

	ld a,b
	add e
	inc a
	ld b,a
	ld e,(iy+3)
	call DrawSquare
	
	ld a,b
	add e
	inc a
	ld b,a
	;; For the final square the width starts at zero
	ld e,(iy+5)
	inc e

	;; Check if it's larger than the starting width
	
	ld a,e
	cp &0E
	jr c,SkipRightReset 	
	ld e,&00
	SkipRightReset:
	ld (iy+5),e
	call DrawSquare
	
ret

DrawSquare:
	;; INPUTS
	;; bc (x,y)
	;; de Height, Width
	ld a,e
	cp 0
	ret z
	bit 7,e
	ret nz

	push bc
	push de
		call GetScreenPos 	;; HL = screen position
		ld b,d ; Height in lines
		ld c,e ; Width in Bytes
		SquareNextLine:
			push hl
			push bc
		SquareNextByte:
			ld a,%11110000	; Sourcebyte	
			ld (hl),a	;; A = Screen desintation
			inc de
			inc hl
			dec c
			jr nz,SquareNextByte
			pop bc
			pop hl
		call GetNextLine 		
		djnz SquareNextLine	;; djnz - decreases b and jumps when it's not zero
	pop de
	pop bc
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

;****************************************
; Variables
;****************************************
ScreenStartAddressFlag:	db 48  		; 16 = &4000 48 = &C000 
ScreenOverflowAddress: 	dw &7FFF
BackBufferAddress: 	dw &4000 
FrameCounter: 		db 0

Row1Template:
	db &0F ;; X pos
	db &00 ;; Y pos
	db &30 ;; Height
	db &0D ;; Width
	db &0D ;; Current LH square width
	db &0  ;; Current RH square width

Row2Template:
	db &0F ;; X pos
	db &43 ;; Y pos
	db &30 ;; Height
	db &0D ;; Width
	db &06 ;; Current LH square width
	db &07 ;; Current RH square width


Row3Template:
	db &0F ;; X pos
	db &76 ;; Y pos
	db &10 ;; Height
	db &0D ;; Width
	db &0D ;; Current LH square width
	db &0  ;; Current RH square width

Row4Template:
	db &0F ;; X pos
	db &89 ;; Y pos
	db &30 ;; Height
	db &0D ;; Width
	db &06 ;; Current LH square width
	db &07 ;; Current RH square width


read ".\libs\CPC_V1_SimpleScreenSetUp.asm"
read ".\libs\CPC_V1_SimplePalette.asm"

;****************************************
; Resources
;****************************************
