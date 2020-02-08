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
SETTIM		= $FFDB
RDTIM		= $FFDE

SCREEN_SET_MODE	= $FF5F
PLOT		= $FFF0
PIC		= $00
GETIN		= $FFE4
TMP1		= $01
TMP2		= $02
PLAYERS		= $03
CURRENT_PLYER	= $04
DICE		= $05
FIRST_THROW	= $06

	jsr Reset
	jsr Load2vram
	jsr Spacebar
	inc PIC
	jsr Load2vram
	jsr Load_sprites
	jsr Enable_sprites
	jsr Players
	jsr Player_choice
	jsr Throw_dice
	jsr Show_pieces
	jsr Gameloop

	rts			;end program

Move:	lda @Pcs_addr_hi	;First we need to know where the piece
	sta VERA_ADDR_HIGH	;is located
	lda CURRENT_PLYER
	bne @Lightgreen
	lda @Lightblue_addr	;We change the VERA address to the relevant
	sta TMP2
	jmp @Next

@Lightgreen
	cmp #1
	bne @Purple
	lda @Lightgreen_addr
	sta TMP2
	jmp @Next

@Purple	cmp #2
	bne @Yellow
	lda @Purple_addr
	sta TMP2
	jmp @Next

@Yellow	lda @Yellow_addr
	sta TMP2

@Next	lda TMP2
	sta VERA_ADDR_LOW	;Position and increment with 2
	lda #$2F		;each time we read VERA_DATA0
	sta VERA_ADDR_BANK	;as we do not need upper bytes at the moment
	lda VERA_DATA0
	sta @Xpos		;Horizontal position is stored in @Xpos
	lda VERA_DATA0
	sta @Ypos		;Vertical position is stored in @Ypos

	lda @Pcs_addr_hi	;Now I want to move lightblue to tile 1
	sta VERA_ADDR_HIGH	;VERA High is $50
	lda TMP2		;gamepiece's Xpos is located at $12
	sta VERA_ADDR_LOW	;=$5012
	lda #$0F		;Increment 0, Bank $F
	sta VERA_ADDR_BANK
	lda FIRST_THROW
	bne @Dice
@Start	lda #1
	sta TMP1
	jsr Delay
	dec @Xpos		;Decrement Xpos with 1 pixel
	lda @Xpos		;Load new Xpos into register A
	sta VERA_DATA0		;Send to VERA
	cmp #4			;Is X position #$04 which is center of tile 1
	bne @Start		;If not then move another pixel
	inc TMP2		;We need to know if the upper byte is 0
	lda TMP2		;If not we end up placing the piece in the
	sta VERA_ADDR_LOW	;wrong place
	lda VERA_DATA0		;Load upper byte of Xpos
	beq +			;If 0 then continue
	dec TMP2
	lda TMP2
	sta VERA_ADDR_LOW
@Remain	lda #1			;We need another loop to take care of moving
	sta TMP1		;the gamme piece the last 3 pixels
	jsr Delay		;So it doesn't jump around but moves slowly
	dec @Xpos		;towards it's start position
	lda @Xpos
	sta VERA_DATA0
	bne @Remain		;When Xpos reaches 0 then decrement upper byte
	inc TMP2		;of Horizontal position
	lda TMP2		;Change VERA_ADDR_LOW to upper byte of Xpos
	sta VERA_ADDR_LOW	;to 0
	dec TMP2		;Change addess back
	lda #0
	sta VERA_DATA0		;Change upper byte of Xpos to 0
	lda TMP2
	sta VERA_ADDR_LOW
	jmp @Start
+	dec TMP2
	dec DICE		;We need to not move the first tile first time

@Dice	ldx #0			;Reset X
	lda DICE		;How many eyes on the dice left?
	beq @End
	lda TMP2
	sta VERA_ADDR_LOW
@Right	inx
	inc @Xpos		;Increment @Xpos
	lda @Xpos		;So gamepiece can move 1 pixel right
	sta VERA_DATA0
	lda #1			;Delay with one Jiffy
	sta TMP1		;Before moving on to next pixel
	jsr Delay
	cpx #24			;1 tile is 24 pixels wide
	bne @Right
	lda #30			;Delay with half a second
	sta TMP1		;when center of new tile is reached
	jsr Delay
	dec DICE		;We moved for one of the eyes how many left?
	jmp @Dice







@End	rts
@Lightblue_addr 	!byte $12
@Lightgreen_addr 	!byte $1A
@Purple_addr		!byte $22
@Yellow_addr		!byte $2A
@Pcs_addr_hi		!byte $50
@Xpos			!byte $00
@Ypos			!byte $00
@Lightblue_row		!byte $00
@Lightgreen_row		!byte $00
@Purple_row		!byte $00
@Yellow_row		!byte $00

;************************************************************************
;Routine that enable all gamepieces at starting position
;************************************************************************
Show_pieces:
	lda #$50		;Enabling lightblue piece
	sta VERA_ADDR_HIGH
	lda #$10
	sta VERA_ADDR_LOW
	lda #$1F
	sta VERA_ADDR_BANK
	lda Pcs_addr_0
	sta VERA_DATA0
	lda Pcs_addr_0+1
	sta VERA_DATA0
	lda #250
	sta VERA_DATA0
	lda #0
	sta VERA_DATA0
	lda #220
	sta VERA_DATA0
	lda #0
	sta VERA_DATA0
	lda #%00001100		;No collision; On layer1; No flip
	sta VERA_DATA0
	lda #%01010000		;16x16 pixels and no PALETTE_OFFSET
	sta VERA_DATA0

	lda Pcs_addr_1		;Enabling Green piece
	sta VERA_DATA0
	lda Pcs_addr_1+1
	sta VERA_DATA0
	lda #10
	sta VERA_DATA0
	lda #1
	sta VERA_DATA0
	lda #220
	sta VERA_DATA0
	lda #0
	sta VERA_DATA0
	lda #%00001100
	sta VERA_DATA0
	lda #%01010000
	sta VERA_DATA0
	lda PLAYERS
	cmp #3			;Show next piece if PLAYERS is greater than
	bcs +			;or equal to 3
	jmp @End

+	lda Pcs_addr_2		;Enabling Purple piece
	sta VERA_DATA0
	lda Pcs_addr_2+1
	sta VERA_DATA0
	lda #26
	sta VERA_DATA0
	lda #1
	sta VERA_DATA0
	lda #220
	sta VERA_DATA0
	lda #0
	sta VERA_DATA0
	lda #%00001100
	sta VERA_DATA0
	lda #%01010000
	sta VERA_DATA0
	lda PLAYERS
	cmp #4			;Show next piece if PLAYERS is greater than
	bcs +			;or equal to 4
	jmp @End

+	lda Pcs_addr_3		;Enabling Yellow piece
	sta VERA_DATA0
	lda Pcs_addr_3+1
	sta VERA_DATA0
	lda #42
	sta VERA_DATA0
	lda #1
	sta VERA_DATA0
	lda #220
	sta VERA_DATA0
	lda #0
	sta VERA_DATA0
	lda #%00001100
	sta VERA_DATA0
	lda #%01010000
	sta VERA_DATA0

@End:	rts



;************************************************************************
;Delay function
;************************************************************************
Delay	lda #0
	jsr SETTIM		;Set clocktime to 0

@Delay	jsr RDTIM		;Read clocktime
	cmp TMP1		;Has predefined jiffies been reached?
	bne @Delay		;If not read again
	rts

;************************************************************************
;Gameloop waits for player to press space while spinning dice
;************************************************************************
Gameloop:
	inc Rndnum
	jsr GETIN

	cmp #' '
	bne +
	jmp @Pick

+	lda #8			;Delay for 8 jiffies
	sta TMP1
	jsr Delay

	lda #$08
	sta VERA_ADDR_LOW
	lda #$50
	sta VERA_ADDR_HIGH
	lda #$1f
	sta VERA_ADDR_BANK

	lda DICE
	bne @Dice2
@D0	lda @Dice_addr_0
	sta VERA_DATA0
	lda @Dice_addr_0+1
	jmp @Show

@Dice2	cmp #1
	bne @Dice3
	lda @Dice_addr_2
	sta VERA_DATA0
	lda @Dice_addr_2+1
	jmp @Show

@Dice3	cmp #2
	bne @Dice4
@D1	lda @Dice_addr_1
	sta VERA_DATA0
	lda @Dice_addr_1+1
	jmp @Show

@Dice4	cmp #3
	bne @Dice5
	lda @Dice_addr_3
	sta VERA_DATA0
	lda @Dice_addr_3+1
	jmp @Show

@Dice5	cmp #4
	bne @Dice6
	jmp @D0

@Dice6	cmp #5
	bne @Dice7
	lda @Dice_addr_4
	sta VERA_DATA0
	lda @Dice_addr_4+1
	jmp @Show

@Dice7	cmp #6
	bne @Dice8
	jmp @D1

@Dice8	cmp #7
	bne @Dice9
	lda @Dice_addr_5
	sta VERA_DATA0
	lda @Dice_addr_5+1
	jmp @Show

@Dice9	cmp #8
	bne @Dice10
	jmp @D0

@Dice10	cmp #9
	bne @Dice11
	lda @Dice_addr_6
	sta VERA_DATA0
	lda @Dice_addr_6+1
	jmp @Show

@Dice11	cmp #10
	bne @Dice12
	jmp @D1

@Dice12	lda @Dice_addr_7
	sta VERA_DATA0
	lda @Dice_addr_7+1

@Show	inc DICE
	sta VERA_DATA0
	lda #10			;X position
	sta VERA_DATA0		;X position 265
	lda #1			;bit 9-8 of x position
	sta VERA_DATA0
	lda #100		;Y position
	sta VERA_DATA0
	lda #0			;Bit 9-8 of Y position
	sta VERA_DATA0
	lda #%00001100		;No collision; Z=3 on top of txt; no flip
	sta VERA_DATA0
	lda #%10100000		;Sprite 32x32; No PALETTE_OFFSET
	sta VERA_DATA0
	lda DICE
	cmp #11
	bne +
	lda #0
	sta DICE

+	jmp Gameloop

@Pick	inc Rndnum
	lda Rndnum
	and #$0F
	sta DICE
	beq @Pick
	cmp #7
	bcs @Pick
	beq @Pick
	lda #$08
	sta VERA_ADDR_LOW
	lda #$50
	sta VERA_ADDR_HIGH
	lda #$1F
	sta VERA_ADDR_BANK
	lda DICE
	cmp #1
	bne @Is_2
	lda @Dice_addr_2
	sta VERA_DATA0
	lda @Dice_addr_2+1
	sta VERA_DATA0
	jmp @End

@Is_2	cmp #2
	bne @Is_3
	lda @Dice_addr_3
	sta VERA_DATA0
	lda @Dice_addr_3+1
	sta VERA_DATA0
	jmp @End

@Is_3	cmp #3
	bne @Is_4
	lda @Dice_addr_4
	sta VERA_DATA0
	lda @Dice_addr_4+1
	sta VERA_DATA0
	jmp @End

@Is_4	cmp #4
	bne @Is_5
	lda @Dice_addr_5
	sta VERA_DATA0
	lda @Dice_addr_5+1
	sta VERA_DATA0
	jmp @End

@Is_5	cmp #5
	bne @Is_6
	lda @Dice_addr_6
	sta VERA_DATA0
	lda @Dice_addr_6+1
	sta VERA_DATA0
	jmp @End

@Is_6	lda @Dice_addr_7
	sta VERA_DATA0
	lda @Dice_addr_7+1
	sta VERA_DATA0


@End	jsr Move
	inc CURRENT_PLYER
	lda CURRENT_PLYER
	cmp #4
	beq +
	jsr Throw_dice
	jmp Gameloop
+	lda #0
	sta CURRENT_PLYER
	lda #1
	sta FIRST_THROW
	jsr Throw_dice
	jmp Gameloop
	rts
@Dice_addr_0	!byte $C0, $06
@Dice_addr_1	!byte $D0, $06
@Dice_addr_2	!byte $E0, $06
@Dice_addr_3	!byte $F0, $06
@Dice_addr_4	!byte $00, $07
@Dice_addr_5	!byte $10, $07
@Dice_addr_6	!byte $20, $07
@Dice_addr_7	!byte $30, $07
;************************************************************************
;Presenting players with text to press space to stop dice from rolling
;************************************************************************
Throw_dice:
	ldx #31
	ldy #1
	jsr Go_XY

	lda CURRENT_PLYER
	bne @Plyer_2
	lda #$E0
	sta COLPORT
	ldx #<@P1
	ldy #>@P1
	jsr Print_Str
	jmp @Throw

@Plyer_2:
	cmp #1
	bne @Plyer_3
	lda #$50
	sta COLPORT
	ldx #<@P2
	ldy #>@P2
	jsr Print_Str
	jmp @Throw

@Plyer_3
	cmp #2
	bne @Plyer_4
	lda #$40
	sta COLPORT
	ldx #<@P3
	ldy #>@P3
	jsr Print_Str
	jmp @Throw

@Plyer_4
	lda #$70
	sta COLPORT
	ldx #<@P4
	ldy #>@P4
	jsr Print_Str

@Throw
	lda #$01
	sta COLPORT

	ldx #31
	ldy #2
	jsr Go_XY

	ldx #<@Press
	ldy #>@Press
	jsr Print_Str

	ldx #31
	ldy #3
	jsr Go_XY

	ldx #<@To
	ldy #>@To
	jsr Print_Str

	ldx #31
	ldy #4
	jsr Go_XY

	ldx #<@Dice
	ldy #>@Dice
	jsr Print_Str

	rts

@P1	!pet "player 1",0
@P2	!pet "player 2",0
@P3	!pet "player 3",0
@P4	!pet "player 4",0
@Press	!pet "hit space",0
@To	!pet "to stop",0
@Dice	!pet "dice",0
;************************************************************************
;Routine so user can choose number of players
;************************************************************************
Player_choice:
	inc Rndnum
	jsr GETIN
	cmp #'1'
	bne @Is_2
	inc PLAYERS
	jmp @End

@Is_2	cmp #'2'
	bne @Is_3
	lda #2
	sta PLAYERS
	jmp @End

@Is_3	cmp #'3'
	bne @Is_4
	lda #3
	sta PLAYERS
	jmp @End

@Is_4	cmp #'4'
	bne Player_choice
	lda #4
	sta PLAYERS

@End	rts
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
	ldx #$80		;Start should be $D600+$20 = $D620
	lda #$02

	jmp @Load

@Purple:cmp #4
	bne @Yellow
	lda #(@Yellow_file-@Purple_file)
	ldx #<@Purple_file
	ldy #>@Purple_file
	jsr SETNAM

	ldy #$D7
	ldx #$00
	lda #$02

	jmp @Load

@Yellow:cmp #5
	bne @Dice
	lda #(@Dice_file-@Yellow_file)
	ldx #<@Yellow_file
	ldy #>@Yellow_file
	jsr SETNAM

	ldy #$D7
	ldx #$80
	lda #$02

	jmp @Load

@Dice:	cmp #6
	bne Load_sprites
	lda #(@End-@Dice_file)
	ldx #<@Dice_file
	ldy #>@Dice_file
	jsr SETNAM

	ldy #$D8
	ldx #$00
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
	sta PLAYERS
	sta CURRENT_PLYER
	sta FIRST_THROW
	ldx #$0E
	stx VERA_ADDR_LOW
	ldx #$50
	stx VERA_ADDR_HIGH
	ldx #$4F
	stx VERA_ADDR_BANK
	sta VERA_DATA0
	sta VERA_DATA0
	sta VERA_DATA0
	sta VERA_DATA0
	sta VERA_DATA0

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
Pcs_addr_0 !byte $B0, $06
Pcs_addr_1 !byte $B4, $06
Pcs_addr_2 !byte $B8, $06
Pcs_addr_3 !byte $BC, $06
