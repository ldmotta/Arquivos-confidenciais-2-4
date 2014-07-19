UPSMON_AddArtillery = {
	private ["_area","_maxcadence","_mincadence","_rounds","_vector","_static","_typeunit","_grp","_cfgArtillery","_grpunits","_batteryunits","_assistsmortar","_unit","_vehicle","_result","_staticteam","_artimuntype","_id","_foundshell","_foundsmoke","_foundrocket","_foundillum","_vector","_sidearty"];

	_area = 50;
	_maxcadence = 6;
	_mincadence = 3;
	_rounds = [10,30,50];	
	_vector =[];
	_static = false;
	_typeunit = "MAN";
	
	_grp  = _this select 0;	
	
	_cfgArtillery = 0;
	_grpunits = units _grp;
	_batteryunits = [];
	_assistsmortar = [];
	_artillery = "";
	
	{
		if (alive _x) then
		{
			_unit = _x;
			_vehicle = vehicle _x;
			_cfgArtillery = getnumber (configFile >> "cfgVehicles" >> (typeOf (_vehicle)) >> "artilleryScanner");
			if (_cfgArtillery == 1 && !(vehicle _unit in _batteryunits)) then {_batteryunits = _batteryunits + [vehicle _unit];_artillery = typeOf (_vehicle);};
		};
	} foreach _grpunits;		

	If (count _batteryunits == 0) then
	{
		_result = [_grp] call UPSMON_GetStaticTeam;
		_vehicle = _result select 1;
		_staticteam = _result select 0;
		If (count _staticteam == 2) then
		{
			_cfgArtillery = getnumber (configFile >> "cfgVehicles" >> _vehicle >> "artilleryScanner");
			if (_cfgArtillery == 1 && !(vehicle _unit in _batteryunits)) then {_batteryunits = _batteryunits + [vehicle (_staticteam select 0)];_assistsmortar = _assistsmortar + [(_staticteam select 1)]};
		};
		_artillery = _vehicle;
	};
	
	if (count _batteryunits == 0) exitwith {_static};
	
	_cfgArtillerymag = getArray (configFile >> "cfgVehicles" >> _artillery >> "Turrets" >> "MainTurret" >> "magazines");
	_artimuntype = [0,0,0];
	_id = -1; 
	{
		_foundshell=[_x,"shells"] call UPSMON_StrInStr;
		if (!_foundshell) then {_foundshell=[_x,"HE"] call UPSMON_StrInStr;};
		_foundrocket=[_x,"rockets"] call UPSMON_StrInStr;
		_foundsmoke=[_x,"smoke"] call UPSMON_StrInStr;
		if (!_foundsmoke) then {_foundsmoke=[_x,"WP"] call UPSMON_StrInStr;};
		_foundillum=[_x,"Flare"] call UPSMON_StrInStr;
		if (!_foundillum) then {_foundillum=[_x,"ILLUM"] call UPSMON_StrInStr;};
		If (_foundshell || _foundrocket) then {_artimuntype set [2,1]};
		If (_foundsmoke) then {_artimuntype set [1,1]};
		If (_foundillum) then {_artimuntype set [0,1]};
	} foreach _cfgArtillerymag;

	{
		_id = _id + 1;
		if (_x != 0 && (_artimuntype select _id) != 1) then {_rounds set [_id,0];};
	} foreach _rounds;
	
	{
		If (_x iskindof "StaticWeapon") exitwith {_static = true; _typeunit = "STATIC"};
		If (_x iskindof "TANK" || _x iskindof "CAR") exitwith {_typeunit = "VEHICLE"};
	} foreach _batteryunits;
	
	//Add artillery to array of artilleries
	_vector = [false,_rounds,_area,_maxcadence,_mincadence,_batteryunits,_typeunit,_assistsmortar,_artillery];
	if ((count _this) > 1) then {_vector = _this select 1;};
	
	_sidearty = side _grp;


	switch (_sidearty) do {
		case West: {
		if (isnil "UPSMON_ARTILLERY_WEST_UNITS") then  {UPSMON_ARTILLERY_WEST_UNITS = []};
		UPSMON_ARTILLERY_WEST_UNITS = UPSMON_ARTILLERY_WEST_UNITS + [_grp];
		PublicVariable "UPSMON_ARTILLERY_WEST_UNITS";		
		};
		case EAST: {
		if (isnil "UPSMON_ARTILLERY_EAST_UNITS") then  {UPSMON_ARTILLERY_EAST_UNITS = []};
		UPSMON_ARTILLERY_EAST_UNITS = UPSMON_ARTILLERY_EAST_UNITS + [_grp];
		PublicVariable "UPSMON_ARTILLERY_EAST_UNITS";	
		};
		case resistance: {
		if (isnil "UPSMON_ARTILLERY_GUER_UNITS") then  {UPSMON_ARTILLERY_GUER_UNITS = []};
		UPSMON_ARTILLERY_GUER_UNITS = UPSMON_ARTILLERY_GUER_UNITS + [_grp];
		PublicVariable "UPSMON_ARTILLERY_GUER_UNITS";			
		};
	
	};
	
		
	if (UPSMON_Debug>0) then {diag_log format["MON_artillery_add: %1 %2",_grp,_typeunit]};
	
	_grp setVariable ["UPSMON_ArtiOptions",_vector];
	_grp setVariable ["UPSMON_OnBattery",false];

	_static
};

UPSMON_Artyhq = 
{
	private ["_artillerysidegrps","_firemission","_radiorange","_npcpos","_roundsask","_targetpos","_artigrp"];
	
	_artillerysidegrps = _this select 0;
	_firemission = _this select 1;
	_radiorange = _this select 2;
	_npcpos = _this select 3;
	_targetpos = _this select 4;
	_roundsask = _this select 5;
	_area = _this select 6;
	
	_artigrp = [_artillerysidegrps,_firemission,_RadioRange,_npcpos] call UPSMON_selectartillery;
	if (UPSMON_Debug>0) then {player sidechat format ["Arti: %1",_artigrp];};
	If !(IsNull _artigrp) then {
	[_artigrp,_firemission,_npcpos,_targetpos,_roundsask,_area] spawn UPSMON_artillerysetBattery;};
};

UPSMON_selectartillery = 
{
	private ["_support","_artiarray","_askMission","_RadioRange","_arti","_rounds","_artiarray","_artillerysidegrps","_npcpos","_support","_artibusy"];
	
	_artillerysidegrps = _this select 0;
	_askMission = _this select 1;
	_RadioRange = _this select 2;
	_npcpos = _this select 3;

	
	_arti = ObjNull;
	_rounds = 0;
	_artiarray = [_artillerysidegrps, [], { _npcpos distance (leader _x) }, "ASCEND"] call BIS_fnc_sortBy;
	{
		_arti = _x;
		_support = _x getVariable "UPSMON_ArtiOptions";
		_artibattery  = _support select 5;
		_artibusy  = _support select 0;
		
		If (count units _x > 0 && count _artibattery > 0) then
		{
		
			Switch (_askmission) do {
				case "HE": {
					_rounds = (_support select 1) select 2;
				};
		
				case "WP": {
					_rounds = (_support select 1) select 1;
				};
		
				case "FLARE": {
					_rounds = (_support select 1) select 0;
				};
			};
	
		}
		else
		{
			switch (side _x) do 
			{
				case West: 
				{
					UPSMON_ARTILLERY_WEST_UNITS = UPSMON_ARTILLERY_WEST_UNITS - [_x];
					PublicVariable "UPSMON_ARTILLERY_WEST_UNITS";		
				};
				case EAST: 
				{
					UPSMON_ARTILLERY_EAST_UNITS = UPSMON_ARTILLERY_EAST_UNITS - [_x];
					PublicVariable "UPSMON_ARTILLERY_EAST_UNITS";	
				};
				case resistance: 
				{
					UPSMON_ARTILLERY_GUER_UNITS = UPSMON_ARTILLERY_GUER_UNITS - [_x];
					PublicVariable "UPSMON_ARTILLERY_GUER_UNITS";			
				};
	
			};
		};
		
		If (!_artibusy && (round([getposATL (leader _arti),_npcpos] call UPSMON_distancePosSqr)) <= _RadioRange && _rounds > 0) exitwith 
		{
			_support set [0,true]; 
			_arti setVariable ["UPSMON_ArtiOptions",_support];
			_arti setVariable ["UPSMON_OnBattery",true];
			_arti
		};
			if (UPSMON_Debug>0) then {diag_log format ["Busy:%1 Distance:%2 RadioRange:%3 Rounds:%4",_artibusy,leader _x distance _npcpos,_RadioRange,_rounds];};
		
	} ForEach _artiarray;

	_arti
	
};
UPSMON_artillerysetBattery = {
	
	private ["_grp","_support","_askBullet","_target","_arti","_missionabort","_rounds","_range","_area","_maxcadence","_mincadence","_askmission","_fire","_targetpos","_auxtarget","_npc"];
	_grp = _this select 0;
	_support = _grp getVariable "UPSMON_ArtiOptions";
	
	// If (count _support <= 0 ) exitwith {if (UPSMON_Debug>0) then {player sidechat "ABORT: no support";};};
	
	
	_askMission = _this select 1;
	_npcpos = _this select 2;
	_targetpos = _this select 3;
	_roundsask = _this select 4;
	_area = _this select 5;
	
	_rounds = _support select 1;					
	_area = _support select 2;	
	_maxcadence = _support select 3;	
	_mincadence = _support select 4;
	_batteryunits = _support select 5;
	
	If (count _batteryunits == 0) 
	exitwith 
	{
		if (UPSMON_Debug>0) then {player sidechat "ABORT: no gunner";};
	};

	_arti = _support select 8;
	
	_askbullet = "";
	_missionabort = false;
	_foundshell=false;
	_foundrocket=false;
	_foundsmoke=false;
	_foundillum=false;
	_totalrounds = 0;
	
	_side = side _grp;
	_munradius = 100;	

	Switch (_askmission) do {
		case "HE": {
			_cfgArtillerymag = getArray (configFile >> "cfgVehicles" >> _arti >> "Turrets" >> "MainTurret" >> "magazines");
			{
				_foundshell=[_x,"shells"] call UPSMON_StrInStr;
				if (!_foundshell) then {_foundshell=[_x,"HE"] call UPSMON_StrInStr;};;
				_foundrocket=[_x,"rockets"] call UPSMON_StrInStr;
				If (_foundshell || _foundrocket) exitwith {_askbullet = _x; _munradius = 250; if (_foundrocket) then {_munradius = 400;};};
			} foreach _cfgArtillerymag;
			_totalrounds = _rounds select 2;
		};
		
		case "WP": {
			_cfgArtillerymag = getArray (configFile >> "cfgVehicles" >> _arti >> "Turrets" >> "MainTurret" >> "magazines");
			{
				_foundsmoke=[_x,"smoke"] call UPSMON_StrInStr;
				if (!_foundsmoke) then {_foundsmoke=[_x,"WP"] call UPSMON_StrInStr;};
				If (_foundsmoke) exitwith {_askbullet = _x; _munradius = 100;};
			} foreach _cfgArtillerymag;
			_totalrounds = _rounds select 1;
		};
		
		case "FLARE": {
			_cfgArtillerymag = getArray (configFile >> "cfgVehicles" >> _arti >> "Turrets" >> "MainTurret" >> "magazines");
			{
				_foundillum=[_x,"Flare"] call UPSMON_StrInStr;
				if (!_foundillum) then {_foundillum=[_x,"ILLUM"] call UPSMON_StrInStr;};
				If (_foundillum) exitwith {_askbullet = _x; _munradius = 0;};
			} foreach _cfgArtillerymag;
			_totalrounds = _rounds select 0;
		};
	
	};
	
	If(_totalrounds <=0) 
	exitwith 
	{
		if (UPSMON_Debug>0) then {player sidechat format ["ABORT: Arti: %1",_support select 0];};
		_support set [0,false];
		_grp setVariable ["UPSMON_ArtiOptions",_support];
		_grp setVariable ["UPSMON_OnBattery",false];
	};

	If (_foundsmoke) 
	then 
	{ 
		_vcttarget = [_npcpos, _targetpos] call BIS_fnc_dirTo;
		_dist = (_npcpos distance _targetpos)/2;
		_targetPos = [_npcpos,_vcttarget, _dist] call UPSMON_GetPos2D;
	};
	
	
		if (!isnil "_targetPos" || count _targetPos > 0) then 
		{
			//If target in range check no friendly squad near									
			if ((_targetPos inRangeOfArtillery [[_arti], _askbullet])) 
			then 
			{
				//Must check if no friendly squad near fire position

				{	
					if (alive (leader _x) && _side == side _x) then 
					{																								
						if ((round([getposATL (leader _x),_targetPos] call UPSMON_distancePosSqr)) <= (_munradius)) exitwith {_targetpos = [];};
					};										
				} foreach UPSMON_NPCs;
			}
			else
			{
				_missionabort = true; 
				if (UPSMON_Debug>0) then {player sidechat "Arti not in range";};
			};
			
		};
	
	If (count _targetPos > 0) then 
	{	
	
		if (UPSMON_Debug>0) then {player sidechat "FIRE";};
		[_grp,_targetPos,_area,_maxcadence,_mincadence,_askbullet,_support,_totalrounds,_roundsask] spawn UPSMON_artillerydofire;

	}
	else
	{
		if (UPSMON_Debug>0) then {player sidechat "ABORT: no more target";}; 
		_missionabort = true
	};
	
	If (_missionabort) then
	{
	
		if (UPSMON_Debug>0) then {player sidechat "ABORT: no more target";};
		_support set [0,false];
		_grp setVariable ["UPSMON_ArtiOptions",_support];
		_grp setVariable ["UPSMON_OnBattery",false];
	};
};

UPSMON_artillerydofire = {
	 
		private ["_smoke1","_i","_area","_position","_maxcadence","_mincadence","_sleep","_nbrbullet","_rounds","_grp","_timeout","_bullet"];
		
		_grp = _this select 0;
		_position  = _this select 1;	
		_area = _this select 2;	
		_maxcadence = _this select 3;	
		_mincadence = _this select 4;	
		_bullet = _this select 5;
		_support = _this select 6;
		_totalrounds = _this select 7;
		_roundsask = _this select 8;
		
		_supportrounds = _support select 1;
		_batteryunits = _support select 5;
		_typeofunit = _support select 6;
		_assistsmortar = _support select 7;
		_npc = leader _grp;
		_support2 = [];
		
		_rounds = 3;
		
		_foundshell=[_bullet,"shells"] call UPSMON_StrInStr;
		if (!_foundshell) then {_foundshell=[_bullet,"HE"] call UPSMON_StrInStr;};
		_foundrocket=[_bullet,"rockets"] call UPSMON_StrInStr;
		_foundsmoke=[_bullet,"smoke"] call UPSMON_StrInStr;
		if (!_foundsmoke) then {_foundsmoke=[_bullet,"WP"] call UPSMON_StrInStr;};
		_foundillum=[_bullet,"Flare"] call UPSMON_StrInStr;
		if (!_foundillum) then {_foundillum=[_bullet,"ILLUM"] call UPSMON_StrInStr;};
		
		_found155=[_bullet,"155mm"] call UPSMON_StrInStr;
		_found122=[_bullet,"Sh_122"] call UPSMON_StrInStr;
		If (!_found155 && !_found122) then {_roundsask = _roundsask*2;};
		If (_foundrocket) then {_roundsask = _roundsask/2;};
		
		If (_foundshell || _foundrocket) then 
		{
			_supportrounds = [_supportrounds select 0, _supportrounds select 1, (_supportrounds select 2) - _roundsask];
		};
		If (_foundsmoke) then 
		{
			_supportrounds = [_supportrounds select 0, (_supportrounds select 1) - _roundsask, _supportrounds select 2];
		};
			
		If (_roundsask > _totalrounds) then {_roundsask = _totalrounds;};
		
		If (_foundillum)
		then {[] spawn UPSMON_Flaretime;
		_supportrounds = [(_supportrounds select 0) - _roundsask, _supportrounds select 1, _supportrounds select 2];};
		
		_area2 = _area * 1.4;
		
		if (UPSMON_Debug>0) then { player globalchat format["artillery doing fire on %1",_position] };	
		If (UPSMON_DEBUG > 0) then {[_position,"ColorBlue"] call fnc_createMarker;};
		
		If (_typeofunit != "STATIC") then
		{
			{
				Dostop _x;
			} foreach units _grp;
			
			_pos =  (getposATL _npc) isFlatEmpty [10,5,0.5,10,20,true];
			
			if (count _pos > 0) then
			{
				_pos = ASLtoATL(_pos select 0);
			}
			else
			{
				_pos = getposATL _npc;
			};
			
			
			If (_typeofunit == "MAN") then
			{
				_staticteam = _batteryunits + _assistsmortar;
				{
					If (alive _x && vehicle _x != _x && !((vehicle _x) getvariable ["UPSMON_disembarking",false])) then 
					{
						[vehicle _x] spawn UPSMON_dodisembark;
						_time = time + 90;
						waituntil {vehicle _x == _x || !alive _x || time >= _time};
					};
					If (!alive _x) exitwith {_batteryunits = [];};
				} foreach _staticteam; 
				
				If (count _batteryunits > 0) then
				{
					[_staticteam select 0,_staticteam select 0,_pos,_position] call UPSMON_Unpackbag;
				};
			};
		};
		
		sleep 5;
		_i = 0;
		
		while {_i<_rounds && count _batteryunits > 0} do
		{
			{
				if (alive _x && (getnumber (configFile >> "cfgVehicles" >> (typeOf (vehicle _x)) >> "artilleryScanner") == 1)) then
				{
					_i=_i+1;
					(vehicle _x) addMagazine _bullet;
					(vehicle _x) commandArtilleryFire [[(_position select 0)+ random _area2 - _area, (_position select 1)+ random  _area2 - _area, 0], _bullet, 1];	
					//Swap this
					_x setVehicleAmmo 1;
					sleep random 1;
				}
				else
				{
					_batteryunits = _batteryunits - [_x];
				};
			} foreach _batteryunits;
			
			_sleep = random _maxcadence;			
			if (_sleep < _mincadence) then {_sleep = _mincadence};
			sleep _sleep;
		};
	
	If (_typeofunit == "MAN") then
	{
		_staticteam = _batteryunits + _assistsmortar;
		{
			
			If (!alive _x) exitwith {_batteryunits = [];};
		} foreach _staticteam; 
				
		If (count _batteryunits > 0) then
		{
			[_staticteam select 0,_staticteam select 0] call UPSMON_Packbag;
		};
		
	};
	
	sleep 30;
	
	If (alive _npc) then
	{
		_support set [0,false];
		_support set [1,_supportrounds];
		
		_grp setVariable ["UPSMON_ArtiOptions",_support];
		_grp setVariable ["UPSMON_OnBattery",false];
	};
};


UPSMON_Flaretime = {
	UPSMON_FlareInTheAir = true;
	sleep 120;
	UPSMON_FlareInTheAir = false;
	Publicvariable "UPSMON_FlareInTheAir";
};