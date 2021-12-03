//
//  SmartFileTransferTableViewController.swift
//  SmartController
//
//  Created by 李哲翰 on 2021/10/21.
//

import UIKit
import CoreBluetooth

class SmartFileTransferTableViewController: UITableViewController {
    
    @IBOutlet weak var ssidTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var commandLabel: UILabel!
    @IBOutlet weak var fileCommandTextField: UITextField!
    @IBOutlet weak var fileMessageLabel: UILabel!
    
    let writeWiFiLabelCellIndexPath = IndexPath(row: 2, section: 0)
    let writefileCommandLabelCellIndexPath = IndexPath(row: 1, section: 1)
    let fileMessageLabelCellIndexPath = IndexPath(row: 2, section: 1)
    let savedFileLabelCellIndexPath = IndexPath(row: 3, section: 1)
    
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
    
    var isReceivingFile = false
    var fileData = Data()
    
    var receiveFileTimeoutTask: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case fileMessageLabelCellIndexPath:
            if isReceivingFile {
                return 44
            } else {
                return 0
            }
        default:
            return 44
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath {
        case writeWiFiLabelCellIndexPath:
            writeWiFi()
        case writefileCommandLabelCellIndexPath:
            writeFileCommand()
        case savedFileLabelCellIndexPath:
            openFiles()
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

extension SmartFileTransferTableViewController {
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
    
    func writeWiFi() {
        write("sd:\(ssidTextField.text ?? "")")
        write("pd:\(passwordTextField.text ?? "")")
    }
    
    func writeFileCommand() {
        if let fileCommand = fileCommandTextField.text, !fileCommand.isEmpty {
            write("pull\(fileCommand)")
            
            fileData.removeAll()
            
            isReceivingFile = true
            fileMessageLabel.text = "正在等待对方发送文件…"
            tableView.beginUpdates()
            tableView.endUpdates()
            
            receiveFileTimeoutTask?.cancel()
            receiveFileTimeoutTask = DispatchWorkItem {
                self.isReceivingFile = false
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: receiveFileTimeoutTask!)
        } else {
            presentMessage(title: "请先输入文件指令")
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
    
    func openFiles() {
        let path = getDocumentsDirectory().absoluteString.replacingOccurrences(of: "file://", with: "shareddocuments://")
        let url = URL(string: path)!
        UIApplication.shared.open(url)
    }
    
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

extension SmartFileTransferTableViewController: CBPeripheralDelegate {
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
        
        if isReceivingFile {
            fileData.append(value)
            
            fileMessageLabel.text = "正在接收文件…"
            
            receiveFileTimeoutTask?.cancel()
            receiveFileTimeoutTask = DispatchWorkItem {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
                let defaultFileName = "File \(dateFormatter.string(from: Date())).txt"
                
                self.presentTextFieldAlertController(title: "保存文件", message: "收到一个文件，是否保存？", text: defaultFileName, placeholder: "文件名称", okActionTitle: "保存", cancelActionTitle: "取消") { _, text in
                    let fileName = text ?? defaultFileName
                    let fileURL = self.getDocumentsDirectory().appendingPathComponent(fileName)
                    do {
                        try self.fileData.write(to: fileURL)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                
                self.isReceivingFile = false
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: receiveFileTimeoutTask!)
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
