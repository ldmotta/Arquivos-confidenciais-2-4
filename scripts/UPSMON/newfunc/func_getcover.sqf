
//==================================================================
// BY TPWCAS Team
UPS_fnc_find_cover =
{
	private ["_units","_position_use","_unit","_status","_cover","_allcover","_objects","_lineIntersect","_terrainIntersect","_inCover","_coverPosition","_cPos","_vPos"];

	_units 		= 		_this select 0;
	_vdir 		= 		_this select 1;
	_lookpos 	= 		_this select 2;
	_dist 		= 		_this select 3;
	
	_unit 		= 		_units select 0;
	
	_cover = [];
	_allcover = [];
	_position_use = [];
	_coverPosition = [];
	
	_gothit = false;
	
	// sleep 2;
	if (KRON_UPS_Debug>0) then {player sidechat "Cover"};
	//potential cover objects list	
	_objects = [ (nearestObjects [_unit, [], _dist]), { _x call fnc_filter } ] call BIS_fnc_conditionalSelect;

	_nb1 = -1;
	_nb2 = -1;
	If ((_vdir select 0) == 0) then {_nb1 = 1;};
	If ((_vdir select 1) == 0) then {_nb2 = 1;};
	
	
		if ( count _objects > 0 ) then
	{
		{

			_coverfound = false;
			
		while {!_coverfound && count _objects > 0} do 
		{
		
			_gothit = [_x] call Aze_GothitParam;

			_object = _objects select 0;
			_objects = _objects - [_object];
			// start foreach _objects
			 
				If (_gothit) exitwith {};
				if ( !(IsNull _object)) then
				{
					//_x is potential cover object
					_cPos = (position _object);
					// If ((_cpos find _position_use) > -1) then {_use = true;} else {_position_use = _position_use + [_cpos]};
					_vPos = [(_vdir select 0)*(_nb1),(_vdir select 1)*(_nb2),_vdir select 2];
					
					//set coverposition to 1.3 m behind the found cover
					_coverPosition = [((_cPos select 0) + (0.8 * (_vPos select 0))), ((_cPos select 1) + (0.8 * (_vPos select 1))), (_cPos select 2)];
					//_manarray = nearestObjects [_cPos,["MAN"],10]; 
					
		
					//Any object which is high and wide enough is potential cover position, excluding water
					if (!(surfaceIsWater _coverPosition)) exitwith
					{
					
						if (KRON_UPS_Debug>0) then {
							_ballCover = "sign_sphere100cm_F" createvehicle _coverPosition;
							_ballCover attachto [_coverPosition,[0,0,245]];	
							diag_log format ["object: %1",_object];
						};	

						_cover = [_object, _coverPosition];
						_coverfound = true;
					};
				};
			sleep 0.01;
			};

			
				//if cover found order unit to move into cover
			if (_coverfound) then
			{		
				[_x, _cover,_lookpos,_vdir] spawn UPS_fnc_move_to_cover;
			}
			else
			{
			If (!_gothit) then
			{
				_x lookat [_lookpos select 0, _lookpos select 1, 1];
				sleep 1;
				doStop _x;
				_x setUnitPos "DOWN";
				_x setBehaviour "STEALTH";
			}
			else
			{
				_x setUnitPos "DOWN";
				_x setBehaviour "COMBAT";
				(group _x) setCombatMode "YELLOW";
			};
			
			};
			} foreach _units;
			// end foreach _objects
		};
		
};

//======================================================================================================================================================================================================
// By TPWCAS Team
UPS_fnc_move_to_cover =
{
	private ["_unit","_cover","_coverArray","_coverPosition","_coverDist","_coverTarget","_cPos","_vPos","_debug_flag","_dist","_continue","_logOnce","_startTime","_checkTime","_stopped","_tooFar","_tooLong","_elapsedTime"];
	
	_unit 			=	_this select 0;
	_coverArray 	=	_this select 1;
	_lookpos  		=	_this select 2;
	_vdir 			=	_this select 3;
	
	_cover 			=	_coverArray select 0;
	_coverPosition 	= 	_coverArray select 1;

	_sowounded = false;
	_sokilled = false;

	_unit forceSpeed -1;
	_unit doMove _coverPosition;

	_coverDist = round ( _unit distance _coverPosition );

	_stopped = true;
	_continue = true;
	
	_startTime = time;
	_checkTime =  (_startTime + (1.7 * _coverDist) + 20);

	while { _continue } do 
	{
		_gothit = [_unit] call Aze_GothitParam;
			
		_dist = _unit distance _coverPosition;
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

	if ( !( _stopped) ) then 
	{			
			doStop _unit;
			// _lookpos = [getpos _unit,_direction,50] call MON_GetPos;
			if (_unit == leader (group _unit) || random 100 < 50) then 
			{
			_unit dowatch ObjNull;
			_unit dowatch [_lookpos select 0, _lookpos select 1, 1];
			};	
			sleep 0.5;
			doStop _unit;
			if (_unit == leader (group _unit)) then 
			{
				_unit setUnitPos "DOWN";
				_sight = [_unit,getdir _unit, 50] call Aze_CanSee; 
				If (!_sight) then {_unit setUnitPos "MIDDLE";};
			} else 
			{
				_unit setUnitPos "DOWN";
			};
			_unit setBehaviour "STEALTH";
	};
	
};


// By Robalo
fnc_filter = { 
    private ["_type","_z","_bbox","_dz","_dy"]; 
    if (_this isKindOf "Man") exitWith {false}; 
    if (_this isKindOf "Bird") exitWith {false}; 
    if (_this isKindOf "BulletCore") exitWith {false}; 
    if (_this isKindOf "Grenade") exitWith {false}; 
    if (_this isKindOf "WeaponHolder") exitWith {false}; 
    if (_this isKindOf "WeaponHolderSimulated") exitWith {false}; 
    _type = typeOf _this; 
    if (_type == "") then { 
        if (damage _this == 1) exitWith {false}; 
   } else { 
        //if (_type in ["Land_Concrete_SmallWall_4m_F", "Land_Concrete_SmallWall_8m_F"]) exitWith {false}; 
        if (_type in ["#crater","#crateronvehicle","#soundonvehicle","#particlesource","#lightpoint","#slop","#mark","#footprint"]) exitWith {false}; 
        if (["fence", _type] call BIS_fnc_inString) exitWith {false}; 
		if (["b_", _type] call BIS_fnc_inString) exitWith {false};
		if (["t_", _type] call BIS_fnc_inString) exitWith {false};
   }; 
    _z = (getPosATL _this) select 2; 
    if (_z > 0.3) exitWith {false}; 
	_bbox = boundingBoxReal _this;
	_dz = ((_bbox select 1) select 2) - ((_bbox select 0) select 2);
	_dy = abs(((_bbox select 1) select 0) - ((_bbox select 0) select 0));//width
	if ((_dz > 0.35) && (_dy > 0.35) ) exitWith {true};

	false
};  
