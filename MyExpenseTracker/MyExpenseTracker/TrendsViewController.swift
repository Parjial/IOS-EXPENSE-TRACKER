import UIKit
import CoreData

class TrendsViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var smartInsightsLabel: UILabel!
    @IBOutlet weak var topSpendingTableView: UITableView!
    
    // MARK: - Properties
    var smartInsights: String = ""  // To receive smart insights from ViewController
    var topSpending: [(title: String, amount: Double)] = []  // To hold top 5 expensive items

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the smart insights label
        smartInsightsLabel.text = smartInsights

        // Set up table view for top spending
        topSpendingTableView.delegate = self
        topSpendingTableView.dataSource = self

        // Fetch top spending data from Core Data
        fetchTopSpendingData()

        // Reload the table view to display top spending
        topSpendingTableView.reloadData()
    }

    // MARK: - Fetch Top Spending Data from Core Data
    private func fetchTopSpendingData() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

        // Fetch all Expense entities
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Expense")
        
        do {
            let expenses = try context.fetch(fetchRequest)
            
            // Sort expenses by amount (descending)
            let sortedExpenses = expenses.sorted {
                let amount1 = $0.value(forKey: "amount") as? Double ?? 0.0
                let amount2 = $1.value(forKey: "amount") as? Double ?? 0.0
                return amount1 > amount2
            }
            
            // Get the top 5 spending items
            var topSpendingItems: [(title: String, amount: Double)] = []
            
            for expense in sortedExpenses.prefix(5) {
                if let title = expense.value(forKey: "title") as? String,  // Accessing the correct attribute
                   let amount = expense.value(forKey: "amount") as? Double {
                    topSpendingItems.append((title: title, amount: amount))
                }
            }
            
            // Assign the top spending items to the property
            self.topSpending = topSpendingItems
            
        } catch {
            print("Failed to fetch expenses: \(error)")
        }
    }
}

// MARK: - UITableView DataSource and Delegate
extension TrendsViewController: UITableViewDataSource, UITableViewDelegate {
    
    // Number of rows in the table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topSpending.count
    }

    // Configure the cell for top spending
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpendingCell", for: indexPath)
        
        let spendingItem = topSpending[indexPath.row]
        cell.textLabel?.text = spendingItem.title  // Display the title
        
        return cell
    }
    
    // Row selection action (optional, depending on your design)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // You can add any action when a row is selected if needed
    }
}
