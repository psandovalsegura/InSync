//
//  ObjectsViewController.swift
//  InSync
//
//  Created by Olivia Gregory on 7/12/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class ObjectsViewController: UIViewController {

    //let currentUser = PFUser.currentUser()
    var party : PFObject?
    var playlist: PFObject?

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func didTapBack(sender: AnyObject) {
        self.dismissViewControllerAnimated(true) {
            //
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //An experimental function to try the "start party" function.
    //Note: The user initialization should happen on the first screen
    @IBAction func didTapStartParty(sender: AnyObject) {
            let currentUser = PFUser.currentUser()
            Party.startParty(currentUser!, completion: { (party: PFObject) in
                self.party = currentUser!["party"] as? PFObject
            })
    }

    @IBAction func didTapGetPlaylists(sender: AnyObject) {
        SpotifyClient.getCurrentUserPlaylists { (userPlaylists: [Playlist]) in
            let userPlaylist = userPlaylists[0]
            SpotifyClient.getPlaylistTracks(userPlaylist, completionHandler: { (tracks: [Track]) in
                print("got playlist tracks")
                Playlist.createPlaylistWithTracks(tracks, completion: { (parsePlaylist) in
                    print("created playlist with tracks")
                    Party.setPlaylist(self.party!, playlist: parsePlaylist)
                })
            })

        }
    }

    @IBAction func didTapGetTrack(sender: AnyObject) {
        let currentUser = PFUser.currentUser()
        let currentParty = currentUser!["party"] as? PFObject

        let currentPlaylist = Party.getCurrentPlaylist(currentParty!)
        let tracksArray = currentPlaylist["tracks"] as! [PFObject]

        let firstTrack = tracksArray[0]
        Track.getTrackFromParty(currentParty!, newTrack: firstTrack, completion:  { (track) in
            print("Got the track!")
            print(track)
        })
    }

    @IBAction func didTapUpvoteTrack(sender: AnyObject) {
        let currentUser = PFUser.currentUser()
        let currentParty = currentUser!["party"] as? PFObject

        let currentPlaylist = Party.getCurrentPlaylist(currentParty!)
        let tracksArray = currentPlaylist["tracks"] as! [PFObject]

//        let thirdTrack = tracksArray[0]
//        Track.getTrackFromParty(currentParty!, newTrack: thirdTrack, completion: { (track) in
//            Track.upvote(thirdTrack, user: currentUser!)
//            Playlist.reorderPlaylist(currentParty!)
//        })
    }

    @IBAction func didTapAddTrack(sender: AnyObject) {
        let currentUser = PFUser.currentUser()
        let currentParty = currentUser!["party"] as? PFObject
        
        //let currentPlaylist = Party.getCurrentPlaylist(currentParty!)
        SpotifyClient.getCurrentUserSavedTracks { (tracks) in
            //Playlist.addTrack(tracks[0], party: currentParty!)
        }

    }
}
