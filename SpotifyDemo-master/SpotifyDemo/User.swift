//
//  User.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/8/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import Foundation
import Parse
import ParseUI

class User: NSObject {

    //Fields
    var birthdate: String?
    var email: String?
    var id: String?
    var uri: String?
    var profileImageUrl: String? //May be nil if user does not have a profile picture
    var fullName: String?

    var party: PFObject? //Make sure to initialize party field after user creation
    var previousTrack: PFObject? //Need to find a better place for this variable
    var personalLitness: Int?
    var danceNumber: Int?
    var previousLitness: Int?
    var lastGuestName: String?

    init(dictionary: NSDictionary) {
        self.birthdate = dictionary["birthdate"] as? String //Should be an NSDate
        self.email = dictionary["email"] as? String
        self.id = dictionary["id"] as? String
        self.uri = dictionary["uri"] as? String
        self.personalLitness = 0
        self.danceNumber = 0
        self.fullName = dictionary["display_name"] as? String

        //Check if the user has a profile picture
        if let imageDictionary = dictionary["images"] as? [NSDictionary] {
            if !imageDictionary.isEmpty {
                self.profileImageUrl = imageDictionary[0]["url"] as? String
            } else {
                self.profileImageUrl = ""
            }

        } else {
            self.profileImageUrl = ""
        }

    }

    /**
     Method to add a user to Parse (or find a user in Parse) after they sign up or log in
     - @param user: the user to be added to Parse
     */
    class func initializeParseUser(user: User, completion: (PFUser) -> ()) {
        let newUser = PFUser()

        //Fields for user
        newUser.email = user.email
        newUser.username = user.id
        newUser.password = user.id
        newUser["uri"] = user.uri
        newUser["birthdate"] = user.birthdate
        newUser["upvotes"] = [] as [String]
        newUser["downvotes"] = [] as [String]
        newUser["profileImageUrl"] = user.profileImageUrl
        if let fullName = user.fullName {
             newUser["fullName"] = user.fullName
        } else {
            newUser["fullName"] = user.id
        }
       

        //try signing up
        newUser.signUpInBackgroundWithBlock { (success: Bool, error: NSError?) in
            if (error != nil) {
                //try logging in
                PFUser.logInWithUsernameInBackground(newUser.username!, password: newUser.password!, block: { (user: PFUser?, error: NSError?) in
                    if (error == nil) {
                        print("User successfully logged in")
                        completion(newUser)
                    } else {
                        print ("Error signing up user")
                    }
                })
            } else {
                print("User successfully logged in")
                completion(newUser)
            }
        }

        //party field set at joinParty or startParty methods
    }

    /**
     Method to find a user in Parse by Spotify ID
     - @param spotifyID: the user's spotify ID
     - @param completion: the block to be completed after the user is found
     */
    class func getParseUser (spotifyID: String, completion: (PFUser) -> ()) {
        //search for user by spotify ID
        let query = PFQuery(className: "_User")
        query.whereKey("username", equalTo: spotifyID)
        query.includeKey("party")

        query.findObjectsInBackgroundWithBlock { (users: [PFObject]?, error: NSError?) in
            if error == nil {
                print(users)
                if let user = users![0] as? PFUser {
//                    print("Users found include: ")
//                    print(user)
//                    print("User found")
                    completion(user)
                } else {
                    print("Error: \(error?.localizedDescription)")
                }
            } else {
                    print("Error in getParseUser: \(error)")
                }
            }
        }

        /**
         Method to find a user in Parse by passing in the parse user object
         - @param user: the user to be searched for
         - @param completion: the block to be completed after the user is found
         */

        class func getUpdatedParseUser (user: PFUser, completion: (PFUser) -> ()) {
            let query = PFQuery(className: "_User")
            query.includeKey("party")
            query.getObjectInBackgroundWithId(user.objectId!) { (updatedUser: PFObject?, error: NSError?) in
                if error == nil {
                    let returnedUser = updatedUser as! PFUser
                    completion(returnedUser)
                } else {
                    print ("Error finding user: \(error?.localizedDescription)")
                }
            }

        }

        /* Method to return the current user's party.
         Seems to be unnecesary so far.
         */
        class func getParty() -> PFObject {
            return SpotifyClient.CURRENT_USER.party!
        }
}
