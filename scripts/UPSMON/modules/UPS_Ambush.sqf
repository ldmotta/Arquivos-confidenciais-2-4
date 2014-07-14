///////////////////////////////////////////////////////////////// Ambush module //////////////////////////////////////////////////////////////////////

Aze_SetAmbush = {

	private ["_npc","_ambushdir","_ambushdist","_ambushType","_Mines","_vdir","_npcdir","_positiontoambush","_diramb","_soldier","_mineposition","_roads","_minetype1","_minetype2","_rdmdir","_gothit"];
	
	_npc = _this select 0;
	_Ucthis = _this select 1;
	_ambushdir = "";
	_ambushType = 1;
	_ambushdist = KRON_UPS_ambushdist;
	_Mines = 3;
	_Minestype = 1;
	
	_ambushdir = ["AMBUSHDIR:",_ambushdir,_UCthis] call KRON_UPSgetArg;_ambushdir = ["AMBUSHDIR2:",_ambushdir,_UCthis] call KRON_UPSgetArg;
	_ambushType = if ("AMBUSH2" in _UCthis) then {2} else {_ambushType};_ambushType = if ("AMBUSHDIR2:" in _UCthis) then {2} else {_ambushType};_ambushType = if ("AMBUSH2:" in _UCthis) then {2} else {_ambushType};
	if ("AMBUSHDIST:" in _UCthis) then {_ambushdist = ["AMBUSHDIST:",_ambushdist,_UCthis] call KRON_UPSgetArg;} else {_ambushdist = 100};

	// Mine Parameter (for ambush)	
	if ("MINE:" in _UCthis) then {_Mines = ["MINE:",_Mines,_UCthis] call KRON_UPSgetArg;}; // ajout
	if ("MINEtype:" in _UCthis) then {_Minestype = ["MINEtype:",_Minestype,_UCthis] call KRON_UPSgetArg;}; // ajout	
	
	(group _npc) setFormation "LINE";
	(group _npc) setBehaviour "STEALTH";	// In stead of "AWERE" -> will make AI go prone and look for cover
	(group _npc) setSpeedMode "FULL";
	(group _npc) setCombatMode "BLUE";
	_vdir = vectordir _npc; // Ajout
	_npcdir= 0;
	sleep 2;
	_positiontoambush = getpos _npc;
	_soldier = _npc;
			
	if ((count units _npc) > 1) then {_soldier = (units _npc) select 1;};	
		
	{					
	// _x stop true;
	dostop _x;
	} foreach ((units _npc) - [_soldier]);
	
	_soldier setunitpos "UP";
			
	If (_ambushdir != "") then 
	{
		switch (_ambushdir) do 
		{
			case "NORTH": {_vdir = [0,1,0];_npcdir = 0;};
			case "NORTHEAST":{_vdir = [0.842,0.788,0];_npcdir = 45;};
			case "EAST": {_vdir = [1,0,0];_npcdir = 90;};
			case "SOUTHEAST": {_vdir = [0.842,-0.788,0];_npcdir = 135;};
			case "SOUTH": {_vdir = [0,-1,0];_npcdir = 180;};
			case "SOUTHWEST": {_vdir = [-0.842,-0.788,0];_npcdir = 225;};
			case "WEST": {_vdir = [-1,0,0];_npcdir = 270;};
			case "NORTHWEST": {_vdir = [-0.842,0.788,0];_npcdir = 315;};
		};
	};	


	_gothit = [_npc] call Aze_GothitParam;
	
	If (_gothit) exitwith {_positiontoambush};
	
	_diramb = getDir _npc;
			
	If (_ambushdir != "") then {_diramb = _npcdir;};
	If ("gdtStratisforestpine" == surfaceType getPosATL _npc) then {_ambushdist = 50;};
	If ((count(nearestobjects [_npc,["house","building"],20]) > 4)) then {_ambushdist = 18;};
			
			
	//Puts a mine if near road
	if ( KRON_UPS_useMines && _ambushType == 1 ) then 
	{	
		if (KRON_UPS_Debug>0) then {player sidechat format["%1: Putting mine for ambush",_grpidx]}; 	
		if (KRON_UPS_Debug>0) then {diag_log format["UPSMON %1: Putting mine for ambush",_grpidx]}; 
				
		sleep 1;
		_mineposition = [position _npc,_diramb, _ambushdist] call MON_GetPos2D;					
		_roads = (getpos _npc) nearRoads 50; // org value 40 - ToDo check KRON_UPS_ambushdist value
				
		If (count _roads <= 0) then 
		{
			_roads = (getpos _npc) nearRoads 100;			
		};
				
		if (count _roads > 0) then 
		{
			_roads = [_roads, [], { _npc distance _x }, "ASCEND"] call BIS_fnc_sortBy;
			_positiontoambush = position (_roads select 0);
		};	

		if (KRON_UPS_Debug>0) then {diag_log format["%1: Roads #:%2 Pos:%3 Dir:%4",_grpidx, _roads,_positiontoambush,_npcdir]}; 
				_minetype1 = "ATMine";
				_minetype2 = "APERSBoundingMine";
				
		switch (_Minestype) do 
		{
			case "1": {_minetype2 = _minetype1;};
			case "2":{_minetype2 = _minetype2;};
			case "3": {_minetype1 = _minetype2;};
		};
				
		if (count _roads < 0 && _Mines > 0) then 
		{				
			if ([_soldier,_mineposition,_minetype2] call MON_CreateMine) then {_Mines = _Mines -1;_i =1;};
		};
		
		while {_Mines > 0} do
		{

			_i = 0;
			if (KRON_UPS_Debug>0) then {diag_log format["%1 Current Roads #:%2 _Mines:%3",_grpidx, (count _roads),_Mines]}; 
			if (count _roads > 0) then 
			{
				_mineposition = position (_roads select 0); 
				_roads = [];
				if ([_soldier,[(_mineposition select 0) + (random 0.7),(_mineposition select 1) + (random 0.5),_mineposition select 2],_minetype1] call MON_CreateMine) then {_Mines = _Mines -1; _i =1;};
			} 
			else 
			{	
			
			
					if (floor random 50 > 100) then 
				{
					_rdmdir = (_npcdir + (random 80) + 10) mod 360;				
				}
				else
				{
					_rdmdir = (_npcdir + 270 + (random 80)) mod 360;
				};		
			
				_mineposition = [_positiontoambush,_rdmdir,(random 30) + 10] call MON_GetPos2D;						
				if (_Mines > 0) then {_Mine=createMine [_minetype2, _mineposition , [], 0]; (side _npc) revealMine _Mine;_Mines = _Mines -1;_i =1;};	
				if (KRON_UPS_Debug>0) then {_ballCover = "Sign_Arrow_Large_GREEN_F" createvehicle [0,0,0];_ballCover setpos _mineposition;};
						
			};
					
			if (KRON_UPS_Debug>0) then {diag_log format["UPSMON %1: mines left: [%2]",_grpidx, _Mines]};
					
			sleep 0.1;
			
			if (_i != 1) then {_Mines = _Mines -1;}; //in case no mine was set
		};
				
		_mineposition = _positiontoambush;
				
	};				
	_AmbushPosition = [_npc,_diramb,_ambushdir,_positiontoambush,_ambushdist,_soldier] call Aze_FindAmbushPos;
	sleep 0.05;	
	{
		_x domove _AmbushPosition; 
	} foreach units _npc;
	
	_npc setbehaviour "CARELESS";
	
	waituntil {((_soldier distance _AmbushPosition <=10) && (_npc distance _AmbushPosition <=10)) || (!alive _npc) || (!canstand _npc) || (!alive _soldier) || (!canstand _soldier)};
	sleep 1;
										
	if (!alive _npc || !canmove _npc || isplayer _npc ) exitwith {_positiontoambush};
	
	_gothit = [_npc] call Aze_GothitParam;
		
	If (!_gothit) then 
	{
		_npc dowatch objNull;
		sleep 0.5;
		_npc dowatch [_positiontoambush select 0,_positiontoambush select 1,1];
		sleep 0.5;
		_vdir = vectordir _npc;
		_npc dowatch objNull;
			
		If ((count(nearestobjects [_npc,["house","building"],30]) > 2)) then 
		{
			[_npc,50,false,9999,true] spawn MON_moveNearestBuildings;
		} 
		else 
		{
			_dist = 50;
			If ("gdtStratisforestpine" == surfaceType getPosATL _npc) then {_dist = 20;};
			If ((count(nearestobjects [_npc,["house","building"],40]) > 3)) then {_dist = 15;};
			[units group _npc,_vdir,_positiontoambush,_dist] spawn UPS_fnc_find_cover;
		};
			
	}
	else
	{
		(group _npc) setCombatMode "YELLOW";
	};
	
	_positiontoambush
};


Aze_FindAmbushPos = {

	private ["_npc","_diramb","_ambushdir","_positiontoambush","_ambushdist","_soldier","_AmbushPosition","_AmbushPositions","_markerstr","_dirposamb"];
	_npc = _this select 0;
	_diramb = _this select 1;
	_ambushdir = _this select 2;
	_positiontoambush = _this select 3;
	_ambushdist = _this select 4;
	_soldier = _this select 5;
		
			
	_dirposamb = ((_diramb) +180) mod 360;
	
	
	_AmbushPosition = [_positiontoambush,_dirposamb, _ambushdist] call MON_GetPos2D;
	_AmbushPositions = [_positiontoambush,_dirposamb,_ambushdist,_soldier,_ambushdir] call Aze_fnc_Overwatch;
			
			
	if (count _AmbushPositions > 0) then 
	{
		_AmbushPositions = [_AmbushPositions, [], { _npc distance _x }, "ASCEND"] call BIS_fnc_sortBy;
		_AmbushPosition = _AmbushPositions select 0;
	
	};
	
	_AmbushPosition
};

Aze_fnc_Overwatch = {
	private ["_position","_dirposamb","_distance","_man","_ambushdir","_direction","_i","_obspos","_FS","_insight"];
	_position = _this select 0;
	_dirposamb = _this select 1;
	_distance = _this select 2;
	_man = _this select 3;
	_ambushdir = _this select 4;
	
	_direction = 0;
	_i = 0;
	_obspos = [];
	
	_loglos = "logic" createVehicleLocal [0,0,0];
	_orig = "RoadCone_F" createVehicleLocal _position;
	
	while {count _obspos < 3 && _i < 30} do
	{
		_direction = ((floor random 360) +180) mod 360;
		
		If (_ambushdir != "") then
		{
			if (floor random 50 > 100) then 
			{
				_direction = (_dirposamb + (random 100)) mod 360;				
			}
			else
			{
				_direction = (_dirposamb + 270 +(random 100)) mod 360;
			};
			diag_log format["PosDirAmb #:%1 Direction:%2",_dirposamb,_direction];
		};
		
		_obspos1 = [_position,_direction, _distance + (random 30)] call MON_GetPos2D;

		_dest = "RoadCone_F" createVehicleLocal _obspos1;
		hideObject _dest;
		hideObject _orig;
		_los_ok = [_loglos,_orig,_dest,20, 0.5] call mando_check_los;

		If (_los_ok) then 
		{
			_objects = [ (nearestObjects [_obspos1, [], 50]), { _x call fnc_filter } ] call BIS_fnc_conditionalSelect;
			If (count _objects < 10) then
			{
				_los_ok = false;
			};
			If (count (_obspos1 nearRoads 50) > 0) then
			{
				_los_ok = false;
			};
		};
		
		if (_los_ok) then 
		{
			_obspos = _obspos + [_obspos1];
			if (KRON_UPS_Debug>0) then 
			{
				diag_log format["Positions #:%1",_obspos1];
				//Make Marker
				_markerstr = createMarker[format["markername%1_%2",_i,name _npc],_obspos1];
				_markerstr setMarkerShape "ICON";
				_markerstr setMarkerType "mil_flag";
				_markerstr setMarkerColor "ColorGreen";
				_markerstr setMarkerText format["markername%1_%2",_i,_npc];
			};
		};

		sleep 0.5;
		deletevehicle _dest;
		_i = _i +1;
	};
	
	
	deletevehicle _loglos;
	deletevehicle _orig;
	_obspos
};

Aze_CanSee = {
	private ["_see","_infront","_uposASL","_opp","_adj","_hyp","_eyes","_obstruction","_angle"];

	_unit = _this select 0;
	_angle = _this select 1;
	_hyp = _this select 2;


	_eyes = eyepos _unit;

	
	_adj = _hyp * (cos _angle);
	_opp = sqrt ((_hyp*_hyp) - (_adj * _adj));

	
	_infront = if ((_angle) >=  180) then 
	{
		[(_eyes select 0) - _opp,(_eyes select 1) + _adj,(_eyes select 2)]
	} 
	else 
	{
		[(_eyes select 0) + _opp,(_eyes select 1) + _adj,(_eyes select 2)]
	};

	_obstruction = (lineintersectswith [_eyes,_infront,_unit]) select 0;


	_see = if (isnil("_obstruction")) then {true} else {false};

	_see
};
