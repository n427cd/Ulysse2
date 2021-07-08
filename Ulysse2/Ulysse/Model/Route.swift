//
//  Route.swift
//  Ulysse
//
//  Created by Eric Duchenne on 15/06/2021.
//

import Foundation
import CoreLocation
import CoreGraphics


/// La classe Waypoint implémente des points géographiques et les opérations usuelles sur ces objets

class Waypoint : Identifiable {
      static func == (lhs: Waypoint, rhs: Waypoint) -> Bool {
         (lhs.coord.latitude == rhs.coord.latitude) &&
            (lhs.coord.longitude == rhs.coord.latitude)
      }
   var id = UUID()
   var description : String = "WPT"
   var coord = CLLocationCoordinate2D(latitude:0, longitude:0)

   var LC : CGFloat { log(tan(CGFloat(coord.latitude).deg2rad()/2 + .pi / 4 ))}

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


   /// Calcul de la distance loxodromique aentre deux Waypoint
   /// - parameter to: Waypoint duquel on détermine la distance
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


/// La classe Route décrit et gère la séquence de Waypoints qui constitue une
/// navigation.

class Route : Identifiable {
   var id = UUID()
   var description : String = "Route"

   /// Liste des waypoints, extrémités successives des segments
   var segments : [Waypoint] = []

   init(description : String) {
      self.description = description
      segments = []
   }

   //TODO:  ajouter un boundingRect (structure à identifier pour être compatible
   //       avec d'autres modules. Attention : rectangle géographique différent
   //       du rectangle cartographique (latitude <> latitude croissante)


   /// centre géographique de la route
   var center : CLLocationCoordinate2D {
      var minX : CLLocationDegrees = CLLocationDegrees.infinity
      var maxX = -minX
      var minY = minX
      var maxY = -minX

      for w in segments {
         minX = min(minX, w.coord.longitude)
         maxX = max(maxX, w.coord.longitude)
         minY = min(minY, w.coord.latitude)
         maxY = max(maxY, w.coord.latitude)
      }

      return CLLocationCoordinate2D(latitude: (minY + maxY) / 2,
                                    longitude: (minX + maxX) / 2)
   }


   /// Ajoute un Waypoint à la fin de la route
   /// - parameter waypoint : waypoint à ajouter
   /// - returns : void

   func appendWaypoint(_ waypoint : Waypoint)->() {
      segments.append(waypoint)
   }


   /// Insère un Waypoint dans la route
   /// - parameter  waypoint : waypoint à ajouter
   /// - parameter pos : position à laquelle waypoint sera inséré
   /// - returns : void
   /// - important : il n'y a pas de contrôle de validité de pos

   func insertWaypoint(_ waypoint : Waypoint, at pos : Int) -> () {
      segments.insert(waypoint, at: pos)
   }


   /// Retire un Waypoint de la route
   /// - parameter pos : position dans la séquence segments du waypoint qui sera retiré.
   /// Elle doit correspondre à un indice valide de la séquence, et ne peut pas être égale au nombre d'éléments de la séquence
   /// - returns : le Waypoint retiré
   /// - excerpt : sdgfsdf

   func removeWaypoint(at pos: Int) -> Waypoint {
      segments.remove(at: pos)
   }
}
