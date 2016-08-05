//
//  QueueViewController.swift
//  InSync
//
//  Created by Olivia Gregory on 7/13/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import AFNetworking

class QueueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    //try with table view controller, maybe?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var currentHeaderView: UIView!
    @IBOutlet weak var firstImageView: UIImageView!
    @IBOutlet weak var firstSongName: UILabel!
    @IBOutlet weak var firstArtistName: UILabel!
    
    //Note: pass this in for the first time
    var tracks: [PFObject]?
    let currentUser = PFUser.currentUser()
    var currentParty: PFObject?
    var headerView: UIView?
    var kTableHeaderHeight: CGFloat = 250.00
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        currentParty = currentUser!["party"] as? PFObject
        let currentPlaylist = Party.getCurrentPlaylist(currentParty!)
        let tracksArray = currentPlaylist["tracks"] as! [PFObject]
        
        tracks = tracksArray
        //when merge with Nancy, use "now_playing" field instead
        firstSongName.text = tracks![0]["name"] as? String
        firstArtistName.text = tracks![0]["artist"] as? String
        firstImageView.imageFromUrl((tracks![0]["albumImageURL"] as? String)!)
        
        headerView = tableView.tableHeaderView
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView!)
        tableView.contentInset = UIEdgeInsets(top: kTableHeaderHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -kTableHeaderHeight)
        updateHeaderView()
        
        tableView.reloadData()
    }
    
    
    
    func updateHeaderView() {
        var headerRect = CGRect(x: 0, y: -kTableHeaderHeight, width: tableView.bounds.width, height: kTableHeaderHeight)
        if tableView.contentOffset.y < -kTableHeaderHeight {
            headerRect.origin.y = tableView.contentOffset.y
            headerRect.size.height = -tableView.contentOffset.y
        }
        headerView?.frame = headerRect
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        updateHeaderView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapUpvote(sender: AnyObject) {
        let buttonPosition: CGPoint = sender.convertPoint(CGPointZero, toView: self.tableView)
        let indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition)
        //let cell = self.tableView.cellForRowAtIndexPath(indexPath!) as! QueueTableViewCell
        
        
        if (indexPath != nil) {
            Track.getTrackFromParty(currentParty!, newTrack: tracks![(indexPath?.row)!], completion: { (track) in
                Track.upvote(self.tracks![((indexPath?.row)! + 1)], user: self.currentUser!) {
                    self.tableView.reloadData()
                }
            })
            
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func didTapDownvote(sender: AnyObject) {
        let buttonPosition: CGPoint = sender.convertPoint(CGPointZero, toView: self.tableView)
        let indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition)
        //let cell = self.tableView.cellForRowAtIndexPath(indexPath!) as! QueueTableViewCell
        
        if (indexPath != nil) {
            Track.getTrackFromParty(currentParty!, newTrack: tracks![(indexPath?.row)! + 1], completion: { (track) in
                Track.downvote(self.tracks![(indexPath?.row)!], user: self.currentUser!) {
                    self.tableView.reloadData()
                }
            })
            
        }
    }
    
    
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //        if (indexPath.row == 0) {
        //            print(indexPath.row)
        //            let cell = tableView.dequeueReusableCellWithIdentifier("nowPlayingCell", forIndexPath: indexPath) as! NowPlayingTableViewCell
        //
        //            let track = tracks![0]
        //                cell.songNameLabel.text = track["name"] as? String
        //                cell.artistNameLabel.text = track["artist"] as? String
        //
        //                cell.albumCoverImageView.imageFromUrl(track["albumImageURL"] as! String)
        //            return cell
        //        } else {
        let cell = tableView.dequeueReusableCellWithIdentifier("queueCell", forIndexPath: indexPath) as! QueueTableViewCell
        let track = tracks![indexPath.row + 1]
        cell.songNameLabel.text = track["name"] as? String
        cell.artistNameLabel.text = track["artist"] as? String
        cell.votesCountLabel.text = track["votes"].stringValue
        
        cell.albumCoverImageView.imageFromUrl(track["albumImageURL"] as! String)
        //            if !UIAccessibilityIsReduceTransparencyEnabled() {
        //                cell.backgroundColor = UIColor.clearColor()
        //
        //                let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        //                let blurEffectView = UIVisualEffectView(effect: blurEffect)
        //
        //                //always fill the view
        //                blurEffectView.frame = self.view.bounds
        //                blurEffectView.autoresizingMask  = [.FlexibleWidth, .FlexibleHeight]
        //                cell.addSubview(blurEffectView) //if you have more UIViews, use an insertSubview API to place it where needed
        //            } else {
        //                cell.backgroundColor = UIColor.blackColor()
        //            }
        
        return cell
        //     }
    }
    
    func tableView(tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return ((tracks?.count)! - 1)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        //        if (indexPath.row == 0) {
        //            return 237;
        //        }
        //        else {
        return 81;
        //}
        
    }
    
}
