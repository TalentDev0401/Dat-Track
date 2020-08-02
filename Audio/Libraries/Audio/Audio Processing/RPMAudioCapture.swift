//
//  RPMAudioCapture.swift
//  Audio
//
//  Created by Talent on 12.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox
import CoreAudioKit
import UIKit

let KNumberBuffers = 3

func DeriveBufferSize(_ audioQueue: AudioQueueRef?, ASBDescription: AudioStreamBasicDescription, seconds: Float64, outBufferSize: UnsafeMutablePointer<UInt32>?) {
//    var outBufferSize = outBufferSize
    /*
     1. The audio queue that owns the buffers whose size you want to specify.
     2. The AudioStreamBasicDescription structure for the audio queue.
     3. The size you are specifying for each audio queue buffer, in terms of seconds of audio.
     4. On output, the size for each audio queue buffer, in terms of bytes.
     */
    
    print("BufferByteSize is \(String(describing: outBufferSize?.pointee))")

    let maxBufferSize = 0xfffff
    
    var maxPacketSize = Int(ASBDescription.mBytesPerPacket) // 2
    if maxPacketSize == 0 {
        // 3
        var maxVBRPacketSize = UInt32(MemoryLayout.size(ofValue: maxPacketSize))
        if let audioQueue = audioQueue {
            AudioQueueGetProperty(audioQueue, kAudioQueueProperty_MaximumOutputPacketSize, UnsafeMutableRawPointer(mutating: &maxPacketSize), UnsafeMutablePointer<UInt32>(mutating: &maxVBRPacketSize))
        }
    }

    let numBytesForTime = Float64(ASBDescription.mSampleRate * Float64(maxPacketSize)) * seconds // 4
    
    if (Int(numBytesForTime) < maxBufferSize) {
        let num = UInt32(numBytesForTime)
        outBufferSize?.pointee = num
    }else {
        let max = UInt32(maxBufferSize)
        outBufferSize?.pointee = max
    }
}


func AQAudioQueueInputCallback(inUserData: UnsafeMutableRawPointer?, inAQ: AudioQueueRef, inBuffer: AudioQueueBufferRef, inStartTime: UnsafePointer<AudioTimeStamp>, inNumberPacketDescriptions: UInt32, inPacketDescs: UnsafePointer<AudioStreamPacketDescription>?) {
    
    print("AudioQueueInputCallback called")
    print("mAudioDataByteSize: \(inBuffer.pointee.mAudioDataByteSize)")
    print("InBuffer is \(inBuffer)")
    print("inAQ is \(inAQ)")
        
    let capture = unsafeBitCast(inUserData!, to: RPMAudioCapture.self)
    
    var inNumPackets = inNumberPacketDescriptions
    
    if inNumPackets == 0 && capture.mDataFormat.mBytesPerPacket != 0 {
        inNumPackets = inBuffer.pointee.mAudioDataByteSize / capture.mDataFormat.mBytesPerPacket
    }
    capture.capturedSamples(sampleBuffer: inBuffer)
    capture.mCurrentPacket = Int64(inNumPackets)
    if !capture.mIsRunning {
        return
    }
    
//    let err = AudioQueueEnqueueBuffer(capture.mQueue!, inBuffer, 0, nil)
//    if err != noErr {
//        print("AudioQueueEnqueueBuffer inAQ err: \(err)")
//        return
//    }
    let err1 = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
    if err1 != noErr {
        print("AudioQueueEnqueueBuffer inAQ err: \(err1)")
        return
    }
}

class RPMAudioCapture {
    
    static let shared = RPMAudioCapture()
    
//    var aqData: AQRecorderState!
    var compressors: [Any] = []
    var dateStarted: Date!
    var callbackFrequency: CGFloat!
    var nSamp: UInt64!
    
    #if TEST_AUDIO_RECORDING
    var wav_filename: [Int8]!
    var wav_file: FILE? = nil

    var debugFPFilename = ""
    #endif
    
    var mQueue: AudioQueueRef?
    var mBuffers = Array<AudioQueueBufferRef?>(repeating: nil, count: 3)
    var bufferByteSize: UInt32 = 0
    var mCurrentPacket: Int64!
    var mIsRunning: Bool = false
    var mDataFormat: AudioStreamBasicDescription {
        return AudioStreamBasicDescription(mSampleRate: Float64(Double(SAMP_PER_SEC)), mFormatID: kAudioFormatLinearPCM, mFormatFlags: AudioFormatFlags(kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked), mBytesPerPacket: UInt32(BYTES_PER_SAMPLE), mFramesPerPacket: 1, mBytesPerFrame: UInt32(BYTES_PER_SAMPLE), mChannelsPerFrame: 1, mBitsPerChannel: UInt32(PCM_BIT_DEPTH), mReserved: 0)
    }
    
    func prepareForRecord() {
        
        print("PrepareForRecord")
        var err: OSStatus?

        var mDataFormat = self.mDataFormat
        err = AudioQueueNewInput(&mDataFormat, AQAudioQueueInputCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self), nil, CFRunLoopMode.commonModes.rawValue, 0, &mQueue)
    
        if err != noErr {
            print("failed creating new audio input \(err.debugDescription)")
            return
        }

        var dataFormatSize = UInt32(MemoryLayout.size(ofValue: mDataFormat))
        AudioQueueGetProperty(mQueue!, kAudioQueueProperty_StreamDescription, &mDataFormat, &dataFormatSize)

        if mDataFormat.mBitsPerChannel != PCM_BIT_DEPTH {
            print("recording bit depth doesn't match desired")
        }
        if mDataFormat.mSampleRate != Double(SAMP_PER_SEC) {
            print("recording sample rate doesn't match desired")
        }

        print("BufferByteSize is \(String(describing: bufferByteSize))")
        DeriveBufferSize(mQueue!, ASBDescription: mDataFormat, seconds: Float64(callbackFrequency), outBufferSize: &bufferByteSize)
            
        print("BufferByteSize is \(String(describing: bufferByteSize))")
        for i in 0..<mBuffers.count { //KNumberBuffers
            err = AudioQueueAllocateBuffer(mQueue!, bufferByteSize, &mBuffers[i])
            err = AudioQueueEnqueueBuffer(mQueue!, mBuffers[i]!, 0, nil)
            if err != noErr {
                print("failed creating audio buffer \(i) \(String(describing: err))")
                return
            }
        }
    }
                    
    init() {
        compressors = [AnyHashable]()
        callbackFrequency = 0.5
    }
        
    func start() -> Bool {
        
        if !mIsRunning {
            
            self.prepareForRecord()
            
            #if TEST_AUDIO_RECORDING
            let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
            let docPath = paths[0]
            let dateString = Date.iso8601String(with: Date(), timeZoneUTC: true)
            var filePath = "temp\(dateString).wav"
            let wavFilename = URL(fileURLWithPath: docPath).appendingPathComponent(filePath).absoluteString
            wav_filename = malloc(wavFilename.count + 1)
            wavFilename.getCString(&wav_filename, maxLength: wavFilename.count + 1, encoding: .ascii)
            //        testWavHeader( wav_filename, 0 );
            wav_file = fopen(wav_filename, "ab")

            // Save hex FPs
            filePath = "temp\(dateString).hex.txt"
            debugFPFilename = URL(fileURLWithPath: paths[0]).appendingPathComponent(filePath).absoluteString
            #endif
            
            dateStarted = Date()
            nSamp = 0
            
            for compressor in compressors {
                
                let compress = compressor as! RPMAudioCompressor
                if compress.isStopped() {
                    compress.restart()
                }
            }
            
            mCurrentPacket = Int64(0)
            mIsRunning = true
                                   
            let err: OSStatus? = AudioQueueStart(mQueue!, nil)
            if err != noErr {
                RPMSilenceDetector.shared.logMessage(message: "AudioMan: Failed to start AQ. Error: \(String(describing: err))")
                print("failed starting audio queue \(String(describing: err))")
                return false
            }
        }
        return true
    }
    
    func stop() {
        
        AudioQueueStop(mQueue!, true)
        mIsRunning = false
        
        for compressor in compressors {
            let compress = compressor as! RPMAudioCompressor
            compress.stop()
        }
        
        #if TEST_AUDIO_RECORDING
        if wav_filename {
            fclose(wav_file)
            
            // correct file size in header
            wav_file = fopen(wav_filename, "ab")
            fseek(wav_file, Int(MemoryLayout.size(ofValue: waveHeader1_struct) - MemoryLayout.size(ofValue: __uint32_t)), 0)
            let sizes = __uint32_t(nSamp * BYTES_PER_SAMPLE)
            fwrite(&sizes, MemoryLayout.size(ofValue: __uint32_t), 1, wav_file)
            print("data size \(sizes)")
            fflush(wav_file)
            fclose(wav_file)
            wav_filename = nil // Hack bc pointer claimed to be unallocated
            free(wav_filename)
            print("Wrote file.")
        }
        #endif
    }
    
    func addCompressor(_ compressor: RPMAudioCompressorCapable?) {
        if let compressor = compressor {
            compressors.append(compressor)
        }
    }
    
    func Compressors() -> [Any]? {
        return compressors
    }

    func samplesReceived() -> UInt64 {
        return nSamp
    }
  
    func capturedSamples(sampleBuffer: AudioQueueBufferRef?) {
        
        nSamp += UInt64((sampleBuffer?.pointee.mAudioDataByteSize)! / mDataFormat.mBytesPerFrame)
        
        for compressor in compressors {
            let compress = compressor as! RPMAudioCompressorCapable
            compress.addSampleBuffer(sampleBuffer: sampleBuffer!)
        }
        
        #if TEST_AUDIO_RECORDING
        fwrite(sampleBuffer?.pointee.mAudioData, sampleBuffer?.pointee.mAudioDataByteSize, 1, wav_file)
        #endif
    }
    
    #if TEST_AUDIO_RECORDING
    func receivedFingerprintNotification(note: Notification) {
        
        let fingerprintString = note.userInfo["fingerprintString"] as? String
        fingerprintString?.append(toFile: debugFPFilename, encoding: String.Encoding.utf8)
    }
    #endif
}
