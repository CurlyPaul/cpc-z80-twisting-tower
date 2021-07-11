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
simplest thing is to know the row width

#### hacky POC shows a max of 87709 cycles per draw!! 

Proposal:

Modifiy DrawSquare so that it only draws the one line and does not reset the scr pos
Draw row then takes responsibility of drawing the black lines, as it's already testing for reseting the left and right hand squares
Draw row then block copies that line Height - 1 times


as ldir insists that de has the scr pos, would it be worth changing GetNextLine and GetScreenPos to operate over DE rather than HL first?

