//
//  Track.swift
//  InSync
//
//  Created by Olivia Gregory on 7/8/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class Track: NSObject {

    //The fields below are set by the getFullTrack API call
    var duration: Int?
    var id: String?
    var uri: String?
    var name: String?
    var albumImageUrl: String?
    var albumName: String?
    var artistName: String = ""
    var artists = [Artist]()
    var parseTrack: PFObject?
    var parseID: String?

    var upvotedByUser = false
    var downvotedByUser = false


    //The fields below are set by the getFullTrack API call
    var danceability: Double? //how suitable a track is for dancing based on a combination of musical elements including tempo, rhythm stability, beat strength, and overall regularity. A value of 0.0 is least danceable and 1.0 is most danceable.
    var acousticness: Double? //from 0.0 to 1.0 of whether the track is acoustic. 1.0 represents high confidence the track is acoustic
    var energy: Double? //from 0.0 to 1.0 and represents a perceptual measure of intensity and activity. Typically, energetic tracks feel fast, loud, and noisy
    var liveliness: Double? //Detects the presence of an audience in the recording, value above 0.8 provides strong likelihood that the track is live.
    var loudness: Double? //overall loudness of a track in decibels (dB)
    var speechiness: Double? //Speechiness detects the presence of spoken words in a track
    var valence: Double? //from 0.0 to 1.0 describing the musical positiveness conveyed by a track

    init(dictionary: NSDictionary) {
        super.init()
        self.duration = dictionary["duration_ms"] as? Int
        self.id = dictionary["id"] as? String
        self.uri = dictionary["uri"] as? String
        self.name = dictionary["name"] as? String

        //Additional information loaded in getAudioFeatures (helper method) of Spotify Client

        //When tracks are initialized from getAlbumTracks Spotify API call, track objects do not have album references

        if let albumDictionary = dictionary["album"] as? NSDictionary {
            self.albumName = albumDictionary["name"] as? String
            if let imagesArray = albumDictionary["images"] as? [NSDictionary] {
                let thumbnail = imagesArray[0]
                self.albumImageUrl = thumbnail["url"] as? String
            }
        }


        let artistDictionaries = dictionary["artists"] as? [NSDictionary]
        for artistDictionary in artistDictionaries! {
            let currentArtist = Artist(dictionary: artistDictionary)
            self.artists.append(currentArtist)
        }

        //Constructing artist(s) string
        if (artists.count == 1) {
            artistName = artists[0].name!
        } else {
            for artist in self.artists {
                if (artist != self.artists[self.artists.endIndex - 1]) {
                    self.artistName += (artist.name! + ", ")
                } else {
                    self.artistName += (artist.name!)
                }
            }

        }
    }

    /*
     Method to initialize a track object for a specific track and saves it to Parse.

     @param newTrack: a Track object
     @param completion: block to be executed with parse track after code finishes
     
     NOTE: To call:
        createdTrackObject() { (track) -> () in
        //use the "track" object here
     
     }
     */
     class func createTrackObject(newTrack: Track, completion: (PFObject) -> Void) {
        let track = PFObject(className: "Track")
        track["uri"] = newTrack.uri!
        track["name"] = newTrack.name!
        track["albumImageURL"] = newTrack.albumImageUrl!
        track["albumName"] = newTrack.albumName
        track["artist"] = newTrack.artistName
        track["votes"] = 0
        track["playedCount"] = 0
        track["currentOffset"] = NSTimeInterval(0.0)
        track["voters"] = [] as [PFUser]
        track["currentParty"] = PFUser.currentUser()!["party"]

        track.saveInBackgroundWithBlock { (success, error) in
            if error == nil {
                newTrack.parseID = track.objectId
                completion(track)
            } else {
                print("Error saving new track object: \(error?.localizedDescription)")
            }
        }
    }



    /*
     Method to find a specific track from Parse.

     @param newTrack: a parse track object
     @param completion: what to do with the track object

     NOTE: To call:
           getTrack() { (track) -> () in
           //use the "track" object here

           }

     */

    class func getTrackFromParty (party: PFObject, newTrack: PFObject, completion: (PFObject) -> ()) {
        //may not need to query if object id is set
        let currentUser = PFUser.currentUser()
        let currentParty = currentUser!["party"] as! PFObject

        let query = PFQuery(className: "Track")
        query.whereKey("currentParty", equalTo: currentParty)
        query.whereKey("uri", equalTo: newTrack["uri"])

        query.findObjectsInBackgroundWithBlock { (tracks: [PFObject]?, error: NSError?) in
            //Assume that one track comes back
            print("tracks found are: ")
            print(tracks)

            if let track = tracks![(tracks?.count)! - 1] as? PFObject {
                print("Track found from party")
                completion(track)
            } else {
                print("Error: \(error?.localizedDescription)")
            }
        }

    }

    /* Method to upvote a track.
     @param track: a track object for which the user is upvoting
     @param user: user object representing user currently voting
     @warning: assumes that caller already checked that the user
     belongs to current party
     */

    class func upvote(parseTrack: PFObject, user: PFUser, completion: () -> Void) {
        User.getUpdatedParseUser(user) { (user) in

            var currentUpvotes = user["upvotes"] as! [String]
            var currentDownvotes = user["downvotes"] as! [String]
            let party = user["party"] as! PFObject
            
            //check that user voting hasn't already voted on the song
            if (!(currentUpvotes.contains(parseTrack.objectId!))) {

                //if they already downvoted, undo their downvote
                if (currentDownvotes.contains(parseTrack.objectId!)) {
                    undoDownvote(parseTrack, user: user)
                }
                //increment votes
                parseTrack.incrementKey("votes")

                //add track to list of user's upvotes
                currentUpvotes.append(parseTrack.objectId!)
                user.setObject(currentUpvotes, forKey: "upvotes")
                
                //save track
                parseTrack.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) in
                    if (success) {
                        print("Track successfully upvoted and saved")
                        //save user
                        user.saveInBackgroundWithBlock({ (succes: Bool, error: NSError?) in
                            if (success) {
                                //reorder playlist, and pass in completion
                                Playlist.reorderPlaylist(party, completion: { 
                                    completion()
                                })
                            } else {
                                print("Error saving user's upvotes: \(error?.localizedDescription)")
                            }
                        })
                    }
                    else {
                        print("Error un-upvoting and saving track: \(error?.localizedDescription)")
                    }
                })
            }
        }
    }
    
    class func undoUpvote(parseTrack: PFObject, user: PFUser) {
        let party = user["party"] as! PFObject
        var currentUpvotes = user["upvotes"] as! [String]
        let trackID = parseTrack.objectId!
        
        //remove from user upvotes
        while currentUpvotes.contains(trackID) {
            if let trackIDIndex = currentUpvotes.indexOf(trackID) {
                currentUpvotes.removeAtIndex(trackIDIndex)
            }
        }
        user.setObject(currentUpvotes, forKey: "upvotes")
        
        //decrement vote count
        var currentVotes = parseTrack["votes"] as! Int
        currentVotes -= 1
        parseTrack.setObject(currentVotes, forKey: "votes")
        
        parseTrack.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) in
            if (success) {
                print("Track successfully un-upvoted and saved")
                user.saveInBackgroundWithBlock({ (succes: Bool, error: NSError?) in
                    if (success) {
                        //print(success)
                    } else {
                        print("Error saving user's upvotes: \(error?.localizedDescription)")
                    }
                })
            }
            else {
                print("Error un-downvoting and saving track: \(error?.localizedDescription)")
            }
        })
        
    }
    
    class func undoDownvote(parseTrack: PFObject, user: PFUser) {
        let party = user["party"] as! PFObject
        var currentDownvotes = user["downvotes"] as! [String]
        let trackID = parseTrack.objectId!
        
        //remove from user downvotes
        while currentDownvotes.contains(trackID) {
            if let trackIDIndex = currentDownvotes.indexOf(trackID) {
                currentDownvotes.removeAtIndex(trackIDIndex)
            }
        }
        user.setObject(currentDownvotes, forKey: "upvotes")
        
        //increment vote count
        parseTrack.incrementKey("votes")
        
        parseTrack.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) in
            if (success) {
                print("Track successfully un-downvoted and saved")
                user.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) in
                    if (success) {
                        //print("success")
                    } else {
                        print("Error saving user's upvotes: \(error?.localizedDescription)")
                    }
                })
            }
            else {
                print("Error upvoting and saving track: \(error?.localizedDescription)")
            }
        })
    }


    /* Method to downvote a track.
     @param track: the track object the user is downvoting
     @param user: user object representing user currently voting
     @warning: assumes that caller already checked that the user
     belongs to current party
     */
    class func downvote(parseTrack: PFObject, user: PFUser, completion: () -> Void) {
        var currentDownvotes = user["downvotes"] as! [String]
        var currentUpvotes = user["upvotes"] as! [String]
        let party = user["party"] as! PFObject

        //check that user voting hasn't already voted on the song
        if (!currentDownvotes.contains(parseTrack.objectId!)) {
            if (currentUpvotes.contains(parseTrack.objectId!)) {
                undoUpvote(parseTrack, user: user)
            }
            //decrement vote count
            var currentVotes = parseTrack["votes"] as! Int
            currentVotes -= 1
            parseTrack.setObject(currentVotes, forKey: "votes")

            //add track to list of user's upvotes
            currentDownvotes.append(parseTrack.objectId!)
            user.setObject(currentDownvotes, forKey: "downvotes")
            
            //save track
            parseTrack.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) in
                if (success) {
                    print("Track successfully downvoted and saved")
                    //save user
                    user.saveInBackgroundWithBlock({ (succes: Bool, error: NSError?) in
                        if (success) {
                            //reorder playlist and pass in completion
                            Playlist.reorderPlaylist(party, completion: { 
                                completion()
                            })
                        } else {
                            print("Error saving user's downvotes: \(error?.localizedDescription)")
                        }
                    })
                }
                else {
                    print("Error downvoting and saving track: \(error?.localizedDescription)")
                }
            })
        }

    }

    /* Adds tracks to a playlist on Parse
     @param tracks: array of track objects
     @param completion: block to be executed upon code's completion
     */
    class func addSelectedTracksToParty(tracks: [Track], completion: Void -> Void) {
        let currentUser = PFUser.currentUser()
        let party = currentUser!["party"] as! PFObject

        Playlist.createPlaylistWithTracks(tracks) { (parsePlaylist) in
            Party.setPlaylist(party, playlist: parsePlaylist)
            completion()
        }
    }
    
    /* Gets an updated version of a parse track with a query
     @param newTrack: track object to be found on parse
     @param completion: block of code to be executed when code is done
    */
    class func getParseTrack(newTrack: Track, completion: (PFObject) -> ()) {

        let query = PFQuery(className: "Track")
        query.whereKey("uri", equalTo: newTrack.uri!)
        query.orderByAscending("createdAt")
        
        query.findObjectsInBackgroundWithBlock { (tracks: [PFObject]?, error: NSError?) in
            if let track = tracks![(tracks?.count)! - 1] as? PFObject {
                print("Track found")
                completion(track)
            } else {
                print("Error: \(error?.localizedDescription)")
            }
        }
    }

    class func convertMillisToReadableTime(millisDuration: Int) -> String {
        var totalSeconds = millisDuration / 1000

        //Check to make sure there is not an extra second of remaining milliseconds
        if millisDuration % 1000  > 500 {
            totalSeconds += 1
        }

        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    //    class func checkIfUpvoted(user: PFUser, parseTrack: PFObject) -> Bool {
    //        User.getUpdatedParseUserForCheck(user) { (user) -> (Bool) in
    //            let currentUpvotes = user["upvotes"] as! [PFObject]
    //            return currentUpvotes.contains(parseTrack)
    //        }
    //        return false
    //    }
    //
        class func checkIfDownvoted(user: PFUser, parseTrack: PFObject) -> Bool {
            let currentUpvotes = user["downvotes"] as! [PFObject]
            return currentUpvotes.contains(parseTrack)
        }
    
    class func getTrackFromPartyWithUri (party: PFObject, trackUri: String, completion: ([PFObject]) -> ()) {
        //may not need to query if object id is set
        let currentUser = PFUser.currentUser()
        let currentParty = currentUser!["party"] as! PFObject
        
        let query = PFQuery(className: "Track")
        query.whereKey("currentParty", equalTo: currentParty)
        query.whereKey("uri", equalTo: trackUri)
        
        query.findObjectsInBackgroundWithBlock { (tracks: [PFObject]?, error: NSError?) in
            if let tracks = tracks {
                print("Track found from party")
                completion(tracks)
            } else {
                print("Error: \(error?.localizedDescription)")
            }
        }
        
    }
}
