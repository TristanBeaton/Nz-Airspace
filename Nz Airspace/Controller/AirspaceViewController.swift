//
//  AirspaceViewController.swift
//  Nz Airspace
//
//  Created by Tristan Beaton on 20/10/17.
//  Copyright © 2017 Tristan Beaton. All rights reserved.
//

import UIKit

class AirspaceViewController: UITableViewController {
    
    var tableData = Array<Airspace>()
    var selectedRow = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.navigationItem.largeTitleDisplayMode = .automatic
//        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        guard
            let path = Bundle.main.path(forResource: "airspace", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let json = try? JSONSerialization.jsonObject(with: data),
            let dict = json as? Dictionary<String,Dictionary<String,Any>>
            else {
                return
        }
        
        var array = Array<Dictionary<String,Any>>()
        
        for (key, value) in dict {
            array.append(value)
//            if key == "NZA936" { array.append(value) }
//            if key == "NZA937" { array.append(value) }
//            if key == "NZA938" { array.append(value) }
        }
        
        let jsonArray = try! JSONSerialization.data(withJSONObject: array, options: .prettyPrinted)
        let airspaces = try! JSONDecoder().decode([Airspace].self, from: jsonArray)
        self.tableData = airspaces.sorted{ $0.id < $1.id }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "airspaceCell", for: indexPath) as! AirspaceCell

        let airspace = self.tableData[indexPath.row]
        cell.airspace = airspace

        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
