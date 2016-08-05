//
//  User.swift
//  Interaction
//
//  Created by Pedro Sandoval Segura on 7/5/16.
//  Copyright © 2016 FBU Team Interaction. All rights reserved.
//

import Foundation
import Parse
import ParseUI

class User: NSObject {
    
    //The current logged in user
    public static var CURRENT_USER: PFUser!
    
    //Default profile image name, located in Assets.xcassets
    public static var DEFAULT_PROFILE_IMAGE_NAME = "default"
    
    //Constants for use in resizing current user profile image
    public static let PROFILE_VIEW_WIDTH = 40
    public static let PROFILE_VIEW_HEIGHT = 40
    
    /*
     Method to create a new user and upload to Parse
     Fields below must be configured in sign up process
     -username, password, email
     -Ex. newUser.username = usernameField.text
     
     - parameter newUser: a new PFUser object created on sign-up
     */
    static func createUser(newUser: PFUser) {
        //Add relevant fields to the PFUser object
        newUser["author"] = PFUser.currentUser() // Pointer column type that points to PFUser
        newUser["email"] = newUser["author"].email!!
        newUser["username"] = newUser["author"].username!!
        //newUser["last_known_longitude"] =
        //newUser["last_known_latitude"] =
        newUser["last_active_time"] = String(NSDate())
        newUser["active"] = true
        newUser["friendships"] = [Friendship]()
        newUser["profilePicture"] = loadDefaultProfileImageFile()
        
        newUser.saveInBackgroundWithBlock { (success: Bool, error: NSError?) in
            if success {
                print("New user successfully created")
                CURRENT_USER = newUser
            } else {
                print("error: \(error?.localizedDescription)")
            }
        }
    }
    
    
    /* Method to update user data, as used in Create Profile view.
    */
    
    static func updateData(name: String, education: String, work: String, location: String) {
        CURRENT_USER["name"] = name
        CURRENT_USER["education"] = education
        CURRENT_USER["work"] = work
        CURRENT_USER["location"] = location
    }
    
    
    /*
     Method to load a user that is already signed in.
     
     - parameter user: a new PFUser object that is persisted.
     */
    static func loadUser(user: PFUser) {
        CURRENT_USER = user
    }
    
    /*
     Method to load a user's default profile picture on sign up
     
     - returns: PFFile for the data in the image
     */
    static func loadDefaultProfileImageFile() -> PFFile? {
        let defaultImage = UIImage(named: DEFAULT_PROFILE_IMAGE_NAME)
        let file = Friendship.getPFFileFromImage(defaultImage)
        return file
    }
    
    /*
     Method to change a user's profile image
     
     - parameter newProfileImage: a new UIImage to set as profile picture
     */
    static func updateProfilePicture(newProfileImage: UIImage) {
        
        //Resize image in preparation for upload
        let resizedImage = resize(newProfileImage, newSize: CGSize(width: PROFILE_VIEW_WIDTH, height: PROFILE_VIEW_HEIGHT))
        
        //Update the profile picture
        CURRENT_USER["profilePicture"] = Friendship.getPFFileFromImage(resizedImage)
        
        //Save
        CURRENT_USER.saveInBackground()
        
    }
    
    /*
     Method to resize an Image
     - parameter image: image to be resized
     - parameter newSize: size the picture will be changed to
     */
    class func resize(image: UIImage, newSize: CGSize) -> UIImage {
        let resizeImageView = UIImageView(frame: CGRectMake(0, 0, newSize.width, newSize.height))
        resizeImageView.contentMode = UIViewContentMode.ScaleAspectFill
        resizeImageView.image = image
        
        UIGraphicsBeginImageContext(resizeImageView.frame.size)
        resizeImageView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    /*
     Method to change a user's active state on logout/app close
     */
    static func goInactive() {
        CURRENT_USER["active"] = false
        CURRENT_USER.saveInBackgroundWithBlock { (success: Bool, error: NSError?) in
            if success {
                print("User's active field set to false.")
            } else {
                print("error: \(error?.localizedDescription)")
            }
        }
    }
    
    /*
     Method to update the current user's location
     */
    static func updateLocation() {
        //CURRENT_USER["last_known_longitude"] =
        //CURRENT_USER["last_known_latitude"] =
        CURRENT_USER.saveInBackgroundWithBlock { (success: Bool, error: NSError?) in
            if success {
                print("User's location fields updated.")
            } else {
                print("error: \(error?.localizedDescription)")
            }
        }
    }
    
    /*
     Method for user to log in with username and password
     - parameter username
     - parameter password
     */
    static func login(username: String, password: String, withCompletion completion: PFUserResultBlock) {
        let username = username
        let password = password
        
        PFUser.logInWithUsernameInBackground(username, password: password, block: completion)
    }

}