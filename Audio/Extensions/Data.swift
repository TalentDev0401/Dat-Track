//
//  Data.swift
//  Audio
//
//  Created by Talent on 02.03.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import UIKit

extension Data {
    func copyBytes<T>(as _: T.Type) -> [T] {
        return withUnsafeBytes { (bytes: UnsafePointer<T>) in
            Array(UnsafeBufferPointer(start: bytes, count: count / MemoryLayout<T>.stride))
        }
    }
}
