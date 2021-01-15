SECTION "Emulator Initialization Code", ROM0

; ------------------------------------------------------------------------------
; Initializes all emu-relevant system variables
; ------------------------------------------------------------------------------
InitSysvars::
    ld hl, _start_sysvars
    ld bc, _end_sysvars - _start_sysvars
    call Zerofill
    xor a
    ld [wCycleBuf], a
    ld [wSprOverflow], a
    ld [wSprOverflowY], a
    ret

; ------------------------------------------------------------------------------
; Initializes VRAM as well as emuVRAM
; ------------------------------------------------------------------------------
InitEmuVRAM::
    ; Clear EmuVRAM
    ld hl, wBaseVRAM
    ld bc, wEndVRAM - wBaseVRAM
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
    ld hl, EmuScreenPtrVRAM
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

    ; Set emulator to update VRAM on first frame
    ld a, 1
    ld [wUpdateDisplay], a

    ; Fall-through to Emulator Display Border initialization

; ------------------------------------------------------------------------------
; Loads emulator screen border tiles into VRAM
; ------------------------------------------------------------------------------
InitEmuBorder::
    ; Load Border Tiles
    ld hl, $8B00
    ld de, borderTiles
    ld bc, endBorderTiles - borderTiles
    call Memcpy

    ; Load top border into map
    ld hl, (EmuScreenPtrVRAM - $21)
    ld d, $B0
    ld a, d
    ld [hli], a
    inc d
    ld bc, $0010
    call Memfill
    inc d
    ld a, d
    ld [hl], a

    ; Load side borders into map
    ld hl, (EmuScreenPtrVRAM-1)
    ld de, $B708
.sideBordersLoop
    ld a, d
    ld [hli], a
    sub $04
    ld d, a
    ld a, l
    add $10
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, d
    ld [hli], a
    add $04
    ld d, a
    ld a, l
    add $0E
    ld l, a
    adc h
    sub l
    ld h, a
    dec e
    jr nz, .sideBordersLoop

    ; Load bottom border into map
    ld d, $B6
    ld a, d
    ld [hli], a
    dec d
    ld bc, $0010
    call Memfill
    dec d
    ld a, d
    ld [hl], a

    ; Load "CHIP 8" text
    ld hl, $9967
    ld de, strChip8
    call PrintString

    ret

strChip8: db "CHIP 8", 0

; ------------------------------------------------------------------------------
; Loads the game title from HL and centers it on screen below the emulator
; display screen.
; ------------------------------------------------------------------------------
InitGameTitleDisplay::
    ; Load horizontal offset into B, string pointer into DE
    push hl
    call Strln
    ld a, d
    srl a
    ld b, a
    pop de

    ; Offset HL by B
    ld a, LOW(GameTitlePtrVRAM)
    sub b
    ld l, a
    ld h, HIGH(GameTitlePtrVRAM)
    jr nc, .skipOffsetCarry
    dec h
.skipOffsetCarry

    ; Print String
    jp PrintString