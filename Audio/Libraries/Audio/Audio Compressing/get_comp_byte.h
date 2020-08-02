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
#include <Accelerate/Accelerate.h>

//=============================================================================
//==[ Definitions ]============================================================
//=============================================================================
#define TRUE 1
#define FALSE 0

#define PCM_BIT_DEPTH 16

#define SAMP_PER_STAIR 40

#define SAMP_PER_SEC 8000
#define BITS_PER_BYTE 8
#define BYTES_PER_SAMPLE (16/8)

#define SAMP_PER_READ 4000

#define BETA_SHIFT 4

#define BP_FILTER_TAPS 32
#define LOG2N 13
#define N (1 << LOG2N)

//#define N_AUDIO_FILTERS 2
// Define constant Filter Numbers for each filter
#define LOW_RATE_FILTER 1
#define HIGH_RATE_FILTER 0
// Use a magic value for operating on both filters
#define BOTH_FILTERS 3

#define VDSP_STEP 1

#define BETA .75f

#define BIT_COUNT_MIN 10

//=============================================================================
//==[ Types ]==================================================================
//=============================================================================
typedef unsigned char boolean;

typedef struct {
    //   uint32_t compare_threshold;
    int16_t read_count;
    
    DSPDoubleSplitComplex *fft_data;  // used during FFT calculation
    FFTSetupD fft_setup; // parameters for FFT
    
    uint8_t *fingerprint_output;
    int n_fingerprint_bytes;
} comp_data_store;

//=============================================================================
//==[ Prototypes ]=============================================================
//=============================================================================
comp_data_store* InitCompareData(void);
void FreeCompareData( comp_data_store *data );

void do_fft(double audio_buf[], FFTSetupD fft_setup, DSPDoubleSplitComplex *fft_data);
boolean GetFingerprint (comp_data_store* data_store, const int16_t *audio_buf, uint8_t filt_num, double *max_fft_sum, double *min_fft_sum, double *running_sum_of_diffs, double *running_sum, int audio_chunkS );
