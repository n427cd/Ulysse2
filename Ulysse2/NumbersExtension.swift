//
//  NumbersExtension.swift
//  Ulysse
//
//  Created by Isa on 24/06/2021.
//

import Foundation
import CoreGraphics

let DEG2RAD : CGFloat = .pi / 180
let RAD2DEG : CGFloat = 180 / .pi
let EPSILON : CGFloat = 1e-6

let INTERVAL_24HOURS : Double = 86400

extension CGFloat {
    func deg2rad()->CGFloat {return DEG2RAD * self }
    func rad2deg()->CGFloat {return RAD2DEG * self }
}


extension CGPoint {
   @inlinable func squaredDist(to p : CGPoint)->CGFloat { return (self.x - p.x) * (self.x - p.x) + (self.y - p.y) * (self.y - p.y)}
   @inlinable func distance(to p : CGPoint)->CGFloat { return sqrt((self.x - p.x) * (self.x - p.x) + (self.y - p.y) * (self.y - p.y))}

}
