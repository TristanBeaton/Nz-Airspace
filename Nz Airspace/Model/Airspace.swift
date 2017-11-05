//
//  Airspace.swift
//  Nz Airspace
//
//  Created by Tristan Beaton on 20/10/17.
//  Copyright © 2017 Tristan Beaton. All rights reserved.
//

import Foundation
import MapKit

class Airspace : NSObject, MKOverlay, Codable {
    
    #if os(OSX)
    typealias Color = NSColor
    #else
    typealias Color = UIColor
    #endif
    
    // Properties
    private(set) var id: String
    private(set) var name: String
    private(set) var type: String
    private(set) var lower: Int
    private(set) var upper: Int
    private(set) var descriptors: Array<PathDescription>
    private(set) var boundary: Array<MKMapPoint>
    
    // MKOverlay Properties
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
    
    override var description: String {
        return "Airspace(id: \(id), name: \(name), lower: \(lower), upper: \(upper), type: \(type))"
    }
    
    // Default Color
    var color: Color {
        switch type.components(separatedBy: "/")[0] {
            case "CTA": return Color(red: 129/255, green: 044/255, blue: 124/255, alpha: 1.0)
            case "CTR": return Color(red: 000/255, green: 103/255, blue: 165/255, alpha: 1.0)
            case "T": return Color(red: 119/255, green: 166/255, blue: 205/255, alpha: 1.0)
            case "D": return Color(red: 216/255, green: 035/255, blue: 042/255, alpha: 1.0)
            case "QNH": return .yellow
            default: return .black
        }
    }
    
    // MARK: - Initialise
    
    init(id:String, name:String, type:String, lower:Int, upper:Int) {
        self.id = id
        self.name = name
        self.type = type
        self.lower = lower
        self.upper = upper
        self.descriptors = Array<PathDescription>()
        self.boundary = Array<MKMapPoint>()
        super.init()
    }
    
    // Helper functions for drawing an airspace
    // Draws an line.
    func add(latitude:Double, longitude:Double) {
        self.add(descriptor: .line(coordinate: CLLocationCoordinate2DMake(latitude, longitude)))
    }
    // Draws an point.
    func add(latitude:Double, longitude:Double, angle:Int, radius:Double) {
        self.add(descriptor: .point(coordinate: CLLocationCoordinate2DMake(latitude, longitude), angle: angle, radius: radius))
    }
    // Draws an arc. Default initiliser will draw a circle.
    func add(latitude:Double, longitude:Double, start:Int = 0, end:Int = 359, radius:Double, clockwise:Bool = true) {
        self.add(descriptor: .arc(coordinate: CLLocationCoordinate2DMake(latitude, longitude), start: start, end: end, radius: radius, clockwise: clockwise))
    }
    
    // This is a helper function that calculates the coordinates for the boundary.
    private func add(descriptor:PathDescription) {
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
        // Add the descriptor to the array
        self.descriptors.append(descriptor)
    }
    
    // Method for calculating coordiantes.
    private func point(center:CLLocationCoordinate2D, angle:Int, radius:Double) -> CLLocationCoordinate2D {
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
    
    // Add point to boundary.
    private func add(_ coordinate:CLLocationCoordinate2D) {
        let point = MKMapPointForCoordinate(coordinate)
        // If the array is emtpy, just add the point straight to the array.
        if self.boundary.count == 0 { self.boundary.append(point); return }
        // Otherwise, calculate the closest point, this is due to points crossing the date line.
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
    
    // MARK: - Codable
    enum PathDescription : Codable {
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
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            // Encode Descriptor
            switch self {
            // Encode Line
            case .line(let coordinate):
                try container.encode(round(coordinate.latitude * 1000000) / 1000000, forKey: .latitude)
                try container.encode(round(coordinate.longitude * 1000000) / 1000000, forKey: .longitude)
            // Encode Point
            case .point(let coordinate, let angle, let radius):
                try container.encode(round(coordinate.latitude * 1000000) / 1000000, forKey: .latitude)
                try container.encode(round(coordinate.longitude * 1000000) / 1000000, forKey: .longitude)
                try container.encode(angle, forKey: .angle)
                try container.encode(radius, forKey: .radius)
            // Encode Arc
            case .arc(let coordinate, let start, let end, let radius, let clockwise):
                try container.encode(round(coordinate.latitude * 1000000) / 1000000, forKey: .latitude)
                try container.encode(round(coordinate.longitude * 1000000) / 1000000, forKey: .longitude)
                try container.encode(start, forKey: .start)
                try container.encode(end, forKey: .end)
                try container.encode(radius, forKey: .radius)
                try container.encode(clockwise, forKey: .clockwise)
            }
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
        self.type = try container.decode(String.self, forKey: .type)
        self.lower = try container.decode(Int.self, forKey: .lower)
        self.upper = try container.decode(Int.self, forKey: .upper)
        self.descriptors = Array<PathDescription>()
        self.boundary = Array<MKMapPoint>()
        // Initilise superclass
        super.init()
        // Add descriptors
        try container.decode([PathDescription].self, forKey: .boundary).forEach{ add(descriptor: $0) }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(lower, forKey: .lower)
        try container.encode(upper, forKey: .upper)
        try container.encode(descriptors, forKey: .boundary)
    }
}
