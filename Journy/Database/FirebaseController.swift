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
        tripRef?.document(tripID).getDocument { (document, error) in
            if let document = document, document.exists {
                if let data = document.data(), let expensesData = data["expenses"] as? [[String: Any]] {
                    var expenses: [Expense] = []
                    
                    for expenseData in expensesData {
                        print(expenseData)
                        if let id = expenseData["id"] as? String,
                           let title = expenseData["title"] as? String,
                           let amount = expenseData["amount"] as? Double,
                           let dateTimestamp = expenseData["date"] as? Timestamp {
                            
                            let date = dateTimestamp.dateValue()
                            
                            let expense = Expense(id: id, title: title, amount: amount, date: date)
                            expenses.append(expense)
                        }
                    }
                    completion(.success(expenses))
                } else {
                    print("empty array returned")
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
    
    func addExpense(_ expense: Expense, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let expenseData: [String: Any] = [
            "id": expense.id as Any,
            "title": expense.title as Any,
            "amount": expense.amount as Any,
            "date": expense.date as Any
        ]
        
        tripRef?.document(tripID).updateData(["expenses": FieldValue.arrayUnion([expenseData])]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func updateExpense(_ expense: Expense, completion: @escaping (Result<Void, Error>) -> Void) {
//        let expenseData: [String: Any] = [
//            "title": expense.title,
//            "amount": expense.amount,
//            "date": expense.date,
//            // to add
//        ]
//        
//        db.collection("expenses").document(expense.id).setData(expenseData, merge: true) { error in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                completion(.success(()))
//            }
//        }
    }
    
    func deleteExpense(_ expenseID: String, fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        tripRef?.document(tripID).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
            } else if let document = document, document.exists {
                var expensesArray = document.data()?["expenses"] as? [[String: Any]] ?? []
                
                if let index = expensesArray.firstIndex(where: { $0["id"] as? String == expenseID }) {
                    expensesArray.remove(at: index)
                    
                    self.tripRef?.document(tripID).updateData(["expenses": expensesArray]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "Expense not found"])))
                }
            } else {
                completion(.failure(NSError(domain: "FirebaseController", code: 0, userInfo: [NSLocalizedDescriptionKey: "Trip not found"])))
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
            "airline": flightInfo.airline as Any,
            "flightNumber": flightInfo.flightNumber,
            "departureAirport": flightInfo.departureAirport as Any,
            "arrivalAirport": flightInfo.arrivalAirport as Any,
            "departureDate": flightInfo.departureDate,
            "arrivalDate": flightInfo.arrivalDate as Any,
            "boardingGate": flightInfo.boardingGate as Any,
            "departureTerminal": flightInfo.departureTerminal as Any
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
                    completion(.failure(NSError(domain: "Firebase Controller", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document does not exist"])))
                }
            }
        }
    }
    
    func addAccommodationToTrip(_ accommodation: Accommodation, tripID: String, completion: @escaping (Result<Void, any Error>) -> Void) {
        let accommodationData: [String: Any] = [
            "id": accommodation.id as Any,
            "name": accommodation.name as Any,
            "location": accommodation.location as Any,
            "checkInDate": Timestamp(date: accommodation.checkInDate ?? Date()),
            "checkOutDate": Timestamp(date: accommodation.checkOutDate ?? Date())
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
    func fetchActivitiesForTrip(_ tripID: String, completion: @escaping (Result<[Activity], Error>) -> Void) {
        tripRef?.document(tripID).getDocument { (document, error) in
            if let document = document, document.exists {
                if let data = document.data(), let activitiesData = data["activities"] as? [[String: Any]] {
                    var activities: [Activity] = []
                    
                    for activityData in activitiesData {
                        if let id = activityData["id"] as? String,
                           let name = activityData["name"] as? String,
                           let location = activityData["location"] as? String,
                           let dateTimeTimestamp = activityData["dateTime"] as? Timestamp {
                            
                            let dateTime = dateTimeTimestamp.dateValue()
                            
                            let activity = Activity(id: id, name: name, location: location, activityDate: dateTime)
                            activities.append(activity)
                        }
                    }
                    completion(.success(activities))
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
    
    func addActivity(_ activity: Activity, toTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let activityData: [String: Any] = [
            "id": activity.id as Any,
            "name": activity.name as Any,
            "location": activity.location as Any,
            "dateTime": Timestamp(date: activity.activityDate ?? Date())
        ]
        
        tripRef?.document(tripID).updateData(["activities": FieldValue.arrayUnion([activityData])]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func deleteActivity(_ activityID: String, fromTrip tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        tripRef?.document(tripID).getDocument { (document, error) in
            if let document = document, document.exists {
                var activitiesData = document.data()?["activities"] as? [[String: Any]] ?? []
                
                activitiesData.removeAll { $0["id"] as? String == activityID }
                
                self.tripRef?.document(tripID).updateData(["activities": activitiesData]) { error in
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
