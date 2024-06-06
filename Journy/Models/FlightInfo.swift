//
//  FlightInfo.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import Foundation

class FlightInfo: NSObject {
    let id: String
    var airline: String?
    var flightNumber: String
    var departureAirport: String?
    var arrivalAirport: String?
    var departureDate: Date
    var arrivalDate: Date?
    var boardingGate: String?
    var departureTerminal: String?

    init(id: String, flightNumber: String, departureDate: Date) {
        self.id = id
        self.flightNumber = flightNumber
        self.departureDate = departureDate
    }
}
