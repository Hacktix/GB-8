SECTION "Emulator Code", ROM0
; ------------------------------------------------------------------------------
; Main loop of the emulator, runs a certain amount of emulated cycles each
; frame.
; ------------------------------------------------------------------------------
EmuLoop::
    ; Check if cycles per frame have been exhausted
    ld a, [wCycleBuf]
    and a
    jr nz, .noScreenUpdate

    ; Wait for VBlank
    halt 

    ; Update Delay Timer
    ld a, [wRegDelay]
    and a
    jr z, .zeroDT
    dec a
    ld [wRegDelay], a
.zeroDT

    ; Reset cycle buffer
    ld a, 1
    ld [wCycleBuf], a
    
    ; Check if display was updated
    ld a, [wUpdateDisplay]
    and a
    jr z, .noScreenUpdate

    ; Initialize HDMA
    ld a, HIGH(wBaseVRAM)
    ldh [rHDMA1], a
    ld a, LOW(wBaseVRAM)
    ldh [rHDMA2], a
    xor a
    ldh [rHDMA3], a
    ldh [rHDMA4], a
    ld a, (wEndVRAM - wBaseVRAM) / $10 - 1
    ldh [rHDMA5], a

    ; Reset display update flag
    xor a
    ld [wUpdateDisplay], a
.noScreenUpdate

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

    ; Decrement cycle buffer
    ld a, [wCycleBuf]
    dec a
    ld [wCycleBuf], a

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
    ld hl, wBaseVRAM
    ld bc, wEndVRAM - wBaseVRAM
.clsLoop
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .clsLoop

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
    dw ArithmeticSUBN
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
; 8xy7 - SUBN Vx, Vy
; Set Vx = Vy - Vx, set VF = NOT borrow.
; ------------------------------------------------------------------------------
ArithmeticSUBN::
    ld a, b
    and $0F
    ld l, a
    ld a, HIGH(wRegV)
    ld h, a
    ld a, e
    sub d
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
; Cxkk - RND Vx, byte
; Set Vx = random byte AND kk.
; ------------------------------------------------------------------------------
RandomInstruction::
    ld a, b
    and $0F
    ld l, a
    ld h, HIGH(wRegV)

    ld a, c
    and $0F
    ld d, a
    ldh a, [rDIV]
    and d
    ld [hl], a

    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; Dxyn - DRW Vx, Vy, nibble
; Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision.
; ------------------------------------------------------------------------------
DrawInstruction::
    ; Load sprite size into RAM
    ld a, c
    and $0F
    inc a
    ld [wSpriteSize], a

    ; Load X into B and Y into C
    ld a, b
    call EmuRegRead
    and 63
    ld b, a
    ld a, c
    swap a
    call EmuRegRead
    and 31
    ld c, a

    ; Load HL with VRAM base pointer and add Y-offset
    ld hl, wBaseVRAM
    ld e, c       ; Load into E for temporary modification
    ld a, e
    and %11111000 ; Divide by 8 for tile-based offset
    srl a
    srl a
    srl a
    ld e, a
    inc e
.baseOffsetLoopY8
    dec e
    jr z, .endOffsetY8
    ld a, l
    add 128
    ld l, a
    adc h
    sub l
    ld h, a
    jr .baseOffsetLoopY8
.endOffsetY8
    ld a, c
    and 7         ; Mod 8 for row-based offset
    add a
    add l
    ld l, a
    adc h
    sub l
    ld h, a

    ; Add X-offset to HL
    ld d, b       ; Load into D for temporary modification
    ld a, d
    and %11111000 ; Divide by 8 for tile-based offset
    srl a
    srl a
    srl a
    ld d, a
    inc d
.baseOffsetLoopX8
    dec d
    jr z, .endOffsetX8
    ld a, l
    add 16
    ld l, a
    adc h
    sub l
    ld h, a
    jr .baseOffsetLoopX8
.endOffsetX8

    ; Load bitmask into E
    ld a, b
    and 7        ; Mod 7 for pixel-based offset
    ld d, a
    ld e, %10000000
    inc d
.baseOffsetLoopX1
    dec d
    jr z, .endOffsetX1
    srl e
    jr .baseOffsetLoopX1
.endOffsetX1

    ; Load sprite pointer into BC
    ld a, [wRegI+1]
    ld c, a
    ld a, [wRegI]
    and $0F
    or $C0
    ld b, a

    ; XOR sprite into VRAM
.spriteLoadLoop
    ld a, [wSprOverflow]
    and a
    jr z, .noResetOverflow
    xor a
    ld [wSprOverflow], a
    ld a, l
    sub 16
    ld l, a
    jr nc, .noResetOverflow
    dec h
.noResetOverflow
    ld a, [wSpriteSize]
    dec a
    ld [wSpriteSize], a
    jr z, .endSpriteDraw
    push de
    ld a, [bc]
.spriteXorLoop
    bit 7, a
    jr z, .spriteZeroBit ; Bit can be ignored if zero
    ld d, a
    ld a, [hl]
    ; TODO: Check for collision
    xor e
    ld [hl], a
    ld a, d
.spriteZeroBit
    srl e
    jr nz, .noTileSwitchX
    ; Switch to drawing on next tile (horizontal)
    ld d, a
    ld a, 1
    ld [wSprOverflow], a
    ld e, %10000000
    ld a, l
    add 16
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, d
.noTileSwitchX
    sla a
    jr nz, .spriteXorLoop
    ; Run when current sprite byte is fully drawn
    inc bc
    inc hl
    inc hl
    ld d, a
    ld a, l
    and $0F
    jr nz, .noTileSwitchY
    ; Switch to drawing on next tile (vertical)
    ld a, l
    add 7*16
    ld l, a
    adc h
    sub l
    ld h, a
.noTileSwitchY
    ld a, d
    pop de
    jr .spriteLoadLoop
.endSpriteDraw

    ; Set display update flag
    ld a, 1
    ld [wUpdateDisplay], a

    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; Jumps to the instruction handler for Fxxx instructions.
; ------------------------------------------------------------------------------
FInstruction::
    ld a, c
    and $0F
    add a
    add LOW(FJumpTable)
    ld l, a
    adc HIGH(FJumpTable)
    sub l
    ld h, a

    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld h, a
    ld l, e
    jp hl

FJumpTable::
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw BCDInstruction
    dw DummyInstruction
    dw F5Instruction
    dw DummyInstruction
    dw LoadRegDTInstruction
    dw DummyInstruction
    dw LoadDigitPtrInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw IAddInstruction

; ------------------------------------------------------------------------------
; Jumps to the instruction handler for Fxx5 instructions.
; ------------------------------------------------------------------------------
F5Instruction::
    ld a, c
    swap a
    and $0F
    add a
    add LOW(F5JumpTable)
    ld l, a
    adc HIGH(F5JumpTable)
    sub l
    ld h, a

    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld h, a
    ld l, e
    jp hl

F5JumpTable::
    dw DummyInstruction
    dw LoadDTInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw DummyInstruction
    dw StoreRegistersInstruction
    dw LoadRegistersInstruction

; ------------------------------------------------------------------------------
; Fx07 - LD Vx, DT
; Set Vx = delay timer value.
; ------------------------------------------------------------------------------
LoadRegDTInstruction::
    ld a, b
    and $0F
    ld l, a
    ld a, HIGH(wRegV)
    ld h, a
    ld a, [wRegDelay]
    ld [hl], a

    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; Fx15 - LD DT, Vx
; Set delay timer = Vx.
; ------------------------------------------------------------------------------
LoadDTInstruction::
    ld a, b
    call EmuRegRead
    ld [wRegDelay], a

    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; Fx1E - ADD I, Vx
; Set I = I + Vx.
; ------------------------------------------------------------------------------
IAddInstruction::
    ld a, b
    call EmuRegRead
    ld d, a
    ld a, [wRegI+1]
    add d
    ld [wRegI+1], a
    jr nc, .noCarry
    ld a, [wRegI]
    inc a
    ld [wRegI], a
.noCarry

    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; Fx29 - LD F, Vx
; Set I = location of sprite for digit Vx.
; ------------------------------------------------------------------------------
LoadDigitPtrInstruction::
    ld a, b
    call EmuRegRead

    ld de, $0000
    and a
    jr z, .endDigitSearchLoop
    ld b, a
.digitSearchLoop
    ld a, 5
    add e
    ld e, a
    adc d
    sub e
    ld d, a
    dec b
    jr nz, .digitSearchLoop
.endDigitSearchLoop

    ld a, d
    ld [wRegI], a
    ld a, e
    ld [wRegI+1], a

    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; Fx33 - LD B, Vx
; Store BCD representation of Vx in memory locations I, I+1, and I+2.
; ------------------------------------------------------------------------------
BCDInstruction::
    ; Load register value
    ld a, b
    call EmuRegRead
    ld d, a

    ; Load I base pointer
    ld a, [wRegI+1]
    ld l, a
    ld a, [wRegI]
    and $0F
    or $C0
    ld h, a

    ; Initialize BCD region to zero
    xor a
    ld [hli], a
    ld [hli], a
    ld [hld], a
    dec hl

    ; Calculate BCD
    ld a, d
.hundredsLoop
    cp 100
    jr c, .endHundredsLoop
    inc [hl]
    sub 100
    jr .hundredsLoop
.endHundredsLoop
    inc hl
.tensLoop
    cp 10
    jr c, .endTensLoop
    inc [hl]
    sub 10
    jr .tensLoop
.endTensLoop
    inc hl
.onesLoop
    and a
    jr z, .endOnesLoop
    inc [hl]
    dec a
    jr .onesLoop
.endOnesLoop

    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; Fx55 - LD [I], Vx
; Store registers V0 through Vx in memory starting at location I.
; ------------------------------------------------------------------------------
StoreRegistersInstruction::
    ; Load I base pointer
    ld a, [wRegI+1]
    ld l, a
    ld a, [wRegI]
    and $0F
    or $C0
    ld h, a

    ; Store register values in EmuRAM
    ld de, wRegV
    ld a, b
    and $0F
    inc a
    ld b, a
.storeLoop
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .storeLoop

    pop hl
    jp EmuLoop

; ------------------------------------------------------------------------------
; Fx65 - LD Vx, [I]
; Read registers V0 through Vx from memory starting at location I.
; ------------------------------------------------------------------------------
LoadRegistersInstruction::
    ; Load I base pointer
    ld a, [wRegI+1]
    ld l, a
    ld a, [wRegI]
    and $0F
    or $C0
    ld h, a

    ; Store register values in EmuRAM
    ld de, wRegV
    ld a, b
    and $0F
    inc a
    ld b, a
.storeLoop
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .storeLoop

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
    dw RandomInstruction
    dw DrawInstruction
    dw DummyInstruction
    dw FInstruction

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