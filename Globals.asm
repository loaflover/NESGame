.segment "CONSTANTS"

    
    ; OAM sprite attributes 
        OAM_Y_POS = 0 ; these 4 symbols let me use a sprites memory address plus these to get the correct sprite attribute
        OAM_TILE = 1
        OAM_ATTRIBUTES = 2
        OAM_X_POS = 3
        ONE_SPRITE = 4 ; this is the size of 1 whole sprite. to move to next sprite (at the same attribute!) add this.
        SHADOW_OAM := $0200 ; this is the address of the shadow OEM. or, the local copy of the PPU sprite table before its copied to the PPU
    ; screen limits
        MAX_Y = 0 ; max y seems swapped with min y but no, screen just loops early (top of screen is not FF but instead 0)
        MIN_Y = $E1
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
    ; game states
        TITLE_SCREEN = $FF
        GAME_OVER = $FE ; will display the game over screen for a certein length. then move to startup
        STARTUP = $FD ; will do stuff like clearing memory for one frame. then, will move to title screen
        WIN_SCREEN = $FC ; will display the win screen for a certein length. then move to startup
        GOAL_SCREEN = $FC ; some levels might have other goals. this loads before the level starts. will display for a certein length. then move to main level code
        ; everything else is levels. anything undefined will likely be chnaged to title screen.
        ; start level is always 00.
        LAST_LEVEL = $00 ; last level i am set up to run. 