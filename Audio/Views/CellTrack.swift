//
//  CellTrack.swift
//  Audio
//
//  Created by Talent on 04.03.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import UIKit

protocol AudioTrackDelegate {
    
    func playbackDidChange(cell: CellTrack, same: Bool)
}

class CellTrack: UITableViewCell {
    
    @IBOutlet weak var viewThumb: UIView!
    @IBOutlet weak var imgvThumb: UIImageView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var trackTitle: UILabel!
    @IBOutlet weak var artistTitle: UILabel!
    @IBOutlet weak var updated_at: UILabel!
    
    var match: Match!
    
    var delegate: AudioTrackDelegate?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        viewThumb.roundedButton(radius: 10)
        playBtn.roundedButton(radius: self.playBtn.frame.size.height/2)
    }
    
    func ConfigurationCell(match: Match, otherCellPlaying: Bool) {
        
        self.match = match
        
        
//        if otherCellPlaying {
//
//            if SharedManager.shared.isFinishPlaying {
//
//                DispatchQueue.main.async {
//                    self.playBtn.setImage(UIImage(named: "pause_t"), for: .normal)
//                }
//            }else {
//                DispatchQueue.main.async {
//                    self.playBtn.setImage(UIImage(named: "play_t"), for: .normal)
//                }
//            }
//
//        }
//
        self.trackTitle.text = match.track?.title
        self.artistTitle.text = match.track?.artist?.name!
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: match.updated_at!)
        
        // convert your string to date
        let tempDate = formatter.date(from: dateString)
        
        formatter.dateFormat = "yyyy MMM dd, hh:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        self.updated_at.text = formatter.string(from: tempDate!)
                
        if self.imgvThumb.image == nil {
        
            let image150 = (match.track?.album!.image_album150x150)!
             let deletlastpath =  image150.stringByDeletingLastPathComponentString
             let image800 = deletlastpath + "/800x800bb.jpg"
             
             let imageURL = image800 as NSString
             
             if imageURL.contains("http") {
             
             if let url = URL(string: image800) {
                 self.imgvThumb.loadImageWithURL(url: url) { (image) in
                     // station image loaded
                 }
             }
                 
             } else if imageURL != "" {
                 self.imgvThumb.image = UIImage(named: imageURL as String)
            
             }
            
        }
        
        self.imgvThumb.applyShadow()
        
//        if SharedManager.shared.selectMatchId == self.match.id {
//
//            if FRadioPlayer.shared.isPlaying {
//                self.playBtn.setImage(UIImage(named: "pause_t"), for: .normal)
//                NotificationCenter.default.post(name: Notification.Name("start_indicator"), object: nil, userInfo: nil)
//            }
//        }
        
    }
    
    @IBAction func onBtnPlay(_ sender: Any) {
        
//        if SharedManager.shared.sharedMatch != nil {
//
//            if SharedManager.shared.sharedMatch!.id != self.match.id {
//                self.playBtn.setImage(UIImage(named: "pause_t"), for: .normal)
//                delegate?.playbackDidChange(cell: self, same: false)
//            }else {
//
//                if FRadioPlayer.shared.isPlaying {
//                    self.playBtn.setImage(UIImage(named: "play_t"), for: .normal)
//                }else {
//                    self.playBtn.setImage(UIImage(named: "pause_t"), for: .normal)
//                }
//                
//                delegate?.playbackDidChange(cell: self, same: true)
//            }
//
//        }else {
//            self.playBtn.setImage(UIImage(named: "pause_t"), for: .normal)
//            delegate?.playbackDidChange(cell: self, same: false)
//        }
        
        delegate?.playbackDidChange(cell: self, same: false)
       
    }
    
    @IBAction func onBtnShare(_ sender: Any) {
    }
    
    @IBAction func onBtnAppleMusic(_ sender: Any) {
    }
}

