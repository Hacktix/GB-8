SECTION "WRAM", WRAM0[$C000]
wBaseMemory:: ds $1000

_start_sysvars:

; Register Pointers
wRegV::         ds 16
wRegI::         dw
wRegDelay::     db
wRegSound::     db

; Stack
wSP::           db
wStack::        ds 32
wStackEnd::

; Input
wInputMaskMap:: ds 16
wInputData::    db

; Other
wCycleBuf::     db
wCycleLimit::   db

_end_sysvars:

SECTION "EmuVRAM", WRAM0, ALIGN[8]
wBaseVRAM::      ds 2048
wEndVRAM::
wSpriteSize::    db
wSprOverflow::   db
wSprOverflowY::  db
wUpdateDisplay:: db