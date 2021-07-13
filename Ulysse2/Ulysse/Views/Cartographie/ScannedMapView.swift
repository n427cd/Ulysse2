//
//  ScannedMapView.swift
//  Ulysse
//
//  Created by Eric Duchenne on 08/06/2021.
//

import Foundation
import SwiftUI
import CoreGraphics
import CoreLocation



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

   let cgimg : CGImage

   let X_A, X_B : Double       // coeff. de transformation (longitude) -> (eastings) x = g x X_A + X_B
   let Y_A, Y_B : Double       // coeff. de transformation (Lat croissante) -> (northings) y = LC x Y_A + Y_B

   @State private var centreImage = CGPoint()      // coord. (x,y) du bitmap au centre de la vue

   @State private var currentAmount: CGFloat = 1
   @State private var currentZoomFactor: CGFloat = 1

   @State var inverseZoomFactor : CGFloat = 1.0

   @State private var deplacement : CGSize = .zero     // valeur du déplacement en cours
   @State private var userOffset : CGSize = .zero      // valeur du déplacement cumulé jusqu'au dernier déplacement terminé

   var navigation : Route?
   var bDisplayRoute = false


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

      self.init(assetName: "Atlantique1", mapCenter: mapCenter, 1150, 7000, -66185.8, 65131.085, route: route, showRoute: showRoute)

   }


   //MARK: - Dessin de la carte affichée -





   /// Construit le fond de carte qui convient au centre de la carte et à
   /// la taille de la fenêtre, avec les différentes couches d'informations
   /// supplémentaires
   /// - parameter geometry : géométrie de la vue
   /// - returns : `Image?` contenant la carte et les différentes couches
   ///              d'information

   func drawCroppedMap(geometry : GeometryProxy) ->  Image? {
      guard let _ = fileName else { return Image(systemName : "exclamationmark.circle")}

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

      // Si la couverture cartographique n'est pas suffisante, retourne une
      // image qui l'indique

      return Image(systemName:"rectangle.slash")
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



   /// Met à jour le niveau de zoom
   ///
   /// L'évolution est multiplicative, c'est à dire que le zoom est
   /// mutiplié par `currentAmount`

   fileprivate func updateZoomLevel() {
      currentZoomFactor *= currentAmount
      currentAmount = 1
      inverseZoomFactor = 1/currentZoomFactor
   }

   /// Vérifie si deux points à l'écran peuvent être considérés voisins
   ///
   /// - parameter p : coordonnées écran du premier point
   /// - parameter q : coordonnées écran du second point
   ///
   /// - returns `true` si les deux points sont proches, '`false` sinon
   ///
   /// On regarde si le carré de la distance entre les points est inférieur
   /// au seuil défini

   func areNeighbours(_ p : CGPoint, _ q : CGPoint) -> Bool {
      /// carré de la distance de la boule
      let VICINITY : CGFloat = 200
      return (p.x - q.x) * (p.x - q.x)  + (p.y - q.y) * (p.y - q.y) < VICINITY
   }


   //-----------------------------------------------------------------------
   /**
    Détermine le waypoint qui est est en cours de sélection pendant les gestures

    - parameter compute : indicateur qui va déterminer si l'index doit être
                          calculé (`true`) ou simplement lu (`false`)
    - parameter location : `CGPoint` position du tap de l'utilisateur
    - parameter geometry : géométrie de la fenêtre

    - returns : l'index du waypoint sélectionné dans la route. Si le point choisi
                ne correspond pas à un waypoint à l'écran, retourne `nil`

    S'il y a besoin de rafraîchir la sélection, on calcule l'index en
    parcourant la liste des waypoints pour regarder si l'un d'entre eux
    se trouve à proximité du point indiqué par l'utilisateur

    - Important : l'index n'est pas mis à jour par la fonction. Il doit être mis
      à jour spécifiquement, par exemple :

         ````
         `selectedIndex.waypoint = findSelectedWaypoint(update: true,
                                          drag!.startLocation, geometry)
         ````
    */

   func findSelectedWaypoint(compute : Bool, _ location : CGPoint? = nil, _ geometry : GeometryProxy? = nil) -> Int? {

      guard let _ = navigation else { return nil}

      // si on doit déterminer l'index, on lance le calcul, et on retourne
      // la valeur trouvée sans modifier `selectedIndex.waypoint`

      if(compute == true)
      {
         guard let _ = location else { return nil }

         var value : Int?
         var noSeq = 0

         for w : Waypoint in navigation!.segments
         {
            // on récupère les coordonnées à l'écran du waypoint
            let p = projectOnClippedMap(waypoint: w, geometry: geometry!)
            if( areNeighbours( location!, p )) {
                value = noSeq
               break
            }
            noSeq += 1
         }
         return value
      }
      // on veut juste la dernière valeur de l'index qu'on retourne
      else {
         return selectedIndex.waypoint
      }
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
//                  if(selectedIndex.waypoint == nil && selectedIndex.segment == nil)
//                  {
//
//                  }
               }

            drawCroppedMap(geometry: geometry)
               .onAppear(perform: appear)
               .clipped()
               .onTapGesture(count: 2, perform: { toggleZoom() })
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
                        updateZoomLevel()
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
