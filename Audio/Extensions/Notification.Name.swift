//
//  Notification.Name.swift
//  Audio
//
//  Created by Talent on 02.03.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation

// MARK: NotificationCenter names
extension Notification.Name {
    static let didReceiveMatchDataInForground = Notification.Name("didReceiveMatchDataInForground")
    static let didReceiveMatchDataInBackground = Notification.Name("didReceiveMatchDataInBackground")
    static let kRPMSettingsUserToggledRecordingNotification = Notification.Name("userToggledRecordingNotification")
    static let successSignUp = Notification.Name("successSignUp")
    static let kPreviewStoppedNotification = Notification.Name("previewStopped")
    static let previewAniToggle = Notification.Name("previewAniToggle")
    static let timeOut = Notification.Name("timeout")
    static let EnterForegroundWhenTapTrack = Notification.Name("EnterForegroundWhenTapTrack")
    static let EnterBackgroundWhenAutoTrack = Notification.Name("EnterBackgroundWhenAutoTrack")
}
