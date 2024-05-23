//
//  AddTripViewController.swift
//  Journy
//
//  Created by Justin Goi on 2/5/2024.
//

import UIKit
import MapKit

class AddTripViewController: UIViewController, MKLocalSearchCompleterDelegate, UITextFieldDelegate {
    var databaseController: DatabaseProtocol?
    
    @IBOutlet weak var tripNameTextField: UITextField!
    @IBOutlet weak var tripLocationTextField: UITextField!
    @IBOutlet weak var tripStartDate: UIDatePicker!
    @IBOutlet weak var tripEndDate: UIDatePicker!
    
    private var searchCompleter = MKLocalSearchCompleter()
    private let locationSearchView = LocationSearchView()
    private let pexelsApiKey = "zJkVxec43HQGnIY8OLdwElRk5WWVgntjajfMHeZ7SRWNoQkYuKgCC2Zi"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        tripLocationTextField.delegate = self
        
        // Set up the search completer
        searchCompleter.delegate = self
        searchCompleter.queryFragment = tripLocationTextField.text ?? ""
        
        view.addSubview(locationSearchView)
            locationSearchView.isHidden = true
            locationSearchView.onSelectLocation = { [weak self] selectedResult in
                self?.tripLocationTextField.text = selectedResult.title
                self?.locationSearchView.isHidden = true
            }
            
        // Add constraints for the location search view
        locationSearchView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationSearchView.topAnchor.constraint(equalTo: tripLocationTextField.bottomAnchor),
            locationSearchView.leadingAnchor.constraint(equalTo: tripLocationTextField.leadingAnchor),
            locationSearchView.trailingAnchor.constraint(equalTo: tripLocationTextField.trailingAnchor),
            locationSearchView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    @IBAction func saveTripButtonTapped(_ sender: Any) {
        guard let tripName = tripNameTextField.text,
              let location = tripLocationTextField.text else {
            return
        }
        
        fetchImage(for: location) { [weak self] imageURL in
            print("image fetched: \(imageURL)")
            DispatchQueue.main.async {
                let trip = Trip(title: tripName, location: location, startDate: self?.tripStartDate.date ?? Date(), endDate: self?.tripEndDate.date ?? Date(), imageURL: imageURL ?? "")
                self?.databaseController?.addTrip(trip) { result in
                    switch result {
                    case .success:
                        print("Trip successfully added.")
                        self?.navigationController?.popViewController(animated: true)
                    case .failure(let error):
                        print("Error adding trip: \(error.localizedDescription)")
                        self?.displayMessage(title: "Error", message: "Error adding new trip.")
                    }
                }
            }
        }
    }
    
    func fetchImage(for location: String, completion: @escaping (String?) -> Void) {
        let query = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.pexels.com/v1/search?query=\(query)&per_page=1&page=\(Int.random(in: 1...200))"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(pexelsApiKey, forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received from Pexels API")
                completion(nil)
                return
            }
            
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let photos = jsonResult["photos"] as? [[String: Any]],
                   let firstPhoto = photos.first,
                   let src = firstPhoto["src"] as? [String: Any],
                   let imageUrlString = src["original"] as? String {
                    completion(imageUrlString)
                } else {
                    print("Invalid JSON format from Pexels API")
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON data: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }

    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
            locationSearchView.searchResults = completer.results
            locationSearchView.reloadData()
            locationSearchView.isHidden = completer.results.isEmpty
        print("Search Results: \(completer.results)")
        }
        
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle error
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == tripLocationTextField {
            locationSearchView.isHidden = false
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == tripLocationTextField {
            locationSearchView.isHidden = true
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == tripLocationTextField {
            let newString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? ""
            searchCompleter.queryFragment = newString
            print("Query Fragment: \(newString)")
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField == tripLocationTextField {
            searchCompleter.queryFragment = ""
            locationSearchView.isHidden = true
        }
        return true
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
