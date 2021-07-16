//
//  ModelData.swift
//  Ulysse
//
//  Created by Eric Duchenne on 04/05/2021.
//

import Foundation
import CoreLocation
import Combine




/// Modèle des données de l'application
///
final class ModelData : ObservableObject {
   @Published var Region : String = "Atlantique"
   @Published var infoData : [[InformationDataSource]] = []
   @Published var navs : [Route] = LoadRouteLibrary()

   init() {

      // Les sauvegardes sont lues lors de l'initialisation. La mise à jour
    // du flux RSS a lieu lors de l'ouverture de la vue `AvurnavList`

      for region in Premar.allCases {
         var temp : [InformationDataSource] = []
        
         for category in typeInformation.allCases {
            temp.append(InformationDataSource(region: region, info: category))
            
            if let savedFeed = temp[category.rawValue].loadFromDisk() {
                temp[category.rawValue] = savedFeed
            }
         }

         infoData.append(temp)

//         async temp[0].downloadFeed()
//         async temp[1].downloadFeed()
//         async temp[2].downloadFeed()
//         wait infoData.append(temp)
      }
   }
}



func downloadAndDecodeRssFeed(_ filename: String) throws -> InformationDataSource {

   guard let file = URL(string:filename)
   else
   {  // URL invalide
      throw downloadError.invalidURL  
   }
   let decoder = InfoNavParser(contentsOf: file)!
   if(decoder.parse())
   {
      return decoder.infosSourceRead
   }
   else
   {  // Décodage de l'url impossible.   
      throw downloadError.invalidSyntax
   }
}

func LoadRouteLibrary() -> [Route]{
   let WPT1 = Waypoint(description: "YEU_1",
                    coord: CLLocationCoordinate2D(latitude: 46.3296666667, longitude: -1.435333))
   let WPT2 = Waypoint(description: "YEU_2",
                    coord: CLLocationCoordinate2D(latitude: 46.3296666667, longitude: -1.522))
   let WPT3 = Waypoint(description: "YEU_3",
                    coord: CLLocationCoordinate2D(latitude: 46.4083333333, longitude: -1.7146667))
   let WPT4 = Waypoint(description: "YEU_4",
                    coord: CLLocationCoordinate2D(latitude: 46.4746666667, longitude: -1.8763333333))

   let WPT5 = Waypoint(description: "YEU_5",
                    coord: CLLocationCoordinate2D(latitude: 46.6948333333, longitude: -2.27133333))
   let WPT6 = Waypoint(description: "YEU_6",
                    coord: CLLocationCoordinate2D(latitude: 46.7211666667, longitude: -2.2873333))
   let WPT7 = Waypoint(description: "YEU_7",
                    coord: CLLocationCoordinate2D(latitude: 46.7296666667, longitude: -2.346))
   let WPT_00 = Waypoint(description: "CHECK_46 30 N 002 00 W",
                         coord: CLLocationCoordinate2D(latitude: 46.5, longitude: -2))


   let r = Route(description: "La Tranche - Ile d'Yeu")
   r.appendWaypoint(WPT1)
   r.appendWaypoint(WPT2)
   r.appendWaypoint(WPT3)
   r.appendWaypoint(WPT4)
   r.appendWaypoint(WPT_00)
   r.appendWaypoint(WPT5)
   r.appendWaypoint(WPT6)
   r.appendWaypoint(WPT7)

   return ([r])

}

//#if DO_NOT_BUILD
//
///*
// Chargement d'un fichier au format JSON - Abandonné, pour une lecture et
// sauvegarde du fichier xml
// */
//func load<T: Decodable>(_ filename: String) -> T {
//   let data: Data
//
//   guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
//   else {
//      fatalError("Couldn't find \(filename) in main bundle.")
//   }
//
//   do {
//      data = try Data(contentsOf: file)
//   } catch {
//      fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
//   }
//
//   do {
//      let decoder = JSONDecoder()
//      return try decoder.decode(T.self, from: data)
//   } catch {
//      fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
//   }
//}
//
//#endif

