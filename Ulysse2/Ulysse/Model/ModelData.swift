//
//  ModelData.swift
//  Ulysse
//
//  Created by Eric Duchenne on 04/05/2021.
//

import Foundation
import CoreLocation
import Combine


/// liste des préfectures maritimes
///
/// `.atlantique` : Premar atlantique
/// `.manche` : Premar Manche et Mer du nord
/// `.mediterranee` = Premar Méditerranée
enum Premar : Int, CaseIterable, Codable {
   case atlantique
   case manche
   case mediterranee
}


/// nature des avis à la navigation
///
/// `.urgent` : avurnavs
/// `.normal` : avinavs
/// `.rade` : avirade
enum typeInformation : Int, CaseIterable, Codable {
   case urgent
   case normal
   case rade
}


/// erreurs au téléchargement du flux
///
/// `.invalidURL`: l'URL de téléchargement n'est pas correcte
/// `.invalidSyntax` : le décodage du flux a échoué
enum downloadError : Error
{
   case invalidURL
   case invalidSyntax
}


/// Source d'information pour les informations aux navigateurs
/// Englobe toutes les opérations nécessaires à la récupération des informations,
/// leur sauvegarde, mise à jour, etc.

class InformationDataSource : Codable {
   /// Premar émettant les informations
   var region : Premar

   /// URL de la source de données
   func sourceURL() -> String {
      var urlRegionName : String
      switch self.region {
      case .atlantique :  urlRegionName = "atlantique"
      case .manche :  urlRegionName = "manche"
      case .mediterranee : urlRegionName = "mediterranee"
      }

      var infoName : String
      switch self.nature {
      case .urgent : infoName = "AVURNAV"
      case .normal : infoName = "AVINAV"
      case .rade : infoName = "AVIRADE"
      }

      return "https://www.premar-\(urlRegionName).gouv.fr/avis/rss/\(infoName)?format=rss"
   }

   /// URL de la sauvegarde locale de la source de données
   func localURL() -> String {

      var urlRegionName : String
      switch self.region {
      case .atlantique :  urlRegionName = "A"
      case .manche :  urlRegionName = "B"
      case .mediterranee : urlRegionName = "C"
      }

      var infoName : String
      switch self.nature {
      case .urgent : infoName = "U"
      case .normal : infoName = "N"
      case .rade : infoName = "R"
      }

      return "infonav\(urlRegionName)\(infoName).data"
   }


   /// Date de publication par le propriétaire des données
   var publishedOn : Date? //= nil
   /// Date du dernier chargement avec nouvelle entrée
   var lastModifiedOn : Date?// = nil
   /// Date de la dernière interrogation du serveur
   var lastCheckedServer : Date?// = nil
   /// Type des informations téléchargées (avinav, avurnav, ...)
   var nature : typeInformation
   /// liste des messages
   var items : [InfoNavItem]
   /// Description du flux
   var sourceDescription : String = ""
   

   /// L'initialisation de la source d'information consiste à définir la Premar 
   /// et le type de messages 
   init(region : Premar, info : typeInformation) {
      self.region = region
      self.nature = info
      items = []
   }



   /// Téléchargement du flux RSS
   ///
   /// Le flux RSS correpondant à la région et à la nature des messages est
   /// téléchargé. S'il y a de nouvelles modifications, la date `lastModifiedOn`
   /// est mise à jour.
   /// Dans tous les cas, la date `lastCheckedServer` est mise à jour et peut
   /// servir de repère pour déclencher une vérification ultérieure du serveur
   ///
   /// - Postcondition :
   /// `self.items` contient la liste à jour des informations.
   /// Les nouveaux messages sont indiqués `isNewItem = true`
   ///
   /// Je n'ai pas trouvé de moyen pour vérifier simplement s'il y a des données
   /// nouvelles sans télécharger intégralement le flux RSS
   ///

   func downloadFeed()
   {
      let now = Date()

      // On tente de récupérer la sauvegarde si elle existe.
      // Si on vient de lancer l'application, on remplace self.items qui est
      // vide ou nil par les informations sauvegardées.
      // Si l'application était déjç chargée, on remplace les oinformations par
      // elles-mêmes, ce qui en terme d'efficacité n'est pas forcément bon, mais...

      //TODO: voir si on peut éviter le manque d'efficacité

      var hasBackup = false

      if let savedFeed = loadFromDisk()
      {
         publishedOn = savedFeed.publishedOn
         items = savedFeed.items
         hasBackup = true
      }

      // on télécharge les informations à partir du flux RSS

      do {
         let webFeed = try downloadAndDecodeRssFeed(sourceURL())

         lastCheckedServer = now

         ///TODO #1 : vérifier la date de publication du feed et simplement
         ///       mettre à jour `lastCheckedServer` si le feed n'a pas été maj

         if(hasBackup)
         {
            if(webFeed.publishedOn != nil  &&
                  ((publishedOn! < webFeed.publishedOn!) ||
                    publishedOn!.addingTimeInterval(86400) < now))
            {
               // La version sauvegardée est plus ancienne,
               // On la remplace par le flux qui vient d'être
               // téléchargé
               // Parfois la date de publication du flux
               // n'est pas mise à jour par la premar. On regarde
                // donc si la date du flux n'est pas trop vieille
                // (86400 = 1 journée)

               publishedOn = webFeed.publishedOn
               sourceDescription = webFeed.sourceDescription

               let flux = Set<InfoNavItem>(webFeed.items)

               let newItems = flux.subtracting(self.items)
               let oldItems = flux.intersection(self.items)
               let previousCount = items.count

               for item in oldItems { item.setNew(false) }
               items = (Array(newItems) + Array(oldItems)).sorted(by:{                                                                     ($0.pubDate > $1.pubDate)})// || ($0.pubDate == $1.pubDate && $0.id > $1.id) })

               // on sauvegarde si la liste des messages a évolué
               if (newItems.count > 0 || oldItems.count !=  previousCount) {
                  saveOnDisk()
                  lastModifiedOn = now
               }
            }

            // Là, on a une sauvegarde qui est bonne, on ne change rien

         }
         else {
            // Si on n'a pas de sauvegarde, on récupère ce qui provient du flux
            // sauf si on n'a pas de flux...
            //if( tempFeed != nil) {
               publishedOn = webFeed.publishedOn
               sourceDescription = webFeed.sourceDescription
            items = webFeed.items.sorted(by: {                                                                     ($0.pubDate > $1.pubDate) || ($0.pubDate == $1.pubDate && $0.id > $1.id) })
               saveOnDisk()
               lastModifiedOn = now
            //}
         }
      }
      catch downloadError.invalidURL {}
      catch downloadError.invalidSyntax {}
      catch {}

      //for i in items { print("\(i.title)")}
   }


   /// chargement des informations à partir du disque, afin d'avoir des données
   /// offline.
   ///
   /// Le fichier est sauvegardé au format JSON dans le répertoire correspondant
   /// à `.documentDirectory`, sous le nom `infonav(A|B|C)(U|N|R).data` selon la
   /// région et la nature des infos.
   ///
   /// - returns : l'`InformationDataSource` sauvegardée, ou `nil` si le fichier
   ///             n'existe pas

   func loadFromDisk() -> InformationDataSource? {
      let fileManager = FileManager.default
      let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
      let fileName = docsDir[0].appendingPathComponent(localURL())

      let decoder = JSONDecoder()

      if(fileManager.fileExists(atPath: fileName.path))
      {
         do
         {
            let data = try Data(contentsOf: fileName)
            return try decoder.decode(InformationDataSource.self, from: data)
         }
         catch
         {
            print("\(error) Problème de sauvegarde des avis à la navigation")
            return nil
         }
      }
      else
      {
         return nil
      }
   }


   /// Sauvegarde des informations sur disque pour accès offline
   ///
   /// Le fichier est sauvegardé au format JSON dans le répertoire correspondant
   /// à `.documentDirectory`, sous le nom `infonav(A|B|C)(U|N|R).data` selon la
   /// région et la nature des infos.

   func saveOnDisk() {
      let fileManager = FileManager.default
      let localDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
      let fileName = localDir[0].appendingPathComponent(localURL())

      let encoder = JSONEncoder()
      encoder.outputFormatting = .sortedKeys
      do 
      {
         let data = try encoder.encode(self)
         fileManager.createFile(atPath: fileName.path, contents: data, attributes: nil)
      }
      catch
      {
         print("\(error) Problème de sauvegarde des avis à la navigation")
      }
   }
}

/// Modèle des données de l'application
///
final class ModelData : ObservableObject {
   @Published var Region : String = "Atlantique"
   @Published var infoData : [[InformationDataSource]] = []
   @Published var navs : [Route] = LoadRouteLibrary()

   init() {

      // Téléchargement des informations aux navigateurs

      for region in Premar.allCases {
         var temp : [InformationDataSource] = []
         for category in typeInformation.allCases {
            temp.append(InformationDataSource(region: region, info: category))
            temp[category.rawValue].downloadFeed()
         }

         infoData.append(temp)

//         async temp[0].downloadFeed()
//         async temp[1].downloadFeed()
//         async temp[2].downloadFeed()
//         wait infoData.append(temp)
      }

      // Bidon, pour essai seulement
      // >>>>>
      infoData[0][0].downloadFeed()
      // <<<<<
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

