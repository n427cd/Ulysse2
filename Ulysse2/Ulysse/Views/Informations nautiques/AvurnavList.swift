//
//  AvurnavList.swift
//  Ulysse
//
//  Created by Eric Duchenne on 04/05/2021.
//

import SwiftUI



struct AvurnavList: View {
   @EnvironmentObject var modelData : ModelData
   
   //@State private var filterApplied = false
   @State private var showPinnedOnly = false
   @State private var ShowUnreadOnly = false
   //   @State private var NewUnread : Int = 0
   
   var region : Premar
   var info : TypeInformation
   
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
         avurnav in ((!showPinnedOnly || avurnav.isPinned) &&
                        (!ShowUnreadOnly || avurnav.isUnread))
      }
   }
   
   var filteredOldAvurnavs:[InfoNavItem] {
      modelData.infoData[region.rawValue][info.rawValue].items.filter {
         avurnav in ((!showPinnedOnly || avurnav.isPinned) &&
                        (!avurnav.isNewItem))
      }
   }
   var filteredNewAvurnavs:[InfoNavItem] {
      modelData.infoData[region.rawValue][info.rawValue].items.filter {
         avurnav in ((!showPinnedOnly || avurnav.isPinned) &&
                        (avurnav.isNewItem))
      }
   }
   var filteredUnreadNewAvurnavs:[InfoNavItem] {
      modelData.infoData[region.rawValue][info.rawValue].items.filter {
         avurnav in ((!showPinnedOnly || avurnav.isPinned) &&
                        (avurnav.isNewItem && avurnav.isUnread))
      }
   }
   var filteredUnreadOldAvurnavs:[InfoNavItem] {
      modelData.infoData[region.rawValue][info.rawValue].items.filter {
         avurnav in ((!showPinnedOnly || avurnav.isPinned) &&
                        (!avurnav.isNewItem && avurnav.isUnread))
      }
   }
   
   
   init(region : Premar, info : TypeInformation)
   {
      self.region = region
      self.info = info
   }
   
   var body: some View {
      
      NavigationView {
         List {
            Section(header:
                     HStack {
                        Image(systemName: "tray.and.arrow.down")
                           .foregroundColor(.blue)
                        VStack {
                           Text("Nouveaux avis")
                              .font(.headline)
                              .foregroundColor(.blue)
                           Text("\(filteredNewAvurnavs.count) avis, dont \(filteredUnreadNewAvurnavs.count) non lus")
                              .font(.footnote)
                              .foregroundColor(.gray)
                        }
                     }) {
               
               ForEach(filteredNewAvurnavs) {avurnav in
                  NavigationLink(destination:AvurnavDetail(avurnav : avurnav, region : region, info : info)){
                     AvurnavRow(avurnav: avurnav)
                  }
               }
            }
            Section(header:
                     HStack {
                        Image(systemName: "tray")
                           .foregroundColor(.blue)
                        VStack {
                           Text("Avis précédents")
                              .font(.headline)
                              .foregroundColor(.blue)
                           Text("\(filteredOldAvurnavs.count) avis, dont \(filteredUnreadOldAvurnavs.count)  non lus")
                              .font(.footnote)
                              .foregroundColor(.gray)
                        }
                        
                     }) {
               
               ForEach(filteredOldAvurnavs) {avurnav in
                  NavigationLink(destination:AvurnavDetail(avurnav : avurnav, region : self.region, info : self.info)){
                     AvurnavRow(avurnav: avurnav)
                  }
               }
            }
            
         }
         .navigationBarTitle("Avis \(descriptionInfo) à la navigation", displayMode: .inline)
         .navigationBarItems(leading:
                              HStack {
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
      .onAppear() {
         modelData.objectWillChange.send()
         modelData.infoData[region.rawValue][info.rawValue].downloadFeed()
      }
      // savegarde des modifications apportées à la liste des informations pour
      // assurer leur persistence (en particulier les favoris)
      .onDisappear (perform: {
         modelData.infoData[region.rawValue][info.rawValue].saveOnDisk()
         print("Sauvegarde de \(region)\(info) .onDisappear")
         
      })
   }
   
}

struct AvurnavList_Previews: PreviewProvider {
   static var previews: some View {
      AvurnavList(region: .atlantique, info: .normal)
   }
}
