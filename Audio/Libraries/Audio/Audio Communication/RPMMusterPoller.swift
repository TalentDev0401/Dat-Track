//
//  RPMMusterPoller.swift
//  Audio
//
//  Created by Talent on 12.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation

class RPMMusterPoller {
    
    var musterTimer: Timer!
    
    func startTimer_FG() {
        
        self.stopTimer()
        self.musterTimer = Timer.scheduledTimer(timeInterval: TimeInterval(Constants.kRPMWaitUnitNextMusterMatchPull_BG), target: self, selector: #selector(tick_FG(timer:)), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        
        self.musterTimer.invalidate()
    }
    
    @objc func tick_FG(timer: Timer) {
        
        let appState = UIApplication.shared.applicationState
        _ = appState == UIApplication.State.background || appState == UIApplication.State.inactive
        
        
    }
}
