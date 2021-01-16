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
    ; Store initial value of L in RAM
    ld [wInitialRegA], a

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

    ; Check if running in CGB mode
    ld a, [wInitialRegA]
    cp BOOTUP_A_CGB
    jp nz, ScreenNonCGB

    ; Jump to Selection Menu Initialization
    jp StartSelectionMenu

ScreenNonCGB::
    ; Initialize DMG Palette
    ld a, %11010100
    ld [rBGP], a

    ; Print CGB-only text to screen
    ld hl, (NonCGBPtrVRAM)
    ld de, strNonCGB1
    call PrintString
    ld hl, (NonCGBPtrVRAM + $40)
    ld de, strNonCGB2
    call PrintString
    ld hl, (NonCGBPtrVRAM + $80)
    ld de, strNonCGB3
    call PrintString

    ; Initialize LCD and clear IF/IE
    xor a
    ldh [rIF], a
    ldh [rIE], a
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG8000
    ldh [rLCDC], a
    ei
    nop 

    ; HALT infinitely
    halt

strNonCGB1: db "THIS SOFTWARE IS", 0
strNonCGB2: db "INTENDED FOR USE", 0
strNonCGB3: db "ON GAMEBOY COLOR", 0