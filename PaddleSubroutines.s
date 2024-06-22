.include "Globals.asm" ; this whole thing is just done so globals can be seen everywhere.
.segment "STARTUP"
    
    .export drawPaddle, MovePaddle
    .importzp buttons,frame_ready,PaddlePosX,ballPosX,ballPosY,ballProperties,gamestate, SubroutineInput
    .import PaddleSprites
    .import ReadController
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