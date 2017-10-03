//
//  DevicesViewController.swift
//  LogViewer
//
//  Created by Oleksii Shvachenko on 10/3/17.
//  Copyright © 2017 oleksii. All rights reserved.
//

import Cocoa

class DeviceCellView: NSTableCellView {
  @IBOutlet weak var idLabel: NSTextField!
  @IBOutlet weak var descriptionLabel: NSTextField!
}

protocol DevicesViewControllerDelegate: class {
  func didSelect(device: DeviceData)
}

class DevicesViewController: NSViewController {
  @IBOutlet weak var tableView: NSTableView!
  weak var delegate: DevicesViewControllerDelegate?

  var devices: [DeviceData] = [] {
    didSet {
      tableView.reloadData()
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.usesAutomaticRowHeights = true
  }

  @IBAction func rowSelected(_ sender: NSTableView) {
    guard sender.selectedRow >= 0 else {
      return
    }
    let selectedDevice = devices[sender.selectedRow]
    delegate?.didSelect(device: selectedDevice)
  }
}

extension DevicesViewController: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return devices.count
  }
  
  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DeviceInfoCell"), owner: nil) as! DeviceCellView
    let device = devices[row]
    cell.idLabel.stringValue = device.deviceID
    cell.descriptionLabel.stringValue = "\(device.deviceName) \(device.deviceOS)"
    return cell
  }
}
