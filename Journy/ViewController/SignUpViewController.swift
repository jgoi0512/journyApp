//
//  SignUpViewController.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import UIKit
import FirebaseStorage

class SignUpViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    
    weak var databaseController: DatabaseProtocol?
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Setting up image view to be circular and adding a black border around the image view.
        profilePictureImageView.layer.masksToBounds = true
        profilePictureImageView.layer.cornerRadius = profilePictureImageView.frame.height / 2
        profilePictureImageView.layer.borderColor = UIColor.black.cgColor
        profilePictureImageView.layer.borderWidth = 1.5
        
        view.addSubview(loadingIndicator)
        loadingIndicator.center = view.center
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
            
        loadingIndicator.startAnimating()
        
        databaseController?.signUp(email: email, password: password) { [weak self] result in
            switch result {
            case .success(let user):
                // Update user profile with display name and profile image URL
                user.displayName = name
                if let profileImage = self?.profilePictureImageView.image {
                    self?.uploadProfileImage(profileImage, for: user) { result in
                        print("uploading image")
                        self?.loadingIndicator.stopAnimating()
                        switch result {
                        case .success(let imageURL):
                            print("successfully uploaded image to firebase storage.")
                            user.profileImageURL = imageURL
                            self?.updateUserProfile(user)
                        case .failure(let error):
                            print("Error uploading profile image: \(error.localizedDescription)")
                            self?.updateUserProfile(user)
                        }
                    }
                } else {
                    self?.updateUserProfile(user)
                }
            case .failure(let error):
                self?.displayMessage(title: "Sign Up Failure", message: error.localizedDescription)
            }
        }
    }
    
    private func updateUserProfile(_ user: User) {
        databaseController?.updateUserProfile(user) { [weak self] result in
            switch result {
            case .success:
                print("successfully updated profile info with name, email and picture URL.")
                self?.navigateToHomeScreen()
            case .failure(let error):
                self?.displayMessage(title: "Profile Update Failure", message: error.localizedDescription)
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage, for user: User, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG data"])))
            return
        }
        
        let storageRef = Storage.storage().reference().child("profile_images/\(user.id).jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
            } else {
                storageRef.downloadURL { url, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let url = url {
                        completion(.success(url))
                    } else {
                        completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve download URL"])))
                    }
                }
            }
        }
    }
    
    private func navigateToHomeScreen() {
        print("Navigating to home screen.")
        let homeVC = storyboard?.instantiateViewController(withIdentifier: "homeTabBarController") as! HomeTabBarViewController
        navigationController?.pushViewController(homeVC, animated: true)
        
        displayMessage(title: "Success!", message: "Successfully signed up!")
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
