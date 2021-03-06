//
//  EstimationViewController.swift
//  SwiftSample
//
//  Created by Bob Vork on 17/03/2016.
//  Copyright © 2016 Scandit AG. All rights reserved.
//

import UIKit


protocol EstimationDelegate {
    func estimationViewControllerDidCancel()
    func estimationViewControllerDidSelectEstimate(estimate: Int)
}


private let reuseIdentifier = "EstimateCell"

class EstimationViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var delegate: EstimationDelegate?

    @IBOutlet var collectionView: UICollectionView!
    
    var pointScale = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView!.registerNib(UINib(nibName: "EstimateCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.delegate?.estimationViewControllerDidCancel()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.collectionView.reloadData()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.pointScale.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:EstimateCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! EstimateCollectionViewCell
        
        // Configure the cell
        cell.estimateLabel.text = self.pointScale[indexPath.row]
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
     return true
     }
     */
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.estimationViewControllerDidSelectEstimate(Int(self.pointScale[indexPath.row])!)
    }
    
}
