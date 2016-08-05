//
//  MainPartyViewController.swift
//  InSync
//
//  Created by Olivia Gregory on 7/17/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import Parse

class MainPartyViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var nowPlayingAlbumCover: UIImageView!
    @IBOutlet weak var nowPlayingSongLabel: UILabel!
    @IBOutlet weak var nowPlayingArtist: UILabel!
    @IBOutlet weak var nowPlayingAlbumLabel: UILabel!

    @IBOutlet weak var tempMessageLabel: UILabel!
    @IBOutlet weak var tempMessageField: UITextField!
    
    
    let currentUser = PFUser.currentUser()
    let currentParty = PFUser.currentUser()!["party"] as! PFObject


    // MARK: ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().idleTimerDisabled = true
        //        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(MainPartyViewController.onTimer), userInfo: nil, repeats: true)
        setUpView()
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            backgroundImageView.backgroundColor = UIColor.clearColor()
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)

            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            backgroundImageView.addSubview(blurEffectView)
        } else {
            backgroundImageView.backgroundColor = UIColor.blackColor()
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainPartyViewController.setUpView), name: "SongDidChange", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MainPartyViewController.updateMessage), name: "DataDidChange", object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        setUpView()
        updateMessage()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Now Playing View

    func setUpView() {
        currentParty.fetchInBackgroundWithBlock { (fetchParty:PFObject?, error:NSError?) in
            let nowPlayingSong = fetchParty!["now_playing"] as! PFObject
            nowPlayingSong.fetchInBackgroundWithBlock { (fetchSong: PFObject?, error:NSError?) in
                print("fetching nowplaying in main vc", nowPlayingSong["name"] as! String)
                self.nowPlayingSongLabel.text = fetchSong!["name"] as? String
                self.nowPlayingArtist.text = fetchSong!["artist"] as? String
                self.nowPlayingAlbumLabel.text = fetchSong!["albumName"] as? String
                self.nowPlayingAlbumCover.imageFromUrl((fetchSong!["albumImageURL"] as? String)!)
                self.backgroundImageView.imageFromUrl((fetchSong!["albumImageURL"] as? String)!)
            }
        }
    }
    
    func updateMessage() {
        Message.getTopMessage(self.currentParty, completion: { (newMessage) in
            if let newMessage = newMessage {
                self.tempMessageLabel.text = newMessage["text"] as! String
            } else {
                self.tempMessageLabel.text = ""
            }

        })
    }
    
    
    @IBAction func didTapComment(sender: AnyObject) {
        let message = tempMessageField.text ?? ""
        Message.postMessage(message, forParty: currentParty, completion: { (message) in
            Message.getTopMessage(self.currentParty, completion: { (newMessage) in
                if let newMessage = newMessage {
                    self.tempMessageLabel.text = newMessage["text"] as! String
                } else {
                    self.tempMessageLabel.text = ""
                }
            })
        })
    }
    
//    func onTimer() {
//        setUpView()
//    }
}
