//
//  DatabaseProtocol.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import Foundation
import UIKit
import Firebase

protocol DatabaseProtocol: NSObject {
    var currentUser: FirebaseAuth.User? { get set }
    
    // Trip-related functions
    func fetchTrips(completion: @escaping (Result<[Trip], Error>) -> Void)
    func addTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void)
    func updateTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void)
    
    // Expense-related functions
    func fetchExpensesForTrip(_ tripID: String, completion: @escaping (Result<[Expense], Error>) -> Void)
    func addExpense(_ expense: Expense, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func updateExpense(_ expense: Expense, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteExpense(_ expense: Expense, fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    // Flight-related functions
    func fetchFlightInfoForTrip(_ tripID: String, completion: @escaping (Result<FlightInfo?, Error>) -> Void)
    func addFlightInfo(_ flightInfo: FlightInfo, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func updateFlightInfo(_ flightInfo: FlightInfo, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteFlightInfo(fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    // Destination-related functions
    func fetchDestinationsForTrip(_ tripID: String, completion: @escaping (Result<[Destination], Error>) -> Void)
    func addDestination(_ destination: Destination, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func updateDestination(_ destination: Destination, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteDestination(_ destination: Destination, fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    // User-related functions
    func fetchUserProfile(completion: @escaping (Result<User, Error>) -> Void)
    func updateUserProfile(_ user: User, completion: @escaping (Result<Void, Error>) -> Void)
    
    // Authentication-related functions
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void)
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void)
    func signOut(completion: @escaping (Result<Void, Error>) -> Void)
    static func isUserLoggedIn() -> Bool
    
    // Other utility functions
    func uploadImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void)
}
