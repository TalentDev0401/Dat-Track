//
//  UserManager.swift
//  Audio
//
//  Created by TeamPlayer on 1/16/20.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import SwiftTryCatch
import CoreData

class UserManager {
    
    static let shared = UserManager()
    init() {}
            
    // MARK: Signup with UDID.
    /** sign up with udid
     After successful signup, get response data(user info: first name, last name, email....
     */
    func signUp(completion: @escaping (_ response1 : JSON?, _ errormsg: Error?) -> ()) {
        
        let udid = getUDID()
        
        var params: [String: Any] = [:]
        params[Constants.udid] = udid
        
        let path = Constants.signupURL
        let request_URL = "\(Constants.baseURL)\(path)"
        
        APIManager.shared.doRequestWithParams_AFNetworking(request_URL: request_URL, method: Constants.PostMethod, params: params) { (data, error) in
            
            if let error = error {
                
                completion(nil, error)
                return
            }
            
            if let data = data {
                
                DefaultsManager.shared.setDeviceId(udid)
                
                print("UDID is \(String(describing: DefaultsManager.shared.getDeviceId()))")
                
                //MARK: Fetching, Add, Update, Save to core data using MagicalRecord
                // add user info(uuid) into coredata
                self.AddUser(uuid: udid)
                // Update user's detailed info
                self.UpdateUserDetail(userinfo: data)
                // Save to core data
                appDelegate.saveContext()
                                
                completion(data, nil)
            }
            
        }
    }
    
    // MARK: Signin with UDID.
    /** sign in with udid
     After successful signin, get response data(user info: first name, last name, email....
     */
    func signIn(params: [String: Any], completion: @escaping (_ response1 : JSON?, _ errormsg: Error?) -> ()) {
        
        let udid = getUDID()
        
        var params: [String: Any] = [:]
        params[Constants.udid] = udid
        
        let path = Constants.loginURL
        let request_URL = "\(Constants.baseURL)\(path)"
        
        APIManager.shared.doRequestWithParams_AFNetworking(request_URL: request_URL, method: Constants.PostMethod, params: params) { (data, error) in
           
            if let error = error {
                
                completion(nil, error)
                return
            }
            
            if let data = data {
                
                // Save UUID to UserDefaults
                DefaultsManager.shared.setDeviceId(udid)
                
                //MARK: Fetch User and set(MagicalRecord)
                // Update user's detailed info
                self.UpdateUserDetail(userinfo: data)
                appDelegate.saveContext()
                
                completion(data, nil)
            }
        }
    }
    
    // MARK: - MagicalRecord Methods
    // Fetching user by udid
    func fetchUser() -> [NSManagedObject] {
        
        var user: [NSManagedObject] = []
        // Fetch records from Entity Beer using a MagicalRecord method.
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "User")
        
        do {
            user = try managedContext.fetch(fetchRequest)
            return user
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return []
        
    }
    
    // Fetching userDetail
    func fetchUserDetail() -> [UserModel] {
        
        var userDetail: [NSManagedObject] = []
        var userdetails: [UserModel] = []
       
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "UserDetail")
        
        do {
            userDetail = try managedContext.fetch(fetchRequest)
            
            for item in userDetail {
                let detail = UserModel(userinfo: item)
                userdetails.append(detail)
            }
            
            return userdetails
            
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return []
    }
    
    // Add user with udid to coredata
    func AddUser(uuid: String) {
        
                        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "User", in: managedContext)!
        let user = NSManagedObject(entity: entity, insertInto: managedContext)
        user.setValue(uuid, forKeyPath: "udid")

        do {
          try managedContext.save()
        } catch let error as NSError {
          print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    // Update user detail info
    func UpdateUserDetail(userinfo: JSON) {
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "UserDetail", in: managedContext)!
        let userDetail = NSManagedObject(entity: entity, insertInto: managedContext)
        
        for (key, value) in userinfo {
            
            let tempValue = userinfo[key]
            
            if !tempValue.isNull {
                
                SwiftTryCatch.try({
                         // try something
                        userDetail.setValue(value, forKey: key)
                    
                     }, catch: { (error) in
                        print("\(String(describing: error?.name))")
                       
                        if error?.name.rawValue == "NSInvalidArgumentException" {
                            
                            let exceptionString = APIManager.shared.findDesiredTypeIn(exceptionReason: (error?.reason)!)
                            
                            print("exception reason ******** \(String(describing: exceptionString))")
                            
                            let newValue = APIManager.shared.castValue(value: value, exceptionReason: (error?.reason)!)
                            print("new value is *******\(String(describing: newValue))")
                            userDetail.setValue(newValue, forKey: key)
                            
                        }
                        
                     }, finally: {
                         // close resources
                })
                
                // Save each item in UserDetail
                do {
                  try managedContext.save()
                } catch let error as NSError {
                  print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
    }
           
    class func path() -> String {
        return "users"
    }
    
    // MARK: URL requests
    // For Audio Uploader
    func identifiedRequestToURL(url: URL) -> GeneralMultipartRequest {
        
        let ids = self.fetchUserDetail().first?.id
        
        let request = GeneralMultipartRequest.init(url: url)
        request?.addValue(ids, forField: "id")
        return request!
        
    }
}
