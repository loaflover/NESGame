.exportzp buttons,frame_ready,PaddlePosX,ballPosX,ballPosY,ballProperties,gamestate, SubroutineInput
.segment "ZEROPAGE"
    buttons: .RES 1
    ; bit:       7     6     5     4     3     2     1     0
    ; button:    A     B   select start  up   down  left right
    frame_ready: .RES 1

    PaddlePosX: .RES 1 ; these signify the leftmost paddle piece

    ballPosX: .RES 1
    ballPosY: .RES 1
    ballProperties: .RES 1 ; last bit signifies if it is moving. if last bit is 0, no move. next bit signifies up/down. 1 is up, 0 is down. next bit signifies left/right. 1 is left, 0 is right. rest are unused as of now.
    ; so a ball moving up and right would be equal to 00000101

    gamestate: .RES 1 ; as declared in CONSTANTS
    SubroutineInput: .RES 2