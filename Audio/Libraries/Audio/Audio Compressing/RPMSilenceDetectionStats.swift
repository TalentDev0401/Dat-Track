//
//  RPMSilenceDetectionStats.swift
//  Audio
//
//  Created by Talent on 12.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation

class RPMSilenceDetectionStats {
    
    public var maxFFTSum: Double! = 0.0
    public var minFFTSum: Double! = 0.0
    public var sumOfFFTDiffs: Double! = 0.0
    public var sumOfAudioData: Double! = 0.0
}
