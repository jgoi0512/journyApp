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

class FileUploadViewController: UIViewController, UIDocumentPickerDelegate, PHPickerViewControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var filesTableView: UITableView!
    
    private var files: [FileEntity] = []
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filesTableView.dataSource = self
        filesTableView.delegate = self
        
        fetchFilesFromCoreData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return files.count
        }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath)
        let file = files[indexPath.row]
        cell.textLabel?.text = file.name
        return cell
    }
                
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let file = files[indexPath.row]
        if let data = file.data {
            if let image = UIImage(data: data) {
                // Present the image
                let imageViewController = UIViewController()
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                imageView.frame = imageViewController.view.frame
                imageViewController.view.addSubview(imageView)
                present(imageViewController, animated: true, completion: nil)
            } else {
                // Handle other types of files or show a message
                let alert = UIAlertController(title: "File Content", message: "File \(file.name ?? "") could not be displayed as an image.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteFile(at: indexPath)
        }
    }

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

    func presentPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .any(of: [.images, .videos])
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let result = results.first else { return }
        
        if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                if let error = error {
                    print("Error loading image: \(error)")
                    return
                }
                
                guard let image = object as? UIImage, let imageData = image.jpegData(compressionQuality: 0.8) else { return }
                
                self?.saveFileToCoreData(data: imageData, withName: "picked_image.jpg")
            }
        } else if result.itemProvider.canLoadObject(ofClass: URL.self) {
            let _ = result.itemProvider.loadObject(ofClass: URL.self) { [weak self] (object, error) in
                if let error = error {
                    print("Error loading video: \(error)")
                    return
                }
                
                guard let videoURL = object else { return }
                
                do {
                    let videoData = try Data(contentsOf: videoURL)
                    self?.saveFileToCoreData(data: videoData, withName: videoURL.lastPathComponent)
                } catch {
                    print("Error converting video URL to Data: \(error)")
                }
            }
        }
    }

    func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        self.present(documentPicker, animated: true, completion: nil)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else {
            return
        }
        
        do {
            let fileData = try Data(contentsOf: selectedFileURL)
            saveFileToCoreData(data: fileData, withName: selectedFileURL.lastPathComponent)
        } catch {
            print("Error reading file data: \(error)")
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }

    private func saveFileToCoreData(data: Data, withName name: String) {
        let newFile = FileEntity(context: context)
        newFile.id = UUID()
        newFile.name = name
        newFile.data = data
        newFile.dateCreated = Date()

        do {
            try context.save()
            files.append(newFile) // Update the files array with the new file
            fetchFilesFromCoreData()
            print("File saved to Core Data with name: \(name)")
        } catch {
            print("Error saving file to Core Data: \(error)")
        }
    }
    
    private func fetchFilesFromCoreData() {
        let fetchRequest: NSFetchRequest<FileEntity> = FileEntity.fetchRequest()
        
        do {
            files = try context.fetch(fetchRequest)
            
            DispatchQueue.main.async {
                self.filesTableView.reloadData()
            }
        } catch {
            print("Error fetching files from Core Data: \(error)")
        }
    }
    
    private func deleteFile(at indexPath: IndexPath) {
        let fileToDelete = files[indexPath.row]
        context.delete(fileToDelete)
        
        do {
            try context.save()
            files.remove(at: indexPath.row) // Update the files array
            DispatchQueue.main.async {
                self.filesTableView.deleteRows(at: [indexPath], with: .automatic)
            }
            print("File deleted from Core Data: \(fileToDelete.name ?? "Unknown")")
        } catch {
            print("Error deleting file from Core Data: \(error)")
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
