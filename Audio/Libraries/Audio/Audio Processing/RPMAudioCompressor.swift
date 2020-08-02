//
//  RPMAudioCompressor.swift
//  Audio
//
//  Created by Talent on 12.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import AudioToolbox
import Accelerate

let  MAX_SIZE_OF_BUFFERED_AUDIO = BYTES_PER_SAMPLE*SAMP_PER_SEC*60*4

protocol RPMAudioCompressorCapable: class {
    
    func addSampleBuffer(sampleBuffer: AudioQueueBufferRef)
}

protocol RPMAudioCompressorDelegate: class {
    func newFingerprintReady(fingerprintData: Data, fingerprintNumber: Int, filterNumber: Int, stats: RPMSilenceDetectionStats)
}

class RPMAudioCompressor: NSObject, RPMAudioCompressorCapable {
    
    
    var cleanedAfterRestart: Bool! = false
    var restartThreshold: Int! = 0
    var restartRequests: Int! = 0
    var firstFingerprintNumber: Int! = 0
    var fingerprintNumberIncrement: Int! = 0
    var bufferPointerIncrement: Int! = 0
    var numSamples: Int! = 0
    var runningSum: Double! = 0.0
    var runningSumOfDiffs: Double! = 0.0
    var minFFTSum: Double! = 0.0
    var maxFFTSum: Double! = 0.0
    var filterNumber: Int! = 0
    var wantsRestart: Bool! = false

    var dataStore: UnsafeMutablePointer<comp_data_store>?//comp_data_store?
    var dataBufferLock: NSRecursiveLock!
    var fingerprintNumber: Int! = 0
    
    var delegate: RPMAudioCompressorDelegate!
    
    var dataBuffer: UnsafeMutableRawPointer? = nil
    var dataBufferReadPtr: UnsafeMutableRawPointer? = nil
    var dataBufferWritePtr: UnsafeMutableRawPointer? = nil
            
    init(MyFilterNumber: Int) {
        super.init()
        
        restartThreshold = 10
        filterNumber = MyFilterNumber
        dataBufferLock = NSRecursiveLock()
        self.start()
        
    }
    
    func addSampleBuffer(sampleBuffer: AudioQueueBufferRef) {
        
        dataBufferLock.lock()
        
        if dataBuffer == nil {
            
            dataBufferLock.unlock()
            return
        }
        
        memcpy(dataBufferWritePtr!, sampleBuffer.pointee.mAudioData, Int(sampleBuffer.pointee.mAudioDataByteSize))
        dataBufferWritePtr! = dataBufferWritePtr! + Int(sampleBuffer.pointee.mAudioDataByteSize)
        dataBufferLock.unlock()
        self.compressAvailableData()
    }
    
    func compressAvailableData() {
        
        var kBytesPerChunk = 8000
        dataBufferLock.lock()
        
        autoreleasepool() {
            
            if dataStore != nil && dataBuffer != nil {
                
                // Audio Buffers are moved into 1 large working buffer.  When we go to process the audio we check to ensure there is
                // enough samples available to work on the 1 Fingperprint.  Filter one requires 8000 samples (2 bytes per read) and filter 1
                // requires 1000
                if filterNumber == 0 {
                    
                    kBytesPerChunk = 8000
                }else {
                    kBytesPerChunk = 4000
                }
                while dataBufferWritePtr! - dataBufferReadPtr! >= kBytesPerChunk { 
                   
                    print("dataBufferReadPtr is \(String(describing: dataBufferReadPtr))")
                    print("dataStore: \(String(describing: dataStore))")
                    print("filterNumber: \(UInt8(filterNumber))")
                    print("maxFFTSUm: \(String(describing: maxFFTSum))")
                    print("minFFTSum: \(String(describing: minFFTSum))")
                    print("runningSumOfDiffs \(String(describing: runningSumOfDiffs))")
                    print("runningSum: \(String(describing: runningSum))")
                    print("numSamples : \(Int32(numSamples))")
                    
                    let s = dataBufferReadPtr?.assumingMemoryBound(to: Int16.self)
                    if GetFingerprint(&dataStore!.pointee, UnsafePointer<Int16>(s), UInt8(filterNumber), &maxFFTSum, &minFFTSum, &runningSumOfDiffs, &runningSum, Int32(numSamples)) != 0 {
                        
                        let fingerprintData = Data(bytes: dataStore!.pointee.fingerprint_output, count: Int(dataStore!.pointee.n_fingerprint_bytes))
                        
                        let stats = RPMSilenceDetectionStats()
                        stats.maxFFTSum = maxFFTSum
                        stats.minFFTSum = minFFTSum
                        stats.sumOfFFTDiffs = runningSumOfDiffs
                        stats.sumOfAudioData = runningSum
                                                                       
                        delegate.newFingerprintReady(fingerprintData: fingerprintData, fingerprintNumber: fingerprintNumber, filterNumber: filterNumber, stats: stats)
                       
                    }
                    
                    if cleanedAfterRestart {
                        
                        /// Signal that a restart has been triggered, and
                        /// fingerprintNumber and dataBuffer have been reset.
                        /// In this case, we should not increment
                        cleanedAfterRestart = false
                    }else {
                        dataBufferReadPtr = dataBufferReadPtr! + bufferPointerIncrement
                    }
                    fingerprintNumber = fingerprintNumber + fingerprintNumberIncrement
                }
                
                if self.wantsRestart {
                    self.wantsRestart = false
                    self.restart()
                }
            }
        }
        dataBufferLock.unlock()
    }
    
    // RPMUploader is in charge of FP batch size,
    // so it's in charge of telling us when to reset.
    //
    // This is decoupled from [restart] to avoid
    // discarding buffer data when we hit the end of our batch (e.g., 32 FPs)
    //
    // Silence Detection stats should also reset with a new batch
    func startNewFingerprintBatch() {
        
        runningSumOfDiffs = 0.0
        runningSum = runningSumOfDiffs
        maxFFTSum = runningSum
        minFFTSum = maxFFTSum

        restartRequests += 1
        if restartRequests >= restartThreshold {
            wantsRestart = true
            restartRequests = 0
        }
        
        // This is hacky, but:
        // reset the FP to less than the initial state,
        // knowing it will be incremented in the [compressAvailableData] loop
        // (even if we restart here)
        fingerprintNumber = firstFingerprintNumber - fingerprintNumberIncrement
    }
    
    func restart() {
        
        self.stop()
        self.start()
        cleanedAfterRestart = true
    }
    
    func start() {
        
        DispatchQueue.main.async {
            
            self.updateFilterSettings()
            assert(self.fingerprintNumberIncrement >= 1, "Fingerprint Increment must be >= 1")
        }
        
        restartRequests = 0
        dataBufferLock.lock()
        
        dataBuffer = UnsafeMutableRawPointer(malloc(Int(MAX_SIZE_OF_BUFFERED_AUDIO)))
        
        dataBufferWritePtr = dataBuffer
        dataBufferReadPtr = dataBuffer
                
        dataStore = UnsafeMutablePointer<comp_data_store>.allocate(capacity: MemoryLayout<comp_data_store>.size)
        dataStore = InitCompareData()
                
        dataBufferLock.unlock()
    }
    
    func updateFilterSettings() {
        
        assert(filterNumber == LOW_RATE_FILTER || filterNumber == HIGH_RATE_FILTER, "Filter number must be 0 or 1")
        
        let defaults = UserDefaults.standard
        
        if filterNumber == LOW_RATE_FILTER {
            
            let appState = UIApplication.shared.applicationState
            let inBackground = appState == UIApplication.State.background
            
            if inBackground {
                numSamples = defaults.integer(forKey: Constants.kRPMUserDefaultKeyBackgroundLowRateNumSamples)
                fingerprintNumberIncrement = defaults.integer(forKey: Constants.kRPMUserDefaultKeyBackgroundLowRateFingerprintNumberIncrement)
                bufferPointerIncrement = defaults.integer(forKey: Constants.kRPMUserDefaultKeyBackgroundLowRateBufferPointerIncrement)
            }else {
                
                numSamples = defaults.integer(forKey: Constants.kRPMUserDefaultKeyLowRateNumSamples)
                fingerprintNumberIncrement = defaults.integer(forKey: Constants.kRPMUserDefaultKeyLowRateFingerprintNumberIncrement)
                bufferPointerIncrement = defaults.integer(forKey: Constants.kRPMUserDefaultKeyLowRateBufferPointerIncrement)
                
            }
        }else {
            
            numSamples = defaults.integer(forKey: Constants.kRPMUserDefaultKeyHighRateNumSamples)
            fingerprintNumberIncrement = defaults.integer(forKey: Constants.kRPMUserDefaultKeyHighRateFingerprintNumberIncrement)
            bufferPointerIncrement = defaults.integer(forKey: Constants.kRPMUserDefaultKeyHighRateBufferPointerIncrement)
        }
    }
    
    func stop() {
        
        dataBufferLock.lock()
        if (dataBuffer != nil) {
            
            free(dataBuffer)
            dataBufferWritePtr = nil
            dataBufferReadPtr = dataBufferWritePtr
            dataBuffer = dataBufferReadPtr
        }
        
        if (dataStore != nil) {
            
            FreeCompareData(&dataStore!.pointee)
            dataStore = nil
        }
        
        dataBufferLock.unlock()
    }
    
    func isStopped() -> Bool {
        return dataStore == nil
    }
    
    func currentFilt() -> Int {
        return filterNumber
    }
}
