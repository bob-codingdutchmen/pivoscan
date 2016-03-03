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


let kScanditBarcodeScannerAppKey = "GIEGzinOn+WlzV4rVcY/bPQbV92kGmLCMEbqDK1p/2o";

class ViewController: UIViewController, PivoDelegate, SBSScanDelegate, UIAlertViewDelegate {

    @IBOutlet weak var camView: UIView!
    
    @IBOutlet weak var storyNameView: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    
    @IBOutlet var estimateButtons: [UIButton]!
    
    @IBOutlet weak var idLabel: UILabel!

    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var labelsLabel: UILabel!
    @IBOutlet weak var overlayButton: UIButton!
    
    var picker : SBSBarcodePicker?
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
        picker?.startScanning()
        overlayButton.hidden = true
    }
    
    @IBAction func estimateButtonPressed(sender: UIButton) {
        
//       Get estimate from button
        if let estimate: Int = Int((sender.titleLabel?.text)!) {
            if let story: Story = self.current_story {
                if let pivo = self.pivo {
                    pivo.set_story_estimate(story.id!, estimate: estimate)
                }
            }
        }
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
    
    
    func barcodePicker(picker: SBSBarcodePicker, didScan session: SBSScanSession) {
        
        session.stopScanning();
        
        let code = session.newlyRecognizedCodes[0] as! SBSCode;
        
        dispatch_async(dispatch_get_main_queue()) {
            var continueScanning = true;
            
            if let scannedString:String = code.data! {
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
                picker.startScanning()
            }
            
        };
    }
    
    @IBAction func openStoryButtonPressed(sender: AnyObject) {
        if let story: Story = self.current_story {
            UIApplication.sharedApplication().openURL(NSURL(string: story.url!)!)
        }
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        picker?.startScanning();
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
        
        
        

        SBSLicense.setAppKey(kScanditBarcodeScannerAppKey);
        
        let settings = SBSScanSettings.pre47DefaultSettings();

        settings.setActiveScanningArea(CGRect(x: 0.25, y: 0.3, width: 0.5, height: 0.4))
        settings.restrictedAreaScanningEnabled = true
        
        let thePicker = SBSBarcodePicker(settings:settings);
        
        thePicker.overlayController.setViewfinderColor(0.5, green:0.5, blue: 0.5)
        thePicker.overlayController.setViewfinderHeight(0.2, width: 0.5, landscapeHeight: 0.5, landscapeWidth: 0.5)
        thePicker.overlayController.setViewfinderDecodedColor(0.2, green: 1.0, blue: 0.2)

        
        thePicker.allowedInterfaceOrientations = UIInterfaceOrientationMask.Portrait;
        
        thePicker.scanDelegate = self;
        thePicker.startScanning();
        
        picker = thePicker;
        let pickerView = picker!.view
        self.camView.addSubview(pickerView)
        self.camView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        
        self.camView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            "H:|[picker]|",
            options: NSLayoutFormatOptions.DirectionLeftToRight,
            metrics: nil,
            views: ["picker": pickerView]
            ) )
        self.camView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
            "V:|[picker]|",
            options: NSLayoutFormatOptions.DirectionLeftToRight,
            metrics: nil,
            views: ["picker": pickerView]
            ) )
        self.overlayButton.hidden = true
    }

}

