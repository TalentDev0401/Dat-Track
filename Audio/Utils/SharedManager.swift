//
//  SharedManager.swift
//  Audio
//
//  Created by Talent on 24.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation

class SharedManager {
    
    static let shared = SharedManager()
    
    var successSignup: Bool = false
    var enterInBackgroundWhenRecording: Bool = false
    var enterInForegroundWhenRecording: Bool = false
    var matchCountInAutoTracking: Int = 0
    var getMatched: Bool = false
//    var sharedMatch: Match?
//    var selectMatchId: Int64!
//    var selectIndex: Int?
//    var isFinishPlaying: Bool = false
//    var isFirst = false
    
}
