//
//  LoginViewController.swift
//  Journy
//
//  Created by Justin Goi on 23/4/2024.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    var handle: AuthStateDidChangeListenerHandle?
    
    weak var databaseController: DatabaseProtocol?
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty, let password = passwordTextField.text, !password.isEmpty else {
            displayMessage(title: "Error", message: "Please enter your email and password.")
            
            return
        }
        
        databaseController?.signIn(email: email, password: password) { [weak self] result in
            switch result {
                case .success(let user):
                    print("User signed in: \(user.email)")
                    self?.navigateToHomeScreen()
                case .failure(let error):
                    self?.displayMessage(title: "Sign In Error", message: error.localizedDescription)
            }
        }
    }
    
    @IBAction func forgotPasswordButtonTapped(_ sender: Any) {
        // yet to implement
    }
    
    private func navigateToHomeScreen() {
         let homeVC = storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
         navigationController?.pushViewController(homeVC, animated: true)
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
