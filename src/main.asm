INCLUDE "inc/hardware.inc"
INCLUDE "inc/gb8.inc"

INCLUDE "src/roms.asm"
INCLUDE "src/ram.asm"
INCLUDE "src/functions.asm"
INCLUDE "src/emu.asm"
INCLUDE "src/init/gfxinit.asm"
INCLUDE "src/init/emuinit.asm"

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
    
    ; Zero out VRAM tile data
    ld hl, $8000
    ld bc, $01A0
    call Zerofill

    ; Initialize Graphics
    call InitPalettes
    call InitFont

    ; Initialize Emulator Variables
    call InitSysvars
    call InitEmuVRAM

    ; Turn off Audio initially
    ld a, AUDENA_OFF
    ldh [rAUDENA], a

    ; Load ROM File
    ld hl, Airplane
    call InitROM

    ; Initialize Interrupts
    xor a
    ldh [rIF], a
    ld a, IEF_VBLANK
    ldh [rIE], a
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG8000
    ldh [rLCDC], a
    ei

    ; Initialize system variables and start emulator
    ld hl, wBaseMemory + $200          ; Load HL (= PC) with base pointer
    jp EmuLoop

SECTION "Graphics", ROM0
fontNumbers:
INCBIN "inc/font/numbers.bin"
endFontNumbers:

fontLetters:
INCBIN "inc/font/letters.bin"
endFontLetters:

borderTiles:
INCBIN "inc/gfx/border.bin"
endBorderTiles: