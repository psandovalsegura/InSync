//
//  TestSwipeViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/23/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import EZSwipeController

class TestSwipeViewController: EZSwipeController, EZSwipeControllerDataSource {
    var isGuest:Bool?
    
    override func setupView() {
        datasource = self
        navigationBarShouldNotExist = true
        //        cancelStandardButtonEvents = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blackColor()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func viewControllerData() -> [UIViewController] {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if (isGuest != nil) {
            let pageOne = storyboard.instantiateViewControllerWithIdentifier("newPartyQueue") as! NewQueueViewController
            let pageThree = storyboard.instantiateViewControllerWithIdentifier("settingsPage") as! GuestSettingsViewController
            let pageTwo = storyboard.instantiateViewControllerWithIdentifier("nowPlaying") as! NewNowPlayingViewController
            return [pageOne, pageTwo, pageThree]
        } else {
            let pageOne = storyboard.instantiateViewControllerWithIdentifier("hostQueue") as! HostQueueViewController
            let pageThree = storyboard.instantiateViewControllerWithIdentifier("hostSettingsPage") as! HostSettingsViewController
            let pageTwo = storyboard.instantiateViewControllerWithIdentifier("nowPlaying") as! NewNowPlayingViewController
            return [pageOne, pageTwo, pageThree]
        }
    }
    
    func indexOfStartingPage() -> Int {
        return 1
    }
}