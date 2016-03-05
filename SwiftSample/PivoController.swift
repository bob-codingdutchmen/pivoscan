//
//  PivoController.swift
//  SwiftSample
//
//  Created by Bob Vork on 20/02/16.
//  Copyright © 2016 Scandit AG. All rights reserved.
//

import Foundation
import Alamofire


protocol PivoDelegate {
    func scannedStory(story: Story)
    func gotUser(userId: Int, name: String)
}

enum StoryType {
    case Bug, Chore, Release, Story
}

class Story {
    var id: Int?
    var estimate: Int = -1
    var name: String?
    var state: String?
    var url: String?
    var story_type: StoryType = .Story
    var labels = [String]()
    
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
        
        let kind: String = dict["story_type"] as! String
        switch kind {
        case "story":
            self.story_type = .Story
        case "release":
            self.story_type = .Release
        case "bug":
            self.story_type = .Bug
        case "chore":
            self.story_type = .Chore
        default:
            self.story_type = .Story
        }
        
        if self.story_type == .Story || self.story_type == .Bug {
            let estimate = dict["estimate"]
            if (estimate! != nil) {
                self.estimate = dict["estimate"] as! Int
            } else {
                self.estimate = -1
            }
        }
        
        // Labels
        for labelDict in dict["labels"] as! NSArray {
            self.labels += [labelDict["name"] as! String]
        }
    }
}

class PivoController {
    var token: String?
    var delegate: PivoDelegate?
    
    init(token: String) {
        self.token = token
    }
    
    func get_story_with_id(id: Int) {
        let headers = [
            "X-TrackerToken": token!
        ]
        let url = String(
            format: "https://www.pivotaltracker.com/services/v5/stories/%d", id)
        Alamofire.request(.GET, url, headers: headers)
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    let story = Story(dict:JSON)
                    self.delegate?.scannedStory(story)
                }
            }
    }
    
    func get_current_user() {
        let headers = [
            "X-TrackerToken": token!
        ]
        let url = String("https://www.pivotaltracker.com/services/v5/me")
        Alamofire.request(.GET, url, headers: headers)
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    let userId = JSON["id"] as! Int
                    let name = JSON["name"] as! String
                    self.delegate?.gotUser(userId, name: name)
                }
        }
        
    }
    
    func set_story_estimate(id: Int, estimate: Int) {
        
        let headers = [
            "X-TrackerToken": token!
        ]
        var realEstimate: AnyObject = estimate
        if estimate == -1 {
            realEstimate = NSNull()
        }
        let url = String(format: "https://www.pivotaltracker.com/services/v5/stories/%d", id)
        let parameters = [
            "estimate": realEstimate
        ]
        
        Alamofire.request(.PUT, url, headers: headers, parameters: parameters, encoding: .JSON)
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    let story = Story(dict:JSON)
                    self.delegate?.scannedStory(story)
                }
        }
    }
    
    func set_story_state(id: Int, state: String, user: Int?) {
        
        let headers = [
            "X-TrackerToken": token!
        ]
        let url = String(format: "https://www.pivotaltracker.com/services/v5/stories/%d", id)
        let parameters = [
            "current_state": state
        ]
        
        Alamofire.request(.PUT, url, headers: headers, parameters: parameters, encoding: .JSON)
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    let story = Story(dict:JSON)
                    self.delegate?.scannedStory(story)
                    
//                    Set owner if we started this story:
                    if (user != nil) && state == "started" {
                        let ownerParams = [
                            "id": user!
                        ]
                        let ownerUrl = String(format: "https://www.pivotaltracker.com/services/v5/projects/%d/stories/%d/owners", JSON["project_id"] as! Int, id)
                        Alamofire.request(.POST, ownerUrl, headers: headers, parameters: ownerParams, encoding: .JSON)
                    }
                }
        }
    }
    
}