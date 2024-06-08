//
//  TripOverviewViewController.swift
//  Journy
//
//  Created by Justin Goi on 8/6/2024.
//

import UIKit
import MapKit
import CoreLocation
import GoogleMaps

class TripOverviewViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var tripOverviewMapView: MKMapView!
    static let geocoder = GMSGeocoder()
    var databaseController: DatabaseProtocol?
    
    var tripID: String?
    
    var activityCoordinates: [CLLocationCoordinate2D] = []
    var accommodationCoordinates: [CLLocationCoordinate2D] = []
    
    var accommodationAnnotationsAdded = 0
    var activityAnnotationsAdded = 0
    
    private var mapsApiKey = "AIzaSyAajo69DbQs-Uj6-9kyH6_Rw-bDTCk8iKo"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        tripOverviewMapView.delegate = self
        // Do any additional setup after loading the view.
        guard let tripID = tripID else { return }
        
        fetchAccommodationsAndActivities(for: tripID)
    }
    
    // Function to fetch both accommodations and activities
    func fetchAccommodationsAndActivities(for tripID: String) {
        databaseController?.fetchAccommodationsForTrip(tripID) { [weak self] result in
            switch result {
            case .success(let accommodations):
                self?.processAccommodations(accommodations)
            case .failure(let error):
                print("Error fetching accommodations: \(error)")
            }
        }
        
        databaseController?.fetchActivitiesForTrip(tripID) { [weak self] result in
            switch result {
            case .success(let activities):
                self?.processActivities(activities)
            case .failure(let error):
                print("Error fetching activities: \(error)")
            }
        }
    }
    
    // Process accommodations and add annotations
    func processAccommodations(_ accommodations: [Accommodation]) {
        for accommodation in accommodations {
            geocodeAddressString(accommodation.location ?? "") { [weak self] coordinate in
                guard let coordinate = coordinate else { return }
                
                self?.accommodationCoordinates.append(coordinate)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = accommodation.name
                annotation.subtitle = "Accommodation"
                self?.tripOverviewMapView.addAnnotation(annotation)
                
                // Increment the count and check if all accommodations and activities are added
                self?.accommodationAnnotationsAdded += 1
                self?.checkAllAnnotationsAdded(totalAccommodations: accommodations.count, totalActivities: self?.activityAnnotationsAdded ?? 0)
            }
        }
    }
    
    // Process activities and add annotations
    func processActivities(_ activities: [Activity]) {
        for activity in activities {
            geocodeAddressString(activity.location ?? "") { [weak self] coordinate in
                guard let coordinate = coordinate else { return }
                
                self?.activityCoordinates.append(coordinate)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = activity.name
                annotation.subtitle = "Activity"
                self?.tripOverviewMapView.addAnnotation(annotation)
                
                // Increment the count and check if all accommodations and activities are added
                self?.activityAnnotationsAdded += 1
                self?.checkAllAnnotationsAdded(totalAccommodations: self?.accommodationAnnotationsAdded ?? 0, totalActivities: activities.count)
            }
        }
    }
    
    // Geocode an address to get coordinates using Google Geocoding API
    func geocodeAddressString(_ addressString: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocodingUrl = "https://maps.googleapis.com/maps/api/geocode/json?key=\(mapsApiKey)&address=\(addressString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        print(addressString)
        print(geocodingUrl)
        guard let url = URL(string: geocodingUrl) else {
            print("Invalid URL.")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Geocoding request error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data returned from geocoding request.")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let firstResult = results.first,
                   let geometry = firstResult["geometry"] as? [String: Any],
                   let location = geometry["location"] as? [String: Any],
                   let latitude = location["lat"] as? CLLocationDegrees,
                   let longitude = location["lng"] as? CLLocationDegrees {
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    completion(coordinate)
                } else {
                    print("No valid geocoding results found.")
                    completion(nil)
                }
            } catch {
                print("Error parsing geocoding response: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
    
    // Check if all annotations are added and then set the map's region
    func checkAllAnnotationsAdded(totalAccommodations: Int, totalActivities: Int) {
        if accommodationAnnotationsAdded == totalAccommodations && activityAnnotationsAdded == totalActivities {
            setMapViewRegionToFitAllCoordinates()
        }
    }
    
    func setMapViewRegionToFitAllCoordinates() {
        let allCoordinates = activityCoordinates + accommodationCoordinates
        
        guard !allCoordinates.isEmpty else { return }
        
        var minLat = CLLocationDegrees.infinity
        var maxLat = -CLLocationDegrees.infinity
        var minLng = CLLocationDegrees.infinity
        var maxLng = -CLLocationDegrees.infinity
        
        for coordinate in allCoordinates {
            if coordinate.latitude < minLat { minLat = coordinate.latitude }
            if coordinate.latitude > maxLat { maxLat = coordinate.latitude }
            if coordinate.longitude < minLng { minLng = coordinate.longitude }
            if coordinate.longitude > maxLng { maxLng = coordinate.longitude }
        }
        
        let centerLat = (minLat + maxLat) / 2
        let centerLng = (minLng + maxLng) / 2
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
        
        let latDelta = (maxLat - minLat) * 2 // adding padding
        let lngDelta = (maxLng - minLng) * 2 // adding padding
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
        
        print("setting region")
        DispatchQueue.main.async {
            self.tripOverviewMapView.setRegion(region, animated: true)
        }
    }
        
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        let identifier = annotation.subtitle ?? "Default"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier ?? "")
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.calloutOffset = CGPoint(x: -5, y: 5)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            annotationView?.annotation = annotation
        }

        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let coordinate = view.annotation?.coordinate else { return }
        
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = view.annotation?.title ?? "Destination"
        
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        
        mapItem.openInMaps(launchOptions: launchOptions)
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
