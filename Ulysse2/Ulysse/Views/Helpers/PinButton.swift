//
//  PinButton.swift
//  Ulysse
//
//  Created by Eric Duchenne on 05/05/2021.
//

import SwiftUI

struct PinButton: View {
   @Binding var isSet : Bool

   var body: some View {
      Button(action: {
         isSet.toggle()
      }) {
         Image(systemName : isSet ? "star.fill" : "star")
            .foregroundColor(isSet ? Color.yellow : Color.gray)
      }
   }
}

struct PinButton_Previews: PreviewProvider {
   static var previews: some View {
      PinButton(isSet: .constant(true))
   }
}
