//
//  AlbumTracksViewController.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/17/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import Parse
import StretchHeader

import NVActivityIndicatorView
import MultipeerConnectivity

class AlbumTracksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NVActivityIndicatorViewable {


    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!

    var album: Album?
    var albumTracks: [Track]?

    let gradientLayer = CAGradientLayer()
    let header = StretchHeader()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsMultipleSelection = TrackAdder.hostInitialSelection ? true : false
        checkDoneButtonAvailability()

        self.navigationItem.title = album?.name
        self.navigationController?.navigationBar.barStyle = .BlackTranslucent
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(),NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 16)!]

        // gradient
        self.view.backgroundColor = UIColor.blackColor()
        gradientLayer.frame = UIScreen.mainScreen().bounds
        let color2 = UIColor(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 0.38).CGColor as CGColorRef
        let color1 = UIColor.clearColor().CGColor as CGColorRef
        gradientLayer.colors = [color1, color1, color2]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        self.view.layer.addSublayer(gradientLayer)

        setUpHeader()

        loadAlbumTracks()


    }

    override func viewWillAppear(animated: Bool) {
        //Check if the host is the one selecting
        tableView.allowsMultipleSelection = TrackAdder.hostInitialSelection ? true : false
        doneButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir-Book", size: 16.0)!], forState: UIControlState.Normal)
        checkDoneButtonAvailability()
    }


    func loadAlbumTracks() {
        SpotifyClient.getAlbumTracks(album!) { (tracks) in
            self.albumTracks = tracks
            self.tableView.reloadData()

            //Set the albumImageUrl and albumName fields of the returned track objects
            for track in self.albumTracks! {
                track.albumName = self.album?.name!
                track.albumImageUrl = self.album?.albumImageUrl!

            }
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

    // HEADER

    func setUpHeader() {
        let options = StretchHeaderOptions()
        options.position = .FullScreenTop
        header.stretchHeaderSize(headerSize: CGSizeMake(self.view.frame.width, self.view.frame.width), imageSize: CGSizeMake(self.view.frame.size.width, self.view.frame.width), controller: self, options: options)

        header.imageView.imageFromUrl((album?.albumImageUrl!)!)
        header.imageView.backgroundColor = UIColor.blackColor()

        tableView.tableHeaderView = header
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        header.updateScrollViewOffset(scrollView)
    }

    // TABLEVIEW

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if albumTracks != nil {
            let rows = (self.albumTracks?.count)!
            return rows
        }
        return 0
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 63
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("trackCell") as! TrackTableViewCell
        let currentTrack = self.albumTracks![indexPath.row]

        cell.trackNameLabel.text = currentTrack.name!
        cell.artistNameLabel.text = currentTrack.artistName
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

        let selectedTrack = self.albumTracks![indexPath.row]
        TrackAdder.addPossibleChoiceTrack(selectedTrack)

        checkDoneButtonAvailability()
    }

    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None

        let selectedTrack = self.albumTracks![indexPath.row]
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
