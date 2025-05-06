# Default value for assembly support
GBA_ASM_SUPPORT := 0

# Include local override configuration, if it exists.
-include config.local.mk

# Compiler and tools configuration
PREFIX	:= arm-none-eabi-
CC		:= $(PREFIX)gcc
CXX		:= $(PREFIX)g++
OBJCOPY	:= $(PREFIX)objcopy

ifeq ($(ASM_ENABLED),1)
	AS	:= $(PREFIX)as
endif

# Game-specific configuration
TARGET	:= my_game
SRC_DIR	:= src
SRC		:= $(wildcard $(SRC_DIR)/*.cpp) $(wildcard $(SRC_DIR)/*.c)
INC		:= include

# Assembly support
# Check if GBA_ASM_SUPPORT environment variable is set
# This is set by install.ps1 when -WithAssembly flag is used
ifeq ($(GBA_ASM_SUPPORT),1)
	ASM_ENABLED		:= 1
	ASM_DIR			:= asm
	ASM_SRC_DIR		:= $(ASM_DIR)/src
	ASM_LIB_DIR		:= $(ASM_DIR)/lib
	ASM_SRC			:= $(wildcard $(ASM_SRC_DIR)/*.s)
	ASM_LIB			:= $(wildcard $(ASM_LIB_DIR)/*.s)
	ASM_INC			:= $(ASM_DIR)/include
	ASM_MACROS		:= $(ASM_DIR)/macros
	INCLUDES_ASM	:= -I$(ASM_INC) -I$(ASM_MACROS)
else
	ASM_ENABLED		:= 0
	ASM_DIR			:=
	ASM_SRC_DIR		:=
	ASM_LIB_DIR		:=
	ASM_SRC			:=
	ASM_LIB			:=
	ASM_INC			:=
	ASM_MACROS		:=
	INCLUDES_ASM	:=
endif