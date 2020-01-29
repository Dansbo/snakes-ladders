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

CHROUT		= $FFD2
SETLFS		= $FFBA
SETNAM		= $FFBD
LOAD		= $FFD5

COLPORT		= $0376

SCREEN_SET_MODE	= $FF5F
PIC		= $00
GETIN		= $FFE4

!zone main{
	jsr Reset
	jsr Load2vram
	jsr Spacebar
	inc PIC
	jsr Load2vram
	jsr Load_sprites

	rts			;end program
;************************************************************************
;Routine to load sprites into VRAM
;************************************************************************
;Uses: PIC to choose sprite file
;************************************************************************
Load_sprites:
	inc PIC
	lda PIC
	cmp #6			;If PIC is greater than 5 end routine
	beq @End_routine

	lda #1			;Logical file number
	ldx #8			;Device number (8=SDcard)
	ldy #0			;Ignore address in bin file
	jsr SETLFS

	lda PIC
	cmp #2			;If PIC=2 then load lightblue sprite
	bne Green
	lda #(@Lightgreen-@Lightblue)
	ldx #<@Lightblue
	ldy #>@Lightblue
	jsr SETNAM

	ldy #$CF		;Bitmap is 4 bpp 320x230 36800 bytes = $8FC0
	ldx #$C0		;Start should be $4000+$8FC0 = $CFC0
	lda #$02		;Bank 2

	jmp @Load

Green:	cmp #3
	bne Purple
	lda #(@Purple-@Lightgreen)
	ldx #<@Lightgreen
	ldy #>@Lightgreen
	jsr SETNAM

	ldy #$CF		;Sprite is 4 bpp 8x8 = 32 bytes = $20
	ldx #$E0		;Start should be $CFC0+$20 = $CFE0
	lda #$02

	jmp @Load

Purple:	cmp #4
	bne Yellow
	lda #(@Yellow-@Purple)
	ldx #<@Purple
	ldy #>@Purple
	jsr SETNAM

	ldy #$CF
	ldx #$F0
	lda #$02

	jmp @Load

Yellow:	cmp #5
	bne Load_sprites
	lda #(@End-@Yellow)
	ldx #<@Yellow
	ldy #>@Yellow
	jsr SETNAM

	ldy #$D0
	ldx #$00
	lda #$02

@Load	jsr LOAD
	jmp Load_sprites

@End_routine
	rts

@Lightblue 	!text "lightblue.bin"
@Lightgreen 	!text "lightgreen.bin"
@Purple 	!text "purple.bin"
@Yellow 	!text "yellow.bin"
@End
;************************************************************************
;A loop waiting for the user to press "spacebar"
;************************************************************************
Spacebar:
	inc Rndnum
	jsr GETIN
	cmp #' '
	bne Spacebar
;************************************************************************
;Reset variables used throughout the game
;************************************************************************
Reset:
	lda #0
	sta PIC

	rts

Load2vram:
	lda #0			; Set scree mode to 40x30 (320x240)
	jsr SCREEN_SET_MODE

	lda #$01
	sta COLPORT

	lda #147
	jsr CHROUT

	lda #0			; No reset, use data0
	sta VERA_CTRL

	; Setup Layer0 for bitmap data
	lda #$1F		; Inc=1, Bank=F
	sta VERA_ADDR_BANK
	lda #$20		; Addr=2000 = Layer 0 register
	sta VERA_ADDR_HIGH
	lda #$00
	sta VERA_ADDR_LOW

	lda #%11000001		; Mode=6; Enabled=1
	sta VERA_DATA0
	lda #0
	sta VERA_DATA0		; TILEW=0 = 320x230 mode
	sta VERA_DATA0		; MAP_BASE, not used in bitmap mode
	sta VERA_DATA0		; MAP_BASE, not used in bitmap mode
	sta VERA_DATA0		; TILE_BASE low byte = $00
	lda #%00010000		; TILE_BASE high = $10 = $1000
	sta VERA_DATA0		;   Translates to $04000
	lda #0
	sta VERA_DATA0		; HSCROLL=0
	sta VERA_DATA0		; PALETTE_OFFSET
	sta VERA_DATA0		; VSCROLL_L=0
	sta VERA_DATA0		; VSCROLL_H=0


	lda #1			; Logical file number
	ldx #8			; Device 8 = sd card
	ldy #0			; 0=ignore address in bin file
				; 1=use address in bin file
	jsr SETLFS

	lda PIC			;Check PIC value to find correct picture
	bne +
	lda #(@Fname-@Loading)
	ldx #<@Loading
	ldy #>@Loading
	jmp @Vera


+	lda #(@End_fname-@Fname); Length of filename
	ldx #<@Fname		; Low byte of Fname address
	ldy #>@Fname		; High byte of Fname address
@Vera	jsr SETNAM

	ldy #$40		; VERA HIGH/MID address
	ldx #$00		; VERA LOW address
	lda #$02		; VERA BANK + 2
	jsr LOAD

	rts

@Loading !text	"loading.bin"
@Fname	!text	"gameboard.bin"
@End_fname

;************************************************************************
;Global variables
;************************************************************************
Rndnum !byte 0
}
