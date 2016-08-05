//
//  OptionsViewController.swift
//  InSync
//
//  Created by Pedro Sandoval Segura on 7/14/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit

class OptionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //Possible options
    let options = ["My Playlists", "Featured Playlists", "Saved Tracks", "Search"]
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set up Table View
        tableView.dataSource = self
        tableView.delegate = self
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("spotifyOptionsCell") as! SpotifyOptionsTableViewCell
        cell.accessoryType = .DisclosureIndicator
        cell.optionLabel.text = self.options[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedOptionIndex = indexPath.row
        switch selectedOptionIndex {
        case 0:
            self.performSegueWithIdentifier("toUserPlaylists", sender: nil)
        case 1:
            self.performSegueWithIdentifier("toFeaturedPlaylists", sender: nil)
        case 2:
            self.performSegueWithIdentifier("toUserSavedTracks", sender: nil)
        case 3:
            self.performSegueWithIdentifier("toSearchTracks", sender: nil)
        default:
            print("Error choosing option in OptionsViewController")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Cell deselection
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let path = tableView.indexPathForSelectedRow {
            
            tableView.deselectRowAtIndexPath(path, animated: true)
        }
    }
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "toHot100" {
            let playlistVC = segue.destinationViewController as! PlayViewController
            
        }
     }
    
    
}
