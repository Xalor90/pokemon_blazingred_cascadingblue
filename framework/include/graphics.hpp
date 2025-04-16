#ifndef GRAPHICS_HPP
#define GRAPHICS_HPP

#include "gba_framework.hpp" // Include the main GBA framework header

/**
 * @namespace Graphics
 * @brief Provides functionality for managing the GBA's graphics system, including display modes and rendering.
 */
namespace Graphics {

    /**
     * @class Display
     * @brief Handles display settings and background management.
     */
    class Display {
    public:
        /**
         * @brief Sets the display mode.
         * 
         * @param mode The display mode to set (e.g., MODE_0, MODE_1).
         */
        static void SetMode(u16 mode);

        /**
         * @brief Enables specific background layers.
         * 
         * @param bgFlags Flags for the background layers to enable (e.g., BG0_ENABLE, BG1_ENABLE).
         */
        static void EnableBackground(u16 bgFlags);
    };
}

#endif // GRAPHICS_HPP