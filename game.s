.include "Globals.asm" ; this whole thing is just done so globals can be seen everywhere.
.segment "HEADER"
    .byte 'N','E','S',$1A ; magic INES number, standard and required.
    .byte $02 ; number of 16KB prg rom bank's
    .byte $01 ; number of 8KB chr rom bank's
    .byte %00000000 ; last bit signifies if game is vertical(1) or horizontal (0)
    .byte %00000000 ; special case flags, none here
    .byte $00 ; prg ram (none here)
    .byte $00 ; NTSC format
    ; prg - program. CHR - charecter (sprite related).

    .import GameOverBG, WinBG, Palettes, PaddleSprites, BallSprites
    .importzp buttons,frame_ready,PaddlePosX,ballPosX,ballPosY,ballProperties,gamestate

.segment "STARTUP"
    reset:
        sei        ; ignore IRQs
        cld        ; disable decimal mode
        ldx #$40
        stx $4017  ; disable APU frame IRQ
        ldx #$ff
        txs        ; Set up stack
        inx        ; now X = 0
        stx $2000  ; disable NMI
        stx $2001  ; disable rendering
        stx $4010  ; disable DMC IRQs

        ; Optional (omitted):
        ; Set up mapper and jmp to further init code here.

        ; The vblank flag is in an unknown state after reset,
        ; so it is cleared here to make sure that @vblankwait1
        ; does not exit immediately.
        bit $2002

        ; First of two waits for vertical blank to make sure that the
        ; PPU has stabilized
    @vblankwait1:  
        bit $2002
        bpl @vblankwait1

        ; We now have about 30,000 cycles to burn before the PPU stabilizes.
        ; One thing we can do with this time is put RAM in a known state.
        ; Here we fill it with $00, which matches what (say) a C compiler
        ; expects for BSS.  Conveniently, X is still 0.
        txa
    @clrmem:
        sta $000,x
        sta $100,x
        sta $200,x
        sta $300,x
        sta $400,x
        sta $500,x
        sta $600,x
        sta $700,x
        inx
        bne @clrmem

        ; Other things you can do between vblank waits are set up audio
        ; or set up other mapper registers.
    
    @vblankwait2:
        bit $2002
        bpl @vblankwait2
    jmp game_loop
            
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

;--------------subroutines--------------;
game_loop:
    JSR gameCode
    jmp game_loop
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
        ADC PaddleSprites, x
        STA $0200, x
        INX 

        LDA PaddleSprites, x 
        STA $0200, x
        INX

        LDA PaddleSprites, x 
        STA $0200, x
        INX 

        LDA PaddlePosX
        CLC
        ADC PaddleSprites, x
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

        LDA BallSprites, x 
        STA $0210, x
        INX

        LDA BallSprites, x 
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
            ; lose condition
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
        CLC 
        ADC #4 ; since sprites are drawn from the top left pixel, and the ball is dead center, i need to add the offset.
        CMP PaddlePosX
        BCC exit ; if its x value is less then the paddles, exit

        SEC ; set carry flag, a must have for subtraction. works reverse from addition for some reason
        SBC #PADDLE_OFFSET
        SEC 
        SBC #8 ; since sprites are drawn from the top left pixel, and the ball is dead center, i need to subtract the offset ( and the 4 from the other calculation).
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
