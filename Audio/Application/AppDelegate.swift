//
//  AppDelegate.swift
//  Audio
//
//  Created by TeamPlayer on 1/14/20.
//  Copyright © 2020 Audio. All rights reserved.
//

import UIKit
import RSLoadingView
import UIKit.UIWindow
import MediaPlayer
import AudioToolbox
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var AudioMan: RPMAudioManager!
    var audioCatState: Int!
    var playlistPlaying: Bool = false
    var isSongPlaying: Bool!
    var forgroundTimer: Timer?
    var timeIndex: Int = 0

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        initNavBar()
        
        // FRadioPlayer config
        FRadioPlayer.shared.isAutoPlay = true
        FRadioPlayer.shared.enableArtwork = true
        FRadioPlayer.shared.artworkSize = 600
        
        AudioMan = RPMAudioManager()
        
        
        NotificationCenter.default.addObserver(self, selector: #selector((userToggledRecording(note:))), name: Notification.Name.kRPMSettingsUserToggledRecordingNotification, object: nil)
                
        return true
    }
    
    // Recording Notification
    @objc func userToggledRecording(note: Notification) {//94
        
        let info = note.userInfo as? Dictionary<String, Any>
        let shouldEnableRecording = info![Constants.kRPMSettingsUserToggledRecordingValue] as! Bool
        
        DispatchQueue.main.async {
            
            self.AudioMan.toggleRecordingEnabled(enable: shouldEnableRecording)
        }        
        
        if !shouldEnableRecording {
            self.forgroundTimer?.invalidate()
            self.forgroundTimer = nil
            timeIndex = 0
        }
        
        
  
    }
    
    // MARK: Countdown 20 seconds for ending capture after 20 seconds.
    func CountingFor20Seconds() {
        
        if forgroundTimer == nil {
          let forground = Timer(timeInterval: 1.0,
                            target: self,
                            selector: #selector(CountDown20Seconds),
                            userInfo: nil,
                            repeats: true)
          RunLoop.current.add(forground, forMode: .common)
                    
          self.forgroundTimer = forground
        }
    }
    
    @objc func CountDown20Seconds() {
        
        if timeIndex == 21 {
            
            // Stop Audio capturing(time out)
            let info = [Constants.kRPMSettingsUserToggledRecordingValue: false]
            NotificationCenter.default.post(name: Notification.Name.kRPMSettingsUserToggledRecordingNotification, object: nil, userInfo: info)
            NotificationCenter.default.post(name: Notification.Name.timeOut, object: nil, userInfo: nil)
            self.forgroundTimer?.invalidate()
            self.forgroundTimer = nil
            timeIndex = 0
        }else {
            timeIndex += 1
            
            if timeIndex % 2 == 0 || timeIndex == 21 {
                // Send Match request one by 2 seconds.
                if !SharedManager.shared.getMatched {
                    MatchManager.shared.GetMatchNew(bgMode: false)
                }
            }
        }
    }
   
    private func initNavBar() {
        UINavigationBar.appearance().barTintColor = UIColor(hex: "#333333")
        UINavigationBar.appearance().tintColor = Constants.colorOrange
        UINavigationBar.appearance().titleTextAttributes =  [NSAttributedString.Key.foregroundColor: UIColor.white]
        UINavigationBar.appearance().isTranslucent = false
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func applicationWillTerminate(_ application: UIApplication) {

        // Save Coredata when app will terminate
        AudioMan.terminate()
//        MagicalRecord.cleanUp()
//        NSManagedObjectContext.default().saveToPersistentStoreAndWait()
        self.saveContext()
    }
    
    func startMusterTimer_FG() {
        
        print("Started Muster Timer in foreground")
    }
    
    func startMusterTimer_BG() {
        print("Started Must Timer in background")
    }
    
    //MARK: Audio Functions
    
    func stopPlayingCurrentSong() {
        
    }
    
    func startAudioCapture() {
        AudioMan.startCapture()
    }
    
    func stopAudioCapture() {
        AudioMan.stopCapture()
    }
    
    func killCapture() {
        AudioMan.stopCapture()
    }
    
    func pauseAudioCapture() {
        AudioMan.pauseCapture()
    }
   
    func unpausePlayer() {
        
    }
    
    func resumeAudioCapture() {
        AudioMan.resumeCapture()
    }
    
    func isRecordingSessionEnabled() -> Bool {
        return AudioMan.isRecordingSessionEnabled
    }
    
    // Fingerprint Rates
    func firstFingerprintNumber() -> Int {
        return AudioMan.firstFingerprintNumber()
    }
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "AudioModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    // MARK: - Core Data Saving support

    func saveContext () {
      let context = persistentContainer.viewContext
      if context.hasChanges {
        do {
          try context.save()
        } catch {
          // Replace this implementation with code to handle the error appropriately.
          // fatalError() causes the application to generate a crash log and terminate.
          /// You should not use this function in a shipping application, although it may be useful during development.
          let nserror = error as NSError
          fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
      }
    }
    
}

