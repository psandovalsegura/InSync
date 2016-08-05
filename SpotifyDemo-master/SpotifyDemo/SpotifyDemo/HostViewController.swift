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

class HostViewController: UIViewController, MCNearbyServiceAdvertiserDelegate, SPTAudioStreamingPlaybackDelegate, SpotifyHandlerDelegate, MPCDelegate {
    
    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var invitationHandler: ((Bool, MCSession) -> Void)!
    var spotifyHandler:SpotifyHandler!
    
    @IBOutlet weak var hostTestLabel: UILabel!
    
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
    }
    override func viewWillAppear(animated: Bool) {
        //        appDelegate.spotifyHandler.setupSpotifyPlayer()
        
        hostPlaySendTrack(PFUser.currentUser()!["party"] as! PFObject) {
            print("Host: playing track")
            self.appDelegate.mpcHandler.hostAdvertiser = MCNearbyServiceAdvertiser(peer: self.appDelegate.mpcHandler.peerID, discoveryInfo: nil, serviceType: "in-sync")
            self.appDelegate.mpcHandler.hostAdvertiser!.delegate = self
            self.appDelegate.mpcHandler.hostAdvertiser!.startAdvertisingPeer()
            print("Host: started advertising")
            self.performSegueWithIdentifier("hostSwipeSegue", sender: nil)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: Connecting to Peer
    
    /*
     Method for recognizing when a peer has changed state (ex: from not connected to connecting to connected)
     - parameter notification
     */
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
            let sentPeer = [peerID]
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
    /*
     Method for recognizing when data has been received and handling the data
     - parameter notification
     */
    func handleReceivedDataWithNotification(notification:NSNotification) {
        let userInfo = notification.userInfo! as Dictionary
        let receivedData:NSData = userInfo["data"] as! NSData
        let fromPeer:[MCPeerID] = [userInfo["peerID"] as! MCPeerID]
        if NSString(data: receivedData, encoding: NSUTF8StringEncoding) == "resync" {
            print("Host: received re-sync request from guest")
            
            let alert = UIAlertController(title: "Re-sync Request", message: "\(fromPeer) requests a re-sync.", preferredStyle: UIAlertControllerStyle.Alert)
            let acceptAction: UIAlertAction = UIAlertAction(title: "Re-Sync", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
                self.sendOffsetData(fromPeer)
            }
            let declineAction = UIAlertAction(title: "Ignore", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
            }
            alert.addAction(acceptAction)
            alert.addAction(declineAction)
            NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    
    // MARK: Music Control
    
    func onPlayPause() {
        let playPauseString:String = "play-pause-key"
        let playPauseData = playPauseString.dataUsingEncoding(NSUTF8StringEncoding)
        do {
            try appDelegate.mpcHandler.session.sendData(playPauseData!, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
            print("Host sent play/pause signal")
        } catch {
            print("Host: error sending play/pause signal")
        }
        
        if appDelegate.spotifyHandler.player!.isPlaying {
            appDelegate.spotifyHandler.player?.setIsPlaying(false, callback: { (error:NSError!) in
                if error != nil {
                    print("Host: error pausing")
                }})
        } else {
            appDelegate.spotifyHandler.player?.setIsPlaying(true, callback: { (error:NSError!) in
                if error != nil {
                    print("Host: error playing after pause")
                }})
        }
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
    
    
    
    
    // TESTING //
    
    func hostPlaySendTrack(party: PFObject, withCompletion completion: () -> Void) {
        print("called hostPlaySendTrack")
        let hostPlayGroup = dispatch_group_create()
        var tracksArray:[PFObject]!
        dispatch_group_enter(hostPlayGroup)
        let currentPlaylist = Party.getCurrentPlaylist(PFUser.currentUser()!["party"] as! PFObject)
        currentPlaylist.fetchInBackgroundWithBlock { (fetchPlaylist:PFObject?, error:NSError?) in
            if error != nil {
                print("error fetching currentplaylist in hostplaysendtrack")
            } else {
                tracksArray = fetchPlaylist!["tracks"] as! [PFObject]
                dispatch_group_leave(hostPlayGroup)
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
                self.notifySongChange()
                
                print("Got first track: \(nowPlayingTrack)")
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
                
                print("Host: got next track: \(nextTrack)")
                
                if let prevTrack = party["now_playing"] as? PFObject {
                    previousPlaylist.append(prevTrack)
                    //prevTrack.incrementKey("playedCount")
                    party.setObject(previousPlaylist, forKey: "previousPlaylist")
                    //prevTrack.deleteInBackground()
                }
                dispatch_group_enter(group)
                party["now_playing"] = nextTrack
                party.saveInBackgroundWithBlock({ (success:Bool, error:NSError?) in
                    if error != nil {
                        print("Error saving party: \(error?.localizedDescription)")
                    } else {
                        print("saved next track as now playing")
                        self.notifySongChange()
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
                            print("Started playing next track")
                            //                        dispatch_group_leave(group)
                            tracksArray.removeAtIndex(0)
                            currentPlaylist["tracks"] = tracksArray
                            currentPlaylist.saveInBackgroundWithBlock({ (success, error: NSError?) in
                                if error != nil {
                                    print ("Error saving playlist: \(error?.localizedDescription)")
                                } else {
                                    print("updated and saved playlist tracks array in hostPlaySendTrack")
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