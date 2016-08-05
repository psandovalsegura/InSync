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
import VideoSplashKit
import Onboard
import CBZSplashView

class LoginViewController: VideoSplashViewController, SPTAuthViewDelegate, SPTAudioStreamingPlaybackDelegate, NVActivityIndicatorViewable  {

    // MARK: Properties

    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

    // Spotify Setup
    var player = SPTAudioStreamingController?()
    let spotifyAuthenticator = SPTAuth.defaultInstance()
    var loginSession = SPTSession()

    override func viewDidLoad() {
        
        let logo = UIImage(named: "Logo1")
        let color = UIColor.blackColor()
        let splashview = CBZSplashView(icon: logo, backgroundColor: color)
        
        // customize duration, icon size, or icon color here;
        self.view.addSubview(splashview)
        splashview.startAnimation()

        super.viewDidLoad()
        // Needed to let users use the Info Center (Now Playing) controls
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()

        //Background Video set up
        let url = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("Untitled", ofType: "mp4")!)
        self.videoFrame = view.frame
        self.fillMode = .ResizeAspectFill
        self.alwaysRepeat = true
        self.sound = false
        self.startTime = 0.0
        self.duration = 30.0
        self.alpha = 0.7
        self.backgroundColor = UIColor.blackColor()
        self.contentURL = url
        self.restartForeground = true
    }

    @IBAction func loginWithSpotify(sender: AnyObject) {

        // Basic Setup for App

        // Use your apps client id - found in developer.spotify.com
        spotifyAuthenticator.clientID = SpotifyClient.CLIENT_ID

        // Tells the user what services your app will use
        spotifyAuthenticator.requestedScopes = [SPTAuthStreamingScope, SPTAuthUserLibraryReadScope, SPTAuthUserReadEmailScope, SPTAuthPlaylistReadPrivateScope, SPTAuthUserReadPrivateScope, SPTAuthUserReadBirthDateScope, SPTAuthUserLibraryModifyScope]

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
        startActivityAnimating(size, message: "Logging in...", type: NVActivityIndicatorType.AudioEqualizer, color: UIColor.whiteColor())

        let firstPage = OnboardingContentViewController(title: "Start a party!", body: "Or join one that's nearby!", image: UIImage(named: "firstpic"), buttonText: "Ok!") { () -> Void in
            //self.dismissViewControllerAnimated(true, completion: nil)
            //self.performSegueWithIdentifier("loginSegue", sender: nil)
        }
        firstPage.movesToNextViewController = true
        firstPage.bodyLabel.font = UIFont(name: "Avenir-Medium", size: 15.0)
        firstPage.titleLabel.font = UIFont(name: "Avenir-Medium", size: 18.0)
        //firstPage.actionButton.


        let secondPage = OnboardingContentViewController(title: "Hype it up!", body: "Add tracks from Spotify and let guests vote in which they want next!", image: UIImage(named: "secondpic"), buttonText: "Ok!") { () -> Void in
            //self.dismissViewControllerAnimated(true, completion: nil)
            //self.performSegueWithIdentifier("loginSegue", sender: nil)
        }
        secondPage.movesToNextViewController = true
        secondPage.bodyLabel.font = UIFont(name: "Avenir-Medium", size: 15.0)
        secondPage.titleLabel.font = UIFont(name: "Avenir-Medium", size: 18.0)
        //firstPage.actionButton.

        let thirdPage = OnboardingContentViewController(title: "Have fun!", body: "Dance to increase the lit meter, make announcements, and save songs to your Spotify account!", image: UIImage(named: "Afghan-DJ-party"), buttonText: "Let's Go!") { () -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
            self.performSegueWithIdentifier("loginSegue", sender: nil)
            //let myNewVC = ChoiceViewController()
            //self.presentViewController(myNewVC, animated: true, completion: nil)

        }
        thirdPage.bodyLabel.font = UIFont(name: "Avenir-Medium", size: 15.0)
        thirdPage.titleLabel.font = UIFont(name: "Avenir-Medium", size: 18.0)
        //firstPage.actionButton.
        let onboardingVC = OnboardingViewController(backgroundImage: UIImage(named: "Logo1"), contents: [firstPage, secondPage, thirdPage])
        onboardingVC.shouldFadeTransitions = true
        onboardingVC.shouldBlurBackground = true

        SpotifyClient.getCurrentUser { (user) in
            SpotifyClient.CURRENT_USER = user
            User.initializeParseUser(SpotifyClient.CURRENT_USER, completion:  { (user) in
                //if let fullName = SpotifyClient.CURRENT_USER.fullName {
                  //  self.appDelegate.mpcHandler.setupPeerWithDisplayName(SpotifyClient.CURRENT_USER.fullName!)
                //} else {
                    self.appDelegate.mpcHandler.setupPeerWithDisplayName(SpotifyClient.CURRENT_USER.id!)

//                }

                //self.appDelegate.mpcHandler.setupPeerWithDisplayName(SpotifyClient.CURRENT_USER.id!)
                self.stopActivityAnimating()

                //if (!(AppDelegate.isAppAlreadyLaunchedOnce())) {
                   // self.presentViewController(onboardingVC, animated: true, completion: nil)

                //}
                //else {
                    self.performSegueWithIdentifier("loginSegue", sender: nil)
                //}

            })
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


    // MARK: - Memory Warning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
