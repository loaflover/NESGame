.include "Globals.asm" ; this whole thing is just done so globals can be seen everywhere.
.segment "STARTUP"
    
    
    .export BallCollisionTest, drawBall, MoveBall
    .importzp buttons,frame_ready,PaddlePosX,ballPosX,ballPosY,ballProperties,gamestate, SubroutineInput
    .import BallSprites
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
                LDA #GAME_OVER
                STA gamestate
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

            ;since the paddle is bound to screen, it means its edges will never be below or over 00 and FF. the balkl however, since it is 1 sprite, can be less then 0, so subtracting the paddle offset from it will cause issues at edges, as 00 - 18 = E8 (iirc)
            LDA PaddlePosX
            CLC 
            ADC #PADDLE_OFFSET
            CLC 
            ADC #4 ; since sprites are drawn from the top left pixel, and the ball is dead center, i need to add the offset.
            CMP ballPosX
            BCC exit ; if its x value is greater then then the paddles plus offset, exit

            LDA ballProperties
            EOR #VERTICAL_BALL_MASK
            STA ballProperties
        exit:
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
