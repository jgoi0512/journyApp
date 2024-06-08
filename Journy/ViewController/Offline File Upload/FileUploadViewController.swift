//
//  FileUploadViewController.swift
//  Journy
//
//  Created by Justin Goi on 8/6/2024.
//

import UIKit
import MobileCoreServices
import PhotosUI

class FileUploadViewController: UIViewController, UIDocumentPickerDelegate, PHPickerViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                
                guard let image = object as? UIImage, let imageData = image.jpegData(compressionQuality: 1.0) else { return }
                
                self?.saveFile(data: imageData, withName: "picked_image.jpg")
            }
        } else if result.itemProvider.canLoadObject(ofClass: URL.self) {
            result.itemProvider.loadObject(ofClass: URL.self) { [weak self] (object, error) in
                if let error = error {
                    print("Error loading video: \(error)")
                    return
                }
                
                guard let videoURL = object else { return }
                
                self?.saveFile(from: videoURL, withName: videoURL.lastPathComponent)
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
        
        saveFile(from: selectedFileURL, withName: selectedFileURL.lastPathComponent)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }

    private func saveFile(data: Data, withName name: String) {
        let fileManager = FileManager.default
        do {
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let savedURL = documentsURL.appendingPathComponent(name)
            try data.write(to: savedURL)
            
            print("File saved to: \(savedURL)")
        } catch {
            print("Error saving file: \(error)")
        }
    }

    private func saveFile(from url: URL, withName name: String) {
        let fileManager = FileManager.default
        do {
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let savedURL = documentsURL.appendingPathComponent(name)
            try fileManager.copyItem(at: url, to: savedURL)
            
            print("File saved to: \(savedURL)")
        } catch {
            print("Error saving file: \(error)")
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
