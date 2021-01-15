SECTION "Selection Menu", ROM0
StartSelectionMenu::
    ; Initialize page number to zero
    xor a
    ld [wSelectionPage], a

ReloadSelectionMenu::
    ; Load BC with ROM table pointer + page offset
    ld a, [wSelectionPage]
    swap a
    add LOW(GameDataList)
    ld c, a
    adc HIGH(GameDataList)
    sub c
    ld b, a

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

SelectionMenuLoop::
    halt 
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