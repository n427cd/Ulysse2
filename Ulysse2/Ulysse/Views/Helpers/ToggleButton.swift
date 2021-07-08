//
//  ToogleButton.swift
//  Ulysse
//
//  Created by Eric Duchenne on 05/05/2021.
//

import SwiftUI

struct ToggleButton: ToggleStyle {
   func makeBody(configuration: Self.Configuration) -> some View {
      return HStack {
         configuration.label
         Spacer()
         Image(systemName : configuration.isOn ? "line.horizontal.3.decrease.circle.fill" : "line.horizontal.3.decrease.circle")
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundColor(configuration.isOn ? .blue : . gray)
            .onTapGesture {
               configuration.isOn.toggle()
            }
      }
   }
}


