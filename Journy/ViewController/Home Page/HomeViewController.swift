//
//  HomeViewController.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import UIKit

//, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout

class HomeViewController: UIViewController {
    var databaseController: DatabaseProtocol?
    
    @IBOutlet weak var addTripButton: UIButton!
    @IBOutlet weak var tripCollectionView: UICollectionView!
    
    var trips: [Trip] = []
    
//    let sampleTrips: [Trip] = [
//        Trip(id: "1", title: "Paris Getaway", startDate: Date(), endDate: Date().addingTimeInterval(60 * 60 * 24 * 5), imageURL: URL(string: "https://example.com/paris.jpg")),
//        Trip(id: "2", title: "Beach Vacation", startDate: Date().addingTimeInterval(60 * 60 * 24 * 7), endDate: Date().addingTimeInterval(60 * 60 * 24 * 14), imageURL: URL(string: "https://example.com/beach.jpg")),
//        Trip(id: "3", title: "Mountain Retreat", startDate: Date().addingTimeInterval(60 * 60 * 24 * 21), endDate: Date().addingTimeInterval(60 * 60 * 24 * 28), imageURL: URL(string: "https://example.com/mountain.jpg")),
//        Trip(id: "4", title: "City Exploration", startDate: Date().addingTimeInterval(60 * 60 * 24 * 30), endDate: Date().addingTimeInterval(60 * 60 * 24 * 35), imageURL: URL(string: "https://example.com/city.jpg")),
//        Trip(id: "5", title: "Countryside Escape", startDate: Date().addingTimeInterval(60 * 60 * 24 * 40), endDate: Date().addingTimeInterval(60 * 60 * 24 * 45), imageURL: URL(string: "https://example.com/countryside.jpg"))
//    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
//        tripCollectionView.dataSource = self
//        tripCollectionView.delegate = self
//        
//        tripCollectionView.register(TripCollectionViewCell.self, forCellWithReuseIdentifier: "tripCell")
                
//        self.trips = sampleTrips
        // Adding shadow to button.
//        addTripButton.layer.shadowColor = UIColor.darkGray.cgColor
//        addTripButton.layer.shadowOffset = CGSize(width: 1, height: 1)
//        addTripButton.layer.shadowRadius = 0.5
//        addTripButton.layer.shadowOpacity = 1.0
    }
    
    @IBAction func addTripButtonPressed(_ sender: Any) {
        
    }
    
    // Collection view.
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return trips.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tripCell", for: indexPath) as! TripCollectionViewCell
//        
//        let trip = trips[indexPath.item]
//        
//        cell.tripNameLabel?.text = trip.title
//        cell.tripDateLabel?.text = "\(trip.startDate) - \(trip.endDate)"
//        
//        
//        return cell
//    }
    
    @IBAction func tempSignOut(_ sender: Any) {
        databaseController?.signOut() { _ in
            
        }
        print("logged out")
        let loginVC = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        navigationController?.pushViewController(loginVC, animated: true)
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
