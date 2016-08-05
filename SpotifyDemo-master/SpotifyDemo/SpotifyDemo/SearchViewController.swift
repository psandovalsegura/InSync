
//
//  SearchViewController.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/14/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var queriedTracks: [Track]?
    var queriedAlbums: [Album]?
    var queriedArtists: [Artist]?
    var queriedPlaylists: [Playlist]? //Feature not implemented
    
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = true
        disableDone()
        
        // Do any additional setup after loading the view.
        searchField.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        //Check if the host is the one selecting
        tableView.allowsMultipleSelection = TrackAdder.hostInitialSelection ? true : false
        checkDoneButtonAvailability()
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
    
    //Called when editing ends
    @IBAction func search(sender: AnyObject) {
        SpotifyClient.searchAll(self.searchField.text!) { (returnTuple) in
            self.queriedTracks = returnTuple.tracks
            self.queriedAlbums = returnTuple.albums
            self.queriedArtists = returnTuple.artists
            self.queriedPlaylists = returnTuple.playlists
            
            self.tableView.reloadData()
        }
    }
    
    
    @IBAction func changeSegmentControlSelection(sender: AnyObject) {
        self.tableView.reloadData()
        
        //Button
        if segmentedControl.selectedSegmentIndex != 0 {
            disableDone()
        }
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if segmentedControl.selectedSegmentIndex == 0 {
            //If the user has selected to view only tracks
            if queriedTracks == nil {
                return 0
            } else {
                let trackRows = (self.queriedTracks?.count)!
                return trackRows
            }
            
        } else if segmentedControl.selectedSegmentIndex == 1 {
            //If the user has selected to view only albums
            if queriedAlbums == nil {
                return 0
            } else {
                return (self.queriedAlbums?.count)!
            }
            
        } else if segmentedControl.selectedSegmentIndex == 2 {
            //If the user has selected to view only artists
            if queriedArtists == nil {
                return 0
            } else {
                return (self.queriedArtists?.count)!
            }
            
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if segmentedControl.selectedSegmentIndex == 0 {
            
            //If the user has selected to view only tracks
            let cell = tableView.dequeueReusableCellWithIdentifier("trackCell") as! TrackTableViewCell
            let currentTrack = self.queriedTracks![indexPath.row]
            
            cell.trackNameLabel.text = currentTrack.name!
            cell.artistNameLabel.text = currentTrack.artistName
            cell.albumImageView.imageFromUrl(currentTrack.albumImageUrl!)
            cell.durationLabel.text = Track.convertMillisToReadableTime(currentTrack.duration!)
            
            //Check if the track cell is selected
            if TrackAdder.wasSelected(currentTrack) {
                
                cell.accessoryType = .Checkmark
                self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
                
            } else {
                
                cell.accessoryType = .None
                
            }
            
            return cell
            
        } else if segmentedControl.selectedSegmentIndex == 1 {
            //If the user has selected to view only albums
            let cell = tableView.dequeueReusableCellWithIdentifier("albumCell") as! AlbumTableViewCell
            cell.accessoryType = .DisclosureIndicator
            let currentAlbum = self.queriedAlbums![indexPath.row]
            cell.albumImage.imageFromUrl(currentAlbum.albumImageUrl!)
            cell.albumNameLabel.text = currentAlbum.name!
            
            return cell
        }
        
        //If the user has selected to view only artists
        let cell = tableView.dequeueReusableCellWithIdentifier("artistCell") as! ArtistTableViewCell
        cell.accessoryType = .DisclosureIndicator
        let currentArtist = self.queriedArtists![indexPath.row]
        cell.artistNameLabel.text = currentArtist.name!
        if let imageUrl = currentArtist.profileImageUrl {
            cell.artistProfileImage.imageFromUrl(imageUrl)
        }
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Only track cells should be selectable
        if segmentedControl.selectedSegmentIndex == 0 {
            tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
            let selectedTrack = self.queriedTracks![indexPath.row]
            TrackAdder.addPossibleChoiceTrack(selectedTrack)
        }
        
        checkDoneButtonAvailability()
        
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        //Only track cells should be selectable
        if segmentedControl.selectedSegmentIndex == 0 {
            tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
            let selectedTrack = self.queriedTracks![indexPath.row]
            TrackAdder.removePossibleChoiceTrack(selectedTrack)
        }
        
        checkDoneButtonAvailability()
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    @IBAction func didFinishSelectingTracks(sender: AnyObject) {
        if !TrackAdder.hostInitialSelection {
            let currentUser = PFUser.currentUser()
            let currentParty = currentUser!["party"] as! PFObject
            Playlist.addTrack(TrackAdder.selectedTracks[0], party: currentParty, completion: { (playlist) in
                TrackAdder.clearSelectedTracks()
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        } else {
            //Add the tracks to the party
            Track.addSelectedTracksToParty(TrackAdder.selectedTracks) { () in
                self.performSegueWithIdentifier("toHostSegue", sender: nil)
                TrackAdder.hostInitialSelection = false
                TrackAdder.clearSelectedTracks()
            }
        }
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "toArtistTopTracks" {
            //Get tapped cell
            let cellTapped = sender as! UITableViewCell
            let indexPath = tableView.indexPathForCell(cellTapped)
            let artistVC = segue.destinationViewController as! ArtistTracksViewController
            artistVC.artist = self.queriedArtists![indexPath!.row]
            
        } else if segue.identifier == "toAlbumTracks" {
            //Get tapped cell
            let cellTapped = sender as! UITableViewCell
            let indexPath = tableView.indexPathForCell(cellTapped)
            let albumVC = segue.destinationViewController as! AlbumTracksViewController
            albumVC.album = self.queriedAlbums![indexPath!.row]
        }
        
    }
    
    
}