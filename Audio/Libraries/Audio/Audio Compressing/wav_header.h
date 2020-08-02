/******************************************************************************
 * Copyright (C)
 *
 * File:
 *
 * Description:
 *
 * History:
 *
 *
 ******************************************************************************/
#include <stdint.h>

//=============================================================================
//==[ Definitions ]============================================================
//=============================================================================

//=============================================================================
//==[ Types ]==================================================================
//=============================================================================
typedef struct waveHeader1_struct {
	char chunkID[4];		// Contains the letters "RIFF" in ASCII form
    
	uint32_t chunkSize;		// 36 + <number of raw audio bytes>, or more precisely:
    // 4 + (8 + SubChunk1Size) + (8 + SubChunk2Size)
    // This is the size of the rest of the chunk
    // following this number.  This is the size of the
    // entire file in bytes minus 8 bytes for the
    // two fields not included in this count:
    // ChunkID and ChunkSize.
    
	char format[4];			// Contains the letters "WAVE"
    
    // The "WAVE" format consists of two subchunks: "fmt " and "data":
    // The "fmt " subchunk describes the sound data's format:
    
	char subchunk1ID[4];	// Contains the letters "fmt "
    
	uint32_t subchunk1Size;	// 16 for PCM.  This is the size of the
    // rest of the Subchunk which follows this number.
    
    
	uint16_t audioFormat;	// PCM = 1 (i.e. Linear quantization)
    // Values other than 1 indicate some
    // form of compression.
    
	uint16_t numChannels;	// Mono = 1, Stereo = 2, etc.
	
	uint32_t sampleRate;	// 8000, 44100, etc.
	uint32_t byteRate;		// == SampleRate * NumChannels * BitsPerSample/8
	
	uint16_t blockAlign;	// == NumChannels * BitsPerSample/8
    // The number of bytes for one sample including
    // all channels. I wonder what happens when
    // this number isn't an integer?
    
	uint16_t bitsPerSample;	// 8 bits = 8, 16 bits = 16, etc.
    
    //	uint16_t extraParamSize	// if PCM, then doesn't exist
    //			 extraParams      space for extra parameters
    
    // The "data" subchunk contains the size of the data and the actual sound:
    
	char subchunk2ID[4];	// Contains the letters "data"
    
	uint32_t subchunk2Size;	// == NumSamples * NumChannels * BitsPerSample/8
    // This is the number of bytes in the data.
    // You can also think of this as the size
    // of the read of the subchunk following this
    // number.
} waveHeader2_t;

//=============================================================================
//==[ Prototypes ]=============================================================
//=============================================================================
void testWavHeader (const char* wav_filename, uint32_t raw_audio_bytes);
