//
//  MapView.swift
//  Ulysse
//
//  Created by Eric Duchenne on 03/05/2021.
//

import SwiftUI
import MapKit

struct MapView: View {
   var coordinate : CLLocationCoordinate2D
   @State private var region = MKCoordinateRegion()
    var body: some View {
        Map(coordinateRegion: $region)
         .onAppear {
            setRegion(coordinate)
            
         }
    }

   private func setRegion(_ coordinate : CLLocationCoordinate2D ){
      region = MKCoordinateRegion(
      center : coordinate,
         span: MKCoordinateSpan(latitudeDelta:0.2, longitudeDelta : 0.2)
      )
   }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
      MapView(coordinate: CLLocationCoordinate2D(latitude: 45, longitude:-1.0))
    }
}
