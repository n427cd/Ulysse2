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
      case longPress(location: CGPoint)
      case dragging(translation: CGSize, location : CGPoint, initialPos : CGPoint)

      var translation: CGSize {
         switch self {
         case .inactive, .pressing, .longPress:
            return .zero
         case .dragging(let translation, _, _):
            return translation
         }
      }

      var location : CGPoint {
         switch self {
         case .inactive, .pressing:
            return .zero
         case .longPress(let location):
            return location
         case .dragging(_, let location, _):
            return location
         }
      }
      
      var initialPos : CGPoint {
         switch self {
         case .inactive, .pressing :
            return .zero
         case .longPress(let location):
            return location
         case .dragging(_, _, let initialPos):
            return initialPos
         }
      }

      var isActive: Bool {
         switch self {
         case .inactive:
            return false
         case .pressing,.longPress, .dragging:
            return true
         }
      }

      var isDragging: Bool {
         switch self {
         case .inactive, .pressing, .longPress:
            return false
         case .dragging:
            return true
         }
      }
   }

   
}
