//
//  JSON.swift
//  Audio
//
//  Created by Talent on 02.03.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import SwiftyJSON

// MARK: add function whether value is nil or not to JSON
extension JSON {
    public var isNull: Bool {
        get {
            return self.type == .null;
        }
    }
}
