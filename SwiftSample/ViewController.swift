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

class ViewController: UIViewController, PivoDelegate, BarcodeReaderViewDelegate, EstimationDelegate {

    @IBOutlet weak var camView: BarcodeReaderView!
    
    @IBOutlet weak var storyNameView: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var cardView: UIView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet var estimateButtons: [UIButton]!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var idLabel: UILabel!

    @IBOutlet weak var pointsLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var labelsLabel: UILabel!
    @IBOutlet weak var overlayButton: UIButton!

    @IBOutlet var storyView: UIView!
    
    
    @IBOutlet weak var estimateCollectionView: UICollectionView!
    
    
    @IBOutlet weak var estimateConstraint: NSLayoutConstraint!
    var current_story : Story?
    var userId : Int?
    var pivo : PivoController?
    
    var estimateViewController: EstimationViewController?
    
    var scannedStories = [String]()
    
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
        self.enableScan(true)
    }
    
    func constraintsToMatchViews(view: UIView, matchToView: UIView) -> [NSLayoutConstraint] {
        return [
            NSLayoutConstraint(
                item: view,
                attribute: .Left,
                relatedBy: .Equal,
                toItem: matchToView,
                attribute: .Left,
                multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(
                item: view,
                attribute: .Right,
                relatedBy: .Equal,
                toItem: matchToView,
                attribute: .Right,
                multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(
                item: view,
                attribute: .Top,
                relatedBy: .Equal,
                toItem: matchToView,
                attribute: .Top,
                multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(
                item: view,
                attribute: .Bottom,
                relatedBy: .Equal,
                toItem: matchToView,
                attribute: .Bottom,
                multiplier: 1.0, constant: 0.0),
            ]
    }
    
    @IBAction func estimateButtonPressed(sender: UIButton) {
        
        
//        - Add estimation view to current view
//        - Animate to final position
        
        self.view.addSubview(self.estimateViewController!.view)
        self.estimateViewController!.view.translatesAutoresizingMaskIntoConstraints = false;
        
//      Tell estimate controller what points to show:
        
        let point_scale = self.pivo!.project_with_id(self.current_story!.project_id!).point_scale
        self.estimateViewController!.pointScale = point_scale.componentsSeparatedByString(",")
        
        self.estimateViewController!.view.alpha = 0.0
        
        let step1Constraints = self.constraintsToMatchViews(self.estimateViewController!.view, matchToView: self.pointsLabel)
        self.view.addConstraints(step1Constraints)
        self.view.layoutIfNeeded()
        
        UIView.animateWithDuration(
            0.3,
            delay: 0,
            usingSpringWithDamping: 0.96,
            initialSpringVelocity: 1.0,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: { () -> Void in
                self.view.removeConstraints(step1Constraints)
                self.estimateViewController!.view.alpha = 1.0
                self.view.addConstraints(self.constraintsToMatchViews(self.estimateViewController!.view, matchToView: self.storyView))
                self.view.layoutIfNeeded()
            },
            completion: nil)
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
                        self.spinner.startAnimating()
                        pivo.set_story_state(story.id!, state: state.0, user: self.userId)
                    }
                }
            }
            actionSheetController.addAction(stateAction)
        }
        
        //Present the AlertController
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    func scannedStory(story: Story) {
        self.spinner.stopAnimating()
        storyNameView.text = story.name
        self.current_story = story
        
        self.idLabel.text = String(format:"#%d", story.id!)
        self.stateLabel.text = story.state?.capitalizedString
        if story.estimate == -1 {
            self.pointsLabel.text = "-"
        } else {
            self.pointsLabel.text = String(format:"%d", story.estimate)
        }
        
        self.userLabel.text = self.pivo!.project_with_id(story.project_id!).name
        self.labelsLabel.text = story.labels.joinWithSeparator("\n")
    }
    
    func gotUser(userId: Int, name: String) {
//        self.userLabel.text = name
        self.userId = userId
    }
    
    func barcodeReader(barcodeReader: BarcodeReaderView, didFailReadingWithError error: NSError) {}
    
    func barcodeReader(barcodeReader: BarcodeReaderView, didFinishReadingString info: String) {
        //handle success reading
        
        if let scannedString:String = info {
            if scannedString.hasPrefix("#") {
                if self.scannedStories.contains(scannedString) {
                    return
                }
                if let story_id:Int = Int(String(scannedString.characters.dropFirst())) {
                    if let pivo = self.pivo {
                        self.scannedStories.append(scannedString)
                        self.spinner.startAnimating()
                        pivo.get_story_with_id(story_id)
                        //self.enableScan(false)
                    }
                }
            }
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
        self.pivo!.setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardView.layer.shadowColor = UIColor.blackColor().CGColor
        cardView.layer.shadowOpacity = 0.4
        cardView.layer.shadowOffset = CGSizeZero
        cardView.layer.shadowRadius = 30
        
        self.camView.delegate = self
        self.camView.barCodeTypes = [.Code128, .QR]
        self.camView.startCapturing()
        self.enableScan(true)
        
        self.camView.translatesAutoresizingMaskIntoConstraints = false
        
        self.estimateViewController = EstimationViewController(nibName: "EstimationViewController", bundle: nil)
        self.estimateViewController?.delegate = self

    }
    
    override func viewDidAppear(animated: Bool) {
        
        let pivokey = KeychainSwift().get("pivotalapikey")
        
        if (pivokey != nil) {
            initializeAPIWithKey(pivokey!)
        } else {
            self.performSegueWithIdentifier("setup", sender: self)
        }
    }
    
    func enableScan(enable: Bool) {
        let anim_duration = 0.4
        
        if enable {
            
            UIView.animateWithDuration(anim_duration, animations: { () -> Void in
                self.overlayButton.alpha = 0.0
                self.blurView.effect = nil
            })
            self.camView.startCapturing()
            
        } else {
            
            UIView.animateWithDuration(anim_duration, animations: { () -> Void in
                self.overlayButton.alpha = 1.0
                self.blurView.effect = UIBlurEffect(style: .Dark)
            })
            self.camView.stopCapturing()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "estimate" {
            segue.destinationViewController.view.backgroundColor = UIColor.clearColor()
            segue.sourceViewController.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        }
        
    }
    
    // MARK: EstimationDelegate
    
    func estimationViewControllerDidCancel() {
        self.hideEstimateViewController()
    }
    
    func estimationViewControllerDidSelectEstimate(estimate: Int) {
        if let story: Story = self.current_story {
            if let pivo = self.pivo {
                self.spinner.startAnimating()
                pivo.set_story_estimate(story.id!, estimate: estimate)
                self.hideEstimateViewController()
            }
        }
    }
    
    func hideEstimateViewController() {
        self.estimateViewController!.view.alpha = 0.0
        
        var removeConstraints = [NSLayoutConstraint]()
        for constraint: NSLayoutConstraint in self.view.constraints {
            if constraint.firstItem as! UIView == self.estimateViewController!.view {
                removeConstraints += [constraint]
            }
        }
        
        
        self.view.removeConstraints(removeConstraints)
        self.view.layoutIfNeeded()
        
        self.view.addConstraints(self.constraintsToMatchViews(self.estimateViewController!.view, matchToView: self.pointsLabel))
        
        
        UIView.animateWithDuration(
            0.3,
            delay: 0,
            usingSpringWithDamping: 0.96,
            initialSpringVelocity: 1.0,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: { () -> Void in
                self.estimateViewController!.view.alpha = 0.0
                self.view.layoutIfNeeded()
            },
            completion: { (Bool) -> Void in
                (self.estimateViewController?.view.removeFromSuperview())!
            })
    }
}

