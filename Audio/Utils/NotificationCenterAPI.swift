//
//  NotificationCenterAPI.swift
//  Audio
//
//  Created by Talent on 06.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation

class NotificationCenterAPI {
    
    static let api = NotificationCenterAPI()
            
    // Post data with parameter( match arry) in forground.
    func PostMatchDataForground(matches: Match) {
        
        let dic = ["matches": matches]
        NotificationCenter.default.post(name: .didReceiveMatchDataInForground, object: nil, userInfo: dic)
    }
    
    // Post data with parameter( match arry) in background.
    func PostMatchDataBackground(matches: [Match]) {
        
        let dic = ["matches": matches]
        NotificationCenter.default.post(name: .didReceiveMatchDataInBackground, object: nil, userInfo: dic)
    }
    
    func SuccessSignUp() {
        NotificationCenter.default.post(name: .successSignUp, object: nil, userInfo: nil)
    }
    
    func EnterForegroundWhenTapTrack() {
        NotificationCenter.default.post(name: .EnterForegroundWhenTapTrack, object: nil, userInfo: nil)
    }
    
    func EnterBackgroundWhenAutoTrack() {
        NotificationCenter.default.post(name: .EnterBackgroundWhenAutoTrack, object: nil, userInfo: nil)
    }
}
