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

extension CGFloat {
    func deg2rad()->CGFloat {return DEG2RAD * self }
    func rad2deg()->CGFloat {return RAD2DEG * self }
}