//
//  AddPlanViewController.swift
//  Journy
//
//  Created by Justin Goi on 15/5/2024.
//

import UIKit

class AddPlanViewController: UIViewController {
    
    @IBOutlet weak var planSegmentedControl: UISegmentedControl!
    @IBOutlet weak var inputStackView: UIStackView!
    
    weak var databaseController: DatabaseProtocol?
    var tripID: String?
    
    var datePickerContainer: UIView?
    var datePicker: UIDatePicker?
    var timePickerContainer: UIView?
    var timePicker: UIDatePicker?
    
    var textFieldValues: [String: String] = [:]
    var dateFieldValues: [String: Date] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        setupConstraints()
        updateTextFields()
    }
    
    func setupConstraints() {
        inputStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            inputStackView.topAnchor.constraint(equalTo: planSegmentedControl.bottomAnchor, constant: 50),
            inputStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            inputStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            inputStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
        
        inputStackView.spacing = 20
        
        // Add constraints for the text fields
        inputStackView.arrangedSubviews.forEach { textField in
            if let textField = textField as? UITextField {
                textField.translatesAutoresizingMaskIntoConstraints = false
                textField.heightAnchor.constraint(equalToConstant: 30).isActive = true
                textField.leadingAnchor.constraint(equalTo: inputStackView.leadingAnchor, constant: 8).isActive = true
                textField.trailingAnchor.constraint(equalTo: inputStackView.trailingAnchor, constant: -8).isActive = true
            }
        }
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        updateTextFields()
    }
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard let tripID = tripID else {
            displayMessage(title: "Error", message: "Trip ID not found.")
            return
        }
        
        switch planSegmentedControl.selectedSegmentIndex {
        case 0: // Flight
            print(textFieldValues)
            saveFlightInfo(tripID: tripID)
        case 1: // Accommodation
            print("temp")
//            saveAccommodation(tripID: tripID)
        case 2: // Activity
            print("temp")
//            saveActivity(tripID: tripID)
        default:
            break
        }
    }
    
    func updateTextFields() {
        inputStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        switch planSegmentedControl.selectedSegmentIndex {
        case 0: // Flight
            let departureDateTextField = createDateTextField(placeholder: "Departure Date")
            let flightNumberTextField = createTextField(placeholder: "Flight Number")
            inputStackView.addArrangedSubview(departureDateTextField)
            inputStackView.addArrangedSubview(flightNumberTextField)
            
        case 1: // Accommodation
            let nameTextField = createTextField(placeholder: "Accommodation Name")
            let checkInDateTextField = createDateTextField(placeholder: "Check-in Date")
            let checkOutDateTextField = createDateTextField(placeholder: "Check-out Date")
            let locationTextField = createTextField(placeholder: "Location")
            inputStackView.addArrangedSubview(nameTextField)
            inputStackView.addArrangedSubview(checkInDateTextField)
            inputStackView.addArrangedSubview(checkOutDateTextField)
            inputStackView.addArrangedSubview(locationTextField)
            
        case 2: // Activity
            let nameTextField = createTextField(placeholder: "Activity Name")
            let locationTextField = createTextField(placeholder: "Activity Location")
            let dateTextField = createDateTextField(placeholder: "Activity Date")
            let timeTextField = createTimeTextField(placeholder: "Activity Time")
            inputStackView.addArrangedSubview(nameTextField)
            inputStackView.addArrangedSubview(locationTextField)
            inputStackView.addArrangedSubview(dateTextField)
            inputStackView.addArrangedSubview(timeTextField)
            
        default:
            break
        }
    }
    
    func createTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(textFieldValueChanged(_:)), for: .editingChanged)
        
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return textField
    }
    
    func createDateTextField(placeholder: String) -> UITextField {
        let textField = createTextField(placeholder: placeholder)
        textField.inputView = createDatePickerContainer()
        return textField
    }
    
    func createTimeTextField(placeholder: String) -> UITextField {
        let textField = createTextField(placeholder: placeholder)
        textField.inputView = UIView()
        textField.inputAccessoryView = createTimePickerContainer()
        return textField
    }
    
    @objc func textFieldValueChanged(_ textField: UITextField) {
        textFieldValues[textField.placeholder ?? ""] = textField.text
    }
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if let textField = inputStackView.arrangedSubviews.first(where: { $0.isFirstResponder }) as? UITextField {
            textField.text = dateFormatter.string(from: sender.date)
            dateFieldValues[textField.placeholder ?? ""] = sender.date
        }
    }
    
    @objc func timePickerValueChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        if let textField = inputStackView.arrangedSubviews.first(where: { $0.isFirstResponder }) as? UITextField {
            textField.text = dateFormatter.string(from: sender.date)
            dateFieldValues[textField.placeholder ?? ""] = sender.date
        }
    }
    
    func createDatePickerContainer() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 216))
        
        let datePicker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: 216))
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: .valueChanged)
        
        container.addSubview(datePicker)
        
        datePickerContainer = container
        self.datePicker = datePicker
        
        return container
    }
    
    func createTimePickerContainer() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 216))
        
        let timePicker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: container.frame.width, height: 216))
        timePicker.datePickerMode = .time
        timePicker.addTarget(self, action: #selector(timePickerValueChanged(_:)), for: .valueChanged)
        
        container.addSubview(timePicker)
        
        timePickerContainer = container
        self.timePicker = timePicker
        
        return container
    }
    
    func saveFlightInfo(tripID: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let flightNumber = textFieldValues["Flight Number"], let departureDate = dateFieldValues["Departure Date"] else {
            displayMessage(title: "Error", message: "Please fill in all the flight details.")
            return
        }
        
        let flightInfo = FlightInfo(id: UUID().uuidString, flightNumber: flightNumber, departureDate: departureDate)
        
        databaseController?.addFlightInfo(flightInfo, toTrip: tripID) { [weak self] result in
            switch result {
            case .success:
                self?.displayMessage(title: "Success", message: "Flight information saved successfully.")
                self?.navigationController?.popViewController(animated: true)
            case .failure(let error):
                self?.displayMessage(title: "Error", message: "Failed to save flight information: \(error.localizedDescription)")
            }
        }
    }
}
