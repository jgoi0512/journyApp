//
//  FirebaseController.swift
//  Journy
//
//  Created by Justin Goi on 1/5/2024.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class FirebaseController: NSObject, DatabaseProtocol {
    var db: Firestore
    var currentUser: FirebaseAuth.User?
    
    
    override init() {
        FirebaseApp.configure()
        db = Firestore.firestore()
        
        super.init()
        
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            
            if let user = user {
                self.currentUser = user
                
            } else {
                self.currentUser = nil
            }
        }
    }
    
    // Trip-related functions
    func fetchTrips(completion: @escaping (Result<[Trip], Error>) -> Void) {
        //        db.collection("trips").getDocuments { snapshot, error in
        //            if let error = error {
        //                completion(.failure(error))
        //            } else {
        //                let trips = snapshot?.documents.compactMap { document -> Trip? in
        //                    let data = document.data()
        //                    // Parse the trip data and create a Trip instance
        //                    // ...
        //                    return trip
        //                } ?? []
        //                completion(.success(trips))
        //            }
        //        }
    }
    
    func addTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void) {
        let tripData: [String: Any] = [
            "title": trip.title,
            "startDate": trip.startDate,
            "endDate": trip.endDate,
            // Add more trip data as needed
        ]
        
        db.collection("trips").addDocument(data: tripData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void) {
        let tripData: [String: Any] = [
            "title": trip.title,
            "startDate": trip.startDate,
            "endDate": trip.endDate,
            // Add more trip data as needed
        ]
        
        db.collection("trips").document(trip.id).setData(tripData, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("trips").document(trip.id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // Expense-related functions
    func fetchExpensesForTrip(_ tripID: String, completion: @escaping (Result<[Expense], Error>) -> Void) {
        //        db.collection("trips").document(tripID).collection("expenses").getDocuments { snapshot, error in
        //            if let error = error {
        //                completion(.failure(error))
        //            } else {
        //                let expenses = snapshot?.documents.compactMap { document -> Expense? in
        //                    let data = document.data()
        //                    // Parse the expense data and create an Expense instance
        //                    // ...
        //                    return expense
        //                } ?? []
        //                completion(.success(expenses))
        //            }
        //        }
    }
    
    func addExpense(_ expense: Expense, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let expenseData: [String: Any] = [
            "title": expense.title,
            "amount": expense.amount,
            "date": expense.date,
            // Add more expense data as needed
        ]
        
        db.collection("trips").document(tripID).collection("expenses").addDocument(data: expenseData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateExpense(_ expense: Expense, completion: @escaping (Result<Void, Error>) -> Void) {
        let expenseData: [String: Any] = [
            "title": expense.title,
            "amount": expense.amount,
            "date": expense.date,
            // Add more expense data as needed
        ]
        
        db.collection("expenses").document(expense.id).setData(expenseData, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteExpense(_ expense: Expense, fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("trips").document(tripID).collection("expenses").document(expense.id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // Flight-related functions
    func fetchFlightInfoForTrip(_ tripID: String, completion: @escaping (Result<FlightInfo?, Error>) -> Void) {
        //        db.collection("trips").document(tripID).collection("flightInfo").getDocuments { snapshot, error in
        //            if let error = error {
        //                completion(.failure(error))
        //            } else {
        //                let flightInfo = snapshot?.documents.first.flatMap { document -> FlightInfo? in
        //                    let data = document.data()
        //                    // Parse the flight info data and create a FlightInfo instance
        //                    // ...
        //                    return flightInfo
        //                }
        //                completion(.success(flightInfo))
        //            }
        //        }
    }
    
    func addFlightInfo(_ flightInfo: FlightInfo, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let flightData: [String: Any] = [
            "airline": flightInfo.airline,
            "flightNumber": flightInfo.flightNumber,
            "departureAirport": flightInfo.departureAirport,
            "arrivalAirport": flightInfo.arrivalAirport,
            "departureDate": flightInfo.departureDate,
            "arrivalDate": flightInfo.arrivalDate,
            // Add more flight info data as needed
        ]
        
        db.collection("trips").document(tripID).collection("flightInfo").addDocument(data: flightData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateFlightInfo(_ flightInfo: FlightInfo, completion: @escaping (Result<Void, Error>) -> Void) {
        let flightData: [String: Any] = [
            "airline": flightInfo.airline,
            "flightNumber": flightInfo.flightNumber,
            "departureAirport": flightInfo.departureAirport,
            "arrivalAirport": flightInfo.arrivalAirport,
            "departureDate": flightInfo.departureDate,
            "arrivalDate": flightInfo.arrivalDate,
            // Add more flight info data as needed
        ]
        
        db.collection("flightInfo").document(flightInfo.id).setData(flightData, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteFlightInfo(fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("trips").document(tripID).collection("flightInfo").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                snapshot?.documents.forEach { document in
                    document.reference.delete()
                }
                completion(.success(()))
            }
        }
    }
    
    // Destination-related functions
    func fetchDestinationsForTrip(_ tripID: String, completion: @escaping (Result<[Destination], Error>) -> Void) {
        //        db.collection("trips").document(tripID).collection("destinations").getDocuments { snapshot, error in
        //            if let error = error {
        //                completion(.failure(error))
        //            } else {
        //                let destinations = snapshot?.documents.compactMap { document -> Destination? in
        //                    let data = document.data()
        //                    // Parse the destination data and create a Destination instance
        //                    // ...
        //                    return destination
        //                } ?? []
        //                completion(.success(destinations))
        //            }
        //        }
    }
    
    func addDestination(_ destination: Destination, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let destinationData: [String: Any] = [
            "name": destination.name,
            "startDate": destination.startDate,
            "endDate": destination.endDate,
            // Add more destination data as needed
        ]
        
        db.collection("trips").document(tripID).collection("destinations").addDocument(data: destinationData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateDestination(_ destination: Destination, completion: @escaping (Result<Void, Error>) -> Void) {
        let destinationData: [String: Any] = [
            "name": destination.name,
            "startDate": destination.startDate,
            "endDate": destination.endDate,
            // Add more destination data as needed
        ]
        
        db.collection("destinations").document(destination.id).setData(destinationData, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteDestination(_ destination: Destination, fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("trips").document(tripID).collection("destinations").document(destination.id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // User-related functions
    func fetchUserProfile(completion: @escaping (Result<User, Error>) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                guard let data = snapshot?.data(),
                      let email = data["email"] as? String else {
                    completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user data"])))
                    return
                }
                
                let displayName = data["displayName"] as? String
                let profileImageURL = data["profileImageURL"] as? String
                
                let user = User(id: userID, email: email, displayName: displayName, profileImageURL: URL(string: profileImageURL ?? ""))
                completion(.success(user))
            }
        }
    }
    
    func updateUserProfile(_ user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRef = db.collection("users").document(user.id)
        
        let userData: [String: Any] = [
            "email": user.email,
            "displayName": user.displayName ?? "",
            "profileImageURL": user.profileImageURL?.absoluteString ?? ""
        ]
        
        userRef.setData(userData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // User auth
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else {
                guard let userID = authResult?.user.uid else {
                    completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
                    return
                }
                
                print("\(userID) registered account.")
                
                let user = User(id: userID, email: email)
                self.updateUserProfile(user) { result in
                    switch result {
                    case .success:
                        completion(.success(user))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
            
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else {
                guard let userID = authResult?.user.uid else {
                    completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
                    return
                }
                        
                print("\(userID) logged in.")
                        
                self.fetchUserProfile { result in
                    switch result {
                        case .success(let user):
                            completion(.success(user))
                        case .failure(let error):
                            completion(.failure(error))
                    }
                }
            }
        }
    }
            
    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
