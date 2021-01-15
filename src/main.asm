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

    ; Clear system variables
    ld hl, _start_sysvars
    ld bc, _end_sysvars - _start_sysvars
    call Zerofill
    xor a
    ld [wCycleBuf], a

    ; Clear EmuVRAM
    ld hl, wBaseVRAM
    ld bc, wEndVRAM - wBaseVRAM
    call Zerofill
    xor a
    ld [wSprOverflow], a

    ; Initialize Palettes
    ld a, BCPSF_AUTOINC
    ldh [rBCPS], a
    xor a
    ldh [rBCPD], a
    ldh [rBCPD], a
    dec a
    ldh [rBCPD], a
    ldh [rBCPD], a
    inc a
    ldh [rBCPD], a
    ldh [rBCPD], a

    ; Zero out VRAM tile data
    ld hl, $8000
    ld bc, $01A0
    call Zerofill

    ; Initialize tiles to $FF
    ld hl, $9800
.screenClearLoop
    ld a, $ff
    ld [hli], a
    ld a, h
    cp $9a
    jr nz, .screenClearLoop
    ld a, l
    cp $34
    jr nz, .screenClearLoop

    ; Initialize screen section tiles
    ld hl, $9822
    xor a
    ld bc, $1008
.screenSectionInitLoop
    ld [hli], a
    inc a
    dec b
    jr nz, .screenSectionInitLoop
    push af
    ld a, $10
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    pop af
    ld b, $10
    dec c
    jr nz, .screenSectionInitLoop

    ; Load Font Tiles
    ld hl, $8800
    ld de, fontNumbers
    ld bc, endFontNumbers - fontNumbers
    call Memcpy
    ld hl, $8910
    ld de, fontLetters
    ld bc, endFontLetters - fontLetters
    call Memcpy

    ; Turn off Audio initially
    ld a, AUDENA_OFF
    ldh [rAUDENA], a

    ; Load ROM File
    ld hl, Airplane
    call InitROM

    ; Set emulator to update VRAM on first frame
    ld a, 1
    ld [wUpdateDisplay], a

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

SECTION "Text Data", ROM0
fontNumbers:
INCBIN "inc/font/numbers.bin"
endFontNumbers:

fontLetters:
INCBIN "inc/font/letters.bin"
endFontLetters: