//
//  WeatherData.swift
//  Ulysse
//
//  Created by Eric Duchenne on 01/07/2021.
//

import Foundation

/*
"/meteo-marine/agde-palavas/MICROZONE-26", Agde Palavas
"/meteo-marine/albatre/MICROZONE-03", Albatre
"/meteo-marine/antibes-menton/MICROZONE-36", Antibes - Menton
"/meteo-marine/argeles-leucate/MICROZONE-23", Argeles leucate
"/meteo-marine/baie-de-seine/MICROZONE-05", Baie de seine
"/meteo-marine/bassurelle/MICROZONE-02", Bassurelle
"/meteo-marine/bastia-solenzara/MICROZONE-39", Bastia - Solenzara<
"/meteo-marine/bouches-de-bonifacio/MICROZONE-42", Bouches de Bonifacio
"/meteo-marine/camarat-saint-raphael/MICROZONE-34", Camarat - Saint-Raphaël
"/meteo-marine/cap-bear/MICROZONE-22", Cap Bear
"/meteo-marine/cap-corse/MICROZONE-37", Cap Corse
"/meteo-marine/cap-corse-bastia/MICROZONE-38", Cap Corse - Bastia
"/meteo-marine/cap-sicie/MICROZONE-31", Cap Sicie
"/meteo-marine/charente/MICROZONE-16", Charente
"/meteo-marine/chiappa-st-amanza/MICROZONE-41", Chiappa - St Amanza
"/meteo-marine/cote-vendeenne/MICROZONE-15", Côte vendéenne
"/meteo-marine/estuaire-loire/MICROZONE-14", Estuaire Loire
"/meteo-marine/fos-marseille/MICROZONE-29", Fos - Marseille
"/meteo-marine/gironde-nord/MICROZONE-17", Gironde nord
"/meteo-marine/gironde-sud/MICROZONE-18", Gironde sud
"/meteo-marine/groix-belle-ile/MICROZONE-13", Groix - Belle-Île
"/meteo-marine/gruissan-agde/MICROZONE-25", Gruissan Agde
"/meteo-marine/landes-nord/MICROZONE-19", Landes nord
"/meteo-marine/landes-sud/MICROZONE-20", Landes sud
"/meteo-marine/leucate-gruissan/MICROZONE-24", Leucate Gruissan
"/meteo-marine/marseille-la-ciotat/MICROZONE-30", Marseille - La Ciotat
"/meteo-marine/mer-d-iroise/MICROZONE-11", Mer d'Iroise
"/meteo-marine/minquiers/MICROZONE-08", Minquiers
"/meteo-marine/nord-cotentin/MICROZONE-06", Nord Cotentin
"/meteo-marine/nord-finistere/MICROZONE-10", Nord Finistère
"/meteo-marine/ouest-cotentin/MICROZONE-07", Ouest Cotentin
"/meteo-marine/palavas-port-camargue/MICROZONE-27", Palavas - Port-Camargue
"/meteo-marine/pays-basque/MICROZONE-21", Pays basque
"/meteo-marine/pointe-de-caux/MICROZONE-04", Pointe de Caux
"/meteo-marine/porquerolles/MICROZONE-32", Porquerolles
"/meteo-marine/port-camargue-fos/MICROZONE-28", Port-Camargue - Fos
"/meteo-marine/port-cros-camarat/MICROZONE-33", Port-Cros - Camarat
"/meteo-marine/revellata-centuri/MICROZONE-46", Revellata - Centuri
"/meteo-marine/roches-douvres/MICROZONE-09", Roches-Douvres
"/meteo-marine/saint-raphael-antibes/MICROZONE-35", Saint-Raphaël - Antibes
"/meteo-marine/sandettie/MICROZONE-01", Sandettie
"/meteo-marine/scandola-revellata/MICROZONE-45", Scandola - Revellata
"/meteo-marine/senetosa-scandola/MICROZONE-44", Senetosa - Scandola
"/meteo-marine/solenzara-chiappa/MICROZONE-40", Solenzara - Chiappa
"/meteo-marine/sud-finistere/MICROZONE-12", Sud Finistère
"/meteo-marine/ventilegne-senetosa/MICROZONE-43", Ventilegne - Senetosa
*/


class WeatherData : NSObject {

}

extension WeatherData: XMLParserDelegate {

   // Called when opening tag (`<elementName>`) is found
   func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

      switch elementName {
      case "div" : print()
         //if( attr)
      case "titrebulletin" : print()
      case "chapeaubulletin" :print()
      case "unitebulletin" :print()
      case "bulletinspecial" :print()
      case "echeance" :print()
      case "titreecheance" :print()
      case "region" :print()
      case "situation" :print()
      case "piedbulletin" :print()

      default:
         print("Ignoring \(elementName)")
      }
   }

   // Called when closing tag (`</elementName>`) is found
   func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

      //print ("</\(elementName)>, bInItem : \(bInItem)")
      switch elementName {
      case "div" :print()
      case "titrebulletin" :print()
      case "chapeaubulletin" :print()
      case "unitebulletin" :print()
      case "bulletinspecial" :print()
      case "echeance" :print()
      case "titreecheance" :print()
      case "region" :print()
      case "situation" :print()
      case "piedbulletin" :print()

      default:
         print("Ignoring \(elementName)")
      }
 /*     switch elementName {
      case "item":
         if let navItem = nextAvurnav {
            itemsRead.items.append(navItem)
         }
         self.bInItem = false

      case "title":
         if (self.bInItem)
         {
            nextAvurnav?.title = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            let range = NSRange(location: 0, length: textBuffer.count)
            let result = regexID.firstMatch(in: textBuffer, options: [], range: range)

            let r = Range(result!.range, in: textBuffer)

            nextAvurnav?.id = String(textBuffer[r!])

            //print(nextAvurnav!.id)
         }

      case "id":
         nextAvurnav?.id = textBuffer

      case "link":
         if (self.bInItem)
         {
            nextAvurnav?.link = textBuffer
         }

      case "description":
         if (self.bInItem)
         {
            nextAvurnav?.description = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

            let (lat, lon) = findPosition(s:textBuffer)
            if(lat != nil && lon != nil) {
               nextAvurnav?.lat = lat!
               nextAvurnav?.lon = lon!
            }
         }
         else {
            // ajouter la date de publicatino au flux
            itemsRead.description = textBuffer
         }

      case "pubDate":
         if (self.bInItem)
         {
            nextAvurnav?.pubDate = (dateFormater.date(from: textBuffer))!
         }
         else
         {
            // DONE: Ajouter la date de publication au flux
            //print("pubdate: \(textBuffer)")
            itemsRead.publishedOn = (dateFormater.date(from: textBuffer))!
         }
      case "category":
         nextAvurnav?.category = textBuffer


      default:
         //print("Ignoring \(elementName)")
         break
      }
 */
   }

   // Called when a character sequence is found
   // This may be called multiple times in a single element
   func parser(_ parser: XMLParser, foundCharacters string: String) {
     // textBuffer += string
   }

   // Called when a CDATA block is found
   func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
      guard let string = String(data: CDATABlock, encoding: .utf8) else {
         print("CDATA contains non-textual data, ignored")
         return
      }
      //textBuffer += string
   }

   // For debugging
   func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
      print(parseError)
      print("on:", parser.lineNumber, "at:", parser.columnNumber)
   }
}




