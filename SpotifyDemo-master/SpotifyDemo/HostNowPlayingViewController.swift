//
//  HostNowPlayingViewController.swift
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
import BAFluidView
import Gecco

class HostNowPlayingViewController: UIViewController, VolumeControlDelegate, UIViewControllerTransitioningDelegate {

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

    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var resyncButton: UIButton!
    var songLength:Double!
    var pause = false
    var pauseTime:CFTimeInterval?
    var currentProgress:CGFloat?

    // MARK: ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.translucent = true

        screenSize = UIScreen.mainScreen().bounds

        UIApplication.sharedApplication().idleTimerDisabled = true

        // gradient
        self.view.backgroundColor = UIColor.blackColor()
        gradientView = UIView.init(frame: self.view.frame)
        gradientLayer.frame = UIScreen.mainScreen().bounds
        let clear = UIColor.clearColor().CGColor as CGColorRef
        let black = UIColor.blackColor().CGColor as CGColorRef
        gradientLayer.colors = [black, clear, black]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        self.gradientView.layer.addSublayer(gradientLayer)
        self.view.addSubview(gradientView)
        self.view.sendSubviewToBack(gradientView)


//        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(LitMeterViewController.onTimer), userInfo: nil, repeats: true)

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

        let tapAlbumRecognizer = UITapGestureRecognizer(target: self, action: #selector(HostNowPlayingViewController.onAlbumTap(_:)))
        progressView.userInteractionEnabled = true
        progressView.addGestureRecognizer(tapAlbumRecognizer)

        let tapVolumeRecognizer = UITapGestureRecognizer(target: self, action: #selector(HostNowPlayingViewController.dismissVolumeTap(_:)))
        viewForVolumeControl.userInteractionEnabled = true
        viewForVolumeControl.addGestureRecognizer(tapVolumeRecognizer)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostNowPlayingViewController.updateForSongChange), name: "SongDidChange", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostNowPlayingViewController.updateMessage), name: "DataDidChange", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostNowPlayingViewController.displayLitness), name: "CalculatedLitness", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostNowPlayingViewController.displayNewPeer), name: "New Peer", object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostNowPlayingViewController.displayPartyMessage), name: "Started Party", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostNowPlayingViewController.resyncRequest), name: "ResyncRequest", object: nil)

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func viewDidLayoutSubviews() {
        print(self.view.frame.size)
        if (!AppDelegate.showedTutorial()) {
            displayTutorial()
        } else {
            //displayPartyMessage()
        }
    }
    override func viewDidAppear(animated: Bool) {
        self.becomeFirstResponder()
        updateMessage()
        // displayTutorial()
    }

    func displayPartyMessage() {
        if (AppDelegate.showedTutorial()) {
            self.view.makeToast("Welcome to your party!", duration: 3.0, position: .Top)
        }
    }

    // MARK: Now Playing View

    func initialSetUpView() {
        let partyName = currentParty["name"] as? String
        partyNameLabel.text = partyName!
        let firstSong = currentParty["now_playing"] as! PFObject
        self.songLabel.text = firstSong["name"] as? String
        self.artistAlbumLabel.text = (firstSong["artist"] as? String)! + " - " + (firstSong["albumName"] as? String)!
        self.albumImageView.imageFromUrl((firstSong["albumImageURL"] as? String)!)
        self.backgroundImageView.imageFromUrl((firstSong["albumImageURL"] as? String)!)
        songLength = firstSong["duration"] as! Double
        self.progressView.setProgress(1.0, animated: true, duration: CGFloat(songLength))
        let announcement = ("Welcome to \(partyName!)!")
        Message.postMessage(announcement, forParty: currentParty) { (newMessage) in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("DataDidChange", object: nil, userInfo: nil)
                print("sent message notif")
            })

        }
    }
    func setUpView() {
        self.progressView.setProgress(0.0, animated: true, duration: CGFloat(0.001))
        currentParty.fetchInBackgroundWithBlock { (fetchParty:PFObject?, error:NSError?) in
            let nowPlayingSong = fetchParty!["now_playing"] as! PFObject
            nowPlayingSong.fetchIfNeededInBackgroundWithBlock { (fetchSong: PFObject?, error:NSError?) in
                print("fetching nowplaying in main vc", nowPlayingSong["name"] as! String)
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
        setUpView()
    }

    func displayNewPeer() {
        self.view.makeToast("\(SpotifyClient.CURRENT_USER.lastGuestName!) just joined your party!", duration: 3.0, position: .Top)
    }

    //MARK: Litness

    func displayLitness() {
        let avgLitness = SpotifyClient.CURRENT_USER.previousTrack!["litness"]

        print("The last track's litness was: \(avgLitness)")
    }
    /*
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
     */
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

    // MARK: Request Resync

    func resyncRequest() {
        print("RESYNC REQUEST")
        let fromPeer = appDelegate.mpcHandler.fromPeer[0] as! MCPeerID
        let alert = UIAlertController(title: "Re-sync Request", message: "\(fromPeer.displayName) requests a re-sync.", preferredStyle: UIAlertControllerStyle.Alert)
        let acceptAction: UIAlertAction = UIAlertAction(title: "Re-Sync", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            self.sendOffsetData(self.appDelegate.mpcHandler.fromPeer as! [MCPeerID])
        }
        let declineAction = UIAlertAction(title: "Ignore", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
        }
        alert.addAction(acceptAction)
        alert.addAction(declineAction)
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.presentViewController(alert, animated: true, completion: nil)
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
        indicator.sizeToFit()
        indicator.state = .ESTMusicIndicatorViewStatePlaying
        indicator.hidden = true
        playPauseButton.selected = false
    }
    @IBAction func onPlayPauseButton(sender: AnyObject) {
        // send over session
        let playPauseString:String = "play-pause-key"
        let playPauseData = playPauseString.dataUsingEncoding(NSUTF8StringEncoding)
        do {
            try appDelegate.mpcHandler.session.sendData(playPauseData!, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
            print("Host sent play/pause signal")
        } catch {
            print("Host: error sending play/pause signal")
        }
        // update button and indicator
        if playPauseButton.selected == false {
            playPauseButton.selected = true
            if albumImageView.hidden == true {
                indicator.state = .ESTMusicIndicatorViewStatePaused
            }
        } else {
            playPauseButton.selected = false
            if albumImageView.hidden == true {
                indicator.state = .ESTMusicIndicatorViewStatePlaying
            }
        }
        pause = !pause
        if pause {
            print("PAUSE")
            currentProgress = progressView.progress
            progressView.stopAnimation()
            pauseTime = CACurrentMediaTime()
            progressView.setProgress(currentProgress!, animated: false)

            appDelegate.spotifyHandler.player?.setIsPlaying(false, callback: { (error:NSError!) in
                if error != nil {
                    print("Host: error pausing")
                }})
        } else {
            print("RESUME")
            let timeSincePause = CACurrentMediaTime() - pauseTime!
            let timeLeft = songLength - Double(currentProgress!) - timeSincePause
            progressView.setProgress(1.0, animated: true, duration: CGFloat(timeLeft))

            appDelegate.spotifyHandler.player?.setIsPlaying(true, callback: { (error:NSError!) in
                if error != nil {
                    print("Host: error playing after pause")
                }})
        }

//        if appDelegate.spotifyHandler.player!.isPlaying {
//            appDelegate.spotifyHandler.player?.setIsPlaying(false, callback: { (error:NSError!) in
//                if error != nil {
//                    print("Host: error pausing")
//                }})
//        } else {
//            appDelegate.spotifyHandler.player?.setIsPlaying(true, callback: { (error:NSError!) in
//                if error != nil {
//                    print("Host: error playing after pause")
//                }})
//        }
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

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let announceVC = segue.destinationViewController as? AnnouncementViewController {
            announceVC.transitioningDelegate = self
            announceVC.modalPresentationStyle = .Custom
        }
    }

    //MARK: App hints
    
    func displayTutorial () {
        print("called display tutorial")
        //if (!(AppDelegate.isAppAlreadyLaunchedOnce())) {
        presentAnnotation()
        //} else {

        //}
    }
    func presentAnnotation() {
        print("presenting annotation")
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("Annotation") as! AnnotationViewController
        viewController.alpha = 0.5
        presentViewController(viewController, animated: true, completion: nil)
    }
}
