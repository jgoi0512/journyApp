//
//  ProfileViewController.swift
//  Journy
//
//  Created by Justin Goi on 10/5/2024.
//

import UIKit
import FirebaseStorage
import PhotosUI

class ProfileViewController: UIViewController, PHPickerViewControllerDelegate {
    var databaseController: DatabaseProtocol?
    
    var currentUser: AuthUser?
    var userDisplayName: String?
    var userEmail: String?

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var uploadImageButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.layer.borderColor = UIColor.black.cgColor
        profileImageView.layer.borderWidth = 1.5
        
        self.loadUserData()
        requestPhotoLibraryAccess()
    }
    
    // MARK: Actions
    
    /**
     Action triggered when the sign out button is tapped.
     
     This method signs out the current user and navigates to the login view controller.
     */
    @IBAction func signOutButtonTapped(_ sender: Any) {
        databaseController?.signOut() { _ in
            print("User logged out.")
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = sb.instantiateViewController(identifier: "loginViewController")
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.setRootViewController(loginVC)
        }
    }
    
    /**
     Action triggered when the upload image button is tapped.
     
     This method presents the PHPickerViewController for selecting an image from the photo library.
     */
    @IBAction func uploadImageButtonTapped(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    // MARK: PHPickerViewController Method
    
    /**
     Handles image selection from the PHPickerViewController.
     
     This method is called when the user selects an image from the PHPickerViewController.
     It retrieves the selected image, updates the profile image view, and dismisses the picker.
     - Parameters:
        - picker: The PHPickerViewController instance.
        - results: An array of PHPickerResult objects containing the selected media items.
     */
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let provider = results.first?.itemProvider else { return }
        
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    if let selectedImage = image as? UIImage {
                        self?.profileImageView.image = selectedImage
                    } else if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: Helper Methods
    
    /**
     Requests access to the photo library.
     
     This method requests authorization to access the user's photo library.
     If access is denied or restricted, it displays a message informing the user about the requirement.
     */
    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                print("Access granted")
            case .denied, .restricted:
                DispatchQueue.main.async {
                    self.displayMessage(title: "Access Denied", message: "Photo Library access is required to select a profile picture.")
                }
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
    
    /**
     Action triggered when the edit button is tapped.
     
     This method configures the navigation bar buttons and enables editing of text fields and image selection.
     */
    @IBAction func editButtonTapped(_ sender: Any) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        
        nameTextField.isUserInteractionEnabled = true
        nameTextField.isEnabled = true
        nameTextField.becomeFirstResponder()
        
        uploadImageButton.isUserInteractionEnabled = true
        uploadImageButton.isEnabled = true
    }
    
    /**
     Action triggered when the done button is tapped.
     
     This method finalizes the editing process by disabling text field editing, updating the user profile, and resetting the navigation bar.
     */
    @objc func doneButtonTapped() {
        nameTextField.isUserInteractionEnabled = false
        nameTextField.isEnabled = false
        nameTextField.resignFirstResponder()
        
        uploadImageButton.isUserInteractionEnabled = false
        uploadImageButton.isEnabled = false
        
        userDisplayName = nameTextField.text ?? ""
        
        if let currentUser = self.currentUser {
            currentUser.displayName = userDisplayName
            
            if let profileImage = self.profileImageView.image {
                self.uploadProfileImage(profileImage, for: currentUser) { result in
                    print("uploading image")
                    switch result {
                    case .success(let imageURL):
                        print("successfully uploaded image to firebase storage.")
                        currentUser.profileImageURL = imageURL
                        self.updateUserProfile(user: currentUser)
                    case .failure(let error):
                        print("Error uploading profile image: \(error.localizedDescription)")
                        self.updateUserProfile(user: currentUser)
                    }
                }
            } else {
                self.updateUserProfile(user: currentUser)
            }
        }
        
        resetNavBar()
    }
    
    /**
     Action triggered when the cancel button is tapped.
     
     This method cancels the editing process by disabling text field editing, resetting the user data, and resetting the navigation bar.
     */
    @objc func cancelButtonTapped() {
        nameTextField.isUserInteractionEnabled = false
        nameTextField.isEnabled = false
        nameTextField.resignFirstResponder()
        
        uploadImageButton.isUserInteractionEnabled = false
        uploadImageButton.isEnabled = false
        
        loadUserData()
        
        resetNavBar()
    }
    
    /**
     Loads the user's profile data.
     
     This method fetches the current user's profile data from the database and populates the view with the retrieved information.
     It sets the user's display name, email, and profile picture.
     */
    func loadUserData() {
        databaseController?.fetchUserProfile { [weak self] result in
            switch result {
            case .success(let user):
                self?.currentUser = user
                
                self?.nameTextField.text = user.displayName
                self?.emailTextField.text = user.email
                self?.navigationItem.title = "Hello \(user.displayName!)!"
                
                if let imageURL = user.profileImageURL {
                    self?.downloadImage(from: imageURL) { [weak self] image in
                           DispatchQueue.main.async {
                               self?.profileImageView.image = image
                           }
                       }
                   } else {
                       self?.profileImageView.image = UIImage(named: "default_profile")
                   }
            case .failure( _ ):
                print("Fail to fetch user profile.")
            }
        }
    }
    
    /**
     Updates the user's profile information.
     
     This method updates the user's profile information in the database with the modified display name and/or profile picture.
     Upon successful update, it reloads the user's data and displays a success message.
     - Parameter user: The user object containing the updated profile information.
     */
    func updateUserProfile(user: AuthUser) {
        databaseController?.updateUserProfile(user) { result in
            switch result {
            case .success:
                print("successfully updated profile info with name, email and picture URL.")
                self.loadUserData()
                self.displayMessage(title: "Success!", message: "Successfully updated profile!")
            case .failure(let error):
                self.displayMessage(title: "Profile Update Failure", message: error.localizedDescription)
            }
        }
    }
    
    /**
     Downloads an image from the specified URL.
     
     This method asynchronously downloads an image from the given URL using a URLSession data task.
     - Parameters:
        - url: The URL of the image to be downloaded.
        - completion: A closure that is called when the download completes, passing the downloaded image as an argument.
     */
    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            let image = UIImage(data: data)
            completion(image)
        }.resume()
    }
    
    /**
     Resets the navigation bar buttons.
     
     This method configures the navigation bar buttons to their default state, including the edit and sign out buttons.
     */
    func resetNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOutButtonTapped(_ :)))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
    }
    
    /**
     Uploads the user's profile image to Firebase Storage.
     
     This private method compresses the provided image to JPEG data and uploads it to Firebase Storage.
     Upon successful upload, it retrieves the download URL of the image and passes it to the completion handler.
     - Parameters:
        - image: The profile image to be uploaded.
        - user: The user object for whom the profile image is being uploaded.
        - completion: A closure that is called upon completion of the upload operation, passing the result containing the download URL or an error.
     */
    private func uploadProfileImage(_ image: UIImage, for user: AuthUser, completion: @escaping (Result<URL, Error>) -> Void) {
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
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
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
