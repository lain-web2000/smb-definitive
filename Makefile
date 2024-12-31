AS = ca65
CC = cc65
LD = ld65

.PHONY: clean
build: smb-definitive.nes

%.o: %.asm
	$(AS) --create-dep "$@.dep" -g --debug-info $< -o $@

smb-definitive.nes: layout sm2main.o
	$(LD) --dbgfile $@.dbg -C layout sm2main.o -o $@

clean:
	rm -f smb-definitive*.nes *.o *.o.bin *.o.dep *.nes.dbg

include $(wildcard ./*.dep)
