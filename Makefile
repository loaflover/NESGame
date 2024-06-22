# Makefile for building my NES game

# Define assembler and linker
AS = ca65
LD = ld65
# Define the target platform
TARGET = nes
# Output binary
OUTPUT = game.nes

# Source files
SOURCES = $(wildcard *.s)

# Object files
OBJECTS = $(SOURCES:.s=.o)



# Rules
all: $(OUTPUT)

# Assemble .s files to .o files
%.o: %.s
	$(AS) $< -g -o $@ -t $(TARGET)

# Link .o files to create the final binary
$(OUTPUT): $(OBJECTS)
	$(LD) -o $@ $^ -t $(TARGET)

# Clean rule for Windows
clean:
	del /s *.o *.nes

.PHONY: all clean
