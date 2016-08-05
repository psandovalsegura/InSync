//
//  PartyDetailsViewController.swift
//  InSync
//
//  Created by Olivia Gregory on 7/24/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse

class PartyDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var isGuest:Bool?
    var previousPlaylist: [PFObject] = []
    var currentGuests: [PFObject!] = []
    var allMessages: [PFObject!] = []
    var allPhotos : [PFObject!] = []
    
    @IBOutlet weak var photosView: UICollectionView!
    @IBOutlet weak var guestsTableView: UITableView!
    @IBOutlet weak var announcementsTableView: UITableView!
    
    let currentUser = PFUser.currentUser()
    let currentParty = PFUser.currentUser()!["party"] as! PFObject
    
    let gradientLayer = CAGradientLayer()
    let gradientLayer2 = CAGradientLayer()
    
    @IBOutlet weak var guestlistView: UIView!
    @IBOutlet weak var announcementsView: UIView!
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        announcementsTableView.delegate = self
        announcementsTableView.dataSource = self
        announcementsTableView.estimatedRowHeight = 70
        announcementsTableView.rowHeight = UITableViewAutomaticDimension
        
        guestsTableView.delegate = self
        guestsTableView.dataSource = self
        
        setUpGradientLayer()
        photosView.hidden = true
        
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        currentParty.fetchInBackgroundWithBlock({ (fetchParty:PFObject?, error:NSError?) in
            if error == nil {
                self.previousPlaylist = fetchParty!["previousPlaylist"] as! [PFObject]
                //                print("previous playlist is: ")
                //                print(self.previousPlaylist)
                
                self.currentGuests = fetchParty!["guest"] as! [PFObject]
                let guestGroup = dispatch_group_create()
                let guestsCount = self.currentGuests.count
                var fetchedGuests = [PFObject!](count: guestsCount, repeatedValue: nil)
                for (index, guest) in self.currentGuests.enumerate() {
                    dispatch_group_enter(guestGroup)
                    guest.fetchIfNeededInBackgroundWithBlock({ (guest:PFObject?, error:NSError?) in
                        fetchedGuests[index] = guest
                        dispatch_group_leave(guestGroup)
                    })
                }
                dispatch_group_notify(guestGroup, dispatch_get_main_queue(), {
                    self.currentGuests = fetchedGuests
                    self.guestsTableView.reloadData()
                })
                
                self.allMessages = fetchParty!["messages"] as! [PFObject]
                let announcementGroup = dispatch_group_create()
                let announcementsCount = self.allMessages.count
                var fetchedAnnouncements = [PFObject!](count: announcementsCount, repeatedValue: nil)
                for (index, announcement) in self.allMessages.enumerate() {
                    dispatch_group_enter(announcementGroup)
                    announcement.fetchIfNeededInBackgroundWithBlock({ (announcement:PFObject?, error:NSError?) in
                        fetchedAnnouncements[index] = announcement
                        dispatch_group_leave(announcementGroup)
                    })
                }
                dispatch_group_notify(announcementGroup, dispatch_get_main_queue(), {
                    self.allMessages = fetchedAnnouncements
                    self.announcementsTableView.reloadData()
                })
                
                self.allPhotos = fetchParty!["photos"] as! [PFObject]
                let photosGroup = dispatch_group_create()
                let photosCount = self.allPhotos.count
                var fetchedPhotos = [PFObject!](count: photosCount, repeatedValue: nil)
                for (index, photo) in self.allPhotos.enumerate() {
                    dispatch_group_enter(photosGroup)
                    photo.fetchIfNeededInBackgroundWithBlock({ (photo:PFObject?, error:NSError?) in
                        fetchedPhotos[index] = photo
                        dispatch_group_leave(photosGroup)
                    })
                }
                dispatch_group_notify(photosGroup, dispatch_get_main_queue(), {
                    self.allPhotos = fetchedPhotos
                    self.photosView.reloadData()
                })
                
//                self.announcementsTableView.reloadData()
            }
        })
    }
    
    
    // MARK: Buttons
    
    @IBAction func onSettingsButton(sender: UIButton) {
        if (appDelegate.mpcHandler.isGuest == true) {
            self.performSegueWithIdentifier("GuestSettingsSegue", sender: nil)
        } else {
            self.performSegueWithIdentifier("HostSettingsSegue", sender: nil)
        }
    }
    
    // MARK: Table Views
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tableView == self.guestsTableView {
            let cell1 = self.guestsTableView.dequeueReusableCellWithIdentifier("GuestsCell") as! GuestsCell
            let guest = currentGuests[indexPath.row]
            
            cell1.guestNameLabel!.text = guest["username"] as? String
            if guest["profileImageUrl"] as! String == "" {
                cell1.guestImageView.image = UIImage(named: "default-user")
            } else {
                cell1.guestImageView.imageFromUrl((guest["profileImageUrl"] as? String)!)
            }
            cell1.guestImageView.layer.cornerRadius = cell1.guestImageView.frame.size.width / 2
            cell1.guestImageView.clipsToBounds = true
            return cell1
        } else {
            let cell2 = self.announcementsTableView.dequeueReusableCellWithIdentifier("AnnouncementsCell") as! AnnouncementsCell
            let announcement = allMessages[indexPath.row]
            
            cell2.nameLabel.text = announcement["username"] as? String
            cell2.announcementLabel.text = announcement["text"] as? String
            
            var timestampString:String?
            let formatter = NSDateFormatter()
            formatter.dateFormat = "h:mm a"
            if let timestampDate = announcement.createdAt {
                timestampString = formatter.stringFromDate(timestampDate)
            }
            cell2.timestampLabel.text = timestampString
            return cell2
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.guestsTableView {
            return currentGuests.count
        } else {
            return allMessages.count
        }
    }
    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if tableView == self.guestsTableView {
            return 60
        } else {
            return 70
        }
    }
    
    func setUpGradientLayer() {
        let color1 = UIColor.clearColor().CGColor as CGColorRef
        let color2 = UIColor(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 0.5).CGColor as CGColorRef
        
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.colors = [color2, color1]
        gradientLayer.locations = [0.0, 1.0]
        
        gradientLayer.frame = self.guestlistView.bounds
        gradientLayer.cornerRadius = 25
        gradientLayer.borderWidth = 0
        
        let backgroundView = UIView(frame: self.guestlistView.bounds)
        backgroundView.layer.insertSublayer(gradientLayer, atIndex: 0)
        self.guestlistView.backgroundColor = UIColor.clearColor()
        self.guestlistView.addSubview(backgroundView)
        self.guestlistView.sendSubviewToBack(backgroundView)
        self.guestlistView.layer.cornerRadius = 25
        self.guestlistView.layer.borderWidth = 0
        
        gradientLayer2.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer2.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer2.colors = [color2, color1]
        gradientLayer2.locations = [0.0, 1.0]
        
        gradientLayer2.frame = self.announcementsView.bounds
        gradientLayer2.cornerRadius = 25
        gradientLayer2.borderWidth = 0
        
        let backgroundView2 = UIView(frame: self.announcementsView.bounds)
        backgroundView2.layer.insertSublayer(gradientLayer2, atIndex: 0)
        self.announcementsView.backgroundColor = UIColor.clearColor()
        self.announcementsView.addSubview(backgroundView2)
        self.announcementsView.sendSubviewToBack(backgroundView2)
        self.announcementsView.layer.cornerRadius = 25
        self.announcementsView.layer.borderWidth = 0
    }
    
//    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return self.allPhotos.count
//    }
//    
//    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
//        //let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MovieGridCell", forIndexPath: indexPath) as! MovieCollectionViewCell
//        //let photo = allPhotos[indexPath.row]
//        //cell.posterImage.setImageWithURL(imageURL!)
//       // return cell
//        
//    }

}
