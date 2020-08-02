//
//  TracksViewController.swift
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

class TracksViewController: UIViewController {
    
    // MARK: - IBOutlet
    
    @IBOutlet weak var viewSearch: UIView!
    @IBOutlet weak var txtfSearch: UITextField!
    @IBOutlet weak var tblvTracks: UITableView!
    @IBOutlet weak var indicator: AudioIndicatorBarsView!
    @IBOutlet weak var indicatorview: UIView!
    @IBOutlet weak var loadingview: NVActivityIndicatorView!
    
    // MARK: - Properties
    
    let radioPlayer = RadioPlayer()
    var isSearch: Bool = false
        
    // Weak reference to update the NowPlayingViewController
    weak var nowPlayingViewController: NowPlayingViewController?
    
    // MARK: - Lists
    
    var dataStore: UnsafeMutablePointer<Match>?
    
    var matches = [Match]() {
        didSet {
            guard matches != oldValue else { return }
            print("Match count is \(self.matches.count)")
            
        }
    }
    
    var searchedMatches = [Match]() {
        didSet {
            guard searchedMatches != oldValue else { return }
            
            DispatchQueue.main.async {
                self.tblvTracks.reloadData()
            }
        }
    }
    
    var previousMatch: Match?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        free(dataStore)
        dataStore = nil
    }
    
    //*****************************************************************
    // MARK: - ViewDidLoad
    //*****************************************************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataStore = UnsafeMutablePointer<Match>.allocate(capacity: MemoryLayout<Match>.size)
       
        // Setup Player
        radioPlayer.delegate = self
        self.initUI()
        self.getMatches()

        // Setup Remote Command Center
        setupRemoteCommandCenter()

        // MARK: Starting audio indicator view animation if audio is already plaing.
        NotificationCenter.default.addObserver(self, selector: #selector(self.StartIndicator), name: Notification.Name("start_indicator"), object: nil)

        // MARK: Notify when current play item is finished
        NotificationCenter.default.addObserver(self, selector:#selector(self.playerDidFinishPlaying),name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: radioPlayer.player.currentPlayItem())
    }
    
    //*****************************************************************
    // MARK: - ViewDidLayoutSubView
    //*****************************************************************
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewSearch.roundedButton()
    }
   
    //*****************************************************************
    // MARK: - Initialize UI
    //*****************************************************************
    
    private func initUI() {
        let strAttr = NSAttributedString(string: "Search", attributes: [NSAttributedString.Key.foregroundColor: UIColor(hex: "#cccccc")!])
        txtfSearch.attributedPlaceholder = strAttr
        
        // MARK: Detect when search textfield is changed.
        txtfSearch.addTarget(self, action: #selector(TracksViewController.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        tblvTracks.allowsSelection = false
        
        // MARK: Init indicator view
        self.indicatorview.CircleUIView()
        self.indicatorview.ShadowUIView()
        
        // Display or hidden indicator bar if current item is playing
        if !radioPlayer.player.isPlaying {
            
            self.indicatorview.isHidden = true
        }else {
            self.indicatorview.isHidden = false            
        }
        
        // MARK: Initialize TapGestureRecorgnizer for ending text editing
        //for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    //*****************************************************************
    // MARK: - IBAction methods
    //*****************************************************************
    
    @IBAction func onBtnBack(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onBtnSettings(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "segueSettings", sender: nil)
    }
    
    @IBAction func onBtnPlayDetail(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(identifier: "NowPlayingViewController") as! NowPlayingViewController
        vc.modalPresentationStyle = .fullScreen //or .overFullScreen for transparency
                
        let newStation: Bool
        
        guard let index = getIndex(of: radioPlayer.match) else {
            
            newStation = false
            return
            
        }
        
        radioPlayer.match = isSearch ? searchedMatches[index] : matches[index]
        
        newStation = radioPlayer.match != previousMatch
        previousMatch = radioPlayer.match
        
        nowPlayingViewController = vc
        vc.load(match: radioPlayer.match, track: radioPlayer.track, isNewStation: newStation)
        vc.delegate = self
        
        self.present(vc, animated: true, completion: nil)
        
    }
    
    //*****************************************************************
    // MARK: - Load match data from core data
    //*****************************************************************
    
    func getMatches() {
        
        self.matches = MatchManager.shared.fetchMatchObjects()
        stationsDidUpdate()
    }
    
    // Start Indicator
    @objc func StartIndicator() {
        DispatchQueue.main.async {
            self.indicator.start()
        }
    }
    
    // MARK: Calling when current audio is finished.
    @objc func playerDidFinishPlaying() {
        
        print("current item was finished")
    }
    
    //*****************************************************************
    // MARK: - Private helpers
    //*****************************************************************
        
    private func stationsDidUpdate() {
        DispatchQueue.main.async {
            self.tblvTracks.reloadData()
            guard let currentmatch = self.radioPlayer.match else { return }
            
            // Reset everything if the new stations list doesn't have the current station
            if self.matches.firstIndex(of: currentmatch) == nil { self.resetCurrentMatch() }
        }
    }
    
    // Reset all properties to default
    private func resetCurrentMatch() {

        radioPlayer.resetRadioPlayer()
    }
    
    private func getIndex(of match: Match?) -> Int? {
        guard let match = match, let index = matches.firstIndex(of: match) else { return nil }
        return index
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
    
    //*****************************************************************
    // MARK: - MPNowPlayingInfoCenter (Lock screen)
    //*****************************************************************
    
    func updateLockScreen(with track: RadioTrack?) {
        
        // Define Now Playing Info
        var nowPlayingInfo = [String : Any]()
        
        if let image = track?.artworkImage {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size -> UIImage in
                return image
            })
        }
        
        if let artist = track?.artist {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        }
        
        if let title = track?.title {
            nowPlayingInfo[MPMediaItemPropertyTitle] = title
        }
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    //*****************************************************************
    // MARK: - Audio configuration
    //*****************************************************************
    
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
        
        isPlayingDidChange(radioPlayer.player.isPlaying)
    }
    
    func playerStateDidChange(_ state: FRadioPlayerState, animate: Bool) {
                        
        switch state {
        case .loading:
            self.indicator.stop()
            self.indicator.isHidden = true
            self.loadingview.startAnimating()
        case .urlNotSet:
            print("url not set")
        case .readyToPlay:
            
            playbackStateDidChange(radioPlayer.player.playbackState, animate: animate)
            
        case .loadingFinished:
            
            playbackStateDidChange(radioPlayer.player.playbackState, animate: animate)
            
            self.loadingview.stopAnimating()
            self.indicator.isHidden = false
            self.indicator.start()
                        
        case .error:
            print("Error Playing...")
        }
    }
    
}

//*****************************************************************
// MARK: - TableViewDataSource
//*****************************************************************

extension TracksViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return isSearch ? self.searchedMatches.count : self.matches.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellTrack") as! CellTrack
        
        if isSearch {
            
            if radioPlayer.match != nil {
                
                if let index = getIndex(of: radioPlayer.match) {
                    
                    if indexPath.row == index {
                        
                        cell.ConfigurationCell(match: self.searchedMatches[indexPath.row], otherCellPlaying: true)
                    }else {
                        
                        cell.ConfigurationCell(match: self.searchedMatches[indexPath.row], otherCellPlaying: false)
                    }
                }
                
            }else {
                
                cell.ConfigurationCell(match: self.searchedMatches[indexPath.row], otherCellPlaying: false)
            }
            
        }else {
            
            if radioPlayer.match != nil {
                
                if let index = getIndex(of: radioPlayer.match) {
                    
                    if indexPath.row == index {
                        
                        cell.ConfigurationCell(match: self.matches[indexPath.row], otherCellPlaying: true)
                    }else {
                        
                        cell.ConfigurationCell(match: self.matches[indexPath.row], otherCellPlaying: false)
                    }
                }
                
            }else {
                
                cell.ConfigurationCell(match: self.matches[indexPath.row], otherCellPlaying: false)
            }
        }
                
        cell.delegate = self
        
        return cell
    }
    
}

//*****************************************************************
// MARK: - UITextFieldDelegate - Search
//*****************************************************************

extension TracksViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        self.view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        guard let txt = textField.text else {return}
        if txt == "" {
            
            self.searchedMatches = self.matches
        }
        self.isSearch = true
    }
    
    // MARK: Detecting when textfield is changed, Not UITextFieldDelegate method
    @objc func textFieldDidChange(_ textField: UITextField) {

        if textField.text! != "" {
            
            self.searchedMatches = self.matches.filter{        ($0.track?.title!.lowercased().contains(textField.text!.lowercased()))!}
            
        }else {
            
            self.searchedMatches = self.matches
        }
               
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
    }
}

extension TracksViewController: AudioTrackDelegate {
        
    func playbackDidChange(cell: CellTrack, same: Bool) {
        guard let indexpath = self.tblvTracks.indexPath(for: cell) else {
            return
        }
        
        if radioPlayer.match != nil && !same {
            guard let index = getIndex(of: radioPlayer.match) else {return}
            let previousIndexPath = IndexPath(row: index, section: 0)
            self.tblvTracks.reloadRows(at: [previousIndexPath], with: .none)
        }
        
        var match: Match!
        
        if isSearch {
            match = self.searchedMatches[indexpath.row]
        }else {
            match = self.matches[indexpath.row]
        }
        
        self.playbackSelectedMatch(match: match, indexpath: indexpath)
    }
    
    func playbackSelectedMatch(match: Match, indexpath: IndexPath) {
        
        if radioPlayer.match != nil {
            guard getIndex(of: radioPlayer.match) != nil else {return}
        }
    }
}

//*****************************************************************
// MARK: - RadioPlayerDelegate
//*****************************************************************

extension TracksViewController: RadioPlayerDelegate {
    func playerStateDidChange(_ playerState: FRadioPlayerState) {
        self.playerStateDidChange(playerState, animate: true)
        nowPlayingViewController?.playerStateDidChange(playerState, animate: true)
    }
    
    func playbackStateDidChange(_ playbackState: FRadioPlaybackState) {
        
        self.playbackStateDidChange(playbackState, animate: true)
        nowPlayingViewController?.playbackStateDidChange(playbackState, animate: true)
    }
    
    func trackDidUpdate(_ track: RadioTrack?) {
        updateLockScreen(with: track)
        nowPlayingViewController?.updateTrackMetadata(with: track)
    }
    
    func trackArtworkDidUpdate(_ track: RadioTrack?) {
        updateLockScreen(with: track)
        nowPlayingViewController?.updateTrackArtwork(with: track)
    }
   
}

//*****************************************************************
// MARK: - NowPlayingViewControllerDelegate
//*****************************************************************


extension TracksViewController: NowPlayingViewControllerDelegate {
    
    func didPressPlayingButton() {
        radioPlayer.player.togglePlaying()
    }
    
    func didPressStopButton() {
        radioPlayer.player.stop()
    }
    
    func didPressNextButton() {
        
        if isSearch {
            
            guard let index = getIndex(of: radioPlayer.match) else { return }
            radioPlayer.match = (index + 1 == searchedMatches.count) ? searchedMatches[0] : searchedMatches[index + 1]
            handleRemoteStationChange()
            
        }else {
            
            guard let index = getIndex(of: radioPlayer.match) else { return }
            radioPlayer.match = (index + 1 == matches.count) ? matches[0] : matches[index + 1]
            handleRemoteStationChange()
            
        }
       
    }
    
    func didPressPreviousButton() {
        
        if isSearch {
            
            guard let index = getIndex(of: radioPlayer.match) else { return }
            radioPlayer.match = (index == 0) ? searchedMatches.last : searchedMatches[index - 1]
            handleRemoteStationChange()
            
        }else {
            
            guard let index = getIndex(of: radioPlayer.match) else { return }
            radioPlayer.match = (index == 0) ? matches.last : matches[index - 1]
            handleRemoteStationChange()
            
        }
  
    }
    
    func handleRemoteStationChange() {
        
        if let nowPlayingVC = nowPlayingViewController {
            // If nowPlayingVC is presented
            nowPlayingVC.load(match: radioPlayer.match, track: radioPlayer.track)
            nowPlayingVC.stationDidChange()
        } else if let match = radioPlayer.match {
                                    
            // If nowPlayingVC is not presented (change from remote controls)
            radioPlayer.player.radioURL = URL(string: (match.track?.itunes_preview_url)!)
        }
    }
}
