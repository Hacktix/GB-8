INCLUDE "inc/hardware.inc"
INCLUDE "inc/gb8.inc"

INCLUDE "src/data.asm"
INCLUDE "src/roms.asm"
INCLUDE "src/ram.asm"
INCLUDE "src/functions.asm"
INCLUDE "src/emu.asm"
INCLUDE "src/init/gfxinit.asm"
INCLUDE "src/init/emuinit.asm"
INCLUDE "src/selection.asm"

SECTION "Vectors", ROM0[0]
    ds $40 - @

VBlankVector::
    reti 

    ds $100 - @

SECTION "Entry Point", ROM0[$100]
    nop
    jr Main

    ; Pad header fields
    ds $150 - @

SECTION "Main", ROM0[$150]
Main::
    ; Wait for VBlank, disable LCD
    ldh a, [rLY]
	cp SCRN_Y
	jr c, Main
    xor a
    ld [rLCDC], a

    ; Disable Sound
    ld a, AUDENA_OFF
    ldh [rAUDENA], a
    
    ; Zero out VRAM tile data
    ld hl, $8000
    ld bc, $01A0
    call Zerofill

    ; Initialize Graphics
    call InitPalettes
    call InitFont

    ; Jump to Selection Menu Initialization
    jp StartSelectionMenu