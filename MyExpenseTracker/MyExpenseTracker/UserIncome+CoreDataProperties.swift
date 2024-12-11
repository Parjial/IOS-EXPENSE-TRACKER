//
//  UserIncome+CoreDataProperties.swift
//  MyExpenseTracker
//
//  Created by Parth Karki on 2024-11-25.
//
//

import Foundation
import CoreData


extension UserIncome {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserIncome> {
        return NSFetchRequest<UserIncome>(entityName: "UserIncome")
    }

    @NSManaged public var title: String?
    @NSManaged public var amount: Double
    @NSManaged public var date: Date?

}

extension UserIncome : Identifiable {

}
