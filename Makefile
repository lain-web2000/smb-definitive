AS = ca65
CC = cc65
LD = ld65

INCS = inc/wram.inc 
	   
.PHONY: clean
build: smb-definitive.nes

%.o: %.asm
	$(AS) --create-dep "$@.dep" -g --debug-info $< -o $@

inc/wram.inc: wram.asm wram.map
	python scripts/genram.py wram.map inc/wram.inc

wram.map: wram.asm
	$(AS) -l wram.map wram.asm -o wram.o
	
smb-definitive.nes: $(INCS) layout sm2main.o
	$(LD) --dbgfile $@.dbg -C layout sm2main.o -o $@
	
clean:
	rm -f smb-definitive*.nes *.o *.o.bin *.o.dep *.nes.dbg

include $(wildcard ./*.dep)
