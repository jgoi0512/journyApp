//
//  Expense.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import Foundation

class Expense {
    let id: String?
    let title: String?
    let amount: Double?
    let date: Date?
    
    init(id: String, title: String, amount: Double, date: Date) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
    }
}
