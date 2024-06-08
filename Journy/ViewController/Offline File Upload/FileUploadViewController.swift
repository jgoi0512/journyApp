//
//  FileUploadViewController.swift
//  Journy
//
//  Created by Justin Goi on 8/6/2024.
//

import UIKit
import MobileCoreServices
import PhotosUI
import CoreData
import FirebaseAuth

class FileUploadViewController: UIViewController, UIDocumentPickerDelegate, PHPickerViewControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var filesTableView: UITableView!
    
    // Array to store files to be displayed in table view and tripID of current trip passed in from TripDetailViewController
    private var files: [FileEntity] = []
    var tripID: String?
    
    // Setting Core Data context for persistent storage
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filesTableView.dataSource = self
        filesTableView.delegate = self
        
        // Fetch files from Core Data to populate table view cells
        fetchFilesFromCoreData()
    }
    
    // MARK: Table View Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    // Table view cell configuration
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath)
        
        let file = files[indexPath.row]
        
        // Set cell text to be file name
        cell.textLabel?.text = file.name
        
        return cell
    }
    
    // Handling row selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let file = files[indexPath.row]
        
        if let data = file.data {
            // Handling case where file is an image
            if let image = UIImage(data: data) {
                
                // Present the image
                let imageViewController = UIViewController()
                
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                imageView.frame = imageViewController.view.frame
                imageViewController.view.addSubview(imageView)
                present(imageViewController, animated: true, completion: nil)
            }
            // Handling case where file is not an image or cannot be displayed as an image
            else {
                // Shows an alert that the file cannot be displayed
                let alert = UIAlertController(title: "File Content", message: "File \(file.name ?? "") could not be displayed as an image.", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // Handling swipe to delete action
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteFile(at: indexPath)
        }
    }
    
    // MARK: Actions
    
    // Bar button for uploading file, presents option to upload from Photo Library or Files
    @IBAction func uploadFile(_ sender: Any) {
        let alert = UIAlertController(title: "Upload File", message: "Choose a source", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.presentPhotoPicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Files", style: .default, handler: { _ in
            self.presentDocumentPicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: File Uploading Methods
    
    // Present the photo picker
    func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .any(of: [.images, .videos])
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        
        self.present(picker, animated: true, completion: nil)
    }
    
    // Handling result of photo picker
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let result = results.first else { return }
        
        // Handling loading image
        if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }
                
                guard let image = object as? UIImage, let imageData = image.jpegData(compressionQuality: 0.8) else { return }
                
                // Prompt user for name for the picture to be saved under
                DispatchQueue.main.async {
                    self?.promptForFileName { fileName in
                        self?.saveFileToCoreData(data: imageData, withName: fileName)
                    }
                }
            }
        } 
        // Handling loading video
        else if result.itemProvider.canLoadObject(ofClass: URL.self) {
            let _ = result.itemProvider.loadObject(ofClass: URL.self) { [weak self] (object, error) in
                if let error = error {
                    print("Error loading video: \(error)")
                    return
                }
                
                guard let videoURL = object else { return }
                
                do {
                    let videoData = try Data(contentsOf: videoURL)
                    DispatchQueue.main.async {
                        self?.promptForFileName { fileName in
                            self?.saveFileToCoreData(data: videoData, withName: fileName)
                        }
                    }
                } catch {
                    print("Error converting video URL to Data: \(error)")
                }
            }
        }
    }
    
    // Presenting document picker
    func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    // Handling result of document picker
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }
        
        do {
            let fileData = try Data(contentsOf: selectedFileURL)
            
            DispatchQueue.main.async {
                self.promptForFileName { fileName in
                    self.saveFileToCoreData(data: fileData, withName: fileName)
                }
            }
        } catch {
            print("Error reading file data: \(error)")
        }
    }
    
    // Handling cancellation of document picker
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }
    
    // Function to save to Core Data
    private func saveFileToCoreData(data: Data, withName name: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User is not logged in")
            return
        }
        
        // Creating an instance of file to be saved
        let newFile = FileEntity(context: context)
        newFile.id = UUID()
        newFile.name = name
        newFile.data = data
        newFile.dateCreated = Date()
        newFile.userId = userId
        newFile.tripId = tripID ?? ""

        do {
            try context.save()
            
            // Update files array with the new file saved
            files.append(newFile)
            fetchFilesFromCoreData()
            
            print("File saved to Core Data with name: \(name)")
        } catch {
            print("Error saving file to Core Data: \(error)")
        }
    }
    
    // Function to fetch files from Core Data
    private func fetchFilesFromCoreData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User is not logged in")
            return
        }

        let fetchRequest: NSFetchRequest<FileEntity> = FileEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@ AND tripId == %@", userId, tripID ?? "")
        
        do {
            files = try context.fetch(fetchRequest)
            
            DispatchQueue.main.async {
                self.filesTableView.reloadData()
            }
        } catch {
            print("Error fetching files from Core Data: \(error)")
        }
    }

    // Function for deleting file in Core Data
    private func deleteFile(at indexPath: IndexPath) {
        let fileToDelete = files[indexPath.row]
        
        context.delete(fileToDelete)
        
        do {
            try context.save()
            
            // Update files array to remove the deleted file
            files.remove(at: indexPath.row)
            
            DispatchQueue.main.async {
                self.filesTableView.deleteRows(at: [indexPath], with: .automatic)
            }
            
            print("File deleted from Core Data: \(fileToDelete.name ?? "Unknown")")
        } catch {
            print("Error deleting file from Core Data: \(error)")
        }
    }
    
    // Function for prompting user for file name
    private func promptForFileName(completion: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "File Name", message: "Enter a name for the file", preferredStyle: .alert)
            
            alert.addTextField { textField in
                textField.placeholder = "File name"
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
                if let fileName = alert.textFields?.first?.text, !fileName.isEmpty {
                    completion(fileName)
                } else {
                    // Handle empty file name if needed
                    completion("Untitled")
                }
            }))
            self.present(alert, animated: true, completion: nil)
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
