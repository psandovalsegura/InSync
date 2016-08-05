//
//  HostQueueViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/22/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import StretchHeader
import MEVFloatingButton
import MGSwipeTableCell

class HostQueueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, MEVFloatingButtonDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentHeaderView: UIView!
    
    @IBOutlet weak var nowPlayingView: UIView!
    @IBOutlet weak var firstSongName: UILabel!
    @IBOutlet weak var firstArtistName: UILabel!
    var header : StretchHeader!
    var navigationView = UIView()
    var playlistID: String?
    
    var button: MEVFloatingButton = MEVFloatingButton()
    
    //Note: pass this in for the first time
    var tracks: [PFObject]?
    let currentUser = PFUser.currentUser()
    var headerView: UIView?
    let currentParty = PFUser.currentUser()!["party"] as! PFObject
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(HostQueueViewController.refresh), name: "SongDidChange", object: nil)
        
        
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
        currentPlaylist.fetchInBackgroundWithBlock { (fetchPlaylist:PFObject?, error:NSError?) in
            if error == nil {
                self.playlistID = fetchPlaylist!.objectId
                let tracksArray = fetchPlaylist!["tracks"] as! [PFObject]
                self.tracks = tracksArray
                completion()
            } else {
                print("error fetching currentPlaylist in setuptable in newqueue vc")
            }
        }
    }
    func setupHeaderView() {
        
        let nowPlayingSong = currentParty["now_playing"] as? PFObject
        print("now playing header: \(nowPlayingSong)")
        print("nowplaying song in newqueue setupheaderview fetched")
        self.firstSongName.text = nowPlayingSong!["name"] as? String
        self.firstArtistName.text = nowPlayingSong!["artist"] as? String
        
        let options = StretchHeaderOptions()
        options.position = .UnderNavigationBar
        
        self.header = StretchHeader()
        self.header.stretchHeaderSize(headerSize: CGSizeMake(self.view.frame.size.width, 220), imageSize: CGSizeMake(self.view.frame.size.width, 220), controller: self, options: options)
        
        if let albumImage = nowPlayingSong!["albumImageURL"] as? String {
            self.header.imageView.imageFromUrl(albumImage)
        }
        self.header.addSubview(self.nowPlayingView)
        self.tableView.tableHeaderView = self.header
    }
    
    func refresh() {
        setupHeaderView()
        setUpTable {
            self.tableView.reloadData()
        }
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
        //        let cell = tableView.dequeueReusableCellWithIdentifier("queueCell", forIndexPath: indexPath) as! QueueTableViewCell
        //        let track = tracks![indexPath.row]
        //        cell.songNameLabel.text = track["name"] as? String
        //        cell.artistNameLabel.text = track["artist"] as? String
        //        cell.votesCountLabel.text = track["votes"].stringValue
        //        cell.selectionStyle = UITableViewCellSelectionStyle.None
        //
        //        cell.albumCoverImageView.imageFromUrl(track["albumImageURL"] as! String)
        //
        //        return cell
        
        let reuseIdentifier = "queueCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! QueueSwipeTableCell!

        let track = tracks![indexPath.row]
        cell.songNameLabel.text = track["name"] as? String
        cell.artistNameLabel.text = track["artist"] as? String
        cell.votesCountLabel.text = track["votes"].stringValue
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.albumCoverImageView.imageFromUrl(track["albumImageURL"] as! String)
        
//        //configure left buttons
//        cell.leftButtons = [MGSwipeButton(title: "Up", backgroundColor: UIColor.greenColor())]
//        //        cell.leftButtons = [MGSwipeButton(title: "", icon: UIImage(named:"transparenttriangle1.png"), backgroundColor: UIColor.greenColor())]
//        cell.leftSwipeSettings.transition = MGSwipeTransition.Drag
//        
//        //configure right buttons
//        cell.rightButtons = [MGSwipeButton(title: "Down", backgroundColor: UIColor.redColor())]
//        cell.rightSwipeSettings.transition = MGSwipeTransition.Drag
        
        
        //expandable
//        cell.leftExpansion.
        
            cell.leftButtons = [MGSwipeButton(title: "", icon: UIImage(named:"transparenttriangle1.png"), backgroundColor: UIColor.greenColor())]
            cell.leftSwipeSettings.transition = MGSwipeTransition.Drag
            
            cell.rightButtons = [MGSwipeButton(title: "Down", backgroundColor: UIColor.redColor())]
            cell.rightSwipeSettings.transition = MGSwipeTransition.Drag

        
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
    
    @IBAction func didTapUpvote(sender: AnyObject) {
        let buttonPosition: CGPoint = sender.convertPoint(CGPointZero, toView: self.tableView)
        let button = sender as? UIButton
        let image = UIImage(named: "selectedButton")
        let unselectedImage = UIImage(named: "plain-triangle-1")
        let indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition)
        if (indexPath != nil) {
            Track.getTrackFromParty(currentParty, newTrack: tracks![(indexPath?.row)!], completion: { (track) in
                
                let track = self.tracks![((indexPath?.row)!)]
                //If not already upvoted, upvote (included: if downvoted before, upvote twice)
                //unset down button? -- make an outlet??
                //if (!(Track.checkIfUpvoted(self.currentUser!, parseTrack: track))) {
                print("not upvoted")
                print(track)
                Track.upvote(self.tracks![(indexPath?.row)!], user: self.currentUser!, completion: {
                    self.tableView.reloadData()
                })
                //                Track.upvote(self.tracks![((indexPath?.row)!)], user: self.currentUser!)
                button?.setImage(image, forState: UIControlState.Normal)
                // } else {
                //Track.undoUpvote
                // button?.setImage(unselectedImage, forState: UIControlState.Normal)
                // }
                //                self.tableView.reloadData()
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
        let cell = self.tableView.cellForRowAtIndexPath(indexPath!)
        let image = UIImage(named: "selectedButton2")
        let unselectedImage = UIImage(named: "down-arrow-1")
        
        if (indexPath != nil) {
            Track.getTrackFromParty(currentParty, newTrack: tracks![(indexPath?.row)!], completion: { (track) in
                
                let track = self.tracks![((indexPath?.row)!)]
                //If not already downvoted, downvote (included: if downvoted before, upvote twice)
                //unset down button? -- make an outlet??
                if (!Track.checkIfDownvoted(self.currentUser!, parseTrack: track)) {
                    Track.downvote(self.tracks![(indexPath?.row)!], user: self.currentUser!, completion: {
                        self.tableView.reloadData()
                    })
                    //                    Track.downvote(self.tracks![((indexPath?.row)!)], user: self.currentUser!)
                    button?.setImage(image, forState: UIControlState.Normal)
                } else {
                    //Track.undoUpvote
                    button?.setImage(unselectedImage, forState: UIControlState.Normal)
                    self.tableView.reloadData()
                }
                //                self.tableView.reloadData()
            })
            
        }
    }
}


