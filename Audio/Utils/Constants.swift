//
//  Constants.swift
//  Audio
//
//  Created by TeamPlayer on 1/14/20.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import UIKit

// Display Comments
let kDebugLog = true

struct Constants {
    static let colorOrange = UIColor(hex: "#f36a10")
    
    // MARK: Base URLs
    static let baseProdURL = "https://muster.jukedmedia.com"
    static let baseStagingURL = "https://muster-staging.jukedmedia.com"
    static let baseURL = baseProdURL
    static let loginURL = "/social/v1/users/anonymous/login.json"
    static let signupURL = "/social/v1/users.json"
    static let matchURL = "/social/v1/matches/users/anonymous/"
    static let fingerprintURL = "/social/v1/fingerprints.json"
    static let kFPApiServerPreference = "http://duster.jukedmedia.com:4000/v1"
    static let kSocialApiServerPreference = "https://muster.jukedmedia.com/"
    static let kRPMAlertURLPrefix = "http://prod.jukedmedia.com:4000/duster/v1/notes/"
    
    // MARK: User
    static let udid = "udid"
    static let id = "id"
    static let since = "since"
    
    // MARK: Server method
    static let GetMethod = "GET"
    static let PostMethod = "POST"
    static let PutMethod = "PUT"
    static let kDeleteMethod = "DELETE"
    
    // MARK: Time between automatic muster calls
    static let kRPMWaitUnitNextMusterMatchPull_FG = 2
    static let kRPMWaitUnitNextMusterMatchPull_BG = 6
    
    // MARK: User info keys for notifications
    static let kRPMSettingsUserToggledRecordingValue = "userToggledRecordingValue"
    
    // MARK: The number of fingerprints per upload
    static let kRPMUserDefaultKeyFingerprintUploadRateForeground = "userdefault.uploadRateForeground"
    static let kRPMUserDefaultKeyFingerprintUploadRateBackground = "userdefault.uploadRateBackground"
    
    // MARK: Default settings for low/high rate Filters
    static let kRPMUserDefaultKeyLowRateNumSamples = "userdefault.lowRateNumSamples"
    static let kRPMUserDefaultKeyLowRateFingerprintNumberIncrement = "userdefault.lowRateFingerprintNumberIncrement"
    static let kRPMUserDefaultKeyLowRateBufferPointerIncrement = "userdefault.lowRateBufferPointerIncrement"
    static let kRPMUserDefaultKeyBackgroundLowRateNumSamples = "userdefault.backgroundLowRateNumSamples"
    static let kRPMUserDefaultKeyBackgroundLowRateFingerprintNumberIncrement = "userdefault.backgroundLowRateFingerprintNumberIncrement"
    static let kRPMUserDefaultKeyBackgroundLowRateBufferPointerIncrement = "userdefault.backgroundLowRateBufferPointerIncrement"
    static let kRPMUserDefaultKeyHighRateNumSamples = "userdefault.highRateNumSamples"
    static let kRPMUserDefaultKeyHighRateFingerprintNumberIncrement = "userdefault.highRateFingerprintNumberIncrement"
    static let kRPMUserDefaultKeyHighRateBufferPointerIncrement = "userdefault.highRateBufferPointerIncrement"
    
    // MARK: Communication
    static let kRPMUploadFileSentNotification = "uploadFileSent"
    static let kRPMUploadReceivedErrorResponseNotification = "uploadReceivedErrorResponse"
    static let kRPMUploadReceivedSuccessResponseNotification = "uploadReceivedSuccessResponse"
    static let kRPMUploadErrorNotification = "uploadError"
    static let kRPMResultsDownloadPollTimerStartedNotification = "resultsDownloadPollTimerStarted"
    static let kRPMResultsDownloadNotification = "resultsDownloadTimeout"
    static let kRPMDownloadReceivedErrorResponseNotification = "downloadReceivedErrorResponse"
    static let kRPMDownloadErrorNotification = "downloadError"
    static let kRPMHistoryRangeDownloadReceivedSuccessResponseNotification = "historyRangeDownloadReceivedSuccessResponse"
                    
}
