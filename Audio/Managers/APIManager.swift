//
//  APIManager.swift
//  Audio
//
//  Created by TeamPlayer on 1/16/20.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import AFNetworking
import SwiftTryCatch

class APIManager {
    static let shared = APIManager()
    
    var fingerprintRatesFetched: Bool = false

    init() {}
               
    // MARK: Send Post Request with params
    func doRequestWithParams_Post(request_URL: String, params: [String: Any], completion: @escaping (_ success: Bool, _ response: JSON?, _ errormsg: String?) -> ()) {
        
        Alamofire.request(request_URL, method:.post, parameters:params).responseJSON { response in

            switch response.result {

            case .failure(let error):
                
                let message = error.localizedDescription
                
                completion(false, nil, message)

            case .success(let data):

                let dict = JSON(data)
                print(dict)
                
                completion(true, dict, nil)

            }
        }
    }
    
    // MARK: Send request with params using AFNetowking(any type is available - get, post, put...)
    func doRequestWithParams_AFNetworking(request_URL: String, method: String, params: [String: Any], completion: @escaping (_ response: JSON?, _ error: Error?) -> ()) {
     
        RPMSocialClient.shared?.requestWithMethod(method: method, path: request_URL, params: params) { (response, error) in
            
            if let error = error {
                
                print(error.localizedDescription)
                completion(nil, error)
                
                return
            }
            
            if let response = response {
                
                let dict = JSON(response)
                
                completion(dict, nil)
                
                return
            }
            
        }
    }
    
    // MARK: Send get request
    func doRequestWithParams_Get(request_URL: String, params: [String: Any], completion: @escaping ( _ response: JSON?, _ errormsg: Error?) -> ()) {
        
        Alamofire.request(request_URL, parameters: params).responseJSON { response in
            
            switch response.result {

            case .failure(let error):
                
                let message = error.localizedDescription
                
                print("get error : \(message)")
                
                completion(nil, error)

            case .success(let data):

                let dict = JSON(data)
                
                completion(dict, nil)

            }
        }
       
    }
    
    func doRequestWithoutParams_Get(request_URL: String, completion: @escaping ( _ response: JSON?, _ error: Error?) -> ()) {
                        
        Alamofire.request(request_URL).responseJSON { response in
            
            switch response.result {

            case .failure(let error):
                
                let message = error.localizedDescription
                
                print("get error : \(message)")
                
                completion(nil, error)

            case .success(let data):

                let dict = JSON(data)
                
                completion(dict, nil)

            }
        }
    }
    
    // Look at the exception to determine what kind of data type it wants to be
    func findDesiredTypeIn(exceptionReason: String) -> String? {
        
        do {
            let regex = try NSRegularExpression(pattern: "desired type = (\\w+)", options: NSRegularExpression.Options.caseInsensitive)
            let results = regex.matches(in: exceptionReason, options: [], range: NSMakeRange(0, exceptionReason.count))
            
            for checkingResult: NSTextCheckingResult in results {
                
                let desiredType = exceptionReason.substring(with: exceptionReason.rangeFromNSRange(nsRange: checkingResult.range(at: 1))!)
                    
                
                return desiredType
            }
        } catch {
            print("Didn't get excpetion reason")
        }
        
        return nil
    }
    
    // Cast all errant strings into their appropriate data types
    func castValue(value: JSON, exceptionReason: String) -> Any? {
        
        let desiredType = self.findDesiredTypeIn(exceptionReason: exceptionReason)
        
        var newThing: Any?
        if desiredType == "NSNumber" {
            newThing = NSNumber(value: value.intValue)
        }else if desiredType == "NSDate" {
            let date = Date()
            newThing = date.dateFromInternetDateTimeString(dateString: value.stringValue, hint: DateFormatHint.DateFormatHintRFC3339)
        }else if desiredType == "NSDecimalNumber" {
            let userLocale = NSLocale(localeIdentifier: "en_US")
            newThing = NSDecimalNumber.init(string: value.stringValue, locale: userLocale)
        }else if desiredType == "NSString" {
            newThing = value.stringValue
        }else {
            print("Don't know about this data type \(exceptionReason)")
        }
        
        return newThing
    }
    
    func updateFingerprintRates() {
        
        if !fingerprintRatesFetched {
            
            let path = Constants.baseURL + Constants.fingerprintURL
            
            print(path)
            
            APIManager.shared.doRequestWithoutParams_Get(request_URL: path) { (response, error) in
                
                if self.fingerprintRatesFetched {
                    return
                }
            
                if let error = error {
                    
                    print(error.localizedDescription)
                    return
                }
                
                if let response = response {
                    
                    SwiftTryCatch.try({
                        
                        let defaults = UserDefaults.standard
                        
                        if response["fingerprintsPerUpload"].dictionary != nil {
                            if response["fingerprintsPerUpload"]["foreground"].number != nil {
                                let fgUpload = response["fingerprintsPerUpload"]["foreground"].number?.intValue
                                if RPMAudioUploader.isValidFingerprintUploadRate(fingerprintsPerUpload: fgUpload!) {
                                    
                                    defaults.set(fgUpload!, forKey: Constants.kRPMUserDefaultKeyFingerprintUploadRateForeground)
                                }
                            }
                            if response["fingerprintsPerUpload"]["background"].number != nil {
                                let bgUpload = response["fingerprintsPerUpload"]["background"].number?.intValue
                                
                                if RPMAudioUploader.isValidFingerprintUploadRate(fingerprintsPerUpload: bgUpload!) {
                                    defaults.set(bgUpload!, forKey: Constants.kRPMUserDefaultKeyFingerprintUploadRateBackground)
                                }
                            }
                        }
                        
                        if response["filters"].dictionary != nil {
                            defaults.set(response["filters"]["low"]["numSamples"].number?.intValue, forKey: Constants
                                .kRPMUserDefaultKeyLowRateNumSamples)
                            defaults.set(response["filters"]["low"]["fingerprintNumberIncrement"].number?.intValue, forKey: Constants.kRPMUserDefaultKeyLowRateFingerprintNumberIncrement)
                            defaults.set(response["filters"]["low"]["bufferPointerIncrement"].number?.intValue, forKey: Constants.kRPMUserDefaultKeyLowRateBufferPointerIncrement)
                            defaults.set(response["filters"]["background"]["low"]["numSamples"].number?.intValue, forKey: Constants.kRPMUserDefaultKeyBackgroundLowRateNumSamples)
                            defaults.set(response["filters"]["background"]["low"]["fingerprintNumberIncrement"].number?.intValue, forKey: Constants.kRPMUserDefaultKeyBackgroundLowRateFingerprintNumberIncrement)
                            defaults.set(response["filters"]["background"]["low"]["bufferPointerIncrement"].number?.intValue, forKey: Constants.kRPMUserDefaultKeyBackgroundLowRateBufferPointerIncrement)
                            defaults.set(response["filters"]["high"]["numSamples"].number?.intValue, forKey: Constants.kRPMUserDefaultKeyHighRateNumSamples)
                            defaults.set(response["filters"]["high"]["fingerprintNumberIncrement"].number?.intValue, forKey: Constants.kRPMUserDefaultKeyHighRateFingerprintNumberIncrement)
                            defaults.set(response["filters"]["high"]["bufferPointerIncrement"].number?.intValue, forKey: Constants.kRPMUserDefaultKeyHighRateBufferPointerIncrement)
                        }
                        
                        defaults.synchronize()
                        
                        }, catch: { (error) in
                            print("\(String(describing: error?.name))")
                        }, finally: {
                             // close resources
                            
                            print("Finally closed")
                    })
                }
                
                self.fingerprintRatesFetched = true
            }
        
        }
    }
}
