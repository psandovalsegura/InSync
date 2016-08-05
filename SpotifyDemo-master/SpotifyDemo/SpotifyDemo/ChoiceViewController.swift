//
//  ChoiceViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/13/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import Parse
import NVActivityIndicatorView

class ChoiceViewController: UIViewController, UITextFieldDelegate, NVActivityIndicatorViewable {
    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var loadingIndicator: NVActivityIndicatorView?
    var loadingView: UIView?
    
    // MARK: UIViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: Start or Join Party
    
    @IBAction func onStartPartyButton(sender: UIButton) {
        let size = CGSize(width: 30, height:30)
        Party.startParty(PFUser.currentUser()!) { (party: PFObject) in
            self.startActivityAnimating(size, message: "Starting party...", type: NVActivityIndicatorType.AudioEqualizer, color: UIColor.blackColor())
            print("Host: started party")
            self.appDelegate.mpcHandler.setupSession()
            print("Host: session initiated")
             self.stopActivityAnimating()
            self.performSegueWithIdentifier("chooseTracksSegue", sender: nil)
        }
    }
    @IBAction func onJoinPartyButton(sender: UIButton) {
        appDelegate.mpcHandler.setupSession()
        print("Guest: session initiated")
    }
}