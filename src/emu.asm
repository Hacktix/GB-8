SECTION "Emulator Code", ROM0
; ------------------------------------------------------------------------------
; Main loop of the emulator, runs a certain amount of emulated cycles each
; frame.
; ------------------------------------------------------------------------------
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

; ------------------------------------------------------------------------------
; Placeholder for unimplemented instructions - does absolutely nothing other
; than triggering an emulator breakpoint using LD b, b.
; ------------------------------------------------------------------------------
DummyInstruction::
    pop hl
    ld b, b
    jp EmuLoop

; ------------------------------------------------------------------------------
; Checks the low byte of the instruction to check what to actually do.
; ------------------------------------------------------------------------------
ZeroByteInstruction::
    ld a, c
    cp $E0
    jr z, ClearDisplayInstruction

; ------------------------------------------------------------------------------
; 00EE - RET
; Return from a subroutine.
;
; The interpreter sets the program counter to the address at the top of the
; stack, then subtracts 1 from the stack pointer.
; ------------------------------------------------------------------------------
ReturnInstruction::
    ; Pop off Emulated stack onto HL
    call EmuPop
    pop hl
    ld h, d
    ld l, e
    jp EmuLoop

; ------------------------------------------------------------------------------
; 00E0 - CLS
; Clear the display.
; ------------------------------------------------------------------------------
ClearDisplayInstruction::
    ; TODO: Implement Properly
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; 1nnn - JP addr
; Jump to location nnn.
; ------------------------------------------------------------------------------
JumpInstruction::
    pop hl
    ld a, b
    and $0F
    add HIGH(wBaseMemory)
    ld h, a
    ld l, c
    jp EmuLoop
    
; ------------------------------------------------------------------------------
; 6xkk - LD Vx, byte
; Set Vx = kk.
; ------------------------------------------------------------------------------
LoadInstruction::
    ld a, b
    and $0F
    ld l, a
    ld a, HIGH(wRegV)
    ld h, a
    ld [hl], c
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; Annn - LD I, addr
; Set I = nnn.
; ------------------------------------------------------------------------------
ILoadInstruction::
    ld hl, wRegI
    ld a, b
    and $0F
    ld [hli], a
    ld [hl], c
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; Table containing jump vectors related to the upper 4 bits of the instruction.
; ------------------------------------------------------------------------------
InstrJumpTable::
    dw ZeroByteInstruction
    dw JumpInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw LoadInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw ILoadInstruction
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