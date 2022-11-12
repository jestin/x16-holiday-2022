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

palettefile: .literal "PAL.BIN"
end_palettefile:

vram_tilebase = $00000
vram_mapbase = $10000
vram_palette = $1fa00

.segment "DATA"

irq_line_counter:	.byte 0
raster_low:			.byte $20, $40, $60, $80, $A0, $B0, $C0, $D0, 0
raster_hi:			.byte 0, 0, 0, 0, $0, $0, $0, $0, $0
hscales:			.byte 128, 120, 112, 104, 96, 88, 80, 72, 72

next_line_lo:		.res 1
next_line_hi:		.res 1
scale:				.res 1

.segment "CODE"

main:

	; set video mode
	lda #%00010001		; l0 enabled
	sta veradcvideo

	; set the l0 tile mode	
	lda #%00000010 	; height (2-bits) - 0 (32 tiles)
					; width (2-bits) - 0 (32 tiles
					; T256C - 0
					; bitmap mode - 0
					; color depth (2-bits) - 2 (4bpp)
	sta veral0config

	lda #(<(vram_tilebase >> 9) | (1 << 1) | 1)
								;  height    |  width
	sta veral0tilebase

	; set the tile map base address
	lda #<(vram_mapbase >> 9)
	sta veral0mapbase

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
	lda #(end_palettefile-palettefile)
	ldx #<palettefile
	ldy #>palettefile
	jsr SETNAM
	lda #(^vram_palette + 2)
	ldx #<vram_palette
	ldy #>vram_palette
	jsr LOAD

	lda #$3
	sta veraien

	lda #$05
	sta verairqlo

	lda #$0a
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
	beq :+

	; line IRQ

	; acknowledge line IRQ
	sta veraisr

	jsr set_scale

	lda raster_low,x
	sta verairqlo

	lda veraien
	and #$7f
	ora raster_hi,x
	sta veraien

	inc irq_line_counter

	; return from the IRQ manually
	ply
	plx
	pla
	rti
	; end of line IRQ
:
	lda veraisr
	and #$01

	beq @end
	sta zp_vsync_trig
	; clear vera irq flag
	sta veraisr

@end:
	jmp (default_irq)

;==================================================
; check_vsync
;==================================================
check_vsync:
	lda zp_vsync_trig
	beq @end

	; VSYNC has occurred, handle
	jsr set_scale
	
	stz irq_line_counter

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

	ldx irq_line_counter
	lda hscales,x
	sta veradchscale
	sta veradcvscale

	; un-stash veractl
	sty veractl

	rts

;==================================================
; tick
;==================================================
tick:

	dec veral0vscrolllo	

	rts



