//
//  HomeViewController.swift
//  Audio
//
//  Created by TeamPlayer on 1/14/20.
//  Copyright © 2020 Audio. All rights reserved.
//

import UIKit
import RSLoadingView
import CDAlertView
import AVFoundation

protocol HomeVCDelegate {
    func didAutoModeChanged(_ autoMode: Bool)
}

class HomeViewController: UIViewController {

    @IBOutlet var lblHints:[UILabel]!
    @IBOutlet weak var btnTrack: UIButton!
        
    private var hints = ["Tap to Track", "Hold to Auto Track"]
    private var hintsAuto = ["Auto Tracking", "Tap to Stop"]
    private var autoMode = false
    
    private var indexHint = 0
    
    let onBtnMatch = BadgedButtonItem(with: UIImage(named: "icon_track_noBGMatches"))
    
    var backgroundTimer: RepeatingTimer?
   
    // MARK: ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

//        ClearMatchData()
       
        print("Match count is \(MatchManager.shared.fetchMatchObjects().count)")
        print("Track count is \(TrackManager.shared.fetchTrackObjects().count)")
        print("Artist count is \(ArtistManager.shared.fetchArtistObjects().count)")
        print("Album count is \(AlbumManager.shared.fetchAlbumObjects().count)")
        
        // Initialize Hint label animation
        self.initHintsAnimation()
        
        if DefaultsManager.shared.getDeviceId() != nil {
            
            self.InitializeAllEvents()
        }
        
    }
    
    // MARK: ViewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
                        
        if DefaultsManager.shared.getDeviceId() == nil {
            
            self.SignupAction()
        }
                        
        if SharedManager.shared.enterInBackgroundWhenRecording {
            
            self.setAutoMode(true)
        }
    }
    
    func SignupAction() {
        
        self.showOnWindow()
        
        // Clear all core data
        DeleteEntity(entity: "User")
        DeleteEntity(entity: "UserDetail")
        DeleteEntity(entity: "Match")
        DeleteEntity(entity: "Track")
        DeleteEntity(entity: "Artist")
        DeleteEntity(entity: "Album")
        appDelegate.saveContext()
        
        // Signup with UUID
        UserManager.shared.signUp() { (data, error) in
            
            if let error = error {
                
                self.AlertMessage(title: "Authentication Failed", message: error.localizedDescription)
                self.hideLoadingHubFromKeyWindow()
                return
            }
            
            if data != nil {
                
                self.InitializeAllEvents()
                
                self.navigationController?.dismiss(animated: true, completion: nil)
                
                self.hideLoadingHubFromKeyWindow()
                
                // MARK: Get all match when sign up was successful and save to core data
                DispatchQueue.main.async {
                    MatchManager.shared.GetMatchAll()
                }
            }
        }
    }
    
    // MARK: ViewDidLayoutSubviews
    private var isFirst = true
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirst {
            isFirst = false
            animateHints()
        }
    }
    
    // Initialize All events in viewcontroller
    @objc func InitializeAllEvents() {
                        
        // Initialize audio and view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOnTrack))
        self.btnTrack.addGestureRecognizer(tapGesture)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressOnTrack))
        self.btnTrack.addGestureRecognizer(longPress)
        
        // Get match array from server
        self.getMatchDataFromNotificationCenter()
        
        rotateTrack()
        
        self.SetupBadgeButton()
        
        NotificationCenterAPI.api.SuccessSignUp()
        
        NotificationCenter.default.addObserver(self, selector: #selector(OpenAppFromBackgroundWhenAutoTrack), name: .EnterBackgroundWhenAutoTrack, object: nil)
    }
    
    func SetupBadgeButton() {
        
        onBtnMatch.badgeTextColor = UIColor.init(hex: "#f36a10")
        onBtnMatch.badgeTintColor = .white
        onBtnMatch.position = .right
        onBtnMatch.hasBorder = false
        onBtnMatch.badgeSize = .medium
        onBtnMatch.badgeAnimation = true
        onBtnMatch.setBadge(with: 0)
        self.navigationItem.leftBarButtonItem = onBtnMatch
        onBtnMatch.tapAction = {
            self.onBtnMatch.setBadge(with: 0)
            self.performSegue(withIdentifier: "segueTracks", sender: nil)
            SharedManager.shared.matchCountInAutoTracking = 0
        }
    }

    // Get match data from server
    func getMatchDataFromNotificationCenter() {
                        
        let notification1 = NotificationCenter.default
        notification1.addObserver(self, selector: #selector(getMatchArray(_:)), name: .didReceiveMatchDataInBackground, object: nil)
    }
    
    // Notification obsever selector
    @objc func getMatchArray(_ notification: Notification) {
        
        if let matches = notification.userInfo?["matches"] as? [Match] {
            SharedManager.shared.matchCountInAutoTracking += matches.count
            onBtnMatch.setBadge(with: SharedManager.shared.matchCountInAutoTracking)
        }
        
    }

    // MARK: tap event on track
    @objc func tapOnTrack(_ sender: UIGestureRecognizer){
        if autoMode {
            
            // Stop audio capturing
            ToggleRecording(bgMode: false, recording: false)
            self.setAutoMode(false)
            SharedManager.shared.enterInBackgroundWhenRecording = false
            self.backgroundTimer?.suspend()
        } else {
            
            AVAudioSession.sharedInstance().requestRecordPermission { state in
                if !state {
                    print("please allow mic permession to use the app")
                }else {
                    
                    DispatchQueue.global(qos: .background).async {
                        DispatchQueue.main.async {
                            
                            SharedManager.shared.getMatched = false
                            
                            //MARK: Start capturing audio
                            ToggleRecording(bgMode: false, recording: true)
                            
                            self.performSegue(withIdentifier: "segueTrack", sender: nil)
                        }
                    }
                }
            }
        }
    }
    
    @objc func OpenAppFromBackgroundWhenAutoTrack() {
        self.setAutoMode(true)
    }
    
    // MARK:  long press event on track
    @objc func longPressOnTrack(_ sender: UIGestureRecognizer) {
        if sender.state.rawValue == 1 {
            
            AVAudioSession.sharedInstance().requestRecordPermission { state in
                if !state {
                    print("please allow mic permession to use the app")
                }else {
                                        
                    DispatchQueue.global(qos: .background).async {
                        DispatchQueue.main.async {
                            
                            self.setAutoMode(true)
                            
                            //MARK: Start capturing audio
                            ToggleRecording(bgMode: true, recording: true)
                            
                        }
                    }
                    
                    SharedManager.shared.enterInBackgroundWhenRecording = true
                    
                    // Send Match request one by two seconds
                    self.backgroundTimer = RepeatingTimer(timeInterval: 2.0)
                    self.backgroundTimer?.eventHandler = {
                        MatchManager.shared.GetMatchNew(bgMode: true)
                    }
                    self.backgroundTimer?.resume()
                }
            }
            
        }
    }
            
    private func setAutoMode(_ autoMode: Bool) {
        self.autoMode = autoMode
        updateHints()
        initHintsAnimation()
        rotateTrack()
    }
    
    // Rotate track
    private func rotateTrack() {
        if autoMode {
            self.btnTrack.rotate(duration: 10)
        } else {
            self.btnTrack.stopRotating()
        }
    }

    // Hint label animation initialize
    private func initHintsAnimation() {
        
        indexHint = 0
        for lbl in lblHints {
            lbl.alpha = 0
            lbl.isHidden = true
        }
        self.lblHints[self.indexHint].alpha = 1
        self.lblHints[self.indexHint].isHidden = false
    }

    // Update hint label animation
    private func updateHints() {
        if autoMode {
            for i in 0 ..< lblHints.count {
                lblHints[i].text = hintsAuto[i]
            }
        } else {
            for i in 0 ..< lblHints.count {
                lblHints[i].text = hints[i]
            }
        }
    }
    
    // Animate hint label
    private func animateHints() {
        
        UIView.animate(withDuration: 1, delay: 2.5, options: .curveEaseOut, animations: {
            self.lblHints[self.indexHint].alpha = 0
        }) { (finished) in
            self.lblHints[self.indexHint].isHidden = true
            self.indexHint += 1
            if self.indexHint == self.lblHints.count {
                self.indexHint = 0
            }
            self.lblHints[self.indexHint].isHidden = false
            UIView.animate(withDuration: 1, delay: 0, options: .curveEaseOut, animations: {
                self.lblHints[self.indexHint].alpha = 1
            }) { (finished) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.0, execute: {
                    self.animateHints()
                })
            }
        }
    }
    
    // MARK: IBAction methods
    @IBAction func onBtnSettings(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "segueSettings", sender: nil)
    }
    
    // MARK: Segue event(prepare for segue)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueSettings" {
            let settingsVC = segue.destination as! SettingsViewController
            settingsVC.homeVCDelegate = self
            settingsVC.autoMode = self.autoMode
        }else if segue.identifier == "segueTrack" {
            let _ = segue.destination as! ListeningViewController
        }
    }
    
    //MARK: RSLoadingView(show/hide)
    func showOnWindow() {
       let loadingView = RSLoadingView()
       loadingView.showOnKeyWindow()
        
    }

    func hideLoadingHubFromKeyWindow() {
       RSLoadingView.hideFromKeyWindow()
        
    }
    
    //MARK: Create CDAlertView
    func AlertMessage(title: String, message: String) {
        
        let alert = CDAlertView(title: title, message: message, type: .notification)//.custom(image: UIImage(named: "AppIcon")!)
        
        let trys = CDAlertViewAction(title: "Sign Up")
        alert.isTextFieldHidden = true
        alert.add(action: trys)
       
        alert.hideAnimations = { (center, transform, alpha) in
//            transform = .identity
            transform = CGAffineTransform(scaleX: 1, y: 1)
            alpha = 0
        }
        
        alert.hideAnimationDuration = 0.1

        alert.show() { (alert) in
            
            self.SignupAction()
        }
    }
}

// MARK: HomeVCDelegate implementation.
extension HomeViewController: HomeVCDelegate {
    
    func didAutoModeChanged(_ autoMode: Bool) {
        self.setAutoMode(autoMode)
    }
}
