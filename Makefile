NAME = HOLIDAY2022
ASSEMBLER6502 = cl65
TITLE = Jestins_2022_Holdiday_Demo

INCLUDEDIR = 3rdParty/include/
LIBDIR = 3rdParty/lib/
LIBS = zsound.lib

ASFLAGS = -t cx16 -l $(NAME).list -L $(LIBDIR) --asm-include-dir $(INCLUDEDIR)

PROG = $(NAME).PRG
LIST = $(NAME).list
ZIPFILE = $(TITLE).zip

MAIN = main.asm
SOURCES = $(MAIN) \
		  x16.inc \
		  vera.inc

RESOURCES = TILES.BIN \
			MAP.BIN \
			PAL.BIN \
			SKY.BIN \
			SKYPAL.BIN \
			SLEIGH.BIN \
			SLEIGHPAL.BIN \
			DEER.BIN \
			DEERPAL.BIN

all: clean bin/$(PROG)


TILES.BIN: tiles.xcf
	gimp -i -d -f -b '(export-vera "tiles.xcf" "TILES.BIN" 0 4 16 16 0 1 1)' -b '(gimp-quit 0)'

MAP.BIN: map.tmx
	tmx2vera map.tmx -l terrain MAP.BIN

# SKY.BIN: map.tmx
# 	tmx2vera map.tmx -l sky SKY.BIN -d

PAL.BIN: TILES.BIN
	cp TILES.BIN.PAL PAL.BIN

SKY.BIN: sky.xcf
	gimp -i -d -f -b '(export-vera "sky.xcf" "SKY.BIN" 1 4 8 8 0 1 1)' -b '(gimp-quit 0)'

SKYPAL.BIN: SKY.BIN
	cp SKY.BIN.PAL SKYPAL.BIN

SLEIGH.BIN: sleigh.xcf
	gimp -i -d -f -b '(export-vera "sleigh.xcf" "SLEIGH.BIN" 0 4 64 64 0 0 1)' -b '(gimp-quit 0)'

SLEIGHPAL.BIN: SLEIGH.BIN
	cp SLEIGH.BIN.PAL SLEIGHPAL.BIN

DEER.BIN: deer.xcf
	gimp -i -d -f -b '(export-vera "deer.xcf" "DEER.BIN" 0 4 32 64 0 0 1)' -b '(gimp-quit 0)'

DEERPAL.BIN: DEER.BIN
	cp DEER.BIN.PAL DEERPAL.BIN

resources: $(RESOURCES)
	cp *.BIN bin 2> /dev/null
	cp *.ZSM bin 2> /dev/null

bin/$(PROG): $(SOURCES) bin
	$(ASSEMBLER6502) $(ASFLAGS) -o bin/$(PROG) $(MAIN) $(LIBS)

$(ZIPFILE): all resources clean_zip
	(cd bin; zip ../$(ZIPFILE) *)

zip: $(ZIPFILE)

run: all resources
	(cd bin; x16emu -prg $(PROG) -run -scale 2 -debug)

clean:
	rm  -f bin/$(PROG) $(LIST)

clean_resources:
	rm -f $(RESOURCES) *.BIN.PAL

clean_zip:
	rm -f $(ZIPFILE)
	
cleanall: clean clean_resources
	rm -rf bin

bin:
	mkdir ./bin
