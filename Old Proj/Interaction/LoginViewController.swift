//
//  LoginViewController.swift
//  Interaction
//
//  Created by Olivia Gregory on 7/6/16.
//  Copyright © 2016 FBU Team Interaction. All rights reserved.
//

import UIKit
import Parse

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    /* On load in, screen hides the text fields and the error label until needed.
       Also, adds tap gesture recognizer for the keyboard.
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        errorLabel.text = ""
        usernameField.hidden = true
        passwordField.hidden = true
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer (target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /* Logs in user with username and password entered into onscreen fields by user when
       user presses "login" button.
    */
   
    @IBAction func onLogin(sender: AnyObject) {
        usernameField.hidden = false
        passwordField.hidden = false
        
        let username = usernameField.text ?? ""
        let password = passwordField.text ?? ""
        
        User.login(username, password: password, withCompletion: { (user: PFUser?, error: NSError?) -> Void in
            if let error = error {
                //If user does not log in successfully, display appropriate error message
                self.errorLabel.text = error.localizedDescription
                print("User login failed: " + error.localizedDescription)
            } else {
                print ("User logged in successfully.")
                //send user to home screen
                self.performSegueWithIdentifier("loginSegue", sender: nil)
            }
        })
    }
    
    
    @IBAction func onSignup(sender: AnyObject) {
        //send user to Create Profile screen
        performSegueWithIdentifier("signupSegue", sender: nil)
    }
    


}
