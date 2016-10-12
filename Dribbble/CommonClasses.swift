//
//  CommonClasses.swift
//  Dribbble
//
//  Created by Александр Кожарский on 29.09.16.
//  Copyright © 2016 kozharsky. All rights reserved.
//

import Foundation
import RealmSwift
import Alamofire
import SwiftyJSON
import UIKit

extension String {
    func stripHTML() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}

class LogInfo: Object {
    dynamic var token: String = ""
    dynamic var type: String = ""
}

class DribbApiManager {
    static let inst = DribbApiManager()
    let apiURL:String = "https://api.dribbble.com/v1"
    
    var OAuthToken:String?
    var OAuthTokenCompletionHandler:((NSError?) -> Void)?
    var Complete:((NSDictionary?) -> Void)?
    var CompleteLoadShots:((NSArray?) -> Void)?
    var CompleteLoadComments:((NSArray?) -> Void)?
    
    func processStep1auth(url: NSURL) {
        let components = NSURLComponents(url: url as URL, resolvingAgainstBaseURL: false)
        var code:String?
        if let queryItems = components?.queryItems {
            for queryItem in queryItems {
                if (queryItem.name.lowercased() == "code") {
                    code = queryItem.value
                    break
                }
            }
        }
        
        if let receivedCode = code {
            let tokPath:String = "https://dribbble.com/oauth/token"
            let params: Parameters = [
                "client_id": "48a0f2d306113b97824df1b199253c2e622263ca9f5a20d8df8b7f47c9ed236b",
                "client_secret": "bae83b7bc6c3eac857b852730b4327a0d7f1010c58821646b18ec7cc91af0f0d",
                "code": receivedCode
            ]
            Alamofire.request(tokPath, method: .post, parameters: params)
                .responseJSON{response in
                    if let result = response.result.value {
                        // Сериализуем JSON-ответ как словарь
                        let JSON = result as! NSDictionary
                        self.OAuthToken = JSON["access_token"] as? String
                        if self.hasToken() {
                            if let completionHandler = self.OAuthTokenCompletionHandler {
                                let info = LogInfo()
                                info.token = self.OAuthToken!
                                info.type = "access_token"
                                
                                let realm = try! Realm()
                                let objs = realm.objects(LogInfo.self).filter("type = 'access_token'")
                                if objs.count > 0 {
                                    try! realm.write {
                                        realm.delete(objs)
                                    }
                                }
                                try! realm.write {
                                    realm.add(info)
                                }
                                completionHandler(nil)
                            }
                        } else {
                            print("TOKEN FAIL")
                        }
                    }
                }
        }
    }

    func hasToken() -> Bool {
        if let token = self.OAuthToken {
            return !token.isEmpty
        }
        return false
    }
    
    func getUserInfo(username: String) {
        let auth_header = [ "Authorization": "Bearer " + self.OAuthToken! ]
        let reqURL: String = self.apiURL + "/users/" + username
        Alamofire.request(reqURL, headers: auth_header)
            .responseJSON{response in
                if let result = response.result.value {
                    let JSON = result as! NSDictionary
                    if let completionHandler = self.Complete {
                        completionHandler(JSON)
                    }
                }
        }
    }
    
    func getRecentShots() {
        let auth_header = [ "Authorization": "Bearer " + self.OAuthToken! ]
        let reqURL: String = self.apiURL + "/shots?list=attachments&sort=recent"
        Alamofire.request(reqURL, headers: auth_header)
            .responseJSON{response in
                if let result = response.result.value {
                    let JSON = result as! NSArray
                    if let completionHandler = self.CompleteLoadShots {
                        completionHandler(JSON)
                    }
                }
        }
    }
    
    func getShotComments(shotId: Int, completion: @escaping (NSArray?) -> ()) {
        let auth_header = [ "Authorization": "Bearer " + self.OAuthToken! ]
        let reqURL: String = self.apiURL + "/shots/" + String(shotId) + "/comments"
        Alamofire.request(reqURL, headers: auth_header)
            .responseJSON{response in
                if let result = response.result.value {
                    let JSON = result as? NSArray
//                    if let completionHandler = self.CompleteLoadComments {
                    completion(JSON)
//                    }
                }
        }
    }
}