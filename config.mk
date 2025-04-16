# Default value for assembly support
GBA_ASM_SUPPORT := 0

# Include local override configuration, if it exists.
-include config.local.mk

# Game-specific configuration
TARGET := game
GAME_SRC :=  $(wildcard src/*.cpp)
GAME_INC := include

# Assembly support
# Check if GBA_ASM_SUPPORT environment variable is set
# This is set by install.ps1 when -WithAssembly flag is used
ifeq ($(GBA_ASM_SUPPORT),1)
    ASM_ENABLED := 1
    ASM_SRC := $(wildcard asm/src/*.s) $(wildcard asm/lib/*.s)
    ASM_INC := asm/include
    ASM_MACROS := asm/macros
    INCLUDES_ASM := -I$(ASM_INC) -I$(ASM_MACROS)
    $(info Assembly support enabled)
else
    ASM_ENABLED := 0
    ASM_SRC :=
    ASM_INC :=
    ASM_MACROS :=
    INCLUDES_ASM :=
    $(info Assembly support disabled. Run install.ps1 -WithAssembly to enable)
endif