//
//  Macros.h
//  Audio
//
//  Created by Talent on 12.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

#ifndef Macros_h
#define Macros_h

#if DEBUG
    #define TEST_AUDIO_RECORDING 0 // save raw audio to WAV file?
    #define ENABLE_SILENCE_DETECTION_LOGGING 0
#else
    #define TEST_AUDIO_RECORDING 0
    #define ENABLE_SILENCE_DETECTION_LOGGING 0
#endif

#define USE_MEASUREMENT_MODE 1
#define USE_MAXIMUM_GAIN 0
#define USE_SILENCE_DETECTION 0

#if DEBUG
    #define TEST_AUDIO_RECORDING 0 // save raw audio to WAV file?
    #define ENABLE_SILENCE_DETECTION_LOGGING 0
#else
    #define TEST_AUDIO_RECORDING 0
    #define ENABLE_SILENCE_DETECTION_LOGGING 0
#endif



#endif /* Macros_h */


