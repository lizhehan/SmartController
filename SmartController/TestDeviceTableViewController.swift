//
//  TestDeviceTableViewController.swift
//  SmartController
//
//  Created by 李哲翰 on 2022/5/16.
//

import UIKit
import CoreBluetooth

class TestDeviceTableViewController: UITableViewController {

    @IBOutlet weak var commandTextField: UITextField!
    @IBOutlet weak var commandLabel: UILabel!
    
    let writeCommandLabelCellIndexPath = IndexPath(row: 1, section: 0)
    
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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath {
        case writeCommandLabelCellIndexPath:
            writeCommand()
        default:
            break
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension TestDeviceTableViewController {
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
    
    func writeCommand() {
        write(commandTextField.text ?? "")
    }
    
    func write(_ command: String) {
        guard let peripheral = peripheral, let characteristic = writeCharacteristic, let data = command.data(using: .utf8) else { return }
        print("Write: CharacteristicUUID = \(characteristic.uuid.uuidString), command = \(command), dataCount = \(data.count)")
        commandLabel.text = command
        if data.count > 18 {
            let num = data.count / 18 + data.count % 18 == 0 ? 0 : 1
            for i in 0..<num {
                let subdata = i == num - 1 ? data.subdata(in: i * 18..<data.count) : data.subdata(in: i * 18..<(i + 1) * 18)
                peripheral.writeValue(subdata, for: characteristic, type: .withResponse)
            }
        } else {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }
}

extension TestDeviceTableViewController: CBPeripheralDelegate {
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
        guard let value = characteristic.value else { return }
        print("Characteristic: uuid = \(characteristic.uuid.uuidString), didUpdateValueFor = \(value)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value, let string = String(data: value, encoding: .utf8) {
            print("Characteristic: uuid = \(characteristic.uuid.uuidString), didWriteValue = \(string)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
    }
}
