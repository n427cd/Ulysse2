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

            Section(header:
                     HStack {
                        Image(systemName: "books.vertical.fill")
                        Text("Information nautique")
                           .font(.headline)}
                     .foregroundColor(.blue))
            {
               NavigationLink("Avis urgents", destination: AvurnavList(region: .atlantique, info: .urgent)
                                    .environmentObject(modelData)
                                    .navigationBarHidden(true))
               NavigationLink("Avis de navigation", destination: AvurnavList(region: .atlantique, info: .normal)
                                    .environmentObject(modelData)
                                    .navigationBarHidden(true))
               NavigationLink("Avis rade", destination: AvurnavList(region: .atlantique, info: .rade)
                                 .environmentObject(modelData)
                                 .navigationBarHidden(true))
                  .disabled(modelData.infoData[Premar.atlantique.rawValue][TypeInformation.rade.rawValue].items.count == 0)
            }
            //.navigationTitle("Information nautique")

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
            //.navigationTitle("Météo marine")

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
            //.navigationTitle("Marée")
            

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
            //.navigationTitle("Passage")
         }
         .listStyle(SidebarListStyle())
         VStack {
         #if swift(>=5.4)
         Text("Running Swift 5.4 or later")
         #else
         Text("Running old Swift (≤ 5.3)")
            .font(.caption)
         #endif
         let info = modelData.infoData[0][0]

         Text("Description :\(info.sourceDescription)")
//TODO:décommenter la ligne suivante
//         Text("Publié : \(info.publishedOn!)")
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
