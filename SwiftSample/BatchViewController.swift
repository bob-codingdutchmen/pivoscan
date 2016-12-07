//
//  BatchViewController.swift
//  SwiftSample
//
//  Created by Bob Vork on 07/12/2016.
//  Copyright © 2016 Scandit AG. All rights reserved.
//

import UIKit
import BarCodeReaderView
import KeychainSwift


class BatchViewController: UIViewController, PivoDelegate, BarcodeReaderViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var camView: BarcodeReaderView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var storiesTableView: UITableView!
    
    var pivo : PivoController?
    var userId : Int?
    
    var scannedStories = [String()]
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.camView.delegate = self
        self.camView.barCodeTypes = [.Code128, .QR]
        self.camView.startCapturing()
        self.enableScan(true)
        
        self.camView.translatesAutoresizingMaskIntoConstraints = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        let pivokey = KeychainSwift().get("pivotalapikey")
        
        if (pivokey != nil) {
            initializeAPIWithKey(pivokey!)
        } else {
            self.performSegueWithIdentifier("setup", sender: self)
        }
    }
    
    // // // // // // // // // // // // // // // //
    
    func initializeAPIWithKey(key: String) {
        
        self.pivo = PivoController(token: key)
        self.pivo!.delegate = self
        self.pivo!.setup()
    }
    
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        self.camView.stopCapturing()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: PivoDelegate
    func gotUser(userId: Int, name: String) {
        //        self.userLabel.text = name
        self.userId = userId
    }
    
    func scannedStory(story: Story) {
//        self.spinner.stopAnimating()
//        storyNameView.text = story.name
//        self.current_story = story
//        
//        self.idLabel.text = String(format:"#%d", story.id!)
//        self.stateLabel.text = story.state?.capitalizedString
//        if story.estimate == -1 {
//            self.pointsLabel.text = "-"
//        } else {
//            self.pointsLabel.text = String(format:"%d", story.estimate)
//        }
//        
//        self.userLabel.text = self.pivo!.project_with_id(story.project_id!).name
//        self.labelsLabel.text = story.labels.joinWithSeparator("\n")
    }
    
    // MARK: Barcode scanner thing
    
    func barcodeReader(barcodeReader: BarcodeReaderView, didFailReadingWithError error: NSError) {}
    
    func barcodeReader(barcodeReader: BarcodeReaderView, didFinishReadingString info: String) {
        //handle success reading
        
        if let scannedString:String = info {
            if scannedString.hasPrefix("#") {
                
                if let story_id:Int = Int(String(scannedString.characters.dropFirst())) {
                    if let pivo = self.pivo {
                        self.spinner.startAnimating()
                        pivo.get_story_with_id(story_id)
                        self.enableScan(false)
                    }
                }
            }
        }
    }
    
    func enableScan(enable: Bool) {
    
    }

    
    // MARK Tableview stuff
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scannedStories.count
    }
    
    func tableView(tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Getting the right element
        let story = scannedStories[indexPath.row]
        
        // Instantiate a cell
        let cellIdentifier = "Storycell"
//        dequeueReusableCellWithIdentifier(identifier: String) -> UITableViewCell?
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        
        // Adding the right informations
        cell.textLabel?.text = story
        cell.detailTextLabel?.text = "test"
        
        // Returning the cell
        return cell
    }
    
    
}
