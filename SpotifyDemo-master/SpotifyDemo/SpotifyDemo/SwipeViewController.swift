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

        // Create variables for all view controllers you want to put in the
        // page menu, initialize them, and add each to the controller array.
        // (Can be any UIViewController subclass)
        // Make sure the title property of all view controllers is set
        // Example:
        //var controller : UIViewController = UIViewController(nibName: "controllerNibName", bundle: nil)
        //controller.title = "SAMPLE TITLE"
        //controllerArray.append(controller)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let pageOne = storyboard.instantiateViewControllerWithIdentifier("newPartyQueue") as! NewQueueViewController
            pageOne.title = "Playlist"
            let pageThree = storyboard.instantiateViewControllerWithIdentifier("settingsPage") as UIViewController
            pageThree.title = "Settings"
            let pageTwo = storyboard.instantiateViewControllerWithIdentifier("myParty") as! MainPartyViewController
            pageTwo.title = "My Party"
            controllerArray = [pageOne, pageTwo, pageThree]

        // Customize page menu to your liking (optional) or use default settings by sending nil for 'options' in the init
        // Example:
        var parameters: [CAPSPageMenuOption] = [
            .MenuItemSeparatorWidth(4.3),
            .UseMenuLikeSegmentedControl(true),
            .MenuItemSeparatorPercentageHeight(0.2)
        ]

        // Initialize page menu with controller array, frame, and optional parameters
        pageMenu = CAPSPageMenu(viewControllers: controllerArray, frame: CGRectMake(0.0, 15.0, self.view.frame.width, self.view.frame.height), pageMenuOptions: parameters)

        // Lastly add page menu as subview of base view controller view
        // or use pageMenu controller in you view hierachy as desired
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
