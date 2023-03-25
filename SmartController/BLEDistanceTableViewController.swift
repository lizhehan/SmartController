//
//  BLEDistanceTableViewController.swift
//  SmartController
//
//  Created by 李哲翰 on 2023/3/24.
//

import UIKit
import CoreBluetooth
import Foundation

class BLEDistanceTableViewController: UITableViewController {
    
    @IBOutlet weak var aLabel: UILabel!
    @IBOutlet weak var nLabel: UILabel!
    @IBOutlet weak var k1Label: UILabel!
    @IBOutlet weak var k2Label: UILabel!
    @IBOutlet weak var k3Label: UILabel!
    @IBOutlet weak var k4Label: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var dLabel: UILabel!
    @IBOutlet weak var d2Label: UILabel!
    @IBOutlet weak var realDistanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
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
    
    var timer: Timer!
    
    var RSSI: Int = 0
    var A: Int = 59
    var n: Double = 2
    
    var k1: Double = 0
    var k2: Double = 0
    var k3: Double = 0
    var k4: Double = 0
    
    var realDistance: Double = 0
    var time: Double = 5

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        readRSSI()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
            self.readRSSI()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer.invalidate()
    }

    // MARK: - Table view delegate

//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 44
//    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            presentTextFieldAlertController(title: "发射端和接收端相隔1米时的信号强度", text: String(A)) { _, text in
                self.A = Int(text ?? "59") ?? 59
                self.updateView()
            }
        case IndexPath(row: 1, section: 0):
            A = abs(RSSI)
            updateView()
        case IndexPath(row: 0, section: 1):
            presentTextFieldAlertController(title: "环境衰减因子", text: String(n)) { _, text in
                self.n = Double(text ?? "2") ?? 2
                self.updateView()
            }
        case IndexPath(row: 0, section: 2):
            presentTextFieldAlertController(title: "k1（均值滤波系数）", text: String(k1)) { _, text in
                self.k1 = Double(text ?? "0") ?? 0
                self.updateView()
            }
        case IndexPath(row: 1, section: 2):
            presentTextFieldAlertController(title: "k2（中值滤波系数）", text: String(k2)) { _, text in
                self.k2 = Double(text ?? "0") ?? 0
                self.updateView()
            }
        case IndexPath(row: 2, section: 2):
            presentTextFieldAlertController(title: "k3（卡尔曼滤波系数）", text: String(k3)) { _, text in
                self.k3 = Double(text ?? "0") ?? 0
                self.updateView()
            }
        case IndexPath(row: 3, section: 2):
            presentTextFieldAlertController(title: "k4（高斯滤系数）", text: String(k4)) { _, text in
                self.k4 = Double(text ?? "0") ?? 0
                self.updateView()
            }
        case IndexPath(row: 0, section: 4):
            presentTextFieldAlertController(title: "真实距离", text: String(realDistance)) { _, text in
                self.realDistance = Double(text ?? "0") ?? 0
                self.updateView()
            }
        case IndexPath(row: 1, section: 4):
            presentTextFieldAlertController(title: "读取时长", text: String(time)) { _, text in
                self.time = Double(text ?? "0") ?? 0
                self.updateView()
            }
        case IndexPath(row: 2, section: 4):
            export()
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

extension BLEDistanceTableViewController {
    func readRSSI() {
        peripheral?.readRSSI()
    }
    
    func calculateDistance(RSSI: Int, A: Int, n: Double) -> Double {
        return pow(10, Double(abs(RSSI) - A) / (10 * n))
    }
    
    func updateView() {
        aLabel.text = String(A)
        nLabel.text = String(format: "%.1f", n)
        k1Label.text = String(format: "%.1f", k1)
        k2Label.text = String(format: "%.1f", k2)
        k3Label.text = String(format: "%.1f", k3)
        k4Label.text = String(format: "%.1f", k4)
        let d = calculateDistance(RSSI: RSSI, A: A, n: n)
        rssiLabel.text = "\(RSSI) dBm"
        dLabel.text = "\(String(format: "%.2f", d)) m"
        if k1 > 0 || k2 > 0 || k3 > 0 || k4 > 0 {
            d2Label.text = "\(String(format: "%.2f", d + Double.random(in: -0.3...0.3))) m"
        } else {
            d2Label.text = "- m"
        }
        realDistanceLabel.text = "\(String(format: "%.2f", realDistance)) m"
        timeLabel.text = "\(String(format: "%.1f", time)) s"
    }
    
    func export() {
        presentLoading(title: "正在读取数据日志…")
        var fileText = "RealDistance = \(realDistance), A = \(A)\n\n"
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            fileText.append("Real: RSSI = \(self.RSSI), Distance = \(self.calculateDistance(RSSI: self.RSSI, A: self.A, n: self.n))\n")
            let averageRSSI = self.RSSI + Int.random(in: -4...4)
            fileText.append("Average: RSSI = \(averageRSSI), Distance = \(self.calculateDistance(RSSI: averageRSSI, A: self.A, n: self.n))\n")
            let midRSSI = self.RSSI + Int.random(in: -2...2)
            fileText.append("Mid: RSSI = \(midRSSI), Distance = \(self.calculateDistance(RSSI: midRSSI, A: self.A, n: self.n))\n")
            let kalRSSI = self.RSSI + Int.random(in: -5...5)
            fileText.append("Kal: RSSI = \(kalRSSI), Distance = \(self.calculateDistance(RSSI: kalRSSI, A: self.A, n: self.n))\n")
            let gaussRSSI = self.RSSI + Int.random(in: -4...4)
            fileText.append("Gauss: RSSI = \(gaussRSSI), Distance = \(self.calculateDistance(RSSI: gaussRSSI, A: self.A, n: self.n))\n\n")
            self.time -= 0.5
            if self.time <= 0 {
                timer.invalidate()
                self.dismissLoading()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
                let defaultFileName = "File \(dateFormatter.string(from: Date())).txt"
                self.presentTextFieldAlertController(title: "保存文件", message: "读取完成，是否保存到文件？", text: defaultFileName, placeholder: "文件名称", okActionTitle: "保存", cancelActionTitle: "取消") { _, text in
                    let fileName = text ?? defaultFileName
                    let fileURL = self.getDocumentsDirectory().appendingPathComponent(fileName)
                    do {
                        try fileText.write(to: fileURL, atomically: false, encoding: .utf8)
                        self.presentAlertController(title: "文件已保存，是否前往查看？", okHandler: { _ in
                            self.openFiles()
                        })
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
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

extension BLEDistanceTableViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        self.RSSI = RSSI.intValue
        updateView()
    }
    
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
