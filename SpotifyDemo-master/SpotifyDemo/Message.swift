//
//  Message.swift
//  InSync
//
//  Created by Olivia Gregory on 7/22/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class Message: NSObject {
    
    /**
     Method to add a message to Parse
     
     @param partyt: Party that the comment is attached to
     @param message: Message text input by the user
     @param completion: block to be completed at end of code's execution, returns message
     */
    
    class func postMessage(message: String?, forParty party: PFObject, completion: (PFObject) -> ()) {
        
        //create message object
        let currentMessage = PFObject(className: "Message")
        currentMessage["text"] = message
        let username = PFUser.currentUser()?.username
        currentMessage["username"] = username
        print("created Message object")
        
        //add to party array of messages
        var currentMessagesArray = party["messages"] as! [PFObject]
        currentMessagesArray.append(currentMessage)
        party.setObject(currentMessagesArray, forKey: "messages")
        print("added to party array")
        
        //designate as "current" message <--should it be done here, or pull last array element from messages array during refresh?
        party["top_message"] = currentMessage
        print("set top message")
        
        currentMessage.saveInBackgroundWithBlock { (success: Bool, error: NSError?) in
            if (success) {
                party.saveInBackgroundWithBlock { (success: Bool, error: NSError?) in
                    if (success) {
                        completion(currentMessage)
                    } else {
                        print(error?.localizedDescription)
                    }
                }
            } else {
                print(error?.localizedDescription)
            }
        }
    }
    
    class func getTopMessage(party: PFObject, completion: (PFObject?) -> ()) {
        getAllMessages(party, withCompletion: { (messages) in
            //    sort?
            var message: PFObject?
            if messages.count > 0 {
                message = messages[messages.count - 1]
            } else {
                message = nil
            }
            completion(message)
        })
    }
    
    class func getTopMessages(party: PFObject, completion: ([PFObject]) ->()) {
        getAllMessages(party, withCompletion: { (messages) in
            //    sort?
            var returnMessages: [PFObject] = []
            if messages.count >= 1 {
                returnMessages.append(messages[messages.count - 1])
            }
            if messages.count >= 2 {
               returnMessages.append(messages[messages.count - 2])
            }
            if messages.count >= 3 {
                returnMessages.append(messages[messages.count - 3])            }
            completion(returnMessages)
        })

    }
    
    class func getAllMessages(party: PFObject, withCompletion completion: ([PFObject]) -> ()) {
        let query = PFQuery(className: "Party")
        query.includeKey("messages")
        query.getObjectInBackgroundWithId(party.objectId!) { (updatedParty: PFObject?, error: NSError?) in
            let messages = updatedParty!["messages"] as! [PFObject]
            print("found messages:")
            print(messages)
            completion(messages)
        }
    }
}