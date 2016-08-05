//
//  LitMeterViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/27/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import BAFluidView
import Parse

class LitMeterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // NOTE: Call the function fillMeter with the amount (from 0.0 to 1.0) to fill, every time litness changes!
    
    // Lit Meter
    let meterGradientLayer = CAGradientLayer()
    var meterView:UIView!
    var fluidView:BAFluidView!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UITableViewHeaderFooterView!
    
    @IBOutlet weak var headerSongLabel: UILabel!
    @IBOutlet weak var headerArtistAlbumLabel: UILabel!
    @IBOutlet weak var litnessLabel: UILabel!
    
    let currentParty = PFUser.currentUser()!["party"] as! PFObject
    var previousPlaylist: [PFObject] = []
    
    var selectedIndexPath: NSIndexPath? = nil
    var percentage: CGFloat?
    
    // MARK: ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        let currentSong = currentParty["now_playing"] as! PFObject
        self.headerSongLabel.text = currentSong["name"] as? String
        self.headerArtistAlbumLabel.text = (currentSong["artist"] as? String)! + " - " + (currentSong["albumName"] as? String)!
        
        litnessLabel.text = "\(SpotifyClient.CURRENT_USER.personalLitness!)%"
        setUpMeter()
        setUpFluidView()
        self.view.bringSubviewToFront(tableView)
        setUpButton()
        
        NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(LitMeterViewController.onTimer), userInfo: nil, repeats: true)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)

        let litness = CGFloat(SpotifyClient.CURRENT_USER.personalLitness!)
        litnessLabel.text = "\(SpotifyClient.CURRENT_USER.personalLitness!)%"
        
        percentage = CGFloat(litness / 100)
        fillMeter(percentage)
        getPreviousTracks {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        self.becomeFirstResponder()
    }
    
    // MARK: Visual Setup
    
    func setUpMeter() {
        let clearish = UIColor.init(white: 0.0, alpha: 0.75).CGColor as CGColorRef
        let black = UIColor.blackColor().CGColor as CGColorRef
        let clear = UIColor.init(white: 0.0, alpha: 0.38).CGColor as CGColorRef
        
        // Vertical Gradient
        meterView = UIView.init(frame: self.view.frame)
        meterGradientLayer.frame = CGRectMake(0.0, 0.0, self.view.frame.width, self.view.frame.height)
        meterGradientLayer.colors = [clearish, black, clear, clear, black, clearish]
        meterGradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        meterGradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        meterGradientLayer.locations = [0.0, 0.05, 0.05, 0.15, 0.15, 1.0]
        self.meterView.layer.addSublayer(meterGradientLayer)
        
        self.view.addSubview(meterView)
    }
    func setUpFluidView() {
        fluidView = BAFluidView.init(frame: self.view.frame)
        fluidView.fillColor = UIColor.init(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 0.8)
        fluidView.fillAutoReverse = false
        fluidView.fillRepeatCount = 1
        fluidView.fillDuration = 3.0
        
        let maskLayer = CAShapeLayer()
        let rectanglePath = UIBezierPath(rect: CGRectMake(self.view.frame.width * 0.05, 0.0, self.view.frame.width * 0.1, self.view.frame.height))
        maskLayer.path = rectanglePath.CGPath
        
        let image = UIImage(named: "fire-turquoise-240") as UIImage?
        let button  = UIButton(type: UIButtonType.Custom) as UIButton
        let width = CGFloat(28)
        button.frame = CGRectMake(24, self.view.frame.height - 16 - width, width, width)
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: #selector(LitMeterViewController.onExitButton), forControlEvents: UIControlEvents.TouchUpInside)
        self.fluidView.addSubview(button)
        
        self.view.addSubview(fluidView)
        fluidView.layer.mask = maskLayer
        
        let litness = CGFloat(SpotifyClient.CURRENT_USER.personalLitness!)
        percentage = CGFloat(litness / 100)
        fillMeter(percentage)
    }
    func setUpButton() {
        let image = UIImage(named: "fire-turquoise-240") as UIImage?
        let button  = UIButton(type: UIButtonType.Custom) as UIButton
        let width = CGFloat(28)
        button.frame = CGRectMake(24, self.view.frame.height - 16 - width, width, width)
        button.setImage(image, forState: .Normal)
        button.addTarget(self, action: #selector(LitMeterViewController.onExitButton), forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(button)
    }
    func onExitButton() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    func fillMeter(litness:CGFloat!) {
        // fill to percent value 0 to 1
        let max = (self.view.frame.height - 20) / self.view.frame.height
        let fill = litness / max
        fluidView.fillTo(fill)
        print("fill is \(fill)")
        fluidView.startAnimation()
    }

    // MARK: Previous Tracks
    
    func getPreviousTracks(completion: () -> Void) {
        currentParty.fetchInBackgroundWithBlock({ (fetchParty:PFObject?, error:NSError?) in
            if error == nil {
                self.previousPlaylist = fetchParty!["previousPlaylist"] as! [PFObject]
                print("previous playlist is: ")
                print(self.previousPlaylist)
                completion()
            } else {
                print("Error getting previous track in Lit view: \(error)")
            }
        })
    }
    
    // MARK: UITableView
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let index = indexPath
        if selectedIndexPath != nil {
            if index == selectedIndexPath {
                return 130
            } else {
                return 70
            }
        } else {
            return 70
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PreviousTrackCell") as! PreviousTrackTableViewCell
        let track = previousPlaylist[indexPath.row]
        track.fetchIfNeededInBackgroundWithBlock { (fetchTrack:PFObject?, error:NSError?) in
            cell.songNameLabel.text = track["name"] as? String
            cell.artistAlbumLabel.text = (track["artist"] as? String)! + " - " + (track["albumName"] as? String)!
            
            let previousLitness = track["litness"] as! Int
            //
           // let previousLitnessFloat = CGFloat(previousLitness)
            //let previousPercentage = CGFloat(previousLitnessFloat/100)
            cell.litnessLabel.text = "\(previousLitness)%"
        }
        cell.clipsToBounds = true
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return previousPlaylist.count
    }
//    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let currentSong = currentParty["now_playing"] as! PFObject
//        self.headerSongLabel.text = currentSong["name"] as? String
//        self.headerArtistAlbumLabel.text = (currentSong["artist"] as? String)! + " - " + (currentSong["albumName"] as? String)!
//        return headerView
//    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch selectedIndexPath {
        case nil:
            selectedIndexPath = indexPath
        default:
            if selectedIndexPath == indexPath {
                selectedIndexPath = nil
            } else {
                selectedIndexPath = indexPath
            }
        }
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
//    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 140
//    }
    
    
    
    @IBAction func didTapAddTrack(sender: AnyObject) {
        let buttonPosition: CGPoint = sender.convertPoint(CGPointZero, toView: self.tableView)
        let indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition)
        
        if indexPath != nil {
            let chosenParseTrack = self.previousPlaylist[(indexPath?.row)!]
            SpotifyClient.addToSavedTracks(chosenParseTrack, completionHandler: { () in
                //If the saved track was already part of the user's saves, alert
                
                
            })
        }
    }
    
    override func motionBegan(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (motion == .MotionShake) {
            print("Shaken")
            //SpotifyClient.CURRENT_USER.personalLitness! += 1
            SpotifyClient.CURRENT_USER.danceNumber! += 1
        }
        
    }
    
    func onTimer() {
        if (SpotifyClient.CURRENT_USER.danceNumber! == 0) {
//            SpotifyClient.CURRENT_USER.personalLitness! -= 5
        }
        else if (SpotifyClient.CURRENT_USER.danceNumber! >= 5) {
            SpotifyClient.CURRENT_USER.personalLitness! += 5
        } else if (SpotifyClient.CURRENT_USER.danceNumber! >= 3) {
            SpotifyClient.CURRENT_USER.personalLitness! += 2
        } else if (SpotifyClient.CURRENT_USER.danceNumber! >= 1) {
            SpotifyClient.CURRENT_USER.personalLitness! += 1
        }
        SpotifyClient.CURRENT_USER.danceNumber = 0
        let litness = CGFloat(SpotifyClient.CURRENT_USER.personalLitness!)
        percentage = CGFloat(litness / 100)
        fillMeter(percentage)
        
        litnessLabel.text = "\(SpotifyClient.CURRENT_USER.personalLitness!)%"
        print("Litmeter View: personal litness is now \(SpotifyClient.CURRENT_USER.personalLitness!)")
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
}