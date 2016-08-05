//
//  Party.swift
//  InSync
//
//  Created by Olivia Gregory on 7/8/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class Party: NSObject {

    /* Method to add a new party to Parse
     @param currentUser: User object representing person currently logged in who is creating party,
         automatically designated admin and added as guest
     @param completion: block to be completed with the party after it's created
     @note pass PFUSer.currentUser() into this method as a parameter
     */
    class func startParty(currentUser: PFUser, completion: (PFObject) -> Void) {
        //create party object
        let party = PFObject(className: "Party")
        
        //set current user's party
        currentUser["party"] = party
        
        //save current user
        currentUser.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            if error == nil {
                print("User saved successfully in start party")
                
                //Set party fields
                party["guest"] = [currentUser] as [PFUser]
                party["host"] = currentUser as PFUser
                party["litness"] = 0 as Double
                party["active"] = true
                party["messages"] = []
                party["photos"] = []
                party["previousPlaylist"] = []
                //Other fields to be set later: "playlist", "now_playing"
                
                //save party
                party.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
                    if error == nil {
                        print("Party saved succesfully")
                        completion(party)
                    } else {
                        print("Error saving party in start party: \(error?.localizedDescription)")
                    }
                }
            } else {
                print("Error saving user in start party: \(error?.localizedDescription)")
            }
        }
    }

    /* Method to delete a party from Parse
     @param party: Party object to be deleted
     //alternatively can be executed by setting "active" field to false
     */
    class func endParty(party: PFObject) {
        //send signal to all guests to "leave party"
        //Or easier: stop signal, and guests will leave automatically
        TrackAdder.hostInitialSelection = true
        party.deleteInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            if (success) {
                print ("Party successfully removed.")
                //should call party["admin"]
                PFUser.currentUser()?.removeObjectForKey("party")
                PFUser.currentUser()?.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) in
                    print("User party successfully blank")
                })
            } else {
                print ("Error ending Party: \(error!.localizedDescription)")
            }
        }
    }

    /* Method to join a party.
     @param party: Party object to be joined
     @param user: User object to be added to the party
     @param completion: block to be completed with the party after it's created
     */

    class func joinParty (party: PFObject, currentUser: PFUser, completion: (PFObject) -> ()) {
        //Find party in parse
        let query = PFQuery(className: "Party")
        query.getObjectInBackgroundWithId(party.objectId!) { (party: PFObject?, error: NSError?) in
            if let party = party as PFObject! {
                //set current user's  party
//                print("party found", party)
                currentUser["party"] = party
                SpotifyClient.CURRENT_USER.party = party
                
                //add user to guest list
                var currentGuests = party["guest"] as! [PFUser]
                currentGuests.append(currentUser)
                party.setObject(currentGuests, forKey: "guest")
                
                //save the user
                currentUser.saveInBackgroundWithBlock({ (success, error) in
                    if error != nil {
                        print("Error joining the current user's current party: \(error?.localizedDescription)")
                    } else {
                        print("User party succesfully set.")
                        
                        //save the party
                        party.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) in
                            if error != nil {
                                print("Error adding the user to the guest list: \(error?.localizedDescription)")
                            }
                            else {
                                print("User successfully joined party")
                                completion(party)
                            }
                        })
                    }
                })


            } else {
                print("Error: \(error?.localizedDescription)")
            }

        }
    }

    /* Method to leave a party.
     @param party: Party object to be left
     @param currentUser: User object to be removed rom the party
     //NEEDS TESTING
     */
    class func leaveParty(party: PFObject, currentUser: PFUser) {
        var currentGuests = party["guest"] as! [PFUser]
        var index = 0
        if currentGuests.count != 0 {
            for guest in currentGuests {
                if guest == currentUser {
                    currentGuests.removeAtIndex(index)
                }
                index += 1
            }
        }
        party.setObject(currentGuests, forKey: "guest")
        party.saveInBackgroundWithBlock({ (success, error) in
            if error != nil {
                print("Error leaving the current user's current party: \(error?.localizedDescription)")
            } else {
                print("User party succesfully left.")
                PFUser.currentUser()?.removeObjectForKey("party")
                PFUser.currentUser()?.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) in
                    if (error == nil) {
                    print("User party successfully blank")
                    } else {
                         print("Error leaving the current user's current party: \(error?.localizedDescription)")
                    }
                })

            }
        })
    }

    /* Method to set the party's current playlist.
     @param party: the party object for which to set the playlist
     @param playlist: playlist object to set for the party
     */
    class func setPlaylist(party: PFObject, playlist: PFObject) {
        print("Setting playlist...")
        party.setObject(playlist, forKey: "playlist")

        party.saveInBackgroundWithBlock { (success, error) in
            if (success) {
                print("Playlist set successfully")
            } else {
                print ("Error setting playlist: \(error?.localizedDescription)")
            }
        }
    }

    /* Method to set a playlist's tracks
     @param playlist: the playlist object for which to set the tracks
     @param tracks: array of parse track objects to set as the tracks
     @param completion: block to be executed when code is finished
     */
    class func setPlaylistTracks(playlist: PFObject, tracks: [PFObject], completion: () -> Void) {
        // party.setObject(playlist, forKey: "playlist")
        playlist.setObject(tracks, forKey: "tracks")
        playlist.saveInBackgroundWithBlock { (success, error) in
            if (success) {
                print("Playlist set successfully")
                completion()
            } else {
                print ("Error setting playlist: \(error?.localizedDescription)")
            }
        }
    }


    /* Method to get the current playlist for the party
     @param party: Current party
     @return: The current playlist for the party as an array of tracks
     */
    class func getCurrentPlaylist (party: PFObject) -> PFObject {
        let currentPlaylist = party["playlist"] as! PFObject
        return currentPlaylist
    }
    
    
    
    /* Method to get the current playlist for the party with a query (to have an updated version)
     @param party: Current party
     @param completion: block to be executed with the found playlist when the code finishes
     */
    class func getCurrentPlaylistWithQuery (party: PFObject, completion: (PFObject) -> Void) {
        let query = PFQuery(className: "Party")
        query.includeKey("playlist")
        query.getObjectInBackgroundWithId(party.objectId!) { (updatedParty: PFObject?, error: NSError?) in
            if error == nil {
                let playlist = updatedParty!["playlist"] as! PFObject
                completion(playlist)
            } else {
                print ("Error finding party: \(error?.localizedDescription)")
            }
        }
    }
    
}
