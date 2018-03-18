//
//  ViewController.swift
//  SQLiteCitySearch
//
//  Created by macbook on 3/16/18.
//  Copyright © 2018 Jaminya. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var resultView: UITableView!
    
    fileprivate let reuseCellIdentifier = "cityCell"
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    var filteredList = [String]()
    let emptyArray = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Hide empty cell in search result
        self.resultView.tableFooterView = UIView()

        configureSearchController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        searchController.searchBar.placeholder = "Search Cities"
        resultView.tableHeaderView = searchController.searchBar
        searchController.searchBar.delegate = self
    }

    func filterSearchController(_ searchBar: UISearchBar) {
        
        let searchText = searchBar.text ?? ""
        self.searchDatabase(searchTerm: searchText)
    }

}

// MARK: - Table view data source

extension ViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseCellIdentifier, for: indexPath)
        let city = searchController.isActive ? filteredList[indexPath.row] : emptyArray[indexPath.row]
        cell.textLabel!.text = city
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredList.count :  emptyArray.count
    }
}

// MARK: - Table view delegate

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "mapSegue", sender: self)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "mapSegue" {
            if let indexPath = resultView.indexPathForSelectedRow {
                let selectedCity = filteredList[indexPath.row]
                print("CityList - selectedCity: \(selectedCity)")
                let mapViewController = segue.destination as? MapViewController
                mapViewController?.selectedCityState = selectedCity
            }
        }
    }

}


// MARK: - Search delegate

extension ViewController : UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        // Debug
        print("In updateSearchResults ")
        
        let characterCount = (searchController.searchBar.text?.characters.count)!
        if characterCount >= 3 {
            filterSearchController(searchController.searchBar)
            resultView.reloadData()
        }
    }
    
}

extension ViewController : UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Debug
        print("In textDidChange")
        
        if searchText.characters.count == 0 {
            
            // Set search results = emptyArray.count
            searchController.isActive = false
            filteredList.removeAll()
        }
        resultView.reloadData()
    }
    
    func searchDatabase(searchTerm: String) {
        var fileExist = true
        var db: OpaquePointer? = nil
        var sqlStatement: OpaquePointer? = nil
        filteredList.removeAll()
        
        let projectBundle = Bundle.main
        let fileMgr = FileManager.default
        let resourcePath = projectBundle.path(forResource: "cities_usa", ofType: "sqlite")
        
        fileExist = fileMgr.fileExists(atPath: resourcePath!)
        
        if (fileExist) {
            if (!(sqlite3_open(resourcePath!, &db) == SQLITE_OK))
            {
                print("An error has occurred.")
            } else {
                let count = searchTerm.characters.count
                //let sqlQry = "SELECT id_state, city FROM us_cities WHERE SUBSTR(city, 1, \(count))=? JOIN us_states ON us_cities.ID_STATE = us_states.ID"
                let sqlQry = "SELECT city, state_code FROM us_states JOIN us_cities ON us_cities.ID_STATE = us_states.ID WHERE SUBSTR(city, 1, \(count))=? "
                if (sqlite3_prepare_v2(db, sqlQry, -1, &sqlStatement, nil) != SQLITE_OK)
                {
                    print("Problem with prepared statement" + String(sqlite3_errcode(db)));
                }
                sqlite3_bind_text(sqlStatement, 0, searchTerm, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(sqlStatement, 1, searchTerm, -1, SQLITE_TRANSIENT)
                while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
                    let concatName: String = String(cString:sqlite3_column_text(sqlStatement, 0)) + ", " +
                       String(cString:sqlite3_column_text(sqlStatement, 1))
                    
                    print("State ID + city name: " + concatName)
                    filteredList.append(concatName)
                    
                }
                sqlite3_finalize(sqlStatement)
                sqlite3_close(db)
            }
        }
    }
}
