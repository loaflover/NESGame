
# NES breakout - Loaf

A simple NES game coded in 6502 assembly.


## Features
### 👾 dynamic sprite drawing
sprites are redrawn each frame, as opposed to being drawn once and moved directly in PPU memory
### 🕹️ fully fledged control system
all NES controller inputs can be read and handeled (although currently only 2 are used)
### ⚽ excelent ball control
ball is controlled using 3 bytes only, 2 for its position and 1 for its attributes. very easy to calculate collision with simple shapes (colliders can be simplified to squares or triangles for ease)
### 🧩 modularity
each section that can be made into a subroutine or a macro is / is planned to be made into one.
### 🛠️ make file!
first goal that was reached! added a make file and clean script. still work to be donte onm it, however it works.
### 😢 game over screen
simple game over screen implemented, whith the general framework in place to add more screens.

## TODO
### 🧩🧩 increase modularity
make catagroies of subroutines and macros and split into files. then, i can have these be shared across projects.
### 🧱 bricks
every breakout game needs bricks... includes the background tiles and the table that holds their data (as with collision, obviously)
### 🏆 game over. win screen, and levels
this is a long term goal (at least the levels and win screen) as its not a core mechanic. more of a nice to have feature. basic versions have been implemented, as stated above.
### 🎵 music
music... for the game... not much to be said
## assembly instructions
to assemble, make sure to have ca65 installed and added to path. then, just run the assemble.bat script.

(if you arent aware, assembly process is taking my code and making it into a game file. to understand the difference between assembly and compilation, refer to google.com)


## run instructions
running this game is the fun part. either download an assembled ROM  from the releases tab, or assemble the source files yourself (please refer to the above section).
you should now choose an emulator. im a fan of Mesen, as it has great debugging capabilities, but any old NES emulator will do.
then, choose your rom file (should be called game.nes), open it in your emulator, and voilà! you have the game running.



## how to play

playing this game is simple. as of now, you use the right asnd left buttons on the controller (mapped differently per emulator, but safe to assume default mapping is left and right keys), and th paddle moves accordingly. then, you just hit the ball and watch it bounce. for now, thats it (more to come soon!)


# credits
while most of this code is written by me exclusively, i have some special thanks to give
### NES development server
thanks to the members of this awsome discord! all their help is incredibly appreceated. they also have a wiki, where i took my startup code (to clarify - i wrote the startup code myself, but due to having better comments and working with edge cases, i used theirs as reccomended by the server members)
link: https://discord.gg/Mf3aYvrg
### Nerdy nights
thanks to the insane nerdy nights for offering an insane tutorial, specifically the contoller handler, which is the only part of my code not written by me
link: https://nerdy-nights.nes.science/
### NESHacker
thanks to the NESHacker on youtube, for simplifying many assembly and NES concepts.
link: https://www.youtube.com/watch?v=R6KJjbbQRFk
### friends
thanks to my awsome friends, for testing the game and reading my assembly code (even though most of them know little to no assembly)
### you 
but most of all, thanks to you. any user that plays, tests and comments on this project is greatly appreceated. this project growning is directly related to reviews, if from friends (currently my only reviews), or from anyone stumbling upon this project. so, thanks (:
