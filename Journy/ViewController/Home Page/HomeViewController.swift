//
//  HomeViewController.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import UIKit
import FirebaseAuth

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIContextMenuInteractionDelegate {
    var databaseController: DatabaseProtocol?
    
    private let pexelsApiKey = "zJkVxec43HQGnIY8OLdwElRk5WWVgntjajfMHeZ7SRWNoQkYuKgCC2Zi"
    
    @IBOutlet weak var tripTableView: UITableView!
    @IBOutlet weak var addTripButton: UIButton!
    
    var trips: [Trip] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        tripTableView.dataSource = self
        tripTableView.delegate = self
        
        databaseController?.addTripListener { [weak self] result in
            switch result {
            case .success(let trips):
                self?.trips = trips
                
                DispatchQueue.main.async {
                    self?.tripTableView.reloadData()
                }
            case .failure(let error):
                print("Error listening for trips: \(error.localizedDescription)")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tripDetailCell", for: indexPath) as! TripDetailTableViewCell
        
        let trip = trips[indexPath.row]
        
        if let imageURL = URL(string: trip.imageURL ?? "") {
            downloadImage(from: imageURL) { image in
                DispatchQueue.main.async {
                    cell.tripImage.image = image
                }
            }
        } else {
            cell.tripImage.backgroundColor = .green // Fallback color if image URL is invalid
        }
        
        cell.tripName.text = trip.title
        cell.tripDate.text = "\(trip.startDate.formatted(date: .complete, time: .omitted)) - \(trip.endDate.formatted(date: .complete, time: .omitted))"
        
        cell.addInteraction(UIContextMenuInteraction(delegate: self))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /**
     Downloads the image from the specified URL.
     
     This method asynchronously downloads the image from the provided URL.
     It then crops the image to a specific aspect ratio before returning it.
     - Parameters:
        - url: The URL of the image to download.
        - completion: A closure to be called when the download is complete, containing the downloaded image.
     */
    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            if let image = UIImage(data: data) {
                let croppedImage = self.cropToAspectRatio(image: image, aspectRatio: 16.0/9.0)
                completion(croppedImage)
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    /**
     Crops the specified image to the given aspect ratio.
     
     This method crops the specified image to the provided aspect ratio.
     It preserves the central region of the image.
     - Parameters:
        - image: The image to be cropped.
        - aspectRatio: The aspect ratio to which the image should be cropped.
     - Returns: The cropped image, preserving the central region.
     */
    func cropToAspectRatio(image: UIImage, aspectRatio: CGFloat) -> UIImage? {
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let imageAspectRatio = imageWidth / imageHeight
        
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if imageAspectRatio > aspectRatio {
            newWidth = imageHeight * aspectRatio
            newHeight = imageHeight
        } else {
            newWidth = imageWidth
            newHeight = imageWidth / aspectRatio
        }
        
        let x = (imageWidth - newWidth) / 2.0
        let y = (imageHeight - newHeight) / 2.0
        
        let cropRect = CGRect(x: x, y: y, width: newWidth, height: newHeight)
        
        if let cgImage = image.cgImage?.cropping(to: cropRect) {
            return UIImage(cgImage: cgImage)
        } else {
            return nil
        }
    }
    
    /**
     Specifies the context menu configuration for a table view cell.
     
     This method constructs and returns a context menu configuration for a trip table view cell.
     It provides a delete action for removing the selected trip.
     - Parameters:
        - interaction: The context menu interaction that triggered this method.
        - location: The location of the context menu.
     - Returns: A UIContextMenuConfiguration object representing the context menu configuration.
     */

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let cell = interaction.view as? TripDetailTableViewCell,
              let indexPath = tripTableView.indexPath(for: cell) else {
            return nil
        }
        
        let trip = trips[indexPath.row]
        
        let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.deleteTrip(trip)
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(title: "", children: [deleteAction])
        }
    }
    
    /**
     Deletes the specified trip from the database and updates the UI.
     
     This method deletes the specified trip from the database.
     It also removes the trip from the local array and updates the table view accordingly.
     - Parameters:
        - trip: The trip to be deleted.
     */
    func deleteTrip(_ trip: Trip) {
        databaseController?.deleteTrip(trip) { [weak self] result in
            switch result {
            case .success:
                // Remove the trip from the local array
                print("successfully deleted trip")
                if let index = self?.trips.firstIndex(where: { $0.id == trip.id }) {
                    self?.trips.remove(at: index)
                    
                    // Update the table view on the main queue
                    DispatchQueue.main.async {
                        self?.tripTableView.reloadData()
                    }
                }
            case .failure(let error):
                print("Error deleting trip: \(error.localizedDescription)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTripDetail" {
            if let indexPath = tripTableView.indexPathForSelectedRow {
                let trip = trips[indexPath.row]
                let destinationVC = segue.destination as! TripDetailViewController
                destinationVC.currentTrip = trip
                destinationVC.navigationItem.title = trip.title
            }
        }
    }

}
