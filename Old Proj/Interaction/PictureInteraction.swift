//
//  PictureInteraction.swift
//  Interaction
//
//  Created by Nancy Yao on 7/6/16.
//  Copyright © 2016 FBU Team Interaction. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class PictureInteraction: NSObject {
    /*
    Method to send a picture as an interaction to a friend, save in Parse
    - parameter source: friend who sends the picture
    - parameter destination: friend who receives the picture
    - parameter friendship: friendship the interaction belongs to
    - parameter caption: caption for the image
    */
    class func makePictureInteraction(source: PFUser, destination: PFUser, friendship: PFObject, image: UIImage?, withCaption caption: String?) {
        //Create Parse object
        let post = PFObject(className: "PictureInteraction")
        
        //Add relevant fields
        post["image"] = Friendship.getPFFileFromImage(image)
        post["caption"] = caption
        
        //Add to Friendship
        var picturesArray = friendship["pictures"] as! [PFObject]
        picturesArray.append(post)
        friendship["pictures"] = picturesArray
        
        //Save edited array in Parse
        friendship.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                print("Picture interaction successfully posted")
            } else {
                print("error: \(error?.localizedDescription)")
            }
        }
    }
    
    /*
    Method to remove a picture interaction from the Friendship
    - parameter pictureInteraction: post to be removed
    - parameter friendship: friendship post is removed from
    */
    class func removePictureInteraction(pictureInteraction: PFObject, friendship: PFObject) {
        var picturesArray = friendship["pictures"] as! [PFObject]
        if let index = picturesArray.indexOf(pictureInteraction) {
            picturesArray.removeAtIndex(index)
        }
        //Save edited array in Parse
        friendship["pictures"] = picturesArray
        friendship.saveInBackgroundWithBlock { (success: Bool, error: NSError?) -> Void in
            if (success) {
                print("Picture interaction successfully removed")
            } else {
                print("error: \(error?.localizedDescription)")
            }
        }
    }
    
    
}
