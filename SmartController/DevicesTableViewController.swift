//
//  DevicesTableViewController.swift
//  SmartController
//
//  Created by 李哲翰 on 2021/5/21.
//

import UIKit
import CoreBluetooth

class DevicesTableViewController: UITableViewController {
    
    var centralManager: CBCentralManager?
    
    var peripherals = [CBPeripheral]()
    var localNames = [String]()
    var connectedPeripheral: CBPeripheral?

    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cancelPeripheralConnection()
    }
    
    @IBAction func refreshButtonTapped(_ sender: UIBarButtonItem) {
        rescan()
    }
    
    @IBAction func refreshControlActivated(_ sender: UIRefreshControl) {
        rescan()
        sender.endRefreshing()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return localNames.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceTableViewCell", for: indexPath)
        cell.textLabel?.text = localNames[indexPath.row]
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        connect(peripheral: peripherals[indexPath.row])
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DeviceTypeSegue" {
            let deviceTypeTableViewController = segue.destination as! DeviceTypeTableViewController
            deviceTypeTableViewController.peripheral = connectedPeripheral
        } else if segue.identifier == "SmartSocketSegue" {
            let smartSocketTableViewController = segue.destination as! SmartSocketTableViewController
            smartSocketTableViewController.peripheral = connectedPeripheral
        }
    }
}

extension DevicesTableViewController {
    func scanForPeripherals() {
        centralManager?.scanForPeripherals(withServices: nil)
    }
    
    func stopScan() {
        centralManager?.stopScan()
    }
    
    func rescan() {
        stopScan()
        peripherals.removeAll()
        localNames.removeAll()
        tableView.reloadData()
        scanForPeripherals()
    }
    
    func connect(peripheral: CBPeripheral) {
        presentLoading(title: "正在连接设备…")
        cancelPeripheralConnection()
        centralManager?.connect(peripheral)
    }
    
    func cancelPeripheralConnection() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
}

extension DevicesTableViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            break
        case .poweredOn:
            scanForPeripherals()
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String, !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            peripherals.append(peripheral)
            localNames.append(localName)
            tableView.insertRows(at: [IndexPath(row: localNames.count - 1, section: 0)], with: .automatic)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScan()
        connectedPeripheral = peripheral
        dismissLoading() {
            self.performSegue(withIdentifier: "DeviceTypeSegue", sender: self)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        rescan()
        dismissLoading {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
            self.presentMessage(title: "连接设备失败，请重试")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        rescan()
        connectedPeripheral = nil
    }
}
