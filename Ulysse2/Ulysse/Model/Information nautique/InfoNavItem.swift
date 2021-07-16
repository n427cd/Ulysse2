//
//  Avurnav.swift
//  Ulysse
//
//  Created by Eric Duchenne on 04/05/2021.
//

import Foundation
import SwiftUI
import CoreLocation

/// Contient le détail des informations nautiques émises par la Premar

class InfoNavItem : Equatable, Hashable, Codable, Identifiable {

   /// Opérateur `equal-to` pour le protocole `Equatable`
   ///
   /// Deux messages sont identiques s'il ont le même numéro et la mâme date de
   /// publication (car il semblerait que certains messages récurrents gardent
   /// le même numéro)
   ///
   /// -Todo: Il faudra sans doute inclure également la région dans l'ID,
   ///        car deux Prémar peuvent utiliser le même numéro

   static func == (lhs: InfoNavItem, rhs: InfoNavItem) -> Bool {
      return lhs.id == rhs.id && lhs.pubDate == rhs.pubDate
   }


   // Fonction de hashage pour le protocole `Hashable`


   func hash(into hasher: inout Hasher) {
      hasher.combine(id)
      hasher.combine(pubDate)
   }


   //BUG : la numérotation est donnée par Premar. Deux avis peuvent donc avoir le même numéro -> ajouter le code de la région à l'ID
   /// identifiant, tel que passé par le flux RSS
   var id : String = ""
   /// Titre de l'avis, fourni par le flux RSS
   var title : String = ""
   /// URL de l'avis sur le site de la Premar
   var link : String = ""
   /// détail de l'avis
   var details : String = ""
   /// date de publication
   var pubDate : Date = Date.init(timeIntervalSinceNow: 0)
   /// catégorie de l'avis
   var category : String = ""

   /// vrai si l'information ne figure pas dans les avis qui ont été sauvegardés
   var isNewItem = true

   /// Coordonnées estimées de l'avis
   var lat: Double = 0
   var lon: Double = 0
   var locationCoordinate : CLLocationCoordinate2D {
      CLLocationCoordinate2D(latitude: lat, longitude: lon)
   }
   /// vrai si le message fait partie des favoris
   var isPinned : Bool = false

   /// 
   private var imageName: String = ""
   var image: Image {
      Image(imageName)
   }

   //TODO: implementer un getter et setter de isNew
   func setNew(_ flag : Bool) { isNewItem = flag }
}






