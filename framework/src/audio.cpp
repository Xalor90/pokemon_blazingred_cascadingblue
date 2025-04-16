#include "audio.hpp"

void Audio::Initialize() {
    // Enable sound hardware
    REG_SOUNDCNT_X = SND_ENABLED;

    // Set sound control registers
    REG_SOUNDCNT_L = 0x77; // Left and right volume full
    REG_SOUNDCNT_H = 0xB0F; // Enable DS A/B, set timer 0/1
}

void Audio::PlaySound(const void* soundData, u32 length) {
    // Play sound using Direct Sound A
    REG_DMA1CNT = 0; // Stop DMA1
    REG_DMA1SAD = (u32)soundData; // Source address
    REG_DMA1DAD = (u32)&REG_FIFO_A; // Destination address (FIFO A)
    REG_DMA1CNT = DMA_ENABLE | DMA_TIMING_FIFO | DMA_32; // Enable DMA1

    // Set timer 0 for sound playback
    REG_TM0CNT_L = 0; // Reset timer
    REG_TM0CNT_H = TIMER_START | TIMER_FREQ_1024; // Start timer with frequency
}

void Audio::PlayMusic(const void* musicData, u32 length) {
    // Play music using Direct Sound B
    REG_DMA2CNT = 0; // Stop DMA2
    REG_DMA2SAD = (u32)musicData; // Source address
    REG_DMA2DAD = (u32)&REG_FIFO_B; // Destination address (FIFO B)
    REG_DMA2CNT = DMA_ENABLE | DMA_TIMING_FIFO | DMA_32; // Enable DMA2

    // Set timer 1 for music playback
    REG_TM1CNT_L = 0; // Reset timer
    REG_TM1CNT_H = TIMER_START | TIMER_FREQ_1024; // Start timer with frequency
}