//
//  Weather.swift
//  Journy
//
//  Created by Justin Goi on 16/5/2024.
//

import Foundation

class Weather {
    let temperature: Double
    let conditions: String
    let iconURL: String
    
    init(temperature: Double, conditions: String, iconURL: String) {
        self.temperature = temperature
        self.conditions = conditions
        self.iconURL = iconURL
    }
}
