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
; 2nnn - CALL addr
; Call subroutine at nnn.
; ------------------------------------------------------------------------------
CallInstruction::
    pop hl
    ld d, h
    ld e, l
    call EmuPush
    ld a, b
    and $0F
    add HIGH(wBaseMemory)
    ld h, a
    ld l, c
    jp EmuLoop

; ------------------------------------------------------------------------------
; 3xkk - SE Vx, byte
; Skip next instruction if Vx = kk.
; ------------------------------------------------------------------------------
SkipEqualInstruction::
    ld a, b
    call EmuRegRead
    pop hl
    cp c
    jr nz, .notEqual
    inc hl
    inc hl
.notEqual
    jp EmuLoop

; ------------------------------------------------------------------------------
; 4xkk - SE Vx, byte
; Skip next instruction if Vx != kk.
; ------------------------------------------------------------------------------
SkipNotEqualInstruction::
    ld a, b
    call EmuRegRead
    pop hl
    cp c
    jr z, .isEqual
    inc hl
    inc hl
.isEqual
    jp EmuLoop

; ------------------------------------------------------------------------------
; 5xy0 - SE Vx, Vy
; Skip next instruction if Vx = Vy.
; ------------------------------------------------------------------------------
SkipEqualRegisterInstruction::
    ld a, b
    call EmuRegRead
    ld d, a
    ld a, c
    swap a
    call EmuRegRead
    pop hl
    cp d
    jr nz, .notEqual
    inc hl
    inc hl
.notEqual
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
; 7xkk - ADD Vx, byte
; Set Vx = Vx + kk.
; ------------------------------------------------------------------------------
AddInstruction::
    ld a, b
    call EmuRegRead
    add c
    ld [hl], a
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; Loads DE with Vx and Vy and calls the proper subroutine for any 8xyz instruction.
; ------------------------------------------------------------------------------
ArithmeticInstruction::
    ; Get pointer to Jump Table
    ld hl, ArithmeticJumpTable
    ld a, c
    and $0F
    add a
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld d, a
    ld h, d
    ld l, e

    ; Load DE with Vx and Vy
    push hl
    ld a, c
    swap a
    call EmuRegRead
    ld e, a
    ld a, b
    call EmuRegRead
    ld d, a
    pop hl

    ; Jump to jump table vector
    jp hl

ArithmeticJumpTable::
    dw RegisterLoadInstruction
    dw ArithmeticOR
    dw ArithmeticAND
    dw ArithmeticXOR
    dw ArithmeticADD
    dw ArithmeticSUB
    dw ArithmeticSHR
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw ArithmeticSHL
    dw DummyInstruction

; ------------------------------------------------------------------------------
; 8xy0 - LD Vx, Vy
; Set Vx = Vy.
; ------------------------------------------------------------------------------
RegisterLoadInstruction::
    ld a, b
    and $0F
    ld l, a
    ld a, HIGH(wRegV)
    ld h, a
    ld [hl], e
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; 8xy1 - OR Vx, Vy
; Set Vx = Vx OR Vy.
; ------------------------------------------------------------------------------
ArithmeticOR::
    or e
    ld d, a
    ld a, b
    and $0F
    ld l, a
    ld a, HIGH(wRegV)
    ld h, a
    ld [hl], d
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; 8xy2 - AND Vx, Vy
; Set Vx = Vx AND Vy.
; ------------------------------------------------------------------------------
ArithmeticAND::
    and e
    ld d, a
    ld a, b
    and $0F
    ld l, a
    ld a, HIGH(wRegV)
    ld h, a
    ld [hl], d
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; 8xy3 - XOR Vx, Vy
; Set Vx = Vx XOR Vy.
; ------------------------------------------------------------------------------
ArithmeticXOR::
    xor e
    ld d, a
    ld a, b
    and $0F
    ld l, a
    ld a, HIGH(wRegV)
    ld h, a
    ld [hl], d
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; 8xy4 - ADD Vx, Vy
; Set Vx = Vx + Vy, set VF = carry.
; ------------------------------------------------------------------------------
ArithmeticADD::
    ld a, b
    and $0F
    ld l, a
    ld a, HIGH(wRegV)
    ld h, a
    ld a, d
    add e
    ld [hl], a
    ld a, $0F
    ld l, a
    jr c, .setCarry
    ld a, 0
    jr .noCarry
.setCarry
    ld a, 1
.noCarry
    ld [hl], a
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; 8xy5 - SUB Vx, Vy
; Set Vx = Vx - Vy, set VF = NOT borrow.
; ------------------------------------------------------------------------------
ArithmeticSUB::
    ld a, b
    and $0F
    ld l, a
    ld a, HIGH(wRegV)
    ld h, a
    ld a, d
    sub e
    ld [hl], a
    ld a, $0F
    ld l, a
    jr nc, .noBorrow
    ld a, 0
    jr .setBorrow
.noBorrow
    ld a, 1
.setBorrow
    ld [hl], a
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; 8xy6 - SHR Vx {, Vy}
; Set Vx = Vx SHR 1.
; ------------------------------------------------------------------------------
ArithmeticSHR::
    ld a, b
    and $0F
    ld l, a
    ld a, HIGH(wRegV)
    ld h, a
    ld a, d
    srl a
    ld [hl], a
    ld a, $0F
    ld l, a
    jr c, .setLSB
    xor a
    jr .unsetLSB
.setLSB
    ld a, 1
.unsetLSB
    ld [hl], a
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; 8xyE - SHL Vx {, Vy}
; Set Vx = Vx SHL 1.
; ------------------------------------------------------------------------------
ArithmeticSHL::
    ld a, b
    and $0F
    ld l, a
    ld a, HIGH(wRegV)
    ld h, a
    ld a, d
    sla a
    ld [hl], a
    ld a, $0F
    ld l, a
    jr c, .setMSB
    xor a
    jr .unsetMSB
.setMSB
    ld a, 1
.unsetMSB
    ld [hl], a
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; 9xy0 - SNE Vx, Vy
; Skip next instruction if Vx != Vy.
; ------------------------------------------------------------------------------
SkipNotEqualRegisterInstruction::
    ld a, b
    call EmuRegRead
    ld d, a
    ld a, c
    swap a
    call EmuRegRead
    pop hl
    cp d
    jr z, .isEqual
    inc hl
    inc hl
.isEqual
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
; Dxyn - DRW Vx, Vy, nibble
; Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision.
; ------------------------------------------------------------------------------
DrawInstruction::
    ; TODO: Actually implement this.
    ; For now just here to not annoy me with breakpoints from the
    ; DummyInstruction references.
    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; Table containing jump vectors related to the upper 4 bits of the instruction.
; ------------------------------------------------------------------------------
InstrJumpTable::
    dw ZeroByteInstruction
    dw JumpInstruction
    dw CallInstruction
    dw SkipEqualInstruction
    dw SkipNotEqualInstruction
    dw SkipEqualRegisterInstruction
    dw LoadInstruction
    dw AddInstruction
    dw ArithmeticInstruction
    dw SkipNotEqualRegisterInstruction
    dw ILoadInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DrawInstruction
    dw DummyInstruction
    dw DummyInstruction

; ------------------------------------------------------------------------------
; Stores the value of emulated register V[A & $0F] in register A.
; ------------------------------------------------------------------------------
EmuRegRead::
    and $0F
    ld l, a
    ld a, HIGH(wRegV)
    ld h, a
    ld a, [hl]
    ret

; ------------------------------------------------------------------------------
; Pops a 16-bit value off the emulated stack onto DE.
; ------------------------------------------------------------------------------
EmuPop::
    ; Decrement SP and get pointer to top of stack
    ld a, [wSP]
    dec a
    ld [wSP], a
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

; ------------------------------------------------------------------------------
; Pushes a 16-bit value from DE onto the emulated stack.
; ------------------------------------------------------------------------------
EmuPush::
    ; Get pointer to top of stack
    ld a, [wSP]
    add a
    add LOW(wStack)
    ld l, a
    adc HIGH(wStack)
    sub l
    ld h, a

    ; Load data from DE into stack and return
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a

    ; Increment SP and return
    ld a, [wSP]
    inc a
    ld [wSP], a
    ret