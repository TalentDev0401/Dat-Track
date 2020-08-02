//
//  ListeningViewController.swift
//  Audio
//
//  Created by TeamPlayer on 1/14/20.
//  Copyright © 2020 Audio. All rights reserved.
//

import UIKit

class ListeningViewController: UIViewController {

    @IBOutlet weak var btnTrack: UIButton!
    
    var match: Match!

    override func viewDidLoad() {
        super.viewDidLoad()

        btnTrack.isUserInteractionEnabled = false
                        
        NotificationCenter.default.addObserver(self, selector: #selector(TimeOut), name: Notification.Name.timeOut, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(getMatchArray(_:)), name: .didReceiveMatchDataInForground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(OpenAppFromBackgroundWhenTapTrack), name: .EnterForegroundWhenTapTrack, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        // Stop Audio capturing after 20 seconds.
        appDelegate.CountingFor20Seconds()
        
        self.btnTrack.rotate(duration: 10)
        
        SharedManager.shared.enterInForegroundWhenRecording = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
  
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    @objc func OpenAppFromBackgroundWhenTapTrack() {
        self.btnTrack.rotate(duration: 10)
    }
    
    // Recording Notification
    @objc func TimeOut() {
        
        SharedManager.shared.enterInForegroundWhenRecording = false
        
        self.performSegue(withIdentifier: "segueNoTrackFound", sender: nil)
    }
    
    // Notification obsever selector
    @objc func getMatchArray(_ notification: Notification) {
        
        SharedManager.shared.getMatched = true
        appDelegate.forgroundTimer?.invalidate()
        appDelegate.forgroundTimer = nil
        appDelegate.timeIndex = 0
        // Stop Audio capturing(Get match)
        let info = [Constants.kRPMSettingsUserToggledRecordingValue: false]
        NotificationCenter.default.post(name: Notification.Name.kRPMSettingsUserToggledRecordingNotification, object: nil, userInfo: info)
        
        self.match = (notification.userInfo?["matches"] as! Match)
        
        FRadioPlayer.shared.stop()
                
        self.performSegue(withIdentifier: "segueMusicFound", sender: nil)
        
    }
    
    @IBAction func onBtnClose(_ sender: UIButton) {
                        
        // Stop audio capturing
        ToggleRecording(bgMode: false, recording: false)
        appDelegate.forgroundTimer?.invalidate()
        appDelegate.forgroundTimer = nil
        appDelegate.timeIndex = 0
        
        // Stop rotating button
        self.btnTrack.stopRotating()
        
        SharedManager.shared.enterInForegroundWhenRecording = false
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onBtnTrack(_ sender: Any) {
        print("track")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueMusicFound" {
            let found = segue.destination as! MusicFoundViewController
            found.match = self.match
        }
    }
    
}
