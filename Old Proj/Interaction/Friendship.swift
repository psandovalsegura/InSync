//
//  Friendship.swift
//  Interaction
//
//  Created by Nancy Yao on 7/5/16.
//  Copyright © 2016 FBU Team Interaction. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class Friendship: NSObject {
    /*
     Method to add a friendship to Parse
     - parameter source: friend 1, requested friendship
     - parameter destination: friend 2, accepted friendship request
     */
    class func makeFriendship(source: PFUser, destination: PFUser) {
        let friendship = PFObject(className: "Friendship")
        friendship["members"] = [source, destination]
        friendship["pictures"] = [] as [PFObject]
        friendship["messages"] = [] as [String]
        //id, created_at, updated_at
        
        friendship.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            if (success) {
                print("Friendship successfully made")
            } else {
                print("error: \(error?.localizedDescription)")
            }
        }
    }
    /*
     Method to delete a friendship from Parse
     - parameter friendship: Friendship object to be deleted
     */
    class func removeFriendship(friendship: PFObject) {
        friendship.deleteInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            if (success) {
                print("Friendship successfully removed")
            } else {
                print("error: \(error?.localizedDescription)")
            }
        }
    }

    /*
     Method to convert UIImage to PFFile
     - parameter image: Image that the user wants to upload to parse
     - returns: PFFile for the the data in the image
     */
    static func getPFFileFromImage(image: UIImage?) -> PFFile? {
        // check if image is not nil
        if let image = image {
            // get image data and check if that is not nil
            if let imageData = UIImagePNGRepresentation(image) {
                return PFFile(name: "image.png", data: imageData)
            }
        }
        return nil
    }
    
    /*
    Method to find a friendship between two users
     - parameter userOne: one friend in the friendship
     - parameter userTwo: other friend in the friendship
    */
    class func getFriendship(userOne:PFUser, userTwo:PFUser, completion: (PFObject?) -> ()) {
        let friendsContained = [userOne, userTwo]
        let query = PFQuery(className: "Friendship")
        query.whereKey("members", containsAllObjectsInArray: friendsContained)
        
        query.findObjectsInBackgroundWithBlock { (friendships: [PFObject]?, error: NSError?) in
            if let friendship = friendships![0] as? PFObject {
                print("Friendship found")
                completion(friendship)
            } else {
                print("error: \(error?.localizedDescription)")
            }
        }
        /* To call:
        getFriendship() { (friendship) -> () in
            //use the "friendship" object here
        */
    }
    
    
    /*
    Method to send a "tug" from one friend to another
    - parameter sender: the friend who tugs the thread
    - parameter receiver: the friend who receives the tug/notification
    */
    class func tug(sender: User, receiver: user) {
        //send notification to receiver including a message saying it's from the sender
        //vibration
    }
    
}