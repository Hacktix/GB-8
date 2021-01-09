NAME = GB-8
PADVAL = 0

RGBASM = rgbasm
RGBLINK = rgblink
RGBFIX = rgbfix

RM_F = rm -f

ASFLAGS = -h
LDFLAGS = -t -w -n gb8.sym
FIXFLAGS = -v -p $(PADVAL) -t $(NAME) -C

gb8.gb: gb8.o
	$(RGBLINK) $(LDFLAGS) -o $@ $^
	$(RGBFIX) $(FIXFLAGS) $@

gb8.o: src/main.asm
	$(RGBASM) $(ASFLAGS) -o $@ $<

.PHONY: clean
clean:
	$(RM_F) gb8.o gb8.gb