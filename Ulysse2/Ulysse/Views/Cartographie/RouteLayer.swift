//
//  RouteLayer.swift
//  Ulysse
//
//  Created by Eric Duchenne on 13/07/2021.
//

import Foundation
import CoreGraphics
import UIKit
import SwiftUI

extension ScannedMapView {
   //-----------------------------------------------------------------------
   /// Retourne l'étiquette du waypoint à afficher. Le départ s'affiche avec un D, l'arrivée avec un A et
   /// chaque point par son numéro de séquence
   /// - parameter index : numéro du waypoint dans la route
   /// - returns: une chaîne contenant l'étiquette à afficher

   fileprivate func waypointLabel(_ index: Int) -> String {
      switch index {
      case 0:
         return "D"
      case navigation!.segments.count - 1 :
         return "A"
      default:
         return String(format:"%d", index)
      }
   }


   //-----------------------------------------------------------------------
   /// Dessine les informations de cap et de distance à l'extrémité du segment
   /// - parameter context : contexte actif dans lequel a lieu l'affichage
   /// - parameter at : position de référence du waypoint. Le texte est déplacé
   ///                  de manière à laisser le waypoint visible et à s'adapter
   ///                  à l'angle de route (rv)
   /// - parameter rv : route vraie à afficher
   /// - parameter distance : distance à afficher
   /// - parameter format : attributs de la chaîne de caractères
   /// - BUG :
   /// - TODO :
   ///     - améliorer la simplification du texte lorsqu'il n'y pas pas suffisament de place pour s'afficher le long du segment
   ///     - détecter quand le texte s'affiche dans un angle rentrant et interfère avec le segment suivant (ou précédent ?)
   /// - returns : void


   fileprivate func drawSegmentInfo(context : CGContext, at: CGPoint, rv : CGFloat, distance : CGFloat, format : [NSAttributedString.Key : Any]? = nil ) {

      // On écrit les informations de cap et de distance dans un contexte
      // graphique translaté et tourné selon l'angle de route

      let s = String(format : "%03.0fT / %.1f NM", rv + 0.5, distance + 0.05)
      let textSize = s.size(withAttributes: format)

      let rotation : CGFloat
      let offset : CGPoint

      // la taille de caractère est indépendante du facteur de zoom, seul
      // l'espacement doit être adapté au facteur de zoom
      switch(rv) {
      case 0...180 :
         rotation = rv - 90
         offset = CGPoint(x: -(textSize.width + 8/inverseZoomFactor), y: -(textSize.height + 2.5 / inverseZoomFactor))
      default :
         rotation = 90 + rv
         offset = CGPoint(x:8/inverseZoomFactor, y: -(textSize.height + 2.5 / inverseZoomFactor))
      }

      // on modifie le contexte, ttranslate et rotationne, on écrit et on
      // revient au contexte précédent

      context.saveGState()

      context.translateBy(x: at.x, y: at.y)
      context.rotate(by: rotation.deg2rad())

      s.draw(at: offset, withAttributes: format)

      context.restoreGState()

   }


   // -----------------------------------------------------------------------
   /// Dessine les segments de la route dans le contexte d'affichage en
   /// respectant la geometry de la vue
   /// - parameter context : contexte actif dans lequel a lieu l'affichage
   /// - parameter geometry : géométrie de la vue


   fileprivate func drawSegments(context : CGContext, geometry : GeometryProxy) {

      context.setLineWidth(5.0 / inverseZoomFactor)
      context.setStrokeColor(UIColor.purple.cgColor)
      context.setLineCap(.square)

      let attrsRoute = [NSAttributedString.Key.font:
                           UIFont(name: "DINCondensed-Bold",
                                  size: 16 / inverseZoomFactor)!,
                        NSAttributedString.Key.foregroundColor: UIColor.purple]

      var previousMark : Waypoint? = nil
      var noSequence : Int = 0

      for w in navigation!.segments {
         var p = projectOnClippedMap(waypoint: w, geometry: geometry)
         var drawnWpt = w

         // si l'utilisateur déplace un waypoint sur le segment, repositionner
         // l'extrémité du segment

         if(noSequence == findSelectedWaypoint(compute: false)) {

            p.x += dragState.translation.width
            p.y += dragState.translation.height

            drawnWpt = waypointFromPoint(p, geometry)
         }

         // Si on est au premier waypoint, on positionne le stylo à l'endroit
         // correspondant
         if(previousMark == nil) {
            context.move(to: p)
         }
         // sinon, on dessine un trait jusqu'au point

         else {

            // si l'utilisateur est en train d'insérer un point en étirant un
            // segment, on affiche le sommet temporaire sous le doigt de
            // l'utilisateur

            if(selectedIndex.segment == noSequence)
            {
               context.addLine(to: dragState.location)

               let intermediateWpt = waypointFromPoint(dragState.location, geometry)
               let trueCourse = previousMark!.trueCourse(to: intermediateWpt)
               let dist = previousMark!.distance(to: intermediateWpt)

               drawSegmentInfo(context: context,
                               at : dragState.location, rv: trueCourse, distance: dist,
                               format : attrsRoute )

               previousMark = intermediateWpt
            }

            context.addLine(to: p)

            // et on affiche les informations de cap et de distance qu'on
            // oriente et aligne correctement

            let trueCourse = previousMark!.trueCourse(to: drawnWpt)
            let dist = previousMark!.distance(to: drawnWpt)

            drawSegmentInfo(context: context,
                            at : p, rv: trueCourse, distance: dist,
                            format : attrsRoute )
         }
         // et on passe au point suivant !
         previousMark = drawnWpt
         noSequence += 1
      }
      context.strokePath()
   }


   // -----------------------------------------------------------------------
   /// Dessine les points de la route dans le contexte d'affichage en
   /// respectant la geometry de la vue
   /// - parameter context : contexte actif dans lequel a lieu l'affichage
   /// - parameter geometry : géométrie de la vue
   // -----------------------------------------------------------------------

   fileprivate func drawWaypoints(context : CGContext, geometry : GeometryProxy) {
      var noSequence : Int = 0

      let WPT_BOX_WIDTH = 14 / inverseZoomFactor
      let WPT_BOX_HEIGHT = 16 / inverseZoomFactor

      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .center

      let attrs = [NSAttributedString.Key.font:
                     UIFont(name: "DINCondensed-Bold",
                            size: 14 / inverseZoomFactor)!,
                   NSAttributedString.Key.paragraphStyle: paragraphStyle,
                   NSAttributedString.Key.foregroundColor: UIColor.white]


      let selectedWaypoint = findSelectedWaypoint(compute: false)

      for w in navigation!.segments {
         var p = projectOnClippedMap(waypoint: w, geometry: geometry)
         if(noSequence == selectedWaypoint) {
            p.x += dragState.translation.width
            p.y += dragState.translation.height
         }

         let r = CGRect(x: p.x - WPT_BOX_WIDTH / 2, y: p.y - WPT_BOX_HEIGHT / 2,
                        width: WPT_BOX_WIDTH, height: WPT_BOX_HEIGHT)
         context.setFillColor(UIColor.purple.cgColor)

         if( noSequence == selectedWaypoint) {
            context.setShadow(offset: CGSize(width: WPT_BOX_WIDTH/3, height: WPT_BOX_WIDTH/3), blur: 0.5)
         }
         else {
            context.setShadow(offset: CGSize(width:0, height: 0), blur: 0, color: nil)
         }

         context.addRect(r)
         context.fillPath()

         // Affichage du numéro des waypoints

         let rectText = CGRect(x: p.x - WPT_BOX_WIDTH / 2,
                               y: p.y - WPT_BOX_HEIGHT / 2,
                               width: WPT_BOX_WIDTH,
                               height: WPT_BOX_HEIGHT).offsetBy(dx: 0, dy: 2/inverseZoomFactor)

         waypointLabel(noSequence).draw(in: rectText, withAttributes: attrs)

         noSequence += 1
      }
   }


   // -----------------------------------------------------------------------
   /// Affichage de la route
   /// - parameter croppedImage : `UIImage` sur laquelle on affiche
   ///                            la carte (`inout`)
   /// - parameter geometry : paramètres géométrique de la vue qui contient
   ///                        l'image croppedImage
   /// - returns: Pas de valeur de retour, mais la fonction modifie le
   ///            paramètre `croppedImage`
   // -----------------------------------------------------------------------

   func drawRoute(_ croppedImage: inout UIImage, _ geometry: GeometryProxy) {
      // On récupère le contexte d'affichage du fond de carte
      //TODO: #5 gérer l'absence de contexte
      UIGraphicsBeginImageContext(croppedImage.size)
      let context = UIGraphicsGetCurrentContext()!

      // on affiche le fond de carte
      croppedImage.draw(at: CGPoint(x: 0, y: 0))

      // Puis les différentes couches vectorielles

      // la route
      if(navigation != nil ) {
         drawSegments(context: context, geometry: geometry)
         drawWaypoints(context: context, geometry: geometry)
      }

      //TODO: les autres couches vectorielles

      croppedImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
   }

}
