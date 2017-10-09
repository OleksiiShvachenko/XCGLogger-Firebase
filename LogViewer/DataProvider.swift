//
//  LogsProvider.swift
//  LogViewer
//
//  Created by Oleksii Shvachenko on 10/3/17.
//  Copyright © 2017 oleksii. All rights reserved.
//

import Foundation
import FirebaseCommunity
import CryptoSwift

struct DeviceData {
  let deviceOS: String
  let deviceName: String
  let deviceID: String
}

extension DeviceData: Hashable {
  static func ==(lhs: DeviceData, rhs: DeviceData) -> Bool {
    return lhs.deviceID == rhs.deviceID
  }

  var hashValue: Int {
    return deviceID.hashValue
  }
}

struct LogData {
  enum SeverityLevel: String {
    case error
    case debug
    case severe
    case info
  }

  let level: SeverityLevel
  let message: String
  let lineNumber: Int
  let fileName: String
  let functionName: String
  let date: Date
  let tags: [String]
}

struct ServerData {
  let deviceData: DeviceData
  let logData: LogData

  init(json: [String: Any]) {
    let level: String = json["level"] as! String
    let message: String = json["message"] as! String
    let lineNumber: Int = json["lineNumber"] as! Int
    let functionName = json["functionName"] as! String
    let date = ISO8601DateFormatter().date(from: json["date"] as! String)!
    let fileName = URL(fileURLWithPath: json["fileName"] as! String).lastPathComponent
    let deviceOS = json["deviceOS"] as! String
    let deviceName = json["deviceName"] as! String
    let deviceID = json["deviceID"] as! String
    let tags = json["tags"] as! [String]
    self.deviceData = DeviceData(
      deviceOS: deviceOS,
      deviceName: deviceName,
      deviceID: deviceID)

    self.logData = LogData(
      level: LogData.SeverityLevel(rawValue: level.lowercased())!,
      message: message,
      lineNumber: lineNumber,
      fileName: fileName,
      functionName: functionName,
      date: date,
      tags: tags)
  }

  private let formatter = DateFormatter()
}

protocol DataFetcher {
  func subscribeForUpdates(updateCallback: @escaping ([ServerData]) -> ())
}

class FirebaseDataProvider: DataFetcher {
  private let firebaseRef: DatabaseReference
  private let aes: AES
  private var updateCallback: (([ServerData]) -> ())!
  private var updateHandler: UInt? = nil

  init() {
    let options = FirebaseOptions(contentsOfFile: Bundle.main.path(forResource: "FirebaseSetting", ofType: "plist")!)!
    FirebaseApp.configure(name: "FirebaseLogs", options: options)
    let app = FirebaseApp.app(name: "FirebaseLogs")!
    firebaseRef = Database.database(app: app).reference().child("Logs")
    aes = try! AES(key: "w6xXnb4FwvQEeF1R", iv: "0123456789012345")
  }
  func subscribeForUpdates(updateCallback: @escaping ([ServerData]) -> ()) {
    self.updateCallback = updateCallback
    updateHandler = firebaseRef.observe(DataEventType.value) { [unowned self] (snapshot) in
      var allLogs: [ServerData] = []
      let logs = snapshot.value! as! [String: String]
      for (_, log) in logs {
        let data = Array<UInt8>(hex: log)
        let decryptData = Data(bytes: try! self.aes.decrypt(data))
        let json = try! JSONSerialization.jsonObject(with: decryptData, options: .mutableContainers) as! [String: Any]
        let logData = ServerData(json: json)
        allLogs.append(logData)
      }
      self.updateCallback(allLogs)
    }
  }

  deinit {
    if let updateHandler = self.updateHandler {
      firebaseRef.removeObserver(withHandle: updateHandler)
    }
  }
}
