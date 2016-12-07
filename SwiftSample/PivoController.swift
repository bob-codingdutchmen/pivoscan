//
//  PivoController.swift
//  SwiftSample
//
//  Created by Bob Vork on 20/02/16.
//  Copyright © 2016 Scandit AG. All rights reserved.
//

import Foundation
import Alamofire
import KeychainSwift


protocol PivoDelegate {
    func scannedStory(_ story: Story)
    func gotUser(_ userId: Int, name: String)
}

enum StoryType {
    case bug, chore, release, story
}

class Story: Equatable {
    var id: Int?
    var estimate: Int = -1
    var name: String?
    var state: String?
    var url: String?
    var project_id: Int?
    var story_type: StoryType = .story
    var labels = [String]()
    
    init(id: Int) {
        self.id = id
    }
    
    init(id: Int, estimate: Int, name: String) {
        self.id = id
        self.estimate = estimate
        self.name = name
    }
    
    init(dict: AnyObject) {
        self.id = dict["id"] as? Int
        self.name = dict["name"] as? String
        self.state = dict["current_state"] as? String
        self.url = dict["url"] as? String
        self.project_id = dict["project_id"] as? Int
        
        let kind: String = dict["story_type"] as! String
        switch kind {
        case "story":
            self.story_type = .story
        case "release":
            self.story_type = .release
        case "bug":
            self.story_type = .bug
        case "chore":
            self.story_type = .chore
        default:
            self.story_type = .story
        }
        
        if self.story_type == .story || self.story_type == .bug {
            let estimate = dict["estimate"]
            if (estimate! != nil) {
                self.estimate = dict["estimate"] as! Int
            } else {
                self.estimate = -1
            }
        }
        
        // Labels
        for labelDict in dict["labels"] as! NSArray {
            self.labels += [(labelDict as! NSDictionary)["name"] as! String]
        }
    }
    

}

func ==(lhs:Story, rhs:Story) -> Bool { // Implement Equatable
    return lhs.id == rhs.id
}

class Project {
    var id: Int
    var point_scale: String
    var name: String
    
    init(id: Int, name: String, point_scale: String) {
        self.id = id
        self.name = name
        self.point_scale = point_scale
    }
}

class PivoController {
    var token: String?
    var delegate: PivoDelegate?
    var projects: [Int: Project]?
    
    init(token: String) {
        self.token = token
        self.projects = [Int: Project]()
    }

    
    func setup() {
        let headers = [
            "X-TrackerToken": token!
        ]
        
        Alamofire.request("https://www.pivotaltracker.com/services/v5/me", headers: headers)
            .responseJSON { response in
                
                
                if let JSON = response.result.value {
                    
                    guard let tResult = JSON as? [String:Any]  else {
                        return
                    }
                    
                    let userId = tResult["id"] as! NSNumber
                    let name = tResult["name"] as! String
                
                    
                    let keychain = KeychainSwift()
                    
                    keychain.set(String(format: "%d", userId), forKey: "userid")
                    keychain.set(name, forKey: "username")
                    
                    self.delegate?.gotUser(userId.intValue, name: name)
                    
                    for projectDict in tResult["projects"] as! NSArray {
                        
                        guard let projectDictionary = projectDict as? [String:Any]  else {
                            return
                        }
                        let proj_name = projectDictionary["project_name"] as! String
                        let proj_id = projectDictionary["project_id"] as! Int
                        
                        let url = String(format:"https://www.pivotaltracker.com/services/v5/projects/%d", proj_id)
                        Alamofire.request(url, headers: headers)
                            .responseJSON { response in
                                if let PROJ = response.result.value {
                                    
                                    guard let pDict = PROJ as? [String:Any]  else {
                                        return
                                    }
                                    self.projects![proj_id] = Project(
                                        id: proj_id,
                                        name: proj_name,
                                        point_scale: pDict["point_scale"] as! String
                                    )
                                }
                        }
                    }
                    
                }
        }
    }
    
    func project_with_id(_ project_id: Int) -> Project {
        return self.projects![project_id]!
    }
    
    func get_story_with_id(_ id: Int) {
        let headers = [
            "X-TrackerToken": token!
        ]
        let url = String(
            format: "https://www.pivotaltracker.com/services/v5/stories/%d", id)
        Alamofire.request(url, headers: headers)
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    guard let resultDict = JSON as? NSDictionary else {
                        return
                    }
                    let story = Story(dict:resultDict)
                    self.delegate?.scannedStory(story)
                }
        }
    }
    
    func get_current_user() {
        let headers = [
            "X-TrackerToken": token!
        ]
        let url = "https://www.pivotaltracker.com/services/v5/me"
        Alamofire.request(url, headers: headers)
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    guard let resultDict = JSON as? [String:Any] else {
                        return
                    }
                    let userId = resultDict["id"] as! Int
                    let name = resultDict["name"] as! String
                    self.delegate?.gotUser(userId, name: name)
                }
        }
        
    }
    
    func set_story_estimate(_ id: Int, estimate: Int) {
        
        let headers = [
            "X-TrackerToken": token!
        ]
        var realEstimate: AnyObject = estimate as AnyObject
        if estimate == -1 {
            realEstimate = NSNull()
        }
        let url = String(format: "https://www.pivotaltracker.com/services/v5/stories/%d", id)
        let parameters = [
            "estimate": realEstimate
        ]
        
        Alamofire.request(url,
                          method: .put,
                          parameters: parameters,
                          encoding: JSONEncoding.default,
                          headers: headers)
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    guard let resultDict = JSON as? NSDictionary else {
                        return
                    }
                    let story = Story(dict:resultDict)
                    self.delegate?.scannedStory(story)
                }
        }
    }
    
    func set_story_state(_ id: Int, state: String, user: Int?) {
        
        let headers = [
            "X-TrackerToken": token!
        ]
        let url = String(format: "https://www.pivotaltracker.com/services/v5/stories/%d", id)
        let parameters = [
            "current_state": state
        ]
        
        Alamofire.request(url,
                          method: .put,
                          parameters: parameters,
                          encoding: JSONEncoding.default,
                          headers: headers)
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    guard let resultDict = JSON as? NSDictionary else {
                        return
                    }
                    print("Status code: ", resultDict["http_status"] ?? "-")
                    if resultDict["http_status"] as? String ?? "200" == "500" {
                        return
                    }
                    let story = Story(dict:resultDict)
                    self.delegate?.scannedStory(story)
                    
//                    Set owner if we started this story:
                    if (user != nil) && state == "started" {
                        let ownerParams = [
                            "id": user!
                        ]
                        guard let jsonDict = JSON as? NSDictionary else {
                            return
                        }
                        let ownerUrl = String(format: "https://www.pivotaltracker.com/services/v5/projects/%d/stories/%d/owners", jsonDict["project_id"] as! Int, id)
                        Alamofire.request(ownerUrl, method: .post, parameters: ownerParams, encoding: JSONEncoding.default, headers: headers)
                    }
                }
        }
    }
    
}
