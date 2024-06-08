//
//  ExpensesViewController.swift
//  Journy
//
//  Created by Justin Goi on 7/6/2024.
//

import UIKit

class ExpensesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var totalSpentLabel: UILabel!
    @IBOutlet weak var currencyConversionLabel: UILabel!
    @IBOutlet weak var expensesTableView: UITableView!
    
    weak var databaseController: DatabaseProtocol?
    
    var expenses: [Expense] = []
    var groupedExpenses: [Date: [Expense]] = [:]
    var sortedDates: [Date] = []
    
    var currentTrip: Trip?
    
    let dateFormatter = DateFormatter()
    
    var datePicker: UIDatePicker?
    var dateTextField: UITextField?
    
    private var conversionApiKey = "0f5c5a66820fd0bca49b95c7"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        expensesTableView.delegate = self
        expensesTableView.dataSource = self
        
        // Do any additional setup after loading the view.
        
        fetchExpenses()
        
        fetchExchangeRate()
    }
    
    // MARK: Actions
    
    /**
     Action method triggered when the user taps the "Add Expense" button.

     - Parameter sender: The object that triggered the action.
     */
    @IBAction func addExpense(_ sender: Any) {
        let alert = UIAlertController(title: "New Expense", message: "Add a new expense", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Title"
        }
        alert.addTextField { textField in
            textField.placeholder = "Amount"
            textField.keyboardType = .decimalPad
        }
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.addTarget(self, action: #selector(self.datePickerValueChanged(_:)), for: .valueChanged)
        
        alert.addTextField { textField in
            textField.placeholder = "Date"
            textField.inputView = datePicker
            self.dateTextField = textField
        }
        
        self.datePicker = datePicker
        
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            guard let titleField = alert.textFields?[0],
                  let amountField = alert.textFields?[1],
                  let title = titleField.text,
                  let amountText = amountField.text,
                  let amount = Double(amountText) else {
                return
            }
            
            let newExpense = Expense(id: UUID().uuidString, title: title, amount: amount, date: datePicker.date)
            
            guard let tripID = self.currentTrip?.id else { return }
            
            self.databaseController?.addExpense(newExpense, toTrip: tripID) { [weak self] result in
                switch result {
                case .success:
                    self?.fetchExpenses()
                    self?.displayMessage(title: "Expense Added", message: "Successfully added expense")
                case .failure(let error):
                    self?.displayMessage(title: "Error", message: "Failed to save expense information: \(error.localizedDescription)")
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        if let dateTextField = self.dateTextField {
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateTextField.text = dateFormatter.string(from: sender.date)
        }
    }
    
    // MARK: Table View Methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return groupedExpenses.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let date = sortedDates[section]
        
        return groupedExpenses[date]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "expenseCell", for: indexPath)
        
        let date = sortedDates[indexPath.section]
        if let expense = groupedExpenses[date]?[indexPath.row] {
            var content = cell.defaultContentConfiguration()
            
            if let title = expense.title,
               let amount = expense.amount {
                content.text = title
                content.secondaryText = String(format: "$%.2f", amount)
                cell.contentConfiguration = content
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date = sortedDates[section]
        dateFormatter.dateStyle = .long
        
        return dateFormatter.string(from: date)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let date = sortedDates[indexPath.section]
            
            guard let tripID = currentTrip?.id else { return }
            
            let expenseToDelete = groupedExpenses[date]?[indexPath.row]
            
            databaseController?.deleteExpense(expenseToDelete?.id ?? "", fromTrip: tripID) { [weak self] result in
                switch result {
                case .success:
                    self?.groupedExpenses[date]?.remove(at: indexPath.row)
                    
                    if self?.groupedExpenses[date]?.isEmpty == true {
                        self?.groupedExpenses.removeValue(forKey: date)
                        self?.sortedDates.remove(at: indexPath.section)
                        
                        DispatchQueue.main.async {
                            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
                        }
                    } else {
                        DispatchQueue.main.async {
                            tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
                    }
                    
                    self?.expenses = self?.groupedExpenses.values.flatMap { $0 } ?? []
                    self?.updateTotalSpentLabel()
                    
                case .failure(let error):
                    print("Error deleting expense: \(error.localizedDescription)")
                    self?.displayMessage(title: "Error", message: "Error deleting expense. Please try again later.")
                }
            }
        }
    }
    
    // MARK: Helper Methods
    
    /**
     Fetches expenses data from the database and updates the UI.
     */
    func fetchExpenses() -> Void {
        guard let tripID = currentTrip?.id else { return }
        
        databaseController?.fetchExpensesForTrip(tripID) { [weak self] result in
            switch result {
            case .success(let expensesArray):
                print("fetching expenses \(expensesArray)")
                
                DispatchQueue.main.async {
                    self?.expenses = expensesArray
                    self?.groupExpensesByDate()
                    self?.expensesTableView.reloadData()
                    self?.updateTotalSpentLabel()
                }
            case .failure(let error):
                print("Error fetching expenses: \(error.localizedDescription)")
            }
        }
    }
    
    /**
     Groups expenses by date and updates the UI.
     */
    func groupExpensesByDate() {
        groupedExpenses = Dictionary(grouping: expenses, by: { Calendar.current.startOfDay(for: $0.date ?? Date()) })
        sortedDates = groupedExpenses.keys.sorted()
    }
    
    /**
     Updates the total spent label with the sum of all expenses.
     */
    func updateTotalSpentLabel() {
        let totalSpent = expenses.reduce(0) { $0 + ($1.amount ?? 0) }
        totalSpentLabel.text = String(format: "$%.2f AUD", totalSpent)
    }
    
    /**
     Fetches the currency conversion rate for the trip's location and updates the UI.
     */
    func fetchExchangeRate() {
        guard let location = currentTrip?.location else {
            print("No location found for the current trip.")
            return
        }
        
        // Determine the currency code for the location
        let currencyCode = getCurrencyCode(for: location)
        
        let urlStr = "https://v6.exchangerate-api.com/v6/\(conversionApiKey)/latest/AUD"
        
        guard let url = URL(string: urlStr) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            print("fetching exchange rate")
            if let error = error {
                print("Error fetching exchange rate: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let conversionRates = json["conversion_rates"] as? [String: Double],
                   let rate = conversionRates[currencyCode] {
                    DispatchQueue.main.async {
                        self?.currencyConversionLabel.text = String(format: "1 AUD approx %.2f %@", rate, currencyCode)
                    }
                }
            } catch {
                print("Error parsing exchange rate data: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    /**
     Retrieves the currency code for a given location.

     - Parameter location: The location for which to retrieve the currency code.
     - Returns: The currency code associated with the location.
     */
    func getCurrencyCode(for location: String) -> String {
        let currencyCodes: [String: String] = [
            "Afghanistan": "AFN",
            "Albania": "ALL",
            "Algeria": "DZD",
            "Andorra": "EUR",
            "Angola": "AOA",
            "Antigua and Barbuda": "XCD",
            "Argentina": "ARS",
            "Armenia": "AMD",
            "Australia": "AUD",
            "Austria": "EUR",
            "Azerbaijan": "AZN",
            "Bahamas": "BSD",
            "Bahrain": "BHD",
            "Bangladesh": "BDT",
            "Barbados": "BBD",
            "Belarus": "BYN",
            "Belgium": "EUR",
            "Belize": "BZD",
            "Benin": "XOF",
            "Bhutan": "BTN",
            "Bolivia": "BOB",
            "Bosnia and Herzegovina": "BAM",
            "Botswana": "BWP",
            "Brazil": "BRL",
            "Brunei": "BND",
            "Bulgaria": "BGN",
            "Burkina Faso": "XOF",
            "Burundi": "BIF",
            "Cabo Verde": "CVE",
            "Cambodia": "KHR",
            "Cameroon": "XAF",
            "Canada": "CAD",
            "Central African Republic": "XAF",
            "Chad": "XAF",
            "Chile": "CLP",
            "China": "CNY",
            "Colombia": "COP",
            "Comoros": "KMF",
            "Congo, Democratic Republic of the": "CDF",
            "Congo, Republic of the": "XAF",
            "Costa Rica": "CRC",
            "Croatia": "HRK",
            "Cuba": "CUP",
            "Cyprus": "EUR",
            "Czech Republic": "CZK",
            "Denmark": "DKK",
            "Djibouti": "DJF",
            "Dominica": "XCD",
            "Dominican Republic": "DOP",
            "Ecuador": "USD",
            "Egypt": "EGP",
            "El Salvador": "USD",
            "Equatorial Guinea": "XAF",
            "Eritrea": "ERN",
            "Estonia": "EUR",
            "Eswatini": "SZL",
            "Ethiopia": "ETB",
            "Fiji": "FJD",
            "Finland": "EUR",
            "France": "EUR",
            "Gabon": "XAF",
            "Gambia": "GMD",
            "Georgia": "GEL",
            "Germany": "EUR",
            "Ghana": "GHS",
            "Greece": "EUR",
            "Grenada": "XCD",
            "Guatemala": "GTQ",
            "Guinea": "GNF",
            "Guinea-Bissau": "XOF",
            "Guyana": "GYD",
            "Haiti": "HTG",
            "Honduras": "HNL",
            "Hungary": "HUF",
            "Iceland": "ISK",
            "India": "INR",
            "Indonesia": "IDR",
            "Iran": "IRR",
            "Iraq": "IQD",
            "Ireland": "EUR",
            "Israel": "ILS",
            "Italy": "EUR",
            "Jamaica": "JMD",
            "Japan": "JPY",
            "Jordan": "JOD",
            "Kazakhstan": "KZT",
            "Kenya": "KES",
            "Kiribati": "AUD",
            "Korea, North": "KPW",
            "Korea, South": "KRW",
            "Kosovo": "EUR",
            "Kuwait": "KWD",
            "Kyrgyzstan": "KGS",
            "Laos": "LAK",
            "Latvia": "EUR",
            "Lebanon": "LBP",
            "Lesotho": "LSL",
            "Liberia": "LRD",
            "Libya": "LYD",
            "Liechtenstein": "CHF",
            "Lithuania": "EUR",
            "Luxembourg": "EUR",
            "Madagascar": "MGA",
            "Malawi": "MWK",
            "Malaysia": "MYR",
            "Maldives": "MVR",
            "Mali": "XOF",
            "Malta": "EUR",
            "Marshall Islands": "USD",
            "Mauritania": "MRU",
            "Mauritius": "MUR",
            "Mexico": "MXN",
            "Micronesia": "USD",
            "Moldova": "MDL",
            "Monaco": "EUR",
            "Mongolia": "MNT",
            "Montenegro": "EUR",
            "Morocco": "MAD",
            "Mozambique": "MZN",
            "Myanmar": "MMK",
            "Namibia": "NAD",
            "Nauru": "AUD",
            "Nepal": "NPR",
            "Netherlands": "EUR",
            "New Zealand": "NZD",
            "Nicaragua": "NIO",
            "Niger": "XOF",
            "Nigeria": "NGN",
            "North Macedonia": "MKD",
            "Norway": "NOK",
            "Oman": "OMR",
            "Pakistan": "PKR",
            "Palau": "USD",
            "Panama": "PAB",
            "Papua New Guinea": "PGK",
            "Paraguay": "PYG",
            "Peru": "PEN",
            "Philippines": "PHP",
            "Poland": "PLN",
            "Portugal": "EUR",
            "Qatar": "QAR",
            "Romania": "RON",
            "Russia": "RUB",
            "Rwanda": "RWF",
            "Saint Kitts and Nevis": "XCD",
            "Saint Lucia": "XCD",
            "Saint Vincent and the Grenadines": "XCD",
            "Samoa": "WST",
            "San Marino": "EUR",
            "Sao Tome and Principe": "STN",
            "Saudi Arabia": "SAR",
            "Senegal": "XOF",
            "Serbia": "RSD",
            "Seychelles": "SCR",
            "Sierra Leone": "SLL",
            "Singapore": "SGD",
            "Slovakia": "EUR",
            "Slovenia": "EUR",
            "Solomon Islands": "SBD",
            "Somalia": "SOS",
            "South Africa": "ZAR",
            "South Sudan": "SSP",
            "Spain": "EUR",
            "Sri Lanka": "LKR",
            "Sudan": "SDG",
            "Suriname": "SRD",
            "Sweden": "SEK",
            "Switzerland": "CHF",
            "Syria": "SYP",
            "Taiwan": "TWD",
            "Tajikistan": "TJS",
            "Tanzania": "TZS",
            "Thailand": "THB",
            "Timor-Leste": "USD",
            "Togo": "XOF",
            "Tonga": "TOP",
            "Trinidad and Tobago": "TTD",
            "Tunisia": "TND",
            "Turkey": "TRY",
            "Turkmenistan": "TMT",
            "Tuvalu": "AUD",
            "Uganda": "UGX",
            "Ukraine": "UAH",
            "United Arab Emirates": "AED",
            "United Kingdom": "GBP",
            "United States": "USD",
            "Uruguay": "UYU",
            "Uzbekistan": "UZS",
            "Vanuatu": "VUV",
            "Vatican City": "EUR",
            "Venezuela": "VES",
            "Vietnam": "VND",
            "Yemen": "YER",
            "Zambia": "ZMW",
            "Zimbabwe": "ZWL"
        ]
        
        // Find the first match for a country in the location string
        for (country, currencyCode) in currencyCodes {
            if location.contains(country) {
                return currencyCode
            }
        }
        
        // Default to USD if no country match is found
        return "USD"
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
