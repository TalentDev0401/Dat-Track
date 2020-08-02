//
//  UserModel.swift
//  Audio
//
//  Created by Talent on 04.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class UserModel {
    
    var year_born: Int16?
    var longitude: Decimal?
    var last_name: String?
    var access_token: String?
    var email: String?
    var birth_date: String?
    var first_name: String?
    var created_on: Date?
    var latitude: Decimal?
    var created_at: Date?
    var facebook_id: String?
    var last_login_date: Date?
    var updated_on: Date?
    var sex: String?
    var updated_at: Date?
    var id: Int64?
    
    init(userinfo: NSManagedObject) {
       
        year_born = userinfo.value(forKey: "year_born") as? Int16
        longitude = userinfo.value(forKey: "longitude") as? Decimal
        last_name = userinfo.value(forKey: "last_name") as? String
        access_token = userinfo.value(forKey: "access_token") as? String
        email = userinfo.value(forKey: "email") as? String
        birth_date = userinfo.value(forKey: "birth_date") as? String
        first_name = userinfo.value(forKey: "first_name") as? String
        created_on = userinfo.value(forKey: "created_on") as? Date
        latitude = userinfo.value(forKey: "latitude") as? Decimal
        created_at = userinfo.value(forKey: "created_at") as? Date
        facebook_id =  userinfo.value(forKey: "facebook_id") as? String
        last_login_date =  userinfo.value(forKey: "last_login_date") as? Date
        updated_on = userinfo.value(forKey: "updated_on") as? Date
        sex = userinfo.value(forKey: "sex") as? String
        updated_at = userinfo.value(forKey: "updated_at") as? Date
        id = userinfo.value(forKey: "id") as? Int64
    }
}
