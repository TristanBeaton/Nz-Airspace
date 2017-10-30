//
//  AirspaceCell.swift
//  Nz Airspace
//
//  Created by Tristan Beaton on 20/10/17.
//  Copyright © 2017 Tristan Beaton. All rights reserved.
//


import UIKit
import MapKit

@IBDesignable class AirspaceCell: UITableViewCell {
    
    var airspace:Airspace? {
        didSet {
            self.updateCell()
        }
    }
    
    var isVisible:Bool = true
    
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var verticalLimitsLabel: UILabel!
    
    override func draw(_ rect: CGRect) {
        self.tintColor.setFill()
        let center = (rect.height > 50 ? CGPoint(x: 25, y: 25) : CGPoint(x: 25, y: rect.midY))
        let path = UIBezierPath(arcCenter: center, radius: 5, startAngle: CGFloat(0).radians, endAngle: CGFloat(360).radians, clockwise: true)
        path.fill()
    }
    
    func updateCell(){
        if let airspace = airspace {
            // Update Labels
            self.idLabel.text = airspace.id
            self.nameLabel.text = "\(airspace.name) (\(airspace.type))"
            let lower = (airspace.lower == 0 ? "SFC" : (airspace.lower > 13000 ? "FL\(airspace.lower / 100)" : "\(airspace.lower)FT"))
            let upper = (airspace.upper == 0 ? "SFC" : (airspace.upper > 13000 ? "FL\(airspace.upper / 100)" : "\(airspace.upper)FT"))
            self.verticalLimitsLabel.text = "\(lower) - \(upper)"
            // Set Tint Color
            self.tintColor = airspace.color
            // Reload Cell
            self.setNeedsDisplay()
        }
    }
}

extension CGFloat {
    var radians: CGFloat { return self * .pi / 180 }
    var degrees: CGFloat { return self * 180 / .pi }
}
