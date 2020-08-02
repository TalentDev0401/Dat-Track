#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <Accelerate/Accelerate.h>
#include "get_comp_byte.h"

/*******************************************************************************
 * Function: InitCompareData
 *
 * Description: Init compare data
 *
 * Parameters: none
 *
 * Returns: nothing
 *
 ******************************************************************************/
comp_data_store* InitCompareData(void) {
    
    comp_data_store* data = (comp_data_store*)malloc( sizeof( comp_data_store ) );
	
	data->read_count = 0;
    
    /* set aside space for variables and check that the memory was correctly
     * allocated */
    const int n_over_2 = N/2;
    
    data->fft_setup = vDSP_create_fftsetupD(LOG2N, kFFTRadix2);
    
    data->fft_data = malloc(sizeof(DSPDoubleSplitComplex));
    data->fft_data->realp = malloc(n_over_2 * sizeof(double));
    data->fft_data->imagp = malloc(n_over_2 * sizeof(double));
    
    data->n_fingerprint_bytes = 10;
    data->fingerprint_output = malloc( data->n_fingerprint_bytes );
    
    return data;
}

/*******************************************************************************
 * Function: FreeCompareData
 *
 * Description: Free allocations of pointer to comp_data_store structure passed
 *              in
 *
 * Parameters: pointer to comp_data_store_structure
 *
 * Output: void
 *
 ******************************************************************************/
void FreeCompareData( comp_data_store *data )
{
    free( data->fingerprint_output );
    free( data->fft_data->imagp );
    free( data->fft_data->realp );
    free( data->fft_data );
    vDSP_destroy_fftsetupD( data->fft_setup );
    free( data );
}

/*******************************************************************************
 * Function: do_fft
 *
 * Input: pointer to copy of audio input, FFTSetupD "scratch work" area for FFT,
 *        DSPDoubleSplitComplex to hold the fft_data after the FFt is complete
 *
 * Output: nothing
 *
 * This function is designed to take in approximately 4000 samples of audio and
 * perform a 8192 point fast fourier transform on these 4000 samples.  The
 * magnitude of the real and imaginary components of the fourier transform are
 * then returned to the caller through the audio_buf input paramter.
 ******************************************************************************/

void do_fft(double audio_buf[], FFTSetupD fft_setup, DSPDoubleSplitComplex *fft_data) {
	const int n_over_2 = N / 2;
	double scale = 0.5;
    
	/* get a split complex vector, which should divide into an even-odd
	 * configuration */
	vDSP_ctozD ((DSPDoubleComplex *)audio_buf, 2, fft_data, 1, n_over_2);
	
	/* forward FFT transform */
	vDSP_fft_zripD (fft_setup, &(*fft_data), 1, LOG2N, kFFTDirection_Forward);
    
    
	/* scale fft_data to match output from matlab */
	vDSP_vsmulD(fft_data->realp, 1, &scale, fft_data->realp, 1, n_over_2);
	vDSP_vsmulD(fft_data->imagp, 1, &scale, fft_data->imagp, 1, n_over_2);
	
    /* === Debugging ===
     printf("FFT output\n");
     
     for (i = 0; i < n_over_2; ++i)
     {
     printf("%d: %8g%8g\n", i, fft_data.realp[i], fft_data.imagp[i]);
     } =================*/
    
    //save the magnitudes in our audio_buf input parameter
    vDSP_vdistD(fft_data->realp, 1, fft_data->imagp, 1, audio_buf, 1, n_over_2);
}

/*******************************************************************************
 * Function: GetFingperint
 *
 * Input: * comp_data_store data structure
 *        * pointer to audio buffer stream
 *        * int representing filter number
 *
 *        Silence Detection inputs,
 *        keeping track of data over the course of 32 calls/FPs:
 *        * pointer to the max sum of the fft vector
 *        * pointer to the min sum of the fft vector
 *        * pointer to running total of the sum of
 *              fft diffs (silence_2 in matlab)
 *        * pointer to running total of the sum of
 *              absolute value of ffts (silence_3 in matlab)
 *
 *
 * Ouput: TRUE. Currently, all fingerprints are considered to have succeeded.
 *        (we have enough flipped bits to constitute a valid fingerprint.)
 *
 * This function performs the fft on the given 4000 samples from the pointer to
 * the audio buffer that is passed in.  After performing the FFT, it will
 * perform the threshold bandpass filtering described in the readme and save the
 * output stream of bits.
 *
 * See associated test in rpmTests
 *
 ******************************************************************************/

boolean GetFingerprint (comp_data_store* data_store, const int16_t *audio_buf, uint8_t filt_num, double *max_fft_sum, double *min_fft_sum, double *running_sum_of_diffs, double *running_sum, int audio_chunkS)
{
	int i;
	double T = 0;
    double *fft_buf;
    int indexLimitLower = 100;
    int indexLimitUpper = 3900;
    
    // zero out fingerprint
    memset( data_store->fingerprint_output, 0, data_store->n_fingerprint_bytes );
    
    // copy audio data into an "interleaved" complex format
    double audio_data[N];
    for( i = 0; i < N; i++ ) {
        if( i < audio_chunkS ){
            audio_data[i] = audio_buf[i]/pow( 2, PCM_BIT_DEPTH - 1 );
            // Silence Detection
            // (*running_sum == silence_3 in matlab)
            *running_sum = *running_sum +fabs(audio_data[i]);
        } else {
            audio_data[i] = 0.;
        }
    }
    
    // audio_data is modified in place with the FFT
	do_fft(audio_data, data_store->fft_setup, data_store->fft_data);
    
    //we only care about certain indices of the FFT
	fft_buf = audio_data + indexLimitLower;
    
    int fft_range = indexLimitUpper - indexLimitLower - 1;
    
    // Silence Detection: Normalize in place (fft/max(fft))
    double max_fft_val = 0.f;
    for (i = 0; i <= fft_range; i++)
        if (fft_buf[i] > max_fft_val)
            max_fft_val = fft_buf[i];
    
    for (i = 0; i <= fft_range; i++)
        fft_buf[i] = fft_buf[i] / max_fft_val;
    
    // Silence Detection: running sum of the audio diffs
    // 1. on fft data, subtract: fft(2..end) - fft(1..end-1)
    // 2. sum the resulting vector (as below)
    // 3. add absolute value to the running total
    // (*running_sum_of_diffs == silence_2 in matlab)
    double diffed_data[fft_range];
    double diffed_sum = 0;
    vDSP_vsubD(&fft_buf[0], VDSP_STEP, &fft_buf[1], VDSP_STEP, diffed_data, VDSP_STEP, (fft_range));
    vDSP_sveD(diffed_data, VDSP_STEP, &diffed_sum, fft_range);
    *running_sum_of_diffs += fabs(diffed_sum);
    
    
    // Silence Detection: keep track of the sum of the FFT
    // fft_sum == silence_1 in matlab
    double fft_sum = 0.f;
    int VAR_SAMP_PER_STAIR = 5;
    T = 0;
	for (i = 0; i < 80; i++) {
		double stair = 0;
		
        //sum up the SAMP_PER_STAIR steps per stair
		vDSP_sveD(fft_buf, VDSP_STEP, &stair, VAR_SAMP_PER_STAIR);
        
        //increment our pointer by the 40 steps per stair
		fft_buf += VAR_SAMP_PER_STAIR;
        VAR_SAMP_PER_STAIR = VAR_SAMP_PER_STAIR+1;
        // On the first pass, we want to capture the "T" value for comparison,
        // but we'll ignore that first bit in our output
        if (i > 0) {
            T = (BETA*T) + ((1-BETA)*stair); //beta in this case should be 7/8
                                             //   printf("Stair :%f T :%f VAR_SAMP_PER_STAIR : %d BIT :%d\n",stair,T,VAR_SAMP_PER_STAIR-1,(i-1)/8);
            
            //shift left so most recent audio is in least significant bitdata_store    comp_data_store *    0x6000035a04e0    0x00006000035a04e0
            data_store->fingerprint_output[(i-1)/8] <<= 1;
            
            /* Potentially need to change code below to accommodate for large number */
            // Compare with previous value
            if (stair > T)
                data_store->fingerprint_output[(i-1)/8] |= 1;
            
        }
        else
            T = stair;
        
        fft_sum += stair;
	}
    
    // Min & max sums will be used in the silence detection
    if (!*min_fft_sum || fft_sum < *min_fft_sum)
        *min_fft_sum = fft_sum;
    
    if (fft_sum > *max_fft_sum)
        *max_fft_sum = fft_sum;
    
	return TRUE;
}
