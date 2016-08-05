//
//  AnnouncementViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/24/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit

class AnnouncementViewController: UIViewController, UITextViewDelegate {

    // MARK: Properties
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var characterCount: UILabel!
    
    
    // MARK: UIViewController LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        self.view.backgroundColor = UIColor(red: 42/255.0, green: 65/255.0, blue: 99/255.0, alpha: 1)
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
        //post message
    }




}
