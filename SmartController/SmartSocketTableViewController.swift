//
//  SmartSocketTableViewController.swift
//  SmartController
//
//  Created by 李哲翰 on 2021/5/21.
//

import UIKit
import CoreBluetooth

class SmartSocketTableViewController: UITableViewController {
    
    @IBOutlet weak var numberOfSocketsLabel: UILabel!
    @IBOutlet weak var timedOnLabel: UILabel!
    @IBOutlet weak var timedOnSwitch: UISwitch!
    @IBOutlet weak var timedOnDatePicker: UIDatePicker!
    @IBOutlet weak var timedOffLabel: UILabel!
    @IBOutlet weak var timedOffSwitch: UISwitch!
    @IBOutlet weak var timedOffDatePicker: UIDatePicker!
    @IBOutlet weak var onTimeLabel: UILabel!
    @IBOutlet weak var onTimePickerView: UIPickerView! {
        didSet {
            onTimePickerView.delegate = self
        }
    }
    @IBOutlet weak var offTimeLabel: UILabel!
    @IBOutlet weak var offTimePickerView: UIPickerView! {
        didSet {
            offTimePickerView.delegate = self
        }
    }
    @IBOutlet weak var numberOfRepeatTimesLabel: UILabel!
    @IBOutlet weak var numberOfRepeatTimesStepper: UIStepper!
    @IBOutlet weak var commandLabel: UILabel!
    
    let timedOnDatePickerCellIndexPath = IndexPath(row: 1, section: 1)
    let turnOnLabelCellIndexPath = IndexPath(row: 2, section: 1)
    let timedOffDatePickerCellIndexPath = IndexPath(row: 1, section: 2)
    let turnOffLabelCellIndexPath = IndexPath(row: 2, section: 2)
    let onTimePickerViewCellIndexPath = IndexPath(row: 1, section: 3)
    let offTimePickerViewCellIndexPath = IndexPath(row: 3, section: 3)
    let beginExecutionLabelCellIndexPath = IndexPath(row: 5, section: 3)
    
    var isTimedOnDatePickerShown = false {
        didSet {
            timedOnDatePicker.isHidden = !isTimedOnDatePickerShown
        }
    }
    var isTimedOffDatePickerShown = false {
        didSet {
            timedOffDatePicker.isHidden = !isTimedOffDatePickerShown
        }
    }
    var isOnTimePickerViewShown = false {
        didSet {
            onTimePickerView.isHidden = !isOnTimePickerViewShown
        }
    }
    var isOffTimePickerViewShown = false {
        didSet {
            offTimePickerView.isHidden = !isOffTimePickerViewShown
        }
    }
    
    var peripheral: CBPeripheral? {
        didSet {
            peripheral?.delegate = self
            peripheral?.discoverServices(nil)
        }
    }
    var readCharacteristic: CBCharacteristic?
    var writeWithoutResponseCharacteristic: CBCharacteristic?
    var writeCharacteristic: CBCharacteristic?
    var notifyCharacteristic: CBCharacteristic?
    var indicateCharacteristic: CBCharacteristic?
    
    var numberOfSockets = 0
    var onHours = 0
    var onMinutes = 0
    var onSeconds = 0
    var offHours = 0
    var offMinutes = 0
    var offSeconds = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        updateNumberOfSocketsView()
        updateTimedOnView()
        updateTimedOffView()
        updateOnTimeView()
        updateOffTimeView()
        updateNumberOfRepeatTimesView()
    }
    
    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        if sender == timedOnDatePicker {
            updateTimedOnView()
        } else if sender == timedOffDatePicker {
            updateTimedOffView()
        }
    }
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        updateNumberOfRepeatTimesView()
    }
    
    @IBAction func unwindToSmartSocket(segue: UIStoryboardSegue) {
        guard segue.identifier == "unwindToSmartSocketSegue" else { return }
        let numberTableViewController = segue.source as! NumberTableViewController
        if let selectedIndex = numberTableViewController.selectedIndex {
            numberOfSockets = selectedIndex
            updateNumberOfSocketsView()
            writeNumberOfSockets()
        }
    }
    
    // MARK: - Update view
    
    func updateNumberOfSocketsView() {
        numberOfSocketsLabel.text = String(numberOfSockets)
    }
    
    func updateTimedOnView() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        timedOnLabel.text = dateFormatter.string(from: timedOnDatePicker.date)
    }
    
    func updateTimedOffView() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        timedOffLabel.text = dateFormatter.string(from: timedOffDatePicker.date)
    }
    
    func updateOnTimeView() {
        var onTimeText = ""
        if onSeconds > 0 {
            onTimeText = "\(onSeconds)秒"
        }
        if onMinutes > 0 {
            onTimeText = "\(onMinutes)分钟\(onTimeText)"
        }
        if onHours > 0 {
            onTimeText = "\(onHours)小时\(onTimeText)"
        }
        if onTimeText.isEmpty {
            onTimeText = "--"
        }
        onTimeLabel.text = onTimeText
    }
    
    func updateOffTimeView() {
        var offTimeText = ""
        if offSeconds > 0 {
            offTimeText = "\(offSeconds)秒"
        }
        if offMinutes > 0 {
            offTimeText = "\(offMinutes)分钟\(offTimeText)"
        }
        if offHours > 0 {
            offTimeText = "\(offHours)小时\(offTimeText)"
        }
        if offTimeText.isEmpty {
            offTimeText = "--"
        }
        offTimeLabel.text = offTimeText
    }
    
    func updateNumberOfRepeatTimesView() {
        numberOfRepeatTimesLabel.text = "\(Int(numberOfRepeatTimesStepper.value))"
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case timedOnDatePickerCellIndexPath:
            if isTimedOnDatePickerShown {
                return 216
            } else {
                return 0
            }
        case timedOffDatePickerCellIndexPath:
            if isTimedOffDatePickerShown {
                return 216
            } else {
                return 0
            }
        case onTimePickerViewCellIndexPath:
            if isOnTimePickerViewShown {
                return 216
            } else {
                return 0
            }
        case offTimePickerViewCellIndexPath:
            if isOffTimePickerViewShown {
                return 216
            } else {
                return 0
            }
        default:
            return 44
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath != IndexPath(row: 0, section: 0) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        switch indexPath {
        case IndexPath(row: timedOnDatePickerCellIndexPath.row - 1, section: timedOnDatePickerCellIndexPath.section):
            if isTimedOnDatePickerShown {
                isTimedOnDatePickerShown = false
            } else if isTimedOffDatePickerShown {
                isTimedOffDatePickerShown = false
                isTimedOnDatePickerShown = true
            } else {
                isTimedOnDatePickerShown = true
            }
            tableView.beginUpdates()
            tableView.endUpdates()
        case turnOnLabelCellIndexPath:
            writeTurnOn()
        case IndexPath(row: timedOffDatePickerCellIndexPath.row - 1, section: timedOffDatePickerCellIndexPath.section):
            if isTimedOffDatePickerShown {
                isTimedOffDatePickerShown = false
            } else if isTimedOnDatePickerShown {
                isTimedOnDatePickerShown = false
                isTimedOffDatePickerShown = true
            } else {
                isTimedOffDatePickerShown = true
            }
            tableView.beginUpdates()
            tableView.endUpdates()
        case turnOffLabelCellIndexPath:
            writeTurnOff()
        case IndexPath(row: onTimePickerViewCellIndexPath.row - 1, section: onTimePickerViewCellIndexPath.section):
            if isOnTimePickerViewShown {
                isOnTimePickerViewShown = false
            } else if isOffTimePickerViewShown {
                isOffTimePickerViewShown = false
                isOnTimePickerViewShown = true
            } else {
                isOnTimePickerViewShown = true
            }
            tableView.beginUpdates()
            tableView.endUpdates()
        case IndexPath(row: offTimePickerViewCellIndexPath.row - 1, section: offTimePickerViewCellIndexPath.section):
            if isOffTimePickerViewShown {
                isOffTimePickerViewShown = false
            } else if isOnTimePickerViewShown {
                isOnTimePickerViewShown = false
                isOffTimePickerViewShown = true
            } else {
                isOffTimePickerViewShown = true
            }
            tableView.beginUpdates()
            tableView.endUpdates()
        case beginExecutionLabelCellIndexPath:
            writeIntermittentExecution()
        default:
            break
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NumberSegue" {
            let numberTableViewController = segue.destination as! NumberTableViewController
            numberTableViewController.title = "路数"
            numberTableViewController.numbers = [0, 1, 2, 3, 4]
            numberTableViewController.selectedIndex = numberOfSockets
        }
    }
}

extension SmartSocketTableViewController {
    func writeCalibrationTime() {
        let dateComponents = Calendar.current.dateComponents([.day, .hour, .minute, .second, .weekday], from: Date())
        let day = dateComponents.day!
        let hour = dateComponents.hour!
        let minute = dateComponents.minute!
        let second = dateComponents.second!
        let weekday = dateComponents.weekday!
        let week = weekday == 1 ? 7 : weekday - 1
        let command = "clk\(day):\(week):\(hour):\(minute):\(second):"
        write(command)
    }
    
    func writeNumberOfSockets() {
        write("inf\(numberOfSockets)")
    }
    
    func writeTurnOn() {
        if timedOnSwitch.isOn {
            let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: timedOnDatePicker.date)
            let hour = dateComponents.hour ?? 0
            let minute = dateComponents.minute ?? 0
            write("pon\(hour):\(minute)")
        } else {
            write("1")
        }
    }
    
    func writeTurnOff() {
        if timedOffSwitch.isOn {
            let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: timedOffDatePicker.date)
            let hour = dateComponents.hour ?? 0
            let minute = dateComponents.minute ?? 0
            write("poff\(hour):\(minute)")
        } else {
            write("0")
        }
    }
    
    func writeIntermittentExecution() {
        var command = ""
        if onHours | onMinutes | onSeconds != 0 {
            command = "\(command)pon\(onHours * 60 * 60 + onMinutes * 60 + onSeconds)"
        }
        if offHours | offMinutes | offSeconds != 0 {
            command = "\(command)poff\(offHours * 60 * 60 + offMinutes * 60 + offSeconds)"
        }
        if Int(numberOfRepeatTimesStepper.value) != 0 {
            command = "\(command)cnt\(Int(numberOfRepeatTimesStepper.value))"
        }
        if command.isEmpty {
            presentMessage(title: "请检查输入条件")
        } else {
            write(command)
        }
    }
    
    func write(_ command: String) {
        guard let peripheral = peripheral, let characteristic = writeWithoutResponseCharacteristic, let data = command.data(using: .utf8) else { return }
        print("Write: CharacteristicUUID = \(characteristic.uuid.uuidString), command = \(command), dataCount = \(data.count)")
        commandLabel.text = command
        if data.count > 18 {
            let num = data.count / 18 + data.count % 18 == 0 ? 0 : 1
            for i in 0..<num {
                let subdata = i == num - 1 ? data.subdata(in: i * 18..<data.count) : data.subdata(in: i * 18..<(i + 1) * 18)
                peripheral.writeValue(subdata, for: characteristic, type: .withoutResponse)
            }
        } else {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        }
    }
}

extension SmartSocketTableViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach { service in
            print("Service: uuid = \(service.uuid.uuidString)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.forEach { characteristic in
            print("Characteristic: uuid = \(characteristic.uuid.uuidString), properties = \(characteristic.properties)")
            if characteristic.properties.contains(.read) {
                readCharacteristic = characteristic
            }
            if characteristic.properties.contains(.writeWithoutResponse) {
                writeWithoutResponseCharacteristic = characteristic
            }
            if characteristic.properties.contains(.write) {
                writeCharacteristic = characteristic
            }
            if characteristic.properties.contains(.notify) {
                notifyCharacteristic = characteristic
            }
            if characteristic.properties.contains(.indicate) {
                indicateCharacteristic = characteristic
            }
        }
        if let notifyCharacteristic = notifyCharacteristic {
            peripheral.setNotifyValue(true, for: notifyCharacteristic)
        }
        writeCalibrationTime()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value, let string = String(data: value, encoding: .utf8) {
            print("Characteristic: uuid = \(characteristic.uuid.uuidString), didUpdateValueFor = \(string)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value, let string = String(data: value, encoding: .utf8) {
            print("Characteristic: uuid = \(characteristic.uuid.uuidString), didWriteValue = \(string)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
}

extension SmartSocketTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return 24
        case 1, 2:
            return 60
        default:
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.width / 3
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0:
            return "\(row)小时"
        case 1:
            return "\(row)分钟"
        case 2:
            return "\(row)秒"
        default:
            return ""
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case onTimePickerView:
            switch component {
            case 0:
                onHours = row
            case 1:
                onMinutes = row
            case 2:
                onSeconds = row
            default:
                break;
            }
            updateOnTimeView()
        case offTimePickerView:
            switch component {
            case 0:
                offHours = row
            case 1:
                offMinutes = row
            case 2:
                offSeconds = row
            default:
                break;
            }
            updateOffTimeView()
        default:
            break
        }
    }
}
