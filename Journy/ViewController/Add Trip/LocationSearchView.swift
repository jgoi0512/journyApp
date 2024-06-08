//
//  LocationSearchView.swift
//  Journy
//
//  Created by Justin Goi on 15/5/2024.
//

import Foundation
import UIKit
import MapKit

/**
 A custom view for displaying location search results.
 
 This view provides a table view to display location search results fetched from the MKLocalSearchCompleter.
 Users can select a location from the search results, triggering a callback with the selected search completion object.
 */
class LocationSearchView: UIView, UITableViewDelegate, UITableViewDataSource {
    var searchResults: [MKLocalSearchCompletion] = []
    var onSelectLocation: ((MKLocalSearchCompletion) -> Void)?
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LocationCell")
        return tableView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        
        let searchResult = searchResults[indexPath.row]
        cell.textLabel?.text = searchResult.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedResult = searchResults[indexPath.row]
        onSelectLocation?(selectedResult)
    }
    
    func reloadData() {
        tableView.reloadData()
    }
}
