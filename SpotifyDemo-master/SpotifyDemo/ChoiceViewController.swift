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
import SwiftSiriWaveformView

class ChoiceViewController: UIViewController, UITextFieldDelegate, NVActivityIndicatorViewable {
    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var loadingIndicator: NVActivityIndicatorView?
    var loadingView: UIView?
    
    @IBOutlet weak var waveformView: SwiftSiriWaveformView!
    var timer:NSTimer?
    var change:CGFloat = 0.01
    
    let gradientLayer = CAGradientLayer()
    
    // MARK: UIViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpGradientLayer()
        
        self.waveformView.density = 1.0
        timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(ChoiceViewController.refreshAudioView(_:)), userInfo: nil, repeats: true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Start or Join Party
    
    @IBAction func onStartPartyButton(sender: UIButton) {
        let size = CGSize(width: 30, height:30)
        Party.startParty(PFUser.currentUser()!) { (party: PFObject) in
            self.startActivityAnimating(size, message: "Starting party...", type: NVActivityIndicatorType.AudioEqualizer, color: UIColor.whiteColor())
            print("Host: started party")
            self.appDelegate.mpcHandler.setupSession()
            print("Host: session initiated")
             self.stopActivityAnimating()
            self.performSegueWithIdentifier("chooseTracksSegue", sender: nil)
        }
        // Note: unclear what happens if they click this and then cancel starting the party on the next screen
    }
    @IBAction func onJoinPartyButton(sender: UIButton) {
        appDelegate.mpcHandler.setupSession()
        
        print("Guest: session initiated")
    }
    
    // MARK: Waveform Animation
    
    internal func refreshAudioView(_:NSTimer) {
        if self.waveformView.amplitude <= self.waveformView.idleAmplitude || self.waveformView.amplitude > 1.0 {
            self.change *= -1.0
        }
        self.waveformView.amplitude += self.change
    }
    
    // MARK: Background
    
    func setUpGradientLayer() {
        let color1 = UIColor.clearColor().CGColor as CGColorRef
        let color2 = UIColor(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 0.5).CGColor as CGColorRef
        
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.colors = [color2, color1, color2]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.frame = self.view.bounds

        
        let backgroundView = UIView(frame: self.view.bounds)
        backgroundView.layer.insertSublayer(gradientLayer, atIndex: 0)
        self.view.backgroundColor = UIColor.clearColor()
        self.view.addSubview(backgroundView)
        self.view.sendSubviewToBack(backgroundView)
    }
}