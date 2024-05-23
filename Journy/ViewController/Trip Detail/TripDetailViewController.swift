//
//  TripDetailViewController.swift
//  Journy
//
//  Created by Justin Goi on 14/5/2024.
//

import UIKit

class TripDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tripDetailTableView: UITableView!
    
    var currentTrip: Trip?
    var weatherData: Weather?
    
    private let weatherApiKey = "DuSdxqGXZmuph7QPgI6TtnzcrD0zSfdg"
    private let flightApiKey = "12b6c2749bb9802c6b99bfb387427a80"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tripDetailTableView.delegate = self
        tripDetailTableView.dataSource = self
        
        // Do any additional setup after loading the view.
        if let location = currentTrip?.location {
            fetchWeatherData(for: location)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "weatherCell", for: indexPath) as! WeatherDetailTableViewCell
            cell.weatherConditions.isHidden = true
            cell.weatherTemperature.isHidden = true
            
            if let weather = weatherData {
                cell.weatherConditions.isHidden = false
                cell.weatherTemperature.isHidden = false
                
                cell.weatherTemperature.text = "\(weather.temperature)°C"
                cell.weatherConditions.text = weather.conditions
                
                if let iconURL = URL(string: weather.iconURL) {
                    let iconTask = URLSession.shared.dataTask(with: iconURL) { (data, response, error) in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                cell.weatherImage.image = image
                            }
                        }
                    }
                    iconTask.resume()
                }
            }
            
            
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "flightCell", for: indexPath)
        
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            if let trip = currentTrip {
                let headerView = UITableViewHeaderFooterView()
                headerView.textLabel?.text = "Current Weather in \(trip.location)"
                return headerView
            }
        }
        else if section == 1 {
            let headerView = UITableViewHeaderFooterView()
            headerView.textLabel?.text = "Your Flights"
            return headerView
        }
        return nil
    }
    
    func fetchWeatherData(for location: String) {
        let locationURL = "https://dataservice.accuweather.com/locations/v1/cities/search?apikey=\(weatherApiKey)&q=\(location)"
        
        let locationTask = URLSession.shared.dataTask(with: URL(string: locationURL)!) { (data, response, error) in
            if let error = error {
                print("Error fetching location key: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received from location API")
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                   let locationKey = jsonArray.first?["Key"] as? String {
                    // Fetch weather data using the location key
                    self.fetchWeatherDataWithLocationKey(locationKey)
                } else {
                    print("Invalid location data format")
                }
            } catch {
                print("Error parsing location data: \(error.localizedDescription)")
            }
        }
        locationTask.resume()
    }

    func fetchWeatherDataWithLocationKey(_ locationKey: String) {
        let weatherURL = "https://dataservice.accuweather.com/currentconditions/v1/\(locationKey)?apikey=\(weatherApiKey)"
        
        // Make API request to fetch weather data
        let weatherTask = URLSession.shared.dataTask(with: URL(string: weatherURL)!) { (data, response, error) in
            if let error = error {
                print("Error fetching weather data: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received from weather API")
                return
            }
            
            // Parse the weather data
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]],
                   let weatherDict = jsonArray.first {
                    let temperatureDict = weatherDict["Temperature"] as? [String: Any]
                    let temperature = temperatureDict?["Metric"] as? [String: Any]
                    let temperatureValue = temperature?["Value"] as? Double ?? 0.0
                    let conditions = weatherDict["WeatherText"] as? String ?? ""
                    let iconNumber = weatherDict["WeatherIcon"] as? Int ?? 0
                    let iconURL = "https://developer.accuweather.com/sites/default/files/\(String(format: "%02d", iconNumber))-s.png"
                    
                    let weather = Weather(temperature: temperatureValue, conditions: conditions, iconURL: iconURL)
                    self.weatherData = weather
                    
                    DispatchQueue.main.async {
                        self.tripDetailTableView.reloadData()
                    }
                } else {
                    print("Invalid weather data format")
                }
            } catch {
                print("Error parsing weather data: \(error.localizedDescription)")
            }
        }
        weatherTask.resume()
    }
    
//    func fetchFlightInfo(flightNumber: String, departureDate: String) {
//        let url = "https://api.aviationstack.com/v1/flights?access_key=\(flightApiKey)&flight_number=\(flightNumber)&flight_date=\(departureDate)"
//
//        let task = URLSession.shared.dataTask(with: URL(string: url)!) { (data, response, error) in
//            if let error = error {
//                print("Error fetching flight info: \(error.localizedDescription)")
//                return
//            }
//
//            guard let data = data else {
//                print("No data received from flight info API")
//                return
//            }
//
//            do {
//                if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//                   let flightData = jsonResult["data"] as? [[String: Any]],
//                   let flight = flightData.first {
//                    let airline = flight["airline"]["name"] as? String ?? ""
//                    let flightNumber = flight["flight"]["number"] as? String ?? ""
//                    let departureAirport = flight["departure"]["airport"] as? String ?? ""
//                    let arrivalAirport = flight["arrival"]["airport"] as? String ?? ""
//                    let departureTimeStr = flight["departure"]["scheduled"] as? String ?? ""
//                    let arrivalTimeStr = flight["arrival"]["scheduled"] as? String ?? ""
//                    let boardingGate = flight["departure"]["gate"] as? String ?? ""
//
//                    let dateFormatter = DateFormatter()
//                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
//
//                    if let departureDate = dateFormatter.date(from: departureTimeStr),
//                       let arrivalDate = dateFormatter.date(from: arrivalTimeStr) {
//                        let flightInfo = FlightInfo(id: UUID().uuidString, airline: airline, flightNumber: flightNumber, departureAirport: departureAirport, arrivalAirport: arrivalAirport, departureDate: departureDate, arrivalDate: arrivalDate, departureTime: departureTimeStr, arrivalTime: arrivalTimeStr, boardingGate: boardingGate)
//                        
//                        DispatchQueue.main.async {
//                            // Update UI with flight info
//                            self.updateFlightInfoUI(with: flightInfo)
//                        }
//                    }
//                }
//            } catch {
//                print("Error parsing flight info: \(error.localizedDescription)")
//            }
//        }
//        task.resume()
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addPlanSegue" {
            let destinationVC = segue.destination as! AddPlanViewController
            destinationVC.tripID = currentTrip?.id
        }
    }

}
