//
//  SplitViewController.swift
//  LogViewer
//
//  Created by Oleksii Shvachenko on 10/3/17.
//  Copyright © 2017 oleksii. All rights reserved.
//

import Cocoa

class SplitViewController: NSSplitViewController {
  let dataFetcher: DataFetcher = FirebaseDataProvider()
  var fetchedData: [DeviceData: [LogData]] = [:]
  var logsController: LogsViewController!
  override func viewDidLoad() {
    super.viewDidLoad()

    let deviceController = splitViewItems.first!.viewController as! DevicesViewController
    deviceController.delegate = self
    logsController = splitViewItems.last!.viewController as! LogsViewController

    self.dataFetcher.subscribeForUpdates { [unowned self] (logs) in
      let devices = logs.map { $0.deviceData }.reduce([DeviceData]()) { result, data in
        if !result.contains(data) {
          return result + [data]
        }
        return result
      }
      self.fetchedData = logs.reduce([DeviceData: [LogData]]()) { result, data in
        var currentResult = result
        if currentResult[data.deviceData] != nil {
          currentResult[data.deviceData]!.append(data.logData)
        } else {
          currentResult[data.deviceData] = [data.logData]
        }
        return currentResult
      }
      for key in self.fetchedData.keys {
        self.fetchedData[key]!.sort {
          $0.date > $1.date
        }
      }
      deviceController.devices = devices
    }
  }
}

extension SplitViewController: DevicesViewControllerDelegate {
  func didSelect(device: DeviceData) {
    logsController.allLogs = fetchedData[device]!
  }
}
