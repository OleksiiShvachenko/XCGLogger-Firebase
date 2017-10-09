//
//  FirebaseDestination.swift
//  XCGLogger+Firebase
//
//  Created by Oleksii Shvachenko on 9/27/17.
//  Copyright © 2017 oleksii. All rights reserved.
//

import Foundation
import XCGLogger
import FirebaseCommunity
import CryptoSwift

struct LogDecorator {
  let log: LogDetails
  let deviceOS: String
  let deviceName: String
  let deviceID: String
  private let formatter = ISO8601DateFormatter()
  init(log: LogDetails) {
    self.log = log
    let device = UIDevice.current
    deviceID = device.identifierForVendor!.uuidString
    deviceName = device.modelName
    deviceOS = "\(device.systemName) \(device.systemVersion)"
  }

  var json: [String: Any] {
    let tagsKey = XCGLogger.Constants.userInfoKeyTags
    let result: [String]
    if let tags = log.userInfo[tagsKey] as? [String] {
      result = tags
    } else if let tags = log.userInfo[tagsKey] as? String {
      result = [tags]
    } else {
      result = []
    }


    return [
      "level": log.level.description,
      "date": formatter.string(from: log.date),
      "message": log.message,
      "functionName": log.functionName,
      "fileName": log.fileName,
      "lineNumber": log.lineNumber,
      "deviceID": deviceID,
      "deviceName": deviceName,
      "deviceOS": deviceOS,
      "tags": result
    ]
  }
}

public extension UIDevice {

  var modelName: String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }

    switch identifier {
    case "iPod5,1":                                 return "iPod Touch 5"
    case "iPod7,1":                                 return "iPod Touch 6"
    case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
    case "iPhone4,1":                               return "iPhone 4s"
    case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
    case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
    case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
    case "iPhone7,2":                               return "iPhone 6"
    case "iPhone7,1":                               return "iPhone 6 Plus"
    case "iPhone8,1":                               return "iPhone 6s"
    case "iPhone8,2":                               return "iPhone 6s Plus"
    case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
    case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
    case "iPhone8,4":                               return "iPhone SE"
    case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
    case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
    case "iPhone10,3", "iPhone10,6":                return "iPhone X"
    case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
    case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
    case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
    case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
    case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
    case "iPad6,11", "iPad6,12":                    return "iPad 5"
    case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
    case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
    case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
    case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
    case "iPad6,3", "iPad6,4":                      return "iPad Pro 9.7 Inch"
    case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9 Inch"
    case "iPad7,1", "iPad7,2":                      return "iPad Pro 12.9 Inch 2. Generation"
    case "iPad7,3", "iPad7,4":                      return "iPad Pro 10.5 Inch"
    case "AppleTV5,3":                              return "Apple TV"
    case "AppleTV6,2":                              return "Apple TV 4K"
    case "AudioAccessory1,1":                       return "HomePod"
    case "i386", "x86_64":                          return "Simulator"
    default:                                        return identifier
    }
  }

}

private protocol DataSaver {
  func save(logDetails: LogDecorator, message: String)
}

private class EncryptedFirebaseDataSaver: DataSaver {
  private let firebaseRef: DatabaseReference
  private let aesEncoder: AES
  init(firebaseRef: DatabaseReference, aesEncoder: AES) {
    self.firebaseRef = firebaseRef
    self.aesEncoder = aesEncoder
  }

  func save(logDetails: LogDecorator, message: String) {
    let data = try! JSONSerialization.data(withJSONObject: logDetails.json, options: JSONSerialization.WritingOptions(rawValue: 0))
    let raw = try! aesEncoder.encrypt(data.bytes)
    let encryptedData = Data(bytes: raw)

    firebaseRef.child(message.md5()).setValue(encryptedData.toHexString())
  }
}


public class FirebaseDestination: BaseDestination {
  public struct EncryptionParams {
    let key: String
    let iv: String
    init(key: String, iv: String) {
      precondition(key.count == iv.count, "Key and iv should have the same length of 16 characters")
      self.key = key
      self.iv = iv
    }
  }
  private let dataSaver: DataSaver
  /**
   Designated initialization

   - Parameter encryptionKey: key to use in AES 128 encryption.
   - Parameter firebaseSettingsPath: path to plist generated by goole, Bundle.main.path(forResource: "FirebaseSetting", ofType: "plist").
   */
  public init?(firebaseSettingsPath: String, encryptionParams: EncryptionParams) {
    guard let options = FirebaseOptions(contentsOfFile: firebaseSettingsPath) else {
      return nil
    }
    guard let aesEncoder = try? AES(key: encryptionParams.key, iv: encryptionParams.iv) else {
      return nil
    }
    FirebaseApp.configure(name: "FirebaseLogs", options: options)
    let app = FirebaseApp.app(name: "FirebaseLogs")!
    let database = Database.database(app: app)
    database.isPersistenceEnabled = true
    let firebaseRef = Database.database(app: app).reference().child("Logs")
    dataSaver = EncryptedFirebaseDataSaver(firebaseRef: firebaseRef, aesEncoder: aesEncoder)
  }
  
  public override func output(logDetails: LogDetails, message: String) {
    var logDetails = logDetails
    var message = message
    // Apply filters, if any indicate we should drop the message, we abort before doing the actual logging
    guard !self.shouldExclude(logDetails: &logDetails, message: &message) else { return }

    self.applyFormatters(logDetails: &logDetails, message: &message)
    //store log detail
    let logDecorator = LogDecorator(log: logDetails)
    dataSaver.save(logDetails: logDecorator, message: message)
  }
}
