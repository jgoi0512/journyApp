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
    
    @IBAction func forgotPasswordButtonTapped(_ sender: Any) {
        // yet to implement
    }
    
    private func navigateToHomeScreen() {
        print("Navigating to home screen.")
        let homeVC = storyboard?.instantiateViewController(withIdentifier: "homeTabBarController") as! HomeTabBarViewController
        navigationController?.pushViewController(homeVC, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.hidesBottomBarWhenPushed = true
        
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                print("\(String(describing: user?.uid))")
                self.navigateToHomeScreen()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Auth.auth().removeStateDidChangeListener(handle!)
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
