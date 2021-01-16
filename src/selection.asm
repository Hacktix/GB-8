SECTION "Selection Menu", ROM0
StartSelectionMenu::
    ; Initialize page number to zero
    xor a
    ld [wSelectionPage], a
    ld [wInputCooldown], a
    ld [wAllowInput], a

ReloadSelectionMenu::
    ; Clear VRAM
    ld hl, $9820
    ld bc, $0800
    call Zerofill

    ; Reset cursor to zero
    xor a
    ld [wSelectionCursorPos], a
    ld [wPageTitles], a
    ld a, CursorTileNo
    ld [$9820], a

    ; Validate current page, set to 0 if invalid
    ld a, [wSelectionPage]
    cp ((EndGameDataList - GameDataList - 2) / 2) / 15 + !!(((EndGameDataList - GameDataList - 2) / 2) % 15)
    jr c, .validPage
    xor a
    ld [wSelectionPage], a 
.validPage

    ; Load BC with ROM table pointer + page offset
    ld bc, GameDataList
    ld a, [wSelectionPage]
    and a
    jr z, .skipPageOffset
    ld d, a
.pageOffsetLoop
    ld a, $1E
    add c
    ld c, a
    adc b
    sub c
    ld b, a
    dec d
    jr nz, .pageOffsetLoop
.skipPageOffset
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

    ; Increment page titles variable
    ld a, [wPageTitles]
    inc a
    ld [wPageTitles], a

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

    ; Check if input allowed, if not wait for input to be all low
    ld d, a
    ld a, [wAllowInput]
    and a
    jr nz, .inputAllowed
    xor a
    or d
    jr nz, SelectionMenuLoop
    inc a
    ld [wAllowInput], a
.inputAllowed
    ld a, d

    ; Check for down button press
    bit 3, a
    jr z, .noDownPress

    ; Update cursor position
    ld a, 1
    jp UpdateCursorPosition

.noDownPress
    ; Check for up button press
    bit 2, a
    jr z, .noUpPress

    ; Update cursor position
    ld a, $FF
    jp UpdateCursorPosition

.noUpPress
    ; Check for left button press
    bit 1, a
    jr z, .noLeftPress

    ; Disable LCD
    xor a
    ld [rLCDC], a

    ; Reset input cooldown
    ld a, PageSwitchCooldownDuration
    ld [wInputCooldown], a

    ; Update page number and reload
    ld hl, wSelectionPage
    dec [hl]
    jp ReloadSelectionMenu

.noLeftPress
    ; Check for right button press
    bit 0, a
    jr z, .noRightPress

    ; Disable LCD
    xor a
    ld [rLCDC], a

    ; Reset input cooldown
    ld a, PageSwitchCooldownDuration
    ld [wInputCooldown], a

    ; Update page number and reload
    ld hl, wSelectionPage
    inc [hl]
    jp ReloadSelectionMenu

.noRightPress
    ; Check for Start button press
    bit 7, a
    jr z, .noStartPress

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

.noStartPress
    jr SelectionMenuLoop

; ------------------------------------------------------------------------------
; Adds the value in A to the cursor position and updates the position
; ------------------------------------------------------------------------------
UpdateCursorPosition::
    ; Preserve A, clear cursor at current position
    push af
    ld h, $00
    ld a, [wSelectionCursorPos]
    swap a
    sla a
    jr nc, .noOldCarry
    inc h
.noOldCarry
    add $20
    ld l, a
    adc $98
    add h
    sub l
    ld h, a
    xor a
    ld [hl], a

    ; Calculate new cursor position
    pop af
    ld d, a
    ld a, [wPageTitles]
    ld e, a
    ld a, [wSelectionCursorPos]
    add d
    cp e
    jr c, .validRange
    xor a
.validRange
    ld [wSelectionCursorPos], a

    ; Place cursor tile at new VRAM pointer
    ld h, $00
    swap a
    sla a
    jr nc, .noNewCarry
    inc h
.noNewCarry
    add $20
    ld l, a
    adc $98
    sub l
    add h
    ld h, a
    ld a, CursorTileNo
    ld [hl], a

    ; Update input cooldown
    ld a, InputCooldownDuration
    ld [wInputCooldown], a

    ; Return to main loop
    jp SelectionMenuLoop

; ------------------------------------------------------------------------------
; Starts up the emulator after initializing the ROM
; ------------------------------------------------------------------------------
StartROM::
    ; Load HL with ROM table pointer + page offset
    ld hl, GameDataList
    ld a, [wSelectionPage]
    and a
    jr z, .skipPageOffset
    ld d, a
.pageOffsetLoop
    ld a, $1E
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    dec d
    jr nz, .pageOffsetLoop
.skipPageOffset

    ; Add cursor offset
    ld a, [wSelectionCursorPos]
    add a
    add a, l
    ld l, a
    adc h
    sub l
    ld h, a

    ; Push ROM pointer to stack
    ld a, [hli]
    ld c, a
    ld a, [hl]
    ld b, a
    push bc

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