import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.Dynel;
import com.GameInterface.Nametags;
import com.GameInterface.Waypoint;
import com.GameInterface.WaypointInterface;
import com.Utils.ID32;
import flash.geom.Point;
import mx.utils.Delegate;

import lp.mobmarkers.utils.ArrayUtils;
import lp.mobmarkers.utils.StringUtils;
import lp.mobmarkers.utils.JSON;

class lp.mobmarkers.Main {
    
    private static var s_app:Main;

    private var m_swfRoot:MovieClip;
    private var m_dynels:Array;
    private var m_screenWidth:Number;
    private var m_settings:Object; // {zones: {[zone: String]: String}}

    private var m_settingsCommand:DistributedValue;
    private var m_addZoneCommand:DistributedValue;
    private var m_removeZoneCommand:DistributedValue;
    
    private var m_initialized:Boolean;

    public static function main(swfRoot:MovieClip) {
        s_app = new Main(swfRoot);
        
        swfRoot.onLoad = function() { Main.s_app.OnLoad(); };
        swfRoot.OnUnload = function() { Main.s_app.OnUnload(); };
    }

    public function Main(swfRoot: MovieClip) {
        m_swfRoot = swfRoot;
    }
    
    public function OnLoad() {
        m_initialized = false;
        
        m_swfRoot.onEnterFrame = Delegate.create(this, OnFrame);
        m_screenWidth = Stage["visibleRect"].width;
    }

    public function OnUnload() {
        m_swfRoot.onEnterFrame = undefined;
        
        Nametags.SignalNametagAdded.Disconnect(Add, this);
        Nametags.SignalNametagRemoved.Disconnect(Add, this);
        Nametags.SignalNametagUpdated.Disconnect(Add, this);
        
        WaypointInterface.SignalPlayfieldChanged.Disconnect(PlayFieldChanged, this);
        
        m_settingsCommand.SignalChanged.Disconnect(ParseSettings, this);
        m_settingsCommand = undefined;
        
        m_addZoneCommand.SignalChanged.Disconnect(AddZone, this);
        m_addZoneCommand = undefined;
        
        m_removeZoneCommand.SignalChanged.Disconnect(RemoveZone, this);
        m_removeZoneCommand = undefined;
        
        for (var i in m_dynels) {
            Remove(m_dynels[i].GetID());
        }
        
        m_initialized = false;
    }
    
    public function Init() {
        m_settingsCommand = DistributedValue.Create("AdvancedMobMarkers_Settings");
        m_settingsCommand.SignalChanged.Connect(ParseSettings, this);
        
        m_addZoneCommand = DistributedValue.Create("AdvancedMobMarkers_AddZone");
        m_addZoneCommand.SignalChanged.Connect(AddZone, this);
        
        m_removeZoneCommand = DistributedValue.Create("AdvancedMobMarkers_RemoveZone");
        m_removeZoneCommand.SignalChanged.Connect(RemoveZone, this);
        
        ParseSettings();
        
        m_dynels = [];
        
        Nametags.SignalNametagAdded.Connect(Add, this);
        Nametags.SignalNametagRemoved.Connect(Add, this);
        Nametags.SignalNametagUpdated.Connect(Add, this);
        
        Nametags.RefreshNametags();
        
        WaypointInterface.SignalPlayfieldChanged.Connect(PlayFieldChanged, this);
        
        m_initialized = true;
    }
    
    private function OnFrame() {
        if (!m_initialized && _root.waypoints.m_CurrentPFInterface) {
            Init();
        }
        
        for (var i in m_dynels) {

            var dynel:Dynel = m_dynels[i];
            if (!ShouldWatch(dynel)) {
                Remove(dynel.GetID());
                return;
            }
            
            var waypointClip:MovieClip = _root.waypoints.m_RenderedWaypoints[dynel.GetID()];
            
            if (!waypointClip) {
                return;
            }
            
            waypointClip.m_Waypoint.m_DistanceToCam = dynel.GetCameraDistance();
            var screenPosition:Point = dynel.GetScreenPosition();
            waypointClip.m_Waypoint.m_ScreenPositionX = screenPosition.x;
            waypointClip.m_Waypoint.m_ScreenPositionY = screenPosition.y;
            waypointClip.Update(m_screenWidth);

        }
    }
    
    private function Add(id:ID32) {
        var dynel:Dynel = Dynel.GetDynel(id);
        var zonePattern:String = m_settings.zones[Character.GetClientCharacter().GetPlayfieldID()];
        var alreadyTracking:Boolean = ArrayUtils.Contains(m_dynels, dynel);
        var nameMatches:Boolean = MatchString(zonePattern, dynel.GetName());

        if (alreadyTracking && (!nameMatches || !zonePattern)) {
            Remove(id);
            return;
        } else if (alreadyTracking || !nameMatches || !zonePattern) {
            return;
        }
        
        if (dynel.GetStat(_global.Enums.Stat.e_CarsGroup) != 3 && !IsNonTargetableEnemy(dynel)) {
            return;
        }
                
        if (ShouldWatch(dynel)) {            
            var waypoint:Waypoint = new Waypoint();
            waypoint.m_WaypointType = _global.Enums.WaypointType.e_RMWPScannerBlip;
            waypoint.m_WaypointState = _global.Enums.QuestWaypointState.e_WPStateActive;
            waypoint.m_IsScreenWaypoint = true;
            waypoint.m_IsStackingWaypoint = true;
            waypoint.m_Radius = 0;
            waypoint.m_Color = 0xFFFF00;
            waypoint.m_CollisionOffsetX = 0;
            waypoint.m_CollisionOffsetY = 0;
            waypoint.m_MinViewDistance = 0;
            waypoint.m_MaxViewDistance = 500;
            waypoint.m_Id = dynel.GetID();
            waypoint.m_Label = dynel.GetName();
            waypoint.m_WorldPosition = dynel.GetPosition();
            var screenPosition:Point = dynel.GetScreenPosition();
            waypoint.m_ScreenPositionX = screenPosition.x;
            waypoint.m_ScreenPositionY = screenPosition.y;
            waypoint.m_DistanceToCam = dynel.GetCameraDistance();
            
            _root.waypoints.m_CurrentPFInterface.m_Waypoints[dynel.GetID().toString()] = waypoint;
            _root.waypoints.m_CurrentPFInterface.SignalWaypointAdded.Emit(waypoint.m_Id);
            
            m_dynels.push(dynel);
        }
    }
    
    private function Remove(id:ID32) {
        var dynel:Dynel = Dynel.GetDynel(id);
        
        ArrayUtils.Remove(m_dynels, dynel);
        delete _root.waypoints.m_CurrentPFInterface.m_Waypoints[id.toString()];
        _root.waypoints.m_CurrentPFInterface.SignalWaypointRemoved.Emit(id);
    }
    
    private function ShouldWatch(dynel:Dynel): Boolean {
        if (dynel.IsDead() || !dynel.GetDistanceToPlayer()) {
            return false;
        }
        
        return true;
    }
    
    private function PlayFieldChanged() {
        m_dynels = [];
    }
    
    private function ParseSettings() {
        var settingsValue:String = m_settingsCommand.GetValue().toString();
        try {
            m_settings = JSON.parse(settingsValue);
        } catch (ex) {
            var defSettings:String = "{\"zones\":{}}";
            m_settingsCommand.SetValue(defSettings);
            m_settings = JSON.parse(settingsValue);
        }
    }
    
    private function AddZone() {
        if (m_addZoneCommand.GetValue() == undefined) {
            return;
        }
        
        var commandValues:Array = m_addZoneCommand.GetValue().split(" ");
        var zone:String = String(commandValues.shift());
        
        m_settings.zones[zone] = commandValues.join(" ");
        m_settingsCommand.SetValue(JSON.stringify(m_settings));
        m_addZoneCommand.SetValue(undefined);
        
        Nametags.RefreshNametags();
    }
    
    private function RemoveZone() {
        if (m_removeZoneCommand.GetValue() == undefined) {
            return;
        }

        var zone:String = m_removeZoneCommand.GetValue();
        
        delete m_settings.zones[zone];
        m_settingsCommand.SetValue(JSON.stringify(m_settings));
        m_removeZoneCommand.SetValue(undefined);
        
        Nametags.RefreshNametags();
    }
    
    private function MatchString(pattern: String, input: String): Boolean {
        var patternItems:Array = pattern.split("|");
        for (var patternItemsIndex in patternItems) {
            var patternItem:String = patternItems[patternItemsIndex];
            var trimmedItem:String = StringUtils.Trim(patternItem);
            
            if (!trimmedItem) {
                continue;
            }
            
            var openStart:Boolean = trimmedItem.charAt(0) == '*';
            var openEnd:Boolean = trimmedItem.charAt(trimmedItem.length - 1) == '*'
            
            var itemWithoutWildcards:String = StringUtils.Trim(trimmedItem, '*');
            var foundIndex:Number = input.toLowerCase().indexOf(itemWithoutWildcards.toLowerCase());
            
            if (foundIndex < 0) {
                continue;
            }
            
            if (!openStart && foundIndex != 0) {
                continue;
            }
            
            if (!openEnd && foundIndex + itemWithoutWildcards.length != input.length) {
                continue;
            }
            
            return true;
        }
        
        return false;
    }
    
    private function IsNonTargetableEnemy(dynel: Dynel): Boolean {
        // Into Darkness
        if (dynel.GetPlayfieldID() == 1120 && dynel.GetName() == "Filthy Mobster") {
            return true;
        }

        return false;
    }
}