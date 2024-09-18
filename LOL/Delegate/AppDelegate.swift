//
//  AppDelegate.swift
//  LOL
//
//  Created by Arpit iOS Dev. on 31/07/24.
//

import UIKit
import CoreData
import FirebaseCore
import UserNotifications
import FBSDKCoreKit
import OneSignalFramework

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        registerForPushNotifications()
        FirebaseApp.configure()
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        OneSignal.initialize("bd3921d2-a2f7-44fb-862f-8ab87e37f09e", withLaunchOptions: launchOptions)
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
        }, fallbackToSettings: true)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return ApplicationDelegate.shared.application(app, open: url, options: options)
    }
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Permission granted: \(granted)")
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        UserDefaults.standard.set(token, forKey: "deviceToken")
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "LOL")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Update Check
    
    func fetchAppStoreVersion(completion: @escaping (String?) -> Void) {
        let appID = "your-app-id" // Replace with your app's App Store ID
        let urlString = "https://itunes.apple.com/lookup?id=\(appID)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let appStoreVersion = results.first?["version"] as? String {
                    completion(appStoreVersion)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func getCurrentAppVersion() -> String? {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return nil
    }
    
    func checkForUpdate() {
        fetchAppStoreVersion { appStoreVersion in
            guard let appStoreVersion = appStoreVersion,
                  let currentVersion = self.getCurrentAppVersion() else {
                return
            }
            
            if appStoreVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                DispatchQueue.main.async {
                    self.promptUserToUpdate()
                }
            }
        }
    }
    
    func promptUserToUpdate() {
        let alert = UIAlertController(
            title: "Update Available",
            message: "A newer version of the app is available. Please update to the latest version.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { _ in
            self.openAppStoreForUpdate()
        }))
        
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: nil))
        
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            topController.present(alert, animated: true, completion: nil)
        }
    }
    
    func openAppStoreForUpdate() {
        let appID = "your-app-id" // Replace with your app's App Store ID
        if let url = URL(string: "https://apps.apple.com/app/id\(appID)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    // Call checkForUpdate when the app becomes active
    func applicationDidBecomeActive(_ application: UIApplication) {
        checkForUpdate()
    }
}
