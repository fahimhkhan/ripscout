//
//  MapViewController.swift
//  DroneMLSwift
//
//  Created by Fahim Hasan Khan on 6/29/23.
//  Copyright © 2023 DJI. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var points = "Coords"
    var dataToPass: String!

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var coords: UILabel!
    
    let locationManager = CLLocationManager()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mpViewSegue" {
            let mpViewController = segue.destination as! mpViewController
            mpViewController.dataPassed = dataToPass
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

//        if let location = locationManager.location {
//            print("Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
//            let locationCoord = location.coordinate
//            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//            let region = MKCoordinateRegion(center: locationCoord, span: span)
//            mapView.setRegion(region, animated: true)
//        }
        
        let location = CLLocationCoordinate2D(latitude: 36.963992088360925,  longitude: -122.00759597225809)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(_:)))
        mapView.addGestureRecognizer(longPressGesture)
    }
    

    @objc func addAnnotation(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            let coordinateString = "\(coordinate.latitude), \(coordinate.longitude)"
            
            self.points = self.points + ";" + coordinateString
            self.coords.text = self.points
            self.dataToPass = self.points
        }
    }
}

