//==================================================================
// BY TPWCAS Team
UPSMON_fnc_find_cover =
{
	private ["_unitpos","_lookpos","_dist","_spawn","_units","_cover","_coverPosition","_gothit","_objects","_vdir","_object","_cPos"];

	_unitpos 	= 		_this select 0;
	_lookpos 	= 		_this select 1;
	_dist 		= 		_this select 2;
	_spawn 		= 		_this select 3;
	_units 		= 		_this select 4;
	
	if (_spawn) then 
	{
		{
			_pos2 = _unitpos findEmptyPosition [1,25];
			_x setposATL _pos2;
		}foreach _units;
	};
	
	_cover = [];
	_coverPosition = [];
	
	_gothit = false;
	
	(group (_units select 0)) setvariable ["UPSMON_Cover",true];
	if (UPSMON_Debug>0) then {player sidechat "Cover"};
	//potential cover objects list	
	_objects = [(nearestObjects [_unitpos, [], _dist]), { _x call UPSMON_fnc_filter } ] call BIS_fnc_conditionalSelect;

	_vdir = [_unitpos, _lookpos] call BIS_fnc_DirTo;
	
	if ( count _objects > 0 ) then
	{
		{
			_coverfound = false;
			while {!_coverfound && count _objects > 0} do 
			{
				If (!_spawn) then {_gothit = [_x] call UPSMON_GothitParam;};
				_object = _objects select 0;
				_objects = _objects - [_object];
				
				// start foreach _objects
				If (_gothit) exitwith {};
				if (!(IsNull _object)) then
				{
					//_x is potential cover object
					_cPos = (getPosATL _object);
					
					//set coverposition to 1.3 m behind the found cover
					_coverPosition = [(_cPos select 0) - (sin(_vdir)*1.5), (_cPos select 1) - (cos(_vdir)*1.5), 0];
	
		
					//Any object which is high and wide enough is potential cover position, excluding water
					if (!(surfaceIsWater _coverPosition)) exitwith
					{
					
						if (UPSMON_Debug>0) then {
							_ballCover = "sign_sphere100cm_F" createvehicle _coverPosition;
							_ballCover setpos _coverPosition;	
							diag_log format ["object: %1",_object];
						};	

						_cover = [_object, _coverPosition];
						_coverfound = true;
					};
				};
			};

			
				//if cover found order unit to move into cover
			if (_coverfound) then
			{		
				[_x, _cover,_lookpos,_spawn] spawn UPSMON_fnc_move_to_cover;
			}
			else
			{
				
				If (!_gothit) then
				{
					_x lookat [_lookpos select 0, _lookpos select 1, 1];
					sleep 1;
					doStop _x;
					_x setUnitPos "AUTO";
					_x setBehaviour "STEALTH";
				}
				else
				{
					_x setUnitPos "AUTO";
					_x setBehaviour "COMBAT";
					(group _x) setCombatMode "YELLOW";
				};
			};
		} foreach _units;
		// end foreach _objects
	}
	else
	{
		{
			_x setUnitPos "AUTO";
			_x setBehaviour "COMBAT";
			(group _x) setCombatMode "BLUE";
		} foreach _units;
	};
		
};

//======================================================================================================================================================================================================
// By TPWCAS Team
UPSMON_fnc_move_to_cover =
{
	private ["_unit","_coverArray","_lookpos","_spawn","_cover","_coverPosition","_coverDist","_stopped","_continue","_checkTime","_gothit","_dist","_tooFar","_toolong","_elapsedTime","_sight"];
	
	_unit 			=	_this select 0;
	_coverArray 	=	_this select 1;
	_lookpos  		=	_this select 2;
	_spawn 			= 	_this select 3;
	
	_cover 			=	_coverArray select 0;
	_coverPosition 	= 	_coverArray select 1;

	if (_spawn) then
	{
		player sidechat "spawn to cover";
		_unit setposATL _coverPosition;
		doStop _unit;
			
		if (_unit == leader (group _unit) || random 100 < 50) then 
		{
			_unit dowatch ObjNull;
			_unit dowatch [_lookpos select 0, _lookpos select 1, 1];
		};	
		
		_unit setBehaviour "STEALTH";
	}
	else
	{
		_unit forceSpeed 60;
		_unit doMove _coverPosition;

		_coverDist = round ( _unit distance _coverPosition );

		_stopped = true;
		_continue = true;
	
		_startTime = time;
		_checkTime =  (_startTime + (1.7 * _coverDist) + 20);

		while { _continue } do 
		{
			_gothit = [_unit] call UPSMON_GothitParam;
			
			_dist = ([getposATL _unit,_coverPosition] call UPSMON_distancePosSqr);
			If (_gothit) exitwith {_continue = false;};
		
			if ( !( unitReady _unit ) && ( alive _unit ) && ( _dist > 1.25 ) ) then
			{
				//if unit takes too long to reach cover or moves too far out stop at current location
				_tooFar = ( _dist > ( _coverDist + 10 ));
				_tooLong = ( time >  _checkTime );
				_elapsedTime = time - _checkTime;
			
				if ( _tooFar || _tooLong ) exitWith
				{
					_coverPosition = getPosATL _unit;
					_unit forceSpeed -1;
					_unit doMove _coverPosition;

					_stopped = false;
					_continue = false;
				
				};
				sleep 0.3;
			}
			else
			{	
				_continue = false;
				_stopped = false;
			};
		}; 

		if (!( _stopped)) then 
		{			
			doStop _unit;
			_sight = [_unit,getdir _unit, 50] call UPSMON_CanSee; 
			If (!_sight) then {_unit setUnitPos "AUTO";};
			//_unit setUnitpos "AUTO";
		};	
	};
	
};

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// By Robalo
UPSMON_fnc_filter = { 
    private ["_type","_z","_bbox","_dz","_dy"]; 
    
    if (_this isKindOf "Man") exitWith {false}; 
    if (_this isKindOf "Bird") exitWith {false}; 
    if (_this isKindOf "BulletCore") exitWith {false}; 
    if (_this isKindOf "Grenade") exitWith {false}; 
    if (_this isKindOf "WeaponHolder") exitWith {false}; 
    if (_this isKindOf "WeaponHolderSimulated") exitWith {false};
	if (_this isKindOf "Sound") exitWith {false};
	//if (!isTouchingGround _this) exitWith {false};
	if (isBurning _this) exitWith {false};
	if (["fence", (format ["%1", _this])] call BIS_fnc_inString) exitWith {false};
	if (["slop", (format ["%1", _this])] call BIS_fnc_inString) exitWith {false};
 
 	_type = typeOf _this; 
    if (_type == "") then { 
        if (damage _this == 1) exitWith {false}; 
   } else { 
        //if (_type in ["Land_Concrete_SmallWall_4m_F", "Land_Concrete_SmallWall_8m_F"]) exitWith {false}; 
		if (_type in ["#soundonvehicle","#mark","#crater","#crateronvehicle","#soundonvehicle","#particlesource","#lightpoint","#slop"]) exitWith {false}; 
   };
   
    _z = (getPosATL _this) select 2; 
    if (_z > 0.3) exitWith {false}; 
	_bbox = boundingBoxReal _this;
	_dz = ((_bbox select 1) select 2) - ((_bbox select 0) select 2);
	_dy = abs(((_bbox select 1) select 0) - ((_bbox select 0) select 0));//width
	if ((_dz > 0.35) && (_dy > 0.35) ) exitWith {true};

	false
};  


UPSMON_sample_terrain = {
private ["_sample", "_sampleValue", "_sampleType"];

_sample = selectBestPlaces [
   _this, // sample position
   30, // radius
   "(1000 * houses) + (100 * forest) + (10 * trees) + (1 * meadow) - (1000 * sea)", // expression
   10, // precision
   1 // sourcesCount
];

if ((count _sample) < 1) exitWith
{
   ["undefined", 0]
};

_sampleValue = (_sample select 0) select 1;
_sampleType = "meadow";

switch (true) do
{
   case (_sampleValue > 200):  { _sampleType = "inhabited"; };
   case (_sampleValue > 50):   { _sampleType = "forest"; };
   case (_sampleValue < -992): { _sampleType = "sea"; };
   case (_sampleValue < 0):    { _sampleType = "coast"; };
   case (_sampleValue == 0):   { _sampleType = "undefined"; }; // out of map/end of world
};

// return sample
[_sampleType, _sampleValue]};
