//
//  MatchManager.swift
//  Audio
//
//  Created by Talent on 05.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import SwiftTryCatch
import CoreData

class MatchManager {
    
    static let shared = MatchManager()
    
    var newMatchIds: [Int64] = []
    var newMatches: [Int16] = []
            
    init() {}
    
    func GetMatchAll() {
        
        // Create parameters for get request
        let udid = DefaultsManager.shared.getDeviceId()!
                               
        let params = [Constants.udid: udid]
        
        self.getMatchesForceNetworkCall(params: params) { (data, errormsg) in
            
            if let error = errormsg {

                print("error occured : *****\(error.localizedDescription)")

                return
            }

            if let matches = data {
                
                if matches["error"].stringValue != "Anonymous user not found or invalid" {

                    if matches.count != 0 {
                        
                        // Save Matches to Core data when signup was successful.
                        self.GetMatchFromJSON(matchArray: matches)
                    }
                }
                
            }
            
        }
        
    }
    
    func GetMatchNew(bgMode: Bool) {
        
        // Create parameters for get request
        let udid = DefaultsManager.shared.getDeviceId()!
        let utcString = Date.ISO8601StringWithDate(date: Date(), useUTC: true)
    
        print("utc String is \(String(describing: utcString))")
               
        let params = [Constants.udid: udid, Constants.since: "2020-02-29T22:12:57+00:00"]
                
        // Get matched data in forground
        self.getMatchesForceNetworkCall(params: params) { (data, errormsg) in


            if let error = errormsg {

                print("error occured : *****\(error.localizedDescription)")

                return
            }

            if let matches = data {

                if matches["error"].stringValue != "Anonymous user not found or invalid" {

                    if matches.count != 0 {
                        
                        // Save Matches to Core data
                        self.GetMatchFromJSON(matchArray: matches)
                        
                        if bgMode {
                            
                            if self.newMatchIds.count != 0 {
                                      
                                  var tempMatches: [Match] = []
                                  
                                  for item in self.newMatchIds {
                                      
                                      let matchesx = self.fetchMatchObjects()
                                      
                                      let filteredMatch = matchesx.filter{ $0.id == item }
                                      tempMatches.append(filteredMatch.first!)
                                      
                                  }
                            
                                  NotificationCenterAPI.api.PostMatchDataBackground(matches: tempMatches)
                            
                            }else {
                              
                                let matchesx = self.fetchMatchObjects()
                                var tempMatches: [Match] = []
                              
                                for i in 0..<self.newMatches.count {
                                    
                                    guard let old = matchesx[i].track?.duration else {
                                        break
                                    }
                                    
                                    let new = self.newMatches[i]
                                    
                                    if old < new {
                                        
                                        tempMatches.append(matchesx[i])                                        
                                    }
                                }
                                
                                if tempMatches.count != 0 {
                                    
                                    NotificationCenterAPI.api.PostMatchDataBackground(matches: tempMatches)
                                }
                            }
                            
                        }else {
                                                        
                            if self.newMatchIds.count != 0 {
                                
                                var tempMatches: [Match] = []
                                
                                for item in self.newMatchIds {
                                    
                                    let matchesx = self.fetchMatchObjects()
                                    
                                    let filteredMatch = matchesx.filter{ $0.id == item }
                                    tempMatches.append(filteredMatch.first!)
                                    
                                }
                                if tempMatches.count >= 2 {
                                    
                                    let sortMatches = tempMatches.sorted { (obj1, obj2) -> Bool in
                                        return obj1.updated_at!.compare(obj2.updated_at!) == .orderedDescending
                                    }
                                    NotificationCenterAPI.api.PostMatchDataForground(matches: sortMatches.first!)
                                }else {
                                    NotificationCenterAPI.api.PostMatchDataForground(matches: tempMatches.first!)
                                }
                                                      
                            }else {
                                
                                let matchesx = self.fetchMatchObjects()
                                
                                if matchesx.count >= 2 {
                                    
                                    let sortMatches = matchesx.sorted { (obj1, obj2) -> Bool in
                                        return obj1.updated_at!.compare(obj2.updated_at!) == .orderedDescending
                                    }
                                    
                                    NotificationCenterAPI.api.PostMatchDataForground(matches: sortMatches.first!)
                                    
                                }else {
                                    
                                    NotificationCenterAPI.api.PostMatchDataForground(matches: matchesx.first!)
                                }
                            }
                        }
                    }
                }
                
                self.newMatches.removeAll()
                self.newMatchIds.removeAll()
            }
        }
    }
    
    // MARK: Get match data from server
    func getMatchesForceNetworkCall(params: [String: Any], completion: @escaping (_ response: JSON?, _ error: Error?) -> ()) {
       
        let ids = UserManager.shared.fetchUserDetail().first!.id!
        print((String(describing: ids)))
        let path = Constants.baseURL + Constants.matchURL + "\(String(describing: ids)).json"
        
        APIManager.shared.doRequestWithParams_Get(request_URL: path, params: params) { (response, error) in
            
            if let error = error {
                
                completion(nil, error)
                return
            }
            
            if let response = response {
                
                completion(response, nil)
                return
            }
        }
    }
    
    // Fetching all Match objects
    func fetchMatchObjects() -> [Match] {
        
        var matchdetails: [Match] = []
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<Match>(entityName: "Match")
        
        do {
            
            matchdetails = try managedContext.fetch(fetchRequest)
           
            return matchdetails
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return []
        
    }
   
    // Add user with udid to coredata
    func GetMatchFromJSON(matchArray: JSON) {
       
        for i in 0..<matchArray.count {
            
            let match = matchArray[i]            
            
            let idValue = NSNumber(value: match["id"].intValue)
            
            // Check whether match data is new or not.
            let matches = self.fetchMatchObjects()
            
            if matches.count == 0 {
                
                self.newMatchIds.append(idValue.int64Value)
                self.SetMatchValueToCoreData(match: match)
                continue
                
            }else {
                
                let filteredMatch = matches.filter{ $0.id == idValue.int64Value }
                if filteredMatch.count == 0 {

                    self.newMatchIds.append(idValue.int64Value)
                    self.SetMatchValueToCoreData(match: match)

                }else {
                    
                    let duration = match["track"]["duration"].int16Value
                    newMatches.append(duration)
                    
                    print("application has already the same Match")
                }                
                
                continue
            }
        }
    }
    
    func SetMatchValueToCoreData(match: JSON) {
        
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = appDelegate.persistentContainer.viewContext
        
                
        let matchDetail = Match(context: privateContext)
        
        for (key, value) in match {
            
            if key == "track" {
                
                TrackManager.shared.GetTrack(track: value, match: matchDetail, context: privateContext)
                continue
            }

            let tempValue = match[key]

            if !tempValue.isNull {

                SwiftTryCatch.try({
                    
                    // try something
                    matchDetail.setValue(value, forKey: key)

                     }, catch: { (error) in
                        print("\(String(describing: error?.name))")

                        if error?.name.rawValue == "NSInvalidArgumentException" {

                            let exceptionString = APIManager.shared.findDesiredTypeIn(exceptionReason: (error?.reason)!)

                            print("exception reason ******** \(String(describing: exceptionString))")

                            let newValue = APIManager.shared.castValue(value: value, exceptionReason: (error?.reason)!)
                            print("new value is *******\(String(describing: newValue))")
                            
                            matchDetail.setValue(newValue, forKey: key)
                            
                        }

                     }, finally: {
                         // close resources
                        
                        print("Finally closed")
                })
            }
        }
        
        // Save each item in UserDetail
        do {
            
            try privateContext.save()
            try privateContext.parent?.save()
        } catch let error as NSError {
          print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
}
