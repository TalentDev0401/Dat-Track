//
//  RPMSilenceDetector.swift
//  Audio
//
//  Created by Talent on 12.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation

class RPMSilenceDetector {
    
    static let shared = RPMSilenceDetector()
    
    var stats: RPMSilenceDetectionStats!
    
    init() {
        self.stats = RPMSilenceDetectionStats()
    }
    
    func reset() {
        
        self.stats = RPMSilenceDetectionStats()
    }
    
    // MARK: Assumes we have a full, current batch
    func statsIndicateSilence() -> Bool {

        let fftSumRatio: Double = self.stats.minFFTSum / self.stats.maxFFTSum
        let sumOfFFTDiffs: Double = self.stats.sumOfFFTDiffs
        let sumOfAudioData: Double = self.stats.sumOfAudioData
        
        var isSilence = false
        
        if (fftSumRatio > 0.45 && (sumOfFFTDiffs > 7.0 && sumOfAudioData < 100)) || (fftSumRatio > 0.6 && sumOfAudioData < 200) || (sumOfAudioData <= 35 && fftSumRatio > 0.35) || sumOfAudioData < 25 {
            
            isSilence = true
        }
        
        #if ENABLE_SILENCE_DETECTION_LOGGING
        self.logStatsWithResult(result: isSilence)
        #endif
        
        #if USE_SILENCE_DETECTION
        return isSilence
        #else
        return false
        #endif
                        
    }
    
    func logStatsWithResult(result: Bool) {
        
        let fftSumRatio: Double = self.stats.minFFTSum / self.stats.maxFFTSum
        let sumOfFFTDiffs: Double = self.stats.sumOfFFTDiffs
        let sumOfAudioData: Double = self.stats.sumOfAudioData
        
        #if USE_SILENCE_DETECTION
        let resultMsg = result ? "SILENT": "sound"
        #else
        let resultMsg = result ? "[SILENT: ignored]": "sound"
        #endif
        let message = String(format: "[%-8@]: %7.4f | %7.4f | %7.4f", resultMsg, fftSumRatio, sumOfFFTDiffs, sumOfAudioData)
        
        self.logMessage(message: message)
    }
    
    func debugLogFilename() -> String {
        
        let directory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        
        return (directory as NSString).appendingPathComponent("silence.log")
    }
    
    func logMessage(message: String) {
        
        #if ENABLE_SILENCE_DETECTION_LOGGING
        let formatter = DateFormatter()
        formatter.timeZone = .local
        formatter.dateFormat = "MM/dd HH:mm:ss"
        let date = formatter.string(from: Date())
        let filename = self.debugLogFilename()
        var datedMessage = String(format: "[%@] %@\n", date, message)
        datedMessage.append(toFile: filename, encoding: String.Encoding.utf8)
        #endif
    }
}
