//
//  PlaylistTracksViewController.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/14/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import NVActivityIndicatorView
import MultipeerConnectivity

class PlaylistTracksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    var playlist: Playlist?
    var playlistTracks: [Track]?
    //var loadedPlaylistImages: [UIImage?]?
    
    //Designates which playlist track controller it is before segue
    var option: String?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    let gradientLayer = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // gradient
        self.view.backgroundColor = UIColor.blackColor()
        gradientLayer.frame = UIScreen.mainScreen().bounds
        let color2 = UIColor(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 0.38).CGColor as CGColorRef
        let color1 = UIColor.clearColor().CGColor as CGColorRef
        gradientLayer.colors = [color1, color1, color2]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        self.view.layer.addSublayer(gradientLayer)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        //Check if the host is the one selecting
        tableView.allowsMultipleSelection = TrackAdder.hostInitialSelection ? true : false
        checkDoneButtonAvailability()
        
        self.title = playlist?.name!
        
        loadPlaylistTracks()
    }
    
    override func viewWillAppear(animated: Bool) {
        //Check if the host is the one selecting
        tableView.allowsMultipleSelection = TrackAdder.hostInitialSelection ? true : false
        doneButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir-Book", size: 16.0)!], forState: UIControlState.Normal)
        checkDoneButtonAvailability()
    }
    
    
    func loadPlaylistTracks() {
        
        //let size = CGSize(width: 30, height:30)
        //startActivityAnimating(size, message: "Loading...", type: NVActivityIndicatorType.AudioEqualizer, color: UIColor.init(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 1.0))
        
        SpotifyClient.getPlaylistTracks(playlist!) { (tracks) in
            self.playlistTracks = tracks
            self.tableView.reloadData()
            
            /*
            //Start a dispatch
            let imageLoads = dispatch_group_create()
            
            for track in self.playlistTracks! {
                dispatch_group_enter(imageLoads)
                
                UIImageView.getUIImageToStore(track.albumImageUrl!, completion: { (image) in
                    track.albumImage = image
                    dispatch_group_leave(imageLoads)
                })
            }
            
            //Receive notification when all images have loaded
            dispatch_group_notify(imageLoads, dispatch_get_main_queue(), {
                self.stopActivityAnimating()
                self.tableView.reloadData()
            })
            */
            
        }
    }
    
    
    
    
    func disableDone() {
        doneButton.enabled = false
        doneButton.tintColor = UIColor.clearColor()
    }
    
    func enableDone() {
        doneButton.enabled = true
        doneButton.tintColor = UIColor.init(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 1.0)
        self.navigationItem.rightBarButtonItem?.title = "Done (\(TrackAdder.selectedTracks.count))"
    }
    
    func checkDoneButtonAvailability() {
        //If a song has been selected (selected tracks array not empty)
        if !TrackAdder.selectedTracks.isEmpty {
            enableDone()
        } else {
            disableDone()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.playlistTracks != nil {
            let rows = (self.playlistTracks?.count)!
            return rows
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("trackCell") as! TrackTableViewCell
        
        let currentTrack = self.playlistTracks![indexPath.row]
        
        cell.trackNameLabel.text = currentTrack.name!
        cell.artistNameLabel.text = currentTrack.artistName
        cell.albumImageView.imageFromUrl(currentTrack.albumImageUrl!)
        
        //Testing to prevent image buffer
        //cell.albumImageView.image = currentTrack.albumImage!
        
        /*
        //Save the album artwork as the table loads
        if let loadedImage = self.loadedPlaylistImages![indexPath.row] {
            cell.albumImageView.image = loadedImage
        } else {
            //The image has not been loaded before, make a network request for the album art
            UIImageView.getUIImageToStore(currentTrack.albumImageUrl!) { (image) in
                self.loadedPlaylistImages![indexPath.row] = image
                cell.albumImageView.image = image
            }
        }*/
        
        
        
        cell.durationLabel.text = Track.convertMillisToReadableTime(currentTrack.duration!)
        
        if TrackAdder.wasSelected(currentTrack) {
            
            cell.accessoryType = .Checkmark
            self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
            
        } else {
            
            cell.accessoryType = .None
            
        }
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
        
        let selectedTrack = self.playlistTracks![indexPath.row]
        TrackAdder.addPossibleChoiceTrack(selectedTrack)
        
        checkDoneButtonAvailability()
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
        
        let selectedTrack = self.playlistTracks![indexPath.row]
        TrackAdder.removePossibleChoiceTrack(selectedTrack)
        
        checkDoneButtonAvailability()
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
    
    @IBAction func didFinishSelectingTracks(sender: AnyObject) {
        let size = CGSize(width: 30, height:30)
        startActivityAnimating(size, message: "Curating...", type: NVActivityIndicatorType.AudioEqualizer, color: UIColor.whiteColor())
        if !TrackAdder.hostInitialSelection {
            let currentUser = PFUser.currentUser()
            let currentParty = currentUser!["party"] as! PFObject
            Playlist.addTrack(TrackAdder.selectedTracks[0], party: currentParty, completion: { (playlist) in
                TrackAdder.clearSelectedTracks()
                self.stopActivityAnimating()
                
                //Notify the playlist queue to reload
                NSNotificationCenter.defaultCenter().postNotificationName("DidAddTrack", object: nil, userInfo: nil)
                self.sendRefreshData()
                
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        } else {
            //Add the tracks to the party
            Track.addSelectedTracksToParty(TrackAdder.selectedTracks) { () in
                self.stopActivityAnimating()
                self.performSegueWithIdentifier("toHostSegue", sender: nil)
                TrackAdder.hostInitialSelection = false
                TrackAdder.clearSelectedTracks()
                
            }
        }
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
