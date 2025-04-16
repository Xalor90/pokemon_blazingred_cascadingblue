#include "input.hpp"

u16 Input::GetKeysPressed() {
    static u16 prevKeys = 0;
    u16 currentKeys = ~REG_KEYINPUT & KEY_MASK;
    u16 pressedKeys = currentKeys & ~prevKeys;
    prevKeys = currentKeys;
    return pressedKeys;
}

u16 Input::GetKeysHeld() {
    return ~REG_KEYINPUT & KEY_MASK;
}