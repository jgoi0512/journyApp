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
    let location: String
    let startDate: Date
    let endDate: Date
    let imageURL: String?
    var expenses: [Expense] = []
    var flightInfo: [FlightInfo] = []
    var destinations: [Activity] = []
    var accommodations: [Accommodation] = []
    
    init(id: String = "", title: String, location: String, startDate: Date, endDate: Date, imageURL: String = "") {
        self.id = id
        self.title = title
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.imageURL = imageURL
    }
}
