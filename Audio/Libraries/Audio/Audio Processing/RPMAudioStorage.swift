//
//  RPMAudioStorage.swift
//  Audio
//
//  Created by Talent on 12.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation

class RPMAudioStorage: NSObject {
        
    var outString: String = ""
    var filename: String = ""
    var filterNumber: Int = 0
    var numberOfFingerprintsStored: Int = 0
    
    class func dateFromFilename(filename: String) -> Date {
        
        let index2 = filename.range(of: ".", options: .backwards)?.lowerBound
        let dateString = index2.map(filename.substring(to:))
        
        return Date.dateWithISO8601String(string: dateString!)!
    }
            
    init(filterNumber: Int) {
        super.init()
        self.filterNumber = filterNumber
        self.resetStorage()
    }
    
    func resetStorage() {
        
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                
                let appState = UIApplication.shared.applicationState
                let inBackground = appState == .background
                
                self.numberOfFingerprintsStored = 0
                let dateString = Date.ISO8601StringWithDate(date: Date(), useUTC: true)
                var filenameString = "\(dateString!)_bp\(self.filterNumber)_fp.txt"
                if inBackground {
                filenameString = "\(dateString!)_r4000.txt"
                }
                if self.filterNumber == 0{
                filenameString = "\(dateString!)_r1000.txt"
                }else if self.filterNumber == 1{
                filenameString = "\(dateString!)_r2000.txt"
                }
                let documentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentRoot = documentPaths.first!

                let tempDirectoryURL = URL(fileURLWithPath: documentRoot)
                let directoryURL = tempDirectoryURL.appendingPathComponent(filenameString)
                
                self.filename = directoryURL.path
                self.outString = ""
            }
        }
    }

    func newFingerprintReady(_ fingerprintData: Data?, fingerprintNumber: Int) {
        let fpLength = fingerprintData?.count ?? 0
        
        print("oringin \(fingerprintData!.copyBytes(as: UInt8.self))")
        
        let fingerprint = fingerprintData!.copyBytes(as: UInt8.self)
        
        for i in 0..<fpLength {
            self.outString += String(format: "%02x", fingerprint[i])
        }
        self.outString += String(format: "%05x\n", fingerprintNumber)
        numberOfFingerprintsStored += 1
    }
    
    func stopWhileSavingChanges(silenceDetected: Bool) {
        
        if silenceDetected {
            do {
                try outString.write(toFile: filename, atomically: true, encoding: .utf8)
            } catch {
            }
            outString = ""
            
        }
    }
}
