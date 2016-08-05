//
//  SwipeController.swift
//  InSync
//
//  Created by Olivia Gregory on 7/17/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import EZSwipeController
import PageMenu

class SwipeViewController: UIViewController, CAPSPageMenuDelegate {
    
    var isGuest: Bool?
    var pageMenu : CAPSPageMenu?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.blackColor()
        
        // Array to keep track of controllers in page menu
        var controllerArray : [UIViewController] = []
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let pageOne = storyboard.instantiateViewControllerWithIdentifier("hostQueue") as! HostQueueViewController
        pageOne.title = "Playlist"
        let pageThree = storyboard.instantiateViewControllerWithIdentifier("hostSettingsPage") as! HostSettingsViewController
        pageThree.title = "Settings"
        let pageTwo = storyboard.instantiateViewControllerWithIdentifier("hostNowPlaying") as! HostNowPlayingViewController
        pageTwo.title = "My Party"
        controllerArray = [pageOne, pageTwo, pageThree]
        
        // Customize page menu to your liking (optional) or use default settings by sending nil for 'options' in the init
        let parameters: [CAPSPageMenuOption] = [
            .MenuItemSeparatorWidth(4.3),
            .UseMenuLikeSegmentedControl(true),
            .SelectedMenuItemLabelColor(UIColor.clearColor()),
            .UnselectedMenuItemLabelColor(UIColor.clearColor()),
            .MenuItemSeparatorPercentageHeight(0.2),
            .SelectionIndicatorColor(UIColor.init(red: 143/255.0, green: 219/255.0, blue: 218/255.0, alpha: 1.0)),
            .SelectionIndicatorHeight(2.0),
            .MenuHeight(20.0),
            .MenuMargin(0.0)
        ]
        
        pageMenu = CAPSPageMenu(viewControllers: controllerArray, frame: CGRectMake(0.0, 0.0, self.view.frame.width, self.view.frame.height), pageMenuOptions: parameters)
//        pageMenu.startingPageForScroll = 1
        self.view.addSubview(pageMenu!.view)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func indexOfStartingPage() -> Int {
        return 1
    }
}
