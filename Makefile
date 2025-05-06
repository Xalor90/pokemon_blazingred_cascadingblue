# Include configuration files
include config.mk

# Directory Paths
BUILD_DIR		:= build
SRC_BUILD_DIR	:= $(BUILD_DIR)/src
MAP_DIR			:= $(BUILD_DIR)/map
ELF_DIR			:= $(BUILD_DIR)/elf
DIST_DIR		:= $(BUILD_DIR)/dist

# Assembly Directory Paths
ifeq ($(ASM_ENABLED),1)
	ASM_BUILD_DIR		:= $(BUILD_DIR)/asm
	ASM_SRC_BUILD_DIR	:= $(ASM_BUILD_DIR)/src
	ASM_LIB_BUILD_DIR	:= $(ASM_BUILD_DIR)/lib
endif

# Include Framework Configuration
include framework.mk

# Ensure build and dist directories exist
$(shell mkdir -p $(SRC_BUILD_DIR) $(FRAMEWORK_BUILD_DIR) $(MAP_DIR) $(ELF_DIR) $(DIST_DIR))

# Create assembly build directories if assembly is enabled
ifeq ($(ASM_ENABLED),1)
	$(shell mkdir -p $(ASM_SRC_BUILD_DIR) $(ASM_LIB_BUILD_DIR))
endif

# Sources and includes
SOURCES		:= $(SRC)
INCLUDES	:= -I$(INC) $(FRAMEWORK_INCLUDES)

# Object files
OBJECTS		:= $(patsubst $(SRC_DIR)/%.cpp,$(SRC_BUILD_DIR)/%.o,$(filter %.cpp,$(SOURCES)))
OBJECTS		+= $(patsubst $(SRC_DIR)/%.c,$(SRC_BUILD_DIR)/%.o,$(filter %.c,$(SOURCES)))

# Assembly object files
ifeq ($(ASM_ENABLED),1)
	OBJECTS += $(patsubst $(ASM_SRC_DIR)/%.s,$(ASM_SRC_BUILD_DIR)/%.o,$(filter %.s,$(ASM_SRC)))
	OBJECTS += $(patsubst $(ASM_LIB_DIR)/%.s,$(ASM_LIB_BUILD_DIR)/%.o,$(filter %.s,$(ASM_LIB)))
endif

# Framework object files
OBJECTS		+= $(FRAMEWORK_OBJECTS)

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
	$(ASM_SRC_BUILD_DIR)/%.o: %.s
		@mkdir -p $(@D)
		$(AS) $(ASFLAGS) $(INCLUDES_ASM) -c $< -o $@

	$(ASM_LIB_BUILD_DIR)/%.o: %.s
		@mkdir -p $(@D)
		$(AS) $(ASFLAGS) $(INCLUDES_ASM) -c $< -o $@
endif

# Pattern rule for building framework object files
$(FRAMEWORK_BUILD_DIR)/%.o: $(FRAMEWORK_SRC_DIR)/%.cpp
	@mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(FRAMEWORK_INCLUDES) -c $< -o $@

# Clean up build and dist files
clean:
	rm -rf $(BUILD_DIR)
	@echo "Build artifacts cleaned"

# Create fresh build and dist directories after cleaning
reset: clean
	mkdir -p $(SRC_BUILD_DIR) $(FRAMEWORK_BUILD_DIR) $(MAP_DIR) $(ELF_DIR) $(DIST_DIR)
ifeq ($(ASM_ENABLED),1)
	mkdir -p $(ASM_SRC_BUILD_DIR) $(ASM_LIB_BUILD_DIR)
endif
	@echo "Build environment reset"

# Phony targets
.PHONY: all blazingred cascadingblue clean reset