SECTION "Emulator Code", ROM0
EmuLoop::
    ; Wait for VBlank
    halt 
    nop

    ; Debug Breakpoint
    ld b, b

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
    push de
    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld h, a
    ld l, e
    pop de

    ; Load high instruction byte into A and jump to instruction routine
    ld a, b
    jp hl

DummyInstruction::
    pop hl
    jp EmuLoop

JumpInstruction::
    pop hl
    and $0F
    add HIGH(wBaseMemory)
    ld h, a
    ld l, c
    jp EmuLoop

InstrJumpTable::
    dw DummyInstruction
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