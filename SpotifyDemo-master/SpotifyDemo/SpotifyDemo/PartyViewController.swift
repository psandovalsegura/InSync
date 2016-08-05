//
//  PartyViewController.swift
//  InSync
//
//  Created by Olivia Gregory on 7/14/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import CoreMotion
import Parse

class PartyViewController: UIViewController {
    
    let currentUser = PFUser.currentUser()
    var currentParty: PFObject?

    @IBOutlet weak var litnessLabel: UILabel!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentParty = currentUser!["party"] as? PFObject
        litnessLabel.text = currentParty!["litness"] as? String
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func viewDidAppear(animated: Bool) {
        self.becomeFirstResponder()
    }
    
    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (motion == .MotionShake) {
            print("Shaken")
            currentParty?.incrementKey("litness", byAmount: 0.1)
            litnessLabel.text = currentParty!["litness"] as? String
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
