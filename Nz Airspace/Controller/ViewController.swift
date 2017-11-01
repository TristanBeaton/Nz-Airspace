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
        }
        
        loadFile(named: "qnh")
//        loadFile(named: "ctr")
//        loadFile(named: "cta")
    }
    
    func loadFile(named:String){
        guard
            let path = Bundle.main.path(forResource: named, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let json = try? JSONSerialization.jsonObject(with: data)
        else {  return }
        
        do {
            let jsonArray = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            let airspaces = try JSONDecoder().decode([Airspace].self, from: jsonArray)
            self.map.addOverlays(airspaces, level: .aboveRoads)
        } catch {
            print(error)
        }
    }
}

extension ViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let airspace = overlay as? Airspace {
            let renderer = AirspaceRenderer(overlay: airspace)
            renderer.showBounds = false
            renderer.strokeColor = airspace.color
            renderer.fillColor = airspace.color.withAlphaComponent(0.1)
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
