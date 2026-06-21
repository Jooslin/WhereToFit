//
//  AppDelegate.swift
//  WhereToFit
//
//  Created by 변예린 on 5/19/26.
//

import UIKit
import CoreData
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let coreDataStack = CoreDataStack.shared
    private let programReminderScheduler = ProgramReminderScheduler.shared // 프로그램 알림 예약 담당
    private let registeredProgramReminderRepository = CoreDataRegisteredProgramRepository() // 사용자가 등록한 프로그램 저장소
    private let notificationHistoryStore = NotificationHistoryStore.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        rescheduleRegisteredProgramStartReminders()
        return true
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

    var persistentContainer: NSPersistentCloudKitContainer {
        coreDataStack.persistentContainer
    }

    // MARK: - Core Data Saving support

    func saveContext() {
        coreDataStack.saveContext()
    }

}

private extension AppDelegate {
    // 알림 재예약 함수
    func rescheduleRegisteredProgramStartReminders() {
        programReminderScheduler.rescheduleStartReminders(
            using: registeredProgramReminderRepository
        ) { _ in }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        notificationHistoryStore.save(notification: notification)
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        notificationHistoryStore.save(notification: response.notification)
        NotificationNavigationStepper.shared.routeToRegisteredProgramsIfProgramNotification(response.notification)
        completionHandler()
    }
}
