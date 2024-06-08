//
//  LoginViewController.swift
//  Journy
//
//  Created by Justin Goi on 23/4/2024.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    weak var databaseController: DatabaseProtocol?
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        navigationItem.hidesBackButton = true
        
        view.addSubview(loadingIndicator)
        loadingIndicator.center = view.center
    }
    
    // MARK: Action
    
    /**
     Attempts to authenticate the user using the provided email and password.
     
     This method validates the email and password fields. If both fields are non-empty,
     it attempts to sign in the user using the provided credentials.
     Upon completion, it displays an error message if authentication fails.
     - Parameters:
        - sender: The button triggering the login attempt.
     */
    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty, let password = passwordTextField.text, !password.isEmpty else {
            displayMessage(title: "Error", message: "Please enter your email and password.")
            
            return
        }
        
        self.view.isUserInteractionEnabled = false
        loadingIndicator.startAnimating()
        
        databaseController?.signIn(email: email, password: password) { [weak self] result in
            self?.view.isUserInteractionEnabled = true
            self?.loadingIndicator.stopAnimating()
            
            switch result {
                case .success(let user):
                    print("User signed in: \(user)")
                case .failure(let error):
                    self?.displayMessage(title: "Sign In Error", message: error.localizedDescription)
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
