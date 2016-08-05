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
    let options = ["My Playlists", "Featured Playlists", "Saved Tracks", "Search Spotify"]
    
    @IBOutlet weak var tableView: UITableView!
    let gradientLayer = CAGradientLayer()

    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if TrackAdder.hostInitialSelection {
            self.title = "Choose Tracks"
        } else {
            self.title = "Request Track"
        }
        
        
        //Set up Table View
        tableView.dataSource = self
        tableView.delegate = self

        // gradient
        self.view.backgroundColor = UIColor.blackColor()
        gradientLayer.frame = UIScreen.mainScreen().bounds
        let color2 = UIColor(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 0.38).CGColor as CGColorRef
        let color1 = UIColor.clearColor().CGColor as CGColorRef
        gradientLayer.colors = [color1, color1, color2]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        self.view.layer.addSublayer(gradientLayer)
        
        cancelButton.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir-Book", size: 16.0)!], forState: UIControlState.Normal)
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("spotifyOptionsCell") as! SpotifyOptionsTableViewCell
        cell.accessoryType = .DisclosureIndicator
        cell.optionLabel.text = self.options[indexPath.row]
        cell.backgroundColor = UIColor.blackColor()
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
     
    @IBAction func onCancelButton(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
