//
//  NowPlayingViewController.swift
//  Audio
//
//  Created by Talent on 05.03.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

//*****************************************************************
// NowPlayingViewControllerDelegate
//*****************************************************************

protocol NowPlayingViewControllerDelegate: class {
    func didPressPlayingButton()
    func didPressStopButton()
    func didPressNextButton()
    func didPressPreviousButton()
}

//*****************************************************************
// NowPlayingViewControllerTapTrackDelegate
//*****************************************************************

protocol NowPlayingViewControllerTapTrackDelegate: class {
    func didPressPlayingButton()
    func didPressStopButton()
    func didPressNextButton()
    func didPressPreviousButton()
}

class NowPlayingViewController: UIViewController {
    
    weak var delegate: NowPlayingViewControllerDelegate?
    weak var tapTrackDelegate: NowPlayingViewControllerTapTrackDelegate?
    
    //MARK: - IBOutlet UI
    @IBOutlet weak var trackTitle: SpringLabel!
    @IBOutlet weak var artistTitle: UILabel!
    @IBOutlet weak var playingButton: UIButton!
    @IBOutlet weak var albumImageView: SpringImageView!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var updated_at: UILabel!
    @IBOutlet weak var musicPlayingProgressSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var timeDurationLabel: UILabel!
    
    // MARK: - Properties
    var currentMatch: Match!
    var currentTrack: RadioTrack!
    var slider: UISlider?
    var newStation = true
    let radioPlayer = FRadioPlayer.shared
    var timer: Timer?
    var loadview: Bool = false
    
    //*****************************************************************
    // MARK: - Initialize UI
    //*****************************************************************
    
    func InitUI() {
        
        if loadview {
            
            self.trackTitle.text = currentTrack.title
            self.artistTitle.text = currentTrack.artist
            albumImageView.image = currentTrack.artworkImage
            
            self.playingButton.setImage(UIImage(named: "ic_pause_white_36dp"), for: .normal)
        }
    }
    
    //*****************************************************************
    // MARK: - ViewWillAppear
    //*****************************************************************
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        self.GetCurrentProgress()
    }
    
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.musicPlayingProgressSlider.setThumbImage(UIImage(), for: .disabled)
        
        self.loadview = true

        self.InitUI()
        
        // Set duration time
        let duration = radioPlayer.durationInSeconds()
        if duration != Float(0) {
            self.timeDurationLabel.text = self.ConvertTime(duration: duration)
        }
        
    }
    
    func GetCurrentProgress() {
        
        if timer == nil {
              let forground = Timer(timeInterval: 1/60,
                                target: self,
                                selector: #selector(GetcurrentTime),
                                userInfo: nil,
                                repeats: true)
              RunLoop.current.add(forground, forMode: .common)
                        
              self.timer = forground
        }
    }
        
    @objc func GetcurrentTime() {
        
        let currentTime = radioPlayer.currentTimeInSeconds()
        self.currentTimeLabel.text = self.ConvertTime(duration: currentTime)
        self.musicPlayingProgressSlider.value = radioPlayer.currentProgress()
        
        if currentTime == radioPlayer.durationInSeconds() {
            timer?.invalidate()
            timer = nil
            self.currentTimeLabel.text = ""
            self.timeDurationLabel.text = ""
            self.musicPlayingProgressSlider.value = 0.0
        }
    }
    
    func stationDidChange() {
        radioPlayer.radioURL = URL(string: (currentMatch.track?.itunes_preview_url)!)
        albumImageView.image = currentTrack.artworkImage
        trackTitle.text = currentTrack.title
        artistTitle.text = currentTrack.artist
        
    }
    //*****************************************************************
    // MARK: - Player Controls (Play/Pause/Volume)
    //*****************************************************************
    
    // Actions
    
    @IBAction func playingPressed(_ sender: Any) {
        
        if radioPlayer.isPlaying {
            
            self.playingButton.setImage(UIImage(named: "ic_play_white_36dp"), for: .normal)
        }else {
            self.playingButton.setImage(UIImage(named: "ic_pause_white_36dp"), for: .normal)
        }
        
        delegate?.didPressPlayingButton()
        tapTrackDelegate?.didPressPlayingButton()
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        self.playingButton.setImage(UIImage(named: "ic_pause_white_36dp"), for: .normal)
        delegate?.didPressNextButton()
        tapTrackDelegate?.didPressNextButton()
    }
    
    @IBAction func previousPressed(_ sender: Any) {
        self.playingButton.setImage(UIImage(named: "ic_pause_white_36dp"), for: .normal)
        delegate?.didPressPreviousButton()
        tapTrackDelegate?.didPressPreviousButton()
    }
    
    @IBAction func goBack(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func musicPlayingProgressSliderValueChanged(_ sender: Any) {
        
        //if appDelegate.AudioMan.player.isPlaying {
        //    appDelegate.AudioMan.player.togglePlaying()
        //}
        
        //let targetTime:CMTime = CMTimeMake(value: Int64(self.musicPlayingProgressSlider.value), timescale: Int32(1))
        
        //appDelegate.AudioMan.player.changeCurrentTime(time: targetTime)
        
        //timer?.invalidate()
        //timer = nil
        
        //appDelegate.AudioMan.player.togglePlaying()
    }
    
    //*****************************************************************
    // MARK: - Load station/track
    //*****************************************************************
    
    func load(match: Match?, track: RadioTrack?, isNewStation: Bool = true) {
        guard let match = match else { return }
        
        currentMatch = match
        currentTrack = track
        newStation = isNewStation
    }
    
    func updateTrackMetadata(with track: RadioTrack?) {
        guard let track = track else { return }
        
        currentTrack.artist = track.artist
        currentTrack.title = track.title
        
    }
    
    // Update track with new artwork
    func updateTrackArtwork(with track: RadioTrack?) {
        guard let track = track else { return }
        
        // Update track struct
        currentTrack.artworkImage = track.artworkImage
        currentTrack.artworkLoaded = track.artworkLoaded
        
        albumImageView.image = currentTrack.artworkImage
        
        if track.artworkLoaded {
            // Animate artwork
            albumImageView.animation = "wobble"
            albumImageView.duration = 2
            albumImageView.animate()
        }
        
        // Force app to update display
        view.setNeedsDisplay()
    }
   
    func playbackStateDidChange(_ playbackState: FRadioPlaybackState, animate: Bool) {
        
        switch playbackState {
        case .paused:
            print("Station Paused...")
        case .playing:
            print("now plaing")
        case .stopped:
            print("Station Stopped...")
        }
        
        
    }
    
    func playerStateDidChange(_ state: FRadioPlayerState, animate: Bool) {
       
        switch state {
        case .loading:
            print("Loading Station ...")
        case .urlNotSet:
            print("Station URL not valide")
        case .readyToPlay:
            playbackStateDidChange(radioPlayer.playbackState, animate: animate)
        case .loadingFinished:
            playbackStateDidChange(radioPlayer.playbackState, animate: animate)
            
            // Set time duration to time label
            let duration = radioPlayer.durationInSeconds()
            self.timeDurationLabel.text = self.ConvertTime(duration: duration)
            // Set current time to current time label
            self.GetCurrentProgress()
                        
        case .error:
            print("Error Playing")
        }
        
    }
    
    func shouldAnimateSongLabel(_ animate: Bool) {
        // Animate if the Track has album metadata
        guard animate, currentTrack.title != currentMatch.track?.title! else { return }
        
        // songLabel animation
        trackTitle.animation = "zoomIn"
        trackTitle.duration = 1.5
        trackTitle.damping = 1
        trackTitle.animate()
        
        // Force app to update display
        view.setNeedsDisplay()
    }
    
    func shouldAnimateAlbumImage(_ animate: Bool) {
        
        // Animate artwork
        albumImageView.animation = "wobble"
        albumImageView.duration = 2
        albumImageView.animate()
        
        // Force app to update display
        view.setNeedsDisplay()
    }
    
    func ConvertTime(duration: Float) -> String {
        
        var fullString = ""
        
        let durationInt = Int(duration)
        if durationInt > 59 {
            
            let minutes = Int(durationInt/60)
            let seconds = durationInt % 60
            
            var minutesString = ""
            var secondsString = ""
            
            if minutes > 9 {
                minutesString = "\(minutes)"
            }else {
                minutesString = "0\(minutes)"
            }
            
            if seconds > 9 {
                secondsString = "\(seconds)"
            }else {
                secondsString = "0\(seconds)"
            }
            
            fullString = minutesString + ":" + secondsString
            
        }else {
            
            var secondsString = ""
            if durationInt > 9 {
                secondsString = "\(durationInt)"
            }else {
                secondsString = "0\(durationInt)"
            }
            
            fullString = "00:\(secondsString)"
        }
        
        return fullString
    }

}
