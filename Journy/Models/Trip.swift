//
//  Trip.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import Foundation

class Trip: NSObject {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let imageURL: URL?
    var expenses: [Expense] = []
    var flightInfo: FlightInfo?
    var destinations: [Destination] = []
    
    init(id: String, title: String, startDate: Date, endDate: Date, imageURL: URL?) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.imageURL = imageURL
    }
    
    // Method to add an expense to the trip
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
    }
    
    // Method to set the flight information for the trip
    func setFlightInfo(_ flightInfo: FlightInfo) {
        self.flightInfo = flightInfo
    }
    
    // Method to add a destination to the trip
    func addDestination(_ destination: Destination) {
        destinations.append(destination)
    }
}
