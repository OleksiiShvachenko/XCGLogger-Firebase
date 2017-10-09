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

extension Tag {
  static let sensitive = Tag("sensitive")
  static let ui = Tag("ui")
  static let data = Tag("data")
}

extension Dev {
  static let dave = Dev("dave")
  static let sabby = Dev("sabby")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    let settingsPath = Bundle.main.path(forResource: "FirebaseSetting", ofType: "plist")!
    let encryptionParams = FirebaseDestination.EncryptionParams(key: "w6xXnb4FwvQEeF1R", iv: "0123456789012345")
    let destination = FirebaseDestination(firebaseSettingsPath: settingsPath, encryptionParams: encryptionParams)!
    log.add(destination: destination)
    log.debug(["Device": "iPhone", "Version": 7])
    log.error("omg!")
    log.severe("omg_2!")
    log.info("omg_3!")
    let tags = XCGLogger.Constants.userInfoKeyTags
    log.error("some error with tag", userInfo: [tags: "iPhone X"])
    log.debug("some error with tag", userInfo: [tags: ["iPhone X", "iPhone 8"]])
    log.debug("A tagged log message", userInfo: Dev.dave | Tag.sensitive)
    return true
  }

}
