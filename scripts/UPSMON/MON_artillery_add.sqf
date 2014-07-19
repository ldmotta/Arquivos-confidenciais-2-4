/*  =====================================================================================================
	MON_spawn.sqf
	Author: Monsada (chs.monsada@gmail.com) 
		Comunidad Hispana de Simulación: 
		http://www.simulacion-esp.com
 =====================================================================================================		
	Parámeters: [_artillery,(_rounds,_area,_cadence,_mincadence)] execvm "scripts\UPSMON\MON_artillery_add.sqf";	
		<- _artillery 		object to attach artillery script, must be an object with gunner.
		<- ( _rounds ) 		number of rounds for the artillery [FLARE,SMOKE,HE]
		<- ( _area ) 		Dispersion area, 150m by default
		<- ( _maxcadence ) 	Cadence of fire, is random between min, default 10s
		<- ( _mincadence )	Minimum cadence, default 5s
 =====================================================================================================
	1.  Place a static weapon on map.
	2. Exec module in int of static weapon

		nul=[this] execVM "scripts\UPSMON\MON_artillery_add.sqf";

	1. Be sure static weapon has a gunner or place a "fortify" squad near, this will make squad to take static weapon.
	2. Create a trigger in your mission for setting when to fire. Set side artillery variable to true:

		UPSMON_ARTILLERY_EAST_FIRE = true;

	This sample will do east artilleries to fire on known enemies position, when you want to stop fire set to false.

	For more info:
	http://dev-heaven.net/projects/upsmon/wiki/Artillery_module
 =====================================================================================================*/
//if (!isserver) exitWith {}; 
if (!isServer) exitWith {};

//Waits until UPSMON is init
waitUntil {!isNil("UPSMON_INIT")};
waitUntil {UPSMON_INIT==1};

private ["_area","_maxcadence","_mincadence","_rounds","_vector","_static","_typeunit","_grp","_cfgArtillery","_grpunits","_batteryunits","_assistsmortar","_unit","_vehicle","_result","_staticteam","_artimuntype","_id","_foundshell","_foundsmoke","_foundrocket","_foundillum","_vector","_sidearty"];

_area = 50;
_maxcadence = 6;
_mincadence = 3;
_rounds = [10,30,50];	
_vector =[];
_typeunit = "MAN";
	
_npc  = _this select 0;
if ((count _this) > 1) then {_rounds = _this select 1;};	
if ((count _this) > 2) then {_area = _this select 2;};	
if ((count _this) > 3) then {_maxcadence = _this select 3;};	
if ((count _this) > 4) then {_mincadence = _this select 4;};

_grp = group _npc;
	
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
	
if (count _batteryunits == 0) exitwith {};
	
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
	If (_x iskindof "StaticWeapon") exitwith {_typeunit = "STATIC"};
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
