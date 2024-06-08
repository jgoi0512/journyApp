//
//  Destination.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import Foundation

class Activity {
    let id: String?
    let name: String?
    let location: String?
    let activityDate: Date?
    
    init(id: String, name: String, location: String, activityDate: Date) {
        self.id = id
        self.name = name
        self.location = location
        self.activityDate = activityDate
    }
}
