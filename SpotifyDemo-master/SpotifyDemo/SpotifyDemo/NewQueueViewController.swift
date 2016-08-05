//
//  NewQueueViewController.swift
//  InSync
//
//  Created by Olivia Gregory on 7/17/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import StretchHeader
import MEVFloatingButton
import MultipeerConnectivity

class NewQueueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, MEVFloatingButtonDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentHeaderView: UIView!
    
    @IBOutlet weak var nowPlayingView: UIView!
    @IBOutlet weak var firstSongName: UILabel!
    @IBOutlet weak var firstArtistName: UILabel!
    var header : StretchHeader!
    var navigationView = UIView()
    var playlistID: String?
    var upvotes: [PFObject]?
    var downvotes: [PFObject]?
    
    var button: MEVFloatingButton = MEVFloatingButton()
    
    //Note: pass this in for the first time
    var tracks: [PFObject]?
    let currentUser = PFUser.currentUser()
    var headerView: UIView?
    let currentParty = PFUser.currentUser()!["party"] as! PFObject
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHeaderView()
        setUpTable {
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.view.addSubview(self.tableView)
        }
        
        upvotes = currentUser!["upvotes"] as! [PFObject]
        downvotes = currentUser!["downvotes"] as! [PFObject]
//        tableView.delegate = self
//        tableView.dataSource = self
//        view.addSubview(tableView)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewQueueViewController.refresh), name: "SongDidChange", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewQueueViewController.refresh), name: "UpDownVoted", object: nil)
        
        
        //        NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(NewQueueViewController.onTimer), userInfo: nil, repeats: true)
        
        //        setUpTable {
        //            //
        //        }
        // NavigationHeader
        //let navibarHeight : CGFloat = CGRectGetHeight(navigationController!.navigationBar.bounds)
        //let statusbarHeight : CGFloat = UIApplication.sharedApplication().statusBarFrame.size.height
        //navigationView = UIView()
        //navigationView.frame = CGRectMake(0, 0, view.frame.size.width, navibarHeight + statusbarHeight)
        //navigationView.backgroundColor = UIColor.darkGrayColor()
        //navigationView.alpha = 0.0
        //view.addSubview(navigationView)
        
        //        setupHeaderView()
    }
    
    /*
     func onTimer() {
     let query = PFQuery(className: "Playlist")
     query.includeKey("tracks")
     
     do {
     let playlist = try query.getObjectWithId(playlistID!)
     //print(playlist)
     let tracksArray = playlist["tracks"] as! [PFObject]
     self.tracks = tracksArray
     
     } catch {
     print(error)
     }
     self.tableView.reloadData()
     setupHeaderView()
     
     //        is there any way to do this in background?
     
     //        query.getObjectInBackgroundWithId(playlistID!) { (playlist: PFObject?, error: NSError?) in
     //            if error == nil {
     //                let trackArray = playlist!["tracks"] as! [PFObject]
     //                self.tracks = trackArray
     //            } else {
     //                print(error!)
     //            }
     //            self.tableView.reloadData()
     //            self.setupHeaderView()
     //        }
     }
     */
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //self.navigationController?.setNavigationBarHidden(true, animated: true)
        //self.navigationController?.interactivePopGestureRecognizer?.delegate = nil;
        print("new queue viewWillAppear, loading...")
        
        refresh()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpTable(completion: () -> Void) {
        //populate array
        let currentPlaylist = Party.getCurrentPlaylist(currentParty)
        self.playlistID = currentPlaylist.objectId
        currentPlaylist.fetchIfNeededInBackgroundWithBlock { (fetchPlaylist:PFObject?, error:NSError?) in
            if error == nil {
                self.playlistID = fetchPlaylist!.objectId

                let tracksArray = fetchPlaylist!["tracks"] as! [PFObject]
                for track in tracksArray {
                    track.fetchIfNeededInBackgroundWithBlock({ (track:PFObject?, error:NSError?) in
                        self.tracks = tracksArray
                        completion()
                    })
                }
//                self.tracks = tracksArray
//                completion()
                
            } else {
                print("error fetching currentPlaylist in setuptable in newqueue vc")
            }
        }
    }
    func setupHeaderView() {
        currentParty.fetchInBackgroundWithBlock({ (fetchParty:PFObject?, error:NSError?) in
            if error == nil {
                
                let options = StretchHeaderOptions()
                options.position = .UnderNavigationBar
                
                self.header = StretchHeader()
                
                let nowPlayingSong = fetchParty!["now_playing"] as? PFObject
                nowPlayingSong?.fetchIfNeededInBackgroundWithBlock({ (nowplayingSong:PFObject?, error:NSError?) in
                    print("nowplaying song in newqueue setupheaderview fetched")
                    self.firstSongName.text = nowplayingSong!["name"] as? String
                    self.firstArtistName.text = nowplayingSong!["artist"] as? String
                    self.header.imageView.imageFromUrl((nowplayingSong!["albumImageURL"] as? String)!)
                })
                
                
                self.header.stretchHeaderSize(headerSize: CGSizeMake(self.view.frame.size.width, 220),
                    imageSize: CGSizeMake(self.view.frame.size.width, 220),
                    controller: self,
                    options: options)
                self.header.addSubview(self.nowPlayingView)
                self.tableView.tableHeaderView = self.header
            } else {
                print("Error fetching currentparty in setupHeaderView in newqueue vc")
            }
        })
    }
    

    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        header.updateScrollViewOffset(scrollView)
        
        // NavigationHeader alpha update
        let offset : CGFloat = scrollView.contentOffset.y
        if (offset > 50) {
            let alpha : CGFloat = min(CGFloat(1), CGFloat(1) - (CGFloat(50) + (navigationView.frame.height) - offset) / (navigationView.frame.height))
            navigationView.alpha = CGFloat(alpha)
            
        } else {
            navigationView.alpha = 0.0;
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("queueCell", forIndexPath: indexPath) as! QueueTableViewCell
        
        setUpTable {
            let track = self.tracks![indexPath.row]
            track.fetchIfNeededInBackgroundWithBlock({ (track:PFObject?, error:NSError?) in
            cell.songNameLabel.text = track!["name"] as? String
            cell.artistNameLabel.text = track!["artist"] as? String
            cell.votesCountLabel.text = track!["votes"].stringValue
            cell.selectionStyle = UITableViewCellSelectionStyle.None
                
                if self.upvotes!.contains(track!) {
                    cell.upvoteButton.setImage(UIImage(named: "selectedButton"), forState: UIControlState.Normal)
                    cell.downvoteButton.setImage(UIImage(named: "down-arrow-1"), forState: UIControlState.Normal)
                } else if self.downvotes!.contains(track!) {
                    cell.upvoteButton.setImage(UIImage(named: "plain-triangle-1"), forState: UIControlState.Normal)
                    cell.downvoteButton.setImage(UIImage(named: "selectedButton2"), forState: UIControlState.Normal)
                } else {
                    cell.upvoteButton.setImage(UIImage(named: "plain-triangle-1"), forState: UIControlState.Normal)
                    cell.downvoteButton.setImage(UIImage(named: "down-arrow-1"), forState: UIControlState.Normal)
                }
        })
        
            //            cell.albumCoverImageView.imageFromUrl(track["albumImageURL"] as! String)
            
        }
        
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = tracks?.count {
            return count
        } else { return 0 }
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 81;
    }
    
    
    
    
    /// testing ////
    func refresh() {
        print("REFRESH FUNCTION CALLED")
        setupHeaderView()
        setUpTable { 
            self.tableView.reloadData()
        }
    }
    func sendRefreshData() {
        let key = "queue-key"
        let keyData = key.dataUsingEncoding(NSUTF8StringEncoding)
        do {
            try appDelegate.mpcHandler.session.sendData(keyData!, toPeers: appDelegate.mpcHandler.session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
            print("NewQueueVC sent signal to refresh queue through session")
        } catch {
            print("NewQueueVC: error sending refresh queue signal")
        }
    }
    ////////
    
    
    
    
    
    @IBAction func didTapUpvote(sender: AnyObject) {
        let buttonPosition: CGPoint = sender.convertPoint(CGPointZero, toView: self.tableView)
        let button = sender as? UIButton
        let image = UIImage(named: "selectedButton")
        let unselectedImage = UIImage(named: "plain-triangle-1")
        let indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition)
//        let cell = self.tableView.cellForRowAtIndexPath(indexPath!)
        if (indexPath != nil) {
            Track.getTrackFromParty(currentParty, newTrack: tracks![(indexPath?.row)!], completion: { (track) in
                User.getUpdatedParseUser(self.currentUser!, completion: { (user) in
                    let track = self.tracks![((indexPath?.row)!)]
                    let currentUpvotes = user["upvotes"] as! [String]
                    
                    //If not already upvoted, upvote (included: if downvoted before, upvote twice)
                    //unset down button? -- make an outlet??
                    
                    if (!currentUpvotes.contains(track.objectId!)) {
                        print("not upvoted")
                        Track.upvote(track, user: self.currentUser!, completion: {
//                            self.tableView.reloadData()
                            self.refresh()
                        })
                        button?.setImage(image, forState: UIControlState.Normal)
                        
//                        self.tableView.reloadData()
                        
                    } else {
                        print("already upvoted")
                        Track.undoUpvote(track, user: self.currentUser!)
                        button?.setImage(unselectedImage, forState: UIControlState.Normal)
                        
//                        self.tableView.reloadData()
                        self.refresh()
                        
                    }
                    
                })
                
                self.sendRefreshData()
                
            })
            
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func didTapDownvote(sender: AnyObject) {
        let buttonPosition: CGPoint = sender.convertPoint(CGPointZero, toView: self.tableView)
        let button = sender as? UIButton
        let indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition)
//        let cell = self.tableView.cellForRowAtIndexPath(indexPath!)
        let image = UIImage(named: "selectedButton2")
        let unselectedImage = UIImage(named: "down-arrow-1")
        
        if (indexPath != nil) {
            Track.getTrackFromParty(currentParty, newTrack: tracks![(indexPath?.row)!], completion: { (track) in
                User.getUpdatedParseUser(self.currentUser!, completion: { (user) in
                    let track = self.tracks![((indexPath?.row)!)]
                    let currentDownvotes = user["downvotes"] as! [String]
                    
                    //If not already upvoted, upvote (included: if downvoted before, upvote twice)
                    //unset down button? -- make an outlet??
                    
                    if (!currentDownvotes.contains(track.objectId!)) {
                        
                        print("not downvoted")
                        print(track)
                        Track.downvote(track, user: self.currentUser!, completion: {
//                            self.tableView.reloadData()
                            self.refresh()
                            
                            
                        })
                        button?.setImage(image, forState: UIControlState.Normal)
                        
                        
                    } else {
                        print("already downvoted")
                        Track.undoDownvote(track, user: self.currentUser!)
                        button?.setImage(unselectedImage, forState: UIControlState.Normal)
                        
//                        self.tableView.reloadData()
                        self.refresh()
                        
                        
                        
                    }
                })
                
                self.sendRefreshData()
                
            })
            
        }
    }
}
