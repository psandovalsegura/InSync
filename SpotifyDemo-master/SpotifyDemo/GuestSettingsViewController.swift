//
//  GuestSettingsViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/21/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import Parse
import Toast_Swift

class GuestSettingsViewController: UIViewController {

    // MARK: Properties

    let currentUser = PFUser.currentUser()
    let currentParty = PFUser.currentUser()!["party"] as! PFObject


    @IBOutlet weak var backgroundImageView: UIImageView!
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate


    // MARK: ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GuestNowPlayingViewController.notifyEndParty), name: "PartyDidEnd", object: nil)
        currentParty.fetchInBackgroundWithBlock { (fetchParty:PFObject?, error:NSError?) in
            let nowPlayingSong = fetchParty!["now_playing"] as! PFObject
            nowPlayingSong.fetchInBackgroundWithBlock { (fetchSong: PFObject?, error:NSError?) in
                //        self.backgroundImageView.imageFromUrl((fetchSong!["albumImageURL"] as? String)!)
                //            }
            }
            //        if !UIAccessibilityIsReduceTransparencyEnabled() {
            //            backgroundImageView.backgroundColor = UIColor.clearColor()
            //            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
            //            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            //
            //            blurEffectView.frame = self.view.bounds
            //            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            //            backgroundImageView.addSubview(blurEffectView)
            //        } else {
            //            backgroundImageView.backgroundColor = UIColor.blackColor()
            //        }

        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onCancelButton(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: Requesting Re-sync

    @IBAction func onRequestReSyncButton(sender: UIButton) {
        let host = [appDelegate.mpcHandler.currentHost!]
        let resync = "resync"
        let resyncData = resync.dataUsingEncoding(NSUTF8StringEncoding)
        do {
            try appDelegate.mpcHandler.session.sendData(resyncData!, toPeers: host, withMode: MCSessionSendDataMode.Reliable)
            print("Guest: requesting resync")
        } catch {
            print("Caught error: ", error)
        }
    }

    func notifyEndParty() {
        self.view.makeToast("This party has ended", duration: 5.0, position: .Top)
        //self.performSegueWithIdentifier("GuestLeavePartySegue", sender: nil)
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
        self.performSegueWithIdentifier("guestLeavesPartySegue", sender: nil)
    }

    //MARK: Litness
    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override func viewDidAppear(animated: Bool) {
        self.becomeFirstResponder()
    }

    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (motion == .MotionShake) {
            print("Shaken")
            SpotifyClient.CURRENT_USER.personalLitness! += 1
        }
    }
}
