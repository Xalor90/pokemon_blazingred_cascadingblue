#include "gba_framework.hpp" // Include the main GBA framework header

int main() {
    // Initialize the GBA system
    System::Initialize();

    // Set display mode to Mode 0 and enable background 0
    Graphics::Display::SetMode(MODE_0);
	Graphics::Display::EnableBackground(BG0_ENABLE);

    // Main loop
    while (true) {
        // Handle input
        u16 keys = Input::GetKeysPressed();
        if (keys & KEY_A) {
            // Do something when A is pressed
        }

        // Wait for VBlank
        System::WaitForVBlank();
    }

    return 0;
}