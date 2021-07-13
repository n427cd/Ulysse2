//
//  GesturesExt.swift
//  Ulysse
//
//  Created by Eric Duchenne on 13/07/2021.
//

import Foundation
import CoreGraphics

extension ScannedMapView {
   enum DragState {
      case inactive
      case pressing
      case dragging(translation: CGSize, location : CGPoint)

      var translation: CGSize {
         switch self {
         case .inactive, .pressing:
            return .zero
         case .dragging(let translation, _):
            return translation
         }
      }

      var location : CGPoint {
         switch self {
         case .inactive, .pressing:
            return .zero
         case .dragging(_, let location):
            return location
         }
      }

      var isActive: Bool {
         switch self {
         case .inactive:
            return false
         case .pressing, .dragging:
            return true
         }
      }

      var isDragging: Bool {
         switch self {
         case .inactive, .pressing:
            return false
         case .dragging:
            return true
         }
      }
   }

   
}
