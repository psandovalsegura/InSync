//
//  TestHomeViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/25/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import MultipeerConnectivity
import CircleProgressBar
import BubbleTransition

class TestHomeViewController: UIViewController, VolumeControlDelegate, UIViewControllerTransitioningDelegate {

    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    let currentUser = PFUser.currentUser()
    let currentParty = PFUser.currentUser()!["party"] as! PFObject
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var songInfoView: UIView!
    
    var screenSize:CGRect!
    
    @IBOutlet weak var announcementButton: UIButton!
    
    var volumeControl:VolumeControl = VolumeControl()
    var viewForVolumeControl:UIView!
    var volume:CGFloat!
    
    let transition = BubbleTransition()
    
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        
        screenSize = UIScreen.mainScreen().bounds
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        
//        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(NewNowPlayingViewController.onTimer), userInfo: nil, repeats: true)
        
        
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            backgroundImageView.backgroundColor = UIColor.clearColor()
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            
            blurEffectView.frame = screenSize
            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            backgroundImageView.addSubview(blurEffectView)
        } else {
            backgroundImageView.backgroundColor = UIColor.blackColor()
        }
        setUpView()
        setUpVolumeControl()
        
        
        let tapAlbumRecognizer = UITapGestureRecognizer(target: self, action: #selector(TestHomeViewController.onAlbumTap(_:)))
        songInfoView.userInteractionEnabled = true
        songInfoView.addGestureRecognizer(tapAlbumRecognizer)
        
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainPartyViewController.setUpView), name: "SongDidChange", object: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidLayoutSubviews() {
        print(self.view.frame.size)
    }
    
    // MARK: Now Playing View
    
    func setUpView() {
        currentParty.fetchInBackgroundWithBlock { (fetchParty:PFObject?, error:NSError?) in
            let nowPlayingSong = fetchParty!["now_playing"] as! PFObject
            nowPlayingSong.fetchInBackgroundWithBlock { (fetchSong: PFObject?, error:NSError?) in
                print("fetching nowplaying in main vc", nowPlayingSong["name"] as! String)
                
                self.albumImageView.imageFromUrl((fetchSong!["albumImageURL"] as? String)!)
                self.backgroundImageView.imageFromUrl((fetchSong!["albumImageURL"] as? String)!)
            }
        }
    }
    
    
    // MARK: Image controls
    
    func background(imageURL:String){
        let beginImage = CIImage(contentsOfURL: NSURL(string:imageURL)!)!
        
        let vignette = CIFilter(name:"CIVignette")
        vignette!.setValue(beginImage, forKey:kCIInputImageKey)
        vignette!.setValue(5, forKey:"inputIntensity")
        vignette!.setValue(17, forKey:"inputRadius")
        
        let vignetteImage = UIImage(CIImage: vignette!.outputImage!)
        self.backgroundImageView.image = vignetteImage
    }
    func onAlbumTap(sender: UITapGestureRecognizer) {
        if self.albumImageView.alpha == 1 {
            UIView.animateWithDuration(0.5) {
                self.songInfoView.alpha = 1
                self.albumImageView.alpha = 0
            }
        } else {
            UIView.animateWithDuration(0.5) {
                self.albumImageView.alpha = 1
                self.songInfoView.alpha = 0
            }
        }
    }
    
    // MARK: Volume Control
    
    func setUpVolumeControl() {
        let initialVolume = CGFloat(appDelegate.spotifyHandler.player!.volume)
        
        viewForVolumeControl = UIView.init(frame: screenSize)
        viewForVolumeControl.backgroundColor = UIColor.init(white: 0.0, alpha: 0.0)
        self.view.addSubview(viewForVolumeControl)
        viewForVolumeControl.hidden = true
        
        volumeControl = VolumeControl.init(center: CGPointMake(screenSize.width, screenSize.height), withRadius: screenSize.width*0.5, withVolume: initialVolume, withVolumeControlDelegate: self)
        volumeControl.setColor(UIColor.whiteColor())
        self.viewForVolumeControl.addSubview(volumeControl)
    }
    @IBAction func onVolumeButton(sender: UIButton) {
        volumeControl.hidden = false
        viewForVolumeControl.hidden = false
        UIView.animateWithDuration(0.2) {
            self.viewForVolumeControl.backgroundColor = UIColor.init(white: 0.0, alpha: 0.6)
        }
    }
    
    // MARK: VolumeControlDelegate
    
    func viewIsHidden(ishidden: Bool) {
        UIView.animateWithDuration(0.2) {
            self.viewForVolumeControl.backgroundColor = UIColor.init(white: 0.0, alpha: 0.0)
        }
        self.viewForVolumeControl.hidden = true
    }
    func didChangeVolume(volume: CGFloat) {
        let volumeDouble = Double(volume) / 100
        appDelegate.spotifyHandler.player?.setVolume(volumeDouble, callback: { (error:NSError!) in
            if error != nil {
                print("Error changing volume with control: \(error)")
            }
        })
    }
    
    
    // MARK: UIViewControllerTransitioningDelegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Present
        transition.startingPoint = announcementButton.center
        transition.bubbleColor = UIColor(red: 42/255.0, green: 65/255.0, blue: 99/255.0, alpha: 0.5)
        return transition
    }
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Dismiss
        transition.startingPoint = announcementButton.center
        transition.bubbleColor = UIColor(red: 42/255.0, green: 65/255.0, blue: 99/255.0, alpha: 0.5)
        return transition
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let announceVC = segue.destinationViewController as? AnnouncementViewController {
            announceVC.transitioningDelegate = self
            announceVC.modalPresentationStyle = .Custom
        }
    } 
}