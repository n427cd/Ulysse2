//
//  TideView.swift
//  Ulysse
//
//  Created by Eric Duchenne on 24/06/2021.
//

import SwiftUI

struct TideView: View {

   var body: some View {
      Menu("Options") {
         Button("Order Now", action: placeOrder)
         Button("Adjust Order", action: adjustOrder)
         Button("Cancel", action: cancelOrder)
      }
   }

   func placeOrder() { }
   func adjustOrder() { }
   func cancelOrder() { }
}


struct TideView_Previews: PreviewProvider {
   static var previews: some View {
      TideView()
   }
}
