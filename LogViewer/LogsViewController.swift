//
//  ViewController.swift
//  LogViewer
//
//  Created by Oleksii Shvachenko on 9/29/17.
//  Copyright © 2017 oleksii. All rights reserved.
//

import Cocoa

enum SelectedFilter: Int {
  case all
  case error
  case debug
  case severe
  case info
}

class LogCellView: NSTableCellView {
  @IBOutlet weak var fileLabel: NSTextField!
  @IBOutlet weak var lineLabel: NSTextField!
  @IBOutlet weak var functionLabel: NSTextField!
  @IBOutlet weak var messageLabel: NSTextField!
  @IBOutlet weak var logLabel: NSTextField!
  @IBOutlet weak var dateLabel: NSTextField!
  @IBOutlet weak var severeView: NSBox!
}

class LogsViewController: NSViewController {
  @IBOutlet weak var tagsEnabledButton: NSButton!
  @IBOutlet weak var tagsButton: NSPopUpButton!
  @IBOutlet weak var tableView: NSTableView!
  var filterText: String? = nil {
    didSet {
      tableView.reloadData()
    }
  }

  var allLogs: [LogData] = [] {
    didSet {
      var tags = Set<String>()
      for log in allLogs {
        tags = tags.union(Set<String>(log.tags))
      }
      tagsButton.addItems(withTitles: tags.map{$0})
      tableView.reloadData()
    }
  }
  let dateFormatter = DateComponentsFormatter()
  var seletedFilter = SelectedFilter.all
  var seletedTag: String? = nil {
    didSet {
      if oldValue != seletedTag {
        tableView.reloadData()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.usesAutomaticRowHeights = true

    dateFormatter.unitsStyle = .abbreviated
    dateFormatter.maximumUnitCount = 2
  }

  @IBAction func didSelelectValue(_ sender: NSPopUpButton) {
    let selectedIndex = sender.indexOfSelectedItem
    seletedFilter = SelectedFilter(rawValue: selectedIndex)!
    tableView.reloadData()
  }

  @IBAction func didSelelectTag(_ sender: NSPopUpButton) {
    if tagsEnabledButton.state == .on {
     self.seletedTag = tagsButton.selectedItem?.title
    }
  }

  @IBAction func didTogleTag(_ sender: NSButton) {
    if tagsEnabledButton.state == .on {
      self.seletedTag = tagsButton.selectedItem?.title
    } else {
      self.seletedTag = nil
    }
  }

  func logsAccordingToSelectedFilter() -> [LogData] {
    let textFilter = { [unowned self] (isIncluded: LogData) -> Bool in
      let text = self.filterText ?? ""
      guard text.count > 0 else {
        return true
      }
      var isTagsContainSearchPatter = false
      for tag in isIncluded.tags {
        if tag.contains(text) {
          isTagsContainSearchPatter = true
          break
        }
      }
      return isIncluded.fileName.contains(text)
        || isIncluded.functionName.contains(text)
        || isIncluded.message.contains(text)
        || isTagsContainSearchPatter
    }

    let tagFilter = { [unowned self] (isIncluded: LogData) -> Bool in
      guard let seletedTag = self.seletedTag else {
        return true
      }

      for tag in isIncluded.tags {
        if tag == seletedTag {
          return true
        }
      }
      return false
    }

    switch seletedFilter {
    case .all:
      return allLogs.filter(tagFilter).filter(textFilter)
    case .debug:
      return allLogs.filter { $0.level == .debug }.filter(tagFilter).filter(textFilter)
    case .error:
      return allLogs.filter { $0.level == .error }.filter(tagFilter).filter(textFilter)
    case .info:
      return allLogs.filter { $0.level == .info }.filter(tagFilter).filter(textFilter)
    case .severe:
      return allLogs.filter { $0.level == .severe }.filter(tagFilter).filter(textFilter)
    }
  }

}

extension LogsViewController: NSTextFieldDelegate {
  override func controlTextDidChange(_ obj: Notification) {
    let textField = obj.object as! NSTextField
    filterText = textField.stringValue
  }
}

extension LogsViewController: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int {
    return logsAccordingToSelectedFilter().count
  }

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LogInfoCell"), owner: nil) as! LogCellView
    let logData = logsAccordingToSelectedFilter()[row]
    cell.fileLabel.stringValue = logData.fileName
    cell.lineLabel.stringValue = "line \(logData.lineNumber)"
    cell.functionLabel.stringValue = logData.functionName
    cell.messageLabel.stringValue = "Message: \(logData.message)"
    cell.dateLabel.stringValue = dateFormatter.string(from: logData.date, to: Date())!
    if logData.tags.count > 0 {
      cell.logLabel.isHidden = false
      cell.logLabel.stringValue = "Tags: \(logData.tags.joined(separator: ", "))"
    } else {
      cell.logLabel.isHidden = true
    }
    switch logData.level {
    case .debug:
      cell.severeView.fillColor = NSColor.brown
    case .error:
      cell.severeView.fillColor = NSColor.red
    case .info:
      cell.severeView.fillColor = NSColor.blue
    case .severe:
      cell.severeView.fillColor = NSColor.orange
    }
    return cell
  }
}

