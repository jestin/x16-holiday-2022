NAME = MODE7DEMO
ASSEMBLER6502 = cl65
ASFLAGS = -t cx16 -l $(NAME).list

PROG = $(NAME).PRG
LIST = $(NAME).list
MAIN = main.asm
SOURCES = $(MAIN) \
		  x16.inc \
		  vera.inc

RESOURCES = TILES.BIN \
			MAP.BIN \
			SKY.BIN \
			PAL.BIN

all: $(PROG)


TILES.BIN: tiles.xcf
	gimp -i -d -f -b '(export-vera "tiles.xcf" "TILES.BIN" 0 4 16 16 0 1 1)' -b '(gimp-quit 0)'

MAP.BIN: map.tmx
	tmx2vera map.tmx -l terrain MAP.BIN -d

SKY.BIN: map.tmx
	tmx2vera map.tmx -l sky SKY.BIN -d

PAL.BIN: TILES.BIN
	cp TILES.BIN.PAL PAL.BIN

resources: $(RESOURCES)

$(PROG): $(SOURCES)
	$(ASSEMBLER6502) $(ASFLAGS) -o $(PROG) $(MAIN)

run: all resources
	x16emu -prg $(PROG) -run -scale 2 -debug

clean:
	rm -f $(PROG) $(LIST)

clean_resources:
	rm -f $(RESOURCES)
	
cleanall: clean clean_resources
