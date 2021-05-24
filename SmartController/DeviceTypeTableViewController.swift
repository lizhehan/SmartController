//
//  DeviceTypeTableViewController.swift
//  SmartController
//
//  Created by 李哲翰 on 2021/5/21.
//

import UIKit
import CoreBluetooth

class DeviceTypeTableViewController: UITableViewController {
    
    var peripheral: CBPeripheral?
    
    let deviceTypes = ["智能插座", "智能闹钟", "智能隔空传文本", "智能点歌" , "智能日程", "智能遥控"]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deviceTypes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceTypeTableViewCell", for: indexPath)
        cell.textLabel?.text = deviceTypes[indexPath.row]
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "SmartSocketSegue", sender: self)
        default:
            presentMessage(title: "该设备类型暂未支持") { _ in 
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SmartSocketSegue" {
            let smartSocketTableViewController = segue.destination as! SmartSocketTableViewController
            smartSocketTableViewController.peripheral = peripheral
        }
    }

}
