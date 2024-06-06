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
    
    var tripRef: CollectionReference?
    
    override init() {
        FirebaseApp.configure()
        db = Firestore.firestore()
        
        super.init()
        
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if user != nil {
                print("Current logged in user: \(String(describing: user?.uid))")
                
                self.currentUser = user
                self.tripRef = self.db.collection("users").document(self.currentUser?.uid ?? "").collection("trips")
            }
        }
    }
    
    // Trip
    func fetchTrips(completion: @escaping (Result<[Trip], Error>) -> Void) {
        tripRef?.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let trips = snapshot?.documents.compactMap { document -> Trip? in
                    let data = document.data()
                    guard let id = data["id"] as? String,
                          let title = data["title"] as? String,
                          let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                          let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                          let location = data["location"] as? String,
                          let imageURL = data["imageURL"] as? String
                    else {
                        print("failed")
                        return nil
                    }
                                        
                    let trip = Trip(id: id, title: title, location: location, startDate: startDate, endDate: endDate, imageURL: imageURL)
                    
                    return trip
                } ?? []
                completion(.success(trips))
            }
        }
    }
    
    func addTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void) {
        let tripData: [String: Any] = [
            "title": trip.title,
            "startDate": trip.startDate,
            "endDate": trip.endDate,
            "location": trip.location,
            "imageURL": trip.imageURL ?? ""
        ]
                
        if let tripRef = tripRef?.addDocument(data: tripData) {
            let updatedTrip = Trip(id: tripRef.documentID, title: trip.title, location: trip.location, startDate: trip.startDate, endDate: trip.endDate)
            self.updateTrip(updatedTrip) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
                
            }
        }
    }
    
    func updateTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void) {
        let tripData: [String: Any] = [
            "id": trip.id,
            "title": trip.title,
            "startDate": trip.startDate,
            "endDate": trip.endDate,
            "location": trip.location
        ]
        
        tripRef?.document(trip.id).setData(tripData, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteTrip(_ trip: Trip, completion: @escaping (Result<Void, Error>) -> Void) {
        tripRef?.document(trip.id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func addTripListener(completion: @escaping (Result<[Trip], any Error>) -> Void) {
        tripRef?.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let trips = snapshot?.documents.compactMap { document -> Trip? in
                    let data = document.data()
                    guard let id = data["id"] as? String,
                          let title = data["title"] as? String,
                          let startDate = (data["startDate"] as? Timestamp)?.dateValue(),
                          let endDate = (data["endDate"] as? Timestamp)?.dateValue(),
                          let location = data["location"] as? String,
                          let imageURL = data["imageURL"] as? String else {
                        return nil
                    }
                    
                    let trip = Trip(id: id, title: title, location: location, startDate: startDate, endDate: endDate, imageURL: imageURL)
                    
                    return trip
                } ?? []
                completion(.success(trips))
            }
        }
    }
    
    // Trip expenses
    func fetchExpensesForTrip(_ tripID: String, completion: @escaping (Result<[Expense], Error>) -> Void) {
//                db.collection("trips").document(tripID).collection("expenses").getDocuments { snapshot, error in
//                    if let error = error {
//                        completion(.failure(error))
//                    } else {
//                        let expenses = snapshot?.documents.compactMap { document -> Expense? in
//                            let data = document.data()
//                            // to add...
//                              return expense
//                        } ?? []
//                        completion(.success(expenses))
//                    }
//                }
    }
    
    func addExpense(_ expense: Expense, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let expenseData: [String: Any] = [
            "title": expense.title,
            "amount": expense.amount,
            "date": expense.date,
            // to add
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
            // to add
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
    
    // Trip flight
    func fetchFlightInfoForTrip(_ tripID: String, completion: @escaping (Result<[FlightInfo?], Error>) -> Void) {
        tripRef?.document(tripID).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                let flightInfoArray = document.data()?["flightInfo"] as? [[String: Any]] ?? []
                let flights = flightInfoArray.compactMap { data -> FlightInfo? in
                    guard let id = data["id"] as? String,
                          let flightNumber = data["flightNumber"] as? String,
                          let departureDate = (data["departureDate"] as? Timestamp)?.dateValue() else {
                        print("error assigning values")
                        return nil
                    }
                    
                    let flightInfo = FlightInfo(id: id, flightNumber: flightNumber, departureDate: departureDate)
                    
                    return flightInfo
                }
                completion(.success(flights))
            } else {
                print("empty array returned")
                completion(.success([]))
            }
        }
    }
    
    func addFlightInfo(_ flightInfo: FlightInfo, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let flightData: [String: Any] = [
            "id": flightInfo.id,
            "flightNumber": flightInfo.flightNumber,
            "departureDate": flightInfo.departureDate
        ]
        
        tripRef?.document(tripID).updateData(["flightInfo": FieldValue.arrayUnion([flightData])]) { error in
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
            "boardingGate": flightInfo.boardingGate,
            "departureTerminal": flightInfo.departureTerminal
        ]
        
        // Fetch the trip document to get the current flightInfo array
        tripRef?.document(flightInfo.id).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                var flightInfoArray = document.data()?["flightInfo"] as? [[String: Any]] ?? []
                
                // Find the index of the flight to update
                if let index = flightInfoArray.firstIndex(where: { $0["id"] as? String == flightInfo.id }) {
                    flightInfoArray[index] = flightData
                    
                    // Update the flightInfo array in Firebase
                    self.tripRef?.document(flightInfo.id).updateData(["flightInfo": flightInfoArray]) { error in
                        print("updating data")
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            print("successfully updated data")
                            completion(.success(()))
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "Flight not found"])))
                }
            }
        }
    }
    
    func deleteFlightInfo(_ flightInfoID: String, fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        tripRef?.document(tripID).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                var flightInfoArray = document.data()?["flightInfo"] as? [[String: Any]] ?? []
                
                // Find the index of the flight to delete
                if let index = flightInfoArray.firstIndex(where: { $0["id"] as? String == flightInfoID }) {
                    flightInfoArray.remove(at: index)
                    
                    // Update the flightInfo array in Firebase
                    self.tripRef?.document(tripID).updateData(["flightInfo": flightInfoArray]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "Flight not found"])))
                }
            } else {
                completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "Trip not found"])))
            }
        }
    }
    
    // Trip Accommodations
    func fetchAccommodationsForTrip(_ tripID: String, completion: @escaping (Result<[Accommodation], Error>) -> Void) {
        tripRef?.document(tripID).getDocument { (document, error) in
            if let document = document, document.exists {
                if let data = document.data(), let accommodationsData = data["accommodations"] as? [[String: Any]] {
                    var accommodations: [Accommodation] = []
                    
                    for accommodationData in accommodationsData {
                        if let id = accommodationData["id"] as? String,
                           let name = accommodationData["name"] as? String,
                           let location = accommodationData["location"] as? String,
                           let checkInTimestamp = accommodationData["checkInDate"] as? Timestamp,
                           let checkOutTimestamp = accommodationData["checkOutDate"] as? Timestamp {
                            
                            let checkInDate = checkInTimestamp.dateValue()
                            let checkOutDate = checkOutTimestamp.dateValue()
                            
                            let accommodation = Accommodation(id: id, name: name, location: location, checkInDate: checkInDate, checkOutDate: checkOutDate)
                            accommodations.append(accommodation)
                        }
                    }
                    completion(.success(accommodations))
                } else {
                    completion(.success([]))
                }
            } else {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Document does not exist"])))
                }
            }
        }
    }
    
    func addAccommodationToTrip(_ accommodation: Accommodation, tripID: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        let accommodationData: [String: Any] = [
            "id": accommodation.id,
            "name": accommodation.name,
            "location": accommodation.location,
            "checkInDate": Timestamp(date: accommodation.checkInDate),
            "checkOutDate": Timestamp(date: accommodation.checkOutDate)
        ]
        
        tripRef?.document(tripID).updateData(["accommodations": FieldValue.arrayUnion([accommodationData])]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteAccommodationFromTrip(_ accommodationID: String, tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        tripRef?.document(tripID).getDocument { (document, error) in
            if let document = document, document.exists {
                var accommodationsData = document.data()?["accommodations"] as? [[String: Any]] ?? []
                
                accommodationsData.removeAll { $0["id"] as? String == accommodationID }
                
                self.tripRef?.document(tripID).updateData(["accommodations": accommodationsData]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            } else {
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Document does not exist"])))
                }
            }
        }
    }
    
    // Trip destinations
    func fetchDestinationsForTrip(_ tripID: String, completion: @escaping (Result<[Activity], Error>) -> Void) {
        //        db.collection("trips").document(tripID).collection("destinations").getDocuments { snapshot, error in
        //            if let error = error {
        //                completion(.failure(error))
        //            } else {
        //                let destinations = snapshot?.documents.compactMap { document -> Destination? in
        //                    let data = document.data()
        //                    // to add
        //                    return destination
        //                } ?? []
        //                completion(.success(destinations))
        //            }
        //        }
    }
    
    func addDestination(_ destination: Activity, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let destinationData: [String: Any] = [
            "name": destination.name,
            "startDate": destination.startDate,
            "endDate": destination.endDate,
            // to add
        ]
        
        db.collection("trips").document(tripID).collection("destinations").addDocument(data: destinationData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateDestination(_ destination: Activity, completion: @escaping (Result<Void, Error>) -> Void) {
        let destinationData: [String: Any] = [
            "name": destination.name,
            "startDate": destination.startDate,
            "endDate": destination.endDate,
            // to add
        ]
        
        db.collection("destinations").document(destination.id).setData(destinationData, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteDestination(_ destination: Activity, fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("trips").document(tripID).collection("destinations").document(destination.id).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // User profiles
    func fetchUserProfile(completion: @escaping (Result<AuthUser, Error>) -> Void) {
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
                
                let user = AuthUser(id: userID, email: email, displayName: displayName, profileImageURL: URL(string: profileImageURL ?? ""))
                completion(.success(user))
            }
        }
    }
    
    func updateUserProfile(_ user: AuthUser, completion: @escaping (Result<Void, Error>) -> Void) {
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
    func signUp(email: String, password: String, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else {
                guard let userID = authResult?.user.uid else {
                    completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
                    return
                }
                
                print("\(userID) registered account.")
                
                let user = AuthUser(id: userID, email: email)
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
            
    func signIn(email: String, password: String, completion: @escaping (Result<AuthUser, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else {
                guard let userID = authResult?.user.uid else {
                    completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])))
                    return
                }
                                                
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
