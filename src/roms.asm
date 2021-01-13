SECTION "ROM Files", ROM0
; ------------------------------------------------------------------------------
; # ROM File Repository
; 
; * Structure:
;  db "<ROM_NAME>", 0
;  db <BUTTON_MAPPING>
;  dw <ROM_SIZE>
;  INCBIN "inc/roms/<FILENAME>"
;
; * Button Mapping:
;  Always 8 bytes. Each byte has an assigned button (see below).
;  Pressing the assigned button is interpreted as pressing the button with
;  the value of the byte. Any value greater than $F is interpreted as an
;  unassigned button.
; 
;  Button Mapping bytes in order:
;  Start, Select, B, A, DPad Down, DPad Up, DPad Left, DPad Right
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; Pong (Singleplayer)
; ------------------------------------------------------------------------------
Pong::
; ROM Title
db "Pong (1P)", 0

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
db "Airplane", 0

; Button Mapping
db $FF, $FF, $08, $08, $FF, $FF, $FF, $FF

; ROM Size
dw airplaneDataEnd - airplaneData

; ROM Data
airplaneData:
INCBIN "inc/roms/Airplane.ch8"
airplaneDataEnd:





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