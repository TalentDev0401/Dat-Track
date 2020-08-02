//
//  AlbumManager.swift
//  Audio
//
//  Created by Talent on 03.03.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import SwiftTryCatch
import CoreData

class AlbumManager {
    
    static let shared = AlbumManager()
    
    init() {}
    
    // Fetching all Album objects
    func fetchAlbumObjects() -> [Album] {
        
        var albumDetail: [NSManagedObject] = []
        var albumdetails: [Album] = []
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Album")
        
        do {
            
            albumDetail = try managedContext.fetch(fetchRequest)
            
            for item in albumDetail {
                let detail = item as! Album
                albumdetails.append(detail)
            }
            
            return albumdetails
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return []
        
    }
   
    func GetAlbum(album: JSON, track: Track, context: NSManagedObjectContext) {
        
        let idValue = NSNumber(value: album["id"].intValue)
        
        // Check whether track data is new or not.
        let albums = self.fetchAlbumObjects()
        
        if albums.count == 0 {
            
            self.SetAlbumValueToCoreData(album: album, track: track, context: context)
            
        }else {
            
//            let filteredAlbum = albums.filter{ $0.id == idValue.int64Value }
//            if filteredAlbum.count == 0 {
//
//                self.SetAlbumValueToCoreData(album: album, track: track, context: context)
//
//            }else {
//                print("application has already the same Album")
//            }
            
            self.SetAlbumValueToCoreData(album: album, track: track, context: context)
            
        }
        
    }
    
    func SetAlbumValueToCoreData(album: JSON, track: Track, context: NSManagedObjectContext) {
        
        let albumDetail = Album(context: context)
        
        for (key, value) in album {
            
            let tempValue = album[key]

            if !tempValue.isNull {

                SwiftTryCatch.try({
                    
                    // try something
                    albumDetail.setValue(value, forKey: key)

                     }, catch: { (error) in
                        print("\(String(describing: error?.name))")

                        if error?.name.rawValue == "NSInvalidArgumentException" {

                            let exceptionString = APIManager.shared.findDesiredTypeIn(exceptionReason: (error?.reason)!)

                            print("exception reason ******** \(String(describing: exceptionString))")

                            let newValue = APIManager.shared.castValue(value: value, exceptionReason: (error?.reason)!)
                            print("new value is *******\(String(describing: newValue))")
                            
                            albumDetail.setValue(newValue, forKey: key)
                            
                        }

                     }, finally: {
                         // close resources
                        
                        print("Finally closed")
                })
            }
        }
        
        track.album = albumDetail
        
    }
    
}
