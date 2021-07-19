//
//  ModelData.swift
//  Ulysse
//
//  Created by Eric Duchenne on 04/05/2021.
//

import CoreLocation


/// Interrupteur commandant la montée de version des schémas d'enregistrement
/// des fichiers de sauvegarde
let SCHEMA_UPGRADE = false


/// Modèle des données de l'application

final class ModelData : ObservableObject {
   @Published var Region : String = "Atlantique"
   @Published var infoData : [[InformationDataSource]] = []
   @Published var navs : [Route] = LoadRouteLibrary()


   /// Nettoyage des fichiers de sauvegarde des infos aux navigateurs
   ///
   /// - Attention : ne doit être appelée que lors des montées de version du
   ///               schéma d'enregistrement, activées en passant `SCHEMA_UPGRADE`
   ///               à `true`

   func cleanDirectoryForSchemaUpgrade() {
      assert(SCHEMA_UPGRADE == false, "Montée de version activé. Vérifier")
      if (SCHEMA_UPGRADE == false) { return }

      let fileManager = FileManager.default
      let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)

      for region in Premar.allCases {
         var urlRegionName : String
         switch region {
         case .atlantique :  urlRegionName = "A"
         case .manche :  urlRegionName = "B"
         case .mediterranee : urlRegionName = "C"
         }
         for type in TypeInformation.allCases {
            var infoName : String
            switch type {
            case .urgent : infoName = "U"
            case .normal : infoName = "N"
            case .rade : infoName = "R"
            }

            let path = "infonav\(urlRegionName)\(infoName).data"
            do {
               print ("Deleting \(path)")
               try fileManager.removeItem(at: docsDir[0].appendingPathComponent(path))
            } catch {}
         }
      }
   }


   /// Initialisation du Model Data
   ///
   /// Récupère les flux d'information
   ///
   /// - note : la maintenance des fichiers peut être effectuée en agissant
   /// sur l'interrupteur `SCHEMA_UPGRADE` qui doit normalement rester sur la
   /// valeur `false`

   init() {

      // Si nécessaire, effacer les fichiers

      cleanDirectoryForSchemaUpgrade()

      // Les sauvegardes sont lues lors de l'initialisation. La mise à jour
      // du flux RSS a lieu lors de l'ouverture de la vue `AvurnavList`

      for region in Premar.allCases {
         var temp : [InformationDataSource] = []
        
         for category in TypeInformation.allCases {
            temp.append(InformationDataSource(region: region, info: category))
            
            if let savedFeed = temp[category.rawValue].loadFromDisk() {
                temp[category.rawValue] = savedFeed
            }
         }

         infoData.append(temp)
      }
   }
}


/// Télécharge et décode le flux RSS
/// - parameter urlName : url du flux à télécharger
/// - returns : le flux décodé dans un `InformationDataSource`
/// - throws  :
///   - `downloadError.invalidURL`   si l'url passée n'est pas correcte
///   - `downloadError.invalidSyntax`  si le décodage n'est pas possible
func downloadAndDecodeRssFeed(_ urlName: String) throws -> InformationDataSource {

   guard let file = URL(string:urlName)
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

