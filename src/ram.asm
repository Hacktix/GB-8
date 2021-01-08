SECTION "WRAM", WRAM0
wBaseMemory: ds $1000

_start_sysvars:

; Register Pointers
wRegV:       ds 16
wRegI:       dw
wRegDelay:   db
wRegSound:   db

; Stack
wStack: ds 32
wStackEnd:

_end_sysvars: