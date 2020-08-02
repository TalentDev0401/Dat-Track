//
//  Date+InternetDateTime.swift
//  Audio
//
//  Created by Talent on 05.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation

enum DateFormatHint {

    case DateFormatHintNone
    case DateFormatHintRFC822
    case DateFormatHintRFC3339
}

extension Date {
    
    // MARK: Converting ISO8601
    
    static func dateWithISO8601String(string: String) -> Date? {
        
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ" // full ISO 8601
        
        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZ" // full ISO 8601
        utcFormatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        
        let formatterLock = NSLock()
        var retval: Date? = nil
        formatterLock.lock()
        retval = localFormatter.date(from: string)
        formatterLock.unlock()
        return retval
    }
    
    static func ISO8601StringWithDate(date: Date, useUTC: Bool) -> String? {
        
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'+00:00'" // full ISO 8601
        
        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'+00:00'" // full ISO 8601
        utcFormatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        
        let formatterLock = NSLock()
        
        var retval: String? = nil
        formatterLock.lock()
        if useUTC {
            retval = utcFormatter.string(from: date)
        }else {
            retval = localFormatter.string(from: date)
        }
        formatterLock.unlock()
        return retval
    }
    
    // MARK: Converting from string to date regarding different time type.
    func dateFromInternetDateTimeString(dateString: String, hint: DateFormatHint) -> Date? {
        
        var date: Date? = nil
        if hint != DateFormatHint.DateFormatHintRFC3339 {
            
            // Try RFC822 first
            date = dateFromRFC822String(dateString: dateString)
            if date == nil {
                date = dateFromRFC3339String(dateString: dateString)
            }
        }else {
            // Try FRC3339 first
            date = dateFromRFC3339String(dateString: dateString)
            if date == nil {
                date = dateFromRFC822String(dateString: dateString)
            }
        }
        
        return date
    }
    
    func dateFromRFC822String(dateString: String) -> Date {
        
        // Create Date formatter
        var dateFormatter: DateFormatter? = nil
        
        if dateFormatter == nil {
            
            let en_US_POSIX = Locale(identifier: "en_US_POSIX")
            dateFormatter = DateFormatter()
            dateFormatter?.locale = en_US_POSIX
            dateFormatter?.timeZone = TimeZone(secondsFromGMT: 0)
        }
        
        // Process
        var date: Date? = nil
        let RFC822String = dateString.uppercased()
        if RFC822String.indexInt(of: ",") != nil {
            if date == nil { // Sun, 19 May 2002 15:21:36 GMT
                dateFormatter?.dateFormat = "EEE, d MMM yyyy HH:mm:ss zzz"
                date = dateFormatter?.date(from: RFC822String)
            }
            if date == nil { // Sun, 19 May 2002 15:21 GMT
                dateFormatter?.dateFormat = "EEE, d MMM yyyy HH:mm zzz"
                date = dateFormatter?.date(from: RFC822String)
            }
            if date == nil { // Sun, 19 May 2002 15:21:36
                dateFormatter?.dateFormat = "EEE, d MMM yyyy HH:mm:ss"
                date = dateFormatter?.date(from: RFC822String)
            }
            if date == nil { // Sun, 19 May 2002 15:21
                dateFormatter?.dateFormat = "EEE, d MMM yyyy HH:mm"
                date = dateFormatter?.date(from: RFC822String)
            }
        } else {
            if date == nil { // 19 May 2002 15:21:36 GMT
                dateFormatter?.dateFormat = "d MMM yyyy HH:mm:ss zzz"
                date = dateFormatter?.date(from: RFC822String)
            }
            if date == nil { // 19 May 2002 15:21 GMT
                dateFormatter?.dateFormat = "d MMM yyyy HH:mm zzz"
                date = dateFormatter?.date(from: RFC822String)
            }
            if date == nil { // 19 May 2002 15:21:36
                dateFormatter?.dateFormat = "d MMM yyyy HH:mm:ss"
                date = dateFormatter?.date(from: RFC822String)
            }
            if date == nil { // 19 May 2002 15:21
                dateFormatter?.dateFormat = "d MMM yyyy HH:mm"
                date = dateFormatter?.date(from: RFC822String)
            }
            if date == nil { // 2012-01-25
                dateFormatter?.dateFormat = "yyyy-mm-dd"
                date = dateFormatter?.date(from: RFC822String)
            }
        }
        if date == nil {
            print("Could not parse RFC822 date: \(dateString) Possibly invalid format.")
        }
        
        return date!
    }
    
    func dateFromRFC3339String(dateString: String) -> Date {
        
        var dateFormatter: DateFormatter? = nil
        if dateFormatter == nil {
            let en_US_POSIX = Locale(identifier: "en_US_POSIX")
            dateFormatter = DateFormatter()
            dateFormatter?.locale = en_US_POSIX
            dateFormatter?.timeZone = TimeZone(secondsFromGMT: 0)
        }
        
        // Proccess date
        var date: Date? = nil
        var RFC3339String = dateString.uppercased()
        RFC3339String = RFC3339String.replacingOccurrences(of: "Z", with: "-0000")
        // Remove colon in timezone as iOS 4+ NSdateFormatter breaks. See https://devforums.apple.com/thread/45837
        if RFC3339String.count > 20 {
                        
            RFC3339String = RFC3339String.replacingOccurrences(of: ":", with: "", options: [], range: RFC3339String.rangeFromNSRange(nsRange: NSMakeRange(20, RFC3339String.count-20)))
        }
        if date == nil { // 1996-12-19T16:39:57-0800
            dateFormatter?.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"
            date = dateFormatter?.date(from: RFC3339String)
        }
        if date == nil { // 1937-01-01T12:00:27
            dateFormatter?.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss"
            date = dateFormatter?.date(from: RFC3339String)
        }
        if date == nil { // 2012-01-25
            dateFormatter?.dateFormat = "yyyy-mm-dd"
            date = dateFormatter?.date(from: RFC3339String)
        }
        if date == nil {
            print("Could not parse RFC3339 date: \(dateString) Possibly invalid format.")
        }
        return date!
    }
    
    func friendlyString() -> String? {
        
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return formatter.string(from: self)
    }
    
    func minutesAge(minutes: Int) -> Date? {
        let gregorian = Calendar(identifier: .gregorian)
        var offsetComponents = DateComponents()
        offsetComponents.minute = -minutes
        let since = gregorian.date(byAdding: offsetComponents, to: self)
        return since
    }
}
