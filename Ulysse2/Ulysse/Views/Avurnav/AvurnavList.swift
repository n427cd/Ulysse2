//
//  AvurnavList.swift
//  Ulysse
//
//  Created by Eric Duchenne on 04/05/2021.
//

import SwiftUI



struct AvurnavList: View {
   @EnvironmentObject var modelData : ModelData
   @State private var showPinnedOnly = false

   var region : Premar
   var info : typeInformation

   var descriptionInfo : String {
      switch info {
      case .urgent : return "urgents "
      case .normal : return ""
      case .rade : return "rade "
      }
   }

   var shortDescription : String {
      switch info {
      case .urgent : return "AVURNAV"
      case .normal : return "AVINAV"
      case .rade : return "AVIRADE"
      }
   }

   var filteredAvurnavs:[InfoNavItem] {
      modelData.infoData[region.rawValue][info.rawValue].items.filter {
         avurnav in (!showPinnedOnly || avurnav.isPinned)
      }
   }

   init(region : Premar, info : typeInformation)
   {
      self.region = region
      self.info = info
   }

   var body: some View {
      NavigationView {
         List {
            ForEach(filteredAvurnavs) { avurnav in
               NavigationLink(destination:AvurnavDetail(avurnav : avurnav, region : self.region, info : self.info)){
                  AvurnavRow(avurnav: avurnav)
               }
            }
         }
         .navigationBarTitle("Avis \(descriptionInfo)à la navigation", displayMode: .inline)



         .navigationBarItems(leading:
                              HStack {
                                 Text("Bientôt...")
//                                 Menu(modelData.Region) {
//                                    if(modelData.Region != "Atlantique") {
//                                       Button("Atlantique", action: { [self] in
//                                          modelData.Region = "Atlantique"
//                                          modelData.avurnavs = downloadXMLFileAsRequired(modelData.urlPremar)
//                                       })
//                                    }
//                                    if(modelData.Region != "Manche") {
//                                       Button("Manche", action: { [self] in
//                                          modelData.Region = "Manche"
//                                          modelData.avurnavs = downloadXMLFileAsRequired(modelData.urlPremar)
//                                       })
//                                    }
//                                    if(modelData.Region != "Méditerranée") {
//                                       Button("Méditerranée", action: { [self] in
//                                          modelData.Region = "Méditerranée"
//                                          modelData.avurnavs = downloadXMLFileAsRequired(modelData.urlPremar)
//                                       })
//                                    }
//                                 }
                              },
                             trailing:
                              HStack {
                                 Toggle(isOn: $showPinnedOnly, label : {
                                 })
                                 .padding()
                                 .toggleStyle(ToggleButton())
                              }
         )
         AvurnavListOptions()
      }
      // savegarde des modifications apportées à la liste des informations pour
      // assurer leur persistence (en particulier les favoris)
      .onDisappear (perform: { modelData.infoData[region.rawValue][info.rawValue].saveOnDisk()})
   }
    
}

struct AvurnavList_Previews: PreviewProvider {
   static var previews: some View {
      AvurnavList(region: .atlantique, info: .normal)
   }
}
