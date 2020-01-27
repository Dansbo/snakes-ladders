!to "SNAKES-LADDERS.PRG", cbm
*=$0801
!byte $0C,$08,$0A,$00,$9E,' ','2','0','6','4',$00,$00,$00
*=$0810

;************************************************************************
;Global constants
;************************************************************************
OPEN=$FFC0
CLOSE=$FFC3
SETNAM=$FFBD
LOAD=$FFD5
BASIN=$FFCF
SETLFS=$FFBA

VERA_CTRL=$9F25
VERA_LO=$9F20
VERA_MI=$9F21
VERA_HI=$9F22
VERA_DATA=$9F23
!byte $FF
	lda #$00
	sta VERA_CTRL
	sta VERA_LO
	lda #$40
	sta VERA_MI
	lda #$10
	sta VERA_HI

	lda #<Filename
	ldy #>Filename
	jsr SETNAM
	jsr SETLFS

	ldx #<VERA_DATA
	ldy #>VERA_DATA
	lda #$00
	jsr LOAD

	lda #0
        sta VERA_LO
        lda #$40
        sta VERA_MI
        lda #$1F
        sta VERA_HI
        lda #1
        sta VERA_DATA

        lda #0
        sta VERA_LO
        lda #$50
        sta VERA_MI
        lda #$1F
        sta VERA_HI
        lda #0
        sta VERA_DATA
        lda #$82
        sta VERA_DATA
        lda #0
        sta VERA_DATA
        sta VERA_DATA
        sta VERA_DATA
        sta VERA_DATA
        lda #$0F
        sta VERA_DATA
        lda #$50
        sta VERA_DATA

        rts








Filename !bin "GAMEBOARD.BIN"
