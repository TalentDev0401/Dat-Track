//
//  Utils.swift
//  Audio
//
//  Created by Talent on 02.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import UIKit
import CoreData

let appDelegate = UIApplication.shared.delegate as! AppDelegate

// MARK: Get UUID from device
func getUDID() -> String {
    return UIDevice.current.identifierForVendor?.uuidString ?? ""
}

// MARK: Toggle Recording(start and stop capturing)
func ToggleRecording(bgMode: Bool, recording: Bool) {
                    
    let userDefaults = UserDefaults.standard
    userDefaults.set(bgMode, forKey: "bgMode")
    userDefaults.synchronize()
    
    let info = [Constants.kRPMSettingsUserToggledRecordingValue: recording]
    NotificationCenter.default.post(name: Notification.Name.kRPMSettingsUserToggledRecordingNotification, object: nil, userInfo: info)
}

// Delete Entity
func DeleteEntity(entity: String) {
    
    var datas: [NSManagedObject] = []
    // Fetch records from Entity Beer using a MagicalRecord method.
    let managedContext = appDelegate.persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entity)
            
    do {
        datas = try managedContext.fetch(fetchRequest)
        
        for item in datas {
            
            let objectToDelete = item
            managedContext.delete(objectToDelete)
            
            do {
              try managedContext.save()
            } catch let error as NSError {
              print("Could not save. \(error), \(error.userInfo)")
            }
        }
        
    } catch let error as NSError {
        print("Could not Delete. \(error), \(error.userInfo)")
    }
}

// Clear all local data(Core Data and UserDefaults data)
func ClearAllData() {
    
    DeleteEntity(entity: "User")
    DeleteEntity(entity: "UserDetail")
    DeleteEntity(entity: "Match")
    DeleteEntity(entity: "Track")
    DeleteEntity(entity: "Artist")
    DeleteEntity(entity: "Album")
    DefaultsManager.shared.resetDefaults()
}

func ClearMatchData() {
    DeleteEntity(entity: "Match")
    DeleteEntity(entity: "Track")
    DeleteEntity(entity: "Artist")
    DeleteEntity(entity: "Album")
}
