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

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension String {
    func stripHTML() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
    
    func dateFormatFromTZ() -> String {
        let dtFormatter = DateFormatter()
        dtFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dtFormatter.date(from: self)
        dtFormatter.dateFormat = "MM.dd.yyyy hh:mm"
        return dtFormatter.string(from: date!)
    }
}

extension UILabel {
    func requiredHeight() -> CGFloat {
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = self.font
        label.text = self.text
        label.sizeToFit()
        return label.frame.height
    }
}

class Shot: Object {
    dynamic var author: String = ""
    dynamic var title: String = ""
    dynamic var desc: String = ""
    dynamic var imgUrl: String = ""
    dynamic var shotId: Int = 0
    dynamic var username: String = ""
    
    override static func primaryKey() -> String? {
        return "shotId"
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
    var CompleteLoadShots:((JSON) -> Void)?
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
    
    func getUserInfo(username: String, completion: @escaping ([String: AnyObject]?) -> ()) {
        let auth_header = [ "Authorization": "Bearer " + self.OAuthToken! ]
        let reqURL: String = self.apiURL + "/users/" + username
        Alamofire.request(reqURL, headers: auth_header)
            .responseJSON{response in
                if let result = response.result.value {
                    let JSON = result as! [String: AnyObject]
                    completion(JSON)
                }
        }
    }
    
    func getUserLikes(username: String, completion: @escaping (JSON) -> ()) {
        let auth_header = [ "Authorization": "Bearer " + self.OAuthToken! ]
        let reqURL: String = self.apiURL + "/users/" + username + "/likes?per_page=50"
        Alamofire.request(reqURL, headers: auth_header)
            .responseJSON{response in
                if let result = response.result.value {
                    let json = JSON(result)
                    completion(json)
                }
        }
    }
    
    func getUserFollowers(username: String, completion: @escaping (JSON) -> ()) {
        let auth_header = [ "Authorization": "Bearer " + self.OAuthToken! ]
        let reqURL: String = self.apiURL + "/users/" + username + "/followers?per_page=50"
        Alamofire.request(reqURL, headers: auth_header)
            .responseJSON{response in
                if let result = response.result.value {
                    let json = JSON(result)
                    completion(json)
                }
        }
    }
    
    func getRecentShots() {
        if self.OAuthToken == nil {
            let realm = try! Realm()
            let login = realm.objects(LogInfo.self)
            self.OAuthToken = login.last?.token
        }
        let auth_header = [ "Authorization": "Bearer " + self.OAuthToken! ]
        let reqURL: String = self.apiURL + "/shots?per_page=25"
        let params: Parameters = [
            "list": "shots",
            "sort": "recent"
        ]
        Alamofire.request(reqURL, parameters: params, headers: auth_header)
            .responseJSON{response in
                if let result = response.result.value {
                    let json = JSON(result)
                    if let completionHandler = self.CompleteLoadShots {
                        completionHandler(json)
                    }
                }
        }
    }
    
    func getShotComments(shotId: Int, completion: @escaping (NSArray?) -> ()) {
        let auth_header = [ "Authorization": "Bearer " + self.OAuthToken! ]
        let reqURL: String = self.apiURL + "/shots/" + String(shotId) + "/comments?per_page=50"
        Alamofire.request(reqURL, headers: auth_header)
            .responseJSON{response in
                if let result = response.result.value {
                    let JSON = result as? NSArray
                    completion(JSON)
//                    }
                }
        }
    }
    
    func sendComment(shotId: Int, text: String, completion: @escaping (NSDictionary?) -> ()) {
        let auth_header = [ "Authorization": "Bearer " + self.OAuthToken! ]
        let reqURL: String = self.apiURL + "/shots/" + String(shotId) + "/comments"
        let params: Parameters = [
            "body": text
        ]
        Alamofire.request(reqURL, method: .post, parameters: params, headers: auth_header)
            .responseString{response in
                print(response)
//                if let result = response.result.value {
//                    let JSON = result as? NSDictionary
//                    completion(JSON)
//                }
        }
    }
    
    func setShotLike(shotId: Int, completion: @escaping (String) -> ()) {
        let auth_header = [ "Authorization": "Bearer " + self.OAuthToken! ]
        let reqURL: String = self.apiURL + "/shots/" + String(shotId) + "/like"
        Alamofire.request(reqURL, method: .post, headers: auth_header)
            .responseString{response in
                if let result = response.result.value {
//                    let json = JSON(result)
                    completion(result)
                }
        }
    }
    
}
