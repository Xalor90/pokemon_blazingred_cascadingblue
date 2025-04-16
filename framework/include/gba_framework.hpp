#ifndef GBA_FRAMEWORK_HPP
#define GBA_FRAMEWORK_HPP

#include <cstdint> // For standard integer types

// Define GBA-specific types
using u8 = uint8_t;
using u16 = uint16_t;
using u32 = uint32_t;

// Define GBA hardware registers
#define REG_DISPCNT (*(volatile u16*)0x4000000)
#define REG_IME (*(volatile u16*)0x4000208) // Interrupt Master Enable
#define REG_IE (*(volatile u16*)0x4000200)  // Interrupt Enable
#define REG_IF (*(volatile u16*)0x4000202)  // Interrupt Flags
#define REG_KEYINPUT (*(volatile u16*)0x4000130)
#define REG_SOUNDCNT_X (*(volatile u16*)0x4000084)
#define REG_SOUNDCNT_L (*(volatile u16*)0x4000080)
#define REG_SOUNDCNT_H (*(volatile u16*)0x4000082)
#define REG_DMA1SAD (*(volatile u32*)0x40000BC)
#define REG_DMA1DAD (*(volatile u32*)0x40000C0)
#define REG_DMA1CNT (*(volatile u32*)0x40000C4)
#define REG_DMA2SAD (*(volatile u32*)0x40000C8)
#define REG_DMA2DAD (*(volatile u32*)0x40000CC)
#define REG_DMA2CNT (*(volatile u32*)0x40000D0)
#define REG_FIFO_A (*(volatile u32*)0x40000A0)
#define REG_FIFO_B (*(volatile u32*)0x40000A4)
#define REG_TM0CNT_L (*(volatile u16*)0x4000100)
#define REG_TM0CNT_H (*(volatile u16*)0x4000102)
#define REG_TM1CNT_L (*(volatile u16*)0x4000104)
#define REG_TM1CNT_H (*(volatile u16*)0x4000106)

// Define constants for display modes
#define MODE_0 0x0000
#define MODE_1 0x0001
#define MODE_2 0x0002
#define BG0_ENABLE 0x0100
#define BG1_ENABLE 0x0200

// Define constants for input keys
#define KEY_A 0x0001
#define KEY_B 0x0002
#define KEY_SELECT 0x0004
#define KEY_START 0x0008
#define KEY_RIGHT 0x0010
#define KEY_LEFT 0x0020
#define KEY_UP 0x0040
#define KEY_DOWN 0x0080
#define KEY_R 0x0100
#define KEY_L 0x0200
#define KEY_MASK 0x03FF

// Define constants for memory reset
#define RESET_ALL 0xFF
#define RESET_IWRAM 0x01

// Define constants for interrupts
#define IRQ_VBLANK 0x0001

// Define constants for sound
#define SND_ENABLED 0x0080

// Define constants for DMA
#define DMA_ENABLE 0x80000000
#define DMA_TIMING_FIFO 0x00000040
#define DMA_32 0x04000000

// Define constants for timers
#define TIMER_START 0x0080
#define TIMER_FREQ_1024 0x0003

// Core system functionality
#include "system.hpp"

// Graphics functionality
#include "graphics.hpp"

// Input handling
#include "input.hpp"

// Audio management
#include "audio.hpp"

#endif // GBA_FRAMEWORK_HPP