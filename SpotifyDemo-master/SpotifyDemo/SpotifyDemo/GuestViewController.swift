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

class GuestViewController: UIViewController, MCNearbyServiceBrowserDelegate, MPCDelegate, SPTAudioStreamingPlaybackDelegate, UITableViewDelegate, UITableViewDataSource, SpotifyHandlerDelegate {
    
    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    @IBOutlet weak var tableView: UITableView!
    var isSynced:Bool = false
    var stateChangeTime: Double!
    var elapsedTime: Double!
    var parseHost:PFUser!
    var currentGuest:PFUser = PFUser.currentUser()!
    
    let sync_constant:Double = 0.2
    
    
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
    func peerChangedStateWithNotification(notification:NSNotification) {
        print("Guest: peer change state CALLED in GENERAL")
        let userInfo = NSDictionary(dictionary: notification.userInfo!)
        let state = userInfo.objectForKey("state") as! Int
        
        if state == MCSessionState.Connected.rawValue && !isSynced {
            print("Guest: peer state change CALLED signaling CONNECTION")
            stateChangeTime = CACurrentMediaTime()
            print("state time: \(stateChangeTime)")
                        self.performSegueWithIdentifier("JoinedPartySegue", sender: nil)
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
            leaveParty()
            
        } else if receivedString == "play-pause-key" {
            if ((appDelegate.spotifyHandler.player?.isPlaying) != nil) {
                self.appDelegate.spotifyHandler.player?.setIsPlaying(false, callback: { (error:NSError!) in
                    if error != nil {
                        print("Guest: error pausing")
                    } else { print("Guest: paused") }
                })
            } else {
                appDelegate.spotifyHandler.player?.setIsPlaying(true, callback: { (error: NSError!) in
                    if error != nil {
                        print("Guest: error playing after pause")
                    } else { print("Guest: played after pausing") }
                })
            }
        } else if receivedString == "queue-key" {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName("UpDownVoted", object: nil, userInfo: nil)
                print("received key, sent refresh queue notification")
            })

        } else if let offset = Double(receivedString!) {
            print("Guest: initial offset \(offset)")
            if !self.isSynced {
                self.elapsedTime = CACurrentMediaTime() - self.stateChangeTime
                print("Guest: elapsed time \(self.elapsedTime)")
                let finalOffset = offset + self.elapsedTime
                print("Guest: final offset: \(finalOffset)")
                self.appDelegate.spotifyHandler.initialGuestPlayTrack(finalOffset)
                isSynced = true
            } else {
                let finalOffset = offset + self.sync_constant
                print("Guest: final offset: \(finalOffset)")
                self.appDelegate.spotifyHandler.receiveOffset(finalOffset)
            }
        } else {
            print("playNextTrack with received uri will be called")
            notifySongChange()
            appDelegate.spotifyHandler.guestPlayNextTrack(receivedString!)
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
                self.performSegueWithIdentifier("guestLeavesPartySegue", sender: nil)
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
        cell.foundPeersLabel.text = foundPeer.displayName
        
        User.getParseUser(foundPeer.displayName) { (peer) in
            let profileImageURL = peer["profileImageUrl"] as! String
            if profileImageURL != "" {
                cell.foundPeersImageView.imageFromUrl(profileImageURL)
            }
        }
        return cell
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80.0
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let currentHost = appDelegate.mpcHandler.foundPeers[indexPath.row] as MCPeerID
        appDelegate.mpcHandler.currentHost = currentHost
        User.getParseUser(currentHost.displayName) { (parseHost: PFUser) in
            print("Parse host retrieved \(parseHost.username!)")
            self.parseHost = parseHost
            
            Party.joinParty(parseHost["party"] as! PFObject, currentUser: self.currentGuest, completion: { (party: PFObject) in
                print("Guest: joined party \(party)")
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
    }
    func audioStreamingDidBecomeActivePlaybackDevice(audioStreaming: SPTAudioStreamingController!) {
        print("Guest: ActivePlaybackDevice")
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
        if let playVC = segue.destinationViewController as? SwipeViewController {
            playVC.isGuest = true
        }
    }
}