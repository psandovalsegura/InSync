//
//  MPCHandler.swift
//  InSync
//
//  Created by Nancy Yao on 7/8/16.
//  Copyright © 2016 Angel Vázquez. All rights reserved.
//

import UIKit
import MultipeerConnectivity


protocol MPCDelegate {
    func connectedWithPeer(peerID: MCPeerID)
}

class MPCHandler: NSObject, MCSessionDelegate {
    
    // MARK: Properties
    
    var mpcDelegate: MPCDelegate?
    
    var peerID:MCPeerID!
    var session:MCSession!
    var hostAdvertiser: MCNearbyServiceAdvertiser?
    var guestBrowser: MCNearbyServiceBrowser?
    var foundPeers = [MCPeerID]()
    var currentHost:MCPeerID?
    
    var stateTimeHandler:Double!
    
    
    
    // MARK: Setup Peer and Session
    
    /*
     Method to set up a peer
     - parameter displayName: the peer's display name
     */
    func setupPeerWithDisplayName (displayName:String) {
        peerID = MCPeerID(displayName: displayName)
    }
    
    /*
     Method to set up a session object that will manage communication among peers (will be used by host)
     */
    func setupSession() {
        session = MCSession(peer: peerID)
        session.delegate = self
    }
    

    // MARK: MCSessionDelegate
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        let userInfo = ["peerID":peerID,"state":state.rawValue]
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("MPC_DidChangeStateNotification", object: nil, userInfo: userInfo)
        })
        
        switch state{
        case MCSessionState.Connected:
            print("CONNECTED to session: \(session)")
            mpcDelegate?.connectedWithPeer(peerID)
            
        case MCSessionState.Connecting:
            print("CONNECTING to session: \(session)")
            
        case MCSessionState.NotConnected:
            print("NOT CONNECTED to session: \(session)")
        }
    }
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        let userInfo = ["data":data, "peerID":peerID]
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("MPC_DidReceiveDataNotification", object: nil, userInfo: userInfo)
        })
    }
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        //called when file has finished transfer from another peer
    }
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        //called when peer starts sending file to us
    }
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        //called when peer establishes stream with us
    }
    
}
