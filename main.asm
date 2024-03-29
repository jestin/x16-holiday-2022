.include "x16.inc"
.include "vera.inc"

; 3rd party includes
.include "zsmplayer.inc"

.segment "ONCE"
.segment "STARTUP"

	jmp main

default_irq			= $8000
zp_vsync_trig		= $30

tilefile: .literal "TILES.BIN"
end_tilefile:

mapfile: .literal "MAP.BIN"
end_mapfile:

skyfile: .literal "SKY.BIN"
end_skyfile:

palettefile: .literal "PAL.BIN"
end_palettefile:

skypalettefile: .literal "SKYPAL.BIN"
end_skypalettefile:

sleighfile: .literal "SLEIGH.BIN"
end_sleighfile:

sleighpalettefile: .literal "SLEIGHPAL.BIN"
end_sleighpalettefile:

deerfile: .literal "DEER.BIN"
end_deerfile:

deerpalettefile: .literal "DEERPAL.BIN"
end_deerpalettefile:

musicfile: .literal "CAROLV1R41.ZSM"
end_musicfile:

vram_tilebase = $0e000
vram_mapbase = $14000
vram_skybase = $00000
vram_sleigh_tiles = $18000
vram_deer_tiles = $18800

vram_palette = $1fa00
vram_sky_palette = $1fa40
vram_sleigh_palette = $1fa60
vram_deer_palette = $1fa80

hi_mem = $a000
bank_music = 1

horizon = $c4
line_inc = 4

.segment "DATA"

next_line_lo:		.res 1
next_line_hi:		.res 1
scale:				.res 1
ticks:				.res 1
vscroll:			.res 2
sleigh_x:			.res 1
sleigh_y:			.res 1
phase:				.res 1

.segment "CODE"

main:

	; set video mode
	lda #%00000001		; disable everything
	sta veradcvideo

	
	lda #$0e ; start at terrain
	; lda #$f6 ; start at streets
	sta vscroll+1

	;=============================================
	; load resources into vram

	lda #1
	ldx #8
	ldy #0
	jsr SETLFS
	lda #(end_tilefile-tilefile)
	ldx #<tilefile
	ldy #>tilefile
	jsr SETNAM
	lda #(^vram_tilebase + 2)
	ldx #<vram_tilebase
	ldy #>vram_tilebase
	jsr LOAD

	lda #1
	ldx #8
	ldy #0
	jsr SETLFS
	lda #(end_mapfile-mapfile)
	ldx #<mapfile
	ldy #>mapfile
	jsr SETNAM
	lda #(^vram_mapbase + 2)
	ldx #<vram_mapbase
	ldy #>vram_mapbase
	jsr LOAD

	lda #1
	ldx #8
	ldy #0
	jsr SETLFS
	lda #(end_skyfile-skyfile)
	ldx #<skyfile
	ldy #>skyfile
	jsr SETNAM
	lda #(^vram_skybase + 2)
	ldx #<vram_skybase
	ldy #>vram_skybase
	jsr LOAD

	lda #1
	ldx #8
	ldy #0
	jsr SETLFS
	lda #(end_palettefile-palettefile)
	ldx #<palettefile
	ldy #>palettefile
	jsr SETNAM
	lda #(^vram_palette + 2)
	ldx #<vram_palette
	ldy #>vram_palette
	jsr LOAD

	lda #1
	ldx #8
	ldy #0
	jsr SETLFS
	lda #(end_skypalettefile-skypalettefile)
	ldx #<skypalettefile
	ldy #>skypalettefile
	jsr SETNAM
	lda #(^vram_sky_palette + 2)
	ldx #<vram_sky_palette
	ldy #>vram_sky_palette
	jsr LOAD

	lda #1
	ldx #8
	ldy #0
	jsr SETLFS
	lda #(end_sleighfile-sleighfile)
	ldx #<sleighfile
	ldy #>sleighfile
	jsr SETNAM
	lda #(^vram_sleigh_tiles + 2)
	ldx #<vram_sleigh_tiles
	ldy #>vram_sleigh_tiles
	jsr LOAD

	lda #1
	ldx #8
	ldy #0
	jsr SETLFS
	lda #(end_sleighpalettefile-sleighpalettefile)
	ldx #<sleighpalettefile
	ldy #>sleighpalettefile
	jsr SETNAM
	lda #(^vram_sleigh_palette + 2)
	ldx #<vram_sleigh_palette
	ldy #>vram_sleigh_palette
	jsr LOAD

	lda #1
	ldx #8
	ldy #0
	jsr SETLFS
	lda #(end_deerfile-deerfile)
	ldx #<deerfile
	ldy #>deerfile
	jsr SETNAM
	lda #(^vram_deer_tiles + 2)
	ldx #<vram_deer_tiles
	ldy #>vram_deer_tiles
	jsr LOAD

	lda #1
	ldx #8
	ldy #0
	jsr SETLFS
	lda #(end_deerpalettefile-deerpalettefile)
	ldx #<deerpalettefile
	ldy #>deerpalettefile
	jsr SETNAM
	lda #(^vram_deer_palette + 2)
	ldx #<vram_deer_palette
	ldy #>vram_deer_palette
	jsr LOAD

	; load music

	
	lda #0			; set ROM bank to KERNAL
	sta $01

	; overworld
	lda #bank_music
	sta 0
	lda #1
	ldx #8
	ldy #2
	jsr SETLFS
	lda #(end_musicfile-musicfile)
	ldx #<musicfile
	ldy #>musicfile
	jsr SETNAM
	lda #0
	ldx #<hi_mem
	ldy #>hi_mem
	jsr LOAD

	jsr init_player

	lda #bank_music
	ldx #<hi_mem
	ldy #>hi_mem
	jsr startmusic
	
	; set the l0 tile mode	
	lda #%11000010 	; height (2-bits) - 0 (32 tiles)
					; width (2-bits) - 0 (32 tiles
					; T256C - 0
					; bitmap mode - 0
					; color depth (2-bits) - 2 (4bpp)
	sta veral0config

	; set the l1 tile mode	
	lda #%00000110 	; height (2-bits) - 0 (32 tiles)
					; width (2-bits) - 2 (128 tiles
					; T256C - 0
					; bitmap mode - 0
					; color depth (2-bits) - 3 (4bpp)
	sta veral1config

	lda #(<(vram_tilebase >> 9) | (1 << 1) | 1)
								;  height    |  width
	sta veral0tilebase
	; sta veral1tilebase

	; set the tile map base address
	lda #<(vram_mapbase >> 9)
	sta veral0mapbase

	; set the tile map base address
	; lda #<(vram_skybase >> 9)
	; sta veral1mapbase

	lda #(<(vram_skybase >> 9) | (1 << 1) | 0)
								;  height    |  width
	sta veral1tilebase

	lda #$02
	sta veral1hscrollhi

	;=============================================
	; setup sleigh sprites

	lda #128
	sta sleigh_x
	lda #32
	sta sleigh_y

	ldx #0
	lda #<(vram_sleigh_tiles >> 5)
	sprstore 0
	lda #>(vram_sleigh_tiles >> 5) | %00000000 ; mode=0
	sprstore 1
	lda sleigh_x
	sprstore 2
	lda #0
	sprstore 3
	lda sleigh_y
	sprstore 4
	lda #0
	sprstore 5
	lda #%00001100	; Collision/Z-depth/vflip/hflip
	sprstore 6
	lda #%11110011	; Height/Width/Paloffset
	sprstore 7

	ldx #1
	lda #<(vram_deer_tiles >> 5)
	sprstore 0
	lda #>(vram_deer_tiles >> 5) | %00000000 ; mode=0
	sprstore 1
	lda #126
	sprstore 2
	lda #0
	sprstore 3
	lda #24
	sprstore 4
	lda #0
	sprstore 5
	lda #%00001100	; Collision/Z-depth/vflip/hflip
	sprstore 6
	lda #%11100100	; Height/Width/Paloffset
	sprstore 7

	ldx #2
	lda #<(vram_deer_tiles >> 5)
	sprstore 0
	lda #>(vram_deer_tiles >> 5) | %00000000 ; mode=0
	sprstore 1
	lda #162
	sprstore 2
	lda #0
	sprstore 3
	lda #24
	sprstore 4
	lda #0
	sprstore 5
	lda #%00001101	; Collision/Z-depth/vflip/hflip
	sprstore 6
	lda #%11100100	; Height/Width/Paloffset
	sprstore 7

	jsr init_irq

	;=============================================
	; set up raster line interrupts

	lda #$3
	sta veraien

	lda #horizon
	sta verairqlo

	lda #horizon + line_inc
	sta next_line_lo
	lda #$0
	sta next_line_hi

	lda veraien
	and #$7f
	ora #0
	sta veraien

	stz phase

;==================================================
; mainloop
;==================================================
mainloop:
	wai
	jsr check_vsync
	jmp mainloop  ; loop forever

	rts

;==================================================
; init_irq
; Initializes interrupt vector
;==================================================
init_irq:
	lda IRQVec
	sta default_irq
	lda IRQVec+1
	sta default_irq+1
	lda #<handle_irq
	sta IRQVec
	lda #>handle_irq
	sta IRQVec+1
	rts

;==================================================
; handle_irq
; Handles VERA IRQ
;==================================================
handle_irq:
	; check for VSYNC
	lda veraisr
	and #$02
	beq @vsync

	; line IRQ

	; acknowledge line IRQ
	sta veraisr

	lda phase
	bne :+
	jsr raster_line_phase_1
	inc phase
	bra :++
:
	jsr raster_line_phase_2
	stz phase
:
	; return from the IRQ manually
	ply
	plx
	pla
	rti
	; end of line IRQ

@vsync:
	lda veraisr
	and #$01

	beq @end
	sta zp_vsync_trig
	; clear vera irq flag
	sta veraisr

@end:
	jmp (default_irq)
;==================================================
; raster_line_phase_1
;==================================================
raster_line_phase_1:

	jsr set_scale

	lda next_line_lo
	sta verairqlo

	lda veraien
	and #$7f
	ora next_line_hi
	sta veraien

	clc
	lda next_line_lo
	adc #1
	sta next_line_lo
	bcc @return
	lda #$80
	sta next_line_hi

@return:
	rts

;==================================================
; raster_line_phase_2
;==================================================
raster_line_phase_2:

	; set video mode
	lda #%01010001		; l0 and sprites enabled
	sta veradcvideo

	inc veral0hscrolllo
	inc veral0hscrolllo
	inc veral0hscrolllo
	inc veral0hscrolllo
	inc veral0hscrolllo

	lda next_line_lo
	sta verairqlo

	lda veraien
	and #$7f
	ora next_line_hi
	sta veraien

	sec
	lda scale
	sbc #2
	sta scale

	sec
	lda #128
	sbc scale
	lsr
	lsr
	lsr
	sta u0L
	cmp #line_inc
	bcs :+
	lda #line_inc
	sta u0L
:
	clc
	lda next_line_lo
	adc u0L
	sta next_line_lo
	bcc @return
	lda #$80
	sta next_line_hi

@return:
	rts

;==================================================
; check_vsync
;==================================================
check_vsync:
	lda zp_vsync_trig
	beq @end

	; VSYNC has occurred, handle
	
	stz next_line_hi

	lda #horizon + line_inc
	sta next_line_lo
	lda #horizon
	sta verairqlo

	lda veraien
	and #$7f
	sta veraien

	lda #128
	sta scale

	lda #64
	sta veradchscale
	sta veradcvscale

	stz veral0hscrolllo
	stz veral1hscrolllo

	; set video mode
	lda #%01110001		; l0, l1, and sprites enabled
	sta veradcvideo

	jsr tick

@end:
	stz zp_vsync_trig
	rts
	
;==================================================
; set_scale
;==================================================
set_scale:

	; stash veractl
	lda veractl
	tay

	; set DCSEL to 0
	lda #0
	sta veractl

	lda scale
	sta veradchscale

	sec
	lda #128
	sbc scale
	lsr
	asl
	lsr
	sta u0L
	lda #128
	sbc u0L
	sta veradcvscale

	asl u0L
	asl u0L

	clc
	lda vscroll
	adc u0L
	sta veral0vscrolllo
	lda vscroll+1
	adc #0
	sta veral0vscrollhi

	; un-stash veractl
	sty veractl

	rts

;==================================================
; tick
;==================================================
tick:

	lda ticks
	stz phase
	lsr
	bcc :+

	lda vscroll
	sec
	sbc #2
	sta vscroll
	bcs :+
	dec vscroll+1
:
	lda vscroll
	sta veral0vscrolllo
	lda vscroll+1
	sta veral0vscrollhi

	jsr set_sleigh_height
	jsr set_deer_tile
	jsr playmusic

	; check for the start of the terrain again and then restart the music
	lda vscroll+1
	and #$0f
	cmp #$0e
	bne :+

	lda vscroll
	bne :+

	; play music again if at the end
	lda #bank_music
	ldx #<hi_mem
	ldy #>hi_mem
	jsr startmusic

:
	inc ticks

	rts

;==================================================
; set_sleigh_height
;==================================================
set_sleigh_height:
	lda ticks

	cmp #16
	bcs :+
	lda #32
	bra @store_sleigh_y
:
	cmp #32
	bcs :+
	lda #33
	bra @store_sleigh_y
:
	cmp #48
	bcs :+
	lda #34
	bra @store_sleigh_y
:
	cmp #64
	bcs :+
	lda #35
	bra @store_sleigh_y
:
	cmp #80
	bcs :+
	lda #36
	bra @store_sleigh_y
:
	cmp #96
	bcs :+
	lda #35
	bra @store_sleigh_y
:
	cmp #112
	bcs :+
	lda #34
	bra @store_sleigh_y
:
	cmp #128
	bcs :+
	lda #33
	bra @store_sleigh_y
:
	cmp #144
	bcs :+
	lda #32
	bra @store_sleigh_y
:
	cmp #160
	bcs :+
	lda #31
	bra @store_sleigh_y
:
	cmp #176
	bcs :+
	lda #30
	bra @store_sleigh_y
:
	cmp #192
	bcs :+
	lda #29
	bra @store_sleigh_y
:
	cmp #208
	bcs :+
	lda #28
	bra @store_sleigh_y
:
	cmp #224
	bcs :+
	lda #29
	bra @store_sleigh_y
:
	cmp #240
	bcs :+
	lda #30
	bra @store_sleigh_y
:
	lda #31

@store_sleigh_y:
	sta sleigh_y

	ldx #0
	sprstore 4

	rts

;==================================================
; set_deer_tile
;==================================================
set_deer_tile:
	lda ticks
	lsr
	lsr
	lsr
	lsr
	and #%00000011
	asl
	asl
	asl
	asl
	asl
	clc
	adc #<(vram_deer_tiles >> 5)

	ldx #1
	sprstore 0

	eor #%00100000
	ldx #2
	sprstore 0

	rts
