SECTION "Strings", ROM0
strChip8: db "CHIP 8", 0

SECTION "Graphics", ROM0
fontNumbers:
INCBIN "inc/font/numbers.bin"
endFontNumbers:

fontLetters:
INCBIN "inc/font/letters.bin"
endFontLetters:

borderTiles:
INCBIN "inc/gfx/border.bin"
endBorderTiles: