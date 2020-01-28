!to "SNAKES-LADDERS.PRG", cbm
*=$0801
!byte $0C,$08,$0A,$00,$9E,' ','2','0','6','4',$00,$00,$00
*=$0810

;************************************************************************
;Global constants
;************************************************************************
VERA_BASE	= $9F20
VERA_ADDR_LOW	= VERA_BASE+0
VERA_ADDR_HIGH	= VERA_BASE+1
VERA_ADDR_BANK	= VERA_BASE+2
VERA_DATA0	= VERA_BASE+3
VERA_DATA1	= VERA_BASE+4
VERA_CTRL	= VERA_BASE+5
VERA_IEN	= VERA_BASE+6
VERA_ISR	= VERA_BASE+7

CHROUT			= $FFD2
SETLFS			= $FFBA
SETNAM			= $FFBD
LOAD			= $FFD5

COLPORT			= $0376

SCREEN_SET_MODE		= $FF5F

	jsr Load_gameboard

	Translates			;end program

Load_gameboard
	lda	#0			; Set scree mode to 40x30 (320x240)
	jsr	SCREEN_SET_MODE

	lda	#$01
	sta	COLPORT

	lda	#147
	jsr	CHROUT

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


	lda	#1			; Logical file number
	ldx	#8			; Device 8 = sd card
	ldy	#0			; 0=ignore address in bin file
					; 1=use address in bin file
	jsr	SETLFS

	lda	#(@End_fname-@Fname)	; Length of filename
	ldx	#<@Fname		; Low byte of Fname address
	ldy	#>@Fname		; High byte of Fname address
	jsr	SETNAM

	ldy	#$40			; VERA HIGH/MID address
	ldx	#$00			; VERA LOW address
	lda	#$02			; VERA BANK + 2
	jsr	LOAD

	rts

@Fname	!text	"gameboard.bin"
@End_fname
