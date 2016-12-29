//
//  BatchViewController.swift
//  SwiftSample
//
//  Created by Bob Vork on 07/12/2016.
//  Copyright © 2016 Scandit AG. All rights reserved.
//

import UIKit
import MTBBarcodeScanner
import KeychainSwift
import AudioToolbox


class BatchViewController: UIViewController, PivoDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var camView:UIView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var storiesTableView: UITableView!
    
    @IBOutlet weak var label: UILabel!
    var pivo : PivoController?
    var userId : Int?
    
    var scanner: MTBBarcodeScanner?
    
    
    var scannedStories: [Story] = []
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scanner = MTBBarcodeScanner(previewView: camView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let pivokey = KeychainSwift().get("pivotalapikey")
        
        if (pivokey != nil) {
            initializeAPIWithKey(pivokey!)
        } else {
            self.performSegue(withIdentifier: "setup", sender: self)
        }
        self.startScanner()
    }
    
    // // // // // // // // // // // // // // // //
    
    func initializeAPIWithKey(_ key: String) {
        
        self.pivo = PivoController(token: key)
        self.pivo!.delegate = self
        self.pivo!.setup()
    }
    
    
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: PivoDelegate
    func gotUser(_ userId: Int, name: String) {
        //        self.userLabel.text = name
        self.userId = userId
    }
    
    func scannedStory(_ story: Story) {
        if let i = self.scannedStories.index(of: story) {
            self.scannedStories[i] = story
            self.storiesTableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .fade)
            
            // Set stories to planned if not already started / finished / etc
            if story.state == "unscheduled" || story.state == "unstarted" {
                if let pivo = self.pivo {
                    pivo.set_story_state(story.id!, state: "planned", user: self.userId)
                    self.ding(sound: "Collect_Point_01")
                }
            }
            
        }

    }
    
    
    func startScanner() {
        self.scanner?.startScanning(resultBlock: { codes in
            let codeObjects = codes as! [AVMetadataMachineReadableCodeObject]?
            for code in codeObjects! {
                
                if code.stringValue.hasPrefix("#") {
                    

                    if let story_id:Int = Int(String(code.stringValue.characters.dropFirst())) {
                        let newStory = Story(id: story_id)
                        if self.scannedStories.contains(newStory) {
                            return
                        }
                        
                        self.storiesTableView.beginUpdates()
                        let stringValue = code.stringValue!
                        
                        self.scannedStories.insert(newStory, at: 0)
                        print("Found code: \(stringValue)")
                        
                        self.ding(sound: "ding")
                        self.label.text = String(format: "%d stories", self.scannedStories.count)
                        
                        self.storiesTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                        self.storiesTableView.endUpdates()
                        if let pivo = self.pivo {
                            pivo.get_story_with_id(story_id)
                            
                        }
                    }
                }
            }
            
        }, error: nil)
    }
    
    
    func ding(sound: String) {
        
        if let soundURL = Bundle.main.url(forResource: sound, withExtension: "wav") {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as URL as CFURL, &mySound)
            // Play
            AudioServicesPlaySystemSound(mySound);
        }
    }
   
    
    
    // MARK Tableview stuff
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scannedStories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Getting the right element
        let story = scannedStories[indexPath.row]
        
        // Instantiate a cell
        let cellIdentifier = "Storycell"

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        
        // Adding the right informations
        var title = String(format: "#%d ", story.id!)
        if let state = story.state {
            title.append(state)
        }
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = story.name
        
        // Returning the cell
        return cell
    }
    
    
}
