//
//  EarthquakesViewController.swift
//  Quakes
//
//  Created by Paul Solt on 10/3/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import MapKit

class EarthquakesViewController: UIViewController {
    
    private let quakeFetcher = QuakeFetcher()
    
    @IBOutlet var mapView: MKMapView!
    private var userTrackingButton: MKUserTrackingButton!
    
    private let locationManager = CLLocationManager()
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        
        userTrackingButton = MKUserTrackingButton(mapView: mapView)
        userTrackingButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(userTrackingButton)
        
        NSLayoutConstraint.activate([
            userTrackingButton.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 20),
            mapView.bottomAnchor.constraint(equalTo: userTrackingButton.bottomAnchor,constant: 20)
        ])
        
        fetchQuakes()
    }
    
    var quakes: [Quake] = [] {
        didSet {
            let oldQuakes = Set(oldValue)
            let newQuakes = Set(quakes)
            let addedQuakes = newQuakes.subtracting(oldQuakes)
            let removedQuakes = oldQuakes.subtracting(newQuakes)
            mapView.removeAnnotations(Array(removedQuakes))
            mapView.addAnnotations(Array(addedQuakes))
        }
    }

    private var isCurrentlyFetchingQuakes = false
    private var shouldRequestQuakesAgain = false
    private func fetchQuakes() {
        /// If we were already requesting quakes…
        guard !isCurrentlyFetchingQuakes else {
            /// … then we want to "remember" to refresh once the busy request finishes
            shouldRequestQuakesAgain = true
            return
        }
        isCurrentlyFetchingQuakes = true
        let visibleRegion = mapView.visibleMapRect
        quakeFetcher.fetchQuakes(in: visibleRegion) { quakes, error in
            self.isCurrentlyFetchingQuakes = false
            defer {
                if self.shouldRequestQuakesAgain {
                    self.shouldRequestQuakesAgain = false
                    self.fetchQuakes()
                }
            }
            if let error = error {
                NSLog("%@", "Error fetching quakes: \(error)")
            }
            self.quakes = quakes ?? []
        }
    }
}

extension EarthquakesViewController: MKMapViewDelegate {
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        fetchQuakes()
    }
}

