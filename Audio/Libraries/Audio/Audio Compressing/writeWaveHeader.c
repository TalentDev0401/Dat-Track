/*****************************************************************************
 * Function: writeWavHeader
 *
 * Description: write wav header to file
 *
 * Parameters: raw_audio_bytes (bytes, not samples)
 *
 * Returns: nothing
 *
 *****************************************************************************/
#include "wav_header.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

void testWavHeader (const char* wav_filename, uint32_t raw_audio_bytes) {
	waveHeader2_t waveHeader;
	
	strncpy(waveHeader.chunkID, "RIFF", 4);
	waveHeader.chunkSize = 36 + raw_audio_bytes;
	strncpy(waveHeader.format, "WAVE", 4);
	strncpy(waveHeader.subchunk1ID, "fmt ", 4);
	waveHeader.subchunk1Size = 16; // for PCM
	waveHeader.audioFormat = 1; // for PCM
	waveHeader.numChannels = 1; // mono
	waveHeader.sampleRate = 8000; // 8Khz
	waveHeader.byteRate = 16000;
	waveHeader.blockAlign = 2; // 2 bytes per sample
	waveHeader.bitsPerSample = 16;
	strncpy(waveHeader.subchunk2ID, "data", 4);
	waveHeader.subchunk2Size = raw_audio_bytes;
	
	// test code
	{
		FILE *pfile = fopen(wav_filename, "wb");
        if( pfile == NULL ) {
            printf( "failed opening %s for writing\n", wav_filename );
        } else {
            // write wav file waveHeader (44 bytes)
            fwrite(&waveHeader, 1, sizeof(waveHeader2_t), pfile);
        }
		fclose(pfile);
	}
}
