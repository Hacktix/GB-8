SECTION "Selection Menu", ROM0
StartSelectionMenu::
    ; Initialize page number to zero
    xor a
    ld [wSelectionPage], a
    ld [wInputCooldown], a

ReloadSelectionMenu::
    ; Reset cursor to zero
    xor a
    ld [wSelectionCursorPos], a
    ld a, CursorTileNo
    ld [$9820], a

    ; Load BC with ROM table pointer + page offset
    ld a, [wSelectionPage]
    swap a
    add LOW(GameDataList)
    ld c, a
    adc HIGH(GameDataList)
    sub c
    ld b, a
    push bc          ; Preserve pointer for later on

    ; Load HL with VRAM pointer
    ld hl, $9821

.titleLoadLoop
    ; Load ROM pointer into DE
    ld a, [bc]
    inc bc
    ld e, a
    ld a, [bc]
    inc bc
    ld d, a

    ; Check if $FFFF pointer was loaded
    and e
    inc a      ; Sets zero flag if DE is $FFFF
    jr z, .endTitleLoop

    ; Print string (preserving HL), add $20 to HL
    push hl
    call PrintString
    pop hl
    ld a, l
    add $20
    ld l, a
    adc h
    sub l
    ld h, a

    ; Check if end of screen is reached, loop if not
    ld a, h
    and $0F
    cp $0A
    jr nz, .titleLoadLoop
.endTitleLoop

    ; Initialize Interrupts
    xor a
    ldh [rIF], a
    ld a, IEF_VBLANK
    ldh [rIE], a
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG8000
    ldh [rLCDC], a
    ei

    ; Restore ROM and cursor VRAM pointer
    pop bc
    ld hl, $9820

SelectionMenuLoop::
    halt 

    ; Check input cooldown
    ld a, [wInputCooldown]
    and a
    jr z, .noInputCooldown

    ; Decrement input cooldown
    dec a
    ld [wInputCooldown], a
    jr SelectionMenuLoop

.noInputCooldown
    ; Fetch Input
    ld a, P1F_GET_BTN
    ldh [rP1], a
    ldh a, [rP1]
    cpl
    and $0F
    swap a
    ld d, a
    ld a, P1F_GET_DPAD
    ldh [rP1], a
    ldh a, [rP1]
    cpl
    and $0F
    or d

    ; Check for down button press
    bit 3, a
    jr z, .noDownPress

    ; Update cursor position and ROM pointer
    xor a
    ld [hl], a
    ld a, l
    add $20
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, CursorTileNo
    ld [hl], a
    inc bc
    inc bc
    jr .inputDone

.noDownPress

    ; Check for up button press
    bit 2, a
    jr z, .noUpPress

    ; Update cursor position and ROM pointer
    xor a
    ld [hl], a
    ld a, l
    sub $20
    ld l, a
    jr nc, .noUpBorrow
    dec h
.noUpBorrow
    ld a, CursorTileNo
    ld [hl], a
    dec bc
    dec bc
    jr .inputDone

.noUpPress

    ; Check for Start button press
    bit 7, a
    jr z, .noInput

    ; Disable LCD
    xor a
    ld [rLCDC], a

    ; Load HL with ROM pointer and start emulator
    ld a, [bc]
    inc bc
    ld l, a
    ld a, [bc]
    ld h, a
    jp StartROM

.inputDone
    ld a, InputCooldownDuration
    ld [wInputCooldown], a

.noInput
    jr SelectionMenuLoop

; ------------------------------------------------------------------------------
; Starts up the emulator after initializing the ROM stored at HL
; ------------------------------------------------------------------------------
StartROM::
    ; Preserve ROM Data Pointer
    push hl

    ; Initialize Emulator Variables
    call InitSysvars
    call InitEmuVRAM

    ; Turn off Audio initially
    ld a, AUDENA_OFF
    ldh [rAUDENA], a

    ; Load ROM File
    pop hl
    push hl
    call InitROM
    pop hl
    call InitGameTitleDisplay

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