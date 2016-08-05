//
//  HostSettingsViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/23/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import Parse

class HostSettingsViewController: UIViewController {

    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func onResyncButton(sender: UIButton) {
        sendOffsetData(appDelegate.mpcHandler.session.connectedPeers)
    }
    func sendOffsetData(toPeers: [MCPeerID]) {
        let offset = appDelegate.spotifyHandler.player!.currentPlaybackPosition
        let offsetString = String(offset)
        let offsetData = offsetString.dataUsingEncoding(NSUTF8StringEncoding)
        do {
            try appDelegate.mpcHandler.session.sendData(offsetData!, toPeers: toPeers, withMode: MCSessionSendDataMode.Reliable)
            print("Host: sent offset data: \(offset)")
        } catch {
            print("Host: error sending offset data")
        }
    }
    @IBAction func onEndPartyButton(sender: UIButton) {
        let exitString = "end-session-key"
        let exitData = exitString.dataUsingEncoding(NSUTF8StringEncoding)
        do {
            try appDelegate.mpcHandler.session.sendData(exitData!, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
        } catch {
            print("Host: error telling connected peers to leave")
        }
        appDelegate.mpcHandler.session.disconnect()
        appDelegate.mpcHandler.hostAdvertiser?.stopAdvertisingPeer()
        Party.endParty(PFUser.currentUser()!["party"] as! PFObject)
        appDelegate.spotifyHandler.player?.logout({ (error: NSError!) in
            if error != nil {
                print("Host: error logging out: \(error.localizedDescription)")
            }
        })
    }

}
