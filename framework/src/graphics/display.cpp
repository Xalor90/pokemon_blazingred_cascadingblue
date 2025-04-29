#include "display.hpp"

void Graphics::Display::SetMode(u16 mode) {
    REG_DISPCNT = mode;
}

void Graphics::Display::EnableBackground(u16 bgFlags) {
    REG_DISPCNT |= bgFlags;
}