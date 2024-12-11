//
//  AppDelegate.swift
//  MyExpenseTracker
//
//  Created by Parth Karki on 2024-11-25.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Singleton instance to access Core Data stack
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Handle discarded sessions
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MyExpenseTracker") // Ensure this matches your .xcdatamodeld file name
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    // MARK: - Core Data Context Access

    /// Returns the main context for use throughout the app
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Core Data Saving Support

    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - Core Data Utility Methods

    /// Deletes all data in the persistent store (use with caution!)
    func resetCoreData() {
        let persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
        for store in persistentStoreCoordinator.persistentStores {
            do {
                try persistentStoreCoordinator.destroyPersistentStore(at: store.url!, ofType: store.type, options: nil)
                try persistentStoreCoordinator.addPersistentStore(ofType: store.type, configurationName: nil, at: store.url, options: nil)
            } catch {
                fatalError("Failed to reset Core Data: \(error.localizedDescription)")
            }
        }
    }
}
