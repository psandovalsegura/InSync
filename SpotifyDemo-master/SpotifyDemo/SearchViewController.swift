//
//  SearchViewController.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/14/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import NVActivityIndicatorView
import MultipeerConnectivity

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, NVActivityIndicatorViewable {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var tableView: UITableView!
    
    var queriedTracks: [Track]?
    var queriedAlbums: [Album]?
    var queriedArtists: [Artist]?
    var queriedPlaylists: [Playlist]? //Feature not implemented
    
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    
    @IBOutlet weak var noResultsLabel: UIView!
    
    var viewForSearch:UIView!
    let gradientLayer = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Search Spotify"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = true
        
        self.edgesForExtendedLayout = UIRectEdge.None

        disableDone()

        searchField.delegate = self
        
        // Gradient
        self.view.backgroundColor = UIColor.blackColor()
        gradientLayer.frame = UIScreen.mainScreen().bounds
        let color2 = UIColor(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 0.38).CGColor as CGColorRef
        let color1 = UIColor.clearColor().CGColor as CGColorRef
        gradientLayer.colors = [color1, color1, color2]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        self.view.layer.addSublayer(gradientLayer)
        
        
        // Search and Segmented Control Attributes
        searchField.attributedPlaceholder = NSAttributedString(string: "Search Music", attributes: [NSForegroundColorAttributeName:UIColor.init(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 0.4)])
        let attr = NSDictionary(object: UIFont(name: "Avenir-Book", size: 14.0)!, forKey: NSFontAttributeName)
        segmentedControl.setTitleTextAttributes(attr as [NSObject : AnyObject] , forState: .Normal)
    }
    
    override func viewWillAppear(animated: Bool) {
        //Check if the host is the one selecting
        tableView.allowsMultipleSelection = TrackAdder.hostInitialSelection ? true : false
        
        //Artist and Album cell deselection
        if let path = tableView.indexPathForSelectedRow {
            
            tableView.deselectRowAtIndexPath(path, animated: true)
            
        }
        
        doneButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir-Book", size: 16.0)!], forState: UIControlState.Normal)
        checkDoneButtonAvailability()
        
        noResultsLabel.hidden = true
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
    
    //Called when editing ends
    @IBAction func search(sender: AnyObject) {
        //The activity view during search appears like a glitch since the search is apparently pretty fast
        //let size = CGSize(width: 30, height:30)
        //startActivityAnimating(size, message: "Curating...", type: NVActivityIndicatorType.AudioEqualizer, color: UIColor.blackColor())
        SpotifyClient.searchAll(self.searchField.text!) { (returnTuple) in
            self.queriedTracks = returnTuple.tracks
            self.queriedAlbums = returnTuple.albums
            self.queriedArtists = returnTuple.artists
            self.queriedPlaylists = returnTuple.playlists
            
            self.tableView.reloadData()
            //self.stopActivityAnimating()
        }
    }
    
    func noResultsFound() {
        noResultsLabel.hidden = false
    }
    
    func resultsFound() {
        noResultsLabel.hidden = true
    }
    
    @IBAction func changeSegmentControlSelection(sender: AnyObject) {
        self.tableView.reloadData()
        
        checkDoneButtonAvailability()
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if segmentedControl.selectedSegmentIndex == 0 {
            //If the user has selected to view only tracks
            if queriedTracks == nil {
                return 0
            } else if (queriedTracks?.isEmpty)! {
                noResultsFound()
                return 0
            } else {
                resultsFound()
                let trackRows = (self.queriedTracks?.count)!
                return trackRows
            }
            
        } else if segmentedControl.selectedSegmentIndex == 1 {
            //If the user has selected to view only albums
            if queriedAlbums == nil {
                return 0
            } else if (queriedAlbums?.isEmpty)! {
                noResultsFound()
                return 0
            } else {
                resultsFound()
                return (self.queriedAlbums?.count)!
            }
            
        } else if segmentedControl.selectedSegmentIndex == 2 {
            //If the user has selected to view only artists
            if queriedArtists == nil {
                return 0
            } else if (queriedArtists?.isEmpty)! {
                noResultsFound()
                return 0
            } else {
                resultsFound()
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
            cell.backgroundColor = UIColor.blackColor()
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
        cell.backgroundColor = UIColor.blackColor()
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
                
                //Notify the playlist queue to reload
                NSNotificationCenter.defaultCenter().postNotificationName("DidAddTrack", object: nil, userInfo: nil)
                self.sendRefreshData()
                
                self.stopActivityAnimating()
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
    

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
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