//
//  QueueTrack.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/24/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse

class QueueTrack: NSObject {
    
    //Fields for a parse object stored on-device and updated on-device
    var name: String?
    var albumImage: UIImage?
    var albumName: String?
    var artist: String?
    var votes: Int?
    var playedCount: Int? //Where is this calculated?
    var currentParty: PFObject?
    
    var parseId: String?
    var parseObject: PFObject?
    
    var downvoted: Bool?
    var upvoted: Bool?
    
    
    init(parseTrack: PFObject, completion: (QueueTrack) -> Void) {
        super.init()
        
        parseTrack.fetchInBackgroundWithBlock({ (refreshedParseTrack, error) in
            if error == nil {
                self.name = refreshedParseTrack!["name"] as? String
                print("\(refreshedParseTrack) being initialized")
                
                self.parseObject = refreshedParseTrack
                //print("The song \(self.name!) is being initialized...")
                
                self.albumName = refreshedParseTrack!["albumName"] as? String
                self.artist = refreshedParseTrack!["artist"] as? String
                
                self.votes = (refreshedParseTrack!["votes"] as? Int)!
                self.playedCount = refreshedParseTrack!["playedCount"] as? Int
                self.currentParty = refreshedParseTrack!["currentParty"] as? PFObject
                
                let albumImageUrl = refreshedParseTrack!["albumImageURL"] as! String
                //print("In the queue track initializer: \(albumImageUrl)")
                UIImageView.getUIImageToStore(albumImageUrl) { (image) in
                    //print("For the song: \(self.name!) the image was set by the INITIALIZER.")
                    self.albumImage = image
                    completion(self)
                }
            }
        })
    }
    

    
    func upvote() {
        //Check that the track hasn't been upvoted before
        if (upvoted != nil) {
            //Testing
            upvoted = false
            self.votes! -= 1
            
            print("Already uploaded, nice try.")
        } else {
            upvoted = true
            
            if (downvoted != nil) {
                self.votes! += 2
            } else {
                self.votes! += 1
            }
        }
        
    }
    
    func downvote() {
        //Check that the track hasn't been downvoted before
        if (downvoted != nil) {
            print("Already uploaded, nice try.")
            downvoted = false
            self.votes! += 1
        } else {
            downvoted = true
            if (upvoted != nil) {
                self.votes! -= 2
            } else {
                self.votes! -= 1
            }
        }
        
    }




}
