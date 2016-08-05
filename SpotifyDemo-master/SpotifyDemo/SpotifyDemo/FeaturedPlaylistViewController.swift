//
//  FeaturedPlaylistViewController.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/15/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit

class FeaturedPlaylistViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var playlists: [Playlist]?
    
    
    @IBOutlet weak var tableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set up Table View
        tableView.dataSource = self
        tableView.delegate = self
        
        loadPlaylists()
        
    }
    
    func loadPlaylists() {
        SpotifyClient.getFeaturedPlaylists { (playlists) in
            self.playlists = playlists
            self.tableView.reloadData()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.playlists != nil {
            return (self.playlists?.count)!
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("featplaylistCell") as! PlaylistTableViewCell
        cell.accessoryType = .DisclosureIndicator
        cell.playlistNameLabel.text = self.playlists![indexPath.row].name!
        
        return cell
    }
    
    //Cell deselection
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let path = tableView.indexPathForSelectedRow {
            
            tableView.deselectRowAtIndexPath(path, animated: true)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let playlistTracksVC = segue.destinationViewController as! PlaylistTracksViewController
        
        let cellTapped = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cellTapped)
        playlistTracksVC.playlist = self.playlists![indexPath!.row]
        playlistTracksVC.option = "featuredplaylist"
    }


}
