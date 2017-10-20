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
//            if key == "NZA149" { array.append(value) }
        }
        
        let jsonArray = try! JSONSerialization.data(withJSONObject: array, options: .prettyPrinted)
        
        
        let airspaces = try! JSONDecoder().decode([Airspace].self, from: jsonArray)
        print(airspaces)
        self.map.addOverlays(airspaces)
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
            renderer.lineWidth = 0
            return renderer
        }
        return MKOverlayRenderer()
    }
}
