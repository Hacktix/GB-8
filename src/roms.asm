SECTION "ROM Files", ROM0
; ------------------------------------------------------------------------------
; # ROM File Repository
; 
; * Structure:
;  db "<ROM_NAME>", 0
;  db <EMULATION_SPEED>
;  db <BUTTON_MAPPING>
;  dw <ROM_SIZE>
;  INCBIN "inc/roms/<FILENAME>"
;
; * Emulation Speed:
;  A single byte determining how many cycles to emulate per frame. The
;  recommended maximum is 40, but may vary between different ROMs. Too high
;  speeds may cause graphical errors.
;
; * Button Mapping:
;  Always 8 bytes. Each byte has an assigned button (see below).
;  Pressing the assigned button is interpreted as pressing the button with
;  the value of the byte. Any value greater than $F is interpreted as an
;  unassigned button. Duplicate mappings are not allowed.
; 
;  Button Mapping bytes in order:
;  Start, Select, B, A, DPad Down, DPad Up, DPad Left, DPad Right
; ------------------------------------------------------------------------------

GameDataList::
dw Airplane, Blinky, Cave, Fall, Pong
dw $FFFF

; ------------------------------------------------------------------------------
; Pong (Singleplayer)
; ------------------------------------------------------------------------------
Pong::
; ROM Title
db "PONG 1P", 0

; Emulation Speed
db 15

; Button Mapping
db $FF, $FF, $FF, $FF, $04, $01, $FF, $FF

; ROM Size
dw pongDataEnd - pongData

; ROM Data
pongData:
INCBIN "inc/roms/Pong.ch8"
pongDataEnd:

; ------------------------------------------------------------------------------
; Airplane
; ------------------------------------------------------------------------------
Airplane::
; ROM Title
db "AIRPLANE", 0

; Emulation Speed
db 12

; Button Mapping
db $FF, $FF, $08, $08, $FF, $FF, $FF, $FF

; ROM Size
dw airplaneDataEnd - airplaneData

; ROM Data
airplaneData:
INCBIN "inc/roms/Airplane.ch8"
airplaneDataEnd:

; ------------------------------------------------------------------------------
; Blinky
; ------------------------------------------------------------------------------
Blinky::
; ROM Title
db "BLINKY", 0

; Emulation Speed
db 20

; Button Mapping
db $FF, $FF, $FF, $FF, $06, $03, $07, $08

; ROM Size
dw blinkyDataEnd - blinkyData

; ROM Data
blinkyData:
INCBIN "inc/roms/Blinky.ch8"
blinkyDataEnd:

; ------------------------------------------------------------------------------
; Cave
; ------------------------------------------------------------------------------
Cave::
; ROM Title
db "CAVE", 0

; Emulation Speed
db 10

; Button Mapping
db $0F, $FF, $FF, $FF, $08, $02, $04, $06

; ROM Size
dw caveDataEnd - caveData

; ROM Data
caveData:
INCBIN "inc/roms/Cave.ch8"
caveDataEnd:

; ------------------------------------------------------------------------------
; Fall
; ------------------------------------------------------------------------------
Fall::
; ROM Title
db "FALL", 0

; Emulation Speed
db 25

; Button Mapping
db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

; ROM Size
dw fallDataEnd - fallData

; ROM Data
fallData:
INCBIN "inc/roms/fall.bin"
fallDataEnd:





SECTION "Emulator Fontset", ROM0
; CHIP-8 Fontset (hardcoded)
Fontset:
db $F0, $90, $90, $90, $F0
db $20, $60, $20, $20, $70
db $F0, $10, $F0, $80, $F0
db $F0, $10, $F0, $10, $F0
db $90, $90, $F0, $10, $10
db $F0, $80, $F0, $10, $F0
db $F0, $80, $F0, $90, $F0
db $F0, $10, $20, $40, $40
db $F0, $90, $F0, $90, $F0
db $F0, $90, $F0, $10, $F0
db $F0, $90, $F0, $90, $90
db $E0, $90, $E0, $90, $E0
db $F0, $80, $80, $80, $F0
db $E0, $90, $90, $90, $E0
db $F0, $80, $F0, $80, $F0
db $F0, $80, $F0, $80, $80
EndFontset: