//
//  String.swift
//  Audio
//
//  Created by Talent on 02.03.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation

// MARK: Getting, appending, deleting lastpath in string.
extension String {
    var fileURL: URL {
        return URL(fileURLWithPath: self)
    }

    func appendingPathComponent(_ string: String) -> String {
        return fileURL.appendingPathComponent(string).path
    }

    var lastPathComponent:String {
        get {
            return fileURL.lastPathComponent
        }
    }

   var deletingPathExtension: String {
    return fileURL.deletingPathExtension().path
   }
}

// MARK: Converting into Range from NSRange
extension String {
    
    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        return Range(nsRange, in: self)
    }
}

// MARK: add function that locate special character in string
public extension String {
  func indexInt(of char: Character) -> Int? {
    return firstIndex(of: char)?.utf16Offset(in: self)
  }
}

// MARK: Get string without lastpath component from url
extension String {
    
    var ns: NSString {
        return self as NSString
    }

    var pathExtension: String {
        return ns.pathExtension
    }

    var lastPathComponentString: String {
        return ns.lastPathComponent
    }

    var stringByDeletingLastPathComponentString: String {
        return ns.deletingLastPathComponent
    }
    
}
