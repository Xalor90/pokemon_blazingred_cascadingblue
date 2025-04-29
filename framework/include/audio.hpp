#ifndef AUDIO_HPP
#define AUDIO_HPP

#include "gba_framework.hpp" // Include the main GBA framework header

/**
 * @class Audio
 * @brief Manages audio playback, including sound effects and music.
 */
class Audio {
public:
    /**
     * @brief Initializes the audio system.
     * 
     * Sets up the sound control registers and prepares the audio system for playback.
     */
    static void Initialize();

    /**
     * @brief Plays a sound effect.
     * 
     * @param soundData Pointer to the sound data.
     * @param length Length of the sound data in bytes.
     */
    static void PlaySound(const void* soundData, u32 length);

    /**
     * @brief Plays background music.
     * 
     * @param musicData Pointer to the music data.
     * @param length Length of the music data in bytes.
     */
    static void PlayMusic(const void* musicData, u32 length);
};

#endif // AUDIO_HPP