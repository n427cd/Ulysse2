//
//  AvurnavDetail.swift
//  Ulysse
//
//  Created by Eric Duchenne on 04/05/2021.
//

import SwiftUI
import MapKit


///TODO: #16 des commentaires !

struct AvurnavDetail: View {
   @EnvironmentObject var modelData : ModelData
   @ObservedObject var avurnav : InfoNavItem
   var region : Premar
   var info : typeInformation
   var isFirstAppear = true
   var avurnavIndex : Int {
      modelData.infoData[region.rawValue][info.rawValue].items.firstIndex(where : {$0.id == avurnav.id }) ?? 0
   }
   
   func qualificatif(_ type : typeInformation)->String
   {
      switch type
      {
      case .urgent : return "urgent"
      case .normal : return ""
      case .rade :   return "rade"
      }
   }
   
   var avurnavNumber : String {
      return modelData.Region + " — Avis \(qualificatif(info)) n° " + avurnav.id
   }
   
   static let pubDateFormat : DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateStyle = .short
      return formatter
   }()
   
   static let RelFormatter : RelativeDateTimeFormatter = {
      let formatter = RelativeDateTimeFormatter()
      formatter.locale = NSLocale.current
      formatter.unitsStyle = .full
      
      return formatter
   }()
   
   
   var body: some View {
      
      ScannedMapView(mapCenter: avurnav.locationCoordinate)
         .frame(height:300)
      ScrollView {
         VStack(alignment: .leading) {
            HStack {
               Text(avurnav.title)
                  .font(.title2)
               PinButton(isSet: $modelData.infoData[region.rawValue][info.rawValue].items[avurnavIndex].isPinned)
            }
            HStack {
               Text("\(avurnav.pubDate, formatter: Self.RelFormatter)")
               Spacer()
               VStack {
                  Text(avurnav.category)
               }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            Divider()
            
            Text(avurnav.details)
               .font(.body)
            
            Spacer()
               .frame(height: 50.0)
            
            Link("consulter le site de la Premar", destination: URL(string: avurnav.link)!)
               .font(.body)
         }
         .padding()
      }
      .navigationTitle(avurnavNumber)
      .navigationBarTitleDisplayMode(.inline)
      .onAppear() {
         if avurnav.isUnread {
            
            //BUGFIX : résoud le problème de mise à jour des `AvurnavRow`
            avurnav.objectWillChange.send()
            
            avurnav.isUnread = false
         }
      }
   }
   }
  



#if DO_NOT_BUILD
struct AvurnavDetail_Previews: PreviewProvider {
   static var previews: some View {
      AvurnavDetail(avurnav : ModelData().avurnavs[0])
   }
}
#endif
