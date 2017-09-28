//
//  AppDelegate.swift
//  XCGLogger+Firebase
//
//  Created by Oleksii Shvachenko on 9/27/17.
//  Copyright © 2017 oleksii. All rights reserved.
//

import UIKit
import XCGLogger

let log = XCGLogger.default

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    let settingsPath = Bundle.main.path(forResource: "FirebaseSetting", ofType: "plist")!
    let destination = FirebaseDestination(encryptionKey: "w6xXnb4FwvQEeF1R", firebaseSettingsPath: settingsPath)!
    log.add(destination: destination)
    log.debug(["Device": "iPhone", "Version": 7])
    log.error("omg!")
    log.severe("omg_2!")
    log.info("omg_3!")
    return true
  }

}
