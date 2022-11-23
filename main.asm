.include "x16.inc"
.include "vera.inc"

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

vram_tilebase = $10000
vram_mapbase = $17000
vram_skybase = $00000
vram_palette = $1fa00
vram_sky_palette = $1fa20

horizon = $c4
line_inc = 4

.segment "DATA"

next_line_lo:		.res 1
next_line_hi:		.res 1
scale:				.res 1
ticks:				.res 1
vscroll:			.res 2

.segment "CODE"

main:

	; set video mode
	lda #%00110001		; l0 and l1 enabled
	sta veradcvideo

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

	lda #$01
	sta veral1hscrollhi

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

	jsr init_irq

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

	jsr raster_line

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
; raster_line
;==================================================
raster_line:

	; set video mode
	lda #%00010001		; l0 enabled
	sta veradcvideo

	jsr set_scale

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

	inc veral0hscrolllo
	inc veral0hscrolllo
	inc veral0hscrolllo
	inc veral0hscrolllo

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
	lda #%00110001		; l0 and l1 enabled
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

	inc ticks

	rts



