INCLUDE "inc/hardware.inc"
INCLUDE "src/roms.asm"
INCLUDE "src/ram.asm"
INCLUDE "src/functions.asm"

SECTION "Vectors", ROM0[0]
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

    ; Load Fontset into memory
    ld hl, wBaseMemory
    ld de, Fontset
    ld bc, EndFontset - Fontset
    call Memcpy

    ; Fill memory with zero up to $200
    ld bc, ($200 - (EndFontset - Fontset))
    call Zerofill

    ; Load ROM into memory
    ld de, TestROM
    ld bc, EndTestROM - TestROM
    call Memcpy

    ; Fill rest of memory with zero
    ld bc, ($1000 - $200 - (TestROM - EndTestROM))
    call Zerofill

    jr @

