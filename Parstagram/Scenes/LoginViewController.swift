//
//  LoginViewController.swift
//  Parstagram
//
//  Created by Aramis on 10/29/21.
//

import UIKit

import Parse

class LoginViewController: UIViewController {
    
    
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var blueGradientView: UIView!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    var user: PFUser?
    
    // A color to use for error messages on the login screen
    // Heavily tinted to stand out in the gradient
    let errorColor = UIColor(red: 1.0000, green: 0.7686, blue: 0.7608, alpha: 1.0)
    

    override func viewDidLoad() {
        super.viewDidLoad()
        makeGradient()
        makeBlueGradient()
        view.layer.layoutIfNeeded()
        styleErrorLabel()
        setupKeyboardHiding()
    }
    
    func makeGradient() {
        let yellowColor = UIColor(red: 0.9961, green: 0.8549, blue: 0.4667, alpha: 1.0).cgColor
        let orangeColor = UIColor(red: 0.9608, green: 0.5216, blue: 0.1608, alpha: 1.0).cgColor
        let redColor = UIColor(red: 0.8667, green: 0.1647, blue: 0.4824, alpha: 1.0).cgColor
        let purpleColor = UIColor(red: 0.5059, green: 0.2039, blue: 0.6863, alpha: 1.0).cgColor
        
        let gradLayer = CAGradientLayer()
        gradientView.layer.addSublayer(gradLayer)
        gradLayer.contentsScale = UIScreen.main.scale
        gradLayer.frame = gradientView.layer.bounds
        gradLayer.type = .radial
        // Lower left corner
        gradLayer.startPoint = CGPoint(x: 0, y: 1)
        gradLayer.endPoint = CGPoint(x: 1, y: 0)
        gradLayer.colors = [
            yellowColor,
            orangeColor,
            redColor,
            purpleColor
        ]
        gradLayer.locations = [0.2, 0.4, 0.7]

        gradientView.layer.layoutIfNeeded()
    }
    
    func makeBlueGradient() {
        let blueColor = UIColor(red: 0.3176, green: 0.3569, blue: 0.8314, alpha: 1.0).cgColor
        let clearColor = UIColor(red: 0.5059, green: 0.2039, blue: 0.6863, alpha: 0.0).cgColor
        
        let gradLayer = CAGradientLayer()
        blueGradientView.layer.addSublayer(gradLayer)
        gradLayer.isOpaque = false
        gradLayer.contentsScale = UIScreen.main.scale
        gradLayer.frame = blueGradientView.layer.bounds
        gradLayer.type = .radial
        gradLayer.startPoint = CGPoint(x: 0, y: 0)
        gradLayer.endPoint = CGPoint(x: 1, y: 1)
        gradLayer.locations = [0.0, 0.8]
        gradLayer.colors = [blueColor, clearColor]
        blueGradientView.layer.layoutIfNeeded()
    }
    
    func setupKeyboardHiding() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(recognizer)
    }
    
    func styleErrorLabel() {
        errorLabel.isHidden = true
        errorLabel.textColor = errorColor
        errorLabel.text = ""
    }
    
    func displayError(withText text: String){
        errorLabel.text = text
        errorLabel.isHidden = false
    }
    
    func hideErrorLabel() {
        errorLabel.isHidden = true
    }
    
    
    func getUsernameAndPassword() -> (String, String)? {
        // Start by obtaining the contents of the two fields
        let username = usernameField.text ?? ""
        let password = passwordField.text ?? ""
        
        // First stage of verification: non-empty
        guard username != "" else {
            displayError(withText: "Please enter a username")
            return nil
        }
        
        guard password != "" else {
            displayError(withText: "Please enter a password")
            return nil
        }
        
        return (username, password)
    }
    
    
    func loginAction() {
        hideErrorLabel()
        guard let (username, password) = getUsernameAndPassword() else {return}
        PFUser.logInWithUsername(inBackground: username, password: password) { (user, error) in
            if error != nil {
                print(error?.localizedDescription ?? "")
                self.displayError(withText: "Invalid username or password")
            } else {
                self.user = user
                self.performSegue(withIdentifier: "exitLoginSegue", sender: self)
            }
        }
    }
    
    
    func signUpAction() {
        hideErrorLabel()
        guard let (username, password) = getUsernameAndPassword() else {return}
        
        let user = PFUser()
        user.username = username
        user.password = password
        // The PFUser model requires a unique email but we won't be using one
        user.email = "\(username)@website.com"
        
        
        user.signUpInBackground() {(success, error) in
            if error != nil {
                self.displayError(withText: "Username is already taken")
            } else if success {
                self.user = user
                self.performSegue(withIdentifier: "exitLoginSegue", sender: self)
            } else {
                self.displayError(withText: "Sign-up failed. Try again later.")
            }
        }
    }
    
    
    // MARK: IBActions
    @IBAction func signUpHandler(_ sender: Any) {
        signUpAction()
    }
    
    @IBAction func loginHandler(_ sender: Any) {
        loginAction()
    }
    
    @objc func hideKeyboard() {
        usernameField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
}
