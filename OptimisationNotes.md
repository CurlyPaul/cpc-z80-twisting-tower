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






