//
//  Destination.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import Foundation

class Activity {
    let id: String
    let name: String
    let location: String
    let startDate: Date
    let endDate: Date
    
    init(id: String, name: String, location: String, startDate: Date, endDate: Date) {
        self.id = id
        self.name = name
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
    }
}
