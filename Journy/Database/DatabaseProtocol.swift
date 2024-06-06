//
//  DatabaseProtocol.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth

protocol DatabaseProtocol: NSObject {
    // Trip
    func fetchTrips(completion: @escaping (Result<[Trip], Error>) -> Void)
    func addTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void)
    func updateTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void)
    func addTripListener(completion: @escaping (Result<[Trip], Error>) -> Void)
    
    // Trip expenses
    func fetchExpensesForTrip(_ tripID: String, completion: @escaping (Result<[Expense], Error>) -> Void)
    func addExpense(_ expense: Expense, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func updateExpense(_ expense: Expense, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteExpense(_ expense: Expense, fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    // Trip flights
    func fetchFlightInfoForTrip(_ tripID: String, completion: @escaping (Result<[FlightInfo?], Error>) -> Void)
    func addFlightInfo(_ flightInfo: FlightInfo, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func updateFlightInfo(_ flightInfo: FlightInfo, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteFlightInfo(_ flightInfoID: String, fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    // Trip accommodation
    func fetchAccommodationsForTrip(_ tripID: String, completion: @escaping (Result<[Accommodation], Error>) -> Void)
    func addAccommodationToTrip(_ accommodation: Accommodation, tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteAccommodationFromTrip(_ accommodationID: String, tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    // Trip destinations
    func fetchDestinationsForTrip(_ tripID: String, completion: @escaping (Result<[Activity], Error>) -> Void)
    func addDestination(_ destination: Activity, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    func updateDestination(_ destination: Activity, completion: @escaping (Result<Void, Error>) -> Void)
    func deleteDestination(_ destination: Activity, fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void)
    
    // User profile
    func fetchUserProfile(completion: @escaping (Result<AuthUser, Error>) -> Void)
    func updateUserProfile(_ user: AuthUser, completion: @escaping (Result<Void, Error>) -> Void)
    
    // User auth
    func signUp(email: String, password: String, completion: @escaping (Result<AuthUser, Error>) -> Void)
    func signIn(email: String, password: String, completion: @escaping (Result<AuthUser, Error>) -> Void)
    func signOut(completion: @escaping (Result<Void, Error>) -> Void)
}
