;;***************************************
;; Origially based an example at http://www.cpcwiki.eu/index.php/Programming An_example_loader
;;***************************************

ColourPalette: ; hardware colours
defb &54,&42,&56,&4A,&4C,&5E,&4E,&5E,&5E,&4C,&4C,&4C,&4C,&4C,&4C,&4B,&54

Palette_Init:
	;; CPC has some quirks here as well, seems to be caused by the ability to flash each colour
	;;
	;; http://www.cpcwiki.eu/forum/programming/screen-scrolling-and-ink-commands/
	;; https://www.cpcwiki.eu/forum/programming/bios-call-scr_set_ink-and-interrupts/
	;; di for safety
	;di
	ld hl,ColourPalette
	call SetupColours
	;; but for this to work, make sure these values are left in the shadow registers
	;; so we've only got one switch in here
	;exx
	;ei
ret

SetupColours:
	;; Inputs: HL Address the palette values are stored
	ld b,17			;; 16 colours + 1 border
	xor a			;; start with pen 0

DoColours:
	push bc			;; need to stash b as we are using it for our loop and need it
				;; below to write to the port 		
		ld e,(hl)	;; read the value of the colour we want into e
		inc hl          ;; move along ready for next time

		ld bc,&7F00
     		out (c),a	;; PENR:&7F{pp} - where pp is the palette/pen number 
		out (c),e	;; INKR:&7F{hc} - where hc is the hardware colour number
	pop bc
	inc a			;; increment pen number
	djnz DoColours
ret