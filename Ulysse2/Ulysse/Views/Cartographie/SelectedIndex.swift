//
//  SelectedIndex.swift
//  Ulysse
//
//  Created by Eric Duchenne on 13/07/2021.
//

import Foundation



/// Encapsulation des index pour la sélection des waypoints ou des segments
///
/// Autorise la modification des index dans la vue
/// - Remark : Permet de corriger le hack qui consistait à passer par une variable statique

class SelectedIndex {
   /// index du waypoint sélectionné. `nil` si pas de sélection active
   var waypoint : Int?

   /// index du segment sélectionné. `nil` si pas de sélection active
   var segment : Int?

   /// Initialisation : pas de sélection par défaut
   init() {}
}

