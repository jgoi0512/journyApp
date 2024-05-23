//
//  FlightInfo.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import Foundation

class FlightInfo {
    let id: String
    let airline: String = ""
    let flightNumber: String
    let departureAirport: String = ""
    let arrivalAirport: String = ""
    let departureDate: Date
    let arrivalDate: Date = Date()

    init(id: String, flightNumber: String, departureDate: Date) {
        self.id = id
        self.flightNumber = flightNumber
        self.departureDate = departureDate
    }
}
