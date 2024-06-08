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
    
    var tripID: String?
    
    let dateFormatter = DateFormatter()
    
    var datePicker: UIDatePicker?
    var dateTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        expensesTableView.delegate = self
        expensesTableView.dataSource = self
        
        // Do any additional setup after loading the view.
        
        fetchExpenses()
    }
    
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
            
            guard let tripID = self.tripID else { return }
            
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
            
            guard let tripID = tripID else { return }
            
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
    
    func fetchExpenses() -> Void {
        guard let tripID = tripID else { return }
        
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
    
    func groupExpensesByDate() {
        groupedExpenses = Dictionary(grouping: expenses, by: { Calendar.current.startOfDay(for: $0.date ?? Date()) })
        sortedDates = groupedExpenses.keys.sorted()
    }
    
    func updateTotalSpentLabel() {
        let totalSpent = expenses.reduce(0) { $0 + ($1.amount ?? 0) }
        totalSpentLabel.text = String(format: "$%.2f AUD", totalSpent)
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
