//
//  RPMSocialClient.swift
//  Audio
//
//  Created by Talent on 05.02.2020.
//  Copyright © 2020 Audio. All rights reserved.
//

import Foundation
import AFNetworking

class RPMSocialClient: AFHTTPClient {
    
    static var shared = RPMSocialClient(baseURL: URL(string: Constants.baseStagingURL))
        
    func requestWithMethod(method: String, path: String, params: [String: Any], completion: @escaping (_ response: Any?, _ error: Error?) -> ()) {
        
        
        if method == "GET" || method == "PUT" {
            self.cancelAllHTTPOperations(withMethod: method, path: path)
        }
                
        let request: URLRequest = self.request(withMethod: method, path: path, parameters: params) as URLRequest
        
        let operation: AFJSONRequestOperation = AFJSONRequestOperation.init(request: request, success: { (request: URLRequest?, response: HTTPURLResponse?, JSON: Any?) in
            
            print("response data is \(String(describing: JSON))")
            
            completion(JSON, nil)
            
            
        }, failure: { (request: URLRequest?, response: HTTPURLResponse?, error: Error?, id: Any?) in
            
            print("error message is \(String(describing: error?.localizedDescription))")
            
            completion(nil, error)
            
        })
        
        self.enqueue(operation)
        
    }
    
    func isOffline() -> Bool {
        if Reachabilities.isConnectedToNetwork(){
            print("Internet Connection Available!")
            return false
        }else{
            print("Internet Connection not Available!")
            return true
        }
    }
}
