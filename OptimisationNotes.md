# Optimisation

Using knowledge squeezed out of the pdf in [this forum post](http://www.cpcwiki.eu/forum/programming/craving-for-speed-a-visual-cheat-sheet-to-help-optimizing-your-code-to-death/)


tldr - the GateArray divides the 16mhz signal from the crystal down to 4mhz for the CPU, but in order to keep everything in sync, the GateArray throttles them so that they always arrive 1µs apart, giving an effective CPU speed of 3.3mhz

3,300,000 cycles per second
50 frames a second == 66,000 cycles per frame


Current cycles per draw cycle: 519372
Gives me a measley 6 frames per second

## Task list

### Switch to 256 mode
No effect

### Remove some pointless commands
506000 cycles per draw
440000

### Switch to the fast frame flyback
Still 440000

### Implement Keith's fast block copy routine
420000

### Restructure DrawSquare
348000 - up to 9 frames per second!!


### Eliminate draw block

Problem I had before...

If I draw the black line on the left of the square...

xxxxx|Bxxxxxx|Bxxxxxx|Bxxxx

then I add the complexity of deciding if I should draw the last one or not
simplest thing is to know the row width.


#### hacky POC shows a max of 87709 cycles per draw!! 

- this still didn't pan out as the rules for the LH and RH square are different but it did unearth this idea

Proposal:

Modifiy DrawSquare so that it only draws the one line and does not reset the scr pos
Draw row then takes responsibility of drawing the black lines, as it's already testing for reseting the left and right hand squares
Draw row then block copies that line Height - 1 times


as ldir insists that de has the scr pos, would it be worth changing GetNextLine and GetScreenPos to operate over DE rather than HL first?

Questions to answer first...

Is ldir faster than just copying it in a normal loop? 
  Yes it is, about twice as fast on the current byte set

Is the 16+8 bit addition on that website faster or slower than push hl/pop to de?
  - Yes it is, about twice as fast when considerig the pusp/pop that we won't need on bc

  - This means that GetNextLine can be changed to write the results to DE
  - Untrue actually, the screen address requires true 16 bit operations to work as intended

    
  

Is pushing and popping faster than moving just two pairs of registers?
    No, but may be useful if you don't have spare registers




DrawRowV2


DrawRowV2:
	;; Set the starting colour
    Need a 16bit register, but they are all free atm

    ;; Call GetNextLine - which returns value to DE

	;; In this context, draw only draws one line to the screen	
	;; Draw the RH square, including the black line if needed
    ;; Will need DE(scr pos) preserved during draw square, or could may just rest it, time this

	;; Given IY contains a row width 
	;; create a loop that draws squares until we run out of width

	;; Draw the LH square, including the black line if needed

	;; Copy the above row down the screen

### DrawRowV2 implemented

72118 cycles per draw... for a maximum of 45 frames
BUT still need to put the dividing lines back and put the sheen right

## Copleting tidy up

66885.. so close!!