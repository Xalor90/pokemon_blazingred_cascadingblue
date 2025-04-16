#ifndef INPUT_HPP
#define INPUT_HPP

#include "gba_framework.hpp" // Include the main GBA framework header

/**
 * @class Input
 * @brief Provides functionality for handling key input on the GBA.
 */
class Input {
public:
    /**
     * @brief Gets the keys pressed in the current frame.
     * 
     * @return A bitmask of keys pressed (e.g., KEY_A, KEY_B).
     */
    static u16 GetKeysPressed();

    /**
     * @brief Gets the keys currently held down.
     * 
     * @return A bitmask of keys held (e.g., KEY_A, KEY_B).
     */
    static u16 GetKeysHeld();
};

#endif // INPUT_HPP