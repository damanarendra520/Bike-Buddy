//
//  ViewController.swift
//  Bike Buddy
//
//  Created by Narendra Dama on 11/8/19.
//  Copyright © 2019 Narendra Dama. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var startingLocation: UITextField!
    @IBOutlet weak var endLocation: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var startingaddressLabel: UILabel!
    @IBOutlet weak var endaddressLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var networks: [GeocodingService] = []
    var cityIds = [String : String]()
    var startingLocationAddress: String = ""
    var endLocationAddress: String = ""
    var cityId: String = ""
    var Lat: Float = 0.0
    var Lng: Float = 0.0
    var selectedAnnotation: MKPointAnnotation?
    var routeStartingPointLat: Float = 0.0
    var routeStartingPointLong: Float = 0.0
    var routeEndPointLat: Float = 0.0
    var routeEndPointLong: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Keyboard Delegate
        startingLocation.delegate = self
        
        // Get All the networks data
        getAllTheNetworks()
        
        //setting the user location.
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    // Keyboard Delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        startingLocationAddress = startingLocation.text!
        getBikesByLocation(address: startingLocationAddress)
        textField.resignFirstResponder()
        return true
    }
    
    func getBikesByLocation(address: String) {
        for (e, value) in cityIds  {
            if e == address {
                self.cityId = value
            }
        }
        getStationsForNetworkId(forNetwork: cityId)
    }
    
    /**
     Routes between points.
     */
    @IBAction func getRoute(_ sender: Any) {
        startingaddressLabel.text = nil
        endaddressLabel.text = nil
        
        // remove old routs
        mapView.removeOverlays(mapView.overlays)
        var sourceLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        var destinationLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        
        if routeStartingPointLong != 0.0 && routeStartingPointLong != 0.0{
            sourceLocation = CLLocationCoordinate2D(latitude: CLLocationDegrees(routeStartingPointLat), longitude: CLLocationDegrees(routeStartingPointLong))
        }
        if routeEndPointLat != 0.0 && routeEndPointLong != 0.0 {
            destinationLocation = CLLocationCoordinate2D(latitude: CLLocationDegrees(routeEndPointLat), longitude: CLLocationDegrees(routeEndPointLong))
        }
        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
     
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let sourceAnnotation = MKPointAnnotation()
        let destinationAnnotation = MKPointAnnotation()
        
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }
        
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }
        
        self.mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        // Calculate the direction
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate {
            (response, error) -> Void in
            
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }
                
                return
            }
            
            let route = response.routes[0]
            self.mapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    
    
    //getAllTheNetworks
    func getAllTheNetworks() {

        let jsonUrlString = "https://api.citybik.es/v2/networks"
        let url = URL(string: jsonUrlString)
        
        URLSession.shared.dataTask(with: url!) { (data, response, err) in
            let data = data
            do {
                let datais = try JSONDecoder().decode(GeocodingService.self, from: data!)
                for result in datais.networks{
                    //print("(\(result.location.city),\(result.id))")
                    self.cityIds[result.location.city] = result.id
                }
            } catch let jsonErr {
                print("Error serializing json:", jsonErr)
            }}.resume()
    }
    
    
    //getStationsForNetworkId
    func getStationsForNetworkId(forNetwork: String) {
        let jsonUrlString = "https://api.citybik.es/v2/networks/\(forNetwork)"
        let url = URL(string: jsonUrlString)
        
        URLSession.shared.dataTask(with: url!) { (data, response, err) in
            let data = data
            do {
                let datais = try JSONDecoder().decode(GeocodingServices.self, from: data!)
                for result in datais.network.stations {
                    print(result.name)
                    let Pin = MKPointAnnotation()
                    Pin.title = result.name
                    Pin.subtitle = "Empty Slots: \(String(result.empty_slots)) && Free Bikes: \(result.free_bikes)"
                    Pin.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(result.latitude), longitude: CLLocationDegrees(result.longitude))
                    self.mapView.addAnnotation(Pin)
                    self.Lat = result.latitude
                    self.Lng = result.longitude
                }
                self.zoomMaptoOneOfPins(Lat: self.Lat, Long: self.Lng)
            } catch let jsonErr {
                print("Error serializing json:", jsonErr)
        }}.resume()
    }
    
    //mapView
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? Artwork else { return nil }
        
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        // 4
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {

            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
    }
    
    //zoomMaptoOneOfPins
    func zoomMaptoOneOfPins(Lat: Float, Long: Float) {
        let location = CLLocationCoordinate2D(latitude: CLLocationDegrees(Lat), longitude: CLLocationDegrees(Long))
        let coordinateRegion = MKCoordinateRegion.init(center: location, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        self.selectedAnnotation = view.annotation as? MKPointAnnotation
        print(self.selectedAnnotation?.coordinate.latitude as Any)
        if routeStartingPointLat == 0.0 {
            routeStartingPointLat = Float((self.selectedAnnotation?.coordinate.latitude)!)
            routeStartingPointLong = Float((self.selectedAnnotation?.coordinate.longitude)!)
            print(self.selectedAnnotation?.title as Any)
            startingaddressLabel.text = (self.selectedAnnotation?.title as Any as! String)
        }else {
            routeEndPointLat = Float((self.selectedAnnotation?.coordinate.latitude)!)
            routeEndPointLong = Float((self.selectedAnnotation?.coordinate.longitude)!)
            endaddressLabel.text = (self.selectedAnnotation?.title as Any as! String)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.red
        renderer.lineWidth = 4.0
        
        return renderer
    }
}

