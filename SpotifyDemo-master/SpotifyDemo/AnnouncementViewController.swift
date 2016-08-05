//
//  AnnouncementViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/24/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import MultipeerConnectivity

class AnnouncementViewController: UIViewController, UITextViewDelegate {

    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var characterCount: UILabel!
    
    var announcement: String?
    let currentUser = PFUser.currentUser()
    let currentParty = PFUser.currentUser()!["party"] as? PFObject
    
    // MARK: UIViewController LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        self.view.backgroundColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.0)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: UITextViewDelegate methods
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        let newText = (textView.text as NSString).stringByReplacingCharactersInRange(range, withString: text)
        let numberOfChars = newText.characters.count // for Swift use count(newText)
        characterCount.text = String(200 - numberOfChars)
        return numberOfChars < 200;
    }
    
    // MARK: Buttons
    
    @IBAction func onCancelButton(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func onPostButton(sender: UIButton) {
        announcement = textView.text ?? ""
        Message.postMessage(announcement, forParty: currentParty!) { (newMessage) in
            self.notifyMessagePost()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    @IBAction func onTapOutside(sender: AnyObject) {
        view.endEditing(true)
    }

    func notifyMessagePost() {
        let data = "message-key"
        let encodedData = data.dataUsingEncoding(NSUTF8StringEncoding)
        do {
            try appDelegate.mpcHandler.session.sendData(encodedData!, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
            print("sent message notif")
        } catch {
             print("Error sending message notif")
        }
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("DataDidChange", object: nil, userInfo: nil)
            print("sent message notif")
        })
    }

}
