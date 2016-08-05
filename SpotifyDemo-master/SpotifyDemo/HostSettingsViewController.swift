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
import AudioKit
import AVFoundation

class HostSettingsViewController: UIViewController {

    // MARK: Properties

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    @IBOutlet weak var backgroundImageView: UIImageView!
    let currentParty = PFUser.currentUser()!["party"] as! PFObject
    
    
    let mic = AKMicrophone()
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!
    var timer: NSTimer!
    let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    

    // MARK: ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
         NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostNowPlayingViewController.displayNewPeer), name: "New Peer", object: nil)

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.tracker = AKFrequencyTracker.init(mic, minimumFrequency: 200, maximumFrequency: 2000)
        self.silence = AKBooster(tracker, gain: 0)
        
    }

    func displayNewPeer() {
        self.view.makeToast("\(SpotifyClient.CURRENT_USER.lastGuestName!) just joined your party!", duration: 3.0, position: .Top)
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        self.view.backgroundColor = UIColor.blackColor()
    }
    @IBAction func onCancelButton(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: Resync

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

    // MARK: End Party

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
        self.performSegueWithIdentifier("HostEndsPartySegue", sender: nil)
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
    
    //MARK: Light Show
    
    @IBAction func lightShowOnOffSwitch(sender: UISwitch) {
//        if sender.on {
//            self.startLightShow()
//        } else {
//            self.stopLightShow()
//        }
    }
    
    func torchOn() {
        do {
            try device.lockForConfiguration()
            do {
                try device.setTorchModeOnWithLevel(1.0)
            } catch {
                print(error)
            }
            
            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func torchOff() {
        do {
            try device.lockForConfiguration()
            device.torchMode = AVCaptureTorchMode.Off
            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func startLightShow() {
        
        //Start mic
        AudioKit.output = silence
        AudioKit.start()
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(HostSettingsViewController.updateShow), userInfo: nil, repeats: true)
        
    }
    
    func stopLightShow() {
        self.timer.invalidate()
        AudioKit.stop()
    }
    
    
    func updateShow() {
        
        if tracker.amplitude > 0.2 {
            self.torchOn()
            
        } else {
            self.torchOff()
        }
        
    }
}
