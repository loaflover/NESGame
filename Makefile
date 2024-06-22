# Makefile for building my NES game

# Define assembler and linker
AS = ca65
LD = ld65

# Define the target platform
TARGET = nes

# Define directories
CODE_DIR = src
OUTPUT_DIR = build

# Output binary
OUTPUT = $(OUTPUT_DIR)/game.nes

# Source files
SOURCES = $(wildcard $(CODE_DIR)/*.s)

# Object files
OBJECTS = $(patsubst $(CODE_DIR)/%.s, $(OUTPUT_DIR)/%.o, $(SOURCES))

# Rules
all: $(OUTPUT)

# Create output directory if it doesn't exist
$(OUTPUT_DIR):
	mkdir $(OUTPUT_DIR)

# Assemble .s files to .o files
$(OUTPUT_DIR)/%.o: $(CODE_DIR)/%.s | $(OUTPUT_DIR)
	$(AS) $< -g -o $@ -t $(TARGET)

# Link .o files to create the final binary
$(OUTPUT): $(OBJECTS)
	$(LD) -o $@ $^ -t $(TARGET)

# Clean rule for Windows
clean:
	del /s *.o $(OUTPUT)

.PHONY: all clean
