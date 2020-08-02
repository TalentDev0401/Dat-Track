//
//  MusicFoundViewController.swift
//  Audio
//
//  Created by TeamPlayer on 1/14/20.
//  Copyright © 2020 Audio. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation
import AudioIndicatorBars
import NVActivityIndicatorView

class MusicFoundViewController: UIViewController {

    @IBOutlet weak var viewBottom: UIView!
    @IBOutlet weak var imgvThumb: UIImageView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var artistTitle: UILabel!
    @IBOutlet weak var updated_at: UILabel!
    @IBOutlet weak var indicator: AudioIndicatorBarsView!
    @IBOutlet weak var indicatorview: UIView!
    @IBOutlet weak var loadingview: NVActivityIndicatorView!
            
    // Weak reference to update the NowPlayingViewController
    weak var nowPlayingViewController: NowPlayingViewController?
    
    var match: Match!
    
    private var isFirst = true
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirst {
            isFirst = false
            viewBottom.topRoundedButton(radius: 30)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.InitUI(match: self.match)
                
//        appDelegate.AudioMan.delegate = self
        
        appDelegate.AudioMan.playingAudioSettings()
        
        // Setup Remote Command Center
        setupRemoteCommandCenter()
//        NotificationCenter.default.addObserver(self, selector:#selector(self.playerDidFinishPlaying),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: appDelegate.AudioMan.player.currentPlayItem())
        
    }
    
    func InitUI(match: Match) {
        
        self.trackTitle.text = match.track?.title
        self.artistTitle.text = match.track?.artist?.name!
        
        let image150 = (match.track?.album!.image_album150x150)!
        let deletlastpath =  image150.stringByDeletingLastPathComponentString
        let image800 = deletlastpath + "/800x800bb.jpg"
       
//        self.imgvThumb.downloadImage(from: URL(string: image800)!)
        
        // MARK: Init indicator view
        self.indicatorview.CircleUIView()
        self.indicatorview.ShadowUIView()
        
//        if !appDelegate.AudioMan.player.isPlaying {
//
//            self.indicatorview.isHidden = true
//        }else {
//            self.indicatorview.isHidden = false
//        }
    }
    
    // MARK: Calling when current audio is finished.
    @objc func playerDidFinishPlaying() {
                
        // If nowPlayingVC is not presented (change from remote controls)
//        appDelegate.AudioMan.playingAudioSettings()
//        appDelegate.AudioMan.player.radioURL = nil
//        appDelegate.AudioMan.player.radioURL = URL(string: (self.match.track?.itunes_preview_url)!)!
        
    }
    
    //*****************************************************************
    // MARK: - Remote Command Center Controls for FRadioPlayer
    //*****************************************************************
    
    func setupRemoteCommandCenter() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add handler for Play Command
        commandCenter.playCommand.addTarget { event in
            return .success
        }
        
        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { event in
            return .success
        }
        
        // Add handler for Next Command
        commandCenter.nextTrackCommand.addTarget { event in
            return .success
        }
        
        // Add handler for Previous Command
        commandCenter.previousTrackCommand.addTarget { event in
            return .success
        }
    }
    
    //MARK: IBAction
    @IBAction func onBtnClose(_ sender: Any) {
        
        FRadioPlayer.shared.stop()
        
        navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func onBtnShare(_ sender: Any) {
        
    }
    
    @IBAction func onBtnPlay(_ sender: Any) {
        
        if isFirst {
                                    
            self.indicatorview.isHidden = false
            self.indicator.isHidden = true
            
//            appDelegate.AudioMan.playingAudioSettings()
//            appDelegate.AudioMan.player.radioURL = URL(string: (match.track?.itunes_preview_url)!)!
            
        }else {
            
//            if appDelegate.AudioMan.player.isPlaying {
//
//                appDelegate.AudioMan.player.togglePlaying()
//
//                self.indicator.stop()
//                self.indicator.isHidden = true
//                self.indicatorview.isHidden = true
//
//            }else {
//                appDelegate.AudioMan.player.togglePlaying()
//                self.indicator.isHidden = false
//                self.indicator.start()
//                self.indicatorview.isHidden = false
//            }
            
        }
    }
    
    @IBAction func onBtnAppleMusic(_ sender: Any) {
        
    }
    
    @IBAction func onBtnPlayDetail(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(identifier: "NowPlayingViewController") as! NowPlayingViewController
        vc.modalPresentationStyle = .fullScreen //or .overFullScreen for transparency
        nowPlayingViewController = vc
//        vc.load(match: self.match)
        vc.tapTrackDelegate = self
        
        self.present(vc, animated: true, completion: nil)
        
    }
    
    // MARK: Audio configuration
    private func isPlayingDidChange(_ isPlaying: Bool) {
        
        startNowPlayingAnimation(isPlaying)
        
    }
    
    func startNowPlayingAnimation(_ animate: Bool) {
        //animate ? nowPlayingImageView.startAnimating() : nowPlayingImageView.stopAnimating()
    }
    
    func playbackStateDidChange(_ playbackState: FRadioPlaybackState, animate: Bool) {
        
        
        switch playbackState {
        case .paused:
            print("Station Paused...")
        case .playing:
            print("Now playing")
        case .stopped:
            print("Station Stopped...")
        }
        
//        isPlayingDidChange(appDelegate.AudioMan.player.isPlaying)
    }
    
    func playerStateDidChange(_ state: FRadioPlayerState, animate: Bool) {
                        
        switch state {
        case .loading:
            self.indicator.stop()
            self.indicator.isHidden = true
            self.loadingview.startAnimating()
        case .urlNotSet:
            print("url not set")
        case .readyToPlay: break
            
//            playbackStateDidChange(appDelegate.AudioMan.player.playbackState, animate: animate)
            
        case .loadingFinished:
            
//            playbackStateDidChange(appDelegate.AudioMan.player.playbackState, animate: animate)
            
            self.loadingview.stopAnimating()
            self.indicator.isHidden = false
            self.indicator.start()
                        
        case .error:
            print("Error Playing...")
        }
    }
    
}

extension MusicFoundViewController: RadioPlayerDelegate {
    func trackDidUpdate(_ track: RadioTrack?) {
        
    }
    
    func trackArtworkDidUpdate(_ track: RadioTrack?) {
        
    }
    
    func playerStateDidChange(_ playerState: FRadioPlayerState) {
        self.playerStateDidChange(playerState, animate: true)
        nowPlayingViewController?.playerStateDidChange(playerState, animate: true)
    }
    
    func playbackStateDidChange(_ playbackState: FRadioPlaybackState) {
        
        self.playbackStateDidChange(playbackState, animate: true)
        nowPlayingViewController?.playbackStateDidChange(playbackState, animate: true)
    }
   
}

extension MusicFoundViewController: NowPlayingViewControllerTapTrackDelegate {
    
    func didPressPlayingButton() {
//        appDelegate.AudioMan.player.togglePlaying()
    }
    
    func didPressStopButton() {
//        appDelegate.AudioMan.player.stop()
    }
    
    func didPressNextButton() {
                
        handleRemoteStationChange()
    }
    
    func didPressPreviousButton() {
        
        handleRemoteStationChange()
    }
    
    func handleRemoteStationChange() {
//        if let nowPlayingVC = nowPlayingViewController {
//            // If nowPlayingVC is presented
//            nowPlayingVC.load(match: self.match)
//            nowPlayingVC.stationDidChange()
//        } else {
//            // If nowPlayingVC is not presented (change from remote controls)
//            appDelegate.AudioMan.playingAudioSettings()
//            appDelegate.AudioMan.player.radioURL = nil
//            appDelegate.AudioMan.player.radioURL = URL(string: (self.match.track?.itunes_preview_url)!)!
//        }
    }
}
