//
//  TracksViewController.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/14/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import NVActivityIndicatorView
import MultipeerConnectivity

class TracksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    var userTracks: [Track]?
    var currentUser = PFUser.currentUser()
    var currentParty = PFUser.currentUser()!["party"] as! PFObject?

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
        tableView.allowsMultipleSelection = TrackAdder.hostInitialSelection ? true : false
        
        checkDoneButtonAvailability()
        loadUserTracks()
    }

    override func viewWillAppear(animated: Bool) {
        //Check if the host is the one selecting
        tableView.allowsMultipleSelection = TrackAdder.hostInitialSelection ? true : false
        doneButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir-Book", size: 16.0)!], forState: UIControlState.Normal)
        
        checkDoneButtonAvailability()
    }

    func loadUserTracks() {
        SpotifyClient.getCurrentUserSavedTracks { (tracks) in
            self.userTracks = tracks
            self.tableView.reloadData()
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
        if self.userTracks != nil {
            let rows = (self.userTracks?.count)!
            return rows
        }

        return 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("trackCell") as! TrackTableViewCell
        let currentTrack = self.userTracks![indexPath.row]
        
        cell.trackNameLabel.text = currentTrack.name!
        cell.artistNameLabel.text = currentTrack.artistName
        cell.albumImageView.imageFromUrl(currentTrack.albumImageUrl!)
        cell.durationLabel.text = Track.convertMillisToReadableTime(currentTrack.duration!)
//        if !(TrackAdder.hostInitialSelection) {
//            Track.getTrackFromPartyWithUri(currentParty!, trackUri: currentTrack.uri!, completion: { (tracks) in
//                if (tracks.count > 0) {
//                    print("Played \(tracks.count) times")
//                    //  countLabel.text = "Played \(tracks.count) times"
//                }
//                })
//        }

        if TrackAdder.wasSelected(currentTrack) {

            cell.accessoryType = .Checkmark
            self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)

        } else {

            cell.accessoryType = .None

        }

        return cell

    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        self.tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
        
        let selectedTrack = self.userTracks![indexPath.row]
        TrackAdder.addPossibleChoiceTrack(selectedTrack)
        
        checkDoneButtonAvailability()
    }

    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None

        let selectedTrack = self.userTracks![indexPath.row]
        TrackAdder.removePossibleChoiceTrack(selectedTrack)

        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        checkDoneButtonAvailability()
    }
    
    //Change the selected cell color
    
    
    
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
            print("The current party: \(currentParty)  The host initial selection is: \(TrackAdder.hostInitialSelection)  Tracks selected: \(TrackAdder.selectedTracks)")
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
