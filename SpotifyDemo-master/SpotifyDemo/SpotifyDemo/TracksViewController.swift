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

class TracksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable {

    var userTracks: [Track]?
    var currentUser = PFUser.currentUser()
    var currentParty = PFUser.currentUser()!["party"] as! PFObject?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!


    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = TrackAdder.hostInitialSelection ? true : false

        checkDoneButtonAvailability()

        // Do any additional setup after loading the view.
        loadUserTracks()
    }

    override func viewWillAppear(animated: Bool) {
        //Check if the host is the one selecting
        tableView.allowsMultipleSelection = TrackAdder.hostInitialSelection ? true : false
        checkDoneButtonAvailability()

//        if !TrackAdder.hostInitialSelection {
//            self.doneButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: Selector("didFinishSelectingTracks"))
//        }
    }

    func loadUserTracks() {
        SpotifyClient.getCurrentUserSavedTracks { (tracks) in
            self.userTracks = tracks
            self.tableView.reloadData()
        }
    }

    func disableDone() {
        doneButton.enabled = true
        doneButton.tintColor = UIColor.clearColor()
    }

    func enableDone() {
        doneButton.enabled = true
        doneButton.tintColor = UIColor(colorLiteralRed: 0/255.0, green: 122/255.0, blue: 255/255.0, alpha: 1.0)
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
        if !(TrackAdder.hostInitialSelection) {
            Track.getTrackFromPartyWithUri(currentParty!, trackUri: currentTrack.uri!, completion: { (tracks) in
                if (tracks.count > 0) {
                    print("Played \(tracks.count) times")
                    //  countLabel.text = "Played \(tracks.count) times"
                }
                })
        }

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

    @IBAction func didFinishSelectingTracks(sender: AnyObject) {
        let size = CGSize(width: 30, height:30)
        startActivityAnimating(size, message: "Curating...", type: NVActivityIndicatorType.AudioEqualizer, color: UIColor.blackColor())
        if !TrackAdder.hostInitialSelection {
            let currentUser = PFUser.currentUser()
            let currentParty = currentUser!["party"] as! PFObject
            Playlist.addTrack(TrackAdder.selectedTracks[0], party: currentParty, completion: { (playlist) in
                TrackAdder.clearSelectedTracks()
                self.stopActivityAnimating()
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
