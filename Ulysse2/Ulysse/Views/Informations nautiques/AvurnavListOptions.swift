//
//  AvurnavListOptions.swift
//  Ulysse
//
//  Created by Eric Duchenne on 01/07/2021.
//

import SwiftUI

///TODO: ici aussi, des commentaires ne seraient pas inutiles

struct RegionView : View {
   @EnvironmentObject var modelData : ModelData
   @State private var showAtl = true

   var body : some View {
      Toggle(isOn: $showAtl) {
         VStack {
            Text("Coucou")
            Text("substitle")
               .font(.caption)
         }
      }
   }

}

struct AvurnavListOptions: View {
   @State private var showAtl = true
   @State private var showManche = false
   @State private var showMed = false

   var body: some View {
      VStack {
      Label("Configuration", systemImage: "gearshape.2")
        
      Form {
         Section(header:
                  HStack {
                     Text("Atlantique")
                     Image(systemName: "circle.fill")
                        .resizable()
                        .frame(width: 9, height: 9, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.green)
                  }) {
            VStack {
               Toggle(isOn: $showAtl) {
                  Text("Afficher les avis")
               }
               VStack{
                  HStack{
                  Text("Avis urgents : ")
                     .font(.callout)
                     Text("tout à l'heure")
                        .fontWeight(.medium)
                     Spacer()
                  }
                  HStack{
                     Text("Avis à la navigation :")
                        .font(.callout)
                     Text("tout à l'heure")
                        .fontWeight(.medium)
                     Spacer()
                  }
                  HStack{
                     Text("Avis rade: ")
                        .font(.callout)
                     Text("tout à l'heure")
                        .fontWeight(.medium)
                     Spacer()
                  }

               }
            }
         }
         Section(header: Text("Manche - Mer du Nord")) {
            VStack {
               Toggle(isOn: $showAtl) {

                  Text("Afficher les avis")
                  Text("substitle")
                     .font(.caption)
               }
            }
         }

         Toggle("Atlantique", isOn: $showAtl)
         Toggle("Manche", isOn: $showManche)
         Toggle("Méditerranée", isOn: $showMed)

    }
   }
   }
}

struct AvurnavListOptions_Previews: PreviewProvider {
    static var previews: some View {
        AvurnavListOptions()
    }
}
