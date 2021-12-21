//
//  SmartFindThingTableViewController.swift
//  SmartController
//
//  Created by 李哲翰 on 2021/12/20.
//

import UIKit
import CoreBluetooth
import Foundation

class SmartFindThingTableViewController: UITableViewController {
    
    @IBOutlet weak var aLabel: UILabel!
    @IBOutlet weak var aStepper: UIStepper! {
        didSet {
            aStepper.value = 59
        }
    }
    @IBOutlet weak var nLabel: UILabel!
    @IBOutlet weak var nStepper: UIStepper! {
        didSet {
            nStepper.value = 2
        }
    }
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var dLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    
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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        readRSSI()
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(readRSSI), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer.invalidate()
    }
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        if sender == aStepper {
            A = Int(sender.value)
            aLabel.text = String(A)
        } else if sender == nStepper {
            n = sender.value
            nLabel.text = String(format: "%.1f", n)
        }
        updateResultView()
    }
    
    func updateResultView() {
        let d = calculateDistance(RSSI: RSSI, A: A, n: n)
        var warning = ""
        if RSSI <= -80 {
            warning = "安全距离"
        } else if RSSI > -80 && RSSI <= -60 {
            warning = "疑似距离"
        } else if RSSI > -60 && RSSI <= -40 {
            warning = "警示距离"
        } else {
            warning = "密切接触"
        }
        rssiLabel.text = "\(RSSI) dBm"
        dLabel.text = "\(String(format: "%.2f", d)) m"
        warningLabel.text = warning
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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

extension SmartFindThingTableViewController {
    @objc func readRSSI() {
        peripheral?.readRSSI()
    }
    
    func calculateDistance(RSSI: Int, A: Int, n: Double) -> Double {
        return pow(10, Double(abs(RSSI) - A) / (10 * n))
    }
}

extension SmartFindThingTableViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        self.RSSI = RSSI.intValue
        updateResultView()
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
