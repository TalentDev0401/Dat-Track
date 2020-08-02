//
//  DefaultsManager.swift
//  OriginHealth
//
//  Created by TeamPlayer on 1/6/20.
//  Copyright © 2020 OriginHealth. All rights reserved.
//

import Foundation

class DefaultsManager {
    static let shared = DefaultsManager()
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        
    }
    
    // Set user id
    func setUserId(_ id: Int64?) {
        userDefaults.set(id, forKey: "id")
        userDefaults.synchronize()
    }

    // Set udid of device
    func setDeviceId(_ udid: String?) {
        userDefaults.set(udid, forKey: "deviceId")
        userDefaults.synchronize()
    }
    
    // get udid of device
    func getDeviceId() -> String? {
        
        return userDefaults.string(forKey: "deviceId")
    }

    // Set token
    func setToken(_ token: String?) {
        userDefaults.set(token, forKey: "access_token")
        userDefaults.synchronize()
    }
    
    // Get token
    func getToken() -> String? {
        return userDefaults.string(forKey: "access_token")
    }

    // Delete authentication data from UserDefaults
    func deleteAuth() {
        userDefaults.removeObject(forKey: "id")
        userDefaults.removeObject(forKey: "deviceId")
        userDefaults.removeObject(forKey: "access_token")
    }
    
    // Clear all UserDefaults data from device
    func resetDefaults() {
        
        let dictionary = userDefaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            userDefaults.removeObject(forKey: key)
        }
    }
}
