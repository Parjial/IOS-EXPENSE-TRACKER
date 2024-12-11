import UIKit
import CoreData

// Protocol for delegate
protocol AddExpenseViewControllerDelegate: AnyObject {
    func updateTotalLabels()
}

class AddExpenseViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets
    @IBOutlet weak var category: UILabel!
    @IBOutlet weak var allIncome: UILabel!
    @IBOutlet weak var allExpense: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var typeSegmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!  // Add Table View Outlet
    @IBOutlet weak var deleteButton: UIButton! // Add this IBOutlet for the delete
    @IBOutlet weak var clearAllButton: UIButton!  // Clear All Button Outlet
    var isDataSaved = false  // Flag to check if data has been saved

    // MARK: - Properties
    var expenses: [NSManagedObject] = []
    var incomes: [NSManagedObject] = []
    var currentData: [NSManagedObject] = [] // Holds either expenses or incomes based on the selected segment
    weak var delegate: AddExpenseViewControllerDelegate? // Delegate to update totals in ViewController
    var selectedItem: NSManagedObject? // Store selected item from the table view

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchData()
        updateTableViewForSelectedType() // Set the initial data based on the segment control
    }

    // MARK: - Setup UI
    private func setupUI() {
        datePicker.maximumDate = Date() // Prevent future dates
        toggleCategoryFieldVisibility()  // Toggle category field visibility based on selected segment
        tableView.delegate = self
        tableView.dataSource = self
        deleteButton.isHidden = true  // Hide the delete button initially
    }

    // MARK: - Segment Control Action
    @IBAction func typeChanged(_ sender: UISegmentedControl) {
        updateTableViewForSelectedType()  // Update the data displayed based on the selected segment
        toggleCategoryFieldVisibility()  // Update visibility of category field
    }

    // MARK: - Update Table View Data
    private func updateTableViewForSelectedType() {
        if typeSegmentControl.selectedSegmentIndex == 0 {  // Expense
            currentData = expenses
        } else {  // Income
            currentData = incomes
        }
        tableView.reloadData()  // Reload the table view with the new data
    }

    // MARK: - Save Action
    @IBAction func saveExpenseOrIncome(_ sender: UIButton) {
        
        // Check for validation before proceeding
        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(message: "Please enter a title.")
            return
        }

        guard let amountText = amountTextField.text, let amount = Double(amountText), amount > 0 else {
            showAlert(message: "Please enter a valid amount greater than zero.")
            return
        }

        let context = AppDelegate.shared.context
        let currentDate = datePicker.date
        
        // If we have a selected item, update it, otherwise create a new one
        if let selectedItem = selectedItem {
            // Update the existing data
            
            if typeSegmentControl.selectedSegmentIndex == 0 {  // Expense
                guard let category = categoryTextField.text, !category.isEmpty else {
                    showAlert(message: "Please enter a category for the expense.")
                    return
                }
                selectedItem.setValue(title, forKey: "title")
                selectedItem.setValue(category, forKey: "category")
                selectedItem.setValue(amount, forKey: "amount")
                selectedItem.setValue(currentDate, forKey: "date")
                print("Expense updated: \(title) - Category: \(category) - Amount: \(amount) - Date: \(currentDate)")
            } else {  // Income
                selectedItem.setValue(title, forKey: "title")
                selectedItem.setValue(amount, forKey: "amount")
                selectedItem.setValue(currentDate, forKey: "date")
                print("Income updated: \(title) - Amount: \(amount) - Date: \(currentDate)")
            }

        } else {
            // Create new data if no item was selected
            if typeSegmentControl.selectedSegmentIndex == 0 {  // Expense
                guard let category = categoryTextField.text, !category.isEmpty else {
                    showAlert(message: "Please enter a category for the expense.")
                    return
                }
                let newExpense = NSEntityDescription.insertNewObject(forEntityName: "Expense", into: context)
                newExpense.setValue(title, forKey: "title")
                newExpense.setValue(category, forKey: "category")
                newExpense.setValue(amount, forKey: "amount")
                newExpense.setValue(currentDate, forKey: "date")
                print("Expense saved: \(title) - Category: \(category) - Amount: \(amount) - Date: \(currentDate)")
            } else {  // Income
                let newIncome = NSEntityDescription.insertNewObject(forEntityName: "Income", into: context)
                newIncome.setValue(title, forKey: "title")
                newIncome.setValue(amount, forKey: "amount")
                newIncome.setValue(currentDate, forKey: "date")
                print("Income saved: \(title) - Amount: \(amount) - Date: \(currentDate)")
            }
        }

        do {
            try context.save()
            print("Data saved successfully!")
            fetchData()  // Reload data after saving
            updateTableViewForSelectedType()  // Update table data based on selected type
            delegate?.updateTotalLabels()  // Notify ViewController to update totals
            clearTextFields()  // Clear text fields for new input
            navigationController?.popViewController(animated: true)
        } catch {
            showAlert(message: "Failed to save data. Please try again.")
            print("Error saving data: \(error)")
        }
    }

    // Function to clear the text fields
    private func clearTextFields() {
        titleTextField.text = ""
        categoryTextField.text = ""
        amountTextField.text = ""
        datePicker.date = Date()
        clearAllButton.isHidden = false  // Show the "Clear All" button again
        deleteButton.isHidden = true  // Hide the delete button after clearing
        selectedItem = nil  // Reset the selected item
    }



    // MARK: - Fetch Data from Core Data
    private func fetchData() {
        let context = AppDelegate.shared.context
        let expenseFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Expense")
        let incomeFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Income")

        do {
            expenses = try context.fetch(expenseFetchRequest)
            incomes = try context.fetch(incomeFetchRequest)
        } catch {
            print("Failed to fetch data: \(error)")
        }
    }

    // MARK: - Table View DataSource Methods
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1  // Only one section to show either expenses or incomes based on selection
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentData.count // The number of rows is based on the selected data type (either expenses or incomes)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseCell", for: indexPath)

        let item = currentData[indexPath.row]

        if let title = item.value(forKey: "title") as? String {
            cell.textLabel?.text = title
        }

        if let amount = item.value(forKey: "amount") as? Double {
            cell.detailTextLabel?.text = "Amount: \(amount)"
        }

        // Only show category for Expense, not Income
        if currentData == expenses {
            if let category = item.value(forKey: "category") as? String {
                cell.detailTextLabel?.text?.append(" - Category: \(category)")
            }
        }

        return cell
    }

    // MARK: - Handle Row Selection in TableView
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = currentData[indexPath.row]
        
        if let title = selected.value(forKey: "title") as? String {
            titleTextField.text = title
        }
        
        if let amount = selected.value(forKey: "amount") as? Double {
            amountTextField.text = String(amount)
        }
        
        if currentData == expenses {
            if let category = selected.value(forKey: "category") as? String {
                categoryTextField.text = category
            }
        }
        
        if let date = selected.value(forKey: "date") as? Date {
            datePicker.date = date
        }
        
        // Hide the Clear All button when a row is selected
        clearAllButton.isHidden = true
        
        // Show the delete button when an item is selected
            deleteButton.isHidden = false
        
        // Store the selected item to update it later
        selectedItem = selected
    }

    // MARK: - Clear All Action with Confirmation
    @IBAction func clearAllData(_ sender: UIButton) {
        let alert = UIAlertController(title: "Are you sure?", message: "This will delete all the expenses or incomes.", preferredStyle: .alert)

        // "Cancel" action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        // "Delete" action
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.clearData()  // Proceed with data clearing
        }))

        present(alert, animated: true, completion: nil)
    }

    private func clearData() {
        let context = AppDelegate.shared.context
        if typeSegmentControl.selectedSegmentIndex == 0 {  // Expense
            for expense in expenses {
                context.delete(expense)
            }
            expenses.removeAll()
            print("All expenses cleared")
        } else {  // Income
            for income in incomes {
                context.delete(income)
            }
            incomes.removeAll()
            print("All incomes cleared")
        }

        do {
            try context.save()
            fetchData()  // Reload data after clearing
            updateTableViewForSelectedType()  // Update table data based on selected type
        } catch {
            print("Error clearing data: \(error)")
        }
    }

    // MARK: - Helper Functions
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Toggle Category Field Visibility
    private func toggleCategoryFieldVisibility() {
        if typeSegmentControl.selectedSegmentIndex == 0 {  // Expense
            categoryTextField.isHidden = false
            category.isHidden = false
            allIncome.isHidden = true
            allExpense.isHidden = false
        } else {  // Income
            categoryTextField.isHidden = true
            category.isHidden = true
            allIncome.isHidden = false
            allExpense.isHidden = true
        }
    }
    // MARK: - Delete Action
    @IBAction func deleteSelectedItem(_ sender: UIButton) {
        guard let selectedItem = selectedItem else {
            showAlert(message: "No item selected for deletion.")
            return
        }

        let context = AppDelegate.shared.context
        
        // Delete the selected item
        context.delete(selectedItem)
        
        do {
            try context.save()
            print("Item deleted successfully!")
            
            // Reload data and refresh table view after deletion
            fetchData()
            updateTableViewForSelectedType()  // Update table data based on selected type
            clearTextFields()  // Clear text fields after deletion
            
            // Hide the delete button again
            deleteButton.isHidden = true
            
        } catch {
            showAlert(message: "Failed to delete the item. Please try again.")
            print("Error deleting data: \(error)")
        }
    }

}
