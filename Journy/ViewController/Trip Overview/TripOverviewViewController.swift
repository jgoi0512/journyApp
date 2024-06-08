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
    
    // Initializing Google Maps Geocoder
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
        
        guard let tripID = tripID else { return }
        
        // Fetch accommodations and activities
        fetchAccommodationsAndActivities(for: tripID)
    }
    
    // MARK: Helper Methods
    
    /** 
     Fetches accommodations and activities for the specified trip.
     - Parameter tripID: The identifier of the trip.
     */
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
    
    /** 
     Processes the fetched accommodations and adds annotations to the map.
     - Parameter accommodations: An array of accommodations.
     */
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
    
    /** 
     Processes the fetched activities and adds annotations to the map.
     - Parameter activities: An array of activities.
     */
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
    
    // MARK: Geocoding Methods
    
    /**
     Geocodes an address string to obtain coordinates using Google Geocoding API.
     - Parameters:
       - addressString: The address to be geocoded.
       - completion: Completion handler that returns the coordinates or nil.
     */
    func geocodeAddressString(_ addressString: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocodingUrl = "https://maps.googleapis.com/maps/api/geocode/json?key=\(mapsApiKey)&address=\(addressString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
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
    
    // MARK: Annotation Handling Methods
    
    /**
     Checks if all annotations have been added to the map and sets the map's region to fit all coordinates.
      - Parameters:
        - totalAccommodations: Total number of accommodations.
        - totalActivities: Total number of activities.
     */
    func checkAllAnnotationsAdded(totalAccommodations: Int, totalActivities: Int) {
        if accommodationAnnotationsAdded == totalAccommodations && activityAnnotationsAdded == totalActivities {
            setMapViewRegionToFitAllCoordinates()
        }
    }
        
    /// Sets the map view region to fit all accommodation and activity coordinates.
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
    
    // MARK: MapView Methods
    
    /** Provides a view for the specified annotation.
     - Parameters:
       - mapView: The map view requesting the annotation view.
      - annotation: The annotation object to provide a view for.
     - Returns: The view to display for the annotation.
     */
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
    
    /** Handles the event when the callout accessory control is tapped. Navigates to the maps app based on the location the user selected for navigation.
     - Parameters:
       - mapView: The map view containing the annotation view.
       - view: The annotation view that was tapped.
       - control: The control that was tapped.
     */
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
