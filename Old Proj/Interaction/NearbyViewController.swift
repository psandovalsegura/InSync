//
//  NearbyViewController.swift
//  Interaction
//
//  Created by Nancy Yao on 7/6/16.
//  Copyright © 2016 FBU Team Interaction. All rights reserved.
//

import UIKit
import Discovery

class NearbyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var users: [AnyObject]?
    var tableView: UITableView! //temporary
    var discovery: Discovery!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        startDiscovery()
    }
    
    func startDiscovery() {
        let uuidString = "B9407F30-F5F8-466E-AFF9-25556B57FE99"
        let uuid = CBUUID(string: uuidString)
        
        //would use user's username (or name?) instead of device name
        discovery = Discovery(UUID: uuid, username: UIDevice.currentDevice().name, startOption: DIStartOptions.None) { (users: [AnyObject]!, usersChanged: Bool) -> Void in
            print("CH", usersChanged)
            print("OK", users.count)
            self.tableView.reloadData()
        }
        discovery.shouldAdvertise = true
        discovery.shouldDiscover = true
    }

    override func viewWillDisappear(animated: Bool) {
        discovery.shouldDiscover = false
        discovery.shouldAdvertise = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if users != nil {
            return users!.count
        } else { return 0 }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NearbyCell", forIndexPath: indexPath) // as! NearbyCell
        
        let bleUser = users![indexPath.row] as! BLEUser
        let proximity = bleUser.proximity
        
        //color based on proximity, change later
        var bgColor: UIColor!
        
        if (proximity < -85) {
            bgColor = UIColor.greenColor()
        } else if (proximity < -65) {
            bgColor = UIColor.yellowColor()
        } else {
            bgColor = UIColor.redColor()
        }
        
        //cell.backgroundColor = bgColor
        //cell.contentView.backgroundColor = UIColor.clearColor()
        
        
        return cell
    }
    
}
