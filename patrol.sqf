_group=(_this select 0);
_group setBehaviour "SAFE";
_group setSpeedMode "LIMITED";

_waypoints=4;
_distance=100;
_leader=leader _group;

// Create waypoints
for "_i" from 1 to _waypoints do {
    _pos =  [(getpos _leader select 0)-_distance*sin(random 359),(getPos _leader select 1)-_distance*cos(random 359)];

    _wp = _group addWaypoint [_pos, 0,_i];
    _wp setWaypointType "MOVE";
    [_group,_i] setWaypointTimeout [0,2,4];

    
    _name=format ["Waypoint %1,%2",_i,_group];
    _txt=format ["Waypoint %1",_i];
    _mkr=createMarker [_name,_pos];
    _mkr setMarkerShape "ICON";
    _mkr setMarkerType "empty";
    _mkr setMarkerText _txt;    
};


// Add cycle waypoint
_pos =  [(getpos _leader select 0)-_distance*sin(random 359),(getPos _leader select 1)-_distance*cos(random 359)];
_wp1 = _group addWaypoint [_pos, 0,(_waypoints+1)];
_wp1 setWaypointType "CYCLE";


_name=format ["Waypoint Cycle: %1",_group];
_txt=format ["Waypoint Cycle",_group];
_mkr=createMarker [_name,_pos];
_mkr setMarkerShape "ICON";
_mkr setMarkerType "empty";
_mkr setMarkerText _txt;    


// Add fired at event handler           
_EHkilledIdx = _leader addEventHandler ["FiredNear", 
{
    _unit=(_this select 0);
    _group=group _unit;
    
    _group setBehaviour "Combat";
    _group setSpeedMode "Normal";
    
    _index = currentWaypoint _group;
    deleteWaypoint [_group, _index];

    _unit removeAllEventHandlers "FiredNear";
}];