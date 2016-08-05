//
//  GuestViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/8/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import Parse
import BFRadialWaveView
import NVActivityIndicatorView

class GuestViewController: UIViewController, MCNearbyServiceBrowserDelegate, MPCDelegate, SPTAudioStreamingPlaybackDelegate, UITableViewDelegate, UITableViewDataSource, SpotifyHandlerDelegate, NVActivityIndicatorViewable {

    // MARK: Properties

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    @IBOutlet weak var tableView: UITableView!
    var isSynced:Bool = false
    var stateChangeTime: Double!
    var elapsedTime: Double!
    var parseHost:PFUser!
    var currentGuest:PFUser = PFUser.currentUser()!

    let sync_constant:Double = 0.2

    //Queue track loading facilitator variables
    var currentParty: PFObject! //Same object as currentGuest above -- not properly set until Party.joinParty is called
    var playlistID: String?
    var queueTracks: [QueueTrack]?

    @IBOutlet weak var radialWaveView: BFRadialWaveView!
    var progress:CGFloat!

    // MARK: UIViewController Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        appDelegate.spotifyHandler.delegate = self
        appDelegate.mpcHandler.mpcDelegate = self //might be useless****

        //listen for this event (state change - connected, disconnected, etc) (received data) - register notifications with "name" and notify self using the "selector" method
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GuestViewController.peerChangedStateWithNotification(_:)), name: "MPC_DidChangeStateNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GuestViewController.handleReceivedDataWithNotification(_:)), name: "MPC_DidReceiveDataNotification", object: nil)

        appDelegate.spotifyHandler.setupSpotifyPlayer()
        appDelegate.spotifyHandler.loginSpotify()
    }
    override func viewWillAppear(animated: Bool) {
        print("Guest: view will appear")

        setUpRadial()

        appDelegate.mpcHandler.foundPeers = []
        tableView.reloadData()

        appDelegate.mpcHandler.guestBrowser = MCNearbyServiceBrowser(peer: appDelegate.mpcHandler.peerID, serviceType: "in-sync")
        appDelegate.mpcHandler.guestBrowser!.delegate = self
        appDelegate.mpcHandler.guestBrowser!.startBrowsingForPeers()
        print("Guest: browser initiated")

        //        appDelegate.spotifyHandler.setupSpotifyPlayer()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    // MARK: Connecting to Peer

    /*
     Method for recognizing when a peer has changed state (ex: from not connected to connecting to connected)
     - parameter notification
     */
    func peerChangedStateWithNotification(notification: NSNotification) {
        print("Guest: peer change state CALLED in GENERAL")
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let state = userInfo.objectForKey("state") as! Int

        if state == MCSessionState.Connected.rawValue && !isSynced {
            print("Guest: peer state change CALLED signaling CONNECTION")
            stateChangeTime = CACurrentMediaTime()
            print("state time: \(stateChangeTime)")
        }
        if state == MCSessionState.NotConnected.rawValue {
            leaveParty()
        }
        tableView.reloadData()
    }


    //MARK: Data Transmission

    /*
     Method for recognizing when data has been received and handling the data
     - parameter notification
     */
    func handleReceivedDataWithNotification(notification:NSNotification) {
        let userInfo = notification.userInfo! as Dictionary
        let receivedData:NSData = userInfo["data"] as! NSData
        //            let senderPeerID:MCPeerID = userInfo["peerID"] as! MCPeerID
        //            let senderDisplayName = senderPeerID.displayName
        let receivedString = String(data: receivedData, encoding: NSUTF8StringEncoding)
        print("received string: \(receivedString)")

        if receivedString == "end-session-key" {
            print("party ended")
            NSNotificationCenter.defaultCenter().postNotificationName("PartyDidEnd", object: nil, userInfo: nil)
            leaveParty()

        } else if receivedString == "play-pause-key" {
            if (appDelegate.spotifyHandler.player?.isPlaying == true) {
                self.appDelegate.spotifyHandler.player?.setIsPlaying(false, callback: { (error:NSError!) in
                    if error != nil {
                        print("Guest: error pausing")
                    } else {
                        print("Guest: paused")
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            NSNotificationCenter.defaultCenter().postNotificationName("DidPlayPause", object: nil, userInfo: nil)
                        })
                    }
                })
            } else {
                appDelegate.spotifyHandler.player?.setIsPlaying(true, callback: { (error: NSError!) in
                    if error != nil {
                        print("Guest: error playing after pause")
                    } else {
                        print("Guest: played after pausing")
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            NSNotificationCenter.defaultCenter().postNotificationName("DidPlayPause", object: nil, userInfo: nil)
                        })
                    }
                })
            }
        } else if receivedString == "queue-key" {
            print("GUEST RECEIVED QUEUE KEY")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("UpDownVoted", object: nil, userInfo: nil)
                print("received key, sent refresh queue notification")
            })

        } else if let litness = Int(receivedString!) {
            print("guest received final litness")
            SpotifyClient.CURRENT_USER.previousLitness = litness
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("CalculatedFinalLitness", object: nil, userInfo: nil)
                print("guest sent self litness notif")
            })
        } else if let offset = Double(receivedString!) {
            print("Guest: initial offset \(offset)")
            if !self.isSynced {
                //Load the Queue Tracks before the Now Playing page loads
//                let size = CGSize(width: 30, height:30)
//                startActivityAnimating(size, message: "Connecting...", type: NVActivityIndicatorType.AudioEqualizer, color: UIColor.whiteColor())

                loadQueueTracksEarly { () in
                    //Queue tracks set
                    print("Queue tracks properly created, ready for segue")

                    self.elapsedTime = CACurrentMediaTime() - self.stateChangeTime
                    print("Guest: elapsed time \(self.elapsedTime)")
                    let finalOffset = offset + self.elapsedTime
                    print("Guest: final offset: \(finalOffset)")
                    self.appDelegate.mpcHandler.firstOffset = finalOffset
                    self.appDelegate.spotifyHandler.initialGuestPlayTrack(finalOffset)

                    //Stop loading indicator
                    self.stopActivityAnimating()

                    self.performSegueWithIdentifier("JoinedPartySegue", sender: nil)
                    self.isSynced = true
                }
            } else {
                let finalOffset = offset + self.sync_constant
                print("Guest: final offset: \(finalOffset)")
                self.appDelegate.spotifyHandler.receiveOffset(finalOffset)
            }
        } else if receivedString == "message-key" {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("DataDidChange", object: nil, userInfo: nil)
                print("sent message notif")
            })
//        } else if receivedString == "litness-key" {
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                NSNotificationCenter.defaultCenter().postNotificationName("CalculatedLitness", object: nil, userInfo: nil)
//                print("sent litness notif")
//            })
        } else {
            print("playNextTrack with received uri will be called")
            notifySongChange()
            appDelegate.spotifyHandler.guestPlayNextTrack(receivedString!)
        }
    }

    /* Functions to looad the queue tracks early
     *
     */

    func loadQueueTracksEarly(completion: Void -> Void) {


        let currentPlaylist = Party.getCurrentPlaylist(currentParty)

        self.playlistID = currentPlaylist.objectId
        currentPlaylist.fetchInBackgroundWithBlock { (fetchPlaylist:PFObject?, error:NSError?) in
            if error == nil {
                self.playlistID = fetchPlaylist!.objectId

                var tracksArray = fetchPlaylist!["tracks"] as! [PFObject]

                print("THE TRACKS ARRAY RETRIEVED WHEN LOADING: \n ")
                for track in tracksArray {
                    print(track)
                    //print("\(track["name"] as! String)")
                }

                //When a guest joins, the first track has been removed by the guest and Parse is accurate
                //tracksArray.removeAtIndex(0)

                //Use QueueTrack objects
                self.queueTracks = [QueueTrack]()
                print("< ------ LOADING QUEUE TRACKS IN NAME PARTY SCREEN ------- >")
                //print("The new tracks are being SET UP and INITIALIZED... the tracks array contains \(tracksArray.count) PFObjects and is: \n ")


                self.loadParseTracks(tracksArray, queueTrackCompletion: { (queue) in
                    self.queueTracks = queue
                    completion()
                })


            } else {
                print("error fetching currentPlaylist in setuptable in HostViewController VC")
            }

        } // End fetch block
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
            var newQueue = queue as! [QueueTrack]

            queueTrackCompletion(newQueue)
        }
    }



    // MARK: Leaving Choose Party Scene

    @IBAction func onCancelButton(sender: UIButton) {
        isSynced = false
        appDelegate.mpcHandler.guestBrowser?.stopBrowsingForPeers()
        self.performSegueWithIdentifier("guestLeavesSegue", sender: nil)
    }

    // MARK: Leaving Party

    func leaveParty() {
        appDelegate.mpcHandler.session.disconnect()
        isSynced = false
        appDelegate.mpcHandler.guestBrowser?.stopBrowsingForPeers()
        print("Guest: left session and stopped browsing")
        Party.leaveParty(PFUser.currentUser()!["party"] as! PFObject, currentUser: PFUser.currentUser()!)
        appDelegate.spotifyHandler.player?.logout({ (error: NSError!) in
            if error != nil {
                print("Guest: error logging out: \(error.localizedDescription)")
            } else {
               // self.performSegueWithIdentifier("guestLeavesPartySegue", sender: nil)
            }
        })
    }


    // MARK: MCNearbyServiceBrowserDelegate

    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        appDelegate.mpcHandler.foundPeers.append(peerID)
        print("Guest: found peer (host)")
        tableView.reloadData()
    }
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        for (index, aPeer) in appDelegate.mpcHandler.foundPeers.enumerate(){
            print("Guest: lost peer (host)")
            if aPeer == peerID {
                appDelegate.mpcHandler.foundPeers.removeAtIndex(index)
                break
            }
        }
        tableView.reloadData()
    }
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print("Guest: error browsing for peers: \(error.localizedDescription)")
    }


    // MARK: MPCGuestDelegate - might delete this later

    /*
     Method to handle when device is connected to another peer
     - parameter peerID: the peerID of the nearby peer the device connected to
     */
    func connectedWithPeer(peerID: MCPeerID) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            print("CONNECTED WITH PEER")
        }
    }


    // MARK: TableView Delegate/DataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let foundCount = appDelegate.mpcHandler.foundPeers.count
        print("Guest count: \(foundCount)")
        return appDelegate.mpcHandler.foundPeers.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FoundPeersCell") as! FoundPeersCell
        let foundPeer = appDelegate.mpcHandler.foundPeers[indexPath.row]
        cell.foundPeersLabel.text = "\(foundPeer.displayName)'s Party"

        User.getParseUser(foundPeer.displayName) { (peer) in
            let profileImageURL = peer["profileImageUrl"] as! String
            if profileImageURL != "" {
                cell.foundPeersImageView.imageFromUrl(profileImageURL)
                cell.foundPeersImageView.layer.cornerRadius = cell.foundPeersImageView.frame.size.width / 2
                cell.foundPeersImageView.layer.masksToBounds = true
                cell.foundPeersImageView.layer.borderWidth = 0
                cell.foundPeersImageView.clipsToBounds = true

            }
        }
        return cell
    }


    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70.0
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let currentHost = appDelegate.mpcHandler.foundPeers[indexPath.row] as MCPeerID
        appDelegate.mpcHandler.currentHost = currentHost
        User.getParseUser(currentHost.displayName) { (parseHost: PFUser) in
            print("Parse host retrieved \(parseHost.username!)")

            self.parseHost = parseHost

            let size = CGSize(width: 30, height:30)
            self.startActivityAnimating(size, message: "Connecting...", type: NVActivityIndicatorType.AudioEqualizer, color: UIColor.whiteColor())

            Party.joinParty(parseHost["party"] as! PFObject, currentUser: self.currentGuest, completion: { (party: PFObject) in
                print("Guest: joined party \(party)")
                
                //Ensure the guest mobile device is not considered a host when deciding to add a track
                TrackAdder.hostInitialSelection = false
                
                self.currentParty = self.currentGuest["party"] as! PFObject
                self.appDelegate.mpcHandler.guestBrowser?.invitePeer(currentHost, toSession: self.appDelegate.mpcHandler.session!, withContext: nil, timeout: 30)
                print("Guest: sent invite/request to host")
            })
        }
    }


    // MARK: AudioStreaming Methods

    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: NSURL!) {
        print("Guest: StoppedPlayingTrack")
    }

    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: NSURL!) {
        // Deprecated - Used for testing purposes only. ************************************************
        // Track Info
        let trackName = audioStreaming.currentTrackMetadata[SPTAudioStreamingMetadataTrackName] as! String
        let trackAlbum = audioStreaming.currentTrackMetadata[SPTAudioStreamingMetadataAlbumName] as! String
        let trackArtist = audioStreaming.currentTrackMetadata[SPTAudioStreamingMetadataArtistName] as! String
        //**********************************************************************************************
        print("Guest: started playing \(trackName) in album \(trackAlbum) by \(trackArtist)")
        let currentUser = PFUser.currentUser()
        let currentParty = currentUser!["party"] as! PFObject
        SpotifyClient.CURRENT_USER.previousTrack = currentParty["now_playing"] as? PFObject
        print("Guest previous track is now:")
        print(SpotifyClient.CURRENT_USER.previousTrack)
    }
    func audioStreamingDidBecomeActivePlaybackDevice(audioStreaming: SPTAudioStreamingController!) {
        print("Guest: ActivePlaybackDevice")
    }


    // MARK: Radial Animation

    func setUpRadial() {
        progress = 0
        radialWaveView.setupWithView(self.view, circles: 20, color: UIColor.init(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 1.0), mode: BFRadialWaveViewMode.Default, strokeWidth: 2, withGradient: false)
        radialWaveView.show()
    }

    // MARK: Navigation

    func notifySongChange() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("SongDidChange", object: nil, userInfo: nil)
            print("sent song change notif")
        })
    }

    func notifyPartyStateChange() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("PartyStateChange", object: nil, userInfo: nil)
            print("sent data change notif")
        })
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let playVC = segue.destinationViewController as? TestSwipeViewController {
            playVC.isGuest = true
            appDelegate.mpcHandler.isGuest = true
            playVC.queueTracks = self.queueTracks!
        }
    }
}
