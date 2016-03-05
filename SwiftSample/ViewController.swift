//
// Copyright 2015 Scandit AG
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
// in compliance with the License. You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under the
// License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import KeychainSwift
import BarCodeReaderView


let kScanditBarcodeScannerAppKey = "GIEGzinOn+WlzV4rVcY/bPQbV92kGmLCMEbqDK1p/2o";

class ViewController: UIViewController, PivoDelegate, BarcodeReaderViewDelegate {

    @IBOutlet weak var camView: BarcodeReaderView!
    
    @IBOutlet weak var storyNameView: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    
    @IBOutlet var estimateButtons: [UIButton]!
    
    @IBOutlet weak var idLabel: UILabel!

    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var labelsLabel: UILabel!
    @IBOutlet weak var overlayButton: UIButton!
    
    var current_story : Story?
    var userId : Int?
    var pivo : PivoController?
    var keychain : KeychainSwift?

    
    let states = [
        ("unscheduled", "Unscheduled"),
        ("planned", "Planned"),
        ("started", "Started"),
        ("finished", "Finished"),
        ("delivered", "Delivered"),
        ("accepted", "Accepted"),
        ("rejected", "Rejected"),
    ]
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    @IBAction func overlayPressed(sender: AnyObject) {
        self.camView.startCapturing()
        overlayButton.hidden = true
    }
    
    @IBAction func estimateButtonPressed(sender: UIButton) {
        
////       Get estimate from button
//        if let estimate: Int = Int((sender.titleLabel?.text)!) {
//            if let story: Story = self.current_story {
//                if let pivo = self.pivo {
//                    pivo.set_story_estimate(story.id!, estimate: estimate)
//                }
//            }
//        }
        
        let actionSheetController: UIAlertController = UIAlertController(
            title: "Change estimate",
            message: nil,
            preferredStyle: .ActionSheet
        )
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        for num in [0, 1, 2, 3, 5, 8, 13, 20, 40, 100] {
            //Create and add first option action
            let title:String = String(format:"%d points", num)
            let stateAction: UIAlertAction = UIAlertAction(title: title, style: .Default) { action -> Void in
                if let story: Story = self.current_story {
                    if let pivo = self.pivo {
                        pivo.set_story_estimate(story.id!, estimate: num)
                    }
                }
            }
            actionSheetController.addAction(stateAction)
        }
        
        //Present the AlertController
        self.presentViewController(actionSheetController, animated: true, completion: nil)
        
    }
    
    @IBAction func stateButtonPressed(sender: AnyObject) {
        let actionSheetController: UIAlertController = UIAlertController(
            title: "Change state",
            message: nil,
            preferredStyle: .ActionSheet
        )
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            //Just dismiss the action sheet
        }
        actionSheetController.addAction(cancelAction)
        
        for state in states {
            //Create and add first option action
            let stateAction: UIAlertAction = UIAlertAction(title: state.1, style: .Default) { action -> Void in
                if let story: Story = self.current_story {
                    if let pivo = self.pivo {
                        pivo.set_story_state(story.id!, state: state.0, user: self.userId)
                    }
                }
            }
            actionSheetController.addAction(stateAction)
        }
        
        //Present the AlertController
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    func scannedStory(story: Story){
        
        storyNameView.text = story.name
        self.current_story = story
        
        self.idLabel.text = String(format:"#%d", story.id!)
        self.stateLabel.text = story.state?.capitalizedString
        if story.estimate == -1 {
            self.pointsLabel.text = "-"
        } else {
            self.pointsLabel.text = String(format:"%d", story.estimate)
        }
        
        overlayButton.hidden = false
        
        self.labelsLabel.text = story.labels.joinWithSeparator("\n")
    }
    
    func gotUser(userId: Int, name: String) {
        self.userLabel.text = name
        self.userId = userId
    }
    
    func barcodeReader(barcodeReader: BarcodeReaderView, didFailReadingWithError error: NSError) {
        // handle error
    }
    
    func barcodeReader(barcodeReader: BarcodeReaderView, didFinishReadingString info: String) {
        //handle success reading
        var continueScanning = true;
        self.camView.stopCapturing()
        
        if let scannedString:String = info {
            if scannedString.hasPrefix("#") {
                
                if let story_id:Int = Int(String(scannedString.characters.dropFirst())) {
                    if let pivo = self.pivo {
                        pivo.get_story_with_id(story_id)
                        continueScanning = false
                    }
                }
            } else if scannedString.characters.count == 32 {
                if self.pivo == nil {
                    debugPrint("setting pivo key")
                    
                    self.keychain!.set(scannedString, forKey: "pivotalapikey")
                    self.initializeAPIWithKey(scannedString)
                }
            }
        }
        
        if continueScanning {
            self.camView.startCapturing()
        }
    }
    
    
    @IBAction func openStoryButtonPressed(sender: AnyObject) {
        if let story: Story = self.current_story {
            let urlString: NSString = NSString(format: "pivotaltracker://s/%d", story.id!)
            UIApplication.sharedApplication().openURL(NSURL(string: urlString as String)!)
        }
    }
    
    func initializeAPIWithKey(key: String) {
        
        self.pivo = PivoController(token: key)
        self.pivo!.delegate = self
        self.pivo!.get_current_user()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.keychain = KeychainSwift()
                
        let pivokey = self.keychain!.get("pivotalapikey")
        
        if (pivokey != nil) {
            initializeAPIWithKey(pivokey!)
        }
        
        self.camView.delegate = self
        self.camView.barCodeTypes = [.Code128, .QR]
        self.camView.startCapturing()
        self.camView.translatesAutoresizingMaskIntoConstraints = false

        self.overlayButton.hidden = true
    }

}

