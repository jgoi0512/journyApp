//
//  HomeViewController.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import UIKit

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var databaseController: DatabaseProtocol?
    
    @IBOutlet weak var tripTableView: UITableView!
    @IBOutlet weak var addTripButton: UIButton!
    
    var trips: [Trip] = []
    
    let sampleTrips: [Trip] = [
        Trip(id: "1", title: "Paris Getaway", startDate: Date(), endDate: Date().addingTimeInterval(60 * 60 * 24 * 5), imageURL: URL(string: "https://example.com/paris.jpg")),
        Trip(id: "2", title: "Beach Vacation", startDate: Date().addingTimeInterval(60 * 60 * 24 * 7), endDate: Date().addingTimeInterval(60 * 60 * 24 * 14), imageURL: URL(string: "https://example.com/beach.jpg")),
        Trip(id: "3", title: "Mountain Retreat", startDate: Date().addingTimeInterval(60 * 60 * 24 * 21), endDate: Date().addingTimeInterval(60 * 60 * 24 * 28), imageURL: URL(string: "https://example.com/mountain.jpg")),
        Trip(id: "4", title: "City Exploration", startDate: Date().addingTimeInterval(60 * 60 * 24 * 30), endDate: Date().addingTimeInterval(60 * 60 * 24 * 35), imageURL: URL(string: "https://example.com/city.jpg")),
        Trip(id: "5", title: "Countryside Escape", startDate: Date().addingTimeInterval(60 * 60 * 24 * 40), endDate: Date().addingTimeInterval(60 * 60 * 24 * 45), imageURL: URL(string: "https://example.com/countryside.jpg"))
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        tripTableView.dataSource = self
        tripTableView.delegate = self
                        
        self.trips = sampleTrips
    }
    
    @IBAction func addTripButtonPressed(_ sender: Any) {
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tripDetailCell", for: indexPath) as! TripDetailTableViewCell
        
        let trip = trips[indexPath.row]
        cell.tripImage.backgroundColor = .green
        cell.tripName.text = trip.title
        cell.tripDate.text = "\(trip.startDate.formatted(date: .complete, time: .omitted)) - \(trip.endDate.formatted(date: .complete, time: .omitted))"
        
        return cell
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
