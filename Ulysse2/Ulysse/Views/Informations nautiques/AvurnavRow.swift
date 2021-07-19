//
//  AvurnavRow.swift
//  Ulysse
//
//  Created by Eric Duchenne on 04/05/2021.
//

import SwiftUI

struct AvurnavRow: View {
   @EnvironmentObject var modelData : ModelData
   @ObservedObject var avurnav : InfoNavItem

   var body: some View {
      HStack(alignment: .center) {
         if(avurnav.isUnread) {
         Image(systemName: "circle.fill")    
            .resizable()
            .frame(width:8, height:8)
            .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            .offset(y: -12)
         }
         else {
            if(avurnav.isNewItem) {
            Image(systemName: "circle")
               .resizable()
               .frame(width:8, height:8)
               .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
               .offset(y: -12)
            }
         }
         VStack(alignment: .leading) {
            Text(avurnav.details)
               .multilineTextAlignment(.leading)
               .font(.callout)
               .lineLimit(1)

            Text(avurnav.title)
               .font(.caption)
               .lineLimit(1)
         }
         .frame(height: 40.0)

         Spacer()

         if(avurnav.isPinned)
         {
            Image(systemName: "star.fill")
               .foregroundColor(.yellow)
         }
      }
   }
}

struct AvurnavRow_Previews: PreviewProvider {
   static var avurnavs = ModelData().infoData[0][0].items
   static var previews: some View {
      Group {

         AvurnavRow(avurnav: avurnavs[1])
         AvurnavRow(avurnav: avurnavs[2])
      }
      .previewLayout(.fixed(width:300, height:50))
   }
}
