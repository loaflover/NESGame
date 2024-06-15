.segment "CONSTANTS"

    SHADOW_OAM := $0200 ; this is the address of the shadow OEM. or, the local copy of the PPU sprite table before its copied to the PPU
    ; OAM sprite attributes 
        OAM_Y_POS = 0 ; these 4 symbols let me use a sprites memory address plus these to get the correct sprite attribute
        OAM_TILE = 1
        OAM_ATTRIBUTES = 2
        OAM_X_POS = 3
        ONE_SPRITE = 4 ; this is the size of 1 whole sprite. to move to next sprite (at the same attribute!) add this.

    ; screen limits
        MAX_Y = $E1 ; temp value
        MIN_Y = $0
        MAX_X = $F8
        MIN_X = $0

    ; actor specific CONSTS

        ; PADDLE specific CONSTS
            PADDLE_HEIGHT = $D0
            PADDLE_WIDTH = $04
            PADDLE_OFFSET = $18 ; for detecting the bounderies. basically just 8 * 3 pixels.

        ; BALL specific CONSTS
        
            ; ball properties masks (for AND)
                HORIZONTAL_BALL_MASK = %00000100 ; left right
                VERTICAL_BALL_MASK = %00000010; up down
                MOVING_BALL_MASK =  %00000001; is ball moving


.segment "HEADER"
    .byte 'N','E','S',$1A ; magic INES number, standard and required.
    .byte $02 ; number of 16KB prg rom bank's
    .byte $01 ; number of 8KB chr rom bank's
    .byte %00000000 ; last bit signifies if game is vertical(1) or horizontal (0)
    .byte %00000000 ; special case flags, none here
    .byte $00 ; prg ram (none here)
    .byte $00 ; NTSC format
    ; prg - program. CHR - charecter (sprite related).
.segment "ZEROPAGE"
    buttons: .RES 1
    frame_ready: .RES 1

    PaddlePosX: .RES 1 ; these signify the leftmost paddle piece

    ballPosX: .RES 1
    ballPosY: .RES 1
    ballProperties: .RES 1 ; last bit signifies if it is moving. if last bit is 0, no move. next bit signifies up/down. 1 is up, 0 is down. next bit signifies left/right. 1 is left, 0 is right. rest are unused as of now.
    ; so a ball moving up and right would be equal to 00000101
.segment "STARTUP"
    reset:

        SEI ;disable interrupts
        CLD ; turn off decimal mode

        LDX #%1000000 ; disable sound IRQ
        STX $4017

        LDX #$00 ; disable PCM
        STX $4010

        LDX #$FF ; initialize stack
        TXS 

        LDX #$00 ; clear PPU registers
        STX $2000
        STX $2001

        JSR WaitForVblank


        TXA ; x is 0. this sets a to zero aswell
        clearmem:
            STA $0000, x ; stores a in 0[i]00 + x, clearing each page.
            STA $0100, x 
            STA $0300, x 
            STA $0400, x 
            STA $0500, x 
            STA $0600, x 
            STA $0700, x 
                LDA #$FF
                STA $0200, x ; this page is the sprite page, needs to be set to FF
                LDA #$00
            inx 
            CPX #$00 ; compares x to 0. if x reached its maximum (FF), adding 1 would make it 0.
            BNE clearmem ; if x was not 0, jump back.
        JSR WaitForVblank

        LDA #$02 ; copy sprites to the right address
        STA $4014
        NOP ; wait for copy to complete



        LDA #$3F ; this whole section tells the cpu to write to memory address $3f00
        STA $2006
        LDA #$00
        STA $2006

        LDX #$00
        LOADPALETTES:
            LDA PALETTEDATA, x ; loads palletes to memory. $2007 increments automatically.
            STA $2007
            INX 
            CPX #$20
            BNE LOADPALETTES
        LDX #128
        STX PaddlePosX
        STX ballPosX
        STX ballPosY
        LDX #%00000001
        STX ballProperties
        CLI ; enable interrupts
        LDA #%10010000 ; generate NMI when Vblank happens. second bit tells PPU to use the second half of the sprites for background.
        STA $2000 
        LDA #%00011110 ; show sprites and background
        STA $2001
        forever:
            JSR gameCode
            jmp forever
            
;-----------------------------------;
nmi:
    pha
    LDA frame_ready
    BNE PpuDone
    LDA #$02 ; load sprite range
    STA $4014
    ; Mark that we've handled the start of this frame already.
    LDA #$01
    STA frame_ready

    PpuDone:
    pla 
    rti
;-----------------------------------;
PALETTEDATA:
	.byte $00, $0F, $01, $10, 	$00, $0A, $15, $01, 	$00, $29, $28, $27, 	$00, $34, $24, $14 	;background palettes
	.byte $31, $0F, $15, $30, 	$00, $0F, $11, $30, 	$00, $0F, $30, $27, 	$00, $3C, $2C, $1C 	;sprite palettes
PaddleDATA:
    ;Y, SPRITE NUM, attributes, X
	.byte $00, $13, %01000000, $00
	.byte $00, $12, $00, $08 
	.byte $00, $12, $00, $10 
	.byte $00, $13, $00, $18
BallDATA:
    ;Y, SPRITE NUM, attributes, X
	.byte $00, $21, $00, $00
	.byte $FF, $FF, $00, $FF 
	.byte $FF, $FF, $00, $FF 
	.byte $FF, $FF, $00, $FF
	
;--------------subroutines--------------;
gameCode:
    ; checks if NMI has run yet
    :
    LDA frame_ready
    BEQ :- 

    JSR disable_all_oam_entries
    JSR MovePaddle
    JSR drawPaddle

    JSR BallCollisionTest
    JSR MoveBall
    JSR drawBall
        
    LDA #$00
    STA frame_ready
    RTS
drawPaddle:
    LDX #$00
    drawPaddleLoop:
        LDA #PADDLE_HEIGHT
        CLC
        ADC PaddleDATA, x
        STA $0200, x
        INX 

        LDA PaddleDATA, x 
        STA $0200, x
        INX

        LDA PaddleDATA, x 
        STA $0200, x
        INX 

        LDA PaddlePosX
        CLC
        ADC PaddleDATA, x
        STA $0200, x
        INX 

        CPX #$10 ; 4 sprites times 4 bytes per sprite
        BNE drawPaddleLoop
    RTS
drawBall:
    LDX #$00
    drawBallLoop:
        LDA ballPosY
        STA $0210, x
        INX 

        LDA BallDATA, x 
        STA $0210, x
        INX

        LDA BallDATA, x 
        STA $0210, x
        INX 

        LDA ballPosX
        STA $0210, x
        INX 

        CPX #$10 ; 4 sprites times 4 bytes per sprite
        BNE drawBallLoop
    RTS
ReadController:
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016
    LDX #$08
    ReadControllerLoop:
        LDA $4016
        LSR A           ; bit0 -> Carry
        ROL buttons     ; bit0 <- Carry
        DEX
        
        BNE ReadControllerLoop
        LDX buttons
        RTS

WaitForVblank:
    BIT $2002
    BPL WaitForVblank
    RTS
BallCollisionTest:
    LDA ballProperties
    horizontal:
        LDX ballPosY
        upCollisionTest:
            CPX #MAX_Y
            BNE downCollisionTest
            EOR #VERTICAL_BALL_MASK
            STA ballProperties
        downCollisionTest:
            CPX #MIN_Y
            BNE vertical
            EOR #VERTICAL_BALL_MASK
            STA ballProperties
    vertical:
        LDX ballPosX
        leftCollisionTest:
            CPX #MAX_X
            BNE rightCollisionTest
            EOR #HORIZONTAL_BALL_MASK
            STA ballProperties
        rightCollisionTest:
            CPX #MIN_X
            BNE paddle
            EOR #HORIZONTAL_BALL_MASK
            STA ballProperties
    paddle:
        LDA ballPosY
        CLC ; clear carry flag, a must have for addition.
        ADC #PADDLE_WIDTH
        CMP #PADDLE_HEIGHT
        BNE exit ; test if its paddle height.


        LDA ballPosX
        CMP PaddlePosX
        BCC exit ; if its x value is less then the paddles, exit

        SEC ; set carry flag, a must have for subtraction. works reverse from addition for some reason
        SBC #PADDLE_OFFSET
        CMP PaddlePosX
        BCS exit ; if its x value is greater then then the paddles plus offset, exit

        LDA ballProperties
        EOR #VERTICAL_BALL_MASK
        STA ballProperties
    exit:
        RTS



MoveBall:
    LDA #MOVING_BALL_MASK
    BIT ballProperties ; if it is 0, dont move ball
    BEQ Return
    
    HorizontalMove:
        LDA #HORIZONTAL_BALL_MASK
        BIT ballProperties ; if it is 0, move right. else move left
        BEQ MoveBallRight
        BNE MoveBallLeft
    VerticalMove:
        LDA #VERTICAL_BALL_MASK
        BIT ballProperties ; if it is 0, move down. else move up
        BEQ MoveBallDown
        BNE MoveBallUp

    ballMoveSections:
        MoveBallLeft:
            INC ballPosX
            JMP VerticalMove
        MoveBallRight:
            DEC ballPosX
            JMP VerticalMove
        MoveBallUp:
            INC ballPosY
            JMP Return
        MoveBallDown:
            DEC ballPosY
            JMP Return
    Return:
        RTS



MovePaddle:
    JSR ReadController
    LDX buttons ; load buttons into register x
    CPX #%00000001
    BEQ  MovePaddlePiecesRight
    CPX #%00000010
    BEQ  MovePaddlePiecesLeft
    RTS
    MovePaddlePiecesRight:
        LDA #MAX_X
        SEC ; set carry flag, a must have for subtraction. works reverse from addition for some reason
        SBC #PADDLE_OFFSET
        CMP PaddlePosX
        BEQ OutOfBounds
        INC PaddlePosX
        RTS
    MovePaddlePiecesLeft:
        LDA #MIN_X
        CMP PaddlePosX
        BEQ OutOfBounds
        DEC PaddlePosX
        RTS
    OutOfBounds:
        RTS

.proc disable_all_oam_entries
    ldx #0
    lda #$FF
    loop:
        sta SHADOW_OAM + OAM_Y_POS, x
        inx
        inx
        inx
        inx
        bne loop
        rts
.endproc
.segment "VECTORS"
    .word nmi, reset, 0
.segment "CHARS"
    .incbin "tiles.chr"
