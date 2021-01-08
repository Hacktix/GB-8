INCLUDE "inc/hardware.inc"
INCLUDE "src/roms.asm"
INCLUDE "src/ram.asm"
INCLUDE "src/functions.asm"
INCLUDE "src/emu.asm"

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

    ; Clear system variables
    ld hl, _start_sysvars
    ld bc, _end_sysvars - _start_sysvars
    call Zerofill

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

