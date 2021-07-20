//
//  InfonavParser.swift
//  Ulysse
//
//  Created by Eric Duchenne on 13/07/2021.
//

import Foundation


/// Analyseur de flux RSS de la Premar

class  InfoNavParser: XMLParser {

   var latestPublishedItemDate : Date
   /// Initialisation
   override init(data: Data) {
      self.latestPublishedItemDate = .distantPast
      super.init(data: data)
      self.delegate = self
   }


   /// Liste les états de lecture du flux
   /// - `.inItem` : quand on est entre deux balises `<item>` et `</item>`
   /// - `.other` : dans tous les autres cas
   enum ReadStatus {
      case inItem
      case other
   }

   /// Objet recueillant les informations décodées du flux
   /// les informations 'region' et 'info' passées en initialisation sont
   /// sans importance, puisqu'elles ne sont pas utilisées
   /// - Todo : réfléchir à la façon de passer l'info de la région pour que l'id
   ///          comporte également cette information
   var infosSourceRead = InformationDataSource(region: .atlantique, info: .normal)

   private var curItem: InfoNavItem?

   /// tampon de lecture du flux
   private var textBuffer: String = ""


   let dateTimeZone = TimeZone.current
   /// La date de publication des informations est donnée dans un format américain
   /// que `pubDateFormmater` permet de décoder
   lazy var pubDateFormatter: DateFormatter = {
      let df = DateFormatter()
      df.locale = Locale(identifier: "en_US")
      df.dateFormat = "E, dd MMM y HH:mm:ss Z"
      df.timeZone = dateTimeZone
      return df
   }()


   /// Etat de lecture du flux
   var readStatus : ReadStatus = .other


   /// Les patterns Regex sont créés une seule fois, pour ne pas pénaliser le
   /// temps d'exécution

   /// pattern pour l'identifiant du message, consitué de deux groupes de chiffres
   /// séparés par un `/`
   let regexID = try! NSRegularExpression(pattern: #"\d+/\d+"#)
   /// Regex pour les coordonnées géographiques au format long
   let regexLong = try! NSRegularExpression(pattern: #"(\d+)[-\s]*(\d+)[\.,](\d+)'*\s*([NnSs])[,\s-]+(\d+)[-\s]*(\d+)[\.,](\d+)'*\s*([EeWw])"#)
   /// Regex pour les coordonnées géographiques au format court
   let regexCourt = try! NSRegularExpression(pattern: #"(\d+)[-\s]*(\d+)\s*([NnSs])[,\s-]+(\d+)[-\s]*(\d+)\s*([EeWw])"#)


   /// Recherche de coordonnées géographiques au format **long**
   /// - parameter s : chaîne de caractère dans laquelle chercher des coordonnées
   /// - parameter range : range de recherche
   /// - returns : un couple de coordonnées, ou `(nil, nil)` si pas trouvé
   ///
   /// Le pattern long est : dd-mm.ssN ddd-mm.ssW, avec des variations autour
   /// du point décimal, du séparateur de champ, et du nombre de décimales.
   /// Un espace peut aussi être présent avant la lettre d'hémisphère
   /// exemple : 46-30.5N 001-25.56W

   func searchLongFormatLatLon(s: String, range : NSRange) -> (Double?, Double?)
   {
      var latitude : Double?
      var longitude : Double?

      regexLong.enumerateMatches(in: s, options: [], range: range) {
         (match, _, stop) in guard let match = match else {return}

         if (match.numberOfRanges == 9) {
            let deglatRange = Range(match.range(at: 1), in:s)
            let minlatRange = Range(match.range(at: 2), in:s)
            let seclatRange = Range(match.range(at: 3), in:s)
            let hemlatRange = Range(match.range(at: 4), in:s)

            latitude = Double(s[deglatRange!])! +
               Double("\(s[minlatRange!]).\(s[seclatRange!])")! / 60.0

            let deglonRange = Range(match.range(at: 5), in:s)
            let minlonRange = Range(match.range(at: 6), in:s)
            let seclonRange = Range(match.range(at: 7), in:s)
            let hemlonRange = Range(match.range(at: 8), in:s)

            longitude = Double(s[deglonRange!])! +
               Double(s[minlonRange!] + "." + s[seclonRange!])!/60.0

            if(s[hemlatRange!].uppercased() == "S") { latitude = -latitude! }
            if(s[hemlonRange!].uppercased() == "W") { longitude = -longitude! }

            stop.pointee = true

         }
      }
      return (latitude, longitude)
   }

   /// Recherche de coordonnées géographiques au format **court**
   /// - parameter s : chaîne de caractère dans laquelle chercher des coordonnées
   /// - parameter range : range de recherche
   /// - returns : un couple de coordonnées, ou `(nil, nil)` si pas trouvé
   ///
   /// Le pattern long est : dd-mm.ssN ddd-mm.ssW, avec des variations autour
   /// du point décimal, du séparateur de champ, et du nombre de décimales
   /// exemple : 46-30.5N 001-25.56W

   func searchShortFormatLatLon(s: String, range : NSRange) -> (Double?, Double?)
   {
      var latitude : Double?
      var longitude : Double?

      regexCourt.enumerateMatches(in: s, options: [], range: range) {
         (match, _, stop) in guard let match = match else {return}

         if (match.numberOfRanges == 7) {
            let deglatRange = Range(match.range(at: 1), in:s)
            let minlatRange = Range(match.range(at: 2), in:s)

            let hemlatRange = Range(match.range(at: 3), in:s)
            latitude = Double(s[deglatRange!])! +
               Double(s[minlatRange!])! / 60.0
            let deglonRange = Range(match.range(at: 4), in:s)
            let minlonRange = Range(match.range(at: 5), in:s)

            let hemlonRange = Range(match.range(at: 6), in:s)
            longitude = Double(s[deglonRange!])! +
               Double(s[minlonRange!])!/60.0

            if(s[hemlatRange!].uppercased() == "S") { latitude = -latitude!}
            if(s[hemlonRange!].uppercased() == "W") { longitude = -longitude!}

            stop.pointee = true
         }
      }

      return (latitude, longitude)
   }


   /// Essaie de trouver la position géographique concernée par le message
   /// - Parameter s: texte dans lequel chercher les coordonnées
   /// - Returns:
   ///   - le couple (latitude, longitude) en degré
   ///   - (`nil`, `nil`) si la position n'a pas été trouvée

   func findPosition(s: String) -> (Double?, Double?) {
      var lat_D: Double?
      var lon_D: Double?

      // on cherche dans l'ensemble du texte.
      //      NB : ne fonctionne pas en prenant s.utf8.count alors que
      //           l'encodage est a priori en UTF8
      let range = NSRange(location: 0, length: s.utf16.count)

      // On recherche d'abord le format long des coordonnées
      (lat_D, lon_D) = searchLongFormatLatLon(s: s, range: range)
      if(lat_D, lon_D) != (nil, nil)
      {
         return (lat_D, lon_D)
      }
      // Si on n'a pas trouvé, on recherche en format court
      return searchShortFormatLatLon(s: s, range: range)
   }
}


/// Protocole XMLParserDelegate
extension InfoNavParser: XMLParserDelegate {

   // Appelé sur l'ouverture d'un tag (`<elementName>`)
   func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

      switch elementName {
      // on débute normalement le flux, on confirme ne pas être dans un item
      case "rss",
           "channel" :
         readStatus = .other

      // on entre dans un item, qu'on crée,  et on modifie le status
      case "item":
         readStatus = .inItem
         curItem = InfoNavItem()

      // on entre dans un champ de texte à récupérer, on vide le buffer
      case "title",
           "id",
           "link",
           "description",
           "pubDate",
           "category" :
         textBuffer = ""

      default:
         break
      }
   }

   // Appelé sur la fermeture d'un tag (`</elementName>`)
   func parser(_ parser: XMLParser, didEndElement elementName: String,
               namespaceURI: String?, qualifiedName qName: String?) {

      switch elementName
      {
      // `</item>`: on an récupéré toutes les infos du message,
      // on l'ajoute à `infoSourceRead`, et on passe à l'état `.other`
      case "item":
         if let navItem = curItem {
            infosSourceRead.items.append(navItem)
         }
         readStatus = .other

      // `<\title> : on ne s'intéresse qu'aux titre des items.
      // On le nettoie, et on extrait l'` id`du titre
      // TODO #3 : ajouter la région à l'`id`

      // ???  Est-ce utile si on extrait l'id dans la balise <id> ???????
      //
      case "title":
         switch readStatus {

         case .inItem:
            curItem?.title = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

            let range = NSRange(location: 0, length: textBuffer.count)
            if let result = regexID.firstMatch(in: textBuffer, options: [], range: range)
            {
               if let r = Range(result.range, in: textBuffer) {
                  curItem?.id = String(textBuffer[r])
               }
            }
         case .other:
            break
         }

      // ???? - Trancher sur la  source de l'id

      case "id":
         curItem?.id = textBuffer

      case "link":
         switch readStatus
         {
         case .inItem:
            curItem?.link = textBuffer

         case .other:
            break
         }

      case "description":
         switch readStatus
         {
         case .inItem:
            curItem?.details = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

            let (lat, lon) = findPosition(s:textBuffer)
            if(lat != nil && lon != nil) {
               curItem?.lat = lat!
               curItem?.lon = lon!
            }

         case .other:
            // ajouter la date de publication au flux
            infosSourceRead.sourceDescription = textBuffer
         }

      case "pubDate":
         let date = pubDateFormatter.date(from: textBuffer)
         switch readStatus
         {
         case .inItem:
            curItem?.pubDate = date!
            if(date! > latestPublishedItemDate) {
               latestPublishedItemDate = date!
            }

         case .other:
            infosSourceRead.publishedOn = date!
         }

      case "category":
         curItem?.category = textBuffer

      case "channel":
         if( infosSourceRead.publishedOn! < latestPublishedItemDate) {
            infosSourceRead.publishedOn = latestPublishedItemDate
         }
         latestPublishedItemDate = .distantPast

      default:
         break
      }
   }

   // Traite une suite de caractères rencontrée dans le flux
   // La suite de caractères 'foundCharacters`est ajoutée au tampon de lecture
   // du flux `textBuffer`.
   // `textBuffer` est vidé sur un tag ouvrant; au tag fermant, il contient le
   // texte encadré par les deux tags.

   func parser(_ parser: XMLParser, foundCharacters string: String) {
      textBuffer += string
   }


   // Traite un bloc CDATA

   func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
      guard let string = String(data: CDATABlock, encoding: .utf8) else {
         print("CDATA contains non-textual data, ignored")
         return
      }
      textBuffer += string
   }


   // Traitement des erreurs lors du décodage, essentiellement pour le débuggage

   func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
      print(parseError)
      print("on:", parser.lineNumber, "at:", parser.columnNumber)
   }
}
