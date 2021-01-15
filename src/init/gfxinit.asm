SECTION "Graphics Initialization Code", ROM0

; ------------------------------------------------------------------------------
; Initializes CGB Palette registers
; ------------------------------------------------------------------------------
InitPalettes::
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
    ret

; ------------------------------------------------------------------------------
; Loads font tiles into VRAM
; ------------------------------------------------------------------------------
InitFont::
    ld hl, $8800
    ld de, fontNumbers
    ld bc, endFontNumbers - fontNumbers
    call Memcpy
    ld hl, $8910
    ld de, fontLetters
    ld bc, endFontLetters - fontLetters
    call Memcpy
    ret