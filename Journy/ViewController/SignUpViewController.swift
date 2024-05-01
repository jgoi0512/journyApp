//
//  SignUpViewController.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import UIKit

class SignUpViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Setting up image view to be circular and adding a black border around the image view.
        profilePictureImageView.layer.masksToBounds = true
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.height / 2
        profilePictureImageView.layer.borderColor = UIColor.black.cgColor
        profilePictureImageView.layer.borderWidth = 1.5
    }
    
    @IBAction func uploadImageButtonTapped(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            profilePictureImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func signUpButtonTapped(_ sender: Any) {
        guard let name = nameTextField.text, !name.isEmpty, let email = emailTextField.text, !email.isEmpty, let password = passwordTextField.text, !password.isEmpty else {
                displayMessage(title: "Error", message: "Please fill in all the fields.")
            
                return
            }
            
        databaseController?.signUp(email: email, password: password) { authResult in
            switch authResult {
            case .success(let user):
                self.displayMessage(title: "Sign Up Successful", message: "placeholder")
                self.navigateToHomeScreen()
            case .failure(let user):
                self.displayMessage(title: "Sign Up Failure", message: "placeholder")
            }
        }
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
