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
	
	call DrawScreen
	call MC_WAIT_FLYBACK
	call SwitchScreenBuffer
jp MainLoop
	
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

DrawScreen:
	di
	call DrawBackground
	;call DrawPlayer
	ei
ret

DrawBackground:
	; for now, just draw an empty background
	call ClearScreen
ret

ClearScreen:
	ld hl,(BackBufferAddress)
	ld de,(BackBufferAddress)
	inc de
	ld bc,ScreenSize-1
	ld (hl),0
	ldir
ret
DrawPlayer:	
	DoPlayerDrawing:
		ld bc,(CursorCurrentPosXY)
		call GetScreenPos
		;ld de,(PickleCurrentFrame)
		ld b,56 ; Lines
		ld c,12 ; Bytes per line
	
DrawSprite:
	;; Inputs: 
	;; 	DE - Frame address
	;; 	HL - Screen address 	
	;; 	B  - Lines per sprite
	;; 	C  - Bytes per line
	SpriteNextLine:
		push hl
		push bc
	SpriteNextByte:
			ld a,(de)	; Sourcebyte	
			ld (hl),a	; Screen desintation

			inc de
			inc hl
			dec c
			jr nz,SpriteNextByte
		pop bc
		pop hl
	call GetNextLine 		; expected - c051, C0A1, C0F1.. last C9e1
	djnz SpriteNextLine 		; djnz - decreases b and jumps when it's not zero
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

;****************************************
; Variables
;****************************************
ScreenStartAddressFlag:	db 48  		; 16 = &4000 48 = &C000 
ScreenOverflowAddress: 	dw &7FFF
BackBufferAddress: 	dw &4000 
FrameCounter: 		db 0

CursorCurrentPosXY:	dw &0000		; Player xy pos

read ".\libs\CPC_V1_SimpleScreenSetUp.asm"
read ".\libs\CPC_V1_SimplePalette.asm"

;****************************************
; Resources
;****************************************
