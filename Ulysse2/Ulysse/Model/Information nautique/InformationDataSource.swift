//
//  InformationDataSource.swift
//  Ulysse
//
//  Created by Eric Duchenne on 13/07/2021.
//

import Foundation

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

enum TypeInformation : Int, CaseIterable, Codable {
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
   /// Type des informations téléchargées (avinav, avurnav, ...)
   var nature : TypeInformation
   /// Date de publication par le propriétaire des données
   var publishedOn : Date?
   /// Date du dernier chargement avec nouvelle entrée
   var lastModifiedOn : Date?
   /// Date de la dernière interrogation du serveur
   var lastCheckedServer : Date?
   /// liste des messages
   var items : [InfoNavItem]
   /// Description du flux
   var sourceDescription : String = ""


   /// L'initialisation de la source d'information consiste à définir la Premar
   /// et le type de messages

   init(region : Premar, info : TypeInformation) {
      self.region = region
      self.nature = info
      items = []
   }


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


   /// Vérifie si la sauvegarde locale est ancienne par rapport au flux RSS

   fileprivate func isBackupOld(_ webFeed: InformationDataSource, _ now: Date) -> Bool {
      // Parfois la date de publication du flux
      // n'est pas mise à jour par la premar. On regarde
      // donc si la date du flux n'est pas trop vieille

      return webFeed.publishedOn != nil  &&
         ((publishedOn! < webFeed.publishedOn!) ||
            publishedOn!.addingTimeInterval(INTERVAL_24HOURS) < now)
   }


   /// Met à jour la sauvegarde locale

   fileprivate func updateBackup(timestamp now: Date) {
      saveOnDisk()
      lastModifiedOn = now
   }


   /// copie les données générales (`publishedOn` et `sourceDescription`) à
   /// partir des mêmes informations disponibles sur la source `from`
   /// - parameter webFeed : `InformationDataSource` source pour la copie

   fileprivate func copyGeneralData(from webFeed: InformationDataSource) {
      publishedOn = webFeed.publishedOn
      sourceDescription = webFeed.sourceDescription
   }


   /// met à jour les avis aux navigateurs, en assurant la fusion entre les
   /// anciennes données et le flux du web
   fileprivate func updateItemsFromWebFeed(_ webFeed : InformationDataSource) -> (Bool, [InfoNavItem]) {
      let flux = Set<InfoNavItem>(webFeed.items)

      // création de ce Set pour récupérer les items actuels plutôt que ceux
      // du flux dont le statut `isUnread` n'est pas à jour
      let currentdata = Set<InfoNavItem>(items)

      let newItems = flux.subtracting(self.items)
      let oldItems = currentdata.intersection(flux)

      let previousCount = items.count

      for item in oldItems { item.setNew(false) }

      return ((newItems.count > 0 || oldItems.count !=  previousCount),
              Array(newItems) + Array(oldItems))
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
      /// tri des `InfoNavItem` par date de publication, puis par identifiant
      let navItemsSort : (_ a : InfoNavItem, _ b : InfoNavItem)->Bool = {
         ($0.pubDate > $1.pubDate) ||
            ($0.pubDate == $1.pubDate && $0.id > $1.id) }

      // On tente de récupérer la sauvegarde si elle existe.
      // Si on vient de lancer l'application, on remplace self.items qui est
      // vide ou nil par les informations sauvegardées.
      // Si l'application était déjà chargée, on remplace les informations par
      // elles-mêmes, ce qui en terme d'efficacité n'est pas forcément bon, mais...

      //TODO: #4 voir si on peut éviter le manque d'efficacité

      var backupExists = false

      if let savedFeed = loadFromDisk()
      {
         backupExists = true
         copyGeneralData(from:savedFeed)
         items = savedFeed.items.sorted(by:navItemsSort)
      }

      // on télécharge les informations à partir du flux RSS

      do {
         let now = Date()

         let webFeed = try downloadAndDecodeRssFeed(sourceURL())
         lastCheckedServer = now

         if(backupExists)
         {
            if(isBackupOld(webFeed, now))
            {
               let shouldUpdateBackup : Bool

               (shouldUpdateBackup,items) = updateItemsFromWebFeed(webFeed)
               items.sort(by: navItemsSort)

               copyGeneralData(from:webFeed)

               // on sauvegarde si la liste des messages a évolué
               if (shouldUpdateBackup) {
                  updateBackup(timestamp: now)
               }
            }

            // Là, on a une sauvegarde qui est bonne, on ne change rien

         }
         else {
            // Si on n'a pas de sauvegarde, on récupère ce qui provient du flux
            // sauf si on n'a pas de flux...

            items = webFeed.items.sorted(by: navItemsSort)

            copyGeneralData(from: webFeed)
            updateBackup(timestamp: now)
         }
      }
      catch downloadError.invalidURL {}
      catch downloadError.invalidSyntax {}
      catch {}

   }

   /// récupère l'URL du fichier de sauvegarde du flux
   /// - returns : un couple avec le `FileManager` et l'URL

   fileprivate func getFile() -> (FileManager, URL)
   {
      let fileManager = FileManager.default
      let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
      return (fileManager, docsDir[0].appendingPathComponent(localURL()))
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
      let (fileManager, fileName) = getFile()

      if(fileManager.fileExists(atPath: fileName.path))
      {
         do
         {
            let data = try Data(contentsOf: fileName)
            let decoder = JSONDecoder()
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
      let (fileManager, fileName) = getFile()

      do
      {
         let encoder = JSONEncoder()
         encoder.outputFormatting = .sortedKeys

         let data = try encoder.encode(self)

         fileManager.createFile(atPath: fileName.path, contents: data, attributes: nil)
         
         print("Enregistrement de \(fileName.path)")
      }
      catch
      {
         print("\(error) Problème de sauvegarde des avis à la navigation")
      }
   }
}
