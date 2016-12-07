//
//  SetupViewController.swift
//  SwiftSample
//
//  Created by Bob Vork on 05/03/16.
//  Copyright © 2016 Scandit AG. All rights reserved.
//

import UIKit
import KeychainSwift

class SetupViewController: UIViewController, PivoDelegate, UITextFieldDelegate {

    @IBOutlet weak var tokenField: UITextField!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var startPivoButton: UIButton!
    
    var pivo : PivoController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.spinner.stopAnimating()
        self.resultLabel.alpha = 0.0
        self.resultImageView.alpha = 0.0
        self.startPivoButton.alpha = 0.0
    }
    
    @IBAction func openSettingsButtonPressed(_ sender: AnyObject) {
        
        let urlString: NSString = "https://www.pivotaltracker.com/profile"
        UIApplication.shared.openURL(URL(string: urlString as String)!)
    }

    @IBAction func startPivoButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tokenFieldValueChanged(_ sender: AnyObject) {

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.verifyAccessToken()
        textField.resignFirstResponder()
        return true
    }
    
    func verifyAccessToken() {
        let token = self.tokenField.text
        let trimmedToken = token!.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )
        let charCount: Int = trimmedToken.characters.count
        
        if charCount == 32 {
            self.spinner.startAnimating()
            self.tokenField.isEnabled = false
            
            self.resultLabel.alpha = 1.0
            self.resultLabel.text = "Verifying…"
            self.resultImageView.alpha = 0.0;
            KeychainSwift().set(trimmedToken, forKey: "pivotalapikey")
            self.pivo = PivoController(token: trimmedToken)
            self.pivo!.delegate = self
            self.pivo!.get_current_user()
            
        } else if charCount == 0 {
            self.resultLabel.alpha = 0.0
            self.resultImageView.alpha = 0.0
            self.startPivoButton.alpha = 0.0
        } else {
            self.resultImageView.alpha = 1.0
            self.resultLabel.alpha = 1.0
            self.resultLabel.text = "That doesn't look like a valid token. Make sure you copy the complete string."
            
            self.resultImageView.image = UIImage(named: "ic_error_red")
        }
    }
    
    
    func gotUser(_ userId: Int, name: String) {
        self.spinner.stopAnimating()
        self.resultLabel.alpha = 1.0
        self.resultImageView.alpha = 1.0
        
        self.resultImageView.image = UIImage(named: "ic_check_green")
        self.resultLabel.text = String(format: "Hi %@, that worked!", name)
        
        self.startPivoButton.alpha = 1.0;
    }
    
    func scannedStory(_ story: Story) {}
}
