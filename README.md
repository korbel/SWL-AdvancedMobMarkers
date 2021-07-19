# AdvancedMobMarkers SWL mod

This mod is a rewrite of [xeio's original MobMarkers mod](https://github.com/Xeio/MobMarkers). It adds more advanced configuration options and it has the ability to show invisible/untargetable enemies.


## Installation instructions

Extract the zip file into `<SWL directory>\Data\Gui\Custom\Flash\` and restart the game.


## Usage

To check the current settings, type the following command in-game:

    /setoption AdvancedMobMarkers_Settings

To set settings for a zone (see details below):

    /setoption AdvancedMobMarkers_AddZone "<zone_id> <expression>"

To clear the settings for a zone:

    /setoption AdvancedMobMarkers_RemoveZone <zone_id>
  

To get the zone ID for the current zone, press Shift+F9 and the game will tell you in the chat (you may have to enable the System channel). You should see something like this:

    Dim: 10 Server: 79 
    Pos: 165.7, 263.7, y 27.8 1000
    Zone: 0
    Server: gs034-nj4.secretworld.com:7005 (id:64 global:79)

The zone ID is right after your coordinates, in this case it is 1000
  
The expression parameter tells which mobs you want to mark in the given zone.
A valid expression can start or end with * joker character and can have multiple expressions joined together with the | character. The matching is not case sensitive.
  
### Examples:

    /setoption AdvancedMobMarkers_AddZone "5715 *lurker*|*titan*|*guardian*"  ### Mark anything that has lurker, titan or guardian in its name in NYR E10 zone
    /setoption AdvancedMobMarkers_AddZone "3140 Swallowed Centurion|Shade from Beyond|Bringer of the Beyond|Septimus|Neesh-Um, the Stalker of Nightmares|Deus Sol Invictus Ritualist" ### Mark all the shades in CF Roman Baths
    /setoption AdvancedMobMarkers_AddZone "1120 *" ### Mark everything in Co-op City Parking Garage (Into Darkness quest)
