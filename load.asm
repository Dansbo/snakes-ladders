*=$0801
!byte $0C,$08,$0A,$00,$9E,' ','2','0','6','4',$00,$00,$00
*=$0810

VERA_BASE	= $9F20
VERA_ADDR_LOW	= VERA_BASE+0
VERA_ADDR_HIGH	= VERA_BASE+1
VERA_ADDR_BANK	= VERA_BASE+2
VERA_DATA0	= VERA_BASE+3
VERA_DATA1	= VERA_BASE+4
VERA_CTRL	= VERA_BASE+5
VERA_IEN	= VERA_BASE+6
VERA_ISR	= VERA_BASE+7

VERA_L0_REG		= $F2000
VERA_L0_CTRL0		= VERA_L0_REG
VERA_L0_CTRL1		= VERA_L0_REG+1
VERA_L0_MAP_BASE_L	= VERA_L0_REG+2
VERA_L0_MAP_BASE_H	= VERA_L0_REG+3
VERA_L0_TILE_BASE_L	= VERA_L0_REG+4
VERA_L0_TILE_BASE_H	= VERA_L0_REG+5
VERA_L0_HSCROLL_L	= VERA_L0_REG+6
VERA_L0_HSCROLL_H	= VERA_L0_REG+7
VERA_L0_BM_PAL_OFFS	= VERA_L0_REG+7
VERA_L0_VSCROLL_L	= VERA_L0_REG+8
VERA_L0_VSCROLL_H	= VERA_L0_REG+9

GETIN			= $FFE4
RDTIM			= $FFDE
SETTIM			= $FFDB
JOY_GET			= $FF56
JOY_SCAN		= $FF53

SCREEN_SET_MODE		= $FF5F

;****************************************************************************
; Increment a 16 bit value held in memory
;****************************************************************************
!macro INC16 .var {
	inc	.var		; Increment low-byte
	bne	.end		; If it has not rolled over to 0, branch to end
	inc	.var+1		; Increment high-byte
.end:
}

;****************************************************************************
; Set a VERA address and ensure the increment bit is set as specified
;****************************************************************************
; USES:		.A
;****************************************************************************
!macro VERA_SET .bank, .addrh, .addrl, .in {
	lda	#.in		; Load increment value and shift it
	asl			; to high nibble
	asl
	asl
	asl
	ora	#.bank		; OR with bank to get bank into low nibble

	sta	VERA_ADDR_BANK	; Write increment value and bank to VERA
	lda	#.addrh		; Write high address to VERA
	sta	VERA_ADDR_HIGH
	lda	#.addrl		; Write low address to vera
	sta	VERA_ADDR_LOW
}

main:
	lda	#0			; Set scree mode to 40x30 (320x240)
	jsr	SCREEN_SET_MODE

	lda	#0			; No reset, use data0
	sta	VERA_CTRL

	; Setup Layer0 for bitmap data
	lda	#$1F			; Inc=1, Bank=F
	sta	VERA_ADDR_BANK
	lda	#$20			; Addr=2000 = Layer 0 register
	sta	VERA_ADDR_HIGH
	lda	#$00
	sta	VERA_ADDR_LOW

	lda	#%11000001		; Mode=6; Enabled=1
	sta	VERA_DATA0
	lda	#0
	sta	VERA_DATA0		; TILEW=0 = 320x230 mode
	sta	VERA_DATA0		; MAP_BASE, not used in bitmap mode
	sta	VERA_DATA0		; MAP_BASE, not used in bitmap mode
	sta	VERA_DATA0		; TILE_BASE low byte = $00
	lda	#%00010000		; TILE_BASE high = $10 = $1000
	sta	VERA_DATA0		;   Translates to $04000
	lda	#0
	sta	VERA_DATA0		; HSCROLL=0
	sta	VERA_DATA0		; PALETTE_OFFSET
	sta	VERA_DATA0		; VSCROLL_L=0
	sta	VERA_DATA0		; VSCROLL_H=0

	; Disable Layer1, which is normally used for Text
	lda	#$30			; Addr=3000 : Layer 1 register
	sta	VERA_ADDR_HIGH
	lda	#$00
	sta	VERA_ADDR_LOW

	sta	VERA_DATA0		; Disable Layer 1

	; Load Image data
	lda	#%00010000		; Inc=1, Bank=0
	sta	VERA_ADDR_BANK
	lda	#$40			; Addr=4000, Image data start
	sta	VERA_ADDR_HIGH
	lda	#$00
	sta	VERA_ADDR_LOW


WIDTH=$00				; Give names to Zero Page locations
HEIGHT=$01				; to use them as variables
IMG_PTR=$02

	lda	#160			; In 4bpp mode, each pixel takes up
	sta	WIDTH			; 4 bit = ½ byte, so width of image in
	lda	#240			; memory is half of actual image width
	sta	HEIGHT

	lda	#<Barm			; Load the start address of the image
	sta	IMG_PTR			; in to Zero Page variable
	lda	#>Barm
	sta	IMG_PTR+1
	ldy	#0			; .Y is used as index, but is always 0

@loop:
	lda	(IMG_PTR),y		; Load byte from image data
	sta	VERA_DATA0		; Write to VERA
	+INC16	IMG_PTR			; Increment ZP pointer
	dec	WIDTH
	bne	@loop			; If width > 0, jump back to @loop
	lda	#160			; Load width with value again
	sta	WIDTH
	dec	HEIGHT
	bne	@loop			; If height > 0, jump back to @loop

	jmp *				; Halt program
	rts

Barm	!bin	"gameboard.bin"
