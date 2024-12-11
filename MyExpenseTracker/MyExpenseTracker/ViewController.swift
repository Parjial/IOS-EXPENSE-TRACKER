import UIKit
import CoreData

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    // MARK: - Outlets
    @IBOutlet weak var totalSavingLabel: UILabel!
    @IBOutlet weak var totalSpendingLabel: UILabel!
    @IBOutlet weak var currencyButton: UIButton!
    @IBOutlet weak var exchangeRateLabel: UILabel!

    // MARK: - Properties
    var expenses: [NSManagedObject] = []
    var incomes: [NSManagedObject] = []
    var pickerView = UIPickerView()
    var currencies: [(name: String, code: String, flagURL: String)] = [] // Store currency name, code, and flag
    var selectedCurrency = "USD"

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initial setup
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.isHidden = true
        view.addSubview(pickerView)

        // Layout pickerView
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pickerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 200)
        ])

        // Fetch expenses/incomes data
        fetchData()
        updateTotalValues()  // Update the total spending and savings
    }

    // MARK: - Fetch Countries and Currencies
    private func fetchCountriesAndCurrencies() {
        let urlString = "https://restcountries.com/v3.1/all"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching countries: \(error)")
                return
            }

            guard let data = data else { return }

            do {
                let countries = try JSONDecoder().decode([Country].self, from: data)
                self.currencies = countries.compactMap { country in
                    // Safely extract the currency code
                    guard let currencyCode = country.currencies?.keys.first else { return nil }

                    // Directly access currencyName and flagURL without using if let
                    if let currency = country.currencies?[currencyCode] {
                        let currencyName = currency.name  // currency.name is non-optional
                        let flagURL = country.flags.png   // country.flags.png is non-optional
                        return (name: currencyName, code: currencyCode, flagURL: flagURL)
                    } else {
                        return nil
                    }
                }

                // Debugging: Check if currencies array is populated
                print("Currencies fetched: \(self.currencies)")

                // Reload picker view only after currencies are populated
                DispatchQueue.main.async {
                    self.pickerView.reloadAllComponents()
                }

            } catch {
                print("Error decoding countries data: \(error)")
            }
        }.resume()
    }

    // MARK: - Actions
    @IBAction func selectCurrency(_ sender: UIButton) {
        // Toggle the visibility of the picker
        pickerView.isHidden = !pickerView.isHidden

        // Automatically fetch countries and currencies if picker is shown
        if !pickerView.isHidden {
            fetchCountriesAndCurrencies()  // Ensure data is fetched
        }
    }

    // MARK: - Picker View Data Source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // Ensure the currencies array is not empty before returning the number of rows
        return currencies.isEmpty ? 0 : currencies.count
    }

    // MARK: - Picker View Delegate
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        // Check that row is within bounds of the currencies array
        guard row < currencies.count else { return UIView() }

        let customView = UIView(frame: CGRect(x: 0, y: 0, width: pickerView.frame.width, height: 50))

        // Add flag image
        let flagImageView = UIImageView(frame: CGRect(x: 10, y: 5, width: 40, height: 40))
        if let flagURL = URL(string: currencies[row].flagURL) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: flagURL) {
                    DispatchQueue.main.async {
                        flagImageView.image = UIImage(data: data)
                    }
                }
            }
        }
        flagImageView.contentMode = .scaleAspectFit
        customView.addSubview(flagImageView)

        // Add currency name and code
        let label = UILabel(frame: CGRect(x: 60, y: 0, width: pickerView.frame.width - 70, height: 50))
        let currency = currencies[row]
        label.text = "\(currency.name) (\(currency.code))"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .left
        customView.addSubview(label)

        return customView
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCurrency = currencies[row].code
        currencyButton.setTitle("Currency: \(selectedCurrency)", for: .normal)
        pickerView.isHidden = true
        fetchExchangeRate(for: selectedCurrency)
    }

    // MARK: - Fetch Exchange Rate
    private func fetchExchangeRate(for currency: String) {
        let urlString = "https://api.exchangerate-api.com/v4/latest/CAD"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching exchange rate: \(error)")
                return
            }

            guard let data = data else { return }

            do {
                let exchangeData = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
                if let rate = exchangeData.rates[currency] {
                    DispatchQueue.main.async {
                        self.exchangeRateLabel.text = "1 CAD = \(rate) \(currency)"
                    }
                }
            } catch {
                print("Error decoding exchange rate data: \(error)")
            }
        }.resume()
    }

    // MARK: - Fetch Data from Core Data
    private func fetchData() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let expenseFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Expense")
        let incomeFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Income")
        
        do {
            expenses = try context.fetch(expenseFetchRequest)
            incomes = try context.fetch(incomeFetchRequest)
        } catch {
            print("Failed to fetch data: \(error)")
        }
    }

    // MARK: - Update Total Values
    private func updateTotalValues() {
        let totalSpending = calculateTotalSpending()
        let totalSaving = calculateTotalSaving()

        totalSpendingLabel.text = "\(totalSpending)"
        totalSavingLabel.text = "\(totalSaving)"
    }

    // MARK: - Calculate Total Spending
    private func calculateTotalSpending() -> Double {
        return expenses.reduce(0.0) { $0 + ($1.value(forKey: "amount") as? Double ?? 0.0) }
    }

    // MARK: - Calculate Total Saving
    private func calculateTotalSaving() -> Double {
        let totalIncome = incomes.reduce(0.0) { $0 + ($1.value(forKey: "amount") as? Double ?? 0.0) }
        let totalSpending = calculateTotalSpending()
        return totalIncome - totalSpending
    }

    // MARK: - Country and Currency Models
    struct Country: Codable {
        let currencies: [String: Currency]?
        let flags: Flags
    }

    struct Currency: Codable {
        let name: String
    }

    struct Flags: Codable {
        let png: String
    }

    // MARK: - Exchange Rate Model
    struct ExchangeRateResponse: Codable {
        let rates: [String: Double]
    }

    // MARK: - Prepare for Segue to Trends View
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTrends",
           let trendsVC = segue.destination as? TrendsViewController {
            
            // Fetch the top 5 spending categories
            let topSpending = calculateTopSpending()
            let totalSpending = calculateTotalSpending()

            // Create a formatted string for the top spending items
            let topSpendingText = topSpending.map {
                "\($0.name): $\(String(format: "%.2f", $0.amount))"
            }.joined(separator: "\n") // Use newline for better separation
            
            // Generate the smart insights with personalized feedback
            let spendingFeedback = generateSpendingFeedback(totalSpending)

            let smartInsights = """
            Top 5 Expensive Items
            \(topSpendingText)
            
            Total Spending: $\(String(format: "%.2f", totalSpending))

            Feedback
            \(spendingFeedback)
            """
            
            // Pass the formatted insights to TrendsViewController
            trendsVC.smartInsights = smartInsights
        }
    }

    // MARK: - Generate Personalized Spending Feedback
    private func generateSpendingFeedback(_ totalSpending: Double) -> String {
        if totalSpending > 1000 {
            return "⚠️ Warning: Your spending is high this month. Consider reducing unnecessary expenses."
        } else if totalSpending > 500 {
            return "⚠️ Caution: Your spending is moderate. Be mindful of your budget."
        } else {
            return "👍 Good job! You're keeping your spending in check."
        }
    }



    // MARK: - Calculate Top Spending
    private func calculateTopSpending() -> [(name: String, amount: Double)] {
        let sortedExpenses = expenses.sorted {
            let amount1 = $0.value(forKey: "amount") as? Double ?? 0.0
            let amount2 = $1.value(forKey: "amount") as? Double ?? 0.0
            return amount1 > amount2
        }
        
        return sortedExpenses.prefix(5).compactMap { expense in
            if let title = expense.value(forKey: "title") as? String,  // Use "title" instead of "name"
               let amount = expense.value(forKey: "amount") as? Double {
                return (name: title, amount: amount)  // Return title and amount
            }
            return nil
        }
    }

}
