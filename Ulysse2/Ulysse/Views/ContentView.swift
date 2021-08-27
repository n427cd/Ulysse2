//
//  ContentView.swift
//  Ulysse
//
//  Created by Eric Duchenne on 03/05/2021.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
   @StateObject private var modelData = ModelData()
   var body: some View {
      NavigationView {
         List {
            // Section information nautique
            
            Section(header: HStack {
               Image(systemName: "books.vertical.fill")
               Text("Information nautique")
                  .font(.headline)
            }
            .foregroundColor(.blue))
            {
               NavigationLink("Avis urgents",
                              destination: AvurnavList(region: .atlantique, info: .urgent)
                                 .environmentObject(modelData)
                                 .navigationBarHidden(false))
                  .navigationBarTitleDisplayMode(.inline)
               NavigationLink("Avis de navigation", destination: AvurnavList(region: .atlantique, info: .normal)
                                 .environmentObject(modelData)
                                 .navigationBarHidden(false))
                  .navigationBarTitleDisplayMode(.inline)
               NavigationLink("Avis rade", destination: AvurnavList(region: .atlantique, info: .rade)
                                 .environmentObject(modelData)
                                 .navigationBarTitleDisplayMode(.inline)
                                 .navigationBarHidden(false))
            }
            
            // Section météo
            
            Section(header: HStack {
                     Image(systemName: "cloud.sun.rain.fill")
                     Text("Météo")
                        .font(.headline)}
                     .foregroundColor(.blue))
            {
               NavigationLink("Bulletin côtier",
                              destination: EmptyView()
                                 .navigationBarHidden(true)
               )
               NavigationLink("Situation générale",
                              destination: EmptyView()
                                 .navigationBarHidden(true)
               )
            }
            
            // Section marée
            
            Section( header: HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("Marée")
                           .font(.headline)}
                        .foregroundColor(.blue))
            {
               NavigationLink("La Rochelle", destination: TideView()
               )
               HStack {
                  Image(systemName: "plus.app")
                  NavigationLink("", destination: EmptyView())
               }
            }
                        
            // Section passage
            
            Section(header: HStack {
                     Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                     Text("Passage")
                        .font(.headline)}
                     .foregroundColor(.blue))
            {
               NavigationLink("Ile d'Yeu - Belle Ile",
                              destination: ScannedMapView(
                                 mapCenter: CLLocationCoordinate2D(latitude: 46.5,
                                                                   longitude: -2)
                              )
                              .navigationBarHidden(true)
                              .ignoresSafeArea()
               )
               
               
               NavigationLink(modelData.navs[0].description,
                              destination: ScannedMapView(
                                 mapCenter: modelData.navs[0].center,
                                 route: modelData.navs[0], showRoute: true)
                                 .navigationBarHidden(true)
                                 .ignoresSafeArea()
               )
               Image(systemName: "plus.app")
            }
         }
         .listStyle(SidebarListStyle())
         .navigationBarItems(trailing: Button(action: {}, label: {
                                                Menu(modelData.Region) {
                                                   switch modelData.Region {
                                                   case "Atlantique" :
                                                      Button("Manche - Mer du nord", action: {})
                                                      Button("Méditerranée", action: {})
                                                   case "Méditerrannée" :
                                                      Button("Atlantique", action: {})
                                                      Button("Manche - Mer du nord", action: {})
                                                   default :
                                                      Button("Atlantique", action: {})
                                                      Button("Méditerranée", action: {})
                                                   }

         }}))

         VStack {
            #if swift(>=5.4)
            Text("Running Swift 5.4 or later")
            #else
            Text("Running older Swift (≤ 5.3)")
               .font(.caption)
            #endif
            let info = modelData.infoData[0][0]
            
            Text("Description :\(info.sourceDescription)")
            
            if let publishedOn = info.publishedOn {
                     Text("Publié : \(publishedOn)")
            }
            else { Text("Pas de date de publication disponible")}
         }
      }
   }
}

struct ContentView_Previews: PreviewProvider {
   static var previews: some View {
      
      ForEach(["iPhone SE (2nd generation)", "iPhone 11 Pro", "iPad Pro"], id: \.self) { deviceName in
         ContentView()
            .environmentObject(ModelData())
            .previewDevice(PreviewDevice(rawValue: deviceName))
            .previewDisplayName(deviceName)
      }
   }
}
