//
//  User.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import Foundation


class User {
    let id: String
    let email: String
    var displayName: String?
    var profileImageURL: URL?
    
    init(id: String, email: String, displayName: String? = nil, profileImageURL: URL? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
    }
}
