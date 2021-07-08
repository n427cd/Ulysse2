//
//  ScannedMapView.swift
//  Ulysse
//
//  Created by Eric Duchenne on 08/06/2021.
//

import SwiftUI
import CoreGraphics
import CoreLocation
import Foundation
import UIKit


/// Encapsulation des index pour la sélection des waypoints ou des segments
///
/// Autorise la modification des index dans la vue
/// - Remark : Permet de corriger le hack qui consistait à passer par une variable statique

class SelectedIndex {
   /// index du waypoint sélectionné. `nil` si pas de sélection active
   var waypoint : Int?

   /// index du segment sélectionné. `nil` si pas de sélection active
   var segment : Int?

   /// Initiliation : pas de sélection par défaut
   init() {}
}


/// Vue permettant la manipulation de cartes scannées
/// - TODO: #2  Implémentation du multizoom
/// - TODO: #3 implémentation de la suppression d'un Waypoint


struct ScannedMapView: View {

    /// Index d'une éventuelle sélection de segment ou de waypoint
   let selectedIndex = SelectedIndex()

   var fileName : String?          // nom de la carte
   let image : UIImage!            // UIImage sur laquelle est construite la vue
   var mapPixelSize : CGSize?      // taille de la carte en pixels

   let generator = UISelectionFeedbackGenerator()

   var currentCenter : CLLocationCoordinate2D      // coord. (lat lon) du centre de la carte
   var initialCenter : CLLocationCoordinate2D      // coord. du point initial à afficher
   @State private var centreImage = CGPoint()      // coord. (x,y) du bitmap au centre de la vue

   let cgimg : CGImage

   let X_A, X_B : Double       // coeff. de transformation (longitude) -> (eastings) x = g x X_A + X_B
   let Y_A, Y_B : Double       // coeff. de transformation (Lat croissante) -> (northings) y = LC x Y_A + Y_B


   @State private var currentAmount: CGFloat = 1
   @State private var currentZoomFactor: CGFloat = 1

   @State var inverseZoomFactor : CGFloat = 1.0

   @State private var deplacement : CGSize = .zero     // valeur du déplacement en cours
   @State private var userOffset : CGSize = .zero      // valeur du déplacement cumulé jusqu'au précent déplacement terminé

   var navigation : Route?
   var bDisplayRoute = false



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

   @GestureState var dragState = DragState.inactive


   //MARK: - Initialisations -

   //-----------------------------------------------------------------------
   //
   // Initialisation générale
   //
   //-----------------------------------------------------------------------

   init(assetName : String, mapCenter: CLLocationCoordinate2D, _ alphaX : Double, _ betaX : Double, _ alphaY : Double, _ betaY : Double, route : Route? = nil, showRoute : Bool = false, ci : CGPoint = CGPoint())
   {
      //TODO #4 : gérer les erreurs au chargement des cartes

      fileName = assetName
      image = UIImage(named: assetName)
      mapPixelSize = image?.size

      cgimg = image.cgImage!

      X_A = alphaX          // coefficients de conversion coordonnées géographiques <-> pixels
      X_B = betaX
      Y_A = alphaY
      Y_B = betaY

      initialCenter = mapCenter        // on garde le centre initial de la carte
      currentCenter = mapCenter        // centre à afficher (lat lon)

      centreImage = projectOnMap(currentCenter.latitude, currentCenter.longitude)

      navigation = route
      bDisplayRoute = showRoute
   }


   //-----------------------------------------------------------------------
   //
   // initialisation avec la carte Atlantique 1
   //
   //-----------------------------------------------------------------------

   init(mapCenter: CLLocationCoordinate2D, route : Route? = nil, showRoute : Bool = false)
   {
      #warning("Utilisation de la carte Atlantique1")
      fileName = "Atlantique1"
      image = UIImage(named: fileName!)
      mapPixelSize = image?.size

      cgimg = image.cgImage!

      // données d'étalonage
      X_A = 1150
      X_B = 7000
      Y_A = -66185.8
      Y_B = 65131.085

      currentCenter = mapCenter
      initialCenter = mapCenter
      centreImage.x = 1
      centreImage = projectOnMap(currentCenter.latitude, currentCenter.longitude)
      userOffset = .zero
      deplacement = .zero

      navigation = route
      bDisplayRoute = showRoute
   }


   //MARK: - Dessin de la carte affichée -


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
      let s = String(format : "%03.0f° / %.1f NM", rv + 0.5, distance + 0.05)
      let textSize = s.size(withAttributes: format)

      context.saveGState()

      context.translateBy(x: at.x, y: at.y)

      let rotation : CGFloat
      let offset : CGPoint

      switch(rv) {
      case 0...180 :
         rotation = rv - 90
         offset = CGPoint(x: -(textSize.width + 8/inverseZoomFactor), y: -(textSize.height + 2.5 / inverseZoomFactor))
      default :
         rotation = 90 + rv
         offset = CGPoint(x:8/inverseZoomFactor, y: -(textSize.height + 2.5 / inverseZoomFactor))
      }


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

   fileprivate func drawRoute(_ croppedImage: inout UIImage, _ geometry: GeometryProxy) {
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

      // les autres couches vectorielles 

      croppedImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
   }


   //-----------------------------------------------------------------------
   //
   // Construction de l'image qui sera affichée
   //
   //-----------------------------------------------------------------------

   func drawCroppedMap(geometry : GeometryProxy) ->  Image? {
      guard let _ = fileName else { return Image("")}

      let croppingRect : CGRect = CGRect(
         x: (centreImage.x - deplacement.width) - geometry.size.width / 2 * inverseZoomFactor,
         y: (centreImage.y - deplacement.height) - geometry.size.height /  2 * inverseZoomFactor,
         width:  geometry.size.width * inverseZoomFactor,
         height: geometry.size.height * inverseZoomFactor)

      if let cutImageRef = cgimg.cropping(to: croppingRect)
      {
         var croppedImage = UIImage(cgImage: cutImageRef,
                                    scale: inverseZoomFactor,
                                    orientation: .up)
         if(self.bDisplayRoute) {
            drawRoute(&croppedImage, geometry)
         }
         return Image(uiImage: croppedImage)
      }

      return Image("")
   }

   //MARK: - Gestion des interactions -

   //-----------------------------------------------------------------------
   //
   // bascule pour l'affichage de la carte
   //
   //-----------------------------------------------------------------------

   mutating func showRoute(route : Route?, _ display : Bool) ->ScannedMapView
   {
      navigation = route

      if(route == nil)
      {
         bDisplayRoute = false
      }
      else {
         bDisplayRoute = display
      }
      return self
   }


   //-----------------------------------------------------------------------
   //
   // Bascule du zoom de la carte
   // Soit on passe au zoom de 2, soit on revient à un zoom de 1 en revenant
   // à la position initiale de la carte
   //
   //-----------------------------------------------------------------------

   fileprivate func toggleZoom() {
      if( currentZoomFactor == 1) {
         currentZoomFactor = 2
         inverseZoomFactor = 0.5
      }
      else {
         currentZoomFactor = 1
         inverseZoomFactor = 1.0
         userOffset.width = 0
         userOffset.height = 0
      }
   }

   //-----------------------------------------------------------------------
   //
   // La valeur du déplacement correspond au déplacement en cours.
   // On modifie le déplacement total (userOffset) à la fin du
   // gesture
   //
   //-----------------------------------------------------------------------

   fileprivate func saveOffset() {
      // cumul
      userOffset.width += deplacement.width
      userOffset.height += deplacement.height

      //remise à zéro
      deplacement = .zero

      // et déplacement du centre
      centreImage = projectOnMap(currentCenter.latitude, currentCenter.longitude)
      centreImage.x -= userOffset.width
      centreImage.y -= userOffset.height
   }

   //-----------------------------------------------------------------------
   //
   // Le déplacement du DragGesture est ajusté pour tenir compte du facteur de
   // zoom et des limites de la carte
   //
   //-----------------------------------------------------------------------

   fileprivate func setDeplacement(_ value: DragGesture.Value, size: CGSize) {

      centreImage = projectOnMap(currentCenter.latitude, currentCenter.longitude)
      centreImage.x -= userOffset.width
      centreImage.y -= userOffset.height

      // On limite le déplacement en absisse aux limites de la carte
      deplacement.width = value.translation.width * inverseZoomFactor

      if(deplacement.width > centreImage.x - size.width / 2 * inverseZoomFactor)
      {
         deplacement.width = centreImage.x - size.width / 2 * inverseZoomFactor
      }
      else if( deplacement.width   <  centreImage.x + size.width / 2 * inverseZoomFactor - mapPixelSize!.width)
      {
         deplacement.width = centreImage.x + size.width / 2 * inverseZoomFactor - mapPixelSize!.width
      }

      // on fait la même chose sur les ordonnées
      deplacement.height = value.translation.height * inverseZoomFactor

      if( deplacement.height > centreImage.y - size.height /  2 * inverseZoomFactor)
      {
         deplacement.height = centreImage.y - size.height /  2 * inverseZoomFactor
      }
      else if ( deplacement.height < centreImage.y + size.height /  2 * inverseZoomFactor - mapPixelSize!.height )
      {
         deplacement.height = centreImage.y + size.height /  2 * inverseZoomFactor - mapPixelSize!.height
      }
   }

   //-----------------------------------------------------------------------
   //
   //-----------------------------------------------------------------------

   fileprivate func setZoomLevel(_ amount: MagnificationGesture.Value) {
      let futureZoom = self.currentAmount * amount * self.currentZoomFactor
      if(futureZoom <= 4) {
         if(futureZoom >= 0.25) {
            self.currentAmount = amount
         }
         else {
            self.currentAmount = 0.33 / self.currentZoomFactor
         }
      }
      else {
         self.currentAmount = 4 / self.currentZoomFactor
      }
      self.inverseZoomFactor =  1 / (currentZoomFactor * currentAmount)
   }


   //-----------------------------------------------------------------------
   //
   //-----------------------------------------------------------------------

   fileprivate func saveZoomLevel() {
      self.currentZoomFactor *= self.currentAmount
      self.currentAmount = 1
      inverseZoomFactor = 1/currentZoomFactor
   }

   //-----------------------------------------------------------------------
   //
   //-----------------------------------------------------------------------

   func areCloseEnough(_ p : CGPoint, _ q : CGPoint) -> Bool {

      return (p.x - q.x) * (p.x - q.x)  + (p.y - q.y) * (p.y - q.y) < 200
   }


   //-----------------------------------------------------------------------
   /**
    Détermine le waypoint qui est est en cours de sélection pendant les gestures

    - parameter compute : indicateur qui va déterminer si l'index doit être
                          calculé (`true`) ou simplement lu (`false`)
    - parameter location : `CGPoint` position du tap de l'utilisateur
    - parameter geometry : géométrie de la fenêtre

    - returns : l'index du waypoint sélectionné dans la route. Si le point choisi ne correspond pas à un waypoint à l'écran, retourne `nil`

    S'il y a besoin de rafraîchir la sélection, on calcule l'index en
    parcourant la liste des waypoints pour regarder si l'un d'entre eux
    se trouve à proximité du point indiqué par l'utilisateur

    - Important : l'index n'est pas mis à jour par la fonction. Il doit être mis à jour spécifiquement, par exemple :

         ````
         `selectedIndex.segment = findSelectedSegment(update: true,
                                          drag!.startLocation, geometry)
         ````
    */

   func findSelectedWaypoint(compute : Bool, _ location : CGPoint? = nil, _ geometry : GeometryProxy? = nil) -> Int? {

      if(navigation == nil) {return nil}

      if(compute == true)
      {
         var value : Int? = nil
         var noSeq = 0

         if(location == nil) { return  nil}

         for w : Waypoint in navigation!.segments
         {
            let p = projectOnClippedMap(waypoint: w, geometry: geometry!)
            if( areCloseEnough( location!, p )) {
                value = noSeq
               break
            }
            noSeq += 1
         }
         return value
      }
      // on retourne l'index
      return selectedIndex.waypoint
   }

   //-----------------------------------------------------------------------
   //
   //-----------------------------------------------------------------------

   func findSelectedSegment(compute : Bool, _ location : CGPoint? = nil, _ geometry : GeometryProxy? = nil) -> Int? {
      guard let _ = navigation else {return nil}

      if(compute == true)
      {
         guard let _ = location else {return nil}

         var value : Int?
         var noSeq = 0
         var prevWpt : CGPoint?

         //if(location == nil) { return nil }

         for w : Waypoint in navigation!.segments
         {
            let p = projectOnClippedMap(waypoint: w, geometry: geometry!)
            if(prevWpt != nil)
            {
               let dx = (p.x - prevWpt!.x)
               let carreDistance : CGFloat
               let lambda : CGFloat

               if(abs(dx) > EPSILON) {
                  let pente = (p.y - prevWpt!.y) / (p.x - prevWpt!.x)
                  let mm = location!.y - prevWpt!.y - pente * (location!.x - prevWpt!.x)
                  carreDistance = mm * mm / (1 + pente * pente)

                  lambda = ((location!.x-prevWpt!.x) + pente * (location!.y-prevWpt!.y)) / ((p.x-prevWpt!.x) * (1 + pente * pente))
               }
               else {
                  carreDistance = (location!.x - p.x) * (location!.x - p.x)
                  lambda = (location!.y - prevWpt!.y)/(p.y - prevWpt!.y)
               }
               let DIST_MAX_CARREE : CGFloat = 49
               if( carreDistance < DIST_MAX_CARREE) &&
                  lambda > 0 && lambda < 1 {
                  value = noSeq
                  break
               }
            }
            prevWpt = p
            noSeq += 1
         }
         return value
      }

      return selectedIndex.segment
   }

   //-----------------------------------------------------------------------
   //
   //-----------------------------------------------------------------------

   func modifySelectedWaypoint(_ translation : CGSize)
   {
      guard let _ = navigation else { return }

      if let n = findSelectedWaypoint(compute: false)
      {
         let w = navigation!.segments[n]
         var p = projectOnMap(w.coord.latitude, w.coord.longitude)

         p.x += translation.width * inverseZoomFactor
         p.y += translation.height * inverseZoomFactor

         let newPosition = inverseProj(p)
         w.coord = newPosition

         //TODO : recalculer le rectangle de la route (centrage de la carte)
      }
   }

   func insertWaypoint(_ location : CGPoint, _ geometry : GeometryProxy)
   {
      guard let _ = navigation else { return }

      if let n = findSelectedSegment(compute: false)
      {
         let p = CGPoint(x: (location.x - geometry.size.width / 2) * inverseZoomFactor +
                           centreImage.x,
                         y: (location.y - geometry.size.height / 2 ) * inverseZoomFactor +
                           centreImage.y )

         // on crée un Waypoint qu'on insère dans la route

         let w = Waypoint(description:"WPT", coord:inverseProj(p))
         navigation!.insertWaypoint(w, at: n)
      }

   }

   func appear()->Void {
      generator.prepare()

      // il n'y a pas encore eu de déplacement de la carte, useroffset étant nul,
      // on se contente de reprojeter le centre de la carte
      centreImage = self.projectOnMap(currentCenter.latitude, currentCenter.longitude)
   }

   //-----------------------------------------------------------------------
   /// Affiche la vue de la carte et des autres couches vectorielles, en particulier celle affichant la route
   /// - Bug :
   ///   - ne parvient pas à faire ofnctionner le feedback haptique quand l'utilisateur sélectionne un point ou un segment
   ///   - l'annulation des déplacements ne fonctionne pas vraiment (soit le point reste là où l'annulation a eu lieu, soit la sélection persiste après l'annulation
   /// 
   /// - TODO: #6 Implémenter le Undo/redo pour les gestures
   /// - TODO: #7 Nettoyer le code des gestures
   /// - TODO: #8 Implémenter le multiscan
   /// - TODO: #9 implémenter le positionnement aimanté des points sur alignements ou des poinnts d'entrée de chenaux par exemple

   var body:  some View {
      GeometryReader { geometry in
         VStack {
            //TODO: faire un peu de ménage dans les gesture qui alourdissent le code
            let minimumLongPressDuration = 0.5
            let longPressDrag = LongPressGesture(minimumDuration: minimumLongPressDuration)
               .sequenced(before: DragGesture())//minimumDistance: 0, coordinateSpace: .local))
               .updating($dragState) { value, state, transaction in
                  switch value {
                  // Long press begins.
                  case .first(true):
                     state = .pressing

                  // Long press confirmed, dragging may begin.
                  case .second(true, let drag):

                     if( drag != nil  &&
                           selectedIndex.waypoint == nil &&
                           selectedIndex.segment == nil)
                     {
                        selectedIndex.waypoint = findSelectedWaypoint(compute: true, drag!.startLocation, geometry)
                        if( selectedIndex.waypoint == nil)
                        {
                           selectedIndex.segment = findSelectedSegment(compute: true, drag!.startLocation, geometry)
                        }
                        
                        if(selectedIndex.segment != nil || selectedIndex.waypoint != nil) {
                           generator.selectionChanged()
                        }
                     }
                     state = .dragging(translation: drag?.translation ?? .zero, location: drag?.location ?? .zero)

                  // Dragging ended or the long press cancelled.
                  default:
                     state = .inactive
                     selectedIndex.waypoint = nil
                     selectedIndex.segment = nil
                  }
               }

               .onEnded { value in
                  guard case .second(true, let drag?) = value else { return }

                  // Mettre à jour la position du point déplacé

                  if(selectedIndex.waypoint != nil)
                  {
                     modifySelectedWaypoint(drag.translation)
                     selectedIndex.waypoint = nil
                  }

                  // Mise à jour du waypoint inséré

                  if(selectedIndex.segment != nil)
                  {
                     insertWaypoint(drag.location, geometry)
                     selectedIndex.segment = nil
                  }
               }

            drawCroppedMap(geometry: geometry)
               .onAppear(perform: appear)
               .clipped()
               .onTapGesture(count: 2, perform: {
                  toggleZoom()
               })
               .gesture(longPressDrag)
               .onLongPressGesture(minimumDuration: 1, maximumDistance: 10, perform: {
                  //TODO: #10 afficher le menu contextuel
                  let impact = UIImpactFeedbackGenerator(style: .heavy)
                  impact.impactOccurred()
                  print("LongPress")
               })

               // Déplacement de la carte
               .gesture(DragGesture()
                           .onChanged({ value in
                              setDeplacement(value, size:geometry.size)
                           })
                           .onEnded({_ in
                              saveOffset()   // on met à jour le déplacement global à la fin du DragGesture
                           })
               )
               // zoom de la carte
               .gesture(
                  MagnificationGesture()
                     .onChanged { amount in
                        setZoomLevel(amount)
                     }
                     .onEnded ({ _ in
                        saveZoomLevel()
                     })
               )
         }
      }

   }

   // MARK: - Projection sur la carte



   //-----------------------------------------------------------------------
   /// calcule la latitude à partir de la latitude croissante sphérique
   /// - parameter fromLC : valeur de la latitude croissante
   /// - returns : latitude en degrés
   ///
   /// Il s'agit bien de la latitude croissante sphérique. Elle est adaptée aux
   /// cartes WEB-Mercator qui utilisent cette version simplifiée de la latitude
   /// croissante.
   /// - SeeAlso : `func LC(latitude:)` qui réalise l'opération inverse


   func latFromLC(_ fromLC: Double) -> Double {
      atan(exp(fromLC)) * 360 / .pi - 90.0
   }


   //-----------------------------------------------------------------------
   /// calcule la latitude croissante spérique d'une latitude croissante
   /// - parameter latitude : latitude en degrés
   /// - returns : valeur de la latitude croissante sphérique
   ///
   /// Il s'agit bien de la latitude croissante sphérique. Elle est adaptée aux
   /// cartes WEB-Mercator qui utilisent cette version simplifiée de la latitude
   /// croissante.
   ///
   /// - SeeAlso :  `func latFromLC(_:)` qui réalise l'opération inverse



   func LC(_ fromLat: Double) -> Double {
      log(tan(.pi / 180.0 * fromLat / 2 + .pi / 4))
   }

   //-----------------------------------------------------------------------
   //
   // projection d'un point de coordonnées latitude, longitude (degrés) en
   // pixel sur la carte (coordonnées locales)
   //
   //-----------------------------------------------------------------------

   func projectOnMap(_ latitude : CLLocationDegrees, _ longitude: CLLocationDegrees) -> CGPoint {
      CGPoint(x: CGFloat(X_A * longitude + X_B),
              y: CGFloat(Y_A * LC(latitude) + Y_B))
   }

   //-----------------------------------------------------------------------
   //
   // Projection du waypoint sur le bitmap affiché (coordonnées locales
   // au bitmap)
   //
   //-----------------------------------------------------------------------

   func projectOnClippedMap(waypoint: Waypoint, geometry : GeometryProxy) -> CGPoint {
      let p : CGPoint = projectOnMap(waypoint.coord.latitude, waypoint.coord.longitude)
      return CGPoint(x: (p.x - ( centreImage.x  - deplacement.width )) / inverseZoomFactor + geometry.size.width / 2,
                     y: (p.y - ( centreImage.y  - deplacement.height)) / inverseZoomFactor + geometry.size.height / 2)
   }



   //-----------------------------------------------------------------------
   // Projection inverse (sphérique Mercator)
   // A partir d'un point en coordonnées locales (pixel) retourne le point
   // latitude, longitude (degrés) correspondant
   //-----------------------------------------------------------------------

   func inverseProj(_ p : CGPoint) -> CLLocationCoordinate2D
   {
      let lat = latFromLC( (Double(p.y) - Y_B) / Y_A)
      let lon = (Double(p.x) - X_B) / X_A
      return CLLocationCoordinate2D(latitude: lat, longitude: lon)
   }


   //-----------------------------------------------------------------------
   /// Crée un Waypoint à partir d'un point sur le bitmap
   /// - parameter p : `CGPoint` position du `Waypoint`, pixels sur le bitmap affiché
   /// - parameter geometry : géometrie de la vue
   /// - parameter name : nom du `Waypoint`, vide par défaut
   /// - returns : `Waypoint` qui se projette en `p`

   func waypointFromPoint(_ p : CGPoint, _ geometry : GeometryProxy,  _ name : String = "" ) -> Waypoint {
      let tempPosition = inverseProj(CGPoint(x: (p.x - geometry.size.width / 2) * inverseZoomFactor + centreImage.x,
                                             y: (p.y - geometry.size.height / 2 ) * inverseZoomFactor + centreImage.y))
      return Waypoint(description: name, coord: tempPosition)
   }
}


//MARK: - Preview -

//-----------------------------------------------------------------------
// Preview de la vue
//-----------------------------------------------------------------------

struct ScannedMapView_Previews: PreviewProvider {
   static var previews: some View {
      //      ScannedMapView(assetName:"Atlantique1",
      //                     mapCenter: CLLocationCoordinate2D(latitude: 47.5, longitude: -4.5),
      //                     1166.4339, 6978.24377, -66037.97, 64990.7486)

      ScannedMapView(mapCenter: CLLocationCoordinate2D(latitude: 47.5, longitude: -4.5))
         .previewDevice("iPhone 11 Pro")
   }
}
