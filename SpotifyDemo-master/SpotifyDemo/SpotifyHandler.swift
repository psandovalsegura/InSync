//
//  SpotifyHandler.swift
//  InSync
//
//  Created by Nancy Yao on 7/15/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse

protocol SpotifyHandlerDelegate {
}

class SpotifyHandler: NSObject, SPTAudioStreamingDelegate {
    
    // MARK: Properties
    
    var delegate:SpotifyHandlerDelegate?
    var player:SPTAudioStreamingController?
    let spotifyAuthenticator = SPTAuth.defaultInstance()
    let initial_sync_constant = 1.28
    
    
    // MARK: Spotify
    
    func setupSpotifyPlayer() {
        player = SPTAudioStreamingController(clientId: spotifyAuthenticator.clientID)
        player?.playbackDelegate = delegate as! SPTAudioStreamingPlaybackDelegate
        player?.diskCache = SPTDiskCache(capacity: 1024 * 1024 * 64)
    }
    func loginSpotify() {
        player?.loginWithSession(SpotifyClient.CURRENT_SESSION, callback: { (error) in
            if (error != nil) {
                print("Error logging in with session: \(error)")
            }
        })
    }
    func initialGuestPlayTrack(offset:Double) {
        let initialPlayTime = CACurrentMediaTime()
        
        let currentParty = PFUser.currentUser()!["party"] as! PFObject
        let group = dispatch_group_create()
        var firstTrack:PFObject!
        var firstURI:String!
        dispatch_group_enter(group)
        currentParty.fetchInBackgroundWithBlock({ (fetchParty:PFObject?, error: NSError?) in
            if error != nil {
                print("Error fetching currentParty \(error)")
            } else {
                firstTrack = fetchParty!["now_playing"] as! PFObject
                firstTrack?.fetchInBackgroundWithBlock({ (fetchTrack:PFObject?, error:NSError?) in
                    if error != nil {
                        print("Error fetching first track")
                    } else {
                        print("Got first track: \(fetchTrack!["name"])")
                        firstURI = fetchTrack!["uri"] as! String
                        dispatch_group_leave(group)
                    }
                })
            }
        })
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            let uriArray = [NSURL(string:firstURI)!] as [AnyObject]
            let playOptions = SPTPlayOptions()
            
            let finalPlayTime = CACurrentMediaTime() - initialPlayTime
            print("finalPlayTime: \(finalPlayTime)")
            playOptions.startTime = NSTimeInterval(offset + finalPlayTime + self.initial_sync_constant)
            self.player?.playURIs(uriArray, withOptions: playOptions, callback: { (error:NSError!) in
                if error == nil {
                    print("playURIs completed in Initial Play Track")
                } else {
                    print("Error in playURIs \(error)")
                }
            })
        }
    }
    func guestPlayNextTrack(uri:String) {
        let uriArray = [NSURL(string:uri)!] as [AnyObject]
        let playOptions = SPTPlayOptions()
        player!.playURIs(uriArray, withOptions: playOptions) { (error:NSError!) in
            if error != nil {
                print("Guest: error in playNextTrck \(error)")
            } else {
                print("Guest: playNextTrack started playing")
            }
        }
    }
    /*
     func hostPlayTrack(party: PFObject, withCompletion completion: () -> Void) {
     print("called hostPlayTrack")
     let currentPlaylist = Party.getCurrentPlaylist(PFUser.currentUser()!["party"] as! PFObject)
     currentPlaylist.fetchInBackgroundWithBlock { (fetchPlaylist:PFObject?, error:NSError?) in
     var tracksArray = fetchPlaylist!["tracks"] as! [PFObject]
     
     if tracksArray.isEmpty {
     //When tracksArray is empty, just keep playing the last song playednow
     party.fetchInBackgroundWithBlock({ (fetchParty:PFObject?, error: NSError?) in
     if error != nil {
     print("Error fetching currentParty \(error)")
     } else {
     let nowPlayingTrack = fetchParty!["now_playing"] as! PFObject
     print("Got first track: \(nowPlayingTrack)")
     let nowPlayingURI = nowPlayingTrack["uri"] as! String
     let uriArray = [NSURL(string:nowPlayingURI)!] as [AnyObject]
     let playOptions = SPTPlayOptions()
     self.player!.playURIs(uriArray, withOptions: playOptions, callback: { (error:NSError!) in
     if error != nil {
     print("Error playing last track \(error)")
     } else {
     print("Started playing last track")
     completion()
     }
     })
     }})
     } else {
     let group = dispatch_group_create()
     let nextTrack = tracksArray[0]
     print("Host: got next track: \(nextTrack)")
     dispatch_group_enter(group)
     if let prevTrack = party["now_playing"] as? PFObject {
     prevTrack.deleteInBackground()
     }
     party["now_playing"] = nextTrack
     party.saveInBackgroundWithBlock({ (success:Bool, error:NSError?) in
     if error != nil {
     print("Error saving party: \(error?.localizedDescription)")
     } else {
     print("saved next track as now playing")
     dispatch_group_leave(group)
     }
     })
     dispatch_group_enter(group)
     let nextURI = nextTrack["uri"] as! String
     let uriArray = [NSURL(string:nextURI)!] as [AnyObject]
     let playOptions = SPTPlayOptions()
     self.player!.playURIs(uriArray, withOptions: playOptions, callback: { (error:NSError!) in
     if error != nil {
     print("Error playing next track \(error)")
     } else {
     print("Started playing next track")
     dispatch_group_leave(group)
     }
     })
     dispatch_group_notify(group, dispatch_get_main_queue(), {
     print("HG Notify")
     tracksArray.removeAtIndex(0)
     
     currentPlaylist["tracks"] = tracksArray
     currentPlaylist.saveInBackgroundWithBlock({ (success, error: NSError?) in
     if error != nil {
     print ("Error saving playlist: \(error?.localizedDescription)")
     } else {
     print("updated and saved playlist tracks array in hostPlayTrack")
     completion()
     }
     })
     })
     }
     }
     }
     func guestPlayTrack(withCompletion completion: () -> Void) {
     let currentPlaylist = Party.getCurrentPlaylist(PFUser.currentUser()!["party"] as! PFObject)
     currentPlaylist.fetchInBackgroundWithBlock { (fetchPlaylist:PFObject?, error:NSError?) in
     var tracksArray = fetchPlaylist!["tracks"] as! [PFObject]
     
     if tracksArray.isEmpty {
     //When tracksArray is empty, just keep playing the last song played
     let currentParty = PFUser.currentUser()!["party"] as! PFObject
     
     currentParty.fetchInBackgroundWithBlock({ (fetchParty:PFObject?, error: NSError?) in
     if error != nil {
     print("Error fetching currentParty \(error)")
     } else {
     let nowPlayingTrack = fetchParty!["now_playing"] as! PFObject
     print("Got last track: \(nowPlayingTrack)")
     let nowPlayingURI = nowPlayingTrack["uri"] as! String
     let uriArray = [NSURL(string:nowPlayingURI)!] as [AnyObject]
     let playOptions = SPTPlayOptions()
     self.player!.playURIs(uriArray, withOptions: playOptions, callback: { (error:NSError!) in
     if error != nil {
     print("Error playing last track \(error)")
     } else {
     print("Started playing last track")
     completion()
     }
     })
     }})
     
     } else {
     let nextTrack = tracksArray[0]
     print("Guest: got next track: \(nextTrack)")
     nextTrack.fetchInBackgroundWithBlock({ (fetchTrack:PFObject?, error:NSError?) in
     let trackURI = fetchTrack!["uri"] as! String
     let uriArray = [NSURL(string:trackURI)!] as [AnyObject]
     let playOptions = SPTPlayOptions()
     self.player!.playURIs(uriArray, withOptions: playOptions, callback: { (error:NSError!) in
     if error != nil {
     print("Guest: error playing track \(error)")
     } else {
     print("Guest: started playing track")
     completion()
     }
     })
     })
     }
     }
     }
     */
    func receiveOffset(offset: Double) {
        self.player?.seekToOffset(NSTimeInterval(offset), callback: { (error) in
            if error != nil {
                print("An error occurred during offset: \(error)")
            } else {
                print("Inside of offset, an offset has been injected")
            }
        })
    }
}
