#include "system.hpp"

void System::Initialize() {
    // Reset memory regions (excluding IWRAM for modern compilers)
    RegisterRamReset(RESET_ALL & ~RESET_IWRAM);

    // Initialize interrupts
    irqInit();
    irqEnable(IRQ_VBLANK);

    // Set default display control (no backgrounds enabled by default)
    REG_DISPCNT = 0;
}

void System::WaitForVBlank() {
    // Wait for the VBlank interrupt to synchronize updates
    while (!(REG_IF & IRQ_VBLANK)) {
        // Spin until VBlank occurs
    }
    REG_IF = IRQ_VBLANK; // Clear the VBlank interrupt flag
}

void System::RegisterRamReset(u16 flags) {
    // Stub implementation for memory reset
    (void)flags; // No-op for now
}

void System::irqInit() {
    // Stub implementation for interrupt initialization
    REG_IME = 0; // Disable interrupts
    REG_IE = 0;  // Clear interrupt enable flags
    REG_IF = 0;  // Clear interrupt flags
    REG_IME = 1; // Enable interrupts
}

void System::irqEnable(u16 flags) {
    // Enable specific interrupts
    REG_IE |= flags;
}