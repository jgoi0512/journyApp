//
//  Destination.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import Foundation

class Destination {
    let id: String
    let name: String
    let startDate: Date
    let endDate: Date
    
    init(id: String, name: String, startDate: Date, endDate: Date) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
    }
}
