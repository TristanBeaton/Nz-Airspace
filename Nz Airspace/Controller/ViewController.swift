//
//  ViewController.swift
//  Nz Airspace
//
//  Created by Tristan Beaton on 20/10/17.
//  Copyright © 2017 Tristan Beaton. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var map: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if #available(iOS 11.0, *) {
            self.map.mapType = .mutedStandard
        } else {
            self.map.mapType = .standard
        }
        loadAirspaces()
    }
    
    func loadAirspaces(){
        guard
            let path = Bundle.main.path(forResource: "qnh", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let json = try? JSONSerialization.jsonObject(with: data),
            let dict = json as? Dictionary<String,Dictionary<String,Any>>
        else {  return }
        
        var array = Array<Dictionary<String,Any>>()
        
        for (key, value) in dict {
            array.append(value)
//            if key == "NZA936" { array.append(value) }
//            if key == "NZA937" { array.append(value) }
//            if key == "NZA938" { array.append(value) }
        }
        do {
            let jsonArray = try JSONSerialization.data(withJSONObject: array, options: .prettyPrinted)
            let airspaces = try JSONDecoder().decode([Airspace].self, from: jsonArray)
            
            print(airspaces)
            self.map.addOverlays(airspaces, level: .aboveRoads)
            
            let airspaceBoundingMapRect = airspaces[0].boundingMapRect
            airspaces.forEach { MKMapRectUnion(airspaceBoundingMapRect, $0.boundingMapRect) }
            self.map.setVisibleMapRect(airspaceBoundingMapRect, animated: true)
        } catch {
            print(error)
        }
    }

    
    func point(center:CLLocationCoordinate2D, angle:Int, radius:Double) -> CLLocationCoordinate2D {
        // Convert to radians
        let lat = center.latitude * .pi / 180
        let dir = Double(angle) * .pi / 180
        let dis = radius * 1852
        // Calculate the change in Latitude and Longitude
        let latDelta = dis * cos(dir) / 110540
        let lonDelta = dis * sin(dir) / (111320 * cos(lat))
        // Add the deltas to the orignal values
        return CLLocationCoordinate2DMake(center.latitude + latDelta, center.longitude + lonDelta)
    }
    
    func point2(center:CLLocationCoordinate2D, angle:Int, radius:Double) -> CLLocationCoordinate2D {
        // Convert to radians
        let lat = center.latitude * .pi / 180
        let dir = Double(angle) * .pi / 180
        let dis = radius * 1852
        
        let er = (dis / 6371000) * .pi / 180
        
        let lat2 = asin(sin(lat) * cos(er) + cos(lat) * sin(er) * cos(dir)) * 180 / .pi
        let lon2 = center.longitude + (atan2(sin(dir) * sin(er) * cos(lat), cos(er) - sin(lat) * sin(lat2)) * 180 / .pi)
        return CLLocationCoordinate2DMake(lat2, lon2)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        print("Memory Warning")
    }
}

extension ViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let airspace = overlay as? Airspace {
            let renderer = AirspaceRenderer(overlay: airspace)
            renderer.strokeColor = airspace.color
            renderer.fillColor = airspace.color.withAlphaComponent(0.3)
            renderer.lineWidth = 0
            return renderer
        }
        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)
            renderer.strokeColor = .blue
            renderer.lineWidth = 0
            return renderer
        }
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 0
            return renderer
        }
        return MKOverlayRenderer()
    }
}
