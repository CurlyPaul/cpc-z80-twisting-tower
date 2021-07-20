;;
;
;  For each row... 
;  Check it's current index
;  Load the value from this list below into the row structures
;
;;

I want to be able to animate....
XPos
YPos
Velocity
Height

I want to be able to turn the aimations on or off as time passes




;; Imagine this is a sine wave around zero or something
XPosScript:
	db &0C
	db &0D
	db &0E
	db &0D
	db &0C
	db &0B
	db &0A
	db &00 	;; zero to terminate it? Means 0 is not a valid value.. how else could I control this?
			;; Use 127??? yPos is going to use this though - unless I can do this as an offset to it's base location? 

;; How do I indicate which part of this cycle the current row is in??

Row1Struct:
	Xpos: blah blah
	AnimationToggle: %0000 0001 <- if bit set set, animate the appropiate property maybe the top byte is the current position in the animation script above?? Might be 									difficult to increment? other way around maybe?

Row1StructScript:
	00000001
	00000001
	00001001
	00000101  <- Change the animation byte in each struct to this value on each tick?? What if the high byte related to the number of frame ticks to cycle the animation 				for? 
				 That's another counter that needs to live for a long time though

MainLoop:

	bit X, FrameCounter ?? Maybe? if needed

