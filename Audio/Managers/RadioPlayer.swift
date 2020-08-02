//
//  RadioPlayer.swift
//  SwiftRadio
//
//  Created by Fethi El Hassasna on 2018-01-05.
//  Copyright © 2018 matthewfecher.com. All rights reserved.
//

import UIKit

//*****************************************************************
// RadioPlayerDelegate: Sends FRadioPlayer and Station/Track events
//*****************************************************************

protocol RadioPlayerDelegate: class {
    func playerStateDidChange(_ playerState: FRadioPlayerState)
    func playbackStateDidChange(_ playbackState: FRadioPlaybackState)
    func trackDidUpdate(_ track: RadioTrack?)
    func trackArtworkDidUpdate(_ track: RadioTrack?)
}

//*****************************************************************
// RadioPlayer: App Radio Player
//*****************************************************************

class RadioPlayer {
    
    weak var delegate: RadioPlayerDelegate?
    
    let player = FRadioPlayer.shared
    
    var match: Match? {
        didSet { resetTrack(with: match) }
    }
    
    private(set) var track: RadioTrack?
    
    init() {
        player.delegate = self
    }
    
    func resetRadioPlayer() {
        match = nil
        track = nil
        player.radioURL = nil
    }
    
    //*****************************************************************
    // MARK: - Track loading/updates
    //*****************************************************************
    
    // Update the track with an artist name and track name
    func updateTrackMetadata(artistName: String, trackName: String) {
        if track == nil {
            track = RadioTrack(title: trackName, artist: artistName)
        } else {
            track?.title = trackName
            track?.artist = artistName
        }
        
        delegate?.trackDidUpdate(track)
    }
    
    // Update the track artwork with a UIImage
    func updateTrackArtwork(with image: UIImage, artworkLoaded: Bool) {
        track?.artworkImage = image
        track?.artworkLoaded = artworkLoaded
        delegate?.trackArtworkDidUpdate(track)
    }
    
    // Reset the track metadata and artwork to use the current station infos
    func resetTrack(with match: Match?) {
        guard let match = match else { track = nil; return }
        updateTrackMetadata(artistName: (match.track?.artist?.name)!, trackName: (match.track?.title)!)
        resetArtwork(with: match)
    }
    
    // Reset the track Artwork to current station image
    func resetArtwork(with match: Match?) {
        guard let match = match else { track = nil; return }
        getStationImage(from: match) { image in
            self.updateTrackArtwork(with: image, artworkLoaded: false)
        }
    }
    
    //*****************************************************************
    // MARK: - Private helpers
    //*****************************************************************
    
    private func getStationImage(from match: Match, completionHandler: @escaping (_ image: UIImage) -> ()) {
        
        if (match.track?.album?.image_album150x150)!.range(of: "http") != nil {
            
            let image150 = (match.track?.album!.image_album150x150)!
            let deletlastpath =  image150.stringByDeletingLastPathComponentString
            let image800 = deletlastpath + "/800x800bb.jpg"
            
            // load current station image from network
            ImageLoader.sharedLoader.imageForUrl(urlString: image800) { (image, stringURL) in
                completionHandler(image ?? #imageLiteral(resourceName: "albumArt"))
            }
        } else {
            
            let image150 = (match.track?.album!.image_album150x150)!
            let deletlastpath =  image150.stringByDeletingLastPathComponentString
            let image800 = deletlastpath + "/800x800bb.jpg"
            
            // load local station image
            let image = UIImage(named: image800) ?? #imageLiteral(resourceName: "albumArt")
            completionHandler(image)
        }
    }
}

extension RadioPlayer: FRadioPlayerDelegate {
    
    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayerState) {
        delegate?.playerStateDidChange(state)
    }
    
    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlaybackState) {
        delegate?.playbackStateDidChange(state)
    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange artistName: String?, trackName: String?) {
        guard
            let artistName = artistName, !artistName.isEmpty,
            let trackName = trackName, !trackName.isEmpty else {
                resetTrack(with: match)
                return
        }
        
        updateTrackMetadata(artistName: artistName, trackName: trackName)
    }
    
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        guard let artworkURL = artworkURL else { resetArtwork(with: match); return }
        
        ImageLoader.sharedLoader.imageForUrl(urlString: artworkURL.absoluteString) { (image, stringURL) in
            guard let image = image else { self.resetArtwork(with: self.match); return }
            self.updateTrackArtwork(with: image, artworkLoaded: true)
        }
    }
}
