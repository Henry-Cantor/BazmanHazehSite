//
//  SceneDelegate.swift
//  BazemanLayout
//
//  Created by Charlie Aronson on 5/1/25.
//

import UIKit
import UserNotifications


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        
        // Ensure navigation bar is properly set up
        showTabBar()
        
        window?.makeKeyAndVisible()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }

    }

    // Show the Tab Bar for authenticated users
    func showTabBar() {
        let homeViewController = ViewController()
        let settingsController = SettingsViewController()
        let communityController = CommunityViewController()
        homeViewController.title = "Home"
        settingsController.title = "Settings"
        communityController.title = "Community"
        
        // Wrap in UINavigationController to ensure NavBar visibility
        let homeNavController = UINavigationController(rootViewController: homeViewController)
        let setNavController = UINavigationController(rootViewController: settingsController)
        let comNavController = UINavigationController(rootViewController: communityController)
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [comNavController, homeNavController, setNavController]
        tabBarController.selectedIndex = 1
        
        // Set tab bar items
        homeNavController.tabBarItem = UITabBarItem(title: "Home",  image: UIImage(systemName: "house"), tag: 0)
        setNavController.tabBarItem = UITabBarItem(title: "Settings / Alarms", image: UIImage(systemName: "gear"), tag: 0)
        comNavController.tabBarItem = UITabBarItem(title: "Community", image: UIImage(systemName: "person.3.fill"), tag:  0)
        

        // Customize Tab Bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.backgroundColor =  UIColor.blue
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        tabBarController.tabBar.standardAppearance = tabAppearance
        tabBarController.tabBar.scrollEdgeAppearance = tabAppearance

        // Set as root view controller
        window?.rootViewController = tabBarController
    }
    
}
