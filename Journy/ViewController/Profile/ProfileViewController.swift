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
    
    @IBAction func signOutButtonTapped(_ sender: Any) {
        databaseController?.signOut() { _ in
            print("User logged out.")
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = sb.instantiateViewController(identifier: "loginViewController")
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.setRootViewController(loginVC)
        }
    }
    
    @IBAction func uploadImageButtonTapped(_ sender: Any) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
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
    
    @IBAction func editButtonTapped(_ sender: Any) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        
        nameTextField.isUserInteractionEnabled = true
        nameTextField.isEnabled = true
        nameTextField.becomeFirstResponder()
        
        uploadImageButton.isUserInteractionEnabled = true
        uploadImageButton.isEnabled = true
    }
    
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
    
    @objc func cancelButtonTapped() {
        nameTextField.isUserInteractionEnabled = false
        nameTextField.isEnabled = false
        nameTextField.resignFirstResponder()
        
        uploadImageButton.isUserInteractionEnabled = false
        uploadImageButton.isEnabled = false
        
        loadUserData()
        
        resetNavBar()
    }
    
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
    
    func resetNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(signOutButtonTapped(_ :)))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
    }
    
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
