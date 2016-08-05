//
//  LoginController.swift
//  InSync
//
//  Created by Olivia Gregory on 7/7/16.
//  Copyright © 2016 FBU Team Interaction. All rights reserved.
//

import UIKit
import MediaPlayer
import Parse
import ParseUI
import MultipeerConnectivity
import NVActivityIndicatorView

class LoginViewController: UIViewController, SPTAuthViewDelegate, SPTAudioStreamingPlaybackDelegate, NVActivityIndicatorViewable  {
    
    // MARK: Properties
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    // Spotify Setup
    var player = SPTAudioStreamingController?()
    let spotifyAuthenticator = SPTAuth.defaultInstance()
    var loginSession = SPTSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Needed to let users use the Info Center (Now Playing) controls
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
    }
    
    @IBAction func loginWithSpotify(sender: AnyObject) {
        
        // Basic Setup for App
        
        // Use your apps client id - found in developer.spotify.com
        spotifyAuthenticator.clientID = SpotifyClient.CLIENT_ID
        
        // Tells the user what services your app will use
        spotifyAuthenticator.requestedScopes = [SPTAuthStreamingScope, SPTAuthUserLibraryReadScope, SPTAuthUserReadEmailScope, SPTAuthPlaylistReadPrivateScope, SPTAuthUserReadPrivateScope, SPTAuthUserReadBirthDateScope]
        
        // User your apps redirect url - found in developer.spotify.com
        spotifyAuthenticator.redirectURL = NSURL(string: SpotifyClient.CALLBACK_URL)
        
        // Use only when you have an application setup for this
        //spotifyAuthenticator.tokenSwapURL = NSURL(string: SpotifyClient.TOKEN_SWAP_URL)
        //spotifyAuthenticator.tokenRefreshURL = NSURL(string: SpotifyClient.TOKEN_REFRESH_URL)
        
        // Create a Spotify Login View Controller
        let spotifyAuthenticationViewController = SPTAuthViewController.authenticationViewController()
        spotifyAuthenticationViewController.delegate = self
        
        // Spotify Login View Controller Setup
        spotifyAuthenticationViewController.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        spotifyAuthenticationViewController.definesPresentationContext = true
        
        // Present Spotify Login View Controller
        presentViewController(spotifyAuthenticationViewController, animated: false, completion: nil)
        
        
        
    }
    
    // MARK: - SPTAuthViewDelegate
    
    // This functions gets called only if your login was succesful.
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didLoginWithSession session: SPTSession!) {
        
        let size = CGSize(width: 30, height:30)
        
        // Current User Session
        self.loginSession = session
        SpotifyClient.CURRENT_SESSION = loginSession
        
        // Goes to Playlists View
        //self.performSegueWithIdentifier("NowPlayingSegue", sender: self)
        
        //Set current user
        print("Setting user")
        startActivityAnimating(size, message: "Logging in...", type: NVActivityIndicatorType.AudioEqualizer, color: UIColor.blackColor())
        
        SpotifyClient.getCurrentUser { (user) in
            SpotifyClient.CURRENT_USER = user
            User.initializeParseUser(SpotifyClient.CURRENT_USER)
            // print("User successfully logged in")
            self.appDelegate.mpcHandler.setupPeerWithDisplayName(SpotifyClient.CURRENT_USER.id!)
            self.stopActivityAnimating()
        }
    }
    
    // Only gets called when there was an error during login
    func authenticationViewController(authenticationViewController: SPTAuthViewController!, didFailToLogin error: NSError!) {
        print("Login failed... \(error)")
        
    }
    
    // Only gets called when user cancels the log in
    func authenticationViewControllerDidCancelLogin(authenticationViewController: SPTAuthViewController!) {
        print("Did Cancel Login...")
    }
    
    // MARK: - Navigation
    //    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    //        if segue.identifier == "NowPlayingSegue" {
    //
    //            //The current user's session is now stored in Spotify Client
    //
    //        }
    //    }
    
    // MARK: - Memory Warning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
