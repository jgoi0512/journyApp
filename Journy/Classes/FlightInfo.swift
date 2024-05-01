//
//  FlightInfo.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import Foundation

class FlightInfo {
    let id: String
    let airline: String
    let flightNumber: String
    let departureAirport: String
    let arrivalAirport: String
    let departureDate: Date
    let arrivalDate: Date
    
    init(id: String, airline: String, flightNumber: String, departureAirport: String, arrivalAirport: String, departureDate: Date, arrivalDate: Date) {
        self.id = id
        self.airline = airline
        self.flightNumber = flightNumber
        self.departureAirport = departureAirport
        self.arrivalAirport = arrivalAirport
        self.departureDate = departureDate
        self.arrivalDate = arrivalDate
    }
}
