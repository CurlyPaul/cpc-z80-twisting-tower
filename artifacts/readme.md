## Output the raw asm to a bin

Open main.asm in Winape and uncomment the following line

    write ".\artifacts\tower.bin"

## Create a loader

Load the txt file into winape, or just type it
Add a new disk and format it, must be DSK format

In the emulator type:

    SAVE"loader.bas"

Close winape to make it flush the disk

Extract the .BAS file using CPCDiskXP

## Create a CDT File

Run the BAT file to use 2CDT to create a CDT image

## Convert to WAV

Using Wav2CDT, create a WAV file, which should have the correct pauses in it