//
//  TrackManager.swift
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

class TrackManager {
    
    static let shared = TrackManager()
    
    init() {}
    
    // Fetching all Track objects
    func fetchTrackObjects() -> [Track] {
       
        var trackdetails: [Track] = []
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<Track>(entityName: "Track")
        
        do {
            
            trackdetails = try managedContext.fetch(fetchRequest)
            
            return trackdetails
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return []
        
    }
    
    func GetTrack(track: JSON, match: Match, context: NSManagedObjectContext) {
        
        print("track data is \(track)")
        
        let idValue = NSNumber(value: track["id"].intValue)
        
        // Check whether track data is new or not.
        let trackes = self.fetchTrackObjects()
        
        if trackes.count == 0 {
            
            self.SetTrackValueToCoreData(track: track, match: match, context: context)
            
        }else {
            
//            let filteredTrack = trackes.filter{ $0.id == idValue.int64Value }
//            if filteredTrack.count == 0 {
//
//                self.SetTrackValueToCoreData(track: track, match: match, context: context)
//
//            }else {
//                print("application has already the same Track")
//            }
            
            self.SetTrackValueToCoreData(track: track, match: match, context: context)
            
        }
        
    }
    
    func SetTrackValueToCoreData(track: JSON, match: Match, context: NSManagedObjectContext) {
                
        let trackDetail = Track(context: context)
        
        for (key, value) in track {
            
            if key == "artist" {
                
                ArtistManager.shared.GetArtist(artist: value, track: trackDetail, context: context)
                continue
            }
            
            if key == "album" {
                
                AlbumManager.shared.GetAlbum(album: value, track: trackDetail, context: context)
                continue
            }

            let tempValue = track[key]

            if !tempValue.isNull {

                SwiftTryCatch.try({
                    
                    // try something
                    trackDetail.setValue(value, forKey: key)

                     }, catch: { (error) in
                        print("\(String(describing: error?.name))")

                        if error?.name.rawValue == "NSInvalidArgumentException" {

                            let exceptionString = APIManager.shared.findDesiredTypeIn(exceptionReason: (error?.reason)!)

                            print("exception reason ******** \(String(describing: exceptionString))")

                            let newValue = APIManager.shared.castValue(value: value, exceptionReason: (error?.reason)!)
                            print("new value is *******\(String(describing: newValue))")
                            
                            trackDetail.setValue(newValue, forKey: key)
                            
                        }

                     }, finally: {
                         // close resources
                        
                        print("Finally closed")
                })
            }
        }
        
        match.track = trackDetail
    }
    
}
