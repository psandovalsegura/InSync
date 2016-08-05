//
//  PagerSwipeViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/28/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class PagerSwipeViewController: ButtonBarPagerTabStripViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override internal func viewControllersForPagerTabStrip(pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [HostQueueViewController(), HostSettingsViewController()]
    }
    
}
