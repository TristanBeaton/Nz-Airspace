//
//  AirspaceRenderer.swift
//  Nz Airspace
//
//  Created by Tristan Beaton on 20/10/17.
//  Copyright © 2017 Tristan Beaton. All rights reserved.
//

import Foundation
import MapKit

class AirspaceRenderer: MKOverlayPathRenderer {
    
    var showBounds = false
    
    override func createPath() {
        let path = CGMutablePath()
        if let airspace = self.overlay as? Airspace {
            for mp in airspace.boundary {
                if path.isEmpty {
                    path.move(to: point(for: mp))
                } else {
                    path.addLine(to: point(for: mp))
                }
            }
            path.closeSubpath()
        }
        
        if showBounds {
            let rect = self.overlay.boundingMapRect
            path.move(to: point(for: rect.topLeft))
            path.addLine(to: point(for: rect.topRight))
            path.addLine(to: point(for: rect.bottomRight))
            path.addLine(to: point(for: rect.bottomLeft))
            path.closeSubpath()
        }
        
        self.path = path
    }
}

extension MKMapRect {
    
    var topLeft: MKMapPoint {
        return self.origin
    }
    
    var topRight: MKMapPoint {
        return MKMapPoint(x: self.origin.x + self.size.width, y: self.origin.y)
    }
    
    var bottomLeft: MKMapPoint {
        return MKMapPoint(x: self.origin.x, y: self.origin.y + self.size.height)
    }
    
    var bottomRight: MKMapPoint {
        return MKMapPoint(x: self.origin.x + self.size.width, y: self.origin.y + self.size.height)
    }
}

