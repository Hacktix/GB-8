SECTION "Emulator Code", ROM0
EmuLoop::
    ; Wait for VBlank
    halt 
    nop

    ; Read instruction into BC
    ld a, [hli]
    ld b, a
    ld a, [hli]
    ld c, a
    push hl

    ; Load HL with jump table address
    ld a, b
    and $F0
    swap a
    add a
    add LOW(InstrJumpTable)
    ld l, a
    adc HIGH(InstrJumpTable)
    sub l
    ld h, a

    ; Load instruction routine pointer into HL
    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld h, a
    ld l, e

    ; Jump to instruction routine
    jp hl

DummyInstruction::
    pop hl
    jp EmuLoop

ZeroByteInstruction::
    ld a, c
    cp $E0
    jr z, ClearDisplayInstruction

ReturnInstruction::
    ; Pop off Emulated stack onto HL
    call EmuPop
    pop hl
    ld h, d
    ld l, e
    jp EmuLoop

ClearDisplayInstruction::
    ; TODO: Implement Properly
    pop hl
    jp EmuLoop

JumpInstruction::
    pop hl
    ld a, b
    and $0F
    add HIGH(wBaseMemory)
    ld h, a
    ld l, c
    jp EmuLoop

InstrJumpTable::
    dw ZeroByteInstruction
    dw JumpInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction

; ------------------------------------------------------------------------------
; Pops a 16-bit value off the emulated stack onto DE.
; ------------------------------------------------------------------------------
EmuPop::
    ; Get pointer to top of stack and decrement SP
    ld a, [wSP]
    dec a
    ld [wSP], a
    inc a
    add a
    add LOW(wStack)
    ld l, a
    adc HIGH(wStack)
    sub l
    ld h, a

    ; Load data from stack into DE and return
    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld d, a
    ret