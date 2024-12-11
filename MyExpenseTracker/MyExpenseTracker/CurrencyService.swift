//
//  CurrencyService.swift
//  MyExpenseTracker
//
//  Created by Parth Karki on 2024-12-10.
//

import Foundation

class CurrencyService {
    static let shared = CurrencyService()
    private let baseURL = "https://v6.exchangerate-api.com/v6/1378daa94c23ca21de6010b9/latest/USD" //API endpoint
    
    func fetchExchangeRates(completion: @escaping (Result<[String: Double], Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let rates = json["rates"] as? [String: Double] {
                    completion(.success(rates))
                } else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
