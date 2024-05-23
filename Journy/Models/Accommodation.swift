//
//  Accommodation.swift
//  Journy
//
//  Created by Justin Goi on 15/5/2024.
//

import Foundation

class Accommodation {
    let id: String
    let name: String
    let location: String
    let checkInDate: Date
    let checkOutDate: Date

    init(id: String, name: String, location: String, checkInDate: Date, checkOutDate: Date) {
        self.id = id
        self.name = name
        self.location = location
        self.checkInDate = checkInDate
        self.checkOutDate = checkOutDate
    }
}
