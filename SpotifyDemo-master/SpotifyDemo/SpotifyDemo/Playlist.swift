//
//  Playlist.swift
//  InSync
//
//  Created by Olivia Gregory on 7/8/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import ParseUI
import Parse

class Playlist: NSObject {
    static let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    //Fields
    var id: String?
    var name: String?
    var uri: String?
    var tracks:[Track] = []
    
    var owner: String?
    
    init(dictionary: NSDictionary) {
        super.init()
        self.id = dictionary["id"] as? String
        self.name = dictionary["name"] as? String
        self.uri = dictionary["uri"] as? String
        
        let ownerDictionary = dictionary["owner"] as! NSDictionary
        self.owner = ownerDictionary["id"] as? String
        
        
    }
    
    /*
     Function creates a new Parse playlist when given an array of track objects
     
     @param tracks: the chosen track objects to be saved to parse
     @param completion: the block of code to be completed with the playlist when code is done executing
     */
    
    
    class func createPlaylistWithTracks (tracks: [Track], completion: (PFObject) -> ()) {
        let newPlaylist = PFObject(className: "Playlist")
        var parseTracks = [PFObject!](count: tracks.count, repeatedValue:nil)
        
        let group = dispatch_group_create()
        for (index, track) in tracks.enumerate() {
            dispatch_group_enter(group)
            Track.createTrackObject(track, completion: { (parseTrack) in
                parseTracks[index] = parseTrack
                dispatch_group_leave(group)
            })
        }
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            for track in parseTracks {
                print(track["name"])
            }
            newPlaylist["tracks"] = parseTracks
            newPlaylist.saveInBackgroundWithBlock({ (success, error) in
                if error == nil {
                    print("Saved new playlist \(newPlaylist)")
                    completion(newPlaylist)
                } else {
                    print("Error saving new track object: \(error?.localizedDescription)")
                }
            })
            
        }
    }
    
    
    /*
     Function adds a track to the Parse playlist for the party.
     
     @param party: the party for which to set the playlist
     @param track: the track to be added
     @param completion: the block of code to be completed with the playlist when code is done executing
     */
    
    class func addTrack(track: Track, party: PFObject, completion: (PFObject) -> Void) {
        //create a parse version of the track object
        Track.createTrackObject(track) { (newTrack) in
            
            let oldPlaylist = Party.getCurrentPlaylist(party)
            var tracksArray = oldPlaylist["tracks"] as? [PFObject]
            //add to existing tracks field
            if tracksArray != nil {
                tracksArray!.append(newTrack)
                oldPlaylist.setObject(tracksArray!, forKey: "tracks")
                //if no existing tracks field, create one
            } else {
                oldPlaylist["tracks"] = [newTrack]
            }
            //save playlist
            oldPlaylist.saveInBackgroundWithBlock({ (success, error) in
                if success {
                    completion(oldPlaylist)
                } else {
                    print("There was an error adding track: \(error?.localizedDescription)")
                }
            })
        }
    }
    
    
    
    /* Method to reorder the playlist based on the number of upvotes vs.
     downvotes.
     @param: the party for which the playlist is being reordered
     @param completion: the block of code to be completed with the playlist when code is done executing
     */
    class func reorderPlaylist (party: PFObject, completion: () -> Void) {
        Party.getCurrentPlaylistWithQuery(party) { (currentPlaylist) in
            Playlist.getPlaylistTracks(currentPlaylist, completion: { (playlistTracks) in
                
                let sortedPlaylist = playlistTracks.sort() {
                    trackOne, trackTwo in
                    let t1 = trackOne["votes"]! as! Int
                    let t2 = trackTwo["votes"]! as! Int
                    
                    return t1 > t2
                    
                }
                Party.setPlaylistTracks(currentPlaylist, tracks: sortedPlaylist, completion: {
                    completion()
                })
            })
        }
    }
    
    /* Gets 
    */
    class func getPlaylistTracks (playlist: PFObject, completion: ([PFObject]) -> ()) {
        let query = PFQuery(className: "Playlist")
        query.includeKey("tracks")
        query.getObjectInBackgroundWithId(playlist.objectId!) { (updatedPlaylist: PFObject?, error: NSError?) in
            if error == nil {
                //                print(updatedPlaylist)
                let tracks = updatedPlaylist!["tracks"] as! [PFObject]
                completion(tracks)
            } else {
                print ("Error finding playlist: \(error?.localizedDescription)")
            }
        }
    }
    
    /*
     Function creates a new Parse playlist when given a playlist object
     
     @param playlist: the chosen playlist object to be saved to parse
     @param completion: the block of code to be completed with the playlist when code is done executing
     DEPRECATED?
     */
    class func createPlaylist (playlist: Playlist, completion: (PFObject) -> ()) {
        let newPlaylist = PFObject(className: "Playlists")
        
        var parseTracks = [PFObject]()
        for track in playlist.tracks {
            Track.createTrackObject(track, completion: { (newtrack) in
                parseTracks.append(newtrack)
                
                newtrack["playlist"] = newPlaylist
                newPlaylist["tracks"] = parseTracks
                
                //Save to parse
                newtrack.saveInBackgroundWithBlock { (success, error) in
                    if error == nil {
                        newPlaylist.saveInBackgroundWithBlock { (success, error) in
                            if error == nil {
                                completion(newPlaylist)
                            } else {
                                print("Error saving new playlist object: \(error?.localizedDescription)")
                            }
                        }
                    } else {
                        print ("Error saving new track object: \(error?.localizedDescription)")
                    }}
                
            })
        }
    }

    
    //    class func setUpNextTrack (party: PFObject, completion: (PFObject) -> ()) {
    //        let currentPlaylist = Party.getCurrentPlaylist(party)
    //        currentPlaylist.fetchInBackgroundWithBlock { (fetchPlaylist: PFObject?, error: NSError?) in
    //            var tracksArray = fetchPlaylist!["tracks"] as! [PFObject]
    //
    //            party.fetchInBackgroundWithBlock({ (party: PFObject?, error: NSError?) in
    //                if tracksArray.isEmpty == false {
    //                    let nextTrack = tracksArray[0]
    //                    if party!["now_playing"] == nil {
    //                        party!["previous_track"] = nextTrack
    //                    } else {
    //                        party!["previous_track"] = party!["now_playing"]
    //                    }
    //                    party!["now_playing"] = nextTrack
    //                    tracksArray.removeAtIndex(0)
    //                    currentPlaylist["tracks"] = tracksArray
    //                } else {
    //                    print("tracks array is empty")
    //                    party!["previous_track"] = party!["now_playing"]
    //                }
    //
    //                print("Previous track: \(party!["previous_track"])")
    //                print("Now_playing track: \(party!["now_playing"])")
    //
    //                party!.saveInBackgroundWithBlock { (success, error: NSError?) in
    //                    if error == nil {
    //                        currentPlaylist.saveInBackgroundWithBlock({ (success, error: NSError?) in
    //                            if error == nil {
    //                                completion(currentPlaylist)
    //                            } else {
    //                                print ("Error saving playlist: \(error?.localizedDescription)")
    //                            }
    //                        })
    //                    } else {
    //                        print ("Error saving party: \(error?.localizedDescription)")
    //                    }
    //                }
    //            })
    //        }
    //    }
    //}
}
