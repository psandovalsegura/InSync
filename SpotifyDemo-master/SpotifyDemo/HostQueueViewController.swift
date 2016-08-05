//
//  HostQueueViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/22/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import StretchHeader
import MNFloatingActionButton
import MultipeerConnectivity
import NVActivityIndicatorView
import BubbleTransition

class HostQueueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, NVActivityIndicatorViewable, UIViewControllerTransitioningDelegate {

    // MARK: Properties

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentHeaderView: UIView!

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    var header : StretchHeader!
    var navigationView = UIView()
    var playlistID: String?

    var upvotes = [String]() //Contains an array of parse object IDs, that the current user has upvoted
    var downvotes = [String]() //Contains an array of parse object IDs, that the current user has upvoted

    //Note: pass this in for the first time
    var tracks: [PFObject]?
    var queueTracks: [QueueTrack]?

    var initialSetup: Bool!

    //Images
    let upvotedImage = UIImage(named: "up-turquoise")
    let notUpvotedImage = UIImage(named: "up-gray")
    let downvotedImage = UIImage(named: "down-turquoise")
    let notDownvotedImage = UIImage(named: "down-gray")

    let currentUser = PFUser.currentUser()
    var headerView: UIView?
    let gradientLayer = CAGradientLayer()
    var gradientView:UIView?
    let currentParty = PFUser.currentUser()!["party"] as! PFObject

    var plusButton:MNFloatingActionButton = MNFloatingActionButton()

    // MARK: View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true

        self.setUpAddButton()
        setupHeaderView() {
            self.setUpTable(true, completion:  {
                self.tableView.delegate = self
                self.tableView.dataSource = self
                self.view.addSubview(self.tableView)

                print("ViewDidLoad ---> The Queue tracks are: \(self.queueTracks) and there are\(self.queueTracks!.count)")

                self.view.bringSubviewToFront(self.plusButton)
                UIApplication.sharedApplication().keyWindow!.bringSubviewToFront(self.plusButton)
            })
        }

//        let gradientView = UIView.init(frame: self.view.frame)
//        gradientLayer.frame = UIScreen.mainScreen().bounds
//        let clear = UIColor.clearColor().CGColor as CGColorRef
//        let black = UIColor.blackColor().CGColor as CGColorRef
//        gradientLayer.colors = [black, clear]
//        gradientLayer.locations = [0.0, 1.0]
//        gradientView.layer.addSublayer(self.gradientLayer)
//        self.view.addSubview(gradientView)
//        self.view.sendSubviewToBack(gradientView)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostQueueViewController.hardRefresh), name: "QueueUpdate", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostQueueViewController.hardRefresh), name: "UpDownVoted", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostQueueViewController.hardRefresh), name: "DidAddTrack", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostNowPlayingViewController.displayNewPeer), name: "New Peer", object: nil)

        //NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(NewQueueViewController.onTimer), userInfo: nil, repeats: true)
    }

    // MARK: Notification

    func displayNewPeer() {
        self.view.makeToast("\(SpotifyClient.CURRENT_USER.lastGuestName!) just joined your party!", duration: 3.0, position: .Top)
    }

    // MARK: Queue Set-up
    func setUpTable(hardReset: Bool, completion: () -> Void) {
        //If this is the first time the controller loads, queueTracks are loaded
        if (initialSetup != nil) && initialSetup {
            completion()
            self.initialSetup = false
            return
        }

        //populate array
        let currentPlaylist = Party.getCurrentPlaylist(currentParty)

        self.playlistID = currentPlaylist.objectId
        currentPlaylist.fetchInBackgroundWithBlock { (fetchPlaylist:PFObject?, error:NSError?) in
            if error == nil {
                self.playlistID = fetchPlaylist!.objectId

                let tracksArray = fetchPlaylist!["tracks"] as! [PFObject]

                print("THE TRACKS ARRAY RETRIEVED WHEN TABLE SET UP IS: \n ")
                for track in tracksArray {
                    print(track)
                    //print("\(track["name"] as! String)")
                }
                if hardReset {
                    self.tracks = tracksArray

                    //Use QueueTrack objects
                    self.queueTracks = [QueueTrack]()
                    print("< ------ HARD RESET ------- >")
                    //print("The new tracks are being SET UP and INITIALIZED... the tracks array contains \(tracksArray.count) PFObjects and is: \n ")


                    self.loadParseTracks(tracksArray, queueTrackCompletion: { (queue) in
                        self.queueTracks = queue
                        self.checkForRearrangement()
                        completion()
                    })
                } else {
                    //If not a hard reset
                    print("< ------ REGULAR RESET ------- >")

                    if (self.tracks != nil && self.tracks! == tracksArray) {
                        print("The tracks FETCHED were the SAME") //Do nothing
                        completion()
                    } else {
                        print("The tracks FETCHED were the DIFFERENT")

                        self.tracks = tracksArray


                        self.loadParseTracks(tracksArray, queueTrackCompletion: { (queue) in
                            self.queueTracks = queue
                            self.checkForRearrangement()
                            completion()
                        })
                    }
                }
            } else {
                print("error fetching currentPlaylist in setuptable in newqueue vc")
            }
        }
    }

    func loadParseTracks(parseTracks: [PFObject], queueTrackCompletion: ([QueueTrack]) -> Void) {

        let amountOfParseTracks = parseTracks.count
        var queue = [QueueTrack!](count: amountOfParseTracks, repeatedValue: nil)

        //Start a dispatch
        let queueTrackCreation = dispatch_group_create()

        for (index, track) in parseTracks.enumerate() {
            //Ensure the tracks are added in the correct order

            dispatch_group_enter(queueTrackCreation)
            QueueTrack(parseTrack: track, completion: { (queueTrack) in
                queue[index] = queueTrack
                dispatch_group_leave(queueTrackCreation)
            })
        }

        dispatch_group_notify(queueTrackCreation, dispatch_get_main_queue()) {
            print("-------------------------> \(queue.count) Queue Tracks were created")
            let newQueue = queue as! [QueueTrack]
            queueTrackCompletion(newQueue)
        }
    }

    func setupHeaderView(setupCompletionHandler: Void -> Void) {
        currentParty.fetchInBackgroundWithBlock({ (fetchParty:PFObject?, error:NSError?) in
            if error == nil {

                let options = StretchHeaderOptions()
                options.position = .FullScreenTop
                self.header = StretchHeader()

                self.header.stretchHeaderSize(headerSize: CGSizeMake(self.view.frame.size.width, 220),
                    imageSize: CGSizeMake(self.view.frame.size.width, 220),
                    controller: self,
                    options: options)
                self.tableView.tableHeaderView = self.header

                let firstSongLabel = UILabel(frame: CGRectMake(8.0, 28.0, self.view.frame.width - 24.0, 24.0))
                firstSongLabel.textAlignment = NSTextAlignment.Left
                firstSongLabel.font = UIFont(name: "Avenir-Medium", size: 17.0)
                firstSongLabel.textColor = UIColor.whiteColor()

                let firstArtistLabel = UILabel(frame: CGRectMake(8.0, 28.0 + 24.0, self.view.frame.width - 24.0, 24.0))
                firstArtistLabel.textAlignment = NSTextAlignment.Left
                firstArtistLabel.font = UIFont(name: "Avenir-Book", size: 13.0)
                firstArtistLabel.textColor = UIColor.init(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 1.0)

                let nowPlayingSong = fetchParty!["now_playing"] as? PFObject
                nowPlayingSong?.fetchIfNeededInBackgroundWithBlock({ (nowplayingSong:PFObject?, error:NSError?) in
                    print("SetUpHeader ---->  nowplaying song in newqueue setupheaderview fetched")
                    self.header.imageView.imageFromUrl((nowplayingSong!["albumImageURL"] as? String)!)
                    self.header.imageView.backgroundColor = UIColor.blackColor()

                    firstSongLabel.text = nowplayingSong!["name"] as? String
                    self.header.addSubview(firstSongLabel)
                    firstArtistLabel.text = nowplayingSong!["artist"] as? String
                    self.header.addSubview(firstArtistLabel)
                    setupCompletionHandler()
                })
            } else {
                print("Error fetching currentparty in setupHeaderView in newqueue vc")
            }
        })
    }

    // MARK: Table View

    func scrollViewDidScroll(scrollView: UIScrollView) {
        header.updateScrollViewOffset(scrollView)
        // NavigationHeader alpha update
        let offset : CGFloat = scrollView.contentOffset.y
        if (offset > 50) {
            let alpha : CGFloat = min(CGFloat(1), CGFloat(1) - (CGFloat(50) + (navigationView.frame.height) - offset) / (navigationView.frame.height))
            navigationView.alpha = CGFloat(alpha)
        } else {
            navigationView.alpha = 0.0;
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("queueCell", forIndexPath: indexPath) as! QueueTableViewCell

        let track = self.queueTracks![indexPath.row]

        cell.songNameLabel.text = track.name!
        cell.artistNameLabel.text = track.artist!
        cell.votesCountLabel.text = String(track.votes)
        cell.selectionStyle = UITableViewCellSelectionStyle.None

        cell.votesCountLabel.text = String(track.votes!)

        //print("Attempting to set the image for \(track.name!) on the queue cell... where the image is \(track.albumImage)")
        if track.albumImage != nil {
            //print("For \(track.name!) the album image should display because it WAS PROPERLY SET")
            cell.albumCoverImageView.image = track.albumImage!
        }

        //Check if user has voted before
        if ((track.upvoted != nil) && track.upvoted!) || self.upvotes.contains((track.parseObject?.objectId)!) {
            //User has upvoted a track
            cell.upvoteButton.setImage(self.upvotedImage, forState: UIControlState.Normal)
            cell.downvoteButton.setImage(self.notDownvotedImage, forState: UIControlState.Normal)
        } else if ((track.downvoted != nil) && track.downvoted!) || self.downvotes.contains((track.parseObject?.objectId)!) {
            //User has downvoted
            cell.downvoteButton.setImage(self.downvotedImage, forState: UIControlState.Normal)
            cell.upvoteButton.setImage(self.notUpvotedImage, forState: UIControlState.Normal)
        } else {
            cell.downvoteButton.setImage(self.notDownvotedImage, forState: UIControlState.Normal)
            cell.upvoteButton.setImage(self.notUpvotedImage, forState: UIControlState.Normal)
        }
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !queueTracks!.isEmpty {
            print("There are \(self.queueTracks!.count) QUEUE TRACKS and they are listed below: ")
            for track in self.queueTracks! {
                //print(track.name!)
            }
            return self.queueTracks!.count
        } else { return 0 }
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 102
    }

    // MARK: Refresh

    //Replaces the entire queue with Parse track data only if the tracks are different
    /*
     func refresh() {
     print("REFRESH FUNCTION CALLED")
     setupHeaderView()
     setUpTable(false, completion:  {
     self.tableView.reloadData()
     })
     }*/

    //Replaces the entire queue with Parse track data, which includes party upvotes and downvotes
    func hardRefresh() {
        print("REFRESH HARD FUNCTION CALLED")

        let size = CGSize(width: 30, height:30)
        startActivityAnimating(size, message: "Loading...", type: NVActivityIndicatorType.AudioEqualizer, color: UIColor.whiteColor())

        setupHeaderView() {
            self.setUpTable(true, completion: {
                self.tableView.reloadData()
                self.stopActivityAnimating()
            })
        }
    }

    func sendRefreshData() {
        let key = "queue-key"
        let keyData = key.dataUsingEncoding(NSUTF8StringEncoding)
        do {
            try appDelegate.mpcHandler.session.sendData(keyData!, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
            print("NewQueueVC sent signal to refresh queue through session")
        } catch {
            print("NewQueueVC: error sending refresh queue signal")
        }
    }

    // MARK: Voting

    @IBAction func didTapUpvote(sender: AnyObject) {
        let buttonPosition: CGPoint = sender.convertPoint(CGPointZero, toView: self.tableView)
        let indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition)

        if (indexPath != nil) {

            //Update queue on device
            let queueTrack = self.queueTracks![(indexPath?.row)!]
            queueTrack.upvote()

            checkForRearrangement()

            Track.getTrackFromParty(currentParty, newTrack: queueTrack.parseObject!, completion: { (track) in
                User.getUpdatedParseUser(self.currentUser!, completion: { (user) in

                    let currentUpvotes = user["upvotes"] as! [String]

                    //If not already upvoted, upvote (included: if downvoted before, upvote twice)
                    //unset down button? -- make an outlet??

                    if (!currentUpvotes.contains(track.objectId!)) {
                        print("On UPVOTE TAP -- > track has not upvoted before")

                        //Add the track to the upvotes
                        self.upvotes.append((queueTrack.parseObject?.objectId)!)

                        Track.upvote(track, user: self.currentUser!, completion: {
                            self.setUpTable(false, completion: {
                                self.tableView.reloadData()

                                self.sendRefreshData()
                            })
                        })
                    } else {
                        print("On UPVOTE TAP -- > already upvoted")

                        //Remove the track from upvotes
                        self.upvotes = self.upvotes.filter() { $0 != queueTrack.parseObject?.objectId!}

                        Track.undoUpvote(track, user: self.currentUser!)
                        self.setUpTable(false, completion: {
                            self.tableView.reloadData()
                        })

                        self.sendRefreshData()
                    }
                })
            })
        }
    }

    @IBAction func didTapDownvote(sender: AnyObject) {
        let buttonPosition: CGPoint = sender.convertPoint(CGPointZero, toView: self.tableView)

        let indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition)

        if (indexPath != nil) {

            //Update queue on device
            let queueTrack = self.queueTracks![(indexPath?.row)!]
            queueTrack.downvote()
            checkForRearrangement()

            Track.getTrackFromParty(currentParty, newTrack: queueTrack.parseObject!, completion: { (track) in
                User.getUpdatedParseUser(self.currentUser!, completion: { (user) in
                    //let track = self.tracks![((indexPath?.row)!)]
                    let currentDownvotes = user["downvotes"] as! [String]

                    //If not already upvoted, upvote (included: if downvoted before, upvote twice)
                    //unset down button? -- make an outlet??

                    if (!currentDownvotes.contains(track.objectId!)) {

                        //Add the track to the downvotes
                        self.downvotes.append((queueTrack.parseObject?.objectId)!)

                        print("not downvoted")
                        print(track)
                        Track.downvote(track, user: self.currentUser!, completion: {
                            self.setUpTable(false, completion: {
                                self.tableView.reloadData()
                            })
                            //self.checkForRearrangement()
                        })
                    } else {
                        print("already downvoted")

                        //Remove the track from downvotes
                        self.downvotes = self.downvotes.filter() { $0 != queueTrack.parseObject?.objectId!}

                        Track.undoDownvote(track, user: self.currentUser!)

                        self.setUpTable(false, completion: {
                            self.tableView.reloadData()
                        })
                        //self.checkForRearrangement()
                    }
                })
                self.sendRefreshData()
            })
        }
    }

    func checkForRearrangement() {
        let rearrangedQueue = self.queueTracks!.sort({ $0.votes > $1.votes })

        if rearrangedQueue == self.queueTracks! {
            print("CheckForRearrangement ---> REARRANGING... the queue's are the SAME")

        } else {
            print("CheckForRearrangement ---> REARRANGING... the queue's are DIFFERENT")
            self.queueTracks = rearrangedQueue

            UIView.transitionWithView(tableView,
                                      duration: 0.20,
                                      options: .TransitionCrossDissolve,
                                      animations:
                { () -> Void in
                    self.tableView.reloadData()
                },
                                      completion: nil);
        }

    }

    //Testing functions
    func updateHeader() {
        self.setupHeaderView { () in
            //
        }
    }

    func updateQueue() {
        self.setUpTable(true) {
            //
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    // MARK: Floating Add Button

    func setUpAddButton() {
        let size = CGFloat(48)
        plusButton = MNFloatingActionButton.init(frame: CGRectMake(self.view.frame.size.width/2 - size/2, self.view.bounds.height - 60.0, size, size))
        plusButton.backgroundColor = UIColor.init(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 0.85)
        plusButton.shadowColor = UIColor.blackColor()
        plusButton.shadowRadius = 1.8

        plusButton.addTarget(self, action: #selector(HostQueueViewController.onAddButton), forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(plusButton)
        //        self.view.bringSubviewToFront(plusButton)
        UIApplication.sharedApplication().keyWindow!.bringSubviewToFront(plusButton)
    }
    func onAddButton() {
        super.performSegueWithIdentifier("hostSongSelectionSegue", sender: nil)
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
