//
//  AppDelegate.swift
//  BazemanLayout
//
//  Created by Charlie Aronson on 5/1/25.
//

import UIKit
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        print("🚀 App launched")

        // Register background refresh task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.BazemanHazeh.001", using: nil) { task in
            self.handleZmanimRefresh(task: task as! BGAppRefreshTask)
        }

        // Schedule the first refresh
        scheduleDailyZmanimRefresh()

        // Run today's alarms now
        callScheduleAlarmsForVisibleZmanim()

        // Enable background fetch fallback
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

        return true
    }

    // Background Fetch fallback (old API)
    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Background fetch triggered")
        callScheduleAlarmsForVisibleZmanim()
        completionHandler(.newData)
    }

    // BGTaskScheduler handler
    func handleZmanimRefresh(task: BGAppRefreshTask) {
        print("🔄 Background zmanim refresh triggered")

        scheduleDailyZmanimRefresh() // schedule for next day

        callScheduleAlarmsForVisibleZmanim()

        task.setTaskCompleted(success: true)
    }

    // Schedule BGTask for next day at midnight
    func scheduleDailyZmanimRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.BazemanHazeh.001")
        request.earliestBeginDate = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400)) // midnight next day

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📆 Scheduled background Zmanim refresh for tomorrow")
        } catch {
            print("❌ Failed to schedule BGTask: \(error)")
        }
    }

    // Helper to find and call scheduleAlarmsForVisibleZmanim in your ViewController inside UITabBarController
    private func callScheduleAlarmsForVisibleZmanim() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController,
              let viewControllers = tabBarController.viewControllers else {
            print("⚠️ Could not find UITabBarController or its tabs")
            return
        }

        for vc in viewControllers {
            if let nav = vc as? UINavigationController {
                if let viewController = nav.viewControllers.first(where: { $0 is ViewController }) as? ViewController {
                    viewController.scheduleAlarmsForVisibleZmanim()
                    print("Called scheduleAlarmsForVisibleZmanim in nav tab")
                    return
                }
            } else if let viewController = vc as? ViewController {
                viewController.scheduleAlarmsForVisibleZmanim()
                print("Called scheduleAlarmsForVisibleZmanim directly in tab")
                return
            }
        }

        print("⚠️ Could not find ViewController in any tab")
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
}

