//
//  Airspace.swift
//  Nz Airspace
//
//  Created by Tristan Beaton on 20/10/17.
//  Copyright © 2017 Tristan Beaton. All rights reserved.
//

import Foundation
import MapKit

class Airspace : NSObject, MKOverlay, Decodable {
    
    var id: String
    var name: String
    var lower: Int
    var upper: Int
    var type: String
    var discriptors: Array<PathDescription>
    var boundary: Array<MKMapPoint>
    
    var boundingMapRect: MKMapRect {
        var rect = MKMapRectNull
        for point in boundary {
            let pointRect = MKMapRectMake(point.x, point.y, 0, 0)
            if MKMapRectIsNull(rect) {
                rect = pointRect
            } else {
                rect = MKMapRectUnion(rect, pointRect)
            }
        }
        return rect
    }
    
    var coordinate: CLLocationCoordinate2D {
        return MKCoordinateForMapPoint(MKMapPointMake(MKMapRectGetMidX(boundingMapRect), MKMapRectGetMidY(boundingMapRect)))
    }
    
    var color: UIColor {
        switch type.components(separatedBy: "/")[0] {
            case "CTA": return UIColor(red: 129/255, green: 044/255, blue: 124/255, alpha: 1.0)
            case "CTR": return UIColor(red: 000/255, green: 103/255, blue: 165/255, alpha: 1.0)
            case "QNH": return .yellow
            default: return .black
        }
    }
    
    enum PathDescription : Decodable {
        case line(coordinate:CLLocationCoordinate2D)
        case point(coordinate:CLLocationCoordinate2D, angle:Int, radius:Double)
        case arc(coordinate:CLLocationCoordinate2D, start:Int, end:Int, radius:Double, clockwise:Bool)
        
        private enum CodingKeys : String, CodingKey {
            case latitude
            case longitude
            case angle
            case start
            case end
            case radius
            case clockwise
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let lat = try container.decode(Double.self, forKey: .latitude)
            let lon = try container.decode(Double.self, forKey: .longitude)
            let coordinate = CLLocationCoordinate2DMake(lat, lon)
            // Try to create a point
            if let angle = try? container.decode(Int.self, forKey: .angle),
                let radius = try? container.decode(Double.self, forKey: .radius) {
                self = .point(coordinate: coordinate, angle: angle, radius: radius)
                return
            }
            // Try to create an arc
            if let start = try? container.decode(Int.self, forKey: .start),
                let end = try? container.decode(Int.self, forKey: .end),
                let radius = try? container.decode(Double.self, forKey: .radius),
                let clockwise = try? container.decode(Bool.self, forKey: .clockwise) {
                self = .arc(coordinate: coordinate, start: start, end: end, radius: radius, clockwise: clockwise)
                return
            }
            // This must just be a line
            self = .line(coordinate: coordinate)
        }
    }
    
    private enum CodingKeys : String, CodingKey {
        case id
        case name
        case lower
        case upper
        case type
        case boundary
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.lower = try container.decode(Int.self, forKey: .lower)
        self.upper = try container.decode(Int.self, forKey: .upper)
        self.type = try container.decode(String.self, forKey: .type)
        self.discriptors = try container.decode([PathDescription].self, forKey: .boundary)
        self.boundary = Array<MKMapPoint>()
        // Initialise Superclass
        super.init()
        // Calculate boundary
        for descriptor in self.discriptors {
            // Methods for calculating points
            func point(center:CLLocationCoordinate2D, angle:Int, radius:Double) -> CLLocationCoordinate2D {
                let centerMP = MKMapPointForCoordinate(center)
                var r = MKMapPointsPerMeterAtLatitude(center.latitude) * radius * 1852
                var mp = MKMapPointMake(r * cos(Double(angle - 90) * .pi / 180.0) + centerMP.x, r * sin(Double(angle - 90) * .pi / 180.0) + centerMP.y)
                var distance = MKMetersBetweenMapPoints(centerMP, mp)
                // This is just for more accuracy. Currently it is the nearest metre.
                while Int(round(distance)) != Int(round(radius * 1852)) {
                    r = radius * 1852 / distance * r
                    mp.x = r * cos(Double(angle - 90) * .pi / 180.0) + centerMP.x
                    mp.y = r * sin(Double(angle - 90) * .pi / 180.0) + centerMP.y
                    distance = MKMetersBetweenMapPoints(centerMP, mp)
                }
                return MKCoordinateForMapPoint(mp)
            }
            // Add point to boundary
            func add(_ coordinate:CLLocationCoordinate2D) {
                let point = MKMapPointForCoordinate(coordinate)
                // If the array is emtpy, just add the point straight to the array.
                if self.boundary.count == 0 { self.boundary.append(point); return }
                // Otherwise, calculate the closest point
                let worldWidth = MKMapRectWorld.size.width
                let yesterday = MKMapPoint(x: point.x + worldWidth, y: point.y)
                let tommorow = MKMapPoint(x: point.x - worldWidth, y: point.y)
                // Calculate distance between mappoints
                func distance(_ pt: MKMapPoint) -> Double {
                    let previous = self.boundary.last!
                    let xDelta = previous.x - pt.x
                    let yDelta = previous.y - pt.y
                    return sqrt((xDelta * xDelta) + (yDelta * yDelta))
                }
                // Calculate the closest point
                let pD = distance(point)
                let yD = distance(yesterday)
                let tD = distance(tommorow)
                // Add the closest point based on distance
                switch min(pD, yD, tD) {
                    case yD: self.boundary.append(yesterday)
                    case tD: self.boundary.append(tommorow)
                    default: self.boundary.append(point)
                }
            }
            // Build Path
            switch descriptor {
            // Add point
            case .line(let coordinate):
                add(coordinate)
            // Calculate a point on a arc.
            case .point(let coordinate, let angle, let radius):
                add(point(center: coordinate, angle: angle, radius: radius))
            // Calculate the points along an arc.
            case .arc(let coordinate, var start, var end, let radius, let clockwise):
                // Adjust start and end values so that the angles can be calculated correctly
                if !clockwise && start < end { start += 360 }
                if clockwise && end < start { end += 360 }
                // Calculate the angles along the arc
                let angles = min(start, end) ... max(start, end)
                if clockwise {
                    for i in angles { add(point(center: coordinate, angle: i, radius: radius)) }
                } else {
                    for i in angles.reversed() { add(point(center: coordinate, angle: i, radius: radius)) }
                }
            }
        }
    }
}
