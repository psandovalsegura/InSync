//
//  ConnectedGuestsViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/23/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit

class ConnectedGuestsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: TableView Delegate, DataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let connectedCount = appDelegate.mpcHandler.session.connectedPeers.count
        print("Host: connected peers count \(connectedCount)")
        if connectedCount > 0 {
            return connectedCount
        } else { return 0 }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ConnectedDevicesCell") as! ConnectedDevicesCell
        let connectedPeers = appDelegate.mpcHandler.session!.connectedPeers
        let connectedPeer = connectedPeers[indexPath.row]
        cell.connectedDeviceLabel.text = connectedPeer.displayName
        return cell
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 30.0
    }
    
    @IBAction func onBackButton(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
