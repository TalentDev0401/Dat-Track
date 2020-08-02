//
//  ArtistManager.swift
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

class ArtistManager {
    
    static let shared = ArtistManager()
    
    init() {}
    
    // Fetching all Artist objects
    func fetchArtistObjects() -> [Artist] {
        
        var artistDetail: [NSManagedObject] = []
        var artistdetails: [Artist] = []
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Artist")
        
        do {
            
            artistDetail = try managedContext.fetch(fetchRequest)
            
            for item in artistDetail {
                let detail = item as! Artist
                artistdetails.append(detail)
            }
            
            return artistdetails
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return []
        
    }
   
    func GetArtist(artist: JSON, track: Track, context: NSManagedObjectContext) {
        
        let idValue = NSNumber(value: artist["id"].intValue)
        
        // Check whether track data is new or not.
        let artists = self.fetchArtistObjects()
        
        if artists.count == 0 {
            
            self.SetTrackValueToCoreData(artist: artist, track: track, context: context)
            
        }else {
            
//            let filteredArtist = artists.filter{ $0.id == idValue.int64Value }
//            if filteredArtist.count == 0 {
//
//                self.SetTrackValueToCoreData(artist: artist, track: track, context: context)
//
//            }else {
//                print("application has already the same Artist")
//            }
            
            self.SetTrackValueToCoreData(artist: artist, track: track, context: context)
            
        }
        
    }
    
    func SetTrackValueToCoreData(artist: JSON, track: Track, context: NSManagedObjectContext) {
        
        let artistDetail = Artist(context: context)
        
        for (key, value) in artist {
            
            let tempValue = artist[key]

            if !tempValue.isNull {

                SwiftTryCatch.try({
                    
                    // try something
                    artistDetail.setValue(value, forKey: key)

                     }, catch: { (error) in
                        print("\(String(describing: error?.name))")

                        if error?.name.rawValue == "NSInvalidArgumentException" {

                            let exceptionString = APIManager.shared.findDesiredTypeIn(exceptionReason: (error?.reason)!)

                            print("exception reason ******** \(String(describing: exceptionString))")

                            let newValue = APIManager.shared.castValue(value: value, exceptionReason: (error?.reason)!)
                            print("new value is *******\(String(describing: newValue))")
                            
                            artistDetail.setValue(newValue, forKey: key)
                            
                        }

                     }, finally: {
                         // close resources
                        print("Finally closed")
                })
            }
        }
        
        track.artist = artistDetail
        
    }
    
}
