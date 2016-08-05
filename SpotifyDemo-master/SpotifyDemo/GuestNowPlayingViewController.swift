//
//  GuestNowPlayingViewController.swift
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
import MarqueeLabel
import ESTMusicIndicator
import Toast_Swift

class GuestNowPlayingViewController: UIViewController, VolumeControlDelegate, UIViewControllerTransitioningDelegate {
    
    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    let currentUser = PFUser.currentUser()
    let currentParty = PFUser.currentUser()!["party"] as! PFObject
    
    @IBOutlet weak var frontView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var artistAlbumLabel: UILabel!
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var songInfoView: UIView!
    @IBOutlet weak var announcementLabel: MarqueeLabel!
    @IBOutlet weak var partyNameLabel: UILabel!
    @IBOutlet weak var announcementButton: UIButton!
    @IBOutlet weak var indicator: ESTMusicIndicatorView!
    
    var progress:CGFloat = 0
    @IBOutlet weak var progressView: CircleProgressBar!
    var screenSize:CGRect!
    
    var volumeControl:VolumeControl = VolumeControl()
    var viewForVolumeControl:UIView!
    var volume:CGFloat!
    
    let transition = BubbleTransition()
    let gradientLayer = CAGradientLayer()
    var gradientView:UIView!
    
    @IBOutlet weak var resyncButton: UIButton!
    var songLength:Double!
    var pause = false
    var pauseTime:CFTimeInterval?
    var currentProgress:CGFloat?
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        screenSize = UIScreen.mainScreen().bounds
        
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(GuestNowPlayingViewController.onTimer), userInfo: nil, repeats: true)
        
        // gradient
        self.view.backgroundColor = UIColor.blackColor()
        gradientView = UIView.init(frame: self.view.frame)
        gradientLayer.frame = UIScreen.mainScreen().bounds
        print("gradient frame: \(gradientLayer.frame)")
        let clear = UIColor.clearColor().CGColor as CGColorRef
        let black = UIColor.blackColor().CGColor as CGColorRef
        gradientLayer.colors = [black, clear, black]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        self.gradientView.layer.addSublayer(gradientLayer)
        self.view.addSubview(gradientView)
        self.view.sendSubviewToBack(gradientView)
        
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
        self.view.sendSubviewToBack(backgroundImageView)
        
        initialSetUpView()
        setUpCircleProgress()
        setUpVolumeControl()
        setUpIndicator()
        
        let tapAlbumRecognizer = UITapGestureRecognizer(target: self, action: #selector(GuestNowPlayingViewController.onAlbumTap(_:)))
        frontView.userInteractionEnabled = true
        frontView.addGestureRecognizer(tapAlbumRecognizer)
        
        let tapVolumeRecognizer = UITapGestureRecognizer(target: self, action: #selector(HostNowPlayingViewController.dismissVolumeTap(_:)))
        viewForVolumeControl.userInteractionEnabled = true
        viewForVolumeControl.addGestureRecognizer(tapVolumeRecognizer)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GuestNowPlayingViewController.updateForSongChange), name: "SongDidChange", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GuestNowPlayingViewController.didPlayPause), name: "DidPlayPause", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GuestNowPlayingViewController.updateMessage), name: "DataDidChange", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GuestNowPlayingViewController.displayLitness), name: "CalculatedFinalLitness", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GuestNowPlayingViewController.notifyEndParty), name: "PartyDidEnd", object: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(animated: Bool) {
        self.becomeFirstResponder()
        updateMessage()
    }
    
    // MARK: End Party
    
    func notifyEndParty() {
        self.view.makeToast("This party has ended", duration: 5.0, position: .Top)
        //self.performSegueWithIdentifier("GuestLeavePartySegue", sender: nil)
    }
    
    // MARK: Now Playing View
    
    func initialSetUpView() {
        partyNameLabel.text = currentParty["name"] as? String
        let firstSong = currentParty["now_playing"] as! PFObject
        firstSong.fetchIfNeededInBackgroundWithBlock { (song:PFObject?, error:NSError?) in
            if error == nil {
                self.songLength = firstSong["duration"] as! Double
                if let firstOffset = self.appDelegate.mpcHandler.firstOffset! as? Double {
                    print("first offset: \(firstOffset), songlength: \(self.songLength)")
                    let initialProgress = self.appDelegate.mpcHandler.firstOffset!/self.songLength
                    self.progressView.setProgress(CGFloat(initialProgress), animated: false)
                }
                self.songLabel.text = firstSong["name"] as? String
                self.artistAlbumLabel.text = (firstSong["artist"] as? String)! + " - " + (firstSong["albumName"] as? String)!
                self.albumImageView.imageFromUrl((firstSong["albumImageURL"] as? String)!)
                self.backgroundImageView.imageFromUrl((firstSong["albumImageURL"] as? String)!)
                self.progressView.setProgress(1.0, animated: true, duration: CGFloat(self.songLength - self.appDelegate.mpcHandler.firstOffset!))
            } else {
                print("Error fetching firstSong in Guest Now Playing: \(error)")
            }
        }
        
    }
    func setUpView() {
        self.progressView.setProgress(0.0, animated: false)
        currentParty.fetchInBackgroundWithBlock { (fetchParty:PFObject?, error:NSError?) in
            let nowPlayingSong = fetchParty!["now_playing"] as! PFObject
            nowPlayingSong.fetchIfNeededInBackgroundWithBlock { (fetchSong: PFObject?, error:NSError?) in
                //print("fetching nowplaying in main vc", nowPlayingSong["name"] as! String)
                self.songLabel.text = fetchSong!["name"] as? String
                self.artistAlbumLabel.text = (fetchSong!["artist"] as? String)! + " - " + (fetchSong!["albumName"] as? String)!
                self.albumImageView.imageFromUrl((fetchSong!["albumImageURL"] as? String)!)
                self.backgroundImageView.imageFromUrl((fetchSong!["albumImageURL"] as? String)!)
                self.songLength = nowPlayingSong["duration"] as! Double
                self.progressView.setProgress(1.0, animated: true, duration: CGFloat(self.songLength))
            }
        }
    }
    
    func updateForSongChange() {
        print("called update for song change")
        sendLitness()
        setUpView()
    }
    
    //MARK: Litness
    
    func sendLitness() {
        let host = [appDelegate.mpcHandler.currentHost!]
        let litness = "\(SpotifyClient.CURRENT_USER.personalLitness!)"
        let litnessData = litness.dataUsingEncoding(NSUTF8StringEncoding)
        do {
            try appDelegate.mpcHandler.session.sendData(litnessData!, toPeers: host, withMode: MCSessionSendDataMode.Reliable)
            print("Guest: sending litness")
        } catch {
            print("Caught error: ", error)
        }
        SpotifyClient.CURRENT_USER.personalLitness = 0
    }
    
    func displayLitness() {
        let avgLitness = SpotifyClient.CURRENT_USER.previousLitness!
        print("The last track's litness was: \(avgLitness)")
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (motion == .MotionShake) {
            print("Shaken")
            //SpotifyClient.CURRENT_USER.personalLitness! += 1
            SpotifyClient.CURRENT_USER.danceNumber! += 1
        }
        
    }
    
    func onTimer() {
        if (SpotifyClient.CURRENT_USER.danceNumber! == 0) {
            // SpotifyClient.CURRENT_USER.personalLitness! -= 5
        }
        else if (SpotifyClient.CURRENT_USER.danceNumber! >= 5) {
            SpotifyClient.CURRENT_USER.personalLitness! += 5
        } else if (SpotifyClient.CURRENT_USER.danceNumber! >= 3) {
            SpotifyClient.CURRENT_USER.personalLitness! += 2
        } else if (SpotifyClient.CURRENT_USER.danceNumber! >= 1) {
            SpotifyClient.CURRENT_USER.personalLitness! += 1
        }
        SpotifyClient.CURRENT_USER.danceNumber = 0
        //SpotifyClient.CURRENT_USER.personalLitness! += 2
        print("personal litness is now \(SpotifyClient.CURRENT_USER.personalLitness!)")
    }
    
    
    // MARK: Image controls
    
    func onAlbumTap(sender: UITapGestureRecognizer) {
        if self.albumImageView.hidden == true {
            self.indicator.hidden = true
            self.albumImageView.hidden = false
        } else {
            self.albumImageView.hidden = true
            self.indicator.hidden = false
            if appDelegate.spotifyHandler.player!.isPlaying {
                self.indicator.state = .ESTMusicIndicatorViewStatePlaying
            } else {
                self.indicator.state = .ESTMusicIndicatorViewStatePaused
            }
        }
    }
    
    // MARK: Progress Circle
    
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
        progressView.progressBarWidth = 3.5
        progressView.progressBarTrackColor = UIColor.clearColor()
        progressView.startAngle = -90
        
        // Hint View Customization (inside progress bar)
        progressView.hintHidden = true
        progressView.sendSubviewToBack(indicator)
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
    func dismissVolumeTap(sender: UITapGestureRecognizer) {
        viewIsHidden(true)
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
        transition.bubbleColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.85)
        return transition
    }
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.transitionMode = .Dismiss
        transition.startingPoint = announcementButton.center
        transition.bubbleColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.85)
        return transition
    }
    
    // MARK: Play/Pause Indicator
    
    func setUpIndicator() {
        indicator.tintColor = UIColor.init(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 1.0)
        indicator.state = .ESTMusicIndicatorViewStatePlaying
        indicator.hidden = true
    }
    func didPlayPause() {
        //        if appDelegate.spotifyHandler.player!.isPlaying == true {
        //            print("RESUME")
        //            if albumImageView.hidden == true {
        //                indicator.state = .ESTMusicIndicatorViewStatePlaying
        //            }
        //            let timeSincePause = CACurrentMediaTime() - pauseTime!
        //            let timeLeft = songLength - Double(currentProgress!) - timeSincePause
        //            progressView.setProgress(1.0, animated: true, duration: CGFloat(timeLeft))
        //        } else {
        //            print("PAUSE")
        //            if albumImageView.hidden == true {
        //                indicator.state = .ESTMusicIndicatorViewStatePaused
        //            }
        //            currentProgress = progressView.progress
        //            progressView.stopAnimation()
        //            progressView.setProgress(currentProgress!, animated: false)
        //            pauseTime = CACurrentMediaTime()
        //        }
        
        pause = !pause
        if pause {
            print("PAUSE")
            if albumImageView.hidden == true {
                indicator.state = .ESTMusicIndicatorViewStatePaused
            }
            currentProgress = progressView.progress
            progressView.stopAnimation()
            progressView.setProgress(currentProgress!, animated: false)
            pauseTime = CACurrentMediaTime()
        } else {
            print("RESUME")
            if albumImageView.hidden == true {
                indicator.state = .ESTMusicIndicatorViewStatePlaying
            }
            let timeSincePause = CACurrentMediaTime() - pauseTime!
            let timeLeft = songLength - Double(currentProgress!) - timeSincePause
            progressView.setProgress(1.0, animated: true, duration: CGFloat(timeLeft))
        }
    }
    
    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let announceVC = segue.destinationViewController as? AnnouncementViewController {
            announceVC.transitioningDelegate = self
            announceVC.modalPresentationStyle = .Custom
        }
    }
    
    // MARK: Messages
    
    func updateMessage() {
        //print("about to update message")
        Message.getTopMessages(self.currentParty, completion: { (newMessages) in
            var expectedLabelSize: CGSize
            var displayString = ""
            self.announcementLabel.text = ""
            
            if newMessages.count == 0 {
                self.announcementLabel.text = "saysomething    •    saysomething    •    saysomething    •     saysomething    •    "
                
            } else if newMessages.count >= 3 {
                let messageOne = newMessages[0]
                let textOne = messageOne["text"] as! String
                let messageTwo = newMessages[1]
                let textTwo = messageTwo["text"] as! String
                let messageThree = newMessages[2]
                let textThree = messageThree["text"] as! String
                
                while (self.announcementLabel.intrinsicContentSize().width < self.view.bounds.size.width) {
                    displayString += "  \(textOne)   •    \(textTwo)    •    \(textThree)    •    "
                    self.announcementLabel.text = displayString
                }
            } else if newMessages.count == 2 {
                let messageOne = newMessages[0]
                let textOne = messageOne["text"] as! String
                let messageTwo = newMessages[1]
                let textTwo = messageTwo["text"] as! String
                
                while (self.announcementLabel.intrinsicContentSize().width < self.view.bounds.size.width) {
                    displayString += "\(textOne)    •    \(textTwo)    •    "
                    self.announcementLabel.text = displayString
                }
            } else if newMessages.count == 1 {
                let messageOne = newMessages[0]
                let textOne = messageOne["text"] as! String
                
                while (self.announcementLabel.intrinsicContentSize().width < self.view.bounds.size.width) {
                    displayString += "\(textOne)     •    "
                    self.announcementLabel.text = displayString
                }
            }
        })
    }
    
    // MARK: Resync
    
    @IBAction func onResyncButton(sender: UIButton) {
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
    
}
