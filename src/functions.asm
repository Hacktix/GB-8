SECTION "Functions", ROM0
; ------------------------------------------------------------------------------
; Copies a memory section of sice BC pointed to by DE to HL.
; ------------------------------------------------------------------------------
Memcpy::
    ld a, [de]
    inc de
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, Memcpy
    ret

; ------------------------------------------------------------------------------
; Fills BC bytes with zero, starting at HL.
; ------------------------------------------------------------------------------
Zerofill::
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, Zerofill
    ret

; ------------------------------------------------------------------------------
; Fills BC bytes starting from HL with the value D.
; ------------------------------------------------------------------------------
Memfill::
    ld a, d
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, Memfill
    ret

; ------------------------------------------------------------------------------
; Prints the string at DE to VRAM starting at HL.
; ------------------------------------------------------------------------------
PrintString::
    ld a, [de]
    inc de
    and a
    ret z
    cp $20
    jr nz, .noSpace
    inc hl
    jr PrintString
.noSpace
    add $50
    ld [hli], a
    jr PrintString

; ------------------------------------------------------------------------------
; Starts reading a ROM file entry at HL and initializes the emulator
; for it.
; ------------------------------------------------------------------------------
InitROM::
    ; Loop until string-terminating zero-byte is reached
    ld a, [hli]
    and a
    jr nz, InitROM

    ; Load emulation speed into RAM
    ld a, [hli]
    ld [wCycleLimit], a

    ; Load Button Mapping into RAM
    ld c, 8
    ld b, %10000000

.buttonMappingInitLoop
    ; Check if button mapping is valid
    ld a, [hli]
    cp $10
    jr nc, .unmappedButton

    ; Load pointer to proper input mask byte
    add LOW(wInputMaskMap)
    ld e, a
    adc HIGH(wInputMaskMap)
    sub e
    ld d, a

    ; Load input mask byte into RAM
    ld a, b
    ld [de], a

.unmappedButton
    ; Update mask byte for next button
    srl b

    ; Check if all 8 buttons were mapped, loop if not
    dec c
    jr nz, .buttonMappingInitLoop

    ; Preserve HL
    push hl

    ; Load Fontset into memory
    ld hl, wBaseMemory
    ld de, Fontset
    ld bc, EndFontset - Fontset
    call Memcpy

    ; Fill memory with zero up to $200
    ld bc, ($200 - (EndFontset - Fontset))
    call Zerofill

    ; Restore HL, load ROM data size and call Memcpy
    pop hl
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a
    ld d, h
    ld e, l
    ld hl, wBaseMemory + $200
    call Memcpy

    ; Initialization done - return
    ret