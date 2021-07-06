# Optimisation

Using knowledge squeezed out of the pdf in [this forum post](http://www.cpcwiki.eu/forum/programming/craving-for-speed-a-visual-cheat-sheet-to-help-optimizing-your-code-to-death/)


tldr - the GateArray divides the 16mhz signal from the crystal down to 4mhz for the CPU, but in order to keep everything in sync, the GateArray throttles them so that they always arrive 1µs apart, giving an effective CPU speed of 3.3mhz

3,300,000 cycles per second
50 frames a second == 66,000 cycles per frame


Current cycles per frame: 539131
Gives me a measley 6 frames per second

## Task list

### Switch to 256 mode
No effect

### Switch to the fast frame flyback

### Implement Keith's fast block copy routine





