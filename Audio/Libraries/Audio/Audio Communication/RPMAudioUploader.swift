//
//  RPMAudioUploader.swift
//  Audio
//
//  Created by Talent on 12.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation

var audioUploaderObject: RPMAudioUploader? = nil
// Instead of uploading at fixed time intervals,
// we'll upload as we acquire the desired amount of data.
// Note that if Silence Detection is enabled, those fingerprints should not
// count towards this quota (they should be discarded immediately).
let kNumberOfFingerprintsPerFile = 32
// number of fingerprints required for upload is configured via API (see method below)
let kDefaultNumberOfFingerprintsRequiredForUploadInForeground = 32
let kDefaultNumberOfFingerprintsRequiredForUploadInBackground = 960
let kNumberOfItemsToDownloadAtStartup = 100

class RPMAudioUploader: NSObject, RPMAudioCompressorDelegate {
    
    static let shared = RPMAudioUploader()
    
    var compressors: [RPMAudioCompressor] = []
    var uploadTimer: Timer!
    var storageLock: NSLock!
    var activeUploadsLock: NSLock!
    var uploadAtFingerprintCount: Int!
    var lastFilenameSent: String!
    var lastError: Error!
    var uploadRatesRetched: Bool!
    var running: Bool = false
    var silenceDetector: RPMSilenceDetector!
    var storages: [RPMAudioStorage?]? = []
        
    class func audioUploader() -> RPMAudioUploader? {
        return audioUploaderObject
    }
    
    override init() {
        super.init()
        
        storageLock = NSLock()
        activeUploadsLock = NSLock()
        self.silenceDetector = RPMSilenceDetector()
        self.start(currentFiltNum: Int(BOTH_FILTERS))
        audioUploaderObject = self
        self.uploadAllFiles()
        self.setDefaultUploadRates()
        APIManager.shared.updateFingerprintRates()
    }
    
    func addCompressorFeed(compressor: RPMAudioCompressor) {
        compressors.append(compressor)
    }
    
    // MARK: Storage Uploading
    /**
    Triggers an immediate upload of outstanding FP data.
    
    */
    func doImmediateUpload() {
        
        self.perform(#selector(uploadAllFiles), with: nil, afterDelay: 0.0)
    }
    
    /**
    Stop & start.
    This will cause new storage files to be created; additional FPs will go there.
    Call this when we've reached the desired number of FPs per upload.
    */
    func startNextStorageBlock(currentFiltNum: Int) {
        
        self.stop(currentFiltNum: currentFiltNum)
        self.start(currentFiltNum: currentFiltNum)
        
        // See if we should upload
        let uploadableFiles = self.uploadableFiles()
        
        // TODO
        // [uploadableFiles count] returns ALL uploadable files.
        // if N_AUDIO_FILTERS > 1, then there will be multiple sets of FP files.
        // Is that expected in relation to numberOfFingerprintsRequiredForUpload?
        // Or does numberOfFingerprintsRequiredForUpload assume that's per audio filter?
        
        DispatchQueue.main.async {
            
            let savedFingerprintCount = uploadableFiles.count * kNumberOfFingerprintsPerFile
            if savedFingerprintCount >= self.numberOfFingerprintsRequiredForUpload() {
                self.doImmediateUpload()
            }
            
        }
    }
    
    /**
    Temporarily allow switching between formats
    while server errors are ironed out.
    @return YES if Upload Data should be compressed (zlib)
    */
    func shouldUploadInBinaryFormat() -> Bool {
        return true
    }
    
    /// @return All cmp files sitting in documents directory,
    ///         except the one still receiving FP data.
    func uploadableFiles() -> [String] {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let docPath = paths[0]
        
        var dir: [String]? = nil
        do {
            dir = try FileManager.default.contentsOfDirectory(atPath: docPath)
        } catch {
        }
        
        var songsToUpload: [String] = []
        for file in dir! {
            
            if (URL(fileURLWithPath: file).pathExtension == "txt") {
                let fullPath = URL(fileURLWithPath: docPath).appendingPathComponent(file).path

                // except those that are currently being recorded...
                var shouldUpload = true
                storageLock.lock()
                for storage in storages! {
                    guard let storage = storage else {
                        continue
                    }
                    if (storage.filename == fullPath) {
                        shouldUpload = false
                    }
                }
                storageLock.unlock()
                if !shouldUpload {
                    continue
                }

                songsToUpload.append(fullPath)
                lastFilenameSent = fullPath
            }
        }
        
        return songsToUpload
    }
    
    /**
    Data compression
    The saved fingerprint hex files are now compressed as binary data using zlib.
    See NSData+Compression for the implementation
    */
    @objc func uploadAllFiles() {
       
        // For the purposes of Reachability,
        // treat Muster status as a proxy for Duster
        if (RPMSocialClient.shared?.isOffline())! {
            
            print("API is offline. Delay upload until later.")
            return
        }
        
        let filesToUpload = self.uploadableFiles()
        if filesToUpload.count == 0 {
            return
        }
        
        // do the upload
        var apiRoot = Constants.kFPApiServerPreference
        let standardUserDefaults = UserDefaults.standard
        
        let stagingOn = standardUserDefaults.bool(forKey: "stagingOn")
        if stagingOn {
            apiRoot = "http://duster-staging.jukedmedia.com:4000/duster/v1"
        }
        
        let uploadTarget = String(format: "%@/fingerprints/receive", apiRoot)
        
        let url = URL(string: uploadTarget)
        
        let request: GeneralMultipartRequest = UserManager.shared.identifiedRequestToURL(url: url!)
        print("request url \(request)")
        var numberOfValidFiles = 0
        
        let udid = standardUserDefaults.string(forKey: "deviceId")
        request.addValue(udid!, forField: "udid")
        
        for i in 0...(filesToUpload.count - 1) {
            
            let fullPath = filesToUpload[i]
            let fileFieldName = String(format: "filename%d", numberOfValidFiles)
            let dataFieldName = String(format: "data%d", i)
            
            // Skip files that contain fewer than 32 FPs
            var fps: String = ""
            do {
                fps = try String(contentsOfFile: fullPath, encoding: .utf8)
//                    String(contentsOfFile: fullPath, encoding: String.Encoding(rawValue: 4))
                print(fps)
            } catch {
                print("Error occured")
            }
            
            let fpCount = fps.components(separatedBy: CharacterSet.newlines).count - 1
            if fpCount < 32 {
                print("Only \(fpCount) FPs in file. Skipping.")
                do {
                    try FileManager.default.removeItem(atPath: fullPath)
                } catch {
                }
                continue
            }
            
            if self.shouldUploadInBinaryFormat() {
                
                let compressedData: Data? = NSData(contentsOfFile: fullPath)?.zlibDeflate()
                let compressedName: String? = fullPath.lastPathComponent.replacingOccurrences(of: ".txt", with: ".bin")
                if compressedName != nil && compressedData != nil {
                    request.addValue(compressedName, forField: fileFieldName)
                    request.addValue(compressedData, forField: dataFieldName, mimeType: "application/octet-stream")
                    numberOfValidFiles += 1
                }
            }else {
                let compressedData: Data? = NSData(contentsOfFile: fullPath)?.zlibDeflate()
                request.addValue(fullPath.lastPathComponent, forField: fileFieldName)
                request.addValue(compressedData, forField: dataFieldName, mimeType: "application/octet-stream")
                numberOfValidFiles += 1
            }
            
            // Do not wait for a successful response; delete file immediately.
            do {
                
                try FileManager.default.removeItem(atPath: fullPath)
            } catch {
            }
            
        }
        
        if numberOfValidFiles > 0 {
            request.addValue(numberOfValidFiles, forField: "file-count")
            
            print("getBinaryFields value is \(String(describing: request.getBinaryFields()))")
            
            
            let urlRequest: URLRequest = request.urlRequest() as URLRequest
            print("urlRequest is \(String(describing: urlRequest))")

            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                guard let data = data,
                    let response = response as? HTTPURLResponse,
                    error == nil else {                                              // check for fundamental networking error
                    print("error", error ?? "Unknown error")
                    return
                }

                guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                    print("statusCode should be 2xx, but is \(response.statusCode)")
                    print("response = \(response)")
                    return
                }

                let responseString = String(data: data, encoding: .utf8)
                print("responseString = \(String(describing: responseString))")
            }

            task.resume()
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(Constants.kRPMUploadFileSentNotification), object: self)
        
        let appState = UIApplication.shared.applicationState
        let inBackground = appState == .background || appState == .inactive
        if inBackground && appDelegate.isRecordingSessionEnabled() {
            appDelegate.startMusterTimer_BG()
        }
        
    }
    
    func numberOfFingerprintsRequiredForUpload() -> Int {
        
        let appState = UIApplication.shared.applicationState
        var inBackground: Bool = false
        inBackground = appState == .background || appState == .inactive
        let defaults = UserDefaults.standard
        if inBackground {
            return defaults.integer(forKey: Constants.kRPMUserDefaultKeyFingerprintUploadRateBackground)
        }else {
            return defaults.integer(forKey: Constants.kRPMUserDefaultKeyFingerprintUploadRateForeground)
        }
    }
    
    func setDefaultUploadRates() {
        
        let defaults = UserDefaults.standard
        defaults.register(defaults: [Constants.kRPMUserDefaultKeyFingerprintUploadRateForeground: NSNumber(value: kDefaultNumberOfFingerprintsRequiredForUploadInForeground), Constants.kRPMUserDefaultKeyFingerprintUploadRateBackground: kDefaultNumberOfFingerprintsRequiredForUploadInBackground])
        defaults.synchronize()
    }
    
    class func isValidFingerprintUploadRate(fingerprintsPerUpload: Int) -> Bool {
        
        if fingerprintsPerUpload < 32 {
            return false
        }
        if fingerprintsPerUpload % 32 != 0 {
            return false
        }
        return true
    }

    // MARK: Managing storage object
    // MARK: RPMAudioCompressorDelegate
    func newFingerprintReady(fingerprintData: Data, fingerprintNumber: Int, filterNumber: Int, stats: RPMSilenceDetectionStats) {
        
        var numberOfFingerprintsInStorageInstance = 0
        storageLock.lock()
        var i: Int = 0
        if storages != nil && filterNumber < storages!.count {
            for compressor in compressors {
                if compressor.filterNumber == filterNumber {
                    let store = storages![i]
                    store!.newFingerprintReady(fingerprintData, fingerprintNumber: fingerprintNumber)
                    numberOfFingerprintsInStorageInstance = store!.numberOfFingerprintsStored
                }
                
                i = i + 1
            }
        }
        
        storageLock.unlock()
        self.silenceDetector.stats = stats
        if numberOfFingerprintsInStorageInstance >= kNumberOfFingerprintsPerFile {
            self.startNextStorageBlock(currentFiltNum: filterNumber)
        }
    }
    
    func start(currentFiltNum: Int) {
        
        if !running {
            self.silenceDetector.reset()
            storageLock.lock()
            
            if (storages?.count == 0) {
                storages?.append(RPMAudioStorage(filterNumber: Int(LOW_RATE_FILTER)))
                // FIXME only needed if we're using high rate
                storages?.append(RPMAudioStorage(filterNumber: Int(HIGH_RATE_FILTER)))
            }
            
            for storage in storages! {
                if currentFiltNum == BOTH_FILTERS || currentFiltNum == storage!.filterNumber {
                    storage!.resetStorage()
                }
            }
            
            storageLock.unlock()
            running = true
        }
    }
    
    func stop(currentFiltNum: Int) {
        
        if running {
            storageLock.lock()
            let silenceDetected = self.currentBatchIsSilence()
            
            for storage in storages! {
                if storage!.filterNumber == currentFiltNum || currentFiltNum == BOTH_FILTERS {
                    storage!.stopWhileSavingChanges(silenceDetected: !silenceDetected)
                }
            }
            storageLock.unlock()
            
            for compressor in compressors {
                if currentFiltNum == BOTH_FILTERS || compressor.filterNumber == currentFiltNum {
                    compressor.startNewFingerprintBatch()
                }
            }
            running = false
        }
    }
                            
    func pauseHighRateFilter() {
        
        for compressor in compressors {
            if compressor.filterNumber == HIGH_RATE_FILTER {
                compressor.stop()
            }
        }
        
        storageLock.lock()
        for storage in storages! {
            if storage!.filterNumber == HIGH_RATE_FILTER {
                storage!.resetStorage()
            }
        }
        storageLock.unlock()
    }
    
    func resumeHighRateFilter() {
        
        storageLock.lock()
        for storage in storages! {
            if storage!.filterNumber == HIGH_RATE_FILTER {
                storage!.resetStorage()
            }
        }
        storageLock.unlock()
        
        for compressor in compressors {
            if compressor.filterNumber == HIGH_RATE_FILTER {
                compressor.restart()
            }
        }
    }
    
    func currentBatchIsSilence() -> Bool {
        return self.silenceDetector.statsIndicateSilence()
    }
}

//extension RPMAudioUploader: NSURLConnectionDelegate {
//
//    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
//
//        print("upload failed \(error.localizedDescription)")
//        print("we were trying to connect to \(String(describing: connection.currentRequest.url))")
//    }
//}
