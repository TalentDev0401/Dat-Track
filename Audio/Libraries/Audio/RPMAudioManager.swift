//
//  RPMAudioManager.swift
//  Audio
//
//  Created by Talent on 12.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer
import CoreTelephony
import SwiftTryCatch
import AudioToolbox

class RPMAudioManager: NSObject, AVAudioPlayerDelegate, MPMediaPickerControllerDelegate {
    
    static let shared = RPMAudioManager()
    
    var isRecordingSessionEnabled: Bool!
    var captureAllowed: Bool!
    var audioCapture: RPMAudioCapture?
    var audioUploader: RPMAudioUploader?
    var lastInputRoute: String?
    var lastOutputRoute: String?
    var getSongDataOp: AFHTTPRequestOperation?
    var routeChanged: Bool = false
    var isPaused: Bool!
   
    // MARK: AVAudioSession initialize
    func initSession() -> Bool {
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print("\(error.localizedDescription)")
         
            return false
        }
        
        appDelegate.audioCatState = 0
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord)
            
        } catch let error {
            print("AudioSession properties didn't set", error)
            return false
        }
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker, .mixWithOthers])
            
        } catch let error {
            print("AudioSession bluetooth properties didn't set", error)
        }
        
        captureAllowed = true
        self.activateSession(activate: true)
        
        return true
    }
    
    // MARK: Session activate
    func activateSession(activate: Bool) {
        
        let audioSession = AVAudioSession.sharedInstance()
        if activate {
            do {
                try audioSession.setActive(true)
            }catch let error {
                print("AudioSession active didn't allowed true", error)
            }
        }else {
            do {
                try audioSession.setActive(false)
            }catch let error {
                print("AudioSession active didn't allowed false", error)
            }
            
        }
    }
          
    // MARK:Init RPMAudioManager
    override init() {
        
        super.init()
        
        isRecordingSessionEnabled = true
        let _ = self.initSession()
        setDefaultFilterSettings()
        APIManager.shared.updateFingerprintRates()
               
    }
    // MARK: Initialize Audio setting for recording
    func recordAudioSettings() {
        
        self.activateSession(activate: false)
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print("\(error.localizedDescription)")
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord,
                                         mode: AVAudioSession.Mode.default,
                                         options: [.defaultToSpeaker, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
        } catch let error {
              print("audioSession properties weren't set!", error)
        }
        
        captureAllowed = true
        appDelegate.audioCatState = 0
        self.activateSession(activate: true)
        
        if appDelegate.audioCatState == 1 {
            
            
        }
    }
    
    // MARK: Initialize Audio setting for playing
    func playingAudioSettings() {
        
        self.activateSession(activate: false)
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print("\(error.localizedDescription)")
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback,
                                         mode: AVAudioSession.Mode.default,
                                         options: [.defaultToSpeaker, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
              try audioSession.setActive(true)
        } catch let error {
              print("audioSession properties weren't set!", error)
        }
        
        captureAllowed = true
        appDelegate.audioCatState = 1
        self.activateSession(activate: true)
        
        if appDelegate.audioCatState == 0 {
            
            
        }
    }
    
    // MARK: Terminate
    func terminate() {
        
        self.recordAudioSettings()
        self.stopCapture()
        
    }
    
    // MARK: Enter background
    func enterBackground() {
        
        let standardUserDefaults = UserDefaults.standard
        let tempBOOL = standardUserDefaults.bool(forKey: "bgMode")
        if !tempBOOL && appDelegate.playlistPlaying {
            self.pauseCapture()
        }

        audioUploader!.pauseHighRateFilter()
    }
    
    // MARK: Enter foreground
    func enterForeground() {
        
        if !appDelegate.playlistPlaying {
            self.recordAudioSettings()
        }
        if appDelegate.playlistPlaying == false {
            self.resumeSession()
//            self.startCapture()
            let tempAni = "NO"
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "previewAniToggle"), object: tempAni)
        }else {
            self.resumeSession()
            let tempAni = "YES"
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "previewAniToggle"), object: tempAni)
        }
    }
    
    func resignActive() {
        print("called")
    }
    
    func becomeActive() {
        print("called")
    }
    
    // MARK: Allow capture
    func allowCapture(allow: Bool) {
        
        if !allow {
            self.killCapture()
        }
        
        captureAllowed = allow
    }
    
    // MARK: Uuse foreground capture
    func useForegroundCapture() -> Bool {
        
        let defaults = UserDefaults.standard
        let highSamples = defaults.integer(forKey: Constants.kRPMUserDefaultKeyHighRateNumSamples)
        let lowSamples = defaults.integer(forKey: Constants.kRPMUserDefaultKeyLowRateNumSamples)
        return highSamples != lowSamples
    }
    
    // MARK: Stop capture
    func stopCapture() {
        
        if (audioCapture != nil) || (audioUploader != nil) {
            
            self.killCapture()
        }
        self.playingAudioSettings()
    }
    
    // MARK: Start capture
    func startCapture() {
        
        self.recordAudioSettings()
        captureAllowed = true
        
        audioCapture = RPMAudioCapture()
        audioUploader = RPMAudioUploader()
        routeChanged = false
        
        isRecordingSessionEnabled = true
        
        var compressors: [RPMAudioCompressor] = []
        let lowCompressor = RPMAudioCompressor(MyFilterNumber: Int(LOW_RATE_FILTER))
        compressors.append(lowCompressor)
        
        if self.useForegroundCapture() {
            let highCompressor = RPMAudioCompressor(MyFilterNumber: Int(HIGH_RATE_FILTER))
            compressors.append(highCompressor)
        }
        
        for compressor in compressors {
            compressor.delegate = audioUploader
            audioCapture!.addCompressor((compressor as RPMAudioCompressorCapable))
            audioUploader!.addCompressorFeed(compressor: compressor)
        }
        
        if DefaultsManager.shared.getDeviceId() != nil {
            
            lastInputRoute = self.getCurrentInputRoute()
            RPMSilenceDetector.shared.logMessage(message: "Starting Capture")
            
            if ((audioCapture?.start()) == false) {
                self.killCapture()
            }
        }else {
            RPMSilenceDetector.shared.logMessage(message: "NOT Starting Capture (No User)")
            self.killCapture()
        }
    }
    
    // MARK: Kill capture
    func killCapture() {
        
        RPMSilenceDetector.shared.logMessage(message: "Killing Capture")
        
        audioCapture?.stop()
        audioUploader?.stop(currentFiltNum: Int(BOTH_FILTERS))
        audioCapture = nil
        audioUploader = nil
        lastInputRoute = nil
        isRecordingSessionEnabled = false
        captureAllowed = false
    }
    
    // MARK: Pause capture
    func pauseCapture() {
        
        self.playingAudioSettings()
        let tempAni = "YES"
        NotificationCenter.default.post(name: NSNotification.Name("previewAniToggle"), object: tempAni)
        captureAllowed = false
        audioCapture?.stop()
        audioUploader?.stop(currentFiltNum: Int(BOTH_FILTERS))
        isRecordingSessionEnabled = false
    }

    // MARK: Suspend session
    func suspendSession() {
        isRecordingSessionEnabled = false
        
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("session deactivated")
            self.allowCapture(allow: false)
        } catch let error {
            print("\(error.localizedDescription)")
        }
    }
 
    // MARK: Resume session
    func resumeSession() {
        
        if !appDelegate.playlistPlaying {
            
            self.recordAudioSettings()
            self.activateSession(activate: true)
            self.resumeCapture()
        }else {
            self.allowCapture(allow: false)
            self.playingAudioSettings()
            self.activateSession(activate: true)
        }
    }

    // MARK: Resume capture
    func resumeCapture() {
        
        self.recordAudioSettings()
        self.isRecordingSessionEnabled = true
        
        if (audioCapture == nil) || (audioUploader == nil) || routeChanged {
            
            self.startCapture()
        }else {
            RPMSilenceDetector.shared.logMessage(message: "Resume Capture")
            audioUploader?.start(currentFiltNum: Int(BOTH_FILTERS))
            let _ = audioCapture?.start()
        }
        
        let tempAni = "NO"
        NotificationCenter.default.post(name: .previewAniToggle, object: tempAni)
    }
     
    // MARK: Set default filter setting
    func setDefaultFilterSettings() {
        
        let settings = [Constants.kRPMUserDefaultKeyLowRateNumSamples: 4000, Constants.kRPMUserDefaultKeyLowRateFingerprintNumberIncrement: 1, Constants.kRPMUserDefaultKeyLowRateBufferPointerIncrement: 4000, Constants.kRPMUserDefaultKeyBackgroundLowRateNumSamples: 4000, Constants.kRPMUserDefaultKeyBackgroundLowRateFingerprintNumberIncrement: 1, Constants.kRPMUserDefaultKeyBackgroundLowRateBufferPointerIncrement: 4000, Constants.kRPMUserDefaultKeyHighRateNumSamples: 500, Constants.kRPMUserDefaultKeyHighRateFingerprintNumberIncrement: 2, Constants.kRPMUserDefaultKeyHighRateBufferPointerIncrement: 1000]
        
        let defaults = UserDefaults.standard
        defaults.register(defaults: settings)
        defaults.synchronize()
    }
    
    func firstFingerprintNumber() -> Int {
        return 1
    }
    
    // MARK: Get boolean value for toggle recording
    func toggleRecordingEnabled(enable: Bool) {
        
        if enable {
            
            appDelegate.playlistPlaying = false
            captureAllowed = true
            self.resumeSession()
        }else {
            self.stopCapture()
            self.suspendSession()
        }
        
        self.isRecordingSessionEnabled = enable
    }
    
    func getCurrentInputRoute() -> String? {
        let routeDescriptRef: CFDictionary? = [:] as CFDictionary
        let arrayRef = CFDictionaryGetValue(routeDescriptRef, kAudioSession_AudioRouteChangeKey_Reason)
        
        if (arrayRef != nil) {
            let count = CFArrayGetCount((arrayRef as! CFArray))
            if count > 0 {
                let descriptRef = CFArrayGetValueAtIndex((arrayRef as! CFArray), 0)
                let name = CFDictionaryGetValue((descriptRef as! CFDictionary), kAudioSession_AudioRouteChangeKey_OldRoute) as! String
                return name
            }
        }
        
        return nil
    }
    
    func getCurrentOutputRoute() -> String? {
        
        let routeDescriptRef: CFDictionary? = [:] as CFDictionary
        let arrayRef = CFDictionaryGetValue(routeDescriptRef, kAudioSession_AudioRouteChangeKey_Reason)
        
        if (arrayRef != nil) {
            let count = CFArrayGetCount((arrayRef as! CFArray))
            if count > 0 {
                let descriptRef = CFArrayGetValueAtIndex((arrayRef as! CFArray), 0)
                let name = CFDictionaryGetValue((descriptRef as! CFDictionary), kAudioSession_AudioRouteChangeKey_OldRoute) as! String
                return name
            }
        }
        
        return nil
    }
    
    func enumerateInputs() {
        
        let sourceRef: CFArray? = nil
        
        if (sourceRef != nil) {
            
            var count = CFArrayGetCount(sourceRef)
            count -= 1
            while count >= 0 {
                
                let descriptRef = CFArrayGetValueAtIndex(sourceRef, 0)
                let name = CFDictionaryGetValue((descriptRef as! CFDictionary), kAudioSession_AudioRouteChangeKey_OldRoute) as! String
                print("device: \(name)")
                count -= 1
            }
        }
    }
    
}

private func CheckError(error: OSStatus, operation: UnsafePointer<Int8>?) {
    
    if error == noErr {
        return
    }
    
}
