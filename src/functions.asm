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