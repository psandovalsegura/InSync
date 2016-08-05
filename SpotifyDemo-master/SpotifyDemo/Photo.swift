//
//  Photo.swift
//  InSync
//
//  Created by Olivia Gregory on 7/31/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import ParseUI
import Parse

class Photo: NSObject {
    
    /**
     Method to add a user post to Parse (uploading image file)
     
     
     - parameter image: Image that the user wants upload to parse
     - parameter caption: Caption text input by the user
     - parameter completion: Block to be executed after save operation is complete
     */
    class func postUserImage(image: UIImage?, withCaption caption: String?, withCompletion completion: PFBooleanResultBlock?) {
        // Create Parse object PFObject
        let photo = PFObject(className: "Photos")
        let user = PFUser.currentUser()
        let party = PFUser.currentUser()!["party"] as! PFObject
        
        // Add relevant fields to the object
        photo["media"] = getPFFileFromImage(image) // PFFile column type
        photo["author"] = user // Pointer column type that points to PFUser
        photo["caption"] = caption
        photo["party"] = party
        
        var currentPartyPhotos = party["photos"] as! [PFObject]
        currentPartyPhotos.append(photo)
        party.setObject(currentPartyPhotos, forKey: "photos")
        // Save object (following function will save the object in Parse asynchronously)
        
        party.saveInBackgroundWithBlock ( { (success, error: NSError?) in
            if error == nil {
                print ("photo added to party")
                photo.saveInBackgroundWithBlock(completion)
            } else {
                print ("Error adding photo to party: \(error?.localizedDescription)")
            }
            
        })
    }
    
    
    /**
     Method to convert UIImage to PFFile
     
     - parameter image: Image that the user wants to upload to parse
     
     - returns: PFFile for the the data in the image
     */
    class func getPFFileFromImage(image: UIImage?) -> PFFile? {
        // check if image is not nil
        if let image = image {
            // get image data and check if that is not nil
            if let imageData = UIImagePNGRepresentation(image) {
                return PFFile(name: "image.png", data: imageData)
            }
        }
        return nil
    }
    
}
