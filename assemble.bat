ca65 game.s -g -o game.o -t nes
ca65 ppu_variables.s -g -o ppu_variables.o -t nes
ld65 -o game.nes game.o ppu_variables.o -t nes