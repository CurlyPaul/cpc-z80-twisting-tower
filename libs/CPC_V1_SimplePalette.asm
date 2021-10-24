;;********************************************************************************************
;; Originally based an example at http://www.cpcwiki.eu/index.php/Programming An_example_loader
;;********************************************************************************************

ColourPalette: ; hardware colours

defb &44 ;; #0 Darkest Blue 
defb &55 ;; #1 Blue 
defb &57 ;; #2 Blue 
defb &5B ;; #3 Brightest Blue
defb &4B ;; #4 White
defb &5B ;; #5
defb &53 ;; #6
defb &5E ;; #7 
defb &58 ;; #8 Darkest Purple
defb &5D ;; #9 Purple
defb &5F ;; #10 Purple
defb &5B ;; #11 Brightest Purple (actually blue looks best here)
defb &4B ;; #12 Another white
defb &4C ;; #13
defb &54 ;; #14 Black
defb &46 ;; #15 Background
defb &46 ;; Border

Palette_Init:
	;; CPC has some quirks here as well, seems to be caused by the ability to flash each colour
	;;
	;; http://www.cpcwiki.eu/forum/programming/screen-scrolling-and-ink-commands/
	;; https://www.cpcwiki.eu/forum/programming/bios-call-scr_set_ink-and-interrupts/
	ld hl,ColourPalette
	call SetupColours
ret

Palette_AllBackground:
	ld b,17			;; 16 colours + 1 border
	xor a			;; start with pen 0
	ld e,&46
DoColours_AllBlack:
	push bc			;; need to stash b as we are using it for our loop and need it
				;; below to write to the port 		
	
		ld bc,&7F00
     		out (c),a	;; PENR:&7F{pp} - where pp is the palette/pen number 
		out (c),e	;; INKR:&7F{hc} - where hc is the hardware colour number
	pop bc
	inc a			;; increment pen number
	djnz DoColours_AllBlack
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