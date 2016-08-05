//
//  HostViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/11/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import Parse
import EZSwipeController
import Toast_Swift
import NVActivityIndicatorView

class HostViewController: UIViewController, MCNearbyServiceAdvertiserDelegate, SPTAudioStreamingPlaybackDelegate, SpotifyHandlerDelegate, MPCDelegate, NVActivityIndicatorViewable {
    
    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var invitationHandler: ((Bool, MCSession) -> Void)!
    var spotifyHandler:SpotifyHandler!
    
    @IBOutlet weak var partyNameLabel: UITextField!
    var partyName:String!
    var guestLitnessCount = 1
    var currentLitness = 0
    var guestsCount = 1
    let currentHost = PFUser.currentUser()
    let currentHostName = PFUser.currentUser()!["fullName"] as! String
    
    //Queue track loading facillitator variables
    let currentParty = PFUser.currentUser()!["party"] as! PFObject
    var playlistID: String?
    var queueTracks: [QueueTrack]?
    
    @IBOutlet weak var startBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var startPartyButton: UIButton!
    
    // MARK: UIViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        appDelegate.spotifyHandler.delegate = self
        appDelegate.mpcHandler.mpcDelegate = self
        
        //listen for this event (state change - connected, disconnected, etc) (received data)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostViewController.peerChangedStateWithNotification(_:)), name: "MPC_DidChangeStateNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostViewController.handleReceivedDataWithNotification(_:)), name: "MPC_DidReceiveDataNotification", object: nil)
        
        appDelegate.spotifyHandler.setupSpotifyPlayer()
        appDelegate.spotifyHandler.loginSpotify()
        
        partyNameLabel.attributedPlaceholder = NSAttributedString(string: "\(currentHostName)'s Party", attributes: [NSForegroundColorAttributeName:UIColor.whiteColor().colorWithAlphaComponent(0.4)])
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        
        //Load the Queue Tracks before the Now Playing page loads
        let size = CGSize(width: 30, height:30)
        startActivityAnimating(size, message: "Loading...", type: NVActivityIndicatorType.AudioEqualizer, color: UIColor.whiteColor())
        
        loadQueueTracksEarly { () in
            //Queue tracks set
            print("Queue tracks properly created, ready for segue")
            self.stopActivityAnimating()
        }
        
    }
    
    
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
                
                //The first track is removed later on in program execution, so remove the first track as the Now Playing track now
                tracksArray.removeAtIndex(0)
                
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
    
    
    
    
    // MARK: Keyboard Methods
    
    @IBAction func onTapOutside(sender: AnyObject) {
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification!) {
        print("keyboard shown")
        let info = notification.userInfo
        let keyboardFrame = info![UIKeyboardFrameEndUserInfoKey]?.CGRectValue()
        let keyboardHeight = keyboardFrame?.size.height
        startBottomConstraint.constant = keyboardHeight!
        view.layoutIfNeeded()
    }
    func keyboardWillHide(notification: NSNotification!) {
        startBottomConstraint.constant = 0
        view.layoutIfNeeded()
    }
    
    // MARK: Connecting to Peer
    
    func peerChangedStateWithNotification(notification:NSNotification) {
        print("Host: peer state change CALLED in GENERAL")
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let state = userInfo.objectForKey("state") as! Int
        let changedPeer = [userInfo.objectForKey("peerID") as! MCPeerID]
        
        if state == MCSessionState.Connected.rawValue {
            //            print("Host: peer state change CALLED signaling CONNECTION")
        }
    }
    func connectedWithPeer(peerID: MCPeerID) {
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            print("CONNECTED WITH PEER")
            SpotifyClient.CURRENT_USER.lastGuestName = peerID.displayName
            NSNotificationCenter.defaultCenter().postNotificationName("New Peer", object: nil, userInfo: nil)
            //print("\(peerID.displayName) just joined your party!")
            let sentPeer = [peerID]
            self.guestsCount += 1
            //try below
            self.sendOffsetData(sentPeer)
        }
    }
    
    // MARK: Handling Data
    
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
    func handleReceivedDataWithNotification(notification:NSNotification) {
        let userInfo = notification.userInfo! as Dictionary
        let receivedData:NSData = userInfo["data"] as! NSData
        let receivedString = String(data: receivedData, encoding: NSUTF8StringEncoding)
        let receivedString2 = NSString(data: receivedData, encoding: NSUTF8StringEncoding)
        let fromPeer:[MCPeerID] = [userInfo["peerID"] as! MCPeerID]
        appDelegate.mpcHandler.fromPeer = fromPeer
        if NSString(data: receivedData, encoding: NSUTF8StringEncoding) == "resync" {
            print("Host: received re-sync request from guest")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("ResyncRequest", object: nil, userInfo: nil)
                print("received key, sent resync request notification")
            })
//            let alert = UIAlertController(title: "Re-sync Request", message: "\(fromPeer) requests a re-sync.", preferredStyle: UIAlertControllerStyle.Alert)
//            let acceptAction: UIAlertAction = UIAlertAction(title: "Re-Sync", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
//                self.sendOffsetData(fromPeer)
//            }
//            let declineAction = UIAlertAction(title: "Ignore", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
//            }
//            alert.addAction(acceptAction)
//            alert.addAction(declineAction)
//            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
//                self.presentViewController(alert, animated: true, completion: nil)
//            }
        } else if receivedString == "queue-key" {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("UpDownVoted", object: nil, userInfo: nil)
                print("received key, sent refresh queue notification")
            })
        } else if NSString(data: receivedData, encoding: NSUTF8StringEncoding) == "message-key" {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("DataDidChange", object: nil, userInfo: nil)
                print("sent message notif")
            })
            //     } else if let guestLitness = Int(receivedString!) {
            //} else if (receivedString2?.characterAtIndex(0) == unichar("L")) {
        } else {
            currentLitness = SpotifyClient.CURRENT_USER.personalLitness!
            print("host received litness")
            print("\(receivedString)")
            let guestLitness = Int(receivedString!)
            print("guest litness is: \(guestLitness!)")
            currentLitness += guestLitness!
            guestLitnessCount += 1
            
            if (guestLitnessCount == guestsCount) {
                print("finished collecting values")
                self.notifyCalculateLitness()
                self.currentLitness = SpotifyClient.CURRENT_USER.personalLitness!
                self.guestLitnessCount = 1
            }
            
            NSNotificationCenter.defaultCenter().postNotificationName("CalculatedLitness", object: nil, userInfo: nil)
            print("sent self litness notif")
        }
    }
    
    func notifyCalculateLitness() {
        let avgLitness = currentLitness / guestLitnessCount
        print("total is: \(currentLitness)")
        print("count is: \(guestLitnessCount)")
        print("average is: \(avgLitness)")
        //currentLitness = SpotifyClient.CURRENT_USER.personalLitness!
        //guestLitnessCount = 0
        let prevTrack = SpotifyClient.CURRENT_USER.previousTrack
        prevTrack!["litness"] = avgLitness
        
        prevTrack?.saveInBackgroundWithBlock({ (success, error: NSError?) in
            //dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let litness = "\(avgLitness)"
            let litnessData = litness.dataUsingEncoding(NSUTF8StringEncoding)
            do {
                try self.appDelegate.mpcHandler.session.sendData(litnessData!, toPeers: self.appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
                print("sent litness notif")
            } catch {
                print("Error sending litness notif")
            }
            NSNotificationCenter.defaultCenter().postNotificationName("CalculatedFinalLitness", object: nil, userInfo: nil)
                print("sent self litness notif")
            })
        //})
    }
    
    // MARK: MCNearbyServiceAdvertiser Delegate
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        self.invitationHandler = invitationHandler
        self.invitationHandler(true, self.appDelegate.mpcHandler.session)
        print("Host: received and accepted invite")
    }
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print("Host: error advertising: \(error.localizedDescription)")
    }
    
    // MARK: AudioStreaming Methods
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: NSURL!) {
        print("Host: StoppedPlayingTrack")
        hostPlaySendTrack(PFUser.currentUser()!["party"] as! PFObject) {
            print("Host: finished calling hostPlaySendTrack")
        }
        
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: NSURL!) {
        // Deprecated - Used for testing purposes only. ************************************************
        // Track Info
        let trackName = audioStreaming.currentTrackMetadata[SPTAudioStreamingMetadataTrackName] as! String
        let trackAlbum = audioStreaming.currentTrackMetadata[SPTAudioStreamingMetadataAlbumName] as! String
        let trackArtist = audioStreaming.currentTrackMetadata[SPTAudioStreamingMetadataArtistName] as! String
        // **********************************************************************************************
        print("Host: Started playing \(trackName) in album \(trackAlbum) by \(trackArtist)")
    }
    func audioStreamingDidBecomeActivePlaybackDevice(audioStreaming: SPTAudioStreamingController!) {
        print("Host: ActivePlaybackDevice")
    }
    
    func notifySongChange() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("SongDidChange", object: nil, userInfo: nil)
            print("sent song change notif")
        })
    }
    
    func notifyQueueChange() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("QueueUpdate", object: nil, userInfo: nil)
            print("sent QueueUpdate ready for update notif")
        })
    }
    
    func notifyHeaderChange() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("HeaderUpdate", object: nil, userInfo: nil)
            print("sent HeaderUpdate ready for update notif")
        })
    }
    
    // MARK: Navigation
    
    @IBAction func onStartPartyButton(sender: UIButton) {
        if partyNameLabel.text != "" {
            partyName = partyNameLabel.text
        } else {
            //let myUsername = appDelegate.mpcHandler.peerID.displayName
            partyName = currentHostName + "'s Party"
        }
        let currentParty = PFUser.currentUser()!["party"] as! PFObject
        currentParty["name"] = partyName
        currentParty.saveInBackgroundWithBlock { (success:Bool, error:NSError?) in
            if error == nil {
                self.hostPlaySendTrack(PFUser.currentUser()!["party"] as! PFObject) {
                    print("Host: playing track")
                    self.performSegueWithIdentifier("hostSwipeSegue", sender: nil)
                    self.appDelegate.mpcHandler.hostAdvertiser = MCNearbyServiceAdvertiser(peer: self.appDelegate.mpcHandler.peerID, discoveryInfo: nil, serviceType: "in-sync")
                    self.appDelegate.mpcHandler.hostAdvertiser!.delegate = self
                    self.appDelegate.mpcHandler.hostAdvertiser!.startAdvertisingPeer()
                    print("Host: started advertising")
                    NSNotificationCenter.defaultCenter().postNotificationName("Started Party", object: nil, userInfo: nil)
                }
            } else {
                print("error saving party name: \(error)")
            }
        }
    }
    
    func sendQueueKey() {
        let key = "queue-key"
        let keyData = key.dataUsingEncoding(NSUTF8StringEncoding)
        do {
            try appDelegate.mpcHandler.session.sendData(keyData!, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
            print("NewQueueVC sent signal to refresh queue through session")
        } catch {
            print("NewQueueVC: error sending refresh queue signal")
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let playVC = segue.destinationViewController as? TestSwipeViewController {
            playVC.isGuest = false
            appDelegate.mpcHandler.isGuest = false
            playVC.queueTracks = self.queueTracks!
        }
    }
    
    // MARK: Playing Track
    
    func hostPlaySendTrack(party: PFObject, withCompletion completion: () -> Void) {
        print("called hostPlaySendTrack")
        let hostPlayGroup = dispatch_group_create()
        print("created host play group")
        var tracksArray:[PFObject]!
        dispatch_group_enter(hostPlayGroup)
        print("entered dispatch group")
        let currentPlaylist = Party.getCurrentPlaylist(PFUser.currentUser()!["party"] as! PFObject)
        print("about to fetch tracks")
        currentPlaylist.fetchInBackgroundWithBlock { (fetchPlaylist:PFObject?, error:NSError?) in
            if error != nil {
                print("error fetching currentplaylist in hostplaysendtrack")
            } else {
                
                tracksArray = fetchPlaylist!["tracks"] as! [PFObject]
                print("fetched tracks")
                dispatch_group_leave(hostPlayGroup)
                print("left dispatch group")
            }
        }
        dispatch_group_enter(hostPlayGroup)
        party.fetchInBackgroundWithBlock({ (party:PFObject?, error:NSError?) in
            if error != nil {
                print("Error fetching currentParty in hostPlaySendTrack")
            } else {
                dispatch_group_leave(hostPlayGroup)
            }
        })
        dispatch_group_notify(hostPlayGroup, dispatch_get_main_queue()) {
            if tracksArray.isEmpty {
                //When tracksArray is empty, just keep playing the last song playednow
                
                let nowPlayingTrack = party["now_playing"] as! PFObject
                self.notifySongChange() //why here?
                
                //print("Got first track: \(nowPlayingTrack)")
                let nowPlayingURI = nowPlayingTrack["uri"] as! String
                
                if self.appDelegate.mpcHandler.session.connectedPeers.isEmpty == false {
                    let nextURIData = nowPlayingURI.dataUsingEncoding(NSUTF8StringEncoding)
                    do {
                        try self.appDelegate.mpcHandler.session.sendData(nextURIData!, toPeers: self.appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
                    } catch {
                        print("Error sending next track to guest")
                    }
                }
                let uriArray = [NSURL(string:nowPlayingURI)!] as [AnyObject]
                let playOptions = SPTPlayOptions()
                self.appDelegate.spotifyHandler.player!.playURIs(uriArray, withOptions: playOptions, callback: { (error:NSError!) in
                    if error != nil {
                        print("Error playing first track \(error)")
                    } else {
                        print("Started playing first track")
                        completion()
                    }
                })
            } else {
                let group = dispatch_group_create()
                let nextTrack = tracksArray[0]
                var previousPlaylist = party["previousPlaylist"] as! [PFObject]
                
                //print("Host: got next track: \(nextTrack)")
                
                if let prevTrack = party["now_playing"] as? PFObject {
                    previousPlaylist.append(prevTrack)
                    //prevTrack.incrementKey("playedCount")
                    party.setObject(previousPlaylist, forKey: "previousPlaylist")
                    SpotifyClient.CURRENT_USER.previousTrack = prevTrack
                    //prevTrack.deleteInBackground()
                }
                
                dispatch_group_enter(group)
                party["now_playing"] = nextTrack
                party.saveInBackgroundWithBlock({ (success:Bool, error:NSError?) in
                    if error != nil {
                        print("Error saving party: \(error?.localizedDescription)")
                    } else {
                        print("saved next track as now playing")
                        
                        //Is there a necessity to notify the queue of song change here? --possible source of bug
                        if (self.guestsCount == 1 && SpotifyClient.CURRENT_USER.previousTrack != nil) {
                            self.notifyCalculateLitness()
                        }
                        self.notifySongChange()
                        self.notifyHeaderChange()
                        dispatch_group_leave(group)
                    }
                })
                dispatch_group_notify(group, dispatch_get_main_queue(), {
                    //                dispatch_group_enter(group)
                    let nextURI = nextTrack["uri"] as! String
                    if self.appDelegate.mpcHandler.session.connectedPeers.isEmpty == false {
                        let nextURIData = nextURI.dataUsingEncoding(NSUTF8StringEncoding)
                        do {
                            try self.appDelegate.mpcHandler.session.sendData(nextURIData!, toPeers: self.appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
                        } catch {
                            print("Error sending next track to guest")
                        }
                    }
                    let uriArray = [NSURL(string:nextURI)!] as [AnyObject]
                    let playOptions = SPTPlayOptions()
                    print("About to playURIs")
                    self.appDelegate.spotifyHandler.player!.playURIs(uriArray, withOptions: playOptions, callback: { (error:NSError!) in
                        if error != nil {
                            print("Error playing next track \(error)")
                        } else {
                            //print("Started playing next track")
                            //                        dispatch_group_leave(group)
                            let removed = tracksArray.removeAtIndex(0)
                            print("Started playing next track, and removed track: \(removed["name"] as! String)")
                            currentPlaylist["tracks"] = tracksArray
                            currentPlaylist.saveInBackgroundWithBlock({ (success, error: NSError?) in
                                if error != nil {
                                    print ("Error saving playlist: \(error?.localizedDescription)")
                                } else {
                                    print("updated and saved playlist tracks array in hostPlaySendTrack")
                                    //Notify queue
                                    self.notifyQueueChange()
                                    
                                    //                                    self.sendQueueKey()
                                    
                                    party.saveInBackgroundWithBlock({ (success, error: NSError?) in
                                        if error == nil {
                                            print("Saved party with previous track")
                                            completion()
                                        } else {
                                            print("Error saving party: \(error?.localizedDescription)")
                                        }
                                    })
                                    // completion()
                                }
                            })
                        }
                    })
                })
            }
        }
    }
}