//
//  ConnectedDevicesViewController.swift
//  InSync
//
//  Created by Nancy Yao on 7/10/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ConnectedDevicesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var connectedPeers: [MCPeerID]?
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
    
    @IBAction func onCloseButton(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if connectedPeers != nil {
            return connectedPeers!.count
        } else { return 0 }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ConnectedDevicesCell") as! ConnectedDevicesCell
        let peer = connectedPeers![indexPath.row]
        cell.connectedDeviceLabel.text = peer.displayName
        return cell
    }
}
