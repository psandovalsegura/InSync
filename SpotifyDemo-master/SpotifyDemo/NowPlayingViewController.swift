//
//  NowPlayingViewController.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/8/16.
//  Copyright © 2016 FBU Team Interaction. All rights reserved.
//

import UIKit
import Alamofire

class NowPlayingViewController: UIViewController, SPTAudioStreamingPlaybackDelegate {
    
    // Spotify Music Player
    var player: SPTAudioStreamingController?
    let spotifyAuthenticator = SPTAuth.defaultInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup our Spotify playlist
        setupSpotifyPlayer()
        
        // Play track after our player is setup
        playTrack()
        
        
    }


    // MARK: - Spotify Setup
    
    func setupSpotifyPlayer() {
        // Initialize player
        player = SPTAudioStreamingController(clientId: spotifyAuthenticator.clientID)
        player?.playbackDelegate = self
        player?.diskCache = SPTDiskCache(capacity: 1024 * 1024 * 64)
    }
    
    func playTrack() {
        player?.loginWithSession(SpotifyClient.CURRENT_SESSION, callback: { (error) in
        
            // Basic Error Handling
            if (error != nil) {
                print("Error... \(error)")
            }
            
            // String to our selected track
            let trackURIString = "spotify:track:6stYbAJgTszHAHZMPxWWCY"
            
            // Track URL
            let trackURI = NSURL(string: trackURIString)
            
            // Play Track
            self.player?.playURI(trackURI, callback: { (error) in
                //
            })
            
            
        })
        
        SpotifyClient.getCurrentUserSavedTracks { (tracks) in
            let first = tracks[0]
            print("\(first.name!) chosen with track id: \(first.id!)....adding features")
            SpotifyClient.getFullFieldTrack(first, completionHandler: { (featureTrack) in
                print("energy \(featureTrack!.energy!) dance \(featureTrack!.danceability!)")
                print("user \(SpotifyClient.CURRENT_USER.id)")
            })
            
        }
    }
    
    // MARK: - SPTAudioStreamingController
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        print("PlaybackStatus")
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didSeekToOffset offset: NSTimeInterval) {
        print("SeekToOffset")
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeVolume volume: SPTVolume) {
        print("ChangedVolume")
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeShuffleStatus isShuffled: Bool) {
        print("ChangedShuffleStatus")
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeRepeatStatus isRepeated: Bool) {
        print("ChangedRepeatStatus")
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didChangeToTrack trackMetadata: [NSObject : AnyObject]!) {
        print("ChangedToTrack")
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didFailToPlayTrack trackUri: NSURL!) {
        print("FailToPlayTrack")
    }
    
    func audioStreamingDidSkipToNextTrack(audioStreaming: SPTAudioStreamingController!) {
        print("NextTrack")
    }
    
    func audioStreamingDidSkipToPreviousTrack(audioStreaming: SPTAudioStreamingController!) {
        print("PreviousTrack")
    }
    
    func audioStreamingDidBecomeActivePlaybackDevice(audioStreaming: SPTAudioStreamingController!) {
        print("ActivePlaybackDevice")
    }
    
    func audioStreamingDidBecomeInactivePlaybackDevice(audioStreaming: SPTAudioStreamingController!) {
        print("InactivePlaybackDevice")
    }
    
    func audioStreamingDidLosePermissionForPlayback(audioStreaming: SPTAudioStreamingController!) {
        print("DidLosePermissionForPlayback")
    }
    
    func audioStreamingDidPopQueue(audioStreaming: SPTAudioStreamingController!) {
        print("DidPopQueue")
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: NSURL!) {
        
        // Deprecated - Used for testing purposes only. ************************************************
        //
        // Track Info
        let trackName = audioStreaming.currentTrackMetadata[SPTAudioStreamingMetadataTrackName] as! String
        let trackAlbum = audioStreaming.currentTrackMetadata[SPTAudioStreamingMetadataAlbumName] as! String
        let trackArtist = audioStreaming.currentTrackMetadata[SPTAudioStreamingMetadataArtistName] as! String
        //
        //
        // **********************************************************************************************
        
        print(trackName)
        print(trackAlbum)
        print(trackArtist)
        print("StartedPlayingTrack")
    }
    
    func audioStreaming(audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: NSURL!) {
        print("StoppedPlayingTrack")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
