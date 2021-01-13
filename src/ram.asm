SECTION "WRAM", WRAM0[$C000]
wBaseMemory:: ds $1000

_start_sysvars:

; Register Pointers
wRegV::       ds 16
wRegI::       dw
wRegDelay::   db
wRegSound::   db

; Stack
wSP::         db
wStack::      ds 32
wStackEnd::

; Other
wCycleBuf::   db

_end_sysvars:

SECTION "EmuVRAM", WRAM0, ALIGN[4]
wBaseVRAM::      ds 2048
wEndVRAM::
wSpriteSize::    db
wSprOverflow::   db
wUpdateDisplay:: db