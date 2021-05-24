//
//  NumberTableViewController.swift
//  SmartController
//
//  Created by 李哲翰 on 2021/5/21.
//

import UIKit

protocol NumberTableViewControllerDelegate: AnyObject {
   func didSelect(index: Int)
}

class NumberTableViewController: UITableViewController {
    
    var numbers = [Int]()
    var selectedIndex: Int?
    weak var delegate: NumberTableViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numbers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NumberTableViewCell", for: indexPath)
        let index = numbers[indexPath.row]
        cell.textLabel?.text = String(index)
        cell.accessoryType = index == selectedIndex ? .checkmark : .none
        return cell
    }

    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedIndex = numbers[indexPath.row]
        delegate?.didSelect(index: selectedIndex!)
        tableView.reloadData()
        navigationController?.popViewController(animated: true)
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
