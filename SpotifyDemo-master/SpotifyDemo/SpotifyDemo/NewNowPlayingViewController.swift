//
//  NewNowPlayingViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/23/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import MultipeerConnectivity
import CircleProgressBar
import BubbleTransition

class NewNowPlayingViewController: UIViewController, VolumeControlDelegate, UIViewControllerTransitioningDelegate {

    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    let currentUser = PFUser.currentUser()
    let currentParty = PFUser.currentUser()!["party"] as! PFObject
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var artistAlbumLabel: UILabel!
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var songInfoView: UIView!
    
    var progress:CGFloat = 0
    @IBOutlet weak var progressView: CircleProgressBar!
    var screenSize:CGRect!
    
    @IBOutlet weak var announcementButton: UIButton!
    
    var volumeControl:VolumeControl = VolumeControl()
    let transition = BubbleTransition()

    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        
        screenSize = UIScreen.mainScreen().bounds
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(NewNowPlayingViewController.onTimer), userInfo: nil, repeats: true)
   
        
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            backgroundImageView.backgroundColor = UIColor.clearColor()
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            
            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            backgroundImageView.addSubview(blurEffectView)
        } else {
            backgroundImageView.backgroundColor = UIColor.blackColor()
        }
        setUpView()
        setUpCircleProgress()
        
        setUpVolumeControl()
        
        
        let tapAlbumRecognizer = UITapGestureRecognizer(target: self, action: #selector(NewNowPlayingViewController.onAlbumTap(_:)))
        progressView.userInteractionEnabled = true
        progressView.addGestureRecognizer(tapAlbumRecognizer)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainPartyViewController.setUpView), name: "SongDidChange", object: nil)
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
                self.songLabel.text = fetchSong!["name"] as? String
                self.artistAlbumLabel.text = (fetchSong!["artist"] as? String)! + " - " + (fetchSong!["albumName"] as? String)!
                self.albumImageView.imageFromUrl((fetchSong!["albumImageURL"] as? String)!)
                //                self.backgroundImageView.imageFromUrl((fetchSong!["albumImageURL"] as? String)!)
                self.background((fetchSong!["albumImageURL"] as? String)!)
            }
        }
    }
    
    
    // MARK: Image controls
    
    func background(imageURL:String){
        let beginImage = CIImage(contentsOfURL: NSURL(string:imageURL)!)!
        
        let vignette = CIFilter(name:"CIVignette")
        vignette!.setValue(beginImage, forKey:kCIInputImageKey)
        vignette!.setValue(4, forKey:"inputIntensity")
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
    
    // MARK: Lit Meter
    
    func setUpCircleProgress() {
        progressView.setProgress(0, animated: true)
        
        albumImageView.layer.borderWidth = 0
        albumImageView.layer.masksToBounds = false
        albumImageView.layer.cornerRadius = albumImageView.frame.height/2
        albumImageView.clipsToBounds = true
        
        songInfoView.layer.borderWidth = 0
        songInfoView.layer.masksToBounds = false
        songInfoView.layer.cornerRadius = albumImageView.frame.height/2
        songInfoView.clipsToBounds = true
        
        // Progress Bar Customization
        progressView.progressBarWidth = 5
        //        progressView.progressBarProgressColor = UIColor.blueColor()
        progressView.progressBarTrackColor = UIColor.clearColor()
        progressView.startAngle = -90
        
        // Hint View Customization (inside progress bar)
        progressView.hintHidden = true
        progressView.hintViewBackgroundColor = UIColor.clearColor()
    }
    
    func onTimer() {
        progress = progress + 0.1
        progressView.setProgress(progress, animated: true)
    }
    
    // MARK: Volume Control
    
    func setUpVolumeControl() {
        let initialVolume = CGFloat(appDelegate.spotifyHandler.player!.volume)
        volumeControl = VolumeControl.init(center: CGPointMake(screenSize.width, screenSize.height), withRadius: screenSize.width*0.36, withVolume: initialVolume, withVolumeControlDelegate: self)
//        volumeControl.setColor(UIColor.blackColor())
        self.view.addSubview(volumeControl)
//        self.control = [[VolumeControl alloc] initWithCenter:CGPointMake(screen.size.width, screen.size.height)
//            
//            withRadius:screen.size.width*0.50
//            
//            withVolume:self.volume/100
//            
//            withVolumeControlDelegate:self];
//        
    }
    @IBAction func onVolumeButton(sender: UIButton) {
        print("tapped volume button")
        viewIsHidden(volumeControl.hidden)
        
    }
    func viewIsHidden(ishidden: Bool) {
        print("volume button tapped")
        if ishidden == true {
            let volume = CGFloat(appDelegate.spotifyHandler.player!.volume)
            volumeControl.setVolume(volume)
            volumeControl.hidden = false
        } else {
            volumeControl.hidden = true
        }
    }
    func didChangeVolume(volume: CGFloat) {
        //
        volumeControl.setVolume(volume)
    }
    
    
    
    
    // MARK: UIViewControllerTransitioningDelegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Present
        transition.startingPoint = announcementButton.center
        transition.bubbleColor = UIColor(red: 42/255.0, green: 65/255.0, blue: 99/255.0, alpha: 1)
        return transition
    }
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Dismiss
        transition.startingPoint = announcementButton.center
        transition.bubbleColor = UIColor(red: 42/255.0, green: 65/255.0, blue: 99/255.0, alpha: 1)
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
