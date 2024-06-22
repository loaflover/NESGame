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



        LDX #$FF ; initialize stack
        TXS 

        SEI ;disable interrupts
        CLD ; turn off decimal mode

        LDX #%1000000 ; disable sound IRQ
        STX $4017

        LDX #$00 ; disable PCM
        STX $4010

        

        LDX #$00 ; clear PPU registers
        STX $2000
        STX $2001


        @vblankwait1:  
            bit $2002
            bpl @vblankwait1

            ; We now have about 30,000 cycles to burn before the PPU stabilizes.
            ; One thing we can do with this time is put RAM in a known state.
            ; Here we fill it with $00, which matches what (say) a C compiler
            ; expects for BSS.  Conveniently, X is still 0.
            txa
        @clrmem:
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
            bne @clrmem

            ; Other things you can do between vblank waits are set up audio
            ; or set up other mapper registers.
        
        @vblankwait2:
            bit $2002
            bpl @vblankwait2


        LDA #$02 ; copy sprites to the right address
        STA $4014
        NOP ; wait for copy to complete



        LDA #$3F ; this whole section tells the cpu to write to memory address $3f00
        STA $2006
        LDA #$00
        STA $2006

        LDX #$00
        LOADPALETTES:
            LDA Palettes, x ; loads palletes to memory. $2007 increments automatically.
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

;--------------subroutines--------------;





gameCode:
    ; checks if NMI has run yet
    :
    LDA frame_ready
    BEQ :- 
    ; global subroutines for every frame
    JSR disable_all_oam_entries
    ; call subroutine based on gamestate
    LDA gamestate
    CMP #TITLE_SCREEN
    BEQ title_screen_code
    CMP #GAME_OVER
    BEQ game_over_code

    JMP main_game ; if no other gamemode applies, it means were in a game loop
    end_Game_logic:
    ; set frame_ready to 0, so game code doesnt run again
    LDA #$00
    STA frame_ready
    RTS
    main_game:
        JSR MovePaddle
        JSR drawPaddle

        JSR BallCollisionTest
        JSR MoveBall
        JSR drawBall
        JMP end_Game_logic
    game_over_code:
        JSR MovePaddle
        JSR drawPaddle

        JSR BallCollisionTest
        JSR MoveBall
        JSR drawBall
        JMP end_Game_logic
    title_screen_code:
        JSR MovePaddle
        JSR drawPaddle

        JSR BallCollisionTest
        JSR MoveBall
        JSR drawBall
        JMP end_Game_logic

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
drawBackground:
    LoadBackground:

        LDA $2002             ; read PPU status to reset the high/low latch
        LDA #$20
        STA $2006             ; write the high byte of $2000 address
        LDA #$00
        STA $2006             ; write the low byte of $2000 address
        LDX #$00              ; start out at 0
    LoadBackgroundLoop:
        LDA background, x     ; load data from address (background + the value in x)
        STA $2007             ; write to PPU
        INX                   ; X = X + 1
        CPX #$80              ; Compare X to hex $80, decimal 128 - copying 128 bytes
        BNE LoadBackgroundLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
    LoadAttribute:
        LDA $2002             ; read PPU status to reset the high/low latch
        LDA #$23
        STA $2006             ; write the high byte of $23C0 address
        LDA #$C0
        STA $2006             ; write the low byte of $23C0 address
        LDX #$00              ; start out at 0
    LoadAttributeLoop:
        LDA attribute, x      ; load data from address (attribute + the value in x)
        STA $2007             ; write to PPU
        INX                   ; X = X + 1
        CPX #$08              ; Compare X to hex $08, decimal 8 - copying 8 bytes
        BNE LoadAttributeLoop


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
