//
//  Route.swift
//  Ulysse
//
//  Created by Eric Duchenne on 15/06/2021.
//

import Foundation
import CoreLocation


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
