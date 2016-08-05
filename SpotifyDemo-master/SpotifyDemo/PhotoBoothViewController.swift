//
//  PhotoBoothViewController.swift
//  InSync
//
//  Created by Olivia Gregory on 7/30/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class PhotoBoothViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
        @IBOutlet weak var imageView: UIImageView!
        @IBOutlet weak var modeControl: UISegmentedControl!
        
        @IBOutlet weak var chooseAPictureButton: UIButton!
        @IBOutlet weak var postButton: UIButton!
        @IBOutlet weak var captionField: UITextField!
    
        @IBAction func didTapCancelButton(sender: AnyObject) {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    
        @IBAction func didTapChooseButton(sender: AnyObject) {
            let vc = UIImagePickerController()
            vc.delegate = self
            vc.allowsEditing = true
            if (modeControl.selectedSegmentIndex == 0) {
                vc.sourceType = UIImagePickerControllerSourceType.Camera
            }
            else {
                vc.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            }
            
            self.presentViewController(vc, animated: true, completion: nil)
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            postButton.hidden = true
        }
        
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
        
        func imagePickerController(picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [String : AnyObject]) {
            // Get the image captured by the UIImagePickerController
            //let originalImage = info[UIImagePickerControllerOriginalImage] as! UIImage
            let editedImage = info[UIImagePickerControllerEditedImage] as! UIImage
            
            imageView.image = editedImage
            
            // Dismiss UIImagePickerController to go back to original view controller
            dismissViewControllerAnimated(true, completion: nil)
            
            chooseAPictureButton.setTitle("Choose another picture", forState: .Normal)
            postButton.hidden = false

        }
    
    @IBAction func didTapPost(sender: AnyObject) {
        // var currentPost: Post
        var caption = captionField.text
        if (captionField.text == nil) {
            caption = ""
        }
        let currentImage = imageView.image
        if currentImage == nil {
            print("no image posted")
        } else {
            Photo.postUserImage(currentImage!, withCaption: caption!, withCompletion: { (success: Bool, error: NSError?) in
                print("posted")
                self.dismissViewControllerAnimated(true, completion: nil)
                //self.performSegueWithIdentifier("postedImage", sender: nil)
            })
        }
    }
    
       

    
    
//        override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//
//        }
    
}
