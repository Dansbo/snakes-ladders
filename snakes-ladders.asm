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
PLOT		= $FFF0
PIC		= $00
GETIN		= $FFE4
TMP1		= $01
TMP2		= $02

	jsr Reset
	jsr Load2vram
	jsr Spacebar
	inc PIC
	jsr Load2vram
	jsr Load_sprites
	jsr Enable_sprites
	jsr Players

	rts			;end program
;************************************************************************
;Presenting choice of players at right side of screen
;************************************************************************
Players:
	ldx #31
	ldy #1
	jsr Go_XY

	ldx #<@Choose
	ldy #>@Choose
	jsr Print_Str

	ldx #31
	ldy #2
	jsr Go_XY

	ldx #<@Number
	ldy #>@Number
	jsr Print_Str

	ldx #31
	ldy #3
	jsr Go_XY

	ldx #<@Player
	ldy #>@Player
	jsr Print_Str

	ldx #31
	ldy #4
	jsr Go_XY

	ldx #<@Pick
	ldy #>@Pick
	jsr Print_Str
	rts

@Choose !pet "choose",0
@Number !pet "number of",0
@Player !pet "players",0
@Pick   !pet "1-4:",0
;************************************************************************
;Print string function
;************************************************************************
Print_Str:
	stx TMP1
	sty TMP2
	ldy #0

@Doprint
	lda (TMP1), Y
	beq @Printdone
	jsr CHROUT
	iny
	jmp @Doprint

@Printdone
	rts

;************************************************************************
;Move text cursor
;************************************************************************
Go_XY:
	stx TMP1		;Switching X and Y around so X is
	sty TMP2		;Horizontal position and Y is
	ldx TMP2		;Vertical as we know from graphing
	ldy TMP1

	clc
	jsr PLOT
	rts

;************************************************************************
;Enable all sprites
;************************************************************************
Enable_sprites:
	lda #0			;Enabling sprites at register $F4000
	sta VERA_ADDR_LOW
	lda #$40
	sta VERA_ADDR_HIGH
	lda #$0F
	sta VERA_ADDR_BANK
	lda #1			;1 to enable all sprites
	sta VERA_DATA0
	rts

;************************************************************************
;Routine to load sprites into VRAM
;************************************************************************
;Uses: PIC to choose sprite file
;************************************************************************
Load_sprites:
	inc PIC
	lda PIC
	cmp #7			;If PIC is greater than 6 end routine
	beq @End_routine

	lda #1			;Logical file number
	ldx #8			;Device number (8=SDcard)
	ldy #0			;Ignore address in bin file
	jsr SETLFS

	lda PIC
	cmp #2			;If PIC=2 then load lightblue sprite
	bne @Green
	lda #(@Lightgreen-@Lightblue)
	ldx #<@Lightblue
	ldy #>@Lightblue
	jsr SETNAM

	ldy #$D6		;Bitmap is 4 bpp 320x240 38400 bytes = $9600
	ldx #$00		;Start should be $4000+$9600 = $D600
	lda #$02		;Bank 2

	jmp @Load

@Green:	cmp #3
	bne @Purple
	lda #(@Purple_file-@Lightgreen)
	ldx #<@Lightgreen
	ldy #>@Lightgreen
	jsr SETNAM

	ldy #$D6		;Sprite is 4 bpp 8x8 = 32 bytes = $20
	ldx #$20		;Start should be $D600+$20 = $D620
	lda #$02

	jmp @Load

@Purple:cmp #4
	bne @Yellow
	lda #(@Yellow_file-@Purple_file)
	ldx #<@Purple_file
	ldy #>@Purple_file
	jsr SETNAM

	ldy #$D6
	ldx #$40
	lda #$02

	jmp @Load

@Yellow:cmp #5
	bne @Dice
	lda #(@Dice-@Yellow_file)
	ldx #<@Yellow_file
	ldy #>@Yellow_file
	jsr SETNAM

	ldy #$D6
	ldx #$60
	lda #$02

	jmp @Load

@Dice:	cmp #6
	bne Load_sprites
	lda #(@End-@Dice_file)
	ldx #<@Dice_file
	ldy #>@Dice_file
	jsr SETNAM

	ldy #$D6
	ldx #$80
	lda #$02

@Load	jsr LOAD
	jmp Load_sprites

@End_routine
	rts

@Lightblue 	!text "lightblue.bin"
@Lightgreen 	!text "lightgreen.bin"
@Purple_file 	!text "purple.bin"
@Yellow_file 	!text "yellow.bin"
@Dice_file	!text "dice.bin"
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
	sta VERA_DATA0		; TILEW=0 = 320x240 mode
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
