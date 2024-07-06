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

    .import GameOverBG, WinBG, Palettes, PaddleSprites, BallSprites, LevelBG
    .importzp buttons,frame_ready,PaddlePosX,ballPosX,ballPosY,ballProperties,gamestate, SubroutineInput
    .import drawPaddle, MovePaddle
    .import BallCollisionTest, drawBall, MoveBall
    .export ReadController, switch_scene_Background

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
        
        ; setting variables 
        LDX #128
        STX PaddlePosX
        STX ballPosX
        STX ballPosY
        LDX #%00000001
        STX ballProperties
        LDX #00
        STX gamestate
        CLI ; enable interrupts
        LDA #%10010000 ; generate NMI when Vblank happens. second bit tells PPU to use the second half of the sprites for background.
        STA $2000 
        LDA #%00011110 ; show sprites and background
        STA $2001
        ;JSR drawBackground
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
        JSR ReadController
        LDX buttons ; load buttons into register x
        CPX #%10000000
        BNE end_Game_logic
        JMP reset

        JMP end_Game_logic
    title_screen_code:
        ;JSR drawBackground
        JMP end_Game_logic


switch_scene_Background:
    LDA gamestate
    CMP #WIN_SCREEN
    BEQ win
    CMP #GAME_OVER
    BEQ game_over

    JMP level

    ; maybe add some exit code so the jsr and rts arent called each time?
    game_over:
        LDA #<GameOverBG 
        STA SubroutineInput 
        LDA #>GameOverBG 
        STA SubroutineInput+1 
        JSR drawBackground
        RTS
    win:
        LDA #<WinBG 
        STA SubroutineInput 
        LDA #>WinBG 
        STA SubroutineInput+1 
        JSR drawBackground
        RTS
    level:
        LDA #<LevelBG 
        STA SubroutineInput 
        LDA #>LevelBG 
        STA SubroutineInput+1 
        JSR drawBackground
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
    LDX #$00 ; clear PPU registers
    STX $2001
    STX $2000
    LoadBackground:
        LDA $2002             ; read PPU status to reset the high/low latch
        LDA #$20
        STA $2006             ; write the high byte of $2000 address
        LDA #$00
        STA $2006             ; write the low byte of $2000 address

        
        LDY #0
        LDX #4
        LoadBackgroundLoop:
            LDA (SubroutineInput),y 
            STA $2007 
            INY 
            BNE LoadBackgroundLoop
            INC SubroutineInput+1 
            DEX 
            BNE LoadBackgroundLoop
    LDA #%10010000 ; generate NMI when Vblank happens. second bit tells PPU to use the second half of the sprites for background.
    STA $2000 
    LDA #%00011110 ; show sprites and background
    STA $2001
    RTS


WaitForVblank:
    BIT $2002
    BPL WaitForVblank
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

; ------------------ variables (nonzpage) --------------;
.endproc
.segment "VECTORS"
    .word nmi, reset, 0
.segment "CHARS"
    .incbin "tiles.chr"
