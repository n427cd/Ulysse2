# Ulysse

Application iOS pour la préparation et le suivi de navigations nautiques, proposant la visualisation des avis urgents aux navigateurs, les bulletins de Météo France, les marées, et les cartes marines.

## Roadmap

### Sprint 1 :
#### Avis aux navigateurs
- récupération des avis aux navigateurs des différentes régions, de manière asynchrone #19
- sauvegarde des avis lus et téléchargés https://github.com/n427cd/Ulysse2/issues/20#issue-946548150
#### Cartographie
- affichage d'une carte, différents niveaux de zooms, système de tuiles éventuellement adapté
- affichage de la route, et du log de nav avec fonctions essentielles : validation du passage d'un waypoint, marquage de la position actuelle
- affichage à la demande du cône d'incertitude de l'estime, par exemple à ± 5°
- modification de la route : ajout, déplacement suppression de waypoint
#### Météo
- affichage du bulletin météo, général, de la zone
- récupération de la carte radar
- récupération du tableau de prévision hauteur de vagues, mer du vent, rafales, etc...
#### Marée
- affichage des heures de marées d'un lieu, calcul de hauteur d'eau / durée

### Sprint 2 : 
#### Interface utilisateur
- définir les cas d'utilisation et propositions d'alternatives d'UI
#### Avis aux navigateurs
- extention de la localisation des avis aux navigateurs par le toponyme
- affichage des polygones des zones concernées par l'avis
- recherche textuelle dans les avis
- sélection des avis concernant la route active
#### Cartographie
- ajout des alignements / aimantation des waypoints sur les alignements
- surimpression d'infos météo
#### Météo
- récupération de gribs, affichage des gribs
- calcul des zones d'inconfort (houle, vent, / profondeur,...)
#### Marée
- détermination des courants

### Sprint 3 : 
#### Interface utilisateur
- choix et implémentation finale de l'UI
#### Avis aux navigateurs
- essai de classification des avis par nature
- impression / pdf / transfert des avis sélectionnés
#### Cartographie
- fluidité d'affichage des cartes
- polaires bateau et routage
#### Météo
#### Marée

