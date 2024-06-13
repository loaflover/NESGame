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

        : ; this waits for vblink. the :- looks back at the last blank label, which just so happens to be on this line
        BIT $2002
        BPL :-


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
        : ; wait for another vblank
        BIT $2002
        BPL :-

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
        LDX #$00
        LOADSPRITES:
            LDA SPRITEDATA, x ; loads palletes to memory. $2007 increments automatically.
            STA $0200, x
            INX 
            CPX #$10 ; 4 sprites times 4 bytes per sprite
            BNE LOADSPRITES

        CLI ; enable interrupts
        LDA #%10010000 ; generate NMI when Vblank happens. second bit tells PPU to use the second half of the sprites for background.
        STA $2000 
        LDA #%00011110 ; show sprites and background
        STA $2001
        forever:



            ; read input
            jmp forever

;-----------------------------------;
    nmi:
    
    LDA #$02 ; load sprite range
    STA $4014
    JSR ReadController
    LDX buttons ; load buttons into register x
    CPX #0
    BEQ  nopress
    LDA $0203   ; load sprite X (horizontal) position
    CLC         ; make sure the carry flag is clear
    ADC #$01    ; A = A + 1
    STA $0203   ; save sprite X (horizontal) position
    nopress:
    rti
;-----------------------------------;
PALETTEDATA:
	.byte $00, $0F, $01, $10, 	$00, $0A, $15, $01, 	$00, $29, $28, $27, 	$00, $34, $24, $14 	;background palettes
	.byte $31, $0F, $15, $30, 	$00, $0F, $11, $30, 	$00, $0F, $30, $27, 	$00, $3C, $2C, $1C 	;sprite palettes
    SPRITEDATA:
    ;Y, SPRITE NUM, attributes, X
	.byte $40, $01, $00, $40
	.byte $40, $02, $00, $48
	.byte $40, $03, $00, $50
	.byte $40, $04, $00, $58

;--------------subroutines--------------;
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
        RTS
.segment "VECTORS"
    .word nmi, reset, 0
.segment "CHARS"
    .incbin "tiles.chr"
