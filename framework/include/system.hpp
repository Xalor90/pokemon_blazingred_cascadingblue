#ifndef SYSTEM_HPP
#define SYSTEM_HPP

#include "gba_framework.hpp" // Include the main GBA framework header

/**
 * @class System
 * @brief Handles core GBA system functionality, such as memory resets, interrupts, and synchronization.
 */
class System {
public:
    /**
     * @brief Initializes the GBA system.
     * 
     * Resets memory regions, initializes interrupts, and sets up the display control register.
     */
    static void Initialize();

    /**
     * @brief Waits for the VBlank interrupt.
     * 
     * Synchronizes updates with the display refresh rate to avoid tearing or glitches.
     */
    static void WaitForVBlank();

    /**
     * @brief Resets memory regions.
     * 
     * @param flags Flags specifying which memory regions to reset.
     */
    static void RegisterRamReset(u16 flags);

    /**
     * @brief Initializes the interrupt system.
     */
    static void irqInit();

    /**
     * @brief Enables specific interrupts.
     * 
     * @param flags Flags specifying which interrupts to enable.
     */
    static void irqEnable(u16 flags);
};

#endif // SYSTEM_HPP