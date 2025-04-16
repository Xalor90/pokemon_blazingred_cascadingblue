# Include configuration files
include config.mk
include framework.mk

# Ensure build and dist directories exist
$(shell mkdir -p build/src build/framework/src dist)
# Create assembly build directories if assembly is enabled
ifeq ($(ASM_ENABLED),1)
    $(shell mkdir -p build/asm/src build/asm/lib)
endif

# Compiler and tools configuration
CC      := arm-none-eabi-gcc
CXX     := arm-none-eabi-g++
OBJCOPY := arm-none-eabi-objcopy

# Paths
BUILD   := build
SOURCES := $(GAME_SRC) $(FRAMEWORK_SRC)
INCLUDES := -I$(GAME_INC) -I$(FRAMEWORK_INC)

# Assembly handling
ifeq ($(ASM_ENABLED),1)
    SOURCES += $(ASM_SRC)
    INCLUDES += $(INCLUDES_ASM)
endif

# Object files
OBJECTS := $(patsubst %.cpp,$(BUILD)/%.o,$(filter %.cpp,$(SOURCES)))
OBJECTS += $(patsubst %.c,$(BUILD)/%.o,$(filter %.c,$(SOURCES)))
OBJECTS += $(patsubst %.s,$(BUILD)/%.o,$(filter %.s,$(SOURCES)))

# Flags
ARCH    := -mthumb-interwork -mthumb
SPECS   := -specs=gba.specs
CFLAGS  := $(ARCH) $(SPECS) -O2 -Wall -fno-strict-aliasing
CXXFLAGS := $(CFLAGS) -fno-rtti -fno-exceptions
LDFLAGS := $(ARCH) $(SPECS) -Wl,-Map,$(BUILD)/$(TARGET).map

# Build target
all: dist/$(TARGET).gba

dist/$(TARGET).gba: $(BUILD)/$(TARGET).elf
	$(OBJCOPY) -v -O binary $< $@
	gbafix $@
	@echo "ROM built successfully: $@"

$(BUILD)/$(TARGET).elf: $(OBJECTS)
	@mkdir -p $(@D)
	$(CXX) $(LDFLAGS) -o $@ $(OBJECTS)

# Pattern rule for building object files
$(BUILD)/%.o: %.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(BUILD)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(BUILD)/%.o: %.s
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Clean up build files
clean:
	rm -rf $(BUILD) dist
	@echo "Build artifacts cleaned"

# Create fresh build and dist directories after cleaning
reset: clean
	mkdir -p $(BUILD)/src $(BUILD)/framework/src dist
ifeq ($(ASM_ENABLED),1)
	mkdir -p $(BUILD)/asm/src $(BUILD)/asm/lib
endif
	@echo "Build environment reset"

# Phony targets
.PHONY: all clean reset