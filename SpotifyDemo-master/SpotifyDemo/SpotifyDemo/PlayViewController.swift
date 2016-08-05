//
//  PlayViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/13/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import Parse

class PlayViewController: UIViewController {
    
    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var selectedHost:MCPeerID!
    
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().idleTimerDisabled = true
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: Requesting Re-sync
    
    @IBAction func onRequestReSyncButton(sender: UIButton) {
        let host = [selectedHost]
        let resync = "resync"
        let resyncData = resync.dataUsingEncoding(NSUTF8StringEncoding)
        do {
            try appDelegate.mpcHandler.session.sendData(resyncData!, toPeers: host as! [MCPeerID], withMode: MCSessionSendDataMode.Reliable)
            print("Guest: requesting resync")
        } catch {
            print("Caught error: ", error)
        }
    }

    
    // MARK: Leaving Party
    
    @IBAction func onLeavePartyButton(sender: UIButton) {
        appDelegate.mpcHandler.session.disconnect()
        appDelegate.mpcHandler.hostAdvertiser?.stopAdvertisingPeer()
        print("Guest left session and stopped advertising")
        Party.leaveParty(PFUser.currentUser()!["party"] as! PFObject, currentUser: PFUser.currentUser()!)
        appDelegate.spotifyHandler.player?.logout({ (error: NSError!) in
            if error != nil {
                print("Guest: error logging out: \(error.localizedDescription)")
            }
        })
        //self.performSegueWithIdentifier("guestPlayLeavesSegue", sender: nil)
    }
}