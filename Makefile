# Include configuration files
include config.mk
include framework.mk

# Directory Paths
BUILD_DIR		:= build
SRC_DIR			:= $(BUILD_DIR)/src
FRAMEWORK_DIR	:= $(BUILD_DIR)/framework
MAP_DIR			:= $(BUILD_DIR)/map
ELF_DIR			:= $(BUILD_DIR)/elf
DIST_DIR		:= $(BUILD_DIR)/dist

# Assembly Directory Paths
ifeq ($(ASM_ENABLED),1)
	ASM_DIR			:= $(BUILD_DIR)/asm
	ASM_SRC_DIR		:= $(ASM_DIR)/src
	ASM_LIB_DIR		:= $(ASM_DIR)/lib
endif

# Ensure build and dist directories exist
$(shell mkdir -p $(SRC_DIR) $(FRAMEWORK_DIR) $(MAP_DIR) $(ELF_DIR) $(DIST_DIR))

# Create assembly build directories if assembly is enabled
ifeq ($(ASM_ENABLED),1)
	$(shell mkdir -p $(ASM_SRC_DIR) $(ASM_LIB_DIR))
endif

# Sources and includes
SOURCES		:= $(GAME_SRC) $(FRAMEWORK_SRC)
INCLUDES	:= -I$(GAME_INC) $(addprefix -I, $(FRAMEWORK_INC))

# Object files
OBJECTS := $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(filter %.cpp,$(SOURCES)))
OBJECTS += $(patsubst %.c,$(BUILD_DIR)/%.o,$(filter %.c,$(SOURCES)))

# Assembly object files
ifeq ($(ASM_ENABLED),1)
	OBJECTS += $(patsubst %.s,$(ASM_SRC_DIR)/%.o,$(filter %.s,$(ASM_SRC)))
	OBJECTS += $(patsubst %.s,$(ASM_LIB_DIR)/%.o,$(filter %.s,$(ASM_LIB)))
endif

# Flags
ARCH		:= -mthumb-interwork -mthumb
SPECS		:= -specs=gba.specs
CFLAGS		:= $(ARCH) $(SPECS) -O2 -Wall -fno-strict-aliasing
CXXFLAGS	:= $(CFLAGS) -fno-rtti -fno-exceptions
LDFLAGS		:= $(ARCH) $(SPECS)

ifeq ($(ASM_ENABLED),1)
	ASFLAGS		:= $(ARCH)
endif

# Build targets
all: blazingred cascadingblue

blazingred: $(DIST_DIR)/blazingred.gba
	@echo "BlazingRed ROM built successfully: $@"

cascadingblue: $(DIST_DIR)/cascadingblue.gba
	@echo "CascadingBlue ROM built successfully: $@"

$(DIST_DIR)/blazingred.gba: $(OBJECTS)
	@mkdir -p $(MAP_DIR) # Ensure the map directory exists
	@mkdir -p $(ELF_DIR) # Ensure the elf directory exists
	@mkdir -p $(@D)      # Ensure the dist directory exists
	$(CXX) $(LDFLAGS) -Wl,-Map,$(MAP_DIR)/blazingred.map -o $(ELF_DIR)/blazingred.elf $^
	$(OBJCOPY) -v -O binary $(ELF_DIR)/blazingred.elf $@
	gbafix $@

$(DIST_DIR)/cascadingblue.gba: $(OBJECTS)
	@mkdir -p $(MAP_DIR) # Ensure the map directory exists
	@mkdir -p $(ELF_DIR) # Ensure the elf directory exists
	@mkdir -p $(@D)      # Ensure the dist directory exists
	$(CXX) $(LDFLAGS) -Wl,-Map,$(MAP_DIR)/cascadingblue.map -o $(ELF_DIR)/cascadingblue.elf $^
	$(OBJCOPY) -v -O binary $(ELF_DIR)/cascadingblue.elf $@
	gbafix $@

# Pattern rule for building object files
$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Pattern rule for building assembly object files
ifeq ($(ASM_ENABLED),1)
	$(ASM_SRC_DIR)/%.o: %.s
		@mkdir -p $(@D)
		$(AS) $(ASFLAGS) $(INCLUDES_ASM) -c $< -o $@

	$(ASM_LIB_DIR)/%.o: %.s
		@mkdir -p $(@D)
		$(AS) $(ASFLAGS) $(INCLUDES_ASM) -c $< -o $@
endif

# Clean up build and dist files
clean:
	rm -rf $(BUILD_DIR)
	@echo "Build artifacts cleaned"

# Create fresh build and dist directories after cleaning
reset: clean
	mkdir -p $(SRC_DIR) $(FRAMEWORK_DIR) $(MAP_DIR) $(ELF_DIR) $(DIST_DIR)
ifeq ($(ASM_ENABLED),1)
	mkdir -p $(ASM_SRC_DIR) $(ASM_LIB_DIR)
endif
	@echo "Build environment reset"

# Phony targets
.PHONY: all blazingred cascadingblue clean reset