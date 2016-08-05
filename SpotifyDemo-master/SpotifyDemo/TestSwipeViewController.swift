//
//  TestSwipeViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/23/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import EZSwipeController

protocol EZSwipeDelegate {
    func leftButton()
    func rightButton()
}

class TestSwipeViewController: EZSwipeController, EZSwipeControllerDataSource {
    var isGuest:Bool?
    var queueTracks: [QueueTrack]?
    var delegate:EZSwipeDelegate?
    
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
    }
    
    func viewControllerData() -> [UIViewController] {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if (isGuest == true) {
            let pageOne = storyboard.instantiateViewControllerWithIdentifier("newPartyQueue") as! NewQueueViewController
            //Load up the queue
            pageOne.queueTracks = self.queueTracks!
            pageOne.initialSetup = true
            let pageTwo = storyboard.instantiateViewControllerWithIdentifier("guestNowPlaying") as! GuestNowPlayingViewController
            let pageThree = storyboard.instantiateViewControllerWithIdentifier("partyDetails") as! PartyDetailsViewController
            return [pageOne, pageTwo, pageThree]
        } else {
            let pageOne = storyboard.instantiateViewControllerWithIdentifier("hostQueue") as! HostQueueViewController
            //Load up the queue
            pageOne.queueTracks = self.queueTracks!
            pageOne.initialSetup = true
            let pageTwo = storyboard.instantiateViewControllerWithIdentifier("hostNowPlaying") as! HostNowPlayingViewController
            let pageThree = storyboard.instantiateViewControllerWithIdentifier("partyDetails") as! PartyDetailsViewController
            return [pageOne, pageTwo, pageThree]
        }
    }
    
    func indexOfStartingPage() -> Int {
        return 1
    }

    
    func navigationBarDataForPageIndex(index: Int) -> UINavigationBar {
        let title = ""
        
        let navigationBar = UINavigationBar()
        navigationBar.backgroundColor = UIColor.blackColor()
        navigationBar.barStyle = UIBarStyle.BlackTranslucent
        navigationBar.translucent = true
        
        let navigationItem = UINavigationItem(title: title)
        navigationItem.hidesBackButton = true
        
        if index == 0 {
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = nil
            navigationBar.hidden = true
        } else if index == 1 {
            
            let rightButtonItem = UIBarButtonItem(image: UIImage(named: "menu-dots-small"), style: UIBarButtonItemStyle.Plain, target: self, action: "a")
            rightButtonItem.tintColor = UIColor.init(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 1.0)
            
            let leftButtonItem = UIBarButtonItem(image: UIImage(named: "menu-hamburger-small"), style: UIBarButtonItemStyle.Plain, target: self, action: "a")
            leftButtonItem.tintColor = UIColor.init(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 1.0)
            
            navigationItem.leftBarButtonItem = leftButtonItem
            navigationItem.rightBarButtonItem = rightButtonItem
            
//            self.navigationController?.navigationBarHidden = true

        } else if index == 2 {
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItem = nil
            navigationBar.hidden = true
        }
        navigationBar.pushNavigationItem(navigationItem, animated: false)
        navigationBar.translucent = true
        return navigationBar
    }
}