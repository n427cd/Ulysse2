//
//  Waypoint.swift
//  Ulysse
//
//  Created by Eric Duchenne on 13/07/2021.
//

import Foundation
import CoreGraphics
import CoreLocation


/// La classe Waypoint implémente des points géographiques et les opérations
/// usuelles sur ces objets

class Waypoint : Identifiable {
   static func == (lhs: Waypoint, rhs: Waypoint) -> Bool {
      (lhs.coord.latitude == rhs.coord.latitude) &&
         (lhs.coord.longitude == rhs.coord.latitude)
   }
   var id = UUID()
   var description : String = "WPT"
   var coord = CLLocationCoordinate2D(latitude:0, longitude:0)

   var LC : CGFloat { log(tan(CGFloat(coord.latitude).deg2rad()/2 + .pi / 4 ))}


   /// Initialisation du `Waypoint`
   /// - parameter description : nom du waypoint
   /// - parameter coord : coordonnées géographiques du waypoint

   init(description: String, coord: CLLocationCoordinate2D) {
      self.description = description
      self.coord = coord
   }


   /// Calcul de la route vraie entre deux Waypoint
   /// - parameter to: Waypoint de destination
   /// - returns : route vraie en degrés 0 < .. ≤ 360

   func trueCourse(to : Waypoint) -> CGFloat {
      let t =  atan2(CGFloat((to.coord.longitude - coord.longitude)).deg2rad() ,
                     (to.LC - LC)).rad2deg()
      if(t <= 0) { return t+360 }
      if(t > 360 ) { return t-360}
      return t
   }


   /// Calcul de la distance loxodromique entre deux waypoints
   /// - parameter to: waypoint auquel on calcule la distance
   /// - returns : distance en mille nautique
   /// - source : Ed William's aviation formulary
   func distance(to: Waypoint) -> CGFloat {
      let dL = CGFloat(to.coord.latitude - coord.latitude)
      let dg = CGFloat(to.coord.longitude - coord.longitude)

      if(abs(dL) < EPSILON)
      {
         return 60 * abs(dg) * cos(CGFloat(coord.latitude).deg2rad())
      }
      else {
         let q = dL.deg2rad() / (to.LC - LC)
         return 60 * sqrt(dL * dL + q * q * dg * dg )
      }
   }
}
