AS = ca65
CC = cc65
LD = ld65
ifdef PAL
AFLAGS += -DPAL
endif

INCS = inc/wram.inc

.PHONY: clean
build: smb-complete.nes

%.o: %.asm
	$(AS) $(AFLAGS) --create-dep "$@.dep" --listing $@.lst -g --debug-info $< -o $@

inc/wram.inc: wram.asm wram.map
	python scripts/genram.py wram.map inc/wram.inc

wram.map: wram.asm
	$(AS) -l wram.map wram.asm -o wram.o

smb-complete.nes: $(INCS) layout main.o
	$(LD) --dbgfile $@.dbg -C layout main.o -o $@

clean:
	rm -f smb-complete*.nes *.o *.o.bin *.o.dep *.nes.dbg

include $(wildcard ./*.dep)
